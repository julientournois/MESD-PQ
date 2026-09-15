// ============================================================
// Query : fnSdpUdf
// Type  : function (Connection only)
// Reads a custom field of an SDP record, whether it is raw text, a number,
// or an [id, name] object. Never fails: returns null when absent.
//
// Where UDFs live depends on the entity and the build. Searched in order:
//   1. rec.udf_fields.<name>          (requests, cmdb)
//   2. rec.<name>                     (flat, at the root)
//   3. rec.<any sub-record>.<name>    (assets: rec.ci_default_fields)
//      one level deep, then two.
// Usage: fnSdpUdf([r], "udf_xxx")
// ============================================================
(rec as any, name as text) as nullable text =>
let
    ToText = (V as any) as nullable text =>
        if V = null then null
        else if V is record then
             Record.FieldOrDefault(V, "name", Record.FieldOrDefault(V, "display_value", null))
        else try Text.From(V) otherwise null,

    // Look for <name> in a record, then in its sub-records (max depth).
    Find = (R as any, depth as number) as any =>
        if not (R is record) then null
        else if Record.HasFields(R, name) then Record.Field(R, name)
        else if depth <= 0 then null
        else
            let
                Subs  = List.Select(Record.FieldValues(R), each _ is record),
                Found = List.Select(List.Transform(Subs, each @Find(_, depth - 1)), each _ <> null)
            in
                List.First(Found, null),

    Direct = if rec is record and Record.HasFields(rec, "udf_fields")
             then Record.FieldOrDefault(rec[udf_fields], name, null)
             else null,

    Value  = if Direct <> null then Direct else Find(rec, 2)
in
    ToText(Value)
