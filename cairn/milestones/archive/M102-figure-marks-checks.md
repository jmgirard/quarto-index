# M102: The figure-marks checks run on every matrix leg, each shown able to fail

**Status:** done (2026-09-14, PR #102 https://github.com/jmgirard/quarto-index/pull/102)

**Goal:** Where an alt-text mark's target lands is checked on every Quarto
version the matrix renders, by checks a planted defect is shown to turn red.

**Outcome:** `versions.yml`'s render job renders `examples/figure-marks.qmd`
to EPUB and runs `tests/figuremarks.py after` on its HTML and EPUB. Its PDF
job renders the fixture to PDF and reads it with the new `figuremarks.py pdf`
against `tests/figure-marks-pdf.txt`, which `m101_pdf_check` also reads.
Two `--self-test` plants: `same-block` edits a captured page, and `alt-strip`
splices `html.lua`. KI300 and KI301 closed. KI302 (a floor-leg book render
with no index, seen once) added.

**Decisions:** none beyond the plan gate's. The LaTeX index is checked on
every leg, and plants cover only the two clauses KI301 names. The same-block
plant edits the page, because the filter's Image function returns inlines.

**Review:** one round, three lenses, seven findings. F1-F5 were fixed at the
gate: workflow comments, a FAIL line for a PDF with no index, and an `after`
check in the alt-strip plant. F6-F7 were rejected. Suite 1708 green, matrix
34899204830 green on attempt 2, PR checks green. Nothing graduated or
retired.
