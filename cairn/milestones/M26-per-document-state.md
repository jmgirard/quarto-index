# M26: A document's accumulators start empty, whoever ran before it

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Branch/PR:** `m26-per-document-state` — https://github.com/jmgirard/quarto-index/pull/26

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

- [x] AC1: Each of `examples/state-reuse.qmd`, `examples/state-reuse-plain.qmd`
      and `examples/state-reuse-empty.qmd`, rendered to LaTeX with the
      test-only pollution filter listed in its filter list and that filter's
      switch set, produces a captured `.tex` byte-identical (`cmp -s`) to the
      captured `.tex` from the same fixture rendered off the same tree with
      that switch unset, and a captured warning stream byte-identical to that
      render's.
- [x] AC2: The same three fixtures rendered to HTML each produce a captured
      page byte-identical (`cmp -s`) between the two renders, the emitted
      preamble and index section included, and a captured warning stream
      byte-identical between them.
- [x] AC3: The AC1 comparison fails, for at least one of the three fixtures,
      under each of four planted defects, one at a time and each reverted
      after: `marks.lua`'s `reset` removed, `latex.lua`'s removed,
      `sortkeys.lua`'s removed, and — varying form rather than location —
      `latex.lua`'s `reset` left in place but with `principal_ordinals` alone
      dropped from what it restores.
- [x] AC4: Sixteen of the 17 cells are load-bearing: for each, its own removal
      from its module's `reset`, that cell alone and reverted after, fails the
      AC1 or the AC2 comparison for at least one of the three fixtures —
      sixteen one-cell probes, reported per cell with the fixture, format and
      artifact (`.tex`, HTML page or warning stream) that moved. The
      seventeenth, `range_pair_found`, is exempt and stays in the `reset`:
      `finish_ranges` assigns it wholesale on every document, so no earlier
      document's value can survive into it; its probe is run and its passing
      every comparison recorded as that.
- [x] AC5: `tests/run-tests.sh --self-test` exits 0 and prints its
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
- [x] T8: Rewrite DESIGN.md's Architecture paragraph at :169-176, which says
      the accumulators are "still module-level" and not per-document; add the
      convention that a new accumulator joins its module's `reset`.
- [x] T9: Full `tests/run-tests.sh --self-test`; capture evidence per
      criterion.

## Work log

