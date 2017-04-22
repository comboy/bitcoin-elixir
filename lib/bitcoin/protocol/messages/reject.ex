defmodule Bitcoin.Protocol.Messages.Reject do

  @moduledoc """
    The reject message is sent when messages are rejected.

    https://en.bitcoin.it/wiki/Protocol_specification#reject
  """

  alias Bitcoin.Protocol.Types.VarString

  @reject_reasons %{
    0x01 => :malformed,
    0x10 => :invalid,
    0x11 => :obsolete,
    0x12 => :duplicate,
    0x40 => :nonstandard,
    0x41 => :dust,
    0x42 => :insufficientfee,
    0x43 => :checkpoint
  }

  defstruct message: "", # type of message rejected
            code: 0, # code relating to the rejected message
            reason: "", # text version of the reason for rejection
            data: <<>> # Optional extra data provided by some errors. Currently, all errors which provide this field
                       # fill it with the TXID or block header hash of the object being rejected, so the field is 32 bytes.

  @type t :: %__MODULE__{
    message: binary,
    code: non_neg_integer,
    reason: binary,
    data: binary
  }

  @spec parse(binary) :: t
  def parse(data) do

    {message, payload} = VarString.parse_stream(data)
    <<code::bytes-size(1),payload::binary>> = payload
    {reason, data} = VarString.parse_stream(payload)

    %__MODULE__{
      message: message,
      code: Map.get(@reject_reasons, code),
      reason: reason,
      data: data
    }

  end

end
