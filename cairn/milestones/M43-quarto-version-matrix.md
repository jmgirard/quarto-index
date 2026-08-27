<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M43: A version matrix renders the fixtures on the oldest supported Quarto

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** m043-quarto-version-matrix / https://github.com/jmgirard/quarto-index/pull/43

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

- [x] AC1. `.github/workflows/versions.yml` renders `examples/html-index.qmd`,
      `examples/named-indexes.qmd`, `examples/demo.qmd` and `examples/book/` —
      HTML for all four, PDF for `demo.qmd` and `examples/book/` — on Quarto
      1.4.549 and on the version `.github/workflows/pages.yml` installs, on
      every push; and on Quarto's `release` channel on a weekly schedule and on
      `workflow_dispatch`. A run on the milestone branch is green.
- [x] AC2. For each HTML artifact that run rendered, the index the floor leg
      emits is byte-identical to the index the pinned leg emits, in the
      serialization the extraction command produces, and the comparison step
      names each fixture it compared. It fails when any compared pair differs.
- [x] AC3. For each PDF artifact that run rendered, every leg's render exits 0
      and the entry list `tests/pdfindex.py` reads from it is non-empty.
- [x] AC4. Two planted defects, one per compared path, each turn the workflow
      red: a filter change emitting different HTML index content under one
      Quarto version than another fails AC2's comparison, and a filter change
      suppressing the printed index under one Quarto version fails AC3's
      check.
- [x] AC5. README and the site's Tests page each name the Quarto version the
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
- 2026-08-26: review checkpoint (in progress) — PR #43 opened as a draft; AC1-AC5 verified with fresh evidence off run 33028991449 on the branch head and ticked; consistency gate green (`cairn_validate` all checks passed, `generic` profile names no toolchain checks, no DESIGN principle changed). AC6's suite run and the three-lens fresh-context review are still outstanding.

## Decisions

## Review

Reviewed 2026-08-26 against branch head `472dede`.
PR: https://github.com/jmgirard/quarto-index/pull/43

### Acceptance criteria

**AC1 — legs, fixtures, triggers, and a green run on the branch.** Fresh run
on the branch head `472dede`:
https://github.com/jmgirard/quarto-index/actions/runs/33028991449 — `plan`,
`render (floor, 1.4.549)`, `render (pinned, 1.10.18)` and `compare` all
success. Each render leg wrote six extractions from the four fixtures: HTML
for `html-index` (21 rows), `named-indexes` (18), `demo` (55) and the book
(26), and PDF for `demo` (39) and the book (20). `versions.yml` carries
`on: push`, `schedule: '37 6 * * 1'` and `workflow_dispatch`; the leg set per
event, run here against the code the `plan` job calls
(`tests/versioncheck.py legs 1.4.549 1.10.18 <event>`), is floor+pinned on
`push` and `pull_request`, and floor+pinned+release on `schedule` and on
`workflow_dispatch`. The first green run, on the workflow before the
TeX-install fixes, was
https://github.com/jmgirard/quarto-index/actions/runs/33025680092.

The release-channel leg had no run behind it when review opened — every
recorded run was a push, and a push renders two legs. Dispatched here on the
branch, `workflow_dispatch` run
https://github.com/jmgirard/quarto-index/actions/runs/33030424324 rendered
three legs (`rendering on: [{"name": "floor", "version": "1.4.549"},
{"name": "pinned", "version": "1.10.18"}, {"name": "release", "version":
"release"}]`), all four jobs success, both PDFs carrying their index on all
three legs, and the comparison `ok   M43-AC2: 8 comparison(s) over 4
fixture(s) — book, demo, html-index, named-indexes — against the `pinned`
leg, for each of floor, release; every one byte-identical`. The `workflow_dispatch`
half of AC1 and the channel leg's own installation path are executed
evidence, not a unit check over `legs`.

**AC2 — the HTML indexes agree across legs, fixture by fixture.** The
`compare` job of that run, verbatim:

- `ok   M43-AC2: book — the \`floor\` leg emits the index the \`pinned\` leg emits, byte for byte (26 row(s))`
- `ok   M43-AC2: demo — … (55 row(s))`
- `ok   M43-AC2: html-index — … (21 row(s))`
- `ok   M43-AC2: named-indexes — … (18 row(s))`
- `ok   M43-AC2: 4 comparison(s) over 4 fixture(s) — book, demo, html-index, named-indexes — against the \`pinned\` leg, for each of floor; every one byte-identical`

It also reports the two PDF extractions it deliberately leaves uncompared, so
the swept domain is stated rather than assumed. That it fails on a difference
is AC4's first probe.

**AC3 — every leg's PDF renders at exit 0 with a non-empty printed index.**
Same run, both legs: `indexdump: examples/demo.pdf: 39 printed entry line(s)
under 'Index'` and `indexdump:
examples/book/_book/Index-Book-Fixture.pdf: 20 printed entry line(s) under
'Index'` on the floor leg and on the pinned leg alike. A render that exits
non-zero fails the step before the extraction runs (`set -euo pipefail`).

