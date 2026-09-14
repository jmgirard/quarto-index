<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M099: A Typst locator prints the number its page shows

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** user-facing — it changes what the index of a Typst render prints
- **Branch/PR:** m099-typst-locator-numbering

## Goal

A Typst index locator prints the text its page's numbering prints on that page,
and locators that print the same text print once.

## Scope

**In:** the two helpers in `TYPST_HELPERS`, `qi-index-page` and
`qi-index-entry` (`_extensions/index/modules/typst.lua`). A new fixture,
`examples/typst-numbering.qmd`, with raw Typst blocks that set the page
numbering and reset the page counter, and its hand-derived manifests. The two
PDF index readers, `tests/typstindex.py` and `tests/pdfindex.py`, read a
locator or a page footer of several words. The suite and the version matrix
render and read the fixture. The Locators section of `site/typst.qmd`, and
`CHANGELOG.md`. KI292 and KI293 leave DESIGN.md.

**Out:**

- A page numbering set as a Typst function in raw Typst keeps the locator it
  prints today. T7 records this as a DESIGN.md Known issues entry.
- Locators ordered by the number the page prints, as makeindex orders them,
  and a span rule that compares printed numbers. Both go to the candidate row
  this plan adds.
- A Typst book whose chapters reset the page counter. The same helper serves
  it, but no book fixture is added. It goes to the same candidate row.
- A one-page range on a page another range spans, a multi-page range that
  prints the same text as a single mark, and nested or overlapping ranges of
  one entry. They go to the same candidate row (AC2 amendment).

## Acceptance criteria

- [ ] AC1: In a Typst render of `examples/typst-numbering.qmd`, each locator
      prints the text that the numbering pattern of its page prints in that
      page's footer. For a pattern that names two counters, this is the
      pattern filled with the page counter's value on that page and its final
      value in the document. For a pattern that names one counter, it is the
      pattern filled with the value on that page alone. On a page whose
      numbering is none, the locator prints the physical page number. The
      fixture carries a mark under each of these four numberings: a
      two-counter pattern of digits (`1 / 1`), a two-counter pattern of other
      counting symbols (such as `i of I`), a one-counter pattern with text
      around its counter (such as `- 1 -`), and no numbering. Shown by `tests/typstindex.py`, which reads the render against manifests
      derived by hand from the fixture source.
- [ ] AC2: In that render, a single mark that sits on a page a range of the
      entry spans across two or more physical pages, its end pages included,
      prints no locator, as today. Of the locators left, those of one entry
      that print the same text print that text once. The one locator sits at
      the position of the earliest such page, links to that page, and is bold
      where any merged mark is principal. A range whose two ends print the
      same text prints that text alone. Locators whose texts differ print
      separately, in physical page order. A one-page range on a page another
      range spans, a range across two or more pages that prints the same text
      as a single mark, and ranges of one entry that nest or overlap are
      outside this criterion. The fixture carries each of these shapes:
      - two marks that print one text, on either side of a page counter reset
      - a range across the reset whose two ends print one text
      - a principal mark only on the later of two pages that print one text
      - two ranges with the same end texts
      - a one-page range beside a single mark of the same text
      - a mark on a physical page inside a range that the reset collapsed
      - a mark on the closing page of a range that prints the same text as a
        later mark outside every range
      - a mark on the opening page of a range
      - two pages with one counter value that print different text under
        different patterns
      - a range whose closing text is lower than its opening text.
      Shown by the same reading.
- [ ] AC3: `examples/typst-index.qmd` still matches
      `tests/typst-index-main.tsv` and `tests/typst-index-people.tsv`, both
      unchanged from main, shown by the M098 checks in `tests/run-tests.sh`.
      `tests/run-tests.sh --self-test` passes.
- [ ] AC4: The version matrix renders `examples/typst-numbering.qmd` to Typst
      on each leg of its existing Typst step. The Quarto 1.5 floor leg is one
      of these legs. The matrix reads the level and text of each index line, locators
      included, against the AC1 and AC2 manifests. Shown by a green
      dispatched run of `.github/workflows/versions.yml` on the milestone
      branch.
- [ ] AC5: The Locators section of `site/typst.qmd` states the locator text
      rule of AC1 and the merge rule of AC2, and `CHANGELOG.md` carries an
      entry for both.

## Coverage

- AC1 → T1, T2, T3, T5, T6
- AC2 → T1, T2, T4, T5, T6
- AC3 → T3, T4, T6
- AC4 → T1, T6
- AC5 → T7

## Tasks

- [ ] T1: Teach `tests/typstindex.py` (`parse_entry`, `PAGE_NUMBER` at :92)
      and `tests/pdfindex.py` (`LOCATOR_ONLY` at :73) to read a locator of
      several words and to drop a page footer of several words. Plant one
      multi-word locator and one multi-word footer for each reader, and show
      each plant red on the unchanged reader.
- [ ] T2: Write `examples/typst-numbering.qmd` with the AC1 numberings, set by
      raw `#set page(numbering: ...)` blocks, a raw `#counter(page).update(1)`
      reset, and the AC2 shapes. Explicit page breaks fix the page of each
      mark. Derive the manifests by hand. Take the spacing that pdftotext
      reads from one probe render. Show the final counter arithmetic in the
      manifest comment, and count the index's own pages in it.
