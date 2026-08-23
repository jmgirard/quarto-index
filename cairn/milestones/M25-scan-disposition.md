# M25: A check that cannot hold its promise is retired, not widened

- **Status:** review
- **Priority:** normal
- **Depends on:** M24
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m25-scan-disposition` / https://github.com/jmgirard/quarto-index/pull/25

## Goal

The suite's zero-warning controls tell this extension's warnings from any other
filter's, and the source-shape scans are cut back to the properties they
actually assert — deleted where they assert none.

## Scope

Surface tier: **internal** — the deliverable is the repo's acceptance suite,
dev tooling over repo-internal artifacts, with no external consumer relying on
it.

**In:** The bare-`(W)` warning patterns replaced by the extension's own message
set, which `tests/scans/warn-distinct.py` already enumerates from the `warn()`
call sites; and the source-shape scans disposed under D-011 — the twelve-scan
count pin removed, the four FIRST-match scans given exactly-one pins or
deleted, `filtersrc.py`'s consumerless `lines()` resolved, and each surviving
scan's header comment narrowed to what it reads. Depends on M24 because these
checks' file-reading is settled there first.

**Out:**
- Widening any scan's promise — refused as the checker-regress shape (D-011,
  following D-004).
- The `examples/`→`$WORK` repair itself → M24.
- `warn-distinct` learning to read `:format(` arguments — that is the widening
  D-011 refuses; the scan's promise narrows instead, and the numbers and text
  built outside the `warn()` call stay held by the rendered-log pins.
- Every remaining item on the acceptance-suite-hardening candidate row → stays
  on that row.

## Acceptance criteria

- [x] AC1: Over the file set `git ls-files tests` enumerates, no check asserts
      a warning count or a warning absence with a pattern that matches every
      `(W)` line: greps for `check_warning_count` calls whose pattern argument
      is `(W)`, and for `grep -q '^(W)'`, both return nothing.
- [x] AC2: A zero-warning control in the suite fails when this extension emits
      a warning during that render, and passes when a warning emitted by
      another filter is the only one present.
- [x] AC3: Nothing under the file set `git ls-files tests` enumerates asserts a
      count of the files under `tests/scans/`; the grep for `tests/scans` in
      that set returns only `run_scan`'s own path construction and the scan
      invocations.
- [x] AC4: Over `git ls-files tests`, every scan in `tests/scans/` that
      searches the filter source set asserts an exact match count for what it
      finds, or no longer exists — enumerated by grepping those files for
      `re.search`, `re.match` and `re.findall` over `filtersrc`'s source set.
- [x] AC5: `tests/filtersrc.py` exports no function without a caller in the set
      `git ls-files tests` enumerates.
- [x] AC6: `tests/run-tests.sh --self-test` exits 0 and prints its
      "All checks passed" line.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T8

## Tasks

- [x] T1: Give `warn-distinct.py` a mode that emits the extension's warning
      literals as a list the shell can read, and load it once near the suite's
      other pinned constants.
- [x] T2: Replace the five bare-`(W)` sites — `tests/run-tests.sh:8406`, `8470`
      and their PDF twins, plus the three `grep -q '^(W)'` controls at `4929`,
      `5005` and `5131` — with assertions over that literal set.
- [x] T3: Prove the replacement discriminating both ways: plant an
      extension warning into a captured log copy and require the control to
      fail; plant a foreign filter's `(W)` line and require it to pass.
- [x] T4: Delete the twelve-scan count pin (`tests/run-tests.sh:9649-9658`).
      Its stated job — noticing a scan that left the probed set — is what
      `run_scan`'s missing-script `fail` already does at every invocation.
- [x] T5: Take the four FIRST-match scans (`html-identifiers`, `marker-class`,
      `xref-manifest`, `xref-both-definition`) one at a time: exactly-one pin
      where the property is real, deletion where the scan asserts a name or an
      indentation rather than a property a tree can break. Record each
      disposition in the Decisions section.
- [x] T6: Resolve `tests/filtersrc.py`'s `lines()` — give it its intended
      consumer or delete it with its only current caller's use inlined.
- [x] T7: Narrow each surviving scan's header comment to what it reads, and the
      moved-definition probe's to the one-module case it exercises.
- [x] T8: Full `tests/run-tests.sh --self-test`; capture evidence per criterion.

## Decisions

- 2026-08-23 (T4) — the twelve-scan count pin is deleted, not narrowed. It counted files under the scan directory while claiming to hold the source-reading sites, so a one-for-one swap passed it (M16 review F8). What it noticed is already said twice over: `run_scan` fails on a missing script at every invocation, and a scan file added without an invocation there fails in its `case`. The probe's loop now reports the number of scans it actually ran, derived from the run rather than pinned.
- 2026-08-23 (T5) — `html-identifiers`, `marker-class`, `xref-manifest` and `store-names` are narrowed, not deleted: each pins a filter constant the suite also spells out, which is a disagreement a tree can really produce. Each now counts every anchored `local NAME = "…"` definition in the source set and requires exactly one before comparing the value, so a stale duplicate left behind by a split is reported as a duplicate instead of masking the live definition.
- 2026-08-23 (T5) — `xref-both-definition` is narrowed rather than deleted, at the gate's choice. Its property — the two-target command takes its labels from `\seename`/`\alsoname` rather than hard-coded English — is real and no render distinguishes it, since a hard-coded label prints the same words in an English document. The first-match hole is closed by an exactly-one pin on the assignment; the extent stays the source's own paragraph break, and the header comment now says that is what the scan reads and all it claims.
- 2026-08-23 (T5) — two scans outside the plan's four were disposed on the same rule, at the gate's choice: `latex-escape-table` took its table at the first `split` and now pins that opening to exactly one, and `m15-joined-messages` asked only that each shape of the replacement report exist somewhere and now requires exactly one message to carry each.
- 2026-08-23 (T6) — `filtersrc.py`'s consumerless export is `defining_lines()`, not `lines()`: `lines()` has one caller, the M17-AC3 require-position check. `defining_lines()` is deleted, with the `re` import it alone needed.

## Work log

- 2026-08-23: created by /milestone-plan alongside M24, from the acceptance-suite-hardening candidate row.
- 2026-08-23: plan gate ran the REDUCED criteria audit (internal tier) on M24's criteria; M25's were written against the same three questions and the five findings that audit returned. Two were caught in drafting here: a criterion promising that each scan's disposition is "recorded in the Decisions section" bound a recording act (D-120) and became T5; a criterion promising each scan's header comment states what it asserts bound a checker's own prose (D-118) and became T7.
- 2026-08-23: plan gate chose retiring the source-shape scans over hardening them, because D-004 already refused the same widening for `byte-diff.sh` and M23 found six such gaps by hand that the scans exited 0 on; falsified by a tree-breaking defect that a widened scan catches and no render does.
- 2026-08-23: plan gate chose matching the extension's own message set over prefixing every warning with an identifying token, because the prefix rewrites user-visible text across 20+ messages and collides with the README claim pins and `warn-distinct`'s single-literal needles; falsified by evidence that the literal set cannot be enumerated from source completely enough for a zero-control to rest on.
- 2026-08-23: gate chose (a) narrowing `xref-both-definition` rather than deleting it, (b) converting the two further bare-`(W)` sites the plan's list missed — the book's four-warning total and the range self-test's per-row report count, both spelled `grep -c` — and (c) repairing two more scans AC4's promise reaches, `m15-joined-messages` (presence, not an exact count) and `latex-escape-table` (its table taken at the first `split`), and (d) having `warn-distinct.py` emit ready-made search patterns rather than raw texts the shell would have to widen.
- 2026-08-23: T1-T3. `warn-distinct.py --patterns` writes one extended regular expression per warn() message, placeholders widened (`%d` to digits, others to a wildcard) and everything else quoted for the platform's grep, emitted only after the scan's own assertions pass. `run-tests.sh` generates the set once beside the message constants and adds `check_extension_warning_count`. Nine bare-`(W)` sites converted: the four `check_warning_count … '(W)'` (M23-AC1 x2, M23-AC2 x2), the three `grep -q '^(W)'` controls (M06-AC1 x2, M06-AC2), the book's four-warning total (M05-AC4/M14-AC5) and the M23 self-test's per-row report count. Both AC1 greps return nothing. The AC2 probe plants `$WARN_BOTH` into a copy of the range-nested html log and requires the control to fail naming its count, then plants a foreign filter's `(W)` line and requires it to pass. Suite green, 263 checks.
- 2026-08-23: minor amendment — T2's site list said five and named line numbers M24 had since moved; nine sites in today's tree, enumerated in the line above.
- 2026-08-23: T4. Scan-count pin removed; `SCAN_DIR` named once above `run_scan` and read everywhere else through the variable, so the grep AC3 names returns that one path-construction line. The M16-AC3 loop counts what it probed (12 this run) instead of asserting a pinned 12.
- 2026-08-23: T5. Six scans narrowed to exactly-one pins — `html-identifiers` (4 constants), `marker-class`, `xref-manifest`, `store-names` (2 constants), `xref-both-definition`, `latex-escape-table` — and `m15-joined-messages`'s presence test made exactly-one. No scan deleted; dispositions in Decisions above.
- 2026-08-23: T6. `defining_lines()` deleted from `tests/filtersrc.py` (no caller anywhere) with its `re` import; `lines()` kept, its caller being the M17-AC3 require-position check. Every remaining export has a caller in `git ls-files tests`.
- 2026-08-23: full `--self-test` green, 397 checks. Two earlier runs failed on the environment, not the tree: one Quarto segfault mid-render, one `quarto list tools` network timeout in the TinyTeX probe.
- 2026-08-23: T7. Each of the nine scans carrying the shared four-line header now states what it READS, what it ASSERTS, and what it does not — `warn-distinct` naming the values and out-of-call text it cannot see, `xref-both-definition` naming why no render distinguishes its property, `latex-escape-table` and `xref-manifest` naming the checks that carry what they do not. The three value-readers say they assert one definition and nothing about the value. `movedefs.py` and the M16-AC3 comment now say the probe builds one member of the moved-into-a-module family, every definition into a single `modules/moved.lua`.
- 2026-08-23: T8. `tests/run-tests.sh --self-test` exits 0, "All checks passed (397 checks)." AC1 both greps return nothing; AC3's grep returns one line, `SCAN_DIR="tests/scans"` at run-tests.sh:212; AC4's eleven enumerated sites each assert an exact count, two of them over `examples/demo.qmd` rather than the source set; AC5's five `filtersrc` exports each have a caller. Status to review.
- 2026-08-23: review — PR #25 opened as a draft; all six criteria executed with fresh evidence and ticked; `cairn_validate` exits 0 and the `generic` profile names no toolchain checks. Review section open, findings triage pending the diff-bug lens.

## Review

Fresh evidence, 2026-08-23, on `m25-scan-disposition` at 85e1880, against
`main` at the same merge base (no divergence to merge).

### Acceptance-criterion evidence

- **AC1 — PASS.** Over `git ls-files tests`, `grep -n "check_warning_count[^"']*['"](W)['"]"`
  returns nothing (exit 1), and `grep -n "grep -q '\^(W)'"` returns nothing (exit 1).
  A third, wider grep — every `check_warning_count` line filtered for the string
  `(W)` — also returns nothing, so no call site reaches the helper with that
  pattern by any spelling.
