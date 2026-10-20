# M119: A Typst cross-reference mark keeps one label wherever it sits

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — it changes the Typst output for an author's id in an image's alt text
- **Branch/PR:** m119-typst-xref-places

## Goal

A test shows that a Typst cross-reference mark gets one label that a link
can reach in each place where a label was once copied.

## Scope

**In:** Since M118 every Typst cross-reference mark carries a label. KI325
records that no fixture puts one where a label was once copied or moved.
A new fixture `examples/typst-xref-places.qmd`, its manifest
`tests/typst-xref-places.tsv` and a suite section in `tests/run-tests.sh`
render it to Typst. The section reads the index and, through
`quarto typst query`, the labels of the laid-out document. It also reads
the page that each link to an author's id goes to. The question set's rule
is that a small defect is fixed here, and the investigation found one. In
Typst, an author's id on a mark in an image's alt text is dropped. A
Markdown link to that id stops the compile with
``label `<id>` does not exist in the document``. `typst.assign_labels`
will move that id to just after the image, as it already moves the mark's
label. Where that image sits in a listed float's caption, the moved id
leaves the caption with the float's other labels. Docs: the Unreleased
Typst entry in `CHANGELOG.md` and `site/typst.qmd`. Records: KI325 struck
in `DESIGN.md`. Absorbs KI325 from the candidate row "Older acceptance-suite
backlog", in part.

**Out:**
- A float whose content is not one block keeps its labels in its caption
  (KI290). That work is the parked row "Laid-out float caption marks".
- A breakable float (KI318): the parked row "Breakable float caption marks".
- The LaTeX, HTML and EPUB back-ends: unchanged.
- This section on the floor Quarto: the parked row "Floor-Quarto CI suite
  job".
- The rest of the acceptance-suite backlog: its candidate row.

## Acceptance criteria

- [ ] AC1: On Quarto 1.10.19, `examples/typst-xref-places.qmd` puts a `see=`
      or `see-also=` mark in each of nine places. One is a heading the table
      of contents lists. Three are captions: a picture with an id, a table
      with an id and a picture with no id. A list of figures and a list of
      tables come before them. The other five are an image's alt text, a
      footnote, a callout's `title` attribute, a callout's first heading and
      a callout's body. The image is not a figure. The Typst render exits 0.
      Its log carries no Typst `warning:` line and no extension warning. The
      printed index gives each of those nine terms its cross-reference, as
      `tests/typstindex.py` reads it against `tests/typst-xref-places.tsv`.
- [ ] AC2: In that render, no label of a `metadata` element is on two
      elements, where the elements are those that `quarto typst query` lists
      for the selector `metadata`. The extension writes each mark's label and
      each author's id it moves as such an element.
- [ ] AC3: In that render, a Markdown link to every author's id on a mark of
      the fixture builds and goes to the page that mark is on. These marks
      include a cross-reference mark and a page-number mark in an image's alt
      text, and a page-number mark in the alt text of an image inside a
      listed float's caption.
- [ ] AC4: The Unreleased Typst entry in `CHANGELOG.md` says that a link to an
      author's id on a mark in an image's alt text builds in Typst, where
      before it stopped the render. `site/typst.qmd` says that the Typst
      back-end writes such an id just after the image.
- [ ] AC5: The active profile's `verify` slot passes:
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1
- AC2 → T1, T3
- AC3 → T1, T2, T3
- AC4 → T4
- AC5 → T1, T2, T3, T4, T5

## Tasks

- [x] T1: Tests first. Write `examples/typst-xref-places.qmd`. Page 1 holds a
      list of figures and a list of tables, and `toc: true` lists the
      headings. Each AC1 place sits on a page of its own after an explicit
      page break. The body marks one term that the cross-references name.
      Every mark carries an author's id. The `title` attribute takes single
      quotes outside. A page-number mark with an id sits in the alt text of a
      second image, and another in the alt text of an inline image in a
      listed float's caption. The last page holds a Markdown link to each id.
      No term holds `fi`, `fl`, `ff` or `!!` (the M30 lesson). Write
      `tests/typst-xref-places.tsv` by hand from the source. Register the
      fixture in M14's dangling-count corpus and in `site/gallery.yml` (the
      M116 lesson). Add a suite section after M115's (`tests/run-tests.sh`
      near line 33003). It renders the fixture to Typst, captures it, and runs
      the warning checks and the `typstindex.py` comparison. It renders a
      work copy with `-M keep-typ:true` under `$WORK`, as M098-AC7 does near
      line 31340, so no `.typ` lands in `examples/`. It runs the query in
      that copy and reads its JSON from stderr. The query check fails on a
      label listed twice and on fewer `qi-mark-` labels than the fixture has
      marks. The link check reads each author's id from the source, fails on
      fewer ids than the fixture holds, and reads each link's target page
      through `typstindex._links`, as M115-AC3 does. Before the first run,
      grep the self-tests for want strings that rest on alt-text output (the
      M117 lesson). Run the section and see the alt-text links fail.
