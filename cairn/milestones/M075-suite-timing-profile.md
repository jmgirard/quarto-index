# M075: The suite reports where its own time goes

- **Status:** review
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

- [x] T1: Add a `sections` mode to `tests/suitescan.py`'s `MODES` dict
      (`tests/suitescan.py:152`), enumerating each `# ---` banner block's first
      heading line that falls inside `run_all_checks` (`tests/run-tests.sh:1715`
      to the function's close). It reads the tracked set `tracked()` already
      enumerates and honours the existing overlay argument. Note in its
      docstring that the banner blocks preceding the function are outside the
      domain by construction.
- [x] T2: Time each such section in `tests/run-tests.sh`, appending
      `heading<TAB>seconds` to `$WORK/timing.tsv`. Emit the timing call from the
      banner sites themselves so the row set is not a hand-kept list, which
      would become the sweep and ship every section it omits untimed.
- [x] T3: The two checks: heading-set equality against `suitescan.py sections`,
      naming the headings each side lacks; and the seconds plus an
      `unattributed` row against the run's own measured wall clock, within one
      second.
- [x] T4: Print the fifteen slowest rows before the "All checks passed" line in
      the driver (`tests/run-tests.sh:25397-25406`).
- [x] T5: Prove T3's set check discriminating: with the overlay handle, plant a
      copy of the suite with one section's timing call removed and show the
      check red naming that heading. The plant runs against the scanner alone —
      no nested suite run.
- [x] T6: Run `tests/run-tests.sh --self-test` to green and record the measured
      profile in this file's work log: total wall clock, the fifteen slowest
      sections with their seconds, and the machine and commit measured.
- [x] T7: Write the execution couplings this planning found as Known-issues
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
- 2026-09-04: T1 done — `tests/suitescan.py sections` reports the 154 banner headings inside `run_all_checks` in source order. Its span is found from the call site backwards, the wrapper defining 86 helper functions at column zero so its close is not the first bare `}` after its head. It refuses a heading carrying a tab, repeating another, or equal to the reserved `unattributed` label, and refuses an empty domain. Suite green, 699 checks. T1's wording corrected: 19 banner blocks (39 rule lines) precede the function, not 39 blocks, so the docstring names no figure it would have to keep.
- 2026-09-04: T2/T3/T4 written and committed as a checkpoint with their boxes unticked: `tests/run-tests.sh` now opens a timed section at each of its 155 banner sites (154 pre-existing plus the accounting block T3 adds), writes `heading<TAB>seconds` rows and one measured setup row to `tests/.work/timing.tsv`, holds the row set to `suitescan.py sections` and the seconds to the run's own clock, and prints the fifteen slowest before the passing line. The 155 calls were generated from the scanner's own enumeration rather than placed by hand. `bash -n` clean; the accounting was smoke-tested standalone green on real headings and red on each of a declared section with no row, a row naming no declared section, five seconds taken off one row, and a malformed row. The `--self-test` verify run was in flight at this commit.
- 2026-09-04: T7 done, taken out of task order because it touches only `cairn/` and could land while the verify run held `tests/run-tests.sh`. KI241-KI245 record the five execution couplings under DESIGN's acceptance-suite-reads subheading, and the parallel-legs candidate row now points at them instead of restating them (313 bytes). KI245 corrects the plan's reading: the two nested self-invocations do truncate `$RAN_LEDGER`, but both `ran_clean` calls and M38-AC6's read of the ledger come after them, so the coupling is latent rather than live.
- 2026-09-04: T2/T3/T4 verified and ticked — `tests/run-tests.sh --self-test` green at 1299 checks in 29:30, `bash -n` clean, and the run's own accounting green: 155 declared sections each with exactly one row, no row naming anything else, and those rows plus a 1s setup row accounting for 1770s of the 1770s the run measured.
- 2026-09-04: T5 done, and widened from the one plant the task names to three, each red inside the same `--self-test` run and each naming what it planted: a section the source declares with no timing row (planted through the scan's overlay handle, which supplies bytes for a tracked path while git supplies the file list, so no nested suite run is needed), a timing row naming a section the reduced source no longer declares, and five seconds taken off one row with the heading set untouched, which only the total can see. A fourth guard refuses a malformed row. The same accounting call is the passing control, green on this run's own file two lines earlier.
- 2026-09-04: T6 profile, `tests/run-tests.sh --self-test`, 1770s total (29:30 wall), 1299 checks, on an Apple M5 Pro (18 cores, Darwin 25.6.0 arm64) at commit ef9f351, TinyTeX and Quarto warm. Setup before the first section 2s. Fifteen slowest, seconds then section: 709 the sweeps' own discrimination (M24); 310 M17-AC3; 67 M40; 58 AC5 planted-defect self-test; 42 the corpus reconciliation the report forces; 26 M070; 23 the store directory replaced by a regular file; 21 M068; 21 M33-AC3; 19 M04-AC2; 16 M02-AC3; 14 M063-AC3/M064-AC1/M064-AC2; 13 M21; 12 M26; 11 M06-AC1.
- 2026-09-04: T6 second profile, plain `tests/run-tests.sh` on the same tree and machine, 461s total (7:41 wall), 701 checks, setup 2s. Fifteen slowest: 61 M40; 23 the corpus reconciliation the report forces; 14 M33-AC3; 13 M04-AC2; 12 M57; 10 M02-AC3; 10 M070; 9 M072; 9 M20; 9 M21; 9 M26; 8 M06-AC1; 8 M17-AC3; 8 M19; 8 M32. Run beyond what T6 asks for, because the parallel-legs candidate row is about the plain run and the self-test profile would have aimed it at the wrong leg.
- 2026-09-04: what the two profiles say: the plain run is flat — its slowest section is 61s of 461s and its top fifteen are 211s of it — so splitting it into parallel legs buys little against the couplings KI241-KI245 name. The cost that exists is the self-test plants: the two sections that carry 1019s of the self-test run's 1770s cost 8s and 8s without `--self-test`. The earlier 13:30 figure the candidate row rested on was a cold-cache run of the same tree at df54c90; the same command warm is 7:41. The parallel-legs row is rewritten to say this.
- 2026-09-04: all seven tasks done; status review. Both verify runs green on the branch tree at ef9f351, code unchanged since: plain 701 checks (699 before this milestone, +2 for M075-AC2 and M075-AC3), `--self-test` 1299. Open concern for review: the fifteen-slowest print sits in the driver after `run_all_checks`, so it reaches neither the check count nor `run.log` — where AC1 asks for it, but the same shape KI30 records for M24's clean assertion.
- 2026-09-04: criteria audit ran in reduced mode (internal tier) on a fresh [O] reader that authored none of the criteria; six findings, all with one clear repair, all fixed before the gate — count-equality replaced by set equality; a checker-bound promise rewritten to bind the timing file; the row set's enumerator changed from hand-placed calls to a scanner mode; the domain narrowed to sections inside `run_all_checks` (39 banners precede it); a discrimination criterion moved to T5; and that plant's evidence moved off a nested 13-minute run onto the scanner's overlay handle.
- 2026-09-04: AC4 is the milestone template's standard verify-clean criterion for a code milestone, added after the criteria audit read AC1-AC3 and not put through it.
- 2026-09-04: plan gate chose measuring the run's cost over going straight at parallelism because the investigation found three whole-run accumulator sweeps, ~90 fixed shared work-directory filenames, and a whole-tree byte-identity assertion, several of them shipped milestones' acceptance criteria, putting any wall-clock gain three or more milestones out; falsified by a measurement showing the run's time concentrated in the 73 render sites already isolated in their own scratch trees.
- 2026-09-04: plan gate chose section-granularity timing over per-render timing because moving the literal `quarto render` into a timing helper would empty the render domain `tests/suitescan.py pairs` sweeps while its comment still claimed coverage; falsified by a section profile too coarse to locate the cost.
- 2026-09-04: plan gate chose timing alone over bundling a subset-selection mode because the three whole-run accumulator sweeps read what earlier sections produced, so a subset run would fail them or pass them vacuously; falsified by those three sweeps being reworked to declare their own domains.

## Decisions

## Review
