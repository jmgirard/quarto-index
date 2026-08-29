# M55: An HTML book builds every index its chapters declare

**Status:** done (2026-08-28, PR #55 https://github.com/jmgirard/quarto-index/pull/55)

**Goal:** An HTML book prints every index its chapters declare, each at its own placement marker.

**Outcome:** The per-chapter sidecar record carries the index each mark files in and that index's sort keys, at
`STORE_VERSION` 4. `book.lua` aggregates per index — `book_marks`, `book_sort_keys`, `book_sort_for`,
`report_book_dangling`, `report_book_ranges` namespaced by index name, `marker_chapter` resolving a placing chapter
per index. Each index prints at the first marker naming it; an index no marker names prints after them in declared
order, at the end of the last chapter that places one. New `fold_undeclared` files a record naming an undeclared
index into the first declared one and names the chapter and the name (IP2). The HTML book stops folding: `fold_slot`,
`folds()`, the three fold reports and the fold branches of `title`, `section_id` and `scope_phrase` are deleted. `examples/book/` declares a third index no marker names,
`examples/book-scopes/` is the cross-chapter judgement fixture, and `check_section_ids` and `check_section_carries`
are new readers.

**Decisions:** an index no marker names goes to the last chapter that places one, not the book's last chapter; one
stale-records warning per placing chapter; the sort-key rivalry report moved to the last chapter in book order.

**Review:** three fresh-context reviewers; blame-history and prior-review returned nothing. The diff-bug lens returned
nine findings, none failing a criterion. Four fixed on the branch: the sort-key merge order (a stale index name could
beat the destination's own key), a duplicated clause in DESIGN.md, four comments describing the deleted fold, and a
docs sentence promising a section for an index no mark files in. Three deferred as KI167-KI169 with a candidate row,
two rejected as KI166 and KI170; KI171 records the merge-order fix shipping with no regression test. Check-design
gained a nineteenth shape. No lesson retired.
