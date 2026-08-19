# M12: A marker that leaves nothing behind is reported without naming what held it

**Status:** done (2026-08-19, PR #12 https://github.com/jmgirard/quarto-index/pull/12)

**Goal:** An author whose nested placement marker was the only thing where it stood is
told so, in a message naming no element the extension cannot honestly name.

**Outcome:** `empties` returns (M08's verified rule, unchanged) beside a new
`emptied_places`, counting every emptying block list under a top-level block minus
every one a marker owns — a marker is removed whole at every depth and is never a
place anyone can find emptied. `strip_nested_markers` takes the top-level position
and emits one report per emptied place. Naming is gone — no `CONTAINER_NAMES`, no
per-kind dispatch — so a table cell, a footnote body and a definition are block lists
like any other; all three were emptied unreported before. `marker-shapes.qmd` gained a
manifest, eleven emptying shapes and five silent ones; the harness partitions every
warning line each render emits against it.

**Decisions:** Milestone-local — the report names no container, and claims the
marker's own place, not the container's emptiness: a callout still renders its title.

**Review:** Three lenses, twelve findings, none meeting the return floor; the Opus
lens failed to break the subtraction on five shapes outside the fixture. Seven fixed
at the gate: the check partitions all warnings rather than searching for the template,
two emptied places under one block are pinned, the message is one literal again, three
false sentences went, and M08 R3 (definition lists) closed. Five rows, three rejected.
