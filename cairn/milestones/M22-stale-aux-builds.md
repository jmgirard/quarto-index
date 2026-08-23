<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M22: A stale `.aux` outliving its marks still builds

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m22-stale-aux-builds · https://github.com/jmgirard/quarto-index/pull/22   <!-- owner: implement (branch) / review (PR URL) · create -->

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
      previous render, with no `Undefined control sequence` in its log —
      asserted over two variants of a document whose surviving `.aux` carries
      all three of those names: one with every `mention=` and `range=`
      attribute removed, and one with every index mark removed.
- [ ] AC2 (regression guard: true today; must stay true under this change): A
      document that carries a principal mention keeps the live subsystem — its
      rendered `.tex` header holds the subsystem's defining block and none of
      the gobbling definitions — and each of AC1's two variants instead holds
      all three `.aux`-borne names, every one defined as the empty-bodied
      `\providecommand*\<name>[2]{}` stand-in and none with a body.
- [ ] AC3: The active profile's verify slot (`tests/run-tests.sh`) passes.

## Coverage
<!-- owner: plan · create/amend-via-gate; review reads to fence evidence -->

- AC1 → T1, T2, T5
- AC2 → T2, T3, T5
- AC3 → T1, T2, T3, T4, T5, T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Build the stale-`.aux` probe red: render the principal-range
      fixture, copy its `.tex` and `.aux` into `$WORK` at the render that
      produces them (M05/M21 lesson: later steps destroy artifacts), author
      the two variants (every `mention=`/`range=` attribute removed; every
      index mark removed), run pdflatex on each variant's `.tex` beside the
      preserved `.aux`, assert exit 0 + clean log + no emphasized locator.
      Both variants fail today with `Undefined control sequence`.
- [x] T2: Inject the three gobbling `\providecommand*…[2]{}` definitions into
      every LaTeX-derived render that does not emit the live subsystem: move
      `index.lua:143`'s early return after the injection, keeping its format
      guard; rewrite `core.lua:141-151`'s block comment, whose "the same
      hazard at one remove … is a ROADMAP candidate row" sentence this
      milestone retires. Probe green.