- 2026-08-23: created by /milestone-plan, promoting the `marks_seen` module-level-state candidate row (M01 review R16, widened through M23).
- 2026-08-23: plan gate ran the FULL criteria audit (user-facing tier) and it returned two findings. Fixed in drafting: the planted-defect criterion varied location only (which module's reset is removed), so AC3 gained a form axis — a reset left in place with one cell dropped from it. Taken to the gate: whether D-004 bars the byte comparison AC1 and AC2 rest on. The audit ran in-context rather than as a fresh-context [O] reader, this session being instructed not to spawn agents — so the reader that authored the criteria also audited them, which is the weaker arrangement.
- 2026-08-23: plan gate chose a per-module `reset` over moving the 17 cells into one `state.lua` and over making each module a per-document factory, because M17 deliberately placed each cell in the module that owns it and both alternatives re-split that at every call site; falsified by a cell whose correctness needs construction rather than restoration — `range_at` is the near miss, already needing a mid-document reset.
- 2026-08-23: plan gate chose a same-tree pollution-versus-clean byte comparison over extracting and comparing only the `\index` arguments and the HTML index section, because a leak reaching the preamble (`principal_emitted`) or the `.aux` registry (`principal_ordinals`) escapes the extraction entirely; falsified by the comparison proving brittle to something neither render's state differs in.
- 2026-08-23: T1 — the harness holds. A test-only filter listed AFTER `index` finds all nine extension modules in `package.loaded` at its own chunk-load time, which Quarto runs before any pass executes, so a value written there reaches the fixture's own marks: the same fixture emitted `\index{ZZZ@synthetic|quartoindexlocator{qi1}` polluted against `\index{synthetic}` clean. A synthetic `pandoc.Pandoc` drives through CollectSort, CollectKeys, CollectRanges/FinishRanges and Span without error. `require` from `tests/` was the wrong door and is not used: its cache key differs from the extension's absolute one, so it returns a SECOND copy of each module. The first reading of that probe as a success was a stale `.tex` left by an earlier render, found by removing the artifact and checking the exit code.
- 2026-08-23: T9 — `tests/run-tests.sh --self-test` exits 0 and prints "All checks passed (409 checks)."; the plain run is 275. Status to review.
- 2026-08-23: T8 — DESIGN.md's architecture paragraph now says the accumulators are returned to their initial values once per document and states the convention that a new one joins its module's `reset` in the commit that adds it; the `passes.lua` bullet and that file's own header were corrected alongside, both having said "the four Span passes" where there are now five entry points. Suite: 275 checks, all passing.
- 2026-08-23: T7 — `tests/stateprobe.py` runs the AC3 and AC4 probes; all four AC3 probes and all sixteen non-exempt cells move a comparison, `range_pair_found` moves none as its exemption predicts, and the per-cell verdicts are in the Decisions section. The driver is committed rather than run out of band so a fresh review session can reproduce it. Suite after the run: 275 checks, all passing.
- 2026-08-23: T5/T6 — `marks.lua`, `latex.lua` and `sortkeys.lua` each own a `reset`, called by a new `passes.Reset` that `index.lua` returns as the pass list's leading `{ Pandoc = ... }`. Tables are emptied in place through a new `qi_core.empty`, because every accumulator is exported by reference and a rebound local would restore this module's view alone. Suite: 275 checks, all passing, all twelve M26 comparisons among them.
- 2026-08-23: T2/T3/T4 — the three fixtures, `tests/state-pollute.lua` and the six paired renders are in the suite, and the suite now FAILS as it must before the fix: `run-tests.sh` reaches M26's first comparison after 255 passing checks and reports `the latex output of state-reuse depends on what ran before it in the same Lua state`. Out of band, all six comparisons differ (output and warnings, three fixtures x two formats); the leaks the rich fixture's `.tex` shows are `Held` contested, `Deep` filed under `dsort`, `Pivot` at ordinal qi2 rather than qi1, and the paired range emitted as two plain locators. `examples/state-reuse.qmd` joined M14's dangling-count manifest (one report) and the rich fixture's two LaTeX captures joined M15's contested-key map.
- 2026-08-23: the first draft of the M26 comparison printed its diff through `diff | head`, whose non-zero exit under `set -e` killed the run before its own FAIL line — found by there being no FAIL line in the log. Both failure branches now absorb the diff's exit.
- 2026-08-23: amendment (Substantive, user delegated the choice at the implement gate): AC1 and AC2 now compare each render's captured warning stream as well as its captured output, AC3 reads over the fixture set, AC4 binds sixteen cells and names `range_pair_found` exempt, Scope names three fixtures, and T2/T3/T4 follow. Cause: reading the cells' consumers showed `marked_paths`, `pending_xrefs`, `clamped_paths` and `range_found` are read by nothing but a `warn()`; `html_marks` only by the HTML path; `range_pair_found` is assigned wholesale by `finish_ranges` on every document; and a leaked `principal_emitted` or `marks_seen` moves nothing in a fixture that sets it itself.
- 2026-08-23: amendment criteria audit ran the FULL mode (user-facing tier) over the amended AC1-AC4 and returned one finding: the warning-stream comparison is unsatisfiable while the pollution drive itself warns, fixed in T3 by silencing `warn` for that drive rather than in the criterion. Run in-context rather than by a fresh-context [O] reader, this session being instructed not to spawn agents — the same weaker arrangement the plan gate's audit recorded.
- 2026-08-23: implement gate chose one fixture source with an environment switch on the pollution filter over sibling copies and over Quarto profiles, because two copies must be kept identical by hand and a later edit to one silently weakens the proof; falsified by an environment the harness cannot pass a variable through.
- 2026-08-23: plan gate chose shipping the fix over holding the row and over a reachability-probe-only milestone, because Quarto runs one process per document so no probe would find a path, while DESIGN.md:169-176 records M17 having weakened the guarantee and one cell's value reaches an on-disk artifact; falsified by the harness of T1 proving unbuildable, which returns this to plan.

- 2026-08-23: amendment return: AC1 — "Each of `examples/state-reuse.qmd`, `examples/state-reuse-plain.qmd` and `examples/state-reuse-empty.qmd`, rendered to LaTeX with the test-only pollution filter listed in its filter list and that filter's switch set, produces a captured `.tex` byte-identical (`cmp -s`) to the captured `.tex` from the same fixture rendered off the same tree with that switch unset, and a captured warning stream byte-identical to that render's."
- 2026-08-23: the amendment-return criteria audit ran the FULL mode (user-facing tier) over the amended AC1 and returned nothing: the state satisfying it is the three `state_reuse_pair ... latex tex` lines at tests/run-tests.sh:10217, no IP or D-entry puts that state out of reach (both renders are off one tree, so D-004 is not engaged, and the comparison is positional rather than a source scan), its domain is the three fixtures it names, and its promise is a property of the shipped filter's emitted output rather than of the harness that observes it. Run in this session, which read the branch cold and authored none of the wording, but not as a spawned fresh-context [O] reader — the arrangement the user chose at the mini gate, this session being instructed not to spawn agents.
- 2026-08-23: amendment executed at the mini gate (user chose the review's proposed wording as written): AC1 alone changed, from "rendered to PDF ... rendered without that filter" to a LaTeX render pair distinguished only by the pollution filter's switch. AC2, AC3 and AC4 read AC1 by reference and were left untouched at the user's selection; no criterion's promise was widened and none was added.

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

2026-08-23, branch `m26-per-document-state` at `66b98de`, PR #26 (draft).

**Sync.** `origin/main` is `ee152af` and has not moved since the branch was
cut; local `main` matches it, and the working tree was clean before any
evidence was gathered.

**Arrangement.** This session did not implement M26 — it read the branch
cold — but the three review lenses were run inside it rather than in spawned
subagents, this session being instructed not to spawn agents. That is the same
weaker arrangement the plan gate's and the amendment gate's criteria audits
already recorded here: the diff reader, the history reader and the prior-review
reader are one reader.

### Evidence

Two fresh runs, both at `66b98de` with nothing planted:

- `tests/run-tests.sh --self-test` — exit 0, final line
  `All checks passed (409 checks).` Twelve of those checks are M26's: for each
  of the three fixtures in each of latex and html, one `cmp` over the captured
  artifact and one over the captured warning stream, with the clean render's
  own report count pinned per fixture (4 and 2 for `state-reuse`, 0 and 0 for
  `state-reuse-plain`, 1 and 1 for `state-reuse-empty`).
- `python3 tests/stateprobe.py` — exit 0. Its control (every fixture identical
  in both formats and in its warnings with nothing planted) passes first; then
  four whole-or-partial reset removals each move `state-reuse`'s latex output,
  and sixteen one-cell removals each move a comparison — eleven the rich
  fixture's latex output, four its latex warnings, one its html output, one
  `state-reuse-empty`'s latex output, one `state-reuse-plain`'s latex output.
  `range_pair_found` moves nothing, as its exemption predicts.

Criterion by criterion:

- **AC1 — not verified. The criterion, not the work, is what fails.** It asks
  for fixtures "rendered to PDF" whose "captured `.tex`" is compared; in this
  repo those two cannot both hold — `tests/run-tests.sh:5542` records that
  `--to pdf` leaves no `.tex` behind, which is why every other check needing
  emitted LaTeX renders `--to latex` first. The suite renders these three
  `--to latex` (`tests/run-tests.sh:10188`). It also asks that the second
  render be the fixture "rendered without that filter", where the implement
  gate deliberately chose one fixture source listing the filter in both
  renders, switched by `QI_STATE_POLLUTE`. Finding F1 below; this is an
  amendment return.
- **AC2 — evidence recorded, not ticked.** The three html pairs and their
  warning pairs are byte-identical (six of the twelve checks above), and the
  captured artifact is the whole page, so the emitted preamble and the index
  section are inside the comparison. Not ticked because the criterion's "the
  two renders" names AC1's pair, which the F1 amendment redefines.
- **AC3 — evidence recorded, not ticked.** All four probes move a comparison:
  `reset:marks`, `reset:latex`, `reset:sortkeys` and the form-varying
  `reset:latex-one-cell` (`principal_ordinals` alone dropped from a reset left
  in place), each on `state-reuse`/latex/output. Not ticked: the criterion
  names "the AC1 comparison".
- **AC4 — evidence recorded, not ticked.** Sixteen cells load-bearing, one
  exempt, each named with the fixture, format and artifact that moved — the
  table in this file's Decisions section is reproduced exactly by this run.
  Not ticked: the criterion names the AC1 and AC2 comparisons.
- **[x] AC5 — verified.** `tests/run-tests.sh --self-test` exits 0 and prints
  `All checks passed (409 checks).`

**Consistency gate.** `cairn_validate.py` exits 0 with every check PASS and
every advisory OK. No `DESIGN.md` principle changed — the diff rewrites the
Architecture prose only and touches no IP/GP line — so `cairn_impact.py` does
not apply. The active profile is `generic`, whose `consistency-gate` slot names
no toolchain checks, so that half of the gate is a clean no-op.

**Diffstat.** 15 files, +800 / -61: six source files under `_extensions/`, the
three fixtures, `tests/state-pollute.lua`, `tests/stateprobe.py`, 77 lines of
`tests/run-tests.sh`, and DESIGN/ROADMAP/this file.

### Findings

Ranked, with disposition. The three lenses ran as one reader (see Arrangement).

- **F1 [O], amendment return — AC1 names a render this repo cannot pair with
  the artifact it demands, and a second render the implement gate replaced.**
  "Rendered to PDF … produces a captured `.tex`" is internally inconsistent
  here, and "rendered without that filter" describes the sibling-copy design
  the implement gate rejected in favour of one source and an environment
  switch. The work is right on both counts: the `.tex` is where a leak shows
  and a PDF render would compare a PDF, and one source cannot drift from its
  twin. The criterion is wrong. Routed to the gated criterion-amendment
  protocol; the amended clause is in the work log.
- **F2 [O], no defect found in the reset itself.** The 17 cells the Scope
  names are exactly the module-level mutable cells in the source: `marks.lua`
  ten, `latex.lua` six, `sortkeys.lua` one, and `html.lua`, `book.lua`,
  `marker.lua`, `levels.lua`, `core.lua` and `passes.lua` declare only
  constants. Each reset restores the value its declaration gives, tables in
  place through `qi_core.empty` because every accumulator is exported by
  reference. `{ Pandoc = qi_passes.Reset }` leads the pass list and carries no
  element function, so it is one traversal before any `Span` pass.
- **F3 [S] blame, checked and clear — the reset does not cut a book's index.**
  `book.lua:147` reads `qi_sortkeys.sort_keys` and the reset now empties it per
  document, which in a book means per chapter. M05 recorded that Quarto renders
  each chapter in its own Pandoc process and that cross-chapter data goes
  through the on-disk sidecar, so the read happens inside the chapter that
  filled the registry. The suite's book renders (latex and html, project and
  `quarto add` install) are among the 409 passing checks.
- **F4 [S] blame, checked and clear — no recorded decision is contradicted.**
  M17's export conventions hold (`M["reset"] = reset` in the bracket form,
  imported names reached through the module table, requires unchanged). D-009
  and D-010 are about pairing within one process and are untouched by a reset
  that runs at the start of one. D-011 is not engaged: `tests/stateprobe.py`
  plants a defect and requires a render to differ, which is the positional
  evidence D-011 prefers, not a source-shape scan.
