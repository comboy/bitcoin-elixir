defmodule Bitcoin.Secp256k1Test do
  use ExUnit.Case

  # Verify in this module is tested by script test cases which include special cases for signature verification

  test "verify from fb0a1d8d34fa5537e461ac384bac761125e1bfa7fec286fa72511240fa66864d" do
    # This case fails for erlang's :crypto.verify, but it is verified by libsecp256k1
    # It's in the bicoin main chain (tx hash in the test title).
    # The reason seems to be R and S null padding.

    sighash = Binary.from_hex "dcbb3b55099218b9dac85c2045456a6b2be3e8a610f12366b0c66658235e0433"
    sig = Binary.from_hex "3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5"
    pk = Binary.from_hex "04d0fe07ff74c9ef5b00fed1104fad43ecf72dbab9e60733e4f56eacf24b20cf3b8cd945bcabcc73ba0158bf9ce769d43e94bd58c5c7e331a188922b3fe9ca1f5a"

    assert Bitcoin.Secp256k1.verify(sighash, sig,pk) == true
  end

end
