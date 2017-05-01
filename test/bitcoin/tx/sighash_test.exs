defmodule Bitocin.Tx.SighashTest do

  use ExUnit.Case
  use Bitwise

  alias Bitcoin.Tx.Sighash

  test "defined_type?" do
    valid = [0x01, 0x02, 0x03, 0x80, 0x01 ^^^ 0x80, 0x02 ^^^ 0x80, 0x03 ^^^ 0x80]
    invalid = [0x04, 0x04 ^^^ 0x80, 0xFF, 0x00, 0x32]

    valid |> Enum.each(fn byte ->
      assert true == Sighash.valid_type?(byte), "#{byte} should be valid"
    end)
  end


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

    sighash = Bitcoin.Tx.sighash(tx, input_index, sub_script, sighash_type) |> Bitcoin.Util.hash_to_hex
    @sighash sighash
    @result result

    test "sighash core test ##{idx}" do
      assert @sighash == @result
    end
  end)

end
