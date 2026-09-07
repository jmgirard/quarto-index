<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M083: The EPUB id-uniqueness sweep goes red on what it claims to catch

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — every deliverable is a check, a plant or a report inside `tests/`, read by no consumer of this repo
- **Branch/PR:** `m083-epub-unique-instruments` / https://github.com/jmgirard/quarto-index/pull/83

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

- [x] AC1: A plant that copies an existing `id=` onto a second element of one
      XHTML member of the captured `id-collision.epub` makes
      `tests/epubcheck.py unique` exit non-zero with a report naming that id,
      while the same command over the unplanted publication exits 0; both runs
      are legs of `tests/run-tests.sh --self-test`.
- [x] AC2: `unique`'s verdict and its docstring state that it reads one index
      section per document — the first its heading search finds — so neither
      claims a sweep of every section; a self-test leg asserts the verdict's
      wording over the unplanted publication, and `cairn/DESIGN.md`'s Known
      issues records the sections the check does not read.
- [x] AC3: A link inside an index section whose href carries a scheme, and one
      whose href opens with `//`, are each planted into a copy of the captured
      publication and leave `unique` green, while a planted dangling relative
      href makes it exit non-zero naming that href; three legs of
      `tests/run-tests.sh --self-test`, one per shape.
- [x] AC4: `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T3, T4
- AC2 → T2, T5
- AC3 → T1, T3, T4
- AC4 → T1, T2, T3, T4, T5

## Tasks

- [x] T1: Repair the href reading in `cmd_unique` (`tests/epubcheck.py:288-297`):
      an href carrying a scheme or opening with `//` leaves the publication, so
      it is skipped rather than normalized against the member's directory, and
      the verdict counts it as a link the check did not resolve.
- [x] T2: Narrow `cmd_unique`'s docstring and verdict (`tests/epubcheck.py:235-262`,
      `:310-316`) to the one index section per document its heading search reads,
      and write the unread sections into `cairn/DESIGN.md`'s Known issues.
- [x] T3: Build the EPUB plant harness beside the M079-AC2 leg
      (`tests/run-tests.sh:4506-4525`), on `m081_census_plant`'s shape
      (`tests/run-tests.sh:4423`): rewrite one XHTML member of a copy of the
      captured publication, re-run `unique`, and fail unless both the exit
      status and the named substring of the report are what the plant claims.
- [x] T4: Plant five cases through it — a duplicate id and a dangling relative
      href, each asserted red on its own report; a scheme href, a `//` href and
      a copy that changes nothing, each asserted green.
- [x] T5: Add the verdict-wording leg over the unplanted publication, asserting
      the section-count sentence T2 writes rather than a substring of the whole
      report.

## Work log

