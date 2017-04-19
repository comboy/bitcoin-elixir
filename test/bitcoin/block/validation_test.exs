defmodule Bitcoin.Block.ValidationTest do

  use ExUnit.Case

  @block1 File.read!("test/data/blk_100000.dat") |> Bitcoin.Protocol.Messages.Block.parse

  test "hash_below_target" do
    assert @block1 |> Bitcoin.Block.Validation.hash_below_target == :ok
    assert @block1 |> Map.put(:nonce, 1) |> Bitcoin.Block.Validation.hash_below_target == {:error, :hash_above_target}
  end

  test "coinbase value" do
    # Dropping transactions other than coinbase to avoid dealing with prevouts
    block = @block1 |> Map.put(:transactions, @block1.transactions |> Enum.take(1))

    # TODO test that is using storage and checks if transaction fees are taken into account
    assert block |> Bitcoin.Block.Validation.coinbase_value(height: 100_000) == :ok
    assert block |> Bitcoin.Block.Validation.coinbase_value(height: 209_999) == :ok
    assert block |> Bitcoin.Block.Validation.coinbase_value(height: 210_000) == {:error, :reward_too_high}
    assert block |> Bitcoin.Block.Validation.coinbase_value(height: 250_000) == {:error, :reward_too_high}
  end

  test "merkle root" do
    assert @block1 |> Bitcoin.Block.Validation.merkle_root == :ok
    assert @block1 |> Map.put(:merkle_root, @block1.merkle_root |> Binary.reverse) |> Bitcoin.Block.Validation.merkle_root == {:error, :merkle_root_invalid}
  end

end
