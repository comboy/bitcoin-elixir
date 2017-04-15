defmodule Bitcoin.TxTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol

  # Hash gets more thoroughly tested in other places e.g. Block.merkle_root()
  test "hash" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)

    tx = block.transactions |> List.first
    hash = tx |> Bitcoin.Tx.hash |> Bitcoin.Util.friendly_hash

    assert hash == "8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87"
  end

  test "bitcore core test cases" do
    # TODO have it always return nil or some opt not to check it in validation for tests, to avoid starting it every time
    {:ok, storage_pid} = Bitcoin.Node.Storage.start_link

    # Tx tests cases coming from bitcoin core
    # https://github.com/bitcoin/bitcoin/blob/master/src/test/data/tx_valid.json
    vaild = File.read!("test/data/tx_valid.json") |> Poison.decode! |> Enum.map(fn x -> {:true, x} end)
    invalid = File.read!("test/data/tx_invalid.json") |> Poison.decode! |> Enum.map(fn x -> {false, x} end)

    txs = (vaild ++ invalid)
    |> Enum.filter(fn {_result, list} -> length(list) > 1 end) # remove comments
    # no segwit implementation yet
    |> Enum.filter(fn {_, [_,_,flags]} -> !String.contains?(flags, "WITNESS") end)

    rets = txs |> Enum.map(fn {result, [prevouts, tx_serialized, _flags]} ->

      tx = tx_serialized |> String.upcase |> Base.decode16! |> Messages.Tx.parse

      previous_outputs = prevouts |> Enum.map(fn [prevout_hash, prevout_index, prevout_pk_script] ->
        {{prevout_hash |> String.upcase |> Base.decode16! |> Bitcoin.Util.binary_reverse, prevout_index},
          %Protocol.Types.TransactionOutput{
            pk_script: prevout_pk_script |> Bitcoin.Script.parse_string2 |> Bitcoin.Script.to_binary,
            value: 0xFF_FF_FF_FF_FF_FF}}
      end) |> Enum.into(%{})

      tx_result = Bitcoin.Tx.validate(tx, %{previous_outputs: previous_outputs}) == :ok
      tx_result == result
    end)

    ok_count = rets |> Enum.count(&(&1)) 
    IO.puts "\nBitcoin core tx tests: #{ok_count}/#{length(txs)}\n"
    Process.exit(storage_pid, :kill)
  end
end
