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

**In:** the emptied-place report (`marker.lua:189`) and the duplicate-marker
report (`marker.lua:222`) carry the chapter file when one is known. Marker
resolution runs at `index.lua:65`, before `book_context` is computed at
`index.lua:70`, so making the chapter file available there is the milestone's
one structural change. A book fixture exercises both reports in a non-first
chapter, and the non-HTML book render pins that the reports keep M28's wording
with no file clause.

**Out:** the incomplete-metadata HTML case (`index.lua:75-78`), where Quarto
supplies too little for `book_context` to return a chapter — no fixture can
produce that state without fabricating metadata Quarto does not emit, which is
the private-structure modelling M12's gate refused; it stays uncovered and gets
its own Known-issues entry. Naming the sequence a number counts → M28, which
this milestone depends on.

## Acceptance criteria

- [ ] Rendering the book fixture to HTML, a nested marker that empties its
      place in a chapter other than the first draws an emptied-place report
      naming that chapter's file, matched against the report's full emitted
      text in a captured log.
- [ ] Rendering the same book fixture to HTML, a second top-level marker in a
      chapter draws a duplicate-marker report naming that chapter's file,
      matched against the report's full emitted text in a captured log.
- [ ] Rendering the book fixture to a non-HTML format, both reports carry
      M28's wording with no file clause, matched by whole-line comparison
      rather than substring — and the same holds for the duplicate-marker
      report over the single document `examples/marker-misuse.qmd`.
- [ ] Every warning `examples/marker-shapes.qmd` emits in html, latex and gfm
      is still either one of that fixture's two known other warnings or M28's
      emptied-place template with only its block number varying.
- [ ] `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test` passes.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T3
- AC4 → T2, T3
- AC5 → T3

## Tasks

- [ ] T1: make the chapter file available where marker resolution runs —
      either by deriving it before `qi_marker.resolve_markers` at
      `index.lua:65` or by passing it in — without moving the book-path
      decisions that read the full `book_context` (`index.lua:70`).
- [ ] T2: splice the file clause into the two reports (`marker.lua:189`,
      `marker.lua:222`), and keep M28's wording verbatim where no chapter is
      known.
- [ ] T3: suite — extend the book fixture with the emptied-place and duplicate
      shapes in a non-first chapter; capture the HTML and non-HTML book render
      logs and assert both reports whole in each; replace the substring pin
      `WARN_MARKER_DUP` (`tests/run-tests.sh:2732`) with a whole-line
      comparison; pass every new grep key to the key-distinctness scan (M18).
- [ ] T4: strike KI22 in `cairn/DESIGN.md`, add the Known-issues entry for the
      uncovered incomplete-metadata HTML case, and rewrite the candidate row
      pointing at KI22, in the same commit (D-013).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan gate chose narrowing the fallback criterion to the non-HTML book render over building a fixture for the incomplete-metadata HTML case because that state needs metadata Quarto does not emit; falsified by a real Quarto configuration that reaches `index.lua:75-78` on its own.
- 2026-08-23: criteria audit for this milestone ran in FULL mode ([O] fresh- context reader, user-facing tier) in the same round as M28's; its findings on M29-AC3, AC4 and AC5 are recorded in M28's work log with the rest.

## Decisions

## Review
