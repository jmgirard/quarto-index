# M46: The claim-container registry is retired, not widened

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** `m046-retire-claim-registry`

## Goal

Retire the claim-container registry and its eighteen containers rather than widen
them, keep D-026's pre-release promise by a check that reads its own domain, and
repair the three real defects in the site checks that stay.

## Scope

**In:** Surface tier **internal** — the deliverable is this repo's own acceptance
suite over its own documentation source; no external consumer of the repo relies
on it. Delete `CLAIM_CONTAINERS`, `claim_row`/`claim_kind`/`claim_domain`/
`claim_text`, `check_claim_registry`, `check_claim_sets` and every comparison
check that reads its domain through `claim_text`. Three registered containers —
`README_RECIPE_LINES`, `README_INDEXES_CLAIMS`, `README_INDEXES_YAML` — are read
by checks naming their own page and are kept with those checks; only their
registry rows go. Replace `README_PRERELEASE_STALE` with a standalone check over
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

- [x] T1: Enumerate the eighteen `CLAIM_CONTAINERS` rows ([run-tests.sh:657](tests/run-tests.sh:657)) and, for each, name the check that reads it and what its deletion drops; write the table into this file's Decisions section.
- [ ] T2: Delete the registry and its helpers ([run-tests.sh:636-727](tests/run-tests.sh:636)), `check_claim_registry` and `check_claim_sets` (~1839-1970), the fourteen container arrays read through `claim_text`, and every comparison check reading them. `README_RECIPE_LINES`, `README_INDEXES_CLAIMS` and `README_INDEXES_YAML` keep their arrays and their checks. The `fail`-inside-a-command-substitution defect goes with `claim_row`.
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
- 2026-08-27: implement gate settled four open choices, all at the recommendation: the link check's base-segment clause binds only when a base path is given (nine existing plants pass an empty one); an escaping link gets its own failure message rather than reusing "names no file"; percent-decoding covers the path part only, as AC4 states; and the replacement pre-release check keeps printing the `M44-AC1` label.
- 2026-08-27: amendment — Scope In's deletion clause narrowed from "every per-container comparison check" to "every comparison check that reads its domain through `claim_text`", and T2's task wording with it. T1's enumeration found three registered containers the registry does not stand between: `check_recipe_block` and `check_readme_indexes` take their page as an argument. Deleting them would have dropped fifteen planted failure cases and M38-AC6's run-ledger clause, none of which the registry's defects were about. Chosen at a mini gate; recorded as D-028, which supersedes D-027's consequences clause on that one point.

## Decisions

### T1 — the eighteen registry rows, dispositioned (AC3)

Every row of `CLAIM_CONTAINERS` as it stands at 9e6b567. "Reads it" names the
check that compares the container against the docs; "disposition" says what the
deletion drops.

| # | Container | Kind | Reads it | Disposition |
|---|---|---|---|---|
| 1 | `SUPPORTED_FORMS` | presence | M02-AC6 exemplar comparison, via `claim_text` | Deleted. Drops the pin holding the ten documented authoring forms to the ones the suite exercises; the forms themselves stay exercised by the render checks. |
| 2 | `README_STALE` | absence | `check_claim_sets` (M03-AC7), via `claim_text` | Deleted. Drops the ban on the one-back-end sentences. |
| 3 | `README_HTML_CLAIMS` | presence | `check_claim_sets` (M03-AC7), via `claim_text` | Deleted with its partner — the check takes both containers at once. |
| 4 | `README_SORT_CLAIMS` | presence | M06-AC6, via `claim_text` | Deleted. Drops the pin on the sort-key prose; the behavior stays checked by the M06 renders. |
| 5 | `README_EMPTY_CLAIMS` | presence | M11-AC6, via `claim_text` | Deleted. Same shape: prose pin only. |
| 6 | `README_PRINCIPAL_CLAIMS` | presence | M20, via `claim_text` | Deleted. Same shape. |
| 7 | `README_STALEAUX_CLAIMS` | presence | M22/M31, via `claim_text` | Deleted. Same shape. |
| 8 | `README_RANGE_CLAIMS` | presence | M21, via `claim_text` | Deleted. Same shape. |
| 9 | `README_LETTER_CLAIMS` | presence | M07-AC6, via `claim_text` | Deleted. Same shape. |
| 10 | `README_REFS_STALE` | absence | M32 stale check, via `claim_text` | Deleted. Drops the ban on the fixed-order sentence. |
| 11 | `README_REFS_CLAIMS` | presence | M32 claims check, via `claim_text` | Deleted. The bibliography recipe's own fixture pair stays; the prose pin goes. |
| 12 | `README_UNICODE_CLAIMS` | presence | M33-AC4 prose check, via `claim_text` | Deleted. The copyable block's own check (row 13) stays. |
| 13 | `README_RECIPE_LINES` | presence | `check_recipe_block site/terms-outside-latin-1.qmd examples/unicode.qmd` — page named as an argument, never `claim_text` | **Kept.** The check survives with four planted cases (dropped line, reordering, unstated line, stated line absent from the fixture). Only the registry row goes. |
| 14 | `README_MISUSE_CLAIMS` | presence | M08, via `claim_text` | Deleted. Prose pin only. |
| 15 | `README_MISUSE_STALE` | absence | M08, via `claim_text` | Deleted with its partner — one check, both containers. |
| 16 | `README_PRERELEASE_STALE` | absence | `check_prerelease_absent`, via `claim_text` | **Replaced** (T3) by a standalone check reading `git ls-files 'site/*.qmd'` plus `README.md`. Its two generic rows — "Breaking changes are recorded in the changelog" and the deprecation sentence — are dropped as still-true sentences; the two retired ones stay forbidden. |
| 17 | `README_INDEXES_CLAIMS` | presence | `check_readme_indexes site/named-indexes.qmd … "$RAN_LEDGER"` — page named as an argument | **Kept.** Eleven planted cases and M38-AC6's run-ledger clause ride on it. Only the registry row goes. |
| 18 | `README_INDEXES_YAML` | presence | same check as row 17 | **Kept**, for the same reason. |

Fourteen deleted, three kept, one replaced. The `fail`-inside-a-command-substitution
defect lives in `claim_row` and goes with rows 1-12 and 14-16.

## Review
