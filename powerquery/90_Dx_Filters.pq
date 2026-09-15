// ============================================================
// Query : Dx_Filters   (DIAGNOSTIC - Connection only, or load it if useful)
// Lists the request views / filters available to the technician key:
// their Name (the value to put in a filter_by) and their ID.
//
// Endpoint : /api/v3/list_view_filters/show_all
// input_data shape verified on this build:
//   { "module": "request",
//     "list_info": { "row_count": "100",
//                    "search_criteria": { "field": "module",
//                                         "value": "request",
//                                         "condition": "contains" } } }
// "module" sits at the ROOT, next to list_info - not inside a wrapper.
// The call bypasses fnSdpFetch, which only knows the list_info envelope.
// ============================================================
let
    Module   = "request",
    RowCount = 500,   // views are few; raise if the list looks truncated

    Payload = Text.FromBinary(Json.FromValue([
        module    = Module,
        list_info = [
            row_count       = Text.From(RowCount),
            search_criteria = [ field = "module", value = Module, condition = "contains" ]
        ]
    ])),

    Response = Web.Contents(Config[ApiBaseURL], [
        RelativePath         = "list_view_filters/show_all",
        Query                = [ input_data = Payload ],
        Headers              = [
            #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
            #"TECHNICIAN_KEY" = ApiKey
        ],
        ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
    ]),
    Status = Value.Metadata(Response)[Response.Status]?,
    Body   = if Status <> null and Status >= 400
             then error Error.Record(
                      "SDP.HttpError",
                      "HTTP " & Text.From(Status) & " on /list_view_filters/show_all",
                      "sent " & Payload & " -> " & (try Text.FromBinary(Response) otherwise "(unreadable body)"))
             else Json.Document(Response),

    // Rows live under the first non-envelope key (expected: list_view_filters).
    Key = List.First(List.Select(Record.FieldNames(Body),
              each not List.Contains({"response_status", "list_info"}, _)), null),
    Raw = if Key = null
          then error Error.Record("SDP.DataKeyNotFound", "No data key in the response",
                   "Keys present: " & Text.Combine(Record.FieldNames(Body), ", "))
          else Record.Field(Body, Key),

    T = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),
    A = Table.AddColumn(T, "Name", each Record.FieldOrDefault([r], "name", null), type text),
    B = Table.AddColumn(A, "ID",   each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    Final = Table.Sort(Table.SelectColumns(B, {"Name", "ID"}), {{"Name", Order.Ascending}})
in
    Final