- **F5 [S] prior review — the primary surface returned one relevant record,
  the secondary none.** `cairn/milestones/archive/` holds one `## Review`
  finding touching these files that bears on this diff: M17's review returned
  the milestone on AC2 rather than rereading the criterion, when the probe's
  `ok` lines shifted a count the criterion pinned. F1 above is the same
  disposition on the same kind of mismatch. The GitHub surface no-ops: the
  probe `gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1` returns
  `[]`, so there are no inline review threads to walk.
- **F6 [O], out of scope, rejected — `examples/state-reuse*.qmd` name
  `../tests/state-pollute.lua` in their own front matter**, so they are suite
  fixtures rather than standalone demonstrations. That is the design T3 and the
  implement gate chose, and each fixture's prose says so.

M10's lesson names the shape F1 belongs to — a criterion whose promise two
audit rounds read without running. Both audits on this milestone were the
in-context kind. Worth a LESSONS line at the hygiene pass that eventually
follows.

**Outcome.** Amendment return on AC1. Status to `in-progress` for that
amendment alone; no other work is convened, and re-review follows it.

### Round 2, 2026-08-23, branch `m26-per-document-state` at `b896252`, PR #26 (draft)

Re-review after the AC1 amendment. The amendment was the only work convened;
the code is unchanged since round 1's `66b98de`.

