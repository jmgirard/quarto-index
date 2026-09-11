# M089: Two book-fixture hygiene gaps close

**Status:** done (2026-09-10, PR #89 https://github.com/jmgirard/quarto-index/pull/89)

**Goal:** Close the two suite-hygiene gaps the HTML book fixtures leave open: pages
a render writes beside a book project, which a commit can sweep in, and a
single-chapter leg that renders over whatever `_book` its copy holds.

**Outcome:** the root `.gitignore` ignores `examples/book*/*.html` and
`examples/book*/site_libs/`, covering the 22 files the reset M073 checkpoint 7c83a21
swept in (pinned locally as `refs/probes/m073-swept`) while hiding no tracked file.
`m069_cold_chapter` in `tests/run-tests.sh` removes its copy's `_book` with the store
before rendering, as `m069_tree` does, and its comment says an emptied `_book` then
holds the chapter's page and the book's `index.html` (KI231 struck).

**Decisions:** none milestone-local; the plan gate's three choices are in the work log (git).

**Review:** pass 1, three-lens fan-out, found no criterion failing. One finding fixed
before merge: the rewritten comment claimed `_book` held the chapter's page alone.
Three rejected: the added `rm` removes nothing today (the intended guard); the rules
miss a page beside a nested chapter (plan scoped them to a project's top level); the
`book*` pattern would match a future `examples/bookmarks/` (same reach as the rules
beside it). Re-run on the fixed head: suite 779 checks, 0 FAIL; CI green on PR #89.
Nothing graduated or retired.
