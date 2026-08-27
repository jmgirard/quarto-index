<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M43: A version matrix renders the fixtures on the oldest supported Quarto

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** m043-quarto-version-matrix

## Goal

The declared Quarto floor stops being an untested claim: a second workflow
renders four fixtures on the oldest Quarto release that range admits, on the
version the Pages workflow installs, and on Quarto's current release, and
compares the HTML index each one emits.

## Scope

Surface tier: **user-facing** — the floor is a claim README and
`_extensions/index/_extension.yml` make to anyone installing the extension,
and this milestone is what puts a run behind it.

**In:** `.github/workflows/versions.yml`, separate from `pages.yml` so a red
floor render reports itself rather than blocking the site from publishing. A
floor leg pinned to Quarto 1.4.549 and a leg on the version `pages.yml`
installs run on every push; a leg on Quarto's `release` channel runs weekly and
on demand. Each leg renders `examples/html-index.qmd`,
`examples/named-indexes.qmd`, `examples/demo.qmd` and `examples/book/`, and an
extraction command reduces each artifact's index to a comparable form. The HTML
indexes are compared across legs; the PDFs are held to rendering at exit 0 with
a non-empty printed index. Both comparisons are proved able to fail on a probe
branch.

The cross-leg comparison is the same-tree shape D-012 licenses — one tree, two
sides differing only in an injected condition, here the Quarto version — not
the merge-base oracle D-004 refused. No check reads the workflow's own source:
D-011 leaves the workflow's steps to the probe runs, as M42's did.

**Out:** running the full acceptance suite on the floor leg — it pins
`M33_NOENGINE_PRODUCER=LuaTeX`, and Quarto 1.4.549 renders PDF through xelatex,
so the suite cannot be green there as written → candidate row. Comparing PDF
output across legs, which two different TeX engines cannot deliver → the same
row. Changing the declared `>=1.4.0` range, which the plan gate kept → no
milestone; the gate's reasoning is in the work log.

## Acceptance criteria

- [ ] AC1. `.github/workflows/versions.yml` renders `examples/html-index.qmd`,
      `examples/named-indexes.qmd`, `examples/demo.qmd` and `examples/book/` —
      HTML for all four, PDF for `demo.qmd` and `examples/book/` — on Quarto
      1.4.549 and on the version `.github/workflows/pages.yml` installs, on
      every push; and on Quarto's `release` channel on a weekly schedule and on
      `workflow_dispatch`. A run on the milestone branch is green.
- [ ] AC2. For each HTML artifact that run rendered, the index the floor leg
      emits is byte-identical to the index the pinned leg emits, in the
      serialization the extraction command produces, and the comparison step
      names each fixture it compared. It fails when any compared pair differs.
- [ ] AC3. For each PDF artifact that run rendered, every leg's render exits 0
      and the entry list `tests/pdfindex.py` reads from it is non-empty.
- [ ] AC4. Two planted defects, one per compared path, each turn the workflow
      red: a filter change emitting different HTML index content under one
      Quarto version than another fails AC2's comparison, and a filter change
      suppressing the printed index under one Quarto version fails AC3's
      check.
- [ ] AC5. README and the site's Tests page each name the Quarto version the
      floor leg installs.
- [ ] AC6. `tests/run-tests.sh --self-test` exits 0 on the branch.

## Coverage

- AC1 → T2
- AC2 → T1, T2, T3
- AC3 → T1, T2
- AC4 → T4
- AC5 → T5
- AC6 → T1, T5

## Tasks

- [x] T1. An extraction entry point that reads one rendered artifact and prints
      its index in a canonical comparable form — HTML through
      `tests/htmlindex.py`, PDF through `tests/pdfindex.py` — failing loudly
      rather than printing nothing when the artifact carries no index.
- [x] T2. `.github/workflows/versions.yml`: the leg matrix and its triggers,
      TinyTeX for the PDF fixtures, the renders, T1's extraction per artifact,
      and each leg's extractions uploaded as an artifact. Its header comment
      records the floor version, the query that returned it as the oldest
      non-prerelease Quarto release satisfying the declared range, and the date
      that query ran — a dated observation, not a standing claim.
- [x] T3. The comparison job: download the legs' extractions, compare the HTML
      indexes of the non-pinned legs against the pinned leg's, and report which
      fixture and which leg pair differed.
- [x] T4. Prove both checks discriminating on a probe branch, one plant per
      path; record each red run's URL in the Review section and keep the probe
      commits under `refs/probes/`, as M42 did.
