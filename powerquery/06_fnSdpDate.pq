// ============================================================
// Query   : fnSdpDate
// Type    : function (Connection only)
// Depends : fnEpochToDateTime
// Takes the full SDP date record and returns a local datetime.
// Tolerates: record with value, record with display_value only, null, text.
// ============================================================
(field as any) as nullable datetime =>
let
    R = if field = null then null
        else if field is record then
            let
                v = Record.FieldOrDefault(field, "value", null),
                d = if v <> null then fnEpochToDateTime(v) else null
            in
                if d <> null then d
                else try DateTime.From(Record.FieldOrDefault(field, "display_value", null)) otherwise null
        else if field is number then fnEpochToDateTime(field)
        else try DateTime.From(field) otherwise null
in
    R
