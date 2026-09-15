// ============================================================
// Query : fnCmdbTable
// Type  : function (Connection only)
// Role  : the full CMDB, shaped. Single source for every CMDB report
//         (Rpt_CMDB, Rpt_CMDBServers...). A column added here shows up
//         in all of them.
//
// Columns: ID, CiURL, Name, Module, ModuleKey, Description, Site,
//          + the UDFs from Config[CmdbUdfFields].
// ModuleKey = module.name (e.g. cmdb_physicalserver): use it to filter
// without depending on the display label.
// ============================================================
() as table =>
let
    Raw  = fnSdpFetch("cmdb", null, null),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    T01 = Table.AddColumn(Base, "Name",        each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,  "Module",      each
              let M = Record.FieldOrDefault([r], "module", null)
              in  if M is record
                  then Record.FieldOrDefault(M, "display_name", Record.FieldOrDefault(M, "name", null))
                  else null, type text),
    T03 = Table.AddColumn(T02,  "ModuleKey",   each fnSdpName([r], "module"), type text),
    T04 = Table.AddColumn(T03,  "Description", each fnStripHtml(Record.FieldOrDefault([r], "description", null)), type text),
    T05 = Table.AddColumn(T04,  "Site",        each fnSdpName([r], "site"), type text),

    // Link to the CI page in SDP (text; HYPERLINK is built in Excel, see README).
    // The URL depends on the module AND the id:
    //   /ui/cmdb_module?ci_type=cmdb_virtual_servers&mode=details&ciid=1234#details
    // The URL ci_type is NOT the API module.name (API "cmdb_virtual_server",
    // URL "cmdb_virtual_servers"). Mapping in Config[CiUrlTypeMap];
    // fallback = append "s".
    fnCiUrlType = (moduleName as nullable text) as nullable text =>
        if moduleName = null then null
        else
            let
                Hit = List.Select(Config[CiUrlTypeMap], each _{0} = moduleName)
            in
                if List.IsEmpty(Hit) then moduleName & "s" else List.First(Hit){1},

    T06 = Table.AddColumn(T05, "ID", each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    T07 = Table.AddColumn(T06, "CiURL", each
              if [ID] = null or [ModuleKey] = null then null
              else Config[WebBaseURL]
                 & Text.Replace(Text.Replace(Config[CiUrlFmt], "{type}", fnCiUrlType([ModuleKey])), "{id}", [ID]),
              type text),

    // One column per entry of Config[CmdbUdfFields]: { api_name, label }.
    // Explicit lambda (row) => rather than "each": "each" would reuse _ and
    // shadow the loop variable u.
    WithUdf = List.Accumulate(
        Config[CmdbUdfFields],
        T07,
        (tbl, u) => Table.AddColumn(tbl, u{1}, (row) => fnSdpUdf(row[r], u{0}), type text)
    ),

    Final = Table.SelectColumns(WithUdf,
        {"ID", "CiURL", "Name", "Module", "ModuleKey", "Description", "Site"}
        & List.Transform(Config[CmdbUdfFields], each _{1}))
in
    Final

// ------------------------------------------------------------------
// Why fnSdpUdf rather than a cascade of ExpandRecordColumn: if a UDF is
// empty on EVERY row of a page, SDP may omit the field entirely and
// ExpandRecordColumn fails with "column does not exist".
// Record.FieldOrDefault never fails. That is the kind of breakage that
// shows up three months later, on a Monday morning.
// ------------------------------------------------------------------
