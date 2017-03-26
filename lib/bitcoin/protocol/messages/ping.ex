defmodule Bitcoin.Protocol.Messages.Ping do

  @moduledoc """
    The ping message is sent primarily to confirm that the TCP/IP connection is still valid. An error in transmission
    is presumed to be a closed connection and the address is removed as a current peer.

    https://en.bitcoin.it/wiki/Protocol_specification#ping
  """

  defstruct nonce: 0 # random nonce

  @type t :: %__MODULE__{
    nonce: non_neg_integer
  }

  def parse(<<nonce::unsigned-little-integer-size(64)>>) do

    %__MODULE__{
      nonce: nonce
    }

  end

  def serialize(%__MODULE__{} = s) do
    <<
      s.nonce :: unsigned-little-integer-size(64)
    >>
  end

end
