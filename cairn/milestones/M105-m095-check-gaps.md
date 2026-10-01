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

- [x] AC1: `python3 tests/stateprobe.py --check-cells` reads the reset of
      each module that `CELLS` names, in `_extensions/index/modules/`. If it
      cannot find exactly one `local function reset(` line outside comments
      that opens the reset the module exports, it exits non-zero and names
      the module. Otherwise it reads every line that holds code outside
      comments and strings, from that line to the function's closing `end`.
      The kept lines
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
- [x] AC4: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T1, T5, T6, T9, T11
- AC2 → T2, T7, T11
- AC3 → T3, T7, T11
- AC4 → T4, T8, T12

## Tasks

- [x] T1: In `tests/stateprobe.py`, add a `KEPT` list of the five
      `indexes.lua` lines and a guard over every module's reset, found by
      search, never by a fixed list. `--check-cells` runs only the guard, and
      `main` runs it before the control sweep. The M26 section of
      `tests/run-tests.sh` runs it before the renders. Under `--self-test`,
      show an unplanted copy green, then a copy with one added `indexes.lua`
      reset line red, naming that line (check-design M42).
- [x] T2: Under `--self-test`, after the M095-AC3 `Bramble` check, show the
      check green on a copy of the `place-oldstore` `index.html`, then red,
      naming `two.html`, after one substitution of the one `Bramble` href in
      `alpha`. Remove the M095-AC3 probe and its pass clause from the M063 T2
      leg.
- [x] T3: In `tests/fragments.py`, give `outside-heading` the container and
      heading tags ahead of the ids, with its messages and docstring. Pass
      `section` and `h2` at the call and in the plant runs. Add the `div` and
      `h3` plants, each asserting its rename changed the page. Run the plants
      under Python 3.9 and 3.12 (LESSONS M082).
- [x] T4: Remove KI284 to KI287 from `cairn/DESIGN.md` Known issues, and name
      the guard in the accumulator paragraph. Run both suite modes with no
      suite edits during either run (LESSONS M073), and log each result.
- [x] T5 (review return 1): Make `reset_body` read to the function's own
      closing `end` by counting Lua blocks, not by the first column-0 `end`.
      Skip the lines of a `--[[ ]]` block comment. Find the modules through
      `tests/filtersrc.py`, kept to `modules/`. Make each guard failure name
      its module and cause, and make the suite message match (R1, R3, R4,
      R8). Add a self-test plant with a column-0 inner `end` and a stray line
      after it, red naming that line.
- [x] T6 (review return 1): Add a D-entry that narrows D-011 for this guard,
      with its reason, and edit KI10's sentence that says D-011 refuses the
      scan (R2).
- [x] T7 (review return 1): Fix the wording of R5, R6 and R7. Add the
      asserts of R9, R10 and R11. Rename the parameter of R12.
- [x] T8 (review return 1): Repeat T4's two suite runs and record each
      result in the work log.
- [x] T9 (review return 2): Find each module's reset with Quarto's Lua
      (`quarto pandoc lua`): load the module and read the first and last
      line of the exported `reset` from `debug.getinfo`. Stop counting
      blocks by hand. Read the opener line's code too. Add self-test plants
      for V1 and V3, each red naming the stray line, and for V2, red naming
      both opener lines (V12, V14).
- [x] T10 (review return 2): Fix the wording of V4. Add one entry that
      supersedes D-062's claim on what the probe drops (V5). Add Known issues
      entries for the accepted gaps (V9). Fix KI10's "Four" (V10).
- [x] T11 (review return 2): Add the asserts and plants of V6, V7 and V8.
      Plant the AC2 copy with `perl` (V11). Compare absolute paths before
      the probes refuse to run (V13).
