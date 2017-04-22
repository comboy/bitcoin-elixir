defmodule Bitcoin.Protocol.Messages.Inv do

  @moduledoc """
    Allows a node to advertise its knowledge of one or more objects. It can be received unsolicited, or in reply to getblocks.

    https://en.bitcoin.it/wiki/Protocol_documentation#inv
  """

  alias Bitcoin.Protocol.Types.InventoryVector

  import Bitcoin.Protocol

  defstruct inventory_vectors: []

  @type t :: %__MODULE__{
    inventory_vectors: [InventoryVector]
  }


  def parse(payload) do
    {inventory_vectors, _} = payload |> collect_items(InventoryVector)

    %__MODULE__{
      inventory_vectors: inventory_vectors
    }
  end

  def serialize(%__MODULE__{} = s) do
    s.inventory_vectors |> serialize_items
  end

end
