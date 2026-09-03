# M074: A record no render has written is reported by the chapter that prints the section, once

- **Status:** planned
- **Priority:** normal
- **Depends on:** M073
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Resolves:** —
- **Branch/PR:** —

## Goal

In an HTML book, the reports about a record no render has written are drawn at
the site that knows whether this chapter prints an index section, each wording
once per chapter that reads the store and naming every chapter it covers,
rather than inline once per record met by every chapter the recovery gate
admits.

## Scope

Surface tier: **user-facing** — the deliverable is the warning text an
installed extension prints to an author, and the site prose about it.

**In:** handing the never-written entries back from `store_read`
(`_extensions/index/modules/book.lua:938`) to the one report site in
`html_book` (`book.lua:1538`), where `builds` is already known — the move M072
made for the version-skewed reports — and drawing each wording there once,
naming every chapter it covers. The refusal drawn on the never-written path
moves with it, following the count of the report it stands in for. The three
superseding decisions this needs, the site and changelog prose, and the suite
legs and planted defects.

**Out:** the recovery GATE itself, which stays settled before the store is
opened: an exact "prints a section" test is computable only from the store,
which is the per-chapter disagreement D-040 and D-045 exist to prevent → not
planned; the alternative is recorded in the work log.
The source parsing a chapter that prints nothing still pays (KI227, KI229's
remainder) → stands as its known issue.
The wordings themselves → M073.

## Acceptance criteria

- [ ] AC1: In an HTML book, a chapter that reads the store and prints no index
      section draws no report about a record no render has written, the
      refusal drawn on that path included. Evidence: a new leg rendering
      `eight.Rmd` alone in a store-less copy of `examples/book-extensions` —
      the book's last chapter, carrying no placement marker, both declared
      indexes placed by `index.qmd` — counts `WARN_STORE_NEVER_RECOVERED`,
      M073's never-written-lost-source key and `WARN_STORE_KIND_REFUSED` at
      zero, and this extension's warnings at zero in that render's log.
- [ ] AC2: A chapter that prints an index section draws each never-written
      wording once, naming every chapter that wording covers, rather than once
      per chapter covered. Evidence: the `m069-index` leg's log carries
      `WARN_STORE_NEVER_RECOVERED` once and a check over that single line
      names each of the four chapters the leg counts four separate reports for
      today; a second leg builds a render drawing two never-written wordings
      at once and counts each once, each naming its own chapters.
- [ ] AC3: A book whose records show no chapter placing any index still hears
      about a record no render has written, from the chapter that reads the
      store and builds nothing. Evidence: a new leg rendering `two.qmd` alone
      in a store-less copy of `examples/book-nomarker` counts
      `WARN_STORE_NEVER_RECOVERED` at one, alongside that book's standing
      no-marker report.
- [ ] AC4: The index every affected chapter prints is unchanged: the `m069`
      legs (`tests/run-tests.sh:8977-9105`) and the `place-first` leg
      (`:6680`) assert the same index rows they assert today.
- [ ] AC5: The store-reports section of `site/books.qmd` and the unreleased
      section of `CHANGELOG.md` state where the never-written reports are
      drawn and at what count as the shipped code has them: a grep over those
      two regions returns no sentence saying one report per record or one per
      chapter that reads the store, and the books page's claim ledger
      (`tests/run-tests.sh:21763`) carries a row for each sentence added.
- [ ] AC6: `tests/run-tests.sh` passes; `tests/run-tests.sh --self-test`
      passes, and its M074 battery shows red against the pre-fix code each
      plant names: (a) the report site's `builds or first == nil` gate turned
      round for the never-written entries, (b) the per-chapter draw restored
      inside `store_read`, and (c) the aggregation reduced to naming one
      chapter of the set.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T2, T3, T4
- AC3 → T1, T4
- AC4 → T4
- AC5 → T6
- AC6 → T5, T7

## Tasks

- [ ] T1: Hand the never-written entries — and the refusal drawn on that path —
      back from `store_read` (`book.lua:1052-1071`) to `html_book` beside the
      stale entries, and draw them at the report site (`book.lua:1538`) under
      the existing `builds or first == nil` gate, ahead of nothing that
      already draws there.
- [ ] T2: Aggregate: one draw per wording per reading chapter, the chapter
      list passed through the message's own `:format()` with a non-newline
      separator, so `warn-distinct.py` still reads the message and
      `check_extension_warning_count` still counts one line.
- [ ] T3: A suite helper asserting that a single matching log line names each
      chapter of an expected set and no other — `check_warning_count` counts
      occurrences of a fixed literal and cannot read a line's contents.
- [ ] T4: Suite legs: the `eight.Rmd` leg (AC1); the `book-nomarker` leg
      (AC3); the two-wordings-at-once leg (AC2); and the count updates every
      moved report forces in `m069-index`, `m069-five`, `m069-three`,
      `m069-lostsource`, `m069-nomarksource`, `place-first` and the M073 legs,
      each hand-derived.
- [ ] T5: The three planted defects of AC6 under `--self-test`, each a single
      substitution shown red before its fix.
- [ ] T6: `site/books.qmd`, `CHANGELOG.md`, the books claim-ledger rows, and
      the recovery prose plus KI228 and KI229 in `cairn/DESIGN.md` — KI229
      struck only for its report half, its parse half restated.
- [ ] T7: Full `tests/run-tests.sh` and `--self-test` runs; D-entry
      superseding D-049's clause that the never-written state keeps the inline
      draw and its count, D-046's count clause where it governs the refusal on
      that path, and D-045's consequence that a book whose markers sit earlier
      reports each recovered chapter.

## Work log

- 2026-09-03: created by /milestone-plan, promoting the held store-reports candidate row (its KI228 and KI229 halves); the other two halves are M073.
- 2026-09-03: plan gate chose moving the reports to the building chapter over narrowing the site prose to admit a report from a chapter that prints nothing, and over deciding the recovery gate from the store; the store-derived gate loses because two chapters of one render read the store at different moments and would disagree about recovering, the failure D-040 records. Falsified by a chapter that builds a section losing a report it draws today.
- 2026-09-03: plan gate chose one report per wording naming every chapter over one per chapter and over a reworded per-chapter report, because position cannot tell a first whole-book render from a single-chapter render on a cold store — `m069-index` recovers four chapters after it in a one-chapter render — so volume is the only axis left. Falsified by an author reporting they could not tell which chapter a named set's report was about.
- 2026-09-03: criteria audit ran in full mode over two passes ([O], fresh context); pass 1 rejected the exact-gate approach, pass 2 returned the `eight.Rmd` leg's unreachable silence (the refusal must move with the report), the aggregation's `:format()` constraint, `book-nomarker` reaching the state only when its last chapter renders alone, and two documentation promises over whole files — all disposed into the criteria above.

## Decisions

## Review