**Sync.** `origin/main` is still `ee152af` and has not moved since the branch
was cut. `origin/m26-per-document-state` matches local `HEAD` at `b896252`.
Working tree clean before any evidence was gathered.

**Arrangement — weaker than round 1's, and the weakest on this milestone.**
This session executed the amendment and then reviewed it, and the three lenses
again ran inside it rather than in spawned subagents, this session being
instructed not to spawn agents. Round 1 at least read the branch cold. Here the
author of the amended AC1 text is also its reviewer.

### Evidence

Three fresh runs, all at `b896252` with nothing planted:

- `tests/run-tests.sh --self-test` — exit 0, final line
  `All checks passed (409 checks).`
- `tests/run-tests.sh` — the twelve M26 checks all `ok`: for each of the three
  fixtures in each of latex and html, one `cmp` over the captured artifact and
  one over the captured warning stream, with the clean render's own report
  count pinned per fixture (4 and 2 for `state-reuse`, 0 and 0 for
  `state-reuse-plain`, 1 and 1 for `state-reuse-empty`).
- `python3 tests/stateprobe.py` — exit 0. Control passes first; four
  whole-or-partial reset removals each move `state-reuse`/latex/output; sixteen
  one-cell removals each move a comparison; `range_pair_found` moves nothing.
  The per-cell table in this file's Decisions section is reproduced line for
  line by this run.

