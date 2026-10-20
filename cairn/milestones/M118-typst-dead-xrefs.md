# M118: A Typst index leaves out what no page backs

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes what a Typst index prints
- **Branch/PR:** m118-typst-dead-xrefs

## Goal

A Typst index prints no cross-reference, entry or index heading that rests
only on marks no page prints.

## Scope

**In:** Finish what M117 began, in `_extensions/index/modules/typst.lua` and
the entry tree it reads. A `see=` or `see-also=` mark gets a Typst label, and
its cross-reference prints only where some mark that writes it is on a page.
A cross-reference target that the index files and leaves out is not printed,
and the kind's word moves to the next target of that kind. An entry whose
every cross-reference is dropped this way, with nothing else that prints, is
left out. An index none of whose entries prints has no heading, outline line
or page. The labels are still looked up while Typst lays out the pages, and a
missing one still fails nothing (IP2). The fixture `examples/typst-unprinted.qmd`,
its manifest and suite section, the `site/typst.qmd` section "A mark Typst
never prints", the Unreleased Typst entry in `CHANGELOG.md`, and the
`DESIGN.md` known issues KI321, KI322 and KI323. Absorbs the candidate row
"Finish leaving out unprinted Typst marks" in full.

**Out:**
- A report that names a dropped cross-reference: declined at the question
  set, because the filter cannot see which page prints. Not planned.
- A range closed in front matter (KI324): the parked row "Pair a range closed
  in front matter".
- Float caption marks (KI290, KI318): their own parked rows.
- The LaTeX, HTML and EPUB back-ends: unchanged.

## Acceptance criteria

- [ ] AC1: On Quarto 1.10.19, whose Typst template does not print
      `description:`, a Typst render of `examples/typst-unprinted.qmd` is held
      by `tests/typstindex.py` to the manifest `tests/typst-unprinted.tsv`,
      and the suite passes that comparison. In that manifest: a term whose
      only mark is a `see=` mark in `description:` has no row, and neither has
      a term whose only mark is a `see-also=` mark there; a term whose one
      `see=` target is written by
      a mark in `description:` and by a mark in the body keeps that
      cross-reference; a parent marked only in `description:`, above a
      sub-entry whose only mark is a `see=` mark in `description:`, has no
      row, and neither has the sub-entry; and a term marked in the body with a
      `see=` target the index prints, and no locator, keeps its row.
- [ ] AC2: In the same manifest, for terms with no page-number mark and no
      sub-entry: a term whose only cross-reference names a term the index
      files and leaves out has no row; a term with two `see=` targets, the
      first of which in the order the index prints them is left out, prints
      `see` and the second target alone; a term whose only cross-reference
      names a term left out by the first clause of this criterion has no row;
      two terms marked
      only in the body, each with a `see=` to the other and no locator, keep
      both rows; and a term with a `see=` target that no mark files keeps that
      cross-reference, and the render's log carries exactly one extension
      warning, the dangling-target report naming that target.
- [ ] AC3: On Quarto 1.10.19, the fixture prints a table of contents, and its
      second index holds two marks: a term marked only in `description:`, and
      a body mark whose only content is a `see=` to that term. The
      `pdftotext` output of its Typst render equals that of a twin render in
      which no mark files in the second index, each body mark's text kept, and
      neither output carries a line beginning `Spare Index`; the suite makes
      this comparison and passes it.
- [ ] AC4: In `site/typst.qmd`, the section "A mark Typst never prints", and
      in `CHANGELOG.md`, the Unreleased entry for the Typst back-end, each say
      that a cross-reference mark in a field no page prints adds no
      cross-reference, that a cross-reference whose target term is left out is
      not printed and nothing reports it, that an entry left with nothing that
      prints is left out, and that an index whose every entry is left out
      prints nothing. `grep -n "Three limits remain" site/typst.qmd` prints
      nothing, and neither that `CHANGELOG.md` entry nor `site/books.qmd`
      says that a Typst index prints because it holds a mark.
- [ ] AC5: The active profile's `verify` slot passes:
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T3, T5
- AC2 → T1, T3, T5
- AC3 → T1, T4, T5
- AC4 → T6
- AC5 → T1, T2, T3, T4, T5, T6, T7

## Tasks

- [x] T1: Tests first. Add the AC1-AC3 cases to
      `examples/typst-unprinted.qmd` (`toc: true` among them), re-derive
      `tests/typst-unprinted.tsv` by hand under the suite's oracle rule, add
      the AC3 twin comparison to the M117-AC1 section (`tests/run-tests.sh`
      near line 31428), and replace that section's check that the second
      index prints its heading; its `typstindex.py` call drops the
      `"Spare Index"` stop, which would then raise. Move the fixture's row in M14's dangling-count
      corpus and its extension-warning count to one. Before the first run,
      grep the self-tests for want strings resting on today's output (the
      M117 lesson). Run the section and see the new rows fail.
- [ ] T2: Label cross-reference marks. `assign_labels`
      (`typst.lua` near line 362) gives a Typst cross-reference mark a label;
      `typst_locator` adds no locator for a mark with cross-references; and
      `build_entry_tree` (`entries.lua` near line 163) keeps on each
      cross-reference the labels of every mark that writes it, the duplicate
      branch included.
