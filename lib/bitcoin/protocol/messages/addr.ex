defmodule Bitcoin.Protocol.Messages.Addr do

  @moduledoc """
    Provide information on known nodes of the network. Non-advertised nodes should be forgotten after typically 3 hours.

    https://en.bitcoin.it/wiki/Protocol_documentation#addr
  """

  alias Bitcoin.Protocol.Types.NetworkAddress

  import Bitcoin.Protocol

  defstruct address_list: []

  @type t :: %__MODULE__{
    address_list: [NetworkAddress.t]
  }

  @spec parse(binary) :: t
  def parse(payload) do

    {address_list, _payload} = payload |> collect_items(NetworkAddress)

    %__MODULE__{
      address_list: address_list
    }
  end

  @spec serialize(t) :: binary
  def serialize(%__MODULE__{} = s) do
    s.address_list |> serialize_items
  end

end
