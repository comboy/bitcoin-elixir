defmodule Bitcoin.Node.Storage.EngineBehaviour do

  alias Bitcoin.Protocol.Messages

  @callback start_link(map) :: {:ok, pid} | {:error, term}

  @callback store_block(Messages.Block.t, %{height: non_neg_integer}) :: :ok | {:error, term}

  @callback get_block(Bitcoin.Block.t_hash) :: Messages.Block.t

  @callback get_block_height(Bitcoin.Block.t_hash) :: non_neg_integer
  @callback get_tx(Bitcoin.Tx.t_hash) :: Messages.Tx.t
  @callback get_blocks_with_height(non_neg_integer) :: list(Messages.Block.t)

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def get_txout(hash, index) do
        case get_tx(hash) do
          nil -> nil
           tx -> tx.outputs |> Enum.at(index)
        end
      end
      defoverridable get_txout: 2


      def has_block?(hash), do: !! get_block(hash)

      defoverridable has_block?: 1


      # Returns true if the storage engine has transaction index enabled
      def tx_index?, do: false

      defoverridable tx_index?: 0


      # Called by mix storage.prepare task, place for an engine to prepare the schema etc.
      def prepare(opts), do: :ok

      defoverridable prepare: 1

    end
  end

end
