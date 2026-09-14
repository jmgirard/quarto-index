# M098: A Typst render prints the index

**Status:** done (2026-09-14, PR #98 https://github.com/jmgirard/quarto-index/pull/98)

**Goal:** A document or book rendered to Typst prints each of its indexes with
page locators, built from the same marks the other back-ends read.

**Outcome:** A fourth back-end, `typst.lua`. Each locator mark gets a
`#metadata` label, moved after a heading or an image. Each index is a raw
Typst block that looks up label pages, merges same-page marks, prints author
ranges, drops a page a range spans, bolds principal pages and links each
locator, in two columns. Collation and the entry tree moved to `entries.lua`,
with HTML and EPUB byte-identical. New: `examples/typst-index.qmd`,
`tests/typstindex.py`, `tests/typstcheck.py`, a `versions.yml` Typst step,
`site/typst.qmd`. KI289-KI296 record the limits.

**Decisions:** raw Typst page lookups, not an index package. Books in scope.
Bold read from PDF font names. Consecutive pages not folded. D-060 set the
Quarto 1.5 floor.

**Review:** two passes, three lenses each. Pass 1 returned it: no hand oracle
for xref-escaping (AC8), chapter bounds read from the PDF (AC5), a stale CI
run (AC6). T8-T13 fixed those, dropped pages a range spans and kept alt-text
locators. Pass 2 verified all eight criteria and documented makeindex's
post-range fold with a PDF check. Suite 1607 green. Nothing graduated.
