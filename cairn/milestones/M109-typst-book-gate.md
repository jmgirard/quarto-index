# M109: The suite checks a Typst book on any Quarto that renders one

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — the acceptance suite is this repo's own test tooling, which no user of the extension runs
- **Branch/PR:** m109-typst-book-gate

## Goal

The suite runs its Typst-book output checks on any Quarto that renders the
book. It skips them only when Quarto refuses to render a Typst book.

## Scope

**In:** the gate on the three Typst-book output checks in
`tests/run-tests.sh`: M098-AC5, the M098-AC7 outline check and M100-AC3.
The gate reads the outcome of the book render each check reads, not the pin
in `.github/workflows/pages.yml`. The M098-AC7 no-author check asserts
Quarto's own template error, so it stays on the pin (D-065) with a reason of
its own. The comments and reason strings that name the old gate. D-067
narrows D-065. The candidate row from the M108 review (F1) is absorbed.

**Out:** the `site/books.qmd` sentence on which Quarto renders a Typst book
stays in its candidate row. A CI job that runs the suite on Quarto 1.5.52
stays in its candidate row. The version matrix's PDF comparison (KI111)
stays in its candidate row. The books' hand-written chapter pages stay as
written: a newer template that moves a chapter turns the run red (D-067), and
no row holds a reader for relative pages. As in M108, `--self-test` on
Quarto 1.5.52 is outside every criterion, and no row asks for it.

## Acceptance criteria

- [x] AC1: In `tests/run-tests.sh`, the outcome of the Typst book render
      that each check reads decides whether the M098-AC5 checks, the M098-AC7
      outline check and the M100-AC3 checks run. The Quarto that
      `.github/workflows/pages.yml` pins does not decide it. The refusal
      warning is `The typst format is not supported by book projects`. These
      checks run after a render that exits 0, writes exactly one PDF under the
      book's `_book`, and logs no refusal warning. After a render that logs
      the refusal warning and writes no PDF there, with any exit status, the
      suite prints one `skip` line per check label. Each skip line names the
      running Quarto and the refusal warning. The run fails and names the
      book after any other render. That is a render with no refusal warning
      that exits non-zero, or that exits 0 and writes no PDF or two or more
      PDFs. It is also a render that logs the refusal warning and writes one
      or more PDFs.
- [x] AC2: The M098-AC7 no-author check still runs on the pinned Quarto
      alone, and the reason its `skip` line gives names Quarto's book
      template, the subject of that check, rather than the Typst-book refusal.
- [x] AC3: On Quarto 1.10.18, the pinned version, `tests/run-tests.sh` and
      `tests/run-tests.sh --self-test` each pass and print no `skip` line.
- [x] AC4: On Quarto 1.5.52, `tests/run-tests.sh` passes, and the `skip`
      lines it prints for M098-AC5, the M098-AC7 outline check and M100-AC3
      name Quarto's refusal warning, not the pin.
- [x] AC5: The comment above the M098-AC5 render, the comments above the
      M100-AC3 and M098-AC7 outline gates, and the reason those three checks'
      `skip` lines give state the gate AC1 describes. A search of
      `tests/run-tests.sh` for `Typst book is rendered on the pinned` finds no
      line.

## Coverage

- AC1 → T1, T2, T3, T6, T7
- AC2 → T4
- AC3 → T5, T9
- AC4 → T2, T3, T5, T9
- AC5 → T4

## Tasks

- [x] T1: Write the gate beside `on_pinned_quarto`
      (`tests/run-tests.sh:136-165`). Its inputs are the render's exit
      status, its log, the book's `_book` directory, the book's name and the
      check labels. It runs, skips or fails per AC1's three cases. Add a
      `--self-test` passing control with one PDF. Add two plants for the
      refusal with no PDF, which print skip lines: one exits 0 and one exits
      1. Add one plant for each failing
      shape AC1 lists. Assert each case by its line text, never by its exit
      status alone.
