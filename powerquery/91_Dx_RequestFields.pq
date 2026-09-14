// ============================================================
// Requête : Dx_RequestFields   (DIAGNOSTIC - Connexion uniquement)
// Montre TOUS les champs reellement renvoyes par ton build sur un ticket.
// Utile pour verifier les noms avant de les mettre dans fields_required.
// ============================================================
let
    Raw    = fnSdpFetch("requests", [ row_count = 1 ], "requests"),
    First  = List.First(Raw, null),
    Fields = if First = null then {} else Record.FieldNames(First),
    T      = Table.FromList(Fields, Splitter.SplitByNothing(), {"Champ"}),
    Typed  = Table.AddColumn(T, "Type", each
                 let v = Record.Field(First, [Champ])
                 in  if v = null then "null"
                     else if v is record then "record : " & Text.Combine(Record.FieldNames(v), ", ")
                     else if v is list then "list"
                     else Text.From(Value.Type(v)))
in
    Typed
