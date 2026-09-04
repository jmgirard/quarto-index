# M074: A record no render has written is reported by the chapter that prints the section, once

- **Status:** review
- **Priority:** normal
- **Depends on:** M073
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Resolves:** —
- **Branch/PR:** m074-never-written-report-site · https://github.com/jmgirard/quarto-index/pull/74

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

- [x] AC1: In an HTML book, a chapter that reads the store and prints no index
      section draws no report about a record no render has written, the
      refusal drawn on that path included. Evidence: a new leg rendering
      `eight.Rmd` alone in a store-less copy of `examples/book-extensions` —
      the book's last chapter, carrying no placement marker, both declared
      indexes placed by `index.qmd` — counts `WARN_STORE_NEVER_RECOVERED`,
      M073's never-written-lost-source key and `WARN_STORE_KIND_REFUSED` at
      zero, and this extension's warnings at zero in that render's log.
- [x] AC2: A chapter that prints an index section draws each never-written
      wording once, naming every chapter that wording covers, rather than once
      per chapter covered. Evidence: the `m069-index` leg's log carries
      `WARN_STORE_NEVER_RECOVERED` once and a check over that single line
      names each of the four chapters the leg counts four separate reports for
      today; a second leg builds a render drawing two never-written wordings
      at once and counts each once, each naming its own chapters.
- [x] AC3: A book whose records show no chapter placing any index still hears
      about a record no render has written, from the chapter that reads the
      store and builds nothing. Evidence: a new leg rendering `two.qmd` alone
      in a store-less copy of `examples/book-nomarker` counts
      `WARN_STORE_NEVER_RECOVERED` at one, alongside that book's standing
      no-marker report.
- [x] AC4: The index every affected chapter prints is unchanged: the `m069`
      legs (`tests/run-tests.sh:8977-9105`) and the `place-first` leg
      (`:6680`) assert the same index rows they assert today.
- [x] AC5: The store-reports section of `site/books.qmd` and the unreleased
      section of `CHANGELOG.md` state where the never-written reports are
      drawn and at what count as the shipped code has them: a grep over those
      two regions returns no sentence saying one report per record or one per
      chapter that reads the store, and the books page's claim ledger
      (`tests/run-tests.sh:21763`) carries a row for each sentence added.
