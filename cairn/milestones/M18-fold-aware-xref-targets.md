<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M18: A cross-reference target is judged against the path the entry prints

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP6
- **Branch/PR:** `m18-fold-aware-xref-targets` / https://github.com/jmgirard/quarto-index/pull/18

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

- [x] AC1 In the intermediate `.tex` copied to `$WORK` at each fold fixture's
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
- [x] AC2 In the LaTeX log of `examples/self-xref.qmd` the dangling-target
      report is counted 0 times — the one count this milestone moves, from 3 —
      while five counts hold as regression pins: the fold-self-reference report
      at 3 in that log, and 3 dangling / 0 fold-self in each of the HTML and
      gfm logs. In the HTML render of that file the three fold-induced targets
      are left unlinked, as they are today.
- [x] AC3 In the LaTeX log of `examples/fold-xref.qmd` the dangling-target
      report is counted exactly once over the whole log, and that one
      occurrence names the fixture's one target whose folded form still names
      no printed path; the fixture's target naming a parent level of a folded
      entry draws none, which is what tells a prefix-closed printed-path set
      from one that is not. In the HTML and gfm logs of the same file the
      report is likewise counted exactly once, naming the same mark, and in
      every log of `examples/fold-xref-both.qmd` it is counted 0 times. The
      LaTeX total for `examples/dangling-xref.qmd` is unchanged at 7.
- [x] AC4 In the compiled `examples/fold-xref.pdf` the printed index parsed by
      `tests/pdfindex.py` equals, for full-list equality and in printed order, a
      depth-tagged outline manifest covering the fixture's entire index: each
      entry folded from four or five written levels sitting at level 2 in that
      instrument's numbering — the third printed level — beneath its parents at
      levels 0 and 1, and each referring entry's own printed text carrying
      `see`/`see also` followed by its target's levels joined with `: `.
- [x] AC5 The report for a target the fold rewrites is counted per mark by its
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
- [x] AC6 The verify slot is clean: `tests/run-tests.sh --self-test` passes.

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
- [x] T7 Prose that asserts the superseded rule: DESIGN.md's Span-pass and
      LaTeX back-end sections, README where it documents the ceiling, the
      `examples/dangling-xref.qmd` fixture prose, and the M14 comment block in
      `tests/run-tests.sh`.
