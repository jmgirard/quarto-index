# M119: A Typst cross-reference mark keeps one label wherever it sits

- **Status:** review
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

- [x] AC1: On Quarto 1.10.19, `examples/typst-xref-places.qmd` puts a `see=`
      or `see-also=` mark in each of nine places. One is a heading the table
      of contents lists. Three are captions: a picture with an id, a table
      with an id and a picture with no id. A list of figures and a list of
      tables come before them. The other five are an image's alt text, a
      footnote, a callout's `title` attribute, a callout's first heading and
      a callout's body. The image is not a figure. The Typst render exits 0.
      Its log carries no Typst `warning:` line and no extension warning. The
      printed index gives each of those nine terms its cross-reference, as
      `tests/typstindex.py` reads it against `tests/typst-xref-places.tsv`.
- [x] AC2: In that render, no label of a `metadata` element is on two
      elements, where the elements are those that `quarto typst query` lists
      for the selector `metadata`. The extension writes each mark's label and
      each author's id it moves as such an element.
- [x] AC3: In that render, a Markdown link to every author's id on a mark of
      the fixture builds and goes to the page that mark is on. These marks
      include a cross-reference mark and a page-number mark in an image's alt
      text, and a page-number mark in the alt text of an image inside a
      listed float's caption.
- [x] AC4: The Unreleased Typst entry in `CHANGELOG.md` says that a link to an
      author's id on a mark in an image's alt text builds in Typst, where
      before it stopped the render. `site/typst.qmd` says that the Typst
      back-end writes such an id just after the image.
- [x] AC5: The active profile's `verify` slot passes:
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
- [x] T4: Docs and records. Write the `CHANGELOG.md` entry and the
      `site/typst.qmd` sentence per AC4 from a render. Bring the Typst
      paragraph of `DESIGN.md`'s architecture in line on alt text. Strike
      KI325.
- [x] T5: Run `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` once, in
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
- 2026-10-20: T4: the Typst entry in `CHANGELOG.md` and a Locators bullet in `site/typst.qmd` state the alt-text id, from the T1 render (12 links to their pages, the alt-text ids on page 6); `DESIGN.md`'s Typst architecture paragraph names the id move and the comment; KI325 struck.
- 2026-10-20: T5 run 1 (`--self-test`): red on M24-AC3 alone, 887 ok lines before it: `m119_query` rendered without the capture helper. It now captures each copy under `m119-<dir>`.
- 2026-10-20: claim audit: 51 claims read, 6 corrected — CHANGELOG.md (a link stopped the render unless the image sat in a float's caption), site/typst.qmd (Typst does not print alt text; Pandoc writes it as a plain string), examples/typst-xref-places.qmd (Pandoc drops a label, the links sit on the page before the index), tests/run-tests.sh (floor plants take a written input; the heading plant's label is replaced on its element).
- 2026-10-20: claim audit re-read of the 6 corrected claims: all true; one comment widened at its note to name the link and table plants (comment only, after run 2).
- 2026-10-20: T5 run 2 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at ec8c8c8): exit 0, "All checks passed (1859 checks)", 18 M119 ok lines. Status set to review.
- 2026-10-20: review pass 1: main unmoved (33de9da), Copilot round off; a suite run at 3dcf248 was stopped before its end, since fix-now commits follow and the evidence run goes on the final head.

## Review

