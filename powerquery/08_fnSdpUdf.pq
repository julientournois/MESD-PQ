// ============================================================
// Requête : fnSdpUdf
// Type    : fonction (Connexion uniquement)
// Lit un champ personnalise d'un enregistrement SDP, qu'il soit texte brut,
// nombre, ou objet [id, name]. Ne plante jamais : renvoie null si absent.
//
// L'emplacement des UDF varie selon l'entite et le build. On cherche,
// dans l'ordre :
//   1. rec.udf_fields.<nom>          (requests, cmdb)
//   2. rec.<nom>                     (a plat a la racine)
//   3. rec.<n importe quel sous-record>.<nom>   (assets : rec.ci_default_fields)
//      a un niveau de profondeur, puis deux.
// Usage : fnSdpUdf([r], "udf_sline_609")
// ============================================================
(rec as any, name as text) as nullable text =>
let
    ToText = (V as any) as nullable text =>
        if V = null then null
        else if V is record then
             Record.FieldOrDefault(V, "name", Record.FieldOrDefault(V, "display_value", null))
        else try Text.From(V) otherwise null,

    // Cherche <name> dans un record, sinon dans ses sous-records (profondeur max).
    Find = (R as any, depth as number) as any =>
        if not (R is record) then null
        else if Record.HasFields(R, name) then Record.Field(R, name)
        else if depth <= 0 then null
        else
            let
                Subs  = List.Select(Record.FieldValues(R), each _ is record),
                Found = List.Select(List.Transform(Subs, each @Find(_, depth - 1)), each _ <> null)
            in
                List.First(Found, null),

    Direct = if rec is record and Record.HasFields(rec, "udf_fields")
             then Record.FieldOrDefault(rec[udf_fields], name, null)
             else null,

    Value  = if Direct <> null then Direct else Find(rec, 2)
in
    ToText(Value)