- [x] T2: Render `examples/book/` to Typst unconditionally
      (`tests/run-tests.sh:30169-30185`), pass its outcome to the gate, and
      gate the M098-AC5 checks (30233-30250) and the M098-AC7 outline check
      (30955-30963) on the result. Call `m098_no_typst_warning` only on the
      run branch, since Quarto 1.5.52 logs its refusal as a warning. Give
      `capture` a `--refusable` flag for the two book renders, so a book
      under `examples/` that leaves no `_book` is left to the gate. The M24
      sweep needs `capture` on the line after each render.
- [x] T3: Split `m100_book_read` (30264-30275) so the render and the gate come
      before the read, and gate M100-AC3 (30277-30282) on the result.
- [x] T4: Give the no-author check (31012-31031) its own reason naming
      Quarto's book template. Rewrite the comment at 30169-30172 and remove or
      rename `TYPST_BOOK_WHY`, then run AC5's search. Re-read every message
      that names the gated set (LESSONS line 40).
- [x] T5: Run `tests/run-tests.sh` and `--self-test` on Quarto 1.10.18. Then
      run `tests/run-tests.sh` on Quarto 1.5.52 in a separate worktree, as
      `cairn/PROFILE.md` `verify` says, and never edit the script while a run
      reads it. Record each run's skip lines in the work log.
- [x] T6: In `typst_book_rendered`, count the PDFs at any depth under the
      captured `_book` that the checks read, not the working tree's. Pass the
      capture slug to do this. A refusal that leaves a PDF in a subfolder then
      fails the run (review D3, D1). Add a self-test plant for that case.
- [x] T7: Add a self-test plant whose log carries a near-miss warning, with
      no PDF and a non-zero exit, and expect a FAIL line (review D2). In the
      skip cases, plant a running Quarto version that is not the pin (D5).
- [x] T8: Correct the comment at `.github/workflows/versions.yml:361-364`,
      so it also names the Typst-book refusal skips (review P2a).
- [x] T9: Repeat T5's three runs and record their skip lines.

## Work log

