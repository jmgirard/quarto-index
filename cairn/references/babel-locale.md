# babel-locale — the words LaTeX already prints for an index, per language

**Provenance.** Ingested 2026-08-29 by M057 from the babel locale files
installed with this machine's TinyTeX, read directly off disk at
`~/Library/TinyTeX/texmf-dist/tex/generic/babel/locale/<lang>/babel-<lang>.ini`
(TeX Live package `babel`, revision 80042, catalogue version 26.11).
Pagination: —.
Extraction: verified 2026-08-29 against the installed files, each value read from the line cited below — observed 2026-08-29.

**Citation.** Javier Bezos and Johannes L. Braams, *babel* — localization and
internationalization for LaTeX. CTAN package `babel`; the per-language data
files are `locale/<lang>/babel-<lang>.ini`. Each file states its own version
and date in its `[identification]` block, quoted per language below, and the
file header names its own two data sources: "babel language styles (license
LPPL)" and the "Common Locale Data Repository (license Unicode)".

**Role.** This is the typographic authority behind three of the four words
M057's table ships — the index heading, and the two cross-reference labels.
It is the authority this repo is already bound to in one back-end: the LaTeX
back-end emits `\see`, `\seealso` and an untitled `\printindex`, and babel
supplies the printed words, so a document's PDF prints exactly these strings
today. Matching them in the HTML and EPUB back-ends is what stops one document
from coming out bilingual.

Nothing is copied from babel. The strings are read here, checked against a
lexical reference (see `index-words-by-language.md`), and re-typed into this
repo's own table.

**Note on the two files' independence.** babel's header names CLDR among its
sources, so babel and `cldr-character-labels.md` are not fully independent.
They are never paired as the two references for one word: babel is paired with
a dictionary for the three caption words, and CLDR is paired with a dictionary
for the Symbols heading, which babel does not carry at all.

## Extracted values

Each `[identification]` version and date, then the three `[captions]` values,
quoted as the file prints them:

- Spanish — `version = 1.5`, `date = 2025-11-21`; `index = Índice alfabético`
  (line 39), `see = véase` (line 47), `also = véase también` (line 48).
- French — `version = 1.2`, `date = 2024-11-29`; `index = Index` (line 40),
  `see = voir` (line 48), `also = voir aussi` (line 49).
- German — `version = 1.8`, `date = 2026-02-18`; `index = Index` (line 40),
  `see = siehe` (line 48), `also = siehe auch` (line 49).
- Italian — `version = 1.5`, `date = 2022-09-01`; `index = Indice analitico`
  (line 39), `see = vedi` (line 47), `also = vedi anche` (line 48).
- English — `version = 1.4`, `date = 2025-11-21`; `index = Index` (line 38),
  `see = see` (line 46), `also = see also` (line 47). Recorded as the control:
  these are the three strings this extension has printed since its first
  release, so the English row of the table restates babel rather than
  departing from it.

No babel locale file carries a caption for the heading over entries that file
under no letter. That word comes from `cldr-character-labels.md` instead.

The locale directory holds `de`, `es`, `fr` and `it` and no regional variant of
any of them — no `fr-CA`, no `es-MX` — observed 2026-08-29.

## Traces to

- `_extensions/index/modules/languages.lua` — the `index`, `see` and `see-also`
  words of every row in `LANGUAGE_WORDS`.
- `cairn/references/index-words-by-language.md` — the typographic column of the
  per-word ledger.

## Open questions

- Whether a babel release changes one of these captions, which would put a
  shipped row out of step with what the same document's PDF prints. Nothing
  watches for that; a re-check of this page is the only thing that would catch
  it — observed 2026-08-29.
