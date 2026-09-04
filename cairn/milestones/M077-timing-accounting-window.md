<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M077: The suite's timing accounting checks only what its own window covers

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a checker over a timing file the acceptance suite writes for itself
- **Branch/PR:** —

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

- [ ] T1: Give the section timer a third state (`tests/run-tests.sh:87-112`):
      `section_close` marks the run closed rather than clearing the same
      variable that means "before the first section", and `section` fails
      naming its own call when the run is closed.
- [ ] T2: Remove the seconds clause from `m075_account` (`:25631-25710`) and
      the `M075_OPEN` / `M075_TOTAL` readings that feed it, keeping the
      membership, duplicate-row, setup-row and malformed-row clauses. The
      driver's print (`:25823`) still reports the total, now as a figure
      nothing checks.
- [ ] T3: Retire T5's third plant — five seconds off one row (`:25802`) —
      with the clause it probes, and add the plant for T1's refusal.
- [ ] T4: Repair `m075_plant_source` (`:25726`): recognize a banner rule by the
      rule `tests/suitescan.py` uses (`BANNER_RULE`, `^# -{10,}\s*$`, `:78`)
      rather than by any run of dashes, and bound the inner scan for a block's
      close so an unclosed trailing block is reported rather than raising.
- [ ] T5: Write the decision entry recording the narrowing and why widening was
      declined; correct the M075 sentences in `DESIGN.md` and the suite's own
      header prose that say the run's seconds are held to its clock; full
      `tests/run-tests.sh --self-test` green.

## Work log

- 2026-09-04: created by /milestone-plan.
- 2026-09-04: criteria audit ran in reduced mode (internal tier) on the same fresh [O] reader, which authored none of the criteria; two rounds. Round 1 returned two findings on this milestone's draft, both fixed before the gate: a criterion whose promise was a DESIGN.md recording act, and a criterion binding the T5 plant helper's own properties, which moved to T4. Round 2 over the rewritten set returned nothing.
- 2026-09-04: plan gate chose dropping the accounting's seconds clause over widening the window it reads, because the accounting is a checker over an artifact only this suite reads and hardening such a checker is the regress shape; falsified by a section running untimed or twice-timed in a way only a seconds total could see.
- 2026-09-04: plan gate chose keeping the heading-membership clause over deleting the accounting whole, because a section added with no timing call is the defect the profile exists to prevent and only that clause sees it; falsified by that clause going red for a reason that is neither a missing nor an extra section.

## Decisions

## Review
