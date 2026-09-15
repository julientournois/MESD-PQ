// ============================================================
// Query : fnSdpGet
// Type  : function (Connection only)
// Role  : plain GET of ONE object, WITHOUT any input_data.
//         Verified on this build: /requests/{id} returns udf_fields only
//         when no input_data is sent; fnSdpFetch (which always sends a
//         list_info) gets a record without them.
//
// Usage : fnSdpGet("requests/12345", "request")  -> the request record
// dataKey optional: the key holding the object ("request", "asset"...).
// When null, the first non-envelope key is used.
// Returns null on 404 (object not found); raises on any other HTTP error.
// ============================================================
(endpoint as text, optional dataKey as nullable text) as nullable record =>
let
    Response = Web.Contents(Config[ApiBaseURL], [
        RelativePath         = endpoint,
        Headers              = [
            #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
            #"TECHNICIAN_KEY" = ApiKey
        ],
        ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
    ]),
    Status = Value.Metadata(Response)[Response.Status]?,

    Body = if Status = 404 then null
           else if Status <> null and Status >= 400 then
               error Error.Record(
                   "SDP.HttpError",
                   "HTTP " & Text.From(Status) & " on /" & endpoint,
                   try Text.FromBinary(Response) otherwise "(unreadable body)")
           else Json.Document(Response),

    Key = if Body = null then null
          else if dataKey <> null then dataKey
          else List.First(List.Select(Record.FieldNames(Body),
                   each not List.Contains({"response_status", "list_info"}, _)), null),

    Obj = if Body = null or Key = null then null
          else if not Record.HasFields(Body, Key) then
              error Error.Record(
                  "SDP.DataKeyNotFound",
                  "Key """" & Key & """" is missing from the /" & endpoint & " response",
                  "Keys present: " & Text.Combine(Record.FieldNames(Body), ", "))
          else
              let v = Record.Field(Body, Key)
              in  if v is record then v else null
in
    Obj
