<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M086: The sweep-discrimination probe stops re-sweeping the set once per page

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** internal — a probe over the acceptance suite's own residue sweeps, which nothing outside this repo runs
- **Branch/PR:** —

## Goal

The M24 residue probe shows each whole-set sweep reading every captured page
without running that sweep once per page.

## Scope

**In:** the per-page plant loop in the M24 section of `tests/run-tests.sh`
(the `while` at 20653-20679, whose body runs only under `--self-test`); a
many-page mode for `tests/plantdefect.py --html`; KI33 in `cairn/DESIGN.md`,
whose stated cost this resolves and whose figure is stale.

**Out:** the ~840 s a plain (non-`--self-test`) run costs → the suite-run
shape candidate row. Parallel legs, a named-subset run, per-render timing →
the same row. The M33 plant matrix in the same section (24 plants, already
one sweep each) and the empty-div half (3 named pages) → untouched. Any
change to what `tests/htmlsweep.py` itself promises → out; this milestone
moves only how the probe exercises it.

## Acceptance criteria

- [ ] AC1: The probe plants each residue into every page `find
      "$CAPTURE_ROOT" -name '*.html'` lists, in one pass per residue, and
      requires the sweep to go red naming every one of those pages; the
      three residues are `data-qi-pending`, `data-qi-meta` and the marker
      class.
- [ ] AC2: For each of the three residues the probe also plants into a
      single page of an otherwise unplanted mirror, and requires the sweep
      to go red naming that page and no other page the same `find` lists.
- [ ] AC3: The probe counts the pages it planted and fails when that count
      is not the page count the same `find` returns, so a plant that
      substituted nothing is reported as the plant it is rather than as the
      sweep failing to discriminate.
- [ ] AC4: On a `--self-test` run the M24 section's residue half invokes
      `tests/htmlsweep.py` exactly eight times: two for the unplanted-mirror
      precheck, three for the all-at-once plants, three for the single-page
      plants.
- [ ] AC5: The unplanted-mirror precheck still runs ahead of every plant and
      both sweeps pass on it, so a red leg below it is evidence about the
      plant.
- [ ] AC6: `tests/run-tests.sh --self-test` is clean (the `verify` slot's
      pre-review form).

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T2, T3
- AC5 → T2
- AC6 → T5

## Tasks

- [ ] T1: Give `tests/plantdefect.py --html` a many-page mode: one residue
      kind planted into every page named on the command line, in one
      invocation, printing the marker once. A page whose anchor text is
      absent is an error naming that page, so the existing no-op guard
      holds per page rather than per call (`plant_html`, 266-282).
- [ ] T2: Replace the per-page loop (`tests/run-tests.sh` 20653-20679) with
      one plant pass and one sweep per residue: plant all pages, sweep, and
      require the output to carry the expected marker and to name each page
      the `find` listed. Keep the unplanted-mirror precheck ahead of it
      unchanged, and keep the page-count assertion that stops the leg
      running over an empty mirror.
- [ ] T3: Add the three single-page legs on a freshly re-copied unplanted
      mirror — one per residue — each requiring the sweep red, naming its
      page, and naming no other page in the mirror.
- [ ] T4: Rewrite the section's banner comment to state what the probe now
      does; correct KI33 in `cairn/DESIGN.md` (marked corrected, its 14,000
      figure superseded by the count this milestone leaves).
- [ ] T5: Run `tests/run-tests.sh --self-test` whole and record the M24
      section's new row from `tests/.work/timing.tsv` beside the 3080 s the
      2026-09-10 run recorded.

## Work log

- 2026-09-10: created by /milestone-plan.
- 2026-09-10: plan gate chose all-at-once plants plus three retained single-page legs over an all-at-once-only probe, a sampled subset of pages, and deleting the probe outright, because the accumulating sweeps name every offending page, so one sweep carries the same per-page reading claim while the retained singles keep the one-red-among-clean evidence the all-at-once form loses; falsified by a sweep mode that stops at its first offending page, which would make the all-at-once output silent about every page after it.
- 2026-09-10: plan gate chose a fixed sweep-invocation count as the cost criterion over a wall-clock bound, because KI251 records whole runs as unreliable on this machine and a recorded-seconds promise would go red for reasons that are not this change; falsified by an invocation count staying fixed while per-invocation cost grows.
- 2026-09-10: reduced criteria audit (internal tier) by a fresh [O] reader returned findings on one criterion of five — the drafted AC4 promised a result over an unbounded family of mirror sizes and demanded a second capture root be built; repaired before writing by restating it as a fixed invocation count observed inside the single run. AC1, AC2, AC3, AC5 clean on all three questions.

## Decisions

## Review
