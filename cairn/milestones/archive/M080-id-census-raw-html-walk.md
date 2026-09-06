# M080: The id census reads a page's raw HTML the way a browser does

**Status:** done (2026-09-06, PR #80
https://github.com/jmgirard/quarto-index/pull/80)

**Goal:** No `id=` an element of the rendered page carries goes uncounted by the
id census, and none written where the page renders no element is counted
against a mark.

**Outcome:** `note_raw` in `_extensions/index/modules/html.lua` now tells an
opening tag from a closing one, so a closing tag's attributes claim nothing and
the skip fires only on an opener; its two-name `script`/`style` test became a
declared `RAW_TEXT_ELEMENTS` table of seven whose end tag is matched by name
rather than by prefix. `tests/htmlindex.py` names the same seven,
`examples/id-collision.qmd` gained twenty marks, the M079-AC1 tables grew with
them, and `site/html.qmd` and `CHANGELOG.md` state the rule, give `title` as one
uncovered element without counting them, and name what the walk still misreads.

**Decisions:** none milestone-local.

**Review:** two rounds, three lenses each. Round 1 returned AC6 as an amendment
return — naming `title` as the one uncovered element mandated a false sentence —
repaired by narrowing the promise under two fresh-context re-audits. Round 2:
ten findings, seven fixed on the branch (a false shape count on both pages and
four overstated claims among them), one rejected, the rest as KI260-KI262.
