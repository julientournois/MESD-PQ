// ============================================================
// Requête : Rpt_Laptops   (charger dans une feuille)
// Assets de type "Laptop". Adapte le nom exact du product type au tien
// (Admin > Product Types dans SDP : "Laptop", "Notebook", "Portable"...).
// ============================================================
let
    ListInfo = [
        search_criteria = [
            field     = "product.product_type.name",
            condition = "is",
            value     = "Laptop"
        ],
        sort_field = "name",
        sort_order = "asc"
        // fields_required = {"id","name","asset_tag","state","user","site","product","serial_number"}
    ],

    Raw  = fnSdpFetch("assets", ListInfo, "assets"),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    T01 = Table.AddColumn(Base, "Nom",        each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,  "AssetTag",   each Record.FieldOrDefault([r], "asset_tag", null), type text),
    T03 = Table.AddColumn(T02,  "NumeroSerie",each Record.FieldOrDefault([r], "serial_number", null), type text),
    T04 = Table.AddColumn(T03,  "Etat",       each fnSdpName([r], "state"), type text),
    T05 = Table.AddColumn(T04,  "Utilisateur",each fnSdpName([r], "user"), type text),
    T06 = Table.AddColumn(T05,  "Site",       each fnSdpName([r], "site"), type text),
    T07 = Table.AddColumn(T06,  "Produit",    each fnSdpName([r], "product"), type text),

    Final = Table.SelectColumns(T07, {
        "Nom", "AssetTag", "NumeroSerie", "Etat", "Utilisateur", "Site", "Produit"
    })
in
    Final

// ------------------------------------------------------------------
// Si search_criteria renvoie un 400, la cause la plus probable est le
// chemin du champ. Solutions, dans l'ordre :
//   1. essayer  field = "product_type.name"
//   2. essayer  field = "product.name"  avec le modele exact
//   3. abandonner le filtre serveur et filtrer en M :
//        Filtre = Table.SelectRows(T07, each [Produit] <> null
//                   and Text.Contains(Text.Lower([Produit]), "laptop"))
//      (plus lent : on telecharge tous les assets)
// ------------------------------------------------------------------