- [x] T12 (review return 2): Repeat T4's two suite runs and record each
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
- 2026-10-01: plain suite run passed (898 checks). Three fresh reviewers reported 17 findings, logged in the Review section.
- 2026-10-01: review return 1 (defect): AC1 fails, because `reset_body` stops at a column-0 inner `end`, so the guard never reads the reset lines after it. Status back to in-progress. The user chose send-back at the gate, and a D-entry that allows the guard (R2). Tasks T5 to T8 added, Coverage amended, AC2 to AC4 unticked.
- 2026-10-01: implement resumed on the branch, `main` unmoved. No question gate, because the review gate settled the one open choice (R2).
- 2026-10-01: T5 code landed. `reset_body` counts Lua blocks over code with comments and strings removed. Modules come through `tests/filtersrc.py` under `modules/`, and every guard failure names its module and cause. The self-test adds a column-0 `end` plant (red, naming the line) and a block-comment copy (green), and matches one whole report line (R11, same block). The R5 and R6 wording in this block and in `tests/stateprobe.py` landed here too. On the real modules the new reader returns the same lines as the old one. Under Python 3.9.6 and 3.14.7, the extracted block passes. It is red against a mutant with the old `end` rule, and against one that reads `--[[` as a line comment. T5 stays unticked until T8's suite runs.
- 2026-10-01: T6 done. D-062 narrows D-011 so the cell guard may read reset source, and KI10 now names the direction the guard checks. Tracking only, so ticked now.
- 2026-10-01: T7 code landed. The plant-builder comment names five copies, and the M095-AC3 pass line names its three (R7). If `rename()` or the `h3` plant aims at an element the check does not read, the plant builder now stops (R9). The AC2 plant asserts one changed line and a copy shorter by 10 bytes (R10). The `outside_heading` parameter is now `container` (R12), renamed by a short script inside that one function. Run alone on the last captures under Python 3.9.6 and 3.14.7, both blocks pass. The R9 assert is red on a copy with a heading before the `<h2>`. The R10 assert is red on a plant that changes a second byte. The macOS `sed` keeps a missing final newline, so R10's newline case does not arise here. T7 stays unticked until T8's suite runs.
- 2026-10-01: at cf7a4b4, with `/usr/bin/python3` (3.9.6) first on the PATH and no suite edits during either run, `tests/run-tests.sh --self-test` passed (1738 checks) and `tests/run-tests.sh` passed (898 checks). T5, T7 and T8 are ticked.
- 2026-10-01: claim audit: not owed — internal tier.
- 2026-10-01: status set to review.
- 2026-10-01: review run 2 started at 66991d0, branch holding `origin/main`. Validate passed. Three fresh reviewers reported 21 findings, logged in the Review section.
- 2026-10-01: AC1 not met: a commented-out reset opener above the real one makes the guard read the copy, so a stray line in the real reset passes (V1, reproduced). The self-test run was stopped by hand at 876 checks, all M105 checks green, because the return makes its evidence stale.
- 2026-10-01: review return 2 (defect): AC1 fails, because a commented-out reset opener above the real one makes the guard read the copy (V1). AC1 failed twice by the same shape, a hand-written reader that misplaces the reset. The user chose to let Quarto's Lua find the reset, and accepted the proposed dispositions. Status back to in-progress. Tasks T9 to T12 added, Coverage amended.
- 2026-10-01: implement resumed on the branch, `main` unmoved. No question gate, because `quarto pandoc lua` loads each module and reports its exported reset's lines, so the gate's choice works as stated.
- 2026-10-01: T9 code landed. `tests/stateprobe.py` takes each reset's first and last line from Quarto's Lua (`debug.getinfo` on the exported `reset`), needs one opener line outside comments per module, and reads code after the opener's parameter list. A short string continued by a backslash now spans lines (V14). On the real modules the probes' `reset_lines` returns the same rows as before. Eleven earlier hand plants behave as before, and V1, V3 and a one-line reset are red naming the line (V12). V2 is red naming both opener lines, so T9's wording now says so (minor edit). The three new self-test plants each turn the block red when run against the pre-T9 reader. T9 stays unticked until T12's suite runs.
- 2026-10-01: T10 done. The R5 wording in `tests/stateprobe.py` and the M26 comment now says `plant()` stops only on a second copy of a `CELLS` statement (V4). D-063 supersedes D-062's sentences on what the probe drops, and records that Quarto's Lua gives each reset's bounds (V5). KI306 to KI308 record the accepted gaps (V9), and KI10 says "Four of the accumulators" (V10). Tracking and comments only, so ticked now.
- 2026-10-01: T11 code landed. A red AC1 plant puts a stray line after a block comment, and is red against a mutant reader that never leaves a block comment (V6). The guard prints the lines it read before its verdict, and each red plant asserts that line over the four modules, which goes red when the line is renamed (V8). The `div` and `h3` copies pass when called with the tags they carry, and that turns red against a mutant that ignores its tag arguments (V7). The AC2 plant uses `perl` (V11). The probes compare real paths before refusing (V13). Run alone, the AC1, AC2 and AC3 blocks pass on the last captures under Python 3.9.6, and the AC3 block under 3.14.6. T11 stays unticked until T12's suite runs.
- 2026-10-01: at b0d49c2, with `/usr/bin/python3` (3.9.6) first on the PATH and no suite edits during either run, `tests/run-tests.sh --self-test` passed (1738 checks) and `tests/run-tests.sh` passed (898 checks). T9, T11 and T12 are ticked.
- 2026-10-01: claim audit: not owed — internal tier.
- 2026-10-01: status set to review.
- 2026-10-01: review run 3 started at 1a9f5f8, branch holding `origin/main`. AC1 not met: the guard does not find a module whose `local function reset(` line has its parameter list on the next line (Review section). Self-test run in progress.
- 2026-10-01: both suite runs passed at 1a9f5f8 (1738 and 898 checks), so AC2 to AC4 are ticked. Validate passed. Review return 3 (defect): AC1 fails on a reset opener whose parameter list is on the next line. The disposition goes to the user.
- 2026-10-01: thrash rule (third return): the user chose to narrow M105 over parking, a re-plan or a brief. Status back to in-progress for the amendment alone. Removing AC1 changes the Goal, so the narrowing keeps AC1 and limits its domain.
- 2026-10-01: the amendment put the plan-owned body at 150 lines, so T1 to T4 were compressed in one rewrite: line-number pointers dropped, meaning kept.
- 2026-10-01: status set to review. AC1 ticked against the amended wording, from the run-3 plants and suite runs, since no code changed. Independent review next.
- 2026-10-01: three fresh reviewers reported 15 findings (W1 to W15, Review section). Review return 4 (defect): AC1 fails on its amended wording, because a new module that hides its reset from the guard's lexer (`\z` string, `#!` first line, or a `..` file name) passes unread. AC1 unticked. The disposition goes to the user.
- 2026-10-01: thrash rule (fourth return): the user chose to narrow AC1 again over parking, a re-plan or a brief. No fresh reader ran, because AC1 already carries two re-audit lines, so the user approved the wording as shown. Status stayed review, because no code changed.
- 2026-10-01: AC1 amended at the gate, chosen by the user: "reads the reset of each module that `CELLS` names, in `_extensions/index/modules/`. If it cannot find exactly one `local function reset(` line outside comments that opens the reset the module exports, it exits non-zero and names the module. Otherwise it reads every line that holds code outside comments and strings, from that line to the function's closing `end`." KI308 now records the new-module gaps (W1, W2, W5, W10). AC1 ticked on fresh hand plants.
- re-audit: AC1 (reduced) — first reader: a module with two openers, or whose opener is not the exported reset, fails without naming a stray line. Fixed by limiting the domain to one opener that opens the exported reset. Pre-existing wording (trailing comments, the self-test sentence) left as is.
- re-audit: AC1 (reduced) — second reader: no in-domain stray line passes, except a module behind a symbolic link, which `tests/filtersrc.py` does not follow. Recorded in KI308. Other findings fail closed.
- 2026-10-01: AC1 amended at the mini gate, chosen by the user: "reads each module under `_extensions/index/modules/` that has exactly one line, outside comments and strings, opening with `local function reset(` and closing its parameter list on that same line, where that line opens the function the module exports as `reset`". KI308 in `cairn/DESIGN.md` now records the split-parameter and symbolic-link forms.

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
- AC4: `tests/run-tests.sh --self-test` passed (1738 checks), and then
  `tests/run-tests.sh` passed (898 checks). The two runs were sequential, with
  no suite edits during either.
