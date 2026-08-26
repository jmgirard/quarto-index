# M42: GitHub Actions renders the site and publishes it to Pages

- **Status:** review
- **Priority:** normal
- **Depends on:** M41
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** m042-pages-publish · https://github.com/jmgirard/quarto-index/pull/42

## Goal

A GitHub Actions workflow renders the site with the toolchain it installs and
publishes it to GitHub Pages from the default branch.

## Scope

Surface tier: **user-facing** — this is the step that makes the site public.

**In:** `.github/workflows/pages.yml` — the repo's first workflow — installing
a pinned Quarto and the LaTeX toolchain M41's PDFs need, rendering `site/`,
uploading the Pages artifact, and deploying on the default branch only; the
published URL added to README; ignore rules for the render's whole output.

The build leg is proved **pre-merge on the milestone branch**, per the plan
gate: the deploy job is gated on the default branch and shows as skipped there.
Setting **Settings → Pages → Source: GitHub Actions** is a repository setting
no branch contains — the user does it before this milestone's review, and the
live URL returning 200 is recorded as a post-merge work-log line, never as a
criterion a pre-merge gate could discharge.

**Out:** the Quarto floor/latest CI matrix and KI79 → the standing candidate
row, amended here with a pointer to this workflow as where a matrix attaches.
Pinning one Quarto version satisfies `>=1.4.0` trivially and fences nothing
about the floor; nothing in this milestone closes KI79. Running the acceptance
suite in CI → not planned; a candidate row.

## Acceptance criteria

- [x] AC1. `.github/workflows/pages.yml`, run on this milestone's branch,
      concludes `success`, and the Pages artifact it uploads contains every
      `.html` and `.pdf` path that `quarto render site` produces under
      `site/_site/` on the same commit with the toolchain the workflow
      installs. That set holds at least three `.pdf` paths.
- [x] AC2. The workflow's deploy job is gated on the default branch, and the
      branch run of AC1 reports that job skipped.
- [x] AC3. The workflow pins Quarto to an exact version string, and that string
      satisfies the `quarto-required` range `_extensions/index/_extension.yml`
      declares, compared by splitting both on `.` and comparing integer tuples.
- [x] AC4. The workflow concludes `failure` on each member of this family, each
      planted separately on a probe branch: a `site/` source that fails to
      render; a render leaving no `site/_site/index.html`; a render that
      succeeds while dropping a page AC1's containment requires; a Quarto pin
      naming a version that does not exist; and a render whose non-zero exit is
      produced inside a pipeline (the `tee`/errexit shape `check-design.md`
      records at M04).
- [x] AC5. After `quarto render site`, `git status --porcelain` reports no
      untracked path under `site/`, and `git ls-files` returns none under
      `site/_site/` or `site/.quarto/`.
- [x] AC6. README.md contains the published site URL, and it is the URL the
      workflow's deploy job publishes to.
