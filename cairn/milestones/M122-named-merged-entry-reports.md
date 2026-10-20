# M122: Merged-entry reports are checked where they name their index

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — it adds an acceptance-suite check and one test fixture, which no external consumer of the repo relies on
- **Branch/PR:** m122-named-merged-entry-reports

## Goal

The suite checks each of the four reports about an index entry that merges
different marks in the form that names its index.

## Scope

**In:** The candidate row "Exercise two paths no fixture reaches", from
KI320 and KI60. `index.lua` writes each of the four merged-entry wordings in
two forms: `document`, and `index "<name>"` in a document that declares two
or more indexes (`_extensions/index/index.lua:318-340`). The suite pins the
four document forms on `examples/xref-conflict.qmd` and
`examples/xref-joined.qmd`. No render reaches a named form. The LaTeX path
alone records these reports, so the new fixture renders to PDF. KI60 says no
book fixture round-trips the chapter record's `role` field. M21-AC5 and the
M065-AC4 control both read a `principal` locator that a chapter record
carries, so this milestone confirms the gap is closed by one probe and
strikes KI60. If a new case shows the extension itself is wrong, this
milestone fixes it when the fix fits one sitting, with a changelog entry.

**Out:** The three anchor checks, which M121 takes. The rest of the
acceptance-suite backlog stays under the candidate row "Older
acceptance-suite backlog".

## Acceptance criteria

- [ ] AC1: `examples/xref-conflict-named.qmd` declares two indexes. In one
      of them, it marks a term for each of the four merged-entry shapes. Two
      shapes are a plain mark beside one cross-reference, or beside two or
      more different ones. The other two are two different cross-references
      with no plain mark, or three or more with none. It also marks one term
      in both indexes that clashes in neither. The suite renders the fixture
      to PDF. It reads each line of that render's log that matches any of
      the eight literals of the four wordings, in both scope forms. It holds
      those lines to a hand-stated list, line for line. The list holds one
      line per shape, each naming its term and `index "<name>"`. It holds no
      line for the term marked in both indexes.
- [ ] AC2: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T1, T2, T3, T4, T5

## Tasks

- [x] T1: Write `examples/xref-conflict-named.qmd` with an `indexes:` list
      of two, the four shapes in one index, and the term marked in both.
      Add it to `site/gallery.yml` under `not-shown:` and give it a
      `DANGLING_CORPUS` row with a hand-derived count
      (`tests/run-tests.sh:15163`). Render it to PDF beside M02-AC5
      (`tests/run-tests.sh:2680`) and capture it. No new `warn()` literal is
      added, so `tests/scans/warn-distinct.py`'s `EXPECTED` stays 90.
- [x] T2: Hold the render log's lines to the hand-stated list of AC1,
      matching on all eight literals so that a stray `document` form shows.
      Add `--self-test` plants: `scope_phrase` returning `document`, and one
      shape's report removed.
- [x] T3: Commit first, then remove `role = mark.role` from `build_record`
      (`_extensions/index/modules/book.lua:281`) and run the suite. Record
      the first failing check in the work log, restore the line, and strike
      KI60 in `cairn/DESIGN.md` citing that check. If the suite stays green,
      add a book check that fails on it instead, and record that.
