# M18: A cross-reference target is judged against the path the entry prints

**Status:** done (2026-08-20, PR #18 https://github.com/jmgirard/quarto-index/pull/18)

**Goal:** In a LaTeX render a cross-reference target is folded to the three-level ceiling exactly
as an entry is and resolved against the paths entries print, so the fold neither draws two
contradictory reports about one target nor ships a cross-reference the printed index cannot answer.

**Outcome:** `latex_plan` clamps every target and returns the entry's clamped levels; the Span pass
builds the LaTeX plan before recording the resolution set, so `record_marked` records printed
paths, prefix-closed as before, and a pending target carries the written spelling for the report
(M09) and the folded one for the lookup. All three sites that render a target read one returned
list — single-attribute encapsulation, both-attributes command, contested key's printed field —
and the rewrite report fires only where a target survives the fold. Three fixtures, an M18 suite
section, M14-AC4's pins superseded for LaTeX alone, and the M15 residue sweep and
`tests/plantdefect.py` repaired. 231 → 245 checks.

**Decisions:** D-005 — where a back-end folds levels, it judges targets against what it prints.

**Review:** three-lens fan-out; blame-history and prior-review returned zero. Diff-bug returned 11.
One defect return: the rewrite report fired before the fold-self drop, so a folded self-target drew
two contradictory reports — this milestone's own defect class in a new shape, pinned by a fixture
rather than by a new criterion. Eight more fixed (comments contradicting D-005, an unregistered
warning key, an unchecked clause, an uncompiled site, a self-comparing manifest, a dead stripper, a
misleading message clause, an orphaned DESIGN sentence). F9 to a candidate row; F11 rejected.
