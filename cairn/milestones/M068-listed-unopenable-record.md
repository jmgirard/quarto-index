<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M068: A record that is listed and cannot be opened is not read as one that was never written

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m068-listed-unopenable-record`

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

- [ ] AC1. In the new book fixture, whose store directory lists and holds an
      unopenable record file for one chapter, the render of the chapter that
      builds the book index produces an index section carrying that chapter's
      marked terms, each held row by row in href form against a hand-derived
      manifest for that render.
- [ ] AC2. That same render draws the existing could-not-be-read recovery
      report naming that chapter, asserted message-whole, once per chapter of
      the fixture that reads the store, and the render's extension warnings are
      those reports and nothing else.
- [ ] AC3. The suite's existing cold-first-render control — the
      `place-first` render of `examples/book-placement/` into a tree with no
      store directory — draws no recovery report and matches the
      `PLACE_TERMS_COLD` manifest unchanged.
- [ ] AC4. In the AC1 fixture, every locator belonging to a chapter whose
      record was opened and used carries a page fragment, and every locator
      belonging to the recovered chapter carries none — both held in the same
      manifest AC1 asserts.
- [ ] AC5. `site/books.qmd` and `CHANGELOG.md` each state that a record present
      in a listing store directory and unopenable has its chapter recovered
      from source, and that a file merely named like one counts as written.
- [ ] AC6. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

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
- 2026-09-01: T6 — D-044 appended; `site/books.qmd` and `CHANGELOG.md` state the widened trigger and the named-lookalike boundary; DESIGN.md's recovery prose rewritten, KI205 and KI214 narrowed, KI221 struck and replaced by KI224.

## Decisions

## Review
