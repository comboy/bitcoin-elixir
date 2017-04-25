defmodule Bitcoin.Block.CompactBits do
  @moduledoc """
    256-bit target threshold in the block header is encoded in a 32-bit space (compact bits a.k.a nBits).
    This module provides functions to encode and decode compact bits.

    Simple and understandable explanation:
    http://bitcoin.stackexchange.com/questions/2924/how-to-calculate-new-bits-value
  """

  import Binary

  @doc """
  Encode target integer to compact bits integer
  """
  @spec encode(integer) :: integer
  def encode(int), do: int |> Binary.from_integer |> encode_digits

  @doc """
  Docede compact bits integer to target integer
  """
  @spec decode(integer) :: integer
  def decode(int) do
    {<<num>>, digits} = int |> Binary.from_integer |> split_at(1)
    digits
    |> trim_trailing
    |> pad_trailing(num)
    |> to_integer
  end


  defp encode_digits(<< first, _ :: binary >> = digits) when first > 0x7f, do: digits |> prepend(0) |> encode_digits
  defp encode_digits(digits) do
    digits
    |> prepend(digits |> byte_size)
    |> take(4)
    |> pad_trailing(4)
    |> to_integer
  end

end