- evidence run: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at 915f75c on Quarto 1.10.19, exit 0, "All checks passed (1861 checks)".
- AC1: in that run, the needle check (each of the nine places present, eleven page breaks), the render with no extension warning and no Typst `warning:` line, and `typstindex.py` matching all 26 lines of `Index` to `tests/typst-xref-places.tsv` (each of the nine terms with its cross-reference to Oak) each printed `ok`.
- AC2: in that run, `typstlabels.py labels` over `quarto typst query … metadata` printed "20 labels on 20 metadata elements, each on one, 13 of them for the 13 marks"; the plants show it red on a label on two elements (float, figure) and on a lost label (heading).
- AC3: in that run, `typstlabels.py links` printed "the 13 links on page 12 go to the pages of their marks", the 13 ids being every id the fixture writes on a mark, among them `id-elm` and `id-gum` (alt text), `id-nut` (alt text of an image in alt text) and `id-lark` (alt text of an image in a listed caption); the `altid` and `nestid` plants show the render stopping on ``label `<id-elm>` does not exist`` and ``label `<id-nut>` does not exist`` without the fix.
- AC4: `CHANGELOG.md:27-28` (Unreleased, Typst entry) says an alt-text mark's id "is written just after the image, so a link to the id builds. Before this change, a link to such an id stopped the render", and `site/typst.qmd:85` says the extension writes the mark's label "and an id you give the mark, just after the image".
- AC5: the evidence run above exited 0.
- gate: `cairn_validate.py` all checks passed; profile `generic` names no toolchain checks; no principle text changed, so no `cairn_impact` run.
- spawned: diff-bug, blame-history, prior-review, ripple.
- diff-bug #1: an image nested in another image's alt text loses its id, because the `Image` RawInline branch moves only qi-mark labels and not the `id_inline` elements it now writes — fix now (pre-existing on main, inside the alt-text id scope), fixed 424dab7: the branch moves them too, the fixture holds `nut` in a nested alt text on page 6, and the `nestid` plant is red on ``label `<id-nut>` does not exist``.
- diff-bug #2: the CHANGELOG and `site/typst.qmd` sentences say a link to an alt-text id builds with no exception, and in the caption of a KI290 float a list copies the id and the link fails — fix now (narrow both sentences, extend KI290), fixed 424dab7: a grid figure with that caption under a list of figures stopped on ``label `<id-k>` occurs multiple times`` and built with no list (render 2026-10-20).
- diff-bug #3: a figure caption copy that `declass_caption_copies` missed would now give two id elements — reject, false: no input was found where the copy keeps its class, and the reviewer did not reproduce one.
- diff-bug #4: the link check reads target pages, so links to `id-elm` and `id-gum` swapped on page 6 pass — reject, planned change: AC3 promises the page each link goes to, and both ids are on page 6.
- diff-bug #5: `typstlabels.py labels` raises a traceback on JSON it cannot parse rather than printing a FAIL line — fix now, fixed 424dab7, with the `badjson` plant.
- diff-bug #6: the heading plant is red on AC2's mark floor, not on a label listed twice — reject, planned change: recorded at T3.
- diff-bug #7: the mark floor counts `]{…}` blocks and would miss a raw `<span>` mark — reject, false for this fixture, which writes none.
- diff-bug #8: the float plant's want string pins mark numbers — reject, style.
- blame-history #1: the docs claim and the KI290 floats — fix now, as diff-bug #2, fixed 424dab7.
- blame-history #2: an author's raw Typst opening with `#[/* qi-id */` would be moved — reject, planned change: the work log records the comment as the chosen marker.
- prior-review #1: an id moved beside an image in a laid-out cell changes the image's size, as M115 pass 3 found for a label — reject, false: a `layout-ncol=2` figure with a `width=80%` alt-text mark prints its images at the same size with and without the id, on main and on the branch (pdfimages, 2026-10-20).
- prior-review #2: the alt-text move is checked only on the local Quarto, not the pin or the floor — follow-up: the parked row "Floor-Quarto CI suite job".
- prior-review #3: a KI290 float's caption keeps the id and a list copies it — fix now, as diff-bug #2, fixed 424dab7.
- prior-review #4: M098's unconfirmed break between a boxed image and a moved label — reject, false: the fixture's alt-text links on page 6 build and go to page 6.
- prior-review #5: the prefix match on the opening comment — reject, planned change, as blame-history #2.
- ripple #1: `site/typst.qmd` lines 131-134 and KI290 say a caption id in such a float fails, against the new unqualified sentence — fix now, as diff-bug #2, fixed 424dab7.
- ripple #2: the parked row "Laid-out float caption marks" names caption marks and not an alt-text id in such a caption — follow-up: that row points at KI290, which this pass extends to the id.
- ripple #3: `site/syntax.qmd` says the alt text is left as written — reject, false: the printed alt text is unchanged.
- ripple #4: `DESIGN.md` gives only the label form `#[#metadata(none)<label>]` — reject, false: the line is still true, and the same paragraph now names the id element and its comment.