- Consistency gate: `cairn_validate.py` exits 0, all checks passed. No
  DESIGN principle changed, so no impact report. The generic profile names no
  toolchain checks.

Independent review: three fresh reviewers (Opus diff-bug, Sonnet
blame-history, Sonnet prior-review). Findings merged where two reviewers
named one defect. Each line gives the proposed disposition, decided at the
merge gate.

- R1 (diff-bug 2, reproduced here): a column-0 `end` inside the reset ends
  `reset_body`'s read, so later lines pass unseen. AC1 fails. Proposed: fix
  now, a return to implement.
- R2 (diff-bug 1, blame 1): the guard is a scan of the extension's source,
  which D-011 refuses without a superseding entry. KI10 still says D-011
  refuses that scan. Proposed: fix now, an entry that narrows D-011 for this
  guard and a KI10 edit.
- R3 (diff-bug 4): lines inside a `--[[ ]]` block comment are read as
  statements, a false red. AC1 reads non-comment lines only. Proposed: fix
  now with R1.
- R4 (diff-bug 3): a guard failure that is not a stray line prints a false
  suite message. An unterminated reset names no module. Proposed: fix now.
- R5 (prior 2, diff-bug 6, blame 3): the M26 comment and the docstring say
  no gained line goes without a probe. A duplicate of an allowed line passes
  (plan Out). Proposed: fix the wording now, reject the guard change.