- [x] T5. Name the floor version in README and `site/tests.qmd`, written
      against the AC1 run's own output; record the AC1 run URL in the Review
      section; run the suite.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate probes on a scratch install of Quarto 1.4.549 — `v1.4.0` is no release, the oldest non-prerelease release satisfying `>=1.4.0` is `v1.4.549` (GitHub releases API, 2026-08-26); that version renders `html-index.qmd` (HTML), `demo.qmd` (PDF, 32 entries accepted) and the book fixture (HTML) at exit 0 with every warning 1.10.18 emits, and its emitted HTML index block is byte-identical to 1.10.18's.
- 2026-08-26: plan gate chose comparing the HTML index across legs while holding PDFs to rendering with a non-empty index, over comparing extracted PDF entries too, because 1.4.549 renders through xelatex and 1.10.18 through lualatex, and the M30 and M33 lessons put engine and font differences in the text layer; falsified by a PDF extraction shown engine-neutral across those two engines on these fixtures.
- 2026-08-26: plan gate chose a floor leg pinned to 1.4.549 with the declared `>=1.4.0` range left alone, over narrowing the range to `>=1.4.549`, because `>=1.4.0` is the ordinary spelling for the 1.4 line and README's "Quarto 1.4 or later" is true either way; falsified by a user reading the range as naming an installable release.
- 2026-08-26: plan gate chose running the release-channel leg weekly and on demand, over running it on every push, because the floor and pinned legs are exact versions whose red always traces to a commit while a channel leg can go red on an upstream release alone; falsified by an upstream break reaching the default branch before the weekly run finds it.
- 2026-08-26: plan gate chose a bounded four-fixture matrix over running `tests/run-tests.sh` on each leg, because the suite pins `M33_NOENGINE_PRODUCER=LuaTeX` and the floor renders through xelatex, so it cannot be green there as written; falsified by the suite's engine-dependent checks being made version-aware. The suite runs 396 checks in 5m16s locally, so its cost was not the reason.
- 2026-08-26: T1 — `tests/indexdump.py`, `html`/`pdf` modes over one artifact; `htmlindex.section_rows()` gained the `hrefs` flag `row()` already had, so the dump states where each locator points rather than how many there are. Its judging clauses are split from its reads (`html_rows`, `pdf_rows`) so each is reachable by a plant. Suite: four unplanted controls (single index, two declared indexes, a book's cross-page locators, a printed PDF index) and six planted clauses. 668 checks green.
- 2026-08-26: implement gate — the extraction lives in its own `tests/indexdump.py` rather than as modes on the two reader modules; the HTML dump uses the locator-href row form rather than the count form; and the pinned leg's version is read out of `pages.yml` at run time rather than copied into `versions.yml`.
- 2026-08-26: minor amendment — T3's reader is built before T2's workflow, because the workflow's plan job and its comparison job both run it; the task list's order is otherwise unchanged.
- 2026-08-26: T3 — `tests/versioncheck.py`, `compare` (every leg's HTML extraction against the baseline leg's, byte for byte, naming each fixture and each leg pair, reporting the PDF extractions it deliberately leaves uncompared) and `legs` (the matrix JSON the workflow renders on). `tests/pagescheck.py` gained a `version` mode over `read_pin`, split out of `check_pin`, printing the pin to stdout alone. Suite: the comparison run over this run's own extractions, the matrix asserted per event, and nine planted clauses. 682 checks green.
- 2026-08-26: T2 — `.github/workflows/versions.yml`. Three jobs: `plan` (reads the pin out of `pages.yml` and builds the matrix), `render` (per leg: Quarto + TinyTeX, poppler-utils, the four fixtures with each extraction taken immediately after its own render, uploaded as `index-<leg>`), `compare`. `fail-fast: false`, so a red leg does not cancel the others. Header records the floor 1.4.549, the `gh api` query that returned it as the oldest non-prerelease release satisfying `>=1.4.0`, and the date it ran. 682 checks green.
- 2026-08-26: T4 — both compared paths proved discriminating on their own probe branch, one plant each. `m043-htmldiff`: the HTML index term carries `tostring(PANDOC_VERSION)`, and the comparison job reported all four fixtures red, naming the leg pair and the row (`'0\tAlpha [pandoc 3.1.11]…' on the floor leg and '0\tAlpha [pandoc 3.10]…' on the pinned leg`). `m043-nopdfindex`: `\printindex` emitted only under the pinned leg's pandoc, and the floor render leg went red at `FAIL: examples/demo.pdf: no index heading 'Index'` with the render itself at exit 0. Both branches deleted, commits kept under `refs/probes/`.
- 2026-08-26: `m043-htmldiff`'s first attempt was red for an unrelated reason — TinyTeX's `tlmgr` answered "compilation failed- no matching packages" for `imakeidx.sty` on the floor leg, which is the package search and not the plant. Re-running the failed job alone was green on the pinned leg and red at the comparison, which is the plant. The AC1 run had already installed the same package on the same leg, so the failure is intermittent; noted for the review as a candidate rather than worked around here.
- 2026-08-26: T5 — README and `site/tests.qmd` each name Quarto 1.4.549, written against the AC1 run's own output; `tests/versioncheck.py floor` holds both documents against the floor the workflow declares, so the number cannot move there while the documents keep the old one. Six planted clauses, including each document in turn dropping the version while the other keeps it. 690 checks green.
- 2026-08-26: T2 fix — the floor leg went red on two runs out of three at `finding package for imakeidx.sty` → `compilation failed- no matching packages`, which is Quarto 1.4.549's own on-demand TeX installer failing against today's TeX Live repository and not the fixtures. The workflow now installs `imakeidx` with the runner's own TinyTeX before any render, on every leg rather than only the floor one, so the legs still differ in their Quarto version and in nothing else. Supersedes the earlier work-log line calling that failure intermittent.
- 2026-08-26: T2 fix, three rounds, each round's failure read off the run it came from. `tlmgr` is not on the runner's PATH (`quarto install tinytex` puts the tree under `~/.TinyTeX` and Quarto locates it itself), so its bin directory is now found rather than named. The shipped `tlmgr` is older than the repository it talks to and refuses to install until it updates itself. And `mirror.ctan.org`'s redirect handed the two legs different mirrors, the floor leg's stale enough that `tlmgr` refused to run — the repository is now named, TinyTeX's own default, which the legs that worked were already on. Green on the branch head at 33028185399.
- 2026-08-26: criteria audit ran in full mode (user-facing tier). It returned findings on all five drafted criteria: four bound a property of the checking machinery rather than of the deliverable (a recorded run URL, a log's fixture list, a message's wording, a header comment's content), which moved to T2, T4 and T5; AC1 let the workflow name its own fixture set, now named in the criterion; AC4's "oldest release satisfying the range" quantified over every Quarto release ever published, narrowed to the pinned 1.4.549 with the query kept as a dated observation in T2; AC5 promised README and the site agree with a fixture list nothing enumerates, narrowed to the floor version; and the equality comparison's relation to D-004 is now stated in Scope. Two findings went to the gate as questions — PDF comparability across engines, and one plant standing in for a family free in three axes.

## Decisions

## Review

**AC1 run (green), on the milestone branch's head commit b226d6d:**
https://github.com/jmgirard/quarto-index/actions/runs/33028185399 — `plan`,
`render (floor, 1.4.549)`, `render (pinned, 1.10.18)` and `compare` all
success. Four HTML extractions per leg, and both PDF fixtures on both legs:
`examples/demo.pdf: 39 printed entry line(s) under 'Index'` and
`examples/book/_book/Index-Book-Fixture.pdf: 20 printed entry line(s) under
'Index'` on each (AC3). The comparison: `4 comparison(s) over 4 fixture(s) —
book, demo, html-index, named-indexes — against the pinned leg, for each of
floor; every one byte-identical` (AC2). The first green run, on the workflow
before the TeX-install fixes, was
https://github.com/jmgirard/quarto-index/actions/runs/33025680092.

**AC4 probes.** Two branches, one plant per compared path, both deleted and
their commits kept under `refs/probes/` — outside `refs/heads` and `refs/tags`,
so neither is matched by the workflows' bare `on: push`. Fetch with
`git fetch origin 'refs/probes/*:refs/probes/*'`; each ref is an annotated
object naming its plant and its run.

- `m043-htmldiff` b377cd0 — the emitted index term carries
  `tostring(PANDOC_VERSION)`, so the two legs emit different index content.
  Red at the **comparison job**, all four fixtures named:
  https://github.com/jmgirard/quarto-index/actions/runs/33025964684
- `m043-nopdfindex` 8b43042 — `\printindex` is emitted only under the pinned
  leg's pandoc, so the floor leg typesets at exit 0 with no printed index. Red
  at the **floor render leg**, `no index heading 'Index' in examples/demo.pdf`:
  https://github.com/jmgirard/quarto-index/actions/runs/33025975119

Both probes ran on the workflow as it stood before the three TeX-install fixes
above. Those fixes are in the install step and change nothing about either
compared path, so what each probe shows red is what the workflow checks now;
re-running them would exercise the same two checks over the same two plants.
