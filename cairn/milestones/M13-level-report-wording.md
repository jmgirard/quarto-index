# M13: Level reports name a depth the author can act on

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP1
- **Branch/PR:** m13-level-report-wording / https://github.com/jmgirard/quarto-index/pull/13

## Goal

The two reports about a mark's levels say something the author can act on: an
empty level is reported once per mark naming which written positions were
empty, and the extra-sort-levels report stops reading as a claim about the
depth the entry indexes at.

## Scope

Surface tier: **user-facing** — the deliverable is author-visible warning text
the whole Quarto community reads (GP1).

**In:** the empty-index-level report in `drop_empty_levels`
(`_extensions/index/index.lua:266`), rewritten to fire once per mark and name
the empty positions in the value as the author wrote it; the
extra-sort-levels report in `sort_levels` (`index.lua:337`), rewritten so both
its numbers are labelled as depths of the values as written; the suite checks,
fixtures and prose those two rewrites move.

**Out:** reporting a cross-reference target that names no index entry → M14.
Any change to which levels are dropped or which sort keys survive — D-002's
semantics stand, only the reports change; a change there returns to plan.
Naming the depth the entry *indexes* at, which the shared layer cannot know
because the LaTeX fold happens later (`index.lua:209`) → refused outright, not
deferred. Reader-facing string policy (hard-coded English, `lang`) → stays the
existing candidate row.

## Acceptance criteria

- [x] AC1 A mark whose `entry=` value carries empty levels draws exactly one
      empty-level report, naming which written positions were empty and how
      many levels remain **in the value**. Shapes probed: leading
      (`entry="!Cats"`), trailing (`entry="Dogs!"`), both in one mark
      (`entry="!Sub!"`), and the deep trailing shape `demo.qmd` already
      carries. A value that is only empty levels keeps its existing
      whole-value report and draws none of this one. Evidence: those shapes
      rendered to LaTeX, HTML and gfm; the report text asserted verbatim and
      counted as exactly 1 per mark in each of the three render logs.
- [x] AC2 The report distinguishes a leading empty level from a trailing one
      by naming the position, not merely by echoing a different `entry=`
      value. Evidence: a suite check comparing the reports for `entry="!Cats"`
      and `entry="Dogs!"` with the echoed value masked out, proved
      discriminating by revert (T6) — the pre-milestone reports differ only in
      the echoed value and must fail this check.
- [x] AC3 Both numbers in the extra-sort-levels report are labelled as counts
      taken before any empty level is dropped, so neither reads as the depth
      the entry indexes at, and the wording holds for a mark carrying `sort=`
      with no `entry=`. Evidence: a fixture whose written entry depth (2),
      sort depth (3) and indexed depth (1) all differ (`entry="Moles!"
      sort="a!b!c"`), and a second mark of the no-`entry=` shape
      (`sort="a!b!c"` on visible text, one level via the fallback at
      `index.lua:311`); each report's new text asserted verbatim, and the
      single-level `\index{a@Moles}` emitted for the first mark asserted,
      showing the indexed depth the report does not name.
- [x] AC4 Every `warn(` message in `index.lua` is distinct from every other,
      and each of the two rewritten reports is written as a single literal, so
      the scan reads whole messages rather than first fragments (M10 lesson).
      Evidence: the suite's distinctness scan, which enumerates every
      `warn(`-leading literal in the source, passes.
- [x] AC5 Neither report fires for the well-formed marks of `examples/sortkey.qmd`
      or for the no-empty-level control `entry="Birds!Wrens"` of
      `examples/empty-levels.qmd`. Evidence: per-line greps over the pdf and
      HTML logs the suite already produces for `examples/sortkey.qmd`
      (`tests/run-tests.sh:4714`, `:4793`) and over the LaTeX, HTML and gfm logs
      it produces for `examples/empty-levels.qmd` (`:5984`), asserting no report
      line names any mark of `sortkey.qmd` or that control.
