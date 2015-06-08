defmodule Bitcoin.Protocol.Messages.Headers do

  @moduledoc """
    The headers packet returns block headers in response to a getheaders packet.

    Note that the block headers in this packet include a transaction count (a var_int, so there can be more than 81
    bytes per header) as opposed to the block headers which are sent to miners.

    https://en.bitcoin.it/wiki/Protocol_documentation#headers
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.BlockHeader

  defstruct headers: [] # Bitcoin.Protocol.Types.BlockHeader[], https://en.bitcoin.it/wiki/Protocol_specification#Block_Headers

  @type t :: %Bitcoin.Protocol.Messages.Headers{
    headers: [BlockHeader]
  }

  def parse(data) do

    [header_count, payload] = Integer.parse_stream(data)

    [headers, _] = Enum.reduce(1..header_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = BlockHeader.parse_stream(payload)
      [collection ++ [element], payload]
    end)

    %Bitcoin.Protocol.Messages.Headers{
      headers: headers
    }

  end

end