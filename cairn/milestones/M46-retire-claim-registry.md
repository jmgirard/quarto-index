# M46: The claim-container registry is retired, not widened

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** —

## Goal

Retire the claim-container registry and its eighteen containers rather than widen
them, keep D-026's pre-release promise by a check that reads its own domain, and
repair the three real defects in the site checks that stay.

## Scope

**In:** Surface tier **internal** — the deliverable is this repo's own acceptance
suite over its own documentation source; no external consumer of the repo relies
on it. Delete `CLAIM_CONTAINERS`, `claim_row`/`claim_kind`/`claim_domain`/
`claim_text`, `check_claim_registry`, `check_claim_sets` and every per-container
comparison check. Replace `README_PRERELEASE_STALE` with a standalone check over
`git ls-files 'site/*.qmd'` plus `README.md`. Repair `tests/sitecheck.py links`
(percent-decoding, containment, the base-path clause) and make the standing site
render clean its output directory. Append D-027.

**Out:** the version-matrix disposition → M47. Pinning documentation prose beyond
the two retired pre-release sentences → the residual-risk candidate row D-027
creates. Rewording any site page → not this milestone; the docs' text is
untouched. Every remaining unplanted clause in the kept site checks → the same
candidate row.

## Acceptance criteria

- [ ] AC1: In `tests/run-tests.sh`, `grep -c 'CLAIM_CONTAINERS\|claim_row\|claim_kind\|claim_domain\|claim_text'` reports 0.
- [ ] AC2: `tests/run-tests.sh` carries a check whose swept domain is `git ls-files 'site/*.qmd'` plus `README.md`, which reports that domain's size, and which exits non-zero with a `FAIL:` line naming the offending file when either retired pre-release sentence is present in a tracked page supplied through the suite's overlay handle.
- [ ] AC3: Every row of the `CLAIM_CONTAINERS` array as it stands at commit 9e6b567 is dispositioned in this file's Decisions section — still pinned by a named kept check, or deleted with the reason.
- [ ] AC4: `tests/sitecheck.py links` percent-decodes each link's path part and resolves it only against files inside the captured site directory it was given.
- [ ] AC5: `tests/sitecheck.py links`' base-path clause exits non-zero on a root-relative link carrying no base segment.
- [ ] AC6: The suite's standing site render removes its output directory before rendering into it.
- [ ] AC7: `tests/run-tests.sh` completes at exit 0 and prints its check count, and `tests/run-tests.sh --self-test` completes at exit 0.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T4
- AC5 → T4
- AC6 → T5
- AC7 → T7

## Tasks

- [ ] T1: Enumerate the eighteen `CLAIM_CONTAINERS` rows ([run-tests.sh:657](tests/run-tests.sh:657)) and, for each, name the check that reads it and what its deletion drops; write the table into this file's Decisions section.
- [ ] T2: Delete the registry and its helpers ([run-tests.sh:636-727](tests/run-tests.sh:636)), `check_claim_registry` and `check_claim_sets` (~1839-1970), the eighteen container arrays, and every comparison check reading them. The `fail`-inside-a-command-substitution defect goes with `claim_row`.
- [ ] T3: Write the standalone pre-release check: the two retired sentences verbatim, domain `git ls-files 'site/*.qmd'` plus `README.md`, swept count reported, offending file named. Drop the two generic rows M44 found — sentences still true, which would report a legitimate future stability sentence as the warning coming back. Plant each sentence through the overlay handle.
- [ ] T4: Repair `tests/sitecheck.py links` — percent-decode the path part, confine resolution to the captured site root, fail a root-relative link with no base segment. One planted case each.
- [ ] T5: Make the standing site render remove `$SITE_OUT` before rendering ([run-tests.sh:13302](tests/run-tests.sh:13302)).
- [ ] T6: Append D-027; strike the DESIGN.md Known-issues entries this closes; rewrite the ROADMAP rows pointing at them.
- [ ] T7: Full run plus `--self-test`; record the check count before and after.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose retiring the claim-container registry over narrowing it to a kept set, because three of the row's findings are repairable only by widening a scan over the suite's own source — the shape D-011 refused and M25 executed under "A check that cannot hold its promise is retired, not widened"; falsified by a documentation sentence drifting from behavior and reaching a release with the suite green.
- 2026-08-26: plan gate chose superseding D-026's mechanism clause with a standalone grep over keeping that one container, because a one-row registry is still a registry and M44 found two of its four rows would report a legitimate stability sentence as the warning coming back; falsified by the standalone check going vacuous where the registry's domain enumeration would not have.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). It returned two findings here — a work-log recording clause on the suite-run criterion, and plant-property wording ("red before the fix and green after") on the site-check repairs. Both were fixed before the criteria above were written: the recording clause was dropped, and the repairs are stated as assertions on the shipped checks.

## Decisions

## Review
