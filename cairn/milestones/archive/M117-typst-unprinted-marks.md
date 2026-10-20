# M117: A Typst index leaves out a term no page carries

**Status:** done (2026-10-20, PR #117 https://github.com/jmgirard/quarto-index/pull/117)

**Goal:** A Typst index prints no entry whose page-number marks all sit where no page prints them, such as a front-matter field Quarto's Typst template leaves out, when it has no cross-reference and no sub-entry that prints.

**Outcome:** Strikes KI289. In `typst.lua`, `qi-index-entry` takes `below`
from `labels_below`: the opening and closing labels of its sub-entries at
any depth, in `sorted` order, or `true` for a cross-reference. An entry
none of whose labels `qi-index-live` finds prints nothing; a letter heading
prints under `#context if` only where an entry of its group does; a range
closed on a page keeps its entry, with no locator. New:
`examples/typst-unprinted.qmd`, `tests/typst-unprinted.tsv`, an M117-AC1
section with six plants. M098-AC7's front-matter rows and the M098 alt-kept
plant now expect the term left out. `site/typst.qmd` and the changelog state
the rule and three limits (KI321-KI323).

**Decisions:** no warning and no page-1 locator (question set). AC1 amended
once to Quarto 1.10.19, as no suite runs on the 1.10.18 pin.

**Review:** four lenses, two passes; 31 findings: 12 fixed (the range case,
label order, prose pins, a retired-phrase guard, stale comments), 4 to rows
("Finish leaving out unprinted Typst marks", "Pair a range closed in front
matter" with KI324, "Floor-Quarto CI suite job"), 15 rejected. Claim audit:
46 claims, 4 corrected. LESSONS: one added, the M082 line corrected.
