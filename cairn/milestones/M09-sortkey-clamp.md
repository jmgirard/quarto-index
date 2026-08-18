# M09: Sort keys under the LaTeX level clamp

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** m09-sortkey-clamp

## Goal

Two entries whose printed level paths differ before makeindex's three-level fold
and agree after it are recognized as contesting one printed path, rather than
reaching makeindex as two keys and printing the entry twice with nothing said.

## Scope

Surface tier: **user-facing** — the deliverable is a warning an author reads,
guarding an index a reader receives.

Sort keys are registered against unclamped printed level paths
(`register_sort`, index.lua:624; resolved unclamped at index.lua:686), while
`index_argument` folds levels past the third only at emission (index.lua:437).
An entry written with four levels and one written with three whose third spells
the folded form therefore reach makeindex as `alpha!beta!ZKEY@gamma, delta` and
`alpha!beta!AKEY@gamma, delta` — two keys, one printed path, no report — and the
entry prints twice, identically, in two places. Confirmed by render at plan time.

**In:**
- Reporting two distinct LaTeX index keys that share one printed level path.
- Fixtures covering the one-side-clamped and both-sides-clamped shapes, plus a
  same-key twin, with LaTeX, HTML and compiled-PDF evidence.

**Out:**
- Any change to the HTML back-end's entry tree: it applies no level ceiling, so
  the two entries are genuinely two there, and AC2 pins that they stay so.
- The printed-text collision that predates sort keys (two entries folding to one
  printed form with no sort key at all) → stays the candidate row it is; this
  milestone reports the sort-key case, which is the one makeindex splits.

## Acceptance criteria

- [ ] AC1: In a LaTeX render of `examples/sortkey-clamp.qmd`, which holds two
      pairs of entries whose printed level paths differ before the three-level
      fold and are identical after it — one pair written as four levels against
      three whose third spells the folded form, one pair written as two
      four-level entries folding to one third level — each pair carrying two
      different sort keys, exactly two warnings appear per render, one per pair,
      each naming that pair's two sort keys and the printed level path they
      contest.
- [ ] AC2: In an HTML render of the same fixture, none of those warnings
      appears, and all four entries remain distinct at their unfolded level
      paths, the index's entries and level paths pinned by a hand-derived
      manifest — derived through the entries' sort keys, which is what orders
      them, not their printed text.
- [ ] AC3: In a LaTeX and an HTML render of `examples/sortkey-clamp-twin.qmd`,
      differing only in that each pair's two entries carry one shared sort key
      (chosen to differ from either entry's third-level printed text, since
      `index_argument` compares a key against the *unclamped* level at
      index.lua:449), no such warning appears, the `.tex` writes each pair under
      one makeindex key, and the PDF built from it prints each pair's entry once.
- [ ] AC4: `tests/run-tests.sh --self-test` clean (the `verify` slot).

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T1, T2, T4
- AC4 → T1, T3, T4

## Tasks

- [x] T1: Add `examples/sortkey-clamp.qmd` (both pairs, rival keys) and
      `examples/sortkey-clamp-twin.qmd` (shared keys, each differing from the
      entries' third-level printed text — state that constraint in the fixture
      prose); add the AC1 and AC3 `.tex` checks to `tests/run-tests.sh`, failing.
- [x] T2: Report two distinct LaTeX index keys sharing one printed level path,
      in the document-wide LaTeX pass beside the existing multi-encap report
      (index.lua:1815 neighborhood), naming both sort keys and the path.
- [ ] T3: Hand-derive the HTML manifest for `sortkey-clamp.qmd` and add the AC2
      check; the derivation comment is the manifest's oracle, so it is written
      for these rows rather than borrowed from another manifest.
- [ ] T4: Build the twin's PDF and pin that each pair's entry prints once,
      following the existing PDF checks (run-tests.sh:1968, :2853).
- [ ] T5: Revert the fix and record the failing check and its message in the
      work log. Process evidence, deliberately mapped to no criterion — a
      criterion binding the harness rather than the emitted output is the
      instrument-bound shape the plan audit rejected.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader; it confirmed the premise by building the fixture and rendering it (two makeindex keys, one printed path, nothing reported) and returned AC1 probing only the one-side-clamped shape (both-clamped pair added), AC3 holding only while the shared key differs from the third-level printed text (constraint stated), and every criterion stopping at the .tex though the symptom is a doubled entry in the built index (AC3 extended to the compiled PDF under GP6, T4 added); AC2 passed every question unchanged.
- 2026-08-18: plan chose reporting the collision over keying the sort registry on clamped level paths, because the registry is format-neutral and filled before the back-end branch while the three-level fold is a makeindex property the HTML back-end does not share; falsified by a case where the collision is mechanically resolvable — the two entries genuinely being one entry — rather than an authoring mistake only the author can settle.
- 2026-08-18: implement started on branch m09-sortkey-clamp.

- 2026-08-18: T1 — both fixtures added and the AC1/AC3 `.tex` checks written, with a by-construction check tying the twin to the fixture (same entries, one shared key per pair, each pair folding to one printed path, each shared key differing from both its entries' third level). The LaTeX render confirms the defect as planned: the fixture emits `alpha!beta!Zed@gamma, delta` and `alpha!beta!Ada@gamma, delta`, plus `mu!nu!Wye@xi, omicron, pi` and `mu!nu!Vee@xi, omicron, pi` — two keys per printed path — and the AC1 count check reports 0 occurrences of the report against 2 wanted. The twin already emits one key per pair, so its `.tex` check passes ahead of the fix.

- 2026-08-18: T2 — the report lands in the document-wide LaTeX pass beside the multi-encap one, once per contested printed path, naming every key filed under it; `index_argument` now also returns the printed and filing paths it emitted. Full suite green (143 checks), the two AC1 reports firing as hand-derived and no other fixture newly warning.

## Decisions

### 2026-08-18: the report compares filing paths, not emitted arguments

Two entries contest one printed path when the index tool reads two different
keys for it, which is not the same as their two `\index` arguments differing
as strings: a level whose resolved key equals its own printed text emits
`key@text` where the key was written for the unfolded level and a bare `text`
where it was not, and those two arguments are one key to the index tool.
Comparing arguments would report that pair as a collision it is not. So
`index_argument` returns the filing path it actually emitted — per level, the
key where it wrote a sort field and the clamped printed text where it did not
— and the report compares those.

## Review
