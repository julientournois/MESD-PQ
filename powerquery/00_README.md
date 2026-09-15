# Rapports Excel / Power Query sur ServiceDesk Plus on-premise (API v3)

Structure réutilisable pour produire des rapports Excel à partir de l'API REST
v3 de ManageEngine ServiceDesk Plus **on-premise**, sans dupliquer la logique
d'authentification, de pagination ou de gestion d'erreurs.

## Principe

Power Query n'a pas de modules. La segmentation se fait par **requêtes nommées** :
une requête = un fichier ici. Les fonctions et la config sont en
« Connexion uniquement » ; seuls les rapports se chargent dans une feuille.

```
Config            record       toutes les constantes d'environnement
ApiKey            texte        la clé technicien (hors classeur, cf. option C)
fnSdpFetch        fonction     LE seul appelant HTTP : auth, pagination, erreurs
fnStripHtml       fonction     nettoyage HTML des worklogs / descriptions
fnEpochToDateTime fonction     epoch ms -> datetime local
fnSdpDate         fonction     record de date SDP -> datetime local
fnSdpName         fonction     record lié [id,name] -> texte
fnSdpUdf          fonction     champ personnalisé -> texte
fnCmdbTable       fonction     la CMDB mise en forme, source des Rpt_CMDB*
fnTicketFolder    fonction     id ticket -> chemin UNC par tranche
fnTicketsTable    fonction     le rapport tickets, parametre par le filtre
fnSdpGet          fonction     GET brut d'un objet sans input_data (UDF des tickets)
--------------------------------------------------------------------
Rpt_CMDB          table        -> feuille
Rpt_CMDBServers   table        -> feuille (modules serveurs seulement)
Rpt_Laptops       table        -> feuille
Rpt_TicketsIT     table        -> feuille (vue de Config)
Rpt_TicketsExample  modele     a copier pour un autre filtre
Dx_Filters, Dx_RequestFields, Dx_WorklogSample, Dx_Raw, Dx_Request   diagnostic manuel
```

Ajouter un rapport = une requête de quelques lignes. Un rapport tickets avec
un autre filtre : copier `24_Rpt_TicketsExample.pq` et changer le `filter_by`.
Un rapport sur un autre endpoint : appeler `fnSdpFetch` et mettre en forme.
Zéro duplication d'URL, de clé, de pagination ou de logique de colonnes.

## Langue