**AC4 — both compared paths shown red on a plant.** Two probe branches, one
plant each, both deleted; their commits are kept under `refs/probes/` on
`origin` and locally (`refs/probes/m043-htmldiff` → `b377cd0`,
`refs/probes/m043-nopdfindex` → `8b43042`, each an annotated object naming
its plant and its run). Those refs are outside `refs/heads` and `refs/tags`,
so neither is matched by the workflows' bare `on: push`. Fetch with
`git fetch origin 'refs/probes/*:refs/probes/*'`.

- `m043-htmldiff` `b377cd0` — the emitted index term carries
  `tostring(PANDOC_VERSION)`, so the two legs emit different index content.
  Both render legs stayed green and the **comparison job** went red, naming
  all four fixtures and the differing row —
  `FAIL: M43-AC2: html-index — the \`floor\` leg emits a different index from
  the \`pinned\` leg: row 3 is '0\tA [pandoc 3.1.11]\t' on the \`floor\` leg and
  '0\tA [pandoc 3.10]\t' on the \`pinned\` leg`:
  https://github.com/jmgirard/quarto-index/actions/runs/33025964684
- `m043-nopdfindex` `8b43042` — `\printindex` is emitted only under the pinned
  leg's pandoc, so the floor leg typesets a PDF with no printed index. The
  pinned leg stayed green; the **floor render leg** went red at
  `FAIL: examples/demo.pdf: no index heading 'Index' in examples/demo.pdf`,
  with `Output created: demo.pdf` in the same log — the render itself
  succeeded and the extraction is what failed:
  https://github.com/jmgirard/quarto-index/actions/runs/33025975119

Both probes ran on the workflow as it stood before the three TeX-install
fixes. Those fixes are confined to the `tlmgr`/`imakeidx` install step and
change neither compared path; the fixes are what made the install reliable,
not what either plant exercises.

**AC5 — the floor version named in README and on the site's Tests page.**
`README.md:29` and `site/tests.qmd:22` each name Quarto 1.4.549, and
`tests/versioncheck.py floor` holds both against the floor `versions.yml`
declares — run fresh here, exit 0:
`ok   M43-AC5: .github/workflows/versions.yml pins the floor leg to Quarto
1.4.549, and each of the 2 document(s) named after it says so (README.md,
site/tests.qmd)`.

### Consistency gate

`cairn_validate.py` — all 16 checks PASS, all 7 advisories OK (including
`release window`, which did not fire). The active profile is `generic`, whose
`consistency-gate` slot names no toolchain checks. No `DESIGN.md` principle
changed on the branch, so no Sync Impact Report was owed.

### Independent review

Three fresh-context reviewers, none having seen the implementation, each on a
distinct evidence base.

- **[S] blame-history** — no conflicts with recorded decisions, lessons, or
  past-milestone intent. It confirmed `section_rows`'s new `hrefs` flag
  defaults to the count form every pre-existing caller reads, that
  `pagescheck.py`'s `read_pin`/`check_pin` split reproduces all three original
  failure messages verbatim, and that `versioncheck compare` sits inside
  D-012's licence rather than D-004's refusal. One finding, ranked low, is
  **S1** below.
- **[S] prior-review** — the `gh api .../pulls/comments` probe returned `[]`,
  so no PR-thread walk was owed; against the archived `## Review` sections for
  M40 and M42 it found no reintroduction or contradiction. Each of M42's
  recorded workflow findings is either not applicable or correctly applied
  here.
- **[O] diff-bug** — fifteen findings, **O1**-**O15** below, ranked by the
  reviewer.

### Findings

Verified against the implementation, not against the reviewer's account of it.
O1, O2, O4 and O13 were reproduced by execution; O3 was answered by dispatching
the run recorded under AC1.

- **O1. `tests/indexdump.py:61-75` — a dump with an index section but no entry
  rows passes, so two empty indexes compare equal.** `html_rows` only refuses
  `not rows`; a lone `section\tqi-index\th2\tIndex\t-` row is non-empty, and
  `check_compare`'s only emptiness guard is `os.path.getsize(path) == 0`, which
  a one-line file passes. **Reproduced:** `html_rows(['section\tqi-index\th2\t
  Index\t-'], 'x.html')` returns, printing `1 index section(s), 0 entry/heading
  row(s)`. The module's own header says agreeing about nothing "is the one
  answer this command must not be able to give"; `run-tests.sh` asserts the
  entry-row clause, but only over local captures on the pinned toolchain.
- **O2. `tests/versioncheck.py:155-160` — the PDF domain is allowed to be
  empty and only printed, never failed.** Every other domain in the file
  (`legs`, `others`, `want`) has a clause; `pdfs` has none. Delete the two
  `--to pdf` blocks from `versions.yml` and AC3 has no enforcement left
  anywhere. **Reproduced:** `check_compare` over a legs tree with HTML
  extractions only returns 0, printing `0 PDF extraction(s) were uploaded and
  are not compared across legs (none)`.
