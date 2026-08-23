# M26: A document's accumulators start empty, whoever ran before it

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Branch/PR:** `m26-per-document-state`

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
three purpose-built fixtures, each rendered twice off one tree, once behind a
test-only filter that first drives a synthetic document through the
extension's pass list: a rich fixture reaching the fourteen value-carrying
cells, a one-mark fixture for `principal_emitted` and a mark-free one for
`marks_seen` — two cells a leak moves only in a document that does not set
them itself. Each render's warning stream is captured and compared alongside
its output, five cells being read by nothing but a report. `html.lua`,
`book.lua`, `marker.lua`, `passes.lua`, `levels.lua` and `core.lua` hold no
mutable state and are untouched.

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

- [ ] AC1: Each of `examples/state-reuse.qmd`, `examples/state-reuse-plain.qmd`
      and `examples/state-reuse-empty.qmd`, rendered to PDF behind the
      test-only pollution filter, produces a captured `.tex` byte-identical
      (`cmp -s`) to the captured `.tex` from the same fixture rendered without
      that filter off the same tree, and a captured warning stream
      byte-identical to that render's.
- [ ] AC2: The same three fixtures rendered to HTML each produce a captured
      page byte-identical (`cmp -s`) between the two renders, the emitted
      preamble and index section included, and a captured warning stream
      byte-identical between them.
- [ ] AC3: The AC1 comparison fails, for at least one of the three fixtures,
      under each of four planted defects, one at a time and each reverted
      after: `marks.lua`'s `reset` removed, `latex.lua`'s removed,
      `sortkeys.lua`'s removed, and — varying form rather than location —
      `latex.lua`'s `reset` left in place but with `principal_ordinals` alone
      dropped from what it restores.
- [ ] AC4: Sixteen of the 17 cells are load-bearing: for each, its own removal
      from its module's `reset`, that cell alone and reverted after, fails the
      AC1 or the AC2 comparison for at least one of the three fixtures —
      sixteen one-cell probes, reported per cell with the fixture, format and
      artifact (`.tex`, HTML page or warning stream) that moved. The
      seventeenth, `range_pair_found`, is exempt and stays in the `reset`:
      `finish_ranges` assigns it wholesale on every document, so no earlier
      document's value can survive into it; its probe is run and its passing
      every comparison recorded as that.
- [ ] AC5: `tests/run-tests.sh --self-test` exits 0 and prints its
      "All checks passed" line.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T6
- AC2 → T1, T2, T3, T4, T5, T6
- AC3 → T7
- AC4 → T7
- AC5 → T9

## Tasks

- [x] T1: Probe the harness before building on it: a Lua filter that
      `require`s `./modules/passes` and walks a constructed `pandoc.Pandoc`
      value through `CollectSort`, `CollectKeys`, `CollectRanges`,
      `FinishRanges` and `Span`, confirming it runs under Quarto's Lua and
      that state survives into the real document. If it does not, stop and
      return to plan rather than reaching for a source scan.
- [x] T2: Write the three fixtures. `examples/state-reuse.qmd` — output
      consuming every value-carrying accumulator: a declared `sort=`, a key
      contested between a locator mark and a cross-reference, a
      `mention="principal"` mark, a `see=` naming nothing indexed, a
      four-level `entry=` that the LaTeX fold clamps, a paired `range=`, and a
      `range=` value the filter refuses, which leaves a document position
      nothing is planned at. `examples/state-reuse-plain.qmd` — one ordinary
      mark and nothing else. `examples/state-reuse-empty.qmd` — an index
      placement marker and no marks at all.
- [x] T3: Write the pollution filter as a test-only file under `tests/`,
      walking a synthetic document built to fill all 17 cells with values that
      would collide with the fixtures' (same sort keys, same contested key,
      an earlier principal ordinal, an unclosed range), silencing the
      extension's own `warn` for the length of that drive so the compared
      stream holds the fixture's warnings alone. It pollutes only when its
      environment switch is set, so one fixture source serves both renders.
- [x] T4: Add the six paired renders and the `cmp` comparisons to
      `tests/run-tests.sh`, capturing each render's artifacts and its warning
      stream per M24's rule. Every comparison must DIFFER at this point —
      record that failing state as the tests-first evidence before T5.
- [x] T5: Give `marks.lua`, `latex.lua` and `sortkeys.lua` a `reset` each,
      exported like their other entry points, restoring every cell that module
      owns to the value its declaration gives.
- [x] T6: Wire the resets: `index.lua`'s returned pass list gains a leading
      `{ Pandoc = ... }` table, which Pandoc runs before any element function
      because that table has none. Confirm both comparisons now pass.