- [ ] T3: Change `qi-index-page` (typst.lua:39). If the pattern names two
      counting symbols by Typst's own rule, fill it with both counter values.
      If not, fill it with the page value alone. Render the fixture red
      before the change and green after it.
- [ ] T4: Change `qi-index-entry` (typst.lua:43) to drop the single marks on
      pages a range spans on the physical pages, then merge the locators left
      by their printed text. The order stays physical.
- [ ] T5: In a scratch copy, plant one defect for each AC1 and AC2 clause.
      Show each plant red against the manifests. The plants:
      - a fill that always uses two counters
      - a fill that always uses one counter
      - a merge by physical page
      - a one-page range tested by physical page
      - bold taken from the first merged page only
      - a link to the later page
      - the merged locator placed at the later position
      - a span test by printed text
      - the merge run before the span drop
      - a span test that excludes a range's opening page
      - a span test that excludes a range's closing page
      - a span drop that also drops multi-page ranges
      - a merge by counter value
      - a range whose two ends are reordered.
- [ ] T6: Add the fixture render and both readings to `tests/run-tests.sh`
      beside the M098 section (near :28882). Add a render step and a
      `typstindex.py pages` step to `.github/workflows/versions.yml` (near
      :406). Run the suite with `--self-test`, then dispatch the matrix on the
      branch.
- [ ] T7: Update the Locators section of `site/typst.qmd` (:38) and
      `CHANGELOG.md`. Remove KI292 and KI293 from DESIGN.md Known issues, and
      add an entry for a page numbering set as a Typst function.

## Work log

- 2026-09-13: created by /milestone-plan from the candidate row for KI292 and KI293. Its promotion condition (an author using such a numbering) was not met, and the user chose to promote it.
- 2026-09-13: criteria audit, full mode, fresh Opus reader, 11 findings. The draft fixed 10: the matrix reader, no numbering, the pattern list, the raw page numbering, plants, silent shapes, spacing, the AC3 procedure, the known issue. The plan settled one, the merge order.
- 2026-09-13: plan gate chose the full footer text for a two-counter locator over the page number alone, because the reader finds the text the page shows. Falsified by an author reporting that `5 / 30` locators read worse than `5`.
- 2026-09-13: plan gate chose to merge locators by printed text over physical pages, because the PDF index merges by printed number. Falsified by an author reporting a merged locator that hid a page they needed.
- 2026-09-13: plan chose to merge by text before the physical span rule over the reverse order, because a collapsed range still covers its physical pages. Falsified by a report of a dropped mark that no printed locator shows.
- 2026-09-13: plan gate chose the version matrix over the local suite only, because the new fill reads the final counter value on the Typst of Quarto 1.5. Falsified by a floor leg that cannot run a Typst step.
- 2026-09-13: implement started on branch m099-typst-locator-numbering. No implementation question was open, so no gate.
- 2026-09-13: T1-T4 written. Fixture renders to 8 pages. Unchanged readers red on the render (multi-word locator, `5 / 5` footer). Unchanged helpers red on 8 of the manifest's entries.
- 2026-09-13: renamed the fixture term `fig` to `fern`, because the Quarto 1.5.52 Typst reads `fi` as a ligature (tests/typst-index-main.tsv comment). Added `kale` for the placement plant.
- 2026-09-13: T5-T6 written in the suite self-test. Five M098 plants re-aimed at the new code, each shown red in scratch. Suite run 1 red on the gallery list (fixture unlisted). Fixed in site/gallery.yml.
- 2026-09-13: matrix run 34796793073 red on the floor leg. Quarto 1.5.52's Typst template hard-codes numbering `1` and ignores `page-numbering:`. The fixture now sets `1 / 1` in a raw block. Run 34798353832 green on all legs.
- 2026-09-13: suite run 2 red on one M098 plant that pinned 29 claims. It now reads its count from the claims list. Suite run 3 red on the M099 banner title. Fixed.
- 2026-09-13: claim audit: 91 claims read, 2 corrected — typst.lua, site/typst.qmd, CHANGELOG.md, site/tests.qmd, versions.yml, typstindex.py. The merge before the span drop lost a later locator, so the code now drops first (term `lime`, plant `mergefirst`). The matrix wording overstated its page check. The re-read found both true and one comment slip, fixed.
- 2026-09-13: suite run 4 green (1625 checks, with --self-test). Matrix run 34799239921 green on all legs.
- 2026-09-13: implement chose to drop spanned single marks before the merge over the plan's merge-first order, because merge-first drops a later same-text locator with a spanned first one. Falsified by a shape where drop-first prints a locator for a spanned page. This supersedes the plan's merge-order line above.
- re-audit: AC2 (full) — the order sentence, one-page ranges in a span, nested ranges and the lime bullet were unstated or loose. Three plants were missing: end-page inclusion, counter-value merge, reversed ends.
- re-audit: AC2 (full) — "always prints" was false for merged ranges, and two shapes had no witness: a collapsed range merging with a single mark, and a one-page range in a span. Opening-page inclusion and the span exemption were unplanted. Second line, so the wording went to the user.
- 2026-09-13: AC2 amended at the mini gate (user chose to narrow). It now states drop-then-merge and puts three range shapes out of scope, which go to the candidate row. It adds the closing-page and opening-page shapes. T4 reworded, T5 gains five plants, and the fern opening-page mark is added.

## Decisions

## Review
