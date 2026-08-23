# M28: A reported block position names the sequence it counts

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m028-block-position-naming`

## Goal

An author reading a placement-marker report is told what the number in it
counts, and the report and comment sites this milestone names stop calling that
number the author's own source position.

## Scope

Surface tier: **user-facing** — the deliverable is warning text authors read.

**In:** the three reports that name a top-level-block position or a chapter
count — the emptied-place report (`marker.lua:189`), the duplicate-marker
report (`marker.lua:222`) and the chapter-count report (`book.lua:575`) — each
gain a clause naming the sequence each of their numbers indexes into. The
`resolve_markers` comment (`marker.lua:210`) and the `marker-shapes.qmd`
manifest comment are corrected where they call the position the author's. A new
fixture holds a marker after an `{{< include >}}` so the divergence the reports
are about is exercised rather than asserted. A D-entry records the convention,
annotating D-006.

**Out:** naming the chapter file in a book report (KI22) → M29. Giving the
author's own source position alongside the reported one → refused at the gate,
not deferred: the include has already expanded before the filter runs, so the
source count is not recoverable without new machinery. Covering the executable-
cell and shortcode injection kinds KI21's second clause names → KI21 is narrowed
to that residue rather than struck, and the residue stays a Known issue.

## Acceptance criteria

- [ ] Rendering `examples/marker-position.qmd` to gfm emits an emptied-place
      report whose block number differs from the marker's position among the
      top-level blocks of the file the marker is written in, and that report
      carries the sequence-naming clause. The fixture's manifest comment states
      both numbers.
- [ ] In captured render logs, each number the three reports name says which
      sequence it indexes into: the emptied-place report and the duplicate-
      marker report over `examples/marker-shapes.qmd` and
      `examples/marker-misuse.qmd`, and the chapter-count report over
      `examples/book-order`. The duplicate-marker report names a sequence for
      both of its numbers — the marker ordinal and the block position.
      Asserted against the reports' full emitted text, never against source.
- [ ] Every warning `examples/marker-shapes.qmd` emits in html, latex and gfm
      is either one of that fixture's two known other warnings or the reworded
      emptied-place template with only its block number varying.
- [ ] The `resolve_markers` comment (`marker.lua:210`) and the
      `marker-shapes.qmd` manifest comment each state that a reported position
      is counted over the blocks the filter is handed, after Quarto's own
      processing, and neither states that it is the author's.
- [ ] `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T3, T5
- AC3 → T2, T5
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: add `examples/marker-position.qmd` and the part file it includes.
      The marker goes in the host file, after the `{{< include >}}`; the
      manifest comment states the marker's position among the host file's own
      top-level blocks and the position the render reports. A probe run on
      2026-08-23 gave 3 and 5 for this shape.
- [x] T2: write the naming clause once and splice it into `marker.lua`'s two
      reports (`marker.lua:189`, `marker.lua:222`), giving the duplicate
      report a clause for each of its two numbers.
- [x] T3: splice a naming clause into `book.lua`'s chapter-count report
      (`book.lua:575`), naming what its chapter count is over.
- [x] T4: correct the `resolve_markers` comment (`marker.lua:210`) and the
      `examples/marker-shapes.qmd` manifest comment.
- [x] T5: suite — update the M12 partition template
      (`tests/run-tests.sh:2998`); add the divergence check reading both
      manifest numbers off the new fixture; assert the naming clause in the
      three reports' full emitted text in captured logs; pass every new grep
      key to the key-distinctness scan (M18).
- [x] T6: append the D-entry annotating D-006; narrow KI21 to its residue,
      strike KI25, and rewrite the candidate row pointing at them, in the same
      commit (D-013).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan gate chose qualifying the reported count over reporting the author's source position alongside it because the include has expanded before the filter runs and the source count is not recoverable; falsified by a Quarto-supplied provenance record mapping a filter-visible block back to the source file and position it came from.
- 2026-08-23: plan gate chose asserting the naming clause in captured render logs over a scan joining the `warn` calls' string literals because D-011 refuses widening a source-shape scan and M25 records that such a grep is matched by comments and dead calls; falsified by a report whose text cannot be reached by any render the suite runs.
- 2026-08-23: plan gate chose narrowing KI21 to its un-probed residue over striking it because AC1's fixture exercises only the include member of the injection family it names; falsified by a fixture covering the executable-cell and shortcode members without an engine dependency (GP3).
- 2026-08-23: criteria audit ran in FULL mode ([O] fresh-context reader, user-facing tier) and returned twelve findings; ten fixed at the gate, one (M29-AC5) dropped as a consequence of another fix, and one (M29-AC4's unreachable state) posed as a gate question and narrowed to the reachable render.
- 2026-08-23: implement gate chose the full trailing sentence for the naming clause, labelling the duplicate report's marker ordinal in its own sentence, and naming the book's render list as what the chapter count is over.
- 2026-08-23: T1 — added `examples/marker-position.qmd` and `examples/_marker-position-part.qmd`; a gfm render reports block 5 for a marker written as the host file's third top-level block, and the manifest states both numbers.

- 2026-08-23: T2 — `POSITION_BASIS` written once in `marker.lua` and spliced into the emptied-place and duplicate-marker reports; the duplicate report's first number now reads "marker N in document order". Suite constants moved with it (`WARN_MARKER_DUP`, the M12 partition template); T4's `resolve_markers` comment rode in this commit. Suite green, 275 checks.

- 2026-08-23: T3 — `book.lua`'s chapter-count report now says the count is over the files the book renders, in render-list order.
- 2026-08-23: T4 — the `marker-shapes.qmd` manifest comment now says its numbers hold only because that file has no include or cell, and points at the fixture where the two positions diverge; the `resolve_markers` comment landed in T2's commit.

- 2026-08-23: T5 — suite gained the clause checks over the three reports' emitted text, `tests/m28pos.py` reading both manifest numbers off the new fixture, and four discrimination plants (clause cut out, report removed, manifest numbers equalized, log report renamed to the author's position); `WARN_MARKER_EMPTIED` and `WARN_MARKER_NOT_LAST` now reach the key-distinctness scan. 286 checks, 420 under `--self-test`.
- 2026-08-23: minor amendment — T5 gained the four discrimination plants as a discovered sub-task; the check-discrimination rule requires a new check be shown able to fail, and the repo's idiom is to commit the plant beside it.

- 2026-08-23: T6 — D-014 appended annotating D-006; KI21 narrowed to the un-probed injection kinds and marked narrowed M28; KI25 struck. No candidate row pointed at either label — the block-position row was narrowed to its KI23 remainder at plan time — so no row needed rewriting. cairn_validate clean.

- 2026-08-23: all tasks done; `tests/run-tests.sh` passes (286 checks) and `tests/run-tests.sh --self-test` passes (420 checks). Status set to review.

## Decisions

## Review
