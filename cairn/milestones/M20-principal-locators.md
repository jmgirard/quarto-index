# M20: A term's principal discussion prints as its principal locator

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP5, GP6
- **Branch/PR:** —

## Goal

An author can mark one occurrence of a term as its principal discussion, and both
back-ends print that occurrence's locator emphasized while its other locators stay plain.

## Scope

Surface tier: **user-facing** — it adds an authoring attribute, changes what both
back-ends emit, and is documented in README.

**In:** one new format-neutral mark attribute, `role="principal"`, naming the role a
mention plays rather than a rendering (IP1); the LaTeX encapsulation for it, carried by a
`\providecommand` command injected only into a document that uses it, so an author can
redefine the emphasis without the extension shipping a style; the emphasized locator link
in the HTML back-end, and the record field that carries the role through a book's sidecar
store; the reports for a role written on a mark that can contribute no locator and for an
unrecognized role value; fixtures, suite section, planted-defect entries, README.

Terminology: indexing practice calls the main discussion of a term its *principal
reference* and conventionally sets it in bold; `main` is not used, a *main entry* being
the top-level heading rather than a locator.

Evidence stops at the `.ind` makeindex writes rather than at the PDF's text, because
`pdftotext` cannot see emphasis — a deliberate GP6 trade, recorded rather than left
implicit, and the `.ind` is the artifact that settles whether the encapsulation reached
the right locator at all.

**Out:** page ranges, and a range carrying this role on both its ends → M21. Roles beyond
`principal` (a defining passage, an illustration) → ROADMAP candidate row; the attribute
is shaped to take them as values, and nothing here anticipates one. Shipping CSS for the
HTML class → out of GP3's install story; the locator carries Pandoc-level emphasis so it
reads correctly with no stylesheet at all. Whether a mark's attributes should ride into
pass-through formats at all → the standing ROADMAP row, unchanged by the new attribute.

## Acceptance criteria

- [ ] AC1: The PDF render of `examples/principal.qmd` produces a `.ind` in which the
      principal term's entry shows exactly one emphasized locator and its remaining
      locators plain, and a `.ilg` carrying no conflicting-encapsulation warning for that
      entry's key.
- [ ] AC2: In the HTML render of `examples/principal.qmd`, the index entry for the
      principal term carries exactly one locator link marked as principal, at the position
      of the principal mark, its other locator links unmarked — read structurally by
      `tests/htmlindex.py`.
- [ ] AC3: A mark writing `role="principal"` that can contribute no locator, because it
      carries `see=` or `see-also=`, draws exactly one warning naming the mark and saying
      the role is ignored, and emits index output identical to that of the corresponding
      mark in `examples/principal-twin.qmd`, which omits the role. The warning fires in the
      LaTeX render, the HTML render, and a format with no index back-end.
- [ ] AC4: A `role=` value the extension does not recognize draws exactly one warning
      naming the mark and the value, and the mark indexes exactly as the corresponding
      mark in `examples/principal-twin.qmd` does.
- [ ] AC5: In gfm, a principal-marked term's visible text passes through with no artifacts
      beyond the span attribute residue Pandoc passes through for the mark's own
      attributes, `role=` included.
- [ ] AC6: The command the principal encapsulation names is defined with `\providecommand`
      in the preamble of the rendered `.tex` for `examples/principal.qmd`, and absent from
      the preamble of the rendered `.tex` for `examples/content.qmd`.
- [ ] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1, T3, T5
- AC2 → T1, T4, T5
- AC3 → T1, T2, T5
- AC4 → T1, T2, T5
- AC5 → T1, T5
- AC6 → T3, T5
- AC7 → T5, T6, T7

## Tasks

- [ ] T1: Fixtures `examples/principal.qmd` and `examples/principal-twin.qmd` with their
      expected manifests. The first carries a term marked in three places, one of them
      principal; a principal mark carrying `see=`; a mark with an unrecognized `role=`;
      and a plainly marked control term the new reports must stay silent on (the M11
      lesson). Terms and pages are distinct per slot (the M02 lesson). The twin is the
      same document with every `role=` removed.
- [ ] T2: `core.lua` gains the attribute name and its recognized values; `marks.lua`
      derives the role once, before the back-end branch, with the two warnings — a role on
      a mark contributing no locator, and an unrecognized value — so both fire in every
      format as the other mark warnings do.
- [ ] T3: `latex.lua` and `passes.lua`: the principal encapsulation, its arbitration
      against the contested-key bookkeeping (a principal mark and a cross-reference mark
      of one key emit different encapsulations, which makeindex warns about only on a
      shared page), and the preamble injection flag read by the Pandoc pass.
- [ ] T4: `html.lua`: the principal locator link and its class; the role on the HTML mark
      record; `book.lua` carries it in the per-chapter record as an optional field with a
      named fallback, leaving the store version alone (the M14 lesson).
- [ ] T5: The suite's principal section: copy `.ind`, `.ilg` and `.tex` to `$WORK` at the
      latex render before the pdf render removes them (the M15 lesson); the structural
      HTML check; the rendered-log pins passed through `warn-distinct`; the no-leak sweep;
      the preamble present/absent pair.
- [ ] T6: `tests/plantdefect.py` entries for each check T5 adds, each planting a defect of
      the kind that check names and varying form as well as site — an encapsulation on the
      wrong locator, an encapsulation on none, and a warning whose text is right but whose
      mark is wrong.
- [ ] T7: README section for `role="principal"`: what an author writes, what each back-end
      prints, how to redefine the LaTeX command, and that an unusable role is reported.
      Add its authoring forms to the suite's normative supported-forms list and its
      sentences to a README claims array.

## Work log

- 2026-08-21: created by /milestone-plan.
- 2026-08-21: plan gate chose `role="principal"` over a boolean `principal="true"` because a later role becomes another value rather than another attribute (GP5); falsified by evidence that no second role is ever wanted, which would leave the indirection dead weight.
- 2026-08-21: plan chose a redefinable `\providecommand` command over emitting `\textbf` directly because it gives an author styling control with no configuration (GP4) and matches the existing inject-only-where-used pattern; falsified by evidence that hyperref's encapsulation rewriting breaks an indirected command where a literal one survives.
- 2026-08-21: plan chose `.ind`/`.ilg` evidence over PDF-text evidence for the emphasis itself because `pdftotext` cannot see it; falsified by a PDF reader in the suite that can distinguish a bold locator from a plain one.
- 2026-08-21: criteria audit ran in full mode (user-facing tier) and returned findings on AC3, AC5 and the drafted README criterion; AC3 gained the named twin, AC5's residue clause was reworded to include the new attribute, and the README criterion was descoped to T7.

## Decisions

## Review
