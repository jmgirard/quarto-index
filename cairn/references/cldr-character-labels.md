# cldr-character-labels — the word each language heads a group of symbols with

**Provenance.** Ingested 2026-08-29 by M057 from the Unicode CLDR JSON
distribution, retrieved by `curl` from
`https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-misc-full/main/<lang>/characterLabels.json`
on 2026-08-29; the sibling `package.json` of that directory gives
`"version": "48.2.0"`.
Pagination: —.
Extraction: verified 2026-08-29 against the retrieved JSON, each value read from the `characterLabels.symbols` key of its own file — observed 2026-08-29.

**Citation.** The Unicode Consortium, *Unicode Common Locale Data Repository*,
release 48.2.0, `cldr-misc-full` package, `characterLabels` data. Published
under the Unicode licence. `characterLabels` are the localized names of
character categories — the headings a character picker groups its contents
under.

**Role.** This is the editorial authority behind the fourth word M057's table
ships: the heading over index entries that file under no letter, which this
extension calls `Symbols` in English. No babel locale file carries such a
caption (`babel-locale.md`), and a dictionary can attest a language's word for
*symbol* but not the choice of that word as a category heading. CLDR answers
exactly that question, for a category with the same membership — everything
that is not a letter.

The category is close to this extension's group but not identical: CLDR labels
a character picker's bucket, this extension heads a group of index entries. The
word is what carries over; the heading's capitalization does not, and is this
repo's own (see `index-words-by-language.md`).

## Extracted values

The `symbols` key of each locale's `characterLabels`, quoted as the JSON holds
it:

- Spanish — `"symbols": "Símbolos"`.
- French — `"symbols": "symboles"`.
- German — `"symbols": "Zeichen"`.
- Italian — `"symbols": "Simboli"`.
- English — `"symbols": "symbol"`. Recorded as the control, and it is the one
  that does not match what this extension prints: English CLDR gives the
  singular where the extension's heading has always been the plural `Symbols`.
  That mismatch is why this page is read for the word each language uses and
  never for the form the heading takes.

## Traces to

- `_extensions/index/modules/languages.lua` — the `symbols` word of the
  Spanish, French and Italian rows. The German row ships no `symbols` word;
  `index-words-by-language.md` records why.
- `cairn/references/index-words-by-language.md` — the editorial column of the
  Symbols row of the per-word ledger.

## Open questions

- Whether a later CLDR release changes one of these labels. Nothing watches for
  it; a re-check of this page is what would catch it — observed 2026-08-29.
