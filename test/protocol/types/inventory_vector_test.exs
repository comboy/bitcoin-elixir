defmodule BitcoinTest.Protocol.Types.InventoryVectorTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.InventoryVector

  test "reference type error" do

    payload = Base.decode16!("00000000" <> # type: 00 - Error
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

    assert %Bitcoin.Protocol.Types.InventoryVector{
             hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"),
             reference_type: :error
           } ==
             InventoryVector.parse(payload)

  end

  test "reference type msg_tx" do

      payload = Base.decode16!("01000000" <> # type: 01 - MsgTX
                               "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

      assert %Bitcoin.Protocol.Types.InventoryVector{
               hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"),
               reference_type: :msg_tx
             } ==
               InventoryVector.parse(payload)

  end

  test "reference type msg_block" do

      payload = Base.decode16!("02000000" <> # type: 01 - MsgBlock
                               "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

      assert %Bitcoin.Protocol.Types.InventoryVector{
               hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"),
               reference_type: :msg_block
             } ==
               InventoryVector.parse(payload)

  end

  test "reference type msg_filtered_block" do

      payload = Base.decode16!("03000000" <> # type: 01 - MsgFilteredBlock
                               "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

      assert %Bitcoin.Protocol.Types.InventoryVector{
               hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"),
               reference_type: :msg_filtered_block
             } ==
               InventoryVector.parse(payload)

  end

end