- 2026-10-02: created by /milestone-plan.
- 2026-10-02: criteria audit (reduced mode, fresh Opus reader) returned three findings, each fixed before the gate. AC1's "any other outcome" now lists the outcomes by exit status, warning and PDF count. AC1's "each outcome is tested" moved to T1. AC5's search matched two correct pin-gate lines and passed on a renamed variable. It became three named sites and a search for the old wording.
- 2026-10-02: plan gate chose to gate the Typst-book output checks on the render over keeping the pin and dropping the row. Their subject is the extension's output. Falsified by an off-pin red run of these checks traced to Quarto rather than the extension.
- 2026-10-02: plan gate chose the book render's own outcome over a version threshold and over a separate probe book. This repo has not measured the version a threshold needs, and a probe costs a render and can disagree with the fixtures. Falsified by a Quarto that refuses Typst books with a different warning, which this gate fails on.
- 2026-10-02: plan gate chose to keep the hand-written chapter pages off the pin over pinning the page-number checks behind a second gate. A template that moves a chapter turns the run red. Falsified by template moves on newer Quartos turning the run red often enough that the red carries no signal.
- 2026-10-02: implement started on branch m109-typst-book-gate. Question gate skipped, since nothing in the plan was open. A probe in the scratchpad showed that Quarto 1.5.52 and 1.10.18 both empty a book's `_book` before a Typst render, so a PDF from the earlier LaTeX render cannot reach the gate. 1.5.52 logs the refusal in color, exits 0 and leaves `_book` empty.
- 2026-10-02: checkpoint, T1 code written and not yet run in the suite: `running_quarto`, `typst_book_skip` and `typst_book_rendered` beside `on_pinned_quarto`, and six `--self-test` cases. A scratch harness ran the six cases green on bash 3.2, and four planted gate defects each turned their case red.
- 2026-10-02: the T1 worktree run stopped at an unrelated check: `/usr/local/bin/python3` is now Python 3.14.6, with no PyYAML. Earlier runs used `/usr/bin/python3` 3.9.6, whose user site has PyYAML. Later runs put a scratch `python3` link to 3.9.6 first on `PATH`.
- 2026-10-02: checkpoint, T2-T4 code written in one commit, since their edits interleave. Both books now render on every Quarto and pass through `typst_book_rendered`. The outline check reads the M098-AC5 outcome. The no-author check has its own reason, and `TYPST_BOOK_WHY` is gone. AC5's search finds no line, and no other text names the old gate. Suite runs pending.
- 2026-10-02: runs at 2daf53b failed on both Quartos at M24-AC3: the two book renders were not followed by `capture`. The 1.5.52 run also showed a case the plan did not expect, confirmed in its worktree. On examples/book-typst-reset/, whose only format is Typst, Quarto 1.5.52 logs the refusal, then a TypeError, exits 1 and leaves no `_book`.
- re-audit: AC1 (reduced) — nothing on the bounded-promise, proportionality and instrument questions. The reader counted the 12 combinations of exit status, warning and PDF count, each in one case. Its wording suggestion, "writes one or more PDFs", was applied.
- 2026-10-02: amendment (user chose it at the mini gate over a fixture edit and a re-plan): AC1 now skips after a render that logs the refusal and writes no PDF, with any exit status. A render with no refusal that exits non-zero still fails.
- 2026-10-02: minor amendments: T1 gains a refusal plant that exits 1. T2 gives `capture` a `--refusable` flag, so each book render is followed by `capture` and a missing `_book` is left to the gate. The harness ran the seven T1 cases green, and four gate mutants each turned their case red. The M24 sweeps pass on their own.
- 2026-10-02: T5 runs at 93551ff, each in its own worktree with the 3.9.6 `python3` link first on `PATH`. Quarto 1.10.18 plain: "All checks passed (902 checks)", no skip line. Quarto 1.10.18 `--self-test`: "All checks passed (1765 checks)", no skip line. Quarto 1.5.52 plain: "All checks passed (884 checks)", 17 skip lines.
- 2026-10-02: on 1.5.52, 8 skip lines are the Typst-book checks: M098-AC5 (5 labels), M100-AC3 (2) and the M098-AC7 outline check (1). Each names the running Quarto and the refusal warning, not the pin. The no-author skip line names Quarto's Typst book template. The other 8 skip lines are the D-065 checks M108 left.
- claim audit: not owed — internal tier
- 2026-10-02: T1-T5 checked off. Status set to review.
- 2026-10-02: review defect return 1: AC1 fails as written, because the gate counts PDFs only at the top of `_book`, so a refusal with a PDF in a subfolder skips (finding D3). The user chose return to implement at the step-7 chip. T6-T9 added. Status set to in-progress.
- 2026-10-02: implement resumed on m109-typst-book-gate, main unmoved. Question gate skipped, since T6-T9 leave nothing open. Checkpoint: T6-T8 code written, suite runs pending. The gate takes the capture slug, counts PDFs at any depth there and sets `TYPST_BOOK_PDF`, which M098-AC5 reads. The self-test gains a nested-PDF control, a nested-PDF refusal, a near-miss warning and a planted running Quarto. A scratch harness ran the 10 gate cases green on bash 3.2, and five mutants each turned a case red: a top-level-only count, `grep -q WARN`, `grep -qi typst`, a pinned version in the skip line, and a working-tree count.
- 2026-10-02: T9 runs at 5084975, each in its own worktree with the 3.9.6 `python3` link first on `PATH`. Quarto 1.10.18 plain: "All checks passed (902 checks)", no skip line. Quarto 1.5.52 plain: "All checks passed (884 checks)", 17 skip lines. The 8 Typst-book skip lines name the running Quarto and the refusal, not the pin.
- 2026-10-02: the first 1.10.18 `--self-test` run stopped at the M098-AC7 outline document render. Quarto's own Deno process logged "Segmentation fault: 11" there, on a single-document render M109 does not touch. A re-run in the same worktree passed: "All checks passed (1768 checks)", no skip line, 10 `ok M109 T1 self-test` lines.
- claim audit: not owed — internal tier
- 2026-10-02: T6-T9 checked off. Status set to review.
- step-7 approval: m109-typst-book-gate approved for merge, after the four round-2 fixes (R2-D1, R2-B2, R2-D2, R2-D3).