- [x] AC7. `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T2, T5
- AC3 → T2, T4
- AC4 → T5
- AC5 → T3, T4
- AC6 → T6
- AC7 → T4, T5, T6

## Tasks

- [x] T1. Confirm with the user that Pages source is set to GitHub Actions
      before implementation ends; the deploy leg cannot be exercised otherwise.
- [x] T2. Write `.github/workflows/pages.yml`: pinned Quarto, the LaTeX
      toolchain the render reaches (TinyTeX, which carries `makeindex`),
      render, `upload-pages-artifact`, and a `deploy-pages` job gated on the
      default branch.
- [x] T3. Extend `.gitignore` to cover the render's whole output under `site/`,
      verified against a real render rather than a literal path.
- [x] T4. Write the checks for AC3 and AC5, including the version comparison
      procedure the criterion names.
- [x] T5. Run the five AC4 plants on probe branches, one substitution each so a
      no-op leaves the log unchanged (`check-design.md`, M29), and record each
      run URL and conclusion.
- [x] T6. Add the published URL to README and to the site; amend the CI-matrix
      candidate row with a pointer to this workflow. Verify slot clean.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: [O] criteria audit ran, full mode (user-facing tier), over the round-2 draft; it returned findings on AC1-AC4 of that draft and clean on the verify slot. All disposed here.
- 2026-08-26: plan gate chose proving the build leg pre-merge on the branch and recording the live URL post-merge over making the live URL a criterion; the audit showed `actions/deploy-pages` needs a repo setting and the `github-pages` environment refuses non-default-branch deployments, so a live-URL criterion is unreachable at the gate that owns it. Falsified by a build-leg green run that the deploy leg then fails on.
- 2026-08-26: plan gate chose one pinned Quarto version over a floor/latest matrix here; the matrix is a standing candidate row and belongs with KI79, and folding it in would make a red floor render block the site going public. Falsified by the pinned version diverging from what the floor claim promises in a way a reader hits.
- 2026-08-26: gate chose the artifact's containment judged against a local render of the same commit over the runner's own listing; Quarto pinned to 1.10.18, the version installed here, so the local render is a same-toolchain render; TinyTeX alone rather than the wider toolchain T2's parenthetical names, since nothing in the site build reaches `pdftotext` or the STIX font (minor amendment to T2's wording, the workflow proved by a real CI render); and the actions named by major tag — D-024.
- 2026-08-26: T2 — `.github/workflows/pages.yml` written. `actions/configure-pages` is not used; see this file's Decisions.
- 2026-08-26: T3 — verified against a real `quarto render site`: the render's whole output under `site/` is `site/_site/`, `site/gallery/` and `site/.quarto/`, all three already covered (the first two by the root ignore file, the third by Quarto's own `site/.gitignore`), and `git status` reports no untracked path under `site/`. Nothing to extend.
- 2026-08-26: T4 — `tests/pagescheck.py` added with three readers (`pin`, `built`, `contains`); the suite runs `pin` and `built` as standing checks and adds the AC5 clauses after the site render. Twenty planted cases and two discriminating controls, each clause planted on its own.
- 2026-08-26: T6 (part) — README and the site's entry page name the published URL, and `tests/pagescheck.py url` binds both to the URL the `origin` remote implies and to the base path the suite's link check resolves against; the link check's base path moved from the empty string to the repository segment, which M40 left as the value this milestone sets. The CI-matrix candidate row now names the workflow file. Six more planted cases; the no-remote case first passed for the wrong reason, because `git -C` walks up out of a bare directory in the work tree into this checkout, and now plants a repository of its own.
- 2026-08-26: suite green after those changes: `tests/run-tests.sh --self-test`, 649 checks, exit 0.
- 2026-08-26: T2 (refined) — the workflow's `concurrency` group moved from the workflow onto the deploy job. At workflow level it made every branch's build queue behind every other branch's, including the five probe branches T5 runs; only the publishing step has a single target, so only it needs serializing.
- 2026-08-26: T5 round 1 — five probe branches run. Four failed at the step their plant is about; the broken-source probe instead died installing TinyTeX, on a 403 from the GitHub API, which `quarto install tinytex` calls unauthenticated to resolve the current release. Six runs started together share the runner network, and that is the rate limit. The setup step now passes the run's own token, and all five probes plus the branch run are re-run on the fixed workflow.
- 2026-08-26: T5 — five probe branches re-run on the fixed workflow, each carrying one substitution and nothing else, each concluding `failure` at the step its plant is about: a broken include in `site/index.qmd` at the render (https://github.com/jmgirard/quarto-index/actions/runs/33013552310); an output directory renamed in `site/_quarto.yml` at the tracked-page check, which names all 20 pages (runs/33013553886); one shown fixture dropped from the gallery build's loop at the completeness check, which names that fixture's three paths (runs/33013555753); the Quarto pin at 1.10.999 at the install step, on a 404 for that download (runs/33013557204); and a render target that does not exist inside the `tee` pipeline at the render step, on Quarto's own error and not `tee`'s success (runs/33013558924).
- 2026-08-26: AC1/AC2 evidence on commit cab7fdf — https://github.com/jmgirard/quarto-index/actions/runs/33013541670 concluded `success` with the deploy job skipped, and its `github-pages` artifact contains all 51 `.html`/`.pdf` paths a local render of the same commit produces, 10 of them PDFs.
- 2026-08-26: T6 — DESIGN's Architecture gains the publishing workflow and `tests/pagescheck.py`; its sentence on the toolchain the site build needs is corrected in place and marked, since the workflow renders the whole site with TinyTeX alone.
- 2026-08-26: verify slot clean after T5 and T6: `tests/run-tests.sh --self-test`, 649 checks, exit 0.
- 2026-08-26: T1 — the user was asked at the gate whether Settings → Pages → Source is set to GitHub Actions and chose to set it. `gh api repos/jmgirard/quarto-index/pages` still answered 404 when checked immediately afterwards — observed 2026-08-26 — so the setting is not confirmed from this side; the plan puts the live URL post-merge, and /milestone-review re-reads this endpoint before it merges.
- 2026-08-26: all tasks done, verify slot clean, status → review.
- 2026-08-26: review round 1 — three fresh-context reviewers. Blame-history and prior-review each reported no findings; diff-bug reported fourteen, every one re-run against the implementation before triage. Ten fixed on the branch at the maintainer's direction, two rejected with reason, two filed on the suite-hardening candidate row. Details in the Review section.

## Decisions

- 2026-08-26 (T2): the workflow does not use `actions/configure-pages`. The starter workflow GitHub publishes includes it to hand a site generator the base URL it will be served under, and this site makes only relative links, so nothing reads that output. Keeping it would put a step that calls the Pages API — and fails while Pages is not yet enabled on the repository — ahead of the render on every branch, which would make a probe branch's red say nothing about the render it was planted in. The base path the published site is served under enters this repo in one place instead, the `SITE_BASE_PATH` value `tests/run-tests.sh` gives its link check.

## Review

Reviewed 2026-08-26. Evidence below is from the branch at commit c144320 —
after the ten review fixes — PR https://github.com/jmgirard/quarto-index/pull/42.
Every figure is from a command run at review, not from the implementation
session's records; the round taken before the fixes was discarded rather than
carried forward.

**AC1.** Run https://github.com/jmgirard/quarto-index/actions/runs/33016903266
on commit c144320 concluded `success`. Its `github-pages` artifact was
downloaded, unpacked, and compared with `tests/pagescheck.py contains` against
`site/_site` from a `quarto render site` on the same commit with Quarto
1.10.18, the version the workflow pins: the artifact contains all 51 `.html`
and `.pdf` paths that render produces, 10 of them `.pdf` (floor 3).

**AC2.** `.github/workflows/pages.yml:78` gates the deploy job
`if: github.ref == format('refs/heads/{0}', github.event.repository.default_branch)`,
so the gate is over the ref and not over its short name — a tag named after
the default branch no longer satisfies it (finding F9). The AC1 run reports
that job `skipped`, as does every one of the five AC4 runs.

**AC3.** `python3 tests/pagescheck.py pin .github/workflows/pages.yml
_extensions/index/_extension.yml` exits 0, reading the pin 1.10.18 out of the
step that uses `quarto-dev/quarto-actions/setup` and the declared floor 1.4.0,
and comparing `(1, 10, 18) >= (1, 4, 0)` as integer tuples.

**AC4.** Five probe branches, each rebased onto c144320 and carrying one
substitution and nothing else, each concluding `failure` at the step its plant
is about: a broken include in `site/index.qmd` at the render step
(runs/33016927676); `output-dir` renamed in `site/_quarto.yml` at the
tracked-page step (runs/33016929230); one shown fixture dropped from the
gallery build's loop at the completeness step (runs/33016930697); the Quarto
pin at 1.10.999 at the install step (runs/33016932872); and a render target
that does not exist, inside the `tee` pipeline, at the render step
(runs/33016933334).

**AC5.** `tests/run-tests.sh --self-test` reports M42-AC5 green: over
`git status --porcelain -z` and `git ls-files` taken immediately after the
site render — the criterion's own two commands, the first with NUL separators
so a path git would otherwise C-quote is still seen (finding F11) — no line is an
untracked path under `site/`, git tracks none under `site/_site/` or
`site/.quarto/`, and the render's output directory is reported ignored — the
non-vacuity control.

**AC6.** `python3 tests/pagescheck.py url README.md site/index.qmd
tests/run-tests.sh` exits 0: README and the site's entry page both name
https://jmgirard.github.io/quarto-index/, the URL the `origin` remote implies,
and the suite resolves a root-relative link against `quarto-index`, that URL's
path segment. The second half of the criterion is discharged against GitHub's
own record rather than that convention: with Pages now enabled,
`gh api repos/jmgirard/quarto-index/pages` returns `build_type: workflow`
(the deploy job is the publisher), `cname: null` (no custom domain overriding
it) and `html_url: https://jmgirard.github.io/quarto-index/` — the string
README carries.

