defmodule Bitcoin.Protocol.Messages.TxTest do
  use ExUnit.Case

  alias Bitcoin.Protocol.Messages.Tx

  test "parses the tx message" do
    payload = Base.decode16!("01000000" <> # version, 1
                             "01" <> # number of inputs, 1
                             "6DBDDB085B1D8AF75184F0BC01FAD58D" <> # previous output (outpoint),
                             "1266E9B63B50881990E4B40D6AEE3629" <> # -
                             "00000000" <>                         # -
                             "8B" <>                               # length of signature script, 139 bytes
                             "483045022100F3581E1972AE8AC7C736" <> # signature script, sigScript
                             "7A7A253BC1135223ADB9A468BB3A5923" <> # -
                             "3F45BC578380022059AF01CA17D00E41" <> # -
                             "837A1D58E97AA31BAE584EDEC28D35BD" <> # -
                             "96923690913BAE9A0141049C02BFC97E" <> # -
                             "F236CE6D8FE5D94013C721E915982ACD" <> # -
                             "2B12B65D9B7D59E20A842005F8FC4E02" <> # -
                             "532E873D37B96F09D6D4511ADA8F1404" <> # -
                             "2F46614A4C70C0F14BEFF5" <>           # -
                             "FFFFFFFF" <>                         # sequence
                             "02" <>                               # number of outputs, 2
                             "404B4C0000000000" <>                 # 0.05 BTC (5000000)
                             "19" <>                               # pk_script is 25 bytes long
                             "76A9141AA0CD1CBEA6E7458A7ABAD512" <> # pk_script
                             "A9D9EA1AFB225E88AC" <>               # -
                             "80FAE9C700000000" <>                 # 33.54 BTC (3354000000)
                             "19" <>                               # pk_script is 25 bytes long
                             "76A9140EAB5BEA436A0484CFAB12485E" <> # pk_script
                             "FDA0B78B4ECC5288AC" <>               #-
                             "00000000")                           # lock_time

    assert %Bitcoin.Protocol.Messages.Tx{
             inputs: [
               %Bitcoin.Protocol.Types.TransactionInput{
                 previous_output: %Bitcoin.Protocol.Types.Outpoint{
                   hash: <<109, 189, 219, 8, 91, 29, 138, 247, 81, 132, 240, 188, 1, 250, 213, 141, 18, 102, 233, 182, 59, 80, 136, 25, 144, 228, 180, 13, 106, 238, 54, 41>>,
                   index: 0
                   },
                 sequence: 4294967295,
                 signature_script: Base.decode16!("483045022100F3581E1972AE8AC7C736" <> # signature script, sigScript
                                                  "7A7A253BC1135223ADB9A468BB3A5923" <> # -
                                                  "3F45BC578380022059AF01CA17D00E41" <> # -
                                                  "837A1D58E97AA31BAE584EDEC28D35BD" <> # -
                                                  "96923690913BAE9A0141049C02BFC97E" <> # -
                                                  "F236CE6D8FE5D94013C721E915982ACD" <> # -
                                                  "2B12B65D9B7D59E20A842005F8FC4E02" <> # -
                                                  "532E873D37B96F09D6D4511ADA8F1404" <> # -
                                                  "2F46614A4C70C0F14BEFF5")             # -
                 }
               ],
             lock_time: 0,
             outputs: [
               %Bitcoin.Protocol.Types.TransactionOutput{
                 pk_script: Base.decode16!("76A9141AA0CD1CBEA6E7458A7ABAD512A9D9EA1AFB225E88AC"),
                 value: 5000000
                 },
               %Bitcoin.Protocol.Types.TransactionOutput{
                 pk_script: Base.decode16!("76A9140EAB5BEA436A0484CFAB12485EFDA0B78B4ECC5288AC"),
                 value: 3354000000
                 }
               ],
             version: 1
           } ==
             Tx.parse(payload)
  end

end