defmodule Bitcoin.Protocol.Messages.GetData do

  @moduledoc """
    getdata is used in response to inv, to retrieve the content of a specific object, and is usually sent after
    receiving an inv packet, after filtering known elements. It can be used to retrieve transactions, but only
    if they are in the memory pool or relay set - arbitrary access to transactions in the chain is not allowed
    to avoid having clients start to depend on nodes having full transaction indexes (which modern nodes do not).

    https://en.bitcoin.it/wiki/Protocol_specification#getdata
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
