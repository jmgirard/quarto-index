# M084: The id-census AC1 leg tells apart what it claims to

**Status:** done (2026-09-08, PR #84 https://github.com/jmgirard/quarto-index/pull/84)

**Goal:** Every check, reader and plant it names is shown red on the defect
class it claims to catch.

**Outcome:** `htmlindex.minted_anchors` returns one (printed text, id) pair per
ELEMENT, and the M079-AC1 leg groups them by printed text requiring exactly one
anchor per term — where the map it replaces, keyed by that text with the first
winning, read two anchors as one. `_Builder.parse_html_declaration` ends a
`<![CDATA[` at the first `>`, the reading `html.lua` already took, so reader and
census agree about an `id=` between that `>` and the `]]>`; the fixture writes
that shape as `mid-cdata` / `between-cdata` (mark count 66 → 67), held red by the
`cdata-to-marked-close` census plant. The M075 plant helper runs against two
purpose-written sources and two copies of its own bytes with one M077 repair
reverted each, and M083's EPUB plants derive their locator from the member.

**Decisions:** none.

**Review:** three lenses; blame-history and prior-review found nothing, diff-bug
seven. Fixed before merge: a design-note implying the fixture fenced both
readers, a comment miscalling both plant copies pre-M077, a crash on a valueless
`id=`. Follow-ups: the self-test over a copy of the leg's read, the unscoped
locator derivation, the XHTML reading (KI265). One rejected.
