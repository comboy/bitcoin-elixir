defmodule Bitcoin.Key.PublicTest do
  use ExUnit.Case

  alias Bitcoin.Key.Public, as: PK

  test "strict? for noncanonical" do
    # first byte 0x06
    nc = "0679be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8" |> Binary.from_hex
    assert false == PK.strict?("")
    assert false == PK.strict?("moo")
    assert false == PK.strict?(nc)
  end

  test "strict? uncompressed key" do
    key = "048282263212c609d9ea2a6e3e172de238d8c39cabd5ac1ca10646e23fd5f5150811f8a8098557dfe45e8256e830b60ace62d613ac2f7b17bed31b6eaff6e26caf" |> Binary.from_hex
    assert true == PK.strict?(key)
  end

  test "strict? compressed key" do
    key1 = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798" |> Binary.from_hex
    key2 = "038282263212c609d9ea2a6e3e172de238d8c39cabd5ac1ca10646e23fd5f51508" |> Binary.from_hex
    assert true == PK.strict?(key1)
    assert true == PK.strict?(key2)
  end
end
