// ============================================================
// Requête : fnSdpFetch
// Type    : fonction (Connexion uniquement)
// Rôle    : LE seul endroit du classeur qui parle HTTP.
//           Pagination, auth, erreurs, detection de la cle de donnees.
//
// Usage :
//   fnSdpFetch("cmdb", null, null)
//   fnSdpFetch("assets", [search_criteria = [...]], "assets")
//   fnSdpFetch("requests/12345/worklogs", null, "worklogs")
//
// Retour : liste de records (JSON brut, non aplati). L'aplatissement
//          est la responsabilite de la requete de rapport.
// ============================================================
(
    endpoint as text,
    optional listInfo as nullable record,
    optional dataKey as nullable text
) as list =>
let
    BaseURL  = Config[ApiBaseURL],
    PageSize = Config[PageSize],
    Extra    = if listInfo = null then [] else listInfo,

    GetPage = (startIndex as number) as record =>
        let
            // Record.Combine : la derniere occurrence gagne.
            //  - un tri par defaut sur "id" : sans ordre STABLE, SDP pagine
            //    n'importe comment (doublons en page N, lignes manquantes en
            //    page N+1). L'appelant peut le remplacer via listInfo.
            //  - row_count / start_index sont imposes en dernier : l'appelant
            //    ne peut pas casser la pagination.
            Info = Record.Combine({
                [ sort_field = "id", sort_order = "asc" ],
                Extra,
                [ row_count = PageSize, start_index = startIndex ]
            }),

            Payload = Text.FromBinary(Json.FromValue([ list_info = Info ])),

            // URL de base STATIQUE + RelativePath : indispensable pour que le
            // rafraichissement planifie fonctionne et pour ne pas re-demander
            // les identifiants a chaque ouverture.
            Response = Web.Contents(BaseURL, [
                RelativePath = endpoint,
                Query        = [ input_data = Payload ],
                Headers      = [
                    #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
                    #"TECHNICIAN_KEY" = ApiKey
                ],
                ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
            ]),

            Status = Value.Metadata(Response)[Response.Status]?,

            Body = if Status <> null and Status >= 400 then
                       error Error.Record(
                           "SDP.HttpError",
                           "HTTP " & Text.From(Status) & " sur /" & endpoint,
                           // le corps SDP contient le vrai motif (champ inconnu,
                           // filtre inexistant, cle invalide...)
                           try Text.FromBinary(Response) otherwise "(corps illisible)"
                       )
                   else Json.Document(Response),

            // Detection de la cle porteuse des donnees : "cmdb", "assets",
            // "requests", "worklogs"... On exclut les cles d'enveloppe.
            Envelope = {"response_status", "list_info", "search_criteria"},
            Keys     = Record.FieldNames(Body),
            Resolved = if dataKey <> null then dataKey
                       else List.First(List.Select(Keys, each not List.Contains(Envelope, _)), null),

            // Cle demandee explicitement mais absente : on ECHOUE, on ne
            // renvoie pas une table vide en silence.
            Rows = if Resolved = null then {}
                   else if not Record.HasFields(Body, Resolved) then
                       error Error.Record(
                           "SDP.DataKeyNotFound",
                           "La cle \"" & Resolved & "\" est absente de la reponse de /" & endpoint,
                           "Cles presentes : " & Text.Combine(Keys, ", ")
                         & "  |  response_status : "
                         & (try Text.FromBinary(Json.FromValue(Body[response_status])) otherwise "?")
                       )
                   else
                       let v = Record.Field(Body, Resolved)
                       in  if v is list then v else {v},

            HasMore = try Body[list_info][has_more_rows] otherwise false
        in
            [ Rows = Rows, HasMore = HasMore, Next = startIndex + PageSize ],

    // Pagination pilotee par has_more_rows : aucun appel superflu.
    Pages = List.Generate(
        () => [ P = GetPage(1) ],
        each [P] <> null,
        each if [P][HasMore] then [ P = GetPage([P][Next]) ] else [ P = null ],
        each [P][Rows]
    ),

    Result = List.Combine(Pages)
in
    Result