- **O3. AC1's release-channel leg has no run behind it.** Every recorded run
  was a push, and a push renders two legs, so the channel string, the leg's
  TinyTeX path and its participation in the comparison had never executed.
  **Answered by evidence:** the `workflow_dispatch` run recorded under AC1
  above renders three legs green, all eight comparisons byte-identical.
- **O4. `.github/workflows/versions.yml:200` — `compare` has no `if:
  always()`, so one red leg suppresses the comparison entirely.** `needs:
  [plan, render]` default-gates on success, so `fail-fast: false` lets the
  other legs finish and upload while the job that reports the verdict never
  runs. **Reproduced in the record:** probe run 33025975119 shows `compare ::
  skipped` with the pinned leg green.
- **O5. `tests/htmlindex.py` `section_rows` — the compared serialization
  includes `after`, a field derived from Quarto's own DOM.** The section row's
  fifth field is `preceding_authored_id()`, the last id on the page this
  extension did not mint, so a future Quarto adding or renaming a wrapper id
  ahead of the index section on one leg turns the matrix red about Quarto
  rather than about this extension.
- **O6. `tests/indexdump.py:51-53` — a third, unpinned copy of the filter's
  HTML constants, and only one of the three fails loudly when wrong.** The
  workflow sets none of `HTML_SECTION_ID`, `HTML_ANCHOR_PREFIX`,
  `HTML_ENTRY_PREFIX`. The header's "loud failure" claim holds for
  `SECTION_ID` alone; a renamed anchor prefix would silently change what the
  `after` field means on every leg while the dump still compares equal.
- **O7. `.github/workflows/versions.yml:121-137` — a hardcoded third-party TeX
  repository and a self-updating `tlmgr` on the every-push path, with no
  decision entry.** D-024 weighed exactly this question for CI dependencies
  and its consequence says a future workflow follows the same split unless it
  records a reason not to; nothing records this one.
- **O8. `versions.yml:34-38` vs. `tests/versioncheck.py` `check_floor` — the
  header's "Nothing checks this workflow's own steps" and Scope's "No check
  reads the workflow's own source" are not literally true.** `check_floor`
  compiles `^\s+FLOOR:` and reads it out of `versions.yml`, so moving the
  floor into a workflow-level `env:` would turn the suite red on a
  behavior-preserving edit.
- **O9. `versions.yml:121-127` — the advertised "loud failure, never a
  silently skipped install" branch is mostly unreachable, and the pipeline can
  flake.** Under `set -euo pipefail` a missing `~/.TinyTeX/bin` kills the step
  at the command substitution before `if [ -z "$TLBIN" ]` is evaluated; and
  `find … | head -1` can hand `find` SIGPIPE if more than one platform
  directory exists, which `pipefail` turns into a step failure.
- **O10. `tests/run-tests.sh` `m43_dump` — `2>/dev/null` discards the reader's
  own diagnostic on the path where it matters.** When a control goes red,
  `indexdump.py`'s `FAIL:` line naming which clause fired has already been
  thrown away. Every neighbouring block in the file `cat`s its log to stderr
  before failing.
- **O11. `README.md:28-29` — a standing claim where the workflow deliberately
  keeps a dated observation.** README says 1.4.549 is "the oldest release of
  that line" flatly; the workflow header is careful that this is a dated
  observation.
- **O12. `tests/versioncheck.py` `check_floor` — the document test is a bare
  substring match, and the files are opened without closing.** `version not in
  body` passes on any occurrence anywhere in the document, including inside an
  unrelated code block, and would pass on `11.4.549`; `open(...).read()` leaks
  handles where `check_compare` uses `with`.
- **O13. `tests/versioncheck.py` `fail()` prints to stdout, and `legs`'s
  stdout is captured.** `pagescheck.check_version` was deliberately changed in
  this same diff to print its diagnostic to stderr for exactly this reason,
  with a planted clause asserting it. **Reproduced:** `LEGS=$(python3
  tests/versioncheck.py legs 1.4.549 1.4.549 push)` under `set -euo pipefail`
  exits 1 with the `FAIL:` line swallowed into `$LEGS` and printed nowhere.
- **O14. `tests/run-tests.sh` M43 T3 control compares 3 fixtures; the workflow
  renders 4.** The local legs tree is built from `demo`, `named-indexes` and
  `book`; `html-index`, named in AC1, has no unplanted local control.
- **O15. `EXACT = re.compile(r'^\d+\.\d+\.\d+$')` is now defined twice**, in
  `tests/versioncheck.py` and `tests/pagescheck.py` — two copies of one rule in
  two readers the same workflow step chains together.
- **S1 (blame-history, low). The AC4 probe evidence predates the T2
  TeX-install fixes, and the claim that this does not matter is asserted
  rather than re-verified.** Flagged in the milestone file itself rather than
  hidden.
