# M061: A book reports the index section it deferred, doubled, or can never place

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m061-book-deferred-section-reports`

## Goal

An HTML book whose index section is deferred, printed twice, or blocked by a chapter record
that can never be written says so once, naming the index and the chapters it could not read.

## Scope

User-facing tier: the deliverable is what a rendered book prints and what its render log
tells the author.

**In:**

- `book.lua` reads the chapter store once per render, deriving from that pass both the
  usable records and the later chapters whose record this render could not use;
  `later_recorded`'s second full pass over every later record is retired.
- A chapter's record carries what it concluded, not only what it saw: the index names it
  adopted and the later chapters it could not read. Both optional, absent read as no answer,
  at the current `STORE_VERSION`.
- The deferred-section report reads the recorded adoption rather than re-deriving it, names
  the chapters the placing chapter could not read, and drops its promise that a further
  render will place the section.
- A new report, drawn by the book's last chapter, where the records show two chapters
  adopting one index.
- `examples/book-placement/` gains a fifth chapter, so the chapter that gains a placement
  marker between renders is not the chapter that reports the doubling.

**Out:**

- How often a refused or refiled record is reported → M062.
- Preventing the doubling rather than reporting it → new candidate row; it needs a way for a
  chapter to see a marker a later chapter has not yet recorded.
- Pruning records for chapters no longer in the book, the declared-key map's order, and a
  page outside `book.render` → the standing book sidecar-store candidate row.

## Acceptance criteria

- [ ] AC1. With `examples/book-placement/`'s stored record for `five.qmd` planted to claim a
      placement marker for `gamma` that `five.qmd`'s source does not carry, a whole-book HTML
      render prints a generated index section only on the pages, under the ids and with the
      declared titles a hand-derived manifest states — that manifest listing every rendered
      page of the book, a page carrying no section written as its own row — and draws the
      deferred-section report exactly once, that report naming `gamma`. The render emits
      exactly the extension warnings the check names one by one, and exits 0. The same render
      draws the report zero times before this milestone.
- [ ] AC2. Where `four.qmd` gains a placement marker naming `gamma` between two whole-book
      renders of `examples/book-placement/`, the render made after it gains one prints a
      `gamma` section on both `three.html` and `four.html`, and `five.qmd` — neither the
      chapter that gained the marker nor a chapter that printed the section — draws the
      doubled-section report exactly once, that report naming `gamma`; the next whole-book
      render prints `gamma` on `four.html` alone and draws that report zero times. Each
      render exits 0.
- [ ] AC3. Where the store path `examples/book-placement/`'s `four.qmd` record would occupy
      is held by a directory, so that record can never be written, two consecutive whole-book
      HTML renders each draw the deferred-section report exactly once for `gamma`, each
      report naming `four.qmd` among the chapters whose record the render could not read.
      Each render's other extension warnings are enumerated by count and kind in the check —
      the write-failure report `four.qmd` draws for itself and the unreadable-record report
      every chapter draws for it included — and each render exits 0.
- [ ] AC4. A whole-book render over a store whose records all carry the current
      `STORE_VERSION` and neither new field draws the deferred-section report zero times and
      the doubled-section report zero times, and every chapter's terms still print in the
      book's index sections.
- [ ] AC5. The deferred-section report's new grep key is held to a live message by the
      suite's report-key scan, and the assertions M60 pinned hold over the re-derived
      five-chapter fixture: from an empty store the first render prints the sections its
      manifest names and defers `gamma` once, the second render prints `gamma` in
      `three.html` alone and defers nothing, `examples/book/` carries its three sections in
      `last.html` on a first render and defers nothing, and M60's two planted-superseded-record
      runs keep their version-skew counts of 2 and 1. Each render exits 0.
- [ ] AC6. `tests/sitecheck.py claims` holds `site/books.qmd` and
      `site/placing-the-index.qmd` to a claim naming what a book reports when an index
      section is deferred and when one prints twice, and fails on a copy of either page with
      that claim removed.
- [ ] AC7. `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1, T2, T3, T5, T6
- AC2 → T1, T2, T4, T5, T7
- AC3 → T1, T2, T3, T8
- AC4 → T2, T3, T4, T9
- AC5 → T3, T5, T6
- AC6 → T10
- AC7 → T1, T2, T3, T4, T5, T6, T7, T8, T9, T10

## Tasks

- [x] T1. One store pass: `store_read` returns the usable records, the version-refused
      chapters, and the later chapters whose record this render could not use; retire
      `later_recorded` (`_extensions/index/modules/book.lua:439`). `html_book` builds this
      chapter's record in memory, splices it in at its own position, and writes once.
- [x] T2. The record carries `adopted` (index names this chapter took on) and `unseen` (the
      later chapters it could not read); both optional in `valid_record`, absent read as no
      answer, no `STORE_VERSION` bump — a field only a report reads never invalidates another
      chapter's terms.
- [x] T3. The deferred-section report reads the recorded adoption and names the unseen
      chapters; the sentence promising a further render is removed, and the report's new
      value-free key joins the suite's report-key scan (`tests/run-tests.sh:277`), shown red
      against a key matching no live message. (RB tripwire: ip-touching)
