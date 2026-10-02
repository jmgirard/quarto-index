# M107: An emptied container renders on Quarto 1.5.52

- **Status:** review
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

- [x] AC1: A `versions.yml` run on the head commit renders
      `examples/marker-shapes.qmd`, unchanged from commit 5a12b2b, to `gfm`,
      `docx`, `epub` and `typst`. Each render exits 0 in the render job on
      the floor leg (Quarto 1.5.52) and on the pinned leg.
- [x] AC2: On Quarto 1.10.18, `tests/run-tests.sh` exits 0.
- [x] AC3: On Quarto 1.10.18, the `gfm`, `typst`, `html` and `latex` outputs
      of `examples/marker-shapes.qmd` at the head commit differ from the
      merge base's only where the filter empties a container. `diff -w` over
      the `gfm` pair and over the `typst` source pair (rendered with
      `keep-typ: true`) prints nothing. Over the `html` pair, its hunks change
      the callout's opening `<div>` line only by removing the class
      `callout-empty-content`, and delete the two lines of the empty `<div>`
      wrapper inside the figure `fig-marker`. Over the `latex` pair, its hunks
      only add lines. The added lines are one `figure` environment that holds
      an empty `\centering{}` group and the caption
      `\caption{\label{fig-marker}A caption, which is not the figure\textquotesingle s body.}`,
      and nothing else.
- [x] AC4: `CHANGELOG.md` gains an entry under its Unreleased heading. The
      entry says that on Quarto 1.5.52, a captioned figure or an untitled
      callout that holds only a placement marker no longer stops a `gfm`,
      `docx`, `epub` or `typst` render. It says that on Quarto 1.5.52 and
      1.10.18, the LaTeX output now keeps such a figure and its caption,
      which it used to drop. It says that in HTML on Quarto 1.10.18, such a
      callout no longer carries Quarto's `callout-empty-content` class, so its
      title bar is drawn as on a titled callout with content.

## Coverage

- AC1 → T1, T3, T6
- AC2 → T3, T4, T6
- AC3 → T2, T3, T6
- AC4 → T4, T5

## Tasks

- [x] T1: Add the four renders to the `versions.yml` render job, one step per
      format. Each later step runs past a red one (`!cancelled()`, the M43
      lesson). Describe the steps in the workflow header. Push the branch
      before any fix and record the red run. The floor leg must fail the
      steps that the planning survey saw crash, and the pinned leg must pass.
- [x] T2: Unpack the Quarto 1.5.52 macOS tarball outside the repo. Probe
      which content an emptied figure and an emptied callout can carry, so
      that 1.5.52 renders all four formats and 1.10.18 writes only
      whitespace. Record each shape tried. If no shape meets AC3, stop and
      amend AC3 through the gate before T3.
- [x] T3: Make `strip_nested_markers` leave the shape that T2 chose. Keep the
      emptied-place reports and their count. Run the suite on 1.10.18, and
      run the AC3 `diff -w` against the merge base's three outputs.
- [x] T4: Add a suite check to the marker-shapes section. It requires the
      LaTeX capture to hold `\caption{\label{fig-marker}...}` inside one
      `\begin{figure}` ... `\end{figure}`. It runs on every Quarto, because it
      reads the extension's output (D-065). Show it red with the fill removed.
- [x] T5: Write the CHANGELOG entry from the red run of T1 and the green run
      of T6.
- [x] T6: Push and record a green `versions.yml` run on the head commit. Both
      legs pass all four renders.

## Work log