- [x] AC6: `tests/run-tests.sh` passes; `tests/run-tests.sh --self-test`
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
- 2026-09-03: review round 1 returned at the consistency gate — AC5 fails: its grep over the two named regions returns two sentences saying one report per record (`site/books.qmd:171`, `CHANGELOG.md:83`), with `cairn/DESIGN.md:498` carrying the same claim outside them. Six further findings taken fix-now (F2 the place-first membership assertion its own comment promises, F3 the AC1 leg's missing positive control, F4 a plant naming a detector that no longer detects, F8's wrap, F9's wording) and two as follow-ups (F5, F6); F7 and F10 rejected, F10 refuted against the file. Suite runs stopped at the gate failure, plain run green through 521 checks.
- 2026-09-04: round 1's floor return cleared — the three sentences saying one report per record rewritten to the count the code has (`site/books.qmd:171`, `CHANGELOG.md:83`, `cairn/DESIGN.md:498`, each now "reports them in one line naming each"). No claim-ledger row added or removed, so the ledger stays at 44 and the M063-AC6 needle is unmoved.
- 2026-09-04: F2 — `check_warning_names_nth` added beside `check_warning_names` (one line of several, picked by position among the matches in log order), and `place-first`'s two never-written lines asserted by membership: index.qmd's names two/three/four/five.qmd and not itself, three.qmd's names four.qmd and five.qmd alone. Plant 3 fails there now as well as in the m069 legs.
- 2026-09-04: F3 — the AC1 leg's four zeros given both halves it lacked: `check_book_sections` over the `m074-quiet` capture (eight.html and index.html, no section between them), and a positive control, `m074-unplaced`, the same fixture and chapter with index.qmd's two placement markers taken out. There `builds` is false and `first` is nil, so the same chapter draws all three reports and names the seven sources it read — the zeros above are the report site's gate, not a chapter that never reached the store. That control is also the first render to exercise `first == nil` for a refused entry, so KI237 is marked covered.
- 2026-09-04: F4 — the m070-inverted plant's pass line no longer claims the cold leg's refusal COUNT catches it (aggregation made that count 1 either way); it names the chapters that line names, which is what does. The nomarkdown plant's "now drawn twice" comment corrected to one line naming two chapters. F8's two over-wrapped DESIGN lines fixed by reflowing the paragraph; F9's doubled possessive in `CHANGELOG.md:12` fixed.
- 2026-09-04: F5 and F6 taken as KI239 (the never-written refusal joined into one line while the version-skewed refusal beside it still draws one per chapter — the same sentence at two counts, created by this diff) and KI240 (KI229's second silent shape: a marker naming an index an earlier chapter also places). D-013 puts both in DESIGN.md Known issues rather than a ROADMAP row.
- 2026-09-04: T6 closed. `tests/run-tests.sh --self-test` green, 1296 checks, exit 0, 26m19s.
- 2026-09-04: review round 2 — branch level with `origin/main`, PR #74 already open. Plain `tests/run-tests.sh` green, 699 checks, exit 0; AC1-AC5 verified with fresh evidence and ticked; `cairn_validate` all PASS with no release-window advisory. Three fresh-context lenses ran: prior-review record zero findings, blame-history three, diff-bug nine — none failing a criterion, so no floor return. AC6's `--self-test` half is still running; this is a checkpoint, not the gate.
- 2026-09-04: round 2 AC6 — `tests/run-tests.sh --self-test` green, 1296 checks, exit 0; all six criteria ticked against recorded evidence. Twelve findings across the three lenses: N1/N3/N7 fix-now (three stale or miscounting comment clauses), N2/N4/N5 follow-up, N8/N9/B3 rejected, N6/B2 already filed as KI239/KI240.

## Decisions

## Review

Round 1 (2026-09-03). Returned at the consistency gate: **AC5 fails.** Its own
grep over the two named regions returns two sentences saying one report per
record, which is the count the shipped code no longer has.

### Acceptance criteria

- **AC1 — partial, not ticked.** The `m074-quiet` leg (`eight.Rmd` alone over a
  cold `book-extensions`) was not reached before the run was stopped, so no
  fresh evidence stands for it. F3 below is a defect in the leg itself.
- **AC2 — evidence recorded, not ticked (the gate returned first).** The plain
  run reached the m069 legs green: `m069-index` carries
  `WARN_STORE_NEVER_RECOVERED` once, that one line naming two.qmd, three.qmd,
  four.qmd and five.qmd and not index.qmd; `m069-five`, `m069-three` and
  `m069-lostsource` likewise one line apiece, each naming its own set, with
  `m069-lostsource` drawing both never-written wordings once each. F2 below
  shows the one multi-chapter shape (`place-first`) asserted by count alone.
- **AC3 — not reached.** The `m074-nomarker` leg sits after the stop point.
- **AC4 — evidence recorded, not ticked.** The m069 legs asserted the same
  index rows they assert today (manifest rows matched in `m069-five`,
  `m069-three`, `m069-index`); `place-first` was green earlier in the run.
- **AC5 — FAILED.** A grep over `site/books.qmd`'s store-reports region and
  `CHANGELOG.md`'s unreleased section returns two sentences stating one report
  per record: `site/books.qmd:171` ("that chapter reads their sources and
  reports each one") and `CHANGELOG.md:83` ("reads the sources of the chapters
  behind it and reports each"). `cairn/DESIGN.md:498` carries the same claim
  outside AC5's regions. The claim ledger checks presence and never absence, so
  the suite does not catch it. The ledger itself is at 44 rows as planned.
- **AC6 — not reached.** Both runs were stopped at the gate failure; the plain
  run was green through 521 checks with no failure at the stop point, and no
  `--self-test` evidence stands.

### Consistency gate

`cairn_validate.py`: all 16 checks PASS, all 7 advisories OK (no release-window
advisory). No `DESIGN.md` principle text changed, so `cairn_impact.py` was not
run. The `generic` profile's consistency-gate slot names no toolchain checks.

### Independent review

Three fresh-context lenses (user-facing tier, executable surface). [S]
blame-history: no findings — it read the retired M069 T6 inverted-gate plant
against M074's own plant 1 and found the coverage relocated rather than lost.
[S] prior-review-record: the probe found no inline PR review comments in the
repo at all, so only archived `## Review` sections were read; one finding, F10.
[O] diff-bug: nine findings. It cleared the two gates positively — `builds`
implies `recover_absent`, `absent` is filled in chapter order with each file in
exactly one list, `never_written` and the version-skew test are mutually
exclusive, and `warn-distinct.py`'s expected call count is unchanged.

- **F1 (fix now, floor return).** Three sentences still say one report per
  record: `site/books.qmd:171`, `CHANGELOG.md:83`, `cairn/DESIGN.md:498`. An
  author reading books.qmd expects four reports from a five-chapter render and
  gets one, the page contradicting itself two paragraphs apart.
- **F2 (fix now).** `tests/run-tests.sh:6758-6760` promises "The chapters each
  of the two lines names are asserted below" and nothing below asserts them —
  only `check_warning_count ... 2` at :6766. `place-first` is the only leg
  where two chapters of one render draw the report, so the multi-chapter case
  of AC2 is asserted nowhere; plant 3 (aggregation reduced to `files[1]`)
  passes this leg.
- **F3 (fix now).** The AC1 leg (`tests/run-tests.sh:25168-25178`) is four zero
  counts with no positive control: it never asserts `eight.Rmd` printed no
  index section, nor that it reached the store at all. Dropping the
  last-chapter half of `recover_absent` leaves every check passing at zero.
  The AC3 leg asserts `check_book_sections`; this one does not.
- **F4 (fix now).** `tests/run-tests.sh:23980` claims the m070-inverted plant is
  caught by "the AC2 manifest and the refusal count for the cold leg";
  `m070-cold`'s refusal count is now 1 either way. The surviving detectors are
  the manifest and `m070_refusal_names five.ipynb`.
- **F5 (follow-up).** `absent.refused` is joined into one line at
  `book.lua:1611` while the `stale` refused entries at `:1632` still draw one
  line per chapter, so the identical refusal sentence draws twice for two
  version-skewed notebook chapters and once for two never-written ones. Created
  by this diff, outside its stated scope, and not in D-053's consequences.
- **F6 (follow-up).** A second gate-admitted-but-silent shape is uncovered: a
  chapter whose placement marker names an index an earlier chapter also places
  has `mine` empty, so it recovers every never-written source and says nothing.
  D-053 and KI229 name only the last-chapter shape.
- **F7 (rejected — out of scope taxonomy, pre-existing class).**
  `check_warning_names` matches bare substrings, so a fixture with `two.qmd`
  and `chapter-two.qmd` would give a spurious result. Every named/unnamed pair
  in today's fixtures was checked and is unambiguous; the hand-derivation at
  each call site is the stated guard.
- **F8 (fix now, in part).** `cairn/DESIGN.md:538` and `:542` break the file's
  ~78-column wrap. The same finding's claim that ":537 says two states where
  book.lua enumerates three" is REJECTED: that clause counts record STATES for
  the refusal's draw site (unopenable, undecodable), not the three WORDINGS for
  a written-and-unusable record the earlier sentence enumerates, and "as all
  four were before" is the historical four states, still accurate.
- **F9 (fix now).** `CHANGELOG.md:12-13` "The book's last chapter of a book
  whose every declared index is placed earlier" reads as a doubled possessive.
- **F10 (rejected).** The prior-review lens read `cairn/DESIGN.md`'s "three for
  a record that was written and could not be used" and "the two states about a
  record that WAS there" as one enumeration and called the paragraph
  self-contradictory. Verified against the file: they are different sets
  (wordings vs. record states), and the sentence is correct as written. Same
  refutation as F8's second half.

Return count: 1 defect return (this one). No amendment return.

Round 2 (2026-09-04). Branch synced with `origin/main` (0 behind, 5 ahead);
PR #74 already open, so no second one was cut.

### Acceptance criteria

- **AC1 — PASSED.** Plain run, `m074-quiet`: eight.Rmd alone over a cold copy
  of `book-extensions` draws `WARN_STORE_NEVER_RECOVERED`, the never-written
  lost-source key and `WARN_STORE_KIND_REFUSED` at zero and no warning of this
  extension at all, with `check_book_sections` confirming eight.html and
  index.html carry no generated section. The `m074-unplaced` control — the same
  fixture and chapter with index.qmd's two placement markers removed — draws
  all three reports there, its one never-written line naming
  index.qmd/one.qmd/two.md/three.markdown/four.Rmd/six.qmd/seven.qmd and not
  five.ipynb or eight.Rmd, and its refusal naming five.ipynb. The silence is
  the report site's gate, not a chapter that never reached the store.
- **AC2 — PASSED.** `m069-index` carries `WARN_STORE_NEVER_RECOVERED` once,
  that one line naming two.qmd, three.qmd, four.qmd and five.qmd and not
  index.qmd; `m069-five` and `m069-three` likewise one line apiece naming their
  own four. `m069-lostsource` is the two-wordings-at-once leg: the never-written
  line names index.qmd/two.qmd/three.qmd and neither four.qmd nor five.qmd,
  while the lost-source line names four.qmd alone — each wording once. The
  multi-chapter shape is now asserted by membership rather than by count:
  `place-first` line 1 of 2 names two/three/four/five.qmd and not index.qmd,
  line 2 of 2 names four/five.qmd alone.
- **AC3 — PASSED.** `m074-nomarker`: two.qmd alone over a cold copy of
  `book-nomarker` counts `WARN_STORE_NEVER_RECOVERED` at one, that line naming
  index.qmd and one.qmd and not two.qmd, with the book's two rendered pages
  carrying no generated section.
- **AC4 — PASSED.** The `m069` legs assert the same index rows they assert
  today — `m069-index` 5 manifest rows, `m069-three` 4, `m069-five` 21, all
  matched in order — and `place-first` matched its 3-section/5-page manifest on
  both renders. The diff adds and removes no manifest row.
- **AC5 — PASSED.** The grep over `site/books.qmd`'s store-reports region
  (lines 95-238) and `CHANGELOG.md`'s Unreleased section returns no sentence
  asserting one never-written report per record or one per chapter that reads
  the store. Three hits are all negations or past tense describing the
  superseded count (`books.qmd:209` "a report for each of them said one thing
  several times over"; changelog "rather than once for each of them"), and the
  two remaining changelog hits belong to M073's version-evidence entries, where
  per-chapter-that-reads-the-store is the shipped count. The claim ledger holds
  44 rows, three of them added by this milestone, one per rewritten sentence;
  the M063-AC6 needle reads 44 to match.
- **AC6 — PASSED.** `tests/run-tests.sh` green, 699 checks, exit 0;
  `tests/run-tests.sh --self-test` green, 1296 checks, exit 0. The M074 battery
  shows each plant red against the pre-fix code: (a) the report site's
  `builds or first == nil` gate turned round for the never-written entries —
  the building chapter falls silent and the non-building one reports all seven;
  (b) the per-chapter draw restored inside `store_read` — four reports where
  the milestone draws one; (c) the aggregation reduced to `files[1]` — the one
  line names two.qmd and drops three/four/five.qmd, which no count in the suite
  can see and `check_warning_names` does.

### Consistency gate

`cairn_validate.py`: 16 checks PASS, 7 advisories OK, no release-window
advisory. No `IP`/`GP` principle text changed in the diff, so `cairn_impact.py`
was not run. The `generic` profile's consistency-gate slot names no toolchain
checks.

### Independent review

Three fresh-context lenses (user-facing tier, executable surface), each on a
distinct evidence base. [S] prior-review record: the archive carries no
`## Review` sections at all and the inline-PR-comment probe returned `[]`, so
the only prior-review surface is round 1's own record; it verified every round-1
disposition landed as recorded and reported no findings. [S] blame-history:
three findings (B1-B3), two of them the known issues round 1 filed. [O]
diff-bug: nine findings (N1-N9), and it confirmed all six round-1 fixes landed
correctly — 44 ledger rows against a needle reading 44, `check_warning_names_nth`
with `place-first` asserted by membership, the `m074-unplaced` control closing
F3's hole, the m070-inverted pass line corrected, the DESIGN reflow, the
changelog possessive. It also re-derived every hand-rederived count in the diff
and every named/unnamed pair for substring collisions, finding none.

- **N1 (fix now).** `book.lua:1586-1588`: the report-site comment enumerates
  three reports and then says a source-refused chapter "arrives among the first
  two, flagged". It arrives among the first (`stale`, flagged) and the third
  (`absent.refused`, a separate list) — never among `refiled`, which is
  impossible for it. The clause contradicts its own next sentence, which names
  the version-skew and never-written paths correctly.
- **N3 (fix now).** `book.lua:937`: "One pass, and only these two answers" is
  stale — the three lines above it now say `store_read` returns three things,
  and `:1140` returns three values.
- **N7 (fix now).** `cairn/DESIGN.md:538` "in the two states about a record that
  WAS there" against `book.lua:1042-1049`, whose new comment lists three under
  the same phrase. DESIGN recovers the third in its next sentence, so the
  paragraph is not false, but the numeral undercounts its own subject. Round 1
  rejected F8's second half on the grounds that the sets differ (wordings vs.
  record states); the new evidence is that the diff's own comment now uses the
  identical phrase for a three-member set. Dropping the numeral settles it.
- **N2 (follow-up).** `tests/run-tests.sh:25374-25376`: plant 2's page control
  reads `$CAPTURE_ROOT/m069-m069-index`, the clean leg's capture, not the
  mutant's (`m069-m074-inline`), so nothing in the plant can make it fail. Its
  label says so honestly ("the unmutated leg's section, restated") and the
  discriminating check is the count, which is red on the plant — but every
  sibling plant reads its own mutant's capture, and repointing it would make the
  check live. Deferred because verifying it costs a full self-test run.
- **N4 (follow-up).** `site/books.qmd:171` — the sentence round 1's F1 actually
  failed on — was rewritten rather than added, so it has no claim-ledger row,
  and `sitecheck.py claims` checks presence only. A later reword back to
  "reports each one" would be green. AC5 as written is satisfied (a row per
  sentence *added*); adding a row moves the ledger to 45 and the M063-AC6 needle
  with it, which is the cost that defers it.
- **N5 (follow-up).** `tests/run-tests.sh:2081-2115`: `check_warning_names_nth`
  picks its line by ordinal among the grep matches, relying on Quarto emitting
  chapter logs in render order — a new assumption in a suite whose other
  multi-line assertions are order-free. A flip would fail spuriously, never pass
  falsely; a content-keyed assertion would be equally strong and order-free.
- **N6 / B1 (already filed, KI239).** The never-written refusal is joined into
  one line while the version-skewed refusal beside it still draws one per
  chapter, so the identical sentence draws at two counts. Round 1 took this as
  F5 and D-013 put it in DESIGN Known issues; both lenses re-raised it because
  the diff creates it and the tier is the warning text an author reads. Carried
  as filed, consciously, not silently.
- **B2 (already filed, KI240).** A chapter whose placement marker names an index
  an earlier chapter also places has `mine` empty, so it recovers every
  never-written source and now says nothing about it. Round 1's F6; no suite leg
  exercises the shape.
- **B3 (rejected — no observable symptom remains).** Retiring M069 T6's
  whole-gate inversion plant loses the false-positive-admission mutation class:
  plants 1 and 2 only ever revoke admission, never wrongly grant it. Verified
  against the code — a wrongly admitted chapter is by construction one that
  builds no section, so its recovered terms go nowhere and the report site's
  gate is shut for it; the only remaining symptom is the parse cost already
  accepted as KI227/KI229/KI240. A chapter that does build is admitted by the
  surviving halves either way. The mutation has no correctness consequence left
  to assert.
- **N8 (rejected — unreachable, and out-of-scope class).** `chapter_list`
  returns `""` for an empty list; all three call sites guard with `#... > 0`.
  A hardening suggestion about a fourth site that does not exist.
- **N9 (rejected — style/reuse nitpick).** `check_warning_names_nth` duplicates
  `check_warning_names`; the lens itself calls it quality, not a defect.

### PR conversation

PR #74 carries no reviews, no conversation comments and no unresolved review
threads — the read returned empty on all three surfaces.

Return count: 1 defect return (round 1's). No amendment return. Nothing in
round 2 demonstrates an acceptance criterion failing, so the return floor does
not fire.
