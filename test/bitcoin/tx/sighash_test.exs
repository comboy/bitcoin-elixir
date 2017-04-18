defmodule Bitocin.Tx.SighashTest do
  use ExUnit.Case

  File.read!("test/data/sighash.json") 
  |> Poison.decode! 
  # remove comments
  |> Enum.filter(fn c -> length(c) > 1 end)
  |> Enum.with_index
  |> Enum.map(fn {[tx_hex, sub_script_hex, input_index, sighash_type, result], idx} ->
    tx =
      tx_hex
      |> String.upcase
      |> Base.decode16!
      |> Bitcoin.Protocol.Messages.Tx.parse

    sub_script = sub_script_hex |> String.upcase |> Base.decode16!

    sighash = :crypto.hash(:sha256, Bitcoin.Tx.sighash(tx, input_index, sub_script, sighash_type)) |> Bitcoin.Util.hash_to_hex
    @sighash sighash
    @result result

    test "sighash core test ##{idx}" do
      assert @sighash == @result
    end
  end)

end
