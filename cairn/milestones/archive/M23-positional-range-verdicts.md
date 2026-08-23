# M23: A range verdict follows its mark's position, not its text

**Status:** done (2026-08-23, PR #23 https://github.com/jmgirard/quarto-index/pull/23)

**Goal:** The emitting pass reads each range mark's pairing verdict by document
position, so a mark's rewritten visible text can never move another mark's verdict.

**Outcome:** `marks.lua`'s per-key verdict queues (`range_plan`/`range_cursor`) are gone.
`range_position(span)` holds the guard — index class plus `range=` — as one function both
traversals call before deriving anything, and is the only advance of the `range_at`
counter; `finish_ranges` files each verdict under its mark's position into `range_verdicts`
and resets the counter between passes; `next_range(pos)` reads it back. `pair_ranges` still
pairs by entry key, so what the key stopped doing is standing in for a mark's identity
across the two passes. Behaviour-preserving — no reachable rendering hit the desync.
Fixtures: `examples/range-nested.qmd`, a nested `entry=`-less range beside a plain one, and
`examples/range-position.qmd`, those plus a class-less `range=` span and an entry-less mark.

**Decisions:** AC2's two named functions are `finish_ranges` and `next_range`; `plan_range`
keeps the entry key, since an opening pairs with the next closing of the same entry.

**Review:** Three rounds, three-lens fan-out each. Rounds 1 and 2 both returned on AC2 — the
source scan certified six properties it never asserted, each reproduced against a tree it exited
0 on. AC2 was then amended at a gate to a deliverable property, the scan retired, and certifying
moved to a nine-row defect-injection battery rendering the fixture against each break it plants.
Round 3: seven findings — three fixed, two to follow-ups, two waived. 390 checks, exit 0.
