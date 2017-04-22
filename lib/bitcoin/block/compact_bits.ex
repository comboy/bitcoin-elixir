defmodule Bitcoin.Block.CompactBits do
  @moduledoc """
    256-bit target threshold in the block header is encoded in a 32-bit space (compact bits a.k.a nBits).
    This module provides functions to encode and decode compact bits.

    Simple and understandable explanation:
    http://bitcoin.stackexchange.com/questions/2924/how-to-calculate-new-bits-value
  """

  @doc """
  Encode target integer to compact bits integer
  """
  @spec encode(integer) :: integer
  def encode(int), do: int |> Integer.digits(256) |> encode_digits

  @doc """
  Docede compact bits integer to target integer
  """
  @spec decode(integer) :: integer
  def decode(int) do
    [num | digits] = int |> Integer.digits(256)
    digits
      |> :binary.list_to_bin
      |> Binary.trim_trailing
      |> Binary.pad_trailing(num)
      |> :binary.bin_to_list
      |> Integer.undigits(256)
  end


  defp encode_digits([first | _] = digits) when first > 0x7f, do: [0 | digits] |> encode_digits
  defp encode_digits(digits) do
    [length(digits) | digits]
      |> Enum.take(4)
      |> :binary.list_to_bin
      |> Binary.pad_trailing(4)
      |> :binary.bin_to_list
      |> Integer.undigits(256)
  end

end