- R6 (diff-bug 5): the docstring says a module that gains a reset is read
  with no edit. A reset in another form is not found (AC1 names the form).
  Proposed: fix the wording now.
- R7 (blame 5, prior 1): the plant-builder comment still says three copies,
  and the pass line at 9092 names only the moved-id plants. Proposed: fix now.
- R8 (blame 2): the guard lists `modules/` itself, not through
  `tests/filtersrc.py` (M16-AC2). Proposed: fix now with R1.
- R9 (diff-bug 7): `rename()` does not assert it renamed the intended tag.
  Proposed: fix now.
- R10 (diff-bug 8): AC2's "nothing else changes" rests on the href count
  alone. BSD `sed` can add a final newline. Proposed: fix now, assert that
  one line differs.
- R11 (diff-bug 9): the AC1 self-test `case` pattern can match across two
  report lines. Proposed: fix now, match one line.
- R12 (diff-bug 11): `outside_heading` still names its container id
  `section`. Proposed: fix now.
- R13 (diff-bug 10): the M063-AC2 pass line now prints after the M105-AC2
  lines. Proposed: reject, output order only.
- R14 (blame 4): KI287 is struck with no edit. Proposed: reject, the plan
  gate chose this.
- R15 (blame 6): the `Bramble` control is now a planted copy, not a second
  render. Proposed: reject, the plan and AC2 chose this.
- R16 (blame 7): T3 ran Python 3.14.7, not 3.12. Proposed: reject, logged
  in the work log, and 3.9 and 3.14 bracket 3.12.
- R17 (prior 3): a `CELLS` row whose statement left the reset is caught only
  by the hand-run probe. Proposed: reject, plan Out.

Gate 2026-10-01: the user chose to send M105 back to implement. R1 to R12
are fix-now, as tasks T5 to T7, and T8 repeats both suite runs. R13 to R17
are rejected for the reasons given. For R2, the user chose a new decision
that allows the guard over removing it. AC2 to AC4 are unticked, because T7
and T8 change the code their evidence covers. The next review takes fresh
evidence for all four.

### Review run 2 (2026-10-01, at 66991d0)

The branch holds `origin/main`, and `main` has no unpushed commits. Runs used
`/usr/bin/python3` (3.9.6) first on the PATH.

- AC1 (not met): on the tree the guard exits 0, reading 26 reset lines across
  indexes, latex, marks and sortkeys. The self-test prints `M105-AC1` green and
  `M105-AC1 self-test` green over its four cases. Eleven hand plants on scratch
  copies all behave as AC1 states. They include the R1 column-0 `end`, a
  `while` block and a one-line anonymous function. They also include `end`
  inside a string and a comment, a `repeat`/`until` block, and a multi-line
  long string. A block comment and a line comment stay green. Three further plants pass a stray
  line unseen (V1 to V3 below). In each, `qi_core.empty(hidden)` is added to a
  reset and the guard exits 0, reading 26 lines. V1 puts a commented-out copy
  of `sortkeys.lua`'s reset (`--[[ ... ]]`) above the real one. V2 adds a
  second `local function reset(doc)` after the first in `indexes.lua`. V3
  puts the stray statement on the opener line. V1 fails AC1 as written. The
  source defines the reset once, and the guard reads the commented copy in
  place of the lines up to that function's closing `end`. Box left unticked.
