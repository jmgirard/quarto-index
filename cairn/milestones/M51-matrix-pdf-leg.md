<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M51: The version matrix typesets a PDF again

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Branch/PR:** `m051-matrix-pdf-leg` / https://github.com/jmgirard/quarto-index/pull/51

## Goal

A weekly leg of the version matrix renders the two PDF fixtures on every
Quarto version the matrix plans and fails when either prints no index, so
the LaTeX back-end stops going untypeset on any Quarto but a developer's own
machine.

## Scope

Surface tier: **internal** — the deliverable is CI infrastructure over this
repository's own fixtures, which no consumer of the extension reads.

**In:** `.github/workflows/versions.yml` gains a PDF job carrying the steps
M47 removed at `50899b9` — TinyTeX, `imakeidx` from the repository the file
names, `poppler-utils`, `examples/demo.qmd` and `examples/book/` rendered to
PDF, each artifact extracted through `tests/indexdump.py pdf` — gated on the
`plan` job's output rather than on an event named in the workflow.
`tests/versioncheck.py` gains the one reader that decides, from the event,
whether that job runs. `README.md` and `site/tests.qmd` restate what the
matrix renders. `cairn/DECISIONS.md` records the CI dependency re-add and
the schedule-only path.

**Out:** comparing PDF content or PDF fixture names across legs — that stays
on the version-portability candidate row, promoted on an extraction shown
engine-neutral across lualatex and xelatex. Running the acceptance suite on
the floor leg, and the `M33_NOENGINE_PRODUCER` engine pin that stops it —
same row. Rendering M49's two-index fixture in the matrix — a candidate row
of its own, promoted once the restored leg has run a full schedule cycle
clean. Putting PDF renders on the every-push path — refused here, and the
D-entry this milestone writes is the record of it.

## Acceptance criteria

- [x] AC1: `.github/workflows/versions.yml` carries a job that installs
      TinyTeX and `imakeidx` from a repository the file names, installs
      `poppler-utils`, renders `examples/demo.qmd` and `examples/book/` to
      PDF, and pipes each rendered artifact through `python3
      tests/indexdump.py pdf`; reading the file, that job writes each
      extraction to a path outside the directory named in the render job's
      `upload-artifact` step, and adds no upload of its own.
- [x] AC2: `tests/versioncheck.py` is where the rule deciding whether the
      PDF job runs lives, and it prints its answer for each of `push`,
      `schedule` and `workflow_dispatch`; reading
      `.github/workflows/versions.yml` top to bottom, the PDF job's `if:`
      names no event and gates on the `plan` job's output instead.
- [x] AC3: one `workflow_dispatch` run, cited by URL in the Review section,
      has the PDF job green on every leg that run planned, each leg's log
      carrying `indexdump.py`'s printed-entry-count line with a non-zero
      count for both fixtures.
- [x] AC4: one run of a probe commit kept under `refs/probes/`, cited by
      URL, has the PDF job red at the extraction of a fixture that printed
      no index, with that fixture's own `quarto render` step at exit 0 — so
      the job's green is shown to rest on an index being printed and not on
      the render alone.
- [x] AC5: one push-event run, cited by URL, shows the PDF job skipped and
      the render and compare jobs green.
- [x] AC6: the matrix paragraph in `README.md` and the one in
      `site/tests.qmd` each state that the matrix renders PDF weekly and on
      demand rather than on every push, and that PDF content is not compared
      across legs; and `site/tests.qmd`'s paragraph, which today says the
      matrix renders no PDF, no longer says so.

## Coverage

- AC1 → T2
- AC2 → T1, T2
- AC3 → T5
- AC4 → T6
- AC5 → T5
- AC6 → T4

## Tasks

- [x] T1: Add to `tests/versioncheck.py` the mode that answers, for one
      event name, whether the PDF job runs, beside `legs` and its
      `CHANNEL_EVENTS`; cover `push`, `schedule` and `workflow_dispatch`
      under `--self-test`.
- [x] T2: Restore in `.github/workflows/versions.yml` the steps `50899b9`
      removed, as a job of their own gated on a `plan` output carrying T1's
      answer; write its extractions outside the upload directory, and record
      in the job's header what it checks and what it deliberately does not.
- [x] T3: Append the `cairn/DECISIONS.md` entry recording the CI dependency
      re-add — TinyTeX, `imakeidx` from a named repository, `poppler-utils`
      — and why the job stays off the push path (annotates D-025).
- [x] T4: Rewrite the matrix paragraphs in `README.md` and `site/tests.qmd`.
- [x] T5: Fire a `workflow_dispatch` run and let a push run land; record both
      URLs and the per-leg printed-entry counts.
- [x] T6: Plant a fixture printing no index on a commit under `refs/probes/`,
      run the workflow against it, record the red run, and leave the probe
      ref in place.
