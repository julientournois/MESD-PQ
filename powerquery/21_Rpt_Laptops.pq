// ============================================================
// Query : Rpt_Laptops   (load to a worksheet)
//
// FINDING: on this build, search_criteria is only honoured by /requests.
// On /assets it is ignored and EVERYTHING is returned. Filtering therefore
// happens in Power Query, after a full download.
//
// The filter is driven by Config[AssetTypeFilter]:
//   - empty list {}  -> no filter: every asset, with the ProductType column
//                       visible so you can read the real labels
//   - {"Laptop"}     -> keeps only those type(s), case- and space-insensitive
// First run: empty filter, note the labels, then fill them in.
// ============================================================
let
    Raw  = fnSdpFetch("assets", null, "assets"),
    Base = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    // The product type may live in several places depending on the build.
    // Tried in order, first non-null wins.
    fnProductType = (rec as any) as nullable text =>
        let
            P    = if rec is record then Record.FieldOrDefault(rec, "product", null) else null,
            Try1 = if P is record then fnSdpName(P, "product_type") else null,
            Try2 = if Try1 = null then fnSdpName(rec, "product_type") else Try1,
            Try3 = if Try2 = null then fnSdpName(rec, "asset_type") else Try2
        in
            Try3,

    T00 = Table.AddColumn(Base, "ProductType", each fnProductType([r]), type text),

    // ---------- Client-side filter --------------------------------------
    Wanted   = List.Transform(Config[AssetTypeFilter], each Text.Lower(Text.Trim(_))),
    Filtered = if List.IsEmpty(Wanted) then T00
               else Table.SelectRows(T00, each
                        [ProductType] <> null
                        and List.Contains(Wanted, Text.Lower(Text.Trim([ProductType])))),

    // ---------- Columns --------------------------------------------------
    // No org_serial_number: not filled in SDP, replaced by a UDF
    // (declared in Config[AssetUdfFields], hence shown via WithUdf).
    T01 = Table.AddColumn(Filtered, "Name",    each Record.FieldOrDefault([r], "name", null), type text),
    T02 = Table.AddColumn(T01,      "State",   each fnSdpName([r], "state"), type text),
    T03 = Table.AddColumn(T02,      "User",    each fnSdpName([r], "user"), type text),
    T04 = Table.AddColumn(T03,      "Site",    each fnSdpName([r], "site"), type text),
    T05 = Table.AddColumn(T04,      "Product", each fnSdpName([r], "product"), type text),

    // Link to the asset page in SDP (text; HYPERLINK is built in Excel, see README).
    T06 = Table.AddColumn(T05, "ID", each Text.From(Record.FieldOrDefault([r], "id", null)), type text),
    T07 = Table.AddColumn(T06, "AssetURL", each
              if [ID] = null then null
              else Config[WebBaseURL] & Config[AssetUrlFmt] & [ID] & Config[AssetUrlSuf],
              type text),

    // ---------- Custom fields (Config[AssetUdfFields]) -------------------
    // One column per pair { api_name, label }. Explicit lambda (row) => so
    // the loop variable u is not shadowed by the _ of "each".
    WithUdf = List.Accumulate(
        Config[AssetUdfFields],
        T07,
        (tbl, u) => Table.AddColumn(tbl, u{1}, (row) => fnSdpUdf(row[r], u{0}), type text)
    ),

    // Order: identity, product, UDFs (incl. serial number), then status.
    Final = Table.Sort(
        Table.SelectColumns(WithUdf,
            {"ID", "AssetURL", "Name", "ProductType", "Product"}
            & List.Transform(Config[AssetUdfFields], each _{1})
            & {"State", "User", "Site"}
        ),
        {{"Name", Order.Ascending}}
    )
in
    Final

// ------------------------------------------------------------------
// ProductType empty on every row? None of the three paths tried by
// fnProductType matches your build. Open Dx_Raw on "assets", look where
// the type lives in the first record, and add that path to fnProductType.
// ------------------------------------------------------------------
