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

- [ ] AC1: `section` refuses to open a section after `section_close` has run,
      rather than writing a second setup row valued at the whole run's wall
      clock; shown red on a planted call.
- [ ] AC2: the accounting's seconds clause is removed; what remains holds every
      heading in the timing file to a section `tests/suitescan.py sections`
      reports, and every section that scan reports to exactly one row.
- [ ] AC3: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` each
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

## Decisions

## Review