- AC2: the `--self-test` run was stopped by hand after AC1 was found failing,
  at 876 `ok` lines and no `FAIL`. Before the stop, both `M105-AC2` self-test
  lines printed `ok`. The check passed on the unchanged copy and was red on
  the planted copy, naming `two.html`. Box not ticked,
  because the return below changes the suite again.
- AC3: the same run printed `M105-AC3 self-test` green, the check red on the
  `div` and `h3` copies, each naming its tag. Box not ticked, for the same
  reason.
- AC4: not run to completion (stopped as above). Box not ticked.
- Consistency gate: `cairn_validate.py` exits 0, all checks passed. No DESIGN
  principle text changed. The generic profile names no toolchain checks.

Thrash count: this is defect return 2 (no amendment returns). AC1 failed in
run 1 and again here. Each time, the guard's hand-written Lua reader misplaces
where the reset starts or ends, and a stray line goes unread. That is the same
shape twice, the case the review skill reads as a wrong approach.

Independent review: three fresh reviewers (Opus diff-bug, Sonnet
blame-history, Sonnet prior-review). Merged where two named one defect. Each
line gives the proposed disposition, decided at the merge gate.

- V1 (diff-bug 1, blame 2, reproduced here): a commented-out
  `local function reset(` above the real one is read as the reset. AC1 fails.
  Proposed: fix now, a return to implement.
- V2 (diff-bug 2, reproduced here): only the first of two reset definitions is
  read, though Lua exports the later one. Proposed: fix now with V1.
- V3 (diff-bug 3, reproduced here): code on the opener line is never read,
  against the `check_cells` docstring and DESIGN.md line 263. Proposed: fix
  now with V1.
- V4 (diff-bug 4): the R5 wording says `plant()` stops on a second copy of an
  allowed line. `plant()` matches only `CELLS` statements, so a duplicated
  KEPT line passes both. Proposed: fix the wording now.
- V5 (diff-bug 5, checked here): D-062 says the probe drops only the lines
  the table names. `reset:marks`, `reset:latex` and `reset:sortkeys` drop
  every reset line. Proposed: fix now, one entry that supersedes that
  sentence.
- V6 (diff-bug 6): the block-comment self-test checks only exit 0, and every
  line after its comment is allowed, so a reader that stops at `--[[` passes
  it. Proposed: fix now, a red plant with a stray line after a block comment.
- V7 (diff-bug 7): every call and plant passes `section h2`, so a mode that
  ignores its tag arguments passes. Proposed: fix now, one call with other
  tags.
- V8 (prior 1): the guard prints how many lines it read on a pass alone, not
  on a failure (LESSONS M45). Proposed: fix now, print the domain before the verdict.
- V9 (blame 1): the plan Out gaps and the R5 and R17 rejections have no Known
  issues entry, though D-013 puts accepted coverage gaps there. Proposed: fix
  now, entries in `cairn/DESIGN.md`.
- V10 (blame 3, checked here): in KI10, "Four carry more than a skewed count"
  follows the inserted guard sentence and so lost its referent. Proposed: fix
  now.
- V11 (diff-bug 11): the AC2 plant's 10-byte assert assumes BSD `sed`. GNU
  `sed` adds a final newline. Proposed: fix now, plant with `perl`.
- V12 (diff-bug 9): a one-line reset gets a message about other blocks on the
  opener line. Proposed: fix now with V1.
- V13 (diff-bug 12): the probes refuse `QI_EXT_DIR` set to the absolute path
  of the tree they plant. Proposed: fix now, compare absolute paths.
- V14 (diff-bug 8): a backslash-continued string ends at its line, so the
  block count can stop early. Red anyway. Proposed: fix with V1, else reject.
- V15 (diff-bug 10): a trailing comment or `;` on a cell line gives a false
  red. It fails loud and matches `plant()`'s exact match. Proposed: reject.
- V16 (blame 7): an old-arity `outside-heading` call fails with a tag
  message, not usage. Loud. Proposed: reject.
