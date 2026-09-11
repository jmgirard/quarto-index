# M094: A failed store write or source read reports its own cause

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the write-failure report an author reads changes its stated cause, and a stray `ERROR` line leaves the render log
- **Branch/PR:** —

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

- [ ] AC1: In the M063-AC3 leg of `tests/run-tests.sh`, where a directory
      holds `four.qmd`'s record path, the write-failure report's
      parenthesized cause carries the text that `io.open` returned (`Is a
      directory` on this machine), not a nil-index fault. After SGR escapes
      are stripped, no line of that render's log or of the M064-AC5 leg's
      logs matches `ERROR \(`.
- [ ] AC2: No function under `_extensions/index/modules/` calls the global
      `error`, as a `grep -n 'error('` over those modules at review reads.
- [ ] AC3: `check_extension_warning_count` counts a warning line that starts
      with an SGR escape before `(W) `. The M063-AC3 anchored count over the
      render with the held record reads the same figure as the raw `(W) `
      count beside it.
- [ ] AC4: In a book render over `examples/book-placement/`, a mark refiled
      from an undeclared index name prints inside the section of the book's
      first declared index. A leg asserts this and fails when the refiled
      mark is removed from the record that the section reads.
- [ ] AC5: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T7, T8

## Tasks

- [ ] T1: KI204. At the four `error(...)` sites in `book.lua`, return a
      failure value from the guarded function instead, and branch on it
      beside `pcall`'s own result. `pcall` stays as the IP2 net for faults
      nobody planned for. Keep the report wording, and put the open or read
      failure's own text in the cause.
- [ ] T2: KI204 checks. At the M063-AC3 held-record leg (near line 8867),
      assert the cause substring on the `could not record index marks` line
      itself, not anywhere in the log, and a zero count of `ERROR \(` lines
      after SGR stripping. Assert the same zero count at the M064-AC5 leg
      (near line 9134). The M064-AC5 total extension-warning count (near line
      9139) moves from 6 to 7 once the escape goes. Set it with the reason
      shown. Add a `--self-test` plant that restores the `error(...)` call at
      341 in a scratch copy of the extension and shows the zero count red.
      Add a `CHANGELOG.md` entry under the development heading.
- [ ] T3: KI206. Strip SGR escapes (`\x1b\[[0-9;]*m`) from the log before the
      anchored grep in `check_extension_warning_count` (near line 2228), as
      the M12 check near line 3710 already does. Add a `--self-test` plant: a
      copy of a log with an SGR prefix before one `(W)` line keeps its count.
      Set the M063-AC3 count (near line 8880) to the raw figure and rewrite
      its comment. Re-read every other count this function pins in a run and
      correct any figure the change moves, with the reason shown.
- [ ] T4: KI210. `fold_undeclared` refiles to `qi_indexes.default()`, which
      is `alpha` in `examples/book-placement/`. Add the refiled-term
      assertion to an M062-AC1 leg (near lines 11288-11335) over the alpha
      section of `index.html`. Add a plant that drops the refiled mark. Reword the
      M062-AC3 "the marks still print" assertion (near line 7524) to what it
      reads.
- [ ] T5: KI211, KI212. Rewrite the M062-AC3 count comment (near line 7503)
      to say that the count rules out a revert to `if builds then` and does
      not separate the two counting rules. Label the M062-AC1 single-chapter
      leg (near line 11317) a control.
- [ ] T6: KI213. Re-key `record['sorts']` in the M062-AC3 plant
      (`NOMARKNAMEPY`, near line 7484) as `PLACENAMEPY` does.
- [ ] T7: Strike KI204, KI206, KI210, KI211, KI212 and KI213 from
      `cairn/DESIGN.md` per D-013.
- [ ] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: the `ERROR (` clauses were already true because the line opens with an SGR escape (now matched after stripping); M064-AC5 never reaches sites 905 and 910, and site 346 is unreachable and draws no report, so AC2 became a review grep over the modules; M064-AC5's total count moves 6 to 7 (T2); the refiled term prints in `index.html`'s alpha section, not gamma (AC4, T4); KI206's escape is the reset closing KI204's ERROR line (Scope).
- 2026-09-11: plan gate chose fixing KI204 inside M094 over a separate hotfix because the fix and the M062/M063 check repairs read the same legs; falsified by an author reporting the misleading write-failure cause before M094 merges.
- 2026-09-11: plan chose returning failure values beside `pcall` over calling Quarto's saved `builtin_error_function`, because that name is internal to Quarto's filter runtime; falsified by a Quarto release whose runtime also changes `pcall` or the return path.

## Decisions

## Review
