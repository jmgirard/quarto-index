# M101: A mark in a figure caption or an image's alt text files one locator

**Status:** done (2026-09-14, PR #101 https://github.com/jmgirard/quarto-index/pull/101)

**Goal:** In every back-end, a mark in a figure caption or alt text files one
locator, and its link target exists on the page.

**Outcome:** `marks.declass_caption_copies` takes the index class and id off
the alt-text copy Pandoc makes of a figure's caption. `TagPandoc` and
`book.lua`'s `recovered_marks` call it. `assign_anchors` moves
an alt-text mark's id to an empty span after the image, and
`latex.move_alt_commands` moves its `\index` there. New:
`examples/figure-marks.qmd`, four manifests, `tests/figuremarks.py`, two HTML
book cases, five plants, the fixture on `versions.yml`. KI294, KI295 closed.

**Decisions:** the plan chose to declass the copy, because removing it
changes the `alt` text. It moved alt-text targets in HTML, EPUB and LaTeX
here. The matrix uses its HTML cross-version comparison for the fixture.

**Review:** one round, three lenses. The diff reviewer found nine. F5 (the
LaTeX prefix) and F6 (a stale comment) were fixed at the gate. F1-F2 (a
shortcode caption files twice) are documented, with KI299 and a candidate
row. F3-F4 are KI300, KI301 and a candidate row. F7-F9 were rejected. Suite
1704 and matrix 34891292868 green. Nothing graduated or retired.
