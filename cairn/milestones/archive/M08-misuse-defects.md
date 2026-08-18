# M08: Reachable mark and marker misuse defects

**Status:** done (2026-08-18, PR #8 https://github.com/jmgirard/quarto-index/pull/8)

**Goal:** Four author-reachable misuse cases the earlier reviews left latent are
each reported and handled rather than silently mishandled.

**Outcome:** Three shipped. `mint_section_id` mints the HTML index section id
against `taken_identifiers` — the one generated id that had been fixed —
preferring the bare `qi-index`. In `Span`, a target whose `levels_key` equals the
mark's own is reported and dropped before the back-end branch, on printed levels
never the filing key, so the term indexes plainly. `report_marker_sites` walks
`doc.blocks`, reporting the marker class on any non-Div block or attributed
inline and editing nothing. `tests/htmlindex.py` gained `index_section` (finds
the section by its heading) and `duplicate_ids`; eight README sentences pinned.

**Decisions:** Milestone-local — a misplaced marker class is reported, never
edited away; a self-target is judged on what the entry prints.

**Review:** Three passes, three lenses on the first (two clean). Two defect
returns repaired — false-positive container reports, a metadata walk, false
README sentences, stale DESIGN prose. At the third the maintainer descoped the
emptied-container report under the thrash rule: its recursive rule is verified
correct, naming the container under Quarto's scaffold divs is not. Nine findings
on ROADMAP rows, the descoped work among them.
