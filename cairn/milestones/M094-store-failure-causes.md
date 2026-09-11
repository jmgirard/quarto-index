# M094: A failed store write or source read reports its own cause

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the write-failure report an author reads changes its stated cause, and a stray `ERROR` line leaves the render log
- **Branch/PR:** m094-store-failure-causes

## Goal

A book chapter whose record cannot be written, or whose source cannot be read,
reports the failure that happened and prints no `ERROR` line of Quarto's, and
the M062 and M063 checks around those reports fail on the defects they name.

## Scope

**In:**
- KI204, KI206, KI210, KI211, KI212 and KI213, all under "The repo and its
  packaging" in `cairn/DESIGN.md`.
- KI204. Quarto's filter runtime replaces the global `error` with a logger
  that writes an `ERROR (...)` line and returns (`share/filters/main.lua`,
  `function error`). So the four `error(...)` calls inside `pcall` in
  `_extensions/index/modules/book.lua` (near lines 341, 346, 905 and 910)
  log and fall through. At 341 the next line's nil fault is what `pcall`
  catches. At 346, a failed write falls through to a normal return, so no
  write-failure report is drawn at all (found at this plan's criteria
  audit). No leg reaches 346, 905 or 910. The fix stops calling the global
  `error` at all four sites.
- KI206. `check_extension_warning_count` misses a `(W)` line that starts with
  a colour-reset escape. In the M063-AC3 log that escape closes KI204's
  `ERROR` line, so KI206's entry misreads the cause. Any coloured line from
  Quarto before a `(W)` line leaves the same escape.
- KI210 to KI213: the M062 legs over `examples/book-nomarker/` and
  `examples/book-placement/`.
- A `CHANGELOG.md` entry for the corrected report cause, and each closed
  entry struck from `cairn/DESIGN.md`.

**Out:**
- The counts and sites of the store reports (D-049 to D-053) do not change.
  Only the cause text inside the write-failure report changes.
- The other book-store known issues (KI205, KI208, KI214, KI215, KI217 to
  KI229, KI239, KI240) stay open under their own entries. No row names them.

## Acceptance criteria

- [x] AC1: In the M063-AC3 leg of `tests/run-tests.sh`, where a directory
      holds `four.qmd`'s record path, the write-failure report's
      parenthesized cause carries the text that `io.open` returned (`Is a
      directory` on this machine), not a nil-index fault. After SGR escapes
      are stripped, no line of that render's log or of the M064-AC5 leg's
      logs matches `ERROR \(`.
- [x] AC2: No function under `_extensions/index/modules/` calls the global
      `error`, as a `grep -n 'error('` over those modules at review reads.
- [x] AC3: `check_extension_warning_count` counts a warning line that starts
      with an SGR escape before `(W) `. The M063-AC3 anchored count over the
      render with the held record reads the same figure as the raw `(W) `
      count beside it.
- [x] AC4: In a book render over `examples/book-placement/`, a mark refiled
      from an undeclared index name prints inside the section of the book's
      first declared index. A leg asserts this and fails when the refiled
      mark is removed from the record that the section reads.
- [x] AC5: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T7, T8

## Tasks

- [x] T1: KI204. At the four `error(...)` sites in `book.lua`, return a
      failure value from the guarded function instead, and branch on it
      beside `pcall`'s own result. `pcall` stays as the IP2 net for faults
      nobody planned for. Keep the report wording, and put the open or read
      failure's own text in the cause.
- [x] T2: KI204 checks. At the M063-AC3 held-record leg (near line 8867),
      assert the cause substring on the `could not record index marks` line
      itself, not anywhere in the log, and a zero count of `ERROR \(` lines
      after SGR stripping. Assert the same zero count at the M064-AC5 leg
      (near line 9134). The M064-AC5 total extension-warning count (near line
      9139) moves from 6 to 7 once the escape goes. Set it with the reason
      shown. Add a `--self-test` plant that restores the `error(...)` call at
      341 in a scratch copy of the extension and shows the zero count red.
      Add a `CHANGELOG.md` entry under the development heading.
- [x] T3: KI206. Strip SGR escapes (`\x1b\[[0-9;]*m`) from the log before the
      anchored grep in `check_extension_warning_count` (near line 2228), as
      the M12 check near line 3710 already does. Add a `--self-test` plant: a
      copy of a log with an SGR prefix before one `(W)` line keeps its count.
      Set the M063-AC3 count (near line 8880) to the raw figure and rewrite
      its comment. Re-read every other count this function pins in a run and
      correct any figure the change moves, with the reason shown.
