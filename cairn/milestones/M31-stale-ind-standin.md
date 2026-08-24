<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M31: A leftover index file never breaks the next render

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m031-stale-ind-standin`

## Goal

A LaTeX render whose `.ind` outlives the marks that defined it completes, the
way M22 made a render whose `.aux` outlives them complete.

## Scope

Surface tier: **user-facing** — the deliverable is a set of preamble lines
every LaTeX-derived render carries, and the failure it closes is a dead build.

**In:** Three extension commands can reach a compiled `.ind`, and each is
injected on its own condition, so each has the stale-`.ind` hazard KI4 records
against the first: `\quartoindexlocator`, written into the encapsulation
channel for every locator of a key carrying a principal mention
(`passes.lua:254`); `\quartoindexseeboth`, written there for a mark carrying
both `see=` and `see-also=` (`latex.lua:264`); and `\quartoindexxrefs`,
written there for a contested key no plain mark contributes to
(`passes.lua:561`). The locator's live definition is stateful, so it gets a
pass-through stand-in in `PRINCIPAL_GOBBLERS` (`core.lua:309`) — two
arguments, printing the second, since gobbling it would drop every page number
from a stale index rather than break the build. The two cross-reference
definitions are stateless and are already their own stand-ins, so they become
unconditional in every LaTeX-derived render rather than each gaining a second
block. This adds those changes, a fixture and checks that reproduce a stale
`.ind` carrying all three, and the README sentences that today scope the
promise to the `.aux` alone.

**Out:**
- A stand-in for a command no `.ind` carries → nothing; the three `.aux`-borne
  names are M22's and are covered already.
- Detecting, pruning or otherwise managing stale build files → out of the
  contract; whether the toolchain builds the index is documented, never managed
  (GP2).
- Emphasizing a principal page under a stand-in → out; a stand-in stands in for
  a subsystem this document does not have, and prints plain locators by design.

## Acceptance criteria

- [ ] AC1: A document whose own marks emit none of the three, rendered beside a
      leftover `.ind` carrying `\quartoindexlocator`, `\quartoindexseeboth`
      and `\quartoindexxrefs`, compiles to a PDF, and the pages and
      cross-reference targets those commands carry appear in the compiled index
      as ordinary locators and cross-references.
- [ ] AC2: With any one of the three definitions removed and nothing else
      changed, that same render fails on `Undefined control sequence` naming
      that command — one probe per definition, the failure asserted by
      identity, not by a non-zero exit alone.
- [ ] AC3: A rendered document that does emphasize a principal mention carries
      the subsystem block and not the locator stand-in, and one that does not
      carries the locator stand-in and not the subsystem block — the
      exactly-one-of-two invariant M22 established, held over the widened
      stand-in block.
- [ ] AC4: Every `quartoindex` command name appearing in any `.ind` the suite's
      own captured renders produce is defined in the preamble of every LaTeX
      document those same renders produce — both sets enumerated by a sweep
      over the captured artifacts, never from a written list.
- [ ] AC5: `tests/run-tests.sh --self-test` completes clean.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T1, T5
- AC3 → T4
- AC4 → T6
- AC5 → T8

## Tasks

- [x] T1: Build the stale-`.ind` fixture and reproduce the failure before the
      fix: render a parent carrying a principal mention, a both-attributes mark
      and an all-xref contested key; keep the `.ind`; delete the marks that emit
      the three commands; re-render; record the `Undefined control sequence` and
      the command it names. Sweep the produced `.ind` for every `quartoindex`
      name it carries, settling AC4's reachability from the artifact — a fourth
      name returns AC4 to the amendment gate.
- [ ] T2: Add the pass-through locator stand-in to `PRINCIPAL_GOBBLERS`
      (`core.lua:309`) — `\providecommand*`, two arguments, printing the second
      — keeping the exactly-one-of-two-blocks discipline the comment above it
      states.
- [ ] T3: Make `XREF_BOTH_DEFINITION` and `XREF_LIST_DEFINITION` unconditional
      in every LaTeX-derived render, the zero-mark branch (`index.lua:166`)
      included, and rewrite the comments that state the old conditional
      discipline.
- [ ] T4: Add the checks to `tests/run-tests.sh`, reading captured artifacts
      rather than the working tree (M24), and covering both the changed shape
      and the untouched one — the document that does emphasize a principal
      mention must be in the fixture and must not change (M11). Re-derive
      `m22_standins_only`'s preamble count rather than leaving it pinned at
      three.
- [ ] T5: Prove the checks discriminating: one probe per definition, reverting
      that line on a copy with a single substitution and requiring the check red
      on the named undefined control sequence.
- [ ] T6: Add the AC4 sweep: enumerate every `quartoindex` name in the captured
      `.ind` artifacts and every definition in the captured `.tex` preambles,
      and require containment.
- [ ] T7: Update the README's leftover-file paragraph (`README.md:388-401`) and
      the emitted-preamble sentence (`README.md:545-549`) from the `.aux` alone
      to the `.aux` and the `.ind`, and update `README_STALEAUX_CLAIMS`
      (`run-tests.sh:401-407`), whose pinned `.ind`-exclusion string this
      milestone makes false.
- [ ] T8: Run `tests/run-tests.sh --self-test`; strike KI4 (its candidate row
      was absorbed into this milestone at the plan gate).

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan gate chose shipping the stand-in now over first hunting a real Quarto pipeline that leaves an `.ind` unrewritten, because the line costs an unaffected document nothing and the failure it closes is the IP2 class — the reasoning M21 review F3 and M22 already applied to the `.aux`. This overrides the promotion condition KI4's candidate row states ("promote on evidence a real pipeline leaves an `.ind` unrewritten across a render"), at the user's explicit choice at the plan gate. Falsified by the stand-in changing what a healthy render prints.
- 2026-08-24: criteria audit ran in **full** mode (user-facing tier), inline rather than in a fresh-context [O] reader — this session is under a standing instruction not to spawn subagents. It returned one finding, fixed before the criteria were written: AC2 originally read "the render fails", which asserts a bare failure; it now asserts which failure, per the failure-identity rule.
- 2026-08-24: plan chose a pass-through stand-in over a gobbling one because `\quartoindexlocator` prints its second argument, and gobbling it would drop every page number from a stale index rather than break the build; falsified by a shape where passing the list through is itself unsafe.
- 2026-08-24: implement branch `m031-stale-ind-standin` cut; status in-progress.
- 2026-08-24: amendment gate — investigation found the plan's Scope premise false. Three extension commands reach a compiled `.ind`, each injected on its own condition: `\quartoindexlocator` (`passes.lua:254`, gated on `principal_emitted`), `\quartoindexseeboth` (`latex.lua:264`, gated on `xref_both_emitted`) and `\quartoindexxrefs` (`passes.lua:561`, gated on `xref_list_emitted`). Scope In, the first Out item, the acceptance criteria, Coverage and Tasks were amended to cover all three; the user chose the widening over shipping the locator alone and filing the other two. The locator keeps the planned two-block stand-in because its live definition is stateful; the two cross-reference definitions are stateless and become unconditional, since each is already its own stand-in. Rejected: giving the two their own conditional stand-in blocks, which buys three one-of-two invariants for a discipline whose stated reason — an author's own `\providecommand` surviving — unconditional injection does not touch. Falsified by a document that must not carry a cross-reference definition it does not use.
- 2026-08-24: criteria audit re-ran on the amended wording in **full** mode (user-facing tier), inline rather than in a fresh-context [O] reader, this session being under a standing instruction not to spawn subagents. It returned one finding: AC4's promise is reachable only if no `quartoindex` name beyond the three reaches an `.ind`. Disposed by adding the sweep to T1, which settles it from the produced artifact; a fourth name returns AC4 to the amendment gate rather than widening it silently.
- 2026-08-24: T1 — stale-`.ind` failure reproduced before any fix. A parent carrying a principal mention, a both-attributes mark and an all-cross-reference contested key renders to PDF and leaves an `.ind` holding `\hyperxindexformat{\quartoindexlocator{qi1}}{1, 2}`, `\hyperxindexformat{\quartoindexseeboth{Wyvern}{Hydra}}{2}` and `\hyperxindexformat{\quartoindexxrefs{\see{Wyvern}{}; \seealso{Hydra}{}}}{2}`. The same document with `mention=`/`see=`/`see-also=` stripped renders to a `.tex` naming none of the three; pdflatex on it beside that `.ind` exits 1 with three `Undefined control sequence` errors, each naming its command at the `<argument>` line. Run under `-no-shell-escape`: TinyTeX's restricted shell escape lets imakeidx re-run makeindex, which rebuilds the `.ind` and hides the hazard — with it off the file is byte-identical after the run. The AC4 sweep over that `.ind` returns exactly those three `quartoindex` names and no fourth, settling the criteria-audit finding from the artifact.

## Decisions

## Review
