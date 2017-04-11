defmodule Bitocin.Tx.SighashTest do
  use ExUnit.Case

  test "bitcoin core sighash test cases" do
    File.read!("test/data/sighash.json") 
    |> Poison.decode! 
    # remove comments
    |> Enum.filter(fn c -> length(c) > 1 end)
    |> Enum.map(fn [tx_hex, sub_script_hex, input_index, sighash_type, result] ->
      tx =
        tx_hex
        |> String.upcase
        |> Base.decode16!
        |> Bitcoin.Protocol.Messages.Tx.parse

      sub_script = sub_script_hex |> String.upcase |> Base.decode16!

      sighash = :crypto.hash(:sha256, Bitcoin.Tx.sighash(tx, input_index, sub_script, sighash_type)) |> Bitcoin.Util.friendly_hash

      assert sighash == result
    end)

  end
end
