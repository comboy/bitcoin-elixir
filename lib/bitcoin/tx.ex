defmodule Bitcoin.Tx do

  @moduledoc """
  Functions associated with a Bitcoin transaction.

  Transaction structure is defined in `Bitcoin.Protocol.Messages.Tx`
  """

  use Bitcoin.Common

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Tx.Sighash

  require Logger

  @type t_hash :: Bitcoin.t_hash

  @doc """
  Calculate hash for signing. `sighash_type` is provided as a byte value.

  Do note that this is "almost sighash". It's missing the last sha256 hash,
  that's because `:crypto.verify/5` function does one more sha256 before checking signature.
  """
  defdelegate sighash(tx, input_number, sub_script, sighash_type), to: Sighash

  @doc """
  Calculates hash of the transaction.
  """
  @spec hash(Messages.Tx.t) :: t_hash
  def hash(%Messages.Tx{} = tx) do
    tx
      |> Messages.Tx.serialize
      |> Bitcoin.Util.double_sha256
  end

  @doc """
  Sum of all transaction outputs (in satoshis)
  """
  @spec total_output_value(Messages.Tx.t, map) :: integer
  def total_output_value(%Messages.Tx{} = tx, _opts \\ %{}), do: tx.outputs |> Enum.reduce(0, fn (out, acc) -> acc + out.value end)

  @doc """
  Sum of all previous outputs values (in satoshis)
  """
  @spec total_input_value(Messages.Tx.t, map) :: integer
  def total_input_value(%Messages.Tx{} = tx, opts \\ %{}) do
    tx.inputs |> Enum.reduce(0, fn (input, acc) ->
      # we don't handle case when prevout is not found because that is already covered in previous validations
      acc + find_previous_output(input, opts).value
    end)
  end

  @doc """
  Returns the fee that given transaction offers (in satoshis).

  Fee equals sum of all outputs in sum of all inputs.
  """
  @spec fee(Messages.Tx.t, map) :: integer
  # TODO tests
  def fee(%Messages.Tx{} = tx, opts \\ %{}), do: total_input_value(tx, opts) - total_output_value(tx, opts)

  @doc """
  Validate transaction. Currently it checks if

  * previous outputs exists
  * scripts execute with proper result
  * sum of previous output values is greater or equal than the sum of outputs
  * TODO output is not already spent

  `opts` can be used to provide validation context:

  * `:block` - if transaction is inside a block, this is used to check for previous outputs
             that may be present there which are not yet in storage
  * `:previous_outputs` - already fetched previous outputs in the form of a map
             `%{{hash, index} => pk_script}`, currently used for tests, may be used for
             optimizations later
  & `:flags` - validation flags (dependent on bips activation)
  """
  @spec validate(Messages.Tx.t, map) :: :ok | {:error, term}
  def validate(%Messages.Tx{} = tx, %{} = opts \\ %{}) do
    Bitcoin.Util.run_validations([
      # Validate scripts
      fn ->
        tx.inputs |> Enum.with_index |> Enum.reduce(:ok, fn({input, input_number}, result) ->
          case result do
            :ok ->
              validate_input(tx, input, input_number, opts)
            {:error, err} ->
              {:error, err}
          end
        end)
      end,
      # Check if sum of inputs greater or equal than sum of outputs
      fn ->
        if fee(tx, opts) >= 0, do: :ok, else: {:error, :insufficient_funds}
      end,
    ])
  end

  defp validate_input(tx, input, input_number, opts) do
    case find_previous_output(input, opts) do
      {:error, err} ->
        {:error, err}
      prev_out ->
        case Bitcoin.Script.verify_sig_pk(input.signature_script, prev_out.pk_script, opts |> Map.merge(%{tx: tx, input_number: input_number})) do
          true  -> :ok
          false ->
            save_as_test_case(tx, opts) # only saves if enabled in config
            {:error, {:sig_script, tx |> hash |> Bitcoin.Util.hash_to_hex, input_number}}
        end
    end
  end

  defp find_previous_output(input, %{previous_outputs: previous_outputs} = opts) do
    %{hash: hash, index: index} = input.previous_output
    case previous_outputs[{hash, index}] do
      nil -> find_previous_output(input, opts |> Map.delete(:previous_outputs))
      prevout -> prevout
    end
  end

  defp find_previous_output(input, opts) do
    %{hash: hash, index: index} = input.previous_output
    case Bitcoin.Node.Storage.get_txout(hash, index) do
      # Not found in storage, let's check in the curretn block
      nil ->
        case opts[:block] && Enum.find(opts[:block].transactions, fn tx -> Bitcoin.Tx.hash(tx) == hash end) do
          # Not found in the current block either
          nil ->
            {:error, :no_prevout}
          prev_tx ->
            prev_tx.outputs |> Enum.at(index)
        end
      # Found it in storage
      prev_out -> prev_out
    end
  end

  # Serialize validation context to JSON in the form that is present in test/data/tx_valid.json
  # tx_test runs all these test cases collected in "test/data/auto"
  # TODO move to some Bitcoin.Util.Dev or somtething, it's too messy to be here
  defp save_as_test_case(tx, opts) do
    if (Application.get_env(:bitcoin, :util) || [])[:save_as_test_case] do
      Logger.warn "TX validation failed for #{tx |> hash |> Bitcoin.Util.hash_to_hex}, saving context to test/data/auto"
      json = [
        tx.inputs |> Enum.map(fn i -> [i.previous_output.hash |> Bitcoin.Util.hash_to_hex, i.previous_output.index, find_previous_output(i, opts).pk_script |> Binary.to_hex] end),
        tx |> Messages.Tx.serialize |> Binary.to_hex,
        (opts[:flags] || %{}) |> Map.keys |> Enum.map(& &1 |> to_string |> String.upcase) |> Enum.join(",")
      ] |> Poison.encode!
      File.mkdir_p("test/data/auto/#{@network}")
      "test/data/auto/#{@network}/tx_#{tx |> hash |> Bitcoin.Util.hash_to_hex}.json" |> File.write(json)
    else
      :ok
    end
  end

end
