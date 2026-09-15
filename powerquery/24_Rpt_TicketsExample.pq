// ============================================================
// Query : Rpt_TicketsExample   (template to copy for a new report)
//
// For a new ticket report:
//   1. copy this file, rename the query (Rpt_TicketsXxx)
//   2. change the filter, and the extra columns if any
//   3. load to a worksheet, add the HYPERLINK columns
// Nothing else: base columns, links and worklogs come from fnTicketsTable.
//
// Filter forms accepted by the API (Dx_Filters lists Name and ID):
//   [ name = "My_View" ]     SDP view by API name
//   [ id   = "301" ]         SDP view by id
// If the filter you need does not exist as a view in SDP, create it there:
// faster and more reliable than filtering in M afterwards.
//
// Extra columns: list of [ field, label, kind ], kinds:
//   "text" | "name" | "date" | "udf" | "udfdate"  (see fnTicketsTable)
// ============================================================
let
    Final = fnTicketsTable(
        [ name = "All_Pending_Requests" ],
        {
            [ field = "due_by_time",   label = "DueBy",   kind = "date"    ],
            [ field = "udf_date_2701", label = "RfcDate", kind = "udfdate" ],
            [ field = "group",         label = "Group",   kind = "name"    ]
        }
    )
in
    Final
