<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M076: A store-report leg asserts every wording, not the ones its author recalled

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — assertions inside the repo's own acceptance suite; no consumer of the extension reads them
- **Branch/PR:** m076-store-report-zero-controls / https://github.com/jmgirard/quarto-index/pull/76

## Goal

A leg that asserts which store reports a render drew asserts every store
wording the suite defines — the counts it expects, and zero for the ones it
does not — so a change drawing a wording spuriously is red on the leg that
met it rather than only where a total-warning count happens to sit.

## Scope

**In:** a helper whose domain is the `WARN_STORE_*` family as the shell holds
it at call time, asserting a given count per named wording and zero for the
rest; the conversion of every existing store-wording assertion to it; the two
M074 assertions that cannot fail on what they name — the plant control reading
the unmutated leg's capture, and the line picked by its position in the log;
and the plants that show each of these red.

**Out:** the suite's timing accounting → M077. The docs-site claim ledger's
blindness to a removed sentence → KI249, on the site-checks candidate row. A
source scan over the suite's own text asserting that no old-style store
assertion survives → declined at the plan gate under the standing rule against
widened source-shape scans; the conversion's extent is evidence at review,
not a criterion. Any change to what the Lua filter draws → out entirely; this
milestone changes assertions, never reports.

## Acceptance criteria

- [x] AC1: `tests/run-tests.sh` defines a helper `check_store_reports` whose
      domain is the names `"${!WARN_STORE_@}"` expands to at the moment it is
      called. Given a log, a label, and zero or more `<NAME>=<count>` pairs, it
      asserts that count for each named wording and a count of 0 for every name
      in the domain it was not given. It fails when the domain is empty, and
      fails when it is handed a name the domain does not hold.
- [x] AC2: `check_warning_names_nth` selects the line it asserts on by a
      caller-given content key rather than by that line's position among the
      grep matches, and is shown to pass on a log whose two matching lines have
      been swapped and to fail on one whose names are wrong.
- [x] AC3: under `--self-test`, `check_store_reports` is shown red on a crafted
      log carrying a store wording the call does not name, red on a crafted log
      whose named wording's count is wrong, and red on a call naming a wording
      its domain does not hold — and green on that same crafted log with none
      of the three planted.
- [x] AC4: under `--self-test`, a mutation of the Lua filter that makes one
      named store wording be drawn on a chapter that should not draw it turns
      the suite red on the leg that meets that chapter, and the failure names
      that wording — a leg whose assertions said nothing about that wording
      before this milestone's conversion.