- [x] T8 Run `tests/run-tests.sh --self-test`.

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
- 2026-08-20: T7 — README documents that a target meets the same ceiling an entry does, with the emitted spelling, and that the resolution runs after folding in PDF and on written levels in HTML. DESIGN.md's Span-pass and LaTeX back-end prose extended and its dangling-report paragraph corrected in place (marked `corrected M18`); `examples/dangling-xref.qmd`'s own prose now says which paths its judgements are read off and that nothing in it is deep enough to fold.
- 2026-08-20: the README's HTML half was a documented claim nothing tested, so the M18 section gained a whole-list manifest of `examples/fold-xref.html`'s index — entries nesting four and five deep, every target naming every written level, and the one unresolvable target rendered as text rather than a link. It is the evidence that the LaTeX behaviour is a property of that back-end and not of the mark.
- 2026-08-20: T8 — `tests/run-tests.sh --self-test` passes: 242 checks, 203 without the self-test.
- 2026-08-20: every task done and the verify slot clean; status to review. Acceptance-criterion boxes left unticked for review's own fresh evidence.
- 2026-08-20: review — draft PR #18 opened; fresh `--self-test` run (242 checks, exit 0) executed every criterion and each box was ticked against its own recorded evidence. Consistency gate clean: `cairn_validate` exits 0, `cairn_impact --changed` reports no changed principles, and the `generic` profile names no toolchain checks. No CI is configured on the repo, so the suite run is the whole check surface. Blame-history and prior-review lenses returned zero findings; the diff-bug lens is still running, so this is a pre-gate checkpoint and the findings section is not yet written.
- 2026-08-20: defect return 1 — the [O] diff-bug lens found, and a hand render confirmed, that the fold-rewrite report fires before the fold-self drop, so a target the fold turns into a self-reference draws two contradictory reports: the milestone's own defect class in a new shape. Status back to in-progress. The maintainer directed fixing that and the nine other actioned findings; F11 rejected as intentional redundancy AC3 names.
- 2026-08-20: F1 fixed — the report moved into the branch that keeps a target, so a target the fold drops as a self-reference says that and nothing else. `examples/fold-xref-self.qmd` is the regression fixture: an entry written at three levels whose third carries a comma, against a four-level target that folds onto it. It fails before the fix (two reports) and draws one after. Not a new acceptance criterion — the criteria set is not widened on a milestone carrying a defect return; the pin is a check.
- 2026-08-20: F8 fixed with it — the message no longer calls the `!` spelling what a reader sees; it says the path the entry it points at prints.
- 2026-08-20: F2 fixed — the `marked_paths` and `report_dangling` call-site comments said the resolution set is format-neutral, which D-005 reverses; both corrected in place, marked `corrected M18`.
- 2026-08-20: F3 fixed — `tests/scans/mark-report-keys.py` read `sys.argv[1:4]`, so the new key was outside the scan that exists to keep these keys from going stale. It now takes every key the run passes and asserts it was given some.
- 2026-08-20: F4 fixed — the `self-xref.html` block discarded the href, so AC2's unlinked clause had no check; it now asserts the target text AND that it carries no link.
- 2026-08-20: F5 fixed — `examples/fold-xref-both.qmd` now builds to PDF and its printed row is asserted whitespace-collapsed (a wrap survives that, a wrong fold does not), with both unfolded spellings asserted absent.
- 2026-08-20: F6 fixed — the AC1 level comparison read the manifest on both sides; it now reads the rendered list. F7 fixed with it: a target naming the contested key was added to the fixture, so the entry side's folded-cross-reference stripper is exercised rather than dead.
- 2026-08-20: F10 fixed — the orphaned DESIGN sentence rejoined its subject.
- 2026-08-20: F9 disposition changed from a criterion amendment to a candidate row, absorbed into the M13 report-wording cluster. AC5's promise is bounded to the marks its named procedure enumerates, and no target in either fixture carries an empty level, so on that domain the message does name the depth the author wrote; F9 is behaviour outside it and matches the entry-fold report's precedent. F11 rejected: AC3 names the `dangling-xref` clause explicitly, so the second pin is intentional.
- 2026-08-20: re-review evidence — `tests/run-tests.sh --self-test` passes at 245 checks. One transient `quarto`/deno segfault on an unrelated M06 HTML render was seen once and did not reproduce (that fixture renders exit 0 in isolation, and the re-run was clean).
- 2026-08-20: criteria audit ran in full mode (user-facing tier), fresh-context [O] reader; returned nine findings, all fixed in the drafted criteria before the gate — an unreachable count pin, two single-exemplar families, an instrument the evidence misnamed, a missing discrimination probe, a flat substring test behind a nesting claim, five stale counts reading as fresh verification, and an unrecorded reversal of the report's format-neutrality.
- 2026-08-20: plan gate chose folding targets as entries are folded over patching the two cases separately, because the separate patch leaves an author told to correct a cross-reference that names a real entry; falsified by a fold rule that makes a target resolve onto an entry the author did not mean.
- 2026-08-20: plan gate chose reporting each fold-rewritten target over staying silent when the folded target resolves, because otherwise the only notice of a rewritten target sits on a different mark; falsified by build logs where the per-target report drowns the reports that need action.
- 2026-08-20: plan gate chose PDF-outline evidence over stopping at the emitted LaTeX, because nothing below the printed page shows the folded target and folded entry meeting; falsified by suite runtime becoming the binding constraint.

## Decisions

## Review

Evidence is a fresh `tests/run-tests.sh --self-test` run on cd34b7a (242 checks,
all passing) and the per-format render logs that run produced under
`tests/.work/`. Counts below are read out of those logs, not recalled.

