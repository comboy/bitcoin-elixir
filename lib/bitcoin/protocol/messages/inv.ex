defmodule Bitcoin.Protocol.Messages.Inv do

  @moduledoc """
    Allows a node to advertise its knowledge of one or more objects. It can be received unsolicited, or in reply to getblocks.

    https://en.bitcoin.it/wiki/Protocol_documentation#inv
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.InventoryVector

  defstruct inventory_vectors: []

  @type t :: %Bitcoin.Protocol.Messages.Inv{
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

    %Bitcoin.Protocol.Messages.Inv{
      inventory_vectors: inventory_vectors
    }

  end

end