- [x] T7: `tests/run-tests.sh --self-test` clean before review — the
      profile's `verify` slot, run per task and again at the review gate; it
      is this milestone's gate procedure and not one of its promises.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: criteria audit ran in reduced mode (internal tier), in a fresh-context [O] reader that authored none of the criteria; returned two findings, both fixed here — AC1's tail asserted a domain-equality consequence past what reading the file enumerates (narrowed to the paths the file writes and the upload it does not add), and AC7 bound the acceptance suite's own self-test, an instrument property (deleted; moved to T7 as the gate procedure, the disposal the instrument rule names). One aside adopted: AC6's no-PDF clause was vacuous for README, which carries no such sentence, so it now names `site/tests.qmd`, which does.
- 2026-08-28: plan gate chose restoring the PDF renders over leaving the matrix HTML-only because M47's objection was to the every-push path rather than to PDF rendering, and nothing but a developer's own machine has typeset a fixture since; falsified by the restored job going red on upstream TeX-mirror state rather than on this repository's output.
- 2026-08-28: plan gate chose the weekly-and-on-demand path over every-push because the two push legs are exact versions whose red traces to a commit while a TeX install's red does not, the trade D-025 already made for the release-channel leg; falsified by a PDF break reaching the default branch and users before the weekly run reports it.
- 2026-08-28: plan gate chose M43's TinyTeX-plus-named-repository install over a published TeX Live setup action because the action is unproven against the 1.4.549 floor leg, which is where M43's install pain was; falsified by the named repository going unreachable or stale enough that the floor leg cannot install `imakeidx`.
- 2026-08-28: implement gate confirmed the CI dependency re-add as planned (TinyTeX, `imakeidx` from `https://tlnet.yihui.org`, `poppler-utils`), chose a `pdf <event>` mode printing `true`/`false` over folding the answer into `legs`, and chose running the PDF job beside the render job rather than after it.
- 2026-08-28: T1 — `tests/versioncheck.py` gains `pdf <event>`, answering from `PDF_EVENTS`, declared apart from `CHANNEL_EVENTS` because the two sets coincide for different reasons; an event outside the workflow's declared three is refused on stderr with stdout empty rather than answered `false`, which would skip the job silently. The suite asserts all three answers on every run and, under `--self-test`, plants `push` into `PDF_EVENTS` to show that assertion able to fail. `tests/run-tests.sh --self-test` clean, 794 checks.
- 2026-08-28: T2 — `.github/workflows/versions.yml` gains a `pdf` job carrying the four steps `50899b9` removed (TinyTeX with the run's token, `imakeidx` from `https://tlnet.yihui.org`, `poppler-utils`, the two renders each followed by its `indexdump.py pdf` extraction), over the same leg matrix, `needs: plan` only, gated on `needs.plan.outputs.pdf == 'true'` and naming no event. Extractions go to `$RUNNER_TEMP/pdf`, outside the `$RUNNER_TEMP/extract` the render job uploads; the job adds no upload. The render job's comment no longer says the matrix renders no PDF. `versioncheck.py fixtures` and `floor` still pass against the rewritten file; `tests/run-tests.sh --self-test` clean, 794 checks.
- 2026-08-28: T3 — D-032 appended, recording the re-add of TinyTeX, `imakeidx` from the named repository and `poppler-utils`, the weekly-and-on-demand path, and the gate living in the reader rather than in an `if:` naming events; annotates D-025.
- 2026-08-28: T4 — README's matrix paragraph and `site/tests.qmd`'s each now say the run also typesets two fixtures to PDF on every version, weekly and on demand rather than on every push, and that no PDF is compared across versions. The tests page's "It renders no PDF" sentence is gone, replaced by two paragraphs — what the PDF leg checks and why it is off the push path, then why no PDF is compared. `tests/run-tests.sh --self-test` clean, 794 checks.
- 2026-08-28: T2 refined (minor amendment): the PDF job's one render-and-extract step is split into a step per command, because AC4 asks for a fixture's own `quarto render` step at exit 0 beside a red extraction, which a single step under `set -e` cannot show — the same break reads there as one red step indistinguishable from a render that never typeset. Render-then-extract-then-render-then-extract order kept for the reason the combined step gave it.
- 2026-08-28: T2 defect found by the first dispatch, not by a local check: the book extraction restored from `50899b9` asks `indexdump.py pdf` for a heading named `Index`, which the book has not printed since M49 gave it two declared titles, so the PDF job was red on all three legs at the book step with the demo step already green. Fixed by naming `Index of Subjects` as the heading and `Index of People` as the stop line, the hand-read the acceptance suite makes at its own book-PDF probe; the second declared index is deliberately not read here (D-031).
- 2026-08-28: T5 — dispatch run https://github.com/jmgirard/quarto-index/actions/runs/33190906035 green on all three legs, each printing `39 printed entry line(s) under 'Index'` for `examples/demo.pdf` and `19 printed entry line(s) under 'Index of Subjects'` for the book. Push run https://github.com/jmgirard/quarto-index/actions/runs/33190654491: `pdf` skipped, both render legs and compare green.
- 2026-08-28: T6 — probe commit `4a7e781`, every `{.index` in `examples/demo.qmd` renamed to a class the filter does not read; run https://github.com/jmgirard/quarto-index/actions/runs/33190963909 has the PDF job red on all three legs with `Render examples/demo.qmd to PDF` at success and `Extract the index printed in examples/demo.pdf` at failure. The commit is parked at `refs/probes/m051-noindex` and its branch deleted. The plant also reddens the HTML render and compare jobs, since a demo carrying no mark has no HTML index either; AC4 is about the PDF job's two steps.
- 2026-08-28: T7 — `tests/run-tests.sh --self-test` clean at the gate, 794 checks; `cairn_validate` all checks passed. One earlier invocation aborted at an unrelated pre-existing check whose read of `quarto list tools` returned no TinyTeX status, a network-dependent column; the tool reports `Up to date` and the re-run is the clean one recorded here.
- 2026-08-28: plan gate chose restoring only the two fixtures `50899b9` removed over adding M49's two-index fixture, because that fixture's second index depends on TeX's restricted shell escape (D-031) and adding it widens the restore into new coverage; falsified by the two-index PDF path breaking on a Quarto version while the restored leg stays green. Deferred to a candidate row, not rejected.

- 2026-08-28: review — every criterion verified with fresh evidence (workflow read, `versioncheck.py pdf` run here, the three cited runs re-read job- and step-wise, both docs paragraphs read); `cairn_validate` all checks passed, suite clean at 794 checks; three fresh-context lenses returned ten findings, none demonstrating a criterion failing.
- 2026-08-28: gate triage — findings 1, 3, 5, 6 and 7 fixed on the branch (two docs sentences, three comment claims, one `find` pipeline), finding 2 filed as a follow-up at hygiene, findings 4, 8, 9 and 10 rejected; suite clean after the fixes at 794 checks.

## Decisions

## Review

Reviewed 2026-08-28 on branch `m051-matrix-pdf-leg`, PR
https://github.com/jmgirard/quarto-index/pull/51. `origin/main` at `85cdf2e`
with no commits the branch lacks, so no merge-in was needed.

### Acceptance-criteria evidence

- AC1 — read `.github/workflows/versions.yml` at HEAD: the `pdf` job installs
  TinyTeX (`quarto-actions/setup@v2`, `tinytex: true`, authenticated with the
  run's token), installs `imakeidx` after `tlmgr option repository
  https://tlnet.yihui.org`, installs `poppler-utils`, renders
  `examples/demo.qmd` and `examples/book/` to PDF, and pipes each rendered
  artifact through `python3 tests/indexdump.py pdf`. Both extractions are
  redirected under `$RUNNER_TEMP/pdf`, outside the `$RUNNER_TEMP/extract` the
  render job's `upload-artifact` step names; `grep -n upload-artifact` over the
  file returns one hit, in the render job.
- AC2 — `python3 tests/versioncheck.py pdf <event>` run here answers `false`
  for `push` and `true` for `schedule` and `workflow_dispatch`; an undeclared
  event (`release`) is refused on stderr at exit 1 with stdout empty. The
  workflow's only `if:` lines are `always()` on `compare` and
  `needs.plan.outputs.pdf == 'true'` on `pdf` — the PDF job's gate names no
  event.
- AC3 — dispatch run
  https://github.com/jmgirard/quarto-index/actions/runs/33190906035, re-read
  here: `pdf` green on all three legs the run planned (floor 1.4.549, pinned
  1.10.18, release). Each leg's log carries `39 printed entry line(s) under
  'Index'` for `examples/demo.pdf` and `19 printed entry line(s) under 'Index
  of Subjects'` for the book.
- AC4 — probe run
  https://github.com/jmgirard/quarto-index/actions/runs/33190963909 on commit
  `4a7e781`, parked at `refs/probes/m051-noindex` (present on origin). Per-step
  conclusions re-read here: on each of the three legs `Render examples/demo.qmd
  to PDF` is `success` and `Extract the index printed in examples/demo.pdf` is
  `failure`, the log line reading `FAIL: examples/demo.pdf: no index heading
  'Index'`.
- AC5 — push run
  https://github.com/jmgirard/quarto-index/actions/runs/33190654491: `pdf`
  skipped, both render legs and `compare` green.
- AC6 — README's matrix paragraph says the run "also typesets two of the
  fixtures to PDF" "Weekly and on demand rather than on every push" and that
  "no PDF is compared across versions". `site/tests.qmd` says the same run
  renders the two fixtures to PDF "Weekly and on demand — not on every push",
  and a paragraph of its own opens "No PDF is compared across legs." Its
  former "It renders no PDF" sentence is gone; `grep -i "no PDF"` over both
  files returns only the two comparison sentences.

### Consistency gate

`cairn_validate.py` exit 0, all checks passed, every advisory OK including
`release window`. The active profile is `generic`, whose `consistency-gate`
slot names no toolchain checks. No `DESIGN.md` principle changed in this diff,
so `cairn_impact.py` was not run. `tests/run-tests.sh --self-test` clean at
the gate, 794 checks.

### Independent review

Three fresh-context lenses, none having authored the work. [S]
prior-review-record reported no prior-review evidence (no `## Review` sections
in the archive touching these files; `gh api .../pulls/comments` empty) and
zero findings. [S] blame-history reported no findings: the restore matches
`50899b9` apart from the deliberate step split and the M49 heading fix, M43's
dead PDF-comparison scaffolding stays gone, and the scope matches what M47's
removal objected to. [O] diff-bug reported ten findings, ranked below with
their dispositions.

### Findings and dispositions

Ranked as the [O] lens ranked them. No finding demonstrates an acceptance
criterion failing, so none returns the milestone (return floor).

1. The TeX-bin discovery step's `FAIL: no TeX Live bin directory` branch is
   largely unreachable: under `set -euo pipefail`, a missing `~/.TinyTeX/bin`
   kills the step at the assignment before the test runs (the branch does
   still fire on a present-but-empty directory), and `find | head -1` can in
   principle redden a working leg on SIGPIPE. Restored verbatim from
   `50899b9`, and the failure is loud either way.
2. `DECLARED_EVENTS` in `tests/versioncheck.py` is a hand-kept copy of the
   workflow's `on:` block that nothing reads the workflow to check; adding a
   trigger would fail the `plan` job and so skip `render` and `compare` too,
   stopping the HTML matrix over a PDF-gating question.
3. `tests/run-tests.sh`'s `M51_PDF_ANSWERS` check counts its own table's rows,
   while its pass line says "each of the $M51PDFN events the version workflow
   declares" — a claim about the workflow the check does not establish.
4. AC2's second clause (the PDF job's `if:` names no event) has no automated
   hold; a later edit naming events there would leave the suite green.
5. The plan step's comment credits its `!= true && != false` test with work
   `set -e` already does — a failing reader kills the step at the capture.
6. README says the run typesets PDF "on each of those versions" after
   enumerating only the floor and pinned legs, but the PDF job takes the same
   three-leg matrix, release leg included. `site/tests.qmd`, which names the
   weekly release leg first, is accurate.
7. `site/tests.qmd` lost a true sentence AC6 did not ask it to lose — that the
   acceptance suite renders and reads a printed PDF index on every run, on one
   Quarto version — which the new job's own header comment leans on.
8. Two of the new job's seven run steps omit `shell: bash` that the other five
   declare; behavior is identical on `ubuntu-latest`.
9. `refs/probes/m051-noindex` is a plain commit ref where `m042-*` and
   `m043-*` are annotated tags. The AC4 evidence is reachable either way.
10. The `pdf` job has no `timeout-minutes`, so a hang at the self-updating
    package manager costs the default six hours per leg. The `render` job has
    none either.

**Triage at the gate (2026-08-28).** The maintainer chose fix-now for findings
1, 3, 5, 6 and 7, a follow-up for 2, and rejection for the rest. Applied on the
branch before approval:

- 1 — the `find` is now `2>/dev/null | head -1 || true`, so a missing or empty
  bin directory both reach the named `FAIL:` line and a closed pipe cannot
  redden a good install; the step's comment says so.
- 3 — the suite's pass line no longer calls its three rows "the events the
  version workflow declares"; it says the table names them and that catching a
  trigger added to the workflow is the reader's refusal of a fourth name.
- 5 — the plan step's comment now credits `set -e` with stopping a refused
  reader and calls the explicit test a belt on top of it.
- 6 — README now says the run "also adds Quarto's current release and typesets
  two of the fixtures to PDF on each version it renders on".
- 7 — `site/tests.qmd` regains the sentence that the acceptance suite renders
  and reads a printed PDF index on every run, on one Quarto version.

Finding 2 is filed as a follow-up at the post-merge hygiene pass. Findings 4,
8, 9 and 10 rejected: 4 is the design D-011 called for and the milestone
planned; 8 is style with identical behavior; 9 leaves the cited evidence
reachable; 10 is pre-existing and consistent with the render job.

`tests/run-tests.sh --self-test` clean after the fixes, 794 checks; the
workflow parses and no line grew past 80 columns.
