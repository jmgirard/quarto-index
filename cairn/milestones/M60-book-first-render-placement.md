<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M60: An HTML book's first render places each index where its author asked

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Branch/PR:** `m060-book-first-render-placement`

## Goal

An HTML book whose placement markers sit in different chapters prints no index
section its author did not ask for, and a malformed stored record no longer
takes the render down.

## Scope

Surface tier: **user-facing** — every defect here is something an author sees
in a rendered book or a failed render.

**In:**

- An index no marker names is taken on only by a chapter whose store holds a
  current record for every chapter the book renders. On a first render no
  chapter has that picture, so the section is not printed and the book's last
  chapter reports that a further render will place it. M55's placement rule —
  the section goes to the last chapter that places one — is unchanged; this
  adds the precondition under which a chapter may conclude it is that chapter.
- The report for a record this version cannot read is drawn once per chapter
  that builds an index, which is what M55 decided and not what it shipped.
- A stored record whose `xrefs` field is not a table is refused before it is
  iterated, so it no longer raises outside any `pcall` (`book.lua:278` runs
  ahead of the type test at `book.lua:289`).
- A new book fixture whose markers sit in two chapters, with a marker-free
  chapter after the last placing one and a declared index no marker names.
- A fixture reaching the sort-key merge order M55 fixed at its review gate,
  which shipped with no regression test.

**Out:**

- Rewording the duplicate-marker report's "and a book has a single index"
  tail → stays a known issue; the plan gate re-posed M55's rejection and the
  user kept it.
- Giving the cross-chapter pairing reports a word for the chapter as well as
  the index → stays a known issue; it needs a superseding entry against the
  scope-word decision, which this milestone does not open.
- Pruning store records for chapters no longer in the book, ordering the
  declared-key map, and what a page outside `book.render` should do → the
  book sidecar-store candidate row.
- The PDF and EPUB back-ends: a PDF book is one Pandoc process and has no
  first-render placement problem.

## Acceptance criteria

- [ ] AC1. A new book fixture declares an index no marker names, carries
      placement markers in two different chapters and no duplicate marker, and
      ends with a chapter carrying no marker. Rendered from an empty store, each
      of its pages carries an index section for exactly the indexes the markers
      in that chapter place — the first declared index for a marker naming none
      — and no page carries a section for the index no marker names. Evidence:
      each page's index sections identified by declared title and heading id,
      not by a count, over every page of the rendered output. `examples/book/`,
      rendered from an empty store, still carries in `last.html` the same three
      sections it carries today, identified the same way.
- [ ] AC2. A second render of that fixture, over the store the first left,
      carries a section for the index no marker names on exactly one page, that
      of the last chapter that places an index. Evidence: the same per-page
      identification of sections by declared title and heading id.
- [ ] AC3. The first render's log carries exactly one report naming the index
      that was not placed and saying a further render will place it. Evidence:
      the captured first-render log, matched on the report's stem and its
      occurrence counted.
- [ ] AC4. In a book whose store holds a record at a superseded version, one
      `quarto render` draws the "written by a different version" report once for
      each chapter that builds an index. Evidence: that report's count in the
      captured log, against a placing-chapter count hand-derived from the
      fixture with its arithmetic in the check's comment; run once with the
      stale record in a placing chapter and once with it in a chapter that
      places nothing, on a fixture whose placing-chapter count differs from its
      chapter count.
- [ ] AC5. A stored record whose `xrefs` field is a number leaves the render
      exiting 0, names that chapter in the report for a record that could not be
      read, and leaves the book still printing the indexes the remaining
      chapters' records file marks in — those indexes named individually, not
      counted. The plant carries the store version read from the filter's own
      constant, its unplanted copy is shown to be accepted, and the check is
      shown red with the `xrefs` type test deleted — one deletion, not a move.
- [ ] AC6. A fixture reaches a stored record splitting its marks between a
      declared index and one the book no longer declares, both carrying a sort
      key for one printed level path whose two keys collate into different
      letter groups. The rendered page shows that path under the letter group
      the declared index's own key gives it, and after a named neighbour under
      that key. The check is shown red against the merge order that stood before
      M55's gate fix.
