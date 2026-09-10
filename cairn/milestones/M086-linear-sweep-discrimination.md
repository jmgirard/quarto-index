<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M086: The sweep-discrimination probe stops re-sweeping the set once per page

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** internal — a probe over the acceptance suite's own residue sweeps, which nothing outside this repo runs
- **Branch/PR:** `m086-linear-sweep-discrimination`

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

- [x] T1: Give `tests/plantdefect.py --html` a many-page mode: one residue
      kind planted into every page named on the command line, in one
      invocation, printing the marker once. A page whose anchor text is
      absent is an error naming that page, so the existing no-op guard
      holds per page rather than per call (`plant_html`, 266-282).
- [x] T2: Replace the per-page loop (`tests/run-tests.sh` 20653-20679) with
      one plant pass and one sweep per residue: plant all pages, sweep, and
      require the output to carry the expected marker and to name each page
      the `find` listed. Keep the unplanted-mirror precheck ahead of it
      unchanged, and keep the page-count assertion that stops the leg
      running over an empty mirror.
- [x] T3: Add the three single-page legs on a freshly re-copied unplanted
      mirror — one per residue — each requiring the sweep red, naming its
      page, and naming no other page in the mirror.
- [x] T4: Rewrite the section's banner comment to state what the probe now
      does; correct KI33 in `cairn/DESIGN.md` (marked corrected, its 14,000
      figure superseded by the count this milestone leaves).
- [x] T5: Run `tests/run-tests.sh --self-test` whole and record the M24
      section's new row from `tests/.work/timing.tsv` beside the 3080 s the
      2026-09-10 run recorded.

## Work log

- 2026-09-10: created by /milestone-plan.
- 2026-09-10: plan gate chose all-at-once plants plus three retained single-page legs over an all-at-once-only probe, a sampled subset of pages, and deleting the probe outright, because the accumulating sweeps name every offending page, so one sweep carries the same per-page reading claim while the retained singles keep the one-red-among-clean evidence the all-at-once form loses; falsified by a sweep mode that stops at its first offending page, which would make the all-at-once output silent about every page after it.
- 2026-09-10: plan gate chose a fixed sweep-invocation count as the cost criterion over a wall-clock bound, because KI251 records whole runs as unreliable on this machine and a recorded-seconds promise would go red for reasons that are not this change; falsified by an invocation count staying fixed while per-invocation cost grows.
- 2026-09-10: reduced criteria audit (internal tier) by a fresh [O] reader returned findings on one criterion of five — the drafted AC4 promised a result over an unbounded family of mirror sizes and demanded a second capture root be built; repaired before writing by restating it as a fixed invocation count observed inside the single run. AC1, AC2, AC3, AC5 clean on all three questions.
- 2026-09-10: implement gate chose the plant call's shape as kind-first with a variadic page list (both existing callers rewritten), a run-counted sweep total over a reading of the call sites, and one page for all three single-page legs.
- 2026-09-10: T1-T3 landed together — the plant tool's new call shape and its two callers must move in one commit for the suite to stay runnable. Each new leg proved able to fail by mutating the probe: restoring one planted page silently → the all-pages leg red naming it; planting a second page in a single-page leg → the no-other-page leg red naming it; a ninth sweep → the count leg red at 9; a mirror one page short → the plant-count leg red at 770 of 771.
- 2026-09-10: the sweep's named pages are read with awk's `index` rather than `grep -oFf` — the shim answering `grep` on this machine (ugrep 7.8.4) reported 146 of 771 named pages where the sweep named every one, which would have made the all-pages leg red for a reason that is not the sweep.
- 2026-09-10: T4 — the section banner now states what the probe does, read from `htmlsweep.py`'s two accumulating sweeps; KI33's cost clause corrected, its 14,000-parse figure replaced by eight sweeps over the captured set (6,168 parses at the 771 pages the 2026-09-10 capture root held) and what is left of the entry pointed at the suite-run shape row.
- 2026-09-10: deviation from the per-task verify slot — the M24 residue half runs only under `--self-test`, whose whole run the 2026-09-10 timing recorded at 3080 s, and the profile's own slot forbids concurrent runs. T1-T3 were verified against an extraction of the section over a prior run's 771-page capture root (24 s); the whole `--self-test` run is T5, and stands as the verify for every task.
- 2026-09-10: T5 — `tests/run-tests.sh --self-test` clean, 1451 checks, exit 0. The M24 section's timing row is 23 s against the 3080 s the run before it recorded. The section's own `find` listed 497 pages, the capture root still filling at that point in the run (771 by the end), so the half's cost is 8 x 497 = 3,976 parses.
- 2026-09-10: corrects the T4 line above and the KI33 text it landed — the 771 pages it cited came from a leftover capture root accumulated across runs, not from the 2026-09-10 run's own root at the section's point in it. KI33 fixed in place to 497 pages and 3,976 parses; the mutation and extraction evidence recorded above stands, having been run over that 771-page root.
- 2026-09-10: claim audit: not owed — internal tier.

## Decisions

## Review
