defmodule Bitcoin.DERSigTest do
  use ExUnit.Case

  alias Bitcoin.DERSig

  test "simple parse" do
    sig = Binary.from_hex("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")
    struct = %DERSig{
      length: 72,
      r: Binary.from_hex("00002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e7366"),
      s: Binary.from_hex("0000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5"),
      type: 0x30
    }
    assert DERSig.parse(sig) == struct
  end

  test "normalize" do # also tests sorialization
    sig = Binary.from_hex("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")
    sig_norm = Binary.from_hex("304402202b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e73660220334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")

    assert DERSig.normalize(sig) == sig_norm
  end

  # DERSig.strict?/1 tests included in bitcoin core sript tests

end