- 2026-09-07: created by /milestone-plan.
- 2026-09-07: plan gate chose narrowing `unique`'s verdict to the first index section over teaching it to read every section, because the repo's checker-regress rule makes simplifying the default whenever a shipped internal checker is about to grow; falsified by a publication reaching this check whose document carries two index sections, or by an index locator into a second section found dangling.
- 2026-09-07: plan gate chose two milestones split by instrument over one of five, because the five landed at about ten tasks and the two halves read different artifacts (an EPUB, a rendered HTML page); falsified by the M084 work turning out to need M083's plant harness rather than its own.
- 2026-09-07: T1 — `cmd_unique` skips an href whose file part leaves the publication (a `//` opening or a `scheme:` opening) instead of joining it to the linking member's directory, and the verdict counts those separately. Both shapes were red before the change, reported as naming a manifest item the publication does not list; both are green after. Checkpoint: the verify suite is still running, so T1 is not ticked.
- 2026-09-07: T1 ticked — `tests/run-tests.sh` green, 777 checks, the `unique` leg's verdict reading `0 fragment-carrying link(s) leave the publication and were not resolved`.
- 2026-09-07: T2 — `cmd_unique`'s docstring and verdict now name the one index section per document the heading search reads; `cairn/DESIGN.md` records the unread ones as KI264, cross-referencing KI51. `tests/run-tests.sh` green, 777 checks.
- 2026-09-07: T3/T4/T5 — the EPUB plant harness sits beside the M079-AC2 leg: a Python rewriter repacks the captured `.epub` member for member, substituting one run of text in one XHTML member, and dies on a member it does not hold, a pattern matching nothing, or a substitution leaving the text unchanged. Five plants run through it (duplicate id and dangling relative href red on their own reports; scheme href and `//` href green with one link counted as leaving the publication; a rewrite-nothing repack green with none), plus the verdict-wording leg. Question gate chose the Python rewriter over unzip/rezip, a counted rather than silent skip for outside links, and asserting the count on the two green plants so a plant that deleted the link could not pass as one that rewrote it.
- 2026-09-07: `tests/run-tests.sh --self-test` green, 1435 checks; the six new legs are checks 90-95. Before T1 both outside-href plants were red, reported as naming a manifest item the publication does not list, so the two green legs bind that repair.
- 2026-09-07: reduced criteria audit ([O], fresh context) returned two findings — AC3's two href shapes were promised without a leg for each, fixed here by naming three legs; and the backtick-escaping rider bound a property of how the suite reports rather than of this milestone's deliverable, taken to the gate and settled as a direct commit outside both milestones.
- 2026-09-07: review — the four criteria met on fresh evidence from a green `--self-test` run (exit 0, 1435 checks); the cairn gate passed with no advisory firing; the three-lens fan-out returned fourteen findings, eight taken to the gate as fix-now, four as follow-ups and two rejected, none reaching the return floor.
- 2026-09-07: gate — the eight fix-now findings applied on the branch and the suite re-run green (exit 0, 1434 checks); the verdict-wording leg and a new pin on the skipped-link count moved onto the captured publication and out of `--self-test`, so an ordinary run now catches an index locator the check would skip.
- 2026-09-07: step-7 approval: PR #83 approved for merge.

## Decisions

## Review

Evidence gathered 2026-09-07 on `a9ecec4` against `origin/main`, from one
`tests/run-tests.sh --self-test` run (exit 0, 1435 checks) plus direct
`tests/epubcheck.py unique` runs over the captured publication.

**AC1 — met.** Self-test check 92: the plant copying `id="qi-entry-2"` to
`id="qi-entry-1"` in `EPUB/text/ch002.xhtml` of a repacked copy makes `unique`
exit non-zero on the report `EPUB/text/ch002.xhtml carries the id 'qi-entry-1'
more than once`. The same command over the unplanted captured publication
exits 0 (the M079-AC2 leg, `tests/run-tests.sh:4524`, and a direct run here:
`20 manifest-listed document(s)`, `68 fragment(s)`, `1 generated index
section(s)`, `0 ... leave the publication`). Both legs run under `--self-test`.

**AC2 — met.** The verdict over the unplanted captured publication reads
`... each of the 68 fragment(s) linked from the 1 generated index section(s) —
the first, and the only index section this check reads in each document that
carries one — names an id ...`, so it does not read as a sweep of every
section. `cmd_unique`'s docstring (`tests/epubcheck.py:268-274`) states the
same in its own paragraph. Self-test check 91 asserts the sentence
`the only index section this check reads in each` rather than a substring of
the whole report. That leg runs over `clean.epub` — the member-for-member
repack with no substitution — rather than over the captured file itself; the
repack is bound green with `0 ... leave the publication` by check 90 in the
same block. `cairn/DESIGN.md` records the unread sections as KI264,
cross-referencing KI51.

**AC3 — met, three legs, one per shape.** Check 94 (scheme href
`https://example.invalid/ch018.xhtml#qi-mark-39`): green, report carrying
`1 fragment-carrying link(s) leave the publication`. Check 95 (`//` href
`//example.invalid/ch018.xhtml#qi-mark-39`): green, same count. Check 93
(dangling relative href `ch018.xhtml#qi-mark-no-such`): non-zero, report
naming `ch018.xhtml#qi-mark-no-such names an id EPUB/text/ch018.xhtml carries
0 time(s)`. All three are `--self-test` legs of `tests/run-tests.sh`. Before
T1 the two outside-href shapes were red, reported as naming a manifest item
the publication does not list (implement work log), so the two greens bind
that repair.

