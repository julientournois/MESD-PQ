// ============================================================
// Requête : fnCmdbTable
// Type    : fonction (Connexion uniquement)
// Rôle    : la CMDB complete, mise en forme. Source unique pour tous les
//           rapports CMDB (Rpt_CMDB, Rpt_CMDBServers...). Ajouter une
//           colonne ici la propage partout.
//
// Colonnes : ID, URL_CI, Name, Module, ModuleInterne, Description, Site, + UDF de
//            Config[CmdbUdfFields].
// ModuleInterne = module.name (ex: cmdb_physicalserver), utile pour
// filtrer sans dependre du libelle affiche.
// ============================================================
() as table =>
let
    Raw  = fnSdpFetch("cmdb", null, null),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    T01 = Table.AddColumn(Base, "Name",          each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,  "Module",        each
              let M = Record.FieldOrDefault([r], "module", null)
              in  if M is record
                  then Record.FieldOrDefault(M, "display_name", Record.FieldOrDefault(M, "name", null))
                  else null, type text),
    T03 = Table.AddColumn(T02,  "ModuleInterne", each fnSdpName([r], "module"), type text),
    T04 = Table.AddColumn(T03,  "Description",   each fnStripHtml(Record.FieldOrDefault([r], "description", null)), type text),
    T05 = Table.AddColumn(T04,  "Site",          each fnSdpName([r], "site"), type text),

    // Lien vers la fiche CI dans SDP (texte ; HYPERLINK cote Excel, cf. README).
    T06 = Table.AddColumn(T05, "ID", each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    // L'URL d'une fiche CI depend du module ET de l'id :
    //   /ui/cmdb_module?ci_type=cmdb_virtual_servers&mode=details&ciid=1234#details
    // Config[CiUrlFmt] est un modele avec {type} et {id}.
    T07 = Table.AddColumn(T06, "URL_CI", each
              if [ID] = null or [ModuleInterne] = null then null
              else Config[WebBaseURL]
                 & Text.Replace(Text.Replace(Config[CiUrlFmt], "{type}", [ModuleInterne]), "{id}", [ID]),
              type text),

    WithUdf = List.Accumulate(
        Config[CmdbUdfFields],
        T07,
        (tbl, u) => Table.AddColumn(tbl, u{1}, (row) => fnSdpUdf(row[r], u{0}), type text)
    ),

    Final = Table.SelectColumns(WithUdf,
        {"ID", "URL_CI", "Name", "Module", "ModuleInterne", "Description", "Site"}
        & List.Transform(Config[CmdbUdfFields], each _{1}))
in
    Final