- [x] AC6 The `verify` slot is clean: `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T2, T3, T5
- AC2 → T3, T5, T6
- AC3 → T2, T4, T5
- AC4 → T3, T4, T5
- AC5 → T2, T5
- AC6 → T7

## Tasks

- [x] T1 Baseline probe: render `examples/empty-levels.qmd` and
      `examples/demo.qmd` to LaTeX, HTML and gfm and record verbatim what each
      of the two reports says today and how many times each fires per mark.
- [x] T2 Fixture work in `examples/empty-levels.qmd`: add the three-way depth
      shape (`entry="Moles!" sort="a!b!c"`) and the no-`entry=` shape
      (`sort="a!b!c"` on visible text).
- [x] T3 Rewrite the empty-level report (`index.lua:266`): one report per
      mark, naming the empty written positions and the levels that remain in
      the value. One literal per message.
- [x] T4 Rewrite the extra-sort-levels report (`index.lua:337`) so both
      numbers are labelled as written depths.
- [x] T5 Suite, by procedure not by hand-list: grep every occurrence of
      `WARN_EMPTY_LEVEL`, `WARN_SORT_EXTRA` and `WARN_SORT_DROPPED` and every
      literal quoting either message, and update each hit — the known ones are
      `tests/run-tests.sh:1245`, `:2486`, `:3537`, `:5033`, `:5087`, `:5973`,
      `:5991`, `:6007`, `:6010`, `:6238`. Add the AC1–AC3 and AC5 checks,
      asserting message identity rather than occurrence alone (M08 lesson),
      and pin the distinctness scan's literal count to an explicit integer so
      a fragmented message fails it.
- [x] T6 Prove each new check discriminating: commit the fix first, then
      revert each report rewrite in turn and record which check fails (M08
      lesson — a revert probe on uncommitted work destroys it).
- [x] T7 Update the README and DESIGN prose that quotes either report; run
      `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-19: created by /milestone-plan.
- 2026-08-19: plan gate chose one report per mark naming written positions over one report per dropped level because two byte-identical warnings name neither end (M11 review F8); falsified by evidence that a written position is not something an author can locate in their own value.
- 2026-08-19: plan gate chose labelling the extra-sort-levels numbers as written depths over restating them as indexed depths because the shared layer cannot know the indexed depth — the LaTeX fold runs later (index.lua:209); falsified by evidence that the author needs the indexed depth at that report rather than at the empty-level one.
- 2026-08-19: criteria audit (full mode, fresh-context [O] reader) returned 8 findings against this file; all 8 had one clear repair and were fixed here — AC1 no longer promises the indexed depth, AC2 now requires a position clause (it was satisfied at HEAD), AC3 became a labelling requirement (its property was already true), AC4 dropped an unfalsifiable literal-count claim, AC5's evidence became per-line greps rather than an impossible zero-grep over a whole log, and T5's hand-list became a grep procedure with six further sites named.

- 2026-08-19: T1 baseline probe: `entry="!Sub!"` draws two byte-identical empty-level reports and the leading/trailing pair differs only in the echoed value, confirming AC1 and AC2's premises.
- 2026-08-19: amendment (substantive, mini gate): AC5 was unsatisfiable — its control `entry="Q!R"` correctly draws the extra-sort report, since `sort="Q!R!S"` overreaches by design. Amended to drop that control, state the bounded claim directly, and name the logs the suite actually produces (sortkey.qmd has pdf and HTML only, no gfm or LaTeX). T2's control clause trimmed to match. Fresh-context [O] reader ran the full-mode questions on the amended wording before it was written.
- 2026-08-19: implement gate chose numbered written positions over named ends for the empty-level report because named ends have no wording for a middle position, and "was written with" over naming `entry=` directly for the extra-sort report because a mark can carry `sort=` with no `entry=`; falsified by evidence that authors read a position number as an output position rather than a position in their own value.

- 2026-08-19: amendment (substantive, mini gate): AC3's fixture value renamed `Cats!` -> `Moles!` — `entry="Cats!"` shares its level path with the file's existing `entry="!Cats"` probe, so the registered sort key `a` attached to that probe too and its `\index{Cats}` became `\index{a@Cats}` (verified by render).
- 2026-08-19: amendment (substantive, second on AC3, user-selected): the fresh-context [O] reader of the renamed wording found the proposed message false for a mark with `sort=` and no `entry=` — it reaches the report through the visible-text fallback (index.lua:311) and would be told its index entry "was written with" a depth it never wrote. Message reworded to "against the N it has to sort before empty levels are dropped"; AC3 widened to cover that shape and T2 given its fixture.

- 2026-08-19: T2 done — `entry="Moles!" sort="a!b!c"` and `[ferns]{.index sort="a!b!c"}` added to examples/empty-levels.qmd; render confirms `\index{a@Moles}`, `\index{a@ferns}` and `\index{Cats}` unsorted again.

- 2026-08-19: T3, T4 done — both reports rewritten as single literals; suite green at 170 checks after updating the M11 counts (empty-level 6 marks not 6 levels, sort-dropped 2->3, sort-extra 1->3), manifest 1r's derivation comment, and the three empty-levels manifests for the two new marks.

