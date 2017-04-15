defmodule Bitcoin.Script.Number do

  ## Script integers (a.k.a. CScriptNum)
  #
  # Byte vectors are interpreted as little-endian variable-length integers with the most significant
  # bit determining the sign of the integer. Thus 0x81 represents -1. 0x80 is another representation
  # of zero (so called negative 0). Positive 0 is represented by a null-length vector.
  #
  # Maximum size of integer accepted by arithmetic operations is 4 bytes, however result of these
  # operations may overflow.
  #
  # TODO integers must be encoded with the minimum possible number of bytes (otherwise script should be invalid)

  use Bitwise

  # num(binary) - Interpret binary as script integer
  def num(<<>>), do: 0
  # We reverse it and then encode as big endian because it's only possible to match beginning of binary in Elixir
  def num(x) when is_binary(x), do: x |> Bitcoin.Util.binary_reverse |> rev_num
  def num(x) when is_number(x), do: x

  def rev_num(<< x, bin :: binary >>) when (x &&& 0x80) != 0, do: -1 * rev_num(<< x ^^^ 0x80>> <> bin)
  def rev_num(<< x :: unsigned-integer-size(32) >>), do: x
  def rev_num(<< x :: unsigned-integer-size(24) >>), do: x
  def rev_num(<< x :: unsigned-integer-size(16) >>), do: x
  def rev_num(<< x :: unsigned-integer-size(8) >>), do: x

  # Serialize integer into the script representation
  def bin(0), do: <<>>
  def bin(x) when is_binary(x), do: x

  # If number is negative xor the last byte with 0x80
  def bin(x) when is_number(x) and x < 0 do
    r = x |> abs |> bin
    s = r |> byte_size
    :binary.part(r, 0, s-1) <> << :binary.at(r, s-1) ^^^ 0x80 >>
  end

  def bin(x) when is_number(x) do
    size = (:math.log2(x)+1) |> Float.floor |> round
    size = size - rem(size,8) + 8
    << x :: unsigned-little-integer-size(size) >>
  end

  # This cleaner implementation doesn't replicate core behavior properly
  # E.g. 4294967294 gives <<254, 255, 255, 255>> but should <<254, 255, 255, 255, 0>>
  # def bin(x) when is_number(x) do
  #  << first, bin :: binary >> = x |> abs |> :binary.encode_unsigned
  #  first = if x < 0, do: first ^^^ 0x80, else: first
  #  (<< first >> <> bin) |> Bitcoin.Util.binary_reverse
  # end
end
