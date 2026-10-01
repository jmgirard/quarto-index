<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M104: A caption mark beside a shortcode files one locator

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes the locators and the reports every back-end gives an author
- **Branch/PR:** m104-shortcode-caption-marks

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

- [x] AC1: `examples/figure-marks.qmd` carries a new case on page 7. It is a
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
- [x] AC2: In the HTML and EPUB renders of the fixture, every index link names
      an id that the linked page carries, shown by the M101-AC2 link checks.
      The image of the new figure carries no `alt` attribute in HTML and an
      empty one in EPUB. Images 1 to 5 keep the `alt` values M101 states for
      them.
- [x] AC3: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.
- [x] AC4: A dispatched run of `.github/workflows/versions.yml` on the
      milestone branch is green on the floor leg (Quarto 1.5.52) and on the
      pinned leg. On both legs, the fixture's HTML index agrees with the
      pinned leg's by the workflow's cross-version comparison, and the PDF and
      Typst renders match `tests/figure-marks-pdf.txt` and
      `tests/figure-marks-typst.tsv`.
- [x] AC5: `site/syntax.qmd` no longer carries the exception sentences of its
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

- [x] T1: Add the case after the hazel case of `examples/figure-marks.qmd`.
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
- [x] T2: In `declass_caption_copies`, replace the `image.caption ~=
      caption.content` test (`marks.lua:647`). Compare the two lists after a
      walk at every depth drops `__quarto_custom_id` from each span that
      carries `__quarto_custom`. Update the function's comment. Add a
      self-test plant that restores the old test, beside the M101 plants
      near `tests/run-tests.sh:31095`. The plant must show the log check red
      on the second opening of `larch`'s range in each of the four formats.
      Make sure that the no-declass plant's cedar count still holds. Show the
      T1 checks green.
- [x] T3: Dispatch `.github/workflows/versions.yml` on the branch. Record each
      leg's result in the work log. A red result on the release leg alone
      becomes a Known issue (D-025), not a failed criterion.
- [x] T4: Edit `site/syntax.qmd`, `CHANGELOG.md` and `cairn/DESIGN.md` as AC5
      states.

## Work log

- 2026-10-01: created by /milestone-plan. Promotes the KI299 candidate row (M101 review F1, F2), which the plan commit removes.
- 2026-10-01: criteria audit (full mode, fresh Opus reader) returned 12 findings, all with one clear fix, applied before the gate: printed-index claim per format, reader and `alt`-checker wording dropped, a nested shortcode and a walk at every depth, DESIGN wording on equal nodes, a self-test plant, AC4 leg wording and the release leg, the 1.5.52 floor risk, five count sentences, the candidate row.
- 2026-10-01: plan gate chose to drop `__quarto_custom_id` before comparing over comparing plain text (it counts any alt text with the same words as a copy) and over reading Quarto's custom-node store (an internal table that can move between versions); falsified by a Quarto version whose caption and copy differ in more than that id, or by an author-written alt text that differs from its figure's caption only in which shortcode it holds.
- 2026-10-01: implement started on branch m104-shortcode-caption-marks; question gate skipped, nothing left open by the plan.
- 2026-10-01: checkpoint, T1 and T2 written and unticked: the suite with --self-test is running and has not yet passed. On the unchanged extension (Quarto 1.10.18, scratch render) the new case is red on the log check in all four formats, the HTML and EPUB manifests (two links each for juniper and larch) and the HTML and EPUB link checks (qi-mark-9, qi-mark-10 dangling); the PDF and Typst manifests are green, since both merge the copy's same-page locator.
- 2026-10-01: T1, T2 done. `tests/run-tests.sh --self-test` passed, 1732 checks. The custom-id plant is red on the log check in all four formats, with one report of the second opening of larch's range in each. The no-declass plant's cedar count still holds. A native dump on Quarto 1.10.18 showed the caption and copy differ only in `__quarto_custom_id` and each shortcode span is empty, so the code comment states that two shortcodes of one type compare equal and why that is safe.
- 2026-10-01: T3 started. The branch is pushed and `versions.yml` is dispatched as run 36878545802, which is not finished.
- 2026-10-01: checkpoint, T4 written and unticked. The suite with --self-test is running again over the T4 edits.
- 2026-10-01: T3 done. Dispatched run 36878545802 on 5595c5e is green in all eight jobs. On the floor leg (1.5.52) and the release leg, the figure-marks HTML index matches the pinned leg's byte for byte, 17 rows. The PDF jobs on the floor, pinned and release legs read the 8 lines of `tests/figure-marks-pdf.txt` and the 16 lines of `tests/figure-marks-typst.tsv`.
- 2026-10-01: T4 done. The exception sentences in `site/syntax.qmd`, the CHANGELOG's still-files-twice sentence and KI299 are removed. The DESIGN Architecture paragraph states the custom-id drop and why it is safe. `tests/run-tests.sh --self-test` passed again, 1732 checks, and `cairn_validate` passed.
- claim audit: 30 claims read, 0 corrected — _extensions/index/modules/marks.lua, tests/run-tests.sh, tests/figure-marks-pdf.txt, tests/figure-marks-typst.tsv, examples/figure-marks.qmd, site/syntax.qmd, CHANGELOG.md, .github/workflows/versions.yml
- 2026-10-01: status set to review.

