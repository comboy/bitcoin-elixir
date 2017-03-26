defmodule Bitcoin.Protocol.Messages.Inv do

  @moduledoc """
    Allows a node to advertise its knowledge of one or more objects. It can be received unsolicited, or in reply to getblocks.

    https://en.bitcoin.it/wiki/Protocol_documentation#inv
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.InventoryVector

  defstruct inventory_vectors: []

  @type t :: %__MODULE__{
    inventory_vectors: [InventoryVector]
  }

  def parse(data) do

    [count, payload] = Integer.parse_stream(data)

    inventory_vectors = if count > 0 do

      [vects, _] = Enum.reduce(1..count, [[], payload], fn (_, [collection, payload]) ->
        [element, payload] = InventoryVector.parse_stream(payload)
        [collection ++ [element], payload]
      end)

      vects

    else

      []

    end

    %__MODULE__{
      inventory_vectors: inventory_vectors
    }

  end

  def serialize(%__MODULE__{} = s) do
    Integer.serialize(s.inventory_vectors |> Enum.count)
    <> (
      s.inventory_vectors 
        |> Enum.map(&InventoryVector.serialize/1)
        |> Enum.reverse # we are appending to the beginning of the list in reduce
        |> Enum.reduce(<<>>, &Kernel.<>/2)
    )
  end

end
