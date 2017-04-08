defmodule Bitcoin.TxTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages

  # Hash gets more thoroughly tested in other places e.g. Block.merkle_root()
  test "hash" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)

    tx = block.transactions |> List.first
    hash = tx |> Bitcoin.Tx.hash |> Bitcoin.Util.friendly_hash

    assert hash == "8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87"
  end

  test "bitcore core test cases" do
    # Tx tests cases coming from bitcoin core
    # https://github.com/bitcoin/bitcoin/blob/master/src/test/data/tx_valid.json
    vaild = File.read!("test/data/tx_valid.json") |> Poison.decode! |> Enum.map(fn x -> {:true, x} end)
    invalid = File.read!("test/data/tx_invalid.json") |> Poison.decode! |> Enum.map(fn x -> {false, x} end)

    txs = (vaild ++ invalid)
    |> Enum.filter(fn {_result, list} -> length(list) > 1 end) # remove comments
    # no segwit implementation yet
    |> Enum.filter(fn {_, [_,_,flags]} -> !String.contains?(flags, "WITNESS") end)

    rets = txs
    |> Enum.map(fn {result, [prevouts, tx_serialized, flags]} ->
      try do
        tx = tx_serialized |> String.upcase |> Base.decode16! |> Messages.Tx.parse
        result = tx.inputs |> Enum.reduce({0, prevouts, true}, fn (input, {input_number, prevouts, final_result}) ->
          [prevout | prevouts] = prevouts
          [_prevout_hash, _prevout_index, prevout_pk_script] = prevout
          pk_script = prevout_pk_script |> Bitcoin.Script.Serialization.parse_string2
          sig_script = input.signature_script |> Bitcoin.Script.Serialization.parse
          ret = Bitcoin.Script.verify_sig_pk(sig_script, pk_script, tx: tx, input_number: input_number, sub_script: pk_script |> Bitcoin.Script.Serialization.to_binary)
          #if ret != result do
            #IO.puts "-------------------------------------------------"
            #tx_serialized |> IO.inspect
            #tx |> IO.inspect
          #end
          final_result = case final_result do
            false -> false
            true  -> ret == result
          end
          {input_number + 1, prevouts, final_result}
        end)
        {_, _, ret} = result
        ret
      catch _,_ ->
        false
      end
    end)
    ok_count = rets |> Enum.count(&(&1)) 
    IO.puts "\nBitcoin core tx tests: #{ok_count}/#{length(txs)}\n"
  end
end
