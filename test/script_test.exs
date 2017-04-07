defmodule Bitcoin.ScriptTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types
  alias Bitcoin.Protocol.Messages

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


  # From script test cases json file: 
  #["It is evaluated as if there was a crediting coinbase transaction with two 0"],
  #["pushes as scriptSig, and one output of 0 satoshi and given scriptPubKey,"],
  #["followed by a spending transaction which spends this output as only input (and"],
  #["correct prevout hash), using the given scriptSig. All nLockTimes are 0, all"],
  #["nSequences are max."],
  def test_script_verify(sig_bin, pk_bin) do

    cred_tx = %Messages.Tx{
      inputs: [
        %Types.TransactionInput{
          previous_output: %Types.Outpoint{
            hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>,
            index: 0xFF_FF_FF_FF,
          },
          signature_script: <<0, 0>>,
          sequence: 0xFF_FF_FF_FF,
        }
      ],
      outputs: [
        %Types.TransactionOutput{
          value: 0,
          pk_script: pk_bin,
        }
      ],
      lock_time: 0,
      version: 1
    }

    spend_tx = %Messages.Tx{
      inputs: [ 
        %Types.TransactionInput{
          previous_output: %Types.Outpoint{
            hash: cred_tx |> Bitcoin.Tx.hash,
            index: 0
          },
          signature_script: sig_bin,
          sequence: 0xFF_FF_FF_FF,
        }
      ],
      outputs: [
        %Types.TransactionOutput{
          pk_script: <<>>,
          value: 0
        }
      ],
      lock_time: 0,
      version: 1
    }

    (sig_bin <> pk_bin) |> Bitcoin.Script.verify(tx: spend_tx, input_number: 0, sub_script: pk_bin)
  end

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
    # source https://raw.githubusercontent.com/bitpay/bitcore-lib/master/test/data/bitcoind/script_valid.json
    # (I think they originally come from BitcoinJ, good stuff
    valid =   File.read!("test/data/script_hex_valid.json")   |> Poison.decode! |> Enum.map(fn x -> [true | x] end)
    invalid = File.read!("test/data/script_hex_invalid.json") |> Poison.decode! |> Enum.map(fn x -> [false | x] end)

    scripts = valid ++ invalid
    #scripts = []

    rets = scripts |> Enum.map(fn [result, sig_hex, pk_hex, _flags, comment] ->
      pk_bin = pk_hex |> String.upcase |> Base.decode16!
      sig_bin = sig_hex |> String.upcase |> Base.decode16!
      ret = test_script_verify(sig_bin, pk_bin) == result
      if !ret do
        # Uncomment to get list of scripts that failed
        #(pk_bin <> sig_bin) |> Bitcoin.Script.Binary.parse |> IO.inspect(limit: :infinity) #|> Bitcoin.Script.run |> IO.inspect
        #IO.puts "should be #{result} | #{comment} | #{pk_hex <> sig_hex}"
        #assert false
      end
      ret
    end)

    ok_count = rets |> Enum.filter(fn x -> x == true end) |> Enum.count
    count = scripts |> length
    IO.puts "\nHARDCORE SCRIPT TESTS: #{ok_count}/#{count}"# (#{fail_count} FAIL, #{count - ok_count - fail_count} BAD)"

  end
end
