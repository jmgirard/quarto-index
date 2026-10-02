# M106: The version matrix reads the two-index PDF and the book EPUB

- **Status:** review
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

- [x] AC1: Take one `workflow_dispatch` run of `.github/workflows/versions.yml`
      at the branch head, its latest attempt. On every leg the `plan` job's
      `legs` output lists, the `pdf` job renders `examples/named-indexes.qmd`
      to PDF. It then passes a step running `tests/namedpdf.py entries`
      against `tests/named-indexes-pdf-entries.txt`. It also passes a step
      running `tests/namedpdf.py cells` against
      `tests/named-indexes-pdf-cells.txt`. A leg can be red at a step this
      milestone did not add. That leg counts as met only where a dispatched
      run at the base branch's head is red at that same step.
- [x] AC2: On that same run, the `render` job renders `examples/book` to EPUB
      on every leg the `legs` output lists. It then passes
      `tests/epubcheck.py sections` against `tests/book-epub-index.txt`, and
      `tests/epubcheck.py links` over the same EPUB. AC1's rule for a leg red
      at an older step applies.
- [x] AC3: Take one `workflow_dispatch` run at a probe commit with three
      changes and no others. One entry row of the `Index of Authors` section
      in `tests/named-indexes-pdf-entries.txt` changes. One row of
      `tests/named-indexes-pdf-cells.txt` flips between `present` and
      `absent`. One entry row of `tests/book-epub-index.txt` changes. AC1's
      two reading steps and AC2's `sections` step are each red on every leg
      the `legs` output lists, under AC1's rule for a leg red at an older
      step. Each red step's log carries its reader's FAIL line, then a detail
      line holding the changed row. That line is namedpdf's `<<term>>` line,
      the cells line naming the term, or epubcheck's `got`/`want` pair.
- [x] AC4: The domain is the lines that
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

- [x] T1: Move three manifests to tracked files. `M49_PDF_ENTRIES`
      (`tests/run-tests.sh:19041`) goes to
      `tests/named-indexes-pdf-entries.txt`. `M49_PDF_CELLS` (`:19066`) goes
      to `tests/named-indexes-pdf-cells.txt`. `BOOK_EPUB_INDEX` (`:24225`)
      goes to `tests/book-epub-index.txt`. The suite passes those files to
      the readers at its M49-AC1, M49-AC2 and M52-AC3 checks. No heredoc of
      those three names remains, and each derivation comment stays beside its
      read. Move every site that reads the old `$WORK` copies: the M49 T9
      plants (`:19179-19217`) and the read of `$WORK/book-epub-index.txt` at
      `:24464`. Run `tests/run-tests.sh --self-test`.
- [x] T2: In the `pdf` job, add a step rendering
      `examples/named-indexes.qmd` to PDF. Add one step for
      `namedpdf.py entries` and one for `cells` after it. Put them before any
      later render that writes the same PDF path. Rewrite the job's "WHAT IT
      CHECKS" and "WHAT IT DELIBERATELY DOES NOT CHECK" paragraphs
      (`versions.yml:241-288`). Rewrite the book-extraction comment that
      calls a second declared index no part of the job.
- [x] T3: In the `render` job, after the upload step, add a step rendering
      the book to EPUB. Add a step after it running `epubcheck.py sections`
      and `links` on the EPUB under `examples/book/_book/` with `qi-index`.
      Rewrite the render-job comment (`versions.yml:137-160`) that says the
      job renders only the figure-marks fixture to EPUB.
- [x] T4: Push the branch and dispatch `versions.yml` at its head. Read every
      leg's new steps (AC1, AC2). If a leg is red at a step this milestone
      did not add, dispatch on the base branch to compare. If a leg is red
      because of that version's Pandoc or TeX output, stop at the amendment
      gate. That pair leaves the milestone as Out states.
- [x] T5: On a probe branch, make one commit with the three row changes AC3
      names, and dispatch at it. Read the run against AC3. Keep the commit
      under `refs/probes/m106-manifest-rows` and delete the branch.
- [x] T6: Rewrite the matrix section of `site/tests.qmd` and README's matrix
      sentences against the uncommented render lines of `versions.yml`. Run
      the suite's README and site checks.
