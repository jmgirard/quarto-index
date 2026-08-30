# M062: A book repeats a record complaint once per index section it costs

- **Status:** planned
- **Priority:** normal
- **Depends on:** M061
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** —

## Goal

An HTML book reports a stored chapter record it refused for its version, or refiled because
it names an index the book no longer declares, once per index section that record costs.

## Scope

User-facing tier: the deliverable is what a rendered book's log tells the author.

**In:**

- `fold_undeclared` returns the chapter-and-name pairs it refiled instead of reporting them
  itself, so the report leaves the function every rendering chapter calls.
- Both reports — the version-refused one and the refiled-name one — are drawn once per
  chapter that builds an index; and, where the records a chapter read show no chapter of the
  book placing any index, once by each chapter that read the record, which is the case a
  book with no placement marker anywhere reports zero times today.
- `examples/book-nomarker/` gains a third chapter, so a book with no placement marker has
  more than one chapter that can report and the count separates once-per-book from
  once-per-chapter-that-read-it.

**Out:**

- The placement mechanism itself — a section deferred, doubled, or blocked → M061.
- The duplicate-marker report's closing clause, which still calls a book single-index
  → the standing named-index candidate row.

## Acceptance criteria

- [ ] AC1. With `examples/book-placement/`'s stored record for `five.qmd` planted to name an
      index the book does not declare, a whole-book HTML render draws the refiled-name report
      exactly twice, each naming `five.qmd` and the undeclared name. The arithmetic: two
      chapters build an index (`index.qmd` builds `alpha`, `three.qmd` builds `beta` and, as
      the last chapter that places anything, `gamma`), against four chapters that read the
      plant (`five.qmd` overwrites its own record before it reads) and three sections built,
      so 2 separates once-per-building-chapter from once-per-reading-chapter, from
      once-per-section, and from one report for the book. A render of `index.qmd` alone over
      the same plant draws it exactly once. Each render exits 0.
- [ ] AC2. In `examples/book-nomarker/`, extended to three chapters that carry marks and no
      placement marker anywhere, a whole-book HTML render over a store whose `two.qmd` record
      stands at the version this one supersedes draws the version-refused report exactly
      twice — `index.qmd` and `one.qmd`, the two chapters that read that record while the
      records show no chapter of the book placing an index — each naming `two.qmd`; 2 is
      neither one report for the book nor the three chapters rendered. The same render draws
      the report zero times before this milestone, draws the unreadable-record report zero
      times, and exits 0.
- [ ] AC3. The same three-chapter render with `two.qmd`'s record instead planted to name an
      index the book does not declare draws the refiled-name report exactly twice, each
      naming `two.qmd` and the undeclared name, and the marks that record carries still print
      in a section of the render. The render exits 0.
- [ ] AC4. Every count assertion these two reports already carry holds unchanged: the two
      `m55_stale_name` runs, the declaration-removal run and M60-AC6's split-record run, each
      a single-chapter `examples/book/` render expecting one refiled-name report, together
      with that report's existing zero-count control; `examples/book-nomarker/`'s
      no-marker-chapter report at the count M05 pinned over its re-derived three chapters;
      and `examples/book-placement/`'s two planted-superseded-record runs at their
      version-refused counts of 2 and 1. Each render exits 0.
- [ ] AC5. `tests/sitecheck.py claims` holds `site/books.qmd` to a claim naming when a book
      repeats its report about a chapter record it could not use, and fails on a copy of that
      page with the claim removed.
- [ ] AC6. `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T2, T3, T5
- AC3 → T1, T2, T3, T5
- AC4 → T3, T4, T5, T6
- AC5 → T7
- AC6 → T1, T2, T3, T4, T5, T6, T7

## Tasks

- [ ] T1. `fold_undeclared` (`_extensions/index/modules/book.lua:364`) returns the chapter
      and name of each record it refiled rather than warning from inside the function every
      rendering chapter calls; the caller reports.
- [ ] T2. One report site in `html_book` for both the version-refused and the refiled-name
      reports: once per chapter that builds an index, and once by a chapter that builds none
      only where the records it read show no chapter of the book placing any index.
- [ ] T3. `examples/book-nomarker/` gains `two.qmd`, marking terms and carrying no placement
      marker; the fixture comment and every count M05 pinned over it are re-derived by hand
      with the arithmetic shown.
- [ ] T4. AC1's check over `examples/book-placement/`: one substitution plants the undeclared
      name in `five.qmd`'s record; assert 2 on the whole book and 1 on the single-chapter
      render, each naming the chapter and the name; restore the record.
- [ ] T5. AC2 and AC3's checks over the three-chapter `examples/book-nomarker/`: plant
      `two.qmd`'s record at the superseded version read from the filter's own constant, then
      with an undeclared index name; assert both counts at 2, the chapter each names, the
      zero unreadable-record count, and that the refiled marks print.
- [ ] T6. Show each moved report red where it must now fire and silent where it must not:
      revert T2's gate and record which check fails, and confirm the AC1 render's count moves
      off 2.
- [ ] T7. `site/books.qmd` and `CHANGELOG.md` state when each report repeats, written against
      an executed render's own output; the claim joins the page's
      `tests/sitecheck.py claims` file and is shown red against a copy with it removed.

## Work log

- 2026-08-30: created by /milestone-plan.
- 2026-08-30: criteria audit ran in FULL mode (user-facing tier) over M061's and M062's criteria together in one fresh-context [O] reader; its M062 findings and their disposal are recorded in M061's work log.
- 2026-08-30: plan gate chose a third chapter in `examples/book-nomarker/` over keeping two, because in a two-chapter book exactly one chapter can report and "once" is the answer under once-per-book as well as under the rule this milestone ships; falsified by a fixture shape that separates the two rules without adding a chapter.
- 2026-08-30: plan gate chose one report site for both reports over leaving the refiled-name report inside `fold_undeclared`, because a function every rendering chapter calls cannot draw a report scoped to the chapters that build; falsified by a caller needing the refiled marks folded without wanting the report.

## Decisions

## Review
