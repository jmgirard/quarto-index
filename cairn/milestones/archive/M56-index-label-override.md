# M056: An author sets the words the index back-end picks itself

**Status:** done (2026-08-29, PR #56 https://github.com/jmgirard/quarto-index/pull/56)

**Goal:** An author can set the three English words the HTML and EPUB index back-end
emits on its own — `Symbols`, `see` and `see also` — for a whole document or one index.

**Outcome:** An `index-labels:` map with keys `symbols`, `see` and `see-also`, read by
`read_labels` in `indexes.lua` at the document's top level and inside one `indexes:`
entry, resolved through the exported `qi_indexes.label(index, key, fallback)` at
`html.lua`'s group heading and `core.lua`'s two `XREF_KINDS` rows, which gained a
`label_key` field. Nearest level wins key by key; the unit that falls back is the key,
not the map. Not-a-map, unknown key and empty value each report and fall back rather than
half-install. `latex.lua` is untouched, taking its two words from babel. The suite
gained an M56 block over three new fixtures, a `labels` flag on `htmlindex.row()` (off
by default, all 36 existing xref rows byte-identical) and `epubcheck.py sections --labels`.

**Decisions:** D-039 (renaming the map from `labels:` after the first render showed
`labels:` is a key Quarto injects into every document; amends D-036). Milestone-local:
what falls back is the key, not the map.

**Review:** Three-lens fan-out; only the diff-bug lens found anything (15, plus 1 from
the session). Fixed at the gate: two false babel/`symbols` claims in the site pages, the
stale manifest-1e row-format definition, four stale code comments. Deferred as
KI173–KI183 with a candidate row; two rejected.
