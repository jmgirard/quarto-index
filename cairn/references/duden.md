# duden — the German lexical check on this repo's German index words

**Provenance.** Ingested 2026-08-29 by M057 from Duden online, retrieved by
`curl` on 2026-08-29 from `https://www.duden.de/rechtschreibung/<headword>`
(`siehe`, `Index`, `Symbol`).
Pagination: —.
Extraction: verified 2026-08-29 against the retrieved pages, each wording read from the entry it is attributed to — observed 2026-08-29.

**Citation.** *Duden — Deutsches Universalwörterbuch*, online edition,
duden.de, Cornelsen Verlag GmbH. Entries cited by headword, since the online
edition paginates nothing.

**Role.** The lexical half of the two-reference check on the German row of
M057's word table. babel supplies the strings (`babel-locale.md`); this page is
what says the German words mean what the English ones they replace mean.

`auch` has no reachable entry at `duden.de/rechtschreibung/auch` — the URL
returns "Die Seite wurde nicht gefunden", and the site's search endpoint
refuses automated requests — so the German lexical check on `siehe auch` uses
`wiktionary.md` for that one word, which also attests the whole phrase
directly.

## Extracted values

- `siehe` — the entry is a cross-reference to the verb, not a sense of its own:
  "Das Stichwort „siehe" ist eine grammatische Form von sehen." The headword
  immediately following it in the entry's own alphabetical strip is
  `siehe dort`, which is the same cross-reference formula with a target.
- `Index, der` — sense 1: "alphabetisches Namen-, Stichwort-, Sachverzeichnis;
  Register", with the example "das Buch wäre mit einem ausführlichen Index
  leichter zu benutzen". This is the back-of-book sense, and the one the table
  ships the word for.
- `Symbol, das` — sense 2: "Formelzeichen; Zeichen", marked
  "Gebrauch: Fachsprache", with the example "ein mathematisches, chemisches,
  logisches Symbol". Recorded because it is what makes the German Symbols
  heading contested rather than settled: the headword is `Symbol`, whose
  plural is `Symbole`, while CLDR's German label for the same category is
  `Zeichen` — two different strings, so no German word for that heading is
  shipped (`index-words-by-language.md`).

## Traces to

- `cairn/references/index-words-by-language.md` — the lexical column of the
  four German rows of the per-word ledger.
- `_extensions/index/modules/languages.lua` — the German row, indirectly,
  through that ledger.

## Open questions

- Nothing here depends on a Duden edition or revision date, because the online
  edition prints none. A re-check would re-read the same three headwords rather
  than compare editions — observed 2026-08-29.
