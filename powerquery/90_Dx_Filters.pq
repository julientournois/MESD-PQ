// ============================================================
// Query : Dx_Filters   (DIAGNOSTIC - Connection only, or load it if useful)
// Lists the request views / filters available to the technician key:
// their Name (the value to put in a filter_by) and their ID.
//
// Endpoint : /api/v3/list_view_filters/show_all
// This endpoint does not take a list_info but a dedicated input_data,
// so it bypasses fnSdpFetch. The module is "request"; change it to list
// views of another module (e.g. "asset", "problem", "change").
// ============================================================
let
    Module   = "request",

    Payload  = Text.FromBinary(Json.FromValue([ list_view_filters = [ module = Module ] ])),
    Response = Web.Contents(Config[ApiBaseURL], [
        RelativePath = "list_view_filters/show_all",
        Query        = [ input_data = Payload ],
        Headers      = [
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
                      try Text.FromBinary(Response) otherwise "(unreadable body)")
             else Json.Document(Response),

    // The rows are expected under "list_view_filters"; fail loudly otherwise.
    Raw = if Record.HasFields(Body, "list_view_filters") then Body[list_view_filters]
          else error Error.Record(
                   "SDP.DataKeyNotFound",
                   "Key ""list_view_filters"" is missing from the response",
                   "Keys present: " & Text.Combine(Record.FieldNames(Body), ", ")),

    T = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),
    A = Table.AddColumn(T, "Name", each Record.FieldOrDefault([r], "name", null), type text),
    B = Table.AddColumn(A, "ID",   each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    Final = Table.Sort(Table.SelectColumns(B, {"Name", "ID"}), {{"Name", Order.Ascending}})
in
    Final
