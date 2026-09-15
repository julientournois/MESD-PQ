// ============================================================
// Requête : Rpt_TicketsIT   (charger dans une feuille)
// Tickets de la vue definie dans Config (TicketFilterName / TicketFilterId).
// Toute la logique est dans fnTicketsTable.
// ============================================================
let
    FilterBy = if Config[TicketFilterId] <> null
               then [ id = Config[TicketFilterId] ]
               else [ name = Config[TicketFilterName] ],
    Final = fnTicketsTable(FilterBy)
in
    Final
