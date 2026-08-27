<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M045: The version matrix cannot agree about an empty index

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m045-matrix-empty-index`

## Goal

The two readers the version matrix compares through stop being able to pass on
nothing — a page whose index section holds no entry, and a run whose PDF
extractions never arrived.

## Scope

Surface tier: **internal** — the deliverable is the version matrix's own two
readers and their planted cases; no consumer outside this repo's development
reads them.

**In:** `tests/indexdump.py`'s `html_rows` (`:68-77`) fails when the rows it
judges carry a section and no entry or letter-group row, where today it fails
only on a wholly empty row list, so a one-row dump prints and two of them
compare byte-identical. `tests/htmlindex.py`'s `index_entries` (`:433-448`)
reports the shape it found: an entry list carrying no entry is named as that,
where today it is named as a list that is not a direct child of the index
section, which is false of a page whose empty list is a direct child.
`tests/versioncheck.py`'s `check_compare` (`:158-162`) requires the baseline
leg to carry at least one `*.pdf.txt` and every other leg to carry the same PDF
fixture-name set, where today the set is printed with an explicit `or 'none'`
branch and never judged. A hand-built fixture per new clause under
`--self-test`, and the module prose that says the PDF extractions are only
reported.

**Out:** the other ten findings on the version-matrix candidate row → they stay
on that row. · Comparing PDF extraction *content* across legs → refused by
M43's own reasoning, that two Quarto versions typeset through different TeX
engines; only the name set is compared here. · Making the workflow's own steps
readable by a check → D-011 refuses it; the runs stay the evidence.

## Acceptance criteria

- [x] AC1 `python3 tests/indexdump.py html <page>` exits non-zero with a
      `FAIL:` line naming the page and reporting that its index section carries
      no entry row, when handed a hand-written HTML fixture page — never a
      render output — whose index section carries an empty entry list; and
      exits 0, printing the section row and one entry row, when handed a
      hand-written page whose index section carries one entry row.
- [x] AC2 `python3 tests/versioncheck.py compare <dir> pinned` exits non-zero
      with a `FAIL:` line naming the `pinned` leg and the `.pdf.txt` suffix it
      found no file under, when handed a hand-built legs directory holding an
      `index-pinned` and an `index-floor` directory whose `*.html.txt` sets are
      equal, non-empty and hold no empty file, and in which neither leg carries
      a `.pdf.txt` file.
- [x] AC3 The same command exits non-zero with a `FAIL:` line naming both legs
      and the `.pdf.txt` fixture names they differ in, when handed a hand-built
      legs directory whose two legs' `*.html.txt` sets are equal, non-empty and
      hold no empty file, and whose `.pdf.txt` name sets are not equal.
- [x] AC4 `tests/run-tests.sh --self-test` is clean (the profile's `verify`
      slot, plus the fuller pre-review check it names).

## Coverage

- AC1 → T1, T3
- AC2 → T2, T4
- AC3 → T2, T4
- AC4 → T3, T4, T5

## Tasks

- [x] T1 In `tests/indexdump.py`, make `html_rows` (`:68-77`) fail when the
      rows carry a section row and no entry or letter-group row, naming the
      path and the section. Keep the existing wholly-empty clause, whose
      message says something different. In `tests/htmlindex.py`, narrow
      `index_entries`'s misplaced-list message to a list that really is not a
      direct child, and report an entry list carrying no entry as that.
- [x] T2 In `tests/versioncheck.py`, make `check_compare` (`:158-162`) fail
      when the baseline leg carries no `*.pdf.txt`, and when a non-baseline
      leg's `.pdf.txt` name set differs from the baseline's — after the three
      guards at `:101-129` that return first, so each new message is reachable.
      Correct the module header (`:30-35`) and the surviving report line, which
      both say the PDF extractions are reported and not compared.
- [x] T3 Add the three hand-written HTML fixture pages AC1 names — empty entry
      list, one entry row, and the existing no-entry-list control — and plant
      each under `--self-test`, red for the two failing cases.
- [x] T4 Add the two hand-built legs directories AC2 and AC3 name, each meeting
      the preconditions those criteria state so the new clause is the one that
      fires, and plant both under `--self-test`.
- [x] T5 Run `tests/run-tests.sh --self-test`; fix what it names.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: criteria audit ran in REDUCED mode (declared tier internal), in a fresh-context [O] reader, twice; round 1 returned 1 finding and round 2 returned 4 over the revised wording, all disposed here, none deferred.
- 2026-08-26: plan gate chose hardening the two readers over simplifying or deleting the comparison, at the maintainer's direction after the checker-regress option was posed first, because the matrix is the only evidence behind the `>=1.4.0` floor `_extensions/index/_extension.yml` and README both declare; falsified by that floor claim being dropped or fenced somewhere else.
- 2026-08-26: plan gate chose comparing PDF extraction NAME sets across legs over comparing their content, because M30 and M33 put engine and font differences in a PDF's text layer; falsified by an extraction shown engine-neutral across xelatex and lualatex.
- 2026-08-26: /milestone-implement: status in-progress, branch `m045-matrix-empty-index` cut from main at 8d7ae92.
- 2026-08-26: amendment (substantive, mini gate): Scope In grows by `tests/htmlindex.py`'s `index_entries`, whose empty-entry-list failure today names a placement that is false of the page; AC1 asks the failure to report no entry row and the message is written there. Criteria unchanged.
- 2026-08-26: T1 — `html_rows` fails on a section row with nothing under it, naming each such section; `index_entries` names an empty direct-child entry list as that, and its misplaced-list message narrows to a list that really is not a direct child. Suite green (403 checks).
- 2026-08-26: T2 — `check_compare` fails when the baseline leg carries no `*.pdf.txt` and when another leg's PDF fixture-name set differs from it, reporting both findings alongside any HTML difference rather than returning on the first; the module header and the surviving report line now say the names are compared and the content is not, and the suite's own control reads the new line. Suite green (403 checks).
- 2026-08-26: T3 — three hand-written pages under `--self-test` (an empty entry list, one entry row, no entry list) plus a fourth whose list is nested a level down, so the narrowed placement message is shown still firing; the one-entry page is the control, compared against the exact two rows it carries, and `html_rows`'s own clause is planted by direct call, once on a lone section header and once on a second header beside a first that is fine.
- 2026-08-26: T4 — two hand-built legs trees copied from the control tree, each asserted to carry the equal, non-empty, no-empty-file HTML side the two criteria require before the PDF clause is reached; a third tree broken on both sides shows the HTML difference and the PDF finding reported together.
- 2026-08-26: T5 — `tests/run-tests.sh --self-test` green at 705 checks (693 before). T3-T5 landed in one commit; the three blocks are separate.
- 2026-08-26: all tasks done, `tests/run-tests.sh --self-test` clean (705 checks); status review.

## Decisions

## Review

Fresh evidence, 2026-08-26, on `m045-matrix-empty-index` at 4550791.
PR: https://github.com/jmgirard/quarto-index/pull/45

- AC1 — met. Two hand-written pages built fresh for this review under the
  session scratchpad, neither a render output. The page whose index section
  carries `<ul>\n</ul>` and nothing else: exit 1, `FAIL: <path>: the index
  section carries an entry list with no entry row in it`. The page carrying
  one `qi-term` list item: exit 0, stdout exactly two lines — the section row
  `section\tqi-index\th1\tIndex\tintro` and the entry row
  `0\tAlpha\t#qi-mark-1` — and nothing else.
