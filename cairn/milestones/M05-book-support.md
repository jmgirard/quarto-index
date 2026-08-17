# M05: Multi-chapter book support

- **Status:** review
- **Priority:** normal
- **Depends on:** M04
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP3, GP4
- **Branch/PR:** m05-book-support / https://github.com/jmgirard/quarto-index/pull/5

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

- [x] AC1: Rendering the book fixture with `quarto render --to html`
      produces exactly one index across the site: the marker chapter's entry
      list matches a hand-derived full-index manifest representing every
      chapter's marks; a recursive structural sweep over every `*.html` file
      under the book output directory finds no index section or entry list
      on any other page; and no sidecar-store file exists anywhere under the
      output directory (recursive sweep by store filename pattern).
- [x] AC2: Every locator link in the book fixture's index resolves relative
      to its containing page — target file and anchor id exist, verified
      structurally over every `*.html` file (recursively) in the book
      output. The fixture's marks vary anchor form (plain, inside a heading,
      author-written id, invisible `entry=`-only) and location (three or
      more chapters, one chapter in a subdirectory, one mark in the marker
      chapter itself).
- [x] AC3: A term marked in more than one chapter appears in the book index
      as one entry whose locators point at the contributing chapters in book
      chapter order, document order within a chapter (hand-derived manifest
      row carrying locator hrefs).
- [x] AC4: A cross-reference whose target entry is contributed only by
      another chapter's marks links to that entry's id on the index page
      (hand-derived manifest row), with no spurious warning for the
      cross-file target; a cross-reference to a target no chapter
      contributes renders as unlinked text without breaking the render,
      exactly as a single document does.
- [x] AC5: Rendering the book fixture with `quarto render --to pdf`
      succeeds, and the PDF's bounded index slice contains each fixture term
      followed by a page-number pattern, per a hand-derived term manifest —
      pinning that the LaTeX book path aggregates entries from every
      chapter (page numbers never copied from output).
- [x] AC6: The no-marker book fixture (marks, no marker chapter) renders to
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
- [x] T5: Missing-marker warning via the last-in-order chapter's run (once
      per full render; it also fires when that chapter alone is re-rendered,
      since a partial render is not detectable — amended at review).
- [x] T6: Suite: multi-file structural resolution in `tests/htmlindex.py`
      (row format extended to carry locator hrefs), book HTML checks
      (AC1–AC4, AC6), PDF book check with bounded slice, store-footprint
      sweep; wire into `tests/run-tests.sh`.