- [x] T7: The planted-defect run — AC3's four probes, then AC4's seventeen
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
- 2026-08-23: T1 — the harness holds. A test-only filter listed AFTER `index` finds all nine extension modules in `package.loaded` at its own chunk-load time, which Quarto runs before any pass executes, so a value written there reaches the fixture's own marks: the same fixture emitted `\index{ZZZ@synthetic|quartoindexlocator{qi1}` polluted against `\index{synthetic}` clean. A synthetic `pandoc.Pandoc` drives through CollectSort, CollectKeys, CollectRanges/FinishRanges and Span without error. `require` from `tests/` was the wrong door and is not used: its cache key differs from the extension's absolute one, so it returns a SECOND copy of each module. The first reading of that probe as a success was a stale `.tex` left by an earlier render, found by removing the artifact and checking the exit code.
- 2026-08-23: T7 — `tests/stateprobe.py` runs the AC3 and AC4 probes; all four AC3 probes and all sixteen non-exempt cells move a comparison, `range_pair_found` moves none as its exemption predicts, and the per-cell verdicts are in the Decisions section. The driver is committed rather than run out of band so a fresh review session can reproduce it. Suite after the run: 275 checks, all passing.
- 2026-08-23: T5/T6 — `marks.lua`, `latex.lua` and `sortkeys.lua` each own a `reset`, called by a new `passes.Reset` that `index.lua` returns as the pass list's leading `{ Pandoc = ... }`. Tables are emptied in place through a new `qi_core.empty`, because every accumulator is exported by reference and a rebound local would restore this module's view alone. Suite: 275 checks, all passing, all twelve M26 comparisons among them.
- 2026-08-23: T2/T3/T4 — the three fixtures, `tests/state-pollute.lua` and the six paired renders are in the suite, and the suite now FAILS as it must before the fix: `run-tests.sh` reaches M26's first comparison after 255 passing checks and reports `the latex output of state-reuse depends on what ran before it in the same Lua state`. Out of band, all six comparisons differ (output and warnings, three fixtures x two formats); the leaks the rich fixture's `.tex` shows are `Held` contested, `Deep` filed under `dsort`, `Pivot` at ordinal qi2 rather than qi1, and the paired range emitted as two plain locators. `examples/state-reuse.qmd` joined M14's dangling-count manifest (one report) and the rich fixture's two LaTeX captures joined M15's contested-key map.
- 2026-08-23: the first draft of the M26 comparison printed its diff through `diff | head`, whose non-zero exit under `set -e` killed the run before its own FAIL line — found by there being no FAIL line in the log. Both failure branches now absorb the diff's exit.
- 2026-08-23: amendment (Substantive, user delegated the choice at the implement gate): AC1 and AC2 now compare each render's captured warning stream as well as its captured output, AC3 reads over the fixture set, AC4 binds sixteen cells and names `range_pair_found` exempt, Scope names three fixtures, and T2/T3/T4 follow. Cause: reading the cells' consumers showed `marked_paths`, `pending_xrefs`, `clamped_paths` and `range_found` are read by nothing but a `warn()`; `html_marks` only by the HTML path; `range_pair_found` is assigned wholesale by `finish_ranges` on every document; and a leaked `principal_emitted` or `marks_seen` moves nothing in a fixture that sets it itself.
- 2026-08-23: amendment criteria audit ran the FULL mode (user-facing tier) over the amended AC1-AC4 and returned one finding: the warning-stream comparison is unsatisfiable while the pollution drive itself warns, fixed in T3 by silencing `warn` for that drive rather than in the criterion. Run in-context rather than by a fresh-context [O] reader, this session being instructed not to spawn agents — the same weaker arrangement the plan gate's audit recorded.
- 2026-08-23: implement gate chose one fixture source with an environment switch on the pollution filter over sibling copies and over Quarto profiles, because two copies must be kept identical by hand and a later edit to one silently weakens the proof; falsified by an environment the harness cannot pass a variable through.
- 2026-08-23: plan gate chose shipping the fix over holding the row and over a reachability-probe-only milestone, because Quarto runs one process per document so no probe would find a path, while DESIGN.md:169-176 records M17 having weakened the guarantee and one cell's value reaches an on-disk artifact; falsified by the harness of T1 proving unbuildable, which returns this to plan.

## Decisions

### 2026-08-23: what each probe moved (T7, AC3 and AC4)

`python3 tests/stateprobe.py` removes one reset, or one cell from one reset,
and requires the paired-render comparison to fail. It stops at the first
fixture and format that moves, and the unplanted tree is required to pass all
six pairs first. Run at commit-time on this branch; every probe below is one
line of that run.

The four AC3 probes, three varying location and the fourth varying form:
`marks.lua`'s whole reset, `latex.lua`'s and `sortkeys.lua`'s each move the
rich fixture's LaTeX output, and so does `latex.lua`'s reset left in place with
`principal_ordinals` alone dropped from it.

The seventeen AC4 probes, cell by cell, naming the fixture, format and artifact
that moved:

| Cell | Moved |
|---|---|
| `marks_seen` | state-reuse-empty / latex / output |
| `html_marks` | state-reuse / html / output |
| `marked_paths` | state-reuse / latex / warnings |
| `pending_xrefs` | state-reuse / latex / warnings |
| `clamped_paths` | state-reuse / latex / warnings |
| `range_items` | state-reuse / latex / output |
| `range_found` | state-reuse / latex / warnings |
| `range_pair_found` | nothing — exempt, see below |
| `range_verdicts` | state-reuse / latex / output |
| `range_at` | state-reuse / latex / output |
| `contested_keys` | state-reuse / latex / output |
| `principal_keys` | state-reuse / latex / output |
| `principal_ordinals` | state-reuse / latex / output |
| `xref_list_emitted` | state-reuse / latex / output |
| `xref_both_emitted` | state-reuse / latex / output |
| `principal_emitted` | state-reuse-plain / latex / output |
| `sort_keys` | state-reuse / latex / output |

`range_pair_found` moves nothing, which is the criterion's own expectation:
`finish_ranges` assigns it wholesale on every document, so no earlier
document's findings can survive into one. It stays in the reset all the same —
a rule with an exception nothing enforces is not a rule — and the probe runs on
it, its passing being the recorded evidence for the claim.

Three cells needed the fixture set to be what it is. `marks_seen` and
`principal_emitted` move nothing in a document that sets them itself, which is
why the one-mark and mark-free fixtures exist; `html_marks` is read on the HTML
path alone. Five more — `marked_paths`, `pending_xrefs`, `clamped_paths`,
`range_found` and `range_pair_found` — are read by nothing but a report, which
is why the warning stream is compared alongside the output.

`range_verdicts` needed one further correction found here: the synthetic
document's first range mark was an opening nothing closed, which plans the
verdict `false`, and the emitting pass reads `false` as no verdict at all. A
range that actually pairs now holds that position.

## Review
