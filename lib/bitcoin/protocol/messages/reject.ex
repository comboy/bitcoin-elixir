defmodule Bitcoin.Protocol.Messages.Reject do

  @moduledoc """
    The reject message is sent when messages are rejected.

    https://en.bitcoin.it/wiki/Protocol_specification#reject
  """

  alias Bitcoin.Protocol.Types.VarString

  @reject_reasons %{
    0x01 => :MALFORMED,
    0x10 => :INVALID,
    0x11 => :OBSOLETE,
    0x12 => :DUPLICATE,
    0x40 => :NONSTANDARD,
    0x41 => :DUST,
    0x42 => :INSUFFICIENTFEE,
    0x43 => :CHECKPOINT
  }

  defstruct message: "", # type of message rejected
            code: 0, # code relating to the rejected message
            reason: "", # text version of the reason for rejection
            data: <<>> # Optional extra data provided by some errors. Currently, all errors which provide this field
                       # fill it with the TXID or block header hash of the object being rejected, so the field is 32 bytes.

  @type t :: %__MODULE__{
    message: bitstring,
    code: non_neg_integer,
    reason: bitstring,
    data: { nil, bitstring }
  }

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
