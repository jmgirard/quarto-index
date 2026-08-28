# M54: The candidate backlog comes back under D-013

**Status:** done (2026-08-28, PR #54 https://github.com/jmgirard/quarto-index/pull/54)

**Goal:** Every finding restated in a `cairn/ROADMAP.md` candidate row moves to a labelled
`cairn/DESIGN.md` known issue, so each row states work and its promotion condition alone,
and a stated row shape keeps it that way.

**Outcome:** 72 finding clauses moved out of twelve rows into `## Known issues` as KI91-KI162
across five subheadings, plus KI163 (overlapping-range pairing) and KI164 (M30's print proof)
recovered by T3's word-conservation check over the removed lines. All 36 rows rewritten to work,
promotion condition, dates, sources and `KI<n>` pointers: 22,001 -> 9,051 bytes, largest exactly
400; ROADMAP 24,053 -> 11,483 bytes, back under its 24,000 budget. The `KI24, KI27-KI74` range
became a named reference to `cairn/DESIGN.md`'s two acceptance-suite subheadings plus `KI24`, and
the `KI73 struck` mention is gone. Nothing was dropped and nothing merged.

**Decisions:** D-034 (annotates D-013) — a row holds work, promotion condition, dates, sources
and `KI<n>` pointers under a 400-byte cap; a whole-subheading motivator names the subheading,
never a label range; enforcement is that rule and the comment, not a repo-local checker.

**Review:** one [O] diff-bug reviewer (internal tier, markdown-only diff), 13 findings, none
failing a criterion; six actioned and fixed on the branch (KI24 restored, a subheading reference
naming the wrong document, KI164's wrong provenance, two rows with no promotion condition, a
stray comma, a superseding work-log line), seven rejected. F1's residual — the subheading form
over-claiming after those subheadings grew ~70 entries — is now KI165.
