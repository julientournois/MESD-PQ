// ============================================================
// Requête : Rpt_TicketsExemple   (modele a copier pour un nouveau rapport)
//
// Pour un nouveau rapport tickets :
//   1. copier ce fichier, renommer la requete (Rpt_TicketsXxx)
//   2. changer le filtre ci-dessous
//   3. charger dans une feuille, ajouter les colonnes HYPERLINK
// Rien d'autre : colonnes, liens et worklogs viennent de fnTicketsTable.
//
// Formes de filtre acceptees par l'API :
//   [ name = "Ma_Vue" ]      vue SDP par nom (Dx_Filters liste les noms)
//   [ id   = "301" ]         vue SDP par id
// Si le filtre voulu n'existe pas comme vue dans SDP, cree-la dans SDP :
// c'est plus rapide et plus fiable qu'un filtre en M apres coup.
// ============================================================
let
    Final = fnTicketsTable([ name = "All_Pending_Requests" ])
in
    Final
