defmodule Bitcoin.Tx do
  alias Bitcoin.Protocol.Messages

  def hash(%Messages.Tx{} = tx) do
    tx
      |> Messages.Tx.serialize
      |> Bitcoin.Util.double_sha256
  end
end
