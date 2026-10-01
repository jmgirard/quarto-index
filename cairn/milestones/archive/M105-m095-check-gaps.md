# M105: Three M095 checks each fail on the gap its review found

**Status:** done (2026-10-01, PR #105 https://github.com/jmgirard/quarto-index/pull/105)

**Goal:** The state probe, the `Bramble` check and the `outside-heading` check
each fail on the gap the M095 review found in it.

**Outcome:** `tests/stateprobe.py --check-cells`, run on every suite run,
reads the reset of each module `CELLS` names. It fails on a reset line that is
neither a `CELLS` statement for its module nor a `KEPT` line of `indexes.lua`.
`quarto pandoc lua` gives each exported reset's first and last line. A small
lexer finds the opener and the code lines. The `Bramble` check gets its own
`perl`-planted copy of the page and leaves the M063 T2 leg. `outside-heading`
in `tests/fragments.py` takes its container and heading tags from the call.
KI284 to KI287 closed. KI306 to KI308 record the guard's accepted gaps.

**Decisions:** D-062 (the guard reads reset source, narrowing D-011) and
D-063 (Quarto's Lua gives each reset's bounds).

**Review:** three runs and four defect returns, all on AC1. Each time the
guard's own Lua reading missed part of its domain. The user narrowed AC1 twice, to
modules `CELLS` names. Run 3 logged W1 to W15: W9 fixed, W4, W8 and W12 to a
candidate row, six rejected. Suites passed 1738 and 898 checks. Nothing
graduated or retired.