- V17 (blame 4): the `Bramble` control is a planted copy. Proposed: reject,
  as R15.
- V18 (blame 6): Python 3.12 not run. Proposed: reject, as R16.
- V19 (blame 5): D-062 is longer than the template and records process
  history. Proposed: reject as style, or fold into the V5 entry.
- V20 (prior 2): D-062 says "narrows" where D-011 says a superseding entry.
  Proposed: reject, D-038 uses that form and the user chose it.
- V21 (blame 8): R13 and R14 again. Proposed: reject, already rejected.

Gate 2026-10-01: the user chose to send M105 back to implement, with the
guard finding each reset through Quarto's Lua rather than a hand-written
reader (T9). V1 to V14 are fix-now, as tasks T9 to T11, and T12 repeats both
suite runs. V15 to V21 are rejected for the reasons given. The plan's
recorded alternative, a derived drop list with no guard, was offered and not
chosen. A review brief was offered and not chosen.

### Review run 3 (2026-10-01, at 1a9f5f8)

The branch holds `origin/main`, and `main` has no unpushed commits. Runs used
`/usr/bin/python3` (3.9.6) first on the PATH.

- AC1 (not met): on the tree the guard exits 0, reading 26 reset lines across
  indexes, latex, marks and sortkeys. Each hand plant on a scratch copy adds
  `qi_core.empty(hidden)` to a reset. Six plants are red and name the line:
  V1, V3, the R1 column-0 `end`, a line after a block comment, a `do` block,
  and a one-line reset. V2 (two openers) is red and names both lines. A new
  module `extra.lua` with a normal reset and an unlisted line is found and is
  red. Then the same module puts the parameter `doc)` on the line after
  `local function reset(`, which is valid Lua. The guard does not find it,
  exits 0, and reads 26 lines over the four old modules. Its search pattern
  needs the closing `)` on the opener line. AC1 promises every module whose
  source defines `local function reset(`. This module does, and its unlisted
  line passes. In a module that `CELLS` names, the same split is red, because
  the module goes missing. Box left unticked.
- AC2: `tests/run-tests.sh --self-test` at 1a9f5f8 passed (1738 checks). It
  prints `M105-AC2 self-test (an unchanged copy of the page)` green, with
  `Bramble` linking to `two.html#qi-mark-1`. It prints `M105-AC2 self-test`
  green: the check passes on the unchanged copy and is red on the planted
  copy, naming `two.html`. The M063 T2 leg (lines 11463 to 11525) holds no
  `M095` text, and its four output lines name no `M095-AC3` check.
- AC3: in the same run, the M095-AC3 call passes `section h2` and prints two
  `ok` lines for `four.html`, one per `place-blocked` render. Each line names
  the `<section>` element and its `<h2>` heading. `M105-AC3 self-test` is
  green: the check is red on the `div` copy and on the `h3` copy, each time
  naming the tag it found. Called with the tags each copy carries, it is green
  on that copy.
- AC4: at 1a9f5f8, `tests/run-tests.sh --self-test` passed (1738 checks), and
  then `tests/run-tests.sh` passed (898 checks). The two runs were sequential,
  with no suite edits during either. The commits between them touched only
  the milestone file.
- Consistency gate: `cairn_validate.py` exits 0, all checks passed, with one
  advisory (12 tasks, over the split tripwire). No DESIGN principle text
  changed. The generic profile names no toolchain checks.

Thrash count: this is defect return 3 (no amendment returns). AC1 failed in
runs 1, 2 and 3. Each time the guard missed part of what AC1 promises, by a
new mechanism: an inner `end`, a commented-out opener, and now a parameter
list on the next line. The independent review was not run, because AC1 fails
and the third return puts the disposition to the user.

Disposition: the user chose to narrow AC1 (work log). AC1 now covers modules
with one same-line reset opener that opens the exported reset.

- AC1 (amended wording): no file under `tests/` or `_extensions/` changed
  since 1a9f5f8, so the runs above stand. All four reset modules are in the
  amended domain, and the guard exits 0 on the tree, reading their 26 reset
  lines. In-domain plants are red and name the stray line: V1, V3, the R1
  column-0 `end`, a line after a block comment, a `do` block, a one-line
  reset, and a new module `extra.lua`. The self-test prints
  `M105-AC1 self-test` green, red on the added `indexes.lua` line. The plain
  run prints `M105-AC1` green, so `tests/run-tests.sh` runs the guard. The
  split-parameter opener and two-opener modules are outside the amended
  domain, and KI308 records the first.
