defmodule Bitcoin.Tx do

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Tx.Sighash


  defdelegate sighash(tx, input_number, sub_script, sighash_type), to: Sighash

  # Calculate transaction hash
  def hash(%Messages.Tx{} = tx) do
    tx
      |> Messages.Tx.serialize
      |> Bitcoin.Util.double_sha256
  end

  def total_output_value(%Messages.Tx{} = tx, _opts \\ %{}), do: tx.outputs |> Enum.reduce(0, fn (out, acc) -> acc + out.value end)

  # TODO tests
  def total_input_value(%Messages.Tx{} = tx, opts \\ %{}) do
    tx.inputs |> Enum.reduce(0, fn (input, acc) ->
      # we don't handle case when prevout is not found because that is already covered in previous validations
      acc + find_previous_output(input, opts).value
    end)
  end

  # TODO tests
  def fee(%Messages.Tx{} = tx, opts \\ %{}), do: total_input_value(tx, opts) - total_output_value(tx, opts)

  def validate(%Messages.Tx{} = tx, %{} = opts \\ %{}) do
    # OPTIMIZE fetch previous outputs only once
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
        case Bitcoin.Script.verify_sig_pk(input.signature_script, prev_out.pk_script, tx: tx, sub_script: prev_out.pk_script, input_number: input_number) do
          true  -> :ok
          false -> {:error, {:sig_script, input_number}}
        end
    end
  end

  defp find_previous_output(input, %{previous_outputs: previous_outputs}) do
    %{hash: hash, index: index} = input.previous_output
    case previous_outputs[{hash, index}] do
      nil -> {:error, :no_prevout}
      prevout -> prevout
    end
  end

  defp find_previous_output(input, opts) do
    %{hash: hash, index: index} = input.previous_output
    # TODO maybe storage should offer some get_output function so that it can optimize fetching from UTXO
    case Bitcoin.Node.Storage.get_tx(hash) do
      # Not found in storage, let's check in the curretn block
      nil ->
        # TODO the struct that storage returns should already have hash field (because storage already has it)
        case opts[:block] && Enum.find(opts[:block].transactions, fn tx -> Bitcoin.Tx.hash(tx) == hash end) do
          # Not found in the current block either
          nil ->
            {:error, :no_prevout}
          prev_tx ->
            prev_tx.outputs |> Enum.at(index)
        end
      # Found it in storage
      prev_tx ->
        prev_tx.outputs |> Enum.at(index)
    end
  end

end
