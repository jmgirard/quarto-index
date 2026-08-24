<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M31: A leftover index file never breaks the next render

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m031-stale-ind-standin` / https://github.com/jmgirard/quarto-index/pull/31

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

- [x] AC1: A document whose own marks emit none of the three, rendered beside a
      leftover `.ind` carrying `\quartoindexlocator`, `\quartoindexseeboth`
      and `\quartoindexxrefs`, compiles to a PDF, and the pages and
      cross-reference targets those commands carry appear in the compiled index
      as ordinary locators and cross-references.
- [x] AC2: With any one of the three definitions removed and nothing else
      changed, that same render fails on `Undefined control sequence` naming
      that command — one probe per definition, the failure asserted by
      identity, not by a non-zero exit alone.
- [x] AC3: A rendered document that does emphasize a principal mention carries
      the subsystem block and not the locator stand-in, and one that does not
      carries the locator stand-in and not the subsystem block — the
      exactly-one-of-two invariant M22 established, held over the widened
      stand-in block.
- [x] AC4: Every `quartoindex` command name appearing in any `.ind` the suite's
      own captured renders produce is defined in the preamble of every captured
      LaTeX document carrying `\printindex` — the command that reads an `.ind`
      — with both sets and that domain enumerated by a sweep over the captured
      artifacts, never from a written list.
- [x] AC5: `tests/run-tests.sh --self-test` completes clean.

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
- [x] T2: Add the pass-through locator stand-in to `PRINCIPAL_GOBBLERS`
      (`core.lua:309`) — `\providecommand*`, two arguments, printing the second
      — keeping the exactly-one-of-two-blocks discipline the comment above it
      states.
- [x] T3: Make `XREF_BOTH_DEFINITION` and `XREF_LIST_DEFINITION` unconditional
      in every LaTeX-derived render, the zero-mark branch (`index.lua:166`)
      included, and rewrite the comments that state the old conditional
      discipline.
- [x] T4: Add the checks to `tests/run-tests.sh`, reading captured artifacts
      rather than the working tree (M24), and covering both the changed shape
      and the untouched one — the document that does emphasize a principal
      mention must be in the fixture and must not change (M11). Re-derive
      `m22_standins_only`'s preamble count rather than leaving it pinned at
      three.
- [x] T5: Prove the checks discriminating: one probe per definition, reverting
      that line on a copy with a single substitution and requiring the check red
      on the named undefined control sequence.
- [x] T6: Add the AC4 sweep: enumerate every `quartoindex` name in the captured
      `.ind` artifacts and every definition in the captured `.tex` preambles,
      and require containment.
- [x] T7: Update the README's leftover-file paragraph (`README.md:388-401`) and
      the emitted-preamble sentence (`README.md:545-549`) from the `.aux` alone
      to the `.aux` and the `.ind`, and update `README_STALEAUX_CLAIMS`
      (`run-tests.sh:401-407`), whose pinned `.ind`-exclusion string this
      milestone makes false.
- [x] T8: Run `tests/run-tests.sh --self-test`; strike KI4 (its candidate row
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
- 2026-08-24: T2 and T3 — code landed, boxes left unticked until T4: the suite's `m22_standins_only` pins a no-subsystem preamble at exactly three `quartoindex` mentions, which this change makes six, so `verify` is red by construction until that count is re-derived. T2 adds `\providecommand*\quartoindexlocator[2]{#2}` to `PRINCIPAL_GOBBLERS`. T3 makes `XREF_BOTH_DEFINITION` and `XREF_LIST_DEFINITION` unconditional on both the marked and the zero-mark branch. That leaves `xref_both_emitted` and `xref_list_emitted` written and never read; they are removed rather than kept, because `stateprobe.py` requires every reset it probes to be load-bearing and a write-only flag's reset removal produces no render difference for it to catch — keeping them would turn the state-pollution guard red or need an exemption entry for dead state. Verified on the T1 reproduction: the child `.tex` now defines all six commands, pdflatex beside the same stale `.ind` exits 0 with no undefined control sequence, and the compiled index prints `basilisk, 1, 2`, `chimera, see Wyvern; see also Hydra` and `Drake, see Wyvern; see also Hydra`.
- 2026-08-24: amendment gate — AC4 narrowed. The sweep found beamer captures carrying no definitions, which is deliberate: beamer has no `theindex` environment, so the extension emits no `\index` and no `\printindex` there (`core.lua:391`), and a document with no `\printindex` never reads an `.ind`. AC4's domain is now every captured `.tex` carrying `\printindex`, read off each artifact. Rejected: naming beamer in an exclusion list, which is the exemption-registry shape a second excluded format would fall silently outside of; and injecting the definitions into beamer, which widens the deliverable to fit the criterion for no failure it can close. Falsified by a format that reads an `.ind` without carrying `\printindex`. The amended wording was asked the full-mode audit questions inline and returned no finding.
- 2026-08-24: T4, T5, T6 — checks landed and the suite runs clean. Four existing checks asserted the discipline this milestone reverses and were repaired rather than deleted: M02-AC5 now requires both cross-reference commands defined exactly once in the preamble of the using document AND the mark-free control; M08-AC2 and M15's shape sweep match `|<command>`, makeindex's encap opener, so they read an emission rather than the definition every preamble now carries; and `m20probes.py --standins` takes whole definition strings instead of a `[2]{}` pattern, which assumed every stand-in gobbles its arguments and would have reported the locator's `[2]{#2}` as a leak. `m22_standins_only` strikes out the six definitions it enumerates and requires no `quartoindex` residue, replacing the literal count of three, so a seventh definition fails by residue rather than needing the number edited. The new M31 section renders the T1 parent, re-renders it with the attributes stripped, and runs pdflatex beside the surviving `.ind` under `-no-shell-escape`, asserting the `.ind` byte-identical afterwards — TinyTeX's restricted shell escape whitelists makeindex, so imakeidx would otherwise rebuild the file and hide the hazard. T5's discriminating proof is the AC2 loop: each of the three definitions removed by a single substitution asserted to take exactly one line, the render required to exit non-zero AND to name that command at the `Undefined control sequence` argument line. T6's sweep reports 3 names across 7 captured `.ind` files against 30 captured `.tex` preambles.
- 2026-08-24: T7 — README updated and T2/T3 ticked, the suite now being clean. The leftover-file paragraph is rewritten over both files, and the sentence that scoped the promise to the `.aux` and excluded the `.ind` is gone rather than left standing beside a promise that now covers it. The emitted count goes from three `\providecommand*` definitions to six, split by which render carries which. `README_STALEAUX_CLAIMS` is repinned on the widened promise: its `ind exclusion` row asserted a sentence this milestone makes false, so it is replaced rather than kept. One suite run in between failed on a Quarto/Deno segfault during the gfm render of principal.qmd, unrelated to this branch and not reproduced on the re-run.
- 2026-08-24: T8 — `tests/run-tests.sh --self-test` completes clean: 436 checks, exit 0, the planted-defect batteries included. KI4 struck from DESIGN.md; no ROADMAP candidate row pointed at it, its row having been absorbed into this milestone at the plan gate.

## Decisions

## Review

### Acceptance criteria — fresh evidence

Suite run 2026-08-24 on `06e525c` + the PR-URL header edit: `tests/run-tests.sh
--self-test`, exit 0, 436 checks, planted-defect batteries included.

- AC1 — `M31-AC1`: the stripped-marks document builds at pdflatex exit 0 beside
  the surviving `.ind` carrying all three commands, logs no undefined control
  sequence, leaves that `.ind` byte-identical (run under `-no-shell-escape`), and
  prints its pages and cross-reference targets as ordinary locators and
  cross-references.

- AC2 — `M31-AC2`: each of the three definitions removed by a single
  substitution asserted to take exactly one line; that same render then exits 1
  and the failure is asserted by identity — an `Undefined control sequence`
  naming the removed command itself, not a bare non-zero exit. One probe per
  definition; this is also T5's discrimination proof.
- AC3 — `M31-AC3`: the document that emphasizes a principal mention carries the
  subsystem's locator definition and none of the four stand-ins; the one that
  does not carries the stand-ins and no subsystem residue. The
  exactly-one-of-two invariant holds over the widened block. The M22 self-test
  battery re-confirms it from the other side: the absence reader fails on a
  stand-in planted beside the subsystem.
- AC4 — `M31-AC4`: the sweep enumerates 3 `quartoindex` names across the 7
  captured `.ind` files (`quartoindexlocator`, `quartoindexseeboth`,
  `quartoindexxrefs`) and finds each defined in the preamble of every one of the
  30 captured `.tex` files carrying `\printindex`. Both sets and the domain are
  read off this run's artifacts, never from a written list; no fourth name
  appeared, so the amendment gate T1 fenced did not fire.
- AC5 — `tests/run-tests.sh --self-test` completes clean: exit 0, 436 checks,
  4m32s wall.

No Driving RR, so the projection-vs-outcome record is empty.

### Consistency gate

- `cairn_validate.py` — exit 0; every check PASS, every advisory OK, `release
  window` not fired.
- Toolchain checks — the `generic` profile's `consistency-gate` slot names none,
  so this half is a clean no-op.
- No `DESIGN.md` principle changed (the diff strikes KI4, a known-issue entry),
  so `cairn_impact.py` is skipped.

### Independent review

Deviation, logged: the declared tier is user-facing and the diff touches
executable surface, so the protocol calls for three fresh-context reviewers.
This session runs under a standing instruction not to spawn subagents — the same
instruction the plan-phase criteria audits were run under — so the three lenses
were run inline by the implementing session instead. They are therefore not
fresh-context. The maintainer is offered a re-run with real subagents at the
gate.

Six findings, ranked, all reported unfiltered.

- **F1 [diff-bug] — `index.lua:167-171`, the zero-mark branch's justification is
  false.** The comment added beside the two cross-reference definitions says a
  document that has lost EVERY mark "still reads a surviving `.ind` naming
  them". It does not: the zero-mark branch calls `place_index(doc, nil)`, which
  emits no `\printindex`, and `\printindex` is the only command that reads an
  `.ind` — the same predicate AC4's own sweep uses to bound its domain. Measured
  on this run's captures: seven captured LaTeX documents carry the two
  definitions with no `\printindex` at all. The two lines are inert there and
  harmless; the claim about why they are there is not derived from what the
  branch does.
- **F2 [diff-bug] — `passes.lua:572`, a comment T3 promised to rewrite and
  missed.** "the both-targets form needs `qi_core.XREF_BOTH_COMMAND`, which is
  injected only in a document that uses it" states exactly the discipline this
  milestone reverses.
- **F3 [diff-bug] — `latex.lua:4-5`, the module header counts flags that are
  gone.** "The two `emitted` flags below are read by the Pandoc pass, which
  writes the preamble: a command is defined only in a document that uses it."
  The diff removes both cross-reference flags, leaving one; and the discipline
  the sentence states no longer holds for the two commands it was written about.
- **F4 [diff-bug] — `core.lua:79-80`, a stale analogy.** The principal-emphasis
  command's comment says it is "injected only into a document that uses it,
  exactly like the two cross-reference commands above." The claim about that
  command stays true; the comparison it draws is now false.
- **F5 [diff-bug] — `run-tests.sh`, AC4's sweep reports a domain wider than the
  one it compares.** A captured `.tex` matching `\printindex` but with no
  `\begin{document}` is `continue`d silently, while the non-empty guard and the
  `ok` line both count `len(texs)` from before that skip. No such file exists
  today, so the reported 30 is honest on this run; the drift is latent.
- **F6 [blame-history] — `state-pollute.lua:78-79`, the rewritten comment
  misreads the shape.** The `Both` mark's comment now calls it "contested_keys
  again, through the other shape", but `is_contested` counts distinct
  ENCAPSULATIONS and its own comment says a single mark carrying both attributes
  "emits a single command and contests nothing". The mark records into
  `contested_keys`; it does not make the key contested.

Lens results: the blame-history lens found no change silently undoing a past
milestone's deliberate work — M02-AC5's negative half is reversed openly, in the
check's own comment and at the M31 amendment gate, and no `DECISIONS.md` entry
pins the conditional-injection discipline. The prior-review lens read the
archived `## Review` sections touching these files; M22's record warns of a
README claim reproduced false, and the widened `README_STALEAUX_CLAIMS` pinning
plus AC1's compiled-PDF assertions answer it. Neither lens contributed a
finding beyond F6.
