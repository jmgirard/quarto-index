# M109: The suite checks a Typst book on any Quarto that renders one

- **Status:** in-progress
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

- [ ] AC1: In `tests/run-tests.sh`, the outcome of the Typst book render
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
- [ ] T6: In `typst_book_rendered`, count the PDFs at any depth under the
      captured `_book` that the checks read, not the working tree's. Pass the
      capture slug to do this. A refusal that leaves a PDF in a subfolder then
      fails the run (review D3, D1). Add a self-test plant for that case.
- [ ] T7: Add a self-test plant whose log carries a near-miss warning, with
      no PDF and a non-zero exit, and expect a FAIL line (review D2). In the
      skip cases, plant a running Quarto version that is not the pin (D5).
- [ ] T8: Correct the comment at `.github/workflows/versions.yml:361-364`,
      so it also names the Typst-book refusal skips (review P2a).
- [ ] T9: Repeat T5's three runs and record their skip lines.

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
