# M52: EPUB gets an index back-end

**Status:** done (2026-08-28, PR #52 https://github.com/jmgirard/quarto-index/pull/52)

**Goal:** An EPUB render gets the index the HTML back-end builds — entry tree, letter groups,
cross-references, locator links — not marks passed through.

**Outcome:** `core.lua` gains `is_epub` (FORMAT matching `epub`, so `epub2`/`epub3` too) and
`builds_ast_index` (`is_html` or `is_epub`), routing `indexes.builds_index`, `passes.lua`'s
per-mark record and `index.lua`'s AST back-end branch; `is_html` stays the sole gate on the
sidecar store, the fold, the dangling gate and the chapter-scope wording, because Quarto
renders an EPUB book in one Pandoc process as it does a PDF one — every declared index prints
under its own title and a cross-chapter range pairs. `tests/epubindex.py` reads a container
through `htmlindex.parse_text`; `epubcheck.py` carries the criteria's checks. `site/epub.qmd`
is new, `site/books.qmd` scopes its per-chapter model to the HTML book, and `sitecheck.py`
gains `claims`, `phrase-absent` and `RENAMED_HEADINGS`.

**Decisions:** two milestone-local, in git — a heading renamed after the M40 move is recorded
in a map, not backfilled into the fixture; the fold sentence is pinned to its three occurrences
in the filter source rather than scanned for.

**Review:** three-lens fan-out — blame-history 0, prior-review 1, diff-bug 13. Five fixed
before merge (the "two back-ends" count on README and three site pages, the Books page's
HTML-only model, the book EPUB's links unchecked, a missing blockquote strip regressing the M41
lesson), nine filed. No criterion failed. 824 checks green.
