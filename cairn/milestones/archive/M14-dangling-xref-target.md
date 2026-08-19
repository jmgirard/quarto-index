# M14: A cross-reference target that names no index entry is reported

**Status:** done (2026-08-19, PR #14 https://github.com/jmgirard/quarto-index/pull/14)

**Goal:** An author whose `see=` or `see-also=` names a term the document
never indexes is told, instead of shipping a reference the reader cannot follow.

**Outcome:** A format-neutral report in the Pandoc pass, resolving
`pending_xrefs` (surviving targets, deferred so one may name an entry marked
further down) against `marked_paths` (every mark's level path and its
prefixes). Fires in LaTeX, HTML and back-endless formats alike, once per mark
per target. `report_book_dangling` draws the book's from the whole store, at
the last chapter in book order, naming the chapter the mark is in. Fixtures
`examples/dangling-xref.qmd` (7 reports) and `examples/resolving-xref.qmd` (0);
every example's count pinned with its by-hand derivation behind a grep-derived
roster. 218 checks under `--self-test`.

**Decisions:** what makes a target resolve — a marked path or any prefix, as
`levels_key` strings — and why it cannot share `lookup_entry`; superseded once.

**Review:** three-lens fan-out; blame-history and prior-review found none.
Diff-bug returned 17: 12 fixed (a store-version bump that would have dropped
chapters' terms, two IP2 crash paths, a silently aborting suite pipeline), 1 to
a widened candidate row (contradictory LaTeX pair, pinned by AC4), 2 rejected.
Consolidated the M01/M06/M08 revert-probe lessons into one.
