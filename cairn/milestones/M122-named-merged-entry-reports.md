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

- AC1 → T1, T2
- AC2 → T1, T2, T3, T4

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
- [ ] T4: Strike KI320 in `cairn/DESIGN.md`. Run
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` green.

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

## Decisions

## Review
