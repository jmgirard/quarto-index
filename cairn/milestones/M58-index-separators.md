# M058: An author sets the punctuation the index prints inside an entry

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP4, GP5

## Goal

The two punctuation strings the HTML and EPUB index prints inside an entry — the
comma before and between an entry's locators, and the semicolon between two
cross-references — become author-settable under the existing `index-labels:`
map. Surface tier: **user-facing** — new author-written metadata keys and
changed printed output.

## Scope

**In:** two new `index-labels:` keys, `separator` and `xref-separator`, resolved
by the `label()` ladder `indexes.lua:331` already implements (per-index map,
then document map, then the printing site's own English word), applied at the
five sites `html.lua`'s `entry_inlines` prints:

- S1 term → its locators, S2 locator → locator, S3 locators → first
  cross-reference, S4 term → first cross-reference where the entry has no
  locators — all four take `separator` (`html.lua:287`, `html.lua:317`);
- S5 cross-reference → cross-reference, which takes `xref-separator`
  (`html.lua:317`, reached only when `previous_was_xref`).

A key sets the punctuation glyph alone; the `pandoc.Space()` after it stays the
filter's. No refusal is written for a value ending in whitespace: Pandoc parses
scalar metadata as `MetaInlines` and drops a trailing ASCII space before
`read_labels` sees it (probed on pandoc 3.10.2, 2026-08-29: `a: ", "` stringifies
to `,`, and `"   "` to the empty string, which the existing empty-value branch
at `indexes.lua:163` already reports). A trailing U+00A0 does survive, and is
left alone — a no-break space before a semicolon is French typography, not a
mistake.

**Out:**

- `modules/languages.lua` gains no punctuation keys, so a `lang: ar` document
  still sets these by hand → a new candidate row holds the table half, and the
  existing row is reworded to what this milestone actually delivers.
- LaTeX. `core.lua`'s `XREF_BOTH_DEFINITION` hard-codes its `;` and makeindex
  owns its own term/locator delimiter; no declared separator reaches `.tex`,
  matching D-035's rule for localized words → the candidate row above.
- `levels.lua`'s `TARGET_JOIN` (`": "`), the level join inside a cross-reference
  target: `latex.lua:308` reads the same constant, so localizing it would drift
  the two back-ends apart on target text, which `html.lua:88` forbids → the
  candidate row above.

## Acceptance criteria

- [ ] AC1. Rendering `examples/index-separators.qmd` to HTML, every entry the
      rendered index prints carries the document's declared `separator` at each
      of S1–S4 it reaches and the declared `xref-separator` at S5, checked entry
      by entry against a hand-derived manifest whose row count the check asserts
      equal to the number of entry items the rendered index holds. The fixture
      indexes at least one entry with two locators, one with locators and one
      cross-reference, one with no locators and one cross-reference, and one
      with two cross-references, so all five sites are reached.
- [ ] AC2. `examples/index-separators-twin.qmd` — the same document with its
      `index-labels:` block deleted, that block setting `separator` and
      `xref-separator` and no other key — prints `,` at S1–S4 and `;` at S5 over
      the same manifest of site slots, in the same suite run.
- [ ] AC3. `examples/index-separators-scoped.qmd` declares two indexes, sets
      both keys at the document level and `separator` alone under the second
      index, gives the three declared values three distinct glyphs, and files
      two cross-references on one term in each index. One render prints the
      second index's own `separator` and the document's `xref-separator` within
      that index, and the document's values for both keys in the first.
- [ ] AC4. `examples/index-labels-misuse.qmd` gains one further per-index
      `index-labels:` map giving `separator` and `xref-separator` an empty
      value each; the render emits, for each, `indexes.lua:163`'s empty-value
      report with the key named, asserted message-whole, and the index prints
      `,` and `;` at the sites those keys name.
- [ ] AC5. `indexes.lua`'s unknown-key report names all five keys: rendering
      `examples/index-labels-misuse.qmd`, the message its existing `symbol` key
      draws is asserted message-whole and lists `symbols, see, see-also,
      separator, xref-separator`.
- [ ] AC6. `examples/index-separators.qmd` declares U+060C and U+061B. Rendered
      to LaTeX its `.tex` is byte-identical to `examples/index-separators-twin.qmd`'s
      — a same-tree comparison under D-012, not the merge-base oracle D-004
      refused — and that `.tex` holds the `\index` commands a hand-derived count
      states, the count deriving from the fixture's marks and `latex.lua`'s
      contested-key fold, which merges a term that is both plainly marked and
      cross-referenced.
- [ ] AC7. `examples/index-separators.qmd` rendered to EPUB prints the declared
      values at S1–S5, checked against AC1's manifest over the spine document
      holding the index rather than over the HTML render, with the same
      row-count assertion.
- [ ] AC8. `site/cross-references.qmd`, `site/letter-groups.qmd` and
      `site/back-end-differences.qmd` each name all five `index-labels:` keys
      where they today name three (`cross-references.qmd:107`,
      `letter-groups.qmd:37`, `back-end-differences.qmd:49`);
      `back-end-differences.qmd` states that neither new key reaches LaTeX; and
      one of the three states that the space after a separator is the
      extension's own, so a key sets the glyph alone.
- [ ] AC9. `tests/run-tests.sh` is green plain and with `--self-test`, both
      exit 0, over the merged tree.

## Coverage

- AC1 → T2, T3, T6
- AC2 → T2, T6
- AC3 → T2, T6
- AC4 → T4, T6
- AC5 → T1, T4, T6
- AC6 → T2, T5, T6
- AC7 → T2, T7
- AC8 → T8
- AC9 → T9

## Tasks

- [ ] T1. Add `separator` and `xref-separator` to `LABEL_KEYS`
      (`indexes.lua:61`), which also extends the unknown-key report's key list
      at `indexes.lua:157`. No new validation branch: the empty-value branch at
      `:163` covers both new keys unchanged.
- [ ] T2. Write `examples/index-separators.qmd`, its `-twin.qmd` and
      `-scoped.qmd`, giving every new term a spelling no other example indexes
      (the M13 sort-key-collision lesson), and register them in
      `site/gallery.yml` and `site/examples.qmd` alongside the `index-labels`
      family.
- [ ] T3. Thread `qi_indexes.label(name, …)` through `entry_inlines`'s three
      literal punctuation sites (`html.lua:287`, `html.lua:317`), keeping each
      `pandoc.Space()` where it is; `name` is already in scope at
      `html.lua:277`.
- [ ] T4. Add the empty-value per-index map to `examples/index-labels-misuse.qmd`
      without disturbing the string-valued and list-valued maps AC5 and the
      existing checks depend on.
- [ ] T5. Extend `tests/indexdump.py` (or the reader `run-tests.sh` already uses
      for the `index-labels` pair's `.tex` comparison) to cover the new pair,
      and hand-derive the `\index` count AC6 states from the fixture's marks.
- [ ] T6. Write the HTML manifest reader and its row-count assertion, and the
      scoped-resolution check.
- [ ] T7. Extend `tests/epubindex.py` to read the separators from the spine.
- [ ] T8. Rewrite the three docs pages and the changelog entry.
- [ ] T9. Plant the defect matrix through `tests/plantdefect.py`, varying FORM
      as well as location: glyph swapped at one site, separator dropped
      entirely, the trailing `pandoc.Space()` lost, the wrong key consulted at a
      site, and a per-index map ignored — each shown to redden a named check
      with `plantdefect.py`'s printed expected marker, not merely to fail.

## Work log

- 2026-08-29: created by /milestone-plan.
- 2026-08-29: criteria audit ran in FULL mode (user-facing tier), two passes over a fresh-context [O] reader. Pass 1 returned 15 findings across 6 of 8 drafted criteria; pass 2, over the revised set, returned 11 across 6 of 8. Both disposed at the gate: the manifest-completeness and plant-matrix promises were instrument-bound and moved to the tasks (AC8 of the draft deleted outright), AC1 and AC7 gained row-count closure, AC3 gained distinct glyphs and a mark inventory, AC6 replaced a 1:1 `\index` rule its own required fixture would falsify with a hand-derived count, and AC4/AC8's trailing-whitespace refusal was deleted as a guard for a class the host never delivers.
- 2026-08-29: plan gate chose two new keys inside the existing `index-labels:` map over a separate punctuation map, because GP5 prefers extending one mechanism to adding a parallel syntax and `label()`'s ladder already resolves per-index-then-document; falsified by an author needing punctuation resolved on a different ladder from the words, or by the two surfaces needing different validation.
- 2026-08-29: plan gate chose author-override alone over shipping an `ar` row in `languages.lua`, because the table's method demands two independent references agreeing on the string and "an Arabic index separates locators with U+060C" is an index-specific claim Unicode alone does not settle — M57 withheld German's `Symbols` on that same test; falsified by two references of different kinds agreeing on Arabic index punctuation.
- 2026-08-29: plan gate chose two keys over one per printed site, because no convention found distinguishes S1 from S2 or S3 and five keys would cost three more rows in every docs table; falsified by an author wanting term→locators set differently from locator→locator.
- 2026-08-29: plan gate chose to leave the `pandoc.Space()` with the filter over having the author write it into the value, because a value written without it would silently glue a locator to its term in a render that stays green; falsified by an author needing no space at all after a separator.

## Decisions

## Review
