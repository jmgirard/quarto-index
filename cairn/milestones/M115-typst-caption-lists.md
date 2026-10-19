# M115: Typst caption marks and a list of figures

- **Status:** in-progress
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
- AC4 → T6, T7
- AC5 → T4, T7
- AC6 → T5, T7

## Tasks

- [x] T1: Write `examples/typst-caption-lists.qmd` and `tests/typst-caption-lists.tsv` by hand from its page breaks, and the suite section: the index through `tests/typstindex.py`, each list's text per kind, and the author-id link's destination page. No term, caption or list title holds `fi`, `fl`, `ff` or `!!`, which the floor's Typst sets as one glyph and `typstindex.py pages` does not fold; the fixture header says so. See AC1 red on today's `typst.lua` at the first list's page, and AC3 red on Typst's duplicate-label error, each failure named.
- [x] T2: In a filter stage after `typst.assign_labels`, move each label written in a float's caption, and a caption mark's author id, into the float's content. The filter sees a Pandoc `Figure` for an image figure with no id and Quarto's float scaffold for the other five cases (observed 2026-10-19); probe which handler reaches each on the pinned Quarto. The alt-text move at `typst.lua:297` stays. AC1 to AC3 green.
- [x] T3: Probe a float made breakable (`#show figure: set block(breakable: true)`) whose content crosses a page. If its caption mark names a page other than its caption's, write a `cairn/DESIGN.md` Known issues entry under the Typst back-end.
- [x] T4: Add the fixture to `versions.yml`'s PDF job and to its WHAT IT CHECKS comment, with a pinned-leg step running `tests/typstlists.py` for AC2, dispatch a run on the branch, and log each leg's result.
- [x] T5: Docs: `site/typst.qmd` (the caption sentence and the `outline` call, held to the fixture's own call by the suite), the `CHANGELOG.md` sentence, `site/tests.qmd`'s count of Typst fixtures, `cairn/DESIGN.md`'s Typst paragraph, and KI290 narrowed to the unprobed captions.
- [x] T6: Run `tests/run-tests.sh` and `--self-test`. Revert T2's move and see AC1 red at a named manifest row before restoring it.
- [ ] T7: Review return 1 (work log): a moved author id gets an invisible element of its own, so it takes no other mark's label and adds no blank line; fixture cases with two marks in one caption and an author id on a float with an id, red on the current code first; the Review section's other fix-now items; then the suite, a dispatched matrix run, and the review hand-back.

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
