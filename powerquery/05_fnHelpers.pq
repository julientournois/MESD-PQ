// ============================================================
// Petites fonctions utilitaires. Cree UNE requete par bloc,
// nommee comme indique en commentaire.
// ============================================================


// ------------------------------------------------------------
// Requête : fnEpochToDateTime
// SDP v3 renvoie les dates sous forme [display_value=..., value="1699887600000"]
// ou value = epoch en MILLISECONDES (UTC).
// ------------------------------------------------------------
(value as any) as nullable datetime =>
let
    N = try Number.From(value) otherwise null,
    R = if N = null or N <= 0 then null
        else DateTimeZone.RemoveZone(
                 DateTimeZone.ToLocal(
                     #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)
                     + #duration(0, 0, 0, N / 1000)
                 )
             )
in
    R


// ------------------------------------------------------------
// Requête : fnSdpDate
// Prend le record de date SDP complet et rend un datetime local.
// Tolere : record avec value, record avec display_value seul, null, texte.
// ------------------------------------------------------------
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


// ------------------------------------------------------------
// Requête : fnSdpName
// Les objets lies SDP (status, technician, category...) sont des records
// [id=..., name=...] ou null si non renseigne. Cette fonction evite
// d'ecrire 40 fois "try [x][name] otherwise null" dans les rapports.
// Usage : fnSdpName([r], "technician")
// ------------------------------------------------------------
(rec as any, field as text) as nullable text =>
let
    Sub = if rec is record then Record.FieldOrDefault(rec, field, null) else null,
    Val = if Sub = null then null
          else if Sub is record then
               Record.FieldOrDefault(Sub, "name",
                   Record.FieldOrDefault(Sub, "display_value", null))
          else if Sub is text then Sub
          else try Text.From(Sub) otherwise null
in
    Val
