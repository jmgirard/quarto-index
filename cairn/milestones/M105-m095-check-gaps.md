<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M105: Three M095 checks each fail on the gap its review found

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — it changes test-suite checks only, and no author or other consumer of the extension relies on them
- **Branch/PR:** m105-m095-check-gaps

## Goal

The state probe, the `Bramble` check and the `outside-heading` check each
fail on the gap the M095 review found in it.

## Scope

**In:** KI284 to KI287 (`cairn/DESIGN.md`, Known issues). KI284: a line
added to a module's `reset` and not to `CELLS` in `tests/stateprobe.py` gets
no per-cell probe, and `indexes.lua`'s module probe keeps it. A new guard
reads every reset line from source and fails on one `CELLS` does not hold.
The suite runs the guard, and the state probe runs it before any render.
KI285: the `Bramble` check's negative control borrows the `m063-refuseold`
capture. It gets a plant on its own page instead. KI286: `outside-heading`
in `tests/fragments.py` accepts any wrapper and any heading level. It takes
the two tags from the call instead. KI287 is struck with no edit. The M26 leg
comment (`tests/run-tests.sh:17746`) already points at `CELLS` and at the
probe's output instead of stating a count. The plan gate chose that form.

**Out:**

- A `CELLS` row whose statement no longer sits in its module's reset. When
  the probe runs, `plant()` in `tests/stateprobe.py` stops on such a row
  today. The four known issues do not ask for more.
- Running the state probe's renders in the suite or in CI. It stays a hand
  run (DESIGN.md, the accumulator paragraph near line 258).
- KI288, the case-sensitive retired-sentence sweep. It stays a Known issue.

## Acceptance criteria

- [ ] AC1: `python3 tests/stateprobe.py --check-cells` reads each module
      under `_extensions/index/modules/` whose source defines
      `local function reset(`. In each, it reads every non-blank, non-comment
      line between that line and the function's closing `end`. The kept lines
      are the five `indexes.lua` lines `order[1] = UNNAMED`,
      `titles[UNNAMED] = DEFAULT_TITLE`, `if doc ~= nil then`,
      `read(doc.meta)` and `end`. The statement of a `CELLS` row for its
      module passes. In `indexes.lua`, a kept line also passes.
      For any other line, the guard exits non-zero and names the module and
      the line. It exits zero
      on the merged tree. `tests/run-tests.sh` runs it.
      `tests/run-tests.sh --self-test` shows it red, naming the line, on a
      copy of the modules whose `indexes.lua` reset holds one added line.
- [x] AC2: In `tests/run-tests.sh --self-test`, the M095-AC3 `Bramble` check
      reads a copy of the `place-oldstore` capture's `index.html`. In the
      copy, the href of `Bramble`'s locator in the `alpha` section changes
      from `two.html#qi-mark-1` to `two.html`, and nothing else changes. On
      that copy the check is red and names the href it read. The same check
      passes on an unchanged copy of that page. The M063 T2 leg no longer
      runs the M095-AC3 check.
- [x] AC3: `tests/fragments.py outside-heading` takes two tags from the call.
      The element carrying the named id must have the first tag. Its first
      direct child tagged `h1` to `h6` must have the second. If either
      differs, the check fails and names the tag it found. The M095-AC3 call
      names `section` and `h2` and passes on `four.html` from each
      `place-blocked-$M061_PASS` render. `tests/run-tests.sh --self-test`
      runs it on two copies of `place-blocked-one`'s `four.html`. In one,
      that element's opening and closing tags are renamed to `div`, and the
      check is red and names `div`. In the other, that heading's opening and
      closing tags are renamed to `h3`, and the check is red and names `h3`.
      Each copy is otherwise unchanged.
