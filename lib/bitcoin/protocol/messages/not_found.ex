defmodule Bitcoin.Protocol.Messages.NotFound do

  @moduledoc """
    notfound is a response to a getdata, sent if any requested data items could not be relayed, for example, because
    the requested transaction was not in the memory pool or relay set.

    https://en.bitcoin.it/wiki/Protocol_specification#notfound
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
