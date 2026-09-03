# M071: A front-matter mark in an HTML book chapter files one locator, to the chapter's page

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Branch/PR:** m071-front-matter-locators

## Goal

In an HTML book, a mark written in a chapter's YAML front matter is filed by that chapter's own render as the recovery route files it — once, with a locator that links to the chapter's page and nothing after it — so the index prints no link into a fragment the chapter's page does not carry.

## Scope

User-facing tier: the deliverable is the printed index of an HTML book and the docs that describe it.

Probed 2026-09-02 (quarto 1.10.18, pandoc 3.11): in a book chapter Pandoc hands the `Span` passes a front-matter mark before any body span, and Quarto also copies some fields (`abstract:` among them) into a hidden top-level div `#quarto-meta-markdown` that no filter output survives in, so one `abstract:` mark files three locators of which two are dead, and a `description:` mark files one dead locator, its field unprinted by the book title block. In a single document there is no such div and every probed field (`abstract:`, `description:`, `subtitle:`) prints its anchor (KI232, KI233).

**In:**
- A first pass that tells a front-matter mark from a body mark by a plumbing attribute set on the metadata's marks and stripped wherever an author wrote it (the pending-attribute precedent), and that, in an HTML render, takes the index class off every span inside Quarto's `#quarto-meta-markdown` div so the reflected copies are not marks.
- In an HTML book chapter, a front-matter mark records a page locator and mints no anchor, as a recovered mark does; two such marks of one term print one locator, as the recovery route's do. Sort-key registration from a front-matter mark is unchanged.
- The M070 fixture's record leg also renders `seven.qmd` from its record; its manifest rows move; `examples/front-matter.qmd` is added as the single-document control; a fragment-resolution check runs over the four captures this work touches.
- `site/books.qmd`, its claim ledger, `CHANGELOG.md`, DESIGN's recovery section; KI232 and KI233 struck.

**Out:**
- A single document's front-matter mark keeps its anchor and fragment (AC3 pins it); a field a single document's title block does not print was not probed and is not promised.
- The PDF and EPUB back-ends' handling of a front-matter mark and of Quarto's reflected copies: unmeasured, untouched — the class removal is HTML-only.
- The refusal's count rule (KI234) → M072.
- A recovered locator with a fragment where the author wrote the mark's id (KI205) → its candidate row.

## Acceptance criteria

- [ ] AC1: In `examples/book-extensions`, the index `index.qmd` prints after `six.qmd`, `seven.qmd` and `eight.Rmd` have each written their own record holds `Hasp` at `six.html` and `Mullion`, `Nacelle` and `Lanyard` at `eight.html`, one locator each with no fragment — the same rows the cold and listed-unopenable legs print for those four terms — and holds `Ingot` under its front-matter key `Az` at `seven.html` followed by one locator into `seven.html` carrying a fragment, the body mark's.
- [ ] AC2: In the index sections of the three `book-extensions` captures and the `examples/front-matter.qmd` capture, every locator href carrying a fragment names an id the page it links to carries — a suite check walks every locator of every index section in each of the four captures and reads the ids of the page each href names.
- [ ] AC3: A single HTML document with a mark in each of `abstract:`, `description:` and `subtitle:` and one in its body (`examples/front-matter.qmd`, new) prints four terms with a fragment locator each, and its rendered page carries all four anchors, the three front-matter ones inside its title block — a document that is not a book chapter files a front-matter mark as it did before this milestone.
- [ ] AC4: `site/books.qmd` states that a front-matter mark files one locator, the chapter's page with no fragment, whether the chapter is read from its record or from its source, and `CHANGELOG.md` carries an entry under `## Unreleased` / `### Output` stating the change and that a single document is untouched.
- [ ] AC5: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0 on the branch.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4
- AC3 → T2, T3
- AC4 → T5
- AC5 → T3, T4

## Tasks

