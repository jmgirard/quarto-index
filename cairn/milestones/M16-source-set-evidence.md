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
      merge base. Afterwards that grep reports exactly three, none of which
      reads filter source: the line defining the enumeration root
      `QI_EXT_DIR`, and the two lines of the
      `examples/_extensions/index/_extension.yml` existence check. The pattern
      matches any path under the extension, so a check re-hardcoded to a
      module path stays inside the domain.
- [ ] AC2: The source set is built by one recursive enumeration of
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
- [x] T2: Retarget each of the twelve source-reading sites
      to the source set — the twelve the merge-base run of AC1's grep
      reports. Leave the two `_extensions/index` lines that read no filter
      source (the `examples/.../\_extension.yml` existence check) alone.
- [x] T3: Add the `--self-test` moved-definition probe for each retargeted
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
- 2026-08-20: T1 complete — full `--self-test` run exit 0, 230 checks, 0 FAIL; the AC2 self-test probe reports the enumeration reaching modules/ (1 -> 2 with no edit to the suite) and refusing an empty source set.
- 2026-08-20: reverted an AC2 checkbox tick made at the T1 commit — acceptance-criterion boxes are review's under AC fencing, not implement's; the evidence stands, the tick was mine to leave alone.
- 2026-08-20: AC1 amended at the mini gate (audited first by a fresh-context [O] reader in reduced mode; sound on both questions). Two defects, both found by executing the criterion: it named "the `find` enumeration of AC2" as a matching line, but `find "$QI_EXT_DIR" -name '*.lua'` carries no literal path and never matches its own grep — the matching line is the `QI_EXT_DIR` definition; and its pinned "lines 994-995" had already drifted to 1015-1016 from this milestone's own T1 insertions. The amended wording carries no line coordinates. The promise's strength is unchanged.
- 2026-08-20: T2 complete — all twelve sites retargeted onto the source set, zero `index.lua` references left, and AC1's post-state grep reports exactly the three predicted lines. Full `--self-test` run exit 0, 230 checks, pass set byte-identical to the pre-retarget run. That identity is consistent with a correct retarget AND with a vacuous one; T3/T4 are what discriminate.
- 2026-08-20: T2 also dropped the drifting line numbers from its own task text (minor edit, implement-owned) for the same reason the criterion did.
- 2026-08-20: T3 complete — the twelve scanner bodies lifted into `tests/scans/<name>.py`, a `run_scan` dispatcher holding each one's environment and arguments in one place, `tests/movedefs.py` building the moved-definition tree, and a `--self-test` probe running all twelve against it. Full `--self-test` run exit 0, 231 checks (230 + the new AC3 line), 0 FAIL; the probe reports all 12 still finding what they read with 17 definitions relocated into `modules/moved.lua`.

## Decisions

- 2026-08-20 (T3 mechanism): the implement gate chose "extract the twelve
  scanners into a scan block behind a `--source-scan-check <dir>` flag".
  Mapping the blocks showed function-extraction is the wrong realization of
  it: the twelve are interleaved with some thirty other `PY` heredocs, and
  three of them (`STORE_VERSION`, `MAX_LEVELS`, `OVERFLOW_JOIN`) produce
  values consumed hundreds of lines later, so moving them changes evaluation
  order in ways a passing suite would not reveal.
  Same decision, better mechanism: lift each scanner's BODY out of its
  heredoc into `tests/scans/<name>.py`, invoked as `python3
  tests/scans/<name>.py` with the env it already receives. The `<<'PY'` …
  `PY` boundaries are unambiguous, so the transformation is mechanical and
  reviewable; each scanner becomes independently runnable, which is precisely
  what AC3's probes need; and nothing moves in evaluation order, so the three
  value-producing sites keep their position. `--source-scan-check <dir>` then
  runs every file under `tests/scans/` with `QI_EXT_DIR` pointed at the given
  tree.
  Rejected: re-running the whole suite with the root overridden (the gate's
  option C — renders resolve the extension through the `examples/_extensions`
  symlink rather than `QI_EXT_DIR`, so the scratch tree would be read by the
  scanners while the renders still used the real filter, and each probe would
  cost a full multi-minute run).

- 2026-08-20 (T3 mechanism, refined): the recorded mechanism had
  `--source-scan-check <dir>` re-enter `run-tests.sh` to run every file under
  `tests/scans/`. Executing it showed the re-entry cannot work: seven of the
  twelve scans are handed a pinned constant the suite defines deep in the run
  body (`MARKER_CLASS`, the three `WARN_*` keys, `STORE_SUFFIX`/`STORE_DIR`,
  and the manifest file the xref scan reads), so a re-entry that skipped the
  body would have to carry a second copy of those pins — and a probe running
  the scans with pins of its own proves nothing about the pins the run uses.
  Same decision, no flag: a `run_scan <name>` dispatcher holds each scan's
  environment and arguments in one place, late-binding the globals, so the run
  calls it at the site and the AC3 probe calls the same function with
  `QI_EXT_DIR` pointed at the moved-definition tree. The scan bodies still
  live one per file under `tests/scans/`, enumerated from the directory rather
  than listed.

## Review
