# M16: The suite's source checks read the whole extension, not one file

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Branch/PR:** m16-source-set-evidence

## Goal

Every check that reads the filter's source reads the extension's whole Lua
source set, so a definition moving between files cannot turn a check into a
vacuous pass.

## Scope

Deliverable tier: **internal** — the deliverable is the test harness, and no
external consumer of the repo relies on it.

**In:** `tests/run-tests.sh` gains one recursive enumeration of the
extension's `.lua` files and every source-reading check reads that set; each
such check is proven discriminating against the definition-moving case under
`--self-test`; `tests/byte-diff.sh` is deleted and the rejection recorded as a
D-entry.

Twelve checks read `_extensions/index/index.lua` as text today. Three are
`sed` constant extractions guarded by `|| fail` and would fail loudly if the
constant moved; the rest are regex scans over the file's source, and at least
two — the `warn()`-literal distinctness check (`tests/run-tests.sh:1455`) and
the M15-AC5 joined-message reader (`:7150`) — assert a property of the
literals they find, so finding zero literals passes vacuously.

**Out:** splitting `index.lua` → M17 (this milestone ships no filter change).
Widening or repairing `byte-diff.sh` → refused, not deferred; the D-entry
records why. Making module-level state per-document → stays the standing
`marks_seen` candidate row.

## Acceptance criteria

- [ ] AC1: Every site in `tests/run-tests.sh` naming a filter source path
      reads the source set instead. The domain is the lines
      `grep -n '_extensions/index' tests/run-tests.sh` reports — 14 at the
      merge base. Afterwards that grep reports exactly three: the `find`
      enumeration of AC2, and lines 994-995, the
      `examples/_extensions/index/_extension.yml` existence check, which reads
      no filter source. The pattern matches any path under the extension, so a
      check re-hardcoded to a module path stays inside the domain.
- [x] AC2: The source set is built by one recursive enumeration of
      `_extensions/index/` (`find _extensions/index -name '*.lua'`), never a
      written-down list of file names. The run prints the member count and
      fails when the set is empty. Evidence: adding a second `.lua` file under
      `_extensions/index/modules/` in a scratch copy raises the printed count
      by one with no edit to `run-tests.sh`.
- [ ] AC3: Each site the merge-base run of AC1's grep reported is proven
      discriminating against the definition-moving case. For each, under
      `--self-test`: a scratch copy of the extension is built with the
      definition that site reads moved into a second `.lua` file under
      `modules/`, and (a) the site still finds it, and (b) with a defect of the
      kind that site names planted in the moved definition, the site fails.
      The domain is the twelve source-reading sites the merge-base grep
      reports, enumerated by running it against the merge base.
- [ ] AC4: `tests/byte-diff.sh` is deleted and `cairn/DECISIONS.md` carries the
      entry recording why byte-level output-neutrality evidence was rejected as
      the refactor oracle. The domain of remaining references is the lines
      `grep -rn 'byte-diff' tests/ README.md _extensions/` reports — three at
      the merge base, none afterwards. `cairn/` is outside that domain on
      purpose: a tracking record naming what it deleted is the record working.
- [ ] AC5: `tests/run-tests.sh` reports no failure in the working tree that a
      merge-base run in the same working tree does not also report, under both
      the plain and `--self-test` slots (`cairn/PROFILE.md` verify and
      pre-review). The printed check count is stated.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3, T4
- AC4 → T5, T6
- AC5 → T7

## Tasks

- [x] T1: Add the source-set enumeration to `tests/run-tests.sh` — recursive
      `find` over `_extensions/index/`, a non-empty assertion, a printed
      member count, and for the python scanners a source view that keeps each
      line's FILE identity (never a bare concatenation), since M17-AC1 asks
      which file a definition sits in.
- [ ] T2: Retarget each of the twelve source-reading sites
      (`tests/run-tests.sh:1200, 1252, 1296, 1455, 1630, 2314, 3242, 4349,
      4357, 5748, 5751, 7150`) to the source set. Leave the two
      `_extensions/index` sites that read no filter source (`:994`, the
      `_extension.yml` existence check) alone.
- [ ] T3: Add the `--self-test` moved-definition probe for each retargeted
      site: scratch copy, definition moved into `modules/`, site still finds it.
- [ ] T4: Add the planted-defect half for each retargeted site — a defect of
      the kind that site names, planted in the moved definition, makes it fail.
- [ ] T5: Delete `tests/byte-diff.sh`; drop the reference at
      `tests/run-tests.sh:1242`; rewrite the ROADMAP candidate row that rests
      on the LaTeX byte-diff.
- [ ] T6: Append the D-entry recording the rejection of byte-level
      output-neutrality evidence, with its rationale.
- [ ] T7: Run both verify slots; record the check count and the merge-base
      comparison.

## Work log

- 2026-08-20: created by /milestone-plan.
- 2026-08-20: criteria audit ran in REDUCED mode (declared tier internal); returned findings on AC1's proxy grep domain, its non-recursive glob, and the artifact-side domain of the since-dropped HTML byte-diff criterion — all three fixed at the gate before the criteria were written.
- 2026-08-20: plan gate chose deleting `tests/byte-diff.sh` over widening it to HTML and book projects because the widening is the checker-regress shape and the user took the simplify-or-delete disposition; falsified by a behavior-preserving change to the filter that the ~100-check acceptance suite passes while rendered output actually moves.
- 2026-08-20: plan chose deletion over simplification of `byte-diff.sh` because its three known defects are all hardening repairs, and a byte-diff fails on invisible whitespace changes — the shape tracking-rules names as a defect in the test; falsified by a review needing byte-level evidence that no suite check can supply.
- 2026-08-20: implement gate chose a `tests/filtersrc.py` helper over per-heredoc argv concatenation and over a sentinel-joined temp file, because the enumeration then lives in one place and keeps per-file identity; the sentinel option was rejected outright since its sentinels are Lua comments and the M02-AC5 scanner strips comments before reading.
- 2026-08-20: implement gate chose extracting the twelve scanners into a scan block behind a `--source-scan-check <dir>` re-entry flag, over per-site functions called directly and over re-running the whole suite with the root overridden; the last is not viable (renders need the tree installed at examples/_extensions, and thirteen full runs cost minutes each).
- 2026-08-20: T1 checkpoint, NOT complete — filtersrc.py, the recursive enumeration and the AC2 check are written and the AC2 check passes in-run, but the `--self-test` enumeration probe had not been reached when this was committed. T1 stays unticked until a full run is clean.
- 2026-08-20: a comment drafted for T1 wrote the literal `byte-diff.sh` into tests/, which AC4's own domain grep requires to be empty; caught before commit and reworded to name D-004 instead.
- 2026-08-20: T6 is already satisfied — D-004 was appended to cairn/DECISIONS.md in the plan commit, so the task is a no-op rather than work.
- 2026-08-20: T1 complete — full `--self-test` run exit 0, 230 checks, 0 FAIL; the AC2 self-test probe reports the enumeration reaching modules/ (1 -> 2 with no edit to the suite) and refusing an empty source set. AC2 ticked.

## Decisions

## Review
