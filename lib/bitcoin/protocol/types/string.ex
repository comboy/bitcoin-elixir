defmodule Bitcoin.Protocol.Types.String do

  alias Bitcoin.Protocol.Types.Integer

  def parse_stream(data) do

    [string_size, payload] = Integer.parse_stream(data)

    if string_size > 0 do

      <<str :: bytes-size(string_size), payload :: binary>> = payload
      [ str, payload ]

    else

      [ <<>>, payload ]

    end

  end
end