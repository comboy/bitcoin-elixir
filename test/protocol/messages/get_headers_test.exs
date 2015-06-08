defmodule Bitcoin.Protocol.Messages.GetHeadersTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.GetHeaders

  test "parses the get headers message with 1 locator hash" do

    payload = Base.decode16!("9C7C0000" <> # 31900 (version 0.3.19)
                             "01" <> # number of locator hashes, one
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855" <>
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B835") # stop hash

    assert %Bitcoin.Protocol.Messages.GetHeaders{
             block_locator_hashes: [
               Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
               ],
             hash_stop: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B835"),
             version: 31900
           } == GetHeaders.parse(payload)

  end

  test "parses the get headers message with 2 locator hashes" do

    payload = Base.decode16!("9C7C0000" <> # 31900 (version 0.3.19)
                             "02" <> # number of locator hashes, one
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B815" <>
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855" <>
                             "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B835") # stop hash

    assert %Bitcoin.Protocol.Messages.GetHeaders{
             block_locator_hashes: [
               Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B815"),
               Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
               ],
             hash_stop: Base.decode16!("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B835"),
             version: 31900
           } == GetHeaders.parse(payload)
  end

end