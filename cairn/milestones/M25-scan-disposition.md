# M25: A check that cannot hold its promise is retired, not widened

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M24
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m25-scan-disposition`

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

- [ ] AC1: Over the file set `git ls-files tests` enumerates, no check asserts
      a warning count or a warning absence with a pattern that matches every
      `(W)` line: greps for `check_warning_count` calls whose pattern argument
      is `(W)`, and for `grep -q '^(W)'`, both return nothing.
- [ ] AC2: A zero-warning control in the suite fails when this extension emits
      a warning during that render, and passes when a warning emitted by
      another filter is the only one present.
- [ ] AC3: Nothing under the file set `git ls-files tests` enumerates asserts a
      count of the files under `tests/scans/`; the grep for `tests/scans` in
      that set returns only `run_scan`'s own path construction and the scan
      invocations.
- [ ] AC4: Over `git ls-files tests`, every scan in `tests/scans/` that
      searches the filter source set asserts an exact match count for what it
      finds, or no longer exists — enumerated by grepping those files for
      `re.search`, `re.match` and `re.findall` over `filtersrc`'s source set.
- [ ] AC5: `tests/filtersrc.py` exports no function without a caller in the set
      `git ls-files tests` enumerates.
- [ ] AC6: `tests/run-tests.sh --self-test` exits 0 and prints its
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
- [ ] T7: Narrow each surviving scan's header comment to what it reads, and the
      moved-definition probe's to the one-module case it exercises.
- [ ] T8: Full `tests/run-tests.sh --self-test`; capture evidence per criterion.

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
