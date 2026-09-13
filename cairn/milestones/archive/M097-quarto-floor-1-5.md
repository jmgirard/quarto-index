# M097: The extension requires Quarto 1.5

**Status:** done (2026-09-13, PR #97 https://github.com/jmgirard/quarto-index/pull/97)

**Goal:** The extension declares, documents and tests Quarto 1.5 as its
minimum version, so that the Typst back-end (M098) can emit Typst 0.11 code.

**Outcome:** `_extension.yml` declares `quarto-required: ">=1.5.0"`. README,
`site/index.qmd`, `site/tests.qmd` and a CHANGELOG `### Project` entry state
the new minimum, and Quarto 1.4 users stay on 0.4.0. The `versions.yml` floor
leg installs 1.5.52, the oldest non-prerelease 1.5 release, with the dated
query in its header. The suite's M42 range plants, M43 floor plants,
`versioncheck.py legs` calls and two docstrings moved to the new values.
KI110 was re-checked on the 1.5.52 PDF job and stands. KI114 was removed with
the 1.4.549 leg, and the version-matrix candidate row dropped its label.

**Decisions:** D-060 (raise the floor to 1.5 over a Typst pass-through on 1.4).

**Review:** three lenses, eight findings, none at the return floor. Four
fixed at the gate: stale "matrix is a candidate" sentences in `pages.yml` and
DESIGN's contract bullet, a broken `versions.yml` comment line, and two long
lines in `site/tests.qmd` and README. Four rejected: a run before prose-only
commits, a missing plain-suite line, a narrow header query, and a CHANGELOG
install claim. Quarto 1.4.549's install code refutes that last finding. Suite
804 and self-test 1523 green. Nothing graduated or retired.
