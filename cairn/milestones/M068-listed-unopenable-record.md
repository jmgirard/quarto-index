<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M068: A record that is listed and cannot be opened is not read as one that was never written

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m068-listed-unopenable-record` / https://github.com/jmgirard/quarto-index/pull/68

## Goal

In an HTML book, a chapter's sidecar record whose filename appears in the store
directory's listing and which cannot be opened sends the building chapter to
that chapter's own source, as an opened-and-unusable record already does,
rather than being read as a record that was never written.

## Scope

Surface tier: **user-facing** — the deliverable is what an author's book index
prints and what the render tells them, not an internal artifact.

**In:**

- The store probe in `_extensions/index/modules/book.lua`: one listing of the
  store directory per render, whose entry names `store_read` then tests each
  unopenable record against. A record whose own filename is in that listing
  takes the unusable branch and is recovered from its chapter's source; one
  whose name is absent stays on the absent branch, so a first render and a tree
  with no store are untouched.
- The directory-level case D-043 decided (the store directory cannot be listed
  and its own name is in the parent's listing) is subsumed by the same probe
  and keeps its behavior.
- A cross-cutting decision entry extending D-043's trigger from the store
  directory to the record file, carrying the boundary the plan gate accepted:
  a file merely *named* like a record and unopenable — a broken symlink an
  author made by hand — counts as written and is recovered. The name's presence
  in the listing is the evidence a record was written there; no render produces
  a file of that name it cannot open.
- Acceptance-suite fixture and checks for the listed-but-unopenable record,
  built from a dangling symlink at the record path rather than from permission
  bits, which differ between the machines the suite runs on.
- Author-facing documentation of the widened trigger in `site/books.qmd` and
  `CHANGELOG.md`; `cairn/DESIGN.md`'s recovery prose and KI221 updated to match.

**Out:**

- Recovering a record that is genuinely ABSENT — a book's first render into a
  tree whose records cannot be written (KI205). Stays the recovery-follow-ups
  candidate row.
- Minting a fragment for a recovered locator, so it links to the term rather
  than the chapter's page. Stays the same candidate row.
- Refusing a chapter source Pandoc's markdown reader should not be given, and
  the terms it silently refiles (KI219). Stays the same candidate row; the
  intended next milestone after this one.
- Reaching a mark carried in a chapter's metadata. Stays the same candidate row.
- Telling a real unopenable record from a hand-made lookalike. Declined at the
  plan gate: Pandoc's Lua interface exposes no test that separates them. The
  state is recorded as a known issue and named in the new entry's falsifier.

## Acceptance criteria

- [x] AC1. In the new book fixture, whose store directory lists and holds an
      unopenable record file for one chapter, the render of the chapter that
      builds the book index produces an index section carrying that chapter's
      marked terms, each held row by row in href form against a hand-derived
      manifest for that render.
- [x] AC2. That same render draws the existing could-not-be-read recovery
      report naming that chapter, asserted message-whole, once per chapter of
      the fixture that reads the store, and the render's extension warnings are
      those reports and nothing else.
- [x] AC3. The suite's existing cold-first-render control — the
      `place-first` render of `examples/book-placement/` into a tree with no
      store directory — draws no recovery report and matches the
      `PLACE_TERMS_COLD` manifest unchanged.
- [x] AC4. In the AC1 fixture, every locator belonging to a chapter whose
      record was opened and used carries a page fragment, and every locator
      belonging to the recovered chapter carries none — both held in the same
      manifest AC1 asserts.
- [x] AC5. `site/books.qmd` and `CHANGELOG.md` each state that a record present
      in a listing store directory and unopenable has its chapter recovered
      from source, and that a file merely named like one counts as written.
- [x] AC6. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T4
- AC4 → T2, T3
- AC5 → T6
- AC6 → T3, T4, T5

## Tasks

- [x] T1. Add a suite helper beside `m061_block_record`
      (`tests/run-tests.sh:7134`) that leaves a dangling symlink at a chapter's
      record path, asserting that the path is a symlink whose target is absent
      and that its name appears in the store directory's listing — so a run
      whose fixture silently became an ordinary record fails rather than
      passing. Build the AC1 fixture over `examples/book-placement/` with it.
- [x] T2. Rewrite the probe at `_extensions/index/modules/book.lua:179`: list
      the store directory once per render and keep the entry names; in
      `store_read` (`book.lua:777`), a record `io.open` cannot open whose own
      filename is among them takes the unusable branch. Preserve the
      directory-level case and the once-per-render listing, both of which
      D-043's cost argument rests on.
- [x] T3. Suite checks for AC1, AC2 and AC4 over the new fixture: the href-form
      section manifest, the recovery report asserted message-whole with its
      per-chapter cadence, and the total extension-warning count.
- [x] T4. Hold the cold control (AC3) against the widened probe, and add a
      second control on a store directory that lists and holds no record for
      the chapter at all — the case that separates "name absent" from "name
      present and unopenable".
- [x] T5. `--self-test` plants, one per axis the probe is free in: the
      per-record name test removed; the test inverted; the parent's listing
      consulted where the store's own is meant; the listing taken once per
      record rather than once per render; the name compared as a joined path
      rather than a basename. Each shown red against the check it fences
      before its green is trusted.
- [x] T6. The decision entry extending D-043; `site/books.qmd` and
      `CHANGELOG.md` (AC5); `cairn/DESIGN.md`'s recovery prose; KI221 struck
      and a known issue added for the hand-made lookalike the new trigger
      recovers.
- [x] T7. `store_probe` (`book.lua:216`): a directory whose own listing fails
      takes the `lost` answer of the directory above it, so D-043's
      directory-level case reaches a record at any depth rather than only one
      sitting directly in the store. Probe comment corrected to state it (F1).
- [x] T8. The nested legs, over a copy of `examples/book` whose `sub/two.qmd`
      keeps its record one level down in the store: an unlistable store
      directory above that chapter, and a dangling record whose basename the
      store's top level does not list. Both assert the two listings differ (F2).
- [x] T9. Two self-test plants on the axes only a subdirectory chapter is free
      in — the inherited answer dropped, and the store's top level consulted
      where the record's own directory is meant — each shown red against the
      leg that fences it; the flat parent-listing plant's comment corrected to
      what it does and does not fence (F2).
- [x] T10. Suite hygiene on M068's own checks and the prose the fix bears on:
      the marker-position pair named so all seven warnings of the AC2 render
      are accounted for by kind (F4); the name-absent control's store
      re-asserted short one record and non-empty before its second leg (F7);
      `cairn/DESIGN.md`'s recovery prose made explicit about depth and a known
      issue added for the hand-made link at the store DIRECTORY path (F3, F5).

## Work log

- 2026-09-01: created by /milestone-plan.
- 2026-09-01: plan gate chose a per-record filename-presence test over a per-record `io.open` error-message read and over leaving the probe at the directory level, because the listing already distinguishes written from never-written without reading an error string and keeps D-043's one-listing-per-render cost; falsified by a first render, or a tree with no store directory, drawing a recovery report.
- 2026-09-01: plan gate chose a dangling symlink as the fixture mechanism over permission bits, because the suite runs on machines whose permission semantics differ and a root-run render ignores the bits entirely; falsified by a supported Pandoc opening a dangling symlink successfully.
- 2026-09-01: criteria audit ran in FULL mode ([O], fresh context) and returned seven findings — AC2's warning count unsatisfiable as a total of one, AC4 promising a global invariant off one fixture and naming no antecedent, AC3 satisfiable without rendering, AC5 half instrument-bound, AC5's residual misnaming KI221's remainder, the plant family covering one site in two forms, and two apparent coverage gaps that are not gaps. All fixed at the gate before this file was written.
- 2026-09-01: question gate chose the record's OWN directory listing over the store's top-level listing, because a chapter in a subdirectory keeps its record in a matching subdirectory of the store and two chapters of one filename share a record basename — compared against the top level alone, a never-written record of the second would read as written and a first render would recover it, D-043's own falsifier; the listing is remembered per directory, so a flat book still lists once per render.
- 2026-09-01: question gate chose to hold the once-per-render listing by counting the listings themselves in an instrumented copy, because taking the listing per record changes no output at all — the store is read before the chapter writes — and no manifest or warning count can show that plant red.
- 2026-09-01: T2 — `store_directory_unusable` replaced by `store_probe`, a memoized per-directory listing whose returned test answers "was this record written"; `store_read` consults it per unopenable record. D-043's directory-level case is the same probe's `lost` branch, unchanged.
- 2026-09-01: T1/T3 — `m068_dangle_record` plants a symlink whose target is inside a directory that does not exist, so `store_write` cannot follow it and heal the fixture between two renders; `m068_assert_dangling` holds all three facts before each render and after it. AC1/AC2/AC4 asserted over two consecutive whole-book renders.
- 2026-09-01: T4 — the cold `place-first` control stands unchanged (AC3), and the name-absent control runs in two legs, because a whole-book render lets four.qmd rewrite its own record before the chapter that builds the section reads it; the second leg renders five.qmd alone.
- 2026-09-01: T5 — five plants, each shown red against the check that fences it: the name test removed, the name compared as a joined path, the parent's listing consulted (all three leave four.qmd's terms out in silence), the test inverted (recovers a record no render wrote, refused by the name-absent control), and the memoized listing dropped (5 listings become 8 over a book with two records dangling). M065-AC5's own probe-disabling plant repointed at `store_probe`.
- 2026-09-01: two existing readers repointed at the widened behavior rather than left stating the superseded one: `site/books.qmd`'s two pinned store-directory claims became four, and M063-AC6's self-test guard, which names the claim count, moved from 21 to 23.
- 2026-09-01: `tests/run-tests.sh` exits 0 plain (593 checks) and with `--self-test` (1119 checks); status set to review.
- 2026-09-01: T6 — D-044 appended; `site/books.qmd` and `CHANGELOG.md` state the widened trigger and the named-lookalike boundary; DESIGN.md's recovery prose rewritten, KI205 and KI214 narrowed, KI221 struck and replaced by KI224.
- 2026-09-01: review opened; draft PR #68 pushed, PR URL recorded in the header.
- 2026-09-01: review returned M068 to in-progress at the merge gate. What failed: F1 — `store_probe` does not propagate its `lost` answer down a directory chain, so a chapter whose record sits in a store subdirectory takes the ABSENT branch under an unlistable store directory and loses its terms in silence, which `origin/main` did not and which D-044's own decision text forbids; F2 — no fixture has a chapter in a subdirectory, so that axis is fenced by nothing. Six acceptance criteria verified, consistency gate clean; no merge, no approval marker written.
- 2026-09-02: question gate chose the existing `examples/book` as the fixture carrying the subdirectory chapter (it already has one, with a warm store and a last chapter that builds the index) over nesting a placement chapter or committing a fifth example book; chose to fence both the returned defect and the store-top-level lookup the plan gate rejected, since only the second tells the chosen lookup from that rival; and chose to hold the six criteria as written, the nested case being a defect against the Scope clause promising the directory-level case keeps its behavior rather than new ground (D-118: no criterion added).
- 2026-09-02: T7-T10 written, checks not yet run: `store_probe` hands a lost directory's answer down the chain (F1); two nested legs over a copy of `examples/book` (F2); two self-test plants on the axes only a subdirectory chapter is free in (F2); the marker-position pair named so all seven AC2 warnings are accounted for by kind (F4); the name-absent control re-guarded before its second leg (F7); DESIGN.md's recovery prose made explicit about depth and KI225 added for the hand-made link at the store directory path (F3, F5). Checkpoint only — the profile's verify slot has not passed yet.
- 2026-09-02: T7 — the fix verified on a scratch extraction of `store_probe` run under `pandoc lua` before the suite: with the store directory replaced by a file the probe answers "written" for a flat record, one one level down and one three levels down, and with no store directory, or no `.quarto` at all, it answers "never written" for all three.
- 2026-09-02: T8/T9 — the nested legs and their two plants derived by hand from a copy of `examples/book` rendered in a scratch tree before being written into the suite: pre-fix, the unlistable-store leg left `sub/two.qmd` unrecovered, unreported and its terms gone from the index; post-fix it is recovered and reported by name. `Shared Term`, marked in all three of index.qmd, one.qmd and sub/two.qmd, is what each leg reads — under the unlistable store every locator loses its fragment, under the dangling nested record only the recovered chapter's does.
- 2026-09-02: the first run failed at M24-AC3, the suite's own rule that every render is followed by the capture helper; the warm render of the nested fixture was not. Capture added and `tests/suitescan.py pairs` re-run clean.
- 2026-09-02: `tests/run-tests.sh` exits 0 plain (605 checks, was 593) and with `--self-test` (1140 checks, was 1119); status set back to review.
- 2026-09-02: second review pass — fresh evidence for all six criteria (605 plain, 1140 self-test), consistency gate clean, three-lens fan-out; eight findings from the [O] lens, the first-pass F1/F2 nested defect verified fixed at unit level and by two render legs.

## Decisions

## Review

Second review pass. Fresh evidence taken 2026-09-02 on branch
`m068-listed-unopenable-record` against `origin/main`, which has not moved
since the branch was cut (`git fetch`; `HEAD..origin/main` empty). PR #68.
The first pass returned the milestone at the merge gate on 2026-09-01; its
findings and triage are in the work log and in git.

### Acceptance criteria

- **AC1 — verified.** `tests/run-tests.sh` exits 0 (605 checks). Over the
  `m068-dangling` fixture, whose store directory lists 5 entries one of which
  is a dangling symlink at four.qmd's record path, each of two consecutive
  whole-book renders carries 3 generated index sections over 5 pages and 15
  printed terms, each in the section the manifest names; five.qmd's gamma
  section matches all 21 manifest rows in href form, in order. The fixture is
  re-asserted dangling and listed after each render, so a run whose symlink
  healed fails rather than passing.

- **AC2 — verified.** In the same two renders the could-not-be-read recovery
  report naming four.qmd is drawn message-whole 4 times — once for each of
  index.qmd, two.qmd, three.qmd and five.qmd, four.qmd never reading its own
  record — the three sibling recovery wordings (lost, no-marks, stale) are
  each drawn 0 times, the unwritable-record report once, and the two
  marker-position reports are now named by kind as well, so all 7 `(W) ` lines
  of the render are accounted for by named kind rather than by a raw total.

- **AC3 — verified.** The `place-first` leg renders `examples/book-placement/`
  from an empty store, prints 3 sections over 5 pages against
  `PLACE_TERMS_COLD` — a manifest this diff does not touch, no added or
  removed line naming it — and holds that render's extension warnings to the
  fixture's own 2 marker-position reports, so no recovery report is drawn. The
  name-absent control passes beside it: a store listing 4 records and holding
  none for four.qmd recovers nothing and says nothing, and five.qmd rendered
  alone prints the gamma section short all 8 of four.qmd's terms in silence.
  That control's store is re-asserted non-empty and short four.qmd's record
  immediately before the second leg, not only before the first.

- **AC4 — verified.** Inside the same 21-row manifest AC1 asserts, held in
  href form: four.qmd's 8 locators point at that chapter's page with no
  fragment, and every locator belonging to a chapter whose record was opened
  and used carries its fragment. Both renders match, in order.

- **AC5 — verified.** Read on the branch: `site/books.qmd` states that a
  record that is there and cannot be opened is told from an absent one by the
  listing of the directory it belongs in, so it is read back from its source,
  and that a file merely named like a record and unopenable counts as one that
  was written. `CHANGELOG.md` states both in its own entry. Two pinned claim
  rows became four and M063-AC6's self-test guard moved from 21 to 23.

- **AC6 — verified.** Run sequentially per the profile: `tests/run-tests.sh`
  exits 0 with 605 checks, `tests/run-tests.sh --self-test` exits 0 with 1140.
  Among the latter, seven M068 plants each go red against the check fencing
  them before their green is trusted — the name test removed, the name
  compared as a joined path and the parent's listing consulted each drop
  four.qmd's terms to 7 printed in silence; the test inverted recovers a
  record no render wrote and reports it 3 times; dropping the remembered
  listing takes a two-dangling-record book from 5 store listings to 8; the
  lost answer not handed down drops sub/two.qmd's terms in silence under an
  unlistable store; and the store's top level consulted for a record one level
  down does the same.

### Nested-case evidence (the first pass's F1/F2)

The two nested legs run over a copy of `examples/book`, whose `sub/two.qmd`
keeps its record one level down in the store. Under a store directory replaced
by a file, sub/two.qmd is recovered from its source and reported by name, its
`Beacon` term reaches the index pointing at its page, and every locator of the
entry all three chapters mark loses its fragment. Under a dangling record one
level down whose basename the store's top level does not list, only that
chapter loses its fragment while index.qmd and one.qmd keep theirs. Both legs
assert the two listings differ before rendering.

### Consistency gate

- `cairn_validate.py` exits 0: 16 checks PASS, 7 advisories OK. The `release
  window` advisory did not fire.
- No `IP`/`GP` principle text changed in `cairn/DESIGN.md`, so `cairn_impact`
  does not apply.
- Toolchain half: the `generic` profile's `consistency-gate` slot names no
  checks. Clean no-op.

### Independent review

Full three-lens fan-out (user-facing tier; the diff touches
`_extensions/index/modules/book.lua` and `tests/run-tests.sh`). Fresh
contexts, distinct evidence bases, ref-based git only.

- **[S] blame-history:** no findings. D-043's directory-level test survives
  whole inside `store_probe`'s `lost` branch; the per-directory memoization is
  D-044's restated cost rule, not an undocumented loosening; the M065-AC5
  probe-disabling plant was repointed correctly and still exercises the defect
  it always fenced.
- **[S] prior-review-record:** no findings. The `gh` inline-comment probe
  returned empty, so no PR-thread walk was warranted; the archived `## Review`
  sections show no prior finding on these files reintroduced, and the fix pass
  honours each disposition the first pass recorded.
