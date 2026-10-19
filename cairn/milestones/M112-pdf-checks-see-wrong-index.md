<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M112: Three PDF index checks see a wrong index

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP6   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — acceptance-suite checks and a suite reader, which no user of the extension runs   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m112-pdf-checks-see-wrong-index   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Three acceptance-suite readers of a compiled PDF index fail on a wrong index
that they pass or read short today.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a cluster of the older acceptance-suite backlog, the three entries
KI63, KI69 and KI102 in `cairn/DESIGN.md`. The M02-AC2 and M02-AC3 typeset
checks count each cross-reference row instead of testing for a substring
(KI69). `tests/m23probes.py`'s `_ind` pins the compiled index's entry set and
makeindex's accepted-entry count (KI63). `tests/pdfindex.py`'s `read` fails
when the page its `stop` bound leaves out carries an index line above that
page's section-ending line (KI102). Each repair gets a self-test case, and the
three entries are removed from `cairn/DESIGN.md`.

**Out:**
- KI53, the reader's footer guess on a page with no folio: left out at this
  plan gate, since no fixture prints such a page. It stays under the backlog
  candidate row.
- KI104, `tests/namedpdf.py` reading a manifest row with trailing whitespace:
  stays under the backlog candidate row.
- KI63's other half, the `.ilg`'s "lines written" count: not pinned, since
  that figure counts makeindex's layout lines too and no fact about the
  fixture states it. The entry set and accepted count cover what it guarded.
- The EPUB checks' dead code (KI92, KI94, KI95) and the inline log counts
  that read a missing log as 0 (KI311): each moves to its own new parked
  candidate row in this plan commit.
- Every other entry under the two acceptance-suite subheadings: stays under
  the backlog candidate row, for a later named cluster.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: The M02-AC2 and M02-AC3 typeset checks in `tests/run-tests.sh`
      fail, naming the row, when a manifest row's text occurs more than once
      in the index region they read; today a row printed twice passes. Given
      its captured text with one row written a second time, each check fails
      naming that row.
- [x] AC2: `tests/m23probes.py`'s `ind` and `posind` modes fail when the
      compiled index carries an `\item` entry other than the three terms the
      module states, and when the `.ilg`'s accepted-entry count differs from
      the number of marks the module states the fixture writes. Given a copy
      of the `range-nested` capture with an extra `\item` entry, `ind` fails
      with the entry clause's message; given a copy whose accepted count is
      changed, it fails with the count clause's message.
- [x] AC3: `tests/pdfindex.py`'s `read`, given `stop`, fails with a message
      naming the page when the page it leaves out carries a line printed
      above that page's first section-ending line; today such a line is
      dropped with no message. Given input whose left-out page carries an
      index line above its first section-ending line, `read` fails with that
      message.
- [x] AC4: The repaired checks (M02-AC2, M02-AC3, `m23probes` `ind` and
      `posind`, and every bounded `pdfindex.read` call the suite makes through
      `tests/namedpdf.py`, `tests/indexdump.py` and `tests/typstindex.py`)
      pass on the fixtures' current output in a run of
      `tests/run-tests.sh --self-test`.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: In the M02-AC3 heredoc (`tests/run-tests.sh` ~7285-7306) and the
      M02-AC2 heredoc (~7341-7364), replace the `not in region` test with a
      count of each normalized row in the region, failing with the row and
      its count when it is not exactly 1; check first that no row is a
      substring of another row of its manifest, so a count of 1 is reachable.
      Add a `--self-test` case per check that writes one row a second time
      into a copy of the check's captured text and asserts that check's
      failure names that row, plus the unplanted copy passing.
- [x] T2: In `tests/m23probes.py`, state the fixture's mark count (six
      `\index` calls today, read from `examples/range-nested.qmd` and
      `examples/range-position.qmd`, not from the `.ilg`) beside `RANGES`,
      fail when `_items` holds a term outside `RANGES` and `INNER`, and fail
      when the `.ilg`'s `N entries accepted` differs from the stated count.
      Add one plant per clause to the M23 self-test block (~17559, `M23W`):
      an extra `\item` line, and a changed accepted count, each asserting its
      own message.
- [x] T3: In `tests/pdfindex.py` `read` (~180-235), when `stop` ends the
      read, check the left-out page for a line whose `y` is above the first
      section-ending line on it and raise naming the page and that line;
      update the docstring's account of the dropped page. Add a `--self-test`
      case that feeds `read` such a page (a stubbed `_pages` or a rendered
      variant of the named-indexes fixture, whichever reaches `read` through
      a real caller) and asserts the message.
- [x] T4: Remove KI63, KI69 and KI102 from `cairn/DESIGN.md` and check no
      ROADMAP row names them; run `tests/run-tests.sh --self-test` green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — suite code changes across three known issues in three files, more than one sitting.
