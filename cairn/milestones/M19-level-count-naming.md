# M19: A reported level count says which levels it counts

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** —

## Goal

Every warning that reports a count of index levels names which levels that count
is over, and gives the count the author wrote alongside it wherever the two
differ.

## Scope

The deliverable is warning text authors read, so the surface tier is
**user-facing**. A value has three level counts — what the author wrote, what
survives the empty-level drop, and what the three-level LaTeX ceiling prints —
and the three reports that name one say which they mean either not at all or in
words that mislead. `see="!A!B!C!D"` is reported as four levels against five
written; the extra-sort report attaches "before empty levels are dropped" to two
counts that no drop touched. Only the naming changes; every number these reports
compute stays the number it is today (D-002's arithmetic).

**In:** the three reports naming a level count — the entry fold
(`clamp_levels`, `modules/levels.lua:78`), the folded cross-reference target
(`latex_plan`, `modules/latex.lua:164`) and the extra sort levels
(`sort_levels`, `modules/levels.lua:245`); the plumbing carrying the written
count to the first two; the convention in `cairn/DESIGN.md` Conventions plus a
`cairn/DECISIONS.md` entry; README's account of both reports; one new fixture
file, `examples/fold-xref-empty.qmd`; the suite pins, manifest rows and scan
needles the rewording and the new file move. A consequence accepted here: on
`examples/demo.qmd`'s deep mark the empty-level report and the entry-fold report
will name 6 and 5 on consecutive lines.

**Out:** the arithmetic these reports compute — unchanged, and AC5 pins it. The
empty-level report and the dropped-sort-key report beside it, which already name
both counts. The chapter-count report in `modules/book.lua:482` and the
top-level-block-count reports in `modules/marker.lua:189,222`, whose numbers have
no drop to distinguish → candidate row. Any sweep asserting a convention over
warning messages this milestone does not name → refused at the plan gate, see the
work log.

## Acceptance criteria

- [ ] AC1. `cairn/DESIGN.md`'s Conventions section carries a convention requiring
      a warning that reports a count of index levels to name which levels the
      count is over, and to give both counts where the count differs from the
      number of levels the author wrote; a `cairn/DECISIONS.md` entry records it
      and states that D-002's "depth is counted after the drop" arithmetic is
      unchanged by it.
- [ ] AC2. In a LaTeX render of `examples/fold-xref-empty.qmd`, the
      folded-target report names both the count of levels the author wrote and
      the count left after empty levels are dropped for each of three marks — a
      `see=` target written with five levels whose first is empty, the same
      shape with the empty level trailing, and a `see-also=` target written with
      five levels whose first is empty — and names one count only for a `see=`
      target written with four levels none of which is empty. A `see=` target
      written with four levels whose first is empty draws no folded-target
      report at all, since nothing was folded, while the
      empty-level-in-target report for it still fires.
- [ ] AC3. In a LaTeX render of `examples/empty-levels.qmd`, the
      extra-sort-levels report for `entry="Moles!" sort="a!b!c"` names 3 sort
      levels against 2 and says the 2 is the count of levels the entry is
      written with; the report for its no-`entry=` twin
      `[ferns]{.index sort="a!b!c"}` names 3 against 1, says the 1 is the level
      the mark's visible text makes, and quotes no `entry=` value; and neither
      message contains the phrase "before empty levels are dropped".
- [ ] AC4. In a LaTeX render of `examples/demo.qmd`, the entry-fold report for
      `[deep]{.index entry="One!Two!Three!Four!Five!"}` names both 6 and 5; in a
      LaTeX render of `examples/fold-xref.qmd`, the entry-fold report for
      `[ash]{.index entry="Ash!Bay!Cod!Dun"}` names 4 and no second count.
- [ ] AC5. For each mark named in AC2, AC3 and AC4, every number its
      reports name equals the count derived from that mark's own source line —
      so no number any of the three reports computes changes.
- [ ] AC6. `README.md`'s account of the extra-sort-levels report and of the
      three-level ceiling names, for each count it mentions, which levels that
      count is over, in the same words the reports use, and asserts nothing
      about counts being "taken before empty levels are dropped".
- [ ] AC7. `tests/run-tests.sh --self-test` passes (the profile's verify slot).

## Coverage

- AC1 → T1
- AC2 → T3, T5, T6
- AC3 → T4, T6
- AC4 → T2, T6
- AC5 → T6, T8
- AC6 → T7
- AC7 → T6, T7, T8

## Tasks

- [ ] T1. Write the convention into `cairn/DESIGN.md` Conventions and append the
      DECISIONS entry recording it and its relation to D-002.
- [ ] T2. Carry the written entry depth to the entry-fold report:
      `drop_empty_levels` already returns `#parsed` (`modules/levels.lua:170`);
      thread it from `derive_levels` (`modules/marks.lua:157`) through
      `passes.lua:94,146,158` into `latex_plan` (`modules/latex.lua:116`) →
      `index_argument` → `clamp_levels`. Splice the count phrase in as a `%s`,
      the shape `drop_empty_levels` already uses for `remain`
      (`modules/levels.lua:159-162`), so the message stays one literal.
- [ ] T3. Carry the written target depth: `target_levels`
      (`modules/marks.lua:25`) returns `#parsed` alongside `kept`; both xref
      build sites (`passes.lua:73,128`) record it under a new field name —
      `written` (`modules/latex.lua:140`) already means the pre-fold spelling —
      and `latex_plan` splices it into the folded-target message the same way.
- [ ] T4. Rewrite the extra-sort-levels message: drop the "before empty levels
      are dropped" clause and splice a `%s` phrase naming what the second count
      is over. Branch on `kept == nil`, not on `depth`, which
      `modules/levels.lua:206` has already defaulted by the report site;
      `sort_levels` already tests `kept` at `:196` and `:252`.
- [ ] T5. Add `examples/fold-xref-empty.qmd` with five marks — leading-empty
      `see=`, trailing-empty `see=`, leading-empty `see-also=`, a no-empty
      four-level control, and a written-4/kept-3 mark that must draw no fold
      report — each on terms no other mark in the file indexes (M13), with the
      entries their targets name.
- [ ] T6. Move the suite pins the rewording and the new file touch:
      `M13_SORT_EXTRA_ENTRY`/`_NOENTRY` (`tests/run-tests.sh:6121-6122`, reused
      at `:6124-6125`, `:7694-7696`), the `names a path` pins (`:7280,7283,7292`),
      `WARN_FOLD_TARGET` (`:2978` and its uses), the `levels deep` greps
      (`:1314`, `:3534`), `warn-distinct.py`'s single-literal needles
      (`:139`, `:147`), and a `DANGLING_CORPUS` row for the new file
      (`:6588-6617`, which derives the roster by grep and fails on disagreement).
      Each pinned count's comment shows its arithmetic (M12).
- [ ] T7. Update README's sort-report passage (`README.md:299-305`) and its
      ceiling passage (`:96-115`), and replace the normative claim rows
      `report: counts are pre-drop` (`tests/run-tests.sh:212`) and, if its text
      moves, `depth after the drop` (`:248`).
- [ ] T8. Prove each of the three changed messages discriminating: with the fix
      committed, revert each message in turn and record which named check fails
      (M01/M14). Run `tests/run-tests.sh --self-test`; log the check count.

## Work log

- 2026-08-21: created by /milestone-plan.
- 2026-08-21: plan gate chose giving both counts where they differ over labelling only the count each report already holds, and over reporting the written count alone; labelling alone leaves the author to connect 4 to the 5 they typed, and the written count alone stops explaining why the fold fired, which keys on the post-drop count; falsified by an author report that the second count reads as noise on marks with no empty level.
- 2026-08-21: plan gate chose a new fixture file over adding marks to `examples/fold-xref.qmd`, whose row-index map, pinned warning total, exact output-row list and HTML manifest would each need re-deriving by hand — the shape M12 got wrong twice; falsified by the new file's own manifest rows costing more than the eight it avoids.
- 2026-08-21: plan gate chose pinning the three named reports over adding a scan and ledger over every warning message; the existing message scan cuts each message at `:format(` and so cannot see its numbers, making the sweep a new checker rather than an extension; falsified by a later report shipping an unlabelled count that no review catches.
- 2026-08-21: criteria audit ran in full mode (user-facing tier), fresh-context [O] reader, twice — nine findings on the pre-gate draft and eleven on the post-gate wording, every one disposed by repair before the file was written; none deferred.

## Decisions

## Review
