# M113: PDF index checks count whole printed lines

**Status:** done (2026-10-19, PR #113 https://github.com/jmgirard/quarto-index/pull/113)

**Goal:** Five acceptance-suite readings of a compiled PDF index fail on a wrong index that they pass or read short today.

**Outcome:** Closes KI69, KI312 and KI313 from the older acceptance-suite backlog.
`tests/pdfindex.py`'s new `line_counts` counts a row as the read lines whose `text`
or `term` equals it. `xref_typeset_check` (M02-AC2, M02-AC3), `pdf_term_check` (AC6)
and `book_pdf_check` (M05-AC5) read through `pdfindex.read` instead of flattened
`pdftotext -layout` text, fail naming a row counted other than once, refuse an empty
manifest, and take a planted-lines file for their self-tests; M05-AC5 reads a term's
pages from its one line. The row-inside-another-row refusal is gone.
`tests/typstindex.py`'s bounded `read` refuses a line ahead, in reading order, of the
left-out page's first stop line, exempting stop lines and lines within `SAME_ROW_PT`
of one; the M098-AC5 main read and its T5/T9 plants add `A second placement marker`
as a second stop.

**Decisions:** none milestone-local. AC4 amended once at implement (reading order,
row exemption) after the Typst book's page 14 showed the old read dropping prose.

**Review:** four-lens fan-out, 24 findings: 7 fixed on the branch, 8 to new
KI314-KI316 under the backlog row, 9 rejected. Suite 1773 checks green under Python
3.9.6 (3.14 on PATH lacks PyYAML; three runs hit Quarto segfaults); CI green. No
lesson captured or retired; no row unparked.
