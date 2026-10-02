# M109: The suite checks a Typst book on any Quarto that renders one

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — the acceptance suite is this repo's own test tooling, which no user of the extension runs
- **Branch/PR:** —

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
      book's `_book`, and logs no refusal warning. After a render that exits
      0, logs the refusal warning and writes no PDF there, the suite prints
      one `skip` line per check label. Each skip line names the running
      Quarto and the refusal warning. The run fails and names the book after
      any other render. That is a render that exits non-zero, or one that
      writes no PDF or two or more PDFs with no refusal warning. It is also a
      render that logs the refusal warning and writes a PDF.
- [ ] AC2: The M098-AC7 no-author check still runs on the pinned Quarto
      alone, and the reason its `skip` line gives names Quarto's book
      template, the subject of that check, rather than the Typst-book refusal.
- [ ] AC3: On Quarto 1.10.18, the pinned version, `tests/run-tests.sh` and
      `tests/run-tests.sh --self-test` each pass and print no `skip` line.
- [ ] AC4: On Quarto 1.5.52, `tests/run-tests.sh` passes, and the `skip`
      lines it prints for M098-AC5, the M098-AC7 outline check and M100-AC3
      name Quarto's refusal warning, not the pin.
- [ ] AC5: The comment above the M098-AC5 render, the comments above the
      M100-AC3 and M098-AC7 outline gates, and the reason those three checks'
      `skip` lines give state the gate AC1 describes. A search of
      `tests/run-tests.sh` for `Typst book is rendered on the pinned` finds no
      line.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4
- AC3 → T5
- AC4 → T2, T3, T5
- AC5 → T4

## Tasks

- [ ] T1: Write the gate beside `on_pinned_quarto`
      (`tests/run-tests.sh:136-165`). Its inputs are the render's exit
      status, its log, the book's `_book` directory, the book's name and the
      check labels. It runs, skips or fails per AC1's three cases. Add a
      `--self-test` passing control with one PDF, and a plant for the refusal
      with no PDF, which prints skip lines. Add one plant for each failing
      shape AC1 lists. Assert each case by its line text, never by its exit
      status alone.
- [ ] T2: Render `examples/book/` to Typst unconditionally
      (`tests/run-tests.sh:30169-30185`), pass its outcome to the gate, and
      gate the M098-AC5 checks (30233-30250) and the M098-AC7 outline check
      (30955-30963) on the result. Call `m098_no_typst_warning` only on the
      run branch, since Quarto 1.5.52 logs its refusal as a warning.
- [ ] T3: Split `m100_book_read` (30264-30275) so the render and the gate come
      before the read, and gate M100-AC3 (30277-30282) on the result.
- [ ] T4: Give the no-author check (31012-31031) its own reason naming
      Quarto's book template. Rewrite the comment at 30169-30172 and remove or
      rename `TYPST_BOOK_WHY`, then run AC5's search. Re-read every message
      that names the gated set (LESSONS line 40).
- [ ] T5: Run `tests/run-tests.sh` and `--self-test` on Quarto 1.10.18. Then
      run `tests/run-tests.sh` on Quarto 1.5.52 in a separate worktree, as
      `cairn/PROFILE.md` `verify` says, and never edit the script while a run
      reads it. Record each run's skip lines in the work log.

## Work log

- 2026-10-02: created by /milestone-plan.
- 2026-10-02: criteria audit (reduced mode, fresh Opus reader) returned three findings, each fixed before the gate. AC1's "any other outcome" now lists the outcomes by exit status, warning and PDF count. AC1's "each outcome is tested" moved to T1. AC5's search matched two correct pin-gate lines and passed on a renamed variable. It became three named sites and a search for the old wording.
- 2026-10-02: plan gate chose to gate the Typst-book output checks on the render over keeping the pin and dropping the row. Their subject is the extension's output. Falsified by an off-pin red run of these checks traced to Quarto rather than the extension.
- 2026-10-02: plan gate chose the book render's own outcome over a version threshold and over a separate probe book. This repo has not measured the version a threshold needs, and a probe costs a render and can disagree with the fixtures. Falsified by a Quarto that refuses Typst books with a different warning, which this gate fails on.
- 2026-10-02: plan gate chose to keep the hand-written chapter pages off the pin over pinning the page-number checks behind a second gate. A template that moves a chapter turns the run red. Falsified by template moves on newer Quartos turning the run red often enough that the red carries no signal.

## Decisions

## Review
