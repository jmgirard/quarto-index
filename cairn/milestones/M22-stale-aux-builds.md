<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M22: A stale `.aux` outliving its marks still builds

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

A LaTeX document whose surviving `.aux` carries the typeset-time subsystem's
commands renders cleanly after the marks that defined them are deleted.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Gobbling `\providecommand*` definitions for the three `.aux`-borne
names — `\quartoindexprincipalpage`, `\quartoindexrangeat`,
`\quartoindexrangeto` (three, not the candidate row's "two": D-009 settles
the range pair and M20's page command joins them) — injected into every
LaTeX-derived render that does not inject the live subsystem, the zero-marks
document included (`index.lua:143` currently returns before any injection);
the suite probe; the `core.lua` block-comment and README updates. The
deliverable is user-facing: a render failure in the author's own document
(`! Undefined control sequence`, pdflatex exit 1), the IP2 break the
subsystem exists to avoid. Lineage: promotes the 2026-08-22 candidate row
(M21 review F3).

**Out:** a registered page folded inside a makeindex range printing
unemphasized → standing locator-control candidate row (D-008's remaining
half). Cross-chapter range pairing → standing candidate row (D-009).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: A LaTeX document without a principal mention builds at pdflatex
      exit 0 against a surviving `.aux` carrying `\quartoindexprincipalpage`,
      `\quartoindexrangeat` and `\quartoindexrangeto` lines left by a
      previous render, with no `Undefined control sequence` in its log and no
      emphasized locator in its typeset index — asserted over two variants of
      the principal-range fixture: one with every `mention=` and `range=`
      attribute removed, and one with every index mark removed.
- [ ] AC2 (regression guard: true today; must stay true under this change): A
      document that carries a principal mention keeps the live subsystem: its
      rendered `.tex` header holds the subsystem's defining block and none of
      the gobbling definitions, and the behaviors the M20 and M21 suite
      sections certify still hold, evidenced by those sections passing
      unmodified.
- [ ] AC3: The active profile's verify slot (`tests/run-tests.sh`) passes.

## Coverage
<!-- owner: plan · create/amend-via-gate; review reads to fence evidence -->

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Build the stale-`.aux` probe red: render the principal-range
      fixture, copy its `.tex` and `.aux` into `$WORK` at the render that
      produces them (M05/M21 lesson: later steps destroy artifacts), author
      the two variants (every `mention=`/`range=` attribute removed; every
      index mark removed), run pdflatex on each variant's `.tex` beside the
      preserved `.aux`, assert exit 0 + clean log + no emphasized locator.
      Both variants fail today with `Undefined control sequence`.
- [ ] T2: Inject the three gobbling `\providecommand*…[2]{}` definitions into
      every LaTeX-derived render that does not emit the live subsystem: move
      `index.lua:143`'s early return after the injection, keeping its format
      guard; rewrite `core.lua:141-151`'s block comment, whose "the same
      hazard at one remove … is a ROADMAP candidate row" sentence this
      milestone retires. Probe green.
- [ ] T3: Prove the checks discriminate: splice the gobbler injection out
      (never `git checkout` — consolidated lesson) and watch T1's probe
      fail; assert the principal fixture's `.tex` carries no gobbling
      definition (AC2's clause) and that this check fails when one is
      spliced in ahead of the subsystem.
- [ ] T4: README note on stale-`.aux` behavior; remove the absorbed
      candidate row from the ROADMAP; work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-22: created by /milestone-plan.
- 2026-08-22: criteria audit (full mode, fresh-context reader) ran twice — pre-gate it returned four load-bearing findings (a false attribution clause in AC1, the zero-marks variant unprobed, an embedded probe recipe, AC2 blind to a co-injected gobbler), all repaired; the post-gate re-audit of the widened AC1 returned two mild findings here (AC1 domain scope, AC2's missing regression-guard label), repaired in the wording above.
- 2026-08-22: plan gate chose unconditional gobbling definitions (every LaTeX render without the live subsystem, zero-marks included) over marked-documents-only injection because IP2 covers any document using the extension and `index.lua:143` leaves exactly the zero-marks one crashing; falsified by a LaTeX-derived render reaching pdflatex with neither definition set in its header.
- 2026-08-22: plan (step 2) chose gobblers over always injecting the full subsystem because the subsystem is `@`-sensitive kernel-name code a no-principal document never exercises; falsified by a stale `.aux` line the gobblers fail to absorb cleanly.
- 2026-08-22: plan gate rejected the candidate row's alternative — a stale `.aux` is the author's to delete — because it accepts the render failure IP2 forbids; falsified by a render the gobbler injection itself breaks.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
