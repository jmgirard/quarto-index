# M107: An emptied container renders on Quarto 1.5.52

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2
- **Resolves:** —
- **Surface tier:** user-facing — a render that stops on a supported Quarto is an author-visible failure
- **Branch/PR:** m107-emptied-container-floor

## Goal

On Quarto 1.5.52, each container shape in `examples/marker-shapes.qmd`
renders to GitHub markdown, Word, EPUB and Typst without its marker.

## Scope

**In:** the content that `strip_nested_markers`
(`_extensions/index/modules/marker.lua:211`) leaves in a container it empties.
Quarto 1.5.52 must render that content. Four renders of
`examples/marker-shapes.qmd` join the `versions.yml` render job on every leg.
A CHANGELOG entry states the fix.

**Out:** a suite that passes on Quarto 1.5.52 → M108. The Typst page's
sentence on Typst books under Quarto 1.5.52 → M108. Container kinds that the
fixture does not list, such as titled callouts or column divs, did not crash
in the survey and get no row until one does. A CI job that runs the whole
suite on the floor Quarto → candidate row.

## Acceptance criteria

- [ ] AC1: A `versions.yml` run on the head commit renders
      `examples/marker-shapes.qmd`, unchanged from commit 5a12b2b, to `gfm`,
      `docx`, `epub` and `typst`. Each render exits 0 in the render job on
      the floor leg (Quarto 1.5.52) and on the pinned leg.
- [ ] AC2: On Quarto 1.10.18, `tests/run-tests.sh` exits 0.
- [ ] AC3: On Quarto 1.10.18, the `gfm`, `html` and `latex` outputs of
      `examples/marker-shapes.qmd` at the head commit differ from the merge
      base's outputs only in whitespace. `diff -w` over each pair prints
      nothing.
- [ ] AC4: `CHANGELOG.md` gains an entry under its Unreleased heading. The
      entry says that on Quarto 1.5.52, a captioned figure or an untitled
      callout that holds only a placement marker no longer stops a `gfm`,
      `docx`, `epub` or `typst` render.

## Coverage

- AC1 → T1, T3, T5
- AC2 → T3, T5
- AC3 → T2, T3, T5
- AC4 → T4

## Tasks

- [x] T1: Add the four renders to the `versions.yml` render job, one step per
      format. Each later step runs past a red one (`!cancelled()`, the M43
      lesson). Describe the steps in the workflow header. Push the branch
      before any fix and record the red run. The floor leg must fail the
      steps that the planning survey saw crash, and the pinned leg must pass.
- [ ] T2: Unpack the Quarto 1.5.52 macOS tarball outside the repo. Probe
      which content an emptied figure and an emptied callout can carry, so
      that 1.5.52 renders all four formats and 1.10.18 writes only
      whitespace. Record each shape tried. If no shape meets AC3, stop and
      amend AC3 through the gate before T3.
- [ ] T3: Make `strip_nested_markers` leave the shape that T2 chose. Keep the
      emptied-place reports and their count. Run the suite on 1.10.18, and
      run the AC3 `diff -w` against the merge base's three outputs.
- [ ] T4: Write the CHANGELOG entry from the red run of T1 and the green run
      of T5.
- [ ] T5: Push and record a green `versions.yml` run on the head commit. Both
      legs pass all four renders.

## Work log

- 2026-10-01: created by /milestone-plan. Planning survey under Quarto 1.5.52: the gfm render of `examples/marker-shapes.qmd` crashed. A marker-only captioned figure also crashed typst and docx, and a marker-only callout crashed epub. Quarto 1.10.18 renders all of them. Quarto 1.5.52 crashes on any empty callout in gfm, with or without the extension.
- 2026-10-01: criteria audit, full mode, fresh Opus reader, two rounds. It narrowed the goal and the CHANGELOG claim to the fixture's shapes, pinned the fixture to 5a12b2b, and moved the docs sentence to M108. T2's probe decides whether AC3 is reachable, with a gated amendment if not.
- 2026-10-01: plan gate chose a milestone over /hotfix, because the regression test is a new version-matrix render and the fix needs a choice of what to leave in an emptied container. Falsified by a fix that needs neither.
- 2026-10-01: plan gate chose the version matrix as the regression test's home over a suite check, because only the matrix runs Quarto 1.5.52. Falsified by the suite gaining a floor run in CI.
- 2026-10-01: implement started on branch m107-emptied-container-floor. No question gate: T2's probe settles the one open choice under AC3.
- 2026-10-01: T1 done. Four marker-shapes render steps added to the `versions.yml` render job, its header corrected (the job now writes one PDF, through Typst), and a paragraph added to `site/tests.qmd`. Red-first run 36953456207 on 5d1a0af: the floor leg failed all four steps, each with Quarto's filter failing on missing or empty container content; the pinned leg passed all four.

## Decisions

## Review