## Review

Evidence from `tests/run-tests.sh --self-test` run at f42d094, 2026-10-01: 1732 checks, 0 FAIL, exit 0.

- AC1 evidence: the fixture carries the new case (needle check green, seven page breaks). The HTML index matches its 16 manifest rows, with juniper and larch one link each. The EPUB index matches the same 16 rows. The PDF index is the 8 lines of `tests/figure-marks-pdf.txt` (`juniper, 7` and `larch, 7–8`). The Typst index matches the 16 lines of `tests/figure-marks-typst.tsv` (`7@7`, `7–8@7`). The log check is green in all four renders, and `tests/.work/figure-marks-{html,epub,pdf,typst}.log` carry 0 extension reports. HTML and EPUB print a link, not a page number. The fixture defines a page by its source: each page break starts the next page. A scratch render at f42d094 puts juniper's one link and larch's one link after the sixth break and before the seventh, so on page 7. Every other term's link lands on the page its source gives it.
- AC2 evidence: the HTML link check passes, every id unique and all 8 index links resolving. The EPUB link check passes, all 8 of 8 links resolving. The `alts` check passes on 6 images in HTML and in EPUB. Image 6 is `<none>` in HTML and `<empty>` in EPUB. The branch diff only appends to the two alt lists, so images 1 to 5 keep the M101 values.
- AC3 evidence: `tests/run-tests.sh --self-test` at f42d094 passed, 1732 checks. That run includes the plain suite and the self-test plants, the new custom-id plant red in all four formats among them.
- AC4 evidence: dispatched run 36878545802 (`workflow_dispatch`, branch m104-shortcode-caption-marks, head 5595c5e) concluded success in all eight jobs. The compare job shows figure-marks from the floor leg (1.5.52) matching the pinned leg byte for byte, 17 rows. The floor and pinned PDF jobs read the 8 lines of `tests/figure-marks-pdf.txt` and the 16 lines of `tests/figure-marks-typst.tsv`. After 5595c5e the branch changes only `CHANGELOG.md`, `site/syntax.qmd` and `cairn/` files, and `versions.yml` reads none of them.
- AC5 evidence: `site/syntax.qmd` carries no "One exception", "already open" or "files twice", and its figure paragraph ends at "as written.". The Unreleased section of `CHANGELOG.md` has no "still files" or "twice". The `cairn/DESIGN.md` Architecture paragraph (line 218 on) states the `__quarto_custom_id` drop, that two such nodes of one type compare equal, and why that is safe. `grep -c KI299 cairn/DESIGN.md` gives 0.

Consistency gate: `cairn_validate` passes. No principle changed, so `cairn_impact` is skipped. The generic profile names no toolchain checks.

Review fan-out: three fresh reviewers (Opus diff-bug, Sonnet blame-history, Sonnet prior-review). None found a correctness defect or a regression. Findings, merged across lenses, most severe first, with the disposition proposed at the gate:

- F1 (diff-bug 1): the new CHANGELOG sentence "This holds when the caption also holds a shortcode." follows a sentence about the old defect, so "This" can read as the defect. Proposed: fix now, naming the fix.
- F2 (diff-bug 2): the custom-id plant asserts larch's report once but not cedar's at 0, so a plant that also undid cedar's declass would still pass. Proposed: fix now, asserting cedar's wording at 0.
- F3 (diff-bug 4): the comment in `marks.lua` and the DESIGN paragraph say a custom span "is empty". A nested shortcode's span and slot-bearing custom nodes hold child spans. The walk still compares those children with ids dropped, so behavior is right and only the reason overreaches. Proposed: fix now, wording.
- F4 (prior-review 2): `marks.lua` and DESIGN still say the copy "equals" the caption, which is no longer literal. Proposed: fix now, wording.
- F5 (diff-bug 6): the Typst manifest's "Each term is one case" and the suite's "one case a page" are further off now. Proposed: fix now, wording.
- F6 (all three lenses): one comment line in `tests/run-tests.sh` near line 30767 runs past the block's wrap width. Proposed: fix now.
- F7 (blame-history 1, prior-review 3): no test shows the looser comparison still refusing an alt text that really differs. Proposed: reject. Markdown cannot give a figure's image alt text that differs from its caption (`fig-alt` is an attribute), and shortcode arguments live in Quarto's store, not in spans (diff-bug lens, checked against Quarto 1.10.18).
- F8 (blame-history 2): a shortcode that expands to text holding a mark files in neither caption nor copy as a mark. Proposed: reject, since it predates M104. Shortcodes resolve after the filter runs, as the T2 probe filter saw them unresolved.
- F9 (blame-history 3): no HTML book case holds a shortcode caption. Proposed: reject, because the plan put it Out. The recovery parse yields no custom spans, and the record route makes the same call.
- F10 (diff-bug 3, blame-history 5): the new HTML and EPUB rows have no plant of their own. Proposed: reject. The M101 html-move plant already shows the link check red, the manifest check is generic, and T2 asked for a log-check plant.
- F11 (diff-bug 5): AC1's "page 7" cannot be a printed page number in HTML and EPUB. Proposed: no change needed. The AC1 evidence reads it by the fixture's own page definition and shows it holds.
