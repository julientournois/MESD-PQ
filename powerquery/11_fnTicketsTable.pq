// ============================================================
// Query : fnTicketsTable
// Type  : function (Connection only)
// Role  : THE ticket report logic (columns, links, last worklog).
//         Every Rpt_Tickets* calls it with its own filter.
//
// filterBy: the API filter_by record, for example
//     [ name = "My_View" ]           view by name
//     [ id   = "301" ]               view by id (if the name is rejected)
//
// extraColumns (optional): report-specific columns, appended after
// Subcategory. A list of records [ field, label, kind ]:
//     field : API field name (or UDF name for kind udf / udfdate)
//     label : Excel column name
//     kind  : "text"    raw value as text
//             "name"    linked object [id, name] -> name   (e.g. "group")
//             "date"    SDP date record -> datetime        (e.g. "due_by_time")
//             "udf"     custom field -> text               (e.g. "udf_char_1")
//             "udfdate" custom date field -> datetime      (e.g. "udf_date_1")
// Example:
//     fnTicketsTable([ name = "RFC_View" ],
//                    { [ field = "udf_date_2701", label = "RfcDate", kind = "udfdate" ] })
//     fnTicketsTable([ name = "CSIOC_View" ],
//                    { [ field = "due_by_time", label = "DueBy", kind = "date" ] })
//
// Any column added to the base here shows up in every ticket report.
//
// PERFORMANCE: one HTTP call per ticket for the worklogs. While developing
// set Config[WorklogTicketLimit] = 25.
// ============================================================
(filterBy as record, optional extraColumns as nullable list) as table =>
let
    Extras = if extraColumns = null then {} else extraColumns,

    // fields_required must name every field we read. UDFs come as a block
    // ("udf_fields"), other fields by their own name.
    ExtraFields = List.Distinct(List.Transform(Extras, each
                      if _[kind] = "udf" or _[kind] = "udfdate" then "udf_fields" else _[field])),

    // ---------- 1. Tickets ------------------------------------------------
    ListInfo = [
        filter_by  = filterBy,
        sort_field = "id",
        sort_order = "desc",
        // fields_required greatly reduces the transferred volume.
        // If your build returns 400 "invalid field", COMMENT this block out:
        // you get the full record and the rest of the code works unchanged.
        fields_required = {
            "id", "subject", "status", "priority", "technician",
            "category", "subcategory", "created_time", "last_updated_time"
        } & ExtraFields
    ],

    Raw = fnSdpFetch("requests", ListInfo, "requests"),

    Base0 = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    // Optional cap (development only)
    Base = if Config[WorklogTicketLimit] = null
           then Base0
           else Table.FirstN(Base0, Config[WorklogTicketLimit]),

    // ---------- 2. Flat columns ------------------------------------------
    C01 = Table.AddColumn(Base, "ID",          each Text.From([r][id]), type text),
    C02 = Table.AddColumn(C01,  "Subject",     each fnStripHtml(Record.FieldOrDefault([r], "subject", null)), type text),
    C03 = Table.AddColumn(C02,  "Technician",  each fnSdpName([r], "technician"), type text),
    C04 = Table.AddColumn(C03,  "Status",      each fnSdpName([r], "status"), type text),
    C04b= Table.AddColumn(C04,  "Priority",    each fnSdpName([r], "priority"), type text),
    C05 = Table.AddColumn(C04b, "Category",    each fnSdpName([r], "category"), type text),
    C06 = Table.AddColumn(C05,  "Subcategory", each fnSdpName([r], "subcategory"), type text),

    // ---------- 2b. Report-specific columns ------------------------------
    // Explicit lambda (row) => so the loop variable x is not shadowed by
    // the _ of "each".
    fnUdfRaw = (rec as any, name as text) as any =>
        if rec is record and Record.HasFields(rec, "udf_fields")
        then Record.FieldOrDefault(rec[udf_fields], name, null) else null,

    fnExtra = (rec as any, x as record) as any =>
        if x[kind] = "name"    then fnSdpName(rec, x[field])
        else if x[kind] = "date"    then fnSdpDate(Record.FieldOrDefault(rec, x[field], null))
        else if x[kind] = "udf"     then fnSdpUdf(rec, x[field])
        else if x[kind] = "udfdate" then fnSdpDate(fnUdfRaw(rec, x[field]))
        else (let v = Record.FieldOrDefault(rec, x[field], null)
              in if v = null then null else try Text.From(v) otherwise null),

    C06x = List.Accumulate(Extras, C06, (tbl, x) =>
               Table.AddColumn(tbl, x[label], (row) => fnExtra(row[r], x),
                   if x[kind] = "date" or x[kind] = "udfdate" then type datetime else type text)),

    // ---------- 3. Links (text; HYPERLINK is built in Excel, see README) --
    C07 = Table.AddColumn(C06x, "TicketURL", each
              Config[WebBaseURL] & Config[TicketUrlFmt] & [ID] & Config[TicketUrlSuf],
              type text),
    C08 = Table.AddColumn(C07, "NetworkFolder", each fnTicketFolder([ID]), type text),

    // Buffer BEFORE the worklog loop: prevents Power Query from re-evaluating
    // the ticket list on every row (N calls would become N x N).
    Buffered = Table.Buffer(C08),

    // ---------- 4. Last worklog -----------------------------------------
    // One call per ticket. All worklogs are fetched (there are few) and the
    // most recent is picked in M: no dependency on server-side sorting.
    //
    // A failed call is NOT swallowed: it is distinguished from a ticket
    // without worklog. Otherwise an expired key or an unavailable SDP would
    // yield a "clean" report with invisible holes.
    W01 = Table.AddColumn(Buffered, "_wl", each
              try fnSdpFetch(
                      "requests/" & [ID] & "/worklogs",
                      [ fields_required = {"id", "description", "created_time", "owner"} ],
                      "worklogs"
                  )),

    W02 = Table.AddColumn(W01, "_last", each
              if [_wl][HasError] then
                  [ dt = null,
                    desc = "WORKLOG CALL ERROR: "
                         & (try [_wl][Error][Message] otherwise "?")
                         & " -- "
                         & (try Text.From([_wl][Error][Detail]) otherwise ""),
                    err = true ]
              else
                  let
                      Items  = [_wl][Value],
                      Mapped = List.Transform(Items, each [
                          dt   = fnSdpDate(Record.FieldOrDefault(_, "created_time", null)),
                          desc = Record.FieldOrDefault(_, "description", null),
                          err  = false
                      ]),
                      Dated  = List.Select(Mapped, each [dt] <> null),
                      Sorted = List.Sort(Dated, {each [dt], Order.Descending})
                  in
                      if List.IsEmpty(Sorted)
                      then (if List.IsEmpty(Mapped) then null else List.Last(Mapped))
                      else List.First(Sorted)),

    W03 = Table.AddColumn(W02, "LastWorklogDate", each
              if [_last] = null then null else [_last][dt], type datetime),

    // On error the raw message is written as is (no HTML cleaning) so it
    // stays readable and filterable on "WORKLOG CALL ERROR".
    W04 = Table.AddColumn(W03, "LastWorklog", each
              if [_last] = null then null
              else if [_last][err] then [_last][desc]
              else fnStripHtml([_last][desc]), type text),

    // ---------- 5. Output ------------------------------------------------
    Final = Table.SelectColumns(W04, {
        "ID",
        "TicketURL",
        "NetworkFolder",
        "Technician",
        "Subject",
        "Status",
        "Priority",
        "Category",
        "Subcategory"
    } & List.Transform(Extras, each _[label]) & {
        "LastWorklogDate",
        "LastWorklog"
    })
in
    Final
