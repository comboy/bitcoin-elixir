defmodule Bitcoin.Base58CheckTest do
  use ExUnit.Case
  alias Bitcoin.Base58Check

  @base_cases [
    {"", ""},
    {"000000f832fa3247cc", "11138bZfiH4P"},
    {"deadbeef", "6h8cQN"},
    {"00", "1"},
    {"000111d38e5fc9071ffcd20b4a763cc9ae4f252bb4e48fd66a835e252ada93ff480d6dd43dc62a641155a5",
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"}
  ]

  @cases [
    {"000000f832fa3247cc", "111EwmYw6eMyuPYa7"},
    {"00010203fdfeff", "14HV44ipwoaqfg"},
    {"deadbeef", "eFGDJPketnz"},
    {"0006c59974562e564ce16655a293b0fadc2832125d", "1comboyNsev2ubWRbPZpxxNhghLfonzuN"}
  ]

  @base_invalid ["I", "001", "lalala", "NO"]

  test "encode" do
    @cases
    |> Enum.each(fn {hex, b58} ->
      assert b58 == hex |> Binary.from_hex |> Base58Check.encode
    end)
  end

  test "decode" do
    @cases
    |> Enum.each(fn {hex, b58} ->
      {:ok, bin} = b58 |> Base58Check.decode
      assert hex == bin |> Binary.to_hex
    end)
  end

  test "decode!" do
    @cases
    |> Enum.each(fn {hex, b58} ->
      assert hex == b58 |> Base58Check.decode! |> Binary.to_hex
    end)
  end

  test "checksum test" do
    # deadbeef example with one char wrong
    assert {:error, :invalid_checksum} = "eFGDJpketnz" |> Base58Check.decode
    assert {:error, :invalid_checksum} = "" |> Base58Check.decode
  end

  test "invalid char" do
    # J -> I
    assert {:error, :invalid_character} = "eFGDIPketnz" |> Base58Check.decode
  end

  test "base_encode" do
    @base_cases
    |> Enum.each(fn {hex, b58} ->
      assert b58 == hex |> Binary.from_hex |> Base58Check.base_encode
    end)
  end

  test "base_decode" do
    @base_cases
    |> Enum.each(fn {hex, b58} ->
      {:ok, bin} = b58 |> Base58Check.base_decode
      assert hex == bin |> Binary.to_hex
    end)
  end

  test "base_decode!" do
    @base_cases
    |> Enum.each(fn {hex, b58} ->
      assert hex == b58 |> Base58Check.base_decode! |> Binary.to_hex
    end)
  end

  test "base_decode invalid" do
    @base_invalid
    |> Enum.each(fn str ->
      assert {:error, :invalid_character} == str |> Base58Check.base_decode
    end)
  end

end
