defmodule Bitcoin.Protocol.Types.String do

  alias Bitcoin.Protocol.Types.Integer

  def parse_stream(payload) do
    [string_size, payload] = Integer.parse_stream(payload)

    << data :: bytes-size(string_size), payload :: binary >> = payload

    [data, payload]
  end

  def serialize(str), do: (byte_size(str) |> Integer.serialize) <> str

end
