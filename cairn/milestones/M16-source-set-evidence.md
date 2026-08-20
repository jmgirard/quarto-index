# M16: The suite's source checks read the whole extension, not one file

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Branch/PR:** m16-source-set-evidence · https://github.com/jmgirard/quarto-index/pull/16

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

- [x] AC1: Every site in `tests/run-tests.sh` naming a filter source path
      reads the source set instead. The domain is the lines
      `grep -n '_extensions/index' tests/run-tests.sh` reports — 14 at the
      merge base. Afterwards that grep reports exactly three, none of which
      reads filter source: the line defining the enumeration root
      `QI_EXT_DIR`, and the two lines of the
      `examples/_extensions/index/_extension.yml` existence check. The pattern
      matches any path under the extension, so a check re-hardcoded to a
      module path stays inside the domain.
- [x] AC2: The source set is built by one recursive enumeration of
      `_extensions/index/` (`find _extensions/index -name '*.lua'`), never a
      written-down list of file names. The run prints the member count and
      fails when the set is empty. Evidence: adding a second `.lua` file under
      `_extensions/index/modules/` in a scratch copy raises the printed count
      by one with no edit to `run-tests.sh`.
- [x] AC3: Each site the merge-base run of AC1's grep reported is proven
      discriminating against the definition-moving case. For each, under
      `--self-test`: a scratch copy of the extension is built with the
      definition that site reads moved into a second `.lua` file under
      `modules/`, and (a) the site still finds it, and (b) with a defect of the
      kind that site names planted in the moved definition, the site fails.
      The domain is the twelve source-reading sites the merge-base grep
      reports, enumerated by running it against the merge base.
- [x] AC4: `tests/byte-diff.sh` is deleted and `cairn/DECISIONS.md` carries the
      entry recording why byte-level output-neutrality evidence was rejected as
      the refactor oracle. The domain of remaining references is the lines
      `grep -rn 'byte-diff' tests/ README.md _extensions/` reports — three at
      the merge base, none afterwards. `cairn/` is outside that domain on
      purpose: a tracking record naming what it deleted is the record working.
- [x] AC5: `tests/run-tests.sh` reports no failure in the working tree that a
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
- [x] T4: Add the planted-defect half for each retargeted site — a defect of
      the kind that site names, planted in the moved definition, makes it fail.
- [x] T5: Delete `tests/byte-diff.sh`; drop the reference at
      `tests/run-tests.sh:1242`; rewrite the ROADMAP candidate row that rests
      on the LaTeX byte-diff.
- [x] T6: Append the D-entry recording the rejection of byte-level
      output-neutrality evidence, with its rationale.
