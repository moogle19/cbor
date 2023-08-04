defmodule CBOR.Encode do
  def value(value, acc) when is_atom(value), do: atom(value, acc)
  def value(value, acc) when is_integer(value), do: integer(value, acc)
  def value(value, acc) when is_float(value), do: float(value, acc)
  def value(value, acc) when is_list(value), do: list(value, acc)
  def value(value, acc) when is_tuple(value), do: tuple(value, acc)
  def value(%{__struct__: module} = value, acc), do: do_struct(value, module, acc)
  def value(value, acc) when is_map(value), do: map(value, acc)
  def value(value, acc) when is_bitstring(value), do: string(value, acc)

  def atom(false, acc), do: <<acc::binary, 0xF4>>
  def atom(true, acc), do: <<acc::binary, 0xF5>>
  def atom(nil, acc), do: <<acc::binary, 0xF6>>
  def atom(:__undefined__, acc), do: <<acc::binary, 0xF7>>
  def atom(v, acc), do: CBOR.Utils.encode_string(3, Atom.to_string(v), acc)

  def string(s, acc), do: CBOR.Utils.encode_string(3, s, acc)

  def tag(%CBOR.Tag{tag: :bytes, value: s}, acc) do
    CBOR.Utils.encode_string(2, s, acc)
  end

  def tag(%CBOR.Tag{tag: :float, value: :inf}, acc) do
    <<acc::binary, 0xF9, 0x7C, 0>>
  end

  def tag(%CBOR.Tag{tag: :float, value: :"-inf"}, acc) do
    <<acc::binary, 0xF9, 0xFC, 0>>
  end

  def tag(%CBOR.Tag{tag: :float, value: :nan}, acc) do
    <<acc::binary, 0xF9, 0x7E, 0>>
  end

  def tag(%CBOR.Tag{tag: :simple, value: val}, acc) when val < 0x100 do
    CBOR.Utils.encode_head(7, val, acc)
  end

  def tag(%CBOR.Tag{tag: tag, value: val}, acc) do
    tag(val, CBOR.Utils.encode_head(6, tag, acc))
  end

  def date(time, acc) do
    CBOR.Encoder.encode_into(
      Date.to_iso8601(time),
      CBOR.Utils.encode_head(6, 0, acc)
    )
  end

  def date_time(datetime, acc) do
    CBOR.Encoder.encode_into(
      DateTime.to_iso8601(datetime),
      CBOR.Utils.encode_head(6, 0, acc)
    )
  end

  def float(x, acc), do: <<acc::binary, 0xFB, x::float>>

  def integer(i, acc) when i >= 0 and i < 0x10000000000000000 do
    CBOR.Utils.encode_head(0, i, acc)
  end

  def integer(i, acc) when i < 0 and i >= -0x10000000000000000 do
    CBOR.Utils.encode_head(1, -i - 1, acc)
  end

  def integer(i, acc) when i >= 0, do: encode_as_bignum(i, 2, acc)
  def integer(i, acc) when i < 0, do: encode_as_bignum(-i - 1, 3, acc)

  defp encode_as_bignum(i, tag, acc) do
    CBOR.Utils.encode_string(
      2,
      :binary.encode_unsigned(i),
      CBOR.Utils.encode_head(6, tag, acc)
    )
  end

  def list([], acc), do: <<acc::binary, 0x80>>

  def list(list, acc) when length(list) < 0x10000000000000000 do
    Enum.reduce(list, CBOR.Utils.encode_head(4, length(list), acc), fn v, acc ->
      value(v, acc)
    end)
  end

  def list(list, acc) do
    Enum.reduce(list, <<acc::binary, 0x9F>>, fn v, acc ->
      value(v, acc)
    end) <> <<0xFF>>
  end

  def map(map, acc) when map_size(map) == 0, do: <<acc::binary, 0xA0>>

  def map(map, acc) when map_size(map) < 0x10000000000000000 do
    Enum.reduce(map, CBOR.Utils.encode_head(5, map_size(map), acc), fn {k, v}, subacc ->
      value(v, value(k, subacc))
    end)
  end

  def map(map, acc) do
    Enum.reduce(map, <<acc::binary, 0xBF>>, fn {k, v}, subacc ->
      value(v, value(k, subacc))
    end) <> <<0xFF>>
  end

  # We convert MapSets into lists since there is no 'set' representation
  def map_set(map_set, acc) do
    map_set |> MapSet.to_list() |> CBOR.Encoder.encode_into(acc)
  end

  # We treat all NaiveDateTimes as UTC, if you need to include TimeZone
  # information you should convert your data to a regular DateTime
  def naive_date_time(naive_datetime, acc) do
    CBOR.Encoder.encode_into(
      NaiveDateTime.to_iso8601(naive_datetime) <> "Z",
      CBOR.Utils.encode_head(6, 0, acc)
    )
  end

  # We convert Ranges into lists since there is no 'range' representation
  def range(range, acc) do
    range |> Enum.into([]) |> CBOR.Encoder.encode_into(acc)
  end

  def time(time, acc) do
    CBOR.Encoder.encode_into(
      Time.to_iso8601(time),
      CBOR.Utils.encode_head(6, 0, acc)
    )
  end

  # and they are basically the same thing anyway. This also fixes the problem
  # of having to deal with keyword lists so we don't lose any information.
  def tuple(tuple, acc) do
    tuple |> Tuple.to_list() |> CBOR.Encoder.encode_into(acc)
  end

  def uri(uri, acc) do
    CBOR.Encoder.encode_into(
      URI.to_string(uri),
      CBOR.Utils.encode_head(6, 32, acc)
    )
  end

  defp do_struct(value, NaiveDateTime, acc), do: naive_date_time(value, acc)
  defp do_struct(value, Date, acc), do: date(value, acc)
  defp do_struct(value, Time, acc), do: time(value, acc)
  defp do_struct(value, DateTime, acc), do: date_time(value, acc)
  defp do_struct(value, Range, acc), do: range(value, acc)
  defp do_struct(value, MapSet, acc), do: map_set(value, acc)
  defp do_struct(value, URI, acc), do: uri(value, acc)
  defp do_struct(value, CBOR.Tag, acc), do: tag(value, acc)
end
