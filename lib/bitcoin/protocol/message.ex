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
            message: Bitcoin.Protocol.Message.Payload

  @type t :: %{
    header: Bitcoin.Protocol.Message.Header.t,
    message: Bitcoin.Protocol.Message.Payload.t
  }

  defmodule Payload do

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

    @type t :: %Payload{
      raw_data: binary,
      message: binary
    }

    # 'addr' Messages
    def parse(<<97, 100, 100, 114, 0, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Addr.parse(data)
      }
    end

    # 'alert' Messages
    def parse(<<97, 108, 101, 114, 116, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Alert.parse(data)
      }
    end

    # 'block' Messages
    def parse(<<98, 108, 111, 99, 107, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Block.parse(data)
      }
    end

    # 'getaddr' Messages
    def parse(<<103, 101, 116, 97, 100, 100, 114, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.GetAddr.parse(data)
      }
    end

    # 'getblocks' Messages
    def parse(<<103, 101, 116, 98, 108, 111, 99, 107, 115, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.GetBlocks.parse(data)
      }
    end

    # 'getdata' Messages
    def parse(<<103, 101, 116, 100, 97, 116, 97, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.GetData.parse(data)
      }
    end

    # 'getheaders' Messages
    def parse(<<103, 101, 116, 104, 101, 97, 100, 101, 114, 115, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.GetHeaders.parse(data)
      }
    end

    # 'headers' Messages
    def parse(<<104, 101, 97, 100, 101, 114, 115, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Headers.parse(data)
      }
    end

    # 'inv' Messages
    def parse(<<105, 110, 118, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Inv.parse(data)
      }
    end

    # 'notfound' Messages
    def parse(<<110, 111, 116, 102, 111, 117, 110, 100, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.NotFound.parse(data)
      }
    end

    # 'ping' Messages
    def parse(<<112, 105, 110, 103, 0, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Ping.parse(data)
      }
    end

    # 'pong' Messages
    def parse(<<112, 111, 110, 103, 0, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Pong.parse(data)
      }
    end

    # 'reject' Messages
    def parse(<<114, 101, 106, 101, 99, 116, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Reject.parse(data)
      }
    end

    # 'tx' Messages
    def parse(<<116, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Tx.parse(data)
      }
    end

    # 'verack' Messages
    def parse(<<118, 101, 114, 97, 99, 107, 0, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Verack.parse(data)
      }
    end

    # 'version' Messages
    def parse(<<118, 101, 114, 115, 105, 111, 110, 0, 0, 0, 0, 0>>, data) do
      %Payload{
        raw_data: data,
        message: Bitcoin.Protocol.Messages.Version.parse(data)
      }
    end

    # all other unrecognised messages
    def parse(_, _, data) do

      %Payload{
        raw_data: data,
        message: <<>>
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