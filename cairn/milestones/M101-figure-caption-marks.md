<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M101: A mark in a figure caption or an image's alt text files one locator

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes the locators and the reports every back-end gives an author
- **Branch/PR:** `m101-figure-caption-marks`

## Goal

In every back-end, a mark in a figure caption or alt text files one locator,
and its link target exists on the page.

## Scope

**In:** Pandoc copies the caption of a figure with no id into its image's alt
text, and the filter reads a caption mark twice (KI294). A mark in an image's
alt text gets an HTML and EPUB link to an id that no element carries. LaTeX
writes no `\index` for it. Observed on Quarto 1.10.18, 2026-09-14. The copy
detection in `passes.lua` and in the book recovery reader in `book.lua`. The
move of an alt-text anchor in `html.lua` and of an alt-text `\index` in
`latex.lua`. A new fixture, `examples/figure-marks.qmd`, with hand-derived
manifests, and two HTML book cases. The fixture on the version matrix, which
closes KI295. `site/syntax.qmd`, `CHANGELOG.md` and `cairn/DESIGN.md`.

**Out:**

- KI290 (a list of figures that copies a caption) stays a Known issue.
- The EPUB and PDF renders of the fixture on the version matrix. The suite
  reads them on the pinned Quarto only.
- A figure caption mark in a LaTeX or Typst book. Only the HTML book has a
  recovery route that reads chapter source.

## Acceptance criteria

- [ ] AC1: This criterion covers HTML, EPUB, PDF and Typst renders of
      `examples/figure-marks.qmd`. A caption mark on a figure with no id files
      one locator. A caption mark on a figure with an id also files one. The
      fixture opens a range in a no-id caption and closes it later in the
      text, on a later page in PDF and Typst. Each index prints that range as
      its back-end prints a range: one link in HTML and EPUB, a page span in
      PDF and Typst. Each render's index matches a manifest derived by hand
      from the fixture's source. `tests/htmlindex.py`, `tests/epubindex.py`,
      `tests/pdfindex.py` and `tests/typstindex.py` read the four indexes in
      `tests/run-tests.sh`. The log of each of the four renders carries no
      report from the extension, shown by a log check in `tests/run-tests.sh`.
- [ ] AC2: A mark in an image's alt text files one locator at the image. This
      holds for every image except one that is the only content of a figure
      whose caption equals the image's alt text. In the HTML and EPUB renders
      of `examples/figure-marks.qmd`, each such locator links to an id. The
      element with that id comes after the image in document order, in the
      same block. In the PDF and Typst renders, the index prints the image's
      page. Shown by the AC1 readers and manifests. A check in
      `tests/run-tests.sh` also shows two facts for the HTML and EPUB renders
      of the fixture. Every index link names an id that the linked page
      carries. The `alt` attribute of each image equals the text the check
      states for it, derived by hand from the fixture's source.
- [ ] AC3: In an HTML book, a mark in a figure caption files one locator for
      its chapter on both routes: where the chapter's stored record is read,
      and where the chapter's terms are recovered from its source. The book
      cases open a range in a caption of a figure with no id. They open a
      second range in a caption of a figure with an id. Each range closes
      later in the chapter. The index matches a manifest derived by hand, and
      the render log carries no report on these marks. Shown by one case per
      route in `tests/run-tests.sh`.
- [ ] AC4: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.
- [ ] AC5: On each leg of `.github/workflows/versions.yml`, the Quarto 1.5
      floor leg included, the Typst render of `examples/figure-marks.qmd`
      matches its manifest. On each leg, the HTML index of the fixture agrees
      with the pinned leg's by the workflow's cross-version comparison. Shown
      by a green dispatched run of that workflow on the milestone branch.
- [ ] AC6: `site/syntax.qmd` states that a mark in a figure caption files one
      locator, and that a mark in an image's alt text files its locator at the
      image. `CHANGELOG.md` carries an entry for each. The Architecture section
      of `cairn/DESIGN.md` states both rules, and its Known issues no longer
      carry KI294 or KI295.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T1, T3, T5
- AC3 → T2, T4, T5
- AC4 → T1, T4, T5
- AC5 → T6
- AC6 → T7

## Tasks

