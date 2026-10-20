# M117: A Typst index leaves out a term no page carries

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes what a Typst index prints
- **Branch/PR:** m117-typst-unprinted-marks

## Goal

A Typst index prints no entry whose page-number marks all sit where no page
prints them, such as a front-matter field Quarto's Typst template leaves out,
when it has no cross-reference and no sub-entry that prints.

## Scope

**In:** In `_extensions/index/modules/typst.lua`, an entry prints nothing when
no label of its locators names an element, it has no cross-reference, and no
sub-entry of it prints; a letter group none of whose entries prints has no
heading. The labels are still looked up while Typst lays out the pages, and a
missing one still fails nothing (IP2). A new Typst fixture and suite check,
the M098-AC7 front-matter manifest brought in line, the `site/typst.qmd`
section "A mark Typst never prints", the Unreleased Typst entry in
`CHANGELOG.md`, and the `DESIGN.md` known issue that records today's behavior.

**Out:**
- A warning that names such a mark: declined at the question set, because the
  filter cannot see which fields a template prints. Not planned.
- Three limits go to the parked candidate row "Finish leaving out unprinted
  Typst marks": a cross-reference mark (`see=`, `see-also=`) in such a field
  carries no label, so its cross-reference still prints; a cross-reference
  whose target term is left out still prints, with no dangling-target report;
  and an index whose every entry is left out still prints its heading.
- The LaTeX, HTML and EPUB back-ends: unchanged.

## Acceptance criteria

- [ ] AC1: On the pinned Quarto, whose Typst template does not print
      `description:`, a Typst render of a new fixture,
      `examples/typst-unprinted.qmd`, whose `description:` holds marks, is held
      by `tests/typstindex.py` to a manifest derived by hand from the fixture
      source, and the suite passes that comparison. In that manifest: a term
      marked only in `description:` has no row; a term marked in
      `description:` and in the body has one row carrying the body mark's page
      alone; a sub-entry marked only in `description:`, under a parent marked
      in the body, has no row, and the parent keeps its row; a parent marked
      only in `description:` keeps its row with no locator, above its
      sub-entry, where that sub-entry is marked in the body, where that
      sub-entry's only printing sub-entry is marked in the body (two levels
      down), and where that sub-entry has only a `see=` target; a letter group
      whose every term is marked only in `description:` has no heading row;
      and a term marked in the body with a `see=` target the index prints, and
      no locator, keeps its row.
- [ ] AC2: In `site/typst.qmd`, the section "A mark Typst never prints", and
      in `CHANGELOG.md`, the Unreleased entry for the Typst back-end, each say
      that an entry whose page-number marks all sit in a field no page prints
      is left out of the Typst index when it has no cross-reference and no
      sub-entry that prints. The `site/typst.qmd` section also names the three
      limits the Out list names. `grep -n "Its term is still in the index"
      site/typst.qmd` prints nothing.
