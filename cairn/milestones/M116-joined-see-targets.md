# M116: One see-word for each kind of cross-reference

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the text each back-end prints for an index entry's cross-references
- **Branch/PR:** m116-joined-see-targets

## Goal

An index term with two or more cross-reference targets of one kind prints that kind's word once, in front of all its targets of that kind, in the LaTeX, HTML, EPUB and Typst indexes.

## Scope

**In:** the joins that print an entry's cross-references: `fold_xrefs`
(`_extensions/index/modules/latex.lua:371`), `entry_inlines`
(`_extensions/index/modules/html.lua:135`, which also serves EPUB) and
`entry_lines` (`_extensions/index/modules/typst.lua:186`), or a shared
grouping in `build_entry_tree` (`_extensions/index/modules/entries.lua:137`).
Targets group by kind, `see` before `see also`, and keep the document order of
their first marks inside a kind. A new fixture `examples/xref-joined.qmd` with
hand-derived manifests, a same-kind pair across two chapters of a book fixture,
suite sections in `tests/run-tests.sh`, and the existing rows the joined form
changes (`upsilon` in `examples/xref-conflict.qmd`, `eta` in
`examples/html-index.qmd`, whose two `see` targets differ and print alike). Docs:
`site/cross-references.qmd`, `site/back-end-differences.qmd` where it describes
the join, `CHANGELOG.md`, and `cairn/DESIGN.md`'s KI9 narrowed to its locator
half.