- **AC2 — PASS.** The full `--self-test` run printed, at line 273 of its output,
  `ok M25-AC2: the zero-warning control discriminates both ways`. Both
  directions run against copies of the range-nested HTML render's own log
  (`tests/run-tests.sh:8519-8542`): with one of this extension's own warnings
  appended the control fails *and its message is matched* for "expected 0
  warning(s) from this extension … got 1", so the failure is the count and not
  a missing file; with a foreign filter's `(W)` line appended — checked back by
  its full text first, so the plant is proved to have landed — the control
  passes.
- **AC3 — PASS.** `git ls-files tests | xargs grep -n "tests/scans"` returns one
  line: `tests/run-tests.sh:212: SCAN_DIR="tests/scans"`, which is `run_scan`'s
  own path construction (`local script="$SCAN_DIR/$name.py"`, line 216). Read
  back through the variable, the only other uses are that construction, the
  one-off `warn-distinct.py --patterns` generation at 1651, and the M16-AC3
  `find` at 9794 — which counts nothing: `SCANS_PROBED` is incremented by the
  loop that ran the scans and is reported in the `pass` line, never compared to
  a pinned number.
- **AC4 — PASS.** Grepping `git ls-files tests | grep '^tests/scans/'` for
  `re.search`, `re.match` and `re.findall` enumerates eleven sites in nine
  scans. Nine read the filter source set and each is guarded by an exact count:
  `html-identifiers.py:23-26` (4 constants, `len(found) != 1`),
  `marker-class.py:20-24`, `store-names.py:23-27` (2 constants),
  `max-levels.py:23-27`, `overflow-join.py:23-27`, `store-version.py:23-27`,
  `xref-manifest.py:27-31`, `mark-report-keys.py:45-48` (each key must own
  exactly 1 warning), and `xref-both-definition.py:38`, whose enclosing
  definition is pinned to exactly one at lines 21-25 before it runs. The
  remaining two — `latex-escape-table.py:44` and `:46` — read
  `examples/demo.qmd`, not the source set, so they fall outside the criterion's
  domain; that scan's own source-set read is `src.count(OPENING) != 1` at
  lines 22-25. No scan in the directory searches the source set without an
  exact-count pin, and none was deleted.
