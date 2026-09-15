// ============================================================
// Query : Rpt_TicketsExample   (template to copy for a new report)
//
// For a new ticket report:
//   1. copy this file, rename the query (Rpt_TicketsXxx)
//   2. change the filter below
//   3. load to a worksheet, add the HYPERLINK columns
// Nothing else: columns, links and worklogs come from fnTicketsTable.
//
// Filter forms accepted by the API:
//   [ name = "My_View" ]     SDP view by name (Dx_Filters lists the names)
//   [ id   = "301" ]         SDP view by id
// If the filter you need does not exist as a view in SDP, create it there:
// faster and more reliable than filtering in M afterwards.
// ============================================================
let
    Final = fnTicketsTable([ name = "All_Pending_Requests" ])
in
    Final
