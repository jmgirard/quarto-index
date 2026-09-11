# M088: Two link-check defects M087's review filed close by deletion

- **Status:** in-progress
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

- [ ] AC1: `tests/run-tests.sh` neither defines nor calls
      `check_locator_fragments` — `grep -c check_locator_fragments
      tests/run-tests.sh` prints 0 — the M063-AC2 old-store leg runs
      `tests/fragments.py resolve` over `place-oldstore/_book/index.html` where
      the removed call stood, and `links by an anchor` appears on no line
      between that leg's `place_render place-oldstore ` call and its
      `pass "M063-AC2: over a store` line.
- [ ] AC2: `m085_epub_plant` takes one expected count, and every call holds
      both `epubcheck.py links`' skipped count and `epubcheck.py unique`'s
      leaving count to it.
- [ ] AC3: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

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
- [ ] T3: Run `tests/run-tests.sh`, then `tests/run-tests.sh --self-test`,
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

## Decisions

## Review