- 2026-10-01: created by /milestone-plan. Planning survey under Quarto 1.5.52: the gfm render of `examples/marker-shapes.qmd` crashed. A marker-only captioned figure also crashed typst and docx, and a marker-only callout crashed epub. Quarto 1.10.18 renders all of them. Quarto 1.5.52 crashes on any empty callout in gfm, with or without the extension.
- 2026-10-01: criteria audit, full mode, fresh Opus reader, two rounds. It narrowed the goal and the CHANGELOG claim to the fixture's shapes, pinned the fixture to 5a12b2b, and moved the docs sentence to M108. T2's probe decides whether AC3 is reachable, with a gated amendment if not.
- 2026-10-01: plan gate chose a milestone over /hotfix, because the regression test is a new version-matrix render and the fix needs a choice of what to leave in an emptied container. Falsified by a fix that needs neither.
- 2026-10-01: plan gate chose the version matrix as the regression test's home over a suite check, because only the matrix runs Quarto 1.5.52. Falsified by the suite gaining a floor run in CI.
- 2026-10-01: implement started on branch m107-emptied-container-floor. No question gate: T2's probe settles the one open choice under AC3.
- 2026-10-01: T1 done. Four marker-shapes render steps added to the `versions.yml` render job, its header corrected (the job now writes one PDF, through Typst), and a paragraph added to `site/tests.qmd`. Red-first run 36953456207 on 5d1a0af: the floor leg failed all four steps, each with Quarto's filter failing on missing or empty container content; the pinned leg passed all four.
- 2026-10-01: T2 done. One shape tried: an empty `pandoc.Plain({})` left in any block list the strip empties. With it, marker-shapes renders at exit 0 in gfm, docx, epub, typst, html and latex on Quarto 1.5.52 and on 1.10.18. On 1.10.18 it is not whitespace-only: the HTML callout loses `callout-empty-content`, an empty div inside `fig-marker` goes, and the LaTeX output gains the figure with its caption, which the merge base drops on both Quartos. gfm and the Typst source do not change. AC3 as planned is unreachable.
- 2026-10-01: T2 chose the empty Plain fill over gating it on the Quarto version, because D-060 declines toolchain detection (GP2); and over filling only figures and callouts by their scaffold divs, because KI23 records that structure as private to Quarto. Falsified by a fill that 1.5.52 renders and 1.10.18 writes as whitespace only.
- 2026-10-01: substantive amendment at the mini gate, approved by the user. AC3 now names each hunk the fix makes on 1.10.18, AC4 also states the LaTeX caption and the HTML callout change, a new T4 adds a caption check to the suite, and D-066 allows AC3's diff across commits. Tasks renumbered T4-T6, Coverage with them.
- 2026-10-01: re-audit: AC3 (full) — prose "prints only the callout line" unmeetable, extra added lines in the figure unbounded, typst pair missing, a diff across commits needs an entry under D-004 and D-012; all fixed before the gate.
- 2026-10-01: re-audit: AC4 (full) — callout styling change unstated, PDF claim rested on `.tex` only; fixed before the gate. The new caption check must run on every Quarto under D-065 and must sit in Coverage; fixed.
- 2026-10-01: re-audit: AC3 (full) — second reader: lead sentence named no formats, callout line could change more than the class, the added figure's body was unpinned; all three fixed in the written text.
- 2026-10-01: re-audit: AC4 (full) — second reader: the 1.5.52 LaTeX claim needed its own diff (taken: the 1.5.52 pair also gains only the figure, beside a reordering of the callout box's options between runs), and the callout change is now stated as what a reader sees. D-066 retitled to supersede D-012's clause. The caption check asserts the whole caption inside the figure environment.
- 2026-10-01: T3 done. `strip_nested_markers` leaves one empty Plain in a list it empties. The first suite run then drew the "marker is not empty" report 6 times where M08-AC3 expects 1: a marker nested in a marker had its own list filled first and then read as non-empty. `marker_content` now drops empty Plains before it judges or splices a marker's content, which restored the count. AC3's four `diff -w` pairs on 1.10.18 match the amended criterion, and the four formats render on 1.5.52.
- 2026-10-01: T4 done. M107-AC4 check added after M12-AC5 in `tests/run-tests.sh`. Red on the merge base's LaTeX (0 figure environments hold the caption) and on a plant moving the caption out of its figure environment; green on the head's LaTeX from Quarto 1.10.18 and 1.5.52. T3 and T4 shared one checkpoint, verified by one suite run.
- 2026-10-01: verify: `tests/run-tests.sh` passed, 900 checks, with `/usr/bin/python3` (3.9.6) first on `PATH`. A python.org Python 3.14 installed on this machine at 13:22 the same day now comes first on `PATH` and has no PyYAML, so the suite's tool guard stops under it. The machine's Python setup was left unchanged.
- 2026-10-01: substantive amendment at a second mini gate, approved by the user. AC4's callout sentence read "now draws an empty body under its title bar", which Quarto 1.10.18's bootstrap CSS refutes: the body div is empty with or without the fill, and `callout-empty-content` only sets the title bar's bottom margin to 0 and rounds its lower-right corner. The sentence now says the callout loses that class, so its title bar is drawn as on a titled callout with content. AC4 had two re-audit lines, so no further reader ran.
- 2026-10-01: T5 done. CHANGELOG entry added under Unreleased, Output, worded from T1's red run, T3's diffs and the CSS rule above; T6's green run is still owed.
- 2026-10-01: a second M107-AC4 suite check backs the entry's callout sentence: the marker-only callout carries no `callout-empty-content`. Red on the merge base's 1.10.18 HTML, green on the head's; Quarto 1.5.52 writes the class on neither, so the check discriminates only on a Quarto that writes it. Checkpoint committed with the suite run on it still in flight.
- 2026-10-01: that run passed, 901 checks, both M107-AC4 checks among them (Python 3.9.6 first on `PATH`).
- 2026-10-01: T6 done. Versions run 36955981583 on a35f7b6 green: the floor and pinned legs each passed the gfm, docx, epub and typst renders of marker-shapes, and the HTML comparison passed.
- 2026-10-01: checkpoint during the claim audit. The reader's three corrections are applied to `versions.yml`, `site/tests.qmd`, `tests/run-tests.sh` and `marker.lua`, all comment or docs prose; its re-read of them and the suite run after them are still owed.
- 2026-10-01: claim audit: 24 claims read, 3 corrected — .github/workflows/versions.yml, site/tests.qmd, tests/run-tests.sh, _extensions/index/modules/marker.lua
- 2026-10-01: the reader's re-read found all three corrections hold; its two wrap-width notes were fixed, with one more over-long workflow line.
- 2026-10-01: implement complete. Pre-review check `tests/run-tests.sh --self-test` passed on 1e14279, 1741 checks, Python 3.9.6 first on `PATH`. Status set to review.
- 2026-10-01: review checkpoint. AC1, AC3 and AC4 verified and ticked. The branch was pushed (no PR) so the matrix ran on the head. The AC2 suite run and the three reviewers are still in flight.

## Decisions

## Review

Review run 2026-10-01 on head 52cbe70. The `main` branch did not move
after the branch was cut (merge base 0eaaa8e).

- AC1: pass. `git diff 5a12b2b HEAD -- examples/marker-shapes.qmd` is
  empty. Review pushed the branch (no PR) to run the matrix on the head.
  Versions run 36957701710 on 52cbe70 concluded success. The floor leg
  (1.5.52) and the pinned leg (1.10.18) each passed all four
  marker-shapes render steps: `gfm`, `docx`, `epub` and `typst`.
- AC2: pass. `tests/run-tests.sh` on 52cbe70, Quarto 1.10.18,
  `/usr/bin/python3` first on `PATH`: exit 0, "All checks passed (901
  checks)", no FAIL line. Both M107-AC4 checks are among the passes.