- [x] T1: The tagging pass: a filter table ahead of `CollectSort` in the pass list (`_extensions/index/index.lua:50-59`) whose `Meta` function sets a plumbing attribute on every index span in the metadata, whose `Span` function strips that attribute wherever it is already present (an author's forgery, the `HTML_PENDING_ATTR` precedent at `passes.lua:312-318`), and whose `Div` function, under `qi_core.is_html()`, removes the index class from every span inside a top-level div with id `quarto-meta-markdown`. The module comment records the probe facts and their date and Quarto version.
- [x] T2: The emit pass (`passes.lua:495-535`): in an HTML book chapter (`doc.meta.book ~= nil` under `is_html`, settled in `Reset`) a tagged mark records `page_locator = true` and gets no pending attribute, so `assign_anchors` mints nothing and `mark_target` (`html.lua:146`) prints the page; the book aggregation supplies the href as it does for a recovered mark. In a single document a tagged mark keeps its pending attribute. Check `marks_seen` still counts front-matter marks.
- [x] T3: Fixture and manifests: the record leg (`tests/run-tests.sh:23710-23728`) renders `seven.qmd` too; `M070_SECTIONS_RECORDED` loses the fragments on its four front-matter rows and gains the `Ingot` fragment locator; `examples/front-matter.qmd` gets a manifest and a page assertion that its three front-matter anchors sit inside `#title-block-header`. Each new or moved row shown red first by a `m070_mutant`-style planted defect — one re-enabling the hidden-div copies, one restoring the pending attribute on tagged marks, one forging the plumbing attribute on a body mark — recorded in the work log.
- [x] T4: The fragment-resolution check (a `tests/` Python reader) over the four captures: every locator href in every index section with a fragment resolves to an id on the named page; shown red against a capture with one href rewritten to a fragment no page carries and one to a page the capture lacks; recorded in the work log.
- [x] T5: Docs: `site/books.qmd:109-116` and the "No fragment" bullet restated for both routes, the claim ledger (`tests/run-tests.sh:21753-21785`) pinning the new sentence; the `CHANGELOG.md` entry; DESIGN's recovery section (`cairn/DESIGN.md:497-503`) and KI232/KI233 struck; `warn-distinct.py`'s pinned count untouched (no new wording).

## Work log

- 2026-09-02: created by /milestone-plan from the M070 follow-up candidate row (KI232, KI233); criteria audit ran in FULL mode ([O], fresh context) and returned eight findings — M071's share: an anchor number unwritable into a manifest (dropped from AC1), one metadata field standing in for the family in AC3 (two fields added), and two instrument-binding clauses (moved to T3/T4); D-048 written.
- 2026-09-02: plan gate chose a page-only locator for every front-matter mark in a book chapter over keeping the metadata copy's fragment and dropping only the reflected copies, because the filter cannot tell which fields the book title block prints, so the fragment stays dead for `description:` and any unprinted field; falsified by an author reporting that a front-matter link landing at the top of the chapter's page, not at its abstract, is a defect.
- 2026-09-02: plan gate chose the same over a fragment for an enumerated field list (`abstract:`, `subtitle:`, `keywords:`), because the list is Quarto's title-block template, which drifts by release and theme; falsified by Quarto documenting that list as a stable contract.
- 2026-09-02: plan gate chose the fragment-resolution sweep over the four captures this work touches over every HTML book capture the suite makes, because a dead fragment elsewhere is not this milestone's promise; falsified by a dead fragment found in another fixture's index, which would promote the wider sweep.
- 2026-09-02: /milestone-implement started; branch cut from the pushed default branch. Question gate: a front-matter mark in the chapter that prints the index links to that chapter's own page by name rather than as an empty link (one extra cold render with a mark spliced into `index.qmd` covers it); the tagging attribute (`data-qi-meta`) joins the whole-set residue sweep with a planted defect of its own — a discovered sub-task, minor amendment under T1/T3.
- 2026-09-02: T1 and T2 code landed together (checkpoint, unticked until the suite runs over T3's moved manifests): `TagSpan`/`TagPandoc` in `passes.lua` ahead of `CollectSort`, constants `META_MARK_ATTR` and `META_REFLECTION_ID` in `core.lua`, the emit pass reading the tag off and filing a page locator under `html_book_chapter`; `build_record` carries `page_locator` and `book_marks` gives a page locator in the reading chapter its own page's href. Scratch renders: the cold leg prints the M070 recovered rows unchanged; the record leg prints `Hasp`, `Mullion`, `Nacelle`, `Lanyard` at their pages with no fragment, `Ingot` at `seven.html` then `seven.html#qi-mark-1`, and `Jetsam` and `Oakum` at `seven.html` (the render indexes the two conditional spans in `seven.qmd`'s abstract and drops the conditional block); a single document prints its four anchors as before; no `data-qi-meta` reaches HTML or gfm output.
- 2026-09-02: checkpoint, unverified — T3, T4 and T5 landed: `M070_SECTIONS_RECORDED` re-derived under D-048 (front-matter rows page-only, `Ingot` page then fragment, `Jetsam` and `Oakum` added), the record leg renders `seven.qmd`, `examples/front-matter.qmd` with its manifest and title-block containment checks, the fragment sweep (`tests/fragments.py resolve`) over the four captures, the own-chapter leg, and a self-test of five filter/fixture plants plus reader plants; `site/books.qmd` and its ledger row, `CHANGELOG.md`, DESIGN (architecture, recovery, KI232/KI233 struck). The fixture, gallery row and `htmlsweep`/`plantdefect` extension had gone into the T1/T2 commit. Full `--self-test` run in progress; tasks stay unticked until it is clean.
- 2026-09-03: first `--self-test` run stopped at the M063-AC6 self-test, which pins the books-page ledger count (31 → 32 with the new row); pin moved, suite re-run.
- 2026-09-03: `tests/run-tests.sh --self-test` clean, 1228 checks (1207 at M070's close), after two shell slips in the T4 self-test (an unbound local, a missing parent directory) each fixed and re-run; T1–T5 ticked. Planted defects shown red: the reflected copies' class removal taken out (`Hasp` prints its page then two fragments into ids `six.html` lacks, the fragment sweep failing on the first), the page locator turned back into an anchor (`Hasp` prints one fragment locator), the forgery strip taken out with a forged tag on `seven.qmd`'s body mark (`Ingot` loses its fragment) beside its control (nothing moves, no residue), the fragment reader on an href to a missing fragment and to a missing page, an empty domain, and the containment reader asked the wrong way round; `data-qi-meta` planted per captured page fails the residue sweep. Plain run in progress.
- 2026-09-03: plain `tests/run-tests.sh` clean, 654 checks (642 at M070's close); `cairn_validate` clean; plan-owned body 56 lines. Status → review.

## Decisions

## Review
