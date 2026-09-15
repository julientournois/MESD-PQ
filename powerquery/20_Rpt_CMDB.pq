// ============================================================
// Query : Rpt_CMDB   (load to a worksheet)
// The full CMDB. All the logic lives in fnCmdbTable.
// ============================================================
let
    Source = fnCmdbTable(),
    Final  = Table.RemoveColumns(Source, {"ModuleKey"})
in
    Final
