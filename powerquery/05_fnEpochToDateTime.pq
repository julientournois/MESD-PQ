// ============================================================
// Query : fnEpochToDateTime
// Type  : function (Connection only)
// SDP v3 returns dates as [display_value=..., value="1699887600000"]
// where value = epoch in MILLISECONDS (UTC). Converts value to local time.
// ============================================================
(value as any) as nullable datetime =>
let
    N = try Number.From(value) otherwise null,
    R = if N = null or N <= 0 then null
        else DateTimeZone.RemoveZone(
                 DateTimeZone.ToLocal(
                     #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)
                     + #duration(0, 0, 0, N / 1000)
                 )
             )
in
    R