- **AC5 — PASS.** `tests/filtersrc.py` exports five functions. `sources()` is
  called from `tests/movedefs.py:119` and `tests/run-tests.sh:116, 8892, 8897,
  8906`; `read()` from `tests/movedefs.py:120`; `text()` from twelve scans under
  `tests/scans/`; `lines()` from `tests/run-tests.sh:9944`; `ext_dir()` from
  `sources()` itself at `tests/filtersrc.py:33`, a caller inside the same file
  set. `defining_lines()`, which had none, is gone with the `re` import it
  alone needed.
- **AC6 — PASS.** `tests/run-tests.sh --self-test` exits 0 and its last line is
  `All checks passed (397 checks).` Run in full at review time, not carried
  over from implementation.

No `Driving RR:` on this milestone, so no projection-versus-outcome pairs.

### Consistency gate

`cairn_validate` exits 0, all 16 checks PASS and all 7 advisories OK. No
`DESIGN.md` principle changed on this branch, so `cairn_impact --changed` is
skipped. The active profile is `generic`, whose `consistency-gate` slot names
no toolchain checks.

### Findings

Three fresh-context lenses (diff-bug [O], blame-history [S], prior-review [S]);
the diff touches executable surface, so the full fan-out ran. The prior-review
lens probed GitHub inline comments (`pulls/comments?per_page=1` returned `[]`)
and fell back to archived `## Review` sections; it reports no prior finding
reintroduced or contradicted, and identifies this branch as the remediation of
M16 F3, M16 F8 and M23 F12. Findings below are the diff-bug lens's ranked list,
with the blame-history lens's one substantive finding folded in as F2 (both
lenses reached it independently). No finding demonstrates an acceptance
criterion failing, so the return floor is not met.

