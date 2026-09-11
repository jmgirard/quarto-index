# M091: The cross-reference escaping probe's targets name terms it indexes

**Status:** done (2026-09-11, PR #91 https://github.com/jmgirard/quarto-index/pull/91)

**Goal:** Every `see=`/`see-also=` target in `examples/xref-escaping.qmd` names a path a
mark in that file indexes, so the probe tests target resolution through every printable
ASCII character instead of drawing 271 dangling-target reports.

**Outcome:** `examples/xref-escaping.qmd` gains a closing section of 208 invisible marks, one
per distinct path its 271 non-empty targets name. `tests/run-tests.sh`: `XREF_MARKS` 256 →
464; the fixture's M14 dangling corpus row 271 → 0 with its derivation rewritten; zero counts
for `WARN_DANGLING` and `WARN_DANGLING_INDEX` over `xref-latex.log`, and for the per-index
wording over the gfm corpus log. A one-off scratch probe showed a removed mark drawing its
reports back. KI72 narrowed to `demo.qmd` and `xref-conflict.qmd`, with a candidate row; AC2
amended at implement to what the M02-AC3 legs read.

**Decisions:** none milestone-local; the plan gate's three choices (reconcile over drop, hidden
marks over rewritten targets, one-off probe over a permanent plant) are in git.

**Review:** pass 1, three-lens fan-out; self-test suite 1456 checks, exit 0, all three criteria
verified. History and prior-review lenses found nothing. Diff lens: F1 (a zero count reads a
missing log as 0) → KI277 at hygiene; F2 (gfm zero count unproven in-suite), F3 ("invisible"
in gfm output) and F4 (no guard beyond the zero counts) rejected. CI green on PR #91. Nothing
graduated or retired.
