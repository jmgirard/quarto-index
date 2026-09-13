# M097: The extension requires Quarto 1.5

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — the minimum Quarto version decides who can install the extension
- **Branch/PR:** m097-quarto-floor-1-5

## Goal

The extension declares, documents and tests Quarto 1.5 as its minimum version, so that the Typst back-end (M098) can emit code that needs Typst 0.11.

## Scope

**In:** the `quarto-required:` range in `_extensions/index/_extension.yml`. The version statements in README, `site/index.qmd` and `site/tests.qmd`. The floor leg of `.github/workflows/versions.yml` and its header comment. The comment in `.github/workflows/pages.yml` that names the range. The suite checks and plants in `tests/run-tests.sh` that spell the old range or floor. The Known issues entries in `cairn/DESIGN.md` that name the old floor, KI110 and KI114. A CHANGELOG entry.

**Out:** the Typst back-end itself, which is M098. Released CHANGELOG sections, archived milestones, DECISIONS.md and LESSONS.md keep their text, because they are history. The 1.5.52 floor leg can show a new PDF engine difference. That difference becomes a Known issues entry, and its repair goes to the version-matrix candidate row that holds KI110 to KI114.

## Acceptance criteria

- [x] AC1: `_extensions/index/_extension.yml` declares `quarto-required: ">=1.5.0"`. README, `site/index.qmd` and `site/tests.qmd` state that the extension requires Quarto 1.5 or later.
- [x] AC2: The command `grep -rnIE '1\.4\.549|1\.4\.0|Quarto 1\.4|1\.4 or later' .` returns no hit outside five places. They are `.git/`, `site/_site/`, `tests/.work/` and `cairn/`, which holds history and this plan. The fifth is the CHANGELOG lines that name the old minimum as history: the released sections, and the one `## Unreleased` sentence that names release 0.4.0.
- [x] AC3: The floor leg of `.github/workflows/versions.yml` installs Quarto 1.5.52. Its header comment gives the dated query that found 1.5.52 as the oldest non-prerelease release that `>=1.5.0` admits. A manually started run of the workflow on the milestone branch passes `render (floor)` and `render (pinned)`. Its compare job reports agreement between those two legs. The work log records the result of every other job in that run.
- [x] AC4: The `## Unreleased` section of `CHANGELOG.md` states that the extension now requires Quarto 1.5 or later, and that Quarto 1.4 users stay on release 0.4.0.
- [x] AC5: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1
- AC2 → T1, T2, T3, T4
- AC3 → T2, T4
- AC4 → T1
- AC5 → T3

## Tasks

- [x] T1: Change the range in `_extension.yml` to `>=1.5.0`. Change the version sentences in README (line 23 and the floor sentence after it), `site/index.qmd:32` and `site/tests.qmd:22`. Add the CHANGELOG entry. D-060, written at the plan commit, records the decision.
- [x] T2: In `versions.yml`, set `FLOOR: '1.5.52'` and rewrite the header comment with the query and its date. Re-read the 1.4.549 notes at line 277 and keep only what still applies. Change the range sentence in the `pages.yml` comment.
- [x] T3: Update the suite. These sites spell the old range or floor: the `m42_plant` rows near `tests/run-tests.sh:20632`, the `versioncheck.py legs` calls near 22743, the floor plants near 22966 and 22990, and the comment near 19470. Move each one to the new range or floor so that each plant still goes red. Change the version examples in the `tests/versioncheck.py:292-297` docstring and in `tests/pagescheck.py:7` to the new floor and range. Run the suite and the self-test.
- [x] T4: Push the branch, start `versions.yml` by hand, and record the run URL and the result of each job. Re-check KI110 against the floor leg's PDF job on 1.5.52 rather than substituting the version. Remove KI114, which records a failure on a leg that no longer exists, and name it in the work log. A red PDF job on the floor leg becomes a new Known issues entry.

