# M35: The non-Latin-1 checks fail on the defects they claim to catch

**Status:** done (2026-08-24, PR #35 https://github.com/jmgirard/quarto-index/pull/35)

**Goal:** The six readings, guards and controls M33 and M34 built for terms
outside Latin-1 discriminate the defects their prose claims, each shown red on
an input of the class it names.

**Outcome:** `entries`/`absent` take `<level>:<term>`, holding a term to its
printed index level behind `pdfindex.columns_carry_top_level`; `stopped` parses
the log into TeX error reports (`! ` opens one, the echoed `l.<n>` closes it)
and needs signature and character in the SAME report. In `run-tests.sh`:
`recipe_font_files` parses the fixture's `mainfont:` stem and `*Font=` lines
into filenames, each `kpsewhich`-probed (4 faces, was 1 hardcoded), with
`require_pdf_tools` moved ahead of the first compile; `pdf_producer_names` reads
control (d)'s capture `Producer` and requires LuaTeX; `README_RECIPE_LINES` pins
README's block to 8 lines both ways, in order, each also in the fixture. Plants 15 -> 20 plus 10 new; suite 351 -> 352 plain and
487 -> 491 self-test.

**Decisions:** none milestone-local; `pdfinfo` in the tool guards is D-020.

**Review:** two rounds. Round 1 returned AC4 — the font guard sat after the
renders it protects, so a planted unfindable face died at the render; T8 moved
it. Round 2 met all seven; of 18 findings, F2 and F18 were fixed on the branch,
the rest filed on the suite-hardening row. Nothing retired or graduated.
