<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M18: A cross-reference target is judged against the path the entry prints

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP6
- **Branch/PR:** `m18-fold-aware-xref-targets`

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

- [ ] AC1 In the intermediate `.tex` copied to `$WORK` at each fold fixture's
      LaTeX render, the full list of emitted `\index{…}` commands, in emitted
      order, equals a manifest in that fixture's comment — one row per emitted
      command, so a command the manifest omits fails rather than passing
      unseen, and a contested key's cross-reference mark contributes none.
      Between them the manifests cover all three sites that render a target: a
      single-attribute encapsulation, a both-attributes encapsulation, and a
      target folded into a contested key's printed text; one overflow level
      carries a literal `!`, which the argument must quote. For each
      fold-rewritten target whose referenced entry its fixture marks, the
      levels inside the target argument are the printed text of each level of
      that entry's own `\index{…}` argument — the part after the `@` where a
      level carries a sort field — the same strings in the same order.
      Evidence: the list equality, plus a check splitting the entry argument on
      unquoted `!` (one not preceded by `"`) and the target argument on `: `,
      and comparing the two level lists.
- [ ] AC2 In the LaTeX log of `examples/self-xref.qmd` the dangling-target
      report is counted 0 times — the one count this milestone moves, from 3 —
      while five counts hold as regression pins: the fold-self-reference report
      at 3 in that log, and 3 dangling / 0 fold-self in each of the HTML and
      gfm logs. In the HTML render of that file the three fold-induced targets
      are left unlinked, as they are today.
- [ ] AC3 In the LaTeX log of `examples/fold-xref.qmd` the dangling-target
      report is counted exactly once over the whole log, and that one
      occurrence names the fixture's one target whose folded form still names
      no printed path; the fixture's target naming a parent level of a folded
      entry draws none, which is what tells a prefix-closed printed-path set
      from one that is not. In the HTML and gfm logs of the same file the
      report is likewise counted exactly once, naming the same mark, and in
      every log of `examples/fold-xref-both.qmd` it is counted 0 times. The
      LaTeX total for `examples/dangling-xref.qmd` is unchanged at 7.
- [ ] AC4 In the compiled `examples/fold-xref.pdf` the printed index parsed by
      `tests/pdfindex.py` equals, for full-list equality and in printed order, a
      depth-tagged outline manifest covering the fixture's entire index: each
      entry folded from four or five written levels sitting at level 2 in that
      instrument's numbering — the third printed level — beneath its parents at
      levels 0 and 1, and each referring entry's own printed text carrying
      `see`/`see also` followed by its target's levels joined with `: `.
- [ ] AC5 The report for a target the fold rewrites is counted per mark by its
      context string: 1 on each of the five marks carrying a fold-rewritten
      target in `examples/fold-xref.qmd` and 2 on the both-attributes mark in
      `examples/fold-xref-both.qmd`, summing to 5 and 2 over those LaTeX logs,
      and 0 over each fixture's HTML and gfm logs; the marks carrying only an
      unfolded target — the shallow control and the parent-level target — are
      named by no such report. The message names the mark, the depth the author
      wrote, and the path the target now names; it is one Lua literal, added to
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

- [x] T1 Two fixtures. `examples/fold-xref.qmd`: `see=` at depth 4;
      `see-also=` at depth 5 where the third printed level joins two overflow
      levels and one carries a literal `!`; one whose referenced entry carries
      `sort=` so filing and printed paths differ; one on a contested key,
      folded into the entry's printed text; one whose folded form names no
      printed path; a shallow control needing no fold; and a target naming a
      parent level of a folded entry. `examples/fold-xref-both.qmd`: its own
      two deep entries and one mark carrying both attributes, each target
      fold-rewritten — kept out of the PDF fixture because that row cannot fit
      an index column without wrapping. Terms no other fixture indexes (M13);
      every row in the PDF fixture short enough not to wrap; the manifest
      comments show their arithmetic (M12).
- [x] T2 Fold target levels in `qi_latex.latex_plan`
      (`_extensions/index/modules/latex.lua:116`) and resolve targets against
      printed paths in the LaTeX branch of the Span pass
      (`_extensions/index/modules/passes.lua:190-200`); keep the
      format-neutral self-target comparison and the format-neutral report for
      formats with no ceiling. Escaping still applies to a folded target
      (M02: makeindex parses `!` and `@` inside an encap argument).
- [x] T3 The report for a fold-rewritten target: one Lua literal, distinct,
      added to `SINGLE_LITERAL` with `EXPECTED` raised.
- [x] T4 `.tex` command-list assertions for AC1 over both fixtures; copy each
      intermediate `.tex` to `$WORK` at its LaTeX render, since `--to pdf`
      deletes it (M15).
- [x] T5 Warning-count checks for AC2, AC3 and AC5; move the `self-xref`
      LaTeX pin from 3 to 0, add both fold fixtures to `DANGLING_CORPUS` with
      their derivations, and add the `warn_discrimination` entry.
- [x] T6 PDF render of `examples/fold-xref.qmd` and its outline manifest for AC4.
- [ ] T7 Prose that asserts the superseded rule: DESIGN.md's Span-pass and
      LaTeX back-end sections, README where it documents the ceiling, the
      `examples/dangling-xref.qmd` fixture prose, and the M14 comment block in
      `tests/run-tests.sh`.
