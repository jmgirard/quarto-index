# M095: Three candidate rows' unasserted fixture facts get checks

**Status:** done (2026-09-11, PR #95 https://github.com/jmgirard/quarto-index/pull/95)

**Goal:** The suite asserts three fixture facts three candidate rows left unchecked.
They are the demo fixtures' cross-reference targets, three book locators, and the
six `indexes.lua` cells outside the state probe.

**Outcome:** Twenty invisible marks across `examples/demo.qmd` and
`examples/xref-conflict.qmd` give every incidental target an entry its file indexes.
The M14 corpus rows fall from 8 and 14 to 0 and 1, and a check names the one left.
`Quoin`'s href, `Bramble`'s `two.html#qi-mark-1` anchor, and `mullion-passage`'s
place inside `a-mullion-in-a-heading` and outside its `<h2>` are asserted by value.
The last uses a new `outside-heading` mode in `tests/fragments.py`, and five plants
show each check red. `examples/state-reuse-indexes.qmd` and a declaration read
through `qi_indexes.reset` bring the six index cells into `CELLS`. Four move a
comparison, and two sit in `EXEMPT`, now a name-to-reason map. KI72 and KI273 were
struck, KI10 corrected, and three candidate rows closed.

**Decisions:** none.

**Review:** Three fresh-context lenses returned 15 findings, all from the diff lens.
Nine were prose the branch added that misdescribed its own checks, corrected before
merge across the test comments and KI10. Four became KI284 to KI287 under one
candidate row, two were rejected, and no finding met the return floor.
