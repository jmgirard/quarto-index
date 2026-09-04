# M074: A record no render has written is reported by the chapter that prints the section, once

- **Status:** review
- **Priority:** normal
- **Depends on:** M073
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Resolves:** —
- **Branch/PR:** m074-never-written-report-site

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

- [x] T1: Hand the never-written entries — and the refusal drawn on that path —
      back from `store_read` (`book.lua:1052-1071`) to `html_book` beside the
      stale entries, and draw them at the report site (`book.lua:1538`) under
      the existing `builds or first == nil` gate, ahead of nothing that
      already draws there.
- [x] T2: Aggregate: one draw per wording per reading chapter, the chapter
      list passed through the message's own `:format()` with a non-newline
      separator, so `warn-distinct.py` still reads the message and
      `check_extension_warning_count` still counts one line.
- [x] T3: A suite helper asserting that a single matching log line names each
      chapter of an expected set and no other — `check_warning_count` counts
      occurrences of a fixed literal and cannot read a line's contents.
- [x] T4: Suite legs: the `eight.Rmd` leg (AC1); the `book-nomarker` leg
      (AC3); the two-wordings-at-once leg (AC2); and the count updates every
      moved report forces in `m069-index`, `m069-five`, `m069-three`,
      `m069-lostsource`, `m069-nomarksource`, `place-first` and the M073 legs,
      each hand-derived.
- [x] T5: The three planted defects of AC6 under `--self-test`, each a single
      substitution shown red before its fix.
- [x] T6: `site/books.qmd`, `CHANGELOG.md`, the books claim-ledger rows, and
      the recovery prose plus KI228 and KI229 in `cairn/DESIGN.md` — KI229
      struck only for its report half, its parse half restated.
- [x] T7: Full `tests/run-tests.sh` and `--self-test` runs; D-entry
      superseding D-049's clause that the never-written state keeps the inline
      draw and its count, D-046's count clause where it governs the refusal on
      that path, and D-045's consequence that a book whose markers sit earlier
      reports each recovered chapter.

## Work log

- 2026-09-03: created by /milestone-plan, promoting the held store-reports candidate row (its KI228 and KI229 halves); the other two halves are M073.
- 2026-09-03: plan gate chose moving the reports to the building chapter over narrowing the site prose to admit a report from a chapter that prints nothing, and over deciding the recovery gate from the store; the store-derived gate loses because two chapters of one render read the store at different moments and would disagree about recovering, the failure D-040 records. Falsified by a chapter that builds a section losing a report it draws today.
- 2026-09-03: plan gate chose one report per wording naming every chapter over one per chapter and over a reworded per-chapter report, because position cannot tell a first whole-book render from a single-chapter render on a cold store — `m069-index` recovers four chapters after it in a one-chapter render — so volume is the only axis left. Falsified by an author reporting they could not tell which chapter a named set's report was about.
- 2026-09-03: question gate settled three implementation choices: the three moved sentences are rewritten to read correctly for one chapter or several ("each such chapter's ...", closing "render each again"), one wording per state, so two of the three suite search keys are untouched and the never-written-lost key moves by three words; the new naming helper takes an explicit must-not-appear list from each leg rather than parsing the sentence; and AC2's second leg is the existing `m069-lostsource` leg, which already draws both never-written wordings in one log.
- 2026-09-03: T1/T2 code landed — `store_read` hands back a third table of never-written chapters (refused / recovered / lost, book order) and `html_book` draws one line per list under the existing `builds or first == nil` gate, after the stale and refiled loops; `chapter_list` joins the names with commas and a final "and". Suite counts follow in T4, so the boxes stay open.
- 2026-09-03: T3/T4/T5/T6 landed together (the suite file cannot be edited while a run is in flight, so the edits batched): `check_warning_names` asserts one matching line names an expected chapter set and none of a hand-derived forbidden set; new legs for AC1 (`eight.Rmd` over a cold `book-extensions`) and AC3 (`two.qmd` over a cold `book-nomarker`); counts rederived in `place-first` (6→2, 8→4), `m069-index`/`-five`/`-three` (4→1), `m069-lostsource` (3→1, 4→2), `m069-nomarksource` (3→1), `m070-cold` (7→1, 9→3), `m070-dangling` (6→1, 9→4), `m070-record` (4→1, 6→3), and the M069/M070 plants; three M074 plants; and the site, changelog, ledger and DESIGN prose.
- 2026-09-03: M069 T6's inverted-gate plant retired rather than left green: it read the inversion off the four reports two.qmd drew for nothing, and two.qmd is now silent either way — the report site's gate is shut for it. Both halves of the recovery gate stay planted (plants 1 and 2), and the report site's own gate is M074's plant 1. M070's inverted and nomarkdown plants kept their renders and moved from a refusal COUNT, which aggregation made equal to the unplanted one, to the chapters that line names.
- 2026-09-03: T7 — `tests/run-tests.sh --self-test` green, 1290 checks, exit 0; D-053 appended, superseding D-049's inline-draw clause for this state and D-046's count clause on this path, and narrowing D-045's consequences.
- 2026-09-03: the M063-AC6 self-test pins the books claim ledger's row count in a message needle (41 → 44 with this milestone's three rows), so a ledger row cannot be added without moving it. Noted rather than fixed.
- 2026-09-03: criteria audit ran in full mode over two passes ([O], fresh context); pass 1 rejected the exact-gate approach, pass 2 returned the `eight.Rmd` leg's unreachable silence (the refusal must move with the report), the aggregation's `:format()` constraint, `book-nomarker` reaching the state only when its last chapter renders alone, and two documentation promises over whole files — all disposed into the criteria above.

## Decisions

## Review
