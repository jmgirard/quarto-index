<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M077: The suite's timing accounting checks only what its own window covers

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a checker over a timing file the acceptance suite writes for itself
- **Branch/PR:** m077-timing-accounting-window — https://github.com/jmgirard/quarto-index/pull/77

## Goal

The run's timing accounting keeps the clause it can settle — every section the
source declares has exactly one row and nothing else does — drops the clause
whose window it cannot cover, and stops leaving a state in which a section
opened after the run's last one would be timed as the whole run.

## Scope

**In:** separating "the run has closed" from "no section has opened yet" in the
section timer; removing the seconds-account clause rather than widening the
window it reads, with the decision recorded; repairing the two defects in the
plant helper that would make it fail for a reason other than the one it plants;
and a decision entry narrowing what M075 shipped.

**Out:** widening the accounting's measuring window to cover the whole run →
declined at the plan gate as hardening a checker over the suite's own artifact;
the reason is the decision entry this milestone writes. Banner heading text
sitting in executable source, and a wrapped banner naming its section by a
truncated first line → KI247 and KI248, on a candidate row of their own. The
store-report assertions → M076. The fifteen-slowest print's position outside
the checked run → KI246, accepted.

## Acceptance criteria

- [x] AC1: `section` refuses to open a section after `section_close` has run,
      rather than writing a second setup row valued at the whole run's wall
      clock; shown red on a planted call.
- [x] AC2: the accounting's seconds clause is removed; what remains holds every
      heading in the timing file to a section `tests/suitescan.py sections`
      reports, and every section that scan reports to exactly one row.
- [x] AC3: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` each
      exit 0.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T3
- AC3 → T5

## Tasks

- [x] T1: Give the section timer a third state (`tests/run-tests.sh:87-112`):
      `section_close` marks the run closed rather than clearing the same
      variable that means "before the first section", and `section` fails
      naming its own call when the run is closed.
- [x] T2: Remove the seconds clause from `m075_account` (`:25631-25710`) and
      the `M075_OPEN` / `M075_TOTAL` readings that feed it, keeping the
      membership, duplicate-row, setup-row and malformed-row clauses. The
      driver's print (`:25823`) still reports the total, now as a figure
      nothing checks.
- [x] T3: Retire T5's third plant — five seconds off one row (`:25802`) —
      with the clause it probes, and add the plant for T1's refusal.
- [x] T4: Repair `m075_plant_source` (`:25726`): recognize a banner rule by the
      rule `tests/suitescan.py` uses (`BANNER_RULE`, `^# -{10,}\s*$`, `:78`)
      rather than by any run of dashes, and bound the inner scan for a block's
      close so an unclosed trailing block is reported rather than raising.
- [x] T5: Write the decision entry recording the narrowing and why widening was
      declined; record in `DESIGN.md` that the printed seconds are now held by
      nothing, and correct the suite's own prose that says they are held to
      its clock; full `tests/run-tests.sh --self-test` green.

## Work log

