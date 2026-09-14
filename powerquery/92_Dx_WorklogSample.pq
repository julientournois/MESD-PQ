// ============================================================
// Requête : Dx_WorklogSample   (DIAGNOSTIC - Connexion uniquement)
// Verifie la forme reelle d'un worklog (nom du champ de date notamment :
// created_time vs start_time selon la configuration).
// Remplace 12345 par un vrai numero de ticket qui a des worklogs.
// ============================================================
let
    TicketId = "12345",
    Raw   = fnSdpFetch("requests/" & TicketId & "/worklogs", null, "worklogs"),
    First = List.First(Raw, null),
    Out   = if First = null then "Aucun worklog sur ce ticket"
            else Text.Combine(Record.FieldNames(First), " | ")
in
    Out
