defmodule Bitcoin.Protocol.Messages.NotFound do

  @moduledoc """
    notfound is a response to a getdata, sent if any requested data items could not be relayed, for example, because
    the requested transaction was not in the memory pool or relay set.

    https://en.bitcoin.it/wiki/Protocol_specification#notfound
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.InventoryVector

  defstruct inventory_vectors: []

  @type t :: %Bitcoin.Protocol.Messages.NotFound{
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

    %Bitcoin.Protocol.Messages.NotFound{
      inventory_vectors: inventory_vectors
    }

  end

end