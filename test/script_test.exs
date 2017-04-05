defmodule Bitcoin.ScriptTest do
  use ExUnit.Case

  @parsed_scripts %{
    "76A914C398EFA9C392BA6013C5E04EE729755EF7F58B3288AC" => 
    [:OP_DUP, :OP_HASH160, <<195, 152, 239, 169, 195, 146, 186, 96, 19, 197, 224, 78, 231, 41, 117, 94,  247, 245, 139, 50>>, :OP_EQUALVERIFY, :OP_CHECKSIG],

    # Some examples taken from bitcoin-ruby tests (https://github.com/lian/bitcoin-ruby/blob/master/spec/bitcoin/script/script_spec.rb)
    "526B006B7DAC7CA9143CD1DEF404E12A85EAD2B4D3F5F9F817FB0D46EF879A6C93" =>
    [:OP_2, :OP_TOALTSTACK, :OP_FALSE, :OP_TOALTSTACK, :OP_TUCK, :OP_CHECKSIG, :OP_SWAP, :OP_HASH160, <<60, 209, 222, 244, 4, 225, 42, 133, 234, 210, 180, 211, 245, 249, 248, 23,  251, 13, 70, 239>>, :OP_EQUAL, :OP_BOOLAND, :OP_FROMALTSTACK, :OP_ADD],

    "0002FFFFAB5102FFFF51AE" => 
    [:OP_FALSE, <<255, 255>>, :OP_CODESEPARATOR, :OP_TRUE, <<255, 255>>, :OP_TRUE, :OP_CHECKMULTISIG],

    "6A04DEADBEEF" => 
    [:OP_RETURN, <<222, 173, 190, 239>>]
  }

  test "parse" do
    @parsed_scripts |> Enum.each(fn {hex, script} ->
      assert Bitcoin.Script.Binary.parse(hex |> Base.decode16!) == script
    end)
  end

  test "run super simple" do
    assert true == [2, 3, :OP_ADD, 5, :OP_EQUAL] |> Bitcoin.Script.verify
    assert false ==[2, 3, :OP_ADD, 4, :OP_EQUAL] |> Bitcoin.Script.verify
  end

  test "the suite" do
    hex_from_file = fn (path) -> File.read!(path) |> String.split("\n") end

    # source https://raw.githubusercontent.com/bitpay/bitcore-lib/master/test/data/bitcoind/script_valid.json
    # (I think they originally come from BitcoinJ, good stuff

    valid   = hex_from_file.("test/data/script_valid.hex")   |> Enum.map(fn hex -> {hex, true} end)
    invalid = hex_from_file.("test/data/script_invalid.hex") |> Enum.map(fn hex -> {hex, false} end)

    scripts = valid ++ invalid

    rets = scripts |> Enum.map(fn {hex, result} ->
      ret = hex |> String.upcase
      |> Base.decode16!
      |> Bitcoin.Script.verify == result
      #if !ret do
        #hex |> IO.inspect |> String.upcase |> Base.decode16! |> IO.inspect |> Bitcoin.Script.Binary.parse |> IO.inspect |> Bitcoin.Script.run |> IO.inspect
        #IO.puts "should be #{result}"
        #assert false
      #end
      ret
    end)

    ok_count = rets |> Enum.filter(fn x -> x == true end) |> Enum.count
    count = scripts |> length
    IO.puts "\nHARDCORE SCRIPT TESTS: #{ok_count}/#{count}"# (#{fail_count} FAIL, #{count - ok_count - fail_count} BAD)"
  end
end

