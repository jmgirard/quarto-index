# M085: One answer to whether a link leaves the publication

**Status:** done (2026-09-10, PR #85 https://github.com/jmgirard/quarto-index/pull/85)

**Goal:** One definition decides whether an href leaves the publication, and
the suite's four link readers reach their verdict through it.

**Outcome:** `htmlindex.leaves_publication` strips the href, cuts it at the
first `#`, and answers "leaves" for a value opening `//` or matching an
anchored RFC 3986 scheme, case-insensitively. Four readers route through it and
their own tests are gone: `resolve_href`'s `'://' or mailto:` test,
`epubcheck`'s local `SCHEME` regex, `sitecheck`'s six-name `NON_LOCAL_SCHEMES`
list, and `epubindex.links`, which had no test at all and now marks a `leaves`
row that `unresolved` skips and `epubcheck.cmd_links` counts on its ok line.
Evidence: `M085_HREF_SHAPES` in `tests/run-tests.sh` (14 shapes, 9 leaving,
5 staying) driven through all four readers at their own call sites, plus four
EPUB repacks, four HTML-page plants and three site plants, each shown red first.

**Decisions:** none milestone-local; the rule is D-057.

**Review:** three-lens fan-out; blame-history and prior-PR-comments found no
regression (no inline PR comments exist here; the archive was the surface).
Diff-bug found eleven: two fixed before merge, both stale module docstrings
still stating the pre-M085 contract; five routed to one candidate row and to
KI268/KI269; three rejected. KI98 struck, KI120/KI266 corrected, KI267 added.
