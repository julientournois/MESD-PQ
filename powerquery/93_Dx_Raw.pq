// ============================================================
// Query : Dx_Raw   (DIAGNOSTIC - Connection only)
// RAW call, bypassing fnSdpFetch: returns the full JSON of the first page
// to inspect the exact envelope (response_status, list_info, data key,
// record shape).
//
// Adjust the Endpoint / Extra lines, then click the records in the
// preview to navigate.
// ============================================================
let
    Endpoint = "assets",
    Extra    = [],   // e.g. [ search_criteria = [ field = "product.product_type.name", condition = "is", value = "Laptop" ] ]

    // get_total_count: SDP then returns list_info.total_count, to compare
    // with the report row count to detect duplicates / missing rows.
    Info     = Record.Combine({ Extra, [ row_count = 5, start_index = 1, get_total_count = true ] }),
    Payload  = Text.FromBinary(Json.FromValue([ list_info = Info ])),
    Response = Web.Contents(Config[ApiBaseURL], [
        RelativePath = Endpoint,
        Query        = [ input_data = Payload ],
        Headers      = [
            #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
            #"TECHNICIAN_KEY" = ApiKey
        ],
        ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
    ]),
    Status   = Value.Metadata(Response)[Response.Status]?,
    Body     = Json.Document(Response),

    // Flat list of every field path of the first record
    // (e.g. "udf_fields.udf_xxx"). Filter the list in the preview to find
    // WHERE a field lives.
    DataKey  = List.First(List.Select(Record.FieldNames(Body),
                   each not List.Contains({"response_status","list_info"}, _)), null),
    FirstRec = if DataKey = null then null
               else let v = Record.Field(Body, DataKey)
                    in if v is list then List.First(v, null) else v,
    Paths    = (R as any, prefix as text) as list =>
        if not (R is record) then {}
        else List.Combine(List.Transform(Record.FieldNames(R), each
                 let full = if prefix = "" then _ else prefix & "." & _,
                     v    = Record.Field(R, _)
                 in  if v is record then {full} & @Paths(v, full) else {full})),
    FirstRecordFields = if FirstRec = null then {} else Paths(FirstRec, ""),

    Summary  = [
        HttpStatus        = Status,
        DataKey           = DataKey,
        FirstRecordFields = FirstRecordFields,
        FirstRecord       = FirstRec,
        InputDataSent     = Payload,
        ResponseKeys      = Text.Combine(Record.FieldNames(Body), ", "),
        ResponseStatus    = Record.FieldOrDefault(Body, "response_status", null),
        ListInfo          = Record.FieldOrDefault(Body, "list_info", null),
        Body              = Body
    ]
in
    Summary
