<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M100: A Typst index orders locators by the number the page prints

- **Status:** in-progress
- **Priority:** low
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** user-facing — it changes the order and the locators a Typst index prints
- **Branch/PR:** m100-typst-locator-order

## Goal

A Typst index orders an entry's locators, and decides which pages a range
spans, by the number each page prints, as makeindex does for the PDF index.

## Scope

**In:** `qi-index-entry` in `TYPST_HELPERS` (`_extensions/index/modules/typst.lua:63`).
A new fixture, `examples/typst-order.qmd`, and a new Typst book fixture,
`examples/book-typst-reset/`, each with a hand-derived manifest. The rows of
`tests/typst-numbering.tsv` and the M099 suite pins and plants that the new
rules change. The suite reads both new fixtures, and the version matrix reads
`examples/typst-order.qmd`. The Locators section of `site/typst.qmd`, the
Typst paragraph of `cairn/DESIGN.md`, and `CHANGELOG.md`. Item 4 of
`site/back-end-differences.qmd` and its claim row in `tests/run-tests.sh`.

**Out:**

- KI298 (a counter update later on the mark's page) stays a Known issue.
- Folding consecutive pages into a range, as M098 declined.
- The book fixture on the version matrix: floor-leg Typst books are unprobed.
- A pattern with no counting symbol (`"Page"` holds `a`, printing `Pcge`).
- makeindex's reading of a letter page such as `c` as a roman numeral.

## Acceptance criteria

- [ ] AC1: In a Typst render of `examples/typst-order.qmd`, each locator's
      opening page has a class and a value. On a page whose numbering is none,
      the class is arabic and the value is the physical page number. Under a
      pattern, the first counting symbol of the pattern, by the rule
      `qi-index-counters` uses, sets the class: `i` lower roman, `I` upper
      roman, `1` arabic, `a` lower letters, `A` upper letters, then other. Any
      other symbol and a numbering function give the class other. The value is
      the first value of the page counter at the mark. An entry's locators
      print in class order, as just listed, then by value, then by opening
      physical page, then by closing physical page, a single mark before a
      range. Shown by `tests/typstindex.py pages` on `examples/typst-order.qmd`
      against a manifest derived by hand from its source.
- [ ] AC2: In Typst renders of `examples/typst-order.qmd` and
      `examples/typst-numbering.qmd`, a range whose two ends have one class and
      whose closing value is greater than its opening value spans the values
      from its opening value to its closing value, both included. Where a
      single mark's class and value, as AC1 defines them, are that class and a
      spanned value, the mark prints no locator, and no bold where it is
      principal. A range whose two ends print the same text is a single mark
      under this rule, with its opening page's class and value. Any other range
      spans nothing. A range that spans values never removes another such
      range. Of the locators left, those of one entry that print the same text
      print it once, at the place of the first of them in the AC1 order, linked
      to the earliest opening physical page among them, and bold where any of
      them is principal. Shown by the AC1 reading, and by
      `examples/typst-numbering.qmd` against `tests/typst-numbering.tsv`, whose
      changed rows are rederived by hand.
- [ ] AC3: A Typst render of `examples/book-typst-reset/` prints its index as
      its hand-derived manifest states, under the rules of AC1 and AC2. The
      book has a chapter under lower roman numbering, a chapter that resets the
      counter to 1 under arabic numbering, and a chapter that resets it to 1
      again. A range crosses from the second chapter to the third with a
      closing value greater than its opening value. An arabic mark in the
      second or third chapter, on a page outside the range, has a value inside
      it. Shown by `tests/typstindex.py pages` in `tests/run-tests.sh`.
- [ ] AC4: `examples/typst-index.qmd` still matches
      `tests/typst-index-main.tsv` and `tests/typst-index-people.tsv`, and
      `examples/book/` still matches the M098 book manifests, all unchanged
      from main, shown by the M098 checks in `tests/run-tests.sh`.
      `tests/run-tests.sh --self-test` passes.
- [ ] AC5: The version matrix reads the Typst renders of
      `examples/typst-order.qmd` and `examples/typst-numbering.qmd` against
      their manifests on each leg of its Typst step, the Quarto 1.5 floor leg
      included. Shown by a green dispatched run of
      `.github/workflows/versions.yml` on the milestone branch.
- [ ] AC6: The Locators section of `site/typst.qmd` and the Typst paragraph of
      `cairn/DESIGN.md` state the order rule of AC1 and the span and merge
      rules of AC2, and neither states page order or a span by physical page.
      `CHANGELOG.md` carries an entry for both rules.

## Coverage

- AC1 → T1, T2, T4, T7
- AC2 → T1, T3, T4, T5, T7
- AC3 → T6, T7
- AC4 → T7
- AC5 → T7
- AC6 → T8

## Tasks

- [ ] T1: Write `examples/typst-order.qmd` with raw `#set page(numbering: ...)`
      and `#counter(page).update(...)` blocks and explicit page breaks, and
      derive its manifest by hand, each page's class and value in its comment.
      Keep each entry to two or three locators, so no index line wraps. Shapes,
      each pinned by a suite needle and row check: each adjacent class pair,
      marked in physical order opposite to the class order. A function-numbered
      page and a none page. A mark after a reset with a lower value than a mark
      before it. Two pages of one class and value that print different text. A
      single mark and a range opening on one page. A spanned value on a page
      outside the range, and an unspanned value on a page inside it. Marks on a
      range's opening and closing values, one principal. A one-text range
      inside another range, and beside a single mark. Ranges whose value
      intervals nest, and ranges that overlap. A range whose ends differ in
      class, one whose closing value is lower, and one whose ends have one
      value and print different text. One text on two pages whose AC1 order and
      physical order disagree, with a locator of another text between them.
      End the fixture on a numbering whose index footer the reader drops.
      Show the unchanged helper red.
- [ ] T2: In `qi-index-entry` (typst.lua:63), compute each locator's class and
      value, and sort once per key field, least significant first, with Typst's
      stable `sorted`, so no array comparison or packed key is needed.
- [ ] T3: Replace the span filter (typst.lua:81-82) with the AC2 value rule,
      keep drop-then-merge, and link a merged locator to its earliest opening
      physical page (typst.lua:84-96).
- [ ] T4: In the suite self-test, plant one defect per AC1 and AC2 clause and
      show each red on its row. Order plants: physical order, each adjacent
      class pair swapped, function or none page in the wrong class, value
      ignored, reversed physical tiebreak, range before single mark. Span
      plants: span by physical page, span without its opening value, span
      without its closing value, spanned principal kept bold, one-text range
      kept in a span, reversed range spanning, mixed-class range spanning, a
      range removing a range, equal end values spanning. Merge plants: link to
      the first in order, placement at the earliest physical page, bold from
      the first merged mark only.
- [ ] T5: Rederive by hand the `tests/typst-numbering.tsv` rows the rules change
      (`birch`, `fern`, `holly`, `lime`), their M099 row pins (run-tests.sh:29136)
      and the M099 plants the rules now make correct (`textspan`, :29258-29345).
- [ ] T6: Write `examples/book-typst-reset/` (`_quarto.yml` with an author, and
      the `_extensions` link), its manifest with its page arithmetic, and a
      suite section beside the M098 book section (`tests/run-tests.sh:29496`).
      List both fixtures where the gallery check requires it.
- [ ] T7: Add `examples/typst-order.qmd`, with its index page's `--footer` pattern, to
      the Typst step of `.github/workflows/versions.yml` (near :427). Run
      `tests/run-tests.sh --self-test`, then dispatch the matrix on the branch.
- [ ] T8: Update `site/typst.qmd` (:38), `cairn/DESIGN.md` (:437), `CHANGELOG.md`,
      and item 4 of `site/back-end-differences.qmd` (:35).

## Work log

- 2026-09-14: created by /milestone-plan from the Typst locator-order candidate row. Its promotion condition (an author report) was not met, and the user chose to promote it.
- 2026-09-14: criteria audit, full mode, fresh Opus reader, 16 findings. Fixed in the draft: tiebreak, value at the mark, pattern with no symbol, class-pair probes, reversed tiebreak plant, merge link shape, one-text range class, spanned principal, book range shape, line wrap, shape pins moved to tasks, integer key, DESIGN.md under AC6. Book container question settled by a probe render. One went to the gate: the M099 fixture rows.
- 2026-09-14: re-audit, full mode, same reader, 8 findings, all fixed: criteria scoped to their fixtures, other last in class order, AC2 value as AC1 defines it, equal-end range and placement shapes and plants, the AC3 mark's chapter, the index footer, sort per field. A pattern with no counting symbol moved to Out after a probe printed `Pcge` for `"Page"`.
- 2026-09-14: plan gate chose to span by printed value over M099's physical pages, because the order and the merge by text already follow printed numbers. Falsified by an author reporting a page under another numbering lost inside a range.
- 2026-09-14: plan gate chose makeindex's class order (lower roman, upper roman, arabic, lower letters, upper letters, other) over the physical order of classes, because the PDF index orders so. Falsified by an author reporting a back-matter class listed before the main text.
- 2026-09-14: plan gate chose a new fixture over extending `examples/typst-numbering.qmd`, because more pages change its final counter value and every row. Falsified by the two fixtures needing one shape each can hold only together.
- 2026-09-14: plan gate chose to include the book fixture over leaving it a candidate, because a probe book set numbering and reset the counter in raw Typst per chapter and printed `yam, 1–2, 1`.
- 2026-09-14: /milestone-implement started on branch m100-typst-locator-order.
- 2026-09-14: question gate amended Scope In to add item 4 of `site/back-end-differences.qmd` and its claim row, because its "in page order" claim becomes false. T8 extended to match.
- 2026-09-14: T1 wrote `examples/typst-order.qmd` (37 marked pages, 20 entries) and `tests/typst-order.tsv` by hand. The unchanged helper rendered it red on 14 of 20 rows (scratch render). Deviation: the lime principal mark sits on the range's closing value, so the spanned-bold plant tests bold handed to the range. Quince's ranges are sequential in the source, since one term holds one open range, and nest or overlap by value after counter resets. Added thyme for the merge-first plant.

## Decisions

## Review