- **[O] diff-bug:** eight findings, ranked below.

### Findings

Ranked most severe first. Dispositions are recorded at the merge gate.

- **G1. `book.lua:222-230` — the `lost` chain answers "written" for every
  record path when the store directory does not exist and `.quarto` itself
  cannot be listed.** `lost` now means "some ancestor is out of reach" and is
  handed down to a directory whose own listing failed because it is not there.
  Verified independently of the reviewer's account, by extracting `store_probe`
  verbatim into a scratch file and running it under `pandoc lua` beside
  `origin/main`'s `store_directory_unusable` extracted the same way: with no
  `.quarto/quarto-index` at all, a `.quarto` that is a regular file and a
  `.quarto` at `a-r` both make the branch answer `true` for a flat record, one
  one level down and three levels down, where main answers `false`; with no
  `.quarto` the branch answers `false` for all three, as main does.
  **Not reachable through a render**, which is the half that decides its
  weight: `quarto render` of the fixture book aborts before the extension
  loads in both shapes — `ERROR: PermissionDenied ... readdir '.../.quarto'`
  with the read bit gone, and `ERROR: Failed to ensure directory exists:
  expected 'dir', got 'file'` with a file in its place. No author-visible
  failure follows, and no acceptance criterion fails.

- **G2. `cairn/DESIGN.md:479`, `site/books.qmd`, `CHANGELOG.md`,
  `cairn/DECISIONS.md` D-044 — the "never fires on a record that is simply
  ABSENT" claim is false at the unit level.** Follows from G1 and is bounded
  the same way: the claim holds for every tree state a render can reach, and
  fails only in the two shapes quarto itself refuses.

