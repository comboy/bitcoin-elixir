defmodule Bitcoin.TxTest do
  use ExUnit.Case
  use Bitcoin.Common

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol

  import Test.Helper

  # Hash gets more thoroughly tested in other places e.g. Block.merkle_root()
  test "hash" do
    {:ok, payload} = File.read("test/data/blk_100000.dat")
    block = Messages.Block.parse(payload)

    tx = block.transactions |> List.first
    hash = tx |> Bitcoin.Tx.hash |> Bitcoin.Util.hash_to_hex

    assert hash == "8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87"
  end

  test "bitcoin core test cases" do
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

    rets = txs |> Enum.map(fn {result, [prevouts, tx_serialized, flags]} ->
      flags = flags |> flags_string_to_map
      tx = tx_serialized |> Binary.from_hex |> Messages.Tx.parse
      parser = fn pk -> pk |> Bitcoin.Script.parse_string2 |> Bitcoin.Script.to_binary end

      tx_result = Bitcoin.Tx.validate(tx, %{previous_outputs: prepare_prevouts(prevouts, parser), flags: flags}) == :ok
      tx_result == result
    end)

    ok_count = rets |> Enum.count(&(&1))
    IO.puts "\nBitcoin core tx tests: #{ok_count}/#{length(txs)}\n"
    Process.exit(storage_pid, :kill)
  end

  # Mainnet transactions
  File.read!("test/data/tx_mainnet.json") |> Poison.decode!(keys: :atoms)
  |> Enum.each(fn  %{tx: hash, data: data} ->
    @data data
    test "mainnet tx #{hash}" do
      run_test_case(@data)
    end
  end)

  # Automatically saved test cases
  with {:ok, list} <- File.ls("test/data/auto/#{@network}")
  do
    list |> Enum.each(fn filename ->
      @data "test/data/auto/#{@network}/#{filename}" |> File.read! |> Poison.decode!
      test "auto case #{filename}" do
        run_test_case(@data)
      end
    end)
  end

  def run_test_case(tx_data) do
    [prevouts, tx_serialized, flags] = tx_data
    flags = flags |> flags_string_to_map

    tx = tx_serialized |> Binary.from_hex |> Messages.Tx.parse
    parser = fn pk -> pk |> Binary.from_hex end
    assert Bitcoin.Tx.validate(tx, %{previous_outputs: prepare_prevouts(prevouts, parser), flags: flags}) == :ok
  end

  def prepare_prevouts(prevouts, prevout_parser)  do
    prevouts |> Enum.map(fn [prevout_hash, prevout_index, prevout_pk_script] ->
      {{prevout_hash |> Bitcoin.Util.hex_to_hash, prevout_index},
        %Protocol.Types.TxOutput{
          pk_script: prevout_pk_script |> prevout_parser.(),
          value: 0xFF_FF_FF_FF_FF_FF}}
    end) |> Enum.into(%{})
  end
end
