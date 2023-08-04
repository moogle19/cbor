defprotocol CBOR.Encoder do
  @doc """
  Converts an Elixir data type to its representation in CBOR.
  """

  def encode_into(element, acc)
end

defimpl CBOR.Encoder, for: Atom do
  def encode_into(value, acc), do: CBOR.Encode.atom(value, acc)
end

defimpl CBOR.Encoder, for: BitString do
  def encode_into(value, acc), do: CBOR.Encode.string(value, acc)
end

defimpl CBOR.Encoder, for: CBOR.Tag do
  def encode_into(value, acc), do: CBOR.Encode.tag(value, acc)
end

defimpl CBOR.Encoder, for: Date do
  def encode_into(value, acc), do: CBOR.Encode.date(value, acc)
end

defimpl CBOR.Encoder, for: DateTime do
  def encode_into(value, acc), do: CBOR.Encode.date_time(value, acc)
end

defimpl CBOR.Encoder, for: Float do
  def encode_into(value, acc), do: CBOR.Encode.float(value, acc)
end

defimpl CBOR.Encoder, for: Integer do
  def encode_into(value, acc), do: CBOR.Encode.integer(value, acc)
end

defimpl CBOR.Encoder, for: List do
  def encode_into(value, acc), do: CBOR.Encode.list(value, acc)
end

defimpl CBOR.Encoder, for: Map do
  def encode_into(value, acc), do: CBOR.Encode.map(value, acc)
end

# We convert MapSets into lists since there is no 'set' representation
defimpl CBOR.Encoder, for: MapSet do
  def encode_into(value, acc), do: CBOR.Encode.map_set(value, acc)
end

# We treat all NaiveDateTimes as UTC, if you need to include TimeZone
# information you should convert your data to a regular DateTime
defimpl CBOR.Encoder, for: NaiveDateTime do
  def encode_into(value, acc), do: CBOR.Encode.naive_date_time(value, acc)
end

# We convert Ranges into lists since there is no 'range' representation
defimpl CBOR.Encoder, for: Range do
  def encode_into(value, acc), do: CBOR.Encode.range(value, acc)
end

defimpl CBOR.Encoder, for: Time do
  def encode_into(value, acc), do: CBOR.Encode.time(value, acc)
end

# We convert all Tuples to Lists since CBOR has no concept of Tuples,
# and they are basically the same thing anyway. This also fixes the problem
# of having to deal with keyword lists so we don't lose any information.
defimpl CBOR.Encoder, for: Tuple do
  def encode_into(value, acc), do: CBOR.Encode.tuple(value, acc)
end

defimpl CBOR.Encoder, for: URI do
  def encode_into(value, acc), do: CBOR.Encode.uri(value, acc)
end
