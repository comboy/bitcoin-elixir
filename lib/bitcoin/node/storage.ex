defmodule Bitcoin.Node.Storage do

  use GenServer

  alias Bitcoin.Protocol.Messages

  @engine Bitcoin.Node.Storage.Engine.Dummy #FIXME dynamic from config

  def start_link(opts \\ %{}) do
    {:ok, pid} = @engine.start_link(opts)
    if @engine.max_height() == nil, do: store_block(Bitcoin.Const.genesis_block())
    {:ok, pid}
  end

  def store(%Messages.Block{} = block), do: store_block(block)

  def max_height, do: @engine.max_height()

  def get_blocks_with_height(height) when is_number(height) and height >= 0, do: @engine.get_blocks_with_height(height)

  def store_block(block) do
    # TODO do we do validationo here or elsewhere?
    # To ensure consistency it would be good to have validation here. If Node.Storage is a genserver,
    # (Node.Storage is not currently)
    # we can be sure that after we're done with validation, chain state didn't change.
    # On the other hand we could make use of the fact that transactions are alerady validated
    # and only try to recheck after reorg? (check how core does this)
    case block |> Bitcoin.Block.validate do
      :ok ->
        # TODO also add hash to the struct, we need the storage struct
        case block |> block_height() do
          :error ->
            {:error, :no_previous}
          height when is_number(height) ->
            @engine.store_block(block |> Map.put(:height, height))
        end
      {:error, reason} -> {:error, reason}
    end
  end

  def block_height(%{height: height} = _block) when height != nil, do: height
  def block_height(block) do
    case get_block(block.previous_block) do
      nil   ->
        if Bitcoin.Block.hash(block) == Bitcoin.Const.genesis_hash() do
          0
        else
          :error
        end
      block -> block_height(block) + 1
    end
  end

  def get_block(hash), do: @engine.get_block(hash)
  def get_tx(hash), do: @engine.get_tx(hash)
end
