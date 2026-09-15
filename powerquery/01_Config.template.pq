// ============================================================
// Query : Config
// Type  : record query (Connection only)
// Role  : single source of truth for everything environment-specific.
//         No other query may contain a URL or a constant.
//
// THIS FILE IS A TEMPLATE, VERSIONED AND PUBLIC.
// It must contain NO real value: no hostname, no network path, no internal
// custom field name.
//
// Real values live in 01_Config.local.pq, ignored by git.
// In Excel there is ONE query named "Config": paste the content of your
// .local version into it. This template documents the structure.
// ============================================================
[
    // --- REST API ---------------------------------------------------------
    // IMPORTANT: must stay a LITERAL CONSTANT. Power Query records it as
    // the "data source". Trailing slash required so RelativePath appends.
    ApiBaseURL   = "https://sdp.example.local/api/v3/",

    // Page size. SDP default is 100. 500 divides the number of calls by 5
    // on CMDB / assets. Some builds silently cap at 100: check the row
    // count after changing.
    PageSize     = 100,

    // --- Web UI (to build links to tickets / assets / CIs) ----------------
    // DO NOT GUESS: open an object in the browser and copy the real URL.
    WebBaseURL   = "https://sdp.example.local",

    // Ticket. Known forms depending on version:
    //   legacy : /WorkOrder.do?woMode=viewWO&woID=12345
    //   new    : /app/itdesk/ui/requests/12345/details
    TicketUrlFmt = "/WorkOrder.do?woMode=viewWO&woID=",   // & id
    TicketUrlSuf = "",
    // TicketUrlFmt = "/app/itdesk/ui/requests/",
    // TicketUrlSuf = "/details",

    // Asset. Same rule: copy from the browser.
    //   legacy : /ViewAsset.do?assetId=123
    //   new    : /app/itdesk/ui/assets/123/details
    AssetUrlFmt  = "/ViewAsset.do?assetId=",
    AssetUrlSuf  = "",

    // CI (CMDB). Template with {type} = URL ci_type and {id} = CI id.
    CiUrlFmt     = "/ui/cmdb_module?ci_type={type}&mode=details&ciid={id}#details",
    // API module.name -> URL ci_type. They differ, and are not even
    // consistent with each other. Module missing here: fallback = name + "s".
    CiUrlTypeMap = {
        { "cmdb_physicalserver",  "cmdb_physicalservers" },
        { "cmdb_virtual_server",  "cmdb_virtual_servers" }
    },

    // --- Network folders --------------------------------------------------
    FolderRoot   = "\fileserver",
    FolderPrefix = "ID_",
    // Ticket folders are bucketed: 12345 -> \fileserver\ID_12000_TO_12999\ID_12345
    FolderBucketSize = 1000,
    FolderPadWidth   = 5,                 // bounds on 5 digits: 00000_TO_00999
    FolderBucketFmt  = "ID_{lo}_TO_{hi}", // copy the REAL bucket folder name,
                                          // replacing the numbers with {lo} / {hi}

    // --- Ticket filter ----------------------------------------------------
    // SDP view name. If the API rejects the name, use its id.
    // See 90_Dx_Filters.pq to list them.
    TicketFilterName = "MY_VIEW",
    TicketFilterId   = null,       // set this if the name is rejected

    // --- Asset filter (client side: /assets ignores search_criteria) -------
    // Product type labels to keep, case-insensitive. Empty = no filter
    // (useful to discover the real labels).
    AssetTypeFilter = { "Laptop" },

    // --- Asset custom fields --------------------------------------------
    // Pairs { udf_api_name, column_label }.
    AssetUdfFields = {
        { "udf_example_3", "Example 3" }
    },

    // --- CMDB modules considered as servers (Rpt_CMDBServers) -------------
    // Compared to the internal name AND the display label, case-insensitive.
    CmdbServerModules = { "cmdb_physicalserver", "cmdb_virtual_server" },

    // --- CMDB custom fields ---------------------------------------------
    // Pairs { udf_api_name, column_label }. The CMDB report loops over this
    // list: adding a UDF = adding a line here, no report code to touch.
    CmdbUdfFields = {
        { "udf_example_1", "Example 1" },
        { "udf_example_2", "Example 2" }
    },

    // --- Performance guard -----------------------------------------------
    // Max number of tickets for which worklogs are fetched.
    // Set 25 while developing, otherwise each try costs minutes.
    WorklogTicketLimit = null      // null = all
]
