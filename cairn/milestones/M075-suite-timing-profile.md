# M075: The suite reports where its own time goes

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — instrumentation of the acceptance suite, which is dev tooling nothing outside the repo consumes
- **Branch/PR:** `m075-suite-timing-profile` / https://github.com/jmgirard/quarto-index/pull/75

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

- [x] AC1: `tests/run-tests.sh` writes `tests/.work/timing.tsv` during a full
      run — one row per banner section that `python3 tests/suitescan.py sections`
      reports inside `run_all_checks`, each row naming that section's banner
      heading and its wall-clock seconds; a successful run prints the fifteen
      slowest rows before its "All checks passed" line.
- [x] AC2: The set of banner headings in `timing.tsv` equals the set
      `tests/suitescan.py sections` reports over the suite's own tracked source;
      a run whose two sets differ fails and names the headings each side lacks.
- [x] AC3: The per-section seconds in `timing.tsv`, plus one row labelled
      `unattributed`, sum to the run's own measured wall clock within one second.
- [x] AC4: `tests/run-tests.sh --self-test` is green, which is the profile's
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
- 2026-09-04: review opened on PR #75; branch synced with `main` (0 behind), draft PR pushed. Consistency gate green: `cairn_validate` all PASS, no principle changed so no impact report, and the `generic` profile's consistency-gate slot names no toolchain checks. Criterion evidence and the three review lenses in flight.
- 2026-09-04: review evidence recorded and all four criteria ticked — one fresh `tests/run-tests.sh --self-test` at fb20b8b, exit 0, 1299 checks, 1191s; AC2 and AC3 also held independently of the run's own checks, AC3 against the final timing file and an outer wall clock (gap 0s). Three-lens review fan-out ran; thirteen findings, twelve from the diff-bug lens and one from the prior-review lens duplicating F3, all recorded in the Review section for triage at the gate.
- 2026-09-04: gate approved fixing the four confirmed review findings, re-verifying, and merging on green. F1, F2, F6, F8 and F11's print header fixed on the branch and each verified standalone; F3 routed to a Known-issues entry, F4/F5/F7/F9/F10 and F11's fragment headings to the suite check-discrimination candidate row, F12 rejected. Full re-run in flight.
- 2026-09-04: re-verification green at b1c51c4 — `tests/run-tests.sh --self-test` exit 0, 1299 checks, 1208s; all four criteria held again, AC3 also against an outer wall clock (1209s of 1209s). step-7 approval: PR #75 approved for merge.

## Decisions

## Review

Verified 2026-09-04 on branch head `fb20b8b`, PR #75, against `main` at
`69f867e`. One fresh full run: `tests/run-tests.sh --self-test`, exit 0,
1299 checks, on an Apple M5 Pro (Darwin 25.6.0 arm64), TinyTeX and Quarto
warm.

**AC1 — green.** The run wrote `tests/.work/timing.tsv`: 156 rows, each
`heading<TAB>seconds`, one for each of the 155 headings `python3
tests/suitescan.py sections` reports inside `run_all_checks` plus the one
`unattributed` setup row. The run printed `== the fifteen slowest of 156
timed rows (1191s in all, tests/.work/timing.tsv) ==` and its fifteen rows
immediately before `All checks passed (1299 checks).`

**AC2 — green.** The run's own `M075-AC2` check passed over 155 sections.
Held independently of that check afterwards: the final file's headings less
`unattributed`, sorted, are byte-identical to `python3 tests/suitescan.py
sections` sorted (`diff` empty), with no repeated heading. Shown able to
fail inside this same run — T5's three plants each went red and each named
what it planted (a declared section with no row; a row naming no declared
section; five seconds off one row), the same call passing on the run's own
file two lines earlier.

**AC3 — green.** The run's own `M075-AC3` check passed. Held independently
against the FINAL file, which the in-run check does not cover because
`section_close` writes the last row after it: the 156 rows sum to 1191s,
and a wall clock this session took outside the suite — before invoking it
and after it exited — is 1191s. Gap 0s, inside the one-second tolerance.

**AC4 — green.** `tests/run-tests.sh --self-test` exit 0, 1299 checks,
1191s (19:51). The work log's earlier 1770s figure was the same tree
measured colder; the section ranking is unchanged in shape, the M24
discrimination sweep still carrying more than half the run (644s of 1191s).

**Consistency gate — green.** `cairn_validate.py` all PASS, every advisory
OK (the release-window advisory did not fire). No `DESIGN.md` principle
changed, so no impact report was owed. The `generic` profile's
`consistency-gate` slot names no toolchain checks, so that half is a no-op.

**Triage at the gate.** The maintainer chose to fix the four confirmed
defects, re-verify, and merge on green.

- F1 — fix now. `banner_headings` takes the first comment line that carries
  text, and every other way a block can fail to yield a heading (a block with
  no such line; a block no second rule closes) is reported rather than
  skipped. A lone divider is still stepped over. Verified: the unplanted
  enumeration is byte-identical at 155 headings in the same order, and the
  planted empty-first-line block is now reported.
- F2 — fix now. `awk` truncates to fifteen rows instead of `head`, so no
  writer in the pipeline is cut off. Verified: 200,000 rows now exit 0 where
  the old pipeline exited 141.
- F6 — fix now. The headings are written to `sys.stdout.buffer` on a pinned
  UTF-8 encoding. Verified: 155 headings under `LC_ALL=C`, exit 0.
- F8 — fix now. The row guard rejects a second leading `-` rather than
  passing it to `int()`. A single leading `-` stays legal, so T5's
  five-seconds-short plant is untouched. Verified: `--5` rejected cleanly,
  `-5` still accepted.
