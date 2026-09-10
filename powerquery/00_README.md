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
--------------------------------------------------------------------
Rpt_CMDB          table        -> feuille
Rpt_Laptops       table        -> feuille
Rpt_TicketsIT     table        -> feuille
Dx_*              diagnostic   à exécuter à la main quand ça casse
```

Ajouter un rapport = une requête d'une quinzaine de lignes qui appelle
`fnSdpFetch`. Zéro duplication d'URL, de clé ou de pagination.

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
   → `fnStripHtml` → `fnSdpFetch` → les `Rpt_*`.
6. `05_fnHelpers.pq` contient **trois** requêtes séparées par des commentaires.
   Ne colle pas le fichier entier dans une seule requête.

## À faire avant le premier refresh

- [ ] Remplir `01_Config.local.pq` (hôte API, hôte web, partage réseau, vue).
- [ ] `WebBaseURL` + `TicketUrlFmt` : **copie l'URL d'un vrai ticket** depuis
      ton navigateur. Deux formats coexistent selon la version SDP.
- [ ] Créer le fichier de clé technicien (`C:\SDP\technician.key` par défaut).
- [ ] `WorklogTicketLimit = 25` pour les essais.
- [ ] Confidentialité : Données > Requêtes et connexions > Options de requête >
      Confidentialité > **Ignorer les niveaux de confidentialité**.
      Sans ça, `Rpt_TicketsIT` échoue : il injecte l'ID de ticket (issu d'une
      première requête) dans le chemin d'une seconde requête, ce que le
      pare-feu de confidentialité bloque par défaut.

## Les liens cliquables : la vérité

**Power Query ne peut pas produire de lien cliquable.** Il produit du texte.
Il n'existe aucune option M pour ça, et le marquage « Web URL » n'existe qu'en
Power BI. Les colonnes `URL_Ticket` et `Dossier_Reseau` sortent donc en texte.

Trois façons de les rendre cliquables, par ordre de robustesse :

**1. Colonnes de formule adjacentes (recommandé)**
Après chargement du tableau `Rpt_TicketsIT`, dans la première colonne vide à
droite du tableau :

```
=LIEN_HYPERTEXTE([@URL_Ticket]; [@ID])
=LIEN_HYPERTEXTE([@Dossier_Reseau]; "Dossier")
```

Excel conserve et recopie ces colonnes à chaque actualisation (elles font
partie du tableau, pas de la requête). Masque ensuite les deux colonnes texte.
`LIEN_HYPERTEXTE` gère les chemins UNC sans problème.

**2. Office Script / VBA** sur l'événement d'actualisation, qui convertit les
colonnes texte en vrais hyperliens. Plus propre visuellement, mais introduit
une macro (donc un `.xlsm` et des questions de politique de sécurité).

**3. Ne rien faire.** Un chemin UNC en texte reste copiable-collable. C'est
laid mais ça ne casse jamais.

Recommandation : option 1. L'option 2 est le genre de dette qu'on regrette.

## Coût réel du rapport tickets

Un appel HTTP **par ticket** pour récupérer le dernier worklog. Il n'y a pas
d'endpoint global worklogs fiable en v3 on-premise ; c'est une contrainte de
l'API, pas un choix de conception.

| Tickets ouverts | Appels | Durée typique |
|---|---|---|
| 50 | 51 | ~30 s |
| 200 | 201 | 2–4 min |
| 500 | 501 | 5–12 min |

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

Trois choses varient selon le build SDP. `90_Discover.pq` répond aux trois :

1. **`filter_by` par nom vs par id** — selon la version, les vues
   personnalisées ne sont adressables que par `id`. → `Dx_Filters`.
2. **Le champ de date du worklog** : `created_time` dans la plupart des cas,
   `start_time` dans certaines configurations. → `Dx_WorklogSample`.
3. **`fields_required`** sur `/requests` : un build ancien peut renvoyer un
   400. Commenter la ligne suffit, le reste du code est inchangé (juste plus
   lent). → `Dx_RequestFields`.

Le `ManualStatusHandling` de `fnSdpFetch` remonte le message d'erreur **de
SDP** plutôt qu'une erreur Power Query opaque, ce qui rend ces vérifications
rapides.

## Convention de dossier réseau

Le rapport tickets construit `FolderRoot \ FolderPrefix + ID`, soit par défaut
`\\fileserver\ID_12345`. Si la convention réelle diffère (sous-dossier par
année, par technicien, ID complété sur 6 chiffres…), ajuster `FolderPrefix`
dans la config et l'étape `C08` de `10_Rpt_TicketsIT.pq`.
