# M119: A Typst cross-reference mark keeps one label wherever it sits

**Status:** done (2026-10-20, PR #119 https://github.com/jmgirard/quarto-index/pull/119)

**Goal:** A test shows that a Typst cross-reference mark gets one label that a link can reach in each place where a label was once copied.

**Outcome:** Strikes KI325 and extends KI290. `examples/typst-xref-places.qmd`
puts a cross-reference mark in a listed heading, three listed captions, an
image's alt text, a footnote and a callout's title attribute, first heading
and body, with 13 author ids and a page of links. Its suite section checks
the index against `tests/typst-xref-places.tsv`, each label of a `metadata`
element against `quarto typst query` (new reader `tests/typstlabels.py`), and
each link's page against `tests/typst-xref-places-links.tsv`; 15 plants. Fix:
`typst.assign_labels`'s `Image` walk moves an author's id on an alt-text mark
to just after the image as an `id_inline` element, which now opens with the
comment `/* qi-id */`, so `caption_moves` and the `Image` walk move only the
filter's own id elements. Docs state it with the KI290 float exception.

**Decisions:** none.

**Review:** four lenses, 19 findings: 6 fixed (a nested alt-text image's id,
the docs' KI290 exception, a JSON read that raised), 2 to follow-up
("Floor-Quarto CI suite job", "Laid-out float caption marks" through KI290),
11 rejected. Claim audit: 51 claims, 6 corrected. CI green on the floor and
pinned Quarto. Narrowed "Older acceptance-suite backlog" (KI325).
