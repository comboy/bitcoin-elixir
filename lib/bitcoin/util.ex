defmodule Bitcoin.Util do

  # Random 64 bit nonce
  def nonce64, do: (:rand.uniform(0xFF_FF_FF_FF_FF_FF_FF_FF) |> round) - 1

  # Timestamp represented as a float
  def militime do
    {megas, s, milis} = :os.timestamp
    1.0e6*megas + s + milis * 1.0e-6
  end

  # Helper to run series of functions as a validation.
  # It returns :ok if all functions return :ok
  # Otherwise, first encountered error is returned.
  def run_validations(funs, struct) do
    funs |> Enum.reduce(:ok, fn(fun, status) ->
      case status do
          :ok -> fun.(struct)
        error -> error
      end
    end)
  end

  def double_sha256(data), do: :crypto.hash(:sha256, :crypto.hash(:sha256, data))

  # reverse bytes order in a binary
  def binary_reverse(binary), do: binary |> :binary.bin_to_list |> Enum.reverse |> :binary.list_to_bin

  # this needs a better name
  # it transforms binary hash as used in the Bitcoin protocol to the hex representation that you see everywhere
  def friendly_hash(hash), do: hash |> binary_reverse |> Base.encode16 |> String.downcase

end
