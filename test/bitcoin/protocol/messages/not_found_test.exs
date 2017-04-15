defmodule Bitcoin.Protocol.Messages.NotFoundTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.NotFound
  alias Bitcoin.Protocol.Types.InventoryVector

  test "not found message with 2 inventory vectors" do
    payload = Base.decode16!("02" <> # 2 vectors in this message
                             # Inventory Vector 1
                             "03000000" <> # type: 03 - MsgFilteredBlock
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855" <> # hash
                             # Inventory Vector 2
                             "01000000" <> # type: 01 - MsgTx
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855") # hash

    struct = %NotFound{
             inventory_vectors: [
               %InventoryVector{
                 reference_type: :msg_filtered_block,
                 hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")},
               %InventoryVector{
                 reference_type: :msg_tx,
                 hash: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")}
             ]
           }

    assert NotFound.parse(payload) == struct
    assert NotFound.serialize(struct) == payload
  end

end
