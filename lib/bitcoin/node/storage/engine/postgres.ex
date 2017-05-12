defmodule Bitcoin.Node.Storage.Engine.Postgres do

  use Bitcoin.Node.Storage.EngineBehaviour

  alias Bitcoin.Node.Storage.Engine.Postgres
  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types
  alias Postgres.Repo
  alias Postgres.Models

  require Logger

  def start_link(_) do
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, pid} = Postgres.Repo.start_link
    run_migration() # Check if the schema is present
    {:ok, pid}
  end

  def max_height do
    import Ecto.Query

    Models.Block
    |> select([b], max(b.height))
    |> Repo.one
  end

  @spec store_block(Mesasges.Block.t, %{height: non_neg_integer}) :: :ok
  def store_block(%Messages.Block{} = block_msg, %{height: height} = opts) do
    hash = opts[:hash] || Bitcoin.Block.hash(block_msg)

    Repo.transaction fn ->
      tx_with_hashes = block_msg.transactions |> Enum.map(fn tx ->
        {Bitcoin.Tx.hash(tx), tx}
      end)

      # Persist the block, it stores transactions hashes in an array
      struct(Models.Block, block_msg |> Map.delete(:__struct__))
      |> Map.put(:transactions, tx_with_hashes |> Enum.map(& &1 |> elem(0)))
      |> Map.put(:hash, hash)
      |> Map.put(:height, height)
      |> Repo.insert!

      # We group inputs, outputs and tx to batch inssert them because it's much faster
      # I'm not yet sure though if insert_all does the prroper postgres batch insert TODO check
      # If it doesn't, moebius does.

      # Persist all transactions
      txs =
        tx_with_hashes
        |> Enum.map(fn {tx_hash, tx} ->
          %{hash: tx_hash,
            version: tx.version,
            lock_time: tx.lock_time }
        end)
      Repo.insert_all(Models.Tx, txs, on_conflict: :nothing)

      # Persist all inputs
      inputs =
        tx_with_hashes
        |> Enum.map(fn {tx_hash, tx} ->
          tx.inputs |> Enum.with_index |> Enum.map(fn {input, idx} ->
            %{tx_hash: tx_hash,
              index: idx,
              prevout_hash: input.previous_output.hash,
              prevout_index: input.previous_output.index,
              sig_script: input.signature_script,
              sequence: input.sequence }
          end)
        end)
        |> List.flatten
      Repo.insert_all(Models.TxInput, inputs, on_conflict: :nothing)

      # Persist all outputs
      outputs =
        tx_with_hashes
        |> Enum.map(fn {tx_hash, tx} ->
          tx.outputs |> Enum.with_index |> Enum.map(fn {output, idx} ->
            %{tx_hash: tx_hash,
              index: idx,
              value: output.value,
              pk_script: output.pk_script }
          end)
        end)
        |> List.flatten
      Repo.insert_all(Models.TxOutput, outputs, on_conflict: :nothing)
    end

    :ok
  end

  def get_block(hash) do
    import Ecto.Query

    Models.Block
    |> where(hash: ^hash)
    |> Repo.one
    |> load_block
  end

  def get_block_height(hash) do
    import Ecto.Query

    block =
      Models.Block
      |> where(hash: ^hash)
      |> select([:height])
      |> Repo.one

    block && block.height
  end

  def get_blocks_with_height(height) do
    import Ecto.Query

    Models.Block
    |> where(height: ^height)
    |> Repo.all
    |> Enum.map(&load_block/1)
  end

  def get_tx(hash) do
    import Ecto.Query

    tx =
      Models.Tx
      |> where(hash: ^hash)
      |> Repo.one

    case tx do
      nil -> nil
      _tx ->
        tx_inputs =
          Models.TxInput
          |> where(tx_hash: ^hash)
          |> order_by([t], t.index)
          |> Repo.all
          |> Enum.map(&load_input/1)

        tx_outputs =
          Models.TxOutput
          |> where(tx_hash: ^hash)
          |> order_by([t], t.index)
          |> Repo.all
          |> Enum.map(&load_output/1)

        %Messages.Tx{
          version: tx.version,
          lock_time: tx.lock_time,
          inputs: tx_inputs,
          outputs: tx_outputs
        }
    end
  end

  def prepare(_) do
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = start_link(%{})
    :ok = run_migration()
  end

  defp run_migration do
    # WAT function_exported?( for this function returns false without this o_O
    # which confuses Ecto migratio, no time to debug, calling it fixes it
    Bitcoin.Node.Storage.Engine.Postgres.Migration.__migration__
    Ecto.Migrator.run(Postgres.Repo, [{0, Postgres.Migration}], :up, all: true)
    :ok
  end

  defp load_block(nil), do: nil
  defp load_block(%Models.Block{} = block) do
    # FIXME OPTIMIZE
    # N+1 TX
    # and also we want to fetch inputs/outputs from all transactions in a single query
    struct(Messages.Block,
      block
      |> Map.from_struct
      |> Map.put(:transactions, block.transactions |> Enum.map(&get_tx/1))
    )
  end

  defp load_output(%Models.TxOutput{} = output) do
    %Types.TxOutput{
      value: output.value,
      pk_script: output.pk_script
    }
  end

  defp load_input(%Models.TxInput{} = input) do
    %Types.TxInput{
      sequence: input.sequence,
      signature_script: input.sig_script,
      previous_output: %Types.Outpoint{
        hash: input.prevout_hash,
        index: input.prevout_index,
      }
    }
  end

end
