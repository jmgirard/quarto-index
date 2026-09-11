# M091: The cross-reference escaping probe's targets name terms it indexes

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — `examples/xref-escaping.qmd` is a test fixture the gallery lists under `not-shown:`, and the count manifest is the suite's own
- **Branch/PR:** m091-xref-probe-targets-resolve

## Goal

Every `see=`/`see-also=` target in `examples/xref-escaping.qmd` names a path a
mark in that file indexes, so the probe tests target resolution through every
printable ASCII character instead of drawing 271 dangling-target reports.

## Scope

**In:** hidden marks in `examples/xref-escaping.qmd`, one per distinct target
path; the suite's by-construction figures for that fixture re-derived (the
M02-AC3 makeindex entry count, the corpus manifest row and its derivation
comment); zero counts for both dangling-report wordings over the fixture's gfm
and LaTeX logs; a one-off discrimination probe; KI72 narrowed to what remains.

**Out:**
- The incidental unresolved targets in `examples/demo.qmd` and
  `examples/xref-conflict.qmd` → the candidate row this plan adds.
- The corpus rows whose targets dangle on purpose (`dangling-xref`,
  `self-xref`, the fold fixtures, `html-index`, `principal-cases`,
  `state-reuse`, the books) — they are the report's subject; no work.
- A permanent `--self-test` plant for the zero count → not added (plan gate);
  the discrimination probe is one-off and logged.

## Acceptance criteria

- [x] AC1: Rendered to gfm and to LaTeX, `examples/xref-escaping.qmd` draws no
      dangling-target report in either wording the suite pins:
      `check_warning_count` in `tests/run-tests.sh` reads 0 for
      `WARN_DANGLING` and for `WARN_DANGLING_INDEX` over each render's log.
- [x] AC2: `examples/xref-escaping.qmd` still covers every printable ASCII
      character from `!` to `~` (0x21-0x7E) as its own target level under both
      `see=` and `see-also=`, and its targets under each attribute use all
      three level positions; each of its 16 special-character probes renders
      its target identically in single and dual form; its empty-level and
      unusable-target probes each warn once; makeindex rejects 0 of its
      entries; and each of its 16 see, 16 see-also, 16 dual-target, 16
      special-character-source and 2 non-ASCII probes typesets its exact
      cross-reference string in its PDF index — each as read by the M02-AC3
      legs of `tests/run-tests.sh`.
- [x] AC3: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T5

## Tasks

- [x] T1: Add a section to `examples/xref-escaping.qmd`, after "Targets that
      cannot be used", whose prose says the probe's targets resolve against
      its marks, holding one invisible mark `[]{.index entry="…"}` per distinct
      target path the file's `see=`/`see-also=` values name after the
      empty-level drop (`see="A!"` names `A`; `see=""` names nothing). Derive
      the list from the attribute values, never by recall; write each entry in
      the fixture's own escaping (`!!`, `\\`, `\"`); give a path that is a
      prefix of another its own mark anyway. No added path may equal the
      source entry of a cross-reference mark in the file, which would contest
      that key (M15).
- [x] T2: In `tests/run-tests.sh`, with the arithmetic shown in each comment:
      re-derive `XREF_MARKS` at the M02-AC3 makeindex leg (line 6987) for the
      added entries; set the `examples/xref-escaping.qmd` corpus manifest row
      (line 14043) to 0 and rewrite its derivation comment (lines 13878-13884)
      to name what each target group resolves against; delete the comment at
      lines 13995-13996 calling this reconciliation a candidate; add zero
      counts for `WARN_DANGLING` and `WARN_DANGLING_INDEX` over
      `$WORK/xref-latex.log`, and for `WARN_DANGLING_INDEX` over the fixture's
      gfm corpus log. Batch the edits; never edit the file while a run is in
      flight.
- [x] T3: Discrimination probe, one-off and outside the suite: in a scratch
      directory holding a copy of the fixture and of `examples/_extensions`,
      render the unedited copy to gfm and read no dangling-target report; then,
      one copy each, remove the added mark for a multi-level path, for a
      single-level special-character path whose character leads no added
      multi-level path (a target also resolves as a prefix), and for a
      non-ASCII path, render each to gfm, and read one report per target
      naming the removed path — four for the special character, which its
      single, see-also and two dual forms each name. Record the four results in the work log. Never run
      while the suite runs.
