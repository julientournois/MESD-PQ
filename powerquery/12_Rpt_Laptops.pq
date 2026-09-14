// ============================================================
// Requête : Rpt_Laptops   (charger dans une feuille)
//
// CONSTAT : sur ce build, search_criteria n'est honore que par /requests.
// Sur /assets il est ignore et TOUT est renvoye. Le filtrage se fait donc
// cote Power Query, apres telechargement complet.
//
// Le filtre est pilote par Config[AssetTypeFilter] :
//   - liste vide {}  -> aucun filtre : tous les assets, avec la colonne
//                       TypeProduit visible pour lire les libelles reels
//   - {"Laptop"}     -> ne garde que ce(s) type(s), sans tenir compte de la
//                       casse ni des espaces
// Premiere execution : filtre vide, note les libelles, puis renseigne-les.
// ============================================================
let
    Raw  = fnSdpFetch("assets", null, "assets"),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    // Le type de produit peut etre range a plusieurs endroits selon le build.
    // On essaie dans l'ordre et on prend le premier renseigne.
    fnProductType = (rec as any) as nullable text =>
        let
            P    = if rec is record then Record.FieldOrDefault(rec, "product", null) else null,
            Try1 = if P is record then fnSdpName(P, "product_type") else null,
            Try2 = if Try1 = null then fnSdpName(rec, "product_type") else Try1,
            Try3 = if Try2 = null then fnSdpName(rec, "asset_type") else Try2
        in
            Try3,

    T00 = Table.AddColumn(Base, "TypeProduit", each fnProductType([r]), type text),

    // ---------- Filtre client -------------------------------------------
    Wanted   = List.Transform(Config[AssetTypeFilter], each Text.Lower(Text.Trim(_))),
    Filtered = if List.IsEmpty(Wanted) then T00
               else Table.SelectRows(T00, each
                        [TypeProduit] <> null
                        and List.Contains(Wanted, Text.Lower(Text.Trim([TypeProduit])))),

    // ---------- Colonnes -------------------------------------------------
    T01 = Table.AddColumn(Filtered, "Nom",         each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,      "AssetTag",    each Record.FieldOrDefault([r], "asset_tag", null), type text),
    T03 = Table.AddColumn(T02,      "NumeroSerie", each Record.FieldOrDefault([r], "serial_number", null), type text),
    T04 = Table.AddColumn(T03,      "Etat",        each fnSdpName([r], "state"), type text),
    T05 = Table.AddColumn(T04,      "Utilisateur", each fnSdpName([r], "user"), type text),
    T06 = Table.AddColumn(T05,      "Site",        each fnSdpName([r], "site"), type text),
    T07 = Table.AddColumn(T06,      "Produit",     each fnSdpName([r], "product"), type text),

    Final = Table.Sort(
        Table.SelectColumns(T07, {
            "Nom", "TypeProduit", "Produit", "AssetTag", "NumeroSerie",
            "Etat", "Utilisateur", "Site"
        }),
        {{"Nom", Order.Ascending}}
    )
in
    Final

// ------------------------------------------------------------------
// Si TypeProduit est vide sur toutes les lignes, aucun des trois chemins
// essayes par fnProductType ne correspond a ton build. Ouvre Dx_Raw sur
// "assets", regarde ou vit le type dans le premier enregistrement, et
// ajoute ce chemin dans fnProductType.
// ------------------------------------------------------------------
