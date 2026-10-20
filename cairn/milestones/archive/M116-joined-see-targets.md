# M116: One see-word for each kind of cross-reference

**Status:** done (2026-10-20, PR #116 https://github.com/jmgirard/quarto-index/pull/116)

**Goal:** An index term with two or more cross-reference targets of one kind prints that kind's word once, in front of all its targets of that kind, in the LaTeX, HTML, EPUB and Typst indexes.

**Outcome:** Narrows KI9 to its locator half. LaTeX `fold_xrefs` writes one
`\see{A; B}{}`/`\seealso{...}{}` per kind; `build_entry_tree` (entries.lua)
groups targets by kind, `see` first, arrival order inside a kind, for HTML,
EPUB, the HTML book and Typst; `entry_inlines` and `entry_lines` write the word
on a kind's first target only, each HTML target keeping its `qi-xref` span.
The contested-key report counts distinct targets: two new wordings (a plain
mark beside two or more, three or more with none), so `xref-conflict`'s `phi`
now draws the plural one. New: `examples/xref-joined.qmd`, its twin
`xref-joined-separator.qmd`, `examples/book-xref/`, a suite section with a
self-test; `htmlindex.py` requires the word on a kind's first span only;
`typstindex.printed_text` and `typstcheck.py source` read a joined kind.

**Decisions:** none milestone-local.

**Review:** four-lens fan-out, one pass; 28 findings: 12 fixed (comments,
an EPUB separator check, a dead PDF join, the Typst source derivation, four
doc passages), 2 follow-ups (KI319 with parked row "Semicolon in a
cross-reference target"; KI320), 14 rejected. Claim audit at implement: 58
claims, 7 corrected. LESSONS: added the M116 fixture-registration line.
