# M114: A principal mention in a LaTeX heading or caption builds

**Status:** done (2026-10-19, PR #114 https://github.com/jmgirard/quarto-index/pull/114)

**Goal:** A PDF built through LaTeX no longer fails to render because a heading or a figure or table caption carries a principal mention, and its index emphasizes that mention's page alone.

**Outcome:** Closes KI2 and KI74. `core.lua`'s `\quartoindexregister`,
`\quartoindexrangefrom` and `\quartoindexrangeend` keep their `[1]` form and
call `\qi@guard`: typeset, a `\protected` worker writes the `.aux` line; in a
copy, `\qi@copy` keeps the command only while `\index` means what it did at
`\begin{document}`, so contents lines, list lines and running heads drop it.
New: `examples/principal-headings.qmd` (default class, toc/lof/lot, running
heads, 16 pages), `tests/principal-headings-pdf.tsv`, the M114-AC1/AC2 suite
section, `pdfindex.read`'s `from_page`, KI317 (a `\nameref` copy registers).

**Decisions:** none milestone-local. AC2 narrowed once at a user stop, to its
index promise, after two re-audits; table captions joined the scope at plan.

**Review:** four-lens fan-out, 23 findings: 9 fixed (a second dahlia range
makes the range-closing plant red; docs and changelog narrowed; comments),
3 to the parked rows "Principal marks through nameref" and "Stand-in count
comment", 11 rejected. Suite 1788 checks green; CI green. M01 lesson extended
with the `\@gobble@som` gobbler; a plant-green-by-layout lesson not captured,
`check-design.md` being at its byte budget. No row unparked.