- [ ] T8 Run `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-20: created by /milestone-plan.
- 2026-08-20: in-progress on `m18-fold-aware-xref-targets`, cut from main at 222fa0e.
- 2026-08-20: substantive amendment adopted at the mini gate — AC1, AC3, AC4, AC5 and T1 amended. AC1 as planned was unsatisfiable (an entry's levels join with `!`, a target's with `: `, so the two strings can never be equal); AC4's wrap clause was instrument-bound and unowned; AC5's total-only count admitted a mis-distributed seven; and no criterion probed prefix-closure of the printed-path set or the both-attributes and contested-key rendering sites. The amended wording was read by a fresh-context [O] auditor before it was written, which returned seven findings, all repaired in the adopted text; the criteria set is widened, not narrowed, at the user's selection.
- 2026-08-20: T1 — `examples/fold-xref.qmd` (7 targets: depth-4 `see=`, depth-5 `see-also=` with a literal `!` in an overflow level, a `sort=`-carrying entry, a contested key, one dangling after the fold, a shallow control, and a parent-level target) and `examples/fold-xref-both.qmd` (a both-attributes mark, both targets folded). Both added to `DANGLING_CORPUS` with their derivations; suite green at 197 checks.
- 2026-08-20: baseline recorded before any code change — all three target-rendering sites emit unfolded targets today: `\index{Elm|see{Ash: Bay: Cod: Dun}}` (single encap), `\index{Zinc@Zinc, \see{Ash: Bay: Cod: Dun}{}}` (contested key), `\index{Yuc|quartoindexseeboth{Oat: Pea: Rye: Soy}{Tef: Urd: Vet: Wid: Xan}}` (both attributes), against printed entry paths of `Ash!Bay!Cod, Dun`, `Oat!Pea!Rye, Soy` and `Tef!Urd!Vet, Wid, Xan`.
- 2026-08-20: task-order adjustment — the new contested-key shape failed an M15 check asserting the contested-key emission reaches exactly one fixture. Repaired in place rather than excluded: the check now compares per-file carried shapes against an expected mapping for equality in both directions, so a fixture that silently stops carrying its shape fails as loudly as one that gains a shape it should not have.
- 2026-08-20: T2 — `latex_plan` folds each target by the rule that folds an entry and returns the clamped levels; the Span pass builds the LaTeX plan before recording the resolution set, so `record_marked` records printed paths (prefix-closed as before) and a pending target carries two spellings, the written one for the report and the folded one for the lookup. All three target-rendering sites are covered because all three read `latex_plan`'s returned list. Verified on the fixtures: the single encap, the contested-key printed field and the both-attributes command now all emit the path the referenced entry prints, sort-key case included, and the literal `!` stays quoted.
- 2026-08-20: T3 — the fold-rewritten-target report, one literal, added to `warn-distinct`'s `SINGLE_LITERAL` with `EXPECTED` 38 → 39. `WARN_FOLD_DEPTH` had to be narrowed from `levels deep; the back-end stores` to `and deeper were folded into the third`: the new message shares the ceiling clause, and the suite's distinctness scan caught the key matching two warnings.
- 2026-08-20: M18-AC2 evidence — `examples/self-xref.qmd` now reports 0 dangling / 3 fold-self in LaTeX against 3 / 0 in HTML and gfm; before the change LaTeX drew 3 / 3, the contradictory pair. The M14-AC4 block is superseded for LaTeX alone and says so; suite green at 197 checks.
- 2026-08-20: T4/T5/T6 — a new M18 section renders both fold fixtures to latex, html and gfm, copies each intermediate `.tex` to `$WORK`, and checks: the full emitted `\index` command list of each fixture against a manifest with its per-mark derivation, plus a level-by-level comparison of every folded target against the entry it names (entry side split on unquoted `!` and stripped of sort fields and any folded cross-reference, target side split on `: `); the dangling counts including the parent-level probe and the written-spelling clause; the per-mark fold-rewrite counts with the two unfolded marks and the two ceiling-free formats as negative controls; and the compiled PDF's whole index outline through `tests/pdfindex.py`. `warn_discrimination` entries added for the new report on both fixtures.
- 2026-08-20: the M15 residue sweep needed a second repair — whether `examples/fold-xref.tex` survives to that point depends on whether a PDF render has removed it, so the sweep now reads both contested-key fixtures from `$WORK` copies taken at their own renders and requires no artifact to be present in `examples/`. The fold fixtures' renders moved ahead of that sweep for it.
- 2026-08-20: `tests/plantdefect.py` hardcoded `found 37 warn() messages, expected 38`, so bumping the scan's own count broke the probe that proves the scan discriminates. Now read out of `tests/scans/warn-distinct.py` instead of copied — which closes the acceptance-suite-hardening row's M16 review F11 item.
- 2026-08-20: suite green at 203 checks, 240 under `--self-test`.
- 2026-08-20: criteria audit ran in full mode (user-facing tier), fresh-context [O] reader; returned nine findings, all fixed in the drafted criteria before the gate — an unreachable count pin, two single-exemplar families, an instrument the evidence misnamed, a missing discrimination probe, a flat substring test behind a nesting claim, five stale counts reading as fresh verification, and an unrecorded reversal of the report's format-neutrality.
- 2026-08-20: plan gate chose folding targets as entries are folded over patching the two cases separately, because the separate patch leaves an author told to correct a cross-reference that names a real entry; falsified by a fold rule that makes a target resolve onto an entry the author did not mean.
- 2026-08-20: plan gate chose reporting each fold-rewritten target over staying silent when the folded target resolves, because otherwise the only notice of a rewritten target sits on a different mark; falsified by build logs where the per-target report drowns the reports that need action.
- 2026-08-20: plan gate chose PDF-outline evidence over stopping at the emitted LaTeX, because nothing below the printed page shows the folded target and folded entry meeting; falsified by suite runtime becoming the binding constraint.

## Decisions

## Review