- [ ] AC3: The active profile's `verify` slot passes: `tests/run-tests.sh
      --self-test` exits 0.

## Coverage

- AC1 → T1, T2
- AC2 → T4
- AC3 → T1, T2, T3, T5

## Tasks

- [ ] T1: In `typst.lua`, pass each entry's own labels, and whether any
      sub-entry at any depth has a label or a cross-reference, from
      `entry_lines` (typst.lua:179) to `qi-index-entry` (typst.lua:87), and
      have it print nothing where no label names an element, the entry has no
      cross-reference, and no sub-entry at any depth would print.
      Make the letter-group heading in `index_blocks` (typst.lua:222) print
      only where an entry of its group prints. Update the comments above
      `TYPST_HELPERS` and `entry_lines` to say so.
- [ ] T2: Write `examples/typst-unprinted.qmd` with the shapes AC1 names,
      each parent chain in one column, its hand-derived manifest under
      `tests/`, and a suite section that renders it to Typst, fails naming the
      field if the description's sentence prints before the index, and runs
      `tests/typstindex.py`. Register the fixture in
      `site/gallery.yml` (`not-shown:`) and, as it writes `see=`, in M14's
      dangling-count corpus (the M116 lesson). Plant the pre-T1 entry code and
      show the new check red on it before trusting its green.
- [ ] T3: In `tests/run-tests.sh`, `m098_field_rows` (run-tests.sh:31396)
      writes no row and no letter group for a term whose field the render does
      not print, in place of today's row with no locator.
- [ ] T4: Rewrite the `site/typst.qmd` section "A mark Typst never prints" and
      add the sentence to the Unreleased Typst entry in `CHANGELOG.md`, each
      written against T2's observed render (the derived-claims rule). In
      `cairn/DESIGN.md`, strike the known issue that records today's behavior
      and add one entry for each of the three limits the Out list names.
- [ ] T5: Run `tests/run-tests.sh --self-test` and record the result.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which work — the Typst front-matter mark (KI289), over two wrong-fact reports (KI296, KI105) and an index named like the output file (KI106).
- 2026-10-20: plan gate chose leaving the term out with no warning over a warning built on a list of the fields Quarto's Typst template prints, because that list drifts by Quarto release and custom template (as D-048 found for HTML); falsified by an author reporting a term lost from a Typst index with nothing telling them why.
- 2026-10-20: plan gate chose leaving the term out over filing such a mark at page 1, because the reader would follow a page number to a page that does not show the term; falsified by an author asking for the title page as the locator of an unprinted field's mark.
- 2026-10-20: collision check: no candidate row, planned milestone, or D-entry covers KI289; M098 shipped the limit and recorded it; D-048 (HTML book chapters) declines a printed-field list for the same reason and is not changed. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons harvested: M116 (fixture registration in gallery.yml and the dangling-count corpus), M30 (compare extracted PDF text in NFC from a hand-derived table).
- 2026-10-20: render check before planning: on Quarto 1.10.18, examples/front-matter.qmd's Typst index printed `Halyard` with no page, and its LaTeX output wrote no `\index{Halyard}`.
- 2026-10-20: criteria audit (full mode, fresh Opus reader) returned 6 findings, all fixed: Goal and AC2 narrowed to entries with no cross-reference and no printing sub-entry; AC2's grep narrowed to the old sentence; AC1 gained a two-level chain and a see-only sub-entry, and its see= row names a printed target; the left-out-target cross-reference joined Out; the description-prints guard moved from AC1 to T2; AC2 requires the docs to name the three Out limits. AC3 passed.
- 2026-10-20: implement started on branch m117-typst-unprinted-marks, cut from main at 21391ae.
- 2026-10-20: T1-T4 written, suite not yet run: `labels_below` passes sub-entry labels (or `true` for a cross-reference) to `qi-index-entry`, which prints nothing without a found label; letter headings print under `qi-index-live`. Chose a Lua-side label list over a Typst-side tree walk, since the tree is known before typesetting.
- 2026-10-20: added to the fixture the three Out limits (`Oar`, `Block, see Sheave`, `Spare Index`), each observed in a scratch render first, so each claim the docs page now makes has a check (What gets a test); the M117-AC1 check also counts zero extension warnings.
- 2026-10-20: four plants rendered by hand before writing their want strings (all-entries, all-groups, one-depth, no-xref), each red on its own row; the one-depth plant first broke the one-level case too, so `labels_below` was restructured to keep depth in its recursion alone.
- 2026-10-20: claim audit: 46 claims read, 4 corrected — tests/run-tests.sh (the Thole check read the fixture's own prose, so it searches only after the `Spare Index` line; "eight marks" became eleven; the allentries plant's want is its first mismatch, Horn), _extensions/index/modules/typst.lua (a comment called a label a mark).
- 2026-10-20: the heading check also missed `Spare Index` because pdftotext opens each later page with a form feed; it now turns form feeds into newlines. Checked on the clean scratch render (green) and on a planted render that prints Thole (red, naming Thole).
- 2026-10-20: the first suite run stopped at the PyYAML check: `/usr/local/bin/python3` (3.14.6, installed 2026-10-01) has no PyYAML, and `/usr/bin/python3` (3.9.6) does. The suite runs with `PATH=/usr/bin:$PATH`; nothing was installed. A second run was stopped for the audit fix above before any M117 check.
- 2026-10-20: DESIGN.md: KI289 struck; KI321-KI323 added for the three Out limits and named on the candidate row; the Typst architecture paragraph updated.

## Decisions

## Review
