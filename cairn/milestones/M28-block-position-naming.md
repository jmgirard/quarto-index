# M28: A reported block position names the sequence it counts

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m028-block-position-naming` / https://github.com/jmgirard/quarto-index/pull/28

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

- [x] Rendering `examples/marker-position.qmd` to gfm emits an emptied-place
      report whose block number differs from the marker's position among the
      top-level blocks of the file the marker is written in, and that report
      carries the sequence-naming clause. The fixture's manifest comment states
      both numbers.
- [x] In captured render logs, each number the three reports name says which
      sequence it indexes into: the emptied-place report and the duplicate-
      marker report over `examples/marker-shapes.qmd` and
      `examples/marker-misuse.qmd`, and the chapter-count report over
      `examples/book-order`. The duplicate-marker report names a sequence for
      both of its numbers — the marker ordinal and the block position.
      Asserted against the reports' full emitted text, never against source.
- [x] Every warning `examples/marker-shapes.qmd` emits in html, latex and gfm
      is either one of that fixture's two known other warnings or the reworded
      emptied-place template with only its block number varying.
- [x] The `resolve_markers` comment (`marker.lua:210`) and the
      `marker-shapes.qmd` manifest comment each state that a reported position
      is counted over the blocks the filter is handed, after Quarto's own
      processing, and neither states that it is the author's.
- [x] `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

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
- 2026-08-24: review gate — maintainer directed the seven fix-now items; all landed on the branch, three follow-ups filed as KI80/KI81/KI82 with the suite-hardening row extended. Suite re-run green (286 / 420), cairn_validate exit 0.
- 2026-08-23: review — three fresh-context lenses ran; blame-history and prior-review record returned no findings, diff-bug returned thirteen. Six triaged fix-now, three to a follow-up row, three rejected with reason, one (F1) already carried by KI22/M29. No finding meets the return floor.
- 2026-08-23: review — PR #28 opened as a draft; all five criteria executed with fresh evidence and ticked; consistency gate clean (cairn_validate exit 0, no principle change, generic profile names no toolchain checks). Fresh-context review fan-out spawned; findings pending.

## Decisions

## Review

Reviewed 2026-08-23 on `m028-block-position-naming`, PR #28. Evidence is a
fresh full run of `tests/run-tests.sh` and `tests/run-tests.sh --self-test` on
this branch, plus reads of the two comment sites.

- **AC1 — met.** The suite's M28-AC1 check reads both manifest numbers off
  `examples/marker-position.qmd` (author position 3, reported position 5) and
  matches them against the gfm render's own log: the emitted report names
  top-level block 5 for a marker written as the host file's third top-level
  block, and carries the sequence-naming clause. Its two discrimination plants
  (manifest numbers equalized; the log's report renamed to the author's
  position) both go red.
- **AC2 — met.** Eight clause checks pass over captured render logs, each
  asserting the reports' full emitted text: the emptied-place report (13
  reports each in html, latex, gfm) and the duplicate-marker report (1 each) over
  `marker-shapes.qmd`/`marker-misuse.qmd`, and the chapter-count report (2
  reports) over `book-order`. A separate check holds that the duplicate report's
  clause covers both of its numbers — its first number now reads "index
  placement marker 2 in document order (top-level block 8)", with a trailing
  "Both numbers are counted over the document as this filter received it …".
  The chapter-count report ends "The chapter count is over the files this book
  renders, in the order the book's render list gives them". Two discrimination
  plants go red: the clause cut out of every report, and the report removed
  entirely (which fails by finding no report).
- **AC3 — met.** The M12 partition check passes in all three formats: of 34
  warnings per format, the 13 that are not the fixture's two known ones are
  exactly the manifest's emptied-place reports, each the reworded template with
  only its block position varying. A fourth check holds the same over the three
  renders together, matching the manifest whole.
- **AC4 — met.** Read both sites on this branch. The `resolve_markers` comment
  (`_extensions/index/modules/marker.lua:225`) says a reported position "is
  counted over the blocks this filter is handed, after Quarto's own processing"
  and "is not the author's own source position", pointing at
  `examples/marker-position.qmd`. The `marker-shapes.qmd` manifest comment says
  its own numbering works there only because that file holds no include and no
  executable cell, that "The report's number is counted over what the filter is
  handed, after Quarto's own processing — not over the author's source file",
  and points at the same fixture. Neither calls the position the author's.
- **AC5 — met.** `tests/run-tests.sh` exits 0, 286 checks.
  `tests/run-tests.sh --self-test` exits 0, 420 checks. Both run fresh on this
  branch at review time.

### Consistency gate

