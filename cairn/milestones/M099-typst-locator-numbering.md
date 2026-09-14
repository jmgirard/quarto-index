<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M099: A Typst locator prints the number its page shows

- **Status:** review
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

- [x] AC1: In a Typst render of `examples/typst-numbering.qmd`, each locator
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
- [x] AC2: In that render, a single mark that sits on a page a range of the
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
- [x] AC3: `examples/typst-index.qmd` still matches
      `tests/typst-index-main.tsv` and `tests/typst-index-people.tsv`, both
      unchanged from main, shown by the M098 checks in `tests/run-tests.sh`.
      `tests/run-tests.sh --self-test` passes.
- [x] AC4: The version matrix renders `examples/typst-numbering.qmd` to Typst
      on each leg of its existing Typst step. The Quarto 1.5 floor leg is one
      of these legs. The matrix reads the level and text of each index line, locators
      included, against the AC1 and AC2 manifests. Shown by a green
      dispatched run of `.github/workflows/versions.yml` on the milestone
      branch.
- [x] AC5: The Locators section of `site/typst.qmd` states the locator text
      rule of AC1 and the merge rule of AC2, and `CHANGELOG.md` carries an
      entry for both.

## Coverage

- AC1 → T1, T2, T3, T5, T6
- AC2 → T1, T2, T4, T5, T6
- AC3 → T3, T4, T6
- AC4 → T1, T6
- AC5 → T7

## Tasks

- [x] T1: Teach `tests/typstindex.py` (`parse_entry`, `PAGE_NUMBER` at :92)
      and `tests/pdfindex.py` (`LOCATOR_ONLY` at :73) to read a locator of
      several words and to drop a page footer of several words. Plant one
      multi-word locator and one multi-word footer for each reader, and show
      each plant red on the unchanged reader.
- [x] T2: Write `examples/typst-numbering.qmd` with the AC1 numberings, set by
      raw `#set page(numbering: ...)` blocks, a raw `#counter(page).update(1)`
      reset, and the AC2 shapes. Explicit page breaks fix the page of each
      mark. Derive the manifests by hand. Take the spacing that pdftotext
      reads from one probe render. Show the final counter arithmetic in the
      manifest comment, and count the index's own pages in it.
- [x] T3: Change `qi-index-page` (typst.lua:39). If the pattern names two
      counting symbols by Typst's own rule, fill it with both counter values.
      If not, fill it with the page value alone. Render the fixture red
      before the change and green after it.
- [x] T4: Change `qi-index-entry` (typst.lua:43) to drop the single marks on
      pages a range spans on the physical pages, then merge the locators left
      by their printed text. The order stays physical.
- [x] T5: In a scratch copy, plant one defect for each AC1 and AC2 clause.
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
- [x] T6: Add the fixture render and both readings to `tests/run-tests.sh`
      beside the M098 section (near :28882). Add a render step and a
      `typstindex.py pages` step to `.github/workflows/versions.yml` (near
      :406). Run the suite with `--self-test`, then dispatch the matrix on the
      branch.
- [x] T7: Update the Locators section of `site/typst.qmd` (:38) and
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
- 2026-09-13: criteria reflowed to the 150-line plan-body cap, words unchanged. Suite run 5 green (1630 checks, with --self-test), all 13 M099 plants red as planned. Matrix run 34800224758 green on all legs at 586a6e7. T1-T7 ticked, status review.

## Decisions

## Review

Evidence run 2026-09-14 at 55e8144: `tests/run-tests.sh --self-test`, all checks passed (1630).

