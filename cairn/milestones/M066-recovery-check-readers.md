<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M066: The recovery-route checks read the reports and mutations they name

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** m066-recovery-check-readers · https://github.com/jmgirard/quarto-index/pull/66

## Goal

The checks fencing M064/M065's source-recovery route read every record
wording their own labels claim, prove each substitution they splice, and hold
the recovery prose the books page states.

## Scope

Surface tier: **internal** — the deliverable is the acceptance suite's own
readers over repo-internal artifacts (its captured logs, its spliced filter
trees, a tracked site page); no external consumer of this repo relies on them.

**In:** three read-repairs, all reached from `tests/run-tests.sh`. Each leaves
what its check promises unchanged and repairs what the check reads, which is
the disposition D-011 records for M24's own read-repair.

1. The negative record-report assertions read two of a family's three
   wordings. The six `WARN_STORE_*` constants at `tests/run-tests.sh:871-876`
   are three per family (recovered / parsed-with-no-mark / source-also-lost),
   alternatives on one branch (`modules/book.lua:836-840`, `:1294-1298`). 20
   sites assert the recovered and lost wordings absent and never the
   no-marks wording between them, so a defect emitting only that third
   wording keeps every one of them green. Three sites already read all three
   (`:7649`, `:7719`, `:7774`) and are the model.
2. `m061_mutant` (`tests/run-tests.sh:6796-6804`) applies a whole perl
   expression in one pass and guards it with one whole-file `cmp -s`, while
   its comment states the promise in the singular. The `m065-carryrange` site
   (`:7993-7995`) passes two substitutions against whitespace-exact lines; if
   either slips the file still differs and the guard still passes. That site's
   assertion is an invariance (`M065-AC4 self-test (the section does not
   move)`), so a half-applied mutation produces exactly the expected output
   and the self-test proves nothing.
3. The books-page claim list (`tests/run-tests.sh:20327-20336`) stops at M063,
   so the ~50 lines M064 and M065 added at `site/books.qmd:84-135` — the
   route, the not-returned bullets, the absent-record exclusion, the
   store-directory case — are held by no reader.

**Out:**
- The recovered sort key's declared-vs-resolved discrimination — no
  arrangement of today's fixtures separates the two shapes, since `Zephyr`'s
  declared `sort="Abacus"` is also its resolved key; discriminating needs a
  recovered chapter marking a printed path another chapter also sorts, and a
  reader of the record's `sorts` field, which no check has. Promise-changing
  → the promise-changing suite row in `## Candidates`.
- The editor-metadata readers (KI121, KI122, KI124, KI125) → M067.
- KI117, KI119(c), KI120 → the outstanding reads-repairs candidate row.
- KI24, KI119(a)(b), KI164, KI123 → the promise-changing suite row.

## Acceptance criteria

- [x] AC1. Every `check_warning_count` site in `tests/run-tests.sh` that
      asserts a literal 0 occurrences of one of the six `WARN_STORE_*`
      record-report wordings defined at `tests/run-tests.sh:871-876` has,
      within the same enclosing shell function and against the same log-path
      expression, a `check_warning_count` site for each of the other two
      wordings of that constant's family, each asserting a literal count; the
      domain is the sites that
      `grep -n -A1 'check_warning_count "' tests/run-tests.sh` lists.
- [x] AC2. `m061_mutant` fails, naming the substitution that matched nothing,
      when any one substitution in its expression matches nothing — including
      at the `m065-carryrange` site (`tests/run-tests.sh:7993`), whose two
      substitutions it counts separately rather than through one whole-file
      `cmp`.
- [x] AC3. The claims `tests/sitecheck.py claims` holds `site/books.qmd` to
      cover each of the four prose blocks M064 and M065 added at
      `site/books.qmd:84-135` — the recovery route, the "not returned"
      bullets, the absent-record exclusion, and the store-directory case.
