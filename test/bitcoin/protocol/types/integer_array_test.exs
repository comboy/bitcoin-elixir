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

  test "returns an array of size one" do

    payload = <<1,       # element count
                  1 :: unsigned-little-integer-size(32),     # first element
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

  test "returns an array of size two" do

      payload = <<2,       # element count
                    1 :: unsigned-little-integer-size(32),                 # first element
                    56619 :: unsigned-little-integer-size(32),             # second element
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

  test "returns an array of size three" do

      payload = <<3,                     # element count
                  1 :: unsigned-little-integer-size(32), 56619 :: unsigned-little-integer-size(32), 1305992491 :: unsigned-little-integer-size(32),  # elements
                  1, 1, 1                # remaining stream
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
