<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M083: The EPUB id-uniqueness sweep goes red on what it claims to catch

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — every deliverable is a check, a plant or a report inside `tests/`, read by no consumer of this repo
- **Branch/PR:** —

## Goal

Each clause of `tests/epubcheck.py unique` is shown red on the defect class it
claims to catch, over a verdict that claims only what the clause swept.

## Scope

**In:** a plant harness for the captured `id-collision.epub`; the plants that
show `unique`'s repeated-id and link-resolving clauses red, and the shapes that
must leave them green; the repair of an external href reported as a missing
manifest item; the narrowing of the verdict and docstring to the one index
section per document the check actually reads.

**Out:** reading every index section of a document → candidate row, promoted on
a publication whose document carries two. The M079-AC1 HTML leg's minted-anchor
map and its CDATA case → M084. The M075 plant helper → M084. The foreign-content
CDATA divergence → its own Known issues entry, unchanged here.

## Acceptance criteria

- [ ] AC1: A plant that copies an existing `id=` onto a second element of one
      XHTML member of the captured `id-collision.epub` makes
      `tests/epubcheck.py unique` exit non-zero with a report naming that id,
      while the same command over the unplanted publication exits 0; both runs
      are legs of `tests/run-tests.sh --self-test`.
- [ ] AC2: `unique`'s verdict and its docstring state that it reads one index
      section per document — the first its heading search finds — so neither
      claims a sweep of every section; a self-test leg asserts the verdict's
      wording over the unplanted publication, and `cairn/DESIGN.md`'s Known
      issues records the sections the check does not read.
- [ ] AC3: A link inside an index section whose href carries a scheme, and one
      whose href opens with `//`, are each planted into a copy of the captured
      publication and leave `unique` green, while a planted dangling relative
      href makes it exit non-zero naming that href; three legs of
      `tests/run-tests.sh --self-test`, one per shape.
- [ ] AC4: `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T3, T4
- AC2 → T2, T5
- AC3 → T1, T3, T4
- AC4 → T1, T2, T3, T4, T5

## Tasks

- [ ] T1: Repair the href reading in `cmd_unique` (`tests/epubcheck.py:288-297`):
      an href carrying a scheme or opening with `//` leaves the publication, so
      it is skipped rather than normalized against the member's directory, and
      the verdict counts it as a link the check did not resolve.
- [ ] T2: Narrow `cmd_unique`'s docstring and verdict (`tests/epubcheck.py:235-262`,
      `:310-316`) to the one index section per document its heading search reads,
      and write the unread sections into `cairn/DESIGN.md`'s Known issues.
- [ ] T3: Build the EPUB plant harness beside the M079-AC2 leg
      (`tests/run-tests.sh:4506-4525`), on `m081_census_plant`'s shape
      (`tests/run-tests.sh:4423`): rewrite one XHTML member of a copy of the
      captured publication, re-run `unique`, and fail unless both the exit
      status and the named substring of the report are what the plant claims.
- [ ] T4: Plant five cases through it — a duplicate id and a dangling relative
      href, each asserted red on its own report; a scheme href, a `//` href and
      a copy that changes nothing, each asserted green.
- [ ] T5: Add the verdict-wording leg over the unplanted publication, asserting
      the section-count sentence T2 writes rather than a substring of the whole
      report.

## Work log

- 2026-09-07: created by /milestone-plan.
- 2026-09-07: plan gate chose narrowing `unique`'s verdict to the first index section over teaching it to read every section, because the repo's checker-regress rule makes simplifying the default whenever a shipped internal checker is about to grow; falsified by a publication reaching this check whose document carries two index sections, or by an index locator into a second section found dangling.
- 2026-09-07: plan gate chose two milestones split by instrument over one of five, because the five landed at about ten tasks and the two halves read different artifacts (an EPUB, a rendered HTML page); falsified by the M084 work turning out to need M083's plant harness rather than its own.
- 2026-09-07: reduced criteria audit ([O], fresh context) returned two findings — AC3's two href shapes were promised without a leg for each, fixed here by naming three legs; and the backtick-escaping rider bound a property of how the suite reports rather than of this milestone's deliverable, taken to the gate and settled as a direct commit outside both milestones.

## Decisions

## Review