- 2026-08-19: T5 done — M13-AC1/AC2/AC3/AC5 checks added, asserting whole message text; the distinctness scan's `< 6` floor replaced with a pinned count of 36 plus a call-site/literal agreement check. That new check found a defect in itself, not in the filter: `\bwarn\(` also matches the definition and two comment mentions, so it now scans with line comments stripped. Suite 170 -> 174 checks.

- 2026-08-19: T6 in progress — probe 1 (revert the empty-level report to its pre-M13 per-level form) fails M11-AC5 on the per-mark count (7 not 6) and, once past that, M13-AC1 on the position-naming text; the pre-M13 message draws 0 of the 1 expected. Probe 2 (revert the extra-sort report) and the distinctness-pin probe not yet run. Paused here at the user's request; working tree clean at this commit.

- 2026-08-19: T6 probe 2: reverting the extra-sort report to its pre-M13 wording fails M13-AC3, which draws 0 of the 1 expected.
- 2026-08-19: T6 probe 3 PASSED, which is the finding: splitting a message across `..` leaves both the literal count and the call count unchanged, so the pinned count committed at T5 cannot see fragmentation. The T5 commit message's claim that it could is wrong, superseded here. Repaired by rewriting the distinctness scan to join every literal in a warn() call's message expression, so all 36 warnings are compared whole rather than by first fragment — the underlying property AC4 names, now enforced directly instead of via a proxy.
- 2026-08-19: T6 probe 3b: a duplicate message planted as a concatenation whose first literal differs is caught by the whole-message scan and invisible to the first-literal one — the two scans run side by side on the same planted filter.

- 2026-08-19: T6 probe 4: reverting the empty-level report with the AC1 checks relaxed so the run reaches it fails M13-AC2 on exactly its own terms — the two reports are identical once the echoed value is masked. All four probes recorded; every new check fails against the pre-M13 filter.
- 2026-08-19: T7 done — README's empty-level paragraph and sort-report bullet rewritten against observed output, DESIGN's Span-pass paragraph given the two reports' rule; the README-claim pins for both sections updated (M06-AC6 gains one claim, M11-AC6 three). `tests/run-tests.sh --self-test` green at 191 checks.
- 2026-08-19: all tasks done, verify slot clean; status -> review.

## Decisions

## Review

Evidence gathered 2026-08-19 on the branch at b6c884c, by running the verify
slot fresh (`tests/run-tests.sh --self-test`, exit 0, 191 checks).

- AC1 — `M13-AC1` passes: the leading, trailing and both-ends reports each
  appear exactly once in the LaTeX, HTML and gfm logs of `empty-levels.qmd`,
  the all-empty mark draws zero of them, and the six-level shape in
  `demo-latex.log` reports 5 of 6 written levels remaining. The two-empty-level
  mark draws one report, not two.
- AC2 — `M13-AC2` passes: the leading and trailing reports remain distinct
  once the echoed `entry=` value is masked out, so the difference is the named
  position and not the echoed value.
- AC3 — `M13-AC3` passes in all three formats for both shapes: the mark whose
  written, sorted and indexed depths are 2, 3 and 1, and the mark carrying
  `sort=` with no `entry=`. `\index{a@Moles}` is asserted present and the
  multi-level form asserted absent, so the indexed depth the report does not
  name is pinned.
- AC4 — `M02-AC5` passes, reporting all 36 filter warnings mutually distinct
  and compared as whole messages. Both rewritten reports are single literals
  (`index.lua:294`, `index.lua:371`).
- AC5 — `M13-AC5` passes: zero occurrences of either report in the pdf and
  HTML logs of `sortkey.qmd`, and zero report lines naming
  `entry="Birds!Wrens"` in the three `empty-levels.qmd` logs.
- AC6 — the verify slot is clean: `tests/run-tests.sh --self-test` exits 0 at
  191 checks (170 before this milestone).

Consistency gate: `cairn_validate` all checks passed. No `DESIGN.md` principle
changed, so `cairn_impact` does not apply. The `generic` profile names no
toolchain checks, so that half of the gate is a clean no-op.

Discrimination: four revert probes recorded at T6 — reverting the empty-level
report fails `M11-AC5` and `M13-AC1`, and `M13-AC2` once those are relaxed so
the run reaches it; reverting the extra-sort report fails `M13-AC3`; a
duplicate planted as a concatenation is caught by the rewritten distinctness
scan and invisible to the old one.

### Findings
