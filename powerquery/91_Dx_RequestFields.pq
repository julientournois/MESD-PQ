// ============================================================
// Query : Dx_RequestFields   (DIAGNOSTIC - Connection only)
// Shows EVERY field actually returned by your build on one ticket.
// Useful to check names before putting them in fields_required.
// ============================================================
let
    Raw    = fnSdpFetch("requests", [ row_count = 1 ], "requests"),
    First  = List.First(Raw, null),
    Fields = if First = null then {} else Record.FieldNames(First),
    T      = Table.FromList(Fields, Splitter.SplitByNothing(), {"Field"}),
    Typed  = Table.AddColumn(T, "Type", each
                 let v = Record.Field(First, [Field])
                 in  if v = null then "null"
                     else if v is record then "record: " & Text.Combine(Record.FieldNames(v), ", ")
                     else if v is list then "list"
                     else Text.From(Value.Type(v)))
in
    Typed
