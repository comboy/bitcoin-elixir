defmodule Bitcoin.DERSigTest do
  use ExUnit.Case

  alias Bitcoin.DERSig

  test "simple parse" do
    sig = Binary.from_hex("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")
    struct = %DERSig{
      length: 72,
      r: Binary.from_hex("00002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e7366"),
      s: Binary.from_hex("0000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5"),
      r_type: 0x02,
      s_type: 0x02,
      type: 0x30
    }
    assert DERSig.parse(sig) == struct
  end

  test "normalize" do # also tests sorialization
    sig = Binary.from_hex("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")
    sig_norm = Binary.from_hex("304402202b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e73660220334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5")

    assert DERSig.normalize(sig) == sig_norm
    assert DERSig.low_s?(sig_norm) == true
  end

  test "low_s?" do
    sig = Binary.from_hex("304502203e4516da7253cf068effec6b95c41221c0cf3a8e6ccb8cbf1725b562e9afde2c022100ab1e3da73d67e32045a20e0b999e049978ea8d6ee5480d485fcf2ce0d03b2ef0")
    assert DERSig.low_s?(sig) == false
  end

  # DERSig.strict?/1 tests included in bitcoin core sript tests

end
