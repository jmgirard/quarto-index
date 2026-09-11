# M088: Two link-check defects M087's review filed close by deletion

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — changes only the acceptance suite's own checks and self-test plants
- **Branch/PR:** m088-link-check-deletions

## Goal

Both defects M087's review filed against the suite's link checks, KI271 and
KI272, close by removing the code that carries them.

## Scope

**In:** delete `check_locator_fragments` from `tests/run-tests.sh` and run
`tests/fragments.py resolve` at the one call site that lacks it; collapse
`m085_epub_plant` to one expected count; rewrite the comments describing
either; strike KI271 and correct KI272 to the gap left.

**Out:** routing `check_locator_fragments` through
`htmlindex.leaves_publication` instead (declined at the plan gate, work log); a
plant whose two EPUB counts differ (declined at the plan gate; the gap stays in
KI272 as corrected, no row); pinning `Bramble`'s anchor on the old-store page →
KI273, under the recovered-locator candidate row; root-relative and
percent-encoded hrefs → their own candidate row (KI120, KI266); reading every
index section in `epubcheck.py unique` → KI264's row.

## Acceptance criteria

- [x] AC1: `tests/run-tests.sh` neither defines nor calls
      `check_locator_fragments` — `grep -c check_locator_fragments
      tests/run-tests.sh` prints 0 — the M063-AC2 old-store leg runs
      `tests/fragments.py resolve` over `place-oldstore/_book/index.html` where
      the removed call stood, and `links by an anchor` appears on no line
      between that leg's `place_render place-oldstore ` call and its
      `pass "M063-AC2: over a store` line.
- [x] AC2: `m085_epub_plant` takes one expected count, and every call holds
      both `epubcheck.py links`' skipped count and `epubcheck.py unique`'s
      leaving count to it.
- [x] AC3: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3

## Tasks

Line numbers are as of the plan commit; T1's deletion moves T2's up.

- [x] T1: Delete `check_locator_fragments` with its comment
      (`tests/run-tests.sh:1405-1444`) and its M064-AC2 call (:9012-9014),
      `five.html` being read already by `fragments.py resolve` at :9023.
      Rewrite the M064-AC2 comment (:9003-9008), which describes the removed
      check's sweep, and the M078-AC3 comment (:9016-9022), which sets that
      reader against "a second copy of it". Replace the old-store call
      (:11309-11311) with `tests/fragments.py resolve
      "$CAPTURE_ROOT/place-oldstore/_book" index.html` in :9023's `|| fail`
      shape, its fail text claiming only what that reader asserts, and rewrite
      the comment above it (:11306-11308) so it no longer reads as a check of
      `Bramble`'s anchor (KI273). Re-read every comment and message naming the
      removed check or its label (LESSONS M038). Strike KI271 in
      `cairn/DESIGN.md`.
- [x] T2: Collapse `m085_epub_plant` (:24115-24138) to `<slug> <label> <count>
      [<pattern> <replacement>]`, the one count read by both greps and its pass
      line, and its four calls (:24140-24151) to one count each. Rewrite the
      two-count comment (:24115-24117) to say the one count stands for both
      because every plant keeps its locator's fragment. Correct KI272 in place
      (marked `corrected M088`) to the gap left: no plant shows `unique`
      leaving uncounted a fragment-less leaving link that `links` skips.
- [x] T3: Run `tests/run-tests.sh`, then `tests/run-tests.sh --self-test`,
      sequentially, with no edit to `tests/run-tests.sh` while either is in
      flight (LESSONS M073).

## Work log

