# M05: Multi-chapter book support

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M04
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP3, GP4
- **Branch/PR:** m05-book-support

## Goal

Make index marks work in Quarto book projects: one aggregated HTML index built
from every chapter at the M04 marker's chapter, cross-file locator links, and
the already-working PDF book path pinned by fixtures.

## Scope

Surface tier: **user-facing** — book projects are the primary real-world use
of an index, for the extension's community audience.

**In:** book detection; per-chapter sidecar store under the project directory
(never the output directory); chapter-side suppression of the per-chapter
index (the shipped behavior appends a partial index to every chapter — the
defect this fixes); aggregation at the marker chapter in book order with
cross-file locator hrefs; cross-reference resolution deferred to aggregation;
warn-once when a book has marks but no marker chapter (mechanism: every
chapter run knows the chapter list and its own position; the marker chapter
registers itself in the store; the last-in-order chapter warns if marks exist
and no current chapter registered); book fixtures for HTML and PDF; docs
(book setup, marker-chapter-last recommendation, full-render staleness
contract, store gitignore guidance).

**Out:** staleness detection machinery → rejected at the gate, full render is
the documented contract. Chapter-based locator labels → candidate row (gate
kept numeric locators). epub/other formats keep passing through (IP2) →
future back-end work. Letter groups, sort keys → existing candidate rows.

## Acceptance criteria

- [ ] AC1: Rendering the book fixture with `quarto render --to html`
      produces exactly one index across the site: the marker chapter's entry
      list matches a hand-derived full-index manifest representing every
      chapter's marks; a recursive structural sweep over every `*.html` file
      under the book output directory finds no index section or entry list
      on any other page; and no sidecar-store file exists anywhere under the
      output directory (recursive sweep by store filename pattern).
- [ ] AC2: Every locator link in the book fixture's index resolves relative
      to its containing page — target file and anchor id exist, verified
      structurally over every `*.html` file (recursively) in the book
      output. The fixture's marks vary anchor form (plain, inside a heading,
      author-written id, invisible `entry=`-only) and location (three or
      more chapters, one chapter in a subdirectory, one mark in the marker
      chapter itself).
- [ ] AC3: A term marked in more than one chapter appears in the book index
      as one entry whose locators point at the contributing chapters in book
      chapter order, document order within a chapter (hand-derived manifest
      row carrying locator hrefs).
- [ ] AC4: A cross-reference whose target entry is contributed only by
      another chapter's marks links to that entry's id on the index page
      (hand-derived manifest row), with no spurious warning for the
      cross-file target; a cross-reference to a target no chapter
      contributes renders as unlinked text without breaking the render,
      exactly as a single document does.
- [ ] AC5: Rendering the book fixture with `quarto render --to pdf`
      succeeds, and the PDF's bounded index slice contains each fixture term
      followed by a page-number pattern, per a hand-derived term manifest —
      pinning that the LaTeX book path aggregates entries from every
      chapter (page numbers never copied from output).
- [ ] AC6: The no-marker book fixture (marks, no marker chapter) renders to
      HTML successfully: no index section on any page (recursive structural
      sweep), every chapter's visible marked terms present per a
      hand-derived visible-terms manifest, and the render log carries the
      missing-marker warning exactly once in a full render, naming how to
      add a marker chapter.

## Coverage

- AC1 → T2, T3, T4, T6
- AC2 → T1, T3, T6
- AC3 → T4, T6
- AC4 → T4, T6
- AC5 → T1, T6
- AC6 → T5, T6

## Tasks

- [x] T1: Book fixtures: `examples/book/` (≥3 chapters incl. one in a
      subdirectory; plain / heading / author-id / invisible marks; a term
      shared across chapters; a cross-file cross-reference; an unresolvable
      cross-reference; marker chapter last) and a no-marker variant;
      hand-derived manifests for index page, locator hrefs, PDF terms,
      visible terms.
- [x] T2: Book detection (`doc.meta.book` + `quarto.project.directory`) and
      per-chapter sidecar store: serialization of mark records (levels,
      xrefs, anchor ids, chapter output href, chapter position), store dir
      under the project directory, records filtered to the current chapter
      list at read time (stale chapters ignored).
