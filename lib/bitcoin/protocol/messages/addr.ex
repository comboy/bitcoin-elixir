defmodule Bitcoin.Protocol.Messages.Addr do

  @moduledoc """
    Provide information on known nodes of the network. Non-advertised nodes should be forgotten after typically 3 hours.

    https://en.bitcoin.it/wiki/Protocol_documentation#addr
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.NetworkAddress

  defstruct address_list: []

  @type t :: %Bitcoin.Protocol.Messages.Addr{
    address_list: [NetworkAddress]
  }

  def parse(data) do

    [count, payload] = Integer.parse_stream(data)

    if count > 0 do

      [address_list, _] = Enum.reduce(1..count, [[], payload], fn (_, [addr_collection, payload]) ->
        [element, payload] = NetworkAddress.parse_stream(payload)
        [addr_collection ++ [element], payload]
      end)

    else

      address_list = []

    end

    %Bitcoin.Protocol.Messages.Addr{
      address_list: address_list
    }

  end

end