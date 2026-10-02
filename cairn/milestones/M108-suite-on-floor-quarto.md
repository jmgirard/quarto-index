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
`/A /GoTo` links, a bold face without "Bold" in its font name, an italic face
without "Italic" in its font name, and a glyph the font maps to a
compatibility character, such as the `fi` ligature or `‼` for `!!`, which
`tests/typstcheck.py order` and M098-AC7's page check also read. M098-AC7's
front-matter check must read which front-matter fields the template prints.
The gfm checks must read span attributes without the `data-` prefix, and
M12-AC5 must read the gfm title written as a paragraph without `# `. Checks
whose subject is Quarto's own behavior or the suite's own source run on the
pinned Quarto only, and elsewhere print a `skip` line (D-065). The Typst page
gets one sentence. KI110 closes.

**Out:** the version matrix's PDF comparison across engines (KI111) stays in
its candidate row. A CI job that runs the whole suite on the floor Quarto →
candidate row. The suite's `--self-test` run on Quarto 1.5.52 is not a
criterion. The plants added here run on the pinned Quarto.

## Acceptance criteria

- [ ] AC1: With Quarto 1.5.52 first on `PATH`, `tests/run-tests.sh` on the
      head commit exits 0. With Quarto 1.10.18, it exits 0 too.
- [ ] AC2: A line of a run's output that begins with `ok` or `skip` has a
      label: its text after that word and the spaces after it, up to its
      first `:`, or its whole text when it has no `:`. For each label, the
      head's 1.5.52 run prints at least as many `ok` and `skip` lines with
      that label as the merge base's 1.10.18 run prints `ok` lines with it.
      One merge-base line is exempt: the one naming the Producer of
      `m33-noengine/noengine.pdf`, which the `M34-AC4 control (d)` skip line
      stands for. The head's 1.10.18 run prints no `skip` line.
- [ ] AC3: Every `skip` line in the head's 1.5.52 run carries a label that
      begins with one of `M098-AC5`, `M100-AC3`, `M34-AC4 control (d)`,
      `M57-AC7`, `M105-AC1` or `cell guard`, or is exactly
      `M098-AC7 (the outline lists the index)` or `M098-AC7`. Exactly one
      `skip` line's label is exactly `M098-AC7`, and that line states that
      the book fixture with no author is not rendered.
- [ ] AC4: The Books section of `site/typst.qmd` states that Quarto 1.5.52
      does not render a Typst book. It quotes the warning that 1.5.52 prints:
      `The typst format is not supported by book projects`.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T7
- AC2 → T4, T7
- AC3 → T4, T7
- AC4 → T6

## Tasks

- [x] T1: Unpack the Quarto 1.5.52 macOS tarball outside the repo. Run the
      merge base's suite with it first on `PATH` and record the failing
      labels. The suite stops at its first failure, so the planning survey
      ran a copy with `fail()` and every `set -e` turned off. Repeat that
      survey, because checks that M107's crash hid are now reachable.
- [ ] T2: Port `tests/typstindex.py` to Typst 0.11's PDF. Read links that
      carry an `/A /GoTo` action as well as `/Dest`. Find the bold and
      italic faces without relying on "Bold" or "Italic" in the font name.
      Compare text after NFKC normalization, so the `fi` ligature matches,
      in `typstcheck.py order` and M098-AC7's page check too. Make the
      front-matter check read which fields the template prints.
- [ ] T3: Port the gfm checks (M06-AC3, M20-AC5, M21-AC6) to read a span
      attribute with or without the `data-` prefix, and M12-AC5 to read the
      gfm title as a paragraph.
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
- 2026-10-01: T1 survey: the merge base with every abort off prints 68 FAIL lines on 1.5.52 that its 1.10.18 run does not. M08-AC3 no longer fails (M107). M12-AC5 now fails on the gfm title, which 1.5.52 writes as a paragraph.
- 2026-10-01: implement gate chose: amend AC3 for the two Typst-book checks labeled M098-AC7, name the extra 1.5.52 forms in Scope In, read bold and italic from the font descriptor, and spell out ligatures only.
- re-audit: AC3 (full) — the bare M098-AC7 label did not show which check skipped, and "has the label" read as a prefix match. The wording fixes both.
- re-audit: AC3 (full) — the M098-AC7 skip shared its reason with every book skip, and AC2's label read literally kept the `ok` prefix. Both went to the user.
- 2026-10-01: second implement gate: the user adopted the final AC3 (the no-author skip states its own reason) and moved the label definition into AC2. The ligatures-only choice was reversed for full NFKC, because the 1.5.52 font maps `!!` to `‼` (my first gate said the two gave the same results, which was wrong). The front-matter check reads which fields the template prints, since 1.5.52's template does not print `subtitle:`.
- re-audit: AC2 (full) — a line with no `:` had no defined label. The wording fixes it.
- re-audit: AC2 (full) — the Producer line of the no-engine control has no `:` and cannot appear on 1.5.52, and a count inside a label can differ between Quartos. Both went to the user.
- 2026-10-01: third implement gate: the user adopted the final AC2, which exempts the Producer line, and kept counts inside labels as they are (both Quartos print 367 in the sweep lines).
- 2026-10-01: checkpoint, unverified: code for T2-T6 is written (Typst links, faces, NFKC, front-matter rows; gfm spelling and title; skip helper and gates; plants via the new `tests/typstforms.py`; the AC4 sentence; KI110 removed). The 1.5.52 run and the 1.10.18 `--self-test` run are in progress, so no task past T1 is ticked.

## Decisions

- 2026-10-01: M098-AC7's front-matter check reads from the PDF which front-matter fields the template prints. When a field prints, the check expects page 1 for its mark. Which fields print is the template's choice, and so the Quarto's: 1.5.52 prints the abstract alone. The rule the check tests stays fixed: a printed field's mark has a page, and an unprinted field's mark has none. The check requires one printed and one unprinted field, and on the pinned Quarto it still requires the subtitle and the abstract. Chosen at the second implement gate over a skip, because the check is about the extension's output.

## Review
