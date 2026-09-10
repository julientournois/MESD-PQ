// ============================================================
// Requêtes de DIAGNOSTIC. A garder en "Connexion uniquement",
// a executer manuellement quand quelque chose ne marche pas.
// ============================================================


// ------------------------------------------------------------
// Requête : Dx_Filters
// Liste les vues / filtres disponibles sur les requests, avec leur id.
// C'est ici que tu recuperes l identifiant de la vue si filter_by par nom echoue.
// Selon le build, l'endpoint est "requests/filters" ou "request_filters".
// ------------------------------------------------------------
let
    Try1 = try fnSdpFetch("requests/filters", null, null),
    Try2 = if Try1[HasError] then try fnSdpFetch("request_filters", null, null) else Try1,
    Raw  = if Try2[HasError]
           then error Error.Record(
                    "SDP.NoFilterEndpoint",
                    "Aucun endpoint de filtres trouve.",
                    "Recupere l'id manuellement : ouvre ta vue dans SDP et lis "
                  & "le parametre filterViewID / viewID dans l'URL du navigateur."
                )
           else Try2[Value],
    T = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),
    A = Table.AddColumn(T, "id",   each Record.FieldOrDefault([r], "id", null)),
    B = Table.AddColumn(A, "name", each Record.FieldOrDefault([r], "name", null)),
    C = Table.AddColumn(B, "display", each Record.FieldOrDefault([r], "display_name", null)),
    D = Table.SelectColumns(C, {"id", "name", "display"})
in
    D


// ------------------------------------------------------------
// Requête : Dx_RequestFields
// Montre TOUS les champs reellement renvoyes par ton build sur un
// echantillon de tickets. Utile pour verifier les noms avant de les
// mettre dans fields_required.
// ------------------------------------------------------------
let
    Raw    = fnSdpFetch("requests", [ row_count = 1 ], "requests"),
    First  = List.First(Raw, null),
    Fields = if First = null then {} else Record.FieldNames(First),
    T      = Table.FromList(Fields, Splitter.SplitByNothing(), {"Champ"}),
    Typed  = Table.AddColumn(T, "Type", each
                 let v = Record.Field(First, [Champ])
                 in  if v = null then "null"
                     else if v is record then "record : " & Text.Combine(Record.FieldNames(v), ", ")
                     else if v is list then "list"
                     else Text.From(Value.Type(v)))
in
    Typed


// ------------------------------------------------------------
// Requête : Dx_WorklogSample
// Verifie la forme reelle d'un worklog (nom du champ de date notamment :
// created_time vs start_time selon la configuration).
// Remplace 12345 par un vrai numero de ticket qui a des worklogs.
// ------------------------------------------------------------
let
    Raw   = fnSdpFetch("requests/12345/worklogs", null, "worklogs"),
    First = List.First(Raw, null),
    Out   = if First = null then "Aucun worklog sur ce ticket"
            else Text.Combine(Record.FieldNames(First), " | ")
in
    Out