- [x] AC4. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` each
      exit 0.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T5, T6
- AC4 → T7

## Tasks

- [x] T1. Enumerate the domain with
      `grep -n -A1 'check_warning_count "' tests/run-tests.sh`, and record in
      the work log how many sites assert a literal 0 of a `WARN_STORE_*`
      wording and how many of those read fewer than their family's three.
      The count is the floor the repair is measured against, taken before any
      edit.
- [x] T2. Complete every short site to all three wordings of its family, on
      the model of `:7649`, `:7719`, `:7774`, extending each label tail to
      name the wording added. Re-run the enumeration and show no site short.
- [x] T3. Make `m061_mutant` count substitutions rather than compare files:
      have `perl` report the number of substitutions it applied per
      expression and fail naming the one that applied none, keeping the
      existing whole-file guard only as a backstop.
- [x] T4. Plant each of `m065-carryrange`'s two substitutions slipped on its
      own — one at a time, the other left intact — and show the guard red for
      each; assert the message names the slipped substitution. This is the
      case a whole-file `cmp` cannot see.
- [x] T5. Add claim rows covering the four prose blocks at
      `site/books.qmd:84-135`, choosing sentences that state the behavior
      rather than its wrapping (the M41 lesson on flattening).
- [x] T6. Update the count-coupled failure string in the claims self-test
      (`tests/run-tests.sh:20404`, `does not state 1 of the 9 claim(s)`) to
      the new row count, and re-run that self-test.
- [x] T7. Run `tests/run-tests.sh` and `tests/run-tests.sh --self-test`
      sequentially (PROFILE: never two invocations at once) and record both
      check counts and exit codes.

## Work log

- 2026-08-31: created by /milestone-plan.
- 2026-08-31: plan gate chose completing each short assertion site in place over replacing the 20 sites with one helper asserting a family at a time, because the helper would change every label's wording and so what each check reports, where the finding is only that a read is short; falsified by the completed sites proving unmaintainable as the wording set grows.
- 2026-08-31: plan gate chose counting per-substitution matches in `m061_mutant` over splitting each multi-substitution call into separate single-substitution mutants, because only one of 14 call sites passes two and splitting it would double a render; falsified by a later mutant needing substitutions that are only valid applied together.
- 2026-08-31: criteria audit ran in REDUCED mode (internal tier, no RB-tripwire tag) over the four drafted criteria in a fresh-context [O] reader. It returned two findings, both fixed before writing: AC1's named procedure did not make its quantified sub-domain decidable (217 of the 302 `check_warning_count` lines end in a `\` continuation, putting the pattern and count on the next line), repaired to `grep -n -A1` plus "a literal 0"; and AC3 bound a row-count floor on `check_claims`' hand-written fixture, an instrument property, repaired to the coverage the check holds, with the block range corrected to `84-135`.
- 2026-09-01: T1 enumeration, before any edit: 298 `check_warning_count` sites; 72 assert a `WARN_STORE_*` wording at some count; 56 assert one at a literal 0; 48 of those 56 sit on a log where their family is read short of its three wordings, in 27 (log, family) groups. Read with a parser that joins each site's `\` continuation line, which the first pass missed (the pattern sits on the next line at 217 sites). Note for the AC1 wording: the plan's model sites (`:7719`) hold one wording of the family at 1 and the other two at 0, so `a literal 0 of the other two` cannot be met where a wording is drawn; amendment raised at the mini gate below.
- 2026-09-01: T2 edit landed: 31 assertion sites added across the 27 short groups (the no-marks wording at 0 on 26 of them, the lost wording at 0 on 4, `place-$slug` being two groups in two functions sharing one log name), each label extending its neighbour's tail to name the wording added; the enumeration re-run reads 87 literal-0 sites and 0 short. Box left unticked until T7's runs are clean, the suite being edited between runs (PROFILE: never edit it mid-run).
- 2026-09-01: T3 edit landed: `m061_mutant` takes `<slug> <label> <substitution>...`, one perl process applying each argument in turn and writing its match count to `$M061W/<slug>-counts`; a count of 0 fails naming the substitution's ordinal and its first 72 characters, a count file short of the arguments fails, and the whole-file `cmp` stays as a backstop. The 12 callers reorder to label-then-expression; the `m065-carryrange` site's two substitutions become `M065_CARRYRANGE_CARRY` and `M065_CARRYRANGE_PAIR`. Isolated bash run over a five-line stand-in filter: intact counts 1 and 1; the carry slipped names substitution 1 of 2 with the spliced file still differing from the original; the pair slipped names 2 of 2; both slipped names 1; a non-compiling expression fails behind perl's own message.
- 2026-09-01: T4 edit landed: `m066_slipped` in the M065 self-test block runs `m061_mutant` in a subshell with each carryrange substitution slipped (a `;` for the `,` the pattern anchors on) and the other intact, holding the exit non-zero, the message to name that ordinal, and the spliced file to differ from the original, so the case caught is the half-applied one.
- 2026-09-01: T5/T6 edits landed: nine rows added to `books-claims.txt` (the recovery route; the no-marks report; what comes back; no fragment; conditional content out whole; no range and no principal; an absent record is not recovered; an unlistable store directory; a store that still lists), the call's FAIL text and the rows' comment extended to say so, and the count-coupled self-test string moved from 9 to 18; `python3 tests/sitecheck.py claims site/books.qmd` over the extracted rows states all 18, exit 0. Correction to the T2 line: 27 no-marks sites were added, not 26 (27 + 4 = 31). Boxes T2-T6 stay unticked until T7's two runs are clean.
- 2026-09-01: substantive amendment, mini gate, user adopted the recommended option: AC1's "asserts, on that same log, a literal 0 occurrences of the other two wordings" becomes "has, within the same enclosing shell function and against the same log-path expression, a `check_warning_count` site for each of the other two wordings of that constant's family, each asserting a literal count". Reason: the plan's model sites hold one wording of the family at 1 where the log draws it, so a literal 0 of the other two was unsatisfiable there. Fresh-context [O] reader ran the REDUCED audit over the proposed wording before it was written: one finding (bounded promise: "on that same log" was undecidable from the named grep where two functions share one log-path text, `$WORK/place-$slug.log`), repaired by the function-and-expression clause above; proportionality and instrument clear.
- 2026-09-01: T7: `tests/run-tests.sh` 578 checks exit 0; `tests/run-tests.sh --self-test` 1071 checks exit 0 (1069 before M066: the two `m066_slipped` cases), run sequentially, the second starting after the first ended. Both `M066-AC2 self-test` lines print, each naming its slipped ordinal with the filter still differing; the books-page plant is red on `1 of the 18 claim(s)`. T2-T7 ticked on these runs; status to review.

## Decisions

## Review

- 2026-09-01: sync — `origin/main` unmoved since the branch was cut (no commits in `HEAD..origin/main`); branch pushed; draft PR #66 opened.
- AC1 — VERIFIED. A parser over `grep -n -A1 'check_warning_count "' tests/run-tests.sh` (joining each site's `\` continuation, resolving the enclosing `name() {` function and the log-path argument): 329 sites listed; 108 assert a `WARN_STORE_*` wording; 87 assert one at a literal 0; 0 of those 87 lack, in the same function against the same log-path expression, a literal-count site for each of the other two wordings of the family.
- AC2 — VERIFIED. `m061_mutant` extracted verbatim into a scratch script (a stub `m063_tree` copying `_extensions/index/modules/book.lua`, a stub `fail`) and run over the suite's own `M065_CARRYRANGE_*` and `M066_*_SLIPPED` expressions: intact exits 0 with counts 1 and 1; the carry slipped exits 1 naming "substitution 1 of 2 … matched nothing" and the pair slipped names "substitution 2 of 2", each with the spliced file still differing from the original (the half-applied case a whole-file `cmp` passes); both slipped names 1; a single expression matching nothing names "1 of 1". Counts file per run reads the per-substitution match counts.
- AC3 — VERIFIED. The 18 rows extracted from the `books-claims.txt` heredoc (`tests/run-tests.sh:20456-20473`) run through `python3 tests/sitecheck.py claims site/books.qmd` state all 18, exit 0; mapped onto the page, the nine M066 rows land 2 on the route block (84-90), 4 on the "what comes back / not returned" block (92-121), 1 on the absent-record block (123-125), 2 on the store-directory block (127-135) — each of the four blocks held by at least one row.
- AC4 — VERIFIED. Fresh runs, sequential (the second started after the first exited): `tests/run-tests.sh` 578 checks, exit 0; `tests/run-tests.sh --self-test` 1071 checks, exit 0, both `M066-AC2 self-test` lines printing with their slipped ordinal named and the filter still differing.
- Consistency gate: `cairn_validate.py` exit 0, all checks passed (advisories OK, `release window` not fired); no `DESIGN.md` principle changed by the diff (only `tests/run-tests.sh` and tracking files), so `cairn_impact.py --changed` skipped; profile `generic` names no toolchain checks.
- Lenses: [O] diff-bug 15 findings; [S] blame-history none (all 12 `m061_mutant` callers reordered, no prior distinction lost, D-011/D-041-D-043 read); [S] prior-review none contradicted (archived `## Review` sections M061-M065/M24/M36-M46 and LESSONS read; `gh api pulls/comments?per_page=1` returns `[]`, so no thread walk). Findings, ranked as reported, disposition settled at the gate:
  - F1 (fix now). Two of the five "not returned" bullets — the include/executed-cell bullet and the unreadable-source bullet — are held by no claim row; confirmed: deleting the include bullet from a copy of the page and re-running `sitecheck.py claims` over the 18 rows exits 0. AC3 as written is block-level and stands; this is a gap inside the block's coverage.
  - F2 (fix now). The "Five things recovery does not return." lead and the `entry=`/`sort=`/`see=` sentence are unheld.
  - F3 (fix now). The `what comes back` row pins the paragraph's topic sentence rather than a behavior sentence (T5's own instruction).
  - F4 (record corrected here). Scope item 1 calls `:7649`, `:7719`, `:7774` the model sites that "already read all three"; on `main` each was itself short and the diff completes them too. Scope is plan-owned and stays; this line is the correction.
  - F5 (rejected, refuted against the implementation). A `;`-joined two-statement argument does not half-apply silently: the eval returns the last statement's count and that statement runs on an undefined `$_`, so the count is 0 and the guard fails naming the substitution (scratch run over the real filter).
  - F6 (fix now). `text="${!ordinal}"` runs before the `counted -eq $#` guard, so a counts file longer than the arguments dies on `set -u` as `!ordinal: unbound variable` with no label (confirmed in scratch); loud, but not the message written for it.
  - F7 (follow-up → the M37 guards/bounded-mutations candidate row, KI135). Over-application is counted but never checked (`-gt 0` only); a substitution applying five times passes.
  - F8 (fix now). The backstop message says "the counts above" but the counts go only to `$M061W/<slug>-counts`, never the log.
  - F9 (fix now, wording). "did not compile" also fires on a runtime death inside the substitution.
  - F10 (fix now). `M066_CARRY_SLIPPED`'s replacement half is dead text that reads as a copy to keep in sync.
  - F11 (rejected). `m061_mutant` now asserts strictly more than "the file changed"; the check's promise to its callers (the mutation applied) is unchanged, its read of "applied" repaired — the D-011 disposition the plan names; no D-entry owed.
  - F12 (no change needed). AC4 unticked at the reviewer's read because the fresh runs had not ended; ticked below on them.
  - F13 (rejected, style). Two pre-existing label-tail styles mix within this repair.
  - F14 (rejected, style). `m066_slipped` resembles `m061_planted` 12k lines later; a comment would not change what either does.
  - F15 (rejected, plan-owned). Scope/AC line references (`6796-6804`, `7993-7995`, `20327-20336`, `20404`, `:7993`) name pre-diff positions; plan text is not edited at review, and the enclosing constructs are named beside each number.
