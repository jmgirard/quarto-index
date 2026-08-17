# M01: LaTeX index extension skeleton

**Status:** done (2026-08-16, PR #1 jmgirard/quarto-index#1)

**Goal:** Ship the quarto-index skeleton: span-syntax index marks to LaTeX
`\index{}` with automatic preamble and `\printindex`, verified to a PDF.

**Outcome:** `_extensions/index/` ships four span forms — visible-term,
custom-entry, sub-entry, invisible. `entry=` parses into `!`-separated levels
(`!!` a literal `!`), each level literal text the filter escapes itself; `|`,
`"`, `{`, `}` emit as LaTeX commands, since hyperref, quote rendering and
`\@sanitize` each defeat the obvious escape. Levels past three fold into the
third with a warning. With ≥1 mark it injects `imakeidx` + `\makeindex[intoc]`
and one `\printindex`; `latex`/`pdf` only — beamer and HTML pass text through
(IP2). `tests/run-tests.sh` (PROFILE `verify`) runs 13 checks over four
hand-derived manifests, an all-printable-ASCII escaping probe compiled through
Quarto's engine, and a planted-defect self-test.

**Decisions:** two milestone-local — the per-character escaping mechanism, and
that compiling settles survival while only typesetting settles printing.

**Review:** four passes, three defect returns — fatal beamer render, silent
loss of >3-level entries, AC7 counting nothing, an unbalanced brace aborting
the build, content deletion when a mark yielded no text. All fix-now findings
applied; remainder ROADMAP rows. Nothing retired; 5 lessons captured.
