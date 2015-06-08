defmodule Bitcoin.Protocol.Types.InventoryVector do

  @inventory_vector_reference_types %{
    0 => :error, # 0 - Any data of with this number may be ignored
    1 => :msg_tx, # 1 - Hash is related to a transaction
    2 => :msg_block, # 2 - Hash is related to a data block
    3 => :msg_filtered_block # 3 - Hash of a block header; identical to MSG_BLOCK. When used in a getdata message, this indicates the reply should be a merkleblock message rather than a block message; this only works if a bloom filter has been set.
  }

  defstruct reference_type: :error,
            hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>

  @type t :: %Bitcoin.Protocol.Types.InventoryVector{
    reference_type: atom,
    hash: String.t
  }

  def parse(<<type_id :: unsigned-little-integer-size(32), hash :: bytes-size(32)>>) do
    %Bitcoin.Protocol.Types.InventoryVector{
      reference_type: Map.get(@inventory_vector_reference_types, type_id),
      hash: hash
    }
  end

  def parse_stream(<<type_id :: unsigned-little-integer-size(32), hash :: bytes-size(32), remaining_stream :: binary>>) do
    [%Bitcoin.Protocol.Types.InventoryVector{
      reference_type: Map.get(@inventory_vector_reference_types, type_id),
      hash: hash
    }, remaining_stream]
  end

end