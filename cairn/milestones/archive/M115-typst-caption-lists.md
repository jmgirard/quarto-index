# M115: Typst caption marks and a list of figures

**Status:** done (2026-10-19, PR #115 https://github.com/jmgirard/quarto-index/pull/115)

**Goal:** In a document rendered to Typst, a mark in the caption of a figure, a table or a code listing files the page its caption prints on, also where a list of those floats copies the caption.

**Outcome:** Narrows KI290. A last filter stage, `typst.figure_labels` (Pandoc
`Figure`) and `typst.float_labels` (Quarto `FloatRefTarget`), moves each caption
label, and each mark's author id via `id_inline`, into a float's content when
that content is one Plain/Para (appended) or one Table/CodeBlock (Div wrapper);
any other float keeps them in its caption (KI290). New: fixtures
`typst-caption-lists.qmd` and `typst-caption-layout.qmd` (unmarked twins),
three manifests, `tests/typstlists.py`, a suite section with twelve self-test
plants, a pinned-leg lists step in `versions.yml`, KI318 (breakable floats).

**Decisions:** none milestone-local. Scope narrowed twice at the user's thrash
stop chips, to one-block, then to paragraph, table or code-block content.

**Review:** five passes, four-lens fan-out each; 121 findings: 4 defect
returns (an id stealing a label, merged layout cells, a kept image width, a
code cell's float moved to the margin), 74 fixed, 3 to candidate rows
("Breakable float caption marks", "Laid-out float caption marks", absorbed into
"Floor-Quarto CI suite job"), 43 rejected. Candidate row "Typst caption marks
and a list of figures" graduated. LESSONS: added the M115 float-content line;
pruned the stalest M03 raw-HTML and M05 link-target lines at the cap.
