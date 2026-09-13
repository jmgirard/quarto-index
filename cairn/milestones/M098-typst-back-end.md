# M098: A Typst render prints the index

- **Status:** planned
- **Priority:** normal
- **Depends on:** M097
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP3, GP6
- **Resolves:** —
- **Surface tier:** user-facing — authors who render a document or book to Typst get a printed index
- **Branch/PR:** —

## Goal

A document or book rendered to Typst prints each of its indexes with page locators, built from the same marks the other back-ends read.

## Scope

**In:** a fourth back-end for `FORMAT` `typst`, for single documents and for books. Each mark becomes an invisible Typst label. Lua sorts and groups the entries with the code the HTML back-end uses, which moves out of `_extensions/index/modules/html.lua` into a shared module. The printed index is raw Typst that asks Typst for the page of each label while it typesets. No Typst package is imported (GP3). The index is set in two columns, as the PDF back-end sets it. Named indexes, the placement marker, cross-references, sort keys, letter groups, principal mentions and ranges work as they do in the PDF back-end. A new fixture `examples/typst-index.qmd` and a suite section read the Typst PDF. `.github/workflows/versions.yml` gains a Typst render step. A new page `site/typst.qmd` and the pages that count back-ends change.

**Out:**
- A gallery page for the Typst render goes to the gallery candidate row.
- Typst typesetting options, such as the column count or the locator separator, wait for an author to ask. Each request becomes a candidate row.
- A Typst leg in the weekly release-channel job waits for this step to prove stable on the two exact legs. It becomes a candidate row at review.
- The LaTeX level ceiling and its fold reports do not apply to Typst. Typst prints every level, as the HTML back-end does.

## Acceptance criteria

- [ ] AC1: A Typst render of the new fixture `examples/typst-index.qmd` on Quarto 1.10.18 prints an index. Its entries, read from the PDF with `tests/pdfindex.py`, match a manifest derived by hand from the fixture source. The manifest gives every entry and sub-entry in order under its letter group. It also gives each see and see-also reference with its English default word, and the page number of each locator. The fixture declares no `lang:` and carries each of the ten mark forms that `site/syntax.qmd` lists. Explicit page breaks in its source fix the page of each mark, so the manifest states every page number from the source.
- [ ] AC2: In that render, three marks of one term on one page print one locator. A range whose marks sit on two pages prints one locator from the opening page to the closing page. A range that opens and closes on one page prints that page alone. The locator of a principal mention is set in a bold face in the PDF, read from the font names `pdftohtml -xml` reports. Where a principal and an ordinary mark of one term share a page, the one locator is bold. Other locators are not bold. Each case is a row of the AC1 manifest.
- [ ] AC3: Each page locator in that index is one PDF link, a range locator included. The link targets the page the manifest gives for the locator, which is the opening page for a range. A see or see-also reference is not a locator and carries no link.
- [ ] AC4: A Typst render of `examples/named-indexes.qmd` prints each index that the fixture declares, under its declared title, at the position its marker gives. Each index holds the entries a hand-derived manifest assigns to it, and no entry filed in another index. The manifest prints every level the fixture writes, because Typst has no level ceiling, so its rows differ from the PDF back-end's.
- [ ] AC5: A Typst render of `examples/book/` produces one PDF with three indexes under their declared titles. `main` and `people` sit where the markers in `last.qmd` put them, and `places`, which no marker names, follows them. Each index holds the entries and page locators a hand-derived manifest gives. The term marked in three chapters has a locator on a page of each of those chapters. The existing HTML, PDF and EPUB book checks still pass after the fixture gains the `author:` that Quarto's Typst book template needs.
- [ ] AC6: A manually started run of `.github/workflows/versions.yml` passes a Typst step on the floor leg (Quarto 1.5.52) and on the pinned leg (Quarto 1.10.18). On each leg the step renders `examples/typst-index.qmd` to Typst, and `tests/pdfindex.py` reads entries in the order the AC1 manifest gives.
- [ ] AC7: README, `site/index.qmd`, `site/output.qmd` and `site/back-end-differences.qmd` state four back-ends. The sentences that say three today are README.md:5, `site/back-end-differences.qmd:7` and `site/back-end-differences.qmd:62`, plus any hit `grep -rniE 'three back-ends|all three|back-ends ship' README.md site/*.qmd` returns. `site/other-formats.qmd` no longer covers Typst. A new page `site/typst.qmd` is in the site navigation. It states that a Typst render prints each index with page locators in two columns, and that the index needs no Typst package. A CHANGELOG `## Unreleased` entry states the new back-end.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T3, T4
- AC3 → T3, T4
- AC4 → T3, T5
- AC5 → T3, T5
- AC6 → T6
- AC7 → T7