- **G3. `tests/run-tests.sh` — no leg exercises the upward walk in the
  negative direction, which is why G1 escaped.** Every M068 leg puts the
  unlistable directory at or below the store, where the walk is meant to fire.
  A leg above the store cannot be written as a render check at all, per G1's
  render evidence; it would have to be a unit-level probe check, which this
  suite has no shape for.

- **G4. `tests/run-tests.sh:8469` — `m068_nested_render`'s raw warning-line
  assertion overstates what it fenced.** Its failure text says the kinds the
  check counts by name account for the total, but the kinds named inside the
  function come to 5 of the unlistable leg's 6; the sixth,
  `WARN_STORE_UNWRITABLE`, is named just after the call. The total is pinned
  by kind across the two; only the message is wrong.

- **G5. `tests/run-tests.sh:8662-8712` — `m068_nested_silent`, carrying the
  two nested plants, pins no total warning-line count.** It holds three
  recovery wordings absent and the terms missing, so a mutation that produced
  the intended silence plus some unrelated extension warning would still score
  as the intended defect.

- **G6. `tests/run-tests.sh:8204-8256` — `m068_assert_dangling` and
  `m068_assert_listing` die with a Python traceback rather than a `FAIL:`
  line when handed a directory that is missing or unlistable.** `os.listdir`
  raises; under `set -euo pipefail` the run aborts as a crash rather than as a
  named check.

- **G7. `book.lua:203-204` — the comment's laziness claim ("a book whose
  records all open lists nothing at all") is fenced by nothing.** Both
  listing-count plants run over trees with dangling records, where an eager
  implementation would score the same 5 the lazy one does.

- **G8. `cairn/DESIGN.md:463` — one new line is 86 characters where the
  paragraph around it wraps at ~78.**

### Triage

Presented at the merge gate 2026-09-02.

Defect returns for M068: 1 (the first pass). This pass adds none: G1 is the
only finding of return-floor weight and it fails no acceptance criterion —
AC3's named procedure is the `place-first` cold render, which passes — and it
is not reachable by an author, so it is not a load-bearing defect in what the
extension does for its users.
