# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-24 (M28 merged and archived; three review findings filed as KI80-KI82 and the suite-hardening row extended to point at two of them. ROADMAP 7.0k of its 24k byte budget and 49 lines.)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M29 | A marker report in a book names its chapter | review | M28 | normal | milestones/M29-book-chapter-in-report.md |
| M28 | A reported block position names the sequence it counts | done | — | normal | milestones/archive/M28-block-position-naming.md |
| M27 | A finding about today's behavior is a known issue, not a candidate row | done | — | normal | milestones/archive/M27-record-ownership.md |
| M25 | A check that cannot hold its promise is retired, not widened | done | M24 | normal | milestones/archive/M25-scan-disposition.md |
| M24 | Every check reads the copy, never the working tree | done | — | normal | milestones/archive/M24-captured-artifacts.md |
| M26 | A document's accumulators start empty, whoever ran before it | done | — | normal | milestones/archive/M26-per-document-state.md |
<!-- rows grouped by status, not sorted by ID; keep only the 5 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- proposed work only; one line each: idea — added YYYY-MM-DD — links.
     A finding about today's behavior is a DESIGN.md Known-issues entry, not a row (D-013). -->
- Dedupe `examples/.gitignore` against the root ignore, and make the README claim check assert that the filter emits each pinned string — added 2026-08-19 — M13 review F16/F20 — KI75, KI73
- Reconcile the example corpus so its probe `see=`/`see-also=` targets name terms the fixture indexes — added 2026-08-19 — M14 plan gate — KI72
- Settle whether the emptied-place reports for a callout, a tabset and a captioned figure should keep depending on Quarto's scaffold wrapping; promote on an upstream change surfacing as a manifest mismatch — added 2026-08-19, narrowed 2026-08-23 when M28/M29 took the naming half — M12 review F12 — KI23
- Rewrap the filter source under 80 columns, and narrow each module's exports to what is reached from outside — added 2026-08-20 — M17 review J/I — KI76, KI77
- Release bundle (clustered 2026-08-23), all three gated on one user-declared window and never agent-proposed: the first tagged release; choosing and adding a LICENSE file, which README omits a claim for want of one (M01); and submitting to the Quarto extension listing at that release — added 2026-08-16
- Chapter-based locator labels in the book HTML index (e.g. 2.1 instead of 1, 2, 3) — added 2026-08-17 — M05 gate kept numeric locators; promote on reader evidence that numeric locators fail in long books
- Locator-control follow-ups (clustered): roles beyond `principal` for a locator (a defining passage, an illustration), promoted on evidence an author wants a second role; an author-written id pairing two overlapping ranges of one term, which pairing by entry cannot tell apart, promoted on evidence that authors write them; author control over the range dash; and emphasizing a principal page folded inside a page range — added 2026-08-21 — M20/M21 Scope Out, RR01, M20 amendment gate — KI5, KI74
- Pair a range spanning two chapters of an HTML book; promote on a per-chapter record that separates what the author wrote from what a chapter concluded, never on the feature being wanted, and on a derivation path that reads the mark's rewritten content — added 2026-08-22 — M21 review rounds 1-3, D-009 — KI19, KI20
- Book sidecar-store follow-ups (clustered): prune records for chapters no longer in the book; give the declared-key map a stable order; decide what a page outside `book.render` should do — added 2026-08-17, clustered 2026-08-22 — M05 review F4/F13, M06 review pass 2 F11 — KI16, KI17, KI18
- Cover a leftover `.ind` with a gobbling stand-in the way M22 covers the `.aux`; promote on evidence a real pipeline leaves an `.ind` unrewritten across a render — added 2026-08-22 — M22 review F1 — KI4
- Multiple named indexes (e.g., subject + author) — added 2026-08-16 — suite target
- Quarto version floor + CI matrix (floor + latest) — added 2026-08-16 — contract-boundary commitment (DESIGN) — KI79
- Pick an engine and fonts for non-Latin-1 index terms (Greek, CJK, combining marks, RTL) — added 2026-08-16 — M01 review R7/R9 — KI6
- Acceptance-suite hardening (clustered): close the gaps KI27-KI74 record, from where a check reads and what it holds through the coverage gaps; absorbs six rows refiled here — the escaping-combination probe, bare unquoted attribute values, an independent demo-manifest count, the demo's own makeindex acceptance, cross-reference counts rather than substring presence, and an HTML planted-defect proof — plus a fixture for the all-empty-`entry=` shape — added 2026-08-16, extended 2026-08-17, clustered 2026-08-18, refiled 2026-08-23, extended 2026-08-24 — KI24, KI27-KI74, KI81, KI82, KI84, KI85
- Support Windows checkouts without symlink support — added 2026-08-16 — M01 review R18 — KI78
- Guard an accumulator added after M26 that joins no `reset`; D-011 refuses a source scan, so the guard is a render or nothing — added 2026-08-16, promoted to M26 2026-08-23 — KI10
- Probe `\index` inside a moving argument, and protect `\quartoindexregister` on that path — added 2026-08-16 — M01 review R17, M20 review round 2 R2-F7 — KI2
- Settle the see-also locator semantics and whether repeated `\seename` should join — added 2026-08-16 — M03 gate chose LaTeX-aligned no-locator semantics, M15 keeps it for a contested key — KI9
- Add `[` and `]` to the filter's escape table — added 2026-08-16 — M01 review N11 — KI1
- Print `\printindex` after the bibliography rather than before — added 2026-08-16 — M01 review P2 — KI3
- Settle whether a mark's attribute values may ride into pass-through formats — added 2026-08-17 — M03 review F4/F9 — KI15
- Reach markers written in YAML `abstract:` — added 2026-08-18 — M08 review R4/Q2 — KI11
- Restore byte-level evidence that `resolve_markers` is output-neutral; D-004 refused the merge-base oracle and D-012 licenses a same-tree one — added 2026-08-17 — M04 review F12 — KI12, KI52
- Pin the after-heading anchor relocation against Quarto's own filter ordering — added 2026-08-17 — M03 review pass 3 F8 — KI13
- Handle a chapter filename containing `#` or `?` — added 2026-08-17 — M05 review F11 — KI14
- Key sort-key level paths on the levels the back-end prints — added 2026-08-18 — M06 review pass 2 F9 — KI7
- Report an empty entry tree rather than rendering a bare heading — added 2026-08-18 — M07 review F3 — KI8
- Adopt a `lang` policy for the reader-facing strings the filter emits — added 2026-08-18 — M07 review F6 — KI26
