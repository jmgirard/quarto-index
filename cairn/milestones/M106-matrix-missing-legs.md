# M106: The version matrix reads the two-index PDF and the book EPUB

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — it rewrites the matrix paragraphs of README.md and the published Tests page
- **Branch/PR:** m106-matrix-missing-legs

## Goal

On every Quarto version it renders, the version matrix reads two more
artifacts: both indexes in the two-index fixture's PDF, and the three index
sections in the book's EPUB. It reads them against the manifests the acceptance suite uses for those
artifacts.

## Scope

**In:** the `pdf` job renders `examples/named-indexes.qmd` to PDF. It reads
the PDF with `tests/namedpdf.py entries` and `cells`, in two steps. The
`render` job renders `examples/book` to EPUB and reads it with
`tests/epubcheck.py sections` and `links`. Three suite manifests move from
heredocs in `tests/run-tests.sh` to tracked files. The suite and the workflow
both read those files. The workflow comments that list what each job checks
are rewritten. The matrix paragraphs of `site/tests.qmd` and README are
rewritten against the workflow, with the Typst and figure-marks legs of M098
to M102. KI112 and KI113 close.

**Out:**
- A cross-leg comparison of EPUB or PDF output. The plan gate chose per-leg
  readings (work log). The PDF half waits on the candidate row "Make the
  acceptance suite and its PDF comparison version-portable".
- The LaTeX warnings of the two-index render. The suite reads them on one
  Quarto version (plan gate).
- The book PDF's second declared index. The two-index fixture is where the
  matrix reads a second index's build.
- The demo EPUB. The HTML comparison already holds the demo's entries across
  versions, and the book is where the EPUB writer splits files.
- Any reader module change (`namedpdf.py`, `epubcheck.py`, `versioncheck.py`,
  `indexdump.py`).
- KI302 (a floor-leg book render with no index) stays a Known issue.
- A fixture-and-version pair red because of that version's Pandoc or TeX
  output. It leaves this milestone through the amendment gate, as a Known
  issue plus a candidate row (plan gate).

## Acceptance criteria

- [ ] AC1: Take one `workflow_dispatch` run of `.github/workflows/versions.yml`
      at the branch head, its latest attempt. On every leg the `plan` job's
      `legs` output lists, the `pdf` job renders `examples/named-indexes.qmd`
      to PDF. It then passes a step running `tests/namedpdf.py entries`
      against `tests/named-indexes-pdf-entries.txt`. It also passes a step
      running `tests/namedpdf.py cells` against
      `tests/named-indexes-pdf-cells.txt`. A leg can be red at a step this
      milestone did not add. That leg counts as met only where a dispatched
      run at the base branch's head is red at that same step.
- [ ] AC2: On that same run, the `render` job renders `examples/book` to EPUB
      on every leg the `legs` output lists. It then passes
      `tests/epubcheck.py sections` against `tests/book-epub-index.txt`, and
      `tests/epubcheck.py links` over the same EPUB. AC1's rule for a leg red
      at an older step applies.
- [ ] AC3: Take one `workflow_dispatch` run at a probe commit with three
      changes and no others. One entry row of the `Index of Authors` section
      in `tests/named-indexes-pdf-entries.txt` changes. One row of
      `tests/named-indexes-pdf-cells.txt` flips between `present` and
      `absent`. One entry row of `tests/book-epub-index.txt` changes. AC1's
      two reading steps and AC2's `sections` step are each red on every leg
      the `legs` output lists, under AC1's rule for a leg red at an older
      step. Each red step's log carries its reader's FAIL line, then a detail
      line holding the changed row. That line is namedpdf's `<<term>>` line,
      the cells line naming the term, or epubcheck's `got`/`want` pair.
- [ ] AC4: The domain is the lines that
      `grep -nE '^[^#]*quarto render' .github/workflows/versions.yml` lists,
      a `cd examples/book` line being the book. The version-matrix section of
      `site/tests.qmd` names each fixture-and-format pair those lines render
      as a pair the workflow renders. It places each pair under the events of
      the job holding its line: the `render` job's pairs on every push, the
      `pdf` job's weekly and on demand. It names no other pair as one the
      workflow renders. README's matrix sentences name each output format
      those lines render, and state no count of fixtures. Neither page says a
      PDF leg checks only that an index printed.
- [ ] AC5: `tests/run-tests.sh --self-test` passes at the branch head.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T3, T4
- AC3 → T5
- AC4 → T6
- AC5 → T1, T7

## Tasks

