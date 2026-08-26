# M42: GitHub Actions renders the site and publishes it to Pages

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M41
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** m042-pages-publish

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

- [ ] AC1. `.github/workflows/pages.yml`, run on this milestone's branch,
      concludes `success`, and the Pages artifact it uploads contains every
      `.html` and `.pdf` path that `quarto render site` produces under
      `site/_site/` on the same commit with the toolchain the workflow
      installs. That set holds at least three `.pdf` paths.
- [ ] AC2. The workflow's deploy job is gated on the default branch, and the
      branch run of AC1 reports that job skipped.
- [ ] AC3. The workflow pins Quarto to an exact version string, and that string
      satisfies the `quarto-required` range `_extensions/index/_extension.yml`
      declares, compared by splitting both on `.` and comparing integer tuples.
- [ ] AC4. The workflow concludes `failure` on each member of this family, each
      planted separately on a probe branch: a `site/` source that fails to
      render; a render leaving no `site/_site/index.html`; a render that
      succeeds while dropping a page AC1's containment requires; a Quarto pin
      naming a version that does not exist; and a render whose non-zero exit is
      produced inside a pipeline (the `tee`/errexit shape `check-design.md`
      records at M04).
- [ ] AC5. After `quarto render site`, `git status --porcelain` reports no
      untracked path under `site/`, and `git ls-files` returns none under
      `site/_site/` or `site/.quarto/`.
- [ ] AC6. README.md contains the published site URL, and it is the URL the
      workflow's deploy job publishes to.
- [ ] AC7. `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T2, T5
- AC3 → T2, T4
- AC4 → T5
- AC5 → T3, T4
- AC6 → T6
- AC7 → T4, T5, T6

## Tasks

- [ ] T1. Confirm with the user that Pages source is set to GitHub Actions
      before implementation ends; the deploy leg cannot be exercised otherwise.
- [x] T2. Write `.github/workflows/pages.yml`: pinned Quarto, the LaTeX
      toolchain the render reaches (TinyTeX, which carries `makeindex`),
      render, `upload-pages-artifact`, and a `deploy-pages` job gated on the
      default branch.
- [x] T3. Extend `.gitignore` to cover the render's whole output under `site/`,
      verified against a real render rather than a literal path.
- [x] T4. Write the checks for AC3 and AC5, including the version comparison
      procedure the criterion names.
- [ ] T5. Run the five AC4 plants on probe branches, one substitution each so a
      no-op leaves the log unchanged (`check-design.md`, M29), and record each
      run URL and conclusion.
- [ ] T6. Add the published URL to README and to the site; amend the CI-matrix
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

## Decisions

- 2026-08-26 (T2): the workflow does not use `actions/configure-pages`. The starter workflow GitHub publishes includes it to hand a site generator the base URL it will be served under, and this site makes only relative links, so nothing reads that output. Keeping it would put a step that calls the Pages API — and fails while Pages is not yet enabled on the repository — ahead of the render on every branch, which would make a probe branch's red say nothing about the render it was planted in. The base path the published site is served under enters this repo in one place instead, the `SITE_BASE_PATH` value `tests/run-tests.sh` gives its link check.

## Review
