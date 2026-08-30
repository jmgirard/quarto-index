<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M60: An HTML book's first render places each index where its author asked

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Branch/PR:** `m060-book-first-render-placement` — https://github.com/jmgirard/quarto-index/pull/60

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

- [x] AC1. A new book fixture declares an index no marker names, carries
      placement markers in two different chapters and no duplicate marker, and
      ends with a chapter carrying no marker. Rendered from an empty store, each
      of its pages carries an index section for exactly the indexes the markers
      in that chapter place — the first declared index for a marker naming none
      — and no page carries a section for the index no marker names. Evidence:
      each page's index sections identified by declared title and heading id,
      not by a count, over every page of the rendered output. `examples/book/`,
      rendered from an empty store, still carries in `last.html` the same three
      sections it carries today, identified the same way.
- [x] AC2. A second render of that fixture, over the store the first left,
      carries a section for the index no marker names on exactly one page, that
      of the last chapter that places an index. Evidence: the same per-page
      identification of sections by declared title and heading id.
- [x] AC3. The first render's log carries exactly one report naming the index
      that was not placed and saying a further render will place it. Evidence:
      the captured first-render log, matched on the report's stem and its
      occurrence counted.
- [x] AC4. In a book whose store holds a record at a superseded version, one
      `quarto render` draws the "written by a different version" report once for
      each chapter that builds an index. Evidence: that report's count in the
      captured log, against a placing-chapter count hand-derived from the
      fixture with its arithmetic in the check's comment; run once with the
      stale record in a placing chapter and once with it in a chapter that
      places nothing, on a fixture whose placing-chapter count differs from its
      chapter count.
- [x] AC5. A stored record whose `xrefs` field is a number leaves the render
      exiting 0, names that chapter in the report for a record that could not be
      read, and leaves the book still printing the indexes the remaining
      chapters' records file marks in — those indexes named individually, not
      counted. The plant carries the store version read from the filter's own
      constant, its unplanted copy is shown to be accepted, and the check is
      shown red with the `xrefs` type test deleted — one deletion, not a move.
- [x] AC6. A fixture reaches a stored record splitting its marks between a
      declared index and one the book no longer declares, both carrying a sort
      key for one printed level path whose two keys collate into different
      letter groups. The rendered page shows that path under the letter group
      the declared index's own key gives it, and after a named neighbour under
      that key. The check is shown red against the merge order that stood before
      M55's gate fix.
- [x] AC7. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0
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
- [x] T3. Move the superseded-version report out of `store_read`
      (`book.lua:411-430`) so it is drawn by the chapters that build an index;
      add the two-position stale-record probe and its hand-derived count.
- [x] T4. Suite checks for AC1, AC2 and AC3: render the new fixture from an
      empty store, identify each page's index sections by declared title and
      heading id, render a second time, assert the deferral report's count, and
      pin `examples/book/`'s own first render by the same identification.
- [x] T5. Reorder `valid_record` so the `mark.xrefs` type test (`book.lua:289`)
      precedes the loop (`book.lua:278`); plant a record whose `xrefs` is a
      number, with the version read from the filter's constant; assert the
      report identity and the surviving render, and show the check red with the
      type test deleted.
- [x] T6. Sort-key merge-order fixture and check for AC6, shown red against the
      pre-fix order.
- [x] T7. Update `site/books.qmd:39` and `site/named-indexes.qmd:87-88` for the
      first-render wait, add the `CHANGELOG.md` entries, and strike KI167, KI168,
      KI169 and KI171 from `cairn/DESIGN.md` with their candidate row rewritten.

## Work log

