defmodule Bitcoin.Protocol.Types.Integer do

  @moduledoc """
    var_int type from the Bitcoin protocol ( https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer )
  """

  def parse(binary) do
    [data, <<>>] = parse_stream(binary)
    data
  end

  def parse_stream(<<0xFD, data :: unsigned-little-integer-size(16), remaining :: binary>>), do: [data, remaining]
  def parse_stream(<<0xFE, data :: unsigned-little-integer-size(32), remaining :: binary>>), do: [data, remaining]
  def parse_stream(<<0xFF, data :: unsigned-native-integer-size(64), remaining :: binary>>), do: [data, remaining]
  def parse_stream(<<data :: unsigned-integer-size(8), remaining :: binary>>),               do: [data, remaining]

  def serialize(int) when is_integer(int) and int  < 0xFD,        do: << int :: unsigned-little-integer-size(8) >>
  def serialize(int) when is_integer(int) and int <= 0xFFFF,      do: << 0xFD, int :: unsigned-little-integer-size(16) >>
  def serialize(int) when is_integer(int) and int <= 0xFFFF_FFFF, do: << 0xFE, int :: unsigned-little-integer-size(32) >>
  def serialize(int) when is_integer(int) and int  > 0xFFFF_FFFF, do: << 0xFF, int :: unsigned-little-integer-size(64) >>

end