- AC1 (amended wording, not met after review): the diff reviewer's W1 and W2
  below were reproduced here. Each adds a new module `extra.lua` whose reset
  holds an unlisted line. Quarto's Lua loads it and reports the reset's
  lines. The guard exits 0, reading 26 lines over the four old modules. In
  W1a, a `\z` string continuation holds `--[[`. In W1b, a first line `#! --[[`
  is one Lua skips. In W2, the file is named `..extra.lua`. Each module has
  one same-line opener outside comments and strings as Lua reads them, so it
  sits in the amended domain. Box unticked.

Independent review, run 3: three fresh reviewers (Opus diff-bug, Sonnet
blame-history, Sonnet prior-review). Merged where two named one defect. Each
line gives the proposed disposition.

- W1 (diff-bug 1, reproduced here): the guard's own lexer decides where
  comments are, so a `\z` string or a `#!` first line hides a new module's
  reset. AC1 fails. Proposed: a return.
- W2 (diff-bug 2, reproduced here): `rel.startswith(os.pardir)` also skips
  `..extra.lua`. AC1 fails. Proposed: with W1.
- W3 (diff-bug 3): some reds name the module and not the stray line, such as
  a second opener with odd spacing or a line inside a long string. Fails
  loud. Proposed: with W1.
- W4 (diff-bug 4, blame 4): the AC1 self-test pins the four module names, so
  a correct new reset module turns it red. Proposed: fix now, derive the list.
- W5 (diff-bug 5): KI308 says the guard passes another form, but for a module
  `CELLS` names it fails as missing. It omits W1 and W2. Proposed: fix now.
- W6 (diff-bug 6): code after the closing `end` on that line is a false red.
  Proposed: reject, fails loud, as V15.
- W7 (diff-bug 7): `sys.path.insert(0, 'tests')` needs the repo root as the
  working directory. Proposed: reject, paths were relative before.
- W8 (diff-bug 8, blame 6, prior 3): the `stateprobe.py` docstring has a lone
  "The" line and one long line. Proposed: fix now.
- W9 (blame 1): the DESIGN.md accumulator sentence says the guard covers each
  reset line, wider than AC1's domain. Proposed: fix now, name the domain.
- W10 (blame 2): D-063 does not say that a hand lexer still finds the opener.
  Proposed: record in KI308, no new entry.
- W11 (blame 3): a reset outside `modules/` is never read. Proposed: reject,
  AC1 names `modules/`, or record in KI308.
- W12 (blame 5, prior 2): the commented-out-opener comment sits above the
  block-comment plant. Proposed: fix now.
- W13 (blame 7): the `Bramble` control is a planted copy. Proposed: reject, as
  R15.
- W14 (blame 8): `--check-cells` works only as the first argument. Proposed:
  reject, a usage detail.
- W15 (prior 1): KI287 struck with no edit. Proposed: reject, as R14.

Disposition: the user chose to narrow AC1 a second time, to the modules
`CELLS` names (work log).

- AC1 (second amended wording): no file under `tests/` or `_extensions/`
  changed since 1a9f5f8, so the suite runs above stand. The guard reads the
  four modules `CELLS` names and exits 0 on the tree, reading 26 reset lines.
  Where it cannot find the one opener of the exported reset, it is red and
  names the module: a `#!` first line or a `\z` string hiding `sortkeys.lua`'s
  opener (missing), a parameter list on the next line (missing), an exported
  reset other than the local one (line mismatch), and a second, oddly spaced
  opener in `marks.lua` (two lines), as is V2 (two openers). Where it finds
  the reset, every plant above in a `CELLS` module is red and names the line:
  V1, V3, the R1 column-0 `end`, a line after a block comment, a `do` block, a
  one-line reset, and a `#!` comment closed before the opener. The self-test
  and plain-run lines for `M105-AC1` are as recorded above.

Thrash count: defect return 4. AC1 failed in every run, each time by a
new way the guard's own Lua reading misses part of the domain.