## Tasks

- [ ] T1: Add `is_typst()` beside the format checks in `_extensions/index/modules/core.lua:418-445`. Route a Typst render through the emitting pass (`passes.lua:386` onward) and the Pandoc pass in `index.lua`. The format-gated sites are `index.lua` 133, 140, 171, 197, 202 and 228, and `passes.lua` 46, 104, 167, 290, 535, 580 and 662. Keep beamer, reveal.js and gfm on pass-through, and keep their suite checks green.
- [ ] T2: Move `collate`, the letter-group functions, `build_entry_tree` and `number_entries` (`html.lua:33-285`) into a shared module. Separate the fields that name an anchor from the fields that name a locator. HTML and EPUB output stay byte-identical, which the existing HTML and EPUB checks show.
- [ ] T3: Emit Typst. Each mark gets a label. Each index is a raw Typst block. Its helper looks up pages, merges repeated pages, prints ranges, sets principal locators in bold and links each locator. Place each block with `qi_marker.place_index` (`marker.lua:344`). The see and see-also words come from `indexes.label`.
- [ ] T4: Write `examples/typst-index.qmd` and its manifest. Add the suite section for AC1 to AC3, with a self-test plant for each clause it reads. Adapt `tests/pdfindex.py` only where the Typst layout needs it, and state each change in the section. Add the bold reader over `pdftohtml -xml` and the link reader.
- [ ] T5: Add the Typst checks for `examples/named-indexes.qmd` and `examples/book/`, with their manifests and plants. Add `author:` to `examples/book/_quarto.yml` and run the existing book checks.
- [ ] T6: Add the Typst step to both exact legs of `versions.yml`, with the poppler install it needs. Start the workflow by hand and record the run URL.
- [ ] T7: Write `site/typst.qmd` and add it to `site/_quarto.yml`. Change the back-end counts, `site/other-formats.qmd`, README and CHANGELOG. Add `tests/sitecheck.py` claims for the new sentences. Update the Architecture section of `cairn/DESIGN.md`.

## Work log

- 2026-09-13: created by /milestone-plan.
- 2026-09-13: plan gate chose a Lua-built entry tree with raw Typst page lookups over a Typst Universe index package. A package downloads at compile time, so offline renders fail, and it adds a dependency (GP3). Falsified by a page lookup that the Typst of a supported Quarto cannot run, or that a package does and raw Typst cannot.
- 2026-09-13: plan gate kept books in this milestone rather than a separate one. A Typst book renders as one merged Pandoc process on Quarto 1.10.18, observed 2026-09-13, so it reuses the single-document path. Falsified by a Quarto release that renders a Typst book one chapter at a time.
- 2026-09-13: plan chose reading bold from PDF font names over reading the captured `.typ` source, after the criteria audit (GP6). Falsified by a Typst font setup whose bold face carries no bold marker in its name.
- 2026-09-13: criteria audit (full mode), round 1 on the draft criteria: 17 findings. Adopted: English default words, bold read from the PDF, same-page principal and range rules, range link to its opening page, no link on see references, unplaced index checked through the book, named sweep sites, and two-column layout. The version-gate findings became moot when the gate raised the floor (M097).
- 2026-09-13: criteria audit (full mode), round 2 on the gate-changed criteria of M097 and M098: running at this checkpoint commit. The plan is not final until its findings are disposed.
- 2026-09-13: probe on Typst 0.15.1: labels on `#metadata` marks and `locate(label).page()` inside `context` printed page locators 1, 2 for marks on two pages. The Typst 0.10 form `locate(loc => ...)` fails on 0.15.1.

## Decisions

## Review