- AC3: pass. `git archive` exported the merge base 0eaaa8e and the head
  52cbe70 to a scratch directory. In each, `examples/marker-shapes.qmd`
  rendered on Quarto 1.10.18 to `gfm`, `html`, `latex` and `typst`
  (`-M keep-typ:true`). All eight renders exit 0. `diff -w` over the `gfm`
  pair and over the `.typ` pair printed nothing. The `html` pair changes one
  line, the callout's opening `<div>`, only by removing the class
  `callout-empty-content`. It also deletes two lines, the `<div>` and
  `</div>` of the empty wrapper inside the `fig-marker` figure. The `latex`
  pair has one hunk of added lines only. They hold one `figure` environment
  with an empty `\centering{ }` group and the pinned caption, then
  `\end{figure}%`. Pandoc wraps the caption after "not the", a whitespace
  break.
- AC4: pass. The branch adds one entry at `CHANGELOG.md:54`. It sits
  under `## Unreleased` (line 3) and `### Output`, above `## 0.4.0`
  (line 68). Its first sentence covers the 1.5.52 figure and callout that
  hold only a marker. These no longer stop a `gfm`, `docx`, `epub` or
  `typst` render. Next, it says the LaTeX output on 1.5.52 and 1.10.18 now
  keeps the figure and its caption. Last, it says the HTML callout on
  1.10.18 loses `callout-empty-content`. So its title bar is drawn as on a
  titled callout with content.
