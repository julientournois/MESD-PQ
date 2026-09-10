// ============================================================
// Requête : fnStripHtml
// Type    : fonction (Connexion uniquement)
// Rôle    : nettoyer le HTML des descriptions de worklog / notes SDP.
//
// Limite assumee : ce n'est pas un parseur HTML. Ca supprime les balises,
// convertit les sauts de ligne structurels et decode les entites les plus
// courantes (dont les accentuees francaises). Les entites numeriques exotiques
// (&#8230; etc.) sont ajoutables dans la table Entities ci-dessous.
// ============================================================
(input as any) as nullable text =>
let
    Src = if input = null then null
          else if input is text then input
          else try Text.From(input) otherwise null,

    Result =
        if Src = null or Src = "" then null
        else
            let
                // 1) Balises structurelles -> saut de ligne, AVANT suppression.
                BlockTags = {"<br>", "<br/>", "<br />", "<BR>", "<BR/>",
                             "</p>", "</P>", "</div>", "</DIV>",
                             "</li>", "</tr>", "</h1>", "</h2>", "</h3>"},
                WithBreaks = List.Accumulate(BlockTags, Src,
                    (s, tag) => Text.Replace(s, tag, "#(lf)")),

                // 2) Suppression des balises.
                //    Split sur "<" : le 1er fragment n'est jamais dans une balise.
                //    Un fragment sans ">" signifie un "<" litteral (ex: "a < b").
                Parts   = Text.Split(WithBreaks, "<"),
                Head    = List.First(Parts),
                Tail    = List.Transform(List.Skip(Parts, 1), each
                              if Text.Contains(_, ">")
                              then Text.AfterDelimiter(_, ">")
                              else "<" & _),
                NoTags  = Text.Combine({Head} & Tail),

                // 3) Entites HTML.
                Entities = {
                    {"&nbsp;", " "},   {"&#160;", " "},   {"&#xa0;", " "},
                    {"&lt;", "<"},     {"&gt;", ">"},     {"&quot;", """"},
                    {"&apos;", "'"},   {"&#39;", "'"},    {"&#039;", "'"},
                    {"&#8217;", "’"},  {"&rsquo;", "’"},  {"&lsquo;", "‘"},
                    {"&ldquo;", "«"},  {"&rdquo;", "»"},  {"&hellip;", "…"},
                    {"&#8230;", "…"},  {"&ndash;", "–"},  {"&mdash;", "—"},
                    {"&eacute;", "é"}, {"&egrave;", "è"}, {"&ecirc;", "ê"},
                    {"&euml;", "ë"},   {"&agrave;", "à"}, {"&acirc;", "â"},
                    {"&ccedil;", "ç"}, {"&ugrave;", "ù"}, {"&ucirc;", "û"},
                    {"&icirc;", "î"},  {"&iuml;", "ï"},   {"&ocirc;", "ô"},
                    {"&Eacute;", "É"}, {"&Egrave;", "È"}, {"&Ccedil;", "Ç"},
                    {"&deg;", "°"},    {"&euro;", "€"},   {"&laquo;", "«"},
                    {"&raquo;", "»"},  {"&amp;", "&"}     // &amp; EN DERNIER
                },
                Decoded = List.Accumulate(Entities, NoTags,
                    (s, e) => Text.Replace(s, e{0}, e{1})),

                // 4) Espaces insecables residuels (U+00A0) -> espace normal.
                NoNbsp = Text.Replace(Decoded, Character.FromNumber(160), " "),

                // 5) Normalisation des blancs : lignes trimmees, vides supprimees.
                Lines   = Text.Split(Text.Replace(NoNbsp, "#(cr)", ""), "#(lf)"),
                Trimmed = List.Transform(Lines, each Text.Trim(Text.Replace(_, "#(tab)", " "))),
                Kept    = List.Select(Trimmed, each _ <> ""),
                Joined  = Text.Combine(Kept, "#(lf)")
            in
                if Joined = "" then null else Joined
in
    Result
