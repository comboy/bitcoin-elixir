defmodule Bitcoin.Protocol.Messages.Verack do

  @moduledoc """
    The verack message is sent in reply to version.
    This message consists of only a message header with the command string "verack".

    https://en.bitcoin.it/wiki/Protocol_specification#verack
  """

  def parse(data) do
    %{}
  end

end