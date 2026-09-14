// ============================================================
// Requête : fnSdpDate
// Type    : fonction (Connexion uniquement)
// Depend  : fnEpochToDateTime
// Prend le record de date SDP complet et rend un datetime local.
// Tolere : record avec value, record avec display_value seul, null, texte.
// ============================================================
(field as any) as nullable datetime =>
let
    R = if field = null then null
        else if field is record then
            let
                v = Record.FieldOrDefault(field, "value", null),
                d = if v <> null then fnEpochToDateTime(v) else null
            in
                if d <> null then d
                else try DateTime.From(Record.FieldOrDefault(field, "display_value", null)) otherwise null
        else if field is number then fnEpochToDateTime(field)
        else try DateTime.From(field) otherwise null
in
    R
