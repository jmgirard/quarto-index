# M29: A marker report in a book names its chapter

- **Status:** planned
- **Priority:** normal
- **Depends on:** M28
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** —

## Goal

A placement-marker report drawn while rendering a book chapter to HTML names
the chapter file it is about, as the book-aware marker warnings already do.

## Scope

Surface tier: **user-facing** — the deliverable is warning text authors read.

**In:** the emptied-place report (`marker.lua:206`) and the duplicate-marker
report (`marker.lua:246`) carry the chapter file when one is known. Marker
resolution runs at `index.lua:65`, before `book_context` is computed at
`index.lua:70`, so making the chapter file available there is the milestone's
one structural change. Absorbed from M28's review: KI80 — the duplicate-marker
report introduces the shared position clause with "Both numbers are", so its
source-divergence tail misdescribes the marker ordinal, which is no position.
The repair renames that introduction to the block position; the shared
`POSITION_BASIS` string (`marker.lua:31`) is NOT split, so D-014's consequence
that the two reports cannot drift apart survives, and D-014's own "each is
named where it is printed" is what licenses naming the ordinal separately. A
book fixture exercises both reports in `examples/book/sub/two.qmd`, a chapter
that is neither first nor at the book's top level, and the pdf book render pins
that both reports carry no chapter clause.

**Out:** the incomplete-metadata HTML case (`index.lua:75-78`), where Quarto
supplies too little for `book_context` to return a chapter — no fixture can
produce that state without fabricating metadata Quarto does not emit, which is
the private-structure modelling M12's gate refused; it stays uncovered and gets
its own Known-issues entry. KI82's three-copy suite duplication of the position
clause is accepted, not repaired: M28's review filed it as cost rather than a
hole, T3 adds a fourth copy, and ownership stays on the acceptance-suite
hardening candidate row. Naming the sequence a number counts → M28, which this
milestone depends on.

## Acceptance criteria

- [ ] AC1: In the html render of `examples/book`, a nested marker that empties
      its place in the chapter `sub/two.qmd` draws an emptied-place report
      whose whole emitted line names that chapter's source path the way the
      book-aware marker warnings name `ctx.file`, and is otherwise the
      no-chapter text of AC3 unchanged.
- [ ] AC2: In that same html render, a second top-level marker in
      `sub/two.qmd` draws a duplicate-marker report whose whole emitted line
      names that chapter's source path and is otherwise the no-chapter text of
      AC3 unchanged.
- [ ] AC3: In the pdf render of `examples/book`, the emptied-place and
      duplicate-marker reports each emit a line carrying no chapter clause,
      and each such line is the text M28 shipped except for AC4's change.
- [ ] AC4: In the html, latex and gfm renders of `examples/marker-misuse.qmd`,
      the duplicate-marker report's whole emitted line introduces the shared
      position clause as being about its block position rather than about both
      of its numbers, so the source-divergence tail no longer describes the
      marker ordinal (KI80).
- [ ] AC5: Every warning line in the captured logs of `examples/marker-shapes.qmd`
      in html, latex and gfm, and of `examples/book` in html and pdf, is either
      one of those fixtures' known other warnings or one of this milestone's two
      report templates with only its block number, marker ordinal and chapter
      clause varying — judged line by line over the whole of each log.
- [ ] AC6: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T2, T4
- AC3 → T2, T4
- AC4 → T3, T4
- AC5 → T4
- AC6 → T4

## Tasks

- [ ] T1: make the chapter file available where marker resolution runs —
      either by deriving it before `qi_marker.resolve_markers` at
      `index.lua:65` or by passing it in — without moving the book-path
      decisions that read the full `book_context` (`index.lua:70`). The file
      is available only where a chapter is genuinely known, so the pdf book
      render reaches the no-chapter wording by the same path a single document
      does.
- [ ] T2: splice the file clause into the two reports (`marker.lua:206`,
      `marker.lua:246`), keeping M28's wording verbatim where no chapter is
      known, apart from T3's repair.
- [ ] T3: repair KI80 — rename the duplicate-marker report's introduction of
      the shared clause from both numbers to its block position, leaving
      `POSITION_BASIS` (`marker.lua:31`) one shared string (D-014).
- [ ] T4: suite — add the emptied-place and duplicate shapes to
      `examples/book/sub/two.qmd`; assert both reports whole in
      `$WORK/book-html.log` and `$WORK/book-pdf.log`; extend the whole-warning
      line partition to both book logs; replace the substring pin
      `WARN_MARKER_DUP` (`tests/run-tests.sh:2742`) with a whole-line
      comparison; update the three existing copies of the position clause
      (`run-tests.sh` twice, `tests/m28pos.py` once) for T3's reword; pass
      every new grep key to the key-distinctness scan (M18).
- [ ] T5: in `cairn/DESIGN.md`, rewrite KI22 to keep its chapter-local
      position half and strike its names-no-file half, strike KI80, and add
      the Known-issues entry for the uncovered incomplete-metadata HTML case;
      rewrite any candidate row pointing at them, in the same commit (D-013).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan gate chose narrowing the fallback criterion to the non-HTML book render over building a fixture for the incomplete-metadata HTML case because that state needs metadata Quarto does not emit; falsified by a real Quarto configuration that reaches `index.lua:75-78` on its own.
- 2026-08-23: criteria audit for this milestone ran in FULL mode ([O] fresh- context reader, user-facing tier) in the same round as M28's; its findings on M29-AC3, AC4 and AC5 are recorded in M28's work log with the rest.
- 2026-08-24: amended by /milestone-plan. Gate absorbed KI80 into scope over leaving it standing as a homeless known issue, because M29's T2 already rewrites that warning's format string; falsified by the repair proving to need a D-014 supersession. Gate accepted KI82 over deduping the suite's three copies, because M28's review judged it cost rather than a hole; falsified by a reword landing that the three-copy coupling lets drift through silently.
- 2026-08-24: criteria audit ran again in FULL mode ([O] fresh-context reader, user-facing tier) over the amended criteria and returned twelve findings. Fixed at the gate: the chapter probe moved to `sub/two.qmd` so its path form varies as well as its position; AC2 now requires the same non-first chapter as AC1; AC3 names `examples/book` and the pdf render rather than "a non-HTML format", and T1 now states the gate that makes the no-chapter state reachable; AC1-AC4 rewritten to bind the emitted line rather than the comparison method, which moved to T4; AC5's partition extended to the book logs, which no criterion previously covered; T5 rewrites KI22 rather than striking it, since AC1 repairs only its second half. The auditor's finding that KI80 and D-014 cannot both hold was refuted at the gate: renaming the duplicate report's introduction of the shared clause satisfies both without splitting the string. AC6 was kept instrument-bound against the audit's reading, as the regression gate every milestone in this repo carries.

## Decisions

## Review
