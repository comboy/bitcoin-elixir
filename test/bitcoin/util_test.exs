defmodule Bitcoin.UTilTest do
  use ExUnit.Case

  alias Bitcoin.Util

  test "nonce64" do
    nonce1 = Util.nonce64()
    assert nonce1  >= 0
    assert nonce1  < 0xFF_FF_FF_FF_FF_FF_FF_FF
    nonce2 = Util.nonce64()
    assert nonce1 != nonce2 # randomly failing test ;)
  end

  test "run validations" do
    funs = [
      fn x -> if rem(x,2) == 0, do: :ok, else: {:error, :parity} end,
      fn x -> if x >= 5, do: :ok, else: {:error, :below5} end,
      fn x -> if x >= 10, do: :ok, else: {:error, :below10} end,
    ]
    assert Util.run_validations(funs, 10) == :ok
    assert Util.run_validations(funs, 3) == {:error, :parity}
    assert Util.run_validations(funs, 2) == {:error, :below5}
    assert Util.run_validations(funs, 8) == {:error, :below10}
  end

  test "double sha256" do
    assert Util.double_sha256("foo") |> Base.encode16 == "C7ADE88FC7A21498A6A5E5C385E1F68BED822B72AA63C4A9A48A02C2466EE29E"
  end

  test "friendly hash" do
    assert Util.hash_to_hex(<<239, 190>>) == "beef"
  end
end