- [x] T4: KI210. `fold_undeclared` refiles to `qi_indexes.default()`, which
      is `alpha` in `examples/book-placement/`. Add the refiled-term
      assertion to an M062-AC1 leg (near lines 11288-11335) over the alpha
      section of `index.html`. Add a plant that drops the refiled mark. Reword the
      M062-AC3 "the marks still print" assertion (near line 7524) to what it
      reads.
- [x] T5: KI211, KI212. Rewrite the M062-AC3 count comment (near line 7503)
      to say that the count rules out a revert to `if builds then` and does
      not separate the two counting rules. Label the M062-AC1 single-chapter
      leg (near line 11317) a control.
- [x] T6: KI213. Re-key `record['sorts']` in the M062-AC3 plant
      (`NOMARKNAMEPY`, near line 7484) as `PLACENAMEPY` does.
- [x] T7: Strike KI204, KI206, KI210, KI211, KI212 and KI213 from
      `cairn/DESIGN.md` per D-013.
- [x] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: the `ERROR (` clauses were already true because the line opens with an SGR escape (now matched after stripping); M064-AC5 never reaches sites 905 and 910, and site 346 is unreachable and draws no report, so AC2 became a review grep over the modules; M064-AC5's total count moves 6 to 7 (T2); the refiled term prints in `index.html`'s alpha section, not gamma (AC4, T4); KI206's escape is the reset closing KI204's ERROR line (Scope).
- 2026-09-11: plan gate chose fixing KI204 inside M094 over a separate hotfix because the fix and the M062/M063 check repairs read the same legs; falsified by an author reporting the misleading write-failure cause before M094 merges.
- 2026-09-11: plan chose returning failure values beside `pcall` over calling Quarto's saved `builtin_error_function`, because that name is internal to Quarto's filter runtime; falsified by a Quarto release whose runtime also changes `pcall` or the return path.
- 2026-09-11: implement started on m094-store-failure-causes; question gate skipped, the plan left no implementation choice open.
- 2026-09-11: checkpoint, T1-T7 edits written and not yet verified: a scratch render with four.qmd's record path held shows no ERROR line and the cause `...four.qmd.qi.json: Is a directory`; the strip moves three pinned counts over the prior run's logs, M063-AC3 6 to 7, M064-AC5 6 to 7, and M064-AC3 10 to 12, which the plan did not name (set under T3); `tests/run-tests.sh --self-test` is running, boxes stay unticked until it reads clean.
- 2026-09-11: suite run 1 stopped at M06-AC3 when Quarto's Deno binary crashed with a segmentation fault rendering sort-escaping.qmd to gfm. The same render then exited 0 three times out of three, so the crash was transient. Every leg M094 touches had passed before it.
- 2026-09-11: claim audit: 51 claims read, 7 corrected — CHANGELOG.md, _extensions/index/modules/book.lua, tests/run-tests.sh
- 2026-09-11: suite run 2 failed M24-AC3 because the M094 T2 mutant render had no capture call after it. The call is added, the audit corrections and a tighter `got 1` glob are applied, and suite run 3 is running.
- 2026-09-11: suite run 3 of `tests/run-tests.sh --self-test` exited 0 with all 1504 checks passed. The M094 T2, T3 and T4 plants each went red for their named defect. T1 to T8 are ticked and status is review.
- 2026-09-11: review checkpoint: AC2 grep evidence, the consistency gate and nine diff-bug findings are recorded, and AC2 is ticked. Review suite run 1 stopped at M069-AC1 on a Quarto Deno segmentation fault. Run 2 is running, and AC1, AC3, AC4 and AC5 stay unticked until it reads clean.
- 2026-09-11: review suite run 2 exited 0 with all 1504 checks passed. AC1 to AC5 have evidence lines and are ticked. This is the pre-gate checkpoint, and the nine diff-bug findings go to the merge gate for triage.
- 2026-09-11: step-7 approval: m094-store-failure-causes approved for merge. The gate fixes F1 and F4 land first, and the suite must run clean again.
- 2026-09-11: checkpoint, gate fixes F1 (readable-log guard in both helpers, shown red on a mode-000 log) and F4 (changelog narrowed to the open failure) written. Review suite run 3 is running, and the push waits until it reads clean.

## Decisions

## Review

Reviewed 2026-09-11 on `m094-store-failure-causes` at 0d0506d. The branch
contains `origin/main` (93e8bd7), so no sync merge was needed.

Evidence:
- AC2: `grep -n 'error(' _extensions/index/modules/*.lua` over the 11 modules
  exits 1 with no match.
