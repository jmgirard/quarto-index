# M098: A Typst render prints the index

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M097
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP3, GP6
- **Resolves:** —
- **Surface tier:** user-facing — authors who render a document or book to Typst get a printed index
- **Branch/PR:** m098-typst-back-end

## Goal

A document or book rendered to Typst prints each of its indexes with page locators, built from the same marks the other back-ends read.

## Scope

**In:** a fourth back-end for `FORMAT` `typst`, for single documents and for books. Each mark becomes an invisible Typst label. Lua sorts and groups the entries with the code the HTML back-end uses, which moves out of `_extensions/index/modules/html.lua` into a shared module. The printed index is raw Typst that asks Typst for the page of each label while it typesets. No Typst package is imported (GP3). The index is set in two columns, as the PDF back-end sets it. Named indexes, the placement marker, cross-references, sort keys, letter groups, principal mentions and ranges work as they do in the PDF back-end. A new fixture `examples/typst-index.qmd` and a suite section read the Typst PDF. `.github/workflows/versions.yml` gains a Typst render step. A new page `site/typst.qmd` and the pages that count back-ends change.

**Out:**
- A gallery page for the Typst render goes to the gallery candidate row.
- Typst typesetting options, such as the column count or the locator separator, wait for an author to ask. Each request becomes a candidate row.
- A Typst render on the push path waits, because the PDF tools run only in the weekly and manual `pdf` job. The version-matrix candidate row holds it.
- The LaTeX level ceiling and its fold reports do not apply to Typst. Typst prints every level, as the HTML back-end does.

## Acceptance criteria

- [ ] AC1: A Typst render of the new fixture `examples/typst-index.qmd` on Quarto 1.10.18 prints each index the fixture declares, and the fixture declares two. The entries, read from the PDF with `tests/pdfindex.py`, match a manifest derived by hand from the fixture source. For each index, the manifest gives every entry and sub-entry in order under its letter group. It also gives each see and see-also reference with its English default word, and the page number of each locator. The fixture declares no `lang:` and carries each of the ten mark forms that `site/syntax.qmd` lists. Explicit page breaks in its source fix the page of each mark, so the manifest states every page number from the source.
- [ ] AC2: In that render, three marks of one term on one page print one locator. A range whose marks sit on two pages prints one locator from the opening page to the closing page. A range that opens and closes on one page prints that page alone. The locator of a principal mention is set in a bold face in the PDF, read from the font names `pdftohtml -xml` reports. Where a principal and an ordinary mark of one term share a page, the one locator is bold. Other locators are not bold. Each case is a row of the AC1 manifest.
- [ ] AC3: Each page locator in that index is one PDF link, a range locator included. The link targets the page the manifest gives for the locator, which is the opening page for a range. A see or see-also reference is not a locator and carries no link.
- [ ] AC4: A Typst render of `examples/named-indexes.qmd` prints each index that the fixture declares, under its declared title. In `pdftotext` reading order, each index heading sits after the text before its marker. It sits before the text after its marker. Each index holds the entries a hand-derived manifest assigns to it, and no entry filed in another index. The manifest prints every level the fixture writes, because Typst has no level ceiling, so its rows differ from the PDF back-end's.
- [ ] AC5: A Typst render of `examples/book/` on Quarto 1.10.18 produces one PDF with three indexes under their declared titles. `main` and `people` sit where the markers in `last.qmd` put them, and `places`, which no marker names, follows them. Each index holds the entries and page locators a hand-derived manifest gives. The term marked in three chapters has a locator on a page of each of those chapters. The existing HTML, PDF and EPUB book checks still pass after the fixture gains the `author:` that Quarto's Typst book template needs.
- [ ] AC6: A manually started run of `.github/workflows/versions.yml` passes a Typst step in its `pdf` job on two legs. They are the floor leg (Quarto 1.5.52) and the pinned leg (Quarto 1.10.18). On each leg the step renders `examples/typst-index.qmd` to Typst. `tests/pdfindex.py` then reads the entries in the order the AC1 manifest gives, each locator with the page number the manifest gives.
- [ ] AC7: The docs are true for four back-ends. README.md:5, `site/index.qmd:9`, `site/back-end-differences.qmd:7` and `site/back-end-differences.qmd:62` state four back-ends. Each numbered item of `site/back-end-differences.qmd` states what Typst does. Every hit of `grep -rniE 'three back-ends|all three|back-ends ship|only in (LaTeX|HTML)|printed index|every back-end|both back' README.md site/*.qmd` is re-read, and the work log names each hit that Typst made false and its correction. `site/other-formats.qmd` no longer covers Typst. A new page `site/typst.qmd` is in the site navigation, and `site/output.qmd` links to it. The page states that a Typst render prints each index with page locators in two columns and needs no Typst package. It states that books were tested on Quarto 1.10.18. A CHANGELOG `## Unreleased` entry states the new back-end.
- [ ] AC8: Typst renders of `examples/escaping.qmd`, `examples/xref-escaping.qmd`, `examples/sort-escaping.qmd` and `examples/unicode.qmd` on Quarto 1.10.18 exit 0. Each printed index term matches the term a hand-derived manifest states from the fixture source, compared in NFC. Typst renders of `examples/index-lang-es.qmd` and `examples/index-labels.qmd` print the see and see-also words that the language table and the author's override give.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T3, T4
- AC3 → T3, T4
- AC4 → T3, T5
- AC5 → T3, T5
- AC6 → T6
- AC7 → T7
- AC8 → T3, T5

