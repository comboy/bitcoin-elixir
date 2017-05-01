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

  test "to address" do
    %{
      "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6"
      => "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM",
      "04F888B5BB6DC10B4F607A0D41DBB929C0496747084C40DD92A6C95FAE0188FC4AAEB6B512F8A3799911DE57923427A5695E0F847CD055A817876D943C98D95339"
      => "1KY9DEJRiaKwmnZ5GqJWD45RaP8BK2PGdS"

    } |> Enum.each(fn {pk, addr} ->
      assert pk |> Binary.from_hex |> PK.to_address == addr
    end)
  end
end
