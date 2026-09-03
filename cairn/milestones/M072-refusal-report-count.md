# M072: A refused chapter whose record an older version wrote is reported once per index section

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Branch/PR:** `m072-refusal-report-count` / https://github.com/jmgirard/quarto-index/pull/72

## Goal

In an HTML book, a chapter whose source the recovery route will not read is reported, where its record was written by a different version of this extension, on the count every other different-version report follows — once per chapter that builds an index section, and once by a chapter whose records show no chapter of the book placing an index — rather than once per chapter that reads the store, so a book carrying a notebook chapter with an old record hears about it as often as it hears about any other stale record.

## Scope

User-facing tier: the deliverable is the reports a book render prints and the docs that state their counts.

Today `store_read` draws the refusal inline for every reading chapter in all three record states it is reached in (`book.lua:983-1008`), while the three different-version wordings are handed back in `stale` and drawn at one site under `builds or first == nil` (`book.lua:1496-1504`; M062). D-046 fixed the refusal at once per reading chapter, ahead of every other wording (KI234).

**In:**
- On the version-skewed branch a refused chapter is handed back in `stale` with a `refused` flag instead of being drawn inline, and the report site draws the refusal wording for it ahead of the three different-version wordings, under the same gate. The never-written and listed-unopenable and undecodable states keep the inline draw and their counts.
- The refusal keeps its precedence: a refused chapter still says one thing, and never the different-version wording (D-046's precedence clause stands; D-049 supersedes its count clause).
- A suite leg over `examples/book-extensions` rendering a non-building chapter and the building chapter in each record state; `site/books.qmd`'s count paragraph, its claim ledger, `CHANGELOG.md`, DESIGN's recovery section; KI234 struck.

**Out:**
- A new wording naming both the refusal and the version (the gate declined it: a seventh store wording for a state the author acts on the same way).
- The could-not-be-read family's once-per-opening-chapter count, documented at `site/books.qmd:192-195`: untouched.
- Front-matter locators (KI232, KI233) → M071.

## Acceptance criteria

- [x] AC1: In `examples/book-extensions`, over a store a whole-book render wrote with `five.ipynb`'s record then rewritten to carry a store version other than the extension's, a render of `one.qmd` alone (a chapter with no placement marker that is not the book's last, so it builds no section while the store shows `index.qmd` placing both indexes) draws the refusal wording 0 times, and a render of `index.qmd` alone draws it exactly once, naming `five.ipynb`.
- [x] AC2: In the same fixture, a render of `one.qmd` alone draws the refusal once when `five.ipynb`'s record is listed by the store directory and cannot be opened, once when that record holds bytes that do not decode as a record, and 0 times when no store exists — the counts those three states draw today — so of the four record states `store_read` tells apart the different-version state is the only one whose count moves.
- [x] AC3: In the two single-chapter renders AC1 makes and the three AC2 makes, the three different-version wordings and the three could-not-be-read wordings are drawn 0 times, and the only warnings of this extension naming `five.ipynb` are the refusal and, in the `index.qmd` renders, the marker-position report, which names the chapters after the marker.
- [x] AC4: `site/books.qmd` states the refusal's count for each of the three record states it is reached in, in the paragraph that states the other wordings' counts, and `CHANGELOG.md` carries an entry under `## Unreleased` / `### Output` naming the count that moved.
- [x] AC5: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0 on the branch.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T2

## Tasks

- [x] T1: `store_read` (`book.lua:983-1016`): test the version-skewed state before the refusal, and on that branch append `{ file = file, refused = true }` to `stale` rather than warning; `html_book`'s report site (`book.lua:1496-1504`) draws the refusal wording for `entry.refused` first. The comment at `book.lua:984-1008` restated to say which states draw inline and which at the site.
- [x] T2: Suite leg `m072`: build the store with a whole-book render of `examples/book-extensions`; rewrite `five.ipynb`'s record version the way the existing stale plants do (grep `STORE_VERSION` in `tests/run-tests.sh`); render `one.qmd` and `index.qmd` alone and count the refusal, the three stale keys and the three unreadable keys with `check_warning_count`, the name with a `m070_refusal_names`-style grep; three controls over `one.qmd` — listed-unopenable (the M070 dangling plant), undecodable bytes, no store; extension totals pinned. Shown red first by two planted defects — the site gate inverted, and the refusal test moved back ahead of the version test — recorded in the work log.
- [x] T3: Docs: `site/books.qmd:190-200` gains the refusal's count by state and the claim ledger (`tests/run-tests.sh:21753-21785`) a row pinning it; the `CHANGELOG.md` entry; DESIGN's recovery section sentence "drawn ahead of the other four" (`cairn/DESIGN.md:501-504`) restated with the count, KI234 struck; `warn-distinct.py`'s pinned count untouched.

## Work log

- 2026-09-02: created by /milestone-plan from the M070 follow-up candidate row (KI234); criteria audit ran in FULL mode ([O], fresh context) — M072's share of its eight findings: the goal and AC1 stated a count rule narrower than the code's `builds or first == nil` (restated), AC2's "only state that moves" quantified over states it did not count (the undecodable state added, the four states named), AC3's per-file claim outran the log counter (name check added), the work-log clause moved to T2; D-049 written.
- 2026-09-02: plan gate chose handing the version-skewed refusal to the one report site over also drawing a new wording naming the version, because the record's state decides nothing the author acts on differently and a seventh wording costs a translation and a pin for it; falsified by an author reporting they needed to know the record was stale to act.
- 2026-09-02: plan gate chose the change over leaving the count and recording acceptance, because a book with many chapters and one notebook says the refusal once per chapter where it says a stale record once per section; falsified by nothing — the alternative was the null change.
- 2026-09-03: AC3 amended at a mini gate — its second clause quantified over every line of the logs, which the marker-position report's chapter list falsifies for `five.ipynb` on any render of `index.qmd`, and the whole-book setup render put Quarto's own progress output inside the promise too. Narrowed to this extension's own warnings over the five single-chapter renders, with the marker-position report named as the one carve-out. Full-mode criteria audit ([O], fresh context) returned three findings on the drafted wording; the bounded domain and the demoted relative clause are in the text as adopted, the third recorded as the check shape T2 must take — subtract the two known wordings and assert the residue empty.

- 2026-09-03: T1 — `store_read` tests the version-skewed state before the refusal and hands a refused chapter back in `stale` under a `refused` flag; the report site draws the refusal's wording for such an entry ahead of the three different-version wordings, under the same gate. The wording moved into one helper called from both sites, so the source set still holds one literal for it and the pinned message count is unchanged.
- 2026-09-03: T2 — suite leg `m072` over `examples/book-extensions`, its store filled by a whole-book render: the version field of `five.ipynb`'s record rewritten and nothing else, with the same store one field earlier as the control. Refusal counted from `index.qmd` (builds both sections) and `one.qmd` (builds none) in all four record states; the six other store wordings held at zero and the naming clause read subtractively. Two planted defects shown to produce the counts the criteria would fail on — the report site's gate turned round, and the refusal test moved back ahead of the version test.
- 2026-09-03: T3 — `site/books.qmd` states which report the refusal's count follows in each record state, with a claim-ledger row pinning it (the pinned claim total moved from 32 to 33); `CHANGELOG.md` entry under Unreleased / Output; DESIGN's recovery section restated with the count; KI234 struck.
- 2026-09-03: added to T2 beyond the plan — a control render over the store as the whole-book render left it, before the version plant, so the single refusal is evidenced against the same book, chapter and store one field apart; and a capture after every render, which the M24 sweep requires.
- 2026-09-03: `tests/run-tests.sh --self-test` exits 0 on the branch, 1239 checks.

- 2026-09-03: `tests/run-tests.sh` exits 0 on the branch, 13m09s wall clock (603s user, 72s system, 85% CPU — the run is effectively single-core).

- 2026-09-03: candidate row added for running the suite's legs in parallel, from the 13m09s measured here; ROADMAP reached 60 lines with it, so M067's terminal row was pruned to hold the line cap — the milestone's summary is in milestones/archive/.

- 2026-09-03: review — draft PR #72; branch level with the default branch, no merge needed. Consistency gate clean (cairn_validate all-pass; the generic profile names no toolchain checks). Three-lens fan-out returned eight findings: five fixed on the branch (the docs' account of which record state is which, the omitted builds-none clause, DESIGN's two now-false clauses, and m072_render's over-general failure message, which regressed an M070 review fix), two filed as follow-ups, one rejected. Both suites re-run whole after the fixes: 663 and 1239 checks, exit 0.

- 2026-09-03: step-7 approval: PR #72 approved for merge

## Decisions

## Review

Evidence from the branch at `bb7d091`, over the tree the fix-now commit left:
`tests/run-tests.sh` and `tests/run-tests.sh --self-test` both re-run end to end
after every fix below, 663 and 1239 checks, no FAIL line. The suite's
`check_warning_count` and `check_extension_warning_count` are silent on a pass
and fail loudly, so a leg that ran without a FAIL is a leg whose counts held.

**AC1 — the version-skewed state, from both sides of the rule.** The `m072`
leg fills `examples/book-extensions`' store with a whole-book render, then
rewrites `five.ipynb`'s record version and nothing else (`m072_skew` re-reads
the file and asserts it carries `SUPERSEDED_VERSION`, reported as its own pass
line). A render of `one.qmd` alone draws the refusal 0 times; a render of
`index.qmd` alone draws it exactly once, and `m070_refusal_names` asserts that
line names `five.ipynb`. The control — `index.qmd` over the same store one
field earlier, before the plant — draws the refusal 0 times, so the single
refusal is a consequence of the version and not of the fixture.

**AC2 — the three states whose counts did not move.** Over `one.qmd`, the leg
draws the refusal once with `five.ipynb`'s record listed by the store directory
and unopenable (planted by `m068_dangle_record`), once with that record holding
bytes that do not decode (the plant is asserted undecodable before the render),
and 0 times with no store at all (the store directory is asserted gone first).
Of the four record states `store_read` tells apart, the version-skewed one is
the only one whose count moved.

**AC3 — nothing else drew, and nothing else named.** Across the five
single-chapter renders AC1 and AC2 make, `m072_other_wordings_silent` holds all
six of the other store wordings — the three for a record another version wrote
and the three for one that could not be read — at 0. The naming clause is read
subtractively: of this extension's own warnings, those naming `five.ipynb`, less
the refusal and (on the `index.qmd` renders) the marker-position report, must be
empty — with a non-empty-domain fence that fails if no line names the chapter at
all, so the subtraction can never come out empty for the wrong reason. A seventh
wording naming that chapter would survive both subtractions and fail here.

**AC4 — the docs state the counts.** `site/books.qmd` states the refusal's count
for each of the three record states it is reached in, in the paragraph following
the one that states the other wordings' counts, and the claim ledger carries a
row pinning it; the pinned claim total moved 32 → 33, and the planted-defect
self-test shows the reader red on a page that drops one claim. `CHANGELOG.md`
carries the entry under `## Unreleased` / `### Output` naming the count that
moved. All four docs surfaces were corrected at the gate (F1, F2, F5 below) and
re-verified after.

**AC5 — the suite.** `tests/run-tests.sh` exits 0 (663 checks, 6m54s wall);
`tests/run-tests.sh --self-test` exits 0 (1239 checks, 19m32s wall). The leg's
two planted defects are shown red first inside the self-test: with the report
site's gate turned round, the chapter that builds no section draws the refusal
and the chapter that builds one does not; with the refusal test moved back ahead
of the version test, a chapter that builds no section is told about a record
another version wrote. Each is a count the AC1 checks fail on.

**Consistency gate.** `cairn_validate.py` exits 0, every check PASS, every
advisory OK — re-run after the fix-now commit. The active profile is `generic`,
whose `consistency-gate` slot names no toolchain checks, so that half is a clean
no-op. No `DESIGN.md` principle text changed (GP1 is governed, not amended), so
`cairn_impact.py` was not run.

**Independent review.** The diff touches executable surface (`book.lua`,
`run-tests.sh`), so the full three-lens fan-out ran, fresh context, none having
seen the implementation. Findings as reported, with dispositions:

- **F1 [O]** — a record file holding decodable JSON that is not a record is
  classified as version-skewed, so the refusal's count moves for that state too,
  contradicting AC2 and three doc claims. *Confirmed in part.* Probed directly:
  `pandoc.json.decode("{}", false)` yields a table whose `version` is nil, so it
  takes the version-skew branch; `"this is not a record\n"` decodes to nil, not
  a table, so the suite's plant does exercise the inline path. The
  classification predates this branch (`valid_record` has always required
  `version == STORE_VERSION`); what this branch added was doc prose describing
  the third state as "holding bytes that are not a record", which is false for
  `{}`. AC2 quantifies over "the four record states `store_read` tells apart",
  which is the code's own partition, so AC2 stands. **Fixed now**, in the docs:
  all three surfaces now say a record that decodes and does not carry this
  version's number is read as version-skewed, one carrying no version at all
  included, and that the inline-drawn state is bytes that do not decode at all.
  The code's classification is left as it is and filed as a follow-up.
- **F2 [O]** — `site/books.qmd` said the never-written refusal is "drawn by the
  two chapters that read a source for an absent record", where `recover_absent`
  is `#marker > 0 or ctx.position == #ctx.chapters` — every marker-carrying
  chapter plus the book's last, which the paragraph six lines above states
  correctly as a rule. *Confirmed.* **Fixed now**: the sentence now names the
  rule rather than a pair.
- **P1 [S prior-review]** — `m072_render`'s failure message asserted
  unconditionally that "IP2 forbids an unusable record taking a render down at
  all", on a shared helper also used for the control render (every record valid)
  and the no-store render. This is the same over-general claim M070's review
  corrected on `m070_render`. *Confirmed against both helpers.* **Fixed now**,
  conditioned the way `m070_render`'s is.
- **F3 [O], and the [S blame-history] lens's one nit** — `DESIGN.md`'s "A
  REFUSED chapter is outside that silence and reports on every path" is now
  false for the path this milestone changed, and the retained "drawn ahead of
  the other four and whatever state that chapter's record was in" reads as the
  uniform rule D-049 retired. *Confirmed.* **Fixed now**: "instead of the other
  four", true at both draw sites, and the reports-on-every-path sentence
  narrowed to the count each path's own wording follows.
- **F5 [O]** — `CHANGELOG.md` and `DESIGN.md` stated the moved count as "once
  per chapter that builds an index section" and omitted the
  `first == nil` half that `site/books.qmd` states. *Confirmed.* **Fixed now**
  in both.
- **F4 [O]** — the `first == nil` half of the report gate is never exercised for
  a refused entry: every `m072` render is over a store where `index.qmd` places
  both indexes, and the `gateflip` mutant inverts the whole gate rather than
  that disjunct. A site loop gated on `builds` alone would pass the whole leg.
  *Confirmed.* **Follow-up** — a check-widening, filed as a known issue with a
  candidate row.
- **F6 [O]** — D-046's Consequences still say the refusal "stands ahead of the
  version-skew branch", which no longer describes the code. **Rejected**:
  `DECISIONS.md` is history and never edited (IP4), the sentence's operative
  claim (a refused chapter never draws the different-version wording) remains
  true, and a superseding entry over a mechanism clause whose conclusion holds
  buys nothing.
- **F7 [O]** — `m072_only_refusal_names` writes to fixed `$WORK` paths reused by
  every call, so the diagnostics left after a failure describe only the last
  invocation. Harmless in the serial run. **Follow-up**, folded into the
  parallel-legs candidate row this milestone added, which is where it becomes a
  correctness issue.
- **[S blame-history]** reported no functional defects: it traced every branch
  of the modified conditional, confirmed `valid_record` makes the version-skew
  test exact, confirmed `stale` has one consumer so the new `refused` field is
  inert elsewhere, and confirmed D-046's precedence clause holds at both sites.
- **[S prior-review]** found no other regression; its existence probe
  (`gh api .../pulls/comments?per_page=1`) returned `[]`, so no GitHub thread
  surface was walked.

No finding demonstrated an acceptance criterion failing inside its domain, so
the return floor did not fire; every actioned finding was fixed on the branch
before the approval marker, and the suite re-run whole afterwards.
