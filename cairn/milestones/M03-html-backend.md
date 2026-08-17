# M03: HTML index back-end

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M02
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP4, GP6
- **Branch/PR:** m03-html-backend

## Goal

Realize the existing format-neutral marks in single-document HTML output: an
auto-appended index section with linked locators and cross-references.

## Scope

Surface tier: **user-facing** — a new back-end for extension users (full
criteria audit applied).

**In:**
- HTML output (`FORMAT` matching `html` only; revealjs/epub stay pass-through)
  gets an anchor at each locator-contributing mark site and one auto-appended
  index section at the end of the body (GP4 zero-config), identified by a
  pinned section id, with an unnumbered "Index" heading that enters the TOC.
- The section is built from Pandoc AST nodes, never raw HTML strings (IP2:
  Pandoc's writer owns escaping). No CSS is injected; nested lists render
  under Quarto's defaults.
- Locators are numbered links (1, 2, 3 in document order) to the anchors.
  Cross-reference marks contribute no locator (gate: match LaTeX semantics).
- Entries sort by the normative collation rule: ASCII-lowercase fold, then
  codepoint order, ties by codepoint (DESIGN best-effort collation).
- Sub-entries nest at every depth — no level ceiling in HTML; the 3-level
  clamp and its fold warning are makeindex properties and stay LaTeX-only.
- `see`/`see also` render with M02 target semantics (levels join `: `),
  hyperlinked when the target key exists in the index (matched on parsed
  level lists, never rendered strings), plain text otherwise.
- Entry-parse warnings that are genuinely format-neutral (empty level,
  reworded to name no back-end) move before the back-end branch — absorbs the
  ROADMAP candidate from M01 review R19. The clash report stays LaTeX-only.

**Out:**
- Multi-file book aggregation → existing candidate row.
- Explicit placement option → existing candidate row (GP5; M01 rationale).
- Letter-group headings → new candidate row (needs diacritic folding; sort keys).
- see-also entries keeping locators (print convention) → new candidate row
  (a cross-format decision, taken for both back-ends at once).
- epub/revealjs back-ends, CSS styling, non-Latin collation → not planned;
  candidates when demanded.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh --self-test` passes. Existing M01/M02 checks
      keep their meaning, with two owned exceptions: the AC7/M02-AC4 no-leak
      block is retargeted (AC3), and the xref-conflict HTML comment's
      "no back-end" rationale is updated (the clash report stays LaTeX-only
      as a makeindex property). As one-shot review evidence — never a
      checked-in snapshot — `examples/demo.qmd` rendered `--to latex` on the
      branch is diffed against the same render at the merge-base on the same
      machine: the emitted `.tex` is byte-identical.
- [ ] AC2: `examples/demo.qmd --to html` yields exactly one generated index
      section (pinned section id). Its entries match a hand-derived manifest
      row-for-row — entry text, nesting depth, order under the normative
      collation rule, per-entry locator count — and the manifest is
      exhaustive: a rendered entry absent from it fails. The Latin-1 rows
      (café naïve; Grüße → Straße) pin IP2's non-ASCII clause. The same
      manifest discipline covers a new placement fixture whose repeated
      entry's marks sit in a heading, a table cell, and a footnote, pinning
      locator numbering where Pandoc relocates content. The visible-terms
      manifest rows are unchanged; extraction is retargeted
      (attribute-order-proof, scoped outside the generated section).
- [ ] AC3: In demo.html, every locator-contributing mark emits exactly one
      anchor matching the pinned id scheme, document-unique; every href
      inside the generated index section resolves to an id in the same file;
      the anchor count is pinned to a source-derived mark count whose
      fixture invariant (demo.qmd holds no textless mark) the check reports
      by name. The reworked no-leak check passes: every `entry=`/`see=`/
      `see-also=` value is absent from the rendered body with the generated
      index section excised, with the source-pinned completeness check
      retained.
- [ ] AC4: Cross-reference entries in generated HTML indexes render with M02
      target semantics, labelled see/see also, hyperlinked exactly when the
      target key exists (parsed-level-list match), plain text otherwise;
      linked, unlinked, and the colliding-string negative (a `: `-containing
      single level vs a real two-level target) are all fixture-present in
      `examples/xref-conflict.qmd`'s HTML render, manifest-checked; no
      cross-reference mark contributes a locator (fenced by AC2's exhaustive
      locator counts).
- [ ] AC5: `examples/escaping.qmd --to html`: for every printable ASCII
      character except space (the fixture's by-construction domain, pinned
      by the existing coverage check), the set of entry texts extracted from
      the generated index by an HTML-parsing check contains that character
      as an exact element.
- [ ] AC6: Negatives: `examples/control.qmd --to html` contains no generated
      index section and no anchor-scheme id; `examples/demo.qmd --to gfm`
      renders clean with no index section and no anchor artifacts (the
      newly format-neutral warnings run there); the existing beamer checks
      pass.
- [ ] AC7: README documents the HTML back-end. Grep-pinned in the suite,
      SUPPORTED_FORMS-style: the three stale pass-through sentences are gone
      ("formats with no index back-end — HTML and beamer", "In formats with
      no index back-end, a cross-reference mark is simply a mark",
      "LaTeX/PDF is the back-end that ships today"); a beamer-scoped
      pass-through sentence is present; and each row of an enumerated
      divergence list appears — no level ceiling in HTML, clash warning
      LaTeX-only, the collation rule, locators as numbered links, targets
      hyperlinked when resolvable, cross-references carry no locator in
      either back-end.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T4, T5
- AC3 → T1, T5
- AC4 → T3, T6
- AC5 → T5
- AC6 → T5
- AC7 → T7

## Tasks

- [ ] T1: Refactor the Span pass ([index.lua](../../_extensions/index/index.lua)):
      move format-neutral warnings (empty-level, reworded) before the
      back-end branch, keep clamp+fold LaTeX-only, add an HTML branch that
      records marks and emits pinned-scheme anchors for locator-contributing
      marks; `html` match only.
- [ ] T2: HTML Pandoc pass: build the index section from AST nodes — pinned
      section id, unnumbered TOC heading, normative collation, unlimited
      nesting, numbered locator links.
- [ ] T3: HTML cross-references: labels, parsed-level-list target matching,
      links, no locator; update xref-conflict.qmd's stale comment rationale.
- [ ] T4: New placement fixture (heading / table cell / footnote) with
      hand-derived manifest.
- [ ] T5: Suite rework: retarget visible-terms extraction; scope no-leak
      outside the index section; add exhaustive HTML index manifests, href
      resolution, anchor counts with named invariant; escaping-probe HTML
      check (exact-element); gfm + control negatives; document the
      review-time merge-base `.tex` diff procedure.
- [ ] T6: Extend xref-conflict.qmd with linked-target and colliding-string
      cases; hand-derive its HTML index manifest.
- [ ] T7: README HTML section (divergence list, stale sentences replaced)
      with suite grep pins; fill DESIGN.md Architecture (two back-ends,
      shared format-neutral layer).

## Work log

- 2026-08-16: created by /milestone-plan; promotes ROADMAP candidate "HTML index generation" and absorbs "empty-level warning fires only on the LaTeX branch" (M01 review R19).
- 2026-08-16: criteria audit ran in full mode ([O] fresh reader): 24 findings — unsatisfiable AC1, snapshot sort-order oracle, unpinned section/anchor markers, fixture gaps (linked target, placement hostility), hand-list README pins among them — all repaired in the AC wording above; 4 open findings gated (locators, see-also, warning row, letter groups).
- 2026-08-16: plan gate chose numbered locator links over section-title links because they are predictable, compact, and testable; falsified by user or community feedback preferring section labels.
- 2026-08-16: plan gate chose no-locator-from-xref-marks (matching LaTeX) over HTML realizing the print convention because cross-format semantics stay aligned; falsified by a cross-format decision to keep see-also locators in both back-ends (candidate row).
- 2026-08-16: plan gate chose a flat nested list over letter-group headings because grouping forces diacritic-folding decisions best settled with sort keys; falsified by the sort-key feature landing or user demand.
- 2026-08-16: plan chose normative collation (ASCII fold, codepoint order) over implementation-defined order because manifests need a hand-derivable oracle; falsified by non-Latin corpora needing real collation.
- 2026-08-16: plan chose no HTML level clamp over mirroring makeindex's 3-level ceiling because the ceiling is a back-end property (IP1); falsified by cross-format consistency complaints from users.
- 2026-08-16: plan chose an AST-built index over raw HTML strings because Pandoc's writer owns escaping (IP2); falsified by an index shape AST nodes cannot express.
- 2026-08-16: plan chose a review-time merge-base diff over a checked-in golden `.tex` because the suite's oracle rule forbids snapshots; falsified by LaTeX regressions repeatedly slipping in between reviews.
- 2026-08-16: plan chose no injected CSS over a styled index because nested lists render acceptably under defaults (GP4); falsified by the extension-listing quality bar demanding styling (GP1).

- 2026-08-16: /milestone-implement started; branch m03-html-backend cut from main.

## Decisions

## Review