- AC1: the suite's M099-AC1/AC2 section rendered `examples/typst-numbering.qmd` with no warning and `tests/typstindex.py` matched all 24 lines of `tests/typst-numbering.tsv`, faces and links included. The section's needle check found the `1 / 1`, `i of I`, `- 1 -` and none numberings in the source. The plants `alwaysboth` and `neverboth` were red on their rows.
- AC2: the same reading matched the rows the section holds for each AC2 shape (apple, birch, cedar, dune, elm, fern, holly, kale, lime). The 12 AC2 plants were each red on the row the clause decides: physicalmerge, physicalrange, firstbold, laterlink, laterplace, textspan, mergefirst, spanopen, spanclose, dropranges, countermerge, reorder.
- AC3: the M098 checks matched 26 lines of `tests/typst-index-main.tsv` and 52 of `tests/typst-index-people.tsv`. `git diff main..HEAD` on both manifests is empty. The run above was `--self-test` and passed.
- AC4: dispatched run 34800224758 of `versions.yml` at 586a6e7 concluded success. Its steps "Render examples/typst-numbering.qmd to Typst" and "Read the Typst page-numbering index against its manifest" succeeded on the floor (1.5.52), pinned (1.10.18) and release legs. `git diff 586a6e7 HEAD` outside `cairn/` is empty.
- AC5: the suite's docs check (M52 reader over the M098-AC7 list) found all 34 claims in `site/typst.qmd`, including the five M099 rows for the two-counter text, no numbering, the same-text merge, its link and bold, and a range whose ends print one text. `CHANGELOG.md:13-16` carries the entry for both rules.

Consistency gate: `cairn_validate.py` all checks passed. The generic profile names no toolchain checks. No principle changed, so no impact report.

Independent review, three lenses. Blame-history: no findings. Prior-review: the M098 review's F3 and F9 are the items this milestone fixes, no regression, and no PR comment threads exist. Diff-bug (Opus), ranked, dispositions pending the gate:

- R1 `typst.lua:50-55`: a page numbering set as a Typst function fails the render with "missing argument: total", because the helper passes only the page value. Confirmed by a probe. The line predates M099.
- R2 `DESIGN.md` KI297: says the locator and footer "can differ", where the common result is a failed render.
- R3 `tests/typstindex.py:282-297`: the reader strips a comma after the last locator at the end of a line, where main kept it and failed, so a stray trailing separator reads as correct.
- R4 `site/typst.qmd:40-43`: "the page number as the page shows it" is false where a page counter update sits mid-page after a mark (locator `1 / 7`, footer `6 / 7`). Predates M099.
- R5 `tests/run-tests.sh` M099 header: dated 2026-09-14, the UTC date of a run the work log dates 2026-09-13.
- R6 `tests/pdfindex.py:113-117`: drops the lowest line matching the footer pattern anywhere, where `typstindex.py` tests only the bottom line.
- R7 `tests/typstindex.py:272-297`: a numbering pattern containing a comma splits one locator in two.
- R8 `tests/pdfindex.py` `_fold_continuations`: a wrapped Typst locator line such as `2 / 5` would not fold.
- R9 `typst.lua:22-23` says "character" where the code counts clusters, and DESIGN.md's Typst paragraph does not state drop-before-merge.
- R10 `typst.lua:47-52`: repeated `numbering` calls per locator and a quadratic merge scan, unmeasured.

Triage at the gate (user chose the recommended triage):

- R1 fix now. Tracing it showed two causes: the helper filled a function with one value, and Typst itself fails a link to a location on a page whose numbering is a two-argument function. The helper now fills a function with both values and links to the mark's position. Suite check "M099 review R1" renders such a document and reads `1 of 2`, and two plants (`onevalue`, `locationlink`) are red on "missing argument: total".
- R2 fix now: KI297 retired, since R1's fix removes the limitation it recorded.
- R3 fix now: the reader keeps a comma at the end of a line, as main did. Checked by "M099 review R3".
- R4 follow-up: KI298 in DESIGN.md Known issues (mid-page counter update).
- R5 fix now: date corrected to 2026-09-13. R9 fix now: the comment says grapheme cluster, and DESIGN.md's Typst paragraph states drop-before-merge and position links.
- R6 reject: pre-existing `pdfindex.py` footer behavior, and the only non-default pattern (`^\d+ / \d+$`) cannot match an entry line.
- R7 reject: no fixture or caller uses a numbering pattern with a comma. R8 reject: no Typst index line wraps, which the reader's docstring assumes. R10 reject: unmeasured, and Typst caches counter lookups.

Re-verified after the fixes at b96768c: `tests/run-tests.sh --self-test`, all checks passed (1635), the AC1-AC3 and AC5 checks above among them. Matrix run 34863316506 at 8cecd7f concluded success, with both typst-numbering steps green on the floor, pinned and release legs (AC4). `git diff 8cecd7f HEAD` touches only `tests/run-tests.sh`, which the matrix does not run.