- [ ] T1: Move three manifests to tracked files. `M49_PDF_ENTRIES`
      (`tests/run-tests.sh:19041`) goes to
      `tests/named-indexes-pdf-entries.txt`. `M49_PDF_CELLS` (`:19066`) goes
      to `tests/named-indexes-pdf-cells.txt`. `BOOK_EPUB_INDEX` (`:24225`)
      goes to `tests/book-epub-index.txt`. The suite passes those files to
      the readers at its M49-AC1, M49-AC2 and M52-AC3 checks. No heredoc of
      those three names remains, and each derivation comment stays beside its
      read. Move every site that reads the old `$WORK` copies: the M49 T9
      plants (`:19179-19217`) and the read of `$WORK/book-epub-index.txt` at
      `:24464`. Run `tests/run-tests.sh --self-test`.
- [ ] T2: In the `pdf` job, add a step rendering
      `examples/named-indexes.qmd` to PDF. Add one step for
      `namedpdf.py entries` and one for `cells` after it. Put them before any
      later render that writes the same PDF path. Rewrite the job's "WHAT IT
      CHECKS" and "WHAT IT DELIBERATELY DOES NOT CHECK" paragraphs
      (`versions.yml:241-288`). Rewrite the book-extraction comment that
      calls a second declared index no part of the job.
- [ ] T3: In the `render` job, after the upload step, add a step rendering
      the book to EPUB. Add a step after it running `epubcheck.py sections`
      and `links` on the EPUB under `examples/book/_book/` with `qi-index`.
      Rewrite the render-job comment (`versions.yml:137-160`) that says the
      job renders only the figure-marks fixture to EPUB.
- [ ] T4: Push the branch and dispatch `versions.yml` at its head. Read every
      leg's new steps (AC1, AC2). If a leg is red at a step this milestone
      did not add, dispatch on the base branch to compare. If a leg is red
      because of that version's Pandoc or TeX output, stop at the amendment
      gate. That pair leaves the milestone as Out states.
- [ ] T5: On a probe branch, make one commit with the three row changes AC3
      names, and dispatch at it. Read the run against AC3. Keep the commit
      under `refs/probes/m106-manifest-rows` and delete the branch.
- [ ] T6: Rewrite the matrix section of `site/tests.qmd` and README's matrix
      sentences against the uncommented render lines of `versions.yml`. Run
      the suite's README and site checks.
- [ ] T7: Remove KI112 and KI113 from `cairn/DESIGN.md` Known issues. Run
      `tests/run-tests.sh --self-test` (AC5).

## Work log

- 2026-10-01: created by /milestone-plan from the candidate row "Give the version matrix its missing legs" (KI112, KI113). Five green scheduled runs, 2026-08-31 to 2026-09-28, met its promotion condition.
- 2026-10-01: criteria audit, full mode, fresh Opus reader. It returned 8 findings, and 6 were fixed before the gate. AC3 gained its detail line and the cells and Authors-section plants. AC4's grep skips comments, and AC4 gained the events and the stale claim. The suite-files clause moved to T1. AC1 gained the rule for a leg already red. 2 went to the gate as the red-fallback question.
- 2026-10-01: plan gate chose per-leg manifest readings of the book EPUB over a cross-leg EPUB comparison. The comparison widens M43's `versioncheck.py compare`. Falsified by a version difference in the EPUB index that breaks no manifest row and still misleads a reader.
- 2026-10-01: plan gate chose to descope a version-red pair over a per-version manifest. A manifest written after seeing the output is not an oracle. Falsified by a version difference that the extension needs to absorb.
- 2026-10-01: plan gate chose to read the two printed indexes and not the LaTeX warnings. Those warnings quote block positions that each Quarto version counts differently. Falsified by a warning regression that only one Quarto version shows.
- 2026-10-01: M51's Scope Out kept the two-index fixture off the matrix, because a red there was the TeX installation's. This plan reverses that. D-031 says a stock TinyTeX builds the second index, so a red on CI tests a Quarto version or that documented claim.
- 2026-10-01: implement started on branch m106-matrix-missing-legs. Question gate: T1 makes one docstring sentence of `tests/epubcheck.py` false, and the user chose a comment-only edit to it. Scope Out's reader-module clause is read as code changes.
- 2026-10-01: T1 checkpoint, not done: three manifests moved to tracked files and the suite repointed. The `--self-test` run is in progress.
- 2026-10-01: the first T1 suite run stopped at check 138 on the D-030 PyYAML guard. The `python3` on PATH is now `/usr/local/bin/python3` 3.14.6, which has no PyYAML. The re-run puts a scratch `python3` link to `/usr/bin/python3` (3.9.6, with PyYAML) first on PATH. Nothing is installed.

## Decisions

## Review
