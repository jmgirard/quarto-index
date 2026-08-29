# The four index words, per language, against two references each (M057)

**Provenance.** Ingested 2026-08-29 by M057 from the five source notes beside
it — `babel-locale.md`, `cldr-character-labels.md`, `duden.md`, `treccani.md`,
`tlfi.md` and `wiktionary.md` — no source of its own.
Pagination: —.
Extraction: derived — no external source of its own, only as current as its inputs, none re-read since 2026-08-29 — observed 2026-08-29.

**Scope.** This is the ledger behind the word table this extension ships: one
row per word per language, each carrying what the typographic reference gives,
what the lexical reference gives, and whether the two agree closely enough to
ship the word. It is not a summary of any one source — each source has its own
page — and it builds no rule about resolution order, fallback or syntax; those
live in the milestone file and in the module. It is a reference, not an
authority: status lives in `ROADMAP.md`, decisions in `DECISIONS.md`,
architecture in `DESIGN.md`.

**Evidence snapshot.**

- babel locale files for `de`, `es`, `fr`, `it`, `en` — read on disk at
  `~/Library/TinyTeX/texmf-dist/tex/generic/babel/locale/`, TeX Live package
  revision 80042 — observed 2026-08-29.
- CLDR `characterLabels` for the same five locales — retrieved from
  `unicode-org/cldr-json`, package version 48.2.0 — observed 2026-08-29.
- Duden, Treccani, TLFi (via CNRTL) and Wiktionary entries — retrieved by
  `curl`, per the four dictionary source notes — observed 2026-08-29.

## What the four words are

The HTML and EPUB back-ends print four strings no author wrote:

- the heading over entries that file under no ASCII letter, `Symbols` in
  English;
- the label before a `see` cross-reference;
- the label before a `see also` cross-reference;
- the heading of an index the document never declared, `Index` in English.

The LaTeX back-end prints none of them itself — it emits `\see`, `\seealso`
and an untitled `\printindex`, and babel supplies the words — which is why one
document has come out with a French PDF and an English HTML index since the
first release.

## Method

Each word needs two references **of different kinds**, and they must give the
**same string**:

- one **typographic or editorial** reference — babel for the three caption
  words, CLDR for the Symbols heading, which babel does not carry;
- one **lexical** reference — the language's national dictionary where one
  could be read (Duden, Treccani, TLFi), Wiktionary where none could.

babel and CLDR are never paired with each other: babel's own file header names
CLDR among its sources, so the two are not independent.

Two things the references do not settle, decided here and applied to every row
alike:

1. **Capitalization.** The English words this extension prints are
   `Symbols` (a heading, capitalized) and `see` / `see also` (labels,
   lowercase). Dictionaries print lemmas lowercase and CLDR's own casing
   varies by locale, so neither attests a heading's case. Every shipped
   Symbols word therefore takes an initial capital, matching the English
   heading; every shipped cross-reference label takes the source's own
   lowercase form, matching the English labels. Where the two references
   differ only in that initial letter, they are read as agreeing.
2. **Which two-word phrase.** `see also` is one label, not two words looked up
   separately. Its lexical extract is the extract for each of its parts, except
   in German, where Wiktionary attests `siehe auch` as a phrase outright.

## Word ledger — mapped to the rows `languages.lua` ships

Tags: `Ship` — both references give the same string, the word goes in the
table. `Withhold` — they do not, so the word is left out and falls back to
English.

| # | Language | Word | Typographic / editorial | Lexical | Tag |
|---|---|---|---|---|---|
| W-ES1 | Spanish | index heading | babel `index = Índice alfabético` | Wikcionario `índice` sense 3 + `alfabético` | Ship — `Índice alfabético` |
| W-ES2 | Spanish | see | babel `see = véase` | Wikcionario `véase`, impersonal imperative | Ship — `véase` |
| W-ES3 | Spanish | see also | babel `also = véase también` | Wikcionario `véase` + `también` sense 2 | Ship — `véase también` |
| W-ES4 | Spanish | symbols | CLDR `"symbols": "Símbolos"` | Wikcionario `símbolo` sense 2, plural `símbolos` | Ship — `Símbolos` |
| W-FR1 | French | index heading | babel `index = Index` | TLFi `INDEX` II.B.1 | Ship — `Index` |
| W-FR2 | French | see | babel `see = voir` | TLFi `VOIR`, "se reporter à" | Ship — `voir` |
| W-FR3 | French | see also | babel `also = voir aussi` | TLFi `VOIR` + `AUSSI 1` | Ship — `voir aussi` |
| W-FR4 | French | symbols | CLDR `"symbols": "symboles"` | TLFi `SYMBOLE`, plural `symboles` | Ship — `Symboles` (capital per the rule above) |
| W-DE1 | German | index heading | babel `index = Index` | Duden `Index, der` sense 1 | Ship — `Index` |
| W-DE2 | German | see | babel `see = siehe` | Duden `siehe`, a form of `sehen` | Ship — `siehe` |
| W-DE3 | German | see also | babel `also = siehe auch` | de.wiktionary `auch`, which names `siehe auch` | Ship — `siehe auch` |
| W-DE4 | German | symbols | CLDR `"symbols": "Zeichen"` | Duden headword `Symbol`, plural `Symbole` | Withhold — two different strings |
| W-IT1 | Italian | index heading | babel `index = Indice analitico` | Treccani `ìndice` 2 a, which defines `i. analitico` | Ship — `Indice analitico` |
| W-IT2 | Italian | see | babel `see = vedi` | Treccani `vedere` 1 b, `vedi` "in rinvii" | Ship — `vedi` |
| W-IT3 | Italian | see also | babel `also = vedi anche` | Treccani `vedere` 1 b + it.wiktionary `anche` | Ship — `vedi anche` |
| W-IT4 | Italian | symbols | CLDR `"symbols": "Simboli"` | Treccani `sìmbolo` 3, plural `simboli` | Ship — `Simboli` |

W-DE4 is the one withheld word, and it is withheld on the rule rather than on
a judgement about German: CLDR heads the category `Zeichen`, while the German
word a dictionary gives for *symbol* is `Symbol`, plural `Symbole`. Those are
two different strings, and this repo has no standing to pick between them in a
language its maintainer does not read. A German document therefore prints
three German words and the English `Symbols`, which is the partly-covered
state the design already expects.

English is not a row of the table. Its four words stay where they have always
been printed, and the table is only ever consulted after they are not enough.

## Disposition

- Every `Ship` row lands in `_extensions/index/modules/languages.lua`, in the
  row for its language.
- `W-DE4` lands nowhere: the German row ships three keys, and the fourth falls
  through to the English word at the printing site.
- The choice to author this table rather than read pandoc's translation files
  or shell out to `pandoc` at render time is `D-035`, taken before this page
  existed; nothing here reopens it.
- The tests that lock these strings are the fixture manifests in
  `tests/run-tests.sh` under the M057 heading — each shipped word appears in a
  manifest row derived by hand from this ledger, never from a render.

## Open questions

- The Spanish row rests on Wikcionario alone for its lexical half, because the
  RAE refuses automated requests, and Spanish is the language M057's headline
  case tests. A hand check against the RAE would settle it — observed
  2026-08-29.
- No row has been checked against a published book's index in that language.
  The references say what the words mean and what typesetting uses them; none
  of them is evidence about what a given publisher prints — observed
  2026-08-29.
