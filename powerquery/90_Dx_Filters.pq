// ============================================================
// Query : Dx_Filters   (DIAGNOSTIC - Connection only, or load it if useful)
// Lists the request views / filters available to the technician key:
// their Name (the value to put in a filter_by) and their ID.
//
// Endpoint : /api/v3/list_view_filters/show_all
// It does not take a list_info, so it bypasses fnSdpFetch.
// On this build the endpoint rejects an input_data ("extra key found in
// json"): the call is made WITHOUT it. A second attempt WITH
// {"list_view_filters":{"module":"request"}} is kept as a fallback for
// other builds.
// ============================================================
let
    Headers = [
        #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
        #"TECHNICIAN_KEY" = ApiKey
    ],

    Call = (query as nullable record) as record =>
        let
            Opts = [
                RelativePath         = "list_view_filters/show_all",
                Headers              = Headers,
                ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
            ],
            Opts2    = if query = null then Opts else Record.AddField(Opts, "Query", query),
            Response = Web.Contents(Config[ApiBaseURL], Opts2),
            Status   = Value.Metadata(Response)[Response.Status]?,
            Body     = Json.Document(Response),
            Ok       = (Status = null or Status < 400) and Record.HasFields(Body, "list_view_filters")
        in
            [ Ok = Ok, Body = Body, Status = Status,
              Text = try Text.FromBinary(Response) otherwise "" ],

    // 1) without input_data
    A1 = Call(null),
    // 2) fallback: with module
    A2 = if A1[Ok] then A1
         else Call([ input_data = Text.FromBinary(Json.FromValue([ list_view_filters = [ module = "request" ] ])) ]),

    Raw = if A2[Ok] then A2[Body][list_view_filters]
          else error Error.Record(
                   "SDP.ListViewFilters",
                   "Could not read /list_view_filters/show_all",
                   "Without input_data -> HTTP " & Text.From(A1[Status]) & ": " & A1[Text]
                 & "  |  With module -> HTTP " & Text.From(A2[Status]) & ": " & A2[Text]),

    T = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),
    A = Table.AddColumn(T, "Name", each Record.FieldOrDefault([r], "name", null), type text),
    B = Table.AddColumn(A, "ID",   each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    Final = Table.Sort(Table.SelectColumns(B, {"Name", "ID"}), {{"Name", Order.Ascending}})
in
    Final