- 2026-10-18: promoted in part from the candidate row "The older acceptance-suite backlog held under `DESIGN.md`'s two acceptance-suite subheadings, which no single milestone can take whole; promote a named cluster of it, never the subheadings"; the row stays for the rest.
- 2026-10-18: collision check: no milestone planned or in progress; no other row names KI63, KI69 or KI102; no D-entry declines them (D-059 and D-064 concern EPUB and HTML hrefs); inbox 0 open issues, 0 open PRs.
- 2026-10-18: checker-regress shape judged not to fire: the three readers read the extension's compiled PDF, `.ind` and `.ilg`, not repo-internal artifacts.
- 2026-10-18: Explore fan-out (3 Haiku) checked KI53, KI63, KI69, KI91-KI97, KI102, KI104 and KI311 against the code: all hold, except that KI63 understates what `_ind` checks and no current caller reaches KI311's silent 0.
- 2026-10-18: reduced criteria audit (Opus, fresh context): instrument finding on all four; AC1-AC3 dropped their self-test-case clauses for the checks' behavior on a planted input (the cases moved to T1-T3), and AC4 changed from "`--self-test` passes" to the repaired checks passing on current output. No bounded-promise or proportionality finding.
- 2026-10-18: question set: which cluster — PDF wrong-index (KI63, KI69, KI102); add the footer fix (KI53) — no, left under the backlog row; rows for the EPUB dead code and the missing-log counts — yes, added as parked rows.
- 2026-10-18: plan gate chose failing `read` when its left-out page carries a line above the section-ending line over reading that page up to the line, because the docstring records that a full-width line sorts ahead of the right column, so a line-bounded read loses entries; falsified by a fixture whose index must continue onto the next heading's page.
- 2026-10-18: plan gate chose pinning the entry set and the accepted count over pinning the `.ilg`'s lines-written count, because that count includes makeindex's layout lines and no fixture fact states it; falsified by a defect that changes the written lines while both pinned figures hold.
- 2026-10-18: implement started on branch m112-pdf-checks-see-wrong-index; status in-progress.
- 2026-10-18: T1 code: the two heredocs became one `xref_typeset_check` reader called at both sites and by the new `--self-test` case, so the plant runs the run's own code; it also refuses a manifest with one row inside another, since such a row would count twice on a correct index. Scratch run on the 2026-10-18 captures: both checks green (7 and 66 rows), the doubled-row plant red naming the row. Full-suite verify batched after T3, because editing `tests/run-tests.sh` during a run corrupts that run (M073 lesson); T1 is ticked only after it.
- 2026-10-18: T2 code: `tests/m23probes.py` states `MARKS = 2 * 2 + 2`, counted from both fixtures' `.index` spans, and `_ind` fails on an entry outside `RANGES` and `INNER` and on an accepted count other than `MARKS`; two plants in the M23 self-test block assert each clause's message. Scratch run: `ind` and `posind` green on the 2026-10-18 captures (6 accepted in both `.ilg`), each plant red with its own message. Full-suite verify still batched after T3.
- 2026-10-18: T3 code: `pdfindex.read` raises LookupError, naming the page and the lines, when the page its `stop` bound leaves out prints a line above its first section-ending line; LookupError because all three bounded callers already report it as a FAIL line. The self-test feeds `read` stubbed `_pages` output, a stranded case and a control, in the M49 self-test block. A rendered plant was tried first: the named-indexes fixture with its page break removed puts the next heading on the index's own page, which `read` refuses as unbounded, so no render here builds the input class. Scratch runs: the four bounded reads green on the 2026-10-18 captures, no M098 capture refused, the pageplus plant still red for its own row, the case red on the pre-fix reader.
- 2026-10-18: T4: KI63, KI69 and KI102 removed from `cairn/DESIGN.md`; no ROADMAP row, test file or page names them.
- 2026-10-18: verify: the first `tests/run-tests.sh --self-test` run stopped at its PyYAML guard, because this session's PATH resolves `python3` to a new 3.14.6 install without PyYAML; re-run with `python3` alone pointed at `/usr/bin/python3` 3.9.6, the repo's local interpreter, nothing installed. That run: "All checks passed (1770 checks)" at 58d8c71, the three M112 self-test cases green. T1-T4 ticked.
- 2026-10-18: claim audit: not owed — internal tier.
- 2026-10-18: implement complete; status review.
- 2026-10-19: review: four-lens fan-out, 23 findings: 14 fixed on the branch in d2309c7, 3 to follow-up KI313, 6 rejected; the first review suite run was stopped before the fixes, and the run at d2309c7 is the evidence.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive -->

