# M47: The version matrix compares what it renders

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m047-matrix-compares-html`

## Goal

Cut the version matrix back to the HTML indexes its comparison actually reads,
removing the PDF renders, extractions and TeX install that serve clauses M45
found unreachable.

## Scope

**In:** Surface tier **internal** — the deliverable is this repo's CI matrix over
its own fixture renders; no external consumer of the repo relies on it. Delete
from `.github/workflows/versions.yml` both `--to pdf` renders, both PDF
extractions, `tinytex: true`, the TeX-package step (its hardcoded
`https://tlnet.yihui.org` repository, its `tlmgr update --self`, and the
`find … | head -1` whose loud-failure branch is unreachable under
`set -euo pipefail`) and the poppler step; delete M45's PDF clauses from
`check_compare` in `tests/versioncheck.py`. Delete `site/tests.qmd`'s paragraph
describing the PDF half of the matrix, which M45 wrote to match the clauses this
milestone removes.

**Out:** the version matrix's readers — the `after` id, the duplicated `EXACT`,
the unbound minted identifiers, the local control's fixture set, `m43_dump`
swallowing the reader's `FAIL:` line, and the workflow header's claim about what
reads its source → M48. The site-and-docs disposition → M46. Restoring a PDF leg
on an extraction shown engine-neutral across lualatex and xelatex → the standing
version-portability candidate row. Moving the floor version → not this milestone;
`1.4.549` stands.

## Acceptance criteria

- [ ] AC1: `.github/workflows/versions.yml` contains none of the tokens `tinytex`, `tlmgr`, `poppler`, `--to pdf`, `indexdump.py pdf` — `grep -c` over that one file reports 0 for each.
- [ ] AC2: `grep -ci pdf tests/versioncheck.py` reports 0.
- [ ] AC3: `tests/run-tests.sh` completes at exit 0, and `tests/run-tests.sh --self-test` completes at exit 0.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3

## Tasks

- [x] T1: Delete from `.github/workflows/versions.yml` the "Install the TeX packages the PDF fixtures load" and "Install poppler-utils" steps, `tinytex: true` on the setup action, both `--to pdf` renders and both PDF extractions. State in the render step's comment that the matrix compares HTML indexes and nothing else.
- [ ] T2: Delete M45's PDF clauses from `check_compare` in `tests/versioncheck.py`, and the PDF fixture names they judge across legs.
- [ ] T3: Full run plus `--self-test`; dispatch the Versions workflow and record the run URLs as evidence.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose deleting the PDF half over keeping the PDF renders as render-only coverage, because keeping them keeps a hardcoded third-party TeX repository and a self-updating `tlmgr` on the every-push path for coverage `check_compare` never reads; falsified by a Quarto version breaking the LaTeX back-end and reaching a release with the matrix green.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). Its findings on the original single-milestone draft were an unbounded identifier domain, a disjunct satisfiable by editing a prose comment, helper-plumbing wording, and a green-CI-matrix promise spanning the environment boundary; all four fell to M48 or were fixed there, and the criteria above carry none of them. The CI-matrix promise was dropped from the criteria and is T3 evidence.
- 2026-08-27: T1 — `.github/workflows/versions.yml` renders HTML only: the TeX-package and poppler steps and `tinytex: true` are gone, both `--to pdf` renders and both PDF extractions with them, and the render step's comment now states that the matrix compares HTML indexes and nothing else, why no PDF is rendered, and what restoring a leg would wait on. `grep -c` reports 0 for each of the five tokens; suite green at 386 checks.
- 2026-08-27: Scope amended at the implement gate, adding `site/tests.qmd`'s PDF-matrix paragraph to In: M45 wrote it to match the clauses T2 deletes, no check reads that page since M46 retired the claim-container registry, and neither M46 nor M48 takes it.
- 2026-08-26: `cairn_validate`'s sizing tripwire fired at 8 acceptance criteria on the single-milestone draft; it was split here rather than trimmed, M48 taking the reader repairs.

## Decisions

## Review
