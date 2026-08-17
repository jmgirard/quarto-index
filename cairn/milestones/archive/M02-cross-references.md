# M02: Cross-references (see / see also)

**Status:** done (2026-08-16, PR #2 https://github.com/jmgirard/quarto-index/pull/2)

**Goal:** Add see / see-also index entries to the marking syntax, realized by
the LaTeX back-end with format-neutral target semantics.

**Outcome:** `see=`/`see-also=` work on any mark form. Targets parse into levels
with `entry=`'s `!`/`!!` semantics, drop empty levels with a warning, join with
`: `, reuse `LATEX_LITERAL`; parsing is format-neutral, so misuse warns in every
format. LaTeX emits `\index{source|see{target}}` via makeindex's encap channel,
where `\see`/`\seealso` discard the page — a cross-reference replaces the
locator, so `see-also=` carries no locators either (documented limitation). Both
attributes on one mark emit ONE command, `\quartoindexseeboth`, injected only
when used and labelled via `\seename`/`\alsoname`. Four new warnings plus a
clash report keyed on distinct encap strings. Suite: 28 checks, a 256-entry
probe (printable ASCII in targets AND source keys, non-ASCII), README pin.

**Decisions:** five milestone-local — emission form; `: ` join; no character
unrealizable in encap context; a superseding correction; clash-report scope.

**Review:** three lenses, 19 findings. 15 fixed pre-merge, notably a false README
claim that `see-also=` yields page numbers (its workaround could break builds)
and a clash detector blind to see-vs-see-also. 2 to ROADMAP rows, 1 no action, no
regressions. Nothing retired; 3 lessons captured.
