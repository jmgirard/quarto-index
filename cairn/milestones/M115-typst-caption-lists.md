# M115: Typst caption marks and a list of figures

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the page a Typst index prints for a caption mark
- **Branch/PR:** —

## Goal

In a document rendered to Typst, a mark in the caption of a figure, a table or a code listing files the page its caption prints on, also where a list of those floats copies the caption.

## Scope

**In:** `typst.assign_labels` (`_extensions/index/modules/typst.lua:269`) moves
each label it writes inside a float's caption, and a caption mark's author id,
into the float's own content, so a Typst `outline` copy of the caption carries
neither. A new fixture `examples/typst-caption-lists.qmd`, its hand-derived
manifest `tests/typst-caption-lists.tsv`, a suite section in
`tests/run-tests.sh`, and the fixture's step in `.github/workflows/versions.yml`.
Docs: `site/typst.qmd`, `CHANGELOG.md`, and `cairn/DESIGN.md`'s Typst
architecture paragraph and KI290.

**Out:** making `lof:` or `lot:` print a list in Typst: that is Quarto's own
option, and Quarto 1.10.19 prints no list for it (observed 2026-10-19), so the
docs show the raw `outline` call instead. Subfigure captions, callout titles and
custom float kinds stay unprobed: T5 narrows KI290 to them. A float an author
makes breakable, whose content and caption can print on different pages: T3
probes it and writes a Known issues entry if its caption mark names another
page.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh` renders `examples/typst-caption-lists.qmd` to Typst, and its index files each caption mark at its caption's page, as printed text and as link target, as the hand-derived manifest `tests/typst-caption-lists.tsv` states and `tests/typstindex.py` reads. The fixture's first page holds only a list of figures, a list of tables and a list of listings, each a raw Typst `outline` call with its own title, and ends in an explicit page break; the same three lists follow its last caption. One case to a page, it marks a term in the caption of an image figure with no id, an image figure with an id, a figure div, a table with an id, a table div and a code listing. One of those caption marks is principal and prints bold, one opens a range that closes in the text of a later page and prints from its caption's page to that page, and one carries an id of the author's.
- [ ] AC2: On the pinned Quarto, in that render, the list of each kind (`quarto-float-fig`, `quarto-float-tbl`, `quarto-float-lst`), read from the PDF's text by the suite, holds the caption text of each of the fixture's floats of that kind, once before the captions and once after.
- [ ] AC3: The fixture's caption mark that carries an author's id sits beside a raw Typst `#link` to that id: the Typst render exits 0, and the link's destination, read from the PDF's link annotation, is that caption's page.
- [ ] AC4: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` pass, so the Typst indexes of `examples/figure-marks.qmd` and the suite's other Typst fixtures, which print no list of floats, still match their manifests.
- [ ] AC5: A dispatched run of `.github/workflows/versions.yml` on the milestone branch renders `examples/typst-caption-lists.qmd` to Typst and reads its index against `tests/typst-caption-lists.tsv` with `tests/typstindex.py pages`, green on the floor leg (Quarto 1.5.52) and the pinned leg.
- [ ] AC6: `site/typst.qmd` says that a mark in the caption of an image figure, a figure div, a table or a code listing files the page its caption prints on when the float does not break across pages, also where a list of those floats copies the caption, and it shows the raw Typst `outline` call the fixture uses for its list of figures; a sentence in `CHANGELOG.md`'s Unreleased Output section names the same behavior.

## Coverage

- AC1 → T1, T2, T6
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T6
- AC5 → T4
- AC6 → T5

## Tasks

- [ ] T1: Write `examples/typst-caption-lists.qmd` and `tests/typst-caption-lists.tsv` by hand from its page breaks, and the suite section: the index through `tests/typstindex.py`, each list's text per kind, and the author-id link's destination page. No term, caption or list title holds `fi`, `fl`, `ff` or `!!`, which the floor's Typst sets as one glyph and `typstindex.py pages` does not fold; the fixture header says so. See AC1 red on today's `typst.lua` at the first list's page, and AC3 red on Typst's duplicate-label error, each failure named.
- [ ] T2: In `typst.assign_labels`, move each label written in a float's caption, and a caption mark's author id, into the float's content. The filter sees a Pandoc `Figure` for an image figure with no id and Quarto's float scaffold for the other five cases (observed 2026-10-19); probe which handler reaches each on the pinned Quarto. The alt-text move at `typst.lua:297` stays. AC1 to AC3 green.
- [ ] T3: Probe a float made breakable (`#show figure: set block(breakable: true)`) whose content crosses a page. If its caption mark names a page other than its caption's, write a `cairn/DESIGN.md` Known issues entry under the Typst back-end.
- [ ] T4: Add the fixture to `versions.yml`'s PDF job and to its WHAT IT CHECKS comment, dispatch a run on the branch, and log each leg's result.
- [ ] T5: Docs: `site/typst.qmd` (the caption sentence and the `outline` call, held to the fixture's own call by the suite), the `CHANGELOG.md` sentence, `site/tests.qmd`'s count of Typst fixtures, `cairn/DESIGN.md`'s Typst paragraph, and KI290 narrowed to the unprobed captions.
- [ ] T6: Run `tests/run-tests.sh` and `--self-test`. Revert T2's move and see AC1 red at a named manifest row before restoring it.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: milestone — a change to the Typst back-end's output that needs an approach decision and more than one sitting.
- 2026-10-19: collision check: absorbed the candidate row "Typst caption marks and a list of figures" (KI290). No decision entry rejects it; D-060's Typst 0.11 floor has `outline(target:)` and labels in a figure body; D-065 puts AC2, a reading of Quarto's float kinds, on the pinned Quarto. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-19: lessons harvested: check-design M55 (vary the axis, so lists sit both before and after the captions) and the M30 ligature lesson (no `fi` in what the floor reads).
- 2026-10-19: scratch probe on Quarto 1.10.19: with raw `outline` calls before the floats, three caption marks on pages 3, 4, 5 printed page 1; an author id on a caption span plus a list and a `#link` fails the compile, marked or not.
- 2026-10-19: question set: captions covered — figures, tables and code listings; author id on a caption mark — move it with the label; CI — may edit `versions.yml` and dispatch a run on the branch; docs — show the raw `outline` call.
- 2026-10-19: criteria audit (full mode, fresh Opus reader): 14 findings, each fixed by narrowing. AC1 made the render its subject, named the author-id case, put the leading lists on their own page, and placed the principal mark and the range. AC2 named the three kinds, gave each list a title, kept its captions ligature-free (T1), and moved to the pinned Quarto. AC3 dropped its log grep, which exit 0 implies. AC4 said "list of floats". AC5 kept its floor clause, its evidence to be read per case at T4. AC6 named the shapes and the no-break condition and the Unreleased Output section.
- 2026-10-19: plan gate chose moving the caption label into the float's content over choosing among the label's copies in Typst, because Typst 0.11 cannot tell an outline copy from the caption and taking the first or last copy fails by where the list sits; falsified by a test, portable from Typst 0.11, of whether an element lies inside an outline.
- 2026-10-19: plan gate chose the float's content over a label block after the float, because an invisible element after a block can land on the next page; falsified by a float that breaks across pages by default in Quarto's Typst output.
- 2026-10-19: changelog: one sentence in the Unreleased Output section, since the Typst back-end has not been released.

## Decisions

## Review
