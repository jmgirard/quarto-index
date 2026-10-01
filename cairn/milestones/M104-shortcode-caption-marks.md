<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M104: A caption mark beside a shortcode files one locator

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes the locators and the reports every back-end gives an author
- **Branch/PR:** —

## Goal

If the caption of a figure with no id also holds a Quarto shortcode, a mark
in that caption files one locator in every back-end.

## Scope

**In:** `marks.declass_caption_copies` (`_extensions/index/modules/marks.lua:621`)
declasses an image's alt text only where it equals the figure's caption.
Quarto gives an inline shortcode in the caption and in the copy different
`__quarto_custom_id` values. So the two lists differ, and the copy keeps its
marks (KI299). On Quarto 1.10.18, 2026-10-01, the two lists differed in that
attribute alone. The plan-gate audit read the Quarto 1.5.52 source: it writes
the same four `__quarto_custom` attributes, with the id from a counter. Nobody
rendered the probe on 1.5.52. If the floor leg's HTML comparison goes red on
the new case, the plan reopens. The milestone changes the comparison, adds one
case to `examples/figure-marks.qmd` and its four manifests, edits the docs,
and removes KI299.

**Out:**

- An HTML book case. The recovery route already files such a mark once,
  because its parse reads the shortcode as text (KI299). M101-AC3 covers
  caption marks on both book routes. The plan gate declined a new case.
- KI290 stays a Known issue.

## Acceptance criteria

- [ ] AC1: `examples/figure-marks.qmd` carries a new case on page 7. It is a
      figure with no id whose caption holds the inline shortcode
      `{{< meta title >}}` twice, once inside emphasis. The caption also holds
      a plain mark of `juniper` and a `range="open"` mark of `larch`. The text
      of page 8 closes the range of `larch`. In the printed index of the HTML,
      EPUB, PDF and Typst renders of the fixture, `juniper` has one locator,
      page 7. The range of `larch` prints as one link in HTML and EPUB, and as
      the span 7–8 in PDF and Typst. Each printed index matches its manifest
      in `tests/run-tests.sh`, `tests/figure-marks-pdf.txt` or
      `tests/figure-marks-typst.tsv`. The log of each of the four renders
      carries no report from the extension, shown by the log check in
      `tests/run-tests.sh`.
- [ ] AC2: In the HTML and EPUB renders of the fixture, every index link names
      an id that the linked page carries, shown by the M101-AC2 link checks.
      The image of the new figure carries no `alt` attribute in HTML and an
      empty one in EPUB. Images 1 to 5 keep the `alt` values M101 states for
      them.
- [ ] AC3: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.
- [ ] AC4: A dispatched run of `.github/workflows/versions.yml` on the
      milestone branch is green on the floor leg (Quarto 1.5.52) and on the
      pinned leg. On both legs, the fixture's HTML index agrees with the
      pinned leg's by the workflow's cross-version comparison, and the PDF and
      Typst renders match `tests/figure-marks-pdf.txt` and
      `tests/figure-marks-typst.tsv`.
- [ ] AC5: `site/syntax.qmd` no longer carries the exception sentences of its
      figure paragraph, today lines 37-40, from "One exception:" to "already
      open.". The Unreleased entry in `CHANGELOG.md` no longer says that such
      a caption still files twice. The `cairn/DESIGN.md` Architecture
      paragraph on `declass_caption_copies` states that the comparison drops
      the id Quarto gives each inline custom node, so two such nodes of one
      type compare equal, and why that is safe. Its Known issues no longer
      carry KI299.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4

## Tasks

- [ ] T1: Add the case after the hazel case of `examples/figure-marks.qmd`.
      The hazel case gains a page break, and the fixture then carries seven.
      No new term holds `fi` (M30 lesson). Derive every manifest row by hand
      from the source, with its derivation comment (check-design M06). Update
      each place that states a count or a list the case changes:
      - the needle list and the break count in the M101 section of
        `tests/run-tests.sh` (the "five" wording near line 30772)
      - the per-term derivation comment near line 30738
      - the HTML and EPUB rows, and the two `alt` lists with a sixth image
      - "the same six" near line 30874 and "the six lines" in
        `.github/workflows/versions.yml` near line 271
      - `tests/figure-marks-pdf.txt`, and `tests/figure-marks-typst.tsv` with
        its derivation comment
      - the fixture's own prose (lines 20-31)

      Images 4 and 5 keep their numbers, so the `after` loops in the suite
      and the matrix stay as they are. Record in the work log, per format,
      which check is red on main: LaTeX can merge two locators on one page,
      so the PDF manifest can stay green there.
- [ ] T2: In `declass_caption_copies`, replace the `image.caption ~=
      caption.content` test (`marks.lua:647`). Compare the two lists after a
      walk at every depth drops `__quarto_custom_id` from each span that
      carries `__quarto_custom`. Update the function's comment. Add a
      self-test plant that restores the old test, beside the M101 plants
      near `tests/run-tests.sh:31095`. The plant must show the log check red
      on the second opening of `larch`'s range in each of the four formats.
      Make sure that the no-declass plant's cedar count still holds. Show the
      T1 checks green.
- [ ] T3: Dispatch `.github/workflows/versions.yml` on the branch. Record each
      leg's result in the work log. A red result on the release leg alone
      becomes a Known issue (D-025), not a failed criterion.
- [ ] T4: Edit `site/syntax.qmd`, `CHANGELOG.md` and `cairn/DESIGN.md` as AC5
      states.

## Work log

- 2026-10-01: created by /milestone-plan. Promotes the KI299 candidate row (M101 review F1, F2), which the plan commit removes.
- 2026-10-01: criteria audit (full mode, fresh Opus reader) returned 12 findings, all with one clear fix, applied before the gate: printed-index claim per format, reader and `alt`-checker wording dropped, a nested shortcode and a walk at every depth, DESIGN wording on equal nodes, a self-test plant, AC4 leg wording and the release leg, the 1.5.52 floor risk, five count sentences, the candidate row.
- 2026-10-01: plan gate chose to drop `__quarto_custom_id` before comparing over comparing plain text (it counts any alt text with the same words as a copy) and over reading Quarto's custom-node store (an internal table that can move between versions); falsified by a Quarto version whose caption and copy differ in more than that id, or by an author-written alt text that differs from its figure's caption only in which shortcode it holds.