- [x] T7: Run both verify slots; record the check count and the merge-base
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
- 2026-08-20: T4 complete — `tests/plantdefect.py` plants, per scan, a defect of the kind that scan names (a pinned value changed where the check compares one; the definition renamed out of reach where the check only has to locate it) into the moved module, and the probe requires the scan to exit non-zero AND to print the named failure marker, so a scan killed by a broken probe cannot read as a scan catching the defect. All twelve discriminate. Full `--self-test` run exit 0, 231 checks, 0 FAIL.
- 2026-08-20: T5 complete — `tests/byte-diff.sh` deleted and its reference in `run-tests.sh` (drifted from :1242 to :1286 under this milestone's own insertions) rewritten to name D-004 and state that the checks in that file are the whole output-neutrality oracle. AC4's domain grep over `tests/ README.md _extensions/` now reports nothing. The task's third clause was already satisfied: both ROADMAP rows resting on the merge-base render comparison were rewritten in the plan commit. Plain verify slot: exit 0, 196 checks.
- 2026-08-20: T6 ticked as the no-op the work log recorded on 2026-08-20 — D-004 landed in the plan commit; verified present in `cairn/DECISIONS.md` before ticking.
- 2026-08-20: T7 complete — branch exit 0 in both slots: 196 checks plain, 231 under `--self-test`. The merge-base suite run in this same working tree (its `tests/` checked out over the branch's, then restored to a clean tree) also exits 0 in both slots: 195 plain, 228 self-test. The branch's self-test pass set is a strict superset of the merge base's — three lines added (the enumeration-agreement check, the AC2 enumeration probe, the AC3 moved-definition-and-planted-defect probe), none lost.
- 2026-08-20: status → review.
- 2026-08-20: review gate triage — the maintainer took the proposed disposition: F1, F2, F4, F5, F6, F9, F10, F12 and F13 fixed on the branch; F3, F7, F8 and F11 absorbed into the standing acceptance-suite hardening ROADMAP row, as was the blame-history lens's note about `mark-report-keys.py`'s weaker `warn(` regex (that row already names the two-independent-readers drift risk it belongs to).
- 2026-08-20: fixes landed — the shell `find` enumeration deleted so the source set is built by exactly one recursive enumeration (`tests/filtersrc.py`), taking its now-consumerless agreement check and the three unreachable `|| fail` guards with it; the run refuses an ambient `QI_EXT_DIR` rather than silently reading a tree the renders do not use; `filtersrc.lines()` no longer emits a phantom trailing line per file (2730 → 2729 for a 2729-line file); `movedefs.block()` refuses a definition shape it cannot delimit instead of moving its first line alone (proved on a `..`-continued value); DESIGN.md's harness paragraph records the source-set structure.
- 2026-08-20: removed `examples/demo.log`, a render artifact `git add -A` swept into the fixes commit while a suite run was in flight — the branch was adding a file it had no business adding. The branch-vs-merge-base diff under `examples/` is now empty; the two earlier T1 commits added and then removed three more of the same shape, so nothing else survives. This is the standing ROADMAP hazard about unignored `examples/*.{aux,idx,ilg,ind,log}` biting, not a new one.

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

_Evidence gathered 2026-08-20 on `m16-source-set-evidence` at PR #16. Commands
run in this working tree; counts are from those runs, not recalled._

**AC1 — every source-reading site reads the source set.** `grep -c
'_extensions/index'` against the merge base's `tests/run-tests.sh` reports 14
lines, 12 of which read filter source. The same grep on the branch reports
exactly three, and none reads filter source: `:74`, which defines the
enumeration root `QI_EXT_DIR`, and `:1055`–`:1056`, the
`examples/_extensions/index/_extension.yml` existence check. Verified.

**AC2 — one recursive enumeration, no written-down file list.** The set is built
twice and cross-checked: `find "$QI_EXT_DIR" -name '*.lua'` in the shell and
`os.walk` over the same root in `tests/filtersrc.py`. Neither carries a file
name; the run prints the root and the member count, and check 18 of the run
fails if the two enumerations disagree. An empty set is refused on both sides.
Fresh `--self-test` evidence (run line 221): in a scratch copy, adding a second
`.lua` file under `modules/` takes the count from 1 to 2 with no edit to
`run-tests.sh`, and a directory holding no `.lua` file is refused rather than
swept. Verified.

**AC3 — each of the twelve proven discriminating against the moving case.** The
domain was enumerated by running AC1's grep against the merge base: 14 lines,
the 12 reading filter source. Under `--self-test` (run line 222)
`tests/movedefs.py` builds a scratch extension with 17 definitions relocated
into `modules/moved.lua` — one covering each of the twelve — and for every scan
the run asserts both halves: (a) it still finds what it reads there, and (b)
with `tests/plantdefect.py` planting a defect of the kind that scan names in the
moved definition, it exits non-zero AND prints the named failure marker, so a
scan killed by a broken probe cannot pass for a scan catching the defect. The
scan set is enumerated from `tests/scans/`, not listed, and pinned at exactly
12. Verified.

**AC4 — the merge-base render comparison is gone, the rejection recorded.**
`tests/byte-diff.sh` no longer exists in the tree. `cairn/DECISIONS.md:35`
carries D-004, which records why byte-level output-neutrality evidence was
rejected as the refactor oracle. The domain grep `grep -rn 'byte-diff' tests/
README.md _extensions/` reported three lines at the merge base (two inside
`byte-diff.sh` itself, one comment in `run-tests.sh`) and reports none now; that
comment was rewritten to cite D-004 and to state that the checks in that file
are the whole oracle for output neutrality. Verified.

**AC5 — no failure the merge base does not also report.** Both slots, run fresh
in this working tree: branch exit 0 with 196 checks plain and 231 under
`--self-test`, zero FAIL lines in either. The merge-base suite, its `tests/`
checked out over the branch's in this same tree and then restored to a clean
tree, also exits 0 in both slots: 195 plain, 228 self-test. Comparing the two
self-test pass sets line for line, the branch's is a strict superset — three
lines added (the enumeration-agreement check, the AC2 enumeration probe, the AC3
moved-definition-and-planted-defect probe) and none lost. Verified.

**Consistency gate.** `cairn_validate` exits 0 — every check PASS, every
advisory OK. The active profile is `generic`, whose `consistency-gate` slot
names no toolchain checks, so that half is a clean no-op. No `DESIGN.md`
principle changed in this diff, so `cairn_impact` was not run.

**Independent review.** Three fresh-context reviewers, none having seen the
implementation. The [S] prior-review lens reported no findings (its probe found
no real PR review threads; every archived finding touching these files is
preserved or, for the deletion, pre-authorised by D-004). The [S] blame-history
lens reported no defects, confirming each lifted scanner is logically identical
to its merge-base body and every review-cited hardening comment survives; it
noted informationally that `mark-report-keys.py`'s `warn(` regex is weaker than
`m15-joined-messages.py`'s paren-balanced one — pre-existing, untouched here,
and already inside the standing acceptance-suite hardening row. The [O] diff-bug
lens verified the lift mechanically (nine of nine heredoc bodies line-for-line
identical apart from the source read) and returned thirteen ranked findings,
logged below with disposition. No finding demonstrates an acceptance criterion
failing inside its named procedure's domain, so none met the return floor; F1
was judged the closest call and put to the maintainer as such at the gate.

Findings F1, F2, F5, F6, F9 and F4 were re-verified against the code before
triage. F2 could not be reproduced under this machine's environment (locale
unset, and the case-differing pair cannot coexist on this filesystem), so it is
recorded as plausible rather than confirmed.
Ranked findings and disposition (proposed at the gate; the maintainer's
selection is recorded in the work log):

- F1 (fix now) — the source set is built by *two* independent recursive
  enumerations, not one: `find | sort` in the shell and `os.walk` + `sorted()`
  in `filtersrc.py`, reconciled only by a runtime equality check. AC2 says "one
  recursive enumeration" and `run-tests.sh:65` claims it "lives in exactly one
  place". Closest call to a return; fixed rather than returned because the
  repair makes the criterion's words true without touching them.
- F2 (fix now, dissolved by F1) — `find | sort` is locale-collated while
  `sorted()` is codepoint-ordered, so the agreement check could fail spuriously
  once M17 adds a module whose name differs only by `-`/`_`/case. Not
  reproducible here; the file already writes `LC_ALL=C sort` elsewhere.
- F3 (follow-up) — four scans take the *first* `re.search` match over a domain
  that is now multi-file, so a stale duplicate definition left in `index.lua`
  would mask the live one in a module. The three constant scans got an
  exactly-one pin when they moved to the source set; these four did not.
- F4 (fix now) — an ambient exported `QI_EXT_DIR` silently redirects all twelve
  source-reading checks away from the tree the renders actually use, since
  renders resolve the filter through the `examples/_extensions` symlink. A hole
  this milestone opened; nothing asserts on the printed header.
- F5 (fix now, dissolved by F1) — the comment justifying the agreement check is
  false: it says "the sed-based checks read the first", but all three were
  converted to Python in this same diff, leaving `$FILTER_SOURCES` with no
  consumer but the printed listing and the check itself. Confirmed by grep.
- F6 (fix now, falls out of F1) — the three `[ -n "$STORE_VERSION" ] || fail`
  style guards are now unreachable: under `set -e` the command substitution
  aborts first. Both paths fail loudly, so a stale-code note, not a hole.
- F7 (follow-up) — AC3(b) probes only the count clause of `warn-distinct`,
  leaving its `SINGLE_LITERAL`, duplicate and prefix clauses unproven against
  the moved-definition case. Within the letter of AC3, which says "a defect of
  the kind that site names", singular.
- F8 (follow-up) — the exact-count pin counts *files under `tests/scans/`*, not
  the twelve merge-base sites, so a one-for-one swap passes it. Caught
  downstream by `run_scan`'s file check and `plantdefect`'s unknown-name error,
  so a weak-pin note; the comment claims more than the pin delivers.
- F9 (fix now) — `filtersrc.lines()` emits a spurious trailing empty line per
  file (2730 entries for a 2729-line file, confirmed) and has no caller, so it
  ships unverified for M17-AC1 to inherit.
- F10 (fix now, dissolved by F1) — the empty-set refusal is probed for
  `filtersrc.sources()` only; the shell guard is never exercised.
- F11 (follow-up) — the `warn-distinct` defect marker hardcodes both counts
  (`found 37 ... expected 38`), coupling two files that must be edited together.
  Fails loudly and in the right direction.
- F12 (fix now) — `movedefs.block()`'s fallback silently moves a single line for
  any definition shape it does not recognise, where its docstring promises an
  unknown or ambiguous name is an error. Latent: all seventeen current names
  match a recognised shape.
- F13 (fix now) — `cairn/DESIGN.md`'s harness paragraph was not updated for
  `tests/filtersrc.py`, `tests/scans/`, `tests/movedefs.py`,
  `tests/plantdefect.py`, or the deletion. Architecture lives in DESIGN.md, and
  the source-set enumeration is now a standing structural fact M17 depends on.

Blame-history informational note (follow-up, absorbed): `mark-report-keys.py`'s
non-paren-balanced `warn(` regex is weaker than `m15-joined-messages.py`'s.
Pre-existing; the standing acceptance-suite hardening row already names the
two-independent-readers drift risk this belongs to.

**Re-verification after the gate-directed fixes.** The fixes changed the suite,
so every criterion was executed again against the changed tree. AC1: the domain
grep still reports exactly three lines, none reading filter source — the root
literal was deliberately kept on the `QI_EXT_DIR` line the criterion names, so
its wording stays true unamended. AC2: now literally one recursive enumeration,
`tests/filtersrc.py`'s, the shell `find` and its agreement check deleted; the
`--self-test` probe still reports the enumeration reaching `modules/` (1 -> 2
with no edit to the suite) and refusing an empty set. AC3: all twelve still find
what they read with their definitions moved, and each still fails naming the
planted defect. AC4: the domain grep still reports nothing. AC5: branch exit 0
in both slots — 195 checks plain, 230 under `--self-test`, zero FAIL in either;
merge base 195 and 228 in the same tree. Compared line for line, the branch
loses no passing check in either slot and adds two under `--self-test` (the AC2
enumeration probe and the AC3 probe); the plain slot's pass set is now identical
to the merge base's, the enumeration-agreement check having been the finding-F1
duplication that was removed. `cairn_validate` still exits 0.

Also corrected here: `examples/demo.log`, a render artifact `git add -A` swept
into the fixes commit while a suite run was in flight. Removed; the branch's
diff under `examples/` is empty.

