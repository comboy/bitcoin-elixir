defmodule Bitcoin.Protocol.Messages.Alert do

  @moduledoc """
    An alert message.
    https://en.bitcoin.it/wiki/Protocol_documentation#alert
  """


  @known_valid_alert_signing_pubkeys %{
    satoshi_client: Base.decode16!("04FC9702847840AAF195DE8442EBECEDF5B095CDBB9BC716BDA9110971B28A49E0EAD8564FF0DB22209E0374782C093BB899692D524E9D6A6956E7C5ECBCD68284")
  }

  defstruct signature: <<>>, # An ECDSA signature of the message
            payload: <<>>, # Serialized alert payload (raw)
            version: 0, # Alert format version
            relay_until: 0, # The timestamp beyond which nodes should stop relaying this alert
            expiration: 0, # The timestamp beyond which this alert is no longer in effect and should be ignored
            id: 0, # A unique ID number for this alert
            cancel: 0, # All alerts with an ID number less than or equal to this number should be cancelled: deleted and not accepted in the future
            set_cancel: 0, # All alert IDs contained in this set should be cancelled as above
            min_ver: 0, # This alert only applies to versions greater than or equal to this version. Other versions should still relay it.
            max_ver: 0, # This alert only applies to versions less than or equal to this version. Other versions should still relay it.
            set_sub_ver: 0, # If this set contains any elements, then only nodes that have their subVer contained in this set are affected by the alert. Other versions should still relay it.
            priority: 0, # Relative priority compared to other alerts
            comment: 0, # A comment on the alert that is not displayed
            status_bar: 0, # The alert message that is displayed to the user
            reserved: 0 # Reserved for future use

  @type t :: %Bitcoin.Protocol.Messages.Alert{

    signature: bitstring,
    payload: bitstring,

    version: non_neg_integer, # 32-bit unsigned Integer, little endian
    relay_until: non_neg_integer, # 64-bit unsigned Integer, native
    expiration: non_neg_integer, # 64-bit unsigned Integer, native
    id: non_neg_integer, # 32-bit unsigned Integer, little endian
    cancel: non_neg_integer, # 32-bit unsigned Integer, little endian#
    set_cancel: non_neg_integer,
    min_ver: non_neg_integer,
    max_ver: non_neg_integer,
    set_sub_ver: [],

    priority: non_neg_integer,

    comment: String.t,
    status_bar: String.t,
    reserved: String.t

  }

  def parse(data) do

    [alert_payload_bytes, alert_data] = Bitcoin.Protocol.Types.VarInteger.parse_stream(data)

    << alert_payload :: bytes-size(alert_payload_bytes), alert_signature_payload :: binary >> = alert_data

    <<
      version :: unsigned-little-integer-size(32),
      relay_until :: unsigned-native-integer-size(64),
      expiration :: unsigned-native-integer-size(64),
      id :: unsigned-little-integer-size(32),
      cancel :: unsigned-little-integer-size(32),
      remaining_payload :: binary
    >> = alert_payload

    [set_cancel, set_cancel_payload] = Bitcoin.Protocol.Types.IntegerArray.parse_stream(remaining_payload)

    <<
      min_ver :: unsigned-little-integer-size(32),
      max_ver :: unsigned-little-integer-size(32),
      ver_payload :: binary
    >> = set_cancel_payload

    [set_sub_ver, sub_ver_payload] = Bitcoin.Protocol.Types.StringArray.parse_stream(ver_payload)

    <<
      priority :: unsigned-little-integer-size(32),
      priority_payload :: binary
    >> = sub_ver_payload

    [comment, comment_payload] = Bitcoin.Protocol.Types.VarString.parse_stream(priority_payload)

    [status_bar, status_bar_payload] = Bitcoin.Protocol.Types.VarString.parse_stream(comment_payload)

    [reserved, _] = Bitcoin.Protocol.Types.VarString.parse_stream(status_bar_payload)

    [alert_signature_bytes, alert_signature_payload] = Bitcoin.Protocol.Types.VarInteger.parse_stream(alert_signature_payload)

    << alert_signature :: bytes-size(alert_signature_bytes) >> = alert_signature_payload

    %Bitcoin.Protocol.Messages.Alert{
      signature: alert_signature,
      payload: alert_payload,

      version: version,
      relay_until: relay_until,
      expiration: expiration,
      id: id,
      cancel: cancel,
      set_cancel: set_cancel,

      min_ver: min_ver,
      max_ver: max_ver,
      set_sub_ver: set_sub_ver,

      priority: priority,

      comment: comment,
      status_bar: status_bar,
      reserved: reserved
    }
  end

end
