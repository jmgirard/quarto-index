# M21: A discussion spanning pages prints as one page range

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M20
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP5, GP6
- **Branch/PR:** `m21-page-ranges`

## Goal

An author can mark where a term's discussion begins and where it ends, and the index
prints one locator spanning the two rather than a locator at each.

## Scope

Surface tier: **user-facing** — it adds an authoring attribute, changes what both
back-ends emit, and is documented in README.

**In:** one new format-neutral mark attribute, `range="open"` / `range="close"`, paired by
the entry the two marks index, so the common case needs nothing else written; the LaTeX
range encapsulations, carrying on both ends whichever role M20's attribute puts on the
opening mark, since makeindex warns when the two ends differ, and — where that role is
principal — the registration that puts the range's own printed page string into M20's
typeset-time registry, since a range prints as one string no per-page registration matches;
the HTML realization, where
the pair contributes one locator link pointing at the opening mark's anchor; pairing
across chapters of an HTML book, judged by the chapter that has seen every record, as
every other cross-chapter judgement here is; the reports for the five misuse shapes;
fixtures, suite section, planted-defect entries, README.

An ordinary mark of a term that falls inside that term's own range is folded into the
range by makeindex, silently and with no warning even in its own transcript. The extension
cannot know page numbers, so it cannot tell which marks are affected — a warning would
fire on marks outside the range too. It is documented instead, which is what GP2 asks of a
toolchain behavior the extension does not cause.

**Out:** an author-written id disambiguating two overlapping ranges of one term → ROADMAP
candidate row, promoted on evidence that authors write overlapping ranges of one term;
until then the shape is reported. Author control over the range dash → candidate row; the
back-end's own convention stands. A range on a page Quarto presents as a book chapter
without the metadata the store needs → that page already falls back to indexing itself
alone, and the range is reported as unpaired there rather than silently spanning nothing.

## Acceptance criteria

- [ ] AC1: The PDF render of `examples/range.qmd` produces a `.ind` in which the ranged
      term's entry shows one page range spanning the pages of its opening and closing
      marks, and a `.ilg` carrying no unmatched-, extra- or inconsistent-range warning for
      that entry's key.
- [ ] AC2: A range whose opening mark carries `mention="principal"` emits the same
      encapsulator on its closing `\index` command as on its opening one, and for
      `examples/range.qmd` the page string that entry's locator carries in the `.ind` is
      registered as principal in the `.aux` under that encapsulator's own ordinal — the
      chain that prints the range emphasized, whose last link no `.ind` can show.
- [ ] AC3: In the HTML render of `examples/range.qmd`, the ranged term's index entry
      carries exactly one locator link, whose href is the opening mark's anchor; where the
      opening mark is principal that one link carries the principal class and emphasis; the
      closing mark contributes no locator link and emits no text of its own beyond the
      author's visible text, read at its anchor by `tests/htmlindex.py`.
- [ ] AC4: Each of the five misuse shapes exercised by `examples/range-misuse.qmd` — an
      opening never closed, a closing with no opening, a second opening for a term whose
      range is still open, a range mark also carrying `see=` or `see-also=`, and a `range=`
      value that is neither an opening nor a closing — draws exactly one warning naming the
      mark and saying what the index will show instead, in the LaTeX render, the HTML
      render, and a format with no index back-end.
- [ ] AC5: In the HTML book under `examples/book/`, a range whose opening mark is in one
      chapter and whose closing mark is in a later chapter contributes exactly one locator
      to the book index, whose href is the opening chapter's page and the opening mark's
      anchor, and neither chapter's own render warns about its half of the pair.
- [ ] AC6: In gfm, an opening and a closing mark pass their visible text through with no
      artifacts beyond the span attribute residue Pandoc passes through for the mark's own
      attributes, `range=` included.
- [ ] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1, T3, T6
- AC2 → T1, T3, T6
- AC3 → T1, T4, T6
- AC4 → T1, T2, T6
- AC5 → T1, T5, T6
- AC6 → T1, T6
- AC7 → T6, T7, T8

## Tasks

