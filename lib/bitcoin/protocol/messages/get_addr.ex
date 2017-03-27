defmodule Bitcoin.Protocol.Messages.GetAddr do

  @moduledoc """
    The getaddr message sends a request to a node asking for information about known active peers to help with finding
    potential nodes in the network. The response to receiving this message is to transmit one or more addr messages with
    one or more peers from a database of known active peers. The typical presumption is that a node is likely to be
    active if it has been sending a message within the last three hours.

    No additional data is transmitted with this message.

    https://en.bitcoin.it/wiki/Protocol_specification#getaddr
  """

  def parse(_data) do
    %{}
  end

  def serialize(_), do: <<>>

end
