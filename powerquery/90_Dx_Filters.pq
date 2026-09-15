// ============================================================
// Query : Dx_Filters   (DIAGNOSTIC - Connection only)
// Lists the views / filters available on requests, with their id.
// This is where you get the view id if filter_by by name fails.
// Depending on the build the endpoint is "requests/filters" or
// "request_filters": both are tried.
// ============================================================
let
    Try1 = try fnSdpFetch("requests/filters", null, null),
    Try2 = if Try1[HasError] then try fnSdpFetch("request_filters", null, null) else Try1,
    Raw  = if Try2[HasError]
           then error Error.Record(
                    "SDP.NoFilterEndpoint",
                    "No filter endpoint found.",
                    "Get the id manually: open your view in SDP and read the "
                  & "filterViewID / viewID parameter in the browser URL."
                )
           else Try2[Value],
    T = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),
    A = Table.AddColumn(T, "id",      each Record.FieldOrDefault([r], "id", null)),
    B = Table.AddColumn(A, "name",    each Record.FieldOrDefault([r], "name", null)),
    C = Table.AddColumn(B, "display", each Record.FieldOrDefault([r], "display_name", null)),
    D = Table.SelectColumns(C, {"id", "name", "display"})
in
    D