- F11, the print header — fix now. It now counts and sums the section rows
  and names the setup seconds separately, instead of calling all 156 rows
  section rows. F11's truncated fragment headings — follow-up.
- F3 — accepted as a limitation, recorded in `DESIGN.md`'s Known issues at
  the hygiene pass; it is within AC1's letter and the same shape KI30
  already carries.
- F4, F5, F7, F9, F10 — follow-up, absorbed into the suite check-discrimination
  candidate row at the hygiene pass.
- F12 — rejected. The two implement-gate choices are milestone-local and are
  in the work log with their falsifiers; the cross-cutting decisions file is
  for decisions that bind beyond one milestone, and neither does.

**Re-verified after the gate-directed fixes**, branch head `b1c51c4`:
`tests/run-tests.sh --self-test` exit 0, 1299 checks, 1208s on the run's own
clock. AC1 — 156 rows written, fifteen slowest printed before the passing
line, the header now reading `the fifteen slowest of 155 section rows (1207s,
plus 2s of setup before the first section)`. AC2 — the run's own check green
over 155 sections, the final file's headings again byte-identical to the
scanner's with no duplicate, and T5's three plants again red. AC3 — the run's
own check green, and the final 156 rows sum to 1209s against an outer wall
clock of 1209s, gap 0s. AC4 — exit 0, 1299 checks. The one-second difference
between the run's in-check total (1208s) and the final file (1209s) is F4's
exposure measured: the check reads its clock before the T5 block, and
`section_close` writes the M075 row afterwards.

**PR conversation.** Read on PR #75 before the gate: no reviews, no
conversation comments, no unresolved threads.

**Independent review.** Executable surface touched, so the full three-lens
fan-out ran, each lens fresh-context and none having seen the work.
[S] blame-history: no findings — the diff is purely additive, `check_reads`,
`check_pairs`, `tracked()` and the overlay argument are byte-identical to
`main`, and the `TIMING` truncation guard mirrors the existing `$WORK` and
`$RUN_LOG` guard against both nested self-invocations.
[S] prior-review: the PR-comment probe returned `[]` (no inline review
comments in this repo at all), so the archived `## Review` sections were the
whole surface; one finding, the same as F3 below.
[O] diff-bug: twelve findings, below in the reviewer's own ranking.

F1. A banner block whose first comment line is empty is silently dropped
from the section domain (`tests/suitescan.py`, `banner_headings`): `heading`
stops being `None`, so the real heading on the next line never replaces it,
and the `and heading` test skips the block with no error. Such a section
needs no timing call, runs untimed, and AC2 and AC3 both stay green.
Confirmed at review against an overlay: 155 reported, exit 0, planted
heading absent.

F2. `sort … | head -15` (the driver's fifteen-slowest print) can kill a
fully green run: `set -euo pipefail` is still in force, `head` exits after
15 lines, and once `sort`'s output outgrows the pipe buffer the pipeline
reports 141 and the script exits after every check has passed, with no FAIL
line and no `All checks passed`. Confirmed at review: 156 rows survive,
200,000 rows exit 141.

F3. The fifteen-slowest print sits outside `run_all_checks`, so it reaches
neither `run.log` nor the check count, and nothing checks it. Within AC1's
letter, which asks only that it print before the passing line, and the same
shape KI30 already records for M24's clean assertion. Raised independently
by the prior-review lens as a regression of that finding.

F4. The accounting reads its clock at the top of its own section, so
everything after it — the whole T5 block, `section_close`, the driver print
— is outside AC3's domain, and the row `section_close` later writes for the
M075 section is larger than the one the check saw. Measured today the gap is
0s against an outer clock; the exposure is to that tail growing.

F5. `section_close` clears `SECTION_HEADING`, which is the same state that
means "before the first section", so a `section` call added after it would
write a second `unattributed` row valued at the whole run's wall clock, and
the accounting runs earlier so its one-setup-row guard would not see it.

F6. `sections` mode prints headings under the locale encoding while every
read in the file pins UTF-8; under an ASCII stdout locale the run dies at
AC2's first line with `UnicodeEncodeError`. Confirmed at review under
`LC_ALL=C`: exit 1 on an em dash.

F7. The 155 `section '<heading>'` lines make banner heading text executable
source, which `check_reads` and `check_pairs` both sweep, so a future
heading containing an artifact path or the render command would make M24's
own sweeps report a violation. None of the 155 current headings does.
Extends KI31.

F8. The accounting's row guard admits `--5` (`lstrip('-').isdigit()`) and
then raises an uncaught `ValueError` in `int()`, so that shape produces a
traceback rather than the intended FAIL line. Confirmed at review.
Separately, a negative row value is accepted, so a backwards clock step
could leave a telescoping sum that still matches the total.

F9. The T5 plant treats any `# ` followed only by dashes as a banner rule
while the scanner requires ten or more, so a `# -` line could make the plant
delete a block the scanner never counted and fail the self-test for a reason
unrelated to the check being probed. Test-only, unreachable today.

F10. `m075_plant_source drop`'s inner scan has no upper bound, so an
unclosed trailing banner block would raise `IndexError` rather than its
intended message. Test-only.

F11. A heading is the banner's first LINE, so a wrapped prose banner yields
a truncated sentence fragment in the profile; and the print's header calls
all 156 rows "timed rows" and sums them, though one is the setup row rather
than a section.

F12. The milestone's `## Decisions` section is empty: the two implement-gate
choices are in the work log with their falsifiers rather than as entries.

