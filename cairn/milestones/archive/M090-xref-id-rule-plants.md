# M090: M079's cross-reference id rules each turn the id-collision leg red

**Status:** done (2026-09-10, PR #90 https://github.com/jmgirard/quarto-index/pull/90)

**Goal:** Each of M079's three cross-reference id rules is shown to turn the M079-AC1 leg
red when reverted, with no self-test left claiming to fence a copy of that leg's read.

**Outcome:** `tests/run-tests.sh --self-test` gains three plants through `m081_census_plant`,
which now takes the module it substitutes into (default `html.lua`): `contestable_xref` made
false in `passes.lua` (red on `rho` keeping `xref-dup`), the outrank clause dropped from
`keepable_author_ids` (red on the `chi` locator), and `assign_anchors` giving up an
uncontested cross-reference id (red on `xref-solo`/`upsilon`). The M084 T2 self-test and its
`text_keyed`/`grouped` helpers are removed; the leg's own grouping read stays, its comment
saying no rendered case reaches a group of two. KI274 and KI275 added; KI276 (T3's pinned
line is also printed under T2) added at hygiene.

**Decisions:** none milestone-local; the plan gate's two choices (delete rather than harden
the M084 self-test; record the refusal-wording gap rather than add a fourth plant) are in
the work log (git).

**Review:** pass 1, three-lens fan-out; suite 1455 checks, 0 FAIL, all four criteria
verified. History and prior-review lenses found nothing. Three wording findings, all fixed
before merge: the plant comment claimed no pinned line was printed by a neighbouring plant,
false for T3; the helper's failure messages still named the census; the section header
counted six plants of ten. Checked with `bash -n`; CI green on PR #90. Nothing graduated or
retired.
