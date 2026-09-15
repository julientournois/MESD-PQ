// ============================================================
// Query : fnSdpFetch
// Type  : function (Connection only)
// Role  : THE only place in the workbook that speaks HTTP.
//         Pagination, auth, errors, data-key detection.
//
// Usage:
//   fnSdpFetch("cmdb", null, null)
//   fnSdpFetch("assets", [search_criteria = [...]], "assets")
//   fnSdpFetch("requests/12345/worklogs", null, "worklogs")
//
// Returns: a list of records (raw JSON, not flattened). Flattening is the
//          report's responsibility.
// ============================================================
(
    endpoint as text,
    optional listInfo as nullable record,
    optional dataKey as nullable text
) as list =>
let
    BaseURL  = Config[ApiBaseURL],
    PageSize = Config[PageSize],
    Extra    = if listInfo = null then [] else listInfo,

    GetPage = (startIndex as number) as record =>
        let
            // Record.Combine: last occurrence wins.
            //  - default sort on "id": without a STABLE order, SDP paginates
            //    randomly (duplicates on page N, missing rows on page N+1).
            //    The caller may override it via listInfo.
            //  - row_count / start_index are forced last: the caller cannot
            //    break pagination.
            Info = Record.Combine({
                [ sort_field = "id", sort_order = "asc" ],
                Extra,
                [ row_count = PageSize, start_index = startIndex ]
            }),

            Payload = Text.FromBinary(Json.FromValue([ list_info = Info ])),

            // STATIC base URL + RelativePath: required for scheduled refresh
            // to work and to avoid credential prompts on every open.
            Response = Web.Contents(BaseURL, [
                RelativePath = endpoint,
                Query        = [ input_data = Payload ],
                Headers      = [
                    #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
                    #"TECHNICIAN_KEY" = ApiKey
                ],
                ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
            ]),

            Status = Value.Metadata(Response)[Response.Status]?,

            Body = if Status <> null and Status >= 400 then
                       error Error.Record(
                           "SDP.HttpError",
                           "HTTP " & Text.From(Status) & " on /" & endpoint,
                           // the SDP body carries the real reason (unknown
                           // field, missing view, invalid key...)
                           try Text.FromBinary(Response) otherwise "(unreadable body)"
                       )
                   else Json.Document(Response),

            // Detect the key carrying the rows: "cmdb", "assets", "requests",
            // "worklogs"... Envelope keys are excluded.
            Envelope = {"response_status", "list_info", "search_criteria"},
            Keys     = Record.FieldNames(Body),
            Resolved = if dataKey <> null then dataKey
                       else List.First(List.Select(Keys, each not List.Contains(Envelope, _)), null),

            // Key explicitly requested but absent: FAIL, do not return an
            // empty table silently.
            Rows = if Resolved = null then {}
                   else if not Record.HasFields(Body, Resolved) then
                       error Error.Record(
                           "SDP.DataKeyNotFound",
                           "Key """" & Resolved & """" is missing from the /" & endpoint & " response",
                           "Keys present: " & Text.Combine(Keys, ", ")
                         & "  |  response_status: "
                         & (try Text.FromBinary(Json.FromValue(Body[response_status])) otherwise "?")
                       )
                   else
                       let v = Record.Field(Body, Resolved)
                       in  if v is list then v else {v},

            HasMore = try Body[list_info][has_more_rows] otherwise false
        in
            [ Rows = Rows, HasMore = HasMore, Next = startIndex + PageSize ],

    // Pagination driven by has_more_rows: no superfluous call.
    Pages = List.Generate(
        () => [ P = GetPage(1) ],
        each [P] <> null,
        each if [P][HasMore] then [ P = GetPage([P][Next]) ] else [ P = null ],
        each [P][Rows]
    ),

    Result = List.Combine(Pages)
in
    Result
