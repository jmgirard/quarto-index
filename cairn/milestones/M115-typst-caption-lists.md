# M115: Typst caption marks and a list of figures

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the page a Typst index prints for a caption mark
- **Branch/PR:** m115-typst-caption-lists

## Goal

In a document rendered to Typst, a mark in the caption of a figure, a table or a code listing files the page its caption prints on, also where a list of those floats copies the caption.

## Scope

**In:** a filter stage after `typst.assign_labels`
(`_extensions/index/modules/typst.lua:269`) moves each label that pass writes
inside a float's caption, and a caption mark's author id, into the float's own
content, so a Typst `outline` copy of the caption carries
neither, for a float whose content is one paragraph, table or code block. A
new fixture `examples/typst-caption-lists.qmd`, its hand-derived
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
page. A float whose content is anything else, several blocks (Quarto's layout
cells among them) or one other block (a code cell's output among them), keeps
its caption labels, because changing that content changed Quarto's layout three
times (review returns 2 to 4): KI290 and the candidate row "Laid-out float
caption marks".

## Acceptance criteria

- [x] AC1: `tests/run-tests.sh` renders `examples/typst-caption-lists.qmd` to Typst, and its index files each caption mark at its caption's page, as printed text and as link target, as the hand-derived manifest `tests/typst-caption-lists.tsv` states and `tests/typstindex.py` reads. The fixture's first page holds only a list of figures, a list of tables and a list of listings, each a raw Typst `outline` call with its own title, and ends in an explicit page break; the same three lists follow its last caption. One case to a page, it marks a term in the caption of an image figure with no id, an image figure with an id, a figure div, a table with an id, a table div and a code listing. One of those caption marks is principal and prints bold, one opens a range that closes in the text of a later page and prints from its caption's page to that page, and one carries an id of the author's.
- [x] AC2: On the pinned Quarto, in a Typst render of `examples/typst-caption-lists.qmd`, read from the PDF's text by `tests/typstlists.py`, the list of `quarto-float-fig` floats holds the three picture captions, the list of `quarto-float-tbl` floats the two table captions, and the list of `quarto-float-lst` floats the code listing's caption, both where the list comes before the first caption and where it comes after the last.
- [x] AC3: The fixture's caption mark that carries an author's id sits beside a raw Typst `#link` to that id: the Typst render exits 0, and the link's destination, read from the PDF's link annotation, is that caption's page.
- [x] AC4: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` pass, so the Typst indexes of `examples/figure-marks.qmd` and the suite's other Typst fixtures, which print no list of floats, still match their manifests.
- [x] AC5: A dispatched run of `.github/workflows/versions.yml` on the milestone branch renders `examples/typst-caption-lists.qmd` to Typst and reads its index against `tests/typst-caption-lists.tsv` with `tests/typstindex.py pages`, green on the floor leg (Quarto 1.5.52) and the pinned leg.
- [x] AC6: `site/typst.qmd` says that a mark in the caption of an image figure, a figure div, a table or a code listing files the page its caption prints on when the float does not break across pages, also where a list of those floats copies the caption, and it shows the raw Typst `outline` call the fixture uses for its list of figures; a sentence in `CHANGELOG.md`'s Unreleased Output section names the same behavior.

## Coverage

- AC1 → T1, T2, T6, T7
- AC2 → T1, T2, T4
- AC3 → T1, T2, T7
- AC4 → T6, T7, T8, T9, T10
- AC5 → T4, T7
- AC6 → T5, T7, T9, T10

## Tasks

- [x] T1: Write `examples/typst-caption-lists.qmd` and `tests/typst-caption-lists.tsv` by hand from its page breaks, and the suite section: the index through `tests/typstindex.py`, each list's text per kind, and the author-id link's destination page. No term, caption or list title holds `fi`, `fl`, `ff` or `!!`, which the floor's Typst sets as one glyph and `typstindex.py pages` does not fold; the fixture header says so. See AC1 red on today's `typst.lua` at the first list's page, and AC3 red on Typst's duplicate-label error, each failure named.
- [x] T2: In a filter stage after `typst.assign_labels`, move each label written in a float's caption, and a caption mark's author id, into the float's content. The filter sees a Pandoc `Figure` for an image figure with no id and Quarto's float scaffold for the other five cases (observed 2026-10-19); probe which handler reaches each on the pinned Quarto. The alt-text move at `typst.lua:297` stays. AC1 to AC3 green.
- [x] T3: Probe a float made breakable (`#show figure: set block(breakable: true)`) whose content crosses a page. If its caption mark names a page other than its caption's, write a `cairn/DESIGN.md` Known issues entry under the Typst back-end.
- [x] T4: Add the fixture to `versions.yml`'s PDF job and to its WHAT IT CHECKS comment, with a pinned-leg step running `tests/typstlists.py` for AC2, dispatch a run on the branch, and log each leg's result.
- [x] T5: Docs: `site/typst.qmd` (the caption sentence and the `outline` call, held to the fixture's own call by the suite), the `CHANGELOG.md` sentence, `site/tests.qmd`'s count of Typst fixtures, `cairn/DESIGN.md`'s Typst paragraph, and KI290 narrowed to the unprobed captions.
- [x] T6: Run `tests/run-tests.sh` and `--self-test`. Revert T2's move and see AC1 red at a named manifest row before restoring it.
- [x] T7: Review return 1 (work log): a moved author id gets an invisible element of its own, so it takes no other mark's label and adds no blank line; fixture cases with two marks in one caption and an author id on a float with an id, red on the current code first; the Review section's other fix-now items; then the suite, a dispatched matrix run, and the review hand-back.
- [x] T8: Review return 2 (work log): a laid-out float keeps its cells, the labels joining a paragraph cell or staying in the caption, with a fixture red on the current code first; the Review section's pass-2 fix-now items, the plants committed to the self-test; then the suite, a dispatched matrix run, and the review hand-back.
- [x] T9: The narrowing chosen at the thrash stop (work log): `float_labels` leaves a float whose content is several blocks untouched, with a laid-out image case whose two images must print at one size, red on the current code first; the pass-3 fix-now items (docs and KI290 exceptions, comments, the CHANGELOG wording, the layout fixture's wording, plants per clause for `tests/typstlists.py`); the candidate row "Laid-out float caption marks"; then the suite, a dispatched matrix run, and the review hand-back.
- [x] T10: The second narrowing (work log): `float_labels` wraps only a table or a code block and leaves any other single block alone, with a code-cell-output figure that must stay centered, red on the current code first; the pass-4 fix-now items (scoped docs, KI290 and KI318, the author-id limit, the images check held to 72 ppi, a `pdfimages` presence check, comment reflows); then the suite, a dispatched matrix run, and the review hand-back.

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
- 2026-10-19: status in-progress; branch m115-typst-caption-lists cut from main at f2e5794.
- 2026-10-19: T1 done: fixture (11 pages: lists on 1 and 10, cases 2-9, index 11), manifest and suite section. On the base `typst.lua` (Quarto 1.10.19) the render stopped on Typst's error "label `<alder-mark>` occurs multiple times" (AC3 red), and with the link removed every caption mark printed page 1 while larch, in the text, printed 9 (AC1 red).
- 2026-10-19: T2: `doc:walk` does not reach a Quarto float by name, but a filter stage's `FloatRefTarget` function does, so the move is a new last stage in `index.lua` (`typst.figure_labels`, `typst.float_labels`); Quarto writes only the first block of a figure with no id, so its moved inlines join that block. AC1 (both readings), AC2 and AC3 checks green on 1.10.19 run by hand; `figure-marks.qmd`'s Typst index unchanged.
- 2026-10-19: substantive amendment: Scope In and T2 name a filter stage after `typst.assign_labels` instead of `assign_labels` itself; the deliverable is unchanged, so no stop.
- 2026-10-19: T3 done: with `#show figure: set block(breakable: true)` a long table captioned on page 1 printed `4` and a picture on 5 captioned on 6 printed `5`; without that rule Quarto 1.10.19 kept both whole and both printed the caption's page. Written as KI318.
- 2026-10-19: T4: the fixture's render and `typstindex.py pages` reading joined the PDF job of `versions.yml`; dispatched run 39329028850 on the branch at 439181e.
- 2026-10-19: T5 done: `site/typst.qmd` gained "Lists of figures, tables and listings" with the fixture's own list-of-figures call, which the suite now greps there (M115_LOF, one variable for both sites); the fixture's lists were retitled `List of Figures` and so on, `(end)` for the back ones. CHANGELOG sentence in the Unreleased Typst bullet; `site/tests.qmd` counts five Typst fixtures; DESIGN.md's Typst paragraph names the new stage; KI290 narrowed to subfigures, callout titles and custom float kinds. The simple-english hook reports 207 pre-existing hits in CHANGELOG.md; only this milestone's sentences were rewritten to its limits.
- 2026-10-19: second dispatched `versions.yml` run 39329284098 at 92026d4: green on the floor (1.5.52), pinned (1.10.18) and release legs, the caption-lists render and reading steps included. The run reads the index alone, so it cannot show which floor list copies which caption.
- 2026-10-19: T6 revert probe, in a scratch copy with the new filter stage removed: the render stopped on "label `<alder-mark>` occurs multiple times" (AC3), and without the link the index was red at row 1, alder `1@1` against `2@2`, every caption mark on page 1 (AC1).
- 2026-10-19: T6 suite run 1 (Quarto 1.10.19) stopped at M41-AC1: `site/gallery.yml` did not list the new fixture; added under `not-shown:`.
- 2026-10-19: T6 suite run 2 stopped at M106: the suite holds `site/tests.qmd` to "It renders four fixtures to Typst:", which T5 made five; the held sentence now says five.
- 2026-10-19: claim audit: 55 claims read, 3 corrected — examples/typst-caption-lists.qmd, tests/typst-caption-lists.tsv, tests/run-tests.sh (page 1 also holds the title), _extensions/index/modules/typst.lua (the no-id figure's labels now join its first block, and stay in the caption where that block holds no inlines, rather than going to a block Quarto drops), CHANGELOG.md (the no-break condition)
- 2026-10-19: T6 suite run 3 at 5a93f1e (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1793, with 10 skip lines, M115-AC2 among them, since 1.10.19 is not the pinned 1.10.18. No CI job runs the suite, so nothing ran AC2 on the pin.
- 2026-10-19: substantive amendment: AC2 names its reader `tests/typstlists.py` (new, with the hand-derived manifest `tests/typst-caption-lists-lists.tsv`) in place of "the suite", and the captions each list holds in place of "each float of that kind"; the suite calls that reader, and a pinned-leg step of `versions.yml`'s PDF job runs it, guarded to run whenever the render succeeded. Coverage AC2 gains T4. What the user gets is unchanged, so no stop.
- 2026-10-19: re-audit: AC2 (full) — the amended wording was near tautological ("each float of that kind" holds by construction of an `outline` target), could read as a count, and the suite still read inline; fixed by naming the partition and the two positions and moving the suite onto `tests/typstlists.py`.
- 2026-10-19: re-audit: AC2 (full) — sound; flags "holds the three picture captions" as readable as "only those", where the reader checks presence (left as written, presence being the promise), the evidence being the dispatched pinned leg, and an unguarded step (guarded).
- 2026-10-19: the claim audit found AC1's "first page holds only" the three lists false, the title printing there too; the fixture drops its `title:` so the criterion holds as written, and the three comments say no title prints. Index, `pages` reading, lists and the page-9 link re-read green on 1.10.19.
- 2026-10-19: dispatched `versions.yml` run 39334750678 at 1e28f44: every job green; the caption-lists render and index reading green on the floor, pinned and release legs, and the lists reading green on the pinned leg (1.10.18) and skipped on the other two, as its guard says.
- 2026-10-19: T6 done: suite run 4 at 1e28f44 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1793, 10 skip lines, M115-AC2 among them. Status review.
- 2026-10-19: review return 1: diff-bug #1 — a moved author id on a caption mark is written as a bare `<id>` that takes the label of the mark before it, so in a caption with two marks the earlier one prints no locator at exit 0 (IP2). The return also carries the fix-now items of the Review section: fixture cases with two marks in one caption and an author id on a float with an id (diff-bug #2), no blank line from a moved id (#3), KI290 naming the no-id figure fallback (#5, blame-history #2), the lists reading named in `versions.yml`'s comments and `site/tests.qmd` (#6, ripple #2/#3), the `lof:` sentence as a dated observation (blame-history #4), plants for AC3's link destination and AC6's grep (prior-review #1), per-handler revert probes (prior-review #4), DESIGN.md's pass count (ripple #1), and the candidate row "Breakable float caption marks" (blame-history #1). Status in-progress.
- 2026-10-19: T7: added task T7 for review return 1; Coverage gives T7 to AC1, AC3, AC4, AC5 and AC6 (minor amendment).
- 2026-10-19: T7: elder's table-div caption now also marks juniper with the id `juniper-mark` (manifest gains `juniper 7@7`, the lists manifest the longer caption). On the committed `typst.lua` the render warned "content labelled multiple times" and the index read elder with no locator (row 9). `caption_moves` now writes a moved id as `#[#metadata(none)<id>]`, or `label("…")` for an id Pandoc would not write bare (`label()` attaching checked on Typst 1.10.19's bundle); index, `pages` reading, lists and the page-9 link green, and page 7 renders pixel-identical with and without the id (diff-bug #3).
- 2026-10-19: T7 plants, by hand in scratch copies: AC3's check red on a link to `juniper-mark` ("links to pages [7], not the one link to page 2"); AC6's grep red on a `site/typst.qmd` without the line; with only the `Figure` handler removed the render stopped on the duplicate `alder-mark` label and, without the link, only alder read red; with only the `FloatRefTarget` handler removed alder read right and birch, cedar, dogwood, elder, hazel and juniper read page 1.
- 2026-10-19: T7 docs and records: KI290 names the no-id figure fallback; DESIGN.md's pass count names the Typst stage; `versions.yml`'s WHAT IT CHECKS and reader list name the pinned-leg lists reading; `site/tests.qmd` names it; `site/typst.qmd`'s `lof:` sentence is a dated observation; candidate row "Breakable float caption marks" added, parked. The claim audit ran once at implement and is not re-run (one pass); the return's added prose is derived from this session's probes.
- 2026-10-19: T7 done: dispatched `versions.yml` run 39337730177 at 6f0f4c5 green on every job, the caption-lists render and index reading on all three legs and the lists reading on the pinned leg; suite run 5 at 6f0f4c5 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1793, 10 skip lines, M115-AC2 among them. Status review.
- 2026-10-19: review return 2: diff-bug #1 (pass 2) — `float_labels` wraps a float's content in one Div, which collapses Quarto's `layout-ncol` grid into one cell when the float's own caption holds a mark (probe: `fig-parent` hands the stage Blocks[Div,Div], `fig-pair` Blocks[Para,Para], `tbl-pair` Blocks[Table,Table], each with `layout-ncol=2`). The return also carries pass 2's fix-now items: the `id_inline` and fallback comments, a non-ASCII fixture id for the `label("…")` branch, a nil-content guard, the docs' caption exceptions, committed self-test plants for AC3's link, AC6's grep and each handler, the two long lines, and DESIGN.md's wrapper sentence and KI290. Status in-progress.
- 2026-10-19: T8: added task T8 for review return 2; Coverage gives T8 to AC4 (minor amendment).
- 2026-10-19: T8: `float_labels` no longer wraps several blocks: content of one Plain or Para takes the inlines at its end, one other block is wrapped with a Plain, and several blocks (Quarto's layout cells) give them to the first Plain or Para cell, or leave them in the caption where none is; a nil content returns early. New fixture `examples/typst-caption-layout.qmd` (a `layout-ncol=2` figure div with two text cells and a caption mark) with manifest `tests/typst-caption-layout.tsv` and a suite check that the cells share a line: on the committed code the cells printed on two lines, now on one, kestrel on page 1. A fourth picture in the lists fixture would have changed what AC2's "three picture captions" names, so the case has its own fixture.
- 2026-10-19: T8: juniper's id is now `juniper-märk`, so the fixture runs the `label("…")` branch; the render compiles and the index reads green on 1.10.19. Self-test plants committed in the M115 section: link, lof, figure (the index red at alder), float (red at birch) and cells; the figure plant takes the fixture's link out so the planted copy builds. Comments on `id_inline` and the no-id fallback corrected; `site/typst.qmd` and `CHANGELOG.md` name the exceptions; DESIGN.md's Typst paragraph and KI290 rewritten; `site/tests.qmd` and `versions.yml` reflowed; `site/gallery.yml` lists the new fixture as not shown.
- 2026-10-19: T8 done: dispatched `versions.yml` run 39340658487 at db2cdca green on every job (the caption-lists render and index reading on floor, pinned and release, which compiles `label("juniper-märk")` on Typst 0.11, and the lists reading on the pinned leg); suite run 6 at db2cdca (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1801, 10 skip lines, M115-AC2 among them; the five M115 self-test plants each red on its named failure. Status review.
- 2026-10-19: review return 3: diff-bug #1 (pass 3) — joining the labels to an image Para in a laid-out float keeps the author's image width Quarto otherwise drops (an image about 260 times larger, index right). This is the third defect return, so the thrash rule's trigger (a) holds, and trigger (b) holds too: returns 2 and 3 are one shape, a change to a laid-out float's content that changes Quarto's layout. No retry is queued; the disposition is the user's, at the chip. The plan's recorded alternatives are a Typst-side choice among the label's copies and a label block after the float.
- 2026-10-19: thrash stop chip: the user chose "Narrow it" over park, a re-plan of the approach, and dropping M115.
- 2026-10-19: substantive amendment: Scope In now moves caption labels only "for a float whose content is one block"; Scope Out adds that a float whose content is several blocks, Quarto's layout cells among them, keeps its caption labels, sent to KI290 and the candidate row "Laid-out float caption marks" (split from M115). The acceptance criteria are unchanged: none names a laid-out float. The user approved this narrowing at the chip above.
- 2026-10-19: added task T9 for the narrowing and the pass-3 fix-now items; Coverage gives T9 to AC4 and AC6 (minor amendment). Status in-progress.
- 2026-10-19: T9: `examples/typst-caption-layout.qmd` gained a second laid-out figure, two image cells at `width=80%`, marking linden on page 2 (manifest `linden 2@2`); on the T8 code its images printed at 0.274 and 72 ppi. `float_labels` now returns early for content of several blocks, so it keeps its caption labels; the images print at 72 ppi each and the cells still share a line. A one-cell layout float and a plain figure with widths printed at one size with a mark or without (probe).
- 2026-10-19: T9 suite: `m115_images_check` reads page 2's image resolutions with `pdfimages -list`; the `cells` plant now wraps several blocks in one Div, a new `images` plant restores T8's join, and four `lists-*` plants run `tests/typstlists.py` on a planted manifest (a caption no list holds, a title no page prints, a caption under the wrong list, no rows); each was red by hand on its named message. Docs: `site/typst.qmd` and `CHANGELOG.md` say a float whose content is several blocks still files the list's page; DESIGN.md's Typst paragraph and KI290 rewritten; the stage comments name tables and listings. Pass-3 dispositions settled without a change: blame-history #5, the layout check on the pin, stays on every Quarto, since its subject is the extension leaving Quarto's layout alone, which the fixture's two-version comparison does not need; ripple #3, the no-id figure case, is named on the Typst page and in KI290, not in the changelog, since Markdown does not make it.
- 2026-10-19: T9 done: dispatched `versions.yml` run 39344727546 at 7aceb61 green on every job (caption-lists render and index reading on all three legs, lists reading on the pinned leg); suite run 7 at 7aceb61 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1806, 10 skip lines, M115-AC2 among them; the eleven M115 self-test plants each red on its named failure. Status review.
- 2026-10-19: review return 4: diff-bug #1 (pass 4) — the Div wrapper around a float whose one block is a computation cell's output Div (knitr `kable`, Jupyter's labelled figure shape) stops Quarto unwrapping the cell, and the float prints flush left instead of centered, index right. The thrash rule's trigger (a) still holds, and (b) again: the fourth change to a float's content that changed Quarto's layout. No retry queued; the disposition is the user's, at the chip. Every probed one-block float other than cell output (images with widths, tables with column widths, listings, callouts, column and margin divs, cross-references) printed pixel-identical to main.
- 2026-10-19: thrash stop chip (second): the user chose "Narrow again" over park, a re-plan of the approach, and dropping M115.
- 2026-10-19: substantive amendment: Scope In now moves caption labels only "for a float whose content is one paragraph, table or code block"; Scope Out says a float whose content is anything else, several blocks or one other block (a code cell's output among them), keeps its caption labels, sent to KI290 and the candidate row "Laid-out float caption marks", whose text widens to match. The acceptance criteria are unchanged: each case they name is a paragraph, a table or a code block. The user approved this narrowing at the chip above.
- 2026-10-19: added task T10 for the second narrowing and the pass-4 fix-now items; Coverage gives T10 to AC4 and AC6 (minor amendment). Status in-progress.
- 2026-10-19: T10: `examples/typst-caption-layout.qmd` gained a code-cell-shaped figure (`.cell` Div with `fig-cap` around a `.cell-output-display` Div), hornbeam on page 3; on the T9 code its caption printed at x 91, the margin. `float_labels` now wraps only a Table or CodeBlock and returns early for any other single block; the caption prints at x 154 again, and the lists fixture still reads green. Each check got an unmarked twin instead of a fixed number: page 2 holds the image figure and its unmarked twin (four images, one ppi), page 3 the code-cell figure and its twin (both captions at one x), so the checks hold the extension against Quarto's own output rather than against a value Quarto picks.
- 2026-10-19: T10 suite: `m115_images_check` now wants four images at one ppi, a new `m115_center_check` reads page 3's caption x with `pdftotext -bbox-layout`, `pdfimages` presence is checked by name, and a `center` plant restores the wrapper around any one block; by hand the `center` plant read "x 90.968000 153.556500" and the `images` plant "0.274 72 72 72", each red on its own check only. Docs: `site/typst.qmd` scopes the rule to content of one image or paragraph, table or code block and states the rest, the author-id limit included; `CHANGELOG.md` names other floats with two examples; KI318, KI290, DESIGN.md's pass count and Typst paragraph scoped; `index.lua`, `typst.lua` and `versions.yml` comments scoped and reflowed.
- 2026-10-19: T10: dispatched `versions.yml` run 39347509457 at fabbc2b green on every job. Suite run 8 at fabbc2b stopped at "M115 self-test (cells): the check passed the plant": the plant's Div now takes the new early return, so nothing was wrapped. The plant now writes the first fix's wrapper itself in one splice; by hand its cells printed on two lines. Only `tests/run-tests.sh` changed, which no CI job runs.
- 2026-10-19: T10 done: suite run 9 at 9248aa9 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19): all checks passed, 1807, 10 skip lines, M115-AC2 among them; the twelve M115 self-test plants each red on its named failure. Matrix evidence: run 39347509457 at fabbc2b, whose tree outside `tests/run-tests.sh` and `cairn/` equals 9248aa9's. Status review.

## Decisions

## Review

Evidence base: HEAD 55f1100, whose tree outside `cairn/` equals 1e28f44's (`git diff 1e28f44 HEAD -- . ':!cairn'` empty); local Quarto 1.10.19, pinned 1.10.18.

- AC1: fresh render of `examples/typst-caption-lists.qmd` to Typst at review exited 0 with no warning; `tests/typstindex.py` read "the 14 lines of 'Index' match the manifest, each locator's face and link included" (alder 2, birch bold 3, cedar 4, dogwood 5–6 linked to 5, elder 7, hazel 8, larch 9); page 1's first line is `List of Figures` (no title), 9 page breaks, the lists repeated on page 10. Suite run 4 at 1e28f44 printed the same `ok M115-AC1 (Typst)` and `ok M115-AC1/AC3` lines. The T6 revert probe was red at row 1 (alder `1@1` against `2@2`).
- AC2: on the pinned Quarto, dispatched `versions.yml` run 39334750678 at 1e28f44, job `pdf (pinned, 1.10.18)`, step "Read the Typst caption-lists lists against their manifest" (`tests/typstlists.py` against `tests/typst-caption-lists-lists.tsv`, 12 rows: 3 picture, 2 table, 1 listing caption, on page 1 and page 10): success; skipped on the floor and release legs by its guard. Locally the suite prints `skip M115-AC2` (1.10.19); the same reader on the review render printed "each of the 12 captions the manifest names is in its list". Plants at implement (a wrong caption; a table caption put under the listings list) were red naming the list.
- AC3: the review render, which holds `[alder]{#alder-mark .index}` in a caption copied by two lists and `#link(<alder-mark>)` on page 9, exited 0; the PDF's link annotations on page 9 are one link, to page 2, alder's caption page. On base `typst.lua` the same source stopped on "label `<alder-mark>` occurs multiple times" (T1, and the T6 revert probe).
- AC4: suite run 4, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at 1e28f44 (tree outside `cairn/` equal to HEAD), Quarto 1.10.19: "All checks passed (1793 checks)", 796 self-test `ok` lines, 10 skip lines, each a pinned-only check (M34-AC4 control (d), cell guard, M105-AC1, five M57-AC7, M098-AC7, M115-AC2). Among the passes: `M101-AC1/AC2 (Typst)` "the 16 lines of 'Index' match", and the M098, M099 and M100 Typst index checks.
- AC5: dispatched `versions.yml` run 39334750678 at 1e28f44 (event workflow_dispatch, every job success): steps "Render examples/typst-caption-lists.qmd to Typst" and "Read the Typst caption-lists index against its manifest" (`tests/typstindex.py pages` against `tests/typst-caption-lists.tsv`) success on `pdf (floor, 1.5.52)` and `pdf (pinned, 1.10.18)`, and on the release leg too. Earlier runs 39329028850 and 39329284098 were green the same way.
- AC6: `site/typst.qmd` section "Lists of figures, tables and listings" says a mark "in the caption of a figure, a figure div, a table or a code listing still files the page its caption prints on", that "Both hold when the float does not break across pages", and that such a list copies each caption; line 111 is `#outline(title: [List of Figures], target: figure.where(kind: "quarto-float-fig"))`, which the suite's `ok M115-AC6` holds equal to the fixture's line. `CHANGELOG.md` `## Unreleased` → `### Output`, first bullet: "A mark in the caption of a figure, a table or a code listing files the page its caption prints on. That is also true under a list of those floats that Typst's `outline` prints, which copies each caption. This needs a float that does not break across pages, which is Quarto's default."
- Consistency gate: `cairn_validate.py` all checks passed (coverage complete included); no DESIGN.md principle changed, so `cairn_impact` not run; the generic profile's consistency-gate names no toolchain checks. Main unmoved since the branch was cut (f2e5794). Copilot round off (no `# Copilot review:` line).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `caption_moves` writes a moved author id as an empty Span, which Pandoc writes as a bare `<id>` that attaches to the label element before it; a caption `[oak]{.index} and [pine]{#pine-id .index}` printed oak and pine with no locator at exit 0 (Typst: "content labelled multiple times") — fix now, return floor (a silent lost locator, IP2): review return 1
- diff-bug #2: no case holds two marks in one caption, or an author id on a float with an id — fix now (fixture cases, in return 1)
- diff-bug #3: a moved author id opens a new Plain that Pandoc writes as a zero-width space plus `<id>`, adding a blank line under a table or listing — fix now (in return 1, with #1)
- diff-bug #4: the Div wrap changes the Typst source of a table or listing float with a moved label — reject, planned change: the reviewer's own page-image comparison found the pages identical
- diff-bug #5: a figure with no id whose first block holds no inlines keeps its labels in the caption, and the docs do not say so — fix now (KI290 names it; in return 1)
- diff-bug #6: `versions.yml`'s reader list and `site/tests.qmd` omit the pinned-leg lists reading — fix now (in return 1)
- diff-bug #7: `tests/typstlists.py` takes a title's first match — reject, false within its domain: the fixture's six titles are distinct and no caption equals a title, and a list running onto another page reads red, never green
- diff-bug #8: the new stage walks every document in every format — reject, false as a defect: it returns nil outside Typst, and the reviewer found HTML and LaTeX output byte-identical
- blame-history #1: a breakable float's caption mark now files the content-end page where main filed the caption's — follow-up: KI318 records it; candidate row "Breakable float caption marks" (in return 1's tracking edit)
- blame-history #2: the no-id figure fallback leaves a gap — fix now, same as diff-bug #5
- blame-history #3: the Div wrap is unrecorded — reject, planned change, as diff-bug #4; DESIGN.md's Typst paragraph names the move to the float's content
- blame-history #4: `site/typst.qmd` names Quarto 1.10.19 for `lof:`, off the 1.10.18 pin — fix now: worded as a dated observation (in return 1)
- blame-history #5: the pinned-leg step is skipped by GitHub with no skip line — reject, planned change: D-065's skip line governs the suite, where the AC2 check prints one; the run shows the step as skipped on each other leg
- prior-review #1: AC3's link-destination clause and AC6's grep were never shown red alone — fix now: plants in return 1
- prior-review #2: the `lof:` version string — fix now, same as blame-history #4
- prior-review #3: the pinned-leg step's `!cancelled()` guard is unproven by a red probe — reject, false: the same guard form was proved past a red reading in this workflow at M106 (LESSONS M43, extended M106)
- prior-review #4: removing one of the two handlers alone was not shown red — fix now: per-handler revert probes in return 1
- prior-review #5: 45 added lines over 80 columns — reject, style
- ripple #1: DESIGN.md's "five passes" no longer counts the filter's passes — fix now (in return 1)
- ripple #2: `site/tests.qmd` does not name the pinned-leg lists reading — fix now, same as diff-bug #6; README.md's "reads an index from each printed PDF" stays true — rejected for README
- ripple #3: `versions.yml`'s WHAT IT CHECKS and reader list omit the lists step — fix now, same as diff-bug #6
- ripple #4: version strings off the pin — fix now, same as blame-history #4; KI318's "Observed on Quarto 1.10.19" is a dated observation and stays
- ripple #5: the ROADMAP candidate row still states the caption problem — reject, planned: it carries ` — started M115` and graduates at post-merge hygiene

Pass 2, after review return 1. Evidence base: HEAD 3553374, tree outside `cairn/` equal to 6f0f4c5's; main unmoved (f2e5794).
- AC1 (pass 2): fresh render exited 0 with no warning; `tests/typstindex.py` "the 16 lines of 'Index' match the manifest, each locator's face and link included", juniper 7 and elder 7 from one caption, juniper's mark carrying an author id; red on the pre-return code at row 9 (elder with no locator). Suite run 5 at 6f0f4c5: `ok M115-AC1 (Typst)`.
- AC2 (pass 2): dispatched `versions.yml` run 39337730177 at 6f0f4c5, `pdf (pinned, 1.10.18)` step "Read the Typst caption-lists lists against their manifest": success; skipped on floor and release. The review render on 1.10.19: "each of the 12 captions the manifest names is in its list".
- AC3 (pass 2): fresh render exited 0; page 9 carries one link, to page 2. Plant: the link pointed at `juniper-mark` read red ("links to pages [7], not the one link to page 2").
- AC4 (pass 2): suite run 5, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at 6f0f4c5, Quarto 1.10.19: "All checks passed (1793 checks)", 10 skip lines, all pinned-only checks as in pass 1.
- AC5 (pass 2): run 39337730177 at 6f0f4c5: caption-lists render and `typstindex.py pages` reading success on `pdf (floor, 1.5.52)` and `pdf (pinned, 1.10.18)` (and release); every job success.
- AC6 (pass 2): `site/typst.qmd` keeps the caption sentences and the `List of Figures` call, its `lof:` sentence now a dated observation; suite run 5 `ok M115-AC6`; plant: a copy without the call line fails the grep. CHANGELOG sentence unchanged.
- Consistency gate (pass 2): `cairn_validate.py` all checks passed; no principle changed; profile gate none.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1 (pass 2): wrapping a float's content in one Div collapses Quarto's `layout-ncol` grid when the float's own caption holds a mark (subfigures, a pair of images, a pair of tables stacked in one cell), the index right and the layout silently changed — fix now, return floor (IP2, silent corruption): review return 2
- diff-bug #2 (pass 2): `id_inline`'s comment says it writes an id "as Pandoc writes an id", but `%w` is ASCII, where Pandoc writes Unicode letters bare — fix now (comment; both forms name the same label)
- diff-bug #3 (pass 2): no fixture or leg runs the `label("…")` branch, so the floor's Typst 0.11 never compiles it — fix now: a fixture id outside ASCII
- diff-bug #4 (pass 2): a raw Typst inline in a caption holding `<qi-mark-` moves with the labels — reject, false as a defect: `qi-mark-` labels are the filter's own minted names, matched the same way in alt text since M098
- diff-bug #5 (pass 2): `float_labels` has no guard for a nil `float.content` — fix now (guard)
- diff-bug #6 (pass 2): a plain span id in a caption is still copied by a list — reject, present on main and outside the extension's marks (the plan's probe showed it fails without the extension)
- blame-history #1 (pass 2): `typst.lua`'s "never taken from the author's id" comment — reject, false: each mark's locator label is still minted; the moved element carries the author's id for the author's own links, not as a locator
- blame-history #2 (pass 2): same as diff-bug #2 — fix now
- blame-history #3 (pass 2): `CHANGELOG.md` and `site/typst.qmd` state the caption rule without the no-id figure fallback — fix now, with the layout exception return 2 adds
- blame-history #4 (pass 2): an anchorless cross-reference mark's id moves too — reject, false as a defect: the reviewer found no visible effect and the id still names one element
- prior-review #1 (pass 2): the caption-lists render step has no `if:`, so an earlier red step skips it — reject, planned: every fixture step in the PDF job follows the same pattern, and a run with an earlier red step is red and re-dispatched after its fix
- prior-review #2 (pass 2): docs over-claim — fix now, same as blame-history #3
- prior-review #3 (pass 2): return 1's plants were hand-run, not committed self-test plants as M101 and M114 did — fix now: self-test plants for AC3's link, AC6's grep and each handler
- prior-review #4 (pass 2): the fixture never varies breakability — reject, planned: the plan's Out item sends breakable floats to KI318 and the parked row "Breakable float caption marks"
- prior-review #5 (pass 2): `site/tests.qmd:46` (106 columns) and `versions.yml:353` (105) and its orphan `figuremarks.py` wrap reintroduce what M097 fixed — fix now (rewrap)
- prior-review #6 (pass 2): DESIGN.md never mentions the Div wrapper — fix now, with return 2's change to when a wrapper is used
- prior-review #7 (pass 2): "List of Figures" holds `F` next to `i` — reject, false: the fixture's claim and the M30 lesson are about lowercase `fi`
- ripple #1 (pass 2): KI290 says labels move out of "any float" yet lists custom kinds as unprobed — fix now: KI290 rewritten with return 2's exceptions
- ripple #2 (pass 2): the no-id figure comment says "holds no inlines" where the code tests the block's type — fix now (comment)
- ripple #3 (pass 2): DESIGN.md says `index.lua` "defines the Pandoc pass and nothing else" — reject, false: the new stage only names two module functions, and `index.lua` defines nothing new
- ripple #4 (pass 2): `site/typst.qmd` omits the caption exceptions — fix now, same as blame-history #3
- ripple #5 (pass 2): the candidate row is still open — reject, planned, as ripple #5 of pass 1
- ripple #6 (pass 2): KI318 sits before KI290 — reject, false as a defect: the Typst subsection is not in number order (KI310 precedes KI296)

Pass 3, after review return 2. Evidence base: HEAD 256ba4f, tree outside `cairn/` equal to db2cdca's; main unmoved (f2e5794).
- AC1 (pass 3): fresh render exited 0 with no warning; `tests/typstindex.py` "the 16 lines of 'Index' match the manifest, each locator's face and link included", juniper's id now `juniper-märk` (written as `label("…")`). Suite run 6 at db2cdca: `ok M115-AC1 (Typst)`; self-test plants `figure` (red at alder `1@1`) and `float` (red at birch `1*@1`).
- AC2 (pass 3): dispatched `versions.yml` run 39340658487 at db2cdca, `pdf (pinned, 1.10.18)` step "Read the Typst caption-lists lists against their manifest": success; skipped on floor and release. Review render on 1.10.19: "each of the 12 captions the manifest names is in its list".
- AC3 (pass 3): fresh render exited 0; page 9 carries one link, to page 2. Suite run 6 self-test plant `link`: red on "page 9 carries links to pages [7], not the one link to page 2".
- AC4 (pass 3): suite run 6, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at db2cdca, Quarto 1.10.19: "All checks passed (1801 checks)", 10 skip lines, all pinned-only checks as before; includes the laid-out float check (`examples/typst-caption-layout.qmd`: kestrel page 1, cells on one line) and its `cells` plant red.
- AC5 (pass 3): run 39340658487 at db2cdca: caption-lists render and `typstindex.py pages` reading success on `pdf (floor, 1.5.52)` and `pdf (pinned, 1.10.18)` (and release); every job success.
- AC6 (pass 3): `site/typst.qmd` keeps the caption sentences and the `List of Figures` call and adds the two exceptions; suite run 6 `ok M115-AC6` and its `lof` plant red; `CHANGELOG.md` sentence adds "A grid of subfigures or tables laid out in cells keeps the list's page."
- Consistency gate (pass 3): `cairn_validate.py` all checks passed; no principle changed; profile gate none.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1 (pass 3): appending the labels to an image Para in a laid-out float stops Quarto treating that cell as image-only, so the author's `width=80%` survives in one cell where main drops it in both; the first image printed about 260 times larger, index right, no warning — floor (IP2, silent corruption): review return 3, which reaches the thrash threshold; disposition at the user's chip
- diff-bug #2 (pass 3): `examples/typst-caption-layout.qmd` has no list, so its index check passes whether or not the label moves — fix in the next round, per the chip's outcome
- diff-bug #3 (pass 3): a float with several blocks, no layout attributes and no Plain or Para (a callout and a code block) also keeps its labels in the caption, and the docs name two kinds — fix in the next round (docs and KI290)
- diff-bug #4 (pass 3): several blocks are not always layout cells — fix in the next round (comment and DESIGN.md)
- diff-bug #5 (pass 3): KI318 and the breakable sentences say "where the float's content ends", but a multi-block float puts the label after its first paragraph cell — fix in the next round
- diff-bug #6 (pass 3): `typst.lua:323` past 80 columns — reject, style
- blame-history #1 (pass 3): image and table grids keep the list's page with no D-entry, the failure M115 fixes — follow-up at the chip: the descope option makes it a recorded known issue (KI290), never silent
- blame-history #2 (pass 3): `site/typst.qmd` says "paragraph" where the code tests Plain or Para, so a no-id image figure reads as an exception — fix in the next round
- blame-history #3 (pass 3): the CHANGELOG's "keeps the list's page" reads as a fix — fix in the next round
- blame-history #4 (pass 3): the layout fixture calls text cells "a laid-out picture div" — fix in the next round
- blame-history #5 (pass 3): the layout check runs only locally, off the pin, though its subject is Quarto's layout — fix in the next round, per the chip's outcome
- blame-history #6 (pass 3): `typst.lua:323` long line — reject, style
- blame-history #7 (pass 3): same as diff-bug #4 — fix in the next round
- prior-review #1 (pass 3): the paragraph-cell join has no red probe — same as diff-bug #2
- prior-review #2 (pass 3): `tests/typstlists.py` has no committed plant per clause — fix in the next round
- prior-review #3 (pass 3): the plants are never shown passing unplanted (check-design M42) — reject, false: each plant's copy differs from the run's own green render by its one splice, and the run's own renders of the same fixture pass above
- prior-review #4 (pass 3): AC1's "one case to a page" against page 7's two marks — reject, false: page 7 holds one case, one caption, which marks two terms
- prior-review #5 (pass 3): `typst.lua:323` long line — reject, style
- prior-review #6 (pass 3): the CHANGELOG carve-out wording — same as blame-history #3
- ripple #1 (pass 3): KI290's "moves the labels of any float" against its own exceptions — fix in the next round
- ripple #2 (pass 3): the layout fixture's last line is not a caption — reject, false: the render prints it as "Figure 1: A laid-out picture div, whose caption marks kestrel."
- ripple #3 (pass 3): the CHANGELOG omits the no-id figure exception — fix in the next round
- ripple #4 (pass 3): the caption rule is stated before its exceptions — reject, style: the exceptions follow in the same section and entry
- ripple #5 (pass 3): same as diff-bug #5
- ripple #6 (pass 3): the open candidate row — reject, planned, as before
- ripple #7 (pass 3): `site/syntax.qmd` and an older CHANGELOG line say a caption mark files one locator — reject, false: still true, a list adds no second locator
- ripple #8 (pass 3): two comments name only figures — fix in the next round
- Pass-3 fix-now items, landed at 7aceb61 (T9): diff-bug #2 and prior-review #1 (the `images` case and plant), #3 and #4 (docs, KI290, comments), #5 (KI318 holds again: a one-block float's label sits at its content's end); blame-history #2, #3, #4, #7; prior-review #2 (four `lists-*` plants); ripple #1, #8. Settled without a change, with reasons in the work log: blame-history #5, ripple #3.

Pass 4, after review return 3 and the narrowing. Evidence base: HEAD 1ae0eca, tree outside `cairn/` equal to 7aceb61's; main unmoved (f2e5794).
- AC1 (pass 4): fresh render exited 0 with no warning; `tests/typstindex.py` "the 16 lines of 'Index' match the manifest, each locator's face and link included"; every AC1 case's content is one block, so the narrowing leaves them as they were. Suite run 7 at 7aceb61: `ok M115-AC1 (Typst)`; plants `figure` and `float` red.
- AC2 (pass 4): dispatched `versions.yml` run 39344727546 at 7aceb61, `pdf (pinned, 1.10.18)` step "Read the Typst caption-lists lists against their manifest": success; skipped on floor and release. Review render on 1.10.19: "each of the 12 captions the manifest names is in its list"; plants `lists-caption`, `lists-title`, `lists-wrong`, `lists-empty` red.
- AC3 (pass 4): fresh render exited 0; page 9 carries one link, to page 2; plant `link` red.
- AC4 (pass 4): suite run 7, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at 7aceb61, Quarto 1.10.19: "All checks passed (1806 checks)", 10 skip lines, all pinned-only; includes the layout fixture (kestrel 1, linden 2, cells on one line, both images 72 ppi) and its `cells` and `images` plants red.
- AC5 (pass 4): run 39344727546 at 7aceb61: caption-lists render and `typstindex.py pages` reading success on `pdf (floor, 1.5.52)` and `pdf (pinned, 1.10.18)` (and release); every job success.
- AC6 (pass 4): `site/typst.qmd` keeps the caption sentences and the `List of Figures` call, and its exceptions now name a float whose content is several blocks and a figure with no id whose content does not start with text or an image; suite run 7 `ok M115-AC6`, plant `lof` red; `CHANGELOG.md` ends the bullet "A mark in the caption of a float laid out in cells, such as a grid of subfigures, still files the list's page."
- Consistency gate (pass 4): `cairn_validate.py` all checks passed; no principle changed; profile gate none.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1 (pass 4): a float whose one block is a computation cell's output Div (a knitr `kable` with `tbl-cap`, and the Div shape Jupyter writes for a labelled figure) is wrapped, and Quarto then no longer unwraps the cell, so the float prints flush left instead of centered (caption x 245 to 91 pt), index right — floor (IP2, silent layout change): review return 4; disposition at the user's chip
- diff-bug #2 (pass 4): the wrapper comment and DESIGN.md say it leaves the page as it was — fix in the next round
- diff-bug #3 (pass 4): no fixture holds a computation cell's output — fix in the next round
- diff-bug #4 (pass 4): `m115_images_check` compares the two images only with each other, so a change to both stays green — fix in the next round (hold each to the 72 ppi main prints)
- diff-bug #5 (pass 4): a 1x1 image tells a dropped width from a kept one, not two kept widths — reject, false as a defect for what the check claims: it claims Quarto's drop of a cell image's width is kept
- blame-history #1 (pass 4): an author's id in a several-block float's caption is not moved, so a link to it still fails to compile under a list, while `site/typst.qmd` says such a link builds — fix in the next round (docs and KI290; the id cannot move without touching that content)
- blame-history #2 (pass 4): the CHANGELOG names only floats laid out in cells — fix in the next round
- blame-history #3 (pass 4): KI318 and the breakable sentences are unscoped — fix in the next round
- blame-history #4 (pass 4): AC6's wording against several-block figure divs — reject, false: AC6 names the shapes the fixture holds, each one block, and says "when the float does not break"; the exceptions are documented beside it
- blame-history #5 (pass 4): no fixture shows the several-block list case red — reject, planned: it is the known issue KI290 records, and the layout fixture holds its layout
- blame-history #6 (pass 4): `pdfimages` has no presence guard — fix in the next round (name the missing tool)
- blame-history #7 (pass 4): an image-only Para gains the labels — reject, false: diff-bug pass 4 printed one-image figures with and without width, height and alignment pixel-identical to main
- blame-history #8 (pass 4): a broken reflow in the stage's header comment — fix in the next round
- prior-review #1 (pass 4): KI318 and its sentences unscoped — same as blame-history #3
- prior-review #2 (pass 4): the CHANGELOG exception — same as blame-history #2
- prior-review #3 (pass 4): DESIGN.md's reason covers only laid-out cells — fix in the next round
- prior-review #4 (pass 4): the `lists-*` plants run off the pin — reject, false as a defect: they test the reader, not Quarto's kinds, and the reader runs on any Quarto
- ripple #1, #3, #4, #9 (pass 4): unscoped statements of the move (KI318, `versions.yml`, `site/typst.qmd`, DESIGN.md, `index.lua`) — fix in the next round
- ripple #2 (pass 4): `versions.yml` comments — same as ripple #1
- ripple #5 (pass 4): the open candidate row's wording — reject, planned: it graduates at hygiene
- ripple #6 (pass 4): "which Markdown does not make" against "which no fixture holds" — reject, false: both are true and not in conflict
- ripple #7 (pass 4): the candidate row equates several blocks with layout cells — fix in the next round
- ripple #8 (pass 4): CHANGELOG against "several blocks" — same as blame-history #2
- ripple #10 (pass 4): reflow and a long line — fix in the next round
- Pass-4 fix-now items, landed at fabbc2b and 9248aa9 (T10): diff-bug #2, #3 (code-cell fixture), #4 (unmarked twins in place of a fixed size); blame-history #1 (author-id limit in docs and KI290), #2, #3, #6 (`pdfimages` named), #8; prior-review #3; ripple #1 to #4, #7, #9, #10.

Pass 5, after review return 4 and the second narrowing. Evidence base: HEAD 92e8109; `tests/run-tests.sh` last changed at 9248aa9, and the tree outside it and `cairn/` equals fabbc2b's; main unmoved (f2e5794).
- AC1 (pass 5): fresh render exited 0 with no warning; "the 16 lines of 'Index' match the manifest, each locator's face and link included"; the AC1 cases are one image Plain, one Table or one CodeBlock each, which the stage still moves. Suite run 9 at 9248aa9: `ok M115-AC1 (Typst)`, plants `figure` and `float` red.
- AC2 (pass 5): dispatched `versions.yml` run 39347509457 at fabbc2b, `pdf (pinned, 1.10.18)` step "Read the Typst caption-lists lists against their manifest": success; skipped on floor and release. Review render on 1.10.19: "each of the 12 captions the manifest names is in its list"; four `lists-*` plants red in suite run 9.
- AC3 (pass 5): fresh render exited 0; page 9 carries one link, to page 2; plant `link` red in suite run 9.
- AC4 (pass 5): suite run 9, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at 9248aa9, Quarto 1.10.19: "All checks passed (1807 checks)", 10 skip lines, all pinned-only; the layout fixture (kestrel 1, linden 2, hornbeam 3; cells on one line, four page-2 images at one ppi, both page-3 captions at one x) and its `cells`, `images` and `center` plants red.
- AC5 (pass 5): run 39347509457 at fabbc2b: caption-lists render and `typstindex.py pages` reading success on `pdf (floor, 1.5.52)` and `pdf (pinned, 1.10.18)` (and release); every job success.
- AC6 (pass 5): `site/typst.qmd` keeps the `List of Figures` call and now scopes the caption rule to content of one image or paragraph, table or code block, with the rest and the author-id limit stated; suite run 9 `ok M115-AC6`, plant `lof` red; `CHANGELOG.md` ends "A mark in the caption of other floats still files the list's page. Examples are a grid of subfigures laid out in cells and a figure from a code cell."
- Consistency gate (pass 5): `cairn_validate.py` all checks passed; no principle changed; profile gate none.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug (pass 5): 64 cases the stage still touches (images with every attribute, tables, listings, knitr output, subfloats, one-block layout floats) rendered with the same images and index as main; only caption words moved, by 0.05 to 0.11 pt of kerning once the label left the caption text.
- diff-bug #1 (pass 5): a listing with `filename=` reaches the stage as a Div and keeps its label, unlike what `site/typst.qmd` says of a code listing, and KI290 omits it — fix now (docs, KI290)
- diff-bug #2 (pass 5): the docs say a figure or table from a code cell keeps its label, but knitr plots, `include_graphics` and `output: asis` tables move — fix now (name the output-div shape)
- diff-bug #3 (pass 5): subfigure and subtable caption labels move, which KI290 calls unprobed — fix now (KI290 says they move, with no fixture)
- diff-bug #4 (pass 5): the layout checks run on the local Quarto only — follow-up: absorbed into the candidate row "Floor-Quarto CI suite job", which runs the whole suite on the floor
- diff-bug #5 (pass 5): `m115_center_check` compares the two caption x values as exact strings — fix now (a 0.5 pt tolerance)
- diff-bug #6 (pass 5): caption words shift by up to 0.11 pt — reject, false as a defect: kerning of the caption text once the invisible label leaves it
- diff-bug #7 (pass 5): a mark in a footnote inside a caption now files the float's page — reject, false as a defect: the note belongs to the caption on the float's page, and Typst prints its text there
- blame-history #1, #2 (pass 5): unscoped lead sentences in `site/typst.qmd` and `CHANGELOG.md` — fix now
- blame-history #3 (pass 5): the layout fixture has no list — reject, planned: its checks are layout checks against unmarked twins, and its comment states what the filter does
- blame-history #4 (pass 5): the `float_labels` comment says "wrapped with a Plain" where the code wraps in a Div — fix now
- blame-history #5 (pass 5): "Quarto writes only the first block of a figure with no id" is unverified — reject, false: T2's render dropped a second block (work log)
- blame-history #6 (pass 5): a bare Table or CodeBlock from a code cell is untested — reject, false: diff-bug pass 5 rendered knitr `output: asis` tables and echoed listings identical to main
- prior-review #1 (pass 5): unscoped leads — same as blame-history #1
- prior-review #2 (pass 5): `m115_images_check` stays green if both twins change alike — reject, false: the stage returns before any change to a float whose caption holds no mark, so the twin cannot change
- prior-review #3 (pass 5): the plants' expected messages also match the count branches — fix now (distinct messages for count and mismatch)
- prior-review #4 (pass 5): two `versions.yml` comment lines over 80 columns — reject, style
- prior-review #5 (pass 5): verbless fragments in the `float_labels` comment — fix now
- ripple #1 (pass 5): `site/typst.qmd:18` unscoped — same as blame-history #1
- ripple #2 (pass 5): the wrapper comment — same as blame-history #4
- ripple #3 (pass 5): code-cell tables — same as diff-bug #2
- ripple #4 (pass 5): the candidate row "Laid-out float caption marks" is narrower than KI290's kind — fix now
- ripple #5 (pass 5): CHANGELOG lead — same as blame-history #2
- ripple #6 (pass 5): DESIGN.md's "five passes" count — reject, present before this milestone, which only added the Typst stage to it
- ripple #7 (pass 5): KI318's "at the end of that content" for a wrapped table — fix now
- Fix-now commits: pass 1 items fixed 6f0f4c5 (review return 1); pass 2 items fixed db2cdca (return 2); pass 3 items fixed 7aceb61 (return 3, narrowed); pass 4 items fixed fabbc2b and 9248aa9 (return 4, narrowed); pass 5 items fixed d54adb1 (scoped docs and KI290, the `filename` listing and code-cell wording, KI318's wrapper clause, the two check messages and the 0.5 pt tolerance, the comment).
- Verify after the pass-5 fixes: suite run 10 at d54adb1, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Quarto 1.10.19: "All checks passed (1807 checks)", 10 skip lines (pinned-only, M115-AC2 among them), the twelve M115 plants red on their named messages. d54adb1 changed no file the version matrix reads except `site/typst.qmd` and `CHANGELOG.md`, which it does not render, so run 39347509457 at fabbc2b stands for AC5 and AC2.
