<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M52: EPUB gets an index back-end

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP6
- **Branch/PR:** —

## Goal

A document or book rendered to EPUB gets a real index — the entry tree, letter
groups, cross-references and locator links the HTML back-end already builds —
instead of passing its marks through untouched.

Surface tier: **user-facing**. The deliverable is output an author's readers
read, and the docs site describes it.

## Scope

**In:** a third format predicate (`is_epub`) and a combined `builds_ast_index`
routing EPUB onto the AST index path at the four sites that build one
(`indexes.builds_index`, `passes.lua:497`, `index.lua:197`, and the predicate's
own definition in `core.lua`), with `is_html` left as the sole gate on the book
sidecar store, the fold, and the chapter-scope wording — because Quarto renders
an EPUB book as ONE Pandoc process, like PDF. An EPUB leg for the `demo` and
`book` fixtures; a `tests/epubindex.py` reader over the existing
`tests/htmlindex.py`; a `site/epub.qmd` page and the site/README edits a third
back-end forces.

**Out:**
- An EPUB leg in the version matrix → noted on the existing version-portability
  candidate row; M51 has just restored the PDF leg and it has not run a full
  schedule cycle clean.
- A `site/gallery/` entry for the EPUB fixture → the existing gallery-extension
  candidate row.
- An EPUB stylesheet — GP4 keeps the back-end a hook, not a stylesheet, exactly
  as HTML is; no change.
- revealjs, beamer, gfm and every other format: still pass-through, unchanged.

## Acceptance criteria

- [ ] AC1 — `examples/demo.qmd` rendered to EPUB carries exactly one section
      with id `qi-index` across the XHTML documents its `content.opf` manifest
      lists, and the entry rows `tests/htmlindex.py` returns from that section —
      level, term text, locator count, cross-reference kind and target, in
      document order — are identical to the rows the same reader returns from
      the HTML render of the same fixture, which `tests/run-tests.sh` manifest 2
      already pins by hand from the `.qmd` source.
- [ ] AC2 — for every locator link the reader collects from that EPUB's index
      section, the href's `<file>` part names an XHTML document listed in the
      EPUB's `content.opf` manifest and that document carries an element with
      the href's `<id>`. Unresolved links: zero, over the links the reader
      collected.
- [ ] AC3 — `examples/book/` rendered to EPUB carries one section per name its
      `indexes:` metadata declares (`qi-index-main`, `qi-index-people`), each
      headed with that declaration's own title; the book's `index="people"` mark
      files under `qi-index-people` and its term appears in no other index
      section; and a sweep of the render's captured warning stream finds no
      occurrence of the fold sentence `this output has one index only`.
- [ ] AC4 — a `gfm` and a `revealjs` render of `examples/demo.qmd` carry no
      index section and no `qi-` identifier: a grep of each rendered file for
      `qi-` returns nothing outside any run of that string the fixture's own
      prose puts there, which the check states as a literal exclusion list
      derived from the fixture source, not from the render.
- [ ] AC5 — `site/epub.qmd` exists and states both ways EPUB differs from HTML
      (one Pandoc process, so nothing folds and every declared index prints;
      locators are per-entry sequence numbers, not pages), pinned by a
      `tests/sitecheck.py` clause naming that page; and a sweep of tracked
      `.qmd` and `.md` files for the string `two back-ends` returns nothing.
- [ ] AC6 — `tests/run-tests.sh --self-test` clean (the `verify` slot's fuller
      pre-review check).

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T3, T4
- AC3 → T1, T2, T3, T5, T4
- AC4 → T1, T4
- AC5 → T6, T7
- AC6 → T1, T2, T3, T4, T5, T6, T7

## Tasks

