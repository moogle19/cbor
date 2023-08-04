defprotocol CBOR.Encoder do
  @doc """
  Converts an Elixir data type to its representation in CBOR.
  """

  def encode(element)
end

defimpl CBOR.Encoder, for: Atom do
  def encode(atom), do: CBOR.Encode.atom(atom)
end

defimpl CBOR.Encoder, for: Integer do
  def encode(integer), do: CBOR.Encode.integer(integer)
end

defimpl CBOR.Encoder, for: Float do
  def encode(float), do: CBOR.Encode.float(float)
end

defimpl CBOR.Encoder, for: List do
  def encode(list), do: CBOR.Encode.list(list)
end

defimpl CBOR.Encoder, for: Map do
  def encode(map), do: CBOR.Encode.map(map)
end

defimpl CBOR.Encoder, for: BitString do
  def encode(string), do: CBOR.Encode.string(string)
end

defimpl CBOR.Encoder, for: CBOR.Tag do
  def encode(%CBOR.Tag{tag: :bytes, value: s}) do
    CBOR.Utils.encode_string(2, s)
  end

  def encode(%CBOR.Tag{tag: :float, value: :inf}) do
    <<0xF9, 0x7C, 0>>
  end

  def encode(%CBOR.Tag{tag: :float, value: :"-inf"}) do
    <<0xF9, 0xFC, 0>>
  end

  def encode(%CBOR.Tag{tag: :float, value: :nan}) do
    <<0xF9, 0x7E, 0>>
  end

  def encode(%CBOR.Tag{tag: :simple, value: val}) when val < 0x100 do
    CBOR.Utils.encode_head(7, val)
  end

  def encode(%CBOR.Tag{tag: tag, value: val}) do
    [CBOR.Utils.encode_head(6, tag), CBOR.Encode.value(val)]
  end
end

defimpl CBOR.Encoder, for: [Date, Time, DateTime] do
  def encode(value) do
    [CBOR.Utils.encode_head(6, 0), value |> @for.to_iso8601() |> CBOR.Encode.string()]
  end
end

# We treat all NaiveDateTimes as UTC, if you need to include TimeZone
# information you should convert your data to a regular DateTime
defimpl CBOR.Encoder, for: NaiveDateTime do
  def encode(value) do
    [
      CBOR.Utils.encode_head(6, 0),
      value |> @for.to_iso8601() |> Kernel.<>("Z") |> CBOR.Encode.string()
    ]
  end
end

# We convert MapSets into lists since there is no 'set' representation
defimpl CBOR.Encoder, for: MapSet do
  def encode(map_set) do
    map_set |> MapSet.to_list() |> CBOR.Encode.list()
  end
end

# We convert Ranges into lists since there is no 'range' representation
defimpl CBOR.Encoder, for: Range do
  def encode(range) do
    range |> Enum.into([]) |> CBOR.Encode.list()
  end
end

# We convert all Tuples to Lists since CBOR has no concept of Tuples,
# and they are basically the same thing anyway. This also fixes the problem
# of having to deal with keyword lists so we don't lose any information.
defimpl CBOR.Encoder, for: Tuple do
  def encode(tuple) do
    tuple |> Tuple.to_list() |> CBOR.Encode.list()
  end
end

defimpl CBOR.Encoder, for: URI do
  def encode(uri) do
    [CBOR.Utils.encode_head(6, 32), uri |> URI.to_string() |> CBOR.Encode.string()]
  end
end
