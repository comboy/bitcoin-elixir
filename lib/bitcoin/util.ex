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

end
