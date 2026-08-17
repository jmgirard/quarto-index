# M03: HTML index back-end

**Status:** done (2026-08-17, PR #3 https://github.com/jmgirard/quarto-index/pull/3)

**Goal:** Realize the existing format-neutral marks in single-document HTML output: an auto-appended index section with linked locators and cross-references.

**Outcome:** HTML back-end in index.lua: per-mark anchors — an author id is kept and linked, anything else minted `qi-mark-N` skipping every id the document already uses (raw-HTML ids included, any capitalization); heading marks anchor on empty spans emitted just after the heading, never inside it (Quarto copies heading inlines into the TOC), footnote contents exempt from relocation; author-forged `data-qi-pending` stripped. The `qi-index` section is built from Pandoc AST nodes: unnumbered TOC-listed heading, normative collation (ASCII fold, codepoint ties), unlimited nesting, numbered locator links, cross-references with M02 target semantics deduped on level lists and linked to `qi-entry-N` when resolved. Format-neutral warnings moved before the back-end branch; the 3-level clamp, fold warning and clash report stay LaTeX-only. Suite: `tests/htmlindex.py` structural HTML reading, hand-derived manifests (demo 43, placement 8, html-index 11, xref 8 rows), anchor-count pin with named invariants, escaping-probe HTML check, gfm/control negatives, review-time merge-base `.tex` byte-diff (LaTeX untouched).

**Decisions:** milestone-local — `qi-` identifier namespace; author ids kept and linked, later narrowed: relocated out of headings when the pass-2 gate superseded heading-id borrowing with after-heading anchors; a repeated cross-reference target renders once.

**Review:** three passes, three-lens fan-out each. Pass 1: 16 findings, AC4 failed (string-keyed dedupe) — returned. Pass 2: three same-shape AC3 mechanisms (heading-id borrowing) — returned; the recorded alternative adopted. Pass 3: 8 findings, no criterion failure; F1–F6 fixed at the gate with discriminating fixtures, F7 left recorded (AC3's dead disjunct), F8 a candidate row. 2 defect returns, 2 amendment returns (AC3 — stop reached). Two lessons captured at hygiene.
