// ============================================================
// Query : Dx_WorklogSample   (DIAGNOSTIC - Connection only)
// Checks the real shape of a worklog (notably the date field name:
// created_time vs start_time depending on configuration).
// Replace 12345 with a real ticket number that has worklogs.
// ============================================================
let
    TicketId = "12345",
    Raw   = fnSdpFetch("requests/" & TicketId & "/worklogs", null, "worklogs"),
    First = List.First(Raw, null),
    Out   = if First = null then "No worklog on this ticket"
            else Text.Combine(Record.FieldNames(First), " | ")
in
    Out
