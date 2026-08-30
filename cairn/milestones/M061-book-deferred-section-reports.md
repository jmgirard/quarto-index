# M061: A book reports the index section it deferred, doubled, or can never place

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m061-book-deferred-section-reports` / https://github.com/jmgirard/quarto-index/pull/61

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

- [x] AC1. With `examples/book-placement/`'s stored record for `five.qmd` planted to claim a
      placement marker for `gamma` that `five.qmd`'s source does not carry, a whole-book HTML
      render prints a generated index section only on the pages, under the ids and with the
      declared titles a hand-derived manifest states — that manifest listing every rendered
      page of the book, a page carrying no section written as its own row — and draws the
      deferred-section report exactly once, that report naming `gamma`. The render emits
      exactly the extension warnings the check names one by one, and exits 0. The same render
      draws the report zero times before this milestone.
- [x] AC2. Where `four.qmd` gains a placement marker naming `gamma` between two whole-book
      renders of `examples/book-placement/`, the render made after it gains one prints a
      `gamma` section on both `three.html` and `four.html`, and `five.qmd` — neither the
      chapter that gained the marker nor a chapter that printed the section — draws the
      doubled-section report exactly once, that report naming `gamma`; the next whole-book
      render prints `gamma` on `four.html` alone and draws that report zero times. Each
      render exits 0.
- [x] AC3. Where the store path `examples/book-placement/`'s `four.qmd` record would occupy
      is held by a directory, so that record can never be written, two consecutive whole-book
      HTML renders each draw the deferred-section report exactly once for `gamma`, each
      report naming `four.qmd` among the chapters whose record the render could not read.
      Each render's other extension warnings are enumerated by count and kind in the check —
      the write-failure report `four.qmd` draws for itself and the unreadable-record report
      every chapter draws for it included — and each render exits 0.
- [x] AC4. A whole-book render over a store whose records all carry the current
      `STORE_VERSION` and neither new field draws the deferred-section report zero times and
      the doubled-section report zero times, and every chapter's terms still print in the
      book's index sections.
- [x] AC5. The deferred-section report's new grep key is held to a live message by the
      suite's report-key scan, and the assertions M60 pinned hold over the re-derived
      five-chapter fixture: from an empty store the first render prints the sections its
      manifest names and defers `gamma` once, the second render prints `gamma` in
      `three.html` alone and defers nothing, `examples/book/` carries its three sections in
      `last.html` on a first render and defers nothing, and M60's two planted-superseded-record
      runs keep their version-skew counts of 2 and 1. Each render exits 0.
- [x] AC6. `tests/sitecheck.py claims` holds `site/books.qmd` and
      `site/placing-the-index.qmd` to a claim naming what a book reports when an index
      section is deferred and when one prints twice, and fails on a copy of either page with
      that claim removed.
- [x] AC7. `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

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
- [x] T5. `examples/book-placement/` gains `five.qmd`; `four.qmd`'s prose stops calling
      itself the book's last chapter; every manifest, warning count and comment that fixture
      feeds is re-derived by hand and its arithmetic shown.
- [x] T6. AC1's check: plant the phantom marker claim in `five.qmd`'s record with one
      substitution, assert the manifest, the report count, the index it names, and the
      enumerated warning total; restore the record; show it red by reverting T3.
- [x] T7. AC2's check: copy `four.qmd` aside, append the `gamma` marker with one
      substitution, render, assert two `gamma` sections and the report drawn once by
      `five.qmd`; restore, render, assert one section and zero reports; show it red by
      reverting T4.
- [x] T8. AC3's check: hold `four.qmd`'s store path with a directory, render twice, assert
      the report count, the chapter it names, and the enumerated warnings each render draws;
      show it red by reverting T3's naming of the unseen chapters.
- [x] T9. AC4's check: strip both new fields from every record of a warm store with one
      pass, render the whole book, assert both reports at zero and the index sections still
      carrying every chapter's terms; show it red by reading a missing field as `false`.
