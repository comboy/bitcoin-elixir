defmodule Bitcoin.Tx do


  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Types
  alias Bitcoin.Tx.Sighash


  defdelegate sighash(tx, input_number, sub_script, sighash_type), to: Sighash

  # Calculate transaction hash
  def hash(%Messages.Tx{} = tx) do
    tx
      |> Messages.Tx.serialize
      |> Bitcoin.Util.double_sha256
  end

  # TODO
  def validate(%Messages.Tx{} = tx), do: :ok

end
