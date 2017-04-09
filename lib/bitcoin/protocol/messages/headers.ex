defmodule Bitcoin.Protocol.Messages.Headers do

  @moduledoc """
    The headers packet returns block headers in response to a getheaders packet.

    Note that the block headers in this packet include a transaction count (a var_int, so there can be more than 81
    bytes per header) as opposed to the block headers which are sent to miners.

    https://en.bitcoin.it/wiki/Protocol_documentation#headers


    Block headers: each 80-byte block header is in the format described in the block headers section with an additional 0x00 suffixed. This 0x00 is called the transaction count, but because the headers message doesn’t include any transactions, the transaction count is always zero.

    https://bitcoin.org/en/developer-reference#headers
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.BlockHeader

  import Bitcoin.Protocol

  defstruct headers: [] # Bitcoin.Protocol.Types.BlockHeader[], https://en.bitcoin.it/wiki/Protocol_specification#Block_Headers

  @type t :: %Bitcoin.Protocol.Messages.Headers{
    headers: [BlockHeader]
  }

  def parse(payload) do
    [headers, _payload] = payload |> collect_items(BlockHeader)

    %Bitcoin.Protocol.Messages.Headers{
      headers: headers
    }
  end

  def serialize(%__MODULE__{} = s) do
    s.headers |> serialize_items
  end

end