- Consistency gate: pass. `cairn_validate.py` exit 0, every check PASS or
  OK, coverage complete among them. No DESIGN.md principle changed, so
  `cairn_impact.py` did not run. The `generic` profile names no toolchain
  checks.

Independent review: three fresh reviewers (Opus diff-bug, Sonnet blame
history, Sonnet prior reviews). None found a Lua bug or an AC failing.
The PR comment probe returned no threads. Findings, merged across lenses,
most severe first, with the disposition proposed at the gate:

- F1 (Opus): on Quarto 1.10.18 the Word output now keeps the `fig-marker`
  figure and its caption, which the merge base dropped. Review read both
  in the reviewer's docx renders. The CHANGELOG names only LaTeX, and
  AC3 compared no `docx` or `epub` pair. Proposed: follow-up.
- F2 (Opus): no check pins that Word caption. Proposed: follow-up, with F1.
- F3 (Opus): the `marker_content` comment (`marker.lua:103`) says the drop
  makes a list fill once, not once per level. The drop's effect is that an
  outer marker no longer reads as non-empty. Proposed: fix now.
- F4 (Opus): the `run-tests.sh:3653` comment says each outer marker is
  empty at its splice. It now holds the fill, which `marker_content` drops.
  Proposed: fix now.
- F5 (Opus, prior reviews): `site/tests.qmd:29` and the `versions.yml:138`
  comment say the job renders two fixtures to EPUB. It renders three.
  Proposed: fix now.
- F6 (prior reviews): `README.md:27` lists the book and the figure fixture
  as the EPUB renders, not marker-shapes. Proposed: fix now.
- F7 (Opus, blame history): the DESIGN.md strip paragraph (about line 322)
  does not state that an emptied list keeps one empty Plain. Proposed: fix
  now.
- F8 (Opus): the four new steps run after a failed Quarto install, which
  adds red noise. Proposed: reject, the M43 trade-off as designed.
- F9 (Opus): a titled marker-only callout can lose the class too, and the
  entry names only the untitled one. Unrendered. Proposed: reject, the
  entry is not false and titled callouts are out of scope.
- F10 (Opus, blame history): `versions.yml:267` runs to about 88 columns.
  Proposed: fix now, with F5.
- F11 (blame history): the footnote reach of the strip was probed on the
  1.10.18 Pandoc only. Proposed: reject, M108 runs the suite on 1.5.52.
- F12 (blame history): an author-written empty Plain inside a marker is
  dropped with no warning. Proposed: reject, it holds no text.
- F13 (blame history): a workflow comment says the suite reads the fixture
  on one Quarto, and the LaTeX check pins `\textquotesingle`. Proposed:
  reject, both hold, and the check passed on both Quartos (T4).
- F14 (blame history): the header says the suite cannot run green on the
  floor leg. Proposed: reject. Before M108 lands, the sentence is true.