- [ ] AC4: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: In `tests/stateprobe.py`, add a `KEPT` list holding the five
      `indexes.lua` lines, and a guard that reads each module's reset with
      `reset_body` (line 112). Find the modules by searching
      `_extensions/index/modules/` for `local function reset(`, never by a
      fixed list. `--check-cells [module-dir]` runs only the guard, and `main`
      (line 233) runs it before the control sweep. Update the docstring. In
      the M26 section of `tests/run-tests.sh` (line 17749), run the guard
      before the renders. Under `--self-test`, copy the modules to `$WORK`.
      Add one line to the copy's `indexes.lua` reset with one substitution,
      and assert that the copy changed. Require the guard red and naming that
      line. Show the unplanted copy green first (check-design M42).
- [x] T2: Under `--self-test`, after the M095-AC3 `Bramble` check
      (`tests/run-tests.sh:11365`), copy the `place-oldstore` `index.html`
      to `$WORK`. Show the check green on the copy. Then rewrite the one
      `Bramble` href in the `alpha` section with one substitution. Assert
      that exactly one site changed, and require the check red, naming
      `two.html`. Remove the M095-AC3 probe from the M063 T2 leg (lines
      11429-11439) and the clause naming it in that leg's `pass` line.
- [x] T3: In `tests/fragments.py`, give `outside-heading` two arguments, the
      container tag and the heading tag, ahead of the ids. Update
      `outside_heading` (line 145), its failure messages, and the docstring
      (lines 28-33). Pass `section` and `h2` at the call
      (`tests/run-tests.sh:8961`) and in the three plant runs (line 9046).
      Add the `div` and `h3` plants to the plant builder near line 9013, each
      asserting its rename changed the page. Run the mode's plants under
      Python 3.9 and 3.12 (LESSONS M082).
- [x] T4: Remove KI284 to KI287 from `cairn/DESIGN.md` Known issues, and add
      the guard to the accumulator paragraph near line 258. Run
      `tests/run-tests.sh` and `tests/run-tests.sh --self-test` with no
      edits to the suite during either run (LESSONS M073), and record each
      result in the work log.

## Work log

- 2026-10-01: created by /milestone-plan. Promotes the M095-review candidate row (KI284-KI287), which the plan commit removes.
- 2026-10-01: criteria audit (reduced mode, fresh Opus reader) returned 7 findings, all with one clear fix, applied before the gate. AC1 names the kept lines literally, reads "statement" as a non-blank non-comment line, and names the suite's self-test. AC2 says the M063 T2 leg drops the check. AC3 names each plant's reported tag, renames both tags, reads each `place-blocked` render, and defines the heading child. The plan then split AC1-AC3 into shorter sentences with no change of meaning.
- 2026-10-01: plan gate chose a guard over every reset line over deriving the `reset:indexes` drop list from the reset body, because the guard also closes the missing per-cell probe and the derived list alone does not; falsified by a reset line the guard cannot classify as cell or kept.
- 2026-10-01: plan gate chose to strike KI287 with no edit over restoring the counts with arithmetic, because the comment already points at `CELLS` and the probe output; falsified by a reader of the M26 leg unable to find which fixture moves which cell.
- 2026-10-01: plan gate chose to run the guard in every suite run over the state probe alone, because the probe's renders run only by hand; falsified by the guard turning a suite run red on a tree whose resets are covered.
- 2026-10-01: plan chose to move the `Bramble` control off the M063 T2 leg over keeping both, because the borrowed control adds no evidence the new plant lacks; falsified by a defect the refused-record page catches and the planted copy does not.
- 2026-10-01: plan chose call arguments for the two tags in `outside-heading` over fixing `section` and `h2` inside the mode, because the mode is general and the shape belongs to the M095-AC3 call; falsified by a second caller needing a different rule than two tags.

