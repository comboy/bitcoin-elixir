defmodule Bitcoin.Protocol.Types.StringArray do

  alias Bitcoin.Protocol.Types.VarInteger
  alias Bitcoin.Protocol.Types.VarString

  def parse_stream(data) do

    [array_size, payload] = VarInteger.parse_stream(data)

    if array_size > 0 do

      Enum.reduce(1..array_size, [[], payload], fn (_, [element_collection, payload]) ->
        [element, payload] = VarString.parse_stream(payload)
        [element_collection ++ [element], payload]
      end)

    else

      [[], payload]

    end

  end

end