- [x] T7: Remove KI112 and KI113 from `cairn/DESIGN.md` Known issues. Run
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
- 2026-10-01: T1 done. The three tracked files equal the heredoc output (`cmp`). `--self-test` passed, 1738 checks. M49-AC1, M49-AC2, M52-AC3 and the 11 namedpdf plants read the tracked files.
- 2026-10-01: T2 checkpoint: the `pdf` job renders the two-index fixture and reads it in two steps, and its comments are rewritten. Both step commands pass on the suite's captured PDF. The suite run is shared with T3.
- 2026-10-01: T3 checkpoint: the `render` job renders the book to EPUB after the upload and reads it with `epubcheck.py sections` and `links`. Both commands pass on the suite's captured EPUB. The suite run for T2 and T3 is in progress.
- 2026-10-01: T2 and T3 done. The suite passed, 898 checks, with the workflow edits in place.
- 2026-10-01: T4: run 36940692551 at 42e4b1f, attempt 1, green on all three legs (floor 1.5.52, pinned 1.10.18, release). Each new step prints its reader's `ok` line.
- 2026-10-01: T5 first probe, run 36940741757 at 460498d: entries and EPUB `sections` red on all three legs with the changed row in the detail line. The cells step was skipped after the entries step failed, so AC3 is not met. Minor T2 fix: the cells step runs whenever the two-index render succeeded. T6 drafts are in this checkpoint, not yet checked.
- 2026-10-01: T2 fix landed: the two-index render step has id `named_indexes_pdf`, and the cells step runs `if: !cancelled()` and that step succeeded. T4 and T5 are dispatched again on the new head.
- 2026-10-01: T4 done: run 36941004216 at c143cd0, attempt 1, green on all three legs, with the 12 new reader `ok` lines. No leg was red at an older step, so no base-branch run was needed.
- 2026-10-01: T5 done: probe 467a461 (c143cd0 plus the three row changes), run 36941009713, attempt 1. On all three legs the entries, cells and EPUB `sections` steps are red, each with its FAIL line and then the changed row (`<<Babbidge>>`, `<<Vesalius>> is printed`, `got`/`want` on Turing). The probe is kept at `refs/probes/m106-manifest-rows`, and its branch is deleted.
- 2026-10-01: T6 suite run red at one check: M098-AC7 holds `site/tests.qmd` to a sentence of the old matrix section. The claim row now quotes the rewrite's Typst bullet. It passes on the new page and fails on main's page. T7 checkpoint: KI112 and KI113 removed. The `--self-test` run for T6 and T7 is in progress.
- 2026-10-01: that `--self-test` run stopped at the M101 T5 no-declass Typst plant render: Quarto's Deno segfaulted (`Segmentation fault: 11` from `/usr/local/bin/quarto`). That render reads nothing this branch changed. Re-run after the claim-audit corrections.
- 2026-10-01: claim audit, fresh Opus reader: four claims corrected. README's EPUB sentence (only the book's EPUB is read against a manifest), README's "each printed index" (the book PDF's first index only), the pdf-job comment on the book's indexes after the first, and the TeX-engine reason narrowed to the LaTeX PDFs on both pages. The render-job comment on why the book EPUB runs after the upload is completed.
- 2026-10-01: the same reader re-read each corrected claim once, and each holds. `--self-test` at 8ec0f07 passed, 1738 checks, the crashed Typst plant included. The edited prose and comments are rewrapped to the files' width, with no word changed.
- claim audit: 85 claims read, 4 corrected — README.md, site/tests.qmd, .github/workflows/versions.yml
- 2026-10-01: T6 and T7 done. `--self-test` at 35400ec passed, 1738 checks (AC5). Status set to review. The last dispatched matrix run is at c143cd0. Later commits change comments, prose, the suite and cairn/ only, so review dispatches at the final head for AC1 and AC2.

## Decisions

## Review

Review head be7c60d. main had not moved since the branch was cut, so no merge was needed.