- AC1 — `M18-AC1` passes: both fold fixtures emit exactly the `\index` command
  lists their manifests hold, compared for list equality, and every folded
  target's levels equal the printed levels of the entry it names across all
  three rendering sites — the single-attribute encapsulation (`Elm`, `Koa`,
  `Pine`), a contested key's printed field (`Zinc`) and the both-attributes
  command (`Yuc`, twice). The literal `!` stays makeindex-quoted on both sides
  and the sort-key entry's target carries printed halves, not filing keys.
- AC2 — `M14-AC4/M18-AC2` passes. `self-xref` logs: latex 0 dangling / 3
  fold-self, html 3 / 0, gfm 3 / 0. The one count this milestone moves is the
  LaTeX dangling, from 3; the other five held as regression pins. The HTML
  index of that fixture leaves the three fold-induced targets unlinked, as
  before.
- AC3 — `M18-AC3` passes. `fold-xref` logs: dangling 1 in each of latex, html
  and gfm, and in latex that one names `entry="Reed"`, quoted as
  `points at "Sil!Tea!Urn!Vin"` — what the author wrote, not the folded path
  the lookup ran on. `entry="Yam"`, whose target names a parent level of a
  folded entry, draws 0, which is the prefix-closure probe. `fold-xref-both`
  draws 0 in all three formats, and `dangling-xref` latex is unchanged at 7.
- AC4 — `M18-AC4` passes: the compiled `examples/fold-xref.pdf` index matches a
  16-row depth-tagged manifest through `tests/pdfindex.py`, row for row and in
  printed order, with `columns_carry_top_level` asserted first. Each of the
  three folded entries prints at level 2 under its two parents, and the
  cross-reference naming it prints that same folded path — `Elm, see Ash: Bay:
  Cod, Dun` against `Ash` / `Bay` / `Cod, Dun`.
- AC5 — `M18-AC5` passes. Per mark in the `fold-xref` latex log: `Elm`, `Koa`,
  `Pine`, `Zinc` and `Reed` at 1 each, total 5; `Yuc` at 2 in the
  `fold-xref-both` latex log, total 2. The unfolded marks `Wax` and `Yam` draw
  0, and both fixtures' html and gfm logs draw 0. The message is one Lua
  literal in `SINGLE_LITERAL` with `EXPECTED` at 39, and `warn_discrimination`
  proves the count fails when the message is missing and when it is doubled,
  and passes as rendered, on both fixtures.
- AC6 — the verify slot is clean: `tests/run-tests.sh --self-test` exits 0 at
  242 checks.

**Consistency gate.** `cairn_validate` exits 0 — sixteen PASS, seven advisory
OK. `cairn_impact --changed` reports no changed principles: the milestone
works under IP1, IP2, GP2 and GP6 and rewrites architecture prose, but no
IP/GP text moved. The `generic` profile names no toolchain checks, so that half
of the gate is a clean no-op.

**Independent review.** Three fresh-context lenses, distinct evidence bases.

- **[S] blame-history — zero findings.** Traced each touched region to the
  milestone that set its intent: the supersession of M14's format-neutral
  resolution is recorded rather than silent, M10's self-target comparison is
  untouched as D-005 states, and both rewritten checks are stronger than what
  they replaced.
- **[S] prior-review record — zero findings.** The GitHub inline-comment probe
  returned empty, so that surface was skipped. Against the archived `## Review`
  sections the diff closes two past findings rather than reopening any: M14's
  F1 (the contradictory pair) and M16's F11 (the duplicated warn-count).
- **[O] diff-bug — eleven findings**, listed below with their triage. It
  confirmed the core change sound: all three rendering sites read one returned
  list, the printed-path set stays prefix-closed, targets fold to the printed
  levels rather than the filing ones, `report=false` callers stay silent, and
  no caller's table is mutated.

**Findings and triage.**

- **F1 (verified) — `latex.lua:143`: the fold-rewrite report fires
  before the fold-self drop, so one target draws two contradictory reports.**
  Reproduced independently: `[x]{.index entry="A!B!C, D" see="A!B!C!D"}` to
  latex draws `... points at "A!B!C, D" here, the path a reader is sent to in
  this format` and then `... the fold made the target a cross-reference to
  itself, so it is dropped`. This is the milestone's own defect class in a new
  shape. No fixture reaches it: `self-xref`'s fold-self targets are written at
  exactly three levels, so the new report's `> MAX_LEVELS` guard never fires.
