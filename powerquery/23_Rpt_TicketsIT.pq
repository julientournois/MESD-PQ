// ============================================================
// Query : Rpt_TicketsIT   (load to a worksheet)
// Tickets of the view defined in Config (TicketFilterName / TicketFilterId).
// All the logic lives in fnTicketsTable.
// ============================================================
let
    FilterBy = if Config[TicketFilterId] <> null
               then [ id = Config[TicketFilterId] ]
               else [ name = Config[TicketFilterName] ],
    Final = fnTicketsTable(FilterBy)
in
    Final
