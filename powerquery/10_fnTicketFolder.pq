// ============================================================
// Requête : fnTicketFolder
// Type    : fonction (Connexion uniquement)
// Construit le chemin UNC du dossier d'un ticket. Les dossiers sont
// ranges par tranches de Config[FolderBucketSize] :
//     12345  ->  \fileserver\ID_10000_TO_19999\ID_12345
//     7      ->  \fileserver\ID_0_TO_9999\ID_7
//     20000  ->  \fileserver\ID_20000_TO_29999\ID_20000
// Hypothese : bornes non completees par des zeros (ID_0_TO_9999, pas
// ID_00000_TO_09999). Si c'est faux, adapter Pad ci-dessous.
// ============================================================
(ticketId as any) as nullable text =>
let
    N = try Number.From(ticketId) otherwise null,
    R = if N = null then null
        else
            let
                Size   = Config[FolderBucketSize],
                Prefix = Config[FolderPrefix],
                Lower  = Number.RoundDown(N / Size) * Size,
                Upper  = Lower + Size - 1,
                Pad    = (x as number) as text => Text.From(x),
                Bucket = Prefix & Pad(Lower) & "_TO_" & Pad(Upper),
                Leaf   = Prefix & Text.From(N)
            in
                Config[FolderRoot] & "\" & Bucket & "\" & Leaf
in
    R
