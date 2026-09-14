// ============================================================
// Requête : Rpt_CMDBServers   (charger dans une feuille)
// Sous-ensemble de la CMDB : uniquement les modules listes dans
// Config[CmdbServerModules], compares sans tenir compte de la casse au
// nom interne (module.name) ET au libelle (module.display_name).
// Trie par Module puis Name.
// ============================================================
let
    Source = fnCmdbTable(),

    Wanted = List.Transform(Config[CmdbServerModules], each Text.Lower(Text.Trim(_))),
    Norm   = (t as nullable text) as text => if t = null then "" else Text.Lower(Text.Trim(t)),

    Filtered = Table.SelectRows(Source, each
                   List.Contains(Wanted, Norm([ModuleInterne]))
                   or List.Contains(Wanted, Norm([Module]))),

    Sorted = Table.Sort(Filtered, {{"Module", Order.Ascending}, {"Name", Order.Ascending}}),
    Final  = Table.RemoveColumns(Sorted, {"ModuleInterne"})
in
    Final

// ------------------------------------------------------------------
// Table vide ? Ouvre Rpt_CMDB et regarde les valeurs distinctes de la
// colonne Module ; ou active temporairement ModuleInterne en retirant
// la derniere etape. Les noms internes SDP sont souvent en minuscules
// sans separateur : cmdb_physicalserver, cmdb_virtualserver...
// ------------------------------------------------------------------
