defmodule Bitcoin.Protocol.Types.InventoryVector do

  @inventory_vector_reference_types %{
    0 => :error, # 0 - Any data of with this number may be ignored
    1 => :msg_tx, # 1 - Hash is related to a transaction
    2 => :msg_block, # 2 - Hash is related to a data block
    3 => :msg_filtered_block # 3 - Hash of a block header; identical to MSG_BLOCK. When used in a getdata message, this indicates the reply should be a merkleblock message rather than a block message; this only works if a bloom filter has been set.
  }

  defstruct reference_type: :error,
            hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>

  @type t :: %__MODULE__{
    reference_type: atom,
    hash: Bitcoin.t_hash
  }

  defimpl Inspect, for: __MODULE__ do
    def inspect(data, _opts) do
      "%InventoryVector{ #{data.reference_type} :: #{data.hash |> Base.encode16} }"
    end
  end

  @spec parse(binary) :: t
  def parse(<<type_id :: unsigned-little-integer-size(32), hash :: bytes-size(32)>>) do
    %__MODULE__{
      reference_type: type_id |> get_type_name,
      hash: hash
    }
  end

  @spec parse_stream(binary) :: {t, binary}
  def parse_stream(<<type_id :: unsigned-little-integer-size(32), hash :: bytes-size(32), remaining_stream :: binary>>) do
    {%__MODULE__{
      reference_type: type_id |> get_type_name,
      hash: hash
    }, remaining_stream}
  end

  @spec serialize(t) :: binary
  def serialize(%__MODULE__{} = s) do
    type_id = s.reference_type |> get_type_id
    <<
      type_id :: unsigned-little-integer-size(32),
      s.hash :: bytes-size(32)
    >>
  end

  defp get_type_id(type_name) do
    @inventory_vector_reference_types |> Enum.map(fn {k,v} -> {v,k} end) |> Enum.into(%{}) |> Map.get(type_name)
  end

  defp get_type_name(type_id) do
    @inventory_vector_reference_types |> Map.get(type_id)
  end

end