- [ ] T1: Fixtures. `examples/range.qmd` carries a plain range, a range whose opening mark
      is principal, an ordinary mark of a third term the new reports must stay silent on
      (the M11 lesson), and enough content between each opening and closing to put them on
      different pages, with distinct terms per slot (the M02 lesson).
      `examples/range-misuse.qmd` carries one mark per shape AC4 names. The book fixture
      gains a range opened in one chapter and closed in a later one.
- [ ] T2: `core.lua` gains the attribute and its two values; `marks.lua` derives the range
      role before the back-end branch and holds the per-key pairing state, drawing the four
      shapes it can judge within one document plus the unrecognized-value one, so all five
      fire in every format.
- [ ] T3: `latex.lua` and `passes.lua`: the opening and closing encapsulations, composed
      with M20's role so both ends carry the same encapsulator; the range registration that
      records each end's page and registers the printed range string against the key's
      ordinal, so a principal range prints emphasized where a makeindex-folded one still
      does not; and arbitration against the contested-key bookkeeping — a range
      encapsulation stays in the encapsulation channel, and a key carrying cross-references
      too folds those into the entry's printed text exactly as it already does, so the two
      compose rather than one being dropped.
- [ ] T4: `html.lua`: pairing at index-build time, the single locator link at the opening
      mark's anchor, and the closing mark contributing no locator while keeping its own
      anchor and visible text.
- [ ] T5: `book.lua`: the range role travels in the per-chapter record as an optional field
      with a named fallback, leaving the store version alone (the M14 lesson); pairing and
      the unmatched reports are drawn by the chapter that reads the whole store, so a
      chapter holding one half of a legitimate cross-chapter range warns about nothing.
- [ ] T6: The suite's range section: copy `.ind`, `.ilg` and `.tex` to `$WORK` at the latex
      render before the pdf render removes them (the M15 lesson); the structural HTML
      checks for the single locator and the silent closing mark; the book-index check; the
      rendered-log pins passed through `warn-distinct`; the no-leak sweep.
- [ ] T7: `tests/plantdefect.py` entries for each check T6 adds, varying form as well as
      site — a closing encapsulation that does not match its opening, a range whose two
      ends are emitted under different keys, and a pairing report naming the wrong mark.
- [ ] T8: README section for `range=`: what an author writes, what each back-end prints,
      what each of the five reports means, and that an ordinary mark falling inside a
      term's own range is folded into that range. Add its authoring forms to the suite's
      normative supported-forms list and its sentences to a README claims array.

## Work log

- 2026-08-21: created by /milestone-plan.
- 2026-08-21: plan gate chose pairing by the entry the two marks index over an author-written pair id because the common case then needs nothing extra written (GP4); falsified by evidence that authors write overlapping ranges of one term, which pairing by entry cannot tell apart.
- 2026-08-21: plan gate chose documenting the folded-in ordinary mark over warning about it because the extension knows no page numbers and the warning would fire on marks outside the range as well; falsified by evidence that authors hit the silent loss and cannot find it from the README.
- 2026-08-21: plan gate chose shipping the principal role first (M20) over ranges first because the arbitration over makeindex's single encapsulation channel is shared and the smaller half builds it; falsified by evidence that the arbitration is range-shaped and had to be rewritten for M20's simpler case.
- 2026-08-21: criteria audit ran in full mode (user-facing tier) and returned findings on the drafted AC2, AC3, AC5, AC6 and the README criterion; the role's end was named, the closing-mark promise was narrowed off the whole page body, the cross-chapter range was reconciled against the unmatched-opening report, the residue clause was reworded to include the new attribute, and the README criterion was descoped to T8.
- 2026-08-22: implement gate settled three open choices: correct AC2's attribute name; emphasize a principal range by registering the composed printed range string rather than by matching either endpoint; and compose a range with a same-key cross-reference (the cross-reference folds into the printed text as it already does) rather than dropping the range.
- 2026-08-22: criteria audit ran in full mode on the amended AC2 and returned three findings — the `.ind` can show no emphasis at all, D-007's consequences leave the emphasis promise unfunded by Scope and T3, and no criterion covered the HTML side of a principal range; bounded-promise, probe and instrument questions clean. All three disposed at the mini gate.
- 2026-08-22: amendment: AC2 reworded (attribute name and evidence locus), AC3 widened with the HTML principal-range clause, Scope In and T3 extended with the range registration. Criteria widened or added: AC3. D-008 records the channel extension.

## Decisions

## Review