Criterion by criterion:

- **[x] AC1 — verified.** The amended criterion names a LaTeX render pair, and
  that is what the suite runs: `tests/run-tests.sh:10190` renders each fixture
  `--to latex` twice under `QI_STATE_POLLUTE=1` then `=0`, with
  `../tests/state-pollute.lua` in the fixture's own filter list both times
  (`examples/state-reuse.qmd:8-10`), captures each render per M24's rule, and
  compares the captured `.tex` and the extracted warning stream with `cmp -s`
  (`tests/run-tests.sh:10205-10215`). Six of the twelve `ok` lines above are
  these three pairs. The comparison is the one D-012 licenses: both sides off
  one tree, differing only in the injected condition.
- **[x] AC2 — verified.** The three html pairs and their warning pairs are
  byte-identical — the other six `ok` lines. The captured artifact is the
  rendered page whole (`tests/run-tests.sh:150-190` copies the file), so the
  index section is inside the compared bytes; verified directly by rendering
  `examples/state-reuse.qmd` to html at this commit and reading the emitted
  `<section id="qi-index">` back. Finding G1 records what the criterion's
  "emitted preamble" clause binds on this back-end.
- **[x] AC3 — verified.** All four planted defects move the AC1 comparison,
  which is now a coherent thing to name: `reset:marks`, `reset:latex`,
  `reset:sortkeys` and the form-varying `reset:latex-one-cell`
  (`principal_ordinals` alone dropped from a reset left in place), each on
  `state-reuse`/latex/output. Each is planted alone and reverted after, and the
  unplanted tree is required to pass all six pairs first.