- 2026-10-01: implement started on branch m105-m095-check-gaps. No question gate, because the plan left nothing open.
- 2026-10-01: T1 code landed: the `check_cells` guard and `KEPT` in `tests/stateprobe.py`, run in the M26 section with a self-test plant. Run in isolation, it is green on the tree (26 reset lines) and red on the planted copy, naming the line. T1 stays unticked until a full suite run passes.
- 2026-10-01: T2 code landed: an own-page `Bramble` plant under `--self-test` after the M095-AC3 check, and the borrowed probe and its pass clause removed from the M063 T2 leg. Run in isolation on the last capture, it is green on the copy and red naming `two.html`, with one line of the page changed. T2 stays unticked until a full suite run passes.
- 2026-10-01: the first full `--self-test` run at the T1 commit stopped at M063-AC1 on a Quarto segmentation fault inside Deno, before any M105 check ran. It is no evidence either way, and the run is repeated after T4.
- 2026-10-01: T3 code landed. `outside-heading` takes the container and heading tags ahead of the ids, and the call and plant runs pass `section h2`. The `div` and `h3` plants are new. Under Python 3.9.6 and 3.14.7 on the last capture, the call passes on both `place-blocked` renders. Each plant is red, naming its tag. Python 3.12 is not installed here, so 3.14.7 stands in as the newest in reach. T3 stays unticked until a full suite run passes.
- 2026-10-01: T4 edits landed. KI284 to KI287 are struck from `cairn/DESIGN.md`, and the accumulator paragraph names the guard. KI288 stays. Both full suite runs are pending.
- 2026-10-01: a `--self-test` run at 287507e in a scratch worktree passed all five M105 checks. It then stopped at M098-AC4's Typst render on a second Quarto segmentation fault inside Deno. The same run in the main checkout passed.
- 2026-10-01: at 287507e, with no suite edits during either run, `tests/run-tests.sh --self-test` passed (1738 checks) and `tests/run-tests.sh` passed (898 checks). T1 to T4 are ticked.
- 2026-10-01: claim audit: not owed — internal tier.
- 2026-10-01: status set to review.
- 2026-10-01: review started. Self-test passed (1738 checks), AC2 and AC3 ticked. AC1 not met: a column-0 inner `end` hides later reset lines from the guard. Plain suite run pending.

## Decisions

## Review

Review run 2026-10-01 at bfacc41, branch already holding `origin/main`.
Suite runs used `/usr/bin/python3` (3.9.6) first on the PATH. A python.org
Python 3.14.6 was installed at 13:22 that day, after the green implement
runs. It shadows `/usr/bin/python3` and has no PyYAML. The first self-test
attempt stopped at the PyYAML check of `tests/editormeta.py`, before any
M105 check ran.

- AC1 (not met): `python3 tests/stateprobe.py --check-cells` exits 0 on the
  tree, reading 26 reset lines across indexes, latex, marks and sortkeys.
  The self-test prints `M105-AC1` green and `M105-AC1 self-test` red naming
  the planted line. A scratch copy of the modules shows a gap. In its
  `indexes.lua` reset, the `if` block's `end` moves to column 0 (valid Lua),
  and `qi_core.empty(newcell)` is added before the function's closing `end`.
  On that copy the guard exits 0 and reads 25 lines. `reset_body` stops at
  the first column-0 `end`, so it never reads the lines after it. AC1
  promises every line up to the function's closing `end`. Here a line that is
  neither a `CELLS` statement nor kept passes. Box left unticked.
- AC2: in the `--self-test` run, `M105-AC2 self-test (an unchanged copy of
  the page)` is green and `M105-AC2 self-test` is red on the planted copy,
  naming `two.html`. The plant is one `sed` substitution. The suite asserts
  that it takes the anchored href from one site to none. The diff removes
  the M063 T2 probe and its pass clause, and no `M095-AC3` line prints in
  that leg.
- AC3: `outside_heading` in `tests/fragments.py` takes the container and
  heading tags and fails naming the tag it found. The call passes `section h2`.
  It is green on `four.html` from both `place-blocked` renders, with two `ok`
  lines that name the `<section>` and the `<h2>`. `M105-AC3 self-test`
  is red on the `div` and the `h3` copies, each naming its tag.
- Consistency gate: `cairn_validate.py` exits 0, all checks passed. No
  DESIGN principle changed, so no impact report. The generic profile names no
  toolchain checks.
