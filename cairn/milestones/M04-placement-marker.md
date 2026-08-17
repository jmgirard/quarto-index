# M04: Index placement marker

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP4, GP5
- **Branch/PR:** —

## Goal

Ship a format-neutral placement marker — an empty div with class
`qi-index-here` — that puts the index where the author wrote it, in every
back-end, with today's auto-append preserved when no marker is present.

## Scope

Surface tier: **user-facing** — new documented authoring syntax for the
extension's community audience.

**In:** marker recognition (top-level blocks only); HTML back-end emits the
index section at the marker's site; LaTeX back-end emits `\printindex` at the
marker's site; append suppression when a marker placed; misuse handling
(duplicate, nested, no-marks) warned in every format; pass-through residue
sweeps; docs. Marker token is `qi-index-here`, deliberately distinct from the
generated section id `qi-index` (ROADMAP F11 row records that collision
class).

**Out:** book projects (marker-as-aggregation-site) → M05. Nested-marker
placement support → widen later compatibly if demanded (candidate behavior:
top-level only, stated in README). Letter groups, sort keys → existing
candidate rows.

## Acceptance criteria

- [ ] AC1: In a single-document HTML render whose source carries one marker
      between two body sections, the index section appears at the marker's
      position — after the first section's content and before the second's —
      and nowhere else on the page (structural position check over the
      rendered page), and the page's index content matches its hand-derived
      manifest.
- [ ] AC2: In that same document rendered to LaTeX, exactly one `\printindex`
      is emitted, at the marker's position between the two sections' text
      (asserted on the emitted `.tex`), and the document renders to PDF whose
      index slice — bounded from the Index heading to the following section
      heading's text, not end-of-file — contains each fixture term.
- [ ] AC3: Every existing LaTeX fixture's `.tex` output is byte-identical to
      the merge base, per the byte-diff procedure extended to loop over all
      existing LaTeX fixtures; the full suite passes with a printed check
      count not lower than at the merge base.
- [ ] AC4: Misuse renders safely in every output format, warnings emitted
      before the back-end branch (warning-split check extended): a second
      marker warns identifying it by position and leaves no element residue;
      a nested (non-top-level) marker warns, places nothing, leaves no
      residue; a marker in a document with no index marks leaves no residue
      and emits no index section or `\printindex` in either back-end —
      residue asserted structurally (no empty div/group), not by token grep.
- [ ] AC5: The marker fixture rendered to gfm contains no residue of the
      marker (no marker element, no empty div, no token), and the marker
      fixture added to the existing beamer render compiles clean with no
      residue (IP2).
- [ ] AC6: The README documents the marker with an exemplar row in the
      suite's `SUPPORTED_FORMS` roster, and the now-false sentence
      "Placement is automatic; there is no option to put the index elsewhere
      yet" is captured in `README_STALE` so it cannot survive verbatim.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T3, T4
- AC3 → T4
- AC4 → T1, T2, T3, T4
- AC5 → T4
- AC6 → T5

## Tasks

- [ ] T1: Marker recognition (top-level `doc.blocks` walk; class
      `qi-index-here`), format-neutral misuse warnings (duplicate by
      position, nested, no-marks); fixture `examples/marker.qmd` (marker
      between two sections; duplicate + nested + no-marks variants) with
      hand-derived manifests.
- [ ] T2: HTML back-end: emit section at the marker site, suppress append
      when a marker placed (index.lua `append_html_index`, Pandoc pass).
- [ ] T3: LaTeX back-end: `\printindex` at the marker site, suppress
      append; shared marker resolution with T2 so the two back-ends cannot
      drift.
- [ ] T4: Suite: document-order position primitive in `tests/htmlindex.py`;
      bounded PDF index slice; byte-diff loop over all existing LaTeX
      fixtures; warning-split check extension; gfm + beamer marker-fixture
      renders with structural residue checks; merge-base check-count pin.
- [ ] T5: Docs: README marker section (+ `SUPPORTED_FORMS` and
      `README_STALE` rows), DESIGN.md architecture lines updated ("one
      `\printindex` appended" / "index section appended" become
      marker-aware).

## Work log

- 2026-08-17: created by /milestone-plan.
- 2026-08-17: criteria audit ran in full mode, two rounds ([O] fresh reader; second round after the gate widened the marker to all back-ends): round 1 — AC positives unpinned, missing location axes, undecidable book warning, instrument-bound suite clause; round 2 — unsound end-of-file PDF slice, byte-diff covering only demo.qmd, unenumerable "no assertion weakened" clause, vacuous pass-through sweep, marker/section-id name collision, missing docs criterion. All fixed in the wording above or moved to tasks; none left open.
- 2026-08-17: plan gate chose one marker honored by all back-ends over a book-HTML-only marker because one syntax must not carry per-format meaning (IP1) and it absorbs the placement candidate row; falsified by a back-end where site-placement is impossible to realize.
- 2026-08-17: plan chose top-level-only marker recognition (nested warns, places nothing) over recognize-anywhere because `\printindex` inside a group/environment is an IP2-class render risk; falsified by evidence that nested placement is safe in both back-ends or by author demand.
- 2026-08-17: plan chose marker token `qi-index-here` over reusing `qi-index` because the generated section already owns that id and one string with two meanings is the F11 collision class; falsified by nothing cheaper than a rename before first release (IP3).

## Decisions

## Review