- [ ] AC7. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0
      over the branch.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T2, T4
- AC3 → T2, T4
- AC4 → T3
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks

- [x] T1. Add `examples/book-placement/`: four chapters, markers in the first
      and third, a marker-free fourth, and three declared indexes of which one
      is named by no marker. Give every mark a term no other mark in the
      fixture indexes, so no sort-key path is shared by accident.
- [x] T2. In `html_book` (`book.lua:745`), gate the unplaced-index adoption
      block (`book.lua:275-286` within it) on the store holding a current record
      for every file in `ctx.chapters`; draw the deferral report from the book's
      final chapter, which is the one chapter that always has the picture.
      Register the new message with `tests/scans/warn-distinct.py` by a
      value-free stem, and keep it a prefix of no existing message.
- [ ] T3. Move the superseded-version report out of `store_read`
      (`book.lua:411-430`) so it is drawn by the chapters that build an index;
      add the two-position stale-record probe and its hand-derived count.
- [ ] T4. Suite checks for AC1, AC2 and AC3: render the new fixture from an
      empty store, identify each page's index sections by declared title and
      heading id, render a second time, assert the deferral report's count, and
      pin `examples/book/`'s own first render by the same identification.
- [ ] T5. Reorder `valid_record` so the `mark.xrefs` type test (`book.lua:289`)
      precedes the loop (`book.lua:278`); plant a record whose `xrefs` is a
      number, with the version read from the filter's constant; assert the
      report identity and the surviving render, and show the check red with the
      type test deleted.
- [ ] T6. Sort-key merge-order fixture and check for AC6, shown red against the
      pre-fix order.
- [ ] T7. Update `site/books.qmd:39` and `site/named-indexes.qmd:87-88` for the
      first-render wait, add the `CHANGELOG.md` entries, and strike KI167, KI168,
      KI169 and KI171 from `cairn/DESIGN.md` with their candidate row rewritten.

## Work log

- 2026-08-29: created by /milestone-plan.
- 2026-08-29: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader; returned twelve findings, ten applied to the criteria before writing (fixture shape stated in AC1; section identity replacing counts in AC1/AC2; "places an index" in AC2; instrument-bound oracle clause dropped and two stale-record positions added in AC4; store version read from the constant, unplanted copy proven, single-deletion probe in AC5; observable named in AC6; the untouched-fixture clause added to AC1), one moved to T2 (value-free scan stem), one accepted as stated (AC5's function name dropped).
- 2026-08-29: plan gate chose deferring the unplaced-index section to a later render over always placing it in the book's final chapter, because the latter reverses M55's rule that every index section sits in a chapter its author asked for one in; falsified by an author reporting the missing first-render section as worse than a section in a chapter they did not mark.
- 2026-08-29: implementation gate chose recording, in each chapter's own stored record, whether the store held a record for every other chapter when it rendered — the book's last chapter reads the placing chapter's value rather than inferring a first render — and chose running AC4's two stale-record positions as one whole-book render and one single-chapter render, so the report count equals the chapters that build an index in both.
- 2026-08-29: T1 — `examples/book-placement/` added: four chapters, markers in the first and third, a marker-free fourth, three declared indexes of which `gamma` is named by no marker, and eight terms no two of which share a printed path. Rendered from an empty store against the current filter it reproduces the defect: `index.html` carries sections for `alpha`, `beta` and `gamma`, and a second render leaves `alpha` alone there.
- 2026-08-29: T2 — a chapter takes on an index no marker names only when the store already holds a usable record for every chapter after it, read before the chapter writes its own and carried in that record as `later`; the book's last chapter reads the placing chapter's value and reports a deferred section once. The gate asks only about the chapters that render after, so a refused record in an earlier chapter no longer costs the section M55-AC5 requires. warn-distinct's message count 77 → 78. `examples/book-placement/` renders `alpha` and `beta` alone with one report on the first render and `gamma` on the third chapter on the second; `examples/book/` is unchanged. Suite green, 486 checks.

## Decisions

## Review
