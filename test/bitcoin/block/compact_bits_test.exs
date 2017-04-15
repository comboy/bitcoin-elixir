defmodule Bitcoin.Block.CompactBitsTest do
  use ExUnit.Case

  alias Bitcoin.Block.CompactBits

  @test_cases [
    # {target, nbits}
    {0x1234, 0x02123400},
    {0x123456, 0x03123456},
    {0x12345600, 0x04123456},
    {0x92340000, 0x05009234},
    {0x1234560000000000000000000000000000000000000000000000000000000000, 0x20123456},
    {0x0012, 0x01120000},
    {0x00ffff0000000000000000000000000000000000000000000000000000, 0x1d00ffff},
    {0x00000000000404CB000000000000000000000000000000000000000000000000, 0x1b0404cb}
  ]

  test "encoding" do
    @test_cases |> Enum.each(fn {target, nbits} ->
      assert CompactBits.encode(target) == nbits
    end)
  end
  
  test "decoding" do
    @test_cases |> Enum.each(fn {target, nbits} ->
      assert CompactBits.decode(nbits) == target
    end)
  end
end
