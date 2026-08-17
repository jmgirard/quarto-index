# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-16 (initial scaffold)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M01 | LaTeX index extension skeleton | in-progress | — | normal | milestones/M01-latex-index-skeleton.md |
<!-- rows grouped by status, not sorted by ID; keep only the 5 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- unnumbered ideas; one line each: idea — added YYYY-MM-DD — links -->
- HTML index generation (single-doc index page from marks; HTML behavior undefined in M01) — added 2026-08-16 — builds on M01 syntax
- Multi-chapter book support (cross-file index aggregation) — added 2026-08-16 — builds on M01
- First tagged release (window user-declared, never agent-proposed) — added 2026-08-16
- Explicit index-placement option / shortcode syntax (if demanded) — added 2026-08-16 — see M01 work log for the auto-placement rationale; GP5 governs
- Cross-references (see / see also) — added 2026-08-16 — suite target (DESIGN Purpose & Scope); IP1 semantics
- Page-range & styling control (open/close marks, principal-mention locators) — added 2026-08-16 — suite target
- Multiple named indexes (e.g., subject + author) — added 2026-08-16 — suite target
- Sort-key syntax (format-neutral) — added 2026-08-16 — suite target; prerequisite for non-ASCII collation (DESIGN Conventions)
- Quarto version floor + CI matrix (floor + latest) — added 2026-08-16 — contract-boundary commitment (DESIGN)
- Submit to Quarto extension listing at first release — added 2026-08-16 — window user-declared
- Choose and add a LICENSE file (user decision; needed before public listing) — added 2026-08-16 — M01 README omits a license claim for want of one
