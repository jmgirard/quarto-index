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
- AC2 → T3, T4, T10
- AC3 → T3, T4
- AC4 → T3, T5
- AC5 → T3, T5, T9
- AC6 → T6, T12, T13
- AC7 → T7
- AC8 → T3, T5, T8

## Tasks

- [x] T1: Add `is_typst()` beside the format checks in `_extensions/index/modules/core.lua:418-445`. Route a Typst render through the emitting pass (`passes.lua:386` onward) and the Pandoc pass in `index.lua`. The format-gated sites are `index.lua` 133, 140, 171, 197, 202 and 228, and `passes.lua` 46, 104, 167, 290, 535, 580 and 662. Keep beamer, reveal.js and gfm on pass-through, and keep their suite checks green.
- [x] T2: Move `collate`, the letter-group functions, `build_entry_tree` and `number_entries` (`html.lua:33-285`) into a shared module. Separate the fields that name an anchor from the fields that name a locator. HTML and EPUB output stay byte-identical, which the existing HTML and EPUB checks show.
- [x] T3: Emit Typst. Each mark gets a label. Each index is a raw Typst block. Its helper looks up pages, merges repeated pages, prints ranges, sets principal locators in bold and links each locator. Place each block with `qi_marker.place_index` (`marker.lua:344`). The see and see-also words come from `indexes.label`.
- [x] T4: Write `examples/typst-index.qmd` and its manifest. Add the suite section for AC1 to AC3, with a self-test plant for each clause it reads. Adapt `tests/pdfindex.py` only where the Typst layout needs it, and state each change in the section. Add the bold reader over `pdftohtml -xml` and the link reader.
- [x] T5: Add the Typst checks for `examples/named-indexes.qmd` and `examples/book/`, with their manifests and plants. Add `author:` to `examples/book/_quarto.yml` and run the existing book checks. Add the Typst checks and manifests for the four escaping and Unicode fixtures and the two label fixtures in AC8. Every character Typst reads as markup in a term, a sort key or a label is escaped in T3.
- [x] T6: Add the Typst step to the `pdf` job of `versions.yml`, which already installs poppler. Start the workflow by hand and record the run URL.
- [x] T7: Write `site/typst.qmd` and add it to `site/_quarto.yml`. Change the back-end counts, `site/other-formats.qmd`, README and CHANGELOG. Add `tests/sitecheck.py` claims for the new sentences. Update the Architecture section of `cairn/DESIGN.md`.
- [ ] T8: Write a hand-derived manifest of the terms `examples/xref-escaping.qmd` prints. Hold the AC8 `typstcheck.py source` derivation for that fixture to it, as for the other three fixtures. Add a plant that is red on a changed derived term. (Review finding 5.)
- [ ] T9: Make the AC5 book check compare the page numbers of a hand-derived manifest, with the pages fixed from the fixture source. It no longer reads chapter bounds from the PDF under test. Add a plant that moves a locator one page inside its chapter and is red. (Review finding 4.)
- [ ] T10: In the Typst index, drop an ordinary locator whose page a range of the same term covers, as makeindex does, so `b, 1, 1–2` prints `b, 1–2`. Add the case as a row of the AC1 manifest with a plant, and state the rule in `site/typst.qmd` with a claim check. (Review finding 1.)
- [ ] T11: Make a mark in image alt text, whose label Pandoc's Typst writer drops, no longer lose its locator in silence. Report it at render where the filter can tell, or record it as a known issue beside KI289. (Review finding 2.)
- [ ] T12: Run `typstindex.py pages` green on `examples/typst-index.qmd` in the suite, and not only as a red plant. Correct the `run-tests.sh:9504` comment that names `html.lua` for the locator tree. (Review findings 8 and 11.)
- [ ] T13: After T8 to T12, push the branch head and start `.github/workflows/versions.yml` by hand. Record the run URL and the Typst steps on the floor and pinned legs.

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
- 2026-09-13: T7: `site/typst.qmd` is in the sidebar and linked from `site/output.qmd`. Every back-end-differences item states what Typst does, and `site/books.qmd`, `site/tests.qmd` and CHANGELOG gain Typst sentences. `site/other-formats.qmd` is unchanged: it names no Typst, and its rule covers formats with no back-end, which Typst no longer is. DESIGN gains the `entries.lua`, `typst.lua` and Typst routing text and KI289-KI291. The AC7 section holds 49 claim rows and a three-back-ends sweep. Its renders check consecutive pages, fixed punctuation, an unprinted front-matter field, the outline entry, no package import and the book's `author:`. All 73 M098 checks and plants passed in isolation.
- 2026-09-13: claim audit: 230 claims read, 9 corrected — site/typst.qmd, site/books.qmd, CHANGELOG.md, _extensions/index/index.lua, modules/core.lua, modules/entries.lua, modules/typst.lua, tests/typstindex.py, tests/typstcheck.py, tests/run-tests.sh
- 2026-09-13: the audit found a defect: in a document whose headings start at `##`, Quarto moved the index's Pandoc header up a level for Typst, so it printed as a paragraph the outline did not list. The heading is now a raw Typst `heading`. A new AC7 render checks the outline, the heading an untitled index gets and an index with no marks, and a plant writing the heading as a paragraph is red. The reader's re-read found all nine corrections hold (6e061f9).
- 2026-09-13: T7 checked off. Suite with `--self-test` at 6e061f9: 1599 checks passed. Status review. `tests/pdfindex.py` is unchanged: it reads the Typst index's order, levels and footer as they stand. The reader takes links from the PDF's link annotations, because `pdftohtml -xml` at its default zoom assigned a link to the wrong characters.
- 2026-09-13: review return 1 (defect): AC8 failed as written, because `examples/xref-escaping.qmd` has no hand-derived manifest. AC5 was not verified, because the book locators are compared by chapter with bounds read from the PDF. AC6 was not verified on the final tree, because run 34785351085 predates the heading change in 6e061f9. Status in-progress, with T8 to T13 added.
- 2026-09-13: step-7 gate: the user chose the send-back, the proposed finding dispositions, and dropping a page a range covers. The send-back approves the branch push T13 needs.
- 2026-09-13: T8 code: the xref-escaping check is held to a statement of the fixture's construction, which matches all 643 derived entries. `a00` writes `L1!!!!L3`, which the left-to-right level parse reads as the one level `L1!!L3`, and the statement names that case. The plant xref-changed is red on `(2, '&')` alone, and the real fixture is green (run in isolation).
- 2026-09-13: T9 code: `typstcheck.py book` compares each locator's printed page number with the manifest and no longer maps pages to chapters. Its chapter rows state each chapter's opening page, and the check holds the heading to that page. On Quarto 1.10.18 the chapters open on pages 5, 7, 9 and 11, each chapter's text fits its opening page, and a blank back page follows. The plant book-pageplus moves every locator one page on, onto that blank page, and is red on `Alpha 6`. book-noclose now reads `7*`. All three indexes are green on a scratch render.
- 2026-09-13: T10 code: `qi-index-entry` drops a one-page locator whose page a range of the same entry spans, end pages included. A probe on the PDF back-end showed that makeindex also drops a principal page inside a range, so the bold is lost, and Typst matches it. `examples/typst-index.qmd` gains `kelp`, which prints `2–3@2, 4@4`. The nocover plant, the AC2 case row and two `site/typst.qmd` claim rows were added. The fixture, both manifests, `typstindex.py pages` and the 28 claims are green in isolation, and the fixture renders to HTML, LaTeX and gfm with no warning.
- 2026-09-13: T11 code: the filter moves each label written in image alt text to just after the image, which fixes the lost locator rather than reporting it. A new AC7-section render has an inline image, a figure whose caption Quarto copies into the alt text, and a plain and a principal mark in one alt text. Its manifest is green, and the alt-kept plant is red on `imgterm` with no locator (run in isolation). DESIGN's Typst routing text states the move.