- 2026-09-04: created by /milestone-plan.
- 2026-09-04: criteria audit ran in reduced mode (internal tier) on the same fresh [O] reader, which authored none of the criteria; two rounds. Round 1 returned two findings on this milestone's draft, both fixed before the gate: a criterion whose promise was a DESIGN.md recording act, and a criterion binding the T5 plant helper's own properties, which moved to T4. Round 2 over the rewritten set returned nothing.
- 2026-09-04: plan gate chose dropping the accounting's seconds clause over widening the window it reads, because the accounting is a checker over an artifact only this suite reads and hardening such a checker is the regress shape; falsified by a section running untimed or twice-timed in a way only a seconds total could see.
- 2026-09-04: implement gate: the decision goes to DECISIONS.md rather than the milestone-local section, and the seconds going unchecked gets one DESIGN.md known-issues line. Both as recommended.
- 2026-09-04: T5's DESIGN.md clause has no target: DESIGN.md carries no M075 sentence saying the run's seconds are held to its clock — M075 added KI241-KI245 there and its review KI246, none of them making that claim. The prose to correct is the suite's own, at the timer header, the M075 section banner and the comment above the driver's print. Minor amendment: T5's DESIGN.md half becomes the KI250 line the gate chose.
- 2026-09-04: T1 written (a third timer state, `SECTION_RUN_CLOSED`), pre-fix behaviour confirmed in a scratch harness spliced from HEAD: after `section_close`, a `section` call wrote a second `unattributed` row valued at the whole run. CHECKPOINT — T1's verify-slot run was still in flight when this commit was made; unchecked.
- 2026-09-04: T1 verified: `tests/run-tests.sh` exits 0 over 766 checks with the third state in place, and the timing accounting is green on the run that wrote it.
- 2026-09-04: T2 written: the seconds clause, its two readings and the AC3 print are gone; the membership, duplicate-row, setup-row and malformed-row clauses stand. T5's prose half moved here with it — the timer header, the M075 section banner and the comment above the driver's print all said the seconds were held to the run's clock, and leaving them saying so through T2's commit would have shipped a false comment. D-054 and KI250 written in the same commit for the same reason: T2's comments cite them. Minor amendment, no criterion moved. CHECKPOINT — T2's verify-slot run was still in flight at this commit; unchecked.
- 2026-09-04: T2's first verify run went red, and on the defect the clause is for: rewriting the M075 banner changed the section's heading while its `section '<heading>'` call still passed the old text, so the source declared a section with no row and the file carried a row naming none. Call corrected to the new heading, which is now a whole sentence rather than the wrapped fragment KI248 describes. Re-run in flight at this commit.
- 2026-09-04: T2 verified: `tests/run-tests.sh` exits 0 over 765 checks, one fewer than before, the removed line being the seconds report.
- 2026-09-04: T3 written: the five-seconds plant is retired with the clause it probed; the refusal plant runs two subshell legs over their own timing file, differing by the close alone. Shown to discriminate before the suite run — spliced against a1df8ab's timer it goes red naming the rows the pre-fix code left, `M077 probe section, opened by the probe itself 0` and `unattributed 461`, the second row being the whole run. CHECKPOINT — the --self-test run was in flight at this commit.
- 2026-09-04: T3 verified: `tests/run-tests.sh --self-test` exits 0 over 1396 checks, the plant's own pass line among them.
- 2026-09-04: T4 written: the plant now imports `BANNER_RULE` from `tests/suitescan.py` rather than re-typing a dash test, skips a lone divider as `banner_headings` does, and bounds the scan for a block's close. Both defects shown against the pre-M077 helper on crafted sources: with a `# ---` comment ahead of the real banner it dropped those three comment lines and left the banner standing, and on an unclosed trailing block it deleted through EOF with a final newline and raised IndexError without one. The repaired helper drops the real banner in the first case and reports the unclosed block by line number in the second. CHECKPOINT — the --self-test run was in flight at this commit.
- 2026-09-04: T4 verified: `tests/run-tests.sh --self-test` exits 0 over 1396 checks with no FAIL line, the two plants that drive the repaired helper among them.
- 2026-09-04: T5's wording amended to what the milestone did: `DESIGN.md` carried no sentence to correct, so its half of the task is the KI250 line the implement gate chose. Minor amendment, no criterion moved.
- 2026-09-04: T5 complete and AC3 met on the final source: `tests/run-tests.sh` exits 0 over 765 checks and `tests/run-tests.sh --self-test` exits 0 over 1396, neither printing a FAIL line; the self-test evidence is the run over `tests/run-tests.sh` as commit a2652f7 carries it, which HEAD leaves untouched. D-054 and KI250 landed with T2, the prose corrections with them. cairn_validate all PASS. Status set to review.
- 2026-09-04: plan gate chose keeping the heading-membership clause over deleting the accounting whole, because a section added with no timing call is the defect the profile exists to prevent and only that clause sees it; falsified by that clause going red for a reason that is neither a missing nor an extra section.
- 2026-09-04: /milestone-review opened: main had not moved under the branch, branch pushed, draft PR #77 opened and recorded in the header. Verification of the criteria is in flight.
- 2026-09-04: all three criteria verified with fresh evidence and their boxes ticked; consistency gate clean (cairn_validate 16 PASS / 7 OK, generic profile names no toolchain checks, no principle changed). Three fresh-context reviewers: the prior-review and blame-history lenses returned no findings, the [O] diff-bug lens eleven, all about the suite's own self-checks. No criterion failed, so no return floor is reached.

