// ============================================================
// Query : fnStripHtml
// Type  : function (Connection only)
// Role  : clean the HTML out of SDP worklog descriptions / notes.
//
// Known limit: this is not an HTML parser. It removes tags, turns
// structural breaks into newlines and decodes the most common entities
// (including French accented ones). Exotic numeric entities can be added
// to the Entities table below.
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
                // 1) Structural tags -> newline, BEFORE stripping.
                BlockTags = {"<br>", "<br/>", "<br />", "<BR>", "<BR/>",
                             "</p>", "</P>", "</div>", "</DIV>",
                             "</li>", "</tr>", "</h1>", "</h2>", "</h3>"},
                WithBreaks = List.Accumulate(BlockTags, Src,
                    (s, tag) => Text.Replace(s, tag, "#(lf)")),

                // 2) Strip tags.
                //    Split on "<": the first fragment is never inside a tag.
                //    A fragment without ">" means a literal "<" (e.g. "a < b").
                Parts   = Text.Split(WithBreaks, "<"),
                Head    = List.First(Parts),
                Tail    = List.Transform(List.Skip(Parts, 1), each
                              if Text.Contains(_, ">")
                              then Text.AfterDelimiter(_, ">")
                              else "<" & _),
                NoTags  = Text.Combine({Head} & Tail),

                // 3) HTML entities.
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
                    {"&raquo;", "»"},  {"&amp;", "&"}     // &amp; LAST
                },
                Decoded = List.Accumulate(Entities, NoTags,
                    (s, e) => Text.Replace(s, e{0}, e{1})),

                // 4) Residual non-breaking spaces (U+00A0) -> regular space.
                NoNbsp = Text.Replace(Decoded, Character.FromNumber(160), " "),

                // 5) Whitespace normalisation: trimmed lines, empty ones dropped.
                Lines   = Text.Split(Text.Replace(NoNbsp, "#(cr)", ""), "#(lf)"),
                Trimmed = List.Transform(Lines, each Text.Trim(Text.Replace(_, "#(tab)", " "))),
                Kept    = List.Select(Trimmed, each _ <> ""),
                Joined  = Text.Combine(Kept, "#(lf)")
            in
                if Joined = "" then null else Joined
in
    Result