## Decisions

## Review

Sync: `origin/main` has not moved since the branch was cut. `main` has no unpushed commits. The suite ran with `--self-test` at 926bde6 on Quarto 1.10.18: exit 0, 1599 checks passed.

- AC1: verified. The M098-AC1/AC2/AC3 section shows the fixture declares two indexes and no `lang:`, and it carries the ten forms from `site/syntax.qmd` with fixed page breaks. The 24 lines of `Index of Terms` and the 52 lines of `Index of People` match `tests/typst-index-main.tsv` and `tests/typst-index-people.tsv`, each locator's page included. The people index fills both columns. 15 plants are red, each on its own row.
- AC2: verified. The terms manifest carries a row for each AC2 case, principal and shared-page rows included. The reader matched each face. Plants nomerge, norange, samepage, nobold, sharedpage and allbold are red.
- AC3: verified. `Index of Terms` prints 13 locators on page 5 with exactly 13 links, and `Index of People` prints 26 locators on page 6 with 26 links. The link targets match the manifest pages. Plants closelink and xreflink are red.
- AC4: verified. The `main` index (19 lines) and the `authors` index (20 lines) of `examples/named-indexes.qmd` match their hand manifests at every level. The 6 placement lines are in reading order. Plants named-fold and named-unplaced are red.
- AC5: not verified as written. The render gives one PDF with three indexes under their titles, placed as `last.qmd` places them, and the HTML, PDF and EPUB book checks pass. But the manifest names a chapter for each locator, not a page, and `typstcheck.py book` reads the chapter bounds from the PDF under test. So the check does not compare the "page locators a hand-derived manifest gives" (review finding 4).
- AC6: not verified on the final tree. Run 34785351085 at ddc13a7 passed both Typst steps on the floor (1.5.52), pinned (1.10.18) and release legs. Commit 6e061f9 later changed the index heading that `typst.lua` emits, and no run exists at the branch head.
- AC7: verified. README.md:5, `site/index.qmd:9` and `site/back-end-differences.qmd:7` state four back-ends. The `lang:` item, line 62 on main, now at line 74, says "All four". Each of the ten numbered items covers Typst, item 6 by naming all four back-ends. The sweep grep gives 13 hits, and the work log names each hit it corrected. `site/other-formats.qmd` names no Typst. `typst.qmd` is in `site/_quarto.yml` and linked from `site/output.qmd`, and it states two columns, no package and Quarto 1.10.18. CHANGELOG `## Unreleased` states the back-end. The M098-AC7 checks and their three plants passed.
- AC8: fails as written. The four fixtures render with exit 0, and the two label fixtures print the Spanish and override words. The escaping, sort-escaping and unicode terms are held to a hand statement. `examples/xref-escaping.qmd` has none: its 643 entries come only from `typstcheck.py source`, the code that derives them (review finding 5).

