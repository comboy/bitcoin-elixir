defmodule Bitcoin.Protocol.Messages.GetData do

  @moduledoc """
    getdata is used in response to inv, to retrieve the content of a specific object, and is usually sent after
    receiving an inv packet, after filtering known elements. It can be used to retrieve transactions, but only
    if they are in the memory pool or relay set - arbitrary access to transactions in the chain is not allowed
    to avoid having clients start to depend on nodes having full transaction indexes (which modern nodes do not).

    https://en.bitcoin.it/wiki/Protocol_specification#getdata
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.InventoryVector

  defstruct inventory_vectors: []

  @type t :: %Bitcoin.Protocol.Messages.GetData{
    inventory_vectors: [InventoryVector]
  }

  def parse(data) do

    [count, payload] = Integer.parse_stream(data)

    if count > 0 do

      [inventory_vectors, _] = Enum.reduce(1..count, [[], payload], fn (_, [collection, payload]) ->
        [element, payload] = InventoryVector.parse_stream(payload)
        [collection ++ [element], payload]
      end)

    else

      inventory_vectors = []

    end

    %Bitcoin.Protocol.Messages.GetData{
      inventory_vectors: inventory_vectors
    }

  end

end