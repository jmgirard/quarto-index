# M53: The workflows' actions come up to date

**Status:** done (2026-08-28, PR #53 https://github.com/jmgirard/quarto-index/pull/53)

**Goal:** the five GitHub Actions the two workflows pin move to their current major tags, so the deprecation warnings stop and neither workflow is left on a runtime the runner images are retiring.

**Outcome:** twelve `uses:` references across `.github/workflows/pages.yml` and
`.github/workflows/versions.yml` now read `actions/checkout@v7` x5,
`quarto-dev/quarto-actions/setup@v2` x3, `actions/upload-artifact@v7`,
`actions/download-artifact@v8`, `actions/upload-pages-artifact@v5` and
`actions/deploy-pages@v5`. The evidence is the runs the branch's own pushes
triggered, not a scan of the YAML: `versions.yml` green on `plan`, both render
legs and `compare`, whose per-leg counts (book 26, demo 55, html-index 21,
named-indexes 41) match the last pre-bump default-branch run's, which is what
holds the upload/download round trip across the two majors; and `pages.yml`
green through the v5 upload, its artifact's 70 relative paths identical to the
pre-bump `@v3` artifact's raw and to a local render's once the one
content-hashed bootstrap basename is normalized. `actions/deploy-pages@v5`
ships unexercised — the `github-pages` environment refuses a deployment from a
non-default branch — and was verified on the first default-branch run after the
merge (33214384451, at `2b2d460`), whose `build` and `deploy` jobs both succeeded.

**Decisions:** D-033 (the re-pin under D-024's major-tag rule).

**Review:** four criteria met with fresh evidence, consistency gate clean. Of three fresh-context lenses only diff-bug returned findings, three, none failing a criterion: `download-artifact@v5` and later flatten a single matched artifact, so the comparison's one-surviving-leg message now says no leg arrived (filed, with the records' omission of it, onto the version-matrix-readers row); a coverage-map gap was rejected.