- **F1 — the new exactly-one clause has no discrimination evidence.**
  `tests/plantdefect.py:41-92` plants a changed *value* for every narrowed scan
  and never a *duplicate definition*. Reverting `marker-class.py:20` to
  `re.search` leaves the full `--self-test` green, so the duplicate-masking hole
  M16 F3 named could be reopened unnoticed. Three scans (`store-version`,
  `max-levels`, `overflow-join`) exercise the count clause in the *zero*
  direction via a rename; none exercises the *two* direction.
- **F2 — the M16-AC3 probe can pass over zero scans.**
  `tests/run-tests.sh:9794-9822`: `SCANS_PROBED` is derived from the loop with
  no floor. Empty `tests/scans/` and the run prints `ok M16-AC3: all 0
  source-reading checks…`. The Decisions rationale ("`run_scan` fails on a
  missing script at every invocation") does not reach this, because no
  invocation is left to fail. The suite's own idiom elsewhere is exactly such a
  floor (`[ -s "$QI_WARN_PATTERNS" ]`, `filtersrc.sources()`'s raise,
  `m15-joined-messages`'s `if not messages`).
- **F3 — `cairn/DESIGN.md:47-49` now states something false.** The M17 bracket
  export's stated reason is "the source scans take the FIRST `NAME =` match over
  the whole source set". M25 replaced first-match with anchored exactly-one,
  which `M.NAME = NAME` cannot match at all.
- **F4 — `as_pattern` cannot represent a message concatenated around a runtime
  value.** `tests/scans/warn-distinct.py:182-183` joins a call's literals with
  nothing between them. All 48 current messages concatenate literal-to-literal,
  so today's patterns are right; the first `warn("term " .. name .. " is bad")`
  yields `term  is bad`, matching nothing, and every zero control stops seeing
  that warning. The `blank` guard at line 194 does not catch it.
- **F5 — the generated patterns are not anchored to the `(W) ` prefix.**
  `tests/run-tests.sh:1663` counts any log line containing a message, warning or
  not. Nothing in the repo matches today; the anchor is free.
- **F6 — `FORMAT_SPEC`'s flag class includes a space.**
  `tests/scans/warn-distinct.py:58`: `% o` in "50% of entries" would be read as
  a conversion and widened to `.*`, a wildcard that can swallow another
  message's text. No current message carries a non-format `%`.
- **F7 — AC4's enumeration grep is narrower than the constructs M25 repaired.**
  It reaches `re.search`/`re.match`/`re.findall` but not `re.finditer`,
  `.count(` or `.split(` — so `latex-escape-table`'s `.split` bug (fixed here)
  and `xref-both-definition`'s new `re.finditer` are invisible to it. The two
  live sites the lens named as uncovered were checked and are both exact-count
  pinned: `m15-joined-messages.py:75-86` (exactly one message per shape) and
  `warn-distinct.py:233-238` (`len(owner) != 1`).
- **F8 — AC4 read call-by-call rather than scan-by-scan.**
  `tests/scans/mark-report-keys.py:37` is a `re.findall` over
  `filtersrc.text()` with no count on `calls`. The lens grants the failure
  direction is safe (a shrunken read makes every key match 0 and the scan fails
  loudly) and calls it a conformance gap, not a vacuous pass.
- **F9 — the `--patterns` call bypasses `run_scan`.**
  `tests/run-tests.sh:1651` invokes the scan directly, while `run_scan`'s header
  (199-201) says it is "the one place that says how each is invoked".
- **F10 — the AC2 probe plants the one message with no placeholder.**
  `$WARN_BOTH` carries no `%`, so the widening logic — the only part that can
  over- or under-match — is not what the probe proves. It is exercised
  incidentally by the book's four-warning total.
- **F11 — stale rationale at `tests/run-tests.sh:6511-6513`.** "M06-AC1 and
  M06-AC2 already abort on ANY `^(W)` line there, so such a grep is a tautology"
  — after M25 those two abort only on this extension's messages.
- **F12 — `m15-joined-messages.py:95-97`'s `ok` line states the old, weaker
  promise** ("both shapes … are among them") where the check now requires
  exactly one message to carry each. T7 narrowed the header, not the run log.
- **F13 — the candidate row reads as closing two items M25 did not close.**
  `cairn/ROADMAP.md:16` says M25 absorbs "`warn-distinct`'s `:format(`
  blindness, the one-of-nine moved-definition probe, M17-AC1 unguarded". The
  first is explicitly Out of scope here; the second got a comment only; the
  third got nothing — and none appears in the row's Remainder.
- **F14 — cosmetic.** `tests/scans/store-names.py:31-34` prints "the suite
  expects:" above items formatted `NAME = 'x', filter writes 'y'`; header and
  item no longer read as one sentence.
- **F15 — AC5's evidence rests on an intra-module caller.**
  `filtersrc.ext_dir()` is called only by `sources()` at
  `tests/filtersrc.py:33`.
