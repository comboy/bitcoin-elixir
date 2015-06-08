defmodule BitcoinTest.Protocol.Types.IntegerArrayTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.IntegerArray

  test "returns an empty array and the remaining payload for a size zero array" do

    payload = <<0,       # element count
                1, 1, 0  # remaining stream
              >>

    assert [ [], <<1, 1, 0>> ] ==
      IntegerArray.parse_stream(payload)

  end

  test "returns an array of size one with properly int(8) and the remaining payload" do

    payload = <<1,       # element count
                  1,     # first element, 1 (int(8)) Bitcoin.Protocol.Types.Integer
                0, 1, 0  # remaining stream
              >>
    assert [
             [
               1
             ],
             <<0, 1, 0>>
           ] ==
             IntegerArray.parse_stream(payload)

  end

  test "returns an array of size two with properly int(8), int(16) and the remaining payload" do

      payload = <<2,       # element count
                    1,                 # first element, 1 (int(8)) Bitcoin.Protocol.Types.Integer
                    253, 43, 221,      # second element, 56619 (int(16)) Bitcoin.Protocol.Types.Integer
                  1, 1, 0  # remaining stream
                >>
      assert [
               [
                 1,
                 56619
               ],
               <<1, 1, 0>>
             ] ==
               IntegerArray.parse_stream(payload)

    end

  test "returns an array of size three with properly int(8), int(16), int(32) and the remaining payload" do

      payload = <<3,       # element count
                    1,                 # first element, 1 (int(8)) Bitcoin.Protocol.Types.Integer
                    253, 43, 221,      # second element, 56619 (int(16)) Bitcoin.Protocol.Types.Integer
                    254, 43, 221, 215, 77, # third element, 1305992491 (int(16)) Bitcoin.Protocol.Types.Integer
                  1, 1, 1  # remaining stream
                >>
      assert [
               [
                 1,
                 56619,
                 1305992491
               ],
               <<1, 1, 1>>
             ] ==
               IntegerArray.parse_stream(payload)

    end

end