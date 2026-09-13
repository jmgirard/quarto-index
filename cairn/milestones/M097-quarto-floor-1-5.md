# M097: The extension requires Quarto 1.5

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — the minimum Quarto version decides who can install the extension
- **Branch/PR:** —

## Goal

The extension declares, documents and tests Quarto 1.5 as its minimum version, so that the Typst back-end (M098) can emit code that needs Typst 0.11.

## Scope

**In:** the `quarto-required:` range in `_extensions/index/_extension.yml`. The version statements in README, `site/index.qmd` and `site/tests.qmd`. The floor leg of `.github/workflows/versions.yml` and its header comment. The comment in `.github/workflows/pages.yml` that names the range. The suite checks and plants in `tests/run-tests.sh` that spell the old range or floor. The Known issues entries in `cairn/DESIGN.md` that name the old floor, KI110 and KI114. A CHANGELOG entry.

**Out:** the Typst back-end itself, which is M098. Released CHANGELOG sections, archived milestones, DECISIONS.md and LESSONS.md keep their text, because they are history. The 1.5.52 floor leg can show a new PDF engine difference. That difference becomes a Known issues entry, and its repair goes to the version-matrix candidate row that holds KI110 to KI114.

## Acceptance criteria

- [ ] AC1: `_extensions/index/_extension.yml` declares `quarto-required: ">=1.5.0"`. README, `site/index.qmd` and `site/tests.qmd` state that the extension requires Quarto 1.5 or later.
- [ ] AC2: The command `grep -rnIE '1\.4\.549|1\.4\.0|Quarto 1\.4|1\.4 or later' .` returns no hit outside five places. They are `.git/`, `site/_site/`, `tests/.work/` and `cairn/`, which holds history and this plan. The fifth is the CHANGELOG lines that name the old minimum as history: the released sections, and the one `## Unreleased` sentence that names release 0.4.0.
- [ ] AC3: The floor leg of `.github/workflows/versions.yml` installs Quarto 1.5.52. Its header comment gives the dated query that found 1.5.52 as the oldest non-prerelease release that `>=1.5.0` admits. A manually started run of the workflow on the milestone branch passes `render (floor)` and `render (pinned)`. Its compare job reports agreement between those two legs. The work log records the result of every other job in that run.
- [ ] AC4: The `## Unreleased` section of `CHANGELOG.md` states that the extension now requires Quarto 1.5 or later, and that Quarto 1.4 users stay on release 0.4.0.
- [ ] AC5: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1
- AC2 → T1, T2, T3, T4
- AC3 → T2, T4
- AC4 → T1
- AC5 → T3

## Tasks

- [ ] T1: Change the range in `_extension.yml` to `>=1.5.0`. Change the version sentences in README (line 23 and the floor sentence after it), `site/index.qmd:32` and `site/tests.qmd:22`. Add the CHANGELOG entry. D-060, written at the plan commit, records the decision.
- [ ] T2: In `versions.yml`, set `FLOOR: '1.5.52'` and rewrite the header comment with the query and its date. Re-read the 1.4.549 notes at line 277 and keep only what still applies. Change the range sentence in the `pages.yml` comment.
- [ ] T3: Update the suite. These sites spell the old range or floor: the `m42_plant` rows near `tests/run-tests.sh:20632`, the `versioncheck.py legs` calls near 22743, the floor plants near 22966 and 22990, and the comment near 19470. Move each one to the new range or floor so that each plant still goes red. Change the version examples in the `tests/versioncheck.py:292-297` docstring and in `tests/pagescheck.py:7` to the new floor and range. Run the suite and the self-test.
- [ ] T4: Push the branch, start `versions.yml` by hand, and record the run URL and the result of each job. Re-check KI110 against the floor leg's PDF job on 1.5.52 rather than substituting the version. Remove KI114, which records a failure on a leg that no longer exists, and name it in the work log. A red PDF job on the floor leg becomes a new Known issues entry.

## Work log

- 2026-09-13: created by /milestone-plan.
- 2026-09-13: plan gate chose raising the whole extension floor to Quarto 1.5. The rejected options kept 1.4, with a Typst pass-through and either one warning or none. The user chose it. The warning option detects the toolchain, which GP2 avoids. Falsified by a Quarto 1.4 user who needs a release newer than 0.4.0.
- 2026-09-13: criteria audit (full mode) on these criteria: running at this checkpoint commit. The plan is not final until its findings are disposed.
- 2026-09-13: criteria audit (full mode) returned 4 findings on these criteria, all adopted: grep exclusions, the named docstring sites, KI114 removed and KI110 re-checked, and the compare job read for the floor and pinned pair only. The plan is final.
- 2026-09-13: plan split the floor raise out of the Typst back-end because it ships on its own (split tripwire: tasks shippable independently). M098 depends on this milestone.

## Decisions

## Review
