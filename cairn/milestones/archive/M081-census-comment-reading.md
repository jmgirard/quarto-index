# M081: The id census reads a comment where a browser reads one

**Status:** done (2026-09-06, PR #81 https://github.com/jmgirard/quarto-index/pull/81)

**Goal:** Two comment shapes the id census read wrongly are read the way a browser reads them in ordinary HTML: a construct a browser makes a comment and the walk read as markup, and the three comment ends the walk did not honour.

**Outcome:** `note_raw` in `_extensions/index/modules/html.lua` gained two branches. A `<!` opening anything but `<!--`, a `<?`, and a `</` before a non-letter now run to the next `>` and put no element on the page, so `<!ok>`, `<?ok>`, `<![CDATA[…]]>` and `</ ok>` no longer have their contents walked as markup and no longer take a name from a mark. A `<!--` now ends at an immediate `>`, an immediate `->` and a `--!>` as well as a `-->`, so the walk stops abandoning the rest of a raw string and a name past such a close is counted again instead of landing on two elements unreported. Twelve fixture marks in `examples/id-collision.qmd` and their rows in the M079-AC1 expectation dicts pin both shapes; two `--self-test` plants, one per repair, redden that check. `site/html.qmd` and `CHANGELOG.md` state the reading, each held by its own `sitecheck.py claims` rows and the site page also by a `phrase-absent` sweep over the retired sentence. KI257 and KI260 struck.

**Decisions:** none.

**Review:** three-lens fan-out. Prior-review lens none; blame lens one note; diff-bug lens seven, after exercising `note_raw` over 24 shapes. Eight actioned, none a criterion failure. Fixed on the branch at the maintainer's direction: the changelog's half of AC4 was guarded by nothing (new claims sweep), the numbering paragraph still enumerated `<!--` alone, a doctype was called a comment, and "hides a name inside them" over-claimed; two reflow and citation cleanups with them. Recorded instead: KI263 for the foreign-content CDATA divergence, and the fixture's non-discriminating CDATA case absorbed into the standing M079-instruments candidate row. M080's count lesson sharpened to cover enumerations.
