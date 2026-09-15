// ============================================================
// Query : ApiKey
// Type  : text query (Connection only)
// ============================================================
//
// THREE OPTIONS, worst to best.
//
// --- Option A: hard-coded ---------------------------------------------
// The technician key travels with the workbook. Anyone receiving the .xlsx
// gets your SDP rights. Avoid as soon as the workbook circulates.
//
//   "XXXXXXXXXXXXXXXX"
//
// --- Option B: query parameter ---------------------------------------
// Data > Get Data > Other Sources > Blank Query, then Manage Parameters.
// Cleaner to maintain, but the value is still stored in clear text in the
// workbook. Same risk as A.
//
// --- Option C: local file outside the workbook (recommended) ---------
// The key lives in a file you do not share. The workbook only holds the
// path. Each authorized workstation drops its own file.
// Create C:\SDP\technician.key (single line, ideally no trailing newline)
// and use the code below.
//
// Note: a path relative to the workbook is NOT possible. Power Query has no
// notion of "current folder" and no function returning the host workbook
// path. The only workaround is a named cell computed by Excel with
// CELL("filename"), read back via Excel.CurrentWorkbook() - fragile
// (unsaved workbook, OneDrive/SharePoint URLs). Not implemented here.

let
    KeyPath = "C:\SDP\technician.key",
    Raw     = try Text.FromBinary(File.Contents(KeyPath), TextEncoding.Utf8) otherwise null,
    Key     = if Raw = null
              then error Error.Record(
                        "SDP.MissingKey",
                        "Technician key not found.",
                        "Create the file " & KeyPath & " containing only the SDP technician key."
                   )
              else Text.Trim(Text.Replace(Text.Replace(Raw, "#(cr)", ""), "#(lf)", ""))
in
    Key
