defmodule BitcoinTest.Protocol.Types.StringArrayTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Types.StringArray

  test "returns an empty array and the remaining payload for a size zero array" do

    payload = <<0,       # element count
                1, 1, 0  # remaining stream
              >>

    assert { [], <<1, 1, 0>> } ==
      StringArray.parse_stream(payload)

  end

  test "returns an array of size one with string char 1 'a' and the remaining payload" do

    payload = <<1,       # element count
                  1, 97, # first element, << Integer byte count, string 'a' >>
                0, 1, 0  # remaining stream
              >>
    assert {
             [
               "a"
             ],
             <<0, 1, 0>>
           } ==
             StringArray.parse_stream(payload)

  end

  test "returns an array of size two with string char 1 'a' and string char 0 and the remaining payload" do

      payload = <<2,       # element count
                    1, 97,  # first element, << Integer byte count, string 'a' >>
                    0,      # second element, empty string
                  1, 1, 0  # remaining stream
                >>
      assert {
               [
                 "a",
                 ""
               ],
               <<1, 1, 0>>
             } ==
               StringArray.parse_stream(payload)

    end

  test "returns an array of size three with properly int(8), int(16), int(32) and the remaining payload" do

      payload = <<3,       # element count
                    1, 97,           # first element, << Integer byte count, string 'a' >>
                    0,               # second element, empty string
                    2, 97, 98, # third element, << Integer byte count, string 'ab' >>
                  1, 1, 1  # remaining stream
                >>
      assert {
               [
                 "a",
                 "",
                 "ab"
               ],
               <<1, 1, 1>>
             } ==
               StringArray.parse_stream(payload)

    end

end
