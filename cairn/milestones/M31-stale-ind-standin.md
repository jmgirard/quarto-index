<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M31: A leftover index file never breaks the next render

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** —

## Goal

A LaTeX render whose `.ind` outlives the marks that defined it completes, the
way M22 made a render whose `.aux` outlives them complete.

## Scope

Surface tier: **user-facing** — the deliverable is a preamble line every
LaTeX-derived render carries, and the failure it closes is a dead build.

**In:** `PRINCIPAL_GOBBLERS` (`_extensions/index/modules/core.lua:309`) defines
gobbling stand-ins for the three commands a surviving `.aux` can name. It does
not cover `\quartoindexlocator`, which is the extension command a surviving
`.ind` carries — `\hyperxindexformat{\quartoindexlocator{qi1}}{4--6}` in the
shape M22's review reproduced. That command takes two arguments and prints the
second, so its stand-in must pass the page list through rather than swallow it.
This adds that stand-in, a fixture and check that reproduce the stale `.ind`,
and the README sentence that today scopes the promise to the `.aux` alone.

**Out:**
- A stand-in for any other command → nothing; `\quartoindexlocator` is the only
  extension command an `.ind` carries.
- Detecting, pruning or otherwise managing stale build files → out of the
  contract; whether the toolchain builds the index is documented, never managed
  (GP2).
- Emphasizing a principal page under a stand-in → out; a stand-in stands in for
  a subsystem this document does not have, and prints plain locators by design.

## Acceptance criteria

- [ ] AC1: A document carrying index marks but no principal mention, rendered
      with a leftover `.ind` in place whose locator is encapsulated in
      `\quartoindexlocator`, compiles to a PDF, and the pages that locator
      carries appear in the compiled index as ordinary locators.
- [ ] AC2: Without the stand-in, that same render fails on
      `Undefined control sequence` naming `\quartoindexlocator` — the failure
      asserted by identity, not by a non-zero exit alone.
- [ ] AC3: A rendered document that does emphasize a principal mention carries
      the subsystem block and not the stand-in block, and one that does not
      carries the stand-in block and not the subsystem block — the
      exactly-one-of-two invariant M22 established, held over the widened
      stand-in block.
- [ ] AC4: `tests/run-tests.sh --self-test` completes clean.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T4
- AC3 → T3
- AC4 → T6

## Tasks

- [ ] T1: Build the stale-`.ind` fixture and reproduce the failure before the
      fix: render, keep the `.ind`, remove the principal mark, re-render, and
      record the `Undefined control sequence` and the command it names.
- [ ] T2: Add the pass-through stand-in to `PRINCIPAL_GOBBLERS`
      (`core.lua:309`) — `\providecommand*`, two arguments, printing the second
      — keeping the exactly-one-of-two-blocks discipline the comment above it
      states.
- [ ] T3: Add the check to `tests/run-tests.sh`, reading captured artifacts
      rather than the working tree (M24), and covering both the changed shape
      and the untouched one — the document that does emphasize a principal
      mention must be in the fixture and must not change (M11).
- [ ] T4: Prove the check discriminating: revert the stand-in line on a copy
      with a single substitution and require the check red on the named
      undefined control sequence.
- [ ] T5: Update the README's leftover-file paragraph (`README.md:545-549`) from
      three `\providecommand*` definitions to four, and from the `.aux` alone to
      the `.aux` and the `.ind`.
- [ ] T6: Run `tests/run-tests.sh --self-test`; strike KI4 (its candidate row
      was absorbed into this milestone at the plan gate).

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan gate chose shipping the stand-in now over first hunting a real Quarto pipeline that leaves an `.ind` unrewritten, because the line costs an unaffected document nothing and the failure it closes is the IP2 class — the reasoning M21 review F3 and M22 already applied to the `.aux`. This overrides the promotion condition KI4's candidate row states ("promote on evidence a real pipeline leaves an `.ind` unrewritten across a render"), at the user's explicit choice at the plan gate. Falsified by the stand-in changing what a healthy render prints.
- 2026-08-24: plan chose a pass-through stand-in over a gobbling one because `\quartoindexlocator` prints its second argument, and gobbling it would drop every page number from a stale index rather than break the build; falsified by a shape where passing the list through is itself unsafe.
- 2026-08-24: criteria audit ran in **full** mode (user-facing tier), inline rather than in a fresh-context [O] reader — this session is under a standing instruction not to spawn subagents. It returned one finding, fixed before the criteria were written: AC2 originally read "the render fails", which asserts a bare failure; it now asserts which failure, per the failure-identity rule.

## Decisions

## Review
