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

    Info     = Record.Combine({ Extra, [ row_count = 5, start_index = 1 ] }),
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
    Summary  = [
        HttpStatus      = Status,
        InputDataEnvoye = Payload,
        ClesReponse     = Text.Combine(Record.FieldNames(Body), ", "),
        ResponseStatus  = Record.FieldOrDefault(Body, "response_status", null),
        ListInfo        = Record.FieldOrDefault(Body, "list_info", null),
        Body            = Body
    ]
in
    Summary