**AC4 — met.** `tests/run-tests.sh --self-test` exits 0 with `All checks
passed (1435 checks)`; the six M083 legs are checks 90-95. No FAIL line in the
run.

### Consistency gate

`cairn_validate.py` exit 0, every check PASS, every advisory OK — the release
window advisory did not fire. No principle changed, so `cairn_impact.py` was
not run. The `generic` profile's `consistency-gate` slot names no toolchain
checks, so that half is a no-op. Diffstat against `origin/main`: 5 files,
+209 / -11 (`tests/run-tests.sh` +152, `tests/epubcheck.py` +40 -4,
`cairn/DESIGN.md` +7, the milestone file, the ROADMAP row).

### Independent review

Three fresh-context reviewers, distinct evidence bases, none having seen the
implementation: [O] diff-bug on the full diff, [S] blame-history on the
touched lines' own commits, [S] prior-review over the archived `## Review`
sections (its GitHub probe returned an empty list, so that surface was not
walked). Fourteen findings, ranked by their own reviewers, listed with their
dispositions below.

**Findings and dispositions.** ([O] diff-bug, [B] blame-history,
[P] prior-review; ranks are each reviewer's own.)

- [O]1 The new outside-link skip is unpinned on the real publication in an
  ordinary run: the M079-AC2 leg (`tests/run-tests.sh:4524`) asserts exit
  status only, and the `0 ... leave the publication` count is asserted only
  inside `--self-test`, so a regression emitting absolute index locators would
  be skipped silently and the default run stay green. **Fix now.**
- [O]2 Both count assertions are unanchored substrings and match the wrong
  number: `grep -qF -- '1 fragment-carrying link(s) leave the publication'`
  matches a verdict reading `11 ...`, and the `clean` control's `0 ...`
  matches `10 ...`. Confirmed here by running the greps against a synthetic
  verdict. Including the `; ` separator fixes all three
  (`tests/run-tests.sh:4642, 4669, 4674`). **Fix now.**
- [P]1 The `outside` count prints only in the `ok` sentence; every FAIL path
  of `cmd_unique` (`tests/epubcheck.py:328-342`) goes silent on it, the shape
  the M45 review fixed and LESSONS.md line 45 records — and the docstring the
  diff adds claims the followed-link count "stays the count it could have
  caught something in" while that figure is invisible on a red run. The
  silence is pre-existing for `sections` and `fragments`; this diff adds a
  third figure to it. **Fix now.**
- [B]1 With the skip in place, a document whose index-section links all leave
  the publication leaves `fragments` at 0 and exits on
  `no link inside a generated index section carries a fragment`
  (`tests/epubcheck.py:334`) — a message that is now false. Untested by any
  of the five plants. **Fix now.**
- [O]5 `plant.py` dies on a pattern matching nothing and on a no-op
  substitution but not on one matching more than once (`re.subn(..., count=1)`,
  `tests/run-tests.sh:4597-4608`), so an anchor gone ambiguous plants only in
  the first hit while the docstring claims it dies rather than writing a copy
  the plant did not reach — KI222's shape in new code. **Fix now.**
- [O]6 The T5 wording leg runs over `clean.epub`, the repack, where AC2 says
  "over the unplanted publication", and re-invokes `unique` rather than
  reading the output check 90 just captured (`tests/run-tests.sh:4650`).
  **Fix now.**
- [O]10 The ROADMAP candidate row for the section-widening work cites only
  "M079 review F9" and not KI264, which this diff created and which is exactly
  the row's motivation; D-034 requires the KI labels. **Fix now.**
- [O]7 The verdict's "the first" over-claims what `index_section` returns:
  `htmlindex.index_section` takes the first `h1`/`h2` whose text is exactly
  `Index`, which KI51 records may not be the first index section or a
  generated one at all. The docstring and KI264 are accurate; only the printed
  line flattens it. **Fix now** (one clause).
- [O]3 A fourth divergent answer to "does this href leave the publication"
  now exists — `epubcheck.leaves_publication`, `htmlindex` (`'://' or
  mailto:`), `sitecheck` (a `//` plus a scheme allowlist), and
  `epubindex.links`, which still joins an external href to the member's
  directory (KI98). `unique` and `links` now disagree about the same href and
  nothing records it. **Follow-up** — candidate row.
- [B]2 A root-relative href (`/text/ch1.xhtml#frag`) is caught by neither the
  skip nor the join, producing the same false missing-manifest-item report the
  milestone repaired for the other two shapes. Pre-existing; AC3 scoped T1 to
  the scheme and `//` shapes. **Follow-up** — same candidate row.
- [O]8 `sections` counts documents in which a section was read, one per
  document, so the printed `N generated index section(s)` under-reports a
  publication whose document carries two — the case KI264 exists for. The
  appositive mitigates it; the numeral does not. **Follow-up** — the existing
  section-widening candidate row.
- [O]4 `leaves_publication('%2F%2Fevil.com/x')` is False, KI120's
  percent-encoded shape reproduced in the new helper; a false report only, and
  the docstring's enumeration of what it does not catch omits it.
  **Follow-up** — extend KI120 to `epubcheck`.
- [O]9 "names an id its document carries exactly once" attributes the count to
  the linking document where `count_id` runs on the target. Pre-existing
  wording the diff did not introduce; the new appositive sits before it.
  **Reject** — out-of-scope taxonomy (an unmodified line).
- [O]11 The new self-test block prints no `section` banner, so its six checks
  are attributed to the M079-AC2 section in the timing profile. Consistent
  with the sibling self-test blocks at 4392 and 4790. **Reject** —
  convention, not a defect.

No finding demonstrates an acceptance criterion failing and none is a
load-bearing defect in what this repo's deliverables do for their readers, so
none reaches the return floor; the eight fix-now items are gate-directed work
on the branch.

### Gate-directed fixes and re-verification

The gate chose to fix the eight fix-now findings before merging. What changed,
finding by finding:

- [O]1, [O]6 The verdict-wording assertion and a new pin on the skipped-link
  count both moved out of `--self-test` and onto the captured publication
  itself (`tests/run-tests.sh:4523-4541`), so an ordinary run now fails on a
  filter emitting an absolute or protocol-relative index locator, and AC2's
  leg reads the captured file rather than a repack of it. One `pass` covers
  both.
- [O]2 All three count assertions now carry the `; ` separator, so
  `; 1 fragment-carrying …` no longer matches a verdict reading `11 …`.
- [P]1 `cmd_unique` builds one `domain` sentence — documents swept, sections
  read, links resolved, links left unresolved as leaving the publication — and
  prints it on every FAIL path as well as inside the `ok` line; the docstring
  now claims that rather than the green-only shape.
- [B]1 A publication whose index-section links all leave it now fails on
  `every one of the N fragment-carrying link(s) … leaves the publication, so
  this check resolved none of them` rather than on the false
  `no link … carries a fragment`. Exercised directly here on a copy with all
  68 hrefs rewritten to a scheme: that message, with `0 … resolved` and
  `68 left unresolved` in the domain line.
- [O]5 `plant.py` counts its matches with `re.findall` and dies unless there
  is exactly one, so an anchor gone ambiguous is a failure rather than a plant
  in the first hit. All three live plant patterns match once in
  `EPUB/text/ch002.xhtml`, checked before the run.
- [O]7 The verdict drops "the first" for `the one index section this check
  reads in each document that carries one, the heading match `index_section`
  returns and never a second in the same document`, which does not claim the
  ordering KI51 says may not hold.
- [O]10 The candidate row names KI264 and describes what the verdict now says.

**Re-run after the fixes:** `tests/run-tests.sh --self-test` exit 0,
`All checks passed (1434 checks)`, no FAIL line. The six M083 legs are checks
89-94: the verdict-and-pin leg over the captured publication, then the clean
repack, the duplicate id, the dangling relative href, the scheme href and the
`//` href, each on its anchored report. The count reads 1434 against the
previous run's 1435 because the run counts `ok` lines in its own log and this
check's `ok` verdict is now captured into a variable rather than printed; the
`ok`-line sets of the two runs differ by exactly that line and by the reworded
legs, no check lost. `cairn_validate.py` re-run: all checks passed.