## Decisions

## Review

Runs at 7cfe0b0 (2026-10-02), each in its own worktree, with a `python3` link to `/usr/bin/python3` 3.9.6 first on `PATH`. Default branch not moved since the branch was cut. `cairn_validate` exit 0, every check PASS or OK. No DESIGN.md principle changed, so `cairn_impact` was skipped. The `generic` profile names no toolchain checks.

- AC1: not met as written. The run, skip and fail cases hold for a PDF at the top of `_book`. The seven `--self-test` gate cases pass (7 `ok M109 T1 self-test` lines). The diff-bug reviewer ran the 12 combinations of exit status, refusal and PDF count by hand on bash 3.2. The 1.5.52 run skips both books. But the gate counts PDFs with `find "$book/_book" -maxdepth 1` (`tests/run-tests.sh:201`). The diff-bug reviewer ran a refusal log with `_book/sub/x.pdf`, and the gate printed skip lines. AC1 says a render that logs the refusal and writes one or more PDFs under `_book` fails the run. Finding D3.
- AC2: met. The no-author check is behind `on_pinned_quarto` (`tests/run-tests.sh:31171`). On 1.5.52 its skip line reads "the check's subject is the error Quarto's Typst book template raises for a book with no author". On 1.10.18 it prints `ok M098-AC7: the Typst book fails to compile without an author`.
- AC3: met. Quarto 1.10.18 plain: "All checks passed (902 checks)", exit 0, 0 skip lines. Quarto 1.10.18 `--self-test`: "All checks passed (1765 checks)", exit 0, 0 skip lines. The plain run prints 8 `ok` lines for M098-AC5, M100-AC3 and the M098-AC7 outline check.
- AC4: met. Quarto 1.5.52 plain: "All checks passed (884 checks)", exit 0, 17 skip lines. Eight are for M098-AC5 (5 labels), M100-AC3 (2) and the M098-AC7 outline check (1). Each reads "Quarto 1.5.52 refused to render examples/book[-typst-reset] to Typst, logging <<The typst format is not supported by book projects>>". None names the pin.
- AC5: met. Three comments state the render-outcome gate: above the M098-AC5 render (30310), the M100-AC3 gate (30421) and the outline gate (31106). The shared skip text in `typst_book_skip` states it too. `grep -c 'Typst book is rendered on the pinned' tests/run-tests.sh` prints 0.

Findings. Three fresh-context reviewers ran: Opus diff-bug (D), Sonnet blame-history (B), Sonnet prior-review (P). The PR-comment probe returned `[]`. Each reviewer's ranking is kept. Dispositions are proposed, pending the step-7 gate.

