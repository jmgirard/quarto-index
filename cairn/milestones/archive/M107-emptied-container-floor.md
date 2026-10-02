# M107: An emptied container renders on Quarto 1.5.52

**Status:** done (2026-10-02, PR #107 https://github.com/jmgirard/quarto-index/pull/107)

**Goal:** On Quarto 1.5.52, each container shape in `examples/marker-shapes.qmd`
renders to GitHub markdown, Word, EPUB and Typst without its marker.

**Outcome:** `strip_nested_markers` leaves one empty `pandoc.Plain({})` in a
block list it empties. `marker_content` drops empty Plains before it judges
or splices a marker's content. The `versions.yml` render job renders
marker-shapes to gfm, docx, epub and typst on every leg. Two suite checks pin
the kept LaTeX figure caption and the missing `callout-empty-content` class.
On 1.10.18 the LaTeX and Word output now keep the marker-only figure and its
caption. A CHANGELOG entry and a DESIGN.md sentence state the fill.

**Decisions:** D-066 allows AC3's `diff -w` across commits. The fill is not
gated on the Quarto version (D-060).

**Review:** three lenses, F1-F14, no failing criterion. F3-F7 and F10, stale
prose, were fixed at the gate. F1-F2, the unnamed Word caption, became a
candidate row. The other eight were rejected. Matrix run 36957701710 and PR
checks were green, and the suite passed 901 checks.
