# M057: A non-English document gets a non-English index

**Status:** done (2026-08-29, PR #57 https://github.com/jmgirard/quarto-index/pull/57)

**Goal:** The four reader-facing words the HTML and EPUB index back-end emits follow the document's declared
`lang:`, against a table this repo authors, with `index-labels:` still winning.

**Outcome:** `modules/languages.lua` holds a per-language word table (es, fr, de, it) and a BCP-47 resolver —
exact tag, then primary subtag, then English, with `_` read as a separator and a malformed or absent value
missing silently. `indexes.lua` consults it in `label()` beneath both author levels and above the English word,
per key, and installs the localized heading into `titles[UNNAMED]` alone, which any declaration discards:
`\makeindex[title={...}]` stays unreached and no localized word can enter LaTeX. German ships three words and
keeps the English `Symbols`. Six fixtures, four `lang:`-removed twins, hand-derived manifests, an eight-entry
ledger classifying every differing `.tex` line, eleven planted defects, and seven `cairn/references/` pages.

**Decisions:** Milestone-local: a word two references do not spell the same way is not shipped, which is what
withholds German's `Symbols`; and `es_ES` resolves as `es-ES`, since Quarto localizes a whole document from that
spelling, while a value containing a space resolves to nothing.

**Review:** Three-lens fan-out; blame-history found nothing, diff-bug eleven, prior-review two. Fixed: the
changelog's `title: Index` restore advice, which does not work from the front matter; the ledger's claim that
every shipped word has a fixture, false for Italian; a provenance line miscounting its own sources. Rejected: a
non-string `lang:` Quarto refuses before the filter runs, and the parts-versus-phrase rule the ledger already
states. Deferred as KI184-KI189 with a candidate row; KI178 corrected in place, where two-word labels made it
live.
