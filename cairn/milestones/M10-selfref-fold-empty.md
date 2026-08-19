# M10: Self-references the level fold and empty levels hide

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP6
- **Branch/PR:** m10-selfref-fold-empty

## Goal

Drop and report a cross-reference target that names what the mark's own entry
prints, in the two cases M08's comparison cannot see: after the LaTeX
three-level fold, and where an empty level makes the two spellings differ.

## Scope

Surface tier: **user-facing** — the deliverable is the emitted index and the
warnings an author reads.

**In:** two comparisons where M08 had one. (a) The existing format-neutral
comparison gains empty-level stripping on both sides, so it runs in every
format including back-end-less ones — an empty level prints nothing, so an
entry whose non-empty projection equals the target does read "X, see X". (b) A
second, LaTeX-only comparison runs after `clamp_levels` against the entry's
clamped **printed** path, catching the fold-induced match that does not exist
in HTML. A fold-induced target is dropped, as M08 drops every other
self-target; one document may therefore index differently per format, which is
IP1's back-ends-realize-per-format, not a divergence.

**Out:** a leading empty level (`entry="!Cats"`) → stays on its candidate row;
makeindex rejects a leading null field outright, so probing it here would plant
a known build failure rather than test this fix. Empty levels themselves are
not made representable → same row. The emptied-container report → its own row.
Acceptance-suite hardening → its clustered candidate row.

## Acceptance criteria

- [ ] AC1. For each of the three fold shapes added to `examples/self-xref.qmd`
      — `entry="A!B!C!D" see-also="A!B!C, D"`, `entry="F!G!H!I!J"
      see="F!G!H, I, J"`, and `entry="M!N!O!P" sort="m!n!o!p"
      see-also="M!N!O, P"` — the `\index{}` command in `examples/self-xref.tex`
      whose argument is respectively `A!B!C, D`, `F!G!H, I, J` and
      `m@M!n@N!o@O, P` carries no `|see{...}` and no `|seealso{...}` encap.
      Verified by `tests/run-tests.sh` extracting every `\index{}` command from
      `examples/self-xref.tex` and matching each expected argument against the
      extracted set.
- [ ] AC2. For `entry="Moles!" see="Moles"` (two levels, so the fold cannot
      reach it) and `entry="P!Q!R!" see-also="P!Q!R"`: the `\index{}` command
      for each in `examples/self-xref.tex` carries no encap, and in
      `examples/self-xref.html` the entry node each mark files under — the sole
      child of the `Moles` node, and the sole child of the `R` node — carries
      no `.qi-xref` descendant, asserted on tag, class list and id via
      `tests/htmlindex.py`, never on text.
- [ ] AC3. In `examples/self-xref.html` the `entry="A!B!C!D"` mark's
      fourth-level entry node still carries its `.qi-see-also` target element.
      HTML applies no level fold, so the match exists only in LaTeX.
- [ ] AC4. The fold-self-reference message quotes the printed folded path the
      comparison used (`A!B!C, D`) alongside the author's unclamped `entry=`
      text and states the fold as the reason; the grep key `tests/run-tests.sh`
      uses for each of the three messages — M08's self-reference message, the
      fold-self-reference message, and `clamp_levels`' fold-depth message —
      matches the other two zero times, asserted by counting each key against
      the other two fixed strings; and over the render logs
      `examples/self-xref.qmd` already produces for latex, html and gfm, the
      self-reference message fires 6 / 6 / 6 (M08's four shapes plus AC2's two)
      and the fold-self-reference message fires 3 / 0 / 0.
- [ ] AC5. M08's four shapes are unchanged in kind: the three single-target
      shapes index plainly, and `entry="Dogs" see="Dogs" see-also="Pets"` still
      emits `\index{Dogs|seealso{Pets}}` with no locator; `entry="Lynxes"
      see="Cats"` still emits its `see` target in both back-ends.
- [ ] AC6. `examples/self-xref.qmd` builds to PDF and its compiled index,
      read via `tests/pdfindex.py` and asserted in `tests/run-tests.sh` against
      a hand-derived manifest, carries `(0,'A'), (1,'B'), (2,'C, D')` and
      `(0,'M'), (1,'N'), (2,'O, P')` as consecutive outline rows, and no
      `Entry.text` among the five entries AC1 and AC2 name contains "see also"
      or "see ".
