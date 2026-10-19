<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M112: Three PDF index checks see a wrong index

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [ ] AC1: The M02-AC2 and M02-AC3 typeset checks in `tests/run-tests.sh`
      fail, naming the row, when a manifest row's text occurs more than once
      in the index region they read; today a row printed twice passes. Given
      its captured text with one row written a second time, each check fails
      naming that row.
- [ ] AC2: `tests/m23probes.py`'s `ind` and `posind` modes fail when the
      compiled index carries an `\item` entry other than the three terms the
      module states, and when the `.ilg`'s accepted-entry count differs from
      the number of marks the module states the fixture writes. Given a copy
      of the `range-nested` capture with an extra `\item` entry, `ind` fails
      with the entry clause's message; given a copy whose accepted count is
      changed, it fails with the count clause's message.
- [ ] AC3: `tests/pdfindex.py`'s `read`, given `stop`, fails with a message
      naming the page when the page it leaves out carries a line printed
      above that page's first section-ending line; today such a line is
      dropped with no message. Given input whose left-out page carries an
      index line above its first section-ending line, `read` fails with that
      message.
- [ ] AC4: The repaired checks (M02-AC2, M02-AC3, `m23probes` `ind` and
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

- [ ] T1: In the M02-AC3 heredoc (`tests/run-tests.sh` ~7285-7306) and the
      M02-AC2 heredoc (~7341-7364), replace the `not in region` test with a
      count of each normalized row in the region, failing with the row and
      its count when it is not exactly 1; check first that no row is a
      substring of another row of its manifest, so a count of 1 is reachable.
      Add a `--self-test` case per check that writes one row a second time
      into a copy of the check's captured text and asserts that check's
      failure names that row, plus the unplanted copy passing.
- [ ] T2: In `tests/m23probes.py`, state the fixture's mark count (six
      `\index` calls today, read from `examples/range-nested.qmd` and
      `examples/range-position.qmd`, not from the `.ilg`) beside `RANGES`,
      fail when `_items` holds a term outside `RANGES` and `INNER`, and fail
      when the `.ilg`'s `N entries accepted` differs from the stated count.
      Add one plant per clause to the M23 self-test block (~17559, `M23W`):
      an extra `\item` line, and a changed accepted count, each asserting its
      own message.
- [ ] T3: In `tests/pdfindex.py` `read` (~180-235), when `stop` ends the
      read, check the left-out page for a line whose `y` is above the first
      section-ending line on it and raise naming the page and that line;
      update the docstring's account of the dropped page. Add a `--self-test`
      case that feeds `read` such a page (a stubbed `_pages` or a rendered
      variant of the named-indexes fixture, whichever reaches `read` through
      a real caller) and asserts the message.
- [ ] T4: Remove KI63, KI69 and KI102 from `cairn/DESIGN.md` and check no
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

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive -->
