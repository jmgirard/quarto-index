# M092: The label and separator checks fail on the defects they name

**Status:** done (2026-09-11, PR #92 https://github.com/jmgirard/quarto-index/pull/92)

**Goal:** The M56-M59 label and separator checks each go red on the defect that their own
message names, so a green run over the index-labels and index-separators fixtures is evidence
about those fixtures.

**Outcome:** Test suite only. `check_tex_identical` serves M56-AC6, M58-AC6 and the plant, and
reports diff trouble and an unwritable diff file apart from a difference. Zero-warning totals
cover the labels fixture's HTML and LaTeX logs. 18 zero controls naming undeclared indexes are
deleted, and the clash log's silence half is planted. `derive_labels_twin` parses front matter
with PyYAML and holds M58's exact key set. `m57_tex_ledger` drops diff headers by position.
`entry_separators` walks through wrapper elements. `tests/sepcheck.py` refuses a malformed
manifest with one FAIL line: unknown slot, or a space for a tab after a depth, term or slot.
KI180-KI182, KI186 and KI190-KI195 struck.

**Decisions:** none milestone-local. The plan gate chose two milestones and parsed YAML. The
implement gate chose an exact key set and widened AC3 to the M56-AC5 and M58-AC4 loops.

**Review:** one pass, three-lens fan-out. All seven criteria verified at 1469 checks. The history
and prior-review lenses found nothing beyond R4. Fixed at the gate: R1, R3, R5 (new plants and
guards), R7, R9, R10 (wording). Re-run: 1474 checks, exit 0. R4 (YAML 1.1 and duplicate-key blind
spot) went to KI278. R2, R6 and R8 rejected. CI green on PR #92. Nothing graduated or retired.
