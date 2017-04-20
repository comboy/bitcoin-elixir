defmodule Bitcoin.Protocol.Messages.Mempool do

  @moduledoc """
    The mempool message sends a request to a node asking for information about transactions
    it has verified but which have not yet confirmed. The response to receiving this message
    is an inv message containing the transaction hashes for all the transactions in the
    node's mempool.mempool

    https://en.bitcoin.it/wiki/Protocol_specification#mempool
  """

  defstruct []

  def parse(_data), do: %__MODULE__{}
  def serialize(_), do: ""

end

