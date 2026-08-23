# M26: A document's accumulators start empty, whoever ran before it

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Branch/PR:** —

## Goal

Every module-level accumulator the filter's passes share is returned to its
initial value at the start of each document, and a render proves it.

## Scope

Surface tier: **user-facing** — the deliverable is the shipped extension's
filter, which every consumer of the repo runs.

**In:** The 17 mutable module-level cells — `marks.lua`'s ten (`marks_seen`,
`html_marks`, `marked_paths`, `pending_xrefs`, `clamped_paths`, `range_items`,
`range_found`, `range_pair_found`, `range_verdicts`, `range_at`),
`latex.lua`'s six (`contested_keys`, `principal_keys`, `principal_ordinals`,
`xref_list_emitted`, `xref_both_emitted`, `principal_emitted`) and
`sortkeys.lua`'s `sort_keys` — each returned to its initial value by a `reset`
its own module owns, wired as a leading `{ Pandoc = ... }` pass. The oracle is
a purpose-built fixture rendered twice off one tree, once behind a test-only
filter that first drives a synthetic document through the extension's pass
list. `html.lua`, `book.lua`, `marker.lua`, `passes.lua`, `levels.lua` and
`core.lua` hold no mutable state and are untouched.

**Out:**
- Moving the cells into a `state.lua`, or making each module a per-document
  factory — refused at the gate; M17 placed each cell in the module that owns
  it and both alternatives re-split that. Revisit only on a state a `reset`
  cannot restore.
- Any source scan pinning the cell count or the shape of a new accumulator —
  refused under D-011. The residual risk (a cell added after M26 joining no
  `reset`) → the `marks_seen` candidate row, which stays open.
- Restoring merge-base byte comparison as a refactor oracle → still refused by
  D-004; D-012 records why a same-tree pollution comparison is outside it.
- Establishing whether any toolchain path actually reuses a Lua state — none
  does today; this milestone is defensive and says so.

## Acceptance criteria

- [ ] AC1: `examples/state-reuse.qmd` rendered to PDF behind the test-only
      pollution filter produces a captured `.tex` byte-identical (`cmp -s`) to
      the captured `.tex` from the same fixture rendered without that filter,
      off the same tree.
- [ ] AC2: The same fixture rendered to HTML produces a captured page
      byte-identical (`cmp -s`) between the two renders, the emitted preamble
      and index section included.
- [ ] AC3: The AC1 comparison fails under each of four planted defects, one at
      a time and each reverted after: `marks.lua`'s `reset` removed,
      `latex.lua`'s removed, `sortkeys.lua`'s removed, and — varying form
      rather than location — `latex.lua`'s `reset` left in place but with
      `principal_ordinals` alone dropped from what it restores.
- [ ] AC4: Every one of the 17 cells is load-bearing in AC1: for each, its own
      removal from its module's `reset`, that cell alone and reverted after,
      fails the AC1 comparison — seventeen one-cell probes, reported per cell.
- [ ] AC5: `tests/run-tests.sh --self-test` exits 0 and prints its
      "All checks passed" line.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T6
- AC2 → T1, T2, T3, T4, T5, T6
- AC3 → T7
- AC4 → T7
- AC5 → T9

## Tasks

- [ ] T1: Probe the harness before building on it: a Lua filter that
      `require`s `./modules/passes` and walks a constructed `pandoc.Pandoc`
      value through `CollectSort`, `CollectKeys`, `CollectRanges`,
      `FinishRanges` and `Span`, confirming it runs under Quarto's Lua and
      that state survives into the real document. If it does not, stop and
      return to plan rather than reaching for a source scan.
- [ ] T2: Write `examples/state-reuse.qmd` — a fixture whose output consumes
      every accumulator: a declared `sort=`, a key contested between a locator
      mark and a cross-reference, a `mention="principal"` mark, a `see=`
      naming nothing indexed, a four-level `entry=` that the LaTeX fold
      clamps, and a paired `range=`.
- [ ] T3: Write the pollution filter as a test-only file under `tests/`,
      walking a synthetic document built to fill all 17 cells with values that
      would collide with the fixture's (same sort keys, same contested key,
      an earlier principal ordinal, an unclosed range).
- [ ] T4: Add the two paired renders and the `cmp` comparisons to
      `tests/run-tests.sh`, capturing each render's artifacts per M24's rule.
      Both comparisons must DIFFER at this point — record that failing state
      as the tests-first evidence before T5.
- [ ] T5: Give `marks.lua`, `latex.lua` and `sortkeys.lua` a `reset` each,
      exported like their other entry points, restoring every cell that module
      owns to the value its declaration gives.
- [ ] T6: Wire the resets: `index.lua`'s returned pass list gains a leading
      `{ Pandoc = ... }` table, which Pandoc runs before any element function
      because that table has none. Confirm both comparisons now pass.
- [ ] T7: The planted-defect run — AC3's four probes, then AC4's seventeen
      one-cell probes. Record each cell's verdict in the Decisions section.
- [ ] T8: Rewrite DESIGN.md's Architecture paragraph at :169-176, which says
      the accumulators are "still module-level" and not per-document; add the
      convention that a new accumulator joins its module's `reset`.
- [ ] T9: Full `tests/run-tests.sh --self-test`; capture evidence per
      criterion.

## Work log

- 2026-08-23: created by /milestone-plan, promoting the `marks_seen` module-level-state candidate row (M01 review R16, widened through M23).
- 2026-08-23: plan gate ran the FULL criteria audit (user-facing tier) and it returned two findings. Fixed in drafting: the planted-defect criterion varied location only (which module's reset is removed), so AC3 gained a form axis — a reset left in place with one cell dropped from it. Taken to the gate: whether D-004 bars the byte comparison AC1 and AC2 rest on. The audit ran in-context rather than as a fresh-context [O] reader, this session being instructed not to spawn agents — so the reader that authored the criteria also audited them, which is the weaker arrangement.
- 2026-08-23: plan gate chose a per-module `reset` over moving the 17 cells into one `state.lua` and over making each module a per-document factory, because M17 deliberately placed each cell in the module that owns it and both alternatives re-split that at every call site; falsified by a cell whose correctness needs construction rather than restoration — `range_at` is the near miss, already needing a mid-document reset.
- 2026-08-23: plan gate chose a same-tree pollution-versus-clean byte comparison over extracting and comparing only the `\index` arguments and the HTML index section, because a leak reaching the preamble (`principal_emitted`) or the `.aux` registry (`principal_ordinals`) escapes the extraction entirely; falsified by the comparison proving brittle to something neither render's state differs in.
- 2026-08-23: plan gate chose shipping the fix over holding the row and over a reachability-probe-only milestone, because Quarto runs one process per document so no probe would find a path, while DESIGN.md:169-176 records M17 having weakened the guarantee and one cell's value reaches an on-disk artifact; falsified by the harness of T1 proving unbuildable, which returns this to plan.

## Decisions

## Review
