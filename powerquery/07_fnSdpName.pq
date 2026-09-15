// ============================================================
// Query : fnSdpName
// Type  : function (Connection only)
// SDP linked objects (status, technician, category...) are records
// [id=..., name=...] or null when unset. Avoids writing
// "try [x][name] otherwise null" forty times in the reports.
// Usage: fnSdpName([r], "technician")
// ============================================================
(rec as any, field as text) as nullable text =>
let
    Sub = if rec is record then Record.FieldOrDefault(rec, field, null) else null,
    Val = if Sub = null then null
          else if Sub is record then
               Record.FieldOrDefault(Sub, "name",
                   Record.FieldOrDefault(Sub, "display_value", null))
          else if Sub is text then Sub
          else try Text.From(Sub) otherwise null
in
    Val
