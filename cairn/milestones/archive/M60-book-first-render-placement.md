# M60: An HTML book's first render places each index where its author asked

**Status:** done (2026-08-30, PR #60 https://github.com/jmgirard/quarto-index/pull/60)

**Goal:** An HTML book whose placement markers sit in different chapters prints no index section its
author did not ask for, and a malformed stored record no longer takes the render down.

**Outcome:** `store_write` records a `later` boolean — whether the store already held a usable record for
every chapter after this one — computed by new `later_recorded` before the write; `html_book`'s unplaced-index
adoption is gated on it, so no chapter adopts on a first render, and the book's last chapter reads the placing
chapter's `later` to draw a new deferral report naming each unplaced index some chapter marks (new `marks_in`).
`store_read` returns version-skewed chapters as a second value, reported by each chapter that builds an index, and
`valid_record`'s `mark.xrefs` type test moved ahead of the loop walking it. New `examples/book-placement/` — four
chapters, markers in the first and third, a marker-free fourth, `gamma` declared and unnamed — plus `check_book_sections`,
the two-position version-skew probe, and the sort-key merge-order regression M55 shipped without. Both documentation
pages and `CHANGELOG.md` state the first-render wait.

**Decisions:** the deferred section waits for a later render rather than always going to the book's final chapter,
which would reverse M55's rule; each chapter records what it saw of the store.

**Review:** three lenses; prior-review nothing, blame-history two non-defects, diff-bug eleven. All seven criteria
passed with fresh evidence, 498 checks plain and 948 with `--self-test`. Three fixed at the gate: an absent `later`
field read as `false`, drawing a deferral report for a section already on the page; a shadowed `later` name; and KI168,
struck as fixed when M55's review F4 is about `fold_undeclared`'s report, not the version-skew one — restored, wording
corrected. Four rejected, six deferred as KI198-KI203 behind a new row. No lesson retired.
