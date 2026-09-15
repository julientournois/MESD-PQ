// ============================================================
// Requête : Rpt_TicketsIT   (charger dans une feuille)
// Rôle    : tickets ouverts d une vue SDP (Config[TicketFilterName]) + dernier worklog.
//
// ATTENTION PERFORMANCE : un appel HTTP par ticket pour les worklogs.
// Pendant la mise au point, mets Config[WorklogTicketLimit] = 25.
// ============================================================
let
    // ---------- 1. Les tickets -------------------------------------------
    // filter_by accepte le nom de la vue, ou son id selon le build.
    // Config decide lequel est utilise.
    FilterBy =
        if Config[TicketFilterId] <> null
        then [ id = Config[TicketFilterId] ]
        else [ name = Config[TicketFilterName] ],

    ListInfo = [
        filter_by  = FilterBy,
        sort_field = "id",
        sort_order = "desc",
        // fields_required reduit fortement le volume transfere.
        // Si ton build renvoie un 400 "invalid field", COMMENTE cette ligne :
        // tu recevras tout l'enregistrement, le reste du code fonctionne pareil.
        fields_required = {
            "id", "subject", "status", "technician",
            "category", "subcategory", "created_time", "last_updated_time"
        }
    ],

    Raw = fnSdpFetch("requests", ListInfo, "requests"),

    Base0 = Table.FromList(Raw, Splitter.SplitByNothing(), {"r"}),

    // Limitation optionnelle (mise au point uniquement)
    Base = if Config[WorklogTicketLimit] = null
           then Base0
           else Table.FirstN(Base0, Config[WorklogTicketLimit]),

    // ---------- 2. Colonnes plates ---------------------------------------
    C01 = Table.AddColumn(Base, "ID",           each Text.From([r][id]), type text),
    C02 = Table.AddColumn(C01,  "Sujet",        each fnStripHtml(Record.FieldOrDefault([r], "subject", null)), type text),
    C03 = Table.AddColumn(C02,  "Technicien",   each fnSdpName([r], "technician"), type text),
    C04 = Table.AddColumn(C03,  "Statut",       each fnSdpName([r], "status"), type text),
    C05 = Table.AddColumn(C04,  "Categorie",    each fnSdpName([r], "category"), type text),
    C06 = Table.AddColumn(C05,  "SousCategorie",each fnSdpName([r], "subcategory"), type text),

    // ---------- 3. Liens (texte : voir README pour rendre cliquable) -----
    C07 = Table.AddColumn(C06, "URL_Ticket", each
              Config[WebBaseURL] & Config[TicketUrlFmt] & [ID] & Config[TicketUrlSuf],
              type text),
    C08 = Table.AddColumn(C07, "Dossier_Reseau", each fnTicketFolder([ID]), type text),

    // Buffer AVANT la boucle worklogs : evite que Power Query re-evalue
    // la liste des tickets a chaque ligne (sinon N appels deviennent N x N).
    Buffered = Table.Buffer(C08),

    // ---------- 4. Dernier worklog ---------------------------------------
    // Un appel par ticket. On recupere tous les worklogs (ils sont peu
    // nombreux) et on choisit le plus recent en M : aucune dependance au
    // support du tri cote serveur.
    //
    // Un echec d'appel N'EST PAS avale : il est distingue d'un ticket sans
    // worklog. Sinon une cle expiree ou un SDP indisponible produirait un
    // rapport "propre" avec des trous invisibles.
    W01 = Table.AddColumn(Buffered, "_wl", each
              try fnSdpFetch(
                      "requests/" & [ID] & "/worklogs",
                      [ fields_required = {"id", "description", "created_time", "owner"} ],
                      "worklogs"
                  )),

    W02 = Table.AddColumn(W01, "_last", each
              if [_wl][HasError] then
                  [ dt = null,
                    desc = "ERREUR APPEL WORKLOGS : "
                         & (try [_wl][Error][Message] otherwise "?")
                         & " -- "
                         & (try Text.From([_wl][Error][Detail]) otherwise ""),
                    err = true ]
              else
                  let
                      Items  = [_wl][Value],
                      Mapped = List.Transform(Items, each [
                          dt   = fnSdpDate(Record.FieldOrDefault(_, "created_time", null)),
                          desc = Record.FieldOrDefault(_, "description", null),
                          err  = false
                      ]),
                      Dated  = List.Select(Mapped, each [dt] <> null),
                      Sorted = List.Sort(Dated, {each [dt], Order.Descending})
                  in
                      if List.IsEmpty(Sorted)
                      then (if List.IsEmpty(Mapped) then null else List.Last(Mapped))
                      else List.First(Sorted)),

    W03 = Table.AddColumn(W02, "Date_Dernier_Worklog", each
              if [_last] = null then null else [_last][dt], type datetime),

    // En cas d'erreur, le message brut est ecrit tel quel (pas de nettoyage
    // HTML) pour rester lisible et filtrable sur "ERREUR".
    W04 = Table.AddColumn(W03, "Dernier_Worklog", each
              if [_last] = null then null
              else if [_last][err] then [_last][desc]
              else fnStripHtml([_last][desc]), type text),

    // ---------- 5. Sortie -------------------------------------------------
    Final = Table.SelectColumns(W04, {
        "ID",
        "URL_Ticket",
        "Dossier_Reseau",
        "Technicien",
        "Sujet",
        "Statut",
        "Categorie",
        "SousCategorie",
        "Date_Dernier_Worklog",
        "Dernier_Worklog"
    })
in
    Final