## Work log

- 2026-09-13: created by /milestone-plan.
- 2026-09-13: plan gate chose raising the whole extension floor to Quarto 1.5. The rejected options kept 1.4, with a Typst pass-through and either one warning or none. The user chose it. The warning option detects the toolchain, which GP2 avoids. Falsified by a Quarto 1.4 user who needs a release newer than 0.4.0.
- 2026-09-13: criteria audit (full mode) on these criteria: running at this checkpoint commit. The plan is not final until its findings are disposed.
- 2026-09-13: criteria audit (full mode) returned 4 findings on these criteria, all adopted: grep exclusions, the named docstring sites, KI114 removed and KI110 re-checked, and the compare job read for the floor and pinned pair only. The plan is final.
- 2026-09-13: plan split the floor raise out of the Typst back-end because it ships on its own (split tripwire: tasks shippable independently). M098 depends on this milestone.
- 2026-09-13: implement started on branch m097-quarto-floor-1-5; question gate skipped, the plan left no choice open.
- 2026-09-13: T1 done: range `>=1.5.0`, README, site/index.qmd and site/tests.qmd sentences, CHANGELOG `### Project` entry under Unreleased. README sentence em-dashes replaced by commas; older README style hits left alone.
- 2026-09-13: T2 done: FLOOR 1.5.52, header query re-run 2026-09-13 (first `v1.5.` tag after sort -V is v1.5.52), imakeidx note kept without the version, pages.yml range sentence changed.
- 2026-09-13: T3 done: m42 range plants, versioncheck legs calls, floor plants (1.5 and 1.5.520 forms), comment at 19470 and both docstrings moved; `tests/run-tests.sh --self-test` passed, 1523 checks.
- 2026-09-13: T4 run: versions.yml dispatched on the branch at d599df8, https://github.com/jmgirard/quarto-index/actions/runs/34779339060. All 8 jobs success: plan, render (floor, 1.5.52), render (pinned, 1.10.18), render (release, release), pdf (floor, 1.5.52), pdf (pinned, 1.10.18), pdf (release, release), compare. Compare: floor and pinned byte-identical on book, demo, html-index and named-indexes (release matched pinned too). The push-triggered run 34779339444 also passed.
- 2026-09-13: T4 records: KI110 re-checked, the floor PDF job logs `pdf-engine: xelatex` on 1.5.52, so the entry stands with the new version. KI114 removed (a one-off failure on the retired 1.4.549 leg), and the version-matrix candidate row drops its KI114 label and recurrence clause. No red floor PDF job, so no new Known issues entry.
- 2026-09-13: claim audit: 21 claims read, 1 corrected — .github/workflows/versions.yml, README.md, site/tests.qmd (v1.5.0 to v1.5.51 exist as prereleases, so the header and both floor sentences now say non-prerelease; re-read holds).
- 2026-09-13: `tests/run-tests.sh --self-test` re-run after the correction passed, 1523 checks. Status set to review.
- 2026-09-13: review checkpoint: AC1-AC4 evidence recorded and ticked, validate green; suite, self-test and two reviewers still running, AC5 unticked.
- 2026-09-13: review pre-gate checkpoint: all five criteria evidenced and ticked, gate green, 8 findings from three reviewers logged for triage at the approval gate.
- 2026-09-13: step-7 approval: m097-quarto-floor-1-5 approved for merge
- 2026-09-13: gate fix-now: findings 4-7 fixed (prose and comment wraps only), 1-3 and 8 rejected with reasons in Review.

## Decisions

## Review

Reviewed 2026-09-13 at 2fd04ec. The branch contains `origin/main` (3ae2cfe), so no merge was needed before gathering evidence.