**AC7.** `tests/run-tests.sh --self-test` exits 0, 659 checks.

**Consistency gate.** `cairn_validate.py` passes, all 16 checks PASS and all 7
advisories OK. The `generic` profile names no toolchain consistency check, so
that half is a clean no-op. No principle changed, so `cairn_impact` is skipped.

**Independent review.** Three fresh-context reviewers, none having seen the
implementation. The blame-history lens and the prior-review lens each reported
no findings. The diff-bug lens reported fourteen, ranked; each is recorded
below with its disposition. Ten were fixed on the branch in commit c144320 at
the maintainer's direction; the evidence above was then re-taken in full
against that commit, the suite and all six workflow runs included.

**Findings and dispositions** (diff-bug lens, its own ranking kept). Each was
re-run against the implementation before being triaged.

- F1. `pin`'s `version:` pattern matches any indented `version:` line anywhere
  in the workflow, while its message claims "under a `with:` block" — a
  property it never establishes (check-design, M23). Reproduced: a workflow
  with the pin removed from the Quarto setup step and `version: 1.10.18` on an
  unrelated `actions/setup-node` step exits 0. → fixed on the branch.
- F2. `SITE_BASE_PATH="quarto-index"` does not tighten the M40 link check: a
  root-relative href that does not start with the base is still resolved
  against the site root, so `/syntax.html` passes under either value while
  production would 404, and the rendered site emits no root-relative href at
  all. → reject: the change itself is right (it stops the production-correct
  `/quarto-index/...` form reading as dangling), and the gap named is
  pre-existing and already filed on the suite-hardening candidate row from M40
  review. Row extended with the dead-branch observation.
