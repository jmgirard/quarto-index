# M21: A discussion spanning pages prints as one page range

**Status:** done (2026-08-22, PR #21 https://github.com/jmgirard/quarto-index/pull/21)

**Goal:** An author can mark where a term's discussion begins and where it ends, and the
index prints one locator spanning the two rather than a locator at each.

**Outcome:** `range="open"`/`"close"` on two marks of one entry, paired by the entry
within one Pandoc process (D-009). LaTeX: `|(`/`|)` in the encapsulation channel; a
principal range registers its composed page string via `\quartoindexrangeat`/`rangeto`
in `PRINCIPAL_SUBSYSTEM` (D-008). HTML: one locator at the opening anchor, closing
anchor-only, role resolved from either end. HTML book: each chapter pairs and reports
its own scope; `report_book_ranges` names only split pairs with visible counterparts;
`paired` travels in the per-chapter record, validated to the two known ends. Five misuse
refusals degrade to ordinary locators so no refused range reaches makeindex.
`tests/m21probes.py` (5 readers), 20 planted defects, README section with pinned claims.

**Decisions:** D-008 (range registers its printed page string), D-009 (pairing scope is
one process; cross-chapter left scope), D-010 (annotates D-009: in-chapter ranges pair).

**Review:** five rounds, four defect returns (9/7/12/10 findings), parked once at the
thrash threshold and resumed by user decision. Round 5: two lenses clean; diff-bug lens
nine findings — six fixed at the gate (comment overclaims, a false `pass` line, README
lead-in, PDF-book scope word, an invariant recorded, D-010), three rejected onto
standing candidate rows. Nothing graduated or retired.
