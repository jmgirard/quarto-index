# M099: A Typst locator prints the number its page shows

**Status:** done (2026-09-14, PR #99 https://github.com/jmgirard/quarto-index/pull/99)

**Goal:** A Typst index locator prints the text its page's numbering prints on
that page, and locators that print the same text print once.

**Outcome:** `qi-index-page` fills a pattern with two counting symbols, or a
numbering function, with the page counter and its final value, as the footer
does. `qi-index-counters` counts the symbols. `qi-index-entry` drops single
marks on pages a range spans, then merges locators by printed text, linking
each to its mark's position. New: `examples/typst-numbering.qmd`,
`tests/typst-numbering.tsv`, a multi-word locator and `--footer` pattern in
`typstindex.py` and `pdfindex.py`, a versions.yml step. KI292, KI293 retired.
KI298 added.

**Decisions:** full footer text, merge by printed text, and the fixture on the
matrix, all at the plan gate. AC2 amended to drop-then-merge after the claim
audit. Quarto 1.5.52 ignores `page-numbering:`, so the fixture sets it in raw
Typst.

**Review:** three lenses, 10 findings from the diff-bug lens. Fixed R1 (a
two-argument numbering function failed the render, including in Typst's own
location link), R2, R3, R5, R9. R4 became KI298. R6-R8, R10 rejected. Suite
1635 green, matrix 34863316506 green. No lesson added or retired.