- [x] T2: The fix. In the `Image` function of `assign_labels` (`typst.lua`
      near line 436), move the author's id of each span of class `index` in
      the alt text to an `id_inline` element just after the image. Clear the
      span's id, as `caption_moves` does for a caption. Move `id_inline`
      above `assign_labels`. `caption_moves` (near line 487) also moves the
      elements `id_inline` writes, so an id moved out of an alt text inside a
      caption leaves the caption too.
- [x] T3: Plants. Each is one substitution, seen red on its own clause before
      the green is trusted. Remove the T2 id move: the alt-text links fail
      with the label error. Leave `caption_moves` blind to `id_inline`
      elements: the caption's alt-text link fails with "occurs multiple
      times". Skip the heading relocation for Typst: AC2 finds a label on two
      elements through the table of contents. Make `float_labels` return
      before its move, and in another plant `figure_labels`: AC2 finds one
      through a list each time. Leave the span id in `caption_moves`: a
      caption link fails with "occurs multiple times". Keep the heading
      mark's author id in the heading: its link fails the same way. Empty
      the query's output and the id scan: each floor fires.
- [ ] T4: Docs and records. Write the `CHANGELOG.md` entry and the
      `site/typst.qmd` sentence per AC4 from a render. Bring the Typst
      paragraph of `DESIGN.md`'s architecture in line on alt text. Strike
      KI325.
- [ ] T5: Run `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` once, in
      the background, and read its result.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which work — the Typst label tests (KI325); a defect the work finds — fixed here if it fits one sitting, otherwise a Known issue and a candidate row.
- 2026-10-20: collision check: takes KI325 from the candidate row "Older acceptance-suite backlog" in part; extends M098, M101, M115 and M118 (done); distinct from the parked rows "Laid-out float caption marks" and "Breakable float caption marks"; D-068 keeps KI325 as a gap where the extension could be wrong with the suite green; no standing rejection; GitHub inbox empty (no open issues or PRs).
- 2026-10-20: lessons harvested: M116 (dangling-count corpus, gallery line), M117 (grep self-test want strings first), M118 (plant substitutions by script), M082 (`PATH=/usr/bin:$PATH`), M30 (ligature letters), M115 (a float edit can move layout), check-design (a plant per clause, a floor on each scanned domain).
- 2026-10-20: investigation: a scratch render put a cross-reference mark in all nine places and each label was on one element; a Markdown link to an author's id in an image's alt text stopped the Typst compile ("does not exist"), so the fix joins the scope under the question set's rule.
- 2026-10-20: plan gate chose `quarto typst query` over the laid-out document over a grep of the `.typ` file, because the outline copies a label at layout time and the `.typ` never shows the copy; falsified by the pinned Quarto's Typst dropping `typst query`.
- 2026-10-20: plan gate chose a check in the suite over a `panic` written into the fixture's own Typst, because that would put the extension's label prefix in the artifact under test; falsified by the query's output differing from what the compile sees.
- 2026-10-20: criteria audit (full, fresh Opus reader): 6 findings, all accepted. T2 as first written broke an alt-text id inside a listed caption ("occurs multiple times"), so `caption_moves` also moves `id_inline` elements and the fixture holds that case (1); AC2 narrowed to labels of `metadata` elements, since author ids on text elements are reached by AC3's links (2); T1 renders the query copy under `$WORK` and reads stderr (3); AC3's scan moved to T1 with a floor (4); T3 adds plants for `figure_labels`, `caption_moves` and the heading id (5); AC1 states the printed index, not the manifest (6). Clean: AC1 renders as written, the T2 premise, AC5, no principle or decision conflict.
- 2026-10-20: implement started on branch m119-typst-xref-places, cut from main at 33de9da.
- 2026-10-20: T1: fixture (12 marks, 11 page breaks, 12 linked ids), manifests `tests/typst-xref-places.tsv` and `tests/typst-xref-places-links.tsv` by hand, reader `tests/typstlabels.py` (labels and links modes), M119 suite section after M115's, corpus row and gallery line. Before T2 the render stopped on ``label `<id-elm>` does not exist`` and the same for `id-gum`; `id-lark` already resolved, since `caption_moves` reaches a span in a caption's alt text.
- 2026-10-20: T2: `id_inline` moved above `assign_labels` and now opens with the comment `/* qi-id */` (`ID_INLINE_OPEN`), so `caption_moves` moves the filter's own id elements and never an author's raw Typst; chose the comment over matching `#[#metadata(none)`, which an author's raw Typst in a caption could also open with; falsified by Typst ever reading a comment there as content.
- 2026-10-20: T3: ten plants red on the clause each names, run in a scratch harness that sources the section alone (full suite at T5). The audit's heading-id plant was dropped: an author's id left in a Typst heading stays on one element (`= … ash<id-ash>`, query lists one), so no plant can show AC3 red there. Skipping the heading relocation loses ash's label to the heading's own label rather than copying it, so that plant is red on AC2's mark floor (11 for 12), not on a label listed twice.
