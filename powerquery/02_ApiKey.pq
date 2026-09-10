// ============================================================
// Requête : ApiKey
// Type    : requête texte (Connexion uniquement)
// ============================================================
//
// TROIS OPTIONS, de la pire a la meilleure.
//
// --- Option A : en dur (ce que tu fais aujourd'hui) -------------------
// La cle technicien part avec le fichier. Quiconque recoit le .xlsx
// obtient tes droits sur ServiceDesk. A eviter des que le classeur circule.
//
//   "XXXXXXXXXXXXXXXX"
//
// --- Option B : parametre de requete ---------------------------------
// Donnees > Obtenir des donnees > Autres sources > Requete vide,
// puis Gerer les parametres. Plus propre a maintenir, mais la valeur
// reste stockee en clair dans le classeur. Meme risque qu'en A.
//
// --- Option C : fichier local hors classeur (recommande) -------------
// La cle vit dans un fichier que tu ne partages pas. Le classeur ne
// contient que le chemin. Chaque poste autorise depose son propre fichier.
// Cree C:\SDP\technician.key (une seule ligne, pas de retour a la ligne
// final si possible) et utilise le code ci-dessous.

let
    KeyPath = "C:\SDP\technician.key",
    Raw     = try Text.FromBinary(File.Contents(KeyPath), TextEncoding.Utf8) otherwise null,
    Key     = if Raw = null
              then error Error.Record(
                        "SDP.MissingKey",
                        "Cle technicien introuvable.",
                        "Cree le fichier " & KeyPath & " contenant uniquement la cle technicien SDP."
                   )
              else Text.Trim(Text.Replace(Text.Replace(Raw, "#(cr)", ""), "#(lf)", ""))
in
    Key