- AC2 — met. A hand-built legs directory holding `index-pinned` and
  `index-floor`, each with the same two non-empty `*.html.txt` files (checked:
  equal name sets, zero empty files) and no `*.pdf.txt` anywhere: exit 1,
  `FAIL: M43: the \`pinned\` leg carries no \`*.pdf.txt\` extraction, so no leg
  rendered a PDF the others could be held to and the PDF half of this matrix
  would be enforced nowhere`. The two HTML comparisons pass above it, so the
  clause that fired is this one.
- AC3 — met. The same tree with `demo.pdf.txt` on the baseline leg and
  `book.pdf.txt` on the other: exit 1, `FAIL: M43: the \`floor\` leg extracted
  the \`*.pdf.txt\` fixture(s) ['book'] and the \`pinned\` leg extracted
  ['demo']; the two legs did not render the same fixtures to PDF, and the 2
  name(s) they differ in are ['book', 'demo']` — both legs and both names.
- AC4 — met. `tests/run-tests.sh --self-test` exit 0, "All checks passed (705
  checks)", run uncontended after an earlier attempt collided with a reviewer's
  concurrent run over the shared `tests/.work` (that attempt's red is the
  collision, not a defect). `cairn_validate.py` exit 0, all 16 checks PASS and
  all 7 advisories OK. Profile `generic` names no toolchain consistency-gate
  checks. PR #45 CI green: build, plan, both render legs, and the matrix's own
  `compare` job.

