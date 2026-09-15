// ============================================================
// Query : fnTicketFolder
// Type  : function (Connection only)
// Builds the UNC path of a ticket folder, bucketed by ranges.
//
// Driven by Config:
//   FolderRoot        "\\fileserver"
//   FolderBucketSize  1000        -> 12345 falls in bucket 12000..12999
//   FolderPadWidth    5           -> bounds written on 5 digits: 00000, 12999
//   FolderBucketFmt   "ID_{lo}_TO_{hi}"   -> bucket folder name; {lo} and
//                                          {hi} are substituted
//   FolderPrefix      "ID_"       -> leaf folder: ID_12345 (no padding)
//
//   12345 -> \\fileserver\ID_12000_TO_12999\ID_12345
//   7     -> \\fileserver\ID_00000_TO_00999\ID_7
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