- [x] T3: Chapter-side behavior: suppress per-chapter index emission,
      anchors still assigned per M03 rules, marker chapter registers itself
      in the store.
- [x] T4: Aggregation at the marker chapter: read store in book chapter
      order, build the entry tree with the existing builder, cross-file
      locator hrefs, cross-reference resolution deferred to aggregation.
- [x] T5: Missing-marker warning via the last-in-order chapter's run (warn
      once per full render; no warning on partial renders).
- [ ] T6: Suite: multi-file structural resolution in `tests/htmlindex.py`
      (row format extended to carry locator hrefs), book HTML checks
      (AC1–AC4, AC6), PDF book check with bounded slice, store-footprint
      sweep; wire into `tests/run-tests.sh`.
- [ ] T7: Docs: README book section (setup, marker-chapter-last
      recommendation, full-render staleness contract, store gitignore
      guidance); DESIGN.md architecture updated for the book path.

## Work log

- 2026-08-17: created by /milestone-plan.
- 2026-08-17: criteria audit ran in full mode ([O] fresh reader): findings — AC1's positive half unpinned and sweep non-recursive, AC2 missing the location axis and the same-file locator case, AC3's instrument gap (row format carries no hrefs), AC5's locator shape not hand-derivable under the oracle rule, AC6/AC7 undecidable-warning mechanism, deferred cross-reference resolution missing, store footprint unpinned — all fixed in the wording above; staleness policy and placement scope went to the gate.
- 2026-08-17: plan gate chose sidecar store + marker-chapter aggregation over a post-render project script because extensions cannot contribute project scripts, so a script breaks zero-config install (GP3/GP4); falsified by Quarto adding extension-contributed project scripts.
- 2026-08-17: plan gate chose documented full-render staleness contract over detection machinery because partial renders are preview workflow and detection adds freeze/preview edge cases for little value; falsified by users publishing stale indexes from partial renders in practice.
- 2026-08-17: plan gate kept numeric sequence locators over chapter-based labels for consistency with the shipped single-doc index; falsified by reader evidence that numeric locators fail in long books (candidate row records the alternative).
- 2026-08-17: plan chose last-in-order-chapter warning (store registration) over grepping chapter sources for the marker because source-text scanning is fragile (comments, includes); falsified by the store mechanism producing spurious or missing warnings across freeze/partial renders.
- 2026-08-17: implement started on branch m05-book-support.
- 2026-08-17: implement gate — store lives in Quarto's own `.quarto/` scratch directory (already gitignored, invisible to authors) over a visible cache dir needing author setup; falsified by Quarto reclaiming or wiping `.quarto/` between chapter renders.
- 2026-08-17: implement gate kept AC6's warn-and-place-nothing for a marker-less HTML book over appending the index to the last chapter (which is what the PDF book does), because picking the location for the author is the choice the marker exists to make; falsified by authors reporting the warning as an obstacle rather than a fix.
- 2026-08-17: implement gate added a warning naming the chapters that follow the marker chapter over documenting marker-chapter-last alone, because a misplaced marker otherwise yields a quietly short index; not AC-pinned, additive.
- 2026-08-17: T1-T5 done — book fixtures (examples/book, examples/book-nomarker), book detection from `book.render` + `quarto.doc`/`quarto.project`, per-chapter JSON store under `.quarto/quarto-index/`, aggregation at the marker chapter, missing-marker warning from the last chapter. Verified by render: exactly one index section across the four-chapter book (on the marker chapter's page), locators `index.html#qi-mark-2` / `one.html#gamma-anchor` / `sub/two.html#qi-mark-1` / same-page `#qi-mark-1`, cross-file `see` resolved to the target entry id, PDF book unchanged and passing, single-document suite green at 65 checks.
- 2026-08-17: a second marker chapter is refused (first in book order wins, warned) rather than emitting two indexes; not AC-pinned, additive.

## Decisions

## Review