## Tasks

- [x] T1: Add `is_typst()` beside the format checks in `_extensions/index/modules/core.lua:418-445`. Route a Typst render through the emitting pass (`passes.lua:386` onward) and the Pandoc pass in `index.lua`. The format-gated sites are `index.lua` 133, 140, 171, 197, 202 and 228, and `passes.lua` 46, 104, 167, 290, 535, 580 and 662. Keep beamer, reveal.js and gfm on pass-through, and keep their suite checks green.
- [x] T2: Move `collate`, the letter-group functions, `build_entry_tree` and `number_entries` (`html.lua:33-285`) into a shared module. Separate the fields that name an anchor from the fields that name a locator. HTML and EPUB output stay byte-identical, which the existing HTML and EPUB checks show.
- [x] T3: Emit Typst. Each mark gets a label. Each index is a raw Typst block. Its helper looks up pages, merges repeated pages, prints ranges, sets principal locators in bold and links each locator. Place each block with `qi_marker.place_index` (`marker.lua:344`). The see and see-also words come from `indexes.label`.
- [x] T4: Write `examples/typst-index.qmd` and its manifest. Add the suite section for AC1 to AC3, with a self-test plant for each clause it reads. Adapt `tests/pdfindex.py` only where the Typst layout needs it, and state each change in the section. Add the bold reader over `pdftohtml -xml` and the link reader.
- [x] T5: Add the Typst checks for `examples/named-indexes.qmd` and `examples/book/`, with their manifests and plants. Add `author:` to `examples/book/_quarto.yml` and run the existing book checks. Add the Typst checks and manifests for the four escaping and Unicode fixtures and the two label fixtures in AC8. Every character Typst reads as markup in a term, a sort key or a label is escaped in T3.
- [x] T6: Add the Typst step to the `pdf` job of `versions.yml`, which already installs poppler. Start the workflow by hand and record the run URL.
- [ ] T7: Write `site/typst.qmd` and add it to `site/_quarto.yml`. Change the back-end counts, `site/other-formats.qmd`, README and CHANGELOG. Add `tests/sitecheck.py` claims for the new sentences. Update the Architecture section of `cairn/DESIGN.md`.

## Work log