- D3: the gate counts only top-level PDFs. A refusal with a PDF in a `_book` subfolder skips, where AC1 fails the run (verified by execution). Proposed: floor return. Count recursively, with a nested-PDF plant.
- D1 (= B1, B5): the gate counts PDFs in the working tree `$book/_book`, while the checks read the capture. M24 says every read goes to the capture. Proposed: fix with the return. Count under the capture.
- D2: the self-test does not hold the refusal match to its exact text. `grep -q WARN` and `grep -qi typst` mutants pass all seven cases (verified by execution). Proposed: fix with the return. Add a plant with a near-miss WARN line, no PDF and a non-zero exit, and expect FAIL.
- D4: the count measures PDFs present, not PDFs this render wrote, and relies on Quarto emptying `_book`. Proposed: reject. The implement probe showed both Quartos empty it, and a leftover PDF fails loudly.
- D5: on the pinned Quarto the self-test cannot tell the running version from the pinned one in a skip line. Proposed: fix with the return. Set a planted running version in the self-test.
- D6 (= B3, P2b): `site/typst.qmd:99-101` says Quarto 1.5.52 "exits without an error", but a Typst-only book exits 1 there. The `floor warning` claim row (`tests/run-tests.sh:30768`) carries the same text. Proposed: follow-up, absorbed into the `site/books.qmd` candidate row.
- D7 (= B2): a refusal skips at any exit status, so a later crash after the refusal also skips. Proposed: reject. The user chose this AC1 amendment at implement.
- D8: `capture` reads `--refusable` only right after `--project`. Proposed: reject. Both call sites are correct.
- D9: the outline check's skip branch reads the flag alone. Proposed: reject. The branch is correct while the gate either skips or exits.
- D10: a missing log counts as no refusal. Proposed: reject. The redirect always creates it.
- D11: the no-author skip label `M098-AC7` matches an unconditional `ok M098-AC7` line. Proposed: reject. Main has the same label.
- D12: `printf | grep -q` under pipefail fails on a SIGPIPE that stops the `printf`. Proposed: reject. The output is far below the pipe buffer.
- D13 (= B4): T2's reason for calling `m098_no_typst_warning` only on the run branch is wrong, since its regex does not match `WARN:`. Proposed: noted. The placement is still right.
- B6: "the M108 F1 row is absorbed" names no row on main. Refuted: the plan commit e8cb144 removed it.
- P1: the diff makes M108 F6's premise "on the pinned Quarto no skip can print" false. Proposed: reject. D-067 intends it, and AC3's no-skip run reads it.
- P2a: the `.github/workflows/versions.yml` comment (361-364) says the floor skips are "its checks about Quarto itself". Proposed: fix with the return.
- P3: `typst_book_rendered` runs with errexit off as an `if` condition. Proposed: reject. Its failure paths call `fail`.
- P4: the M100 self-test plant has no gate call. Proposed: reject. It asserts exit 0, and the read fails loudly.

Gate, 2026-10-02: the user chose to return M109 to implement. Every disposition stands as proposed. D3 is the floor return, fixed with D1 by T6. D2 and D5 are fixed by T7, and P2a by T8. D6 is a follow-up, absorbed into the `site/books.qmd` candidate row. The other 11 findings are rejected or noted for the reasons above, and B6 is refuted. The next review gathers fresh evidence for every criterion.

### Round 2

Runs at d8cecba (2026-10-02), each in its own worktree with the 3.9.6 `python3` link first on `PATH`. Main has not moved. `cairn_validate` exit 0. No DESIGN.md principle changed. The `generic` profile names no toolchain checks.

Two Quarto 1.10.18 runs in this milestone stopped at a "Segmentation fault: 11" from Quarto's own Deno process. The T9 `--self-test` run stopped at the outline document. This round's first plain run stopped at an M069 book render. Neither render is code M109 changes. Each re-run passed. This round's plain re-run ran alone.

- AC1: met. The gate counts PDFs at any depth under the captured `_book` (`tests/run-tests.sh:206`). The 1.10.18 `--self-test` run prints 10 `ok M109 T1 self-test` lines. Two are run controls, with the PDF at the top and in a subfolder. Two are refusal skips, at exit 0 and exit 1. Six are failures: a non-zero exit, no PDF, two PDFs, a refusal with a PDF, a refusal with a nested PDF, and a near-miss warning. The diff-bug reviewer ran 30 combinations on bash 3.2, and each gave AC1's outcome. They crossed exit 0, 1 or 3, refusal or none, and 0, 1 or 2 PDFs at the top or nested. The 1.5.52 run skips both books.
- AC2: met. On 1.5.52 the no-author skip line reads "the check's subject is the error Quarto's Typst book template raises for a book with no author". On 1.10.18 it runs and passes.
- AC3: met. Quarto 1.10.18 plain re-run: "All checks passed (902 checks)", exit 0, 0 skip lines, 8 `ok` lines for M098-AC5, M100-AC3 and the M098-AC7 outline check. Quarto 1.10.18 `--self-test`: "All checks passed (1768 checks)", exit 0, 0 skip lines.
- AC4: met. Quarto 1.5.52: "All checks passed (884 checks)", exit 0, 17 skip lines. Eight are for M098-AC5 (5 labels), M100-AC3 (2) and the M098-AC7 outline check (1). Each names Quarto 1.5.52 and the refusal warning, and none names the pin.
- AC5: met. The three comments and the `typst_book_skip` text are as in round 1. `grep -c 'Typst book is rendered on the pinned' tests/run-tests.sh` prints 0.

