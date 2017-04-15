defmodule BitcoinTest.Protocol.Types.StringTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.String
  alias Bitcoin.Protocol.Types.Integer

  test "returns empty string when string size is zero and also returns remaining payload" do

    payload = <<0, 0, 1, 0>>

    assert ["", <<0, 1, 0>>] ==
             String.parse_stream(payload)

  end

  test "returns correct string when string size is one and also returns remaining payload" do

    payload = <<1, 97 ,0, 1, 0>>

    assert ["a", <<0, 1, 0>>] ==
             String.parse_stream(payload)

  end

  test "returns correct string when string size is two and also returns remaining payload" do

    payload = <<2, 97, 98, 1, 1, 0>>

    assert ["ab", <<1, 1, 0>>] ==
             String.parse_stream(payload)

  end

  test "parse 0 length string" do
    assert ["", <<>>] = String.parse_stream(Integer.serialize(0))
  end

  test "serialization" do
    assert String.serialize("ab") ==  << 2, 97, 98 >>
  end

  test "serialization > 255" do
    str = "a" |> Elixir.String.duplicate(255) 
    assert String.serialize(str) == << 253, 255, 0 >> <> str
  end

end
