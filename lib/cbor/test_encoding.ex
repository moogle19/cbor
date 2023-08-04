defmodule TestEncoding do
  @struct %{
    "2" => %{
      "25" => 78.2234,
      "33" => true,
      "92" => %{
        "5" => 19,
        "77" => "Charlie"
      }
    },
    "31" => %{
      "51" => "David",
      "93" => %{
        "35" => %{
          "78" => 0.6829
        }
      },
      "94" => 54.895,
      "97" => 46
    },
    "list" => ["list", "with", "values"],
    "45" => 0.1926
  }

  def run do
    CBOR.encode(@struct)
  end
end