- AC1 evidence: `_extension.yml:4` reads `quarto-required: ">=1.5.0"`. `README.md:23` and `site/index.qmd:32` read "Requires Quarto 1.5 or later". `site/tests.qmd:21-23` states the `>=1.5.0` range the extension declares, with 1.5.52 as its oldest non-prerelease release. That sentence gives the requirement as the declared range, not as the words "1.5 or later".
- AC2 evidence: the criterion's grep, run at the repository root, returns hits under `cairn/` and two hits outside it. `CHANGELOG.md:24` is the `## Unreleased` sentence that names release 0.4.0. `CHANGELOG.md:533` is in the released 0.1.0 section. No hit falls under `.git/`, `site/_site/` or `tests/.work/`, and no other file has a hit.
- AC3 evidence: `versions.yml:90` sets `FLOOR: '1.5.52'`. The header, lines 9-16, dates the query 2026-09-13 and gives it. The query, re-run at review, still returns `v1.5.52`. Run 34779339060 is a `workflow_dispatch` run on `m097-quarto-floor-1-5` at d599df8, read again with `gh run view`. `render (floor, 1.5.52)` and `render (pinned, 1.10.18)` passed. The compare job log reports the floor leg byte-identical to the pinned leg on book, demo, html-index and named-indexes. The T4 work-log line records all 8 job results. The commits after d599df8 change only prose: the `versions.yml` header comment, README and `site/tests.qmd`. The run covers the workflow as it now runs.
- AC4 evidence: `CHANGELOG.md:24-25`, under `## Unreleased` then `### Project`, reads that the extension now requires Quarto 1.5 or later and that Quarto 1.4 users stay on release 0.4.0.
- AC5 evidence: at 743c974, `tests/run-tests.sh` passed with 804 checks and exit 0 in 10 min 42 s. Then `tests/run-tests.sh --self-test` passed with 1523 checks and exit 0 in 14 min 38 s. The two runs were sequential.

Consistency gate: `cairn_validate.py` exit 0, with one advisory on M098's criterion count. No DESIGN principle text changed, so the impact report was skipped. The generic profile names no toolchain checks.

Review findings, three reviewers, ranked within each lens:

- [O] 1: the dispatched run tested d599df8, not the head. The later commits change only prose and comments.
- [O] 2: no plain suite run was recorded for AC5. This review's fresh plain run supplies it.
- [O] 3: if `quarto add` only warns, the CHANGELOG sentence "the last release that installs on it" overstates. At tag v1.4.549, `src/extension/install.ts` reads the staged extension through `readExtensions`, and `validateExtension` in `extension.ts` throws on an unmet `quarto-required`. The sentence holds.
- [O] 4: `pages.yml:12-14` still calls a floor/latest matrix a standing candidate row. `versions.yml` is that matrix, added by M43.
- [O] 5: `cairn/DESIGN.md:27-29` still calls CI against the floor and latest a future candidate.
- [O] 6, [S] blame 1: `versions.yml:282` leaves "Run on every leg and" as a short broken line.
- [O] 7, [S] prior-review 1-2: `site/tests.qmd:23` runs to 96 characters and `README.md:26` to 81. M34 and M093 reviews fixed the same wrap defect.
- [O] 8: the header query greps `^v1\.5\.` and drops prereleases, so it cannot show the prerelease sentence beside it. Both claims are true by the releases API.
- [S] prior-review: the PR-comment probe returned no inline comments.

Triage at the approval gate, chosen by the user:

- Fixed now: 4 (`pages.yml` sentence now points at `versions.yml`), 5 (DESIGN contract bullet, marked corrected M097), 6 (`versions.yml` comment rewrapped), 7 (`site/tests.qmd` paragraph and `README.md` line rewrapped, no line over 80). After the fixes, `tests/versioncheck.py floor` passed and both workflows parse as YAML.
- Rejected: 1, because the commits after the run change no workflow step. 2, because this review's plain run supplies the evidence. 3, because Quarto 1.4.549's install code refuses the extension. 8, because both header claims are true and the query is recorded as the one that returned 1.5.52.
