// ============================================================
// Requête : Rpt_CMDB   (charger dans une feuille)
// Le rapport CMDB, reecrit sur fnSdpFetch.
// Note la difference : plus une seule URL, cle, ou logique de pagination ici.
// Cette requete ne fait que de la mise en forme.
//
// Les champs personnalises ne sont PAS en dur : ils viennent de
// Config[CmdbUdfFields]. Ajouter un UDF = une ligne dans Config.
// ============================================================
let
    Raw  = fnSdpFetch("cmdb", null, null),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    T01 = Table.AddColumn(Base, "Name",        each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,  "Module",      each fnSdpName([r], "module"), type text),
    T03 = Table.AddColumn(T02,  "Description", each fnStripHtml(Record.FieldOrDefault([r], "description", null)), type text),
    T04 = Table.AddColumn(T03,  "Site",        each fnSdpName([r], "site"), type text),

    // Une colonne par entree de Config[CmdbUdfFields] : { nom_api, libelle }.
    // Lambda explicite (row) => et non "each" : "each" reutiliserait _ et
    // masquerait la variable de boucle u.
    WithUdf = List.Accumulate(
        Config[CmdbUdfFields],
        T04,
        (tbl, u) => Table.AddColumn(tbl, u{1}, (row) => fnSdpUdf(row[r], u{0}), type text)
    ),

    Final = Table.SelectColumns(
        WithUdf,
        {"Name", "Module", "Description", "Site"}
            & List.Transform(Config[CmdbUdfFields], each _{1})
    )
in
    Final

// ------------------------------------------------------------------
// Pourquoi fnSdpUdf plutot qu'une cascade de ExpandRecordColumn :
// si un UDF est vide sur TOUTES les lignes de la page, SDP peut ne pas
// renvoyer le champ du tout -> ExpandRecordColumn plante avec
// "la colonne n'existe pas". Record.FieldOrDefault ne plante jamais.
// C'est le genre de panne qui arrive 3 mois plus tard, un lundi matin.
// ------------------------------------------------------------------
