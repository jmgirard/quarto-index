# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-16 (M02 planned from the cross-references candidate; row absorbed)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M02 | Cross-references (see / see also) | planned | M01 | normal | milestones/M02-cross-references.md |
| M01 | LaTeX index extension skeleton | done | — | normal | milestones/archive/M01-latex-index-skeleton.md |
<!-- rows grouped by status, not sorted by ID; keep only the 5 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- unnumbered ideas; one line each: idea — added YYYY-MM-DD — links -->
- HTML index generation (single-doc index page from marks; HTML behavior undefined in M01) — added 2026-08-16 — builds on M01 syntax
- Multi-chapter book support (cross-file index aggregation) — added 2026-08-16 — builds on M01
- First tagged release (window user-declared, never agent-proposed) — added 2026-08-16
- Explicit index-placement option / shortcode syntax (if demanded) — added 2026-08-16 — see M01 work log for the auto-placement rationale; GP5 governs
- Page-range & styling control (open/close marks, principal-mention locators) — added 2026-08-16 — suite target
- Multiple named indexes (e.g., subject + author) — added 2026-08-16 — suite target
- Sort-key syntax (format-neutral) — added 2026-08-16 — suite target; prerequisite for non-ASCII collation (DESIGN Conventions)
- Quarto version floor + CI matrix (floor + latest) — added 2026-08-16 — contract-boundary commitment (DESIGN)
- Submit to Quarto extension listing at first release — added 2026-08-16 — window user-declared
- Leading/medial empty index levels are rejected by makeindex ("Illegal null field"), destroying the whole entry — added 2026-08-16 — M01 review R12; only the trailing case is probed
- Non-Latin-1 scripts in index terms (Greek, CJK, combining marks, RTL) need an engine/font decision — added 2026-08-16 — M01 review R7/R9; pdflatex default fonts do not cover them
- Harden the acceptance suite: brace-aware \index scanner (no longer benign now that unbalanced braces are probed) — added 2026-08-16 — M01 review R14; the script-exit-code item was done in M01, and \printindex ordering has its own row
- Quarto version floor is an untested contract claim; CI matrix would fence it — added 2026-08-16 — M01 review R15; folds into the existing CI-matrix candidate
- Windows checkouts without symlink support break examples/_extensions — added 2026-08-16 — M01 review R18
- `marks_emitted` is module-level state, latent if Lua state is ever reused across documents — added 2026-08-16 — M01 review R16
- `\index` inside a moving argument (section heading) is unprobed — added 2026-08-16 — M01 review R17
- The empty-level warning fires only on the LaTeX branch, though Scope states it as format-neutral entry semantics — added 2026-08-16 — M01 review R19 (its whitespace-only-term half proved false: Pandoc strips the space before the filter sees it)
- Escaping probe covers characters singly; combinations remain an untested axis — added 2026-08-16 — M01 review; see the milestone Decisions entry
- `[` and `]` are escaped by Pandoc's LaTeX writer but are not in the filter's escape table — added 2026-08-16 — M01 review N11; verified harmless in practice
- Bare (unquoted) `entry=` values escape both the no-leak sweep and the probe-coverage pin — added 2026-08-16 — M01 review N9
- Acceptance suite: BSD-sed portability, `]{.index` substring undercount, `include_text` guard — added 2026-08-16 — M01 review N12/N13/N14
- Demo manifests have no independent count, so coverage can shrink silently — added 2026-08-16 — M01 review P10
- The demo's own makeindex acceptance is never asserted — added 2026-08-16 — M01 review P11
- `\printindex` precedes a bibliography rather than following it, since Quarto appends reference blocks after filters run — added 2026-08-16 — M01 review P2; README states the current behavior
- Choose and add a LICENSE file (user decision; needed before public listing) — added 2026-08-16 — M01 README omits a license claim for want of one