### Review findings

Three fresh-context reviewers. The [S] blame-history and [S] prior-PR-comments
lenses each reported zero findings (the latter's GitHub probe returned no
inline review comments at all, so it read the archived `## Review` sections and
the ROADMAP candidate rows). The [O] diff-bug lens reported eleven, ranked;
each is recorded below with its disposition. None demonstrates an acceptance
criterion failing, so none met the return floor.

- F1 (fix now) `site/tests.qmd:27-31` still tells readers the PDFs are not
  compared across legs. T2 corrected the module header and the report line but
  not the public docs page: "The PDFs are not compared across legs. Each leg's
  PDF render is held to exiting 0 with a non-empty printed index instead." A
  dropped `book.pdf` on one leg now goes red with a failure the documented
  contract says cannot happen.
- F2 (fix now) `tests/htmlindex.py:448-452` — the new direct-child clause
  preempts the misplaced-list walk. A section holding both an empty
  direct-child list and the real entry list nested in a `div` now reports the
  empty list and never mentions the nesting, which the old message named.
  Confirmed by running such a page.
- F3 (fix now) `tests/indexdump.py:80-86` — the message ends "so this dump is
  section headers alone", which is false when only one of several sections is
  bare; the suite plants exactly that case. Same misreport class this milestone
  set out to fix in `htmlindex.py`.
- F4 (fix now) `tests/versioncheck.py:183-195` — the PDF report line and the
  `N comparison(s) over N fixture(s)` domain-size line are now printed only on
  a clean run, so a red run says nothing about the domains it swept, against
  the module header's own promise. Confirmed by running a tree whose HTML
  differs and whose PDF side is fine.
- F5 (reject) `tests/indexdump.py:71-86` — the clause is unreachable through
  the command, because `index_entries` raises first on every page the reader
  can parse. Deliberate: T1 scoped it as a guard against that raise being
  removed, and the code comment says so. The plant reaches it by direct call,
  the same shape `pdf_rows` uses.
- F6 (follow-up) Both new PDF clauses are unreachable on the runner as
  `.github/workflows/versions.yml` stands: the render step runs under
  `set -euo pipefail` and the upload step has no `if: always()`, so a leg that
  failed a PDF extraction uploads nothing and is caught by the missing-leg
  clause first. Filed as a candidate row.
- F7 (fix now) `tests/versioncheck.py:138-144` — the HTML name-set skew still
  returns inside the leg loop, ahead of the PDF block, so T2's work-log claim
  that findings report alongside any HTML difference holds for content
  differences only. Corrected by a work-log line.
- F8 (fix now) `tests/run-tests.sh` `m45_planted` asserts non-zero exit, the
  message substring and no traceback, but never the `FAIL:` prefix AC1, AC2 and
  AC3 each word.
- F9 (fix now) `tests/run-tests.sh:15962` labels its failure `M45-AC3` although
  the assertion it guards is the name-set-equal ok line, which is neither AC2
  nor AC3 as worded.
- F10 (fix now) No plant for a non-baseline leg carrying zero PDFs, where the
  skew branch prints an empty list and calls it two legs rendering different
  fixtures rather than a leg that uploaded no PDF at all.
- F11 (fix now) `tests/indexdump.py:78-79` — the `else` arm of the ternary
  cannot be taken, since `starts` is built from rows that start with the
  section token and a tab.
