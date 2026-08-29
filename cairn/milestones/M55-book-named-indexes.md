# M55: An HTML book builds every index its chapters declare

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** m055-book-named-indexes

## Goal

An HTML book prints every index its chapters declare, each at its own placement marker.

## Scope

Surface tier: **user-facing** — the deliverable is the index sections a book
author's rendered pages show.

**In:** the per-chapter record carries the index each mark files in and each
index's declared sort keys, at a bumped store version; `book.lua` aggregates,
places and reports per index; the HTML book stops folding, retiring
`marker.lua`'s `fold_slot` and the three fold reports with it; a stored record
naming an index the reading chapter does not declare is reported rather than
dropped; the book fixture gains a third declared index that no marker names;
the docs and changelog say what a book now does.

**Out:** pruning records for chapters no longer in the book, and the
declared-key map's unstable order → the book sidecar-store candidate row.
A per-chapter `indexes:` override → not planned; book metadata stays
book-wide. Pairing a range across two chapters → the range-pairing candidate
row, unchanged by this milestone.

## Acceptance criteria

- [ ] **AC1.** An HTML render of `examples/book/` prints one index section per
      declared index that some chapter's marks file in, and no other index
      section, read by the suite's whole-page `check_index_sections` over the
      rendered `last.html`; each section carries exactly the entries, levels,
      cross-reference forms and locator hrefs a new hand-derived manifest
      states for it.
- [ ] **AC2.** Each declared index that a marker names prints at that marker,
      and a declared index that no marker names prints after them, in declared
      order. Evidence: the index section ids read from `last.html` in document
      order against an expected order derived by hand from the markers in
      `examples/book/last.qmd` and the declaration order in
      `examples/book/_quarto.yml`, which after this milestone declares one
      index no marker names.
- [ ] **AC3.** A stored chapter record naming an index the reading chapter does
      not declare has its marks printed in the first declared index and draws a
      warning naming that chapter and that name — never dropped in silence — in
      each of three planted cases that vary the key's form as well as its
      story: a name no declaration in the book carries, a name a declaration
      removed, and a key the declaration syntax refuses.
- [ ] **AC4.** Each of the three judgements an HTML book makes across chapters
      — a cross-reference target no chapter indexes, a sort-key rivalry, and a
      range left unpaired — is made inside one index and its report names that
      index. Evidence: a book fixture that writes each judgement in the second
      declared index and its confusable twin in the first — a term the first
      index marks that the second index's cross-reference targets, a rival sort
      key for the same printed path across both, and a range opened in one and
      closed in the other — whose render draws each report naming its own index
      and draws none for the twins.
- [ ] **AC5.** A chapter record written at the superseded store version is
      refused, the existing per-chapter warning names that chapter, and the
      book still prints each declared index the remaining chapters' records
      file marks in.
