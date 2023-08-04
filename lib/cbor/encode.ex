defmodule CBOR.Encode do
  def value(value) when is_atom(value), do: atom(value)
  def value(value) when is_integer(value), do: integer(value)
  def value(value) when is_float(value), do: float(value)
  def value(value) when is_list(value), do: list(value)
  def value(%{__struct__: module} = value), do: do_struct(value, module)
  def value(value) when is_map(value), do: map(value)
  def value(value) when is_bitstring(value), do: string(value)

  def value(value) do
    CBOR.Encoder.encode(value)
  end

  def atom(false), do: <<0xF4>>
  def atom(true), do: <<0xF5>>
  def atom(nil), do: <<0xF6>>
  def atom(:__undefined__), do: <<0xF7>>
  def atom(v), do: CBOR.Utils.encode_string(3, Atom.to_string(v))

  def integer(i) when i >= 0 and i < 0x10000000000000000 do
    CBOR.Utils.encode_head(0, i)
  end

  def integer(i) when i < 0 and i >= -0x10000000000000000 do
    CBOR.Utils.encode_head(1, -i - 1)
  end

  def integer(i) when i >= 0, do: encode_as_bignum(i, 2)
  def integer(i) when i < 0, do: encode_as_bignum(-i - 1, 3)

  def float(f), do: <<0xFB, f::float>>

  def list([]), do: <<0x80>>

  def list([value]), do: [CBOR.Utils.encode_head(4, 1), value(value)]

  def list([head | tail] = list) do
    length = length(list)

    if length < 0x10000000000000000 do
      [CBOR.Utils.encode_head(4, length), value(head) | list_loop(tail)]
    else
      [0x9F, value(head) | large_list_loop(tail)]
    end
  end

  def map(map) do
    size = map_size(map)
    list = Map.to_list(map)

    cond do
      size === 0 ->
        <<0xA0>>

      size < 0x10000000000000000 ->
        [CBOR.Utils.encode_head(5, size) | map_loop(list)]

      true ->
        [0xBF | large_map_loop(list)]
    end
  end

  def string(string), do: CBOR.Utils.encode_string(3, string)

  def struct(%module{} = value), do: do_struct(value, module)

  for module <- [Date, Time, DateTime] do
    defp do_struct(value, unquote(module)),
      do: [CBOR.Utils.encode_head(6, 0), value |> unquote(module).to_iso8601() |> string()]
  end

  defp do_struct(value, NaiveDateTime),
    do: [
      CBOR.Utils.encode_head(6, 0),
      value |> NaiveDateTime.to_iso8601() |> Kernel.<>("Z") |> string()
    ]

  defp do_struct(value, _other), do: CBOR.Encoder.encode(value)

  defp map_loop([{key, value}]), do: [value(key), value(value)]
  defp map_loop([{key, value} | tail]), do: [value(key), value(value) | map_loop(tail)]

  defp large_map_loop([{key, value}]), do: [value(key), value(value), 0xFF]

  defp large_map_loop([{key, value} | tail]),
    do: [value(key), value(value) | large_map_loop(tail)]

  defp list_loop([value]), do: value(value)
  defp list_loop([head | tail]), do: [value(head) | list_loop(tail)]

  defp large_list_loop([value]), do: [value(value), 0xFF]
  defp large_list_loop([head | tail]), do: [value(head) | large_list_loop(tail)]

  defp encode_as_bignum(i, tag) do
    CBOR.Utils.encode_string(
      2,
      :binary.encode_unsigned(i),
      CBOR.Utils.encode_head(6, tag)
    )
  end
end