- [x] T10. `site/books.qmd`, `site/placing-the-index.qmd` and `CHANGELOG.md` state what a
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
- 2026-08-30: T5 — `examples/book-placement/` gains `five.qmd` as its last chapter (no marker, one `gamma` term); `four.qmd` and `index.qmd` no longer call themselves the last chapter and the count of chapters after the first marker. Re-derived by hand: both section manifests gain a `five.html` row and are re-ordered for the sweep's string sort (`five` before `four`); the first render's warning total stays 3 and the second's 2, since the fifth chapter carries no marker and draws no report of its own; the superseded-version run's expected 2 is unchanged, now against a five-chapter book where `three.qmd` builds `beta` alone. Suite green, 498 checks, exit 0.
- 2026-08-30: T6 — AC1's check. A warm store is rebuilt, kept aside as the base every planted run copies, and `five.qmd`'s record is planted with one substitution to claim a `gamma` marker its source does not carry; the render is held to the first-render section manifest, to one unplaced-section report naming `gamma`, `three.qmd` and no unreadable chapter, to zero doubled-section reports and to three extension warnings in total, then the record is restored. Shown red under `--self-test` against a copy of the same tree whose only change is the report deciding from whether the placing chapter could see every later record: the same pages, and no report at all.
- 2026-08-30: T7 — AC2's check. `four.qmd` is copied aside and gains a `gamma` marker; the render made just after prints `gamma` on `three.html` and `four.html` and draws the doubled-section report once, naming `gamma` and both chapters, with four extension warnings in total. Which chapter draws it is shown over that same store by two single-chapter renders — `five.qmd` alone draws one, `four.qmd` alone draws none. The render after that prints `gamma` on `four.html` alone and draws neither report; the source is then restored and two further renders are held to the ordinary second-render manifest. Shown red under `--self-test` against a copy whose only change is the report suppressed: the same two sections, and silence.
- 2026-08-30: T8 — AC3's check. `four.qmd`'s store path is held by a directory and the whole book is rendered twice; each render draws the unplaced-section report once for `gamma`, naming `three.qmd` and `four.qmd`, and each is enumerated by kind — 4 unreadable-record, 1 write-failure, 2 marker-position, 1 unplaced, 8 warning lines. The pattern-set total is 7 rather than 8: Quarto writes an ERROR line of its own before the write-failure report, whose line then opens with that line's colour-reset escape instead of `(W)`, so the anchored patterns do not reach it; the raw warning-line count is asserted alongside. The path is then freed and two renders restore the fixture. Shown red under `--self-test` against a copy whose only change is the report naming no unreadable chapter.
- 2026-08-30: T9 — AC4's check. Both new fields are stripped from every record of a warm store in one guarded pass; the whole-book render prints the second-render section manifest and all eight terms the five chapters mark, each in the section a hand-written list names, and draws neither report, no stale-record report and no unreadable-record report. The store is stripped again and `five.qmd` is rendered alone — the gate-chosen second leg, and the only one that puts a stripped record in front of the chapter that reads one: neither report, and no extension warning at all. Shown red under `--self-test` against a copy whose only change is a missing `adopted` read as an empty one, which draws the unplaced-section report for a section on the page.
- 2026-08-30: T10 — `site/books.qmd` and `site/placing-the-index.qmd` state what a book reports when an index section is left unplaced (naming the index, the chapter it was owed to and the chapters that chapter could not read, and that a record which can never be written draws the same report on every render) and when one prints in two chapters; `CHANGELOG.md` gains three entries for the two reports and the record's two new fields. Every sentence is written against the render logs the checks above captured. Three claim rows join the books page's list and a new list holds the placement page; each page is shown red under `--self-test` against a copy with its own claim removed. `cairn/DESIGN.md`: the book paragraph's "five cases are reported" is corrected to seven — the deferral M60 added was never listed — and gains what a chapter now records and the one store pass; KI198, KI201 and KI203 are struck as fixed, KI199 is narrowed to the doubling that still happens and is now reported, and KI204 records `store_write`'s open-failure guard not stopping the write, observed on AC3's render.
- 2026-08-30: all ten tasks done; status to review. `tests/run-tests.sh` 515 checks exit 0, `tests/run-tests.sh --self-test` 976 checks exit 0.
- 2026-08-30: implement gate chose the drafted texts for both reports and a second single-chapter render leg in AC4's check over amending AC4, because a whole-book render rewrites every record before the last chapter reads one, so the stripped-field control cannot go red without it.
- 2026-08-30: review — checkpoint before the gate. All seven criteria verified with fresh evidence (515 checks plain, 976 with `--self-test`, both exit 0); `cairn_validate.py` exit 0; no principle text changed, so `cairn_impact` was skipped; the `generic` profile names no toolchain checks. Three lenses ran: blame-history and prior-review found nothing, the diff-bug lens eight. Three fixed here — the doubled-section report drawn for a declared index nothing marks (reproduced on a scratch render, guarded on `marks_in` and regression-tested by a fourth declared index in `examples/book-placement/`), AC3's report-naming grep matching a prefix rather than the whole `unseen` set, and KI203's behavioural half restored as KI205 after only its false promise was fixed. KI206 and KI207 file two check gaps. Three rejected, one of them a refutation of KI204 checked against the render log, where the recorded observation reproduces.
- 2026-08-30: plan gate chose optional new record fields read as no answer over a `STORE_VERSION` bump, because a bump drops every chapter's terms from the book index until the whole book renders again for a field only a report reads (M14); falsified by a reader that reaches the index rather than a report coming to depend on either field.

