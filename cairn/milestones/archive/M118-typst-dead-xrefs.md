# M118: A Typst index leaves out what no page backs

**Status:** done (2026-10-20, PR #118 https://github.com/jmgirard/quarto-index/pull/118)

**Goal:** A Typst index prints no cross-reference, entry or index heading that rests only on marks no page prints.

**Outcome:** Strikes KI321-KI323. `passes.lua` tags every Typst
cross-reference mark, `assign_labels` labels it, `typst_locator` adds no
locator for it. `build_entry_tree` copies each cross-reference with
`writers`; `lookup_entry` moved to `entries.lua`. Per index, `typst.lua`
writes `qi-nodes`, and `qi-index-prints` (greatest fixed point, bounded
`for`) decides what prints: an own label found, a sub-entry that prints, or
a cross-reference with a writer's label found and a target that prints or
is not filed. The see word precedes the first printed target of its kind.
The index's page break, heading and columns print only where an entry does.
`examples/typst-unprinted.qmd` gains `toc: true`, the cases and a twin; 12
plants. `site/typst.qmd`, `site/books.qmd` and the changelog state the rule.

**Decisions:** question set: drop a dead target, no report; empty index prints nothing.

**Review:** four lenses, 26 findings: 10 fixed (a Typst `while` limit, two
untested clauses, the twin's red run and contents premise, a false docs
sentence, stale comments), 3 to follow-up ("Floor-Quarto CI suite job",
KI325), 13 rejected. Claim audit: 39 claims, 2 corrected. CI green on the
floor and pinned Quarto. Graduated "Finish leaving out unprinted Typst marks".
