// ============================================================
// Requête : fnSdpName
// Type    : fonction (Connexion uniquement)
// Les objets lies SDP (status, technician, category...) sont des records
// [id=..., name=...] ou null si non renseigne. Cette fonction evite
// d'ecrire 40 fois "try [x][name] otherwise null" dans les rapports.
// Usage : fnSdpName([r], "technician")
// ============================================================
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