- [x] T3: Prove the checks discriminate: splice the gobbler injection out
      (never `git checkout` — consolidated lesson) and watch T1's probe
      fail; assert the principal fixture's `.tex` carries no gobbling
      definition (AC2's clause) and that this check fails when one is
      spliced in ahead of the subsystem.
- [x] T4: README note on stale-`.aux` behavior; remove the absorbed
      candidate row from the ROADMAP; work log.
- [x] T5: Round-1 review fixes in the probe and the criteria's evidence:
      drop AC1's dropped emphasis clause and the fragile
      `\newcommand*\quartoindexprincipal` header it needed (F3, F12);
      grep the log for `Undefined control sequence` after the SECOND pdflatex
      pass too, not the first alone (audit F7); `[ -f ]` guard in
      `m22_nogobblers`, which returns success on a missing file today (F4);
      splice-out plant extended to the zero-marks branch (F5); a bodied
      definition of a trio name planted in the control, to show the leak scan
      still trips after the `--standins` subtraction (F9); `grep -qE` for the
      GNU BRE alternation (F11).
- [x] T6: `examples/control.tex` — the zero-mark negative control — carries
      the three stand-ins with no check reading them (F8): assert them there
      and name them in AC3's forbidden-token loop as the one permitted
      addition.
- [x] T7: Prose the change made false: narrow README's stale-`.aux` paragraph
      to the `.aux` and say what a surviving `.ind` still does (F1); state the
      three preamble lines in README's own "What it emits" section (F7); fix
      `modules/latex.lua`'s byte-identical comment (F6) and the new zero-marks
      branch's "exactly as below" comment, which points at a path that warns
      where it is silent (H1). Candidate row for the surviving-`.ind` hole.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-22: created by /milestone-plan.
- 2026-08-22: criteria audit (full mode, fresh-context reader) ran twice — pre-gate it returned four load-bearing findings (a false attribution clause in AC1, the zero-marks variant unprobed, an embedded probe recipe, AC2 blind to a co-injected gobbler), all repaired; the post-gate re-audit of the widened AC1 returned two mild findings here (AC1 domain scope, AC2's missing regression-guard label), repaired in the wording above.
- 2026-08-22: plan gate chose unconditional gobbling definitions (every LaTeX render without the live subsystem, zero-marks included) over marked-documents-only injection because IP2 covers any document using the extension and `index.lua:143` leaves exactly the zero-marks one crashing; falsified by a LaTeX-derived render reaching pdflatex with neither definition set in its header.
- 2026-08-22: plan (step 2) chose gobblers over always injecting the full subsystem because the subsystem is `@`-sensitive kernel-name code a no-principal document never exercises; falsified by a stale `.aux` line the gobblers fail to absorb cleanly.
- 2026-08-22: plan gate rejected the candidate row's alternative — a stale `.aux` is the author's to delete — because it accepts the render failure IP2 forbids; falsified by a render the gobbler injection itself breaks.
- 2026-08-22: T1 probe verified red on exactly the three undefined `.aux`-borne commands; T2 gobblers landed and turned it green standalone; T3 discrimination checks and T4 README paragraph written; full-suite `--self-test` verify in flight, tasks unticked until it is clean (checkpoint, half-done). T1 refinement: the probe authors its own parent fixture in `$WORK` because no committed fixture's `.aux` carries all three names in one file.
- 2026-08-22: first full run caught M20-AC6's leak check firing on the stand-ins — its bare-name needle was a proxy for "the subsystem leaked"; the check now subtracts exactly the empty-bodied stand-in form of the three named `.aux`-borne commands (`--standins`) before the leak scan, and its planted leak (an empty-bodied `\quartoindexlocator`, outside the trio) still trips it.
- 2026-08-22: full suite `--self-test` green — 372 checks, 0 FAIL — with the M22 section's probe, absence reader and both discrimination plants passing; T1–T4 ticked, status review.
- 2026-08-22: review opened — merged the default branch's status-mirror commit into the branch, pushed, draft PR #22; consistency gate clean (cairn_validate all-pass, no DESIGN principle touched, generic profile names no toolchain checks); full-suite `--self-test` verify and the three-lens fan-out in flight (checkpoint, review half-done).
- 2026-08-22: review round 1 — AC3 verified (suite exit 0, 372 checks, 0 FAIL); consistency gate clean; three-lens fan-out returned 13 findings, all logged in the Review section with dispositions.
- 2026-08-22: amendment return: AC1 — "asserted over two variants of the principal-range fixture" — no committed fixture's `.aux` carries all three `.aux`-borne names, so the probe authors its own parent and the evidence does not answer the criterion as written.
- 2026-08-22: amendment return: AC2 — "evidenced by those sections passing unmodified" — AC1's stand-ins define exactly the three names M20-AC6's leak needle scans for, in exactly the documents it scans, so no correct implementation of AC1 leaves the M20 section unmodified; the criterion is unsatisfiable alongside AC1.
- 2026-08-22: status back to in-progress for those two amendments; the review-round findings F1 (README's stale-.aux claim is false — a surviving `.ind` still breaks the render, reproduced at review), F3, F4, F5, F6, F7, F8, F9 and H1 are triaged fix-now and F11, F12 follow-up, all recorded in the Review section.
- 2026-08-22: amendment return: AC1 — "asserted over two variants of a document whose surviving `.aux` carries all three of those names: one with every `mention=` and `range=` attribute removed, and one with every index mark removed" — and the unfalsifiable "no emphasized locator" clause dropped; a fresh-context [O] criteria audit ran in full mode over the amended wording before it was written and cleared AC1 on every axis.
- 2026-08-22: amendment return: AC2 — "each of AC1's two variants instead holds all three `.aux`-borne names, every one defined as the empty-bodied `\providecommand*\<name>[2]{}` stand-in and none with a body" — replacing the unsatisfiable "passing unmodified" clause; the same full audit found the first draft of this clause vacuously true of `origin/main` (a form restriction on appearances, satisfied by no appearance at all) and it was rewritten to require presence before the gate.
- 2026-08-22: amendment gate held the criteria set at three rather than widening AC2 to the suite's zero-mark control, the audit's uncovered-domain finding routed to T6 instead; the gate also directed all nine round-1 fix-now findings into this pass (T5-T7). Coverage extended to the new tasks; AC3 unticked, its round-1 evidence stale under these changes.
- 2026-08-22: T5-T7 done — the emphasis clause and the fragile `\newcommand*` fixture header removed with the criterion that needed them, both pdflatex passes read for the undefined control sequence, `m22_nogobblers` guarded against a missing file, the splice-out plant extended to the zero-marks branch, a bodied plant added showing the leak scan still trips after the `--standins` subtraction, the committed zero-mark control asserted to carry the three stand-ins and nothing else naming quartoindex, `grep -qE` for the BRE alternation, README's promise scoped to the `.aux` with the surviving-`.ind` hole stated and rowed, and the two comments the change made false corrected. Full suite `--self-test`: exit 0, 373 checks, 0 FAIL. Status review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

**Round 1 — 2026-08-22. Outcome: amendment return on AC1 and AC2.**

Branch synced with the default branch first (`origin/main`'s status-mirror
commit merged in), pushed, draft PR #22 opened. The repo has no CI workflows,
so the local suite is the whole evidence base.

### Acceptance-criterion evidence

- **AC1 — not verified (amendment return).** The probe runs and passes: both
  variants build at pdflatex exit 0 beside the surviving `.aux`, neither log
  reports an undefined control sequence, and the self-test shows the probe
  failing on the injection spliced out — on that undefined control sequence
  itself. Two defects in the evidence. (a) AC1 is stated over "two variants of
  the principal-range fixture"; the probe authors its own parent in `$WORK`.
  The reason is sound and recorded in the work log — verified here by command:
  of the committed artifacts only `examples/principal.aux` and
  `examples/principal-cases.aux` carry `\quartoindexprincipalpage` and only
  `examples/range.aux` carries the two range names, so no one committed `.aux`
  carries all three — but AC1's text was never amended to match, so the
  evidence does not answer the criterion as written. (b) AC1's "no emphasized
  locator" clause cannot fail: `[P:` is produced only by
  `\quartoindexprincipal`, reached only from inside `\quartoindexlocator`,
  which neither variant defines and neither variant's freshly written `.idx`
  encapsulates with. T3 planted a defect for the exit-0 clause and none for
  this one.
- **AC2 — not verified (amendment return).** The header clause passes: both
  no-subsystem variants define all three stand-ins and the principal document
  defines none of them beside its live subsystem, and the shared absence
  reader fails on a stand-in planted ahead of the subsystem. The evidence
  clause does not: AC2 requires the M20 and M21 suite sections to pass
  *unmodified*, and the M20 section was modified on this branch —
  `tests/run-tests.sh` M20-AC6 (both call sites and the self-test's
  `m20_tex`), and `tests/m20probes.py`'s `_tex`, which gained the
  `--standins` subtraction. The modification is unavoidable rather than
  optional: AC1's stand-ins define exactly the three names M20-AC6's leak
  needle scans for, in exactly the documents it scans, so no correct
  implementation of AC1 leaves that check untouched. AC2 as written is
  therefore unsatisfiable alongside AC1.
- **AC3 — verified.** `tests/run-tests.sh --self-test` (the `generic`
  profile's verify slot): exit 0, 372 checks, 0 FAIL, including the M22
  probe, the AC2 absence reader and both discrimination plants.

### Consistency gate

`cairn_validate` exit 0, all 16 checks PASS, 7 advisories OK. No `DESIGN.md`
principle changed, so no Sync Impact Report. The `generic` profile's
`consistency-gate` slot names no toolchain checks — a clean no-op.

### Independent review — three fresh-context lenses

[O] diff-bug returned twelve findings, [S] blame-history one, [S]
prior-review none (its GitHub probe found no inline review comments in the
repo at all, and no archived `## Review` finding on the touched files is
reintroduced here). Every finding and its disposition:

- **F1 (fix now + follow-up).** README's new headline claim, "Deleting marks
  never breaks the next render", is false as written: the subsystem also
  writes `\quartoindexlocator` into the `.idx` and so into the `.ind`, which
  survives on the same conditions the paragraph names, and no gobbler covers
  it. Reproduced independently at review — a document defining the three
  stand-ins, with hyperref and imakeidx loaded and a leftover `.ind` holding
  `\hyperxindexformat{\quartoindexlocator{qi1}}{4--6}`, gives `Undefined
  control sequence` on `\quartoindexlocator` and pdflatex exit 1. The probe
  never sees it because it copies only `.tex` and `.aux` into the run
  directory. Narrow the sentence to the `.aux`; the `.ind` hole is new scope
  and takes a candidate row.
- **F2 (amendment return).** AC2's "passing unmodified" clause — recorded
  under AC2 above.
- **F3 (fix now).** AC1's emphasis clause cannot fail — recorded under AC1
  above.
- **F4 (fix now).** `m22_nogobblers` returns 0 on a file that does not exist:
  `grep -qF` exits 2 on a missing path, all three iterations are false, and
  the function falls off the end. AC2's absence clause would pass silently if
  `$WORK/principal.tex` were ever absent — the hole `m20probes._tex` guards
  against explicitly. One line: `[ -f "$tex" ] || return 1`.
- **F5 (fix now).** The discrimination plant renders only the `noattrs`
  variant, which exercises the `else` branch; the zero-marks branch the scope
  names as the one `index.lua:143` used to return before has no planted-defect
  proof of its own.
- **F6 (fix now).** `modules/latex.lua:154`'s comment — "so a document with no
  principal mention is byte-identical" — is made false by this diff at the
  document level; the milestone rewrote `core.lua`'s block comment and left
  this one.
- **F7 (fix now).** README's "What it emits" section still says a document
  with no marks "gets none of this" and one with neither cross-reference shape
  "gets nothing extra". The new paragraph sits in the principal-emphasis
  section, so the authoritative emissions section never states that every
  LaTeX render now carries three `\providecommand*` lines.
- **F8 (fix now).** The stand-ins are asserted present only in the M22
  fixture's two variants. `examples/control.tex` — the AC3 zero-mark negative
  control — now carries them (verified: lines 192-194) with no check saying
  so, and AC3's forbidden-token loop was not extended to name them as the one
  permitted addition.
- **F9 (fix now).** The `--standins` subtraction is not a weakening —
  confirmed by reading it: it removes only the exact string
  `\providecommand*\<name>[2]{}` for the three named commands, so a bodied
  definition, any other name, and the `\csname` construction all still trip
  the scan, and the positive half independently catches a stand-in
  co-injected into the principal fixture. But the only planted leak is an
  empty-bodied `\quartoindexlocator`, outside the trio, so nothing in the run
  demonstrates that a trio name still trips the scan after the subtraction.
- **F10 (amendment return).** AC1's fixture identity — recorded under AC1
  above.
- **F11 (follow-up).** `grep -q 'mention=\|range='` is a GNU BRE alternation,
  undefined in stock BSD `grep`; a guard that silently fails to fire is the
  M16 failure mode the surrounding comment cites. Absorb into the standing
  acceptance-suite-hardening row's BSD-portability item.
- **F12 (follow-up).** The new parent fixture defines
  `\newcommand*\quartoindexprincipal` in `include-in-header`, which
  hard-errors if the filter's own definition ever lands first. Second
  instance of the standing `\providecommand*` row (M20 review R2-F15).
- **H1 (fix now).** [S] blame-history: the new zero-marks branch guards
  injection on `quarto.doc.include_text` and falls through silently, where the
  marks>0 path a few lines below warns that preamble injection needs Quarto.
  Its own comment says "exactly as below", pointing at the path that warns, so
  the comment is false whichever way the silence is resolved.

Findings the lenses cleared, recorded so the next round does not re-derive
them: the three gobbled commands take exactly the two arguments `[2]`
declares; the three names are exactly the set written through
`\protected@write\@auxout`; the format guard is preserved and now precedes the
marks check; the two definition blocks are genuinely mutually exclusive; and
no `DECISIONS.md` entry or `DESIGN.md` convention is contradicted, with
`PRINCIPAL_GOBBLERS` exported in the bracket form M17 review F3 mandated.
