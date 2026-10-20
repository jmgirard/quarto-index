# M121: Three anchor checks read clashing ids

**Status:** done (2026-10-20, PR #121 https://github.com/jmgirard/quarto-index/pull/121)

**Goal:** Three acceptance-suite checks of index anchors fail on a defect that a page with clashing element ids can hide from them today.

**Outcome:** Strikes KI274, KI267 and KI126. `examples/id-collision.qmd` gains
`iota`, printed by two cross-reference marks whose ids two divs carry (69
marks); the M079-AC1 leg maps each `CONTESTED_XREF` term to its marks' ids,
counts `YIELDS` per mark, and holds each term to that many minted anchors.
`htmlindex.index_sections` skips an `authored` id's element only when it has
no heading; `epubcheck.py links --authored` reads `id-collision.epub` (70 of
70 links), fails on a named id no element carries, and counts the skipped
elements. `ID_COLLISION_CLAIMED` holds the five ids for M08-AC1 and
M121-AC2. `indexdump.py`'s `minted_links_land` holds each same-page index
link with a minted-prefix fragment to one carrying element. Plants for each.

**Decisions:** none.

**Review:** four lenses, 24 findings: 14 fixed (the author-id skip scoped to
headingless elements, pinned `links` counts, plant wants, a one-change
doubling plant, a repack control, docstrings, the two-group guard), 10
rejected, none to follow-up. Suite 1878 green; CI green on both
version-matrix legs. Graduated "Cover clashing ids in anchor checks". No
lesson; no row unparked.