Consistency gate: `cairn_validate.py` exit 0, all checks passed, with one advisory (8 criteria over the 7 tripwire, recorded at plan). The milestone changes no DESIGN principle, so `cairn_impact` was skipped. The generic profile names no toolchain checks.

Independent review, three lenses. The [S] blame-history lens found nothing: the moved code, the retargeted plants and the D-009/D-060 uses match history. The [S] prior-review lens found no prior-review evidence (archived reviews are one-line summaries, and the PR comment probe returned none). The [O] diff-bug lens gave 11 findings, ranked:

1. `typst.lua:56`: a page mark inside a range prints separately (`b, 1, 1–2`), where makeindex drops the covered page. No doc or KI records the difference.
2. `typst.lua:43`: a mark in image alt text loses its locator with no warning, because Pandoc's Typst writer drops the label. KI289 names only front-matter fields.
3. `typst.lua:35-37`: a two-counter `page-numbering` pattern such as `"1 / 1"` prints `1` where the footer shows `1/3`, against `site/typst.qmd:40`.
4. `typstcheck.py:156-192`: the AC5 locators are compared by chapter, with bounds read from the PDF under test. A page off by one inside its chapter passes.
5. `run-tests.sh:29269,29293`: the AC8 check for `xref-escaping.qmd` has no hand-derived oracle.
6. `typstcheck.py:353`: `unrepeat_clusters` folds a doubled combining cluster in the printed text only, so an emitted doubling passes (KI291).
7. `typst.lua:198-214`: a caption mark copied into a list of figures can report the outline's page (KI290).
8. `run-tests.sh:29081`: `typstindex.py pages` runs green only in CI. Locally it runs only as a red plant.
9. `typst.lua:53-57`: merging and the one-page range test use physical pages, so a page counter reset prints `1, 1` or `1–1`.
10. `typst.lua:227`: minted labels skip Pandoc ids but not raw Typst labels an author wrote.
11. Stale: the `run-tests.sh:9504` comment names `html.lua` for the tree.

Triage at the gate (2026-09-13):

- Finding 1: fix now, as T10. The covered page is dropped.
- Finding 2: fix now, as T11.
- Finding 3: follow-up, as KI292 and a candidate row.
- Finding 4: fix now, as T9. The finding is a floor return, because AC5 is not met as written.
- Finding 5: fix now, as T8. The finding is a floor return, because AC8 fails as written.
- Finding 6: rejected, because KI291 already records the fold and its blind spot.
- Finding 7: rejected, because KI290 already records the caption case.
- Finding 8: fix now, as T12.
- Finding 9: follow-up, as KI293 and the same candidate row.
- Finding 10: rejected, because an author label spelled with the extension's `qi-mark-` prefix is very unlikely.
- Finding 11: fix now, as T12.
