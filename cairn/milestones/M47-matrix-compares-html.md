# M47: The version matrix compares what it renders

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m047-matrix-compares-html` / https://github.com/jmgirard/quarto-index/pull/47

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

- [x] AC1: `.github/workflows/versions.yml` contains none of the tokens `tinytex`, `tlmgr`, `poppler`, `--to pdf`, `indexdump.py pdf` — `grep -c` over that one file reports 0 for each.
- [x] AC2: `grep -ci pdf tests/versioncheck.py` reports 0.
- [x] AC3: `tests/run-tests.sh` completes at exit 0, and `tests/run-tests.sh --self-test` completes at exit 0.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3

## Tasks

- [x] T1: Delete from `.github/workflows/versions.yml` the "Install the TeX packages the PDF fixtures load" and "Install poppler-utils" steps, `tinytex: true` on the setup action, both `--to pdf` renders and both PDF extractions. State in the render step's comment that the matrix compares HTML indexes and nothing else.
- [x] T2: Delete M45's PDF clauses from `check_compare` in `tests/versioncheck.py`, and the PDF fixture names they judge across legs.
- [x] T3: Full run plus `--self-test`; dispatch the Versions workflow and record the run URLs as evidence.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose deleting the PDF half over keeping the PDF renders as render-only coverage, because keeping them keeps a hardcoded third-party TeX repository and a self-updating `tlmgr` on the every-push path for coverage `check_compare` never reads; falsified by a Quarto version breaking the LaTeX back-end and reaching a release with the matrix green.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). Its findings on the original single-milestone draft were an unbounded identifier domain, a disjunct satisfiable by editing a prose comment, helper-plumbing wording, and a green-CI-matrix promise spanning the environment boundary; all four fell to M48 or were fixed there, and the criteria above carry none of them. The CI-matrix promise was dropped from the criteria and is T3 evidence.
- 2026-08-27: T3 — `tests/run-tests.sh` exits 0 at 386 checks and `tests/run-tests.sh --self-test` exits 0 at 692 (from 698: the M45 T4 block's four planted cases and two report reads). Both Versions legs ran green on the branch: the push run https://github.com/jmgirard/quarto-index/actions/runs/33111434714 (floor 1.4.549, pinned 1.10.18) and the manually dispatched run https://github.com/jmgirard/quarto-index/actions/runs/33111464900, which adds the release-channel leg. The dispatched run's compare job reports 8 comparisons over 4 fixtures against the pinned leg, all byte-identical. Render jobs now take 22-33s each, TeX install gone.
- 2026-08-27: T2 — `check_compare` compares HTML extractions and nothing else: M45's PDF clauses, `PDF_SUFFIX`, the PDF domain-size line and the PDF name-set `ok` line are gone, and `grep -ci pdf tests/versioncheck.py` reports 0. The suite drops the `demo.pdf` extraction from its local control tree, the two report greps that read the PDF lines, and the whole M45 T4 self-test block. Two prose sites the deletion made false were corrected in the same pass: `site/tests.qmd`'s PDF paragraph (the gated Scope addition) and the M43 T1 block's claim that its PDF control is an artifact shape the matrix renders — that control stays, being what `indexdump.py`'s pdf-mode plants are judged against. Suite green at 386 checks.
- 2026-08-27: T1 — `.github/workflows/versions.yml` renders HTML only: the TeX-package and poppler steps and `tinytex: true` are gone, both `--to pdf` renders and both PDF extractions with them, and the render step's comment now states that the matrix compares HTML indexes and nothing else, why no PDF is rendered, and what restoring a leg would wait on. `grep -c` reports 0 for each of the five tokens; suite green at 386 checks.
- 2026-08-27: Scope amended at the implement gate, adding `site/tests.qmd`'s PDF-matrix paragraph to In: M45 wrote it to match the clauses T2 deletes, no check reads that page since M46 retired the claim-container registry, and neither M46 nor M48 takes it.
- 2026-08-26: `cairn_validate`'s sizing tripwire fired at 8 acceptance criteria on the single-milestone draft; it was split here rather than trimmed, M48 taking the reader repairs.

- 2026-08-27: review — AC1, AC2 and AC3 verified with fresh evidence; consistency gate clean; three fresh-context reviewers, nine findings, all from the diff-bug lens, none meeting the return floor.

- 2026-08-27: gate directed fixing seven findings on the branch; F1-F6 and F8 fixed, F9 rejected, F7 routed to the version-portability candidate row at hygiene. Criteria re-verified after the fixes: AC1 and AC2 counts still 0, both suite legs green at 386 and 692.

## Decisions

## Review

Reviewed 2026-08-27 on branch `m047-matrix-compares-html`, PR
https://github.com/jmgirard/quarto-index/pull/47. Diff against `main`: 6 files,
+50 / -242.

### Acceptance-criteria evidence

- AC1 — met. `grep -cF` over `.github/workflows/versions.yml` alone reports 0
  for each of the five tokens: `tinytex` 0, `tlmgr` 0, `poppler` 0, `--to pdf` 0,
  `indexdump.py pdf` 0.
- AC2 — met. `grep -ci pdf tests/versioncheck.py` reports 0.
- AC3 — met. `tests/run-tests.sh` exits 0 at 386 checks; `tests/run-tests.sh
  --self-test` exits 0 at 692. Both run fresh on this branch at review, run
  sequentially per the `verify` slot's note.

### Consistency gate

`cairn_validate.py` exits 0, all 16 checks PASS and all 7 advisories OK,
including `coverage complete` and `binding criteria`. No principle changed, so
`cairn_impact.py` was not run. The `generic` profile's `consistency-gate` slot
names no toolchain checks, so that half is a no-op. CI on PR #47 is green:
build, plan, both render legs (floor 1.4.549 at 22s, pinned 1.10.18 at 28s) and
compare.

### Independent review

Three fresh-context reviewers, distinct evidence bases, none having seen the
implementation. The blame-history lens reported no findings: every deleted line
traces to M43 (kept where declared) or M45 (fully retired), and the M43 review
gate's own `if: always()` and `fail-fast: false` guards survive untouched. The
prior-review lens reported no findings and no prior-review evidence on the
touched files; its `gh api .../pulls/comments` probe returned `[]`, so no
per-PR walk was made. The diff-bug lens reported nine, ranked below with the
disposition each was given.

### Findings and disposition

Ranked as the diff-bug reviewer ranked them. Verified against the
implementation, not against the report.

- **F1 — the red-run domain-size assertion went with the deleted block.**
  `tests/versioncheck.py`'s surviving comment promises the domain line prints
  "whatever the verdict is", and its header promises every clause reports the
  size of what it swept. The only assertion reading that line off a FAILING run
  was the M45 T4 `bothbroken` case, deleted here; what remains
  (`tests/run-tests.sh:15349`) greps it out of the green control alone.
  Confirmed: moving the print into the success branch leaves both suite legs
  green. Coverage lost by deletion.
- **F2 — a retained rule whose reason was deleted.** The render step's "Each
  render is followed immediately by its extraction, before the next render can
  overwrite the artifact" kept its rule and lost its justifying clause (the
  book rendering HTML and PDF into one `_book` directory). Confirmed: the four
  surviving renders write four distinct paths, so nothing can overwrite
  anything.
- **F3 — a causal clause that credits a deleted render.** The same comment says
  the name comparison "bought no coverage the render itself did not already
  have"; that render is gone as of this commit. The paragraph opens by saying
  no PDF is rendered, so the state is recoverable, but the clause reads as
  though the render's coverage still stands.
- **F4 — `site/tests.qmd` gives the wrong reason.** The published sentence
  explains the missing PDF by the engine argument, which is a reason not to
  COMPARE PDF content; the render was dropped for the TeX-install cost on the
  every-push path, which is what the plan gate decided. No check reads this
  page for this content since M46, so nothing would catch the drift.
- **F5 — `tests/indexdump.py`'s header was not corrected.** It still frames
  both modes as the version matrix's serialization; after this milestone the
  matrix never invokes `pdf` mode and `tests/run-tests.sh` is its only caller.
  Two other prose sites were corrected in this pass and this third was missed.
- **F6 — a dead redirect and a claim true only under `--self-test`.**
  `$WORK/m43-demo-pdf.txt` is written at `tests/run-tests.sh:15029` and read
  nowhere now that the legs-tree loop dropped it. The `m43_dump pdf` call
  itself is still load-bearing. The new pass message justifies the fourth
  control as what "the `pdf` mode's own planted clauses below are judged
  against", and those clauses sit inside the `--self-test` block, so the stated
  reason does not hold on a plain run.
- **F7 — the residual risk is recorded for the comparison, not the render.**
  The standing version-portability candidate row still reads "M43 compares HTML
  indexes only"; after this milestone no Quarto version other than a local
  developer's is asked to typeset the fixtures at all.
- **F8 — a cross-file claim the module cannot check.** `versioncheck.py`'s
  header now asserts "HTML is the whole of what the matrix renders", a fact
  about `versions.yml`, which the module never opens (correctly, per D-011).
- **F9 — `dumps_in`'s `suffix` parameter now has a one-value domain.** The
  reviewer noted it as residue and said it is fine to leave.

Return floor: none of the nine demonstrates an acceptance criterion failing,
and none is a defect in what the extension does for its users — F1 is test
coverage, the rest are prose accuracy. Status stayed `review`.

**Disposition, decided by the maintainer at the gate: fix F1-F6 and F8 on the
branch, reject F9, route F7 to the standing candidate row at hygiene.**

- F1 fixed. The `differ` self-test case now greps its own red report for the
  `comparison(s) over 3 fixture(s)` line. Shown able to fail before being
  trusted: against a scratch copy of `versioncheck.py` whose domain `print` was
  moved into the success branch, the red run states no domain size and the grep
  fires; against the real reader on the same planted legs tree the line is
  present and it passes. It rides the case's existing `ok` line, so the check
  count is unchanged.
- F2 and F3 fixed. The workflow comment now says the render M45's name
  comparison leaned on is what M47 removed and that no leg has typeset a
  fixture since, and states why the render/extract interleaving is kept with
  one format — a second format would render into a path an earlier one already
  wrote, the book into `_book` whatever the format.
- F4 fixed. `site/tests.qmd` now gives the install cost as the reason the
  matrix renders no PDF, keeps the engine argument as the reason the comparison
  that install would serve cannot be had, and says the acceptance suite still
  reads a printed PDF index on one Quarto version.
- F5 fixed. `tests/indexdump.py`'s header says the matrix calls `html` only and
  that `pdf` is the acceptance suite's caller.
- F6 fixed. The PDF control's serialization goes to `/dev/null`, and both the
  block comment and the pass message state what the control asserts on a plain
  run rather than crediting clauses that run only under `--self-test`.
- F8 fixed. `versioncheck.py`'s header claims only what the module does — that
  `*.html.txt` is the whole of what it compares — and leaves what the matrix
  renders to the workflow.
- F7 routed, not fixed here: the standing version-portability candidate row is
  extended at post-merge hygiene to record that no Quarto version but a local
  developer's now typesets the fixtures.
- F9 rejected: a parameter whose domain narrowed to one value is residue, not a
  defect, and the reviewer said as much.

Re-verified after the fixes: AC1's five `grep -cF` counts are still 0, AC2 is
still 0, and both suite legs are green again at 386 and 692 checks, exit 0.

