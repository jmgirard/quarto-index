# M09: Sort keys under the LaTeX level clamp

**Status:** done (2026-08-18, PR #9 https://github.com/jmgirard/quarto-index/pull/9)

**Goal:** Two entries the three-level fold prints at one place, while their sort keys
file them apart, are reported instead of reaching makeindex as two keys and printing
that entry twice with nothing said.

**Outcome:** `index_argument` returns, beside the `\index{}` argument, the printed
level path it emitted and the filing path the index tool keys on; `clamped_paths`
collects filing paths per printed path in the LaTeX emit branch, and the document-wide
LaTeX pass reports each path filed under more than one key, once per path and naming
every key — a contestant filing under its own printed text named as that, not quoted
as a key. `examples/sortkey-clamp.qmd` (both collision shapes) and its shared-key twin
are checked through LaTeX, a hand-derived HTML manifest and the compiled PDF; README
documents the LaTeX-only fifth sort-key report, DESIGN's LaTeX bullet both reports.

**Decisions:** the report compares filing paths, not emitted arguments — `key@text` and
a bare `text` are one key to the index tool, which comparing arguments would split.

**Review:** three-lens fan-out. Blame-history none; prior-review one (the fixture-shape
check hardcoded `MAX_LEVELS`; it and `OVERFLOW_JOIN` are now read from the filter);
diff-bug six, having constructed neither a false positive nor a false negative. Fixed
at the gate: the keyless-contestant wording, the absent DESIGN entry, two README
overstatements, a self-test proving only the coarse substring.
