<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M23: A range verdict follows its mark's position, not its text

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m23-positional-range-verdicts` · https://github.com/jmgirard/quarto-index/pull/23   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The emitting pass reads each range mark's pairing verdict by document
position, so a mark's rewritten visible text can never move another mark's
verdict.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Replace `marks.lua`'s per-key verdict queues (`range_plan` /
`range_cursor`, read at `marks.lua:404` and consumed at `passes.lua:367`)
with one position-ordinal store both traversals advance at the same span
guard (index class + `range=` attribute), before entry derivation; a nested
`entry=`-less fixture; the AC2 source scan. The deliverable is user-facing —
range pairing in rendered documents — though the desync is latent today: for
an `entry=`-less mark the key derives from stringified visible text, the
emitting pass rewrites inner spans bottom-up, and only the accident that raw
inlines stringify to empty keeps the two traversals' keys equal. Lineage:
promotes the 2026-08-22 candidate row (M21 review round 3 R3-F9).

**Out:** cross-chapter range pairing → standing candidate row (D-009). The
gfm span reader stopping at the first `</span>` → standing acceptance-suite-
hardening row (R2-F10); T1 avoids that reader rather than fixing it here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1 (regression guard: true before this milestone; must stay true): A
      `range=` mark whose span content itself contains another index mark,
      the outer mark carrying no `entry=`, pairs with its closing mark — the
      outer entry prints one page range in the PDF index and records a
      paired range in the HTML index — asserted over a fixture carrying the
      nested shape and a plain non-nested range of a different term in the
      same document, in both back-ends.
- [ ] AC2: The range-verdict store keys on document position: the
      verdict-planning and verdict-reading functions take no entry-key
      argument and advance one shared position counter at the same span
      guard (a span carrying the index class and a `range=` attribute) —
      asserted by a source scan over `modules/marks.lua` and
      `modules/passes.lua` pinned to those functions by name, which fails
      when a pinned name is absent.
- [ ] AC3: The active profile's verify slot (`tests/run-tests.sh`) passes.

## Coverage
<!-- owner: plan · create/amend-via-gate; review reads to fence evidence -->

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Nested fixture: an outer `entry=`-less range mark containing an
      inner index mark, plus a plain non-nested range of a different term in
      the same document; give each new mark a term no other mark in the file
      indexes (M13 lesson). Checks in both back-ends, reading the nested
      span through something other than the gfm reader (its first-`</span>`
      truncation is a standing candidate row). Green today — the
      untouched-shape guard (M11 lesson).
- [x] T2: Re-key: replace the per-key `range_plan`/`range_cursor` queues
      with a position-ordinal store; both traversals advance the ordinal at
      the same guard (span has the index class and `range=`), before
      derivation, so alignment is independent of key and derivation alike.
      Existing M21 suite sections and T1 stay green.
- [x] T3: The AC2 source scan, plus proof it discriminates: a spliced
      variant reintroducing a key parameter on the reading path must fail
      it; a renamed pinned function must fail it (name absence); a spliced
      guard divergence (one traversal advancing on a different condition)
      must fail it.
- [x] T4: Comment and README touch-ups; remove the absorbed candidate row
      from the ROADMAP; work log.
- [x] T5 (review round 1, F1-F3): the AC2 scan asserts WHERE, not only how
      many — the reset inside `finish_ranges`'s own body, each traversal's
      `range_position` call inside its own body and the two registered in
      order, and `plan_range`'s call site handed the guard's position. Each of
      the three trees review round 1 built and the scan exited 0 on becomes a
      planted splice.
- [x] T6 (review round 1, F4, F5, F10, F11): the `pair_ranges` and
      `range_items` contract comments say what the branch made true; the
      nested fixture's PDF render clears `.idx`/`.aux` as well as
      `.ind`/`.ilg`; AC2's evidence prints under a `pass "M23-AC2"` of its own.
- [x] T7 (review round 1, F7-F9, F12): the four follow-up findings land as
      ROADMAP candidate rows or widenings of existing ones.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-22: created by /milestone-plan.
- 2026-08-22: criteria audit (full mode, fresh-context reader) ran twice — pre-gate it returned two load-bearing findings here (AC1 satisfiable at the outset with no acknowledged certifier, AC2 a proxy universal whose scan could pass vacuously on a rename), both repaired; the post-gate re-audit returned one mild finding (AC2 verified counter sharing but not guard agreement), repaired in the wording above.
- 2026-08-22: plan gate chose position-ordinal keying over keeping the per-key queues (with a guarantee that span text never differs between traversals) because the key path depends on what the emitting pass's rewrites stringify to — a property of Pandoc and future emitters, not of this filter; falsified by a document where the two traversals visit range marks in different orders.
- 2026-08-22: plan gate chose the source-scan certifier over behavior-only criteria because no current rendering reaches the latent desync, so behavior alone certifies nothing about the change; falsified by a constructible rendering that fails pre-fix, which would supersede the scan with a behavioral criterion.
- 2026-08-22: implementation started on `m23-positional-range-verdicts`.
- 2026-08-22: T1 — `examples/range-nested.qmd` (an `entry=`-less range mark carrying another mark on both ends, overlapping a plain range of another term with a different span width), `tests/m23probes.py` reading the `.ind`/`.ilg` and the HTML index, and seven self-test plants. Green today: the nested range prints `1--4`, the plain one `2--3`, the inner mark two pages, makeindex 0 warnings. Full suite `--self-test` 386 checks, exit 0. Two helpers factored out of `m21probes._html` rather than copied (M16).
- 2026-08-22: T2 — the per-key `range_plan`/`range_cursor` queues are gone; `finish_ranges` files each verdict under its mark's document position and `next_range(pos)` reads it back. Both traversals take that position through one function, `marks.range_position(span)`, which is the only advance of the counter and holds the guard (index class + `range=`) as one piece of code rather than one condition written twice; `finish_ranges` resets the counter between the passes. Full suite `--self-test` 386 checks, exit 0 — the same count as before the change.
- 2026-08-22: T3 — `tests/scans/range-position.py`, over the whole Lua source set through `filtersrc` (a superset of the two files AC2 names, so a pinned name that leaves them is an absence it fails on). Registered in `run_scan`, in `tests/plantdefect.py`, and in the M16-AC3 count, now 13. Three splices show it discriminating: the entry key back on `next_range` and its call site, `finish_ranges` renamed away, and the emitting pass given a second guard advancing the same counter on its own condition. Full suite `--self-test` 391 checks, exit 0.
- 2026-08-22: T4 — the range-machinery header comment now says a verdict belongs to a mark by position; the `marks_seen` module-state candidate row widened for `range_verdicts`/`range_at`. Nothing to remove from the ROADMAP: the R3-F9 row was already absorbed into this milestone at plan time (9b9bf91). README and DESIGN checked and unchanged — the change is behavior-preserving and neither describes the keying. Verify run in flight; result on the next line.
- 2026-08-22: T4 verify run landed — full suite `--self-test`, 391 checks, exit 0. Status to review.
- 2026-08-22: review opened — draft PR #23; consistency gate green (`cairn_validate` all checks passed; no principle change, so no impact report; the `generic` profile names no toolchain checks). No CI configured on this repo. Three fresh-context reviewers running; acceptance evidence to follow.
- 2026-08-22: T5 — the AC2 scan now reads a named function's own body, not only the concatenated set: `pin_in` holds the counter's one reset inside `finish_ranges`, each traversal's `range_position` call inside `CollectRanges` and `Span`, and `plan_range(pos, ` at its call site; a positional read of `index.lua` holds the two passes registered in that order with `FinishRanges` on the collecting one, and `plan_range`/`next_range` each gain a source-wide one-call-site pin. The three trees round 1 built and the scan exited 0 on are now planted splices (iv)-(vi), each failing on its own pin and no other.
- 2026-08-22: T6 — `pair_ranges`'s contract comment names the `pos` field and says pairing never reads it; the `range_items` comment says what the list holds now that the refused-end placeholder went with the per-key queues; the nested fixture's PDF render clears `.idx` and `.aux` as well as `.ind`/`.ilg`, both being inputs to the render that follows; AC2's scan moved out from under AC1's pass line onto a `pass "M23-AC2"` of its own. One verify run covers T5 and T6 together — the suite reads the working tree, so editing `run-tests.sh` under a run in flight was not safe; full suite `--self-test` 395 checks, exit 0.
- 2026-08-22: T7 — F7 is a new candidate row (the two passes number identically but can still derive differently; M23 changed the failure shape from a wrong page span to a failed render); F8 widened the `marks_seen` module-state row (`finish_ranges` resets the counter and leaves the four range tables); F9 and F12 widened the acceptance-suite-hardening row (the pending-attribute sweep runs before the M23 fixture renders; the bare `(W)` pin counts any filter's warnings). ROADMAP at 59 of 60 lines, 21,520 of 24,000 bytes.
- 2026-08-22: review round 1 returned to in-progress — AC2 fails: `tests/scans/range-position.py` does not assert three parts of the property AC2 says it asserts (the reset's location in `finish_ranges`, which traversals hold the two call sites, and that `plan_range` is handed the guard's own position), each reproduced against a built tree that the scan exits 0 on. Twelve findings logged in the Review section; seven fix-now, four follow-up, one rejected. Defect returns on this milestone: 1.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

### The two functions M23-AC2 names (2026-08-22)

AC2 requires "the verdict-planning and verdict-reading functions" to take no
entry-key argument. Three functions were candidates: `plan_range`, which
records one mark; `finish_ranges`, which pairs the marks and builds the verdict
store; and `next_range`, which reads one verdict back. This milestone reads the
two as `finish_ranges` and `next_range` — verdicts are planned where they are
computed, not where a mark is recorded — and `plan_range` keeps the entry key.
It has to: an opening pairs with the next closing of the SAME entry, which
README states normatively and the suite pins, and no other value expresses it.
What the key stopped doing is standing in for a mark's identity between the two
passes, which is the position's job now and is what AC2 is about.

## Review
<!-- owner: review · exclusive -->

### Round 1 — 2026-08-22 — returned to `in-progress`

**Gate.** `cairn_validate` all checks passed (exit 0). No principle change, so no
impact report. The `generic` profile names no toolchain checks. No CI on the
repo. Draft PR #23.

**Criteria.** AC1 and AC3 were not executed: AC2 failed at the review fan-out
before the evidence run, and every artifact re-renders at re-review anyway.
None ticked.

**AC2 — FAILS.** The criterion promises the positional keying is "asserted by a
source scan ... pinned to those functions by name". The property holds in the
shipped tree, but `tests/scans/range-position.py` does not assert three parts of
it. Each was reproduced here against a built tree, and each broken tree exits 0:

- The reset is pinned as `^  range_at = 0$` — an indentation-anchored match
  anywhere in the concatenated source set, not a match inside `finish_ranges`.
  Reset deleted from `finish_ranges` and made `plan_range`'s first statement:
  every mark plans at position 1 while the emitting pass numbers 1, 2, 3…, so
  every range but the first loses its verdict. Scan exits 0.
- The two `range_position` call sites are counted, never located. Collecting
  pass's call moved into `CollectSort` (which runs earlier) with an inline guard
  left behind: count still 2, guard body still tests both clauses, scan exits 0
  — while `finish_ranges` files verdicts offset by the whole mark count and the
  emitting pass reads nil at every one. That tree emits an unmatched range
  opening, makeindex logs it, and Quarto fails the render.
- `plan_range`'s signature is pinned, its call site is not. `plan_range(1, …)`
  files every verdict at position 1; scan exits 0. The `next_range` side is
  pinned at both ends, the planning side at one.

**Findings and dispositions.** Three fresh-context reviewers; twelve findings.

| # | Finding | Disposition |
|---|---|---|
| F1 | Scan does not locate the counter reset in `finish_ranges` | fix now — the return |
| F2 | Scan counts the two call sites without locating their traversals | fix now — the return |
| F3 | `plan_range`'s call site unpinned, so the position need never reach the store | fix now — the return |
| F4 | `pair_ranges` contract comment omits the `pos` field `finish_ranges` depends on | fix now |
| F5 | `range_items` comment no longer describes what the list holds since the placeholder went | fix now |
| F11 | AC2's evidence prints under an AC1 `pass` line; no `pass "M23-AC2"` exists | fix now |
| F10 | The nested fixture's PDF render clears `.ind`/`.ilg` but not `.idx`/`.aux` | fix now |
| F6 | `next_range` no longer advances anything yet keeps the name, now pinned | rejected — deliberate, and the milestone's Decisions entry names it as one of AC2's two functions |
| F7 | The two passes can still *derive* differently though they now *number* identically; unreachable today, but the failure shape changed from a mis-assigned verdict to an unconsumed one (failed render) | follow-up candidate row |
| F8 | `finish_ranges` clears the counter but not `range_items`/`range_found`/`range_pair_found`/`range_verdicts` | follow-up — widen the module-state row |
| F9 | The `data-qi-pending` sweep reads `examples/range-nested.html` before the M23 section renders it | follow-up — widen the acceptance-suite hardening row |
| F12 | The bare `(W)` warning pin counts any filter's warnings, not this extension's | follow-up — widen the acceptance-suite hardening row |

**What the reviewers cleared.** The Lua change itself: positional alignment
holds across traversal order, nested spans, filter-created spans, the HTML
pending-attribute path, book chapters, the degraded book path and the
no-back-end formats; the reset runs exactly once per process; the dropped
placeholder is safe because `range_items` and `verdicts` stay 1:1 by
construction; nothing contradicts D-007, D-008, D-009, D-010 or any IP/GP. The
`m21probes.py` extraction is behavior-preserving. No new check passes
vacuously. The new scan's M16-AC3 registration is complete and its
moved-definition plant works. The blame-history and prior-review lenses each
returned no findings.
