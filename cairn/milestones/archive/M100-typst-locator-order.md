# M100: A Typst index orders locators by the number the page prints

**Status:** done (2026-09-14, PR #100 https://github.com/jmgirard/quarto-index/pull/100)

**Goal:** A Typst index orders an entry's locators, and decides which pages a
range spans, by the number each page prints, as makeindex does for the PDF index.

**Outcome:** `qi-index-rank` gives each locator a class (makeindex's order,
no numbering counted arabic) and a value (the page counter, or the physical
page). `qi-index-entry` sorts by class, value, opening and closing page, a
single mark first. A range spans values within one class, ends included, and
a one-text range is a single mark. Merged locators print at the first place,
linked to the earliest page. New: `examples/typst-order.qmd`,
`examples/book-typst-reset/`, their manifests, a versions.yml read.

**Decisions:** the plan gate chose a span by printed value over M099's
physical pages. It also chose makeindex's class order, a new fixture and the
book fixture. The fixture avoids an `α` pattern and `fi` for the floor leg.

**Review:** two rounds, three lenses each. Round 1 returned on AC6 (docs),
and T9-T11 fixed it with F1 and F7. Round 2 fixed doc wording F2-F4 at the
gate, filed F1 (first counting symbol untested) as a candidate row, and
rejected F5-F6. Suite 1669 and matrix 34882305528 green. The M30 lesson now
names the `fi` ligature.
