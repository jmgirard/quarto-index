<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M51: The version matrix typesets a PDF again

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Branch/PR:** —

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

- [ ] AC1: `.github/workflows/versions.yml` carries a job that installs
      TinyTeX and `imakeidx` from a repository the file names, installs
      `poppler-utils`, renders `examples/demo.qmd` and `examples/book/` to
      PDF, and pipes each rendered artifact through `python3
      tests/indexdump.py pdf`; reading the file, that job writes each
      extraction to a path outside the directory named in the render job's
      `upload-artifact` step, and adds no upload of its own.
- [ ] AC2: `tests/versioncheck.py` is where the rule deciding whether the
      PDF job runs lives, and it prints its answer for each of `push`,
      `schedule` and `workflow_dispatch`; reading
      `.github/workflows/versions.yml` top to bottom, the PDF job's `if:`
      names no event and gates on the `plan` job's output instead.
- [ ] AC3: one `workflow_dispatch` run, cited by URL in the Review section,
      has the PDF job green on every leg that run planned, each leg's log
      carrying `indexdump.py`'s printed-entry-count line with a non-zero
      count for both fixtures.
- [ ] AC4: one run of a probe commit kept under `refs/probes/`, cited by
      URL, has the PDF job red at the extraction of a fixture that printed
      no index, with that fixture's own `quarto render` step at exit 0 — so
      the job's green is shown to rest on an index being printed and not on
      the render alone.
- [ ] AC5: one push-event run, cited by URL, shows the PDF job skipped and
      the render and compare jobs green.
- [ ] AC6: the matrix paragraph in `README.md` and the one in
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

- [ ] T1: Add to `tests/versioncheck.py` the mode that answers, for one
      event name, whether the PDF job runs, beside `legs` and its
      `CHANNEL_EVENTS`; cover `push`, `schedule` and `workflow_dispatch`
      under `--self-test`.
- [ ] T2: Restore in `.github/workflows/versions.yml` the steps `50899b9`
      removed, as a job of their own gated on a `plan` output carrying T1's
      answer; write its extractions outside the upload directory, and record
      in the job's header what it checks and what it deliberately does not.
- [ ] T3: Append the `cairn/DECISIONS.md` entry recording the CI dependency
      re-add — TinyTeX, `imakeidx` from a named repository, `poppler-utils`
      — and why the job stays off the push path (annotates D-025).
- [ ] T4: Rewrite the matrix paragraphs in `README.md` and `site/tests.qmd`.
- [ ] T5: Fire a `workflow_dispatch` run and let a push run land; record both
      URLs and the per-leg printed-entry counts.
- [ ] T6: Plant a fixture printing no index on a commit under `refs/probes/`,
      run the workflow against it, record the red run, and leave the probe
      ref in place.
- [ ] T7: `tests/run-tests.sh --self-test` clean before review — the
      profile's `verify` slot, run per task and again at the review gate; it
      is this milestone's gate procedure and not one of its promises.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: criteria audit ran in reduced mode (internal tier), in a fresh-context [O] reader that authored none of the criteria; returned two findings, both fixed here — AC1's tail asserted a domain-equality consequence past what reading the file enumerates (narrowed to the paths the file writes and the upload it does not add), and AC7 bound the acceptance suite's own self-test, an instrument property (deleted; moved to T7 as the gate procedure, the disposal the instrument rule names). One aside adopted: AC6's no-PDF clause was vacuous for README, which carries no such sentence, so it now names `site/tests.qmd`, which does.
- 2026-08-28: plan gate chose restoring the PDF renders over leaving the matrix HTML-only because M47's objection was to the every-push path rather than to PDF rendering, and nothing but a developer's own machine has typeset a fixture since; falsified by the restored job going red on upstream TeX-mirror state rather than on this repository's output.
- 2026-08-28: plan gate chose the weekly-and-on-demand path over every-push because the two push legs are exact versions whose red traces to a commit while a TeX install's red does not, the trade D-025 already made for the release-channel leg; falsified by a PDF break reaching the default branch and users before the weekly run reports it.
- 2026-08-28: plan gate chose M43's TinyTeX-plus-named-repository install over a published TeX Live setup action because the action is unproven against the 1.4.549 floor leg, which is where M43's install pain was; falsified by the named repository going unreachable or stale enough that the floor leg cannot install `imakeidx`.
- 2026-08-28: plan gate chose restoring only the two fixtures `50899b9` removed over adding M49's two-index fixture, because that fixture's second index depends on TeX's restricted shell escape (D-031) and adding it widens the restore into new coverage; falsified by the two-index PDF path breaking on a Quarto version while the restored leg stays green. Deferred to a candidate row, not rejected.

## Decisions

## Review
