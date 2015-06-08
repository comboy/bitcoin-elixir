defmodule Bitcoin.Protocol.Message do

  @moduledoc """
    https://en.bitcoin.it/wiki/Protocol_documentation#Message_structure
  """

  defimpl String.Chars, for: Bitcoin.Protocol.Message do

    @spec to_string(Message) :: String.t
    def to_string(item) do
      """
      Bitcoin Protocol Message
      ===

      Message Header
      ---
      #{item.header}

      Payload
      ---
      #{item.payload.to_string()}

      """
    end

  end

  defstruct header: Bitcoin.Protocol.Message.Header,
            payload: Bitcoin.Protocol.Message.Payload

  @type t :: %{
    header: Bitcoin.Protocol.Message.Header.t,
    payload: Bitcoin.Protocol.Message.Payload.t
  }

  defmodule Payload do

    defimpl String.Chars, for: Payload do
      @spec to_string(Payload.t) :: String.t
      def to_string(data) do
        """
          parsed data:
            #{data.parsed_data |> String.Chars.to_string()}
          raw data:
            #{"0x" <> Base.encode16(data.raw_data)}
        """ |> String.strip()
      end
    end

    defstruct raw_data: <<>>,
              parsed_data: <<>>

    @type t :: %Payload{
      raw_data: binary,
      parsed_data: binary
    }

    # Alert Messages
    def parse(<<97, 108, 101, 114, 116, 0, 0, 0, 0, 0, 0, 0>>, data) do
      Bitcoin.Protocol.Messages.Alert.parse(data)
    end

    def parse(_, _, data) do

      %Payload{
        raw_data: data,
        parsed_data: <<>>
      }

    end

  end

  defmodule Header do

    @known_network_identifiers %{
      main: <<0xF9, 0xBE, 0xB4, 0xD9>>,
      testnet: <<0xFA, 0xBF, 0xB5, 0xDA>>,
      testnet3: <<0x0B, 0x11, 0x09, 0x07>>,
      namecoin: <<0xF9, 0xBE, 0xB4, 0xFE>>
    }

    defstruct network_identifier: 0,
              command: <<>>,
              payload_size_bytes: 0,
              checksum: 0

    @type t :: %Header{
      network_identifier: non_neg_integer,
      command: String.t,
      payload_size_bytes: non_neg_integer,
      checksum: non_neg_integer # sha256(sha256(payload)) first four bytes
    }

    def parse(<<network_identifier :: unsigned-little-integer-size(32),
                      command :: bytes-size(12),
                      payload_size_bytes :: unsigned-little-integer-size(32),
                      checksum :: unsigned-little-integer-size(32)
                    >>) do

      %Header{
        network_identifier: network_identifier,
        command: command,
        payload_size_bytes: payload_size_bytes,
        checksum: checksum
      }
    end

  end

  @doc """
    Reads and deserialises bitcoin message in serialised format and returns the parsed result
  """
  @spec parse(bitstring) :: Bitcoin.Protocol.Message.t
  def parse(message) do

    <<raw_header :: bytes-size(24), # fixed size header
      payload :: binary
    >> = message

    header =  Header.parse(raw_header)

    %{
      header: header,
      payload: Payload.parse(header.command, payload)
    }

  end

end