- [ ] **AC6.** `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both
      exit 0, and each check this milestone adds has a planted defect, one per
      clause, shown red before its green is trusted.

## Coverage

- AC1 → T1, T2, T3, T5
- AC2 → T2, T3, T5
- AC3 → T4, T6
- AC4 → T2, T5, T6
- AC5 → T1, T6
- AC6 → T5, T6

## Tasks

- [x] **T1.** `book.lua`: the per-mark record carries the index it files in
      (`book.lua:137-139`), `sorts` becomes a per-index map
      (`book.lua:150-153`, today `qi_sortkeys.for_index(qi_indexes.default())`
      alone), `valid_record` shape-checks both, and `STORE_VERSION`
      (`book.lua:39`) bumps to 4.
- [x] **T2.** `book.lua` aggregates per index: `book_marks`, `book_sort_keys`,
      `book_sort_for`, `report_book_dangling` (`book.lua:481-514`, today one
      flat path set) and `report_book_ranges` (`book.lua:395-425`, today keyed
      by level path alone) are namespaced by index name, and `marker_chapter`
      (`book.lua:516-526`) resolves a placing chapter per index.
- [x] **T3.** `indexes.lua:199-200` stops setting `folded`; the three fold
      reports, `folds()`, the fold branches of `title`, `section_id` and
      `scope_phrase`, and `marker.lua`'s `fold_slot` (`marker.lua:293-303`,
      whose only caller is `marker.lua:308`) are deleted. The suite's
      fold-sentence pin (`tests/run-tests.sh:17141-17166`) and the fold-report
      zero-counts on the EPUB book go with them; the two
      `named-indexes-fold*.qmd` fixtures stay as LaTeX marker-placement probes.
- [x] **T4.** `html.lua:548-567`: a mark group whose key is no declared name is
      reported and printed in the first declared index rather than skipped.
- [x] **T5.** Fixtures and manifests: `examples/book/_quarto.yml` gains a third
      declared index no marker names, with one mark for it; `BOOK_HTML_INDEX`
      becomes section-aware and its derivation comment states, per layer, which
      chapter page and anchor each locator links to; `BOOK_EPUB_INDEX`, the
      book-PDF region bounds, `M49-AC3`'s declared list, `m21probes.py bookpdf`'s
      heading arguments, the letter sweep, `BOOK_WARNINGS`, `m29book.py`'s
      partition sets and the `book|…|1|` row at `tests/run-tests.sh:15671`
      follow; the AC4 judgement fixture is written.
- [x] **T6.** Hardening cases and self-test plants for AC3 and AC5, each
      reading `STORE_VERSION` from the artifact rather than writing it down,
      and each plant proven non-empty before its clause is trusted.
- [x] **T7.** Docs and changelog: the "One index in an HTML book" section of
      `site/named-indexes.qmd:82-88`, the opening paragraph of
      `site/books.qmd:7-9`, the retired sentences swept the way `M49_RETIRED`
      sweeps `git ls-files 'site/*.qmd'`, `check_readme_indexes`' pinned claim
      list, and the `CHANGELOG.md` Unreleased entry that today ends "An HTML
      book still builds a single index."

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: criteria audit ran in FULL mode (declared surface tier is user-facing) and returned seven findings. Five fixed before the gate: a fold-report-absence criterion dropped as unfailable once the code writing those reports is deleted; the cross-chapter-judgement fixture repaired to plant each judgement's twin in the first index, without which a per-index and a merged accumulator emit identical output; two criteria narrowed to indexes some mark files in; the named reader corrected to the whole-page `check_index_sections`, and its manifest-derivation-comment sentence moved to T5; the store-version criterion widened to every declared index and its plant told to read the version from the artifact. Two went to the gate.
- 2026-08-28: plan gate chose bumping the store record version over an optional index-name field with a default-index fallback, because a stale record then costs a chapter's terms loudly rather than filing its named marks in the wrong index silently; falsified by an author reporting the re-render cost as worse than a misfiled term.
- 2026-08-28: plan gate chose changing the rendered output outright over adding a setting that keeps one folded index, because a book declaring several indexes is already warned today that its named marks are being folded away; falsified by an author depending on the bare `qi-index` section id a book page prints today.
- 2026-08-28: plan gate chose adding a third declared index to `examples/book/` over dropping the promise about where an index no marker names is placed, because that promise is otherwise stated and never checked; falsified by the third index's manifest churn exceeding the coverage it buys.
- 2026-08-28: implementation began; T1 and T2 were committed together, since the record shape T1 writes is the shape only T2's readers can read, and T3 was taken with T5 for the same reason.
- 2026-08-28: implementation gate chose, for an index no marker names, the end of the last chapter that places one over the end of the book's last chapter, so no chapter whose author wrote no marker grows an index section; chose one stale-records warning per placing chapter over one for the book, each sentence then being exactly true and the common one-marker-chapter book still drawing one; and chose a committed `examples/book-scopes/` for the cross-chapter judgement fixture over one written into scratch at run time.
- 2026-08-28: T4 minor amendment — the undeclared-name report moved from `html.lua` to `book.lua`'s new `fold_undeclared`, which is the only site that knows which chapter the record came from, and which settles every name before any judgement is made about a mark; `html.lua` keeps the mechanical half, resolving a group key so no group is dropped in silence.
- 2026-08-28: the book's sort-key rivalry report moved from the placing chapter to the last chapter in book order, beside the other two book-wide reports: an index per marker means several placing chapters, and the rivalry is one fact about the book. `examples/book-order` now draws it on the first render as well as the second, which the suite asserts per render.
- 2026-08-28: T5's cross-chapter judgement fixture is `examples/book-scopes/`: two chapters, two declared indexes, each of the three judgements written in the second and its confusable twin in the first. Its render draws each report naming index "second" and none for a twin.
- 2026-08-28: T6 planted AC3's three cases (a name no declaration carries, a key the declaration syntax refuses, and — in a scratch copy whose declaration is deleted between renders — a name a declaration removed) and AC5's superseded-version case, which also reads the section ids off the page: refusing one.qmd's record leaves `people` with no marks and no section, while `main` and `places` still print. Two readers were added, `check_section_ids` and `check_section_carries`, and every clause of both plus the section manifest's five and AC4's four is planted and shown red under `--self-test`.
- 2026-08-28: T7 rewrote the "One index in an HTML book" section of `site/named-indexes.qmd` as "Every index in an HTML book", added the several-index and stale-name paragraphs to `site/books.qmd`, dropped `site/epub.qmd`'s "Nothing folds" contrast, and replaced the CHANGELOG's "An HTML book still builds a single index" with the entry for what a book now does. `M49_RETIRED` gained the two sentences the HTML book's fold left behind, and `check_readme_indexes` and the books-page claims gained rows for the new promises. `cairn/DESIGN.md` was corrected where it described the fold, and KI116 retired with `fold_slot`.
- 2026-08-28: recorded KI166: with the fold gone, a book chapter's own pairing reports name the index rather than the chapter, which D-021 requires and which drops the "a chapter is the pairing scope" fact from those two messages.
- 2026-08-28: plan gate chose one milestone over two in sequence, because the halfway state prints several indexes while still judging cross-chapter targets, sort keys and ranges across all of them at once, which D-021 forbids; falsified by the branch outgrowing one reviewable PR.

## Decisions

## Review
