# M29: A marker report in a book names its chapter

**Status:** done (2026-08-24, PR #29 https://github.com/jmgirard/quarto-index/pull/29)

**Goal:** A placement-marker report drawn while rendering a book chapter to HTML names the chapter file it is about, as the book-aware marker warnings already do.

**Outcome:** `index.lua` computes `book_context` before `qi_marker.resolve_markers` and passes `book and book.file` in; `marker.lua` gains `in_chapter(chapter)` beside `POSITION_BASIS`, threaded through `resolve_markers` and `strip_nested_markers`, emitting ` of <chapter>` inside the block position it scopes and the empty string where none is known. The `is_html()` gate is what makes a chapter file mean a chapter, so a PDF book and every single document stay byte-identical to M28. The duplicate report's lead-in became "Block positions are" from "Both numbers are", closing KI80 without splitting the shared string (D-014); the ordinal keeps "in document order". `tests/m29book.py` partitions every extension warning in a log against the fixture's known others and two end-anchored report patterns whose only free parts are the block position, the ordinal and the chapter clause; five planted logs prove it able to fail. Fixtures: a blockquoted marker in `examples/book/sub/two.qmd`, a second top-level marker in `examples/book/last.qmd`. KI22 and KI80 struck; KI83, KI84 and KI85 filed.

**Decisions:** none cross-cutting. Milestone-local: the chapter attaches to the block position rather than riding as its own clause; `POSITION_BASIS` stays one string.

**Review:** three fresh-context lenses; blame-history and prior-review-record clean, diff-bug returned 15. Fixed on the branch: the clause moved inside the parenthesis, a planted probe rewritten self-guarding, a mislabelled criterion, a missing colour strip, KI82's stale count, README's two marker bullets, a T4 divergence logged, two cosmetics. Filed: KI84, KI85. Rejected: five. Nothing retired or graduated.