- In review suite run 1 of `tests/run-tests.sh --self-test`, Quarto's Deno
  binary crashed with a segmentation fault at M069-AC1, and the run stopped
  there after 416 checks. This is the same crash as implement's suite run 1. The run passed the M094 T2 and
  T3 plants and every M064-AC5 check, and it did not reach the M062 legs. It
  counts as evidence for no criterion.
- Review suite run 2 of `tests/run-tests.sh --self-test` exited 0 with "All
  checks passed (1504 checks)", no line opening `FAIL` and no crash.
- AC1: in both M063-AC3 renders (`place-blocked-one.log` and
  `place-blocked-two.log`), the write-failure report's cause reads
  `four.qmd.qi.json: Is a directory`. After SGR stripping, those two logs and
  the two M064-AC5 logs each hold 0 lines matching `ERROR (`. The suite's
  `m094_check_cause` and `check_no_quarto_error` passed at both legs, and the
  M094 T2 plant went red on each check with the raise restored.
- AC3: in both M063-AC3 held-record logs, the anchored patterns read 7
  warning lines after SGR stripping. The raw `(W) ` count beside them is also
  7. Both were counted by hand with `/usr/bin/grep` and by the suite's two
  checks at that leg. The shipped render no longer writes an escape before a
  `(W)` line, so the M094 T3 plant carries the escape case. It reads 6 to
  the anchored patterns alone and 7 to `check_extension_warning_count`.
- AC4: `M094-AC4` passed for the whole-book render and for the index.qmd
  control. In each, `Escutcheon` prints in the `qi-index-alpha` section of
  `index.html`. The M094 T4 plant dropped that mark from five.qmd's record,
  and the assertion went red naming the term.
- AC5: this is suite run 2 above, run alone with no other suite invocation.

Consistency gate: `cairn_validate.py` exits 0 with every check passing. No
principle text changed, so `cairn_impact.py` does not apply. The `generic`
profile names no toolchain checks.

Independent review (three fresh reviewers):
- Blame-history lens: no findings.
- Prior-review lens: no findings. The GitHub probe found no review threads.
- Diff-bug lens: no correctness defect in `book.lua`. Nine findings, most
  severe first:
  - F1. `check_extension_warning_count` and `check_no_quarto_error`
    (`tests/run-tests.sh:2237-2261`) guard with `[ -f ]` only. A log that
    exists and cannot be read makes `perl` fail inside `|| true`, so the count
    reads 0 and every zero expectation passes. Before M094, `grep -c` printed
    nothing on such a file and the check failed. Verified against the code.
  - F2. `store_write` ignores the return value of `fh:close()`. A write that
    fails only at the flush (a full disk) draws no report. The line predates
    M094.
  - F3. No leg reaches the write-failure site (old line 346) or the two
    source-read sites (old 905 and 910). The plan recorded this and set AC2 as
    a grep instead.
  - F4. The `CHANGELOG.md` entry says the report names "the failure that
    stopped the write". Only the open failure (`Is a directory`) is enforced.
  - F5. `m094_check_cause` matches the English system text `Is a directory`,
    which another locale or platform prints differently.
  - F6. The T2 cause probe prints the same message whether the mutant drew no
    report or drew one with the wrong cause. The ERROR probe counts one line
    and does not name it.
  - F7. The T4 plant drops the refiled mark. It does not plant a mark filed
    in two sections, and `place_refiled_term` does not assert the term is
    absent from `gamma`.
  - F8. The T4 plant (`DROPREFILEDPY`) does not re-key `record['sorts']` as
    `PLACENAMEPY` does. five.qmd's `sorts` is empty today.
  - F9. A failed T4 render exits before the `cp` that restores five.qmd's
    record in `examples/book-placement/`.

Triage at the merge gate (2026-09-11, the user chose the recommended set):
- F1: fix now. Both helpers now also refuse a log that cannot be read. In a
  scratch copy with a mode-000 log, the helpers from a6a0cfc passed a zero
  count, and the fixed helpers failed naming the file. A readable log still
  passed a count of 7 and a zero ERROR count.
- F4: fix now. The `CHANGELOG.md` entry now names only the open failure.
- F2, F3, F5, F6: follow-up. Each becomes a known-issue entry under "The repo
  and its packaging" in the post-merge hygiene commit.
- F7: rejected. AC4 asks only for the drop plant.
- F8: rejected. five.qmd's record has no sort keys, so the plant has no
  effect today.
- F9: rejected. The suite is already stopping at that point, and
  `place_undeclared` behaves the same way.