- 2026-09-10: created by /milestone-plan, promoting the candidate row for KI271/KI272 (M087 review O3/O5).
- 2026-09-10: criteria audit (reduced mode, fresh [O] reader) returned two instrument findings, both fixed before the gate: the added-plant AC2 variant restated reader output already true (reworded; variant later declined), and a relabel criterion bound a pass label that does not exist (folded into AC1 as a grep).
- 2026-09-10: plan gate chose deleting `check_locator_fragments` for `fragments.py resolve` over routing it through `htmlindex.leaves_publication` because routing keeps two readers answering one question; falsified by a leg needing one named section's fragments checked where `fragments.py resolve` reads every section on the page.
- 2026-09-10: plan gate chose one expected count in `m085_epub_plant` over adding a plant whose two counts differ because it shrinks a check M085/M087 shipped rather than extending it; falsified by `unique` counting a fragment-less leaving link, or `links` ceasing to count one, with the suite green.
- 2026-09-10: plan gate left `Bramble`'s old-store anchor unpinned (KI273, recovered-locator candidate row) over pinning it with `check_entry_locators` because pinning extends a shipped check; falsified by the record route losing that anchor with the suite green.
- 2026-09-10: T1 done — `check_locator_fragments` and its M064-AC2 call deleted, the old-store leg runs `fragments.py resolve` over index.html (passes on today's capture: 2 locators, 2 fragments), three comments rewritten, KI271 struck, KI273 corrected to the page-wide check; `bash -n` clean, full suite deferred to T3 as planned.
- 2026-09-10: T2 done — `m085_epub_plant` takes one `<count>` read by both greps and its pass line, its four calls pass one count each, the comment says why one number serves (`locators.py` offers only fragment-carrying locators), KI272 corrected in place; `bash -n` clean.
- 2026-09-10: T3 done — `tests/run-tests.sh` passed (779 checks, 0 FAIL), then `tests/run-tests.sh --self-test` passed (1453 checks, 0 FAIL), run one after the other with no edit in flight; the four M085 T7 plants report 0/0, 0/0, 1/1, 1/1.
- 2026-09-10: claim audit: not owed — internal tier
- 2026-09-10: status → review.
- 2026-09-10: review pass 1 in progress — AC1/AC2 evidenced and ticked, `cairn_validate` passed; AC3's suite runs and the three-lens review still running.
- 2026-09-10: step-7 approval: m088-link-check-deletions approved for merge, with F1/F2/F4/F5 fixed first and F3 rejected; suite and self-test re-run before push.
- 2026-09-10: gate fix-now — M063 T2 self-test pass line no longer claims the unasserted anchor contrast (F1), M078-AC3 sweep's fail label names M064-AC2 too (F2), `m085_epub_plant` comment accounts for the clean repack (F4), KI273's pass condition completed (F5); `bash -n` clean.

## Decisions

## Review

Pass 1, 2026-09-10. Branch cut from `origin/main` at bf01f30, which has not moved; no merge needed.

- AC1: `grep -c check_locator_fragments tests/run-tests.sh` prints 0. The old-store leg runs from `place_render place-oldstore ` (:11243) to `pass "M063-AC2: over a store whose records all stand` (:11269); between them `links by an anchor` matches 0 lines, and `python3 tests/fragments.py resolve "$CAPTURE_ROOT/place-oldstore/_book" index.html || fail …` (:11265-11268) stands where the diff removes the `check_locator_fragments … index.html` call.
- AC2: `m085_epub_plant` (:24076) reads `<slug> <label> <count>` and shifts 3; the `links` grep (:24089) matches `; $count link(s) skipped as leaving the publication` and the `unique` grep (:24093) `; $count fragment-carrying link(s) leave the publication`, both on the one `$count`. Its four calls (:24098-24109) pass one count each: clean 0, staying 0, scheme 1, network-path 1.
- AC3: on HEAD 9a4494f (`tests/run-tests.sh` as of b24af65, unchanged since), `tests/run-tests.sh` exited 0 with 779 checks and 0 FAIL, then `tests/run-tests.sh --self-test` exited 0 with 1453 checks and 0 FAIL, run one after the other with no edit to the script in flight. The old-store leg's new call printed 2 locators across 1 section, 2 fragments, 2 pages read; the four M085 T7 plants passed at 0/0, 0/0, 1/1, 1/1.
- Consistency gate: `cairn_validate.py` exit 0, every check PASS/OK; no IP/GP text changed, so `cairn_impact` skipped; the generic profile names no toolchain checks.

Independent review (three lenses, fresh context; dispositions pending the gate):

- [S] prior-review: no finding. The only PR-comment probe returned `[]`; the M063/M064/M078/M085/M087 archives hold nothing the diff reintroduces.
- [S] blame-history: no finding. `check_locator_fragments` had one commit before this deletion (M064); `m085_epub_plant`'s two counts date from M087's split of M085's one.
- [O] F1: `tests/run-tests.sh:11331`, the M063 T2 self-test pass line, says the refused run costs "the anchor a locator the run above links by", while the old-store leg's rewritten comment (:11260-11264) says that anchor is asserted nowhere; the removed check was what backed the contrast.
- [O] F2: :8966-8980, the sweep's comment now carries "M064-AC2's fragment clause with it" but its `|| fail` label names M078-AC3 alone, and its domain widened from the `gamma` section to the whole page (identical today: five.html carries only `gamma`).
- [O] F3: :11265-11268, the same section-to-page widening on the old-store leg (identical today: index.html carries only `alpha`); its fail text names less than `fragments.py resolve` refuses.
- [O] F4: :24072-24075, the comment says "every plant here rewrites a locator", but the `clean` plant rewrites nothing.
- [O] F5: `cairn/DESIGN.md` KI273's pass condition leaves out two things `fragments.py resolve` also refuses: an id on more than one element, and a locator leaving the site.

Dispositions at the gate (2026-09-10): F1, F2, F4, F5 fix now; F3 rejected — the section-to-page widening is the plan's own choice (Tasks T1) and reads the same set on today's fixture, and its fail text understates rather than overstates. No finding meets the return floor: none fails a criterion.
