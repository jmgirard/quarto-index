<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M045: The version matrix cannot agree about an empty index

- **Status:** in-progress
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
compare byte-identical. `tests/versioncheck.py`'s `check_compare` (`:158-162`)
requires the baseline leg to carry at least one `*.pdf.txt` and every other leg
to carry the same PDF fixture-name set, where today the set is printed with an
explicit `or 'none'` branch and never judged. A hand-built fixture per new
clause under `--self-test`, and the module prose that says the PDF extractions
are only reported.

**Out:** the other ten findings on the version-matrix candidate row → they stay
on that row. · Comparing PDF extraction *content* across legs → refused by
M43's own reasoning, that two Quarto versions typeset through different TeX
engines; only the name set is compared here. · Making the workflow's own steps
readable by a check → D-011 refuses it; the runs stay the evidence.

## Acceptance criteria

- [ ] AC1 `python3 tests/indexdump.py html <page>` exits non-zero with a
      `FAIL:` line naming the page and reporting that its index section carries
      no entry row, when handed a hand-written HTML fixture page — never a
      render output — whose index section carries an empty entry list; and
      exits 0, printing the section row and one entry row, when handed a
      hand-written page whose index section carries one entry row.
- [ ] AC2 `python3 tests/versioncheck.py compare <dir> pinned` exits non-zero
      with a `FAIL:` line naming the `pinned` leg and the `.pdf.txt` suffix it
      found no file under, when handed a hand-built legs directory holding an
      `index-pinned` and an `index-floor` directory whose `*.html.txt` sets are
      equal, non-empty and hold no empty file, and in which neither leg carries
      a `.pdf.txt` file.
- [ ] AC3 The same command exits non-zero with a `FAIL:` line naming both legs
      and the `.pdf.txt` fixture names they differ in, when handed a hand-built
      legs directory whose two legs' `*.html.txt` sets are equal, non-empty and
      hold no empty file, and whose `.pdf.txt` name sets are not equal.
- [ ] AC4 `tests/run-tests.sh --self-test` is clean (the profile's `verify`
      slot, plus the fuller pre-review check it names).

## Coverage

- AC1 → T1, T3
- AC2 → T2, T4
- AC3 → T2, T4
- AC4 → T3, T4, T5

## Tasks

- [ ] T1 In `tests/indexdump.py`, make `html_rows` (`:68-77`) fail when the
      rows carry a section row and no entry or letter-group row, naming the
      path and the section. Keep the existing wholly-empty clause, whose
      message says something different.
- [ ] T2 In `tests/versioncheck.py`, make `check_compare` (`:158-162`) fail
      when the baseline leg carries no `*.pdf.txt`, and when a non-baseline
      leg's `.pdf.txt` name set differs from the baseline's — after the three
      guards at `:101-129` that return first, so each new message is reachable.
      Correct the module header (`:30-35`) and the surviving report line, which
      both say the PDF extractions are reported and not compared.
- [ ] T3 Add the three hand-written HTML fixture pages AC1 names — empty entry
      list, one entry row, and the existing no-entry-list control — and plant
      each under `--self-test`, red for the two failing cases.
- [ ] T4 Add the two hand-built legs directories AC2 and AC3 name, each meeting
      the preconditions those criteria state so the new clause is the one that
      fires, and plant both under `--self-test`.
- [ ] T5 Run `tests/run-tests.sh --self-test`; fix what it names.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: criteria audit ran in REDUCED mode (declared tier internal), in a fresh-context [O] reader, twice; round 1 returned 1 finding and round 2 returned 4 over the revised wording, all disposed here, none deferred.
- 2026-08-26: plan gate chose hardening the two readers over simplifying or deleting the comparison, at the maintainer's direction after the checker-regress option was posed first, because the matrix is the only evidence behind the `>=1.4.0` floor `_extensions/index/_extension.yml` and README both declare; falsified by that floor claim being dropped or fenced somewhere else.
- 2026-08-26: plan gate chose comparing PDF extraction NAME sets across legs over comparing their content, because M30 and M33 put engine and font differences in a PDF's text layer; falsified by an extraction shown engine-neutral across xelatex and lualatex.
- 2026-08-26: /milestone-implement: status in-progress, branch `m045-matrix-empty-index` cut from main at 8d7ae92.

## Decisions

## Review
