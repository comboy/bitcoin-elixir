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
  # TODO MINIMALDATA flag integers must be encoded with the minimum possible 
  # number of bytes (otherwise script should be invalid)

  use Bitwise

  # num(binary) - Interpret binary as script integer
  # Do not that while bin(num) can convert any size integer into binary,
  # num will fail with numbers > int32 (this is according to the script spec)
  def num(<<>>), do: 0
  # We reverse it and then encode as big endian because it's only possible to match beginning of binary in Elixir
  def num(x) when is_binary(x), do: x |> Binary.reverse |> rev_num
  def num(x) when is_number(x), do: x

  def rev_num(<< x, bin :: binary >>) when (x &&& 0x80) != 0, do: -1 * rev_num(<< x ^^^ 0x80>> <> bin)
  def rev_num(<< x :: unsigned-integer-size(32) >>), do: x
  def rev_num(<< x :: unsigned-integer-size(24) >>), do: x
  # Helper to cast boolean result operations to resulting stack element
  def rev_num(<< x :: unsigned-integer-size(16) >>), do: x
  def rev_num(<< x :: unsigned-integer-size(8) >>), do: x

  # Serialize integer into the script representation
  def bin(0), do: <<>>
  def bin(x) when is_number(x) do
   # Unsigned int representation (big endian)
   << first, bin :: binary >> = x |> abs |> Binary.from_integer

   append = if (first &&& 0x80) == 0x80 do
     # if sign bit is already 1 then we need to append additional byte with sign information
     << x < 0 && 0x80 || 0x00, first >>
   else
     # otherwise just put sign to the appropriate bit
     << x < 0 && (first ^^^ 0x80) || first >>
   end
   # reverse making it little endian
   (append <> bin) |> Binary.reverse
  end
end