- [x] AC5: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` each
      exit 0.

## Coverage

- AC1 → T1
- AC2 → T4
- AC3 → T5
- AC4 → T2, T5
- AC5 → T3, T7

## Tasks

- [x] T1: Write `check_store_reports` beside `check_warning_count`
      (`tests/run-tests.sh:2053`). Its domain is `"${!WARN_STORE_@}"` — ten
      names today, defined at `:928-973`. Count occurrences inline rather than
      delegating to `check_warning_count`, so the family is reachable from one
      place and the wording variables are named nowhere else.
- [x] T2: Convert the store-wording assertions to it — 179 of the 630 possible
      (log, wording) pairs are asserted today, across 63 captured logs —
      one `check_store_reports` call per log, each leg's existing expectations
      carried over unchanged. Record the pre-conversion figures in the work log.
- [x] T3: Run the plain suite and settle every leg the conversion turns red.
      Each is one of two things: an expectation that was wrong, or a report the
      filter draws that nothing was asserting. Write the second kind up as a
      Known-issues entry rather than silencing it, and say in the work log
      which each was.
- [x] T4: Key `check_warning_names_nth` (`:2106`) on a caller-given content key
      instead of the ordinal, update its call sites, and rewrite the header
      comment that states the log-order assumption.
- [x] T5: Plants under `--self-test`. Three crafted-log cases for
      `check_store_reports` and the unplanted control beside them; the swap and
      wrong-names cases for `check_warning_names_nth`; and one Lua mutation
      drawing a store wording on a chapter that should not draw it, chosen so
      the leg meeting it asserted nothing about that wording before T2.
- [x] T6: Repoint the M074 plant-2 page control (`:25585`) from
      `$CAPTURE_ROOT/m069-m069-index` to the capture its own mutated render
      takes, `$CAPTURE_ROOT/m069-m074-inline` (`m069_mutant_chapter`, `:9387`),
      and restate the label that currently says it reads the unmutated leg's.
- [x] T7: Full `tests/run-tests.sh --self-test` green; record the check count
      and the post-conversion pair figure.

## Work log

- 2026-09-04: created by /milestone-plan.
- 2026-09-04: criteria audit ran in reduced mode (internal tier) on a fresh [O] reader that authored none of the criteria; three rounds. Round 1 returned five findings, each with one clear repair, all fixed before the gate: a hand-list of 63 legs standing in for a procedure, a leg-count floor binding an instrument, a plant's own property bound as a criterion, discrimination demonstrated across a render subprocess where a crafted log settles it in-process, and a DESIGN.md recording act as a promise. Round 2 over the rewritten set returned one, fixed: a trailing clause quantifying over all store assertions where the named grep sees only `check_warning_count` calls, 16 `check_warning_names` and 2 `check_warning_names_nth` calls also naming a store wording. Round 3 over AC4, added after round 2, returned nothing.
- 2026-09-04: plan gate chose enumerating the wording family by shell prefix expansion (`"${!WARN_STORE_@}"`, ten names today) over a list written into the helper, because a written list is fixed by what its author recalled and a tenth wording added later would ship zero-controlled nowhere; falsified by a store report whose key cannot carry the `WARN_STORE_` prefix.
- 2026-09-04: plan gate chose leaving the conversion's extent to the diff at review over a grep asserting that no old-style `check_warning_count` call on a store wording survives, because D-011 refuses widened source-shape scans and D-029 reads it as covering the suite's own source; the user declined to supersede it. Falsified by a leg added after this milestone that bypasses the helper and ships with no zero controls.
- 2026-09-04: plan gate chose sweeping all 63 logs over sweeping only the 33 that carry no `check_extension_warning_count`, because a total says how many reports a render drew and never which wording; falsified by the conversion's cost on the 30 already totalled exceeding what it turns up there.
- 2026-09-04: branch `m076-store-report-zero-controls` cut from the default branch; status in-progress.
- 2026-09-04: implement gate chose spelling each report's full variable name at the call site (`WARN_STORE_STALE_RECOVERED=1`) over a short suffix, because the text at the call site is then the name the domain holds and a typo is caught as an unknown name rather than swept as a zero; falsified by a wording whose full name will not fit a call site's line. Same gate chose one merged label per log over a note beside each expected count, the helper's own failure message naming the offending wording and both counts; falsified by a merged label that no longer says which leg it is about.
- 2026-09-04: T1 checkpoint, half-done: `check_store_reports` written at `tests/run-tests.sh:2079`, its domain read from `${!WARN_STORE_@}` at call time. Its four behaviors shown in a scratch harness over crafted logs — green with nothing named, red on a wording present that the call did not name, red on a wrong count, red on a name the domain does not hold, red on an emptied domain. The plain-suite verify is still running, so T1 is not ticked.

- 2026-09-04: T1 done — plain suite green, 701 checks, exit 0.
- 2026-09-04: T2 checkpoint, half-done: the conversion applied by a script that re-reads the call sites out of the suite's own source, groups them one per render (a group breaks where a line between two same-log calls redirects a render into that log, which is what separates the two functions that both write `$WORK/place-$slug.log` and the two that both write `$WORK/m068-nested-$slug.log`), and merges each group's labels — distinct criterion prefixes joined, then the distinct reasons from each label's first parenthesis. Pre-conversion figures, measured on the branch: 220 `check_warning_count` calls named a store wording, over 78 distinct log-path expressions; 16 `check_warning_names` and 2 `check_warning_names_nth` calls also named one and are unchanged, asserting membership rather than a count. After: 80 `check_store_reports` calls, none of the 10 wordings unasserted on any of them, and no `check_warning_count` call naming a store wording remains. `tests/run-tests.sh` 25,884 to 25,629 lines. T3's settling run is still going, so T2 is not ticked.

- 2026-09-04: T3 checkpoint, half-done. To settle the red legs in one pass rather than one 8-minute run each, `check_store_reports` was temporarily given a survey mode that records a mismatch instead of failing; the plain run then completed (767 checks) and reported seven mismatches over five renders. All seven were the second kind — a report the filter draws that nothing was asserting — and none was a filter defect, so none is written up as a Known issue: in every case the fixture's own setup makes the report follow, and a sibling leg doing the same thing already asserted it. `m063-m064-conditional` and `m063-m064-nomarks` block four.qmd's record path, so four.qmd's own write meets the block and draws the unwritable wording once. `m063-m068-dangling` (both renders) draws the recovery wording four times, asserted until now only inside the whole-message literal `M068_RECOVERED_FOUR`. `book-nostore` replaces the store directory with a file, so all three chapters are recovered by the two others and all three writes fail; both figures now derive from the fixture's chapter count. `m068-nested-unlistable` had two calls reaching one log through two spellings of its path — `$WORK/m068-nested-$slug.log` inside `m068_nested_render` and `$WORK/m068-nested-unlistable.log` beside it — whose sweeps denied each other; the write count is now a parameter of that function and the second call is gone. The `--self-test` survey, which covers the plant-only legs the plain run never reaches, is still running.

- 2026-09-04: T3, second half. The `--self-test` survey completed (1390 checks) and reported eight more mismatches over seven renders, all in plant-only legs the plain run never reaches, and again all the second kind with no filter defect among them: `m063-m065-noprobe` disables the store probe but leaves the store directory a file, so all five writes still fail; `m073-collapsed` recovers the three chapters whose sources read; the four `m070` plants each draw the cold book's own never-written or refusal line, which the unplanted leg draws too; and `m068-nested-lostchain` recovers two chapters and fails one write, so `m068_nested_silent` takes those two counts as parameters the way `m068_nested_render` now does. The `m063-m065-noprobe` pass line said "no report is drawn", which the write failures make false; it now says no chapter is reported as recovered. Survey mode removed.
- 2026-09-04: T4 done. `check_warning_names_nth` picks its line by the two chapter lists the caller already passes — the one line naming every chapter in `named` and none in `not named` — and refuses an empty exclusion list, zero matching lines, and two or more. The ordinal argument is gone from the signature and from both call sites. A literal content key was not available: the one call site's second line names a strict subset of the first's chapters, so no string picks it out. The name is unchanged, which AC2 refers to it by; the header comment now says so.
- 2026-09-04: T6 done. The M074 plant-2 page control reads `$CAPTURE_ROOT/m069-m074-inline`, the capture its own mutated render took, rather than `$CAPTURE_ROOT/m069-m069-index`, the unmutated leg's; its label says which render it reads and why the page is read back at all.

- 2026-09-04: T3 done — plain suite green, 766 checks, exit 0.
- 2026-09-04: T5 written. Six cases for the two helpers over crafted logs, beside the one Lua mutation. `check_store_reports` is shown red on a wording the call does not name, on a named wording's wrong count, on a name the family does not hold and on an emptied family, each checked back by the text of its own failure rather than by a bare non-zero exit, and green on the same log with none of them planted. `check_warning_names_nth` is shown green on the placement fixture's own two lines written in the other order and red on a copy naming a chapter the report never covers. The AC4 mutation takes `.qmd` out of the set of source kinds the recovery route reads, so a chapter reading a store no render has written refuses the four behind it: the leg's warning total is asserted green under the mutation, and the leg's own store-report expectation red and naming the refusal wording — a wording nothing on that leg asserted before the conversion, checked against the pre-conversion file at commit 2e70197. Full `--self-test` run in progress.

- 2026-09-04: T5 done and T7 done — `tests/run-tests.sh --self-test` green, 1397 checks, exit 0; `tests/run-tests.sh` green, 766 checks, exit 0. `cairn_validate` all PASS. The AC4 plant landed as designed: under the mutation the leg's `check_extension_warning_count` of 2 is green — one report became one other report — while the leg's own store-report expectation is red on `WARN_STORE_KIND_REFUSED`.
- 2026-09-04: figures. Before, at commit 2e70197: 220 `check_warning_count` calls named a store wording, covering 214 distinct (log, wording) pairs of the 780 that 78 log-path expressions and 10 wordings allow. After: 80 `check_store_reports` calls over renders, each asserting all 10 wordings, so all 800 pairs of its 80 logs are asserted — two of the 78 expressions are function-local spellings whose calls the conversion split by render, which is where the extra pair of logs comes from. An 81st call is the AC3 control over a crafted log. `tests/run-tests.sh` 25,884 to 25,834 lines.
- 2026-09-04: review — PR #76 opened as a draft; both suites green on the branch head (766 and 1397 checks, exit 0), cairn_validate all PASS, three fresh-context reviewers spawned. The [O] lens returned eight findings, the two Sonnet lenses none: F1, F2, F3, F5 and F6/F8 fixed on the branch (a log-not-a-file guard, a `set -e` abort with no FAIL line, the AC4 plant re-typing the leg's expectation instead of expanding it, a convention slip and four labels), F4 and F7 rejected with reasons logged. Both suites re-run green on the fixed tree at the same check counts. No finding reached the return floor.
- 2026-09-04: step-7 approval: PR #76 approved for merge.

## Decisions

## Review

Verified 2026-09-04 on branch `m076-store-report-zero-controls`, PR #76,
against the tree that carries the fix-now commit below. Both suite runs are
from that tree: `tests/run-tests.sh` green, 766 checks, exit 0;
`tests/run-tests.sh --self-test` green, 1397 checks, exit 0.

**AC1 — met.** `check_store_reports` is defined at `tests/run-tests.sh:2079`.
Its domain is `local -a domain=( ${!WARN_STORE_@} )` read at the call
(`:2082`), never a written list; the shell holds ten such names today. For
each `<NAME>=<count>` pair it asserts that count and for every other name in
the domain it asserts 0, counting occurrences (`grep -oF | wc -l`) rather than
matching lines. It refuses an empty domain (`:2087`), a name the domain does
not hold (`:2098-2105`), and — added at this review, F1 below — a `logfile`
that is not a file (`:2093`). All five refusals are shown red under
`--self-test`; see AC3.

**AC2 — met.** `check_warning_names_nth` (`:2186`) picks its line by the two
chapter lists the caller already passes — the one line of `total` naming every
chapter in `named` and none in `not named` — and refuses zero or two or more
qualifying lines. The ordinal argument is gone from the signature and from
both call sites; `git diff main..HEAD` shows no surviving caller passing one.
Under `--self-test` (`:7056-7111`) both calls pass on `m076-swapped.log`, the
render's own two lines written in the other order, with the swap guarded by a
line count of 2 and a `cmp` against the render's order; and the helper is red
on `m076-wrongnames.log`, failing with `none of the 2 line(s) carrying`. Log
lines, verbatim: `ok   M076-AC2: the line each call asserts on is picked by
the chapters it must and must not name — the same two lines in the other
order are read the same way, a log naming a chapter the report never covers is
red, and a log carrying no such line at all is red rather than a silent abort`.

**AC3 — met.** `--self-test` block at `:6979-7054`. The control passes on
`m076-crafted.log` with nothing planted: `ok   M076-AC3 control (the crafted
log with none of the three defects planted): the store reports in
tests/.work/m076-crafted.log are exactly WARN_STORE_STALE_RECOVERED=2, with
every other wording of the 10 held at zero`. The three cases the criterion
names are each red, and each checked back by the text of its own failure
rather than a bare non-zero exit — a wording the call does not name (a
`WARN_STORE_KIND_REFUSED` line appended to a copy), a named wording's wrong
count, and a call naming `WARN_STORE_NO_SUCH_WORDING`. Two further refusals
ride the same block: the emptied family, and (added at this review) a log that
is not there. Summary line: `ok   M076-AC3: the store-report sweep is red on a
wording the call does not name, on a named wording's wrong count, on a name
the family does not hold, on an emptied family and on a log that is not there,
naming the defect in each — and green on the same log with none of them
planted`.

**AC4 — met.** `--self-test` block at `:25609-25651`. The mutation removes
`[".qmd"] = true` from the set of source kinds the recovery route reads, so
index.qmd — reading a store no render has written — refuses the four chapters
behind it instead of recovering them. Two assertions bracket it. The leg's
warning total is unmoved: `check_extension_warning_count … 2` is green under
the mutation, one report having become one other report. The leg's own
store-report expectation — `WARN_STORE_NEVER_RECOVERED=1` and every other
wording at zero, taken from the leg's own `M069_INDEX_STORE_REPORTS` (`:9319`)
rather than typed out again at the plant, per F3 below — is red, and red by
counting the wording the mutation drew —
the `case` guard requires the failure text to read `expected 0 occurrence(s)
of the WARN_STORE_KIND_REFUSED report … got 1`. That the leg said nothing
about that wording before the conversion is checked against the default branch
rather than recalled: `git show main:tests/run-tests.sh` has the m069-index
leg asserting `WARN_STORE_NEVER_RECOVERED` 1 and three could-not-be-read
wordings at 0 (`:9219-9229`), and `WARN_STORE_KIND_REFUSED` among neither.

**AC5 — met.** Both runs on the reviewed tree: `tests/run-tests.sh` →
`All checks passed (766 checks).`, exit 0; `tests/run-tests.sh --self-test` →
`All checks passed (1397 checks).`, exit 0. Run sequentially, never
concurrently. The same pair was green on the branch head before the fix-now
commit, at the same check counts. One word of one comment inside
`check_store_reports` changed after that run (a free-standing count dropped
from the F1 guard's comment); `bash -n` is clean and no executable line moved.

**Conversion extent** (the plan gate left this to the diff rather than to a
grep). Measured on the reviewed tree against `main`, joining backslash
continuations first: `main` carries 220 `check_warning_count` calls naming a
`WARN_STORE_*` wording; the branch carries 0. The [O] reviewer re-derived the
conversion mechanically — every one of the 220 old expectations extracted as a
(log path, wording, count) triple and diffed against the 81 new calls, an
absent wording read as 0 — and found every one carried over unchanged, with
the only deltas the three the work log records: the `place-$slug.log` group
split across `place_stale`/`place_undeclared`, the `m068-nested-unlistable`
call folded into `m068_nested_render`'s new parameter, and the 13 newly
non-zero expectations the T3 survey turned up. No two of the new calls sweep
one log and deny each other.

### Consistency gate

`cairn_validate.py` — all 16 checks PASS, 7 advisories OK, exit 0; the
`release window` advisory did not fire. Coverage completeness is one of those
checks and passes. `cairn_impact.py` not run: `Principles touched:` is `—`.
Toolchain checks: the `generic` profile's `consistency-gate` slot names none,
so that half is a clean no-op. `bash -n tests/run-tests.sh` clean.

### Independent review

Three fresh-context reviewers, none having seen the implementation, each on a
distinct evidence base. The diff touches executable surface
(`tests/run-tests.sh`), so the full fan-out ran rather than the internal-tier
single-reviewer route.

**[S] prior-review lens — zero findings.** Read the archived `## Review`
sections of M062, M066, M073, M074, M075 and `LESSONS.md`, and checked the
diff against each; the GitHub inline-comment probe returned `[]`, so the
per-PR thread walk was skipped. It reports the diff consistent with, not
regressing, the prior findings it names (M62's occurrences-not-lines rule,
M37's suspended-errexit-in-a-subshell lesson, M38/M073's stale-message lesson,
M39's bare `warn(` token, M074's `unnamed`-list semantics).

