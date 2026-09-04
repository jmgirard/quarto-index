# M075: The suite reports where its own time goes

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — instrumentation of the acceptance suite, which is dev tooling nothing outside the repo consumes
- **Branch/PR:** `m075-suite-timing-profile`

## Goal

A full acceptance run states its wall clock per section, so the next change
aimed at the run's cost is aimed by measurement rather than by assumption.

## Scope

**In:** a `sections` mode on `tests/suitescan.py` enumerating the banner
sections inside `run_all_checks` over the suite's own tracked source; per-section
wall-clock timing written to `tests/.work/timing.tsv` during a run; a check
holding the file's heading set against the scanner's; a check holding the
seconds against the run's own total; the fifteen slowest printed at the end of a
green run; the measured profile recorded in this file; and the execution
couplings this milestone's planning found, written up as Known-issues entries.

**Out:** any change to how the suite executes — no parallelism, no job pool, no
per-leg work directories. Out: a way to run a subset of the suite → candidate
row, which the three whole-run accumulator sweeps block until they declare their
own domains. Out: per-render timing → candidate row; moving the literal
`quarto render` into a timing helper would empty the render domain that
`tests/suitescan.py pairs` sweeps.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh` writes `tests/.work/timing.tsv` during a full
      run — one row per banner section that `python3 tests/suitescan.py sections`
      reports inside `run_all_checks`, each row naming that section's banner
      heading and its wall-clock seconds; a successful run prints the fifteen
      slowest rows before its "All checks passed" line.
- [ ] AC2: The set of banner headings in `timing.tsv` equals the set
      `tests/suitescan.py sections` reports over the suite's own tracked source;
      a run whose two sets differ fails and names the headings each side lacks.
- [ ] AC3: The per-section seconds in `timing.tsv`, plus one row labelled
      `unattributed`, sum to the run's own measured wall clock within one second.
- [ ] AC4: `tests/run-tests.sh --self-test` is green, which is the profile's
      verify slot plus the planted-defect self-test the pre-review check runs.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T3
- AC3 → T3
- AC4 → T5, T6

## Tasks

- [ ] T1: Add a `sections` mode to `tests/suitescan.py`'s `MODES` dict
      (`tests/suitescan.py:152`), enumerating each `# ---` banner block's first
      heading line that falls inside `run_all_checks` (`tests/run-tests.sh:1715`
      to the function's close). It reads the tracked set `tracked()` already
      enumerates and honours the existing overlay argument. Note in its
      docstring that 39 banner blocks precede the function and are outside the
      domain by construction.
- [ ] T2: Time each such section in `tests/run-tests.sh`, appending
      `heading<TAB>seconds` to `$WORK/timing.tsv`. Emit the timing call from the
      banner sites themselves so the row set is not a hand-kept list, which
      would become the sweep and ship every section it omits untimed.
- [ ] T3: The two checks: heading-set equality against `suitescan.py sections`,
      naming the headings each side lacks; and the seconds plus an
      `unattributed` row against the run's own measured wall clock, within one
      second.
- [ ] T4: Print the fifteen slowest rows before the "All checks passed" line in
      the driver (`tests/run-tests.sh:25397-25406`).
- [ ] T5: Prove T3's set check discriminating: with the overlay handle, plant a
      copy of the suite with one section's timing call removed and show the
      check red naming that heading. The plant runs against the scanner alone —
      no nested suite run.
- [ ] T6: Run `tests/run-tests.sh --self-test` to green and record the measured
      profile in this file's work log: total wall clock, the fifteen slowest
      sections with their seconds, and the machine and commit measured.
- [ ] T7: Write the execution couplings this planning found as Known-issues
      entries under `DESIGN.md`'s acceptance-suite subheading — the three
      whole-run accumulator sweeps (`run-tests.sh:11771`, `:15747`, `:14313`),
      the fixed `$WORK` filenames written from many sites (`:1187` from 69 call
      sites, `:1433` from 19), the single backup slot `$WORK/one-record.json`
      restored by two unrelated sections (`:6373`, `:9806`, `:9953`), the
      whole-tree byte-identity assertion (`:17386`), and the two nested
      self-invocations truncating `$RAN_LEDGER` (`:14385`, `:15405`). Rewrite
      the parallel-legs candidate row to name these as the obstacle.

## Work log

- 2026-09-04: created by /milestone-plan.
- 2026-09-04: implement started on `m075-suite-timing-profile`; gate chose whole-second timestamps (`date +%s`) over a sub-second clock, because bash 3.2 and BSD `date` offer no sub-second source and 154 sections would each need two `python3` spawns, adding ~10s to the run being measured; and chose measuring the pre-first-section setup window directly over deriving it as the remainder, so a lost or double-written section row leaves the sum short and AC3's check red rather than absorbed.
- 2026-09-04: criteria audit ran in reduced mode (internal tier) on a fresh [O] reader that authored none of the criteria; six findings, all with one clear repair, all fixed before the gate — count-equality replaced by set equality; a checker-bound promise rewritten to bind the timing file; the row set's enumerator changed from hand-placed calls to a scanner mode; the domain narrowed to sections inside `run_all_checks` (39 banners precede it); a discrimination criterion moved to T5; and that plant's evidence moved off a nested 13-minute run onto the scanner's overlay handle.
- 2026-09-04: AC4 is the milestone template's standard verify-clean criterion for a code milestone, added after the criteria audit read AC1-AC3 and not put through it.
- 2026-09-04: plan gate chose measuring the run's cost over going straight at parallelism because the investigation found three whole-run accumulator sweeps, ~90 fixed shared work-directory filenames, and a whole-tree byte-identity assertion, several of them shipped milestones' acceptance criteria, putting any wall-clock gain three or more milestones out; falsified by a measurement showing the run's time concentrated in the 73 render sites already isolated in their own scratch trees.
- 2026-09-04: plan gate chose section-granularity timing over per-render timing because moving the literal `quarto render` into a timing helper would empty the render domain `tests/suitescan.py pairs` sweeps while its comment still claimed coverage; falsified by a section profile too coarse to locate the cost.
- 2026-09-04: plan gate chose timing alone over bundling a subset-selection mode because the three whole-run accumulator sweeps read what earlier sections produced, so a subset run would fail them or pass them vacuously; falsified by those three sweeps being reworked to declare their own domains.

## Decisions

## Review
