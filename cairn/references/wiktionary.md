# wiktionary — the lexical check where a national dictionary is out of reach

**Provenance.** Ingested 2026-08-29 by M057 from Wiktionary, retrieved by
`curl` on 2026-08-29 through the MediaWiki API
(`action=query&prop=extracts&explaintext=1`) against
`es.wiktionary.org`, `de.wiktionary.org` and `it.wiktionary.org`.
Pagination: —.
Extraction: verified 2026-08-29 against the retrieved plain-text extracts, each sense read from the entry it is attributed to — observed 2026-08-29.

**Citation.** Wiktionary, the free dictionary — Wikcionario (es), Wiktionary
(de), Wikizionario (it). Wikimedia Foundation, text under CC BY-SA. Entries
cited by headword and by the sense number the entry prints. The Spanish page
for `véase` was read at `oldid=6312243`, last edited 2026-08-12.

**Role.** The lexical half of the two-reference check wherever the language's
national dictionary could not be read:

- **Spanish, every word.** The Real Academia Española's *Diccionario de la
  lengua española* refuses automated requests — `dle.rae.es` and `www.rae.es`
  both answer 403 to every route tried, including the data endpoint the site's
  own search uses — observed 2026-08-29. Wikcionario is the whole Spanish
  lexical leg, which makes Spanish the weakest-sourced of the four rows even
  though it is the row M057's headline case tests. Recorded here rather than
  glossed over.
- **German `auch`.** Duden serves no entry at that headword (`duden.md`).
- **Italian `anche`.** Treccani serves no entry body for either of its two
  `anche` headwords (`treccani.md`).

## Extracted values

Spanish (Wikcionario):

- `véase` — "Segunda persona del singular (usted) del imperativo de verse (con
  el pronombre «se» enclítico)", with the usage note "se usa también como
  impersonal". The impersonal imperative is the cross-reference formula.
- `índice`, sense 3 — "Lista o enumeración breve, por orden, de libros,
  capítulos, o cosas notables."
- `alfabético` — "Que pertenece o concierne al alfabeto, o conforme al orden en
  que se presentan sus letras o símbolos." Read together with `índice`, this is
  what `Índice alfabético` says.
- `símbolo`, sense 2 — "Letra o figura empleada para representar algo."; the
  entry prints the plural as `símbolos`.
- `también`, sense 2 — "Usado para añadir algo a lo anteriormente mencionado."

German (de.wiktionary):

- `auch`, sense 1 — "und ferner". The entry's "Charakteristische
  Wortkombinationen" list names `siehe auch` outright, so it attests the whole
  phrase this repo ships and not only the word.

Italian (it.wiktionary):

- `anche` — the conjunction, glossed "perfino" and, by extension, "con
  significato di continuità"; among its synonyms "pure, pur, e, ed, inoltre".

## Traces to

- `cairn/references/index-words-by-language.md` — the lexical column of the
  four Spanish rows, the German `siehe auch` row, and the Italian
  `vedi anche` row of the per-word ledger.
- `_extensions/index/modules/languages.lua` — those rows, indirectly, through
  that ledger.

## Open questions

- Whether the Spanish row should be re-checked against the RAE by hand, since
  no automated route reaches it. A hand check would raise the Spanish row to
  the authority the other three already have — observed 2026-08-29.
