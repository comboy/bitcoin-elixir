defmodule Bitcoin.Protocol.Message.Payload do

  require Logger

  @command_names Bitcoin.Protocol.Message.command_names()

  defimpl String.Chars, for: Payload do
    @spec to_string(Payload.t) :: String.t
    def to_string(data) do
      """
        parsed data:
          #{data.payload |> String.Chars.to_string()}
        raw data:
          #{"0x" <> Base.encode16(data.raw_data)}
      """ |> String.strip()
    end
  end

  defstruct raw_data: <<>>,
            message: <<>>

  @type t :: %__MODULE__{
    raw_data: binary,
    message: binary
  }

  def parse(command, data) when command in @command_names do
    %__MODULE__{
      raw_data: data,
      message: data |> Bitcoin.Protocol.Message.message_type(command).parse
    }
  end

  def parse(command, data) do
    Logger.info "Unknown command: #{command |> inspect} data[#{byte_size(data)}]"
  end

end
