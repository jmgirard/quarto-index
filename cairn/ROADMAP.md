# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-18 (M11 planned — the leading/medial empty-level row graduated into it, carrying its M10 review F2/F5 widening; the M10-F8 double-fold-warning row stays open until M11 retires it. Earlier: M10 done and archived; the surviving-self-reference row graduated at plan time, the empty-levels row widened with the leading-empty behaviour change and the trailing-vs-leading null-field asymmetry, two new rows from M10 review; 4 lessons captured, none retired; M05's terminal row pruned to the 5-row retention; caps and byte budgets clean)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M11 | Empty index levels never lose the entry | in-progress | — | normal | milestones/M11-empty-levels.md |
| M10 | Self-references the level fold and empty levels hide | done | — | normal | milestones/archive/M10-selfref-fold-empty.md |
| M08 | Reachable mark and marker misuse defects | done | — | normal | milestones/archive/M08-misuse-defects.md |
| M09 | Sort keys under the LaTeX level clamp | done | — | normal | milestones/archive/M09-sortkey-clamp.md |
| M07 | Letter-group headings (HTML index) | done | — | normal | milestones/archive/M07-letter-groups.md |
| M06 | Sort keys | done | — | normal | milestones/archive/M06-sort-keys.md |
<!-- rows grouped by status, not sorted by ID; keep only the 5 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- unnumbered ideas; one line each: idea — added YYYY-MM-DD — links -->
- First tagged release (window user-declared, never agent-proposed) — added 2026-08-16
- Chapter-based locator labels in the book HTML index (e.g. 2.1 instead of 1, 2, 3) — added 2026-08-17 — M05 gate kept numeric locators; promote on reader evidence that numeric locators fail in long books
- Page-range & styling control (open/close marks, principal-mention locators) — added 2026-08-16 — suite target
- Multiple named indexes (e.g., subject + author) — added 2026-08-16 — suite target
- Quarto version floor + CI matrix (floor + latest) — added 2026-08-16 — contract-boundary commitment (DESIGN)
- Submit to Quarto extension listing at first release — added 2026-08-16 — window user-declared
- A cross-reference target that resolves to no entry is never reported: in HTML the three M10 fold shapes keep a target rendered as plain text with no href, and LaTeX diagnoses and drops the same marks while HTML ships the dangling target silently — added 2026-08-18 — M10 review F9; consistent with M10's gate reading of IP1, but nothing tells the author
- Non-Latin-1 scripts in index terms (Greek, CJK, combining marks, RTL) need an engine/font decision — added 2026-08-16 — M01 review R7/R9; pdflatex default fonts do not cover them
- Acceptance-suite hardening (clustered): brace-aware `\index` scanner (no longer benign now that unbalanced braces are probed); BSD-sed portability; `]{.index` substring undercount; `include_text` guard; the run fails on a clean checkout (a check reads examples/control.tex before anything renders it); no structural residue check on LaTeX misuse output; three renders write examples/marker.tex in one run; the check-count baseline is not mechanized — added 2026-08-16, extended 2026-08-17, clustered 2026-08-18 — M01 review R14/N12/N13/N14, M04 review F9/F10/F13 + a clean-clone failure hit at review; the script-exit-code item shipped in M01 and `\printindex` ordering has its own row; tests/htmlindex.py's index_section takes the FIRST heading whose text is Index, so a fixture carrying its own would silently locate the wrong element (M08 review F10)
- Quarto version floor is an untested contract claim; CI matrix would fence it — added 2026-08-16 — M01 review R15; folds into the existing CI-matrix candidate
- Windows checkouts without symlink support break examples/_extensions — added 2026-08-16 — M01 review R18
- `marks_seen` is module-level state, latent if Lua state is ever reused across documents; the HTML back-end adds one more such accumulator (`html_marks`) — added 2026-08-16, widened by M03 review P1, corrected M03 (the second accumulator was refactored away by the F1/F2 fix), corrected M04 (`marks_emitted` became the format-neutral `marks_seen`), widened by M06 review F-a (`sort_keys`, the sort-key registry, is another), widened by M09 review F6 (`clamped_paths`, the level-fold collision accumulator, is another) — M01 review R16
- `\index` inside a moving argument (section heading) is unprobed — added 2026-08-16 — M01 review R17
- see-also entries keep their locators (print convention) in both back-ends — added 2026-08-16 — M03 gate chose LaTeX-aligned no-locator semantics; pairs with the plain+cross-reference clash row
- Escaping probe covers characters singly; combinations remain an untested axis — added 2026-08-16 — M01 review; see the milestone Decisions entry
- `[` and `]` are escaped by Pandoc's LaTeX writer but are not in the filter's escape table — added 2026-08-16 — M01 review N11; verified harmless in practice
- Bare (unquoted) `entry=`, `see=` and `see-also=` values escape both the no-leak sweep and the probe-coverage pin; for no-leak this is a false pass, not a false failure — added 2026-08-16 — M01 review N9, widened by M02 review, widened by M06 review F-b (the suite's `sort=` extraction is double-quote-only too; no false pass today, since every fixture quotes its values)
- Demo manifests have no independent count, so coverage can shrink silently — added 2026-08-16 — M01 review P10
- The demo's own makeindex acceptance is never asserted — added 2026-08-16 — M01 review P11
- `\printindex` precedes a bibliography rather than following it, since Quarto appends reference blocks after filters run — added 2026-08-16 — M01 review P2; README states the current behavior
- A term marked both plainly and with a cross-reference fails the PDF render when both marks land on one page; M02 warns but cannot prevent it, since page numbers do not exist at filter time — added 2026-08-16 — M02 Decisions; needs locator suppression or deferred emission
- The PDF cross-reference checks assert substring presence, not counts, so a cross-reference printed twice would pass — added 2026-08-16 — M02 review; mirrors the existing AC6 approach
- Choose and add a LICENSE file (user decision; needed before public listing) — added 2026-08-16 — M01 README omits a license claim for want of one
- A mark's attribute values ride into pass-through formats on the span itself (`data-see` etc. in gfm); whether that markup residue is acceptable is unsettled — added 2026-08-17 — M03 review F4/F9; AC3's scope note defers it
- The planted-defect self-test mutates only the `.tex` fixture; no HTML index check has a planted-defect proof — added 2026-08-17 — M03 review F14
- Report a container a nested marker leaves empty — descoped out of M08 at its third review return (2026-08-18) and to be planned on its own; the recursive rule is right (a marker contributes what its content contributes; a marker is never itself a container) but naming the container is not, and these shapes are known to break it: Quarto wraps callouts, tabsets and captioned figures in `__quarto_custom_scaffold` divs, so the report names a div no author wrote while the construct renders its title bar or caption; figure captions and table cells are emptied unreported; a bullet list emptied through its only item reports as a list item; and a per-kind check on `div` cannot tell the container from the marker div inside it — added 2026-08-17 — M04 review F6, M08 review F1/F3/R1/R2/R3/Q1/Q5/Q7
- A marker written in YAML `abstract:` survives verbatim into the HTML header — filter residue of the IP2 class, since `resolve_markers` reads `doc.blocks` alone; the misplaced-class report is silent there for the same reason — added 2026-08-18 — M08 review R4/Q2
- `resolve_markers` rebuilds every Blocks list in every format whether or not a marker exists; the LaTeX byte-diff proves that output-neutral, HTML has no equivalent byte check — added 2026-08-17 — M04 review F12
- Headings consumed by Quarto constructs (callout titles, tabsets) bypass the after-heading anchor relocation; no TOC copy today, so no defect — the invariant is unpinned against Quarto's own filter ordering — added 2026-08-17 — M03 review pass 3 F8
- Locator hrefs into chapter pages cannot be percent-escaped at the filter layer: Quarto normalizes a link target either way (verified — the filter emitted `later%20chapter.html`, output carried `later chapter.html`, matching Quarto's own `./later chapter.html`), so a chapter filename containing `#` or `?` yields a broken locator — added 2026-08-17 — M05 review F11
- The per-chapter store is never pruned: a renamed or removed chapter leaves its record forever, harmless today because reads are filtered by the current chapter list and validated against a store version — added 2026-08-17 — M05 review F4/F13
- Sort-key level paths are keyed on unclamped levels while the LaTeX back-end prints clamped ones, so a 4-level entry and a 3-level entry spelling the folded form collide under two makeindex keys with no report; the printed-text collision itself predates sort keys — added 2026-08-18 — M06 review pass 2 F9
- The book sidecar writes its declared-key map in `pairs` order, so an identical chapter's record is byte-unstable between renders; read as a map, so no ordering effect — added 2026-08-18 — M06 review pass 2 F11
- An empty entry tree would render the index as a bare `Index` heading with no list and no warning; unreachable today (every path that builds the section is gated on a mark with at least one level), so this is latent — added 2026-08-18 — M07 review F3
- Reader-facing strings the filter emits are hard-coded English (`Index`, and now the `Symbols` group label) with no `lang` policy in DESIGN — added 2026-08-18 — M07 review F6; distinct from the non-Latin-1 author-terms row above, which is about what an author writes
- A book page rendered but absent from `book.render` (via `project: render:`) gets its own per-chapter index rather than contributing to the book's — added 2026-08-17 — M05 review F13
