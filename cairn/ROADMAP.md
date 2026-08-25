# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-24 (M35 done and archived; M30 pruned under terminal-row retention; the suite-hardening candidate row absorbs M35's sixteen filed findings. Two check-design lessons moved into cairn/check-design.md under the ownership exit, none retired. ROADMAP 49 lines / 8,234 bytes, LESSONS 44 / 11,521, check-design 35 / 14,749 against its stated 40 / 18,000, cairn CLAUDE.md section 25 lines — all inside their caps. Suite green at 352 plain / 491 self-test.)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M36 | The non-Latin-1 readers stop reading text that belongs to no error | in-progress | — | normal | milestones/M36-unicode-reader-claims.md |
| M37 | The non-Latin-1 guards report the cause they hit | planned | M36 | normal | milestones/M37-non-latin1-guard-causes.md |
| M35 | The non-Latin-1 checks fail on the defects they claim to catch | done | — | normal | milestones/archive/M35-non-latin1-check-hardening.md |
| M34 | The non-Latin-1 recipe names a font TeX Live still maintains | done | — | normal | milestones/archive/M34-stix-two-recipe.md |
| M33 | An index term outside Latin-1 prints in the PDF index | done | — | normal | milestones/archive/M33-non-latin1-terms.md |
| M32 | An index follows the bibliography where the author puts it | done | — | low | milestones/archive/M32-index-after-references.md |
| M31 | A leftover index file never breaks the next render | done | — | normal | milestones/archive/M31-stale-ind-standin.md |
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
- Make a `,` index entry print as a comma rather than merging with the index style's delimiter into one glyph; promote on evidence that a reader or author reads the merged glyph as wrong, never on the oddity being noticed — added 2026-08-24 — M30 T1 — KI87
- Move the index relative to content Quarto adds after filters run, rather than leaving the order to an author-written `#refs` div; promote on evidence Quarto exposes an ordering hook a filter can reach — added 2026-08-24 — M32 Scope Out — KI3
- Make M32's marker-less plants read the captured artifact rather than the render's working copy, so M24's capture rule is met in intent and not only in letter; promote with any other suite-wide capture sweep — added 2026-08-24 — M32 review R2-F9
- Narrow M32's HTML-cost check from "the fixture carries no `#quarto-appendix` at all" to the bibliography's own wrapper, so a fixture that later grows a footnote or a Citation block cannot turn it red while README stays true; promote on that fixture growing one — added 2026-08-24 — M32 review R2-F14
- Multiple named indexes (e.g., subject + author) — added 2026-08-16 — suite target
- Quarto version floor + CI matrix (floor + latest) — added 2026-08-16 — contract-boundary commitment (DESIGN) — KI79
- Print an RTL index term correctly: the plan gate's probe shows it unshaped with the locator comma on the wrong side of the entry, which a covering font does not fix; promote on a bidi path that also settles locator placement — added 2026-08-24 — M33 Scope Out — KI6
- Acceptance-suite hardening (clustered): close the gaps KI27-KI74 record, from where a check reads and what it holds through the coverage gaps; absorbs six rows refiled here — the escaping-combination probe, bare unquoted attribute values, an independent demo-manifest count, the demo's own makeindex acceptance, cross-reference counts rather than substring presence, and an HTML planted-defect proof — plus a fixture for the all-empty-`entry=` shape, and the typeset print proof M30 gave the escaping probe extended to the cross-reference and sort-key probes, which still assert compile-and-accept only — added 2026-08-16, extended 2026-08-17, clustered 2026-08-18, refiled 2026-08-23, extended 2026-08-24 — M35's sixteen filed findings left here 2026-08-24 when M36 and M37 took them, the row keeping the pointer to that milestone's archived Review section for anything those two decline — KI24, KI27-KI74, KI81, KI82, KI84, KI85
- Support Windows checkouts without symlink support — added 2026-08-16 — M01 review R18 — KI78
- Guard an accumulator added after M26 that joins no `reset`; D-011 refuses a source scan, so the guard is a render or nothing — added 2026-08-16, promoted to M26 2026-08-23 — KI10
- Probe `\index` inside a moving argument, and protect `\quartoindexregister` on that path — added 2026-08-16 — M01 review R17, M20 review round 2 R2-F7 — KI2
- Settle the see-also locator semantics and whether repeated `\seename` should join — added 2026-08-16 — M03 gate chose LaTeX-aligned no-locator semantics, M15 keeps it for a contested key — KI9
- Settle whether a mark's attribute values may ride into pass-through formats — added 2026-08-17 — M03 review F4/F9 — KI15
- Reach markers written in YAML `abstract:` — added 2026-08-18 — M08 review R4/Q2 — KI11
- Restore byte-level evidence that `resolve_markers` is output-neutral; D-004 refused the merge-base oracle and D-012 licenses a same-tree one — added 2026-08-17 — M04 review F12 — KI12, KI52
- Pin the after-heading anchor relocation against Quarto's own filter ordering — added 2026-08-17 — M03 review pass 3 F8 — KI13
- Handle a chapter filename containing `#` or `?` — added 2026-08-17 — M05 review F11 — KI14
- Key sort-key level paths on the levels the back-end prints — added 2026-08-18 — M06 review pass 2 F9 — KI7
- Report an empty entry tree rather than rendering a bare heading — added 2026-08-18 — M07 review F3 — KI8
- Adopt a `lang` policy for the reader-facing strings the filter emits — added 2026-08-18 — M07 review F6 — KI26
