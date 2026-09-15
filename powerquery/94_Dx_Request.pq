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

    // ---------- Detail, RAW: no input_data at all --------------------------
    // fnSdpFetch always sends input_data={"list_info":...}. A plain
    // /requests/{id} does not take one; this call checks whether sending
    // it changes what SDP returns (e.g. drops udf_fields).
    RawResp   = Web.Contents(Config[ApiBaseURL], [
                    RelativePath = "requests/" & TicketId,
                    Headers      = [
                        #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
                        #"TECHNICIAN_KEY" = ApiKey
                    ],
                    ManualStatusHandling = {400, 401, 403, 404, 500}
                ]),
    RawStatus = Value.Metadata(RawResp)[Response.Status]?,
    RawBody   = try Json.Document(RawResp) otherwise null,
    RawDetail = if RawBody = null then null
                else Record.FieldOrDefault(RawBody, "request", null),

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
    RawPaths    = if RawDetail = null then {} else Paths(RawDetail, ""),
    ListPaths   = if FromList = null then {} else Paths(FromList, ""),

    Summary = [
        TicketId            = TicketId,
        // --- raw detail (no input_data) vs detail through fnSdpFetch ---
        RawHttpStatus       = RawStatus,
        RawResponseKeys     = if RawBody = null then "unreadable" else Text.Combine(Record.FieldNames(RawBody), ", "),
        RawHasUdfFields     = RawDetail <> null and Record.HasFields(RawDetail, "udf_fields"),
        RawUdfFields        = if RawDetail = null then "no request record" else Record.FieldOrDefault(RawDetail, "udf_fields", "no udf_fields"),
        OnlyInRawDetail     = List.Difference(RawPaths, DetailPaths),
        // --- detail through fnSdpFetch ---
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
        RawDetailRecord     = RawDetail,
        DetailRecord        = Detail,
        ListRecord          = FromList
    ]
in
    Summary
