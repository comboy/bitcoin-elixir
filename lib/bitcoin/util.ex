defmodule Bitcoin.Util do

  @doc """
  Random 64 bit nonce
  """
  @spec nonce64 :: number
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

  # same as above, but with /0 functions
  def run_validations(funs) do
    funs |> Enum.reduce(:ok, fn(fun, status) ->
      case status do
          :ok -> fun.()
        error -> error
      end
    end)
  end

  @doc """
  Hash data with sha256, then hash the result with sha256
  """
  @spec double_sha256(binary) :: Bitcoin.t_hash
  def double_sha256(data), do: :crypto.hash(:sha256, :crypto.hash(:sha256, data))

  @doc """
  Transforms binary hash as used in the Bitcoin protocol to the hex representation that you see everywhere.

  So basically reverse + to_hex
  """
  @spec hash_to_hex(Bitcoin.t_hash) :: Bitcoin.t_hex_hash
  def hash_to_hex(hash), do: hash |> Binary.reverse |> Binary.to_hex

  @doc """
  The opposite of `hash_to_hex/1`
  """
  @spec hex_to_hash(Bitcoin.to_hex_hash) :: Bitcoin.t_hash
  def hex_to_hash(hex), do: hex |> Binary.from_hex |> Binary.reverse

  @doc """
  Calculate the root hash of the merkle tree built from given list of hashes"
  """
  @spec merkle_tree_hash(list(Bitcoin.t_hash)) :: Bitcoin.t_hash
  def merkle_tree_hash(list) 

  def merkle_tree_hash([hash]), do: hash
  def merkle_tree_hash(list) when rem(length(list), 2) == 1, do: (list ++ [List.last(list)]) |> merkle_tree_hash
  def merkle_tree_hash(list) do
    list
      |> Enum.chunk(2)
      |> Enum.map(fn [a, b] -> Bitcoin.Util.double_sha256(a <> b) end)
      |> merkle_tree_hash
  end
end
