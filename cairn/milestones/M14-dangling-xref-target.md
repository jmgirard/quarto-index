# M14: A cross-reference target that names no index entry is reported

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP1
- **Branch/PR:** `m14-dangling-xref-target`

## Goal

An author whose `see=` or `see-also=` names a term the document never indexes
is told, instead of shipping a reference the reader cannot follow.

## Scope

Surface tier: **user-facing** — the deliverable is a new author-visible report
in every output format (GP1).

**In:** a format-neutral report in the Pandoc pass, drawn from the level paths
the document's own marks index: a target whose level path is not a path in
that set is reported **once per mark per target**, naming the target as the
author wrote it. Whether a target resolves is a fact about what the author
wrote and what the document indexes, not about a back-end, so the report lives
beside the other format-neutral mark reports (IP1) rather than in the HTML
back-end where the entry tree happens to exist (`index.lua:1183`). A target
already dropped as a self-reference is not also reported here. In an HTML book
the report is drawn by the **last chapter in book order** — the only chapter
that has seen every other chapter's record, and already the chapter that draws
the no-marker report (`index.lua:2110-2118`) — never by the chapter that
builds the index, which may sit first (`examples/book-order/index.qmd:10`) and
would then report a resolving cross-chapter target as broken.

**Out:** the HTML rendering of an unresolvable target (still plain text with
no href) and the LaTeX printed prose both stay as they are; only the report is
new. A target that resolves against the written levels but not against the
LaTeX three-level fold is back-end-specific, the shape M10 put in the LaTeX
back-end → new candidate row. Reconciling the existing example corpus so its
~250 probe targets resolve → new candidate row; this milestone records the
expected count per example instead. Reader-facing string policy (`lang`) →
the existing candidate row.

## Acceptance criteria

- [ ] AC1 A document that indexes `Cats` and writes `see="Felines"`, which
      nothing indexes, draws exactly one report naming `Felines`. Evidence: a
      new fixture rendered to LaTeX, HTML and gfm; the report's full text and
      an occurrence count of 1 asserted in each of the three render logs.
- [ ] AC2 A target that resolves draws no report, across every resolution
      shape the new fixture carries: an exact single-level match, a
      multi-level path match, and a match against a level that exists only as
      a parent of a deeper entry. Evidence: exact-zero assertions for the
      report's text over the LaTeX, HTML and gfm logs of a purpose-built
      fixture whose every target resolves.
- [ ] AC3 The report fires per mark per target, over a family varied in form
      as well as position: a dangling `see-also=` beside a resolving `see=`,
      the inversion of that, a multi-level dangling target, a partial-path
      target (`Cats!Kittens` where only `Cats` is indexed), and one dangling
      target written on two separate marks. Evidence: each shape in the new
      fixture with its own expected count asserted, and the resolving target's
      text asserted absent from every report line.
- [ ] AC4 A target dropped as a format-neutral self-reference draws its
      existing report and not this one. Evidence: over the LaTeX, HTML and gfm
      logs of `examples/self-xref.qmd`, the new report's text asserted absent
      from the lines naming the four format-neutral self-target marks, with
      their existing reports asserted still present. The file's three
      fold-induced shapes (`self-xref.qmd:47-54`) do dangle format-neutrally
      and their nonzero counts are pinned rather than zeroed.
- [ ] AC5 In an HTML book the report is drawn once for a target naming
      nothing in the book, and not at all for a target naming a term indexed
      in another chapter — including in `examples/book-order`, whose
      placement marker sits in the first chapter. Evidence: both shapes added
      to both book fixtures; the report counted as exactly 1 across each whole
      book render, which is only reachable if a single chapter draws it.
- [ ] AC6 The new report is distinct from every other `warn(` message in
      `index.lua` and is written as a single literal, so the scan reads the
      whole message rather than its first fragment (M10 lesson). Evidence: the
      suite's distinctness scan, which enumerates every `warn(`-leading
      literal in the source, passes.
