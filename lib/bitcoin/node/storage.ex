defmodule Bitcoin.Node.Storage do

  @moduledoc """
  Handles blocks and transactions persistance.

  This module is responsible for logic of storage, engine below should only do simple tasks.

  TODO ponder we want validation to be done in the specific blockchain context, which
  Storage GenServer could provide (at least for blocks storage), but not sure if blocking
  whole storage for the whole validation time is a good idea. Maybe just put blocks storage
  inside GenServer (remember timeout)?
  """

  use GenServer
  use Bitcoin.Common

  alias Bitcoin.Protocol.Messages

  @engine @modules[:storage_engine]

  @spec start_link(map) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ %{}) do
    case @engine.start_link(opts) do
      {:ok, pid} ->
        if @engine.max_height() == nil, do: store_block(@genesis_block)
        {:ok, pid}
      {:error, error} -> {:error, error}
    end
  end

  def store(%Messages.Block{} = block), do: store_block(block)

  def max_height, do: @engine.max_height()

  def get_blocks_with_height(height) when is_number(height) and height >= 0, do: @engine.get_blocks_with_height(height)

  @spec store_block(Messages.Block.t) :: :ok | {:error, term}
  def store_block(%Messages.Block{} = block) do
    # TODO do we do validationo here or elsewhere?
    # To ensure consistency it would be good to have validation here. If Node.Storage is a genserver,
    # (Node.Storage is not currently)
    # we can be sure that after we're done with validation, chain state didn't change.
    # On the other hand we could make use of the fact that transactions are alerady validated
    # and only try to recheck after reorg? (check how core does this)
    # TODO where do we decide the main chain? Sum of difficulty could be cached with the stored block but
    # maybe that's implementation detail of the engine that doesn't need to be exposed here?
    hash = block |> Bitcoin.Block.hash
    if has_block?(hash) do
      :ok # or should it be {:error, :already_stored} ?
    else
      case block |> block_height() do
        :error ->
          {:error, :no_parent}
        height when is_number(height) ->
          case block |> Bitcoin.Block.validate(%{height: height})  do
            :ok ->
               # TODO also add hash to the struct, we need the storage struct
               @engine.store_block(block |> Map.put(:height, height))
            {:error, reason} -> {:error, reason}
          end
      end
    end
  end

  @spec block_height(Bitcoin.Block.t_hash | Messages.Block.t) :: non_neg_integer | :error
  def block_height(block_hash)

  def block_height(@genesis_hash), do: 0
  def block_height(@genesis_block), do: 0
  def block_height(block_hash) when is_binary(block_hash), do: get_block(block_hash) |> block_height
  def block_height(%{height: height} = _block) when height != nil, do: height
  def block_height(block) do
    case get_block(block.previous_block) do
      nil   ->
        if Bitcoin.Block.hash(block) == @genesis_hash do
          0
        else
          :error
        end
      block -> block_height(block) + 1
    end
  end

  # TODO proper has_block?
  def has_block?(hash), do: @engine.get_block(hash) != nil
  def get_block(hash), do: @engine.get_block(hash)
  def get_tx(hash), do: @engine.get_tx(hash)
end
