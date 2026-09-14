// ============================================================
// Requête : Dx_Filters   (DIAGNOSTIC - Connexion uniquement)
// Liste les vues / filtres disponibles sur les requests, avec leur id.
// C'est ici que tu recuperes l'identifiant de la vue si filter_by par nom
// echoue. Selon le build, l'endpoint est "requests/filters" ou
// "request_filters" : on essaie les deux.
// ============================================================
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
    A = Table.AddColumn(T, "id",      each Record.FieldOrDefault([r], "id", null)),
    B = Table.AddColumn(A, "name",    each Record.FieldOrDefault([r], "name", null)),
    C = Table.AddColumn(B, "display", each Record.FieldOrDefault([r], "display_name", null)),
    D = Table.SelectColumns(C, {"id", "name", "display"})
in
    D