Findings. The same three lenses ran fresh: Opus diff-bug (R2-D), Sonnet blame-history (R2-B), Sonnet prior-review, which reported no prior-review evidence and zero findings. The diff-bug reviewer killed the D1, D2, D3 and D5 mutants with the new cases. Dispositions are proposed, pending the step-7 gate.

- R2-D1 (= R2-B3): `m100_book_read` finds the PDF with `-maxdepth 1`, while the gate counts at any depth. A nested PDF the gate accepts makes M100-AC3 fail with an empty list (verified by execution). Proposed: fix now. Count at any depth there too.
- R2-B2: the no-author pass line ends "and compiles with one (M098-AC5)", but M098-AC5 can now skip on the pin. Proposed: fix now. Name M098-AC5 only when it ran.
- R2-D2: both nested plants sit one folder deep, so a `-maxdepth 2` gate passes all 10 cases (verified by execution). Proposed: fix now. Move the nested refusal two folders deep.
- R2-D3: the refusal skip is planted at exit 0 and 1 only, and no case has exit 1 with one PDF and no refusal. Two exit-status mutants survive (verified by execution). Proposed: fix now. Add a refusal skip at exit 3 and a failure at exit 1 with one PDF.
- R2-D4: the slug and the book directory are separate arguments. Proposed: reject. Both call sites are correct, and on the pin the M098 manifest checks read the PDF.
- R2-D5: the `running_quarto` call in `typst_book_skip` is never exercised. Proposed: reject. `on_pinned_quarto` sets the value before either book render.
- R2-D6: the no-label guard has no test. Proposed: reject. It copies `on_pinned_quarto`'s guard.
- R2-D7: the count matches PDFs by name only. Proposed: reject. Quarto writes no directory named `*.pdf` and no upper-case `.PDF`.
- R2-D8: counting at any depth widens D4 to a stale nested PDF. Proposed: noted. Neither fixture has figures, and the case fails loudly.
- R2-B1: the pin no longer guarantees the book checks run. Proposed: reject. D-067 chose this, and round 1 rejected P1.
- R2-B4: `--refusable` turns off the M24 missing-`_book` failure for the two books. Proposed: reject. The gate owns that case, and the `nopdf` and `refusedcrash` cases cover it.
- R2-B5: the refusal is one fixed string anywhere in the log. Proposed: reject. AC1 defines the refusal by that warning text.
- R2-B6: `site/typst.qmd` still says 1.5.52 exits without an error. Proposed: follow-up, already absorbed into the `site/books.qmd` candidate row (D6).
- R2-B7: D-065 has no note that D-067 narrows it. Proposed: reject. DECISIONS.md is append-only, and D-067's heading names the narrowing.
- R2-B8: housekeeping (the book argument only feeds messages, flag order, call order). Proposed: reject. Each restates D8 or a correct call site.

Gate, 2026-10-02: the user chose to fix the four, then merge. Every disposition stands as proposed. R2-D1, R2-B2, R2-D2 and R2-D3 are fixed now on the branch: `m100_book_read` counts at any depth, the no-author pass line names M098-AC5 only when it ran, the nested refusal sits two folders deep, and new cases cover a refusal at exit 3 and exit 1 with one PDF. A scratch harness ran the 12 gate cases green on bash 3.2. The `-maxdepth 2` mutant and both exit-status mutants each turned a case red.

Fix re-runs at 3c9d88a, two worktrees at once. Quarto 1.10.18 plain: "All checks passed (902 checks)", 0 skip lines. Quarto 1.10.18 `--self-test`: "All checks passed (1770 checks)", 0 skip lines, 12 `ok M109 T1 self-test` lines. The fixes change no 1.5.52 path: the M100 read and the no-author pass line run only on a render that writes the book.
