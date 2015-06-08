defmodule Bitcoin.Protocol.Messages.Pong do

  @moduledoc """
    The pong message is sent in response to a ping message. In modern protocol versions, a pong response is generated
    using a nonce included in the ping.

    https://en.bitcoin.it/wiki/Protocol_specification#pong
  """

  defstruct nonce: 0 # nonce from received ping

  @type t :: %Bitcoin.Protocol.Messages.Pong{
    nonce: non_neg_integer
  }

  def parse(<<nonce::unsigned-little-integer-size(64)>>) do

    %Bitcoin.Protocol.Messages.Pong{
      nonce: nonce
    }

  end

end