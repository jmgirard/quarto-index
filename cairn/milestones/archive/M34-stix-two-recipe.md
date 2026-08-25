# M34: The non-Latin-1 recipe names a font TeX Live still maintains

**Status:** done (2026-08-24, PR #34 https://github.com/jmgirard/quarto-index/pull/34)

**Goal:** An author copying README's `### Terms outside Latin-1` recipe installs a font package TeX Live still maintains, and the suite proves the recipe under it.

**Outcome:** README's recipe block and prose and `examples/unicode.qmd`'s front matter name STIX Two Text, loaded by file from `stix2-otf`, replacing `stix` (obsolete since 2018). The font guard probes `STIXTwoText-Regular.otf` and still stops the run when the package is absent; the claims rows, the control-derivation assertions and the four controls moved with it. Under the new font the no-engine control exits 0 printing all eight terms where under `stix` it dropped `Việt`, so README's third path became a build that works and control (d) flipped from an absence check to the `entries` reading the recipe render gets; `M33_VIET` left the suite. Counts unchanged at 351 plain / 487 self-test.

**Decisions:** the recipe keeps `pdf-engine: xelatex` though the font alone prints correctly today, because the line pins behaviour to what the recipe states rather than to whichever engine a reader's Quarto picks (milestone-local). Cross-cutting: D-018, D-019.

**Review:** three-lens fan-out, 10 + 3 + 0 findings, none meeting the return floor. Fixed at the gate: a suite comment citing a `Missing character` line the new font never emits, README's "either line changes what you get" lead-in and two mis-wrapped lines, the fixture's family-name sentence, the claims-table exception count, control (d)'s colliding AC label, the stale candidate row, and D-019. Follow-up: control (d) reads no evidence of which engine ran. Rejected: the one-of-four-faces guard probe (inherited, Scope Out), the decision's placement, a theoretical regression-protection loss. Nothing graduated or retired.
