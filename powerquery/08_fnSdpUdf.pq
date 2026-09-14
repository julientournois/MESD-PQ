// ============================================================
// Requête : fnSdpUdf
// Type    : fonction (Connexion uniquement)
// Lit un champ personnalise (udf_fields.<nom>) d'un enregistrement SDP,
// qu'il soit texte brut, nombre, ou objet [id, name].
// Ne plante jamais si le champ est absent : renvoie null.
// Usage : fnSdpUdf([r], "udf_sline_609")
// ============================================================
(rec as any, name as text) as nullable text =>
let
    U = if rec is record then Record.FieldOrDefault(rec, "udf_fields", null) else null,
    V = if U = null then null else Record.FieldOrDefault(U, name, null),
    R = if V = null then null
        else if V is record then
             Record.FieldOrDefault(V, "name",
                 Record.FieldOrDefault(V, "display_value", null))
        else try Text.From(V) otherwise null
in
    R