- 2026-08-29: created by /milestone-plan.
- 2026-08-29: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader; returned twelve findings, ten applied to the criteria before writing (fixture shape stated in AC1; section identity replacing counts in AC1/AC2; "places an index" in AC2; instrument-bound oracle clause dropped and two stale-record positions added in AC4; store version read from the constant, unplanted copy proven, single-deletion probe in AC5; observable named in AC6; the untouched-fixture clause added to AC1), one moved to T2 (value-free scan stem), one accepted as stated (AC5's function name dropped).
- 2026-08-29: plan gate chose deferring the unplaced-index section to a later render over always placing it in the book's final chapter, because the latter reverses M55's rule that every index section sits in a chapter its author asked for one in; falsified by an author reporting the missing first-render section as worse than a section in a chapter they did not mark.
- 2026-08-29: implementation gate chose recording, in each chapter's own stored record, whether the store held a record for every other chapter when it rendered — the book's last chapter reads the placing chapter's value rather than inferring a first render — and chose running AC4's two stale-record positions as one whole-book render and one single-chapter render, so the report count equals the chapters that build an index in both.
- 2026-08-29: T1 — `examples/book-placement/` added: four chapters, markers in the first and third, a marker-free fourth, three declared indexes of which `gamma` is named by no marker, and eight terms no two of which share a printed path. Rendered from an empty store against the current filter it reproduces the defect: `index.html` carries sections for `alpha`, `beta` and `gamma`, and a second render leaves `alpha` alone there.
- 2026-08-29: T2 — a chapter takes on an index no marker names only when the store already holds a usable record for every chapter after it, read before the chapter writes its own and carried in that record as `later`; the book's last chapter reads the placing chapter's value and reports a deferred section once. The gate asks only about the chapters that render after, so a refused record in an earlier chapter no longer costs the section M55-AC5 requires. warn-distinct's message count 77 → 78. `examples/book-placement/` renders `alpha` and `beta` alone with one report on the first render and `gamma` on the third chapter on the second; `examples/book/` is unchanged. Suite green, 486 checks.
- 2026-08-29: T3 — `store_read` hands the chapters whose record was refused for version skew back to its caller, and each chapter that builds an index reports them; the unreadable-record report stays where it was. AC4's two positions added over `examples/book-placement/`: the record in the chapter that places nothing and renders last, whole book rendered, expects 2, and the record in a placing chapter with one chapter rendered expects 1, each hand-derived in the check's comment. The count discriminates: with the report back inside `store_read` the first run draws 3, once per chapter rendered. Suite green, 493 checks.
- 2026-08-29: T4 — landed in the same suite section as T3's probe rather than after it, since both read the same two renders of the fixture: `check_book_sections` reads every page of a rendered book by page, section id and declared title against a hand-written manifest, over the first render and the second; the deferral report is counted at 1 and 0 and its index named; both renders' whole warning sets are accounted for at 3 and 2; and `examples/book/`'s own first render is pinned by its three section ids with no deferral.
- 2026-08-29: T5 — the `mark.xrefs` type test now precedes the loop that walks the field. A record whose `xrefs` is a number, planted from `one.qmd`'s own record with its version read from the filter's constant, leaves `quarto render last.qmd` at exit 0, draws the unreadable-record report once naming `one.qmd`, and leaves `main` and `places` printed; the same record unplanted is accepted and all three print. Under `--self-test` the same record against a filter with those three lines deleted and nothing moved takes the render down with `attempt to index a number value` at `valid_record`. Suite green: 496 plain, 945 with `--self-test`.
- 2026-08-29: T6 — a planted `one.qmd` record splits its marks between `main` and a name the book does not declare and carries a key for the printed path `Beta` under each, `Zulu Beta` and `Alpha Beta`; the rendered page files `Beta` under `Z` behind `Zeta` and under no other group. Under `--self-test` the same record against a filter whose fold sorts both names in one run puts it under `A`, and the same reader reports it. Suite green: 498 plain, 948 with `--self-test`.
- 2026-08-29: T7 — both documentation pages now say an index no marker names waits for a second render where the last marker is not in the book's last chapter, and that nothing else does; three `CHANGELOG.md` entries added under Output for the deferred section, the version-skew report's new count, and the refused `xrefs` field. KI167, KI168, KI169 and KI171 struck from `cairn/DESIGN.md`; KI170 stays, being out of scope. No candidate row to rewrite — the row naming those four was consumed when M60 was planned. Suite green: 498 plain, 948 with `--self-test`.
- 2026-08-29: all seven tasks done; `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0 over the branch, 498 and 948 checks. Status review.
- 2026-08-29: review gate fixes applied, suite re-running: a record with no `later` field is read as no answer rather than as "did not have the picture", so a store written before this milestone no longer draws a deferral report for a section already on the page; the list shadowing the new `later` boolean inside `html_book` renamed; and KI168 restored to `cairn/DESIGN.md`, corrected — M55's review F4 is `fold_undeclared`'s report, not the version-skew one this milestone moved.
- 2026-08-30: review evidence recorded for all seven criteria over the fixed tree, 498 checks plain and 948 with `--self-test`, both exit 0; consistency gate clean; three fixed at the gate, four rejected, six deferred.

## Decisions

## Review

Reviewed 2026-08-30 over `ebadc75` (the gate fixes below included). Every
figure here is from `tests/run-tests.sh` run fresh on this tree after those
fixes: 498 checks plain, 948 with `--self-test`, both exit 0.

### Acceptance criteria

- **AC1.** `examples/book-placement/` declares `alpha`, `beta` and `gamma`,
  carries markers in `index.qmd` and `three.qmd` alone and ends with the
  marker-free `four.qmd`. Rendered from an empty store, `check_book_sections`
  reads all four pages and finds two generated sections, each matching the id
  and declared title a hand-written manifest names, `gamma` on no page. The
  same reader over `examples/book/`'s own first render finds
  `['qi-index-main', 'qi-index-people', 'qi-index-places']` on `last.html`, in
  order, and no deferral. Both checks pass.
- **AC2.** A second render over the store the first left puts three sections
  across the four pages by the same id-and-title manifest, `gamma` on
  `three.html` — the last chapter that places an index — and on no other page.
  Passes.
- **AC3.** The captured first-render log carries the deferral report exactly
  once, matched on its value-free stem, naming `gamma`; the second render
  carries it zero times, and both renders' whole warning sets are accounted
  for at 3 and 2. Passes.
- **AC4.** Two runs of the version-skew probe, each expectation hand-derived
  in the check's comment: the stale record in the marker-free `four.qmd` with
  the whole book rendered draws 2 (two of four chapters build an index), and
  the stale record in the placing `three.qmd` with `index.qmd` alone rendered
  draws 1. 2 is neither the chapter count (4) nor one report for the book, so
  the pair separates once-per-building-chapter from once-per-rendered-chapter.
  Both name the refused chapter. Passes.
- **AC5.** A record whose `xrefs` is a number, planted from `one.qmd`'s own
  record with the version read from the filter's constant, leaves the render
  at exit 0, draws the unreadable-record report once naming `one.qmd`, and
  leaves `main` and `places` printed by name; the same record unplanted is
  accepted and all three print. Under `--self-test`, with the three-line
  `xrefs` type test deleted and nothing else changed, the render dies at
  `valid_record` indexing a number. All passing.
- **AC6.** A planted `one.qmd` record splits its marks between `main` and a
  name the book no longer declares, both carrying a key for the printed path
  `Beta`; the page files `Beta` under `Z`, behind `Zeta`, which is the group
  the declared index's own key gives it. Under `--self-test`, against the
  pre-M55 merge order the stale name's key wins and the same reader reports
  the term under the wrong group. Passes.
- **AC7.** `tests/run-tests.sh` exits 0 at 498 checks and
  `tests/run-tests.sh --self-test` exits 0 at 948, both re-run over this tree
  after the gate fixes.

### Consistency gate

`cairn_validate.py` exits 0, every check PASS and every advisory OK, run again
over the completed review edits. No `DESIGN.md` principle changed — only its
Known issues section — so `cairn_impact.py` does not apply. The `generic`
profile names no toolchain checks, so that half of the gate is a no-op.

### Review findings

Three fresh-context lenses (executable surface touched). Prior-review returned
none, its probe finding no real inline review threads on the repo at all.
Blame-history returned two, neither a defect. The diff-bug lens returned
eleven.

**Fixed at the gate** (`ebadc75`):

- **F2.** A record with no `later` field — every record a pre-M060 version
  wrote — was read as "this chapter did not have the picture", so rendering
  the book's last chapter alone over an existing store drew a deferral report
  for a section already on the page, and repeated it on every such render.
  Absent is now read as no answer, which draws no report; only the field
  written `false` does.
- **F4.** KI168 was struck as fixed, but M55's review F4 (recovered from git)
  is about `fold_undeclared`'s report for an index name the book no longer
  declares, not the version-skew report this milestone moved. That report is
  unchanged and still fires once per rendered chapter. KI168 restored to
  `DESIGN.md`, its wording corrected to name the report it is actually about.
- **F7.** `local later` in `html_book`'s marker-position block shadowed the
  milestone's own new `later` boolean in the same function; renamed `after`.

**Rejected:**

- **F8** (AC4's arithmetic is fragile). Refuted against the check: run (1)'s
  expectation of 2 counts *chapters that build an index*, which adoption does
  not change, so the plant's effect on adoption cannot move it. That run (2)
  cannot discriminate alone is what the comment's closing sentence already
  says.
- **F6** (Scope's second bullet says "a record this version cannot read" where
  the work moved the version-skew report). AC4 names that report exactly and
  the work matches it; the Scope prose is loose, not the work.
- **B1** (M55 said "per placing chapter", the code says "builds"). Verified
  synonymous: `builds` is true exactly when this chapter is some index's
  placing chapter.
- **B2** (no written policy on when a store-schema addition needs a version
  bump). The F2 fix makes the optional field correct without one; there is no
  defect to record.

**Deferred** — none demonstrates an acceptance criterion failing; filed as
Known issues with a candidate row at the post-merge hygiene pass:

- **F1.** The last chapter infers whether the placing chapter adopted from
  that chapter's `later` flag rather than from the adoption itself, and the
  two differ when a chapter's stored record still claims a marker it no longer
  has: the section is silently absent for one render, with no report. Self-
  heals on the next render. The fix is to record the adoption decision itself.
- **F3.** Two chapters can both adopt the same unplaced index when a later
  chapter gains a marker between renders. Reproduces identically on the
  default branch; not introduced here.
- **F5.** A version-skewed record is now reported zero times in a book where
  no chapter builds an index, where before it was reported once per rendered
  chapter.
- **F9.** `later_recorded` decodes and validates every record after the
  current chapter, making the store read quadratic in chapter count.
- **F10.** Both `fold_undeclared` report-count assertions sit behind
  single-chapter renders, where either counting rule gives 1 — the gap that
  let F4 through.
- **F11.** A chapter after the last placer that never writes a usable record
  defers the section on every future render, under a report promising the next
  render will place it.