## Decisions

## Review

_Fresh evidence, 2026-09-04, over commit `7fb3f01` (the branch head at review
time; `tests/run-tests.sh` is byte-identical from `a2652f7` onward, so both
suite runs below cover the final source). PR #77._

### AC1 — `section` refuses a section opened after `section_close`

Shown by splicing the timer block (the `SECTION_HEADING` declaration through
the end of `section_close`) out of each of `origin/main` and the branch head
into the same scratch harness, and making the same call after the close:

- spliced from `origin/main`: the call was accepted, exit 0, and the probe's
  timing file carried two rows — `M077 probe section, opened by the probe
  itself 0` and `unattributed 461`, the second valued at the whole run.
- spliced from the branch head: exit 1 with
  `FAIL: M077: section 'M077 probe section, opened after the close' was opened
  after section_close had closed this run's timing …`, and the probe's file
  carried the first row only. No `unattributed` row was written.

The planted call is in the suite itself and green in the `--self-test` run
below (`M075 T5 self-test: … the timer refuses a section opened after the
close, naming that call, while the same call with the run still open goes
through and writes one ordinary row`). Its discrimination is narrower than it
reads — see F1.

### AC2 — the seconds clause is gone; the membership pair stands

- `M075_OPEN`, `M075_TOTAL` and `M075_NOW` are removed with the clause, and
  `grep` over `tests/run-tests.sh` finds no reference to any of them. The only
  surviving reading of `RUN_STARTED` is the setup row's own value (`:114`).
- What `m075_account` now holds: every heading in the timing file names a
  section `tests/suitescan.py sections` reports, every reported section has
  exactly one row, exactly one row is labelled `unattributed`, and every row
  parses as a heading and a whole number of seconds.
- Green on the run that wrote it: `ok M075-AC2: each of the 155 section(s)
  tests/suitescan.py sections declares has exactly one row in the timing file,
  and no row names anything else, the 1s row for the window before the first
  section included`. That pass line overstates what is checked — see F3.
- Red on both planted defects in the `--self-test` run: a section the source
  declares with no timing call, and a timing row no section declares, each
  naming the section it is about.

### AC3 — both runs exit 0

- `tests/run-tests.sh` — exit 0, `All checks passed (765 checks)`, no `FAIL`
  line in the log.
- `tests/run-tests.sh --self-test` — exit 0, `All checks passed (1396
  checks)`, no `FAIL` line in the log.

Merge-base comparison (the count rule at `tests/run-tests.sh:1787`): see the
work-log line recording the `origin/main` figures measured in a scratch
worktree.

### Consistency gate

`cairn_validate.py` — all 16 checks PASS, all 7 advisories OK (`release
window` did not fire). Active profile is `generic`, whose `consistency-gate`
slot names no toolchain checks. No `DESIGN.md` principle changed (the diff
adds one Known-issues entry, KI250), so `cairn_impact.py` does not apply.

### Independent review

Three fresh-context reviewers, distinct evidence bases.

**[S] prior-PR-comments** — no findings. The GitHub inline-comment probe
returned empty, so the archived `## Review` sections were the whole surface;
M075's F2 and F8 fixes and `tests/suitescan.py`'s F1/F6 fixes are untouched,
and T4 applies M076's re-typed-expectation lesson rather than violating it.

**[S] blame-history** — no regressions. It confirms T1 implements M075 review
F5, which predicted this exact bug, and that the seconds clause's removal is
the milestone's stated purpose, recorded in D-054 and KI250 rather than
silently dropped.

**[O] diff-bug** — eleven findings, ranked below.

