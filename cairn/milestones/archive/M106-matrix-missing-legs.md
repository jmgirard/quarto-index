# M106: The version matrix reads the two-index PDF and the book EPUB

**Status:** done (2026-10-02, PR #106 https://github.com/jmgirard/quarto-index/pull/106)

**Goal:** On every Quarto version, the version matrix reads the two-index PDF
and the book EPUB against the acceptance suite's manifests.

**Outcome:** Three suite heredocs became tracked files:
`tests/named-indexes-pdf-entries.txt`, `tests/named-indexes-pdf-cells.txt`
and `tests/book-epub-index.txt`. The `pdf` job renders the two-index fixture
last and reads it with `namedpdf.py entries` and `cells`. The `render` job
renders the book to EPUB after the upload and reads it with `epubcheck.py
sections` and `links`. Each later reading runs past a red one through
`if: !cancelled()` and its render's outcome. The README and `site/tests.qmd`
matrix text is rewritten, with three new claim rows. KI112 and KI113 closed,
and KI302 widened.

**Decisions:** none beyond the plan gate's. A comment-only `epubcheck.py`
docstring edit was approved at the question gate.

**Review:** three lenses, R1-R15. R1-R9 were fixed at the gate: a false claim,
step order, the split `links` step, comments, and claim rows. R10 widened
KI302, R11 is a follow-up, and R12-R14 were rejected. Matrix run 36947400839
was green and probe 36947405509 red. The suite passed 1739 checks, and PR
checks were green. The M43 partial-results lesson was extended.
