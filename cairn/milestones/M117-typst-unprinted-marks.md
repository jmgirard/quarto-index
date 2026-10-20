# M117: A Typst index leaves out a term no page carries

- **Status:** review
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

- [ ] AC1: On Quarto 1.10.19, whose Typst template does not print
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
- [x] AC2: In `site/typst.qmd`, the section "A mark Typst never prints", and
      in `CHANGELOG.md`, the Unreleased entry for the Typst back-end, each say
      that an entry whose page-number marks all sit in a field no page prints
      is left out of the Typst index when it has no cross-reference and no
      sub-entry that prints. The `site/typst.qmd` section also names the three
      limits the Out list names. `grep -n "Its term is still in the index"
      site/typst.qmd` prints nothing.
- [x] AC3: The active profile's `verify` slot passes: `tests/run-tests.sh
      --self-test` exits 0.

## Coverage

- AC1 → T1, T2
- AC2 → T4
- AC3 → T1, T2, T3, T5

## Tasks

- [x] T1: In `typst.lua`, pass each entry's own labels, and whether any
      sub-entry at any depth has a label or a cross-reference, from
      `entry_lines` (typst.lua:179) to `qi-index-entry` (typst.lua:87), and
      have it print nothing where no label names an element, the entry has no
      cross-reference, and no sub-entry at any depth would print.
      Make the letter-group heading in `index_blocks` (typst.lua:222) print
      only where an entry of its group prints. Update the comments above
      `TYPST_HELPERS` and `entry_lines` to say so.
- [x] T2: Write `examples/typst-unprinted.qmd` with the shapes AC1 names,
      each parent chain in one column, its hand-derived manifest under
      `tests/`, and a suite section that renders it to Typst, fails naming the
      field if the description's sentence prints before the index, and runs
      `tests/typstindex.py`. Register the fixture in
      `site/gallery.yml` (`not-shown:`) and, as it writes `see=`, in M14's
      dangling-count corpus (the M116 lesson). Plant the pre-T1 entry code and
      show the new check red on it before trusting its green.
- [x] T3: In `tests/run-tests.sh`, `m098_field_rows` (run-tests.sh:31396)
      writes no row and no letter group for a term whose field the render does
      not print, in place of today's row with no locator.
- [x] T4: Rewrite the `site/typst.qmd` section "A mark Typst never prints" and
      add the sentence to the Unreleased Typst entry in `CHANGELOG.md`, each
      written against T2's observed render (the derived-claims rule). In
      `cairn/DESIGN.md`, strike the known issue that records today's behavior
      and add one entry for each of the three limits the Out list names.
- [x] T5: Run `tests/run-tests.sh --self-test` and record the result.

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
- 2026-10-20: suite run 3 failed at M24-AC3 (the plant renders were not captured), fixed in fa45783; run 4 failed at the M099 dropranges self-test, because `qi-index-entry` tested `found` after the span drop, which that plant empties. It now tests whether any label names an element before that drop (`labelled`), as its comment says; checked by hand on that plant (`dune` prints) and on the M117 fixture (green).
- 2026-10-20: suite run 5 failed at the M098 T11 alt-kept self-test: its plant loses the alt-text labels, and since M117 those entries are left out rather than printed with no locator, so its want is now imgterm's missing row (cc612ed).
- 2026-10-20: T5: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` exited 0, "All checks passed (1832 checks)", at cc612ed; M117-AC1 and its four plants green. T1-T5 ticked; status review.
- 2026-10-20: DESIGN.md: KI289 struck; KI321-KI323 added for the three Out limits and named on the candidate row; the Typst architecture paragraph updated.
- 2026-10-20: record note: the six lines from "claim audit" to "T5" above were written after the "DESIGN.md: KI289 struck" line and inserted above it by mistake; their commits (e4c4c07 to 49d6735) give the true order.
- 2026-10-20: amendment routed: AC1 — the criterion names the pinned Quarto (1.10.18), which this machine does not run and CI never runs the suite on; the check passed on 1.10.19 at 635f9cc, and the deliverable is unchanged.
- 2026-10-20: re-audit: AC1 (full) — nothing; the reader found the amended text reachable on 1.10.19, binding the deliverable, with no D-065/D-067 conflict (the check is about the extension's output), and noted KI321-KI323 named the wrong Quarto.
- 2026-10-20: amendment return: AC1 — "On Quarto 1.10.19, whose Typst template does not print `description:`," (was "On the pinned Quarto, ..."); the rest of AC1 is unchanged.
- 2026-10-20: correction: every render this milestone made ran on Quarto 1.10.19, not 1.10.18. That holds for the "render check before planning" line above and for KI321-KI323, which are corrected in place in DESIGN.md.

## Decisions

## Review

Review pass 1, 2026-10-20, branch at 49d6735 (main unmoved at 21391ae; no PR; Copilot round off).

- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: an entry whose range opens in an unprinted field and closes on a printed page was left out, where main printed it with no locator — fix now, fixed 635f9cc (closing labels count; `Rig` shape and `noclose` plant added).
- diff-bug #2: any non-cross-reference mark with no label now leaves its entry out, wider than the docs' front-matter case — reject, false for reachable shapes: the reviewer found only cross-reference marks and absent records without a label, and the Goal covers any mark no page prints.
- diff-bug #3: `labels_below` walked `pairs()`, so the `.typ` label order could vary between renders — fix now, fixed 635f9cc (walks `sorted`; two renders compared byte-identical).
- diff-bug #4: the new Typst helpers are unchecked on the floor Quarto — follow-up, held by the row "Floor-Quarto CI suite job"; the weekly version matrix also renders `examples/typst-index.qmd` there.
- diff-bug #5: heading and entry calls repeat descendant labels, so the `.typ` grows linearly — reject, planned change (T1's label lists); no defect.
- diff-bug #6: the Thole check reads only text after the first `Spare Index` line — reject, false: the heading check before it requires that line.
- diff-bug #7: the changelog sentence sits at the end of the long Typst bullet — reject, style.
- blame-history #1: a body mark whose label is lost (the alt-text plant) now vanishes — reject, false for reachable shapes (as diff-bug #2).
- blame-history #2: a cross-reference to a left-out term draws no report, against D-005's spirit — follow-up, the row "Finish leaving out unprinted Typst marks" (KI322).
- blame-history #3: no D-entry records reversing M098's limit — reject, planned change: a Typst-only choice, recorded in this work log; no cross-cutting rule.
- blame-history #4: an index left with no entry prints its heading — follow-up, the row "Finish leaving out unprinted Typst marks" (KI323).
- blame-history #5: `m098_field_rows`' "both kinds of row" wording is stale — reject, false: it still compares a printed field's row with an unprinted field's absent row.
- blame-history #6: an over-long line in DESIGN.md's Typst paragraph — reject, style.
- prior-review #1: the retired docs sentence had no phrase-absent guard (M110 precedent) — fix now, fixed 635f9cc.
- prior-review #2: the new changelog and docs sentences were unpinned (M073 F1) — fix now, fixed 635f9cc (claims rows added).
- prior-review #3: the M098 alt-kept plant no longer shows a label-lost row kept — reject, planned change: that row no longer exists, and the plant is still red when M098's move is undone.
- prior-review #4: an entry whose only page a span drops prints bare — reject, false: the span drop removes a single mark inside a range of the same entry, and the range stays.
- ripple #1: `site/typst.qmd` says an index no mark files in prints nothing, beside the new heading limit — fix now, fixed 635f9cc (the limit sentence names the difference).
- ripple #2: "one group per letter" is unqualified — reject, false: it holds for every letter with a printed entry, and the same page states the exception.
- ripple #3: `site/letter-groups.qmd`'s group list — reject, false: that page is about HTML.
- ripple #4: the changelog does not name the three limits — reject, false: AC2 asks the site page alone to name them.

Evidence, pass 1, at 635f9cc (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, exit 0, "All checks passed (1833 checks)", Quarto 1.10.19):

- AC1: not met as written. The M117-AC1 check passed (23 manifest lines; five plants red on their rows), but the run was on Quarto 1.10.19, and the criterion names the pinned Quarto, which `tests/pagescheck.py version .github/workflows/pages.yml` reads as 1.10.18. No 1.10.18 install is here and CI runs no suite. Routed as an amendment return.
- AC2: `site/typst.qmd` "A mark Typst never prints" and the Unreleased Typst bullet of `CHANGELOG.md` each state the left-out rule with both conditions; the page names the three Out limits; `grep -n "Its term is still in the index" site/typst.qmd` printed nothing (exit 1). The suite's claims rows (M098-AC7 page and changelog) and the retired-phrase sweep passed in the same run.
- AC3: `tests/run-tests.sh --self-test` exited 0 at 635f9cc, 1833 checks.
