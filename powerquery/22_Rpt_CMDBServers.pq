// ============================================================
// Query : Rpt_CMDBServers   (load to a worksheet)
// Subset of the CMDB: only the modules listed in Config[CmdbServerModules],
// compared case-insensitively to the internal name (module.name) AND the
// display label (module.display_name).
// Sorted by Module then Name.
// ============================================================
let
    Source = fnCmdbTable(),

    Wanted = List.Transform(Config[CmdbServerModules], each Text.Lower(Text.Trim(_))),
    Norm   = (t as nullable text) as text => if t = null then "" else Text.Lower(Text.Trim(t)),

    Filtered = Table.SelectRows(Source, each
                   List.Contains(Wanted, Norm([ModuleKey]))
                   or List.Contains(Wanted, Norm([Module]))),

    Sorted = Table.Sort(Filtered, {{"Module", Order.Ascending}, {"Name", Order.Ascending}}),
    Final  = Table.RemoveColumns(Sorted, {"ModuleKey"})
in
    Final

// ------------------------------------------------------------------
// Empty table? Open Rpt_CMDB and look at the distinct values of the Module
// column; or temporarily expose ModuleKey by removing the last step.
// SDP internal names are often lowercase, inconsistently separated:
// cmdb_physicalserver, cmdb_virtual_server...
// ------------------------------------------------------------------