- **F2 — `marks.lua:75-80` and `index.lua:74-79`: comments assert the opposite
  of what the code now does.** Both still say the resolution set is
  format-neutral because whether a target names an indexed term is a fact about
  what the author wrote, which D-005 reverses. DESIGN.md was corrected; the
  source comment a reader hits first was not.
- **F3 (verified) — `tests/scans/mark-report-keys.py` reads `sys.argv[1:4]` and
  `run_scan mark-report-keys` passes three keys, so `WARN_FOLD_TARGET` is not
  held to matching exactly one filter warning.** `warn-distinct`'s
  `SINGLE_LITERAL` pins a different needle, so rewording the message tail would
  leave that scan green while every zero-expectation AC5 control passes
  vacuously.
- **F4 — AC2's HTML clause has no check.** The block reading `self-xref.html`
  discards `resolved` and `href`, so it asserts the three targets survive but
  never that they are unlinked. Behaviour is unchanged from main, so this is an
  evidence gap rather than a defect.
- **F5 — `examples/fold-xref-both.qmd` never reaches a compiled artifact**, so
  the both-attributes site's folded rendering stops at `.tex`, short of GP6.
  The reviewer compiled it by hand and it prints correctly, so the risk is real
  but unrealized.
- **F6 — the AC1 level comparison reads `want` on both sides**, so it is an
  internal-consistency check on hand-written strings; it is sound only because
  the list-equality gate `continue`s first.
- **F7 — `entry_levels`'s folded-cross-reference stripper is dead**: the only
  entry row carrying one is never an entry row in `PAIRS`, so the work-log
  claim that the entry side is stripped of a folded cross-reference is
  untested.
- **F8 — `latex.lua:143` quotes `levels_key(folded)` (`One!Two!Three, Four`)
  while calling it the path a reader is sent to**; the printed index shows
  `One: Two: Three, Four`.
- **F9 — AC5's wording.** The message's depth is the post-empty-level-drop
  depth, not "the depth the author wrote": `see="!A!B!C!D"` reports four
  against five written. Consistent with the entry-fold message's precedent, so
  the criterion's wording is what is wrong.
- **F10 — `cairn/DESIGN.md:206`: a pre-existing orphaned sentence** ("then
  branches per format and records what that back-end will need.") now sits five
  lines further from its subject.
- **F11 — `tests/run-tests.sh` duplicates M14's existing per-format pin** of
  `dangling-xref` at 7. AC3 names that clause explicitly, so the redundancy is
  intentional; harmless.

**Dispositions.** F1 returned the milestone to `in-progress` under the return
floor — a load-bearing defect in what the deliverable does for its users, and
the milestone's own defect class in a new shape. It and F2–F8 and F10 were
fixed on the branch at the maintainer's direction; each fix has its own
work-log line. F9 was reclassified from a criterion amendment to a candidate
row (absorbed into the M13 report-wording cluster): AC5's promise is bounded to
the marks its named procedure enumerates, no target in either fixture carries an
empty level, so on that domain the message does name the depth the author
wrote. F11 rejected — AC3 names that clause explicitly, so the second pin is
intentional. Defect returns: 1. Amendment returns: 0.

**Re-review.** `tests/run-tests.sh --self-test` passes at 245 checks after the
fixes. Every criterion's counts re-read from that run's logs and unchanged:
`fold-xref` latex 1 dangling / 5 fold-target, html and gfm 1 / 0;
`fold-xref-both` 0 / 2 latex and 0 / 0 elsewhere; `self-xref` latex 0 / 3
fold-self against 3 / 0 in html and gfm; `dangling-xref` latex 7. The new
regression fixture `fold-xref-self` draws 1 fold-self and 0 of everything else
in latex, and 1 format-neutral report in html and gfm.
