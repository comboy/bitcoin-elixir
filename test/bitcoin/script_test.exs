defmodule Bitcoin.ScriptTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types
  alias Bitcoin.Protocol.Messages

  alias Bitcoin.Script

  import Test.Helper


  # From script test cases json file:
  #["It is evaluated as if there was a crediting coinbase transaction with two 0"],
  #["pushes as scriptSig, and one output of 0 satoshi and given scriptPubKey,"],
  #["followed by a spending transaction which spends this output as only input (and"],
  #["correct prevout hash), using the given scriptSig. All nLockTimes are 0, all"],
  #["nSequences are max."],
  def test_script_verify(sig_bin, pk_bin, opts \\ %{}) do

    cred_tx = %Messages.Tx{
      inputs: [
        %Types.TxInput{
          previous_output: %Types.Outpoint{
            hash: <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>,
            index: 0xFF_FF_FF_FF,
          },
          signature_script: <<0, 0>>,
          sequence: 0xFF_FF_FF_FF,
        }
      ],
      outputs: [
        %Types.TxOutput{
          value: 0,
          pk_script: pk_bin,
        }
      ],
      lock_time: 0,
      version: 1
    }

    spend_tx = %Messages.Tx{
      inputs: [
        %Types.TxInput{
          previous_output: %Types.Outpoint{
            hash: cred_tx |> Bitcoin.Tx.hash,
            index: 0
          },
          signature_script: sig_bin,
          sequence: 0xFF_FF_FF_FF,
        }
      ],
      outputs: [
        %Types.TxOutput{
          pk_script: <<>>,
          value: 0
        }
      ],
      lock_time: 0,
      version: 1
    }

    Script.verify_sig_pk(sig_bin, pk_bin, %{tx: spend_tx, input_number: 0, sub_script: pk_bin} |> Map.merge(opts))
  end


  test "run super simple" do
    assert true == [2, 3, :OP_ADD, 5, :OP_EQUAL] |> Script.verify
    assert false ==[2, 3, :OP_ADD, 4, :OP_EQUAL] |> Script.verify
  end

  test "disabled op prpsent" do
    assert false == [2, :OP_2MUL] |> Script.verify
  end

  test "disabled op in unexecuted if branch" do
    assert false == ([:OP_TRUE, :OP_IF, :OP_TRUE, :OP_ELSE, :OP_2, :OP_2MUL, :OP_ENDIF] |> Script.to_binary |> Script.verify)
  end

  test "bitcoin core scripts.json" do
    cases = File.read!("test/data/script_tests.json") |> Poison.decode! |> Enum.filter(fn x -> length(x) != 1 end)
    rets =
      cases
      |> Enum.map(fn [sig_script, pk_script, flags, result | _comment ] ->
        flags = flags |> flags_string_to_map
        bool_result = result == "OK"
        run_result = try do # try is a lazy way to handle {:errors from parsing
          sig_bin = sig_script |> Script.Serialization.string2_to_binary
          pk_bin = pk_script |> Script.Serialization.string2_to_binary
          test_script_verify(sig_bin, pk_bin, %{flags: flags})
        catch _,_ ->
          false
        end
        run_result == bool_result
      end)
    ok_count = rets |> Enum.filter(fn x -> x == true end) |> Enum.count
    count = cases |> length
    IO.puts "\nBitcoin core script tests: #{ok_count}/#{count}"
  end

  test "bitcore-lib test suite" do
    # source https://raw.githubusercontent.com/bitpay/bitcore-lib/master/test/data/bitcoind/script_valid.json
    # (I think they originally come from BitcoinJ, good stuff
    valid =   File.read!("test/data/script_hex_valid.json")   |> Poison.decode! |> Enum.map(fn x -> [true | x] end)
    invalid = File.read!("test/data/script_hex_invalid.json") |> Poison.decode! |> Enum.map(fn x -> [false | x] end)

    scripts = (valid ++ invalid)
      |> Enum.filter(fn [_,_,_,flags,_] -> !String.contains?(flags, "DISCOURAGE_UPGRADABLE_NOPS") end)
      #|> Enum.filter(fn [_,_,_,flags,_] -> !String.contains?(flags, "MINIMALDATA") end)

    rets = scripts  |> Enum.map(fn [result, sig_hex, pk_hex, flags, _comment] ->
      flags = flags |> flags_string_to_map

      pk_bin = pk_hex |> String.upcase |> Base.decode16!
      sig_bin = sig_hex |> String.upcase |> Base.decode16!
      ret = test_script_verify(sig_bin, pk_bin, %{flags: flags}) == result
      if !ret do
        # Uncomment to get list of scripts that failed
        #IO.puts "should be #{result} #[#{flags}] | #{comment} :"
        #sig_bin |> IO.inspect |> Script.parse |> IO.inspect(limit: :infinity) #|> Script.run |> IO.inspect
        #pk_bin |> IO.inspect |> Script.parse |> IO.inspect(limit: :infinity) #|> Script.run |> IO.inspect
        #assert false
      end
      ret
    end)

    ok_count = rets |> Enum.filter(fn x -> x == true end) |> Enum.count
    count = scripts |> length
    IO.puts "\nBitcore-lib script tests: #{ok_count}/#{count}"# (#{fail_count} FAIL, #{count - ok_count - fail_count} BAD)"

  end

end