- [ ] T3: The print rule. For each entry, write once the Typst condition under
      which it prints: one of its own labels names an element, one of its
      cross-references prints, or one of its sub-entries prints. A
      cross-reference prints where a label of a mark writing it names an
      element and its target prints; a target already on the path being
      decided counts as printing, so a cycle prints where its marks do; a
      target no mark files prints as today. `qi-index-entry` (`typst.lua`
      near line 96) gets each cross-reference with its condition and puts the
      kind's word before the first printed target of each kind; the
      letter-group heading in `index_blocks` reads the same conditions.
- [ ] T4: The empty index. `index_blocks` (`typst.lua` near line 295) writes
      the heading and the body of an index under the condition that one of
      its top-level entries prints, so the heading, its outline line and its
      page go together.
- [ ] T5: Plants, each seen red before its fix is trusted: a cross-reference
      mark with no label (the AC1 rows return), a dead target kept (the AC2
      rows return), the path guard removed (the AC2 cycle rows), and the
      heading written unconditionally (the AC3 twin differs).
- [ ] T6: Docs and records. The `site/typst.qmd` section and the
      `CHANGELOG.md` entry per AC4, written from a render, with that entry's
      "holds at least one mark" sentence and `site/books.qmd` near line 250
      brought in line; the comment above
      `TYPST_HELPERS` (`typst.lua` lines 39-50); the M117-AC1 pass line; and
      in `DESIGN.md`, KI321-KI323 struck and the Typst architecture lines
      that name them brought in line.
- [ ] T7: Run `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` once, in
      the background, and read its result.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which work — "Finish leaving out unprinted Typst marks" (KI321-KI323); a cross-reference to a left-out term — drop that target; an index left with no entry — print nothing.
- 2026-10-20: collision check: absorbs the parked candidate row "Finish leaving out unprinted Typst marks" in full (promoted at the user's choice, its author-report condition unmet); extends M117 (done); no D-entry about Typst cross-references or headings; GitHub inbox empty (no open issues or PRs).
- 2026-10-20: lessons harvested: M117 (grep self-test want strings first; `\f` in pdftotext), M116 (dangling-count corpus row, warn counts), M082 (`PATH=/usr/bin:$PATH`), check-design (an untouched shape in the fixture, a plant per clause, hold a twin).
- 2026-10-20: plan gate chose deciding at Typst layout time whether a label names an element over a filter-side list of the fields Quarto's Typst template prints, because the filter cannot see the template (M117's reason); falsified by Quarto exposing the template's printed fields to filters.
- 2026-10-20: plan gate chose counting a cross-reference cycle as printing where its marks print over dropping every cycle, because a body cycle prints today and in the LaTeX index; falsified by a reference index that drops such a pair.
- 2026-10-20: plan gate chose a twin render's text as AC3's oracle over a scan for blank pages, because a page that carries only a page number is not blank to a text scan; falsified by the twin itself printing a heading for an index no mark files in.
- 2026-10-20: criteria audit (full, fresh Opus reader): 10 findings, all disposed toward the narrower promise. Fixed: AC2 scoped to terms with no page-number mark or sub-entry (1) and "first in the order the index prints them" (2); AC3 adds "no line beginning `Spare Index`" (3), "On Quarto 1.10.19" (4), and a cross-reference route into the second index with a twin that drops every mark of it (5); AC1 adds a `see-also=` row (6); AC4 adds the CHANGELOG "holds at least one mark" sentence and `site/books.qmd` (7) and the left-out entry (8); "derived by hand" moved from AC1 to T1 (9, an instrument property); T1 drops the `"Spare Index"` stop (10). Clean: row format, dangling report on Typst, `toc: true` against M117's `Index` line, twin equality, AC5.
- 2026-10-20: plan gate chose one cross-reference route into the emptied second index (AC3) over a route through a sub-entry too, because the sub-entry condition is the one M117's letter-group heading already reads and its fixture holds; falsified by a plant reading only top-level own labels at index level staying green.
- 2026-10-20: T1: fixture gains `toc: true`, four description marks (Winch, Thwart, Boom, Boom!Vang) and nine body marks (Thwart, Jib, Clew twice, Tack, Yawl, Keel, Pin); manifest re-derived by hand, 30 rows; M117-AC1 section drops the `"Spare Index"` stop, checks no line opens `Spare Index`, holds the one warning to Rudder's report, and adds the M118-AC3 twin (derived in `$WORK` by two once-only substitutions, not a second fixture file, so no gallery or corpus row is owed). The pre-fix render fails the manifest from row 2. Minor amendment: the dangling-count corpus row stays 0, because the fixture declares indexes and its report takes the index-naming wording, which that count does not read.
- 2026-10-20: T2-T4, T6 written (checkpoint, suite not yet run): `build_entry_tree` keeps a copy of each cross-reference with `writers`; `lookup_entry` moved from `html.lua` to `entries.lua` so both back-ends read one definition; `passes.lua` tags every Typst cross-reference mark so `assign_labels` labels it (first render showed none were tagged: only xref marks with an author id were); `typst_locator` adds no locator for them. Chose one `qi-index-prints` pass per index, a greatest fixed point that starts every entry printing and drops entries until stable, over per-entry inline conditions, because inline conditions grow with every path through cross-references and the fixed point evaluates each label once; falsified by a document whose index compile time grows past the render's. The index's page break, heading and columns sit in one `#context` block under `qi-p.any`. A writer with no label returns `true`, keeping the cross-reference (IP2). Fixture renders match all 30 manifest rows; the twin's text equals the fixture's; ten plants each red on their row by hand (M117's six rewritten for the new code, four new).