- [ ] T1 — `core.lua`: add `is_epub` (matching FORMAT `epub`, `epub2`, `epub3`)
      and `builds_ast_index` (`is_html` or `is_epub`); export both. Route
      `indexes.lua:87`, `passes.lua:497` and `index.lua:197` through
      `builds_ast_index`; leave `index.lua:133/135/166/192` and
      `indexes.lua:199` (`folded`) on `is_html`. Correct `core.lua:417`'s
      comment, which says epub passes through.
- [ ] T2 — add `epub:` to `examples/demo.qmd`'s and `examples/book/_quarto.yml`'s
      formats; render both in `tests/run-tests.sh`; `.epub` is already in
      `CAPTURE_EXTS` (`run-tests.sh:171`).
- [ ] T3 — `tests/epubindex.py`: open an `.epub` with `zipfile`, read
      `META-INF/container.xml` → `content.opf` → the manifest's XHTML
      documents, hand each to `htmlindex.parse`, and expose the index sections,
      entry rows and locator hrefs the checks read. Its header says where it
      reads from and what it holds, per the suite-readers doctrine; it produces
      no expected values.
- [ ] T4 — the AC1–AC4 checks, each proven able to fail by a planted defect
      that varies form as well as location: T1's routing reverted (no section);
      a locator href pointed at an id no document carries (AC2); `folded`
      forced true for EPUB (AC3); a `qi-` id injected into the gfm render
      (AC4). Watch the M41/M44/M45 residue lesson on AC4 — the demo's prose
      prints filter strings as content a reader is meant to see.
- [ ] T5 — the hand-derived manifest for the book's two EPUB index sections,
      from the `.qmd` sources under `run-tests.sh`'s ORACLE RULE, never from
      the rendered artifact.
- [ ] T6 — docs: new `site/epub.qmd` + `site/_quarto.yml` nav; edit README,
      `site/index.qmd`, `site/output.qmd`, `site/back-end-differences.qmd`,
      `site/other-formats.qmd`; `CHANGELOG.md`; `cairn/DESIGN.md` Architecture
      (the format tests in the `core.lua` bullet, and line 366's "Every other
      format — beamer, revealjs, epub, gfm" sentence).
- [ ] T7 — the `tests/sitecheck.py` clause for `epub.qmd`'s two claims and the
      `two back-ends` sweep, each with a planted defect showing it red.

## Work log

- 2026-08-28: created by /milestone-plan, promoting the candidate row "An EPUB index, or whatever one can be" (added 2026-08-27, user request), whose promotion condition — a reading of what an EPUB reader can do with an index and of what Pandoc's EPUB writer will carry — was met by the plan-gate probes; the row is absorbed and removed.
- 2026-08-28: criteria audit ran in FULL mode (user-facing tier) and returned one finding — a drafted AC3 clause promising "no per-chapter sidecar record is written during the render" is unobservable, the suite rendering the same fixture to HTML in the same tree; fixed at the gate by replacing it with a bounded sweep of the captured warning stream for the fold sentence. The audit ran in-session, not in a fresh-context [O] reader: this session carries a standing instruction not to spawn subagents.
- 2026-08-28: plan gate chose a distinct `builds_ast_index` predicate over widening `is_html()` to match epub because a scratch probe showed the widening engages the sidecar store on a merged single-process book, folding both declared indexes and drawing three reports that say "an HTML book aggregates its chapters through a per-chapter record", which is false of EPUB; falsified by evidence that Quarto renders an EPUB book per chapter rather than in one Pandoc process.
- 2026-08-28: plan gate chose a thin `epubindex.py` over `htmlindex.py` rather than a standalone EPUB reader because the EPUB's XHTML parses with the existing structural reader and the demo's 41 entry rows came back identical to the HTML render's; falsified by an EPUB writer change producing markup `htmlindex.py` mis-parses.
- 2026-08-28: plan gate chose a hand-derived manifest over comparing the EPUB index against the PDF book's index because the M30 and M33 lessons put engine and font differences in a PDF's text layer; falsified by an extraction shown engine-neutral, which is the existing version-portability row's own promotion condition.

## Decisions

## Review
