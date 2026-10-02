# M108: The acceptance suite passes on Quarto 1.5.52

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M107
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** user-facing — it adds a sentence to the Typst docs page, beside the suite work
- **Branch/PR:** m108-suite-on-floor-quarto

## Goal

On Quarto 1.5.52, the suite passes while it checks the extension's output,
and the Typst page says that this Quarto renders no Typst book.

## Scope

**In:** the suite's readers whose subject is the extension's output, made to
read the forms that Quarto 1.5.52 writes. In `tests/typstindex.py` these are
`/A /GoTo` links, a bold face without "Bold" in its font name, and the `fi`
ligature. The gfm checks must read span attributes without the `data-`
prefix. Checks whose subject is Quarto's own behavior or the suite's own
source run on the pinned Quarto only, and elsewhere print a `skip` line
(D-065). The Typst page gets one sentence. KI110 closes.

**Out:** the version matrix's PDF comparison across engines (KI111) stays in
its candidate row. A CI job that runs the whole suite on the floor Quarto →
candidate row. The suite's `--self-test` run on Quarto 1.5.52 is not a
criterion. The plants added here run on the pinned Quarto.

## Acceptance criteria

- [ ] AC1: With Quarto 1.5.52 first on `PATH`, `tests/run-tests.sh` on the
      head commit exits 0. With Quarto 1.10.18, it exits 0 too.
- [ ] AC2: A check label is the text of an `ok` line before its first `:`.
      For each label, the head's 1.5.52 run prints at least as many `ok` and
      `skip` lines with that label as the merge base's 1.10.18 run prints
      `ok` lines with it. The head's 1.10.18 run prints no `skip` line.
- [ ] AC3: Every `skip` line in the head's 1.5.52 run carries a label that
      begins with one of `M098-AC5`, `M100-AC3`, `M34-AC4 control (d)`,
      `M57-AC7`, `M105-AC1` or `cell guard`.
- [ ] AC4: The Books section of `site/typst.qmd` states that Quarto 1.5.52
      does not render a Typst book. It quotes the warning that 1.5.52 prints:
      `The typst format is not supported by book projects`.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T7
- AC2 → T4, T7
- AC3 → T4, T7
- AC4 → T6

## Tasks

- [ ] T1: Unpack the Quarto 1.5.52 macOS tarball outside the repo. Run the
      merge base's suite with it first on `PATH` and record the failing
      labels. The suite stops at its first failure, so the planning survey
      ran a copy with `fail()` and every `set -e` turned off. Repeat that
      survey, because checks that M107's crash hid are now reachable.
- [ ] T2: Port `tests/typstindex.py` to Typst 0.11's PDF. Read links that
      carry an `/A /GoTo` action as well as `/Dest`. Find the bold face
      without relying on "Bold" in the font name. Compare text after NFKC
      normalization, so the `fi` ligature matches.
- [ ] T3: Port the gfm checks (M06-AC3, M20-AC5, M21-AC6) to read a span
      attribute with or without the `data-` prefix.
- [ ] T4: Add one skip helper. It prints `skip`, the check's label, the
      running Quarto and the reason. It skips only when the running Quarto is
      not the version that `pages.yml` pins. Gate the checks that AC3 lists
      with it, and take the Typst-book captures out of the 1.5.52 run.
- [ ] T5: Add planted-defect self-test cases for each new form the readers
      accept: a `/GoTo` link removed, a bold face dropped, an `fi` ligature
      term misspelled, and a gfm span attribute dropped in each spelling.
      Each case goes red on its own.
- [ ] T6: Write the AC4 sentence from a Typst book render under 1.5.52, and
      remove KI110 from `cairn/DESIGN.md`. The candidate row for KI110 and
      KI111 keeps KI111 alone.
- [ ] T7: Run the head's suite on both Quartos and the merge base's suite on
      1.10.18. Compare the label counts for AC2 and the skip labels for AC3.

## Work log

- 2026-10-01: created by /milestone-plan. Planning survey: the suite under Quarto 1.5.52, with every abort off, gave 69 floor-only `FAIL` lines after a 1.10.18 baseline removed the artifacts of that change. M107's crash causes 2. About 45 come from the Typst PDF reader, 3 from the gfm attribute form, and the rest from checks about Quarto itself or the suite's source.
- 2026-10-01: criteria audit, full mode after the gate made the milestone user-facing, fresh Opus reader, two rounds. It replaced a set comparison with per-label counts against the merge base, added no skips on 1.10.18, closed the skip set to the labels in AC3, moved KI110's closure to a task and the plants to T5, and added the docs sentence to the goal.
- 2026-10-01: plan gate chose porting the output readers and skipping checks about Quarto itself over porting every check, because a per-version expectation for Quarto's own behavior tests Quarto rather than the extension. Falsified by an extension defect on a non-pinned Quarto that a skipped check catches and the ported checks miss.
- 2026-10-01: plan gate chose local floor runs over a CI job in this milestone, because a whole-suite CI job needs TeX, fonts, poppler and PyYAML on the runner. Falsified by a floor-only regression that reaches the default branch unseen by the version matrix.
- 2026-10-01: plan gate placed the Typst-book docs sentence here over a candidate row, beside the skip it explains.

## Decisions

## Review
