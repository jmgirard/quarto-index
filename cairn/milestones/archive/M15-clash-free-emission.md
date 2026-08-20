# M15: A term marked both plainly and with a cross-reference builds

**Status:** done (2026-08-20, PR #15 https://github.com/jmgirard/quarto-index/pull/15)

**Goal:** A document that marks one term with a locator in one place and a cross-reference
in another builds instead of failing, and its index carries both.

**Outcome:** A *contested key* — one whose marks would emit more than one distinct
encapsulation — is settled in a read-only Span pass (`CollectKeys`) before anything is
emitted, routed with the emitting pass through one `latex_plan` so the two cannot drift on
a mark's key or targets. A key with a plain mark folds its cross-references into the printed
text on every plain mark, its cross-reference marks emitting nothing; a key with none carries
its targets in one combined encapsulation (`quartoindexxrefs`), keeping its no-locator
semantics. `index_argument` grew an optional `fold`, applied from the levels; its forced sort
field takes the same key-against-level comparison the uncontested branch makes, so contesting
a key never moves where an entry files. The clash warning became two reports, one per shape,
and `tests/pdfindex.py` learned to fold a wrapped continuation back in, within its column.

**Decisions:** D-003. Milestone-local: fold over a separate page-gobbled item; a combined
encap where a key has no plain mark; `\see`/`\seealso` with an explicit empty page argument.

**Review:** One defect return (AC5, AC6, a fold-branch filing defect), repaired in three
commits. Second pass, three lenses, 11 findings — 8 fixed at the gate (worst: the report
claiming page numbers for a shape that has none, and its pinned README twin), 2 absorbed into
candidate rows, 2 rejected. Retired the M02 clash lesson, now enforced by AC1.