- [x] T7: Docs: README book section (setup, marker-chapter-last
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
- 2026-08-17: T6 done — book checks wired into tests/run-tests.sh (store-name pin, exhaustive href manifest, recursive one-index sweep, store-footprint sweep with a positive control, cross-file link resolution, fixture-axis coverage read off the render, cross-reference id check, no-marker book, book PDF); the missing-marker report joined the warning-discrimination self-test. Suite 65 -> 73 checks, green; --self-test green.
- 2026-08-17: the book PDF check counts PAGES rather than printed locator tokens — makeindex collapses three consecutive pages into a range (`Shared Term, 3-5`), which a token count read as one locator and failed on.
- 2026-08-17: T7 done — README `## Books` section (marker chapter, marker-chapter-last, cross-chapter locators and cross-references, PDF needs nothing, full-render contract, store location) and DESIGN.md architecture updated for the book path.
- 2026-08-17: all tasks done; suite green at 73 checks (65 at the merge base, +8 book checks) and green with --self-test; cairn_validate clean. Status -> review.
- 2026-08-17: review fan-out — [S] blame-history and [S] prior-review lenses returned no findings; [O] diff-bug returned 13, all triaged at the gate, all actioned at the user's selection ("fix everything now").
- 2026-08-17: fixed at the gate — F1 store write guarded whole (an ordinary file where the store directory goes aborted the render; IP2), F2 this chapter's marker flag no longer re-derived from disk (a failed write produced no index and a warning naming chapter `nil`), F3 marker-not-last warning and README now state the entries are one render behind and their links can be dead, F4 store records carry a version and are shape-validated before use, F5 `book.render` paths normalized like input/output paths, F6 a book page whose context cannot be built now warns instead of silently reverting to a per-chapter index, F7 a marker in a book with no marks warns and places nothing instead of emitting an empty index section, F10 the PDF term check anchored on word boundaries, F12 README's gitignore claim narrowed to what Quarto actually scaffolds, F13 the id walk skipped on pages that need no anchors.
- 2026-08-17: F11 (URL escaping) closed as not fixable at this layer — verified the filter emitted `later%20chapter.html` and output carried `later chapter.html`, matching Quarto's own `./later chapter.html`; the escape was removed rather than left as code whose purpose never takes effect, and the limitation became a candidate row.
- 2026-08-17: F9 answered with the examples/book-order fixture (marker in the first chapter, a second marker chapter, a space in a chapter filename) plus second-render, stale-chapter, unreadable-record and unwritable-store checks; the two store reports joined the warning-discrimination self-test. Suite 73 -> 79 checks, 89 with --self-test.
- 2026-08-17: F8 — T5's "no warning on partial renders" did not hold and is not achievable (a partial render is not detectable); task text amended at the user's selection to describe what ships.

## Decisions

## Review

Evidence gathered 2026-08-17 on branch m05-book-support (PR #5) by running
`tests/run-tests.sh --self-test` from a wiped fixture state (both book output
directories and both `.quarto/` store directories removed first, so no record
from an earlier render could stand in for one this run produced): 81 ok lines,
exit 0. Per-criterion evidence below.

- AC1: `M05-AC1/AC3` — the marker chapter's index matched all 10 hand-derived
  manifest rows in order. `M05-AC1/AC2` — the index section id appears on
  exactly one of the 4 recursively discovered pages (`last.html`) and index
  entry markup on no other page; 4 store files written under
  `examples/book/.quarto/` (the positive control: a filter that wrote no store
  at all fails here) and 0 anywhere under `_book/`. `M05-AC1` — the store name
  the sweep looks for is string-compared against the filter's own constants.
- AC2: `M05-AC1/AC2` — all 9 locator links resolved to an existing id on an
  existing page, resolved relative to the page carrying the index. The axis
  coverage is read off the render rather than recalled: locators reach 3
  distinct chapter pages, one in a subdirectory (`sub/two.html`), one within
  the index's own page (`#qi-mark-1`), one via an id of the author's own
  (`one.html#gamma-anchor`), one via a heading mark whose anchor is verified to
  sit outside the heading, and the invisible mark's entry text is verified
  absent from the chapter body.
- AC3: `M05-AC1/AC3` — the `Shared Term` row carries
  `index.html#qi-mark-1 one.html#qi-mark-2 sub/two.html#qi-mark-1`: one entry,
  three locators, in book chapter order. The manifest is exhaustive and
  compared in order, so a locator in the wrong order fails as a row mismatch.
- AC4: `M05-AC4` — `Delta`'s cross-reference links to `#qi-entry-1`, read
  structurally as the id of the `Alpha` entry that only `index.qmd`
  contributes; `Epsilon`'s target, which no chapter contributes, is
  `see-plain` (unlinked) in the exhaustive manifest and the render completed.
  `M05-AC4` — the whole book render emitted no warning line at all.
- AC5: `M05-AC5` — the book rendered to PDF and its bounded index slice (text
  after the `Index` heading) carries all 8 derived terms, each followed by the
  hand-derived number of pages, plus both cross-reference strings verbatim.
  Page numbers are never derived: the manifest states page COUNTS (one per
  locator-contributing mark), and the check expands makeindex's ranges before
  counting.
- AC6: `M05-AC6` — the no-marker book rendered, no index section or entry
  markup on either page, both marked terms still visible where written, and
  the missing-marker report occurs exactly once in the full render, its pinned
  text including the `qi-index-here` class an author needs. The self-test's
  warning-discrimination probe confirms that check fails on a log with the
  report removed and on one with it duplicated, and passes as rendered.

Independent review (three fresh-context lenses, none having seen the
implementation): the [S] blame-history and [S] prior-review lenses each
returned no findings — the first confirming M04's `noautomatic` machinery and
M03's anchor-outside-heading rule untouched and both test-harness signature
changes defaulting to prior behavior, the second finding no archived `## Review`
finding or candidate row reintroduced (the GitHub inline-comment probe returned
empty, so per the probe gate the PR threads were not walked). The [O] diff-bug
lens returned 13 findings; all 13 were triaged at the approval gate and every
one was actioned at the user's selection.

Findings and disposition — F1 unguarded store-directory creation aborting the
render (fixed; reproduced first: an ordinary file where the store directory
goes killed the render at chapter 1), F2 the marker flag re-derived from disk
so a failed write produced no index and a warning naming chapter `nil`
(fixed), F3 marker-not-last entries stale with dead links, understated by the
warning and contradicted by the README (fixed in both), F4 records trusted on
shape with no version (fixed: version + shape validation), F5 `book.render`
paths not normalized like input and output paths (fixed), F6 every
book-detection failure silently restoring the per-chapter index (fixed: warns),
F7 a marker in a book with no marks emitting an empty index section (fixed;
reproduced first), F8 T5's "no warning on partial renders" unachievable (task
text amended at the user's selection), F9 the staleness and ordering dimension
unpinned by the suite (fixed: the `examples/book-order` fixture and six
hardening checks), F10 the PDF term search unanchored (fixed), F11 locator
hrefs unescaped (closed as not fixable at this layer and recorded as a
candidate row — verified directly that a filter-emitted `later%20chapter.html`
reaches output as `later chapter.html`, matching Quarto's own
`./later chapter.html`), F12 the README overstating what Quarto's scaffolding
ignores (fixed), F13 minor notes (id walk skipped on pages needing no anchors;
store pruning and the unlisted-page fallback recorded as candidate rows).

Post-fix verification: `tests/run-tests.sh --self-test` exit 0, 89 checks (79
without the self-test), from a wiped fixture state; `cairn_validate` exit 0.

Consistency gate: `cairn_validate` all checks passed, exit 0 (coverage
complete and binding criteria among them). Profile `generic` names no
toolchain consistency checks, so that half is a clean no-op. No DESIGN.md
principle text changed (the diff touches only the Architecture section), so
`cairn_impact` does not apply.

