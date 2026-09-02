<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M069: A chapter no render has written a record for reaches the book index where its terms would otherwise be lost

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Branch/PR:** —

## Goal

In an HTML book, a chapter for which no render has written a sidecar record has
its own source read by the chapter that prints an index section, so a book
rendered into a tree whose records cannot be written prints an index carrying
every chapter's terms rather than one short of them.

## Scope

Surface tier: **user-facing** — the deliverable is what an author's book index
prints and what the render tells them, not an internal artifact.

**In:**

- The gate in `_extensions/index/modules/book.lua`: a record `io.open` cannot
  open and whose name the store probe finds in no listing is recovered from its
  chapter's source when the reading chapter carries a placement marker of its
  own, or is the book's last chapter, and is treated as absent in every other
  chapter. Both halves are known before the store is read — the marker set from
  `resolve_markers` at `book.lua:1227`'s caller, the position from
  `ctx.position` and `ctx.chapters` — so the gate needs nothing the store
  answers.
- A fourth recovery wording, drawn only on the new branch, naming the record as
  one no render has written; the three wordings at `book.lua:887-891` keep
  their cases and their text.
- A chapter with no record whose source parses to no index mark is silent: a
  chapter that legitimately marks nothing has lost nothing, and the existing
  no-marks report would fire for every such chapter of a correct book on every
  render.
- A cross-cutting decision entry superseding D-041's never-fires-on-an-absent-
  record clause and restating the falsifier D-043 and D-044 both carry, against
  the new gate rather than against absence.
- Acceptance-suite fixture over a store-less copy of `examples/book-placement/`,
  whose markers sit in `index.qmd` and `three.qmd` and whose `two.qmd` and
  `four.qmd` carry none — the two negative controls the gate needs.
- Author-facing documentation in `site/books.qmd` and `CHANGELOG.md`;
  `cairn/DESIGN.md`'s recovery prose with KI205 and KI214 narrowed to what
  remains.

**Out:**

- A chapter that neither carries a placement marker nor is the book's last
  still reads an absent record as absent, so its own page's per-chapter view
  of the store is unchanged. This is the accepted cost of the gate, named in
  the new decision's consequences and in what remains of KI205.
- Minting a fragment for a recovered locator. Stays the recovery-follow-ups
  candidate row, narrowed there to the author-written-id half.
- Refusing a chapter source Pandoc's markdown reader should not be given, and
  reaching a mark a chapter writes in its front matter → M070.
- Bounding the cost of a store-less render, where one chapter parses every
  other chapter's source. Unmeasured at book sizes and recorded as KI217's
  sibling, not fixed here.

## Acceptance criteria

- [ ] AC1. In a render of every chapter of a copy of `examples/book-placement/`
      whose project tree holds no sidecar store at all, `index.html` and
      `five.html` each print index sections carrying the terms every other
      chapter of that fixture marks in its markdown body, held row by row in
      href form against a hand-derived manifest for that render, each recovered
      term's locator a link to that chapter's page with no fragment.
- [ ] AC2. On that same render, `two.html` and `four.html` — the fixture's
      chapters that carry no placement marker and are not its last — print no
      index section, and neither render draws any report about another
      chapter's record.
- [ ] AC3. A chapter recovered because no render has written its record is
      reported by a wording that names the record as one no render has written,
      asserted message-whole with its per-chapter cadence; the three
      could-not-be-read wordings are unchanged and still drawn, message-whole,
      by the `m068-dangling` fixture.
- [ ] AC4. A whole-book render of `examples/book` into a writable tree draws no
      report of any wording this route draws — the never-written wording this
      milestone adds and the three could-not-be-read wordings alike — and
      matches its existing term manifest unchanged.
- [ ] AC5. On the AC1 render, a chapter with no record whose source cannot be
      read draws the report naming that outcome, and a chapter with no record
      whose source parses to no index mark draws nothing at all.
- [ ] AC6. `site/books.qmd` and `CHANGELOG.md` each state that a chapter
      carrying a placement marker, and the book's last chapter, read another
      chapter's source where no record for it has been written, that no other
      chapter does, and that a chapter recovered this way contributes no
      fragment to its locators.
- [ ] AC7. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T3
- AC3 → T2, T4
- AC4 → T5
- AC5 → T2, T4
- AC6 → T7
- AC7 → T6, T7

## Tasks

- [ ] T1. The gate in `store_read` (`book.lua:825`): thread the reading
      chapter's own placement-marker set and its last-chapter answer in from
      the caller at `book.lua:1227`, and take the recovery branch for a record
      the probe reports never written only when one of the two holds. A record
      the probe reports written keeps M068's behavior in every chapter.
- [ ] T2. The fourth wording beside `book.lua:887-891`, drawn only on the
      never-written branch, and the silent outcome for a never-written record
      whose source parses to no mark. `tests/scans/warn-distinct.py`'s EXPECTED
      count moves with it.
- [ ] T3. The store-less fixture over `examples/book-placement/` — a tree with
      no `.quarto` directory at all, re-asserted absent around every render —
      the href-form section manifests for `index.html` and `five.html` (AC1),
      and the two negative controls asserting `two.html` and `four.html` carry
      no index section and draw no report (AC2).
- [ ] T4. Checks for AC3 and AC5 over that fixture: the new report asserted
      message-whole and counted by kind, one leg whose chapter source is made
      unreadable, and one unmarked chapter asserted to draw nothing; the
      render's whole extension-warning count accounted for by name.
- [ ] T5. AC4's control: `examples/book` rendered whole into a writable tree,
      asserted to draw no wording of this route and to match its term manifest.
- [ ] T6. `--self-test` plants, one per axis the gate is free in, each shown red
      against the check that fences it before its green is trusted: the marker
      half of the gate removed; the last-chapter half removed; the gate
      inverted; the never-written wording swapped for the could-not-be-read
      one; and the parses-to-no-mark branch made to report.
- [ ] T7. The decision entry superseding D-041's never-fires clause and
      restating D-043's and D-044's falsifier against the gate; `site/books.qmd`
      and `CHANGELOG.md` (AC6); `cairn/DESIGN.md`'s recovery prose, with KI205
      and KI214 narrowed to the chapters the gate leaves out.

## Work log

- 2026-09-02: created by /milestone-plan.
- 2026-09-02: plan gate chose recovery gated on the reading chapter carrying a placement marker or being the book's last over recovering an absent record in every chapter, because both halves are known before the store is read and an ordinary book keeps its marker in the last chapter, so a first render into a writable tree still recovers nothing; falsified by a first render into a writable tree drawing a recovery report, or by an author reporting a book whose index section chapter is neither of the two.
- 2026-09-02: plan gate chose silence for a never-written record whose source parses to no mark over reusing the existing no-marks report, because in a store-less tree every legitimately unmarked chapter would draw that report on every render and nothing was lost; falsified by an author unable to tell a chapter whose marks failed to recover from one that marks nothing.
- 2026-09-02: criteria audit ran in FULL mode ([O], fresh context) and returned findings on all five drafted criteria — AC1 unbounded over an unnamed book and its locator clause false for a cross-reference-only mark, AC2 vacuous and resting on a pre-branch output comparison D-004 refused, AC3 promising distinctness `tests/scans/warn-distinct.py` already guarantees and half instrument-bound, AC4 miscounting a set of three as two, AC5 ambiguous across six wordings and mandating a report per unmarked chapter. All fixed before this file was written; the report-per-unmarked-chapter finding went to the question gate.

## Decisions

## Review
