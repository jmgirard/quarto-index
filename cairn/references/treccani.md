# treccani — the Italian lexical check on this repo's Italian index words

**Provenance.** Ingested 2026-08-29 by M057 from the Treccani *Vocabolario on
line*, retrieved by `curl` on 2026-08-29 from
`https://www.treccani.it/vocabolario/<headword>/` (`vedere`, `indice`,
`simbolo`).
Pagination: —.
Extraction: verified 2026-08-29 against the retrieved pages, each wording read from the sense it is attributed to — observed 2026-08-29.

**Citation.** *Vocabolario on line*, Istituto della Enciclopedia Italiana
fondata da Giovanni Treccani, treccani.it. Entries cited by headword and by
the sense number the entry itself prints.

**Role.** The lexical half of the two-reference check on the Italian row of
M057's word table. It is the strongest of the four lexical references, because
two of its senses describe this extension's exact use rather than merely the
word's meaning.

`anche` is checked through `wiktionary.md` instead: Treccani splits the
headword across `anche1` and `anche2`, and neither page's entry body is served
to an automated request.

## Extracted values

- `vedere`, sense 1 b — the cross-reference use, stated as such: "vedi (abbrev.
  v., seguito da opportune indicazioni), in rinvii, per invitare il lettore a
  confrontare altri passi dell'opera stessa o di altra opera a stampa". This is
  the imperative `vedi` used in a cross-reference (`in rinvii`) to send the
  reader elsewhere in the same work — which is what this extension's `see`
  label does.
- `ìndice`, sense 2 a — the entry defines the compound this repo ships, not
  just the noun: "i. analitico, quello che, per ciascun esponente elencato,
  rinvia a tutte le pagine in cui si parla di quella persona o di quel luogo o
  di quell'argomento". An index whose every heading points at all the pages
  discussing it is exactly what this extension generates.
- `sìmbolo`, sense 3 — "Segno grafico, lettera o gruppo di lettere, assunti per
  convenzione in varie discipline a indicare determinati elementi, enti,
  grandezze, strumenti, operazioni e sim." The plural the entry prints for the
  headword is `simboli`.

## Traces to

- `cairn/references/index-words-by-language.md` — the lexical column of the
  four Italian rows of the per-word ledger.
- `_extensions/index/modules/languages.lua` — the Italian row, indirectly,
  through that ledger.

## Open questions

- Whether `Indice analitico` or `Indice` is the commoner heading in Italian
  printing. Treccani settles what `indice analitico` means, not which of the
  two a publisher prefers; babel's choice is what breaks the tie, and it is the
  string the same document's PDF already prints — observed 2026-08-29.