- [ ] AC7 The `verify` slot is clean: `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T3, T5, T6
- AC2 → T3, T5, T6
- AC3 → T3, T5, T6
- AC4 → T3, T6
- AC5 → T4, T5, T6
- AC6 → T3, T6
- AC7 → T8

## Tasks

- [x] T1 Baseline probe: render a dangling-target shape to LaTeX, HTML and
      gfm and to both book fixtures, and record what each format emits today
      and where it is silent.
- [x] T2 Pin the resolution rule against the HTML back-end's own walk
      (`lookup_entry`, `index.lua:1172`): a target resolves when its level
      list is a path in the marked-entry set, parent nodes included. Record it
      as a milestone-local decision so the two cannot drift.
- [x] T3 Build the marked-entry path set format-neutrally in the Pandoc pass
      and emit the report there, once per mark per target, excluding targets
      already dropped as self-references (`index.lua:848`).
- [x] T4 Book path: draw the report from the last chapter in book order,
      against the store as of this render, reusing the chapter-position logic
      the no-marker report already uses (`index.lua:2110-2118`).
- [x] T5 Fixtures: a new dangling-target fixture carrying AC1's and AC3's
      shapes; a new all-resolving fixture for AC2; a cross-chapter resolving
      target and a book-wide dangling one added to both book fixtures.
- [x] T6 Suite checks for AC1–AC6, and the corpus reconciliation the report
      forces: grep every `see=`/`see-also=` value in `examples/` and record
      the expected report count for each example whose targets dangle
      (`demo.qmd`, `xref-escaping.qmd`, `self-xref.qmd` among them), by
      procedure rather than by hand-list.
- [x] T7 Prove each new check discriminating: commit the fix first, then
      revert the report and record which checks fail (M08 lesson).
- [x] T8 Update the DESIGN architecture paragraph on cross-reference targets
      and the README; run `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-19: created by /milestone-plan.
