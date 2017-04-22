defmodule Bitcoin.Protocol.Types.VarString do

  alias Bitcoin.Protocol.Types.VarInteger

  def parse_stream(payload) do
    {string_size, payload} = VarInteger.parse_stream(payload)

    << data :: bytes-size(string_size), payload :: binary >> = payload

    {data, payload}
  end

  def serialize(str), do: (byte_size(str) |> VarInteger.serialize) <> str

end
