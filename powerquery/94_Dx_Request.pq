// ============================================================
// Query : Dx_Request   (DIAGNOSTIC - Connection only)
// Compares what the API returns for ONE ticket through the two access
// paths, side by side:
//   Detail : GET /requests/{id}          (full record)
//   List   : GET /requests?filter_by=... (the same ticket as seen by the
//            list endpoint used by the reports)
// Use it to find out whether a field (typically a UDF) is only present in
// the detail and missing from the list.
//
// Set TicketId. ViewName is optional: null = list call without filter
// (the ticket may then be absent from the first pages; the list side of
// the comparison will say "not found in list").
// ============================================================
let
    TicketId = "12345",
    ViewName = null,     // e.g. "My_RFC_View" (API name from Dx_Filters)

    // ---------- Detail ---------------------------------------------------
    Detail = List.First(fnSdpFetch("requests/" & TicketId, null, "request"), null),

    // ---------- List -----------------------------------------------------
    ListInfo   = if ViewName = null then [] else [ filter_by = [ name = ViewName ] ],
    ListRows   = fnSdpFetch("requests", ListInfo, "requests"),
    FromList   = List.First(List.Select(ListRows, each Text.From(Record.FieldOrDefault(_, "id", "")) = TicketId), null),

    // ---------- Flat field paths (same helper as Dx_Raw) -----------------
    Paths = (R as any, prefix as text) as list =>
        if not (R is record) then {}
        else List.Combine(List.Transform(Record.FieldNames(R), each
                 let full = if prefix = "" then _ else prefix & "." & _,
                     v    = Record.Field(R, _)
                 in  if v is record then {full} & @Paths(v, full) else {full})),

    DetailPaths = if Detail = null then {} else Paths(Detail, ""),
    ListPaths   = if FromList = null then {} else Paths(FromList, ""),

    Summary = [
        TicketId            = TicketId,
        DetailFound         = Detail <> null,
        ListFound           = FromList <> null,
        ListRowCount        = List.Count(ListRows),
        // Fields present in the detail but absent from the list: this is
        // what the reports cannot see without a per-ticket detail call.
        OnlyInDetail        = List.Difference(DetailPaths, ListPaths),
        OnlyInList          = List.Difference(ListPaths, DetailPaths),
        DetailUdfFields     = if Detail <> null and Record.HasFields(Detail, "udf_fields")
                              then Record.FieldOrDefault(Detail, "udf_fields", null) else "no udf_fields in detail",
        ListUdfFields       = if FromList = null then "not found in list"
                              else if Record.HasFields(FromList, "udf_fields")
                              then Record.FieldOrDefault(FromList, "udf_fields", null) else "no udf_fields in list",
        DetailRecord        = Detail,
        ListRecord          = FromList
    ]
in
    Summary