- F3. `EXACT` accepts a bare major line (`version: 2` exits 0) although the
  comment beside it says a bare major line is a channel, not a pin.
  Reproduced. → fixed on the branch.
- F4. `check_url`'s unparseable-remote clause has no planted case
  (check-design, M32). → fixed on the branch.
- F5. AC5's two clauses have no planted case at all; only the non-vacuity
  control is proved. → fixed on the branch.
- F6. AC6's second half is checked by convention, not by reading the Pages
  setting: a custom domain would leave both documents naming a URL the deploy
  job does not publish to, with the suite green (check-design, M25). → filed on the suite-hardening candidate row.
- F7. The `contains` PDF-floor plant reuses the artifact copy the previous case
  removed a page from, so it would also fail the containment clause; it passes
  for the right reason only because the reader evaluates the floor first. → fixed on the branch.
- F8. Nothing binds the workflow's own steps: deleting the two completeness
  steps, or changing the upload path, leaves the suite green. → reject: D-011
  refuses a widened source-shape scan and says the evidence for a positional
  property is a render. That evidence exists — AC4's `nooutput` probe fails at
  the tracked-page step and its `droppage` probe at the completeness step, so
  both steps are shown to run. The residual risk goes on the candidate row.
- F9. `github.ref_name` is the tag name on a tag push, so a tag named after the
  default branch satisfies the deploy gate and publishes from that tag. → fixed on the branch; the gate now compares `github.ref` against `refs/heads/<default>` instead.
- F10. The deploy job's job-level `permissions` replaces the workflow-level
  set, dropping `contents: read`. → fixed on the branch.
- F11. `grep -c '^?? site/'` misses a path git C-quotes. Reproduced in a
  scratch repository: an untracked `site/naïve.html` is reported as
  `?? "site/na\303\257ve.html"` and does not match. → fixed on the branch.
- F12. `contains` compares only `.html` and `.pdf`, so an upload dropping
  `site_libs/` would publish an unstyled site and pass. AC1's own wording
  scopes it that way. → filed on the suite-hardening candidate row.
- F13. `PIN` rejects a legitimately quoted pin (`version: "1.10.18"` fails)
  while `REQUIRED` in the same file strips quotes. Reproduced. → fixed on the branch.
- F14. Minor: a local name shadows the module-level `published` function; the
  self-test header says "the two readers M42 adds" where there are four; the
  site side of the not-a-directory clause is unplanted; one corrected DESIGN
  line runs past the file's wrap. → fixed on the branch.

