# M19: A reported level count says which levels it counts

**Status:** done (2026-08-21, PR #19 https://github.com/jmgirard/quarto-index/pull/19)

**Goal:** Every warning reporting a count of index levels names which levels that count is over, and gives
the count the author wrote alongside it wherever the two differ.

**Outcome:** `depth_phrase` in `levels.lua` is the one place a report names a depth; both fold reports splice
it in, reading `is 5 levels deep, of the 6 written` and `names a path 4 levels deep, of the 5 written`, each
falling back to one number where nothing dropped. Its written counts come from `target_levels`' new second
return and `derive_levels`' fourth, both already computed and discarded at `passes.lua`; `latex_plan` carries
the entry's as `entry_written`, `written` in its loop being a target's pre-fold spelling. The extra-sort report
drops the clause about a drop touching neither count, branching on `kept == nil` — nil only where no `entry=`
was written — for `against the 2 the entry is written with` or `against the 1 level its visible text makes`.
New fixture `examples/fold-xref-empty.qmd` probes both empty-level positions, both attributes, a counts-agree
control, and a target the drop leaves at the ceiling, where the report stays silent. Suite 208 -> 210, 248 self-test.

**Decisions:** D-006 — a reported level count names the levels it is over.

**Review:** three-lens fan-out; blame-history and prior-review returned zero regressions. Diff-bug returned 8,
none showing a criterion failing, so no return. Seven fixed at the gate: a branch comment false for an all-empty
`entry=`, an unused pinned constant, a comment claiming a whole message was visible at its call site after two
clauses were spliced out of it, two criteria whose negatives rested on substring pins (now a source-and-README
sweep), a hard-coded singular, a long line, stale task text. F5 rejected: book records persist no written depth,
correctly.
