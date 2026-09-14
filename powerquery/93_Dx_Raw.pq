// ============================================================
// Requête : Dx_Raw   (DIAGNOSTIC - Connexion uniquement)
// Appel BRUT, sans fnSdpFetch : renvoie le JSON complet de la premiere
// page pour voir l'enveloppe exacte (response_status, list_info, cle des
// donnees, forme des enregistrements).
//
// Adapte les deux lignes Endpoint / Extra, puis clique sur les records
// dans l'apercu pour naviguer.
// ============================================================
let
    Endpoint = "assets",
    Extra    = [],   // ex : [ search_criteria = [ field = "product.product_type.name", condition = "is", value = "Laptop" ] ]

    // get_total_count : SDP renvoie alors list_info.total_count, a comparer
    // avec le nombre de lignes du rapport pour detecter doublons / manquants.
    Info     = Record.Combine({ Extra, [ row_count = 5, start_index = 1, get_total_count = true ] }),
    Payload  = Text.FromBinary(Json.FromValue([ list_info = Info ])),
    Response = Web.Contents(Config[ApiBaseURL], [
        RelativePath = Endpoint,
        Query        = [ input_data = Payload ],
        Headers      = [
            #"Accept"         = "application/vnd.manageengine.sdp.v3+json",
            #"TECHNICIAN_KEY" = ApiKey
        ],
        ManualStatusHandling = {400, 401, 403, 404, 405, 500, 503}
    ]),
    Status   = Value.Metadata(Response)[Response.Status]?,
    Body     = Json.Document(Response),
    // Liste a plat de tous les chemins de champs du 1er enregistrement
    // (ex: "udf_fields.udf_sline_609"). Filtre la liste dans l'apercu pour
    // savoir OU vit un champ.
    DataKey  = List.First(List.Select(Record.FieldNames(Body),
                   each not List.Contains({"response_status","list_info"}, _)), null),
    FirstRec = if DataKey = null then null
               else let v = Record.Field(Body, DataKey)
                    in if v is list then List.First(v, null) else v,
    Paths    = (R as any, prefix as text) as list =>
        if not (R is record) then {}
        else List.Combine(List.Transform(Record.FieldNames(R), each
                 let full = if prefix = "" then _ else prefix & "." & _,
                     v    = Record.Field(R, _)
                 in  if v is record then {full} & @Paths(v, full) else {full})),
    ChampsPremierEnregistrement = if FirstRec = null then {} else Paths(FirstRec, ""),

    Summary  = [
        HttpStatus      = Status,
        CleDonnees      = DataKey,
        ChampsPremierEnregistrement = ChampsPremierEnregistrement,
        PremierEnregistrement       = FirstRec,
        InputDataEnvoye = Payload,
        ClesReponse     = Text.Combine(Record.FieldNames(Body), ", "),
        ResponseStatus  = Record.FieldOrDefault(Body, "response_status", null),
        ListInfo        = Record.FieldOrDefault(Body, "list_info", null),
        Body            = Body
    ]
in
    Summary