- [x] T4: Strike KI320 in `cairn/DESIGN.md`. Run
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` green.
- [ ] T5: Review return 1. Make each of the check's eight patterns run to
      the end of the log line, so text after a report leaves the line
      unread, and refuse a missing log by name. Add `--self-test` plants
      for both, and run the suite with `--self-test` green.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which ready work to plan — both candidate rows, as two milestones, M121 first.
- 2026-10-20: question set: what to do if a new case shows the extension is wrong — fix it in the milestone if it fits one sitting, with a changelog entry; a larger fix stops the run.
- 2026-10-20: promoted the candidate row "Exercise two paths no fixture reaches" (KI320, KI60) in full.
- 2026-10-20: collision check: M116 added the count forms and pinned their document scope; M21 and M065 read the `principal` role through a chapter record. No D-entry rejects the work. No open issue or PR on GitHub.
- 2026-10-20: checker-regress shape considered and not taken: the check reads the extension's render log, not repo-internal tracking files.
- 2026-10-20: criteria audit (reduced, internal tier): fresh Opus reader returned 2 findings here. AC1 now matches all eight literals. The `role` criterion was dropped: the removal stops the suite at M21-AC5 before the M065-AC4 control, and the work is outside the goal, so it moved to T3 as a probe and a strike.
- 2026-10-20: plan gate chose a new fixture over rendering `examples/index-labels-misuse.qmd` or `examples/index-separators-scoped.qmd` to PDF, because neither holds all four shapes and a silent case; falsified by one of them reaching all four named forms with no edit.
- 2026-10-20: lessons surfaced: M116 (fixture registration and `warn-distinct.py`'s count), M117 (plants resting on old output), M13 (the multi-index metadata key), M073 (no suite edits mid-run), M082 (run with `PATH=/usr/bin:$PATH`).
- 2026-10-20: implement started on branch m122-named-merged-entry-reports.
- 2026-10-20: choices: indexes `plants` and `places`; Willow is the term in both; the check is a Python script in `$WORK` reused by the plants; plants re-render a mutated extension copy to PDF (about 4 s each) beside an unmutated control; an extension-warning count of 4 over the render is added beside the list.
- 2026-10-20: checkpoint: T1 and T2 written, suite run 1 in flight; scratch render printed the four named lines and none for Willow.
- 2026-10-20: suite run 1 cut off after M33-AC3c with no FAIL line, about two minutes in: the background command's default timeout, not the suite. Run 2, detached, passed `--self-test` with 3757 checks; both T2 plants red on their expected lines, the control green. T1 and T2 done.
- 2026-10-20: correction of the line above: it is false. Run 2 exited 1, cut off when run 3 cleared `tests/.work` while run 2 was still going, and run 1 most likely stopped the same way when run 2 started. The 3757-check pass was never observed. No full run has finished yet. T1 and T2 stay ticked pending a green run, which run 1's output supports so far: M122-AC1 green, both plants red on their expected lines, the control green.
- 2026-10-20: T3 probe: with `role = mark.role` removed from `build_record`, the suite's first and only FAIL was M21-AC5, which read `"Ranged Term"`'s `sub/two.html` locator without `qi-principal` and `strong`, so a chapter record's `role` is exercised. Line restored; KI60 struck citing M21-AC5. A chat-written notice had named a different M21-AC5 message; the run log shows the one above.
- 2026-10-20: T4 (checkpoint): KI320 struck; the full `--self-test` run follows, alone.
- 2026-10-20: run 4 (alone) exited 1 on M24 and M24-AC3: the plant helper's render had no `capture` call. M122-AC1, the control and both plants printed ok in it. Added the capture; run 5 follows.
- 2026-10-20: run 5 (alone) passed `--self-test`: exit 0, "All checks passed (1883 checks)", no FAIL line, read from its log. T4 done.
- 2026-10-20: claim audit: not owed — internal tier.
- 2026-10-20: implementation complete, status review.
- 2026-10-20: review: run 6 stopped by hand before the review fixes, since they change the suite. The T3 line's "first and only FAIL" is corrected: `fail()` exits at the first failure, so M21-AC5 was the first red check and no later check ran. KI60 narrowed rather than struck: the probe covers the write and read of a string `role`, not the refusal of a non-string one.
- 2026-10-20: review return 1: AC1 — the check held only the span of each line from "index entry" to "meant", so a report with text after it passed; the fix (patterns anchored at the line's end, plus a plant) is in 1fff89b, and run 7 is in flight.
- 2026-10-20: resumed for review return 1; added T5 for it (minor amendment, Coverage updated). Its code landed in 1fff89b; T5 waits on run 7.

## Decisions

## Review

- Sync: main had not moved since the branch was cut (`git rev-list --count HEAD..origin/main` = 0). No PR yet; the Copilot round is off.
- Consistency gate: `cairn_validate.py` exit 0, all checks passed. No principle changed, so `cairn_impact` was skipped. The generic profile names no toolchain checks.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the check compared only the span from "index entry" to "meant", so text after a report passed — fix now, and a floor return: AC1 holds the lines "line for line", and the check held a part of each. Patterns now run to the line's end, with a self-test plant.
- diff-bug #2: the KI60 strike covered more than the probe showed; the refusal of a non-string `role` (`book.lua:440`) is unchecked — fix now: KI60 narrowed to that leg.
- diff-bug #3: "first and only FAIL" in the T3 line overstates, since `fail()` exits at the first failure — fix now: corrected by a work-log line.
- diff-bug #4: the check's comment said `%d` matches any text, where it matches digits — fix now.
- diff-bug #5: the section comment left out D-021's condition that the back-end keeps the indexes apart — fix now.
- blame-history #1: the KI60 strike rests on one probe of one leg — fix now, as diff-bug #2.
- blame-history #2: "first and only FAIL" — fix now, as diff-bug #3.
- blame-history #3: the ROADMAP row still names KI320 and KI60 — reject (planned change): post-merge hygiene graduates the row, as M121's review did.
- blame-history #4: the strike carries no citation of M21-AC5 outside the work log — fix now: the narrowed KI60 names M21-AC5.
- blame-history #5: T1's pointer `tests/run-tests.sh:15163` is stale — reject (false as a defect): it is the plan's record, correct when written, and the file grew under it.
- blame-history #6: `m122_plant` lacks m081's "unwanted substring" argument — reject (style): the two plants' want strings name different lines, and neither prints the other's.
- prior-review #1: the KI60 strike closes an M20 finding on partial evidence — fix now, as diff-bug #2.
- prior-review #2: the ROADMAP row is still present — reject (planned change), as blame-history #3.
- prior-review #3: a missing log gave a traceback blaming the list (M111) — fix now: refused by name, with a self-test plant.
- prior-review #4: only the matched span is held — fix now, as diff-bug #1.
- ripple #1: the ROADMAP row names struck entries — reject (planned change), as blame-history #3.
- ripple #2: `site/examples.qmd` says the whole corpus is described below, and the new fixture is not — follow-up: KI327 (the page already left out most fixtures, `xref-conflict.qmd` among them).
- ripple #3: README says that page lists what each fixture exercises — follow-up: KI327.
- diff-bug note, not ranked: the control does not go through the splice path — reject (false): a broken splice fails on its own `die`, `cmp`, render or want check.
- Fixes committed in 1fff89b.