- `cairn_validate` exits 0 — every check PASS, every advisory OK.
- No `DESIGN.md` principle changed on this branch (the DESIGN diff is Known
  issues only: KI21 narrowed, KI25 struck), so `cairn_impact` is skipped.
- Toolchain checks: the active profile is `generic`, whose `consistency-gate`
  slot names none. Clean no-op.

### Findings

Three fresh-context reviewers ran against distinct evidence bases.

- **[S] blame-history — no findings.** Judged the modified lines against the
  intent of the code they touch. Reports the diff changes only string literals
  and comments; `#later`, `resolve_markers` and `strip_nested_markers` control
  flow untouched; `WARN_MARKER_DUP` and the M12 partition template moved with
  the text they key off; the M10-era one-literal `warn` form preserved.
- **[S] prior-review record — no findings.** Archived `## Review` sections are
  the primary surface here; the GitHub inline-comment probe found no real
  threads, so PR threads were not walked. Reports the diff is the on-topic
  resolution of M12 review F6 (KI21) and M19 review F1 (KI25), with no
  regression of a point M12/M17/M20/M21 review raised on these files.
- **[O] diff-bug — thirteen findings**, ranked below with their disposition.

**F1 (rejected — already recorded as KI22, and M29 is the milestone for it).**
"`_extensions/index/modules/marker.lua:31` — the new clause asserts a sequence
that is wrong in a book. `POSITION_BASIS` says the position is 'counted over the
document as this filter received it', but in a book render the filter receives
one *chapter*, and the emptied-place report names no file (that is KI22,
deferred to M29)." Verified: the clause is literally true of a book chapter —
the filter did receive that chapter as its document — and the reader's inability
to tell WHICH file is exactly KI22, which this milestone's Scope Out routes to
M29. No new row; the existing Known issue and planned milestone carry it.

**F2 (follow-up — suite-hardening candidate row).** "`tests/m28pos.py:35-40` —
the 'author position' number is pinned to nothing. Only `reported` is matched
against the render; `author` is checked solely for `!= reported` and `!= got`.
Edit the manifest to say `author position: 2` and the whole suite still passes,
while AC1's claim is evidenced by nothing but a comment. Counting the host
file's own top-level blocks is mechanically checkable and is not done."
Confirmed by reading `tests/m28pos.py`. AC1 itself holds — the host file's three
top-level blocks and the reported 5 were read directly at review — but the
check is weaker than the claim it certifies.

**F3 (fix now).** "`tests/run-tests.sh:239-247` — the distinctness scan does not
get the one key M28 actually reworded. `WARN_MARKER_DUP` (reworded by this
milestone to embed 'in document order') is still not passed to
`mark-report-keys`, while `WARN_MARKER_NOT_LAST` — which M28 did not touch — is."
Confirmed: `origin/main` has `WARN_MARKER_DUP='index placement marker 2
(top-level block 8) is ignored'`; this branch has `... 2 in document order
(top-level block 8) ...`, and the key is absent from the scan's argument list.
The comment above the list also claims both new keys are for text the milestone
reworded, which is false of `WARN_MARKER_NOT_LAST`.

**F4 (fix now).** "`tests/run-tests.sh:10393-10397` — the 'Both numbers are'
check has no vacuity guard and no discrimination plant. If `$WARN_MARKER_DUP`
stops matching, the first `grep -F` emits nothing, `grep -qF` returns 1, and the
run reports 'names a sequence for only one of its two numbers' — a misdiagnosis
of a missing report." Confirmed by reading the loop.

**F5 (fix now).** "`tests/run-tests.sh:10367-10369` — the vacuity guard is a
string compare that an absent file slips through. If `$logfile` does not exist,
`grep -c` prints nothing, `hits` is the empty string, and `[ "$hits" != "0" ]`
is true, so the guard passes." Confirmed by reading `check_report_clause`.

**F6 (fix now).** "`cairn/DESIGN.md:74-80` — the Conventions section still
excludes exactly what D-014 now governs. The D-006 bullet ends 'A report whose
number has no drop to distinguish — a book's chapter count, a top-level block
position — is outside it', and no sibling bullet was added for D-014." Confirmed:
DESIGN's current-knowledge text now contradicts DECISIONS.

**F7 (follow-up — suite-hardening candidate row).** "`marker.lua:246-248` — the
duplicate report's shared clause overstates for its first number. 'Both numbers
are counted over the document as this filter received it … so they can differ
from the positions in your source file': the first number is a marker ordinal,
not a position, so the trailing half of the sentence describes only the second."
Confirmed. The leading half is accurate for both; only the source-file clause is
position-specific. Rewording shipped warning text also moves a suite key, so it
is filed rather than taken at the gate.

