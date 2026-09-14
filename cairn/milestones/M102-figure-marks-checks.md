<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M102: The figure-marks checks run on every matrix leg, each shown able to fail

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — it changes the acceptance suite's self-test and the version matrix, and no author-facing behavior
- **Branch/PR:** —

## Goal

Where an alt-text mark's target lands is checked on every Quarto version the
matrix renders, by checks a planted defect is shown to turn red.

## Scope

**In:** KI300 and KI301, from the candidate row M101's review added. Two
self-test plants for the M101 checks that have none: the same-block clause of
`tests/figuremarks.py after`, and `tests/figuremarks.py alts`. The version
matrix renders `examples/figure-marks.qmd` to HTML and EPUB on each leg of
its render job and runs the `after` check on both. Its PDF job renders the
fixture to PDF. It reads the printed index against the six lines the
acceptance suite states, from one tracked file that both read.

**Out:** plants for the other failure branches of `tests/figuremarks.py`,
which the plan gate declined. A caption holding a shortcode (KI299) stays on
its own candidate row. A cross-leg PDF comparison stays on the
version-portability candidate row. The release-channel leg's result is not
promised, because an upstream release alone can turn it red (D-025).

## Acceptance criteria

- [ ] AC1: The `--self-test` run builds an HTML render in which the id that
      image 4's alt-text move gives dogwood sits in a new block after that
      image's paragraph. On that render, `tests/figuremarks.py after` for
      dogwood at image 4 fails on its same-block clause. The same command
      passes the unplanted render.
- [ ] AC2: The `--self-test` run builds HTML and EPUB renders through a copy
      of the extension whose alt-text move in
      `_extensions/index/modules/html.lua` removes a moved mark's text from
      the image's alt. On each render, `tests/figuremarks.py alts` fails on
      image 4's alt. The unplanted renders pass.
- [ ] AC3: The render job of `.github/workflows/versions.yml` renders
      `examples/figure-marks.qmd` to HTML and to EPUB on each leg. It fails
      that leg unless `tests/figuremarks.py after` passes in both renders
      for dogwood and elder at image 4 and for hazel at image 5. A dispatched
      run on the milestone branch is green on the floor and pinned legs.
- [ ] AC4: The PDF job of `.github/workflows/versions.yml` renders
      `examples/figure-marks.qmd` to PDF on each leg. It fails that leg
      unless the printed index is the six lines `alder, 1`, `birch, 2`,
      `cedar, 3–4`, `dogwood, 5`, `elder, [P:5]` and `hazel, 6`. The same
      dispatched run is green on the floor and pinned legs.
- [ ] AC5: `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T2, T7
- AC2 → T3, T7
- AC3 → T4, T6
- AC4 → T1, T5, T6
- AC5 → T7

## Tasks

- [ ] T1: Move the six expected lines out of `m101_pdf_check`
      (`tests/run-tests.sh` near 30729) into a tracked file,
      `tests/figure-marks-pdf.txt`. Add a `pdf <pdf> <manifest>` subcommand
      to `tests/figuremarks.py`. It compares `pdfindex.read` entry text to
      the file in NFC (LESSONS M30). `m101_pdf_check` calls it. The
      `latex-move` plant stays red, with the string its `m101_red` wants
      changed to the new message.
- [ ] T2: Same-block plant, in the M101 self-test block (near 30903). Copy
      the captured HTML render and read dogwood's href from its index entry.
      With one perl substitution, move the empty span carrying that id out
      of image 4's `<p>` into a new `<p>` just after it. A substitution that
      matches nothing fails the run. Run `m101_red` on
      `figuremarks.py after html` for dogwood at image 4, wanting
      `not in the image's`, the same-block clause's text
      (`tests/figuremarks.py:131`). The before-image clause reads
      differently, so a plant landing before the image cannot pass.
- [ ] T3: Alt-text plant. Build an `m101_tree` copy whose `html.lua` Image
      function (near 690) returns `{}` in place of the span it took the id
      from, so the mark's text leaves the alt. Render HTML and EPUB through
      it. Run `m101_red` on `figuremarks.py alts` for each, wanting `image 4`.
- [ ] T4: In the `versions.yml` render job (near 184), after the
      figure-marks HTML extraction, render the fixture to EPUB. Run
      `figuremarks.py after` on the HTML and the EPUB for dogwood:4, elder:4
      and hazel:5, with the section prefix the suite's `HTML_SECTION_ID`
      holds. Update the job's comments to say what the steps check. Make sure
      that `tests/versioncheck.py fixtures` still reads the same fixture set.
- [ ] T5: In the `versions.yml` PDF job, render the fixture to PDF and read
      it with `figuremarks.py pdf` against `tests/figure-marks-pdf.txt`, as
      separate render and read steps. Put both before the Typst render (near
      476), which writes `examples/figure-marks.pdf` over the LaTeX PDF.
      Update the job's WHAT IT CHECKS comment.
- [ ] T6: Push the branch and dispatch `versions.yml` on it. Watch the run to
      the end and log its id. If the floor leg prints other lines for an
      engine reason, stop for an amendment gate and leave the manifest as it
      is. The reader runs on Python 3.12 in CI and on 3.9 here (LESSONS M082).
- [ ] T7: Run `tests/run-tests.sh --self-test`, never two runs at once.
      Remove KI300 and KI301 from `cairn/DESIGN.md`.

## Work log

- 2026-09-14: created by /milestone-plan, from the candidate row naming KI300 and KI301 (M101 review F3, F4).
- 2026-09-14: criteria audit, reduced mode (internal tier), fresh [O] reader. It found issues in all five drafts. AC1 and AC2 now name the render the self-test builds. AC3 and AC4 now state a workflow property and a run green on the floor and pinned legs, because the release leg can go red upstream. The shared manifest and the Known-issues removal moved to tasks. T5 now names the Typst render that writes over the LaTeX PDF.
- 2026-09-14: plan gate chose to check the LaTeX index on every leg over HTML and EPUB only, because KI300 names all three writers. Falsified by the floor leg printing other index lines for a TeX engine reason.
- 2026-09-14: plan gate chose plants for the two clauses KI301 names over one per failure branch of `tests/figuremarks.py`, because the other branches catch malformed input rather than a filter defect. Falsified by a filter defect that reaches one of the unplanted branches.
- 2026-09-14: plan chose to plant the same-block defect by editing the captured page over splicing the filter, because the Image function in `html.lua` returns only inlines, so no one-substitution splice puts the target in another block. Falsified by a single substitution that does.

## Decisions

## Review
