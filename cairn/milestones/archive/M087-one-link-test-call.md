# M087: The link readers call the one link test and use the href it judged

**Status:** done (2026-09-10, PR #87 https://github.com/jmgirard/quarto-index/pull/87)

**Goal:** What each link reader does with an href follows from the one verdict
`htmlindex.leaves_publication` gave that same href, with each of the EPUB
commands' all-links-leave refusals shown able to fire.

**Outcome:** The per-module `leaves_publication` names in `epubcheck`, `epubindex`
and `sitecheck` are deleted and their call sites call `htmlindex.leaves_publication`;
`resolve_href`, `epubindex.links` and `epubcheck.py unique` split `href.strip()` at
`#`, so a leading-space locator resolves (KI269 struck). The M085 table leg drives
the 14 `M085_HREF_SHAPES` rows through the one predicate. `plant.py --every` plants
every match, and under `--self-test` both EPUB commands are held to their
all-links-leave refusal text; `m085_epub_plant` takes one expected count per command.

**Decisions:** none milestone-local; the plan gate's reversal of M085's per-reader names is in the work log (git), under D-057.

**Review:** pass 1, three-lens fan-out, found no criterion failing; `--self-test`
passed 1455 checks. The gate fixed two comments (one overstated what a plain run
checks of the site and fragment readers, one pointed at the deleted KI269), filed
KI271 (`check_locator_fragments` bypasses the predicate) and KI272 (no plant passes
differing counts) under one candidate row, and rejected three findings, one already
held by KI264's row. Nothing graduated or retired.