**F8 (fix now).** "`cairn/DESIGN.md:238-239` — the architecture description of
the emptied-place report is now stale. It still says the report carries 'the
marker's top-level block position and naming nothing else'." Confirmed.

**F9 (fix now).** "`cairn/DESIGN.md:551-556` — KI21's rewrite overclaims
coverage. 'the include member is covered by `examples/marker-position.qmd`' is
true only for the emptied-place report; the duplicate-marker report and the book
chapter count have no include fixture." Confirmed.

**F10 (follow-up — suite-hardening candidate row).** "`tests/run-tests.sh:3008-3012`,
`tests/run-tests.sh:10357`, `tests/m28pos.py:19-21` — the clause is written out
three times in the suite against one shared string in the filter. Not a hole
(any drift fails loudly in all three), but a reword now takes three coordinated
suite edits where the filter takes one." Confirmed; the triplication is the
price of D-011's refusal to read the expectation out of the filter's source.

**F11 (rejected — the criterion is met on its plain reading).** "AC2 wording vs.
what is checked. AC2 reads 'the emptied-place report and the duplicate-marker
report over `examples/marker-shapes.qmd` and `examples/marker-misuse.qmd`'. The
suite checks emptied-place only over shapes and duplicate only over misuse. The
cross terms are in fact unsatisfiable." Confirmed that the cross terms are
unsatisfiable: `misuse-gfm.log` holds 0 emptied-place reports and
`shapes-gfm.log` 0 duplicate reports. AC2 names a pair of reports and a pair of
fixtures; the collective reading is the plain one and is what the evidence
records. No reinterpretation was needed to tick it, so this is not a criterion
amendment.

**F12 (rejected — consistent with what the report counts and with the repo's
framing).** "`examples/marker-position.qmd:8-10` — 'the marker's position' is
really its container's. The marker div is nested inside `::: {.surrounding}`, so
the fixture's `author position: 3` is the position of the container." The report
says "top-level block N" throughout, meaning the top-level block the marker is
written under; the fixture manifest already says the marker's container is the
third block.

**F13 (fix now).** "`tests/run-tests.sh:10412` — capture slug `marker-position`
breaks the local `<name>-<fmt>` idiom. A later html/latex render of this fixture
would find the unsuffixed slug taken and hit `capture`'s duplicate-slug `fail`."

**Return floor.** No finding demonstrates an acceptance criterion failing, and
none is a load-bearing defect in what the filter does for an author: F1 is an
already-recorded Known issue, F11 and F12 are readings rather than defects, and
the rest are suite strength and record staleness. Status stays `review`.

### Fix-now work directed at the gate (2026-08-24)

The maintainer chose "fix seven, then merge". What landed:

- **F3.** The direct repair the finding names is not available: `WARN_MARKER_DUP`
  carries two RENDERED numbers and `mark-report-keys` compares its keys against
  the filter's source literals, where those places are `%d`. Probed directly —
  passing the key verbatim gives "matches 0 filter warnings, want 1". The
  duplicate report now enters the scan as `WARN_MARKER_DUP_STEM`, the
  number-free stem of the same message, with a shell check beside the two
  constants that fails if the numbered key stops containing the stem. The
  overclaiming comment above the argument list is corrected. The scan now holds
  16 keys, up from 15.
- **F4.** The "Both numbers are" loop counts its matches first and fails naming
  the count when it is not exactly 1, so a key that stopped matching is
  reported as a missing report rather than as a report naming one number.
- **F5.** `check_report_clause` tests `[ -r "$logfile" ]` before greping, and
  refuses a match count that is not a number — the two ways the old string
  compare let an absent file through.
- **F6.** `DESIGN.md`'s Conventions section gains the D-014 bullet, and the
  D-006 bullet's exclusion is corrected in place to point at it (`corrected M28`).
- **F8.** The architecture description of the emptied-place report now says it
  carries the position clause as well as the position.
- **F9.** KI21 no longer claims the include member is covered outright — it is
  covered for the emptied-place report and for neither of the other two.
- **F13.** The capture slug is `marker-position-gfm`, following the local
  `<name>-<fmt>` idiom.

Follow-ups filed as Known issues, with the existing acceptance-suite hardening
row extended to point at the two suite ones: **KI80** (F7), **KI81** (F2),
**KI82** (F10).

Re-verified after the fixes: `tests/run-tests.sh` 286 checks exit 0,
`tests/run-tests.sh --self-test` 420 checks exit 0, `cairn_validate` exit 0.