- 2026-08-19: plan gate chose a format-neutral report in the Pandoc pass over an HTML-back-end-only report because whether a target names an indexed term depends on what the author wrote and what the document indexes, not on any back-end (IP1); falsified by evidence that a format without an index back-end cannot know its own marked-entry set.
- 2026-08-19: plan gate chose drawing the book report from the last chapter in book order over the chapter that builds the index, because every chapter reads the whole store (index.lua:2069) but only the last has seen every record — a marker-first book would otherwise report resolving cross-chapter targets as broken; falsified by evidence that the last chapter can fail to render in a partial render the report must still be right about.
- 2026-08-19: plan gate chose pinning the expected report count for each existing example over adding ~250 index marks so the probe corpus resolves, because the escaping probe's assertions are built on its current marks; falsified by the pinned counts proving unmaintainable across later fixture edits. Corpus reconciliation queued as a candidate row.
- 2026-08-19: implement gate chose the actionable "points at" wording (target named, reader consequence, both fixes) over a short form, and pinned per-example report counts with a grep-derived roster of the examples that must carry one over a Python routine re-deriving counts from source, which could share a bug with the filter.
- 2026-08-19: T1 baseline probe: a mark whose `see=` names a term nothing indexes is silent today in all three formats (LaTeX emits `\index{Lions|see{Felines}}`, HTML renders the target as an unlinked `qi-target` span, gfm passes the attribute through) and silent in both book fixtures — `examples/book` renders warning-free with its `see="No Such Entry"` already in place, and `examples/book-order` emits only its two marker-order warnings.
- 2026-08-19: T2 pinned the resolution rule as a milestone-local decision, and why the report cannot share the HTML walk.
- 2026-08-19: T3 built the marked-entry path set (`marked_paths`, every mark's level prefixes) and the deferred target list (`pending_xrefs`) format-neutrally in the Span pass, and emit the report from the Pandoc pass, which is the first point that has seen every mark; a target dropped as a self-reference never enters the list, one the LaTeX fold later drops still does.
- 2026-08-19: T4 draws the book report from the last chapter in book order against the whole store; the mark's context string is now carried in the per-chapter record (STORE_VERSION 3 -> 4, `valid_record` requires it) because the reporting chapter runs in another process. Verified on `examples/book`: one report naming `No Such Entry`, none for the cross-chapter `see="Alpha"`.
- 2026-08-19: T3/T4 fallout in the suite, committed with them so `verify` stays clean: the warn-distinctness count 36 -> 37 with the new report added to the single-literal list (M14-AC6), and M05-AC4's "the book renders warning-free" replaced by the stronger claim it was really making -- the book's only warning is the one dangling report, so the resolvable cross-file target draws none.
- 2026-08-19: T5 added `examples/dangling-xref.qmd` (AC1's shape plus AC3's five: dangling see-also beside a resolving see=, the inversion, a multi-level target, a partial-path target, and one target on two marks -- 7 reports, identical in LaTeX, HTML and gfm) and `examples/resolving-xref.qmd` (exact single-level, full multi-level path, and parent-of-a-deeper-entry -- 0 reports in all three). `examples/book` already carried both AC5 shapes (`see="Alpha"` cross-chapter, `see="No Such Entry"` book-wide), so only `examples/book-order` gained them: `Early Reference` -> `Late` in the marker-first chapter draws nothing even on the first render, `Missing Reference` draws exactly one across the whole book. Neither new mark carries a locator, so no existing anchor moved; manifest 8 and the letter sweep gained their rows (E, M).
- 2026-08-19: T6 added the M14 suite section: AC1's full report text counted 1 in each of LaTeX, HTML and gfm; AC3's six further shapes each with its own count plus a total, so a shape the manifest does not name fails too, and `Cats` absent from every report line; AC2's exact zeros over the resolving fixture; AC4 over the self-xref logs; AC5 over both book-order renders. Added the T2 decision's cross-check: in both fixtures the targets the HTML index leaves unlinked are exactly the targets the report names.
- 2026-08-19: T6 corpus reconciliation: a pinned count per example (`demo` 8, `html-index` 1, `self-xref` 3, `xref-conflict` 6, `xref-escaping` 271, the rest 0 or the new fixtures' own), each checked against a gfm render, with the roster of examples that must carry a count derived by grepping `examples/` rather than written down. Book chapters carry per-chapter rows that must sum to what their book reports.
- 2026-08-19: T6 fixture reconciliation found by the new report: `examples/self-xref.qmd`'s both-attributes mark carried `see-also="Pets"`, a target the file never indexed, so the surviving half of the mark M08 added to prove a surviving target is still emitted was itself a broken cross-reference. Retargeted to `Cats`, which the file marks; the three suite pins on that encap follow it. Without this AC4's absence clause was unsatisfiable, since that mark's line would carry a dangling report of its own.
- 2026-08-19: T7 discrimination probes, run against a non-exiting copy of the suite so every failure is collected rather than only the first. (a) Report reverted (both call sites neutered): 51 checks fail -- every AC1, AC3, AC4 fold-shape, AC5 and corpus count, plus the resolution-rule cross-check. (b) Report over-reporting (resolution ignored, every target named): 26 fail -- AC2's three exact zeros, AC4's self-reference absence clause on `entry="Dogs"`, AC3's `Cats` absence clause, every pinned corpus count, and the cross-check again. (c) Resolution truncated to the target's first level: 24 fail, led by AC3's partial-path row (`Cats!Kittens`) and the multi-level row, which is the defect those two rows exist for. The exact-zero clauses cannot fail under (a) and the counts cannot fail under (b) -- each direction is discriminated by its partner in the same fixture family, which is why both fixtures exist.
- 2026-08-19: T8 documented the report in DESIGN (a new paragraph beside the shared-layer one: why it is drawn from the collected level paths rather than the HTML entry tree, that a prefix resolves, and the book's last-chapter rule) and in README (a `see=`/`see-also=` naming nothing indexed is reported, not dropped, once per mark per target, with the parent-level and book cases). Four README sentences pinned in the misuse-claims array. Widened the `marks_seen` module-level-state candidate row with the two accumulators this milestone adds. `tests/run-tests.sh --self-test` passes: 216 checks.
- 2026-08-19: all tasks done; `tests/run-tests.sh --self-test` clean at 216 checks (183 without the self-test, up from 175). Status -> review.
- 2026-08-19: criteria audit (full mode, fresh-context [O] reader) returned 4 findings against this file: AC2 was unsatisfiable (~250 corpus targets dangle) and AC5 rested on a false claim about which chapter knows the book's entries — both went to the question gate and are settled above; AC4's exact-zero over self-xref.qmd was narrowed to the four format-neutral marks, AC3's single exemplar was widened to five shapes, and AC6's unfalsifiable literal-count claim was dropped.

## Decisions

### 2026-08-19 — What makes a cross-reference target resolve

A target resolves when its parsed level list is a path in the set of level
paths this document's marks index, every proper prefix of a marked path
included. The set is built format-neutrally from the levels `derive_levels`
returns for each mark that indexes something — the same levels the HTML
back-end builds its entry tree from (`build_entry_tree`, `index.lua:1114`) —
so a target of `Cats` resolves against a mark indexing `Cats!Kittens`, exactly
as `lookup_entry` (`index.lua:1209`) resolves it: that walk creates a node per
level and returns whichever node the target's last level reaches, parent nodes
included. Paths are compared as `levels_key` strings, which double a literal
`!`, so a single level containing `!` can never read as a two-level path.

The report cannot simply call `lookup_entry`: the tree it walks is built from
the HTML back-end's per-mark records, which a format with no index back-end
never builds. The two are held together by evidence instead of by shared code
— the suite asserts that in the HTML render every target the report does not
name is a link into the index, and every target it does name is unlinked text.

## Review
