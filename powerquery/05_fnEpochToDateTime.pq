// ============================================================
// Requête : fnEpochToDateTime
// Type    : fonction (Connexion uniquement)
// SDP v3 renvoie les dates sous forme [display_value=..., value="1699887600000"]
// ou value = epoch en MILLISECONDES (UTC). Cette fonction convertit value.
// ============================================================
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
