defmodule Bitcoin.Protocol.Messages.Ping do

  @moduledoc """
    The ping message is sent primarily to confirm that the TCP/IP connection is still valid. An error in transmission
    is presumed to be a closed connection and the address is removed as a current peer.

    https://en.bitcoin.it/wiki/Protocol_specification#ping
  """

  defstruct nonce: 0 # random nonce

  @type t :: %Bitcoin.Protocol.Messages.Ping{
    nonce: non_neg_integer
  }

  def parse(<<nonce::unsigned-little-integer-size(64)>>) do

    %Bitcoin.Protocol.Messages.Ping{
      nonce: nonce
    }

  end

end