## Decisions

## Review

Fresh evidence, this branch at the tip, `tests/run-tests.sh` run whole (515 checks,
exit 0). Named check lines are the suite's own `ok` lines.

### Acceptance criteria

- AC1 — PASS. `M061-AC1`: over a store whose `five.qmd` record is planted to claim a
  `gamma` placement marker its source does not carry, the whole-book render prints 2
  sections over 5 pages against the hand-derived manifest — every rendered page a row,
  a page with no section its own row — draws the unplaced-section report once naming
  `gamma`, `three.qmd` and no chapter as unreadable, draws the doubled-section report
  zero times, and emits exactly the 3 extension warnings the check enumerates; the
  render exits 0. Before this milestone the same render is silent: the `M061 T6`
  self-test mutant, whose only change is the report deciding from whether the placing
  chapter could see every later record rather than from what it recorded taking on,
  prints the same pages and says nothing at all.
- AC2 — PASS. `M061-AC2`: the render made just after `four.qmd` gains a `gamma`
  marker prints 4 sections over 5 pages against the hand-derived manifest, draws
  the doubled-section report once naming `gamma` and `three.qmd, four.qmd` in book
  order, and draws no unplaced-section report; two single-chapter renders over that
  same store show `five.qmd` alone drawing it and `four.qmd` drawing none; the next
  render prints 3 sections — `gamma` on `four.html` alone — and draws the report
  zero times. Every render exits 0 (the suite fails on a non-zero render).
- AC3 — PASS. `M061-AC3`: with `four.qmd`'s store path held by a directory, two
  consecutive whole-book renders are identical — each draws the unplaced-section
  report once for `gamma`, naming `three.qmd` and `four.qmd` among the chapters
  whose record could not be read, and each draws the same 8 warning lines enumerated
  by kind (4 unreadable-record, 1 write-failure, 2 marker-position, 1 unplaced).
  Freeing the path and rendering twice restores the ordinary second-render manifest
  and silence. Each render exits 0.
- AC4 — PASS. `M061-AC4`: both new fields stripped from all 5 records of a warm
  store; the whole-book render prints the second-render manifest (3 sections over 5
  pages) and all 8 printed terms in the sections the manifest names, drawing neither
  report; a second leg strips again and renders `five.qmd` alone — neither report and
  no extension warning at all.
- AC5 — PASS. `M10-AC4`: each of the 25 report grep keys, `WARN_DEFER` and
  `WARN_DOUBLED` among them, matches exactly its own filter warning and none of the
  others. M60's pinned assertions hold over the re-derived five-chapter fixture:
  `M60-AC1/AC3` (first render from an empty store prints its manifest sections, none
  for the unnamed index, and reports it once by name), `M60-AC2` (second render places
  it in that chapter alone, no deferral), `M60-AC1` (`examples/book/` carries its
  three sections in `last.html` on a first render, defers nothing), `M60-AC4` (the
  superseded-version report drawn twice in the whole-book render and once for the
  single building chapter). Each render exits 0.
- AC6 — PASS. `M061-AC6`: both `site/books.qmd` and `site/placing-the-index.qmd` are
  held to a claim naming what a book reports when a section is left unplaced and when
  one prints twice; the `M061-AC6` self-test shows each of the two claim lists red on
  a copy of its own page with that claim removed.
- AC7 — PASS. `tests/run-tests.sh` — 515 checks, exit 0. `tests/run-tests.sh
  --self-test` — 976 checks, exit 0. Both run whole on this branch at the tip.
