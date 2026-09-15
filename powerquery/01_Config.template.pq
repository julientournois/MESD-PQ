// ============================================================
// Requête : Config
// Type    : requête "record" (Connexion uniquement)
// Rôle    : point unique de vérité pour tout ce qui est environnement.
//           Aucune autre requête ne doit contenir d'URL ou de constante.
//
// CE FICHIER EST UN MODELE, VERSIONNE ET PUBLIC.
// Il ne doit contenir AUCUNE valeur reelle : ni nom d'hote, ni chemin
// reseau, ni nom de champ personnalise interne.
//
// Les vraies valeurs vivent dans 01_Config.local.pq, ignore par git.
// Dans Excel il n'y a qu'UNE seule requete nommee "Config" : tu y colles
// le contenu de ta version .local. Le modele ci-dessous sert de reference
// de structure et de documentation.
// ============================================================
[
    // --- API REST ---------------------------------------------------------
    // IMPORTANT : cette valeur doit rester une CONSTANTE LITTERALE.
    // C'est elle que Power Query enregistre comme "source de donnees".
    // Le slash final est necessaire pour que RelativePath se concatene bien.
    ApiBaseURL   = "https://sdp.example.local/api/v3/",

    // Taille de page. 100 est le defaut SDP. Monter a 500 divise le nombre
    // d'appels par 5 sur la CMDB / les assets. Certains builds plafonnent
    // silencieusement a 100 : verifie le nombre de lignes apres changement.
    PageSize     = 100,

    // --- Interface web (pour construire les liens vers les tickets) -------
    // NE DEVINE PAS ce modele : ouvre un ticket dans ton navigateur et copie
    // l'URL reelle. Les deux formes existantes selon la version :
    //   ancienne : https://<hote>/WorkOrder.do?woMode=viewWO&woID=12345
    //   nouvelle : https://<hote>/app/itdesk/ui/requests/12345/details
    WebBaseURL   = "https://sdp.example.local",
    TicketUrlFmt = "/WorkOrder.do?woMode=viewWO&woID=",   // & id
    TicketUrlSuf = "",
    // Fiche asset. MEME REGLE : ouvre un asset dans le navigateur et copie
    // l'URL. Formes connues selon la version :
    //   ancienne : /ViewAsset.do?assetId=123          (Fmt ci-dessous, Suf "")
    //   nouvelle : /app/itdesk/ui/assets/123/details  (Fmt "/app/itdesk/ui/assets/", Suf "/details")
    AssetUrlFmt  = "/ViewAsset.do?assetId=",
    AssetUrlSuf  = "",
    // Fiche CI (CMDB). Meme regle : copie l'URL depuis le navigateur.
    //   ancienne : /ViewCI.do?ciId=123
    //   nouvelle : /app/itdesk/ui/cmdb/ci/123/details   (a verifier)
    CiUrlFmt     = "/ViewCI.do?ciId=",
    CiUrlSuf     = "",
    // TicketUrlFmt = "/app/itdesk/ui/requests/",
    // TicketUrlSuf = "/details",

    // --- Dossiers reseau --------------------------------------------------
    FolderRoot   = "\\fileserver",
    FolderPrefix = "ID_",
    // Tranches de dossiers : 12345 -> \fileserver\ID_12000_TO_12999\ID_12345
    FolderBucketSize = 1000,
    FolderPadWidth   = 5,                 // bornes sur 5 chiffres : 00000_TO_00999
    FolderBucketFmt  = "ID_{lo}_TO_{hi}", // copie le nom REEL d'un dossier de tranche ici,
                                          // en remplacant les nombres par {lo} et {hi}

    // --- Filtre des tickets ----------------------------------------------
    // Nom de la vue SDP. Si l'API refuse le nom, il faut son id.
    // Voir 90_Dx_Filters.pq pour la lister.
    TicketFilterName = "MY_VIEW",
    TicketFilterId   = null,       // renseigne-le si le nom ne passe pas

    // --- Filtre assets (cote client : search_criteria est ignore par /assets) --
    // Libelles de type de produit a conserver, insensible a la casse.
    // Liste vide = aucun filtre (utile pour decouvrir les libelles reels).
    AssetTypeFilter = { "Laptop" },

    // --- Champs personnalises ASSETS -------------------------------------
    // Meme principe que CmdbUdfFields : paires { nom_api_udf, libelle_colonne }.
    AssetUdfFields = {
        { "udf_example_3", "Exemple 3" }
    },

    // --- Modules CMDB consideres comme serveurs (Rpt_CMDBServers) --------
    // Compare au nom interne ET au libelle, sans casse. Plusieurs variantes
    // possibles = plusieurs entrees.
    CmdbServerModules = { "cmdb_physicalserver", "cmdb_virtualserver" },

    // --- Champs personnalises CMDB ---------------------------------------
    // Liste de paires { nom_api_udf, libelle_colonne }.
    // Le rapport CMDB est generique : il boucle sur cette liste. Ajouter un
    // UDF = ajouter une ligne ici, sans toucher au code du rapport.
    CmdbUdfFields = {
        { "udf_example_1", "Exemple 1" },
        { "udf_example_2", "Exemple 2" }
    },

    // --- Garde-fou performance -------------------------------------------
    // Nombre max de tickets pour lesquels on va chercher les worklogs.
    // Mets 25 pendant la mise au point, sinon chaque essai coute 10 minutes.
    WorklogTicketLimit = null      // null = tous
]