**Out:** sorting targets alphabetically inside a kind: no candidate row, as
nothing asks for it. The locators a see-also entry keeps (KI9's other half),
which M03's gate chose and which stays a known issue. The LaTeX order that puts
a contested entry's cross-references before its page numbers, and the
`site/cross-references.qmd` sentences on `index-labels:` reach: both stand
unless the T5 read finds them false on the page it edits. The version matrix in
`.github/workflows/versions.yml`: the parked row "Floor-Quarto CI suite job"
holds a floor run of the whole suite.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh` renders `examples/xref-joined.qmd` to PDF and reads its printed index from the PDF's text against a hand-derived manifest. The fixture holds four subject terms and marks every target as an entry of its own. One term's two marks name two different `see` targets, one term's two marks name two different `see-also` targets, one term's four marks name `see-also` Moss, `see` Zed, `see-also` Fern and `see` Ash in that document order, and one term has a plain mark beside two marks naming two different `see` targets. Inside each kind, document order is the reverse of alphabetical order. Each term prints the word of a kind once, followed by that kind's targets joined by `; ` in the document order of their first marks, with the `see` targets before `see also` and its targets: the four-mark term prints `see Zed; Ash; see also Moss; Fern`. In the same suite run, `examples/xref-conflict.qmd`'s PDF index prints `upsilon, see One Way; Another Way`.
- [ ] AC2: The LaTeX render of `examples/xref-joined.qmd` draws exactly one contested-key warning naming each of its four subject terms, and none of those warnings states a number of cross-references, or says "both" or "a cross-reference", that differs from the number of different cross-references that term's marks carry.
- [ ] AC3: The suite renders `examples/xref-joined.qmd` to HTML and to EPUB and reads each index section: each of the four subject terms prints the word of a kind once, in front of that kind's targets, with `see` targets before `see also` targets, also for the term whose first mark is a `see-also`, and each target in its own `qi-xref` span with its own link. Targets of one kind are separated by `;` in the default render, and by the set value in an HTML render and an EPUB render of the fixture that set `xref-separator` under `index-labels:`. `examples/html-index.qmd`'s HTML `eta` prints `see` once, followed by `A: B; A: B`, the first linked and the second not.
- [ ] AC4: In the suite's HTML render of a book fixture in which one term has a `see` target in each of two chapters, named so that book order is the reverse of alphabetical order, the book index prints `see` once, with the earlier chapter's target first.
- [ ] AC5: The suite renders `examples/xref-joined.qmd` to Typst and reads its index with `tests/typstindex.py` against a hand-derived manifest: each of the four subject terms prints the word of a kind once, followed by that kind's targets joined by `; `, with `see` targets before `see also` targets and inside a kind in the document order of their first marks. Page numbers stay before the cross-references, as they print today.
- [ ] AC6: These cases print what the suite's rows for them state at the milestone's base commit, and the milestone's diff edits none of those rows: a single target, two identical targets (`mu`, `zeta`), one target of each kind from one mark or from two (`both`, `lambda`, `phi`, `Dolomite`), and the folded targets of `examples/fold-xref.qmd` and `examples/fold-xref-both.qmd`.
- [ ] AC7: The active profile's `verify` slot is clean: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` pass.
- [ ] AC8: `site/cross-references.qmd` shows the joined form for two targets of one kind, and a sentence in `CHANGELOG.md`'s Unreleased Output section says that such a term prints the word once, in all four indexes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T1, T3
- AC5 → T1, T4
- AC6 → T2, T3, T4, T6
- AC7 → T6
- AC8 → T5

## Tasks

- [x] T1: Write `examples/xref-joined.qmd` with the terms of AC1, one subject term per page so each page number is known, every target marked as an entry, and its manifests for the PDF, HTML, EPUB and Typst readers, each row derived from the typesetting fact and not from a render. Add the `xref-separator` render AC3 names, by a twin document or by metadata. Add the cross-chapter `see` pair to a book fixture whose other rows it leaves alone, or to a new small book. Add the suite sections and change the `upsilon` and `eta` rows (`tests/run-tests.sh:15057`, `:2779`, `:2842`). See each new row red on today's code, each failure named.
- [x] T2: LaTeX: in `fold_xrefs`, put a kind's targets inside one `\see{...}{}` or `\seealso{...}{}` joined by `; `, which covers the contested key with a plain mark (printed text) and without one (`quartoindexxrefs`). Leave `mark_encap` and the `quartoindexseeboth` definition alone. Reword the two contested-key warnings (`_extensions/index/index.lua:315`, `:320`) so their count holds for the fixture's terms, pin each whole in the suite, and re-read every comment and message that names the target list (`core.lua:57-67`, `latex.lua`). Update the exact pins this changes and say which in the work log.
- [x] T3: HTML and EPUB: group the targets by kind before the line is built, and write the kind's `Emph` word only in the first `qi-xref` span of each kind, with `xref-separator` between targets. The HTML book path reaches the same builder through `book_marks` (`book.lua:1349`); check that the chapter order holds there. `tests/htmlindex.py` raises on a `qi-xref` span without one word (`htmlindex.py:728-732`): accept a word-less span only after a span of the same kind, and assert one word on each kind's first span. Make the rows for the new terms read the word, which `row()` skips unless `labels` is on.
- [x] T4: Typst: one item per kind in `entry_lines`, the kind's word once and its targets joined by `; `; the `typstindex.py` manifest row then reads `see|Zed; Ash; see also|Moss; Fern`. If the new fixture joins the `tests/typstcheck.py source` sweep, which derives one reference per target (`typstcheck.py:319-322`), derive one reference per kind with its targets joined by `; `; otherwise leave it out.
- [x] T5: Docs: the joined form and its example in `site/cross-references.qmd`, `site/back-end-differences.qmd` where it describes the join, the `CHANGELOG.md` sentence, the gallery page for `xref-conflict` if it states `upsilon`'s output, and KI9 in `cairn/DESIGN.md` narrowed to its locator half.
- [ ] T6: Run `tests/run-tests.sh`, then `--self-test`, never two at once and with no edit to the script during a run. Revert each back-end's join in turn and see its AC row red at a named manifest row before restoring it. Plant an alphabetical sort of the targets inside a kind, and a first-mark-kind-first grouping, in each back-end, and see AC1, AC3, AC4 and AC5 rows red on each before restoring.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to work on — "Join see targets", over the parked rows "Laid-out float caption marks" and "Principal marks through nameref". The set ran as this one question before investigation, so the plan decided the rest; each choice is logged below.
- 2026-10-19: collision check: KI9 (DESIGN.md) is the source, its see-word half taken here and its locator half left; no candidate row, planned milestone or D-entry overlaps (D-005, D-035, D-036 read: target folding and label words, unchanged here); archived M02, M03 and M15 shipped the cross-reference and contested-key machinery this extends. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-19: Explore fan-out (Haiku) mapped the joins: all three back-ends print one word per target (latex.lua:371-382, html.lua:172-181, typst.lua:186-193); LaTeX groups targets by kind and HTML and Typst keep arrival order; `upsilon` is the only distinct same-kind case among the fixtures.
- 2026-10-19: plan chose document order inside a kind over alphabetical order (the printed-index convention) because document order is what LaTeX prints today and what an author controls by writing order, and alphabetical order would need a sort rule for multi-level targets; falsified by an author or reference asking for sorted targets.
- 2026-10-19: plan chose one `qi-xref` span per target, the word in the first span of each kind, over one span per kind, because `site/html.qmd:142` documents the span as one cross-reference, a styling hook authors may target; falsified by an author asking to style a kind's group as one element.
- 2026-10-19: plan took the contested-key warning's "two different cross-references" for a three-mark term into scope (AC2), since the new fixture reaches it and LESSONS M38 says to re-read a message whose set a change widens.
- 2026-10-19: lessons harvested: M38 (re-read messages naming the set), M073 (no edit to `tests/run-tests.sh` mid-run), check-design M10 and M11 (quantify over every entry, keep untouched shapes in the fixture), M30 (fill an expected extraction from the typesetting fact).
- 2026-10-19: criteria audit (full mode, fresh Opus reader) returned 11 findings, all fixed: targets named against alphabetical order (AC1, AC4) and the order plants in T6; a term whose first mark is a `see-also` (AC1, AC3); AC2 rewritten to bound both contested-key warnings' counts; the `htmlindex.py` word-less span (T3); the `xref-separator` render given a task (T1); every target marked as an entry (AC1); `eta`'s new output stated (AC3); Typst page-number position stated (AC5); T4 aimed at `typstcheck.py source`'s per-target derivation; AC6 bound to the base commit's rows. Its finding that suite-green is an instrument promise was answered by keeping it as AC7, the template's verify-slot criterion, split from AC6.
- 2026-10-19: eight criteria, one over the split tripwire's seven; kept as one milestone because AC7 is the template's verify gate and the four back-ends share one fixture and one change.
- 2026-10-19: implement started on branch m116-joined-see-targets.
- 2026-10-19: T1: fixture `examples/xref-joined.qmd` and twin `examples/xref-joined-separator.qmd` share `examples/_xref-joined-body.qmd` (terms Quince, Rowan, Sorrel, Tansy; the twin is checked by `derive_labels_twin`); new book `examples/book-xref/` (Hazel: Yew in chapter 1, Alder in chapter 2); suite section M116 before M075 with PDF, HTML, EPUB, separator, book and Typst rows and a self-test; `upsilon` PDF row now `see One Way; Another Way`. Implementation choice: the PDF check joins a line read below the top level to the line above, since the fixture writes no sub-entry and the two-column index wraps long lines. Red on today's code, checked in scratch: the PDF check fails on Quince, Rowan, Sorrel and Tansy printing the word once per target, and today's Typst rows read `see|Zinnia; see|Aster`. The `eta` HTML row with labels off is unchanged in text.
- 2026-10-19: T2: `fold_xrefs` writes one `\see{...}{}`/`\seealso{...}{}` per kind, its targets joined by `; `; the scratch PDF of `examples/xref-joined.qmd` matches all 14 manifest lines. The contested-key report counts the entry's distinct targets: new wordings for a plain mark beside two or more (`carries a plain locator and N different cross-references`) and for three or more with none (`carries N different cross-references ... carrying all N targets`); the two old wordings keep their counts. Pins changed: `xref-conflict` `phi` now draws the plural plain report (WARN_CLASH_PLAIN 6 to 5, new WARN_CLASH_PLAIN_MANY 1, M15-AC5 shape `plain-two`); `fold-xref` and `fold-xref-both` emissions are unchanged (one target per kind, and the uncontested `quartoindexseeboth`).
- 2026-10-19: T3: implementation choice: the grouping lives in `build_entry_tree` (`entries.lua`), which inserts a target after the last one whose kind ranks at or before its own, so HTML, EPUB, the HTML book and Typst share it; `entry_inlines` writes the word in the first `qi-xref` span of each kind only. `tests/htmlindex.py` now requires one word on a kind's first span and none on a later one, and `row()` states no word for a word-less span. Scratch renders: HTML and EPUB rows, EPUB links, and the separator checks (`;` and U+061B, HTML and EPUB) all match; `eta` reads `see-link see A: B`, `see-plain A: B`; the book prints `see Yew` then `Alder`; both reader plants are refused. Correction: the book rows first said each target is `qi-mark-2`, counting Hazel's mark; a cross-reference mark mints no anchor (`passes.lua:654`), so the rows now read `#qi-mark-1` and `index.html#qi-mark-1`.
- 2026-10-19: T4: implementation choice: `entry_lines` keeps one item per target and writes the kind's word in the first item of each kind only, so `qi-index-entry`'s fixed `; ` join prints `see A; B` with the helper unchanged (the task named one item per kind; the printed line is the same). `tests/typstindex.py`'s `printed_text` reads a reference piece without a word as a bare target after the semicolon. Scratch Typst render: the face-and-link reading and the page reading both match all 26 rows. The new fixture is not in the `typstcheck.py source` sweep, which T4 leaves as it is.
- 2026-10-19: T5: `site/cross-references.qmd` gains the joined-form paragraph and example; the T5 read found two of its sentences false on the page and corrected them, as Scope allows: the order "this extension cannot produce yet" (`cats, 12, 47, see also Felines`), which the Typst, HTML and EPUB indexes do print, and "This reaches the HTML and EPUB indexes only", where the Typst index reads the three word keys (as `site/back-end-differences.qmd` item 9 says). `site/back-end-differences.qmd` and the gallery page state nothing the change makes false and are unchanged. CHANGELOG Unreleased Output entry added; KI9 narrowed to its locator half. The simple-english hook reports 207 hits over the whole CHANGELOG, all in older entries; the new entry adds none.
- 2026-10-19: T6 plants, each in a scratch copy of the extension and fixture, read with the suite's M116 checks: an alphabetical sort inside a kind (entries.lua and fold_xrefs) is red in PDF (line 7, Quince `see Zinnia; Aster` expected), HTML (Quince `see Aster` first), Typst (`see|Aster; Zinnia`) and the book (Hazel `see Alder` first); the first mark's kind first is red in PDF, HTML and Typst at Sorrel (`see also Moss; Fern; see Zed; Ash`); the old word per target is red in PDF (line 7), at the HTML reader's parse (a later same-kind target with a word), and in Typst at the parse of Sorrel's wrapped line.
- 2026-10-19: suite run 1 stopped at `warn-distinct.py`'s pinned message count (86, now 90 with the four new wordings; updated with its derivation). Run 2 stopped at the PyYAML check: this shell's first `python3` is `/usr/local/bin/python3` 3.14 with no PyYAML, where `/usr/bin/python3` 3.9 has it; run 3 puts a scratch `python3` link to `/usr/bin/python3` first on PATH and changes nothing else.
- 2026-10-19: run 3 stopped at M14's corpus roster: the shared body file `examples/_xref-joined-body.qmd` carried the targets and would render alone with no filter, so the two fixtures now carry the body themselves (the twin check holds them equal) and the file is gone; rows added for both fixtures and both `book-xref` chapters (each 0; `book-xref/index.qmd`'s mark moved onto one line so the roster sees it), and the M116 section holds `book-xref.log` to no warning. Run 4 stopped at M41-AC1: `site/gallery.yml` now lists both fixtures under `not-shown:`. Run 5 stopped when Quarto itself crashed (`Segmentation fault: 11` in its Deno runtime) during M065-AC5's store-directory render, a check runs 3 and 4 passed; run 6 started.
- 2026-10-19: run 6 passed every M116 check and stopped at M075-AC2, whose section heading must be its banner's first line; renamed. Run 7 (plain): "All checks passed (919 checks)". Self-test run 1 stopped on a second Quarto crash (`Segmentation fault: 11`, M062-AC2's no-marker book render); self-test run 2 started.
- 2026-10-19: self-test run 2: "All checks passed (1824 checks)", the M116 self-test among them.
- 2026-10-19: claim audit: 58 claims read, 7 corrected — examples/xref-joined.qmd, examples/xref-joined-separator.qmd, tests/run-tests.sh, site/cross-references.qmd, _extensions/index/modules/html.lua (the twin sentence named the separator file as its own twin; "Five books carry targets" missed `book-placement`, whose attributes open a line the roster grep does not match; "no warning at all" is "no warning from this extension"; the PDF join and its self-test claimed a wrap no line of this index has; "the same holds in every back-end" read as links in every back-end; the html.lua comment sent same-kind targets through the dual-target command; S3 is the comma after the locators, not the term's).

## Decisions

## Review
