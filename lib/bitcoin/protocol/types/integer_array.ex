defmodule Bitcoin.Protocol.Types.IntegerArray do

  alias Bitcoin.Protocol.Types.Integer

  def parse_stream(data) do

    [array_size, payload] = Integer.parse_stream(data)

    if array_size > 0 do

      Enum.reduce(1..array_size, [[], payload], fn (_, [element_collection, payload]) ->
        [element, payload] = Integer.parse_stream(payload)
        [element_collection ++ [element], payload]
      end)

    else

      [[], payload]

    end

  end

end