Le code (commentaires, noms de colonnes, messages d'erreur) est **en
anglais**. Ce README reste en français.

## Configuration : template vs local

`01_Config.template.pq` est **public et générique**. Il ne contient aucune
valeur réelle.

Les vraies valeurs (nom d'hôte, partage réseau, nom de vue, noms des champs
personnalisés) vont dans **`01_Config.local.pq`**, ignoré par git
(`*.local.pq` dans `.gitignore`). C'est ce contenu-là que tu colles dans la
requête `Config` du classeur.

Dans Excel il n'y a qu'**une seule** requête nommée `Config`. Le template ne
sert que de référence de structure et de documentation.

## Installation

1. Excel > Données > Obtenir des données > **Autres sources > Requête vide**.
2. Éditeur avancé : coller le contenu du fichier.
3. Renommer la requête **exactement** comme indiqué en tête de fichier
   (les noms sont référencés dans le code : une faute de casse casse tout).
4. Clic droit sur la requête > décocher **Activer le chargement** pour tout
   ce qui n'est pas `Rpt_*`.
5. Ordre de création imposé par les dépendances :
   `Config` → `ApiKey` → `fnEpochToDateTime` → `fnSdpDate` → `fnSdpName`
   → `fnSdpUdf` → `fnStripHtml` → `fnSdpFetch` → `fnCmdbTable` → `fnTicketFolder` → `fnSdpGet` → `fnTicketsTable` → les `Rpt_*`.
6. **Un fichier = une requête, sans exception.** Le nom à donner est en
   tête de chaque fichier (`// Requête : ...`).

## À faire avant le premier refresh

- [ ] Remplir `01_Config.local.pq` (hôte API, hôte web, partage réseau, vue).
- [ ] `WebBaseURL` + `TicketUrlFmt` : **copie l'URL d'un vrai ticket** depuis
      ton navigateur. Deux formats coexistent selon la version SDP.
- [ ] Créer le fichier de clé technicien (`C:\SDP\technician.key` par défaut).
- [ ] `WorklogTicketLimit = 25` pour les essais.
- [ ] **Pare-feu de confidentialité — obligatoire, sinon RIEN ne fonctionne.**
      Données > Obtenir des données > Options de requête > *Classeur actuel* >
      Confidentialité > **Ignorer les niveaux de confidentialité**.

      Pourquoi : `ApiKey` lit un fichier (`File.Contents`) et `fnSdpFetch`
      appelle l'API (`Web.Contents`). Deux sources combinées dans une même
      évaluation = erreur `Formula.Firewall` (« la requête fait référence à
      d'autres requêtes ou étapes, elle ne peut donc pas accéder directement
      à une source de données »). Le réglage désactive ce contrôle pour ce
      classeur uniquement.

      Si l'erreur persiste : Paramètres de la source de données > sélectionner
      l'hôte SDP et le dossier de la clé > **Effacer les autorisations**, puis
      actualiser (répondre *Anonyme* pour l'API : l'auth passe par le header).

      Alternative sans ce réglage : mettre la clé dans un paramètre de requête
      (option B de `02_ApiKey.pq`). Une seule source = pas de pare-feu, mais
      clé en clair dans le classeur.

## Les liens cliquables

**Power Query ne peut pas produire de lien cliquable.** Il produit du texte.
Il n'existe aucune option M pour ça, et le marquage « Web URL » n'existe qu'en
Power BI. Les colonnes `TicketURL` et `NetworkFolder` sortent donc en texte,
et les liens sont fabriqués **dans le tableau Excel**, par des colonnes
calculées. Vérifié : elles survivent au refresh.

### Mise en place (Excel anglais)

1. Sur la feuille de `Rpt_TicketsIT`, clique dans la première cellule vide à
   droite de la ligne d'en-tête du tableau. Tape `Ticket`, Entrée : le
   tableau s'étend d'une colonne.
2. Dans la cellule dessous : `=HYPERLINK([@TicketURL], [@ID])`. Excel propage
   la formule à toute la colonne.
3. Une colonne plus à droite, en-tête `Dossier`, formule
   `=HYPERLINK([@NetworkFolder], "Dossier " & [@ID])`.
4. Déplace les deux colonnes où tu veux dans le tableau : sélection de la
   colonne du tableau (clic sur son en-tête), curseur sur le bord de la
   sélection, **Maj + glisser**. Elles n'ont pas à rester à droite.
5. Regroupe les colonnes sources `ID`, `TicketURL`, `NetworkFolder`
   (sélection des lettres de colonnes › Data › Group) : elles restent
   disponibles d'un clic sur le `+`, sans encombrer la vue. Ne les supprime
   pas de la requête, les formules en dépendent.

Excel français : `LIEN_HYPERTEXTE` et `;` comme séparateur.

Même principe sur `Rpt_Laptops` avec la colonne `AssetURL` :
`=HYPERLINK([@AssetURL], [@Name])`. Le format de l'URL d'une fiche asset est
dans `Config[AssetUrlFmt]` / `AssetUrlSuf` — à copier depuis le navigateur,
il varie selon la version de SDP.

Et sur `Rpt_CMDB` / `Rpt_CMDBServers` avec `CiURL` :
`=HYPERLINK([@CiURL], [@Name])`. `Config[CiUrlFmt]` est un modèle avec `{type}`
(nom interne du module) et `{id}`, car l'URL d'un CI dépend des deux.

### Pourquoi ça tient au refresh

Les colonnes calculées font partie du tableau structuré, pas de la requête.
Power Query réécrit uniquement les colonnes qu'il gère ; les autres sont
conservées, à leur position, par la propriété *Preserve column sort/filter/
layout* (clic droit dans le tableau › Table › External Data Properties),
activée par défaut. Si les colonnes disparaissent après un refresh, c'est
cette case qui a été décochée.

### Ce qui casse

- Renommer une colonne dans la requête (`ID` → autre chose) : les formules
  passent en `#REF!`.
- Le double-clic sur une cellule texte qui « crée le lien » : c'est la
  correction automatique d'Excel à la saisie. Ça marche une cellule à la
  fois et ne survit pas au refresh. Ne pas utiliser.

## Coût réel du rapport tickets

Un appel HTTP **par ticket** pour récupérer le dernier worklog. Il n'y a pas
d'endpoint global worklogs fiable en v3 on-premise ; c'est une contrainte de
l'API, pas un choix de conception.

| Tickets ouverts | Appels | Durée typique |
|---|---|---|
| 50 | 51 | ~30 s |
| 200 | 201 | 2–4 min |
| 500 | 501 | 5–12 min |

Mesure réelle (septembre 2026, vue complète, sans limite) : **15 s**. Les
estimations ci-dessus sont donc pessimistes sur cette instance ; elles
restent l'ordre de grandeur à attendre si le volume de tickets ouverts
explose.

Si ça devient insupportable, les leviers, du plus efficace au moins :

1. **Resserrer le filtre** côté SDP (statuts réellement ouverts).
2. **Rafraîchir hors ligne** : refresh planifié la nuit, personne n'attend
   devant l'écran.
3. **Découper** : le rapport sans worklogs (1 appel, instantané) + une requête
   worklogs séparée fusionnée dessus, actualisée moins souvent.
4. Passer par la base SQL de SDP en lecture seule. Beaucoup plus rapide, mais
   non supporté par ManageEngine et cassable à chaque montée de version.
   À n'envisager que si les points 1–3 ne suffisent pas.

## Points d'incertitude assumés

Trois choses varient selon le build SDP. les requêtes `Dx_*` (fichiers `9x_`) répondent aux trois :

1. **`filter_by` par nom vs par id** — selon la version, les vues
   personnalisées ne sont adressables que par `id`. → `Dx_Filters`
   (`/list_view_filters/show_all`, renvoie Name et ID des vues).
2. **Le champ de date du worklog** : `created_time` dans la plupart des cas,
   `start_time` dans certaines configurations. → `Dx_WorklogSample`.
3. **`fields_required`** sur `/requests` : un build ancien peut renvoyer un
   400. Commenter la ligne suffit, le reste du code est inchangé (juste plus
   lent). → `Dx_RequestFields`.

Le `ManualStatusHandling` de `fnSdpFetch` remonte le message d'erreur **de
SDP** plutôt qu'une erreur Power Query opaque, ce qui rend ces vérifications
rapides.

## Convention de dossier réseau

Les dossiers de tickets sont rangés par tranches de `FolderBucketSize`
(1 000), bornes complétées sur `FolderPadWidth` chiffres (5) :

```
\fileserver\ID_12000_TO_12999\ID_12345
\fileserver\ID_00000_TO_00999\ID_7
```

Le nom du dossier de tranche est un modèle dans `Config[FolderBucketFmt]`
(`ID_{lo}_TO_{hi}`) : copie le nom réel d'un dossier depuis l'Explorateur en
remplaçant les nombres par `{lo}` et `{hi}`. Le dossier feuille est
`FolderPrefix` + numéro, sans complément. La construction est dans
`fnTicketFolder`.