Fresh run: `tests/run-tests.sh --self-test` at d2309c7, `python3` pointed at
`/usr/bin/python3` 3.9.6 (the session's default 3.14.6 lacks PyYAML):
"All checks passed (1770 checks)", 0 FAIL lines.

- AC1: `ok M02-AC3: all 66 … typeset once each` and `ok M02-AC2: all 7 …
  typeset once each` on the captures; `ok M112 T1 self-test`: each check red
  on its captured text with one row written a second time, the failure
  naming `<<row>> x2`. The pre-milestone presence test reads both planted
  copies (`tests/.work/m112-xref/`) with nothing missing, so the plants pass
  without the fix.
- AC2: `ok M23-AC1` (`ind`) and `ok M23-AC2` (`posind`) on the captures;
  `ok M112 T2 self-test`: `ind` red with the entry clause's message on an
  extra `\item quokka`, and with the count clause's message on one accepted
  entry more than `MARKS` and on one rejected entry. The pre-milestone
  `tests/m23probes.py` passes all three planted copies (`tests/.work/m23-planted/`).
- AC3: `ok M112 T3 self-test`: `read`, fed `_pages` output whose left-out
  page prints `zebra, 3` above its section-ending line, raises LookupError
  naming page 2 and that line; it does the same for `zebra, 3` in the left
  column below a section-ending line set in the right; the control without
  either reads its two entries. The `main` reader returns the two entries on
  both planted inputs, and the implement-time y-only reader on the
  left-column one.
- AC4: the fresh run above is green with M02-AC2, M02-AC3, M23-AC1 and
  M23-AC2 on the captures, and with every bounded `pdfindex.read` the run
  makes: M49-AC1/AC2/AC4 and the M49-AC2 cells through `tests/namedpdf.py`,
  the M50 fixture's two indexes through `tests/indexdump.py`, and M098-AC6's
  two `typstindex.py pages` reads.

Consistency gate: `cairn_validate.py` all checks passed; no principle
changed, so `cairn_impact` skipped; the generic profile names no toolchain
checks.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: the stranded-line refusal reads any line above the stop line as index content, so a running header there is refused, and the docstring said every such line is an index line — fix now: the docstring states the no-running-header assumption the module already makes on index pages, and that a header would be refused by name, not read, fixed d2309c7
- diff-bug #2: the T3 plant stubs `_pages` rather than reaching `read` through a real caller — reject (false): AC3 names `read`'s behavior, and the callers' LookupError-to-FAIL path is already planted by M49's `nostop` case through the same `except` clause
- diff-bug #3: the T3 comment "No fixture can print that page" overstates one tried render — fix now: reworded to the one variant tried, fixed d2309c7
- diff-bug #4: the refusal grows a checker over a shape no output shows, which D-059 and D-064 refuse, unrecorded — reject (planned change): the plan gate chose this cluster, and a LaTeX index's next heading can share a page with index content, as the no-page-break render showed
- diff-bug #5: an extra mark makeindex rejects (6 accepted, 1 rejected) passes the count clause — fix now: the clause also requires 0 rejected, with a plant, fixed d2309c7
- diff-bug #6: the T2 plants re-type 6 and 7 rather than reading `MARKS` — fix now: the plants read `MARKS` from the module, fixed d2309c7
- diff-bug #7: a row that also occurs inside other printed text counts twice on a correct index — follow-up: KI313, under the backlog candidate row's subheading
- diff-bug #8: `|| exit 1` where the file usually writes `|| fail "…"` — reject (style)
- diff-bug #9: the T1 plant appends the doubled row after the text rather than inside the columns — reject (false): the count runs over the flattened region, where a row's position does not change it
- diff-bug #10: `_items` keys by term, so a second `\item pooka` collapses — reject (false): a second entry for a term needs another mark, which the accepted-count clause and its plant catch
- diff-bug #11: `y < top` compares lines set in different font sizes — reject (false): a section-ending line matches a whole pdftotext line exactly, and no fixture's heading row carries another line
- blame-history #1: deleting KI69 erases the record of the M05-AC5 book cross-reference presence check — fix now: KI69 restored, narrowed to that check and AC6's term check, fixed d2309c7
- blame-history #2: the refusal is column-blind, so a section-ending line in the right column drops left-column lines below it — fix now: the refusal also takes left-column lines when that line sits in the right one, with a plant red on the y-only reader, fixed d2309c7
- blame-history #3: the counts are substring counts — follow-up: KI313
- blame-history #4: the `_ind` docstring says the `.ilg` is read for a count rather than searched, while the phrases are searched — fix now: docstring states both, fixed d2309c7
- prior-review #1: AC6's term check keeps the presence test KI69 named — fix now: KI69 narrowed names it, fixed d2309c7
- prior-review #2: the refusal is column-blind — fix now: as blame-history #2, fixed d2309c7
- prior-review #3: the counts are substring counts — follow-up: KI313
- ripple #1: `tests/typstindex.py`'s `read` docstring says it drops the stop page as `pdfindex.read` does — fix now: docstring names the difference, fixed d2309c7; the silent drop itself is follow-up KI312
- ripple #2: `pdfindex.read`'s Raises paragraph omits the new LookupError — fix now: moved into that paragraph, fixed d2309c7
- ripple #3: the `_ind` docstring omits the accepted-count read — fix now: added, fixed d2309c7
- ripple #4: the comment above `AC` lists the clauses without the two new ones — fix now: added, fixed d2309c7
- ripple #5: removing KI69 drops the record of two presence-only checks — fix now: KI69 restored narrowed, fixed d2309c7

Return floor: no finding shows a criterion failing or a defect users meet, so
no status change. The fix-now commit landed before this checkpoint; the run
recorded above is on it.