- 2026-09-13: created by /milestone-plan.
- 2026-09-13: plan gate chose a Lua-built entry tree with raw Typst page lookups over a Typst Universe index package. A package downloads at compile time, so offline renders fail, and it adds a dependency (GP3). Falsified by a page lookup that the Typst of a supported Quarto cannot run, or that a package does and raw Typst cannot.
- 2026-09-13: plan gate kept books in this milestone rather than a separate one. A Typst book renders as one merged Pandoc process on Quarto 1.10.18, observed 2026-09-13, so it reuses the single-document path. Falsified by a Quarto release that renders a Typst book one chapter at a time.
- 2026-09-13: plan chose reading bold from PDF font names over reading the captured `.typ` source, after the criteria audit (GP6). Falsified by a Typst font setup whose bold face carries no bold marker in its name.
- 2026-09-13: criteria audit (full mode), round 1 on the draft criteria: 17 findings. Adopted: English default words, bold read from the PDF, same-page principal and range rules, range link to its opening page, no link on see references, unplaced index checked through the book, named sweep sites, and two-column layout. The version-gate findings became moot when the gate raised the floor (M097).
- 2026-09-13: criteria audit (full mode), round 2 on the gate-changed criteria of M097 and M098: running at this checkpoint commit. The plan is not final until its findings are disposed.
- 2026-09-13: criteria audit (full mode), round 2 returned 15 findings across M097 and M098, all adopted. M097: the grep exclusions, the named docstring sites, KI114 removed rather than edited, the compare job read for the floor and pinned pair only, and the floor PDF job recorded. M098: a docs sweep for sentences Typst makes false, placement read in text order, two indexes in the Typst fixture, books claimed for 1.10.18 only, page numbers checked on the floor leg, and the CI step moved to the `pdf` job. A new AC8 covers escaping, Unicode and label words (IP2). The plan is final.
- 2026-09-13: plan kept 8 criteria over the 7-criterion split tripwire. AC8 guards IP2 for the same emitted Typst the other criteria read, so it does not ship on its own.
- 2026-09-13: probe on Typst 0.15.1: labels on `#metadata` marks and `locate(label).page()` inside `context` printed page locators 1, 2 for marks on two pages. The Typst 0.10 form `locate(loc => ...)` fails on 0.15.1.
- 2026-09-13: implement started on branch m098-typst-back-end. Probe on Typst 0.15.1: `link(location, strong(...))` gives a PDF link whose page `pdftohtml -xml` reports. `pdftohtml -xml -fontfullname` names the bold face `LibertinusSerif-Bold`. Plain `-xml` drops the weight from the family name.
- 2026-09-13: question gate: a Typst index prints each page of a run of consecutive pages, and does not fold three or more into a range as makeindex does. Only an author's range prints as a range. A locator prints the page number as the page shows it, and the physical page where the page has no numbering.
- 2026-09-13: T1 done (bfdb2c3). A Typst render records each mark as HTML and EPUB do, and writes a `#metadata` label after each locator mark. A label inside a heading is copied into the outline, so heading marks move after the heading as in HTML. Suite at bfdb2c3: 804 checks passed.
- 2026-09-13: T2 (a85d993): `entries.lua` holds the collation, letter groups, entry tree, numbering and index filing. Each back-end passes its own locator rule to the tree. 71 HTML and XHTML files from 11 fixtures and the book rendered byte-identical before and after. Two self-test plants moved with the code: the EPUB routing plant now removes only the EPUB route, and the fold plant targets `entries.lua`.
- 2026-09-13: T3 code: the letter-group walk and its heading clash report moved to `entries.lua` too, still byte-identical over the same 71 files. All 75 example fixtures render to Typst with exit 0. The Typst label follows the span, because Pandoc writes an author's id label straight after the span content and Typst warned on a doubled label. The book renders to Typst once `_quarto.yml` has `author:`. Found: a mark in a front-matter field the Typst template does not print (`description:`) prints its term with no locator.
- 2026-09-13: T2 and T3 checked off. Suite with `--self-test` at e809c61: 1523 checks passed, the two moved plants among them.
- 2026-09-13: T4 (commit after e809c61) adds `examples/typst-index.qmd`, the manifests `tests/typst-index-main.tsv` and `tests/typst-index-people.tsv`, and the reader `tests/typstindex.py`. The AC1-AC3 section has 15 plants and a clean control, and each plant is red with its own row.
- 2026-09-13: T5 (bbe7cef) adds `tests/typstcheck.py` and the AC4, AC5 and AC8 checks with 6 plants, all red on their own failure. `examples/book/_quarto.yml` gains `author:`. The new fixture joins the M14 cross-reference roster (0 reports) and the gallery's not-shown list, which the T4 suite run found missing. The escaping check folds a repeated combining cluster. pdftotext reads Typst's `Nux̌alk` as `Nux̌x̌alk` in the index and in Pandoc's body text alike, and the page image prints it once.
- 2026-09-13: T6: user approved pushing the branch before review to start the Versions run. Run 34785212891 (https://github.com/jmgirard/quarto-index/actions/runs/34785212891) was red on the floor leg only: every row matched except `fig`, which pdftotext read as `ﬁg` with U+FB01 from the Typst in Quarto 1.5.52. The pinned and release legs passed. The fixture term became `fern`.
- 2026-09-13: T6 done. Run 34785351085 (https://github.com/jmgirard/quarto-index/actions/runs/34785351085) at ddc13a7 passed: both Typst steps passed on the floor (1.5.52), pinned (1.10.18) and release legs.
- 2026-09-13: T4 and T5 checked off. Suite with `--self-test` at bbe7cef: 1575 checks passed. The `fern` rename after it is re-run by the T7 suite run.
- 2026-09-13: T7 AC7 sweep, 17 hits re-read. Typst made six false, each corrected: README.md:5, site/index.qmd:9 and site/back-end-differences.qmd:7 counted three back-ends, now four. back-end-differences:34 said a printed index cannot link at all, now that in the LaTeX and Typst indexes a target is always plain text. Line 42 said a page range is a range only in LaTeX, now LaTeX and Typst. Line 62 said all three back-ends follow `lang:`, now all four, and that item names Typst's table and `index-labels:` reading. Not made false: back-end-differences:63, books.qmd:245, cross-references.qmd:23 and :26, letter-groups.qmd:16, principal-mention.qmd:9, sorting.qmd:85, placing-the-index.qmd:15 and :22, tests.qmd:29, terms-outside-latin-1.qmd:42 and :56, sub-entry-levels.qmd:74.
- 2026-09-13: T7: `site/typst.qmd` is in the sidebar and linked from `site/output.qmd`. Every back-end-differences item states what Typst does, and `site/books.qmd`, `site/tests.qmd` and CHANGELOG gain Typst sentences. `site/other-formats.qmd` is unchanged: it names no Typst, and its rule covers formats with no back-end, which Typst no longer is. DESIGN gains the `entries.lua`, `typst.lua` and Typst routing text and KI289-KI291. The AC7 section holds 49 claim rows and a three-back-ends sweep. Its renders check consecutive pages, fixed punctuation, an unprinted front-matter field, the outline entry, no package import and the book's `author:`. All 73 M098 checks and plants passed in isolation. `tests/pdfindex.py` is unchanged: it reads the Typst index's order, levels and footer as they stand. The reader takes links from the PDF's link annotations, because `pdftohtml -xml` at its default zoom assigned a link to the wrong characters.

## Decisions

## Review