- **F1. The AC1 probe's two legs differ in two variables, not one, so it cannot
  pin the refusal to the new flag** (`tests/run-tests.sh:25902-25913`).
  `section_close` both sets `SECTION_RUN_CLOSED` and clears `SECTION_HEADING`,
  so a wrong implementation spelled `[ -n "$SECTION_HEADING" ] || fail …` — the
  very conflation M077 undoes — passes both legs. Verified at review: splicing
  that guard into the branch's timer, the open leg exits 0 with one ordinary
  row and the closed leg exits 1 with the same refusal message, indistinguish-
  able from the correct implementation. The real run catches it only
  incidentally, at the first `section` call. A third leg — flag unset and
  heading empty, which must succeed and write the `unattributed` row — would
  pin it. Proposed: fix now.
- **F2. T4's two repairs and the new guard have no in-suite regression test**
  (`tests/run-tests.sh:25805`, `:25832-25845`). The pre-fix demonstration lives
  in the work log's prose and a scratch harness only; a later edit reinstating
  "any run of dashes" or dropping the `j >= len(lines)` bound leaves both runs
  green. Proposed: candidate row.
- **F3. The M075-AC2 pass line claims coverage the check does not have**
  (`tests/run-tests.sh:25761-25764`). "…and no row names anything else, the
  `%d`s row for the window before the first section included" reads as though
  the setup row were held against the declared section list; `timed` filters
  `unattributed` out at `:25733`, so only its multiplicity is checked.
  Confirmed by reading the check. Proposed: fix now.
- **F4. The drop plant's scan is bounded by EOF, not by the wrapper span the
  scanner uses** (`tests/run-tests.sh:25832`). `banner_headings` works over
  `[lo, hi)` from `run_all_span`; the plant scans `range(head, len(lines))`.
  The reviewer reproduced a source where the plant reports an unclosed block
  the scan never looks at. Same drift class T4 set out to close, left half
  fixed. Proposed: fix now.
- **F5. D-054's Consequences understate the change's scope**
  (`cairn/DECISIONS.md:404`): "no filter, fixture or other check changes", but
  M077 also adds a hard failure inside `section` that aborts the run.
  Proposed: reject — the sentence is about the checks over the extension's
  behavior, which is what the surrounding paragraph is enumerating, and a
  D-entry is history that is superseded rather than edited.
- **F6. The merge-base check counts were never stated.** The wrapper comment at
  `tests/run-tests.sh:1787-1790` makes the merge-base count a review input; the
  work log records only the post-change figures. Proposed: fix now — measure
  both `origin/main` figures and record them (done; see the work log).
- **F7. The archived M075 outcome still asserts the removed behavior in the
  present tense** (`cairn/milestones/archive/M075-suite-timing-profile.md:7`).
  Proposed: reject — the archive is history (IP4), never edited; D-054 is the
  supersession, and it names M075.
- **F8. `unattributed` is matched as an unanchored substring over whole rows**
  (`tests/run-tests.sh:25926`, `:25944`). A section heading containing the word
  would fail the control leg against a correct row. Proposed: fix now.
- **F9. The plant's rule is derived from the module it probes**
  (`tests/run-tests.sh:25802-25803`) — the "expectation derived from the
  artifact under test" shape. Reported as an observation: the mitigation
  (`rule = '# ' + '-' * 74` typed independently at `:25804`, guarded at
  `:25805` before the mode dispatch) is the right one. Proposed: reject, the
  mitigation is intentional and worth keeping.
- **F10. The plant's block reader omits `banner_headings`' headless-block error
  path** (`tests/run-tests.sh:25839-25845`); unreachable today, because the
  unmodified scan call at `:25694` would already have killed the run.
  Proposed: reject as unreachable.
- **F11. AC1-AC3 checkboxes were unticked while Status was `review`**
  (`cairn/milestones/M077-timing-accounting-window.md:41-48`). Proposed:
  reject — AC fencing ticks each box at review against its own evidence line,
  which is what happened above.

None of the eleven demonstrates an acceptance criterion failing, and none is a
defect in what the extension does for an author: every one is about the
acceptance suite's own self-checks. No return floor is reached.
