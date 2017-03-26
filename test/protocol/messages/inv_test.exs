defmodule Bitcoin.Protocol.Messages.InvTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Inv
  alias Bitcoin.Protocol.Types.InventoryVector

  test "inv message with 1 inventory vector" do
    payload = Base.decode16!("01" <> # 1 vector in this message
                             # Inventory Vector 1
                             "03000000" <> # type: 03 - MsgFilteredBlock
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

    struct = %Inv{
             inventory_vectors: [
               %InventoryVector{
                 reference_type: :msg_filtered_block,
                 hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")}
             ]
           }
    assert Inv.parse(payload) == struct
    assert Inv.serialize(struct) == payload
  end

  test "inv message with 2 inventory vectors" do
    payload = Base.decode16!("02" <> # 2 vectors in this message
                             # Inventory Vector 1
                             "03000000" <> # type: 03 - MsgFilteredBlock
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855" <> # hash
                             # Inventory Vector 2
                             "01000000" <> # type: 01 - MsgTx
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

    struct = %Inv{
             inventory_vectors: [
               %InventoryVector{
                 reference_type: :msg_filtered_block,
                 hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")},
               %InventoryVector{
                 reference_type: :msg_tx,
                 hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")}
             ]
           }

    assert Inv.parse(payload) == struct
    assert Inv.serialize(struct) == payload
  end

end