- **[x] AC4 — verified.** Sixteen cells load-bearing, each reported with the
  fixture, format and artifact that moved: eleven the rich fixture's latex
  output, four its latex warnings, one its html output, one
  `state-reuse-empty`'s latex output, one `state-reuse-plain`'s latex output.
  `range_pair_found` moves nothing and stays in the reset, which is what the
  criterion's exemption says to record.
- **[x] AC5 — verified.** `tests/run-tests.sh --self-test` exits 0 and prints
  `All checks passed (409 checks).`

**Consistency gate.** `cairn_validate.py` exits 0, every check PASS and every
advisory OK. The diff touches no IP/GP line in `DESIGN.md`
(`git diff origin/main...HEAD -- cairn/DESIGN.md` shows no principle line
added or removed), so `cairn_impact.py` does not apply. The active profile is
`generic`, whose `consistency-gate` slot names no toolchain checks.

**Returns.** One amendment return (AC1, round 1), on its own track; no second
return naming AC1. Zero defect returns, so the thrash rule does not fire.

**Diffstat.** 15 files, +932 / -62 against `origin/main`.

### Findings

Ranked. All five lenses ran as one reader — see Arrangement.

- **G1 [O], logged, no action — AC2's "emitted preamble" clause binds nothing
  on this back-end.** The HTML back-end deliberately emits no stylesheet or
  head content (`modules/html.lua:18`, GP4: a hook, not a stylesheet), so
  unlike the LaTeX side there is no emitted preamble for the comparison to
  include. This is not the criterion failing: the compared bytes are the whole
  rendered page, so the comparison is strictly wider than the clause requires,
  and anything the back-end later emits into the head falls inside it
  automatically. No amendment convened.
- **G2 [S] blame, logged, no action — `reset` is the first name in this source
  set with more than one top-level definition.** Three modules now define
  `local function reset()`. `tests/movedefs.py:54-74` requires exactly one
  definition set-wide for any name it is asked to move, and fails loudly rather
  than silently taking the first — the M16 F3 shape. `reset` is not among
  `MOVED_DEFINITIONS` (`tests/run-tests.sh:9807`), so nothing trips today, and
  adding it would fail with a message naming all three sites.
- **G3 [O], checked and clear — the 17-cell enumeration is still exhaustive.**
  Re-derived mechanically at this commit: the only other module-level table in
  the source set is `core.lua`'s `XREF_KIND_BY_ATTR`, built once at load from
  the constant `XREF_KINDS` and only read afterward (`core.lua:31-34`), so it
  is a derived constant rather than an accumulator.
- **G4 [S] blame, checked and clear — each cell's reset form matches its
  reach.** `principal_ordinals` and `range_at` are restored by plain local
  assignment; both are pure locals, read and written only inside their own
  module. `marks_seen` is restored through `M` because it is read as
  `qi_marks.marks_seen` at five sites in `index.lua` and written at
  `passes.lua:414` — the reason its declaration comment already gives. The
  fourteen tables are emptied in place through `qi_core.empty`, because every
  one is exported by reference.
- **G5 [S] blame, checked and clear — the reset does not cut a book's index.**
  `book.lua:147` reads `qi_sortkeys.sort_keys` inside the per-chapter store
  write, which runs in the emitting pass of the same chapter — after Reset and
  after `CollectSort` refilled the registry in that same process. The suite's
  book renders are among the 409 passing checks.
- **G6 [S] prior review — one archived record, still upheld; the GitHub
  surface no-ops.** M17's export conventions hold in this diff:
  `M["reset"] = reset` in the bracket form, imported names reached through the
  module table (`qi_core.empty`, `qi_marks.reset`). The probe
  `gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1` returns `[]`,
  so there are no inline review threads to walk. Round 1's F5 noted M17's own
  review returned that milestone on AC2 rather than rereading the criterion;
  round 1's F1 took the other disposition on the same shape, which is what this
  round verifies.

**Outcome.** All five criteria verified with fresh evidence. Round 1's F1 is
closed by the amendment. No finding meets the return floor.