- Consistency gate: `cairn_validate.py` passes every check. The generic profile names no toolchain checks. No principle changed, so `cairn_impact` is skipped.
- AC4: `grep -nE '^[^#]*quarto render' .github/workflows/versions.yml` lists 15 lines. The 7 in the `render` job are HTML of html-index, named-indexes, demo, the book and figure-marks, and EPUB of figure-marks and the book. The 8 in the `pdf` job are PDF of demo, the book, named-indexes and figure-marks, and Typst of typst-index, typst-numbering, typst-order and figure-marks. The `site/tests.qmd` matrix section names all 15 pairs: the 7 under "On every push, and on the weekly and on-demand runs", the 8 under "Weekly and on demand, and not on every push". It names no other pair as one the workflow renders. README names HTML, EPUB, PDF through LaTeX, and Typst, and gives no fixture count ("two Quarto versions" counts versions). `grep -i 'index printed'` finds nothing on either page. Met.
- AC1: `workflow_dispatch` run 36945569069 at be7c60d, the branch head as pushed, attempt 1, its only attempt. The `legs` output lists floor 1.5.52, pinned 1.10.18 and release. On each leg the `pdf` job's render of examples/named-indexes.qmd passes. The `namedpdf.py entries` step against tests/named-indexes-pdf-entries.txt passes ("2 printed index section(s) carry exactly the 20 entry line(s)"). The `cells` step against tests/named-indexes-pdf-cells.txt passes ("all 4 below-marker cell(s) read as stated"). No leg is red at any step. The commits after be7c60d touch cairn/ only. Met.
- AC2: same run. On each of the three legs the `render` job's book EPUB render passes. `epubcheck.py sections` against tests/book-epub-index.txt passes ("3 generated section(s)" qi-index-main, qi-index-people and qi-index-places "match the manifest"). `links` over the same EPUB passes ("all 16 of 16 link(s) ... resolve"). Met.
- AC3: `workflow_dispatch` run 36945573286, attempt 1, at probe 398552a. The probe is be7c60d plus one commit that changes three rows and nothing else (`git diff --stat`: three files, one line each). It renames the Authors-section entry `Babbage` to `Babbidge`, flips `Vesalius` from present to absent, and changes the book EPUB's `Turing` locator count from 1 to 2. The `legs` output lists the same three legs. On each leg the entries step is red with "FAIL: ... the section headed 'Index of Authors' is not the entry set" and then `<<Babbidge>>`. The cells step is red with "FAIL: ... a below-marker cell does not read as stated" and then `'Index': <<Vesalius>> is printed`. The EPUB `sections` step is red with "FAIL: ... does not match the manifest" and then `got '0\tTuring\t1'` / `want '0\tTuring\t2'`. No leg is red at an older step. The probe is kept at `refs/probes/m106-review-manifest-rows`, and its branch is deleted. Met.

Independent review: three lenses (Opus diff-bug, Sonnet blame-history, Sonnet prior-review). The PR-comment probe returned `[]`. Findings are merged where two lenses reported the same thing, ranked, and proposed for triage:

- R1 (diff-bug 1): versions.yml:316-318 and site/tests.qmd:52-54 say the two-index fixture is where the workflow reads an index after the first. That is false, because the Typst step reads typst-index's second index and the book EPUB step reads People and Places. Proposed: fix now, narrowed to an index after the first that imakeidx builds.
- R2 (diff-bug 2): the three two-index steps sit before the eight Typst and figure-marks steps, so a red two-index step now skips readings that ran before M106. Proposed: fix now, moving them to just before "Report what this leg extracted".
- R3 (diff-bug 3, prior 3): the book EPUB's `sections` and `links` share one step, so a red `sections` hides `links`. Proposed: fix now, with two steps and `links` run whenever the EPUB render succeeded.
- R4 (blame 4, prior 1): the unchanged render-job paragraph still calls a second format of the book hypothetical, the same defect M102 F2 fixed once. Proposed: fix now.
- R5 (prior 2): the `matrix typst` claim row no longer pins that this is the Typst step, and the new two-index and book-EPUB sentences are unpinned. Proposed: fix now with claim rows for the Typst render, the two-index PDF and the book EPUB, each shown red on main's page.
- R6 (diff-bug 4): README's "On every push it renders them to HTML" reads as all example fixtures. Proposed: fix now, as "renders fixtures", with no count (AC4).
- R7 (diff-bug 6): the ORACLE RULE at run-tests.sh:7-8 says "Every manifest row below", but the rows now include tracked files. Proposed: fix now.
- R8 (blame 2): the plan's work log gives M51's reason as "the TeX installation's". M51's plan gate gave "widens the restore into new coverage", and the conclusion stands. Proposed: fix now with a correcting work-log line, and no D-entry, since a Scope Out reversal is a plan choice.
- R9 (blame 6): a short-wrapped line in the edited Manifest 10 comment. Proposed: fix now.
- R10 (blame 1, diff-bug 7): the book EPUB render adds a second every-push place where a KI302-style floor-leg flake can turn a push red. Proposed: follow-up, with KI302 widened at hygiene to name the EPUB render.
- R11 (prior 4): tests/indexdump.py:6-8 says the matrix renders HTML only. That predates M106 and is outside the diff. Proposed: follow-up as a trivial comment commit on main after the merge.
- R12 (diff-bug 5): "Manifest 10 — the two index sections", but there are three. It predates M106, and the line is the suite's section banner. Proposed: reject, as pre-existing and unmodified.
- R13 (blame 5): the three manifests carry no ORACLE RULE header. `namedpdf.py rows` reads every non-empty line, so a `#` header needs a reader change, which Scope Out rules out. Proposed: reject.
- R14 (blame 3): a Pandoc writer change at a future pin bump can redden the push path. That is the same exposure the HTML legs already have. Proposed: reject.
- R15 (blame 7): the epubcheck.py docstring edit is consistent with the gate choice. Noted, with nothing requested.