**[S] blame-history lens — no regressions.** It traced every non-zero count it
could follow out of the 220 removed calls into the new ones and found each
preserved, and confirmed the wording family is the ten D-052 settled. It
raised the T6 capture retarget and the `book-nostore` formula as the diff's
two non-mechanical changes, both scoped and logged by the milestone, and asked
for a human eye on `ORDER_CHAPTERS * (ORDER_CHAPTERS - 1)` (`:10376`). Checked:
the ordering fixture has three chapters, the fixture floor at `:10201` refuses
fewer than three, and the derived 6 and 3 are green on the run above.

**[O] diff-bug lens — eight findings, ranked.** Triage below; every one is
logged, actioned or rejected.

- **F1 — `check_store_reports` passes vacuously on a log path that is not
  there** (`:2079`). `grep … || true` swallows the missing-file exit, so `got`
  is 0 for every wording; 24 of the 88 call sites pass no `<NAME>=<count>` pair
  at all and assert nothing but zeros, so a mistyped or since-renamed path is
  green and prints an `ok` line. **Fixed now**: a `[ -f "$logfile" ]` guard at
  `:2093`, and a fifth `--self-test` case showing the sweep red on an absent
  log and red by naming the path. The plain run stayed at 766 checks with the
  guard in, so no existing call site was reading a log that is not there.