- [ ] AC7. The profile's `verify` slot is clean: `tests/run-tests.sh` and
      `tests/run-tests.sh --self-test` both pass on a clean checkout.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T4
- AC5 → T1, T5
- AC6 → T6
- AC7 → T7

## Tasks

- [x] T1. Extend `examples/self-xref.qmd` with the five new shapes (three fold,
      two empty) in their own section, and add the failing checks to
      `tests/run-tests.sh`: per-shape `\index{}` argument assertions, the HTML
      node assertions via `tests/htmlindex.py`, and per-format message counts
      replacing M08's single shared `check_warning_count ... 4` loop with
      per-format constants (`tests/run-tests.sh:2728`).
- [x] T2. Strip empty levels from both sides of the existing format-neutral
      self-target comparison (`_extensions/index/index.lua:727-737`).
- [x] T3. Add the LaTeX-only comparison after `clamp_levels`, inside
      `index_argument`'s caller (`_extensions/index/index.lua:770`), against
      the clamped printed path with empties stripped; drop the matching target
      before the encap is built.
- [x] T4. Author the fold-self-reference message per AC4, and add the
      three-way grep-key distinctness check.
- [x] T5. Re-verify M08's four shapes against their actual shipped behaviour,
      including `Dogs`' surviving see-also.
- [x] T6. Add the PDF render of `examples/self-xref.qmd` and its hand-derived
      index manifest (derivation comment is the oracle — M06 lesson).
- [ ] T7. Revert-the-fix discrimination probe for every new check, run only
      **after** the fix is committed (M08 lesson: `git checkout --` inside the
      probe destroys uncommitted work); record the observed failures in the
      work log.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: plan gate chose the hybrid comparison (format-neutral empty-strip plus a LaTeX-only post-fold pass) over moving the comparison wholly into the back-ends, because a back-end-local comparison stops diagnosing self-targets in gfm and every other back-end-less format, which DESIGN commits to ("a misused mark is diagnosed in every output format, not only where a back-end exists"); falsified by a format acquiring a level ceiling of its own, which would make the LaTeX-only pass the wrong home for the fold rule.
- 2026-08-18: plan gate chose dropping a fold-induced target over reporting and keeping it, because keeping it ships the useless "P, Q, R, S, see also P: Q: R, S" line M08's rule exists to prevent; falsified by evidence that authors rely on the emitted target surviving a fold they did not intend.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader both times. Round 1 returned 13 findings, none of the six criteria clean; nine were fixed silently and four became the gate's questions. Round 2 over the revised wording returned 16 findings, none clean; all were fixed except the suggested leading-empty probe, rejected because makeindex rejects a leading null field and the shape is an unfixed defect on its own candidate row.
- 2026-08-18: T1 — fixture extended with the five shapes and the checks added; both new check blocks run and fail pre-fix for the right reasons (all five expected plain `\index` arguments found 0 times, all five pre-fix self-encaps present, and both empty-level HTML entries still carrying their targets with no locator). The AC3 clauses passed pre-fix, as they must: HTML never had the defect.
- 2026-08-18: T2 — empty levels ignored on both sides of the format-neutral comparison. The self-reference count went 4 to 6 in latex, html and gfm alike, both empty-level shapes now emit a bare `\index` command, and the HTML check block passes in full (its AC3 clauses included). The three fold shapes are untouched, as expected: they are T3.
- 2026-08-18: T3/T4 — LaTeX-only comparison added after the fold, plus its message. `index_argument` now returns the clamped levels rather than the caller recomputing them, because `clamp_levels` warns and a second call would report the fold twice. Counts are 6/6/6 self-reference and 3/0/0 fold-self-reference, exactly AC4. The sort shape's report quotes the printed folded path `M!N!O, P`, not the filing path `m!n!o`.
- 2026-08-18: T5 — M08's four shapes verified against shipped behaviour by the full suite, whose M08-AC2 blocks are unchanged: the three single-target shapes index plainly and `entry="Dogs"` keeps `\index{Dogs|seealso{Pets}}` with no locator. Full suite green, 150 checks.
- 2026-08-18: T6 — PDF render and hand-derived assertion added. Both folded entries print at their three derived levels and none of the five M10 entries prints a cross-reference; the two entries that legitimately keep one (`Dogs, see also Pets`, `Lynxes, see Cats`) are asserted present, so the absence check cannot pass on an index that lost every cross-reference. Full suite green, 152 checks.
