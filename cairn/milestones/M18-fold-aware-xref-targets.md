<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M18: A cross-reference target is judged against the path the entry prints

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP6
- **Branch/PR:** —

## Goal

In a LaTeX render a cross-reference target is folded to the back-end's
three-level ceiling exactly as an entry is and resolved against the paths
entries print, so the fold neither draws two contradictory reports about one
target nor ships a cross-reference the printed index cannot answer.

## Scope

Surface tier: **user-facing** — the deliverable is what an author reads in the
build log and what a reader follows in the printed index.

Promoted from the ROADMAP candidate "The written-levels/LaTeX-fold divergence
is undiagnosed in both directions" (added 2026-08-19, widened by M14 review
F1), which this milestone absorbs whole.

**In:** the LaTeX back-end folds a cross-reference target's levels by the same
rule it folds an entry's, and resolves targets against printed (clamped) paths
rather than written ones; a report for each target the fold rewrites; the
fixture, suite checks and PDF evidence for both; the DESIGN.md, README and
in-fixture prose that currently assert the format-neutral rule; a D-entry
recording that target resolution is back-end-relative where a ceiling exists.

**Out:** target resolution in HTML and back-end-less formats — unchanged, and
correct there, since neither folds. The book store's cross-chapter dangling
report — unchanged for the same reason (a PDF book is one document; an HTML
book has no ceiling). Reconciling `examples/xref-escaping.qmd`'s corpus so its
targets resolve → its own candidate row. The `see One Way; see Another Way`
print-convention wording → the see-also candidate row.

## Acceptance criteria

- [ ] AC1 In `examples/fold-xref.tex` each of the four fold-rewritten targets
      emits its `\index{…}` command verbatim, exactly once; and for each of the
      three whose referenced entry the fixture marks, the string inside that
      command's `see`/`seealso` argument is character-for-character the
      argument of that entry's own `\index{…}` command. Evidence: the seven
      literals asserted at exactly one occurrence each, listed with their
      derivation in the fixture's manifest comment.
- [ ] AC2 In the LaTeX log of `examples/self-xref.qmd` the dangling-target
      report is counted 0 times — the one count this milestone moves, from 3 —
      while five counts hold as regression pins: the fold-self-reference report
      at 3 in that log, and 3 dangling / 0 fold-self in each of the HTML and
      gfm logs. In the HTML render of that file the three fold-induced targets
      are left unlinked, as they are today.
- [ ] AC3 In the LaTeX log of `examples/fold-xref.qmd` the dangling-target
      report is counted exactly once — for the one target whose folded form
      still names no printed path — and 0 times for each of the other three,
      asserted per mark by its context string; and the LaTeX total for
      `examples/dangling-xref.qmd` is unchanged at 7.
- [ ] AC4 In the compiled `examples/fold-xref.pdf`, `tests/pdfindex.py` parses
      an index outline in which the folded entry sits at depth 3 beneath its
      two parents, and the referring entry's cross-reference line names that
      same folded path. Evidence: a depth-tagged outline manifest compared
      against the parsed index, as the sort-key clamp twin's manifest is.
- [ ] AC5 The report for a target the fold rewrites fires exactly 4 times in
      the LaTeX log of `examples/fold-xref.qmd` — once per fold-rewritten
      target, asserted per mark by its context string — and 0 times for the
      fixture's shallow control target and in its HTML and gfm logs. The
      message names the mark, the depth the author wrote, and the path the
      target now names; it is one Lua literal, added to
      `tests/scans/warn-distinct.py`'s `SINGLE_LITERAL` tuple with `EXPECTED`
      raised 38 → 39, and is proved discriminating by a `warn_discrimination`
      entry under `--self-test` (missing, duplicated, as-rendered).
- [ ] AC6 The verify slot is clean: `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T2, T4
- AC2 → T2, T5
- AC3 → T2, T5
- AC4 → T1, T6
- AC5 → T3, T5
- AC6 → T8

## Tasks

- [ ] T1 `examples/fold-xref.qmd`: one fold-rewritten target per axis the
      family is free in — `see=` at depth 4, `see-also=` at depth 5 where the
      third printed level joins two overflow levels, and one whose referenced
      entry carries `sort=` so filing and printed paths differ — plus a fourth
      whose folded form names no printed path, and a shallow control target
      needing no fold. Terms no other fixture indexes (M13); the manifest
      comment shows its arithmetic (M12).
- [ ] T2 Fold target levels in `qi_latex.latex_plan`
      (`_extensions/index/modules/latex.lua:116`) and resolve targets against
      printed paths in the LaTeX branch of the Span pass
      (`_extensions/index/modules/passes.lua:190-200`); keep the
      format-neutral self-target comparison and the format-neutral report for
      formats with no ceiling. Escaping still applies to a folded target
      (M02: makeindex parses `!` and `@` inside an encap argument).
- [ ] T3 The report for a fold-rewritten target: one Lua literal, distinct,
      added to `SINGLE_LITERAL` with `EXPECTED` raised.
- [ ] T4 `.tex` literal assertions for AC1; copy the intermediate `.tex` to
      `$WORK` at the LaTeX render, since `--to pdf` deletes it (M15).
- [ ] T5 Warning-count checks for AC2, AC3 and AC5; move the `self-xref`
      LaTeX pin from 3 to 0, add `examples/fold-xref.qmd` to `DANGLING_CORPUS`
      with its derivation, and add the `warn_discrimination` entry.
- [ ] T6 PDF render and outline manifest for AC4.
- [ ] T7 Prose that asserts the superseded rule: DESIGN.md's Span-pass and
      LaTeX back-end sections, README where it documents the ceiling, the
      `examples/dangling-xref.qmd` fixture prose, and the M14 comment block in
      `tests/run-tests.sh`.
- [ ] T8 Run `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-20: created by /milestone-plan.
- 2026-08-20: criteria audit ran in full mode (user-facing tier), fresh-context [O] reader; returned nine findings, all fixed in the drafted criteria before the gate — an unreachable count pin, two single-exemplar families, an instrument the evidence misnamed, a missing discrimination probe, a flat substring test behind a nesting claim, five stale counts reading as fresh verification, and an unrecorded reversal of the report's format-neutrality.
- 2026-08-20: plan gate chose folding targets as entries are folded over patching the two cases separately, because the separate patch leaves an author told to correct a cross-reference that names a real entry; falsified by a fold rule that makes a target resolve onto an entry the author did not mean.
- 2026-08-20: plan gate chose reporting each fold-rewritten target over staying silent when the folded target resolves, because otherwise the only notice of a rewritten target sits on a different mark; falsified by build logs where the per-target report drowns the reports that need action.
- 2026-08-20: plan gate chose PDF-outline evidence over stopping at the emitted LaTeX, because nothing below the printed page shows the folded target and folded entry meeting; falsified by suite runtime becoming the binding constraint.

## Decisions

## Review
