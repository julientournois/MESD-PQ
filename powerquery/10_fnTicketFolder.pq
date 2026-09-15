// ============================================================
// Requête : fnTicketFolder
// Type    : fonction (Connexion uniquement)
// Construit le chemin UNC du dossier d'un ticket, range par tranches.
//
// Pilote par Config :
//   FolderRoot        "\fileserver"
//   FolderBucketSize  1000        -> 12345 est dans la tranche 12000..12999
//   FolderPadWidth    5           -> bornes ecrites sur 5 chiffres : 00000, 12999
//   FolderBucketFmt   "ID_{lo}_TO_{hi}"   -> nom du dossier de tranche ;
//                                          {lo} et {hi} sont remplaces
//   FolderPrefix      "ID_"       -> dossier feuille : ID_12345 (sans zeros)
//
//   12345 -> \fileserver\ID_12000_TO_12999\ID_12345
//   7     -> \fileserver\ID_00000_TO_00999\ID_7
// ============================================================
(ticketId as any) as nullable text =>
let
    N = try Number.From(ticketId) otherwise null,
    R = if N = null then null
        else
            let
                Size   = Config[FolderBucketSize],
                Width  = Config[FolderPadWidth],
                Lower  = Number.RoundDown(N / Size) * Size,
                Upper  = Lower + Size - 1,
                Pad    = (x as number) as text => Text.PadStart(Text.From(x), Width, "0"),
                Bucket = Text.Replace(Text.Replace(Config[FolderBucketFmt], "{lo}", Pad(Lower)), "{hi}", Pad(Upper)),
                Leaf   = Config[FolderPrefix] & Text.From(N)
            in
                Config[FolderRoot] & "\" & Bucket & "\" & Leaf
in
    R