- [x] T4: Narrow KI72 in `cairn/DESIGN.md` ("The acceptance suite: coverage
      gaps") to the incidental targets this milestone leaves in
      `examples/demo.qmd` and `examples/xref-conflict.qmd`, marked `narrowed
      M091`.
- [x] T5: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (reduced mode, fresh [O] reader) returned three findings: AC1 counted one of the two dangling-report wordings (fixed: both counted); AC2 was framed as the suite's legs and read wider than they check (fixed: restated as fixture properties, bounded to the 16 probes and 0 rejected); AC3 binds the suite, not the fixture (kept at the plan gate, the template requiring it for code milestones).
- 2026-09-11: plan gate chose reconciling the probe over dropping KI72 as settled by the pinned 271 because no fixture tests a target carrying special characters resolving; falsified by a fixture shown already testing that resolution.
- 2026-09-11: plan gate chose hidden marks naming each target over rewriting the targets to name the probe's own labels because rewriting removes the characters the probe exists to carry; falsified by an M02-AC3 leg found passing only because an added entry supplies the text it reads.
- 2026-09-11: plan gate chose a one-off logged discrimination probe over a permanent `--self-test` plant because the suite is already long-running and heavily planted; falsified by the zero count going vacuous in a later change with no run failing.
- 2026-09-11: implement started; question gate skipped, the plan fixing the mark shape, placement and figures.
- 2026-09-11: T1: 208 invisible marks under "Targets the probe resolves", one per distinct target path, generated from the attribute values; before the edit the gfm render's 271 quoted targets matched the 271 source-derived paths in order, and no added path equals a cross-reference mark's source entry.
- 2026-09-11: T2: `XREF_MARKS` 256 → 464 with its arithmetic, corpus row 271 → 0 with the derivation comment rewritten, candidate comment deleted, zero counts added for both wordings over the LaTeX log and the per-index wording over the gfm corpus log.
- 2026-09-11: T3 amended (minor): a special character is named by four targets, so removing its mark draws four reports, not one.
- 2026-09-11: T3 probe (scratch copies, gfm): unedited 0 reports; `L1!%!L3` removed → 1 naming it; `%` removed → 4 naming `%`; `café naïve` removed → 1 naming it; per-index wording 0 in all four. Scratch LaTeX render of the edited fixture: 0 reports, makeindex 464 accepted, 0 rejected.
- 2026-09-11: T4: KI72 narrowed to the incidental targets in `examples/demo.qmd` and `examples/xref-conflict.qmd`.
- 2026-09-11: T5: `tests/run-tests.sh --self-test` clean, 1456 checks, exit 0, 14m27s; T1-T4 ticked on the same run.
- 2026-09-11: T5 run surfaced that AC2's "16 exact cross-reference strings" names a set the M02-AC3 typeset leg does not read: it reads 66, a count unchanged on main.
- claim audit: not owed — internal tier
- 2026-09-11: mini gate on AC2's count: user chose correcting "16 exact cross-reference strings" to 66.
- re-audit: AC2 (reduced) — bounded promise: "every printable ASCII character" includes the space no leg checks, and "at all three level positions" reads per character where the leg checks the union per attribute; instrument: "66 exact strings" is the manifest's row count, not a fixture property; proportionality: nothing
- 2026-09-11: mini gate on the re-audit's findings: user chose the revised AC2 wording (space excluded, positions as a per-attribute union, the probe groups named in place of the count).
- re-audit: AC2 (reduced) — nothing on the three questions; noted, not adopted: the single/dual comparison reads the `.tex` `\index` argument rather than the PDF, and the typeset leg checks the string's presence in the index text rather than an exact entry
- 2026-09-11: AC2 amended (substantive, user-approved): "every printable ASCII character" → "from `!` to `~` (0x21-0x7E)"; "at all three level positions" → "its targets under each attribute use all three level positions"; "its 16 exact cross-reference strings typeset" → "each of its 16 see, 16 see-also, 16 dual-target, 16 special-character-source and 2 non-ASCII probes typesets its exact cross-reference string". Status → review.

## Decisions

## Review

Fresh run 2026-09-11 on `23ba362` (default branch unmoved since the cut): `tests/run-tests.sh --self-test`, 1456 checks, exit 0.

- AC1: `check_warning_count` (which calls `fail`, exit 1, on a mismatch) read 0 for `WARN_DANGLING` and for `WARN_DANGLING_INDEX` over `$WORK/xref-latex.log` (ok line "no cross-reference target in the probe dangles in the LaTeX render, in either report wording"); over the gfm corpus log `corpus-xref-escaping.log` it read 0 for `WARN_DANGLING` via the manifest row and 0 for `WARN_DANGLING_INDEX` via the added check, both before the M14 ok line "every example's dangling-target report count matches its pinned expectation". The log is written by the corpus loop (`tests/run-tests.sh:14088`) before it is read.
- AC2: the M02-AC3 legs passed on the same run: "probe covers all 94 printable ASCII characters under both attributes, all three level positions, and the single and dual forms render each target identically"; "an empty target level and an unusable target each warn once"; the makeindex grep (a `fail` on mismatch) passed, the run's `xref-escaping.ilg` reading "464 entries accepted, 0 rejected"; "all 66 exact cross-reference strings typeset in the probe index", the 66 rows of `XREF_PROBE_TEXT` being 16 `Xs` (see), 16 `Xt` (see-also), 16 `Xb` (dual), 16 `A?B, see Tgt` (special-character source) and 2 `Xu` (non-ASCII).
- AC3: `tests/run-tests.sh --self-test`, run sequentially with nothing else invoking it, printed "All checks passed (1456 checks)" and exited 0.

**Consistency gate.** `cairn_validate.py` exit 0, every check PASS/OK. No DESIGN principle changed, so `cairn_impact` skipped. Generic profile: no toolchain checks.

**Independent review** (full three-lens fan-out; `tests/run-tests.sh` is executable surface). [S] blame-history: no findings (checked M02, M14, M15 intent; D-011, D-021, D-022; no other leg reads this fixture's counts). [S] prior-review: no findings (archived M02, M14, M15, M39, M076 reviews and LESSONS checked; the GitHub PR-comment probe returned none). [O] diff-bug: no blocking findings; independently derived 208 target paths matching the 208 added marks exactly in order, no contested source key, 464 accepted by a scratch makeindex run, and both logs written before they are read. Ranked findings:

- F1: `check_warning_count` reads a missing log as 0, so the new gfm per-index zero at `tests/run-tests.sh:14110`, which names its log outside the loop that writes it, would pass vacuously if the fixture's manifest row were removed or renamed (the book-row checks beside it share this).
- F2: the gfm zero count has no in-suite discrimination: with the row at 0, nothing proves the fixture's gfm log still carries filter warnings (the LaTeX half is covered by the Xe00/Xe01 counts of 1 on the same log); the plan gate accepted this with a one-off probe.
- F3: "invisible" is loose for gfm: each mark is emitted as a raw empty `<span class="index" data-entry="…">`, hidden only once the HTML renders.
- F4: nothing guards the mark list against a later probe target being added without its mark, beyond the corpus zero counts (LaTeX still catches it).
