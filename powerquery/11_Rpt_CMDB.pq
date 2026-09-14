// ============================================================
// Requête : Rpt_CMDB   (charger dans une feuille)
// La CMDB complete. Toute la logique est dans fnCmdbTable.
// ============================================================
let
    Source = fnCmdbTable(),
    Final  = Table.RemoveColumns(Source, {"ModuleInterne"})
in
    Final