- **F2 — `check_warning_names_nth` could abort the run with no FAIL line**
  (`:2215`). Called with a `total` of 0 on a log with no matching line, the
  bare diagnostic `grep` exits 1 and `set -e` ends the run before either
  `fail` — the failure mode the suite forbids at `:13231` (M14). No call site
  passes 0. **Fixed now**: `|| true` on the diagnostic grep, `if` in place of
  `[ … ] && fail` (which also settles F5), and an AC2 case showing the branch
  reporting a FAIL rather than aborting.
- **F3 — the AC4 plant re-typed the leg's expectation instead of using it**
  (`:25643`). The probe hand-wrote `WARN_STORE_NEVER_RECOVERED=1`; nothing tied
  that literal to the m069-index leg's own call, so changing the leg would
  leave the plant passing while its pass line went on claiming the leg is
  protected. **Fixed now**: the leg holds its expectation in
  `M069_INDEX_STORE_REPORTS` (`:9319`) and the plant expands the same array,
  with a non-empty guard beside it. This is the milestone's own thesis applied
  to the milestone's own plant.
- **F4 — two `case` guards depend on the alphabetical order of
  `${!WARN_STORE_@}`** (`:7006`, `:25647`). Both require the failure text to
  name `WARN_STORE_KIND_REFUSED`, which holds because that name sorts first
  among the mismatching ones and the helper fails on the first mismatch.
  **Rejected, logged**: renaming a wording would turn the plants red on their
  "failed, but not by counting that wording" branch — loud, not silent — and
  a rename is a change that has to revisit these plants anyway. Pinning the
  order would assert the shell's sort rather than the report.
- **F5 — `[ … ] && fail` against the suite's own written convention**
  (`:2216`). **Fixed now**, folded into F2's rewrite.
- **F6 — the label-merging script left duplicated criterion prefixes**
  (`:9436`, `:24113`, `:24149`) and a doubled `$label` (`:7196`). Cosmetic, but
  they print on every green run and one sits inside a parameterized helper.
  **Fixed now**: four labels corrected; a scan for any other repeated prefix
  inside a merged label found none.
- **F7 — unquoted array assignment with no shellcheck annotation** (`:2082`,
  `local -a domain=( ${!WARN_STORE_@} )`). **Rejected, logged**: the split is
  the point and is what the plan gate chose; shell identifiers cannot split
  under the default IFS, and the file's `shellcheck disable=` comments sit on
  splits that are not self-evident.
- **F8 — stray extra blank line** after the AC4 block. **Fixed now.**

None of the eight demonstrates an acceptance criterion failing, and none is a
defect in what the extension does for its users, so the return floor is not
reached and the milestone stays in review. Five were actioned as fixes, three
of which (F1, F2, F3) are load-bearing: each was a check that could not fail on
the thing it claimed to check.