- [x] T4. The doubled-section report, drawn by the book's last chapter from the records.
      (RB tripwire: ip-touching)
- [ ] T5. `examples/book-placement/` gains `five.qmd`; `four.qmd`'s prose stops calling
      itself the book's last chapter; every manifest, warning count and comment that fixture
      feeds is re-derived by hand and its arithmetic shown.
- [ ] T6. AC1's check: plant the phantom marker claim in `five.qmd`'s record with one
      substitution, assert the manifest, the report count, the index it names, and the
      enumerated warning total; restore the record; show it red by reverting T3.
- [ ] T7. AC2's check: copy `four.qmd` aside, append the `gamma` marker with one
      substitution, render, assert two `gamma` sections and the report drawn once by
      `five.qmd`; restore, render, assert one section and zero reports; show it red by
      reverting T4.
- [ ] T8. AC3's check: hold `four.qmd`'s store path with a directory, render twice, assert
      the report count, the chapter it names, and the enumerated warnings each render draws;
      show it red by reverting T3's naming of the unseen chapters.
- [ ] T9. AC4's check: strip both new fields from every record of a warm store with one
      pass, render the whole book, assert both reports at zero and the index sections still
      carrying every chapter's terms; show it red by reading a missing field as `false`.
- [ ] T10. `site/books.qmd`, `site/placing-the-index.qmd` and `CHANGELOG.md` state what a
      deferred or doubled section reports now, written against an executed render's own
      output; both claims join the pages' `tests/sitecheck.py claims` files, and each is
      shown red against a copy of its page with the claim removed.

## Work log

- 2026-08-30: created by /milestone-plan.
- 2026-08-30: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader, on the drafted M061 and M062 criteria together. Returned ten findings and six factual corrections; seven fixed at the gate (instrument-bound warning floor, manifest not stated as a page sweep, the retired grep key going vacuous, AC4's incomplete render list, M062's wrong arithmetic and undercounted assertions, M062's non-discriminating control), three posed as gate questions (doubling prevented or reported, the fixture axis, an old record's missing field).
- 2026-08-30: plan gate chose reporting a doubled index section over always sending an unnamed index to the book's last chapter, because the latter reverses M55's placement rule and moves the section out of the chapter placing the book's other indexes; falsified by a mechanism letting a chapter see a placement marker a later chapter has not yet recorded.
- 2026-08-30: plan gate chose a fifth chapter in `examples/book-placement/` over a new book fixture directory, because the axis under test is the distance between the gaining chapter and the reporting one and a fifth fixture adds a render to every suite run; falsified by the re-derivation of that fixture's manifests proving larger than the new-fixture cost.
- 2026-08-30: T1 — one store pass. `store_read` takes this chapter's in-memory record, splices it in at its own position and never reads this chapter's own file, and returns the usable records, the version-refused chapters and the later chapters whose record this render could not use; `later_recorded` is retired. `store_write` takes a built record and runs after the placement is settled, so the chapter records what it concluded and writes once. `record_for_reading` gives the aggregation a copy, so `fold_undeclared` cannot write a folded index name into the store. Suite green, 498 checks, exit 0.
- 2026-08-30: T2 — a record carries `adopted` (the indexes the chapter built a section for, in declared order) and `unseen` (the later chapters whose record it could not use). Both optional in `valid_record` and walked only after their type is tested; absent read as no answer, no `STORE_VERSION` bump. Suite green, 498 checks, exit 0.
- 2026-08-30: T3 — the unplaced-section report reads the placing chapter's recorded `adopted` rather than re-deriving a picture from the store as it now stands, names that chapter and the chapters it could not read (`none` where there were none), and drops the sentence promising a further render would place the section; a record with no `adopted` field draws no report. `later` is no longer written, only still accepted. The report's new value-free key joins the report-key scan, shown red under `--self-test` against a key matching no filter warning. Suite green, 949 checks with `--self-test`, exit 0.
- 2026-08-30: T4 — the doubled-section report, drawn by the book's last chapter from the records' `adopted` lists, once per index carried by more than one chapter and naming them in book order; a record with no `adopted` field is not counted as one of two. Its value-free key joins the report-key scan and the filter's pinned warning count moves 78 → 79. Verified by hand on a scratch copy of the fixture: adding a `gamma` marker to `four.qmd` between renders drew the report once naming `three.qmd, four.qmd`, with a section on both pages, and the next render printed one section and drew it zero times. Suite green, 498 checks, exit 0.
- 2026-08-30: implement gate chose the drafted texts for both reports and a second single-chapter render leg in AC4's check over amending AC4, because a whole-book render rewrites every record before the last chapter reads one, so the stripped-field control cannot go red without it.
- 2026-08-30: plan gate chose optional new record fields read as no answer over a `STORE_VERSION` bump, because a bump drops every chapter's terms from the book index until the whole book renders again for a field only a report reads (M14); falsified by a reader that reaches the index rather than a report coming to depend on either field.

## Decisions

## Review
