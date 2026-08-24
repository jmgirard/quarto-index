# M28: A reported block position names the sequence it counts

**Status:** done (2026-08-24, PR #28 https://github.com/jmgirard/quarto-index/pull/28)

**Goal:** An author reading a placement-marker report is told what the number in
it counts, and the named report and comment sites stop calling that number the
author's own source position.

**Outcome:** `POSITION_BASIS` — one shared string in `marker.lua` — is spliced
into the emptied-place and duplicate-marker reports, so the two cannot drift;
the duplicate report's first number reads "marker N in document order" and its
clause covers both. `book.lua`'s chapter count is named over the files the book
renders, in render-list order. The `resolve_markers` and `marker-shapes.qmd`
manifest comments say a position is counted over the blocks the filter is
handed, never the author's. Fixture `examples/marker-position.qmd` holds a
marker after an `{{< include >}}` — written at block 3, reported at block 5;
`tests/m28pos.py` reads both numbers off its manifest, backed by four
discrimination plants. The key-distinctness scan holds 16 keys, was 15.

**Decisions:** D-014 (annotates D-006). KI21 narrowed to the un-probed injection kinds; KI25 struck.

**Review:** Three-lens fan-out; blame-history and prior-review record found nothing, diff-bug found thirteen. Seven fixed at the gate (the scan's missing key, two vacuity guards, three stale `DESIGN.md` claims, a capture-slug collision); three filed as KI80/KI81/KI82, the suite-hardening row extended; three rejected (chapter-local position is KI22/M29; AC2's cross-product reading is unsatisfiable, not its plain one; the fixture's author position is its container's). Nothing met the return floor.