- [x] T1: Write `examples/figure-marks.qmd`, with a page break after each case.
      Its cases:
      - a figure with no id and a caption mark
      - a figure with an id and a caption mark
      - a `range="open"` in a no-id caption, closed on a later page
      - an inline image whose alt text has a plain and a principal mark
      - a `::: {#fig-...}` div figure whose image has its own alt mark

      Use markdown image syntax (M03 lesson). No term holds `fi`, which the
      Typst floor sets as one glyph (M30 lesson). Derive the four manifests by
      hand, each with its derivation comment. Add the four readers, the log
      check, the link check and the `alt` check to `tests/run-tests.sh`.
      Record in the work log which checks are red on main.
- [x] T2: Change `TagPandoc` (`_extensions/index/modules/passes.lua:98`) for
      every format. Take the index class off each span in a copied alt text:
      the alt text of an image that is a figure's only content and equals the
      figure's caption. Follow `declass_copy` (`passes.lua:89`). Apply the
      same helper to the blocks the recovery reader walks
      (`_extensions/index/modules/book.lua:842`).
- [x] T3: Move a mark's link target out of image alt text to just after the
      image, as `assign_labels` does for Typst (`typst.lua:297`). HTML and EPUB
      get an empty span carrying the id, in `assign_anchors` (`html.lua:622`).
      LaTeX gets the `\index` command, in `latex.lua`.
- [ ] T4: Add the two HTML book cases to `tests/run-tests.sh`, one on the
      record route and one on the recovery route. Follow the M069 recovery
      cases.
- [ ] T5: Plant each fix. Revert T2 and show the AC1 range check red in each
      of the four formats, and the AC3 range check red on each route. Revert
      the HTML half of T3 and show the link check red. Revert the LaTeX half
      and show the PDF manifest red. Run `tests/run-tests.sh --self-test`.
- [ ] T6: Add the fixture to `.github/workflows/versions.yml`. The pdf job's
      Typst steps read it against a tracked manifest,
      `tests/figure-marks-typst.tsv`. The render job renders and extracts its
      HTML index. The fixture set that `tests/versioncheck.py fixtures` checks
      takes it. Dispatch the workflow on the branch.
- [ ] T7: Write the `site/syntax.qmd` paragraph and the two `CHANGELOG.md`
      entries. State both rules in the `cairn/DESIGN.md` Architecture section,
      the Typst label-move paragraph included. Remove KI294 and KI295.

## Work log

- 2026-09-14: created by /milestone-plan.
- 2026-09-14: criteria audit (full mode, fresh [O] reader) returned 9 findings, all applied before the gate. Findings: range and report wording, link-target rule, `alt` reader, copy detection, merging plants, recovery case, test-file diff clause, HTML matrix step, goal.
- 2026-09-14: plan chose to take the index class off the alt-text copy over removing the copy, because removal changes the `alt` text every back-end writes; falsified by an output where the declassed copy still prints index markup.
- 2026-09-14: plan gate chose to move an alt-text target after the image in HTML, EPUB and LaTeX over recording the defect for later, because KI294 shares the element and fixture; falsified by an image wrapper that puts the moved target in another block.
- 2026-09-14: plan gate chose the HTML cross-version comparison for the matrix over a new HTML manifest step, because the render job already compares each leg to the pinned leg; falsified by a floor leg that agrees with a wrong pinned leg.
- 2026-09-14: implement started on `m101-figure-caption-marks`; question gate skipped, nothing left open.
- 2026-09-14: T1 done. The figure div's image carries a trailing backslash: alone in its paragraph, Pandoc makes it a nested figure, whose LaTeX fails to compile and whose alt text is a caption copy. The alt checks live in `tests/figuremarks.py`. Red on main: the log check in all four formats; the HTML and EPUB manifests (alder and cedar file 2); the HTML and EPUB link checks; all six `after` checks; the PDF manifest (no dogwood, elder or hazel line). Green on main: the `alt` checks, the two locator roles, both Typst readings.
- 2026-09-14: T2 done. `declass_caption_copies` lives in `marks.lua`, the one module both `passes.lua` and `book.lua` load. It compares the image's alt inlines with the caption's inlines by Lua equality. The M101 section's log checks and the HTML and EPUB manifests went green. The full suite runs after T3, whose checks the M101 section still shows red.
- 2026-09-14: T3 done. `assign_anchors` moves each mark id out of an image's alt text to an empty span after the image. `move_alt_commands` in `latex.lua` moves the `\index` and registration commands the same way, called from the LaTeX path of `index.lua`. Every check in the M101 section is green on a driver run of that section alone.

## Decisions

## Review
