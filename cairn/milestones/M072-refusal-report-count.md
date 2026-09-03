# M072: A refused chapter whose record an older version wrote is reported once per index section

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Branch/PR:** `m072-refusal-report-count`

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

- [ ] AC1: In `examples/book-extensions`, over a store a whole-book render wrote with `five.ipynb`'s record then rewritten to carry a store version other than the extension's, a render of `one.qmd` alone (a chapter with no placement marker that is not the book's last, so it builds no section while the store shows `index.qmd` placing both indexes) draws the refusal wording 0 times, and a render of `index.qmd` alone draws it exactly once, naming `five.ipynb`.
- [ ] AC2: In the same fixture, a render of `one.qmd` alone draws the refusal once when `five.ipynb`'s record is listed by the store directory and cannot be opened, once when that record holds bytes that do not decode as a record, and 0 times when no store exists — the counts those three states draw today — so of the four record states `store_read` tells apart the different-version state is the only one whose count moves.
- [ ] AC3: In the two single-chapter renders AC1 makes and the three AC2 makes, the three different-version wordings and the three could-not-be-read wordings are drawn 0 times, and the only warnings of this extension naming `five.ipynb` are the refusal and, in the `index.qmd` renders, the marker-position report, which names the chapters after the marker.
- [ ] AC4: `site/books.qmd` states the refusal's count for each of the three record states it is reached in, in the paragraph that states the other wordings' counts, and `CHANGELOG.md` carries an entry under `## Unreleased` / `### Output` naming the count that moved.
- [ ] AC5: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0 on the branch.

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

## Decisions

## Review
