<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M065: The forms a recovered chapter's marks take are fenced

- **Status:** planned
- **Priority:** normal
- **Depends on:** M064
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** —

## Goal

The source-recovery route M064 ships is held to the mark forms an author
actually writes and to every way a record goes unusable, rather than to the one
bare form and the one cause M064's fixture carries.

## Scope

Surface tier: **user-facing** — what is fenced here is the index a reader of an
authored book reads, in the shapes authors write.

**In:**

- Fixture growth in `examples/book-placement/`: the chapters whose records the
  suite makes unusable gain a multi-level `entry=` mark, a mark with a declared
  `sort=`, a `see=` mark and a `see-also=` mark, a `range=` pair, and a mark
  declaring a mention role — each on a term no other mark in the corpus
  indexes, since the sort-key registry keys on the printed level path (the M13
  lesson, extended M56).
- Criteria over what the recovered section prints for each of those forms.
- The two remaining ways a record goes unusable: a version-skewed record, and a
  store directory that cannot be read at all.
- The two store reports' counts and clauses once recovery has run.
- Per-field mutants, so each recovered field is fenced on its own rather than
  by one kill-switch.

**Out:**

- An include-borne mark and a mark in content the HTML render drops → their
  absence is documented by M064-AC6 and stays a known issue; fencing them needs
  a fixture that renders an include, which this book does not have.
- A fragment for a recovered mark, cross-chapter range pairing, and recovering
  a chapter's resolved role → M064's Out, unchanged; D-009 and D-021 stand.
- Recovery on an absent record → the candidate row M064 leaves.

## Acceptance criteria

- [ ] AC1. In a whole-book render with the enriched chapter's store path held
      by a directory, the recovered section prints its multi-level `entry=`
      mark as a subentry under the parent term the mark names, and prints the
      parent term once.
- [ ] AC2. In that same render, the mark carrying a declared `sort=` prints at
      the position its sort key gives it rather than the position its printed
      term would give it, and the two positions differ.
- [ ] AC3. In that same render, the `see=` mark prints its cross-reference line
      naming its target and no locator, and the `see-also=` mark prints its
      line beside its own locator.
- [ ] AC4. In that same render, the recovered `range=` pair prints as two plain
      locators rather than one range, and the mark declaring a mention role
      prints with the locator an undeclared role gets — the degradation D-009
      and D-021 require of a value no other process resolved.
- [ ] AC5. A whole-book render in which one chapter's record carries a
      `version` this extension does not write prints that chapter's terms in
      their sections and draws the record-stale report once for that chapter,
      naming what recovery returned; a whole-book render in which the store
      directory itself cannot be read prints every chapter's terms and exits 0.
- [ ] AC6. Against copies of the tree whose only change is, in turn, dropping
      the recovered levels and dropping the recovered marker, AC1's section
      loses its subentry and AC5's version-skewed render loses that chapter's
      terms respectively; every mutant render runs to completion and exits 0.
- [ ] AC7. `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T4
- AC7 → T1, T2, T3, T4, T5

## Tasks

- [ ] T1. Grow the fixture's blocked chapters with the six mark forms, each on
      a term no other mark in the corpus indexes, and re-baseline every
      manifest the new marks move.
- [ ] T2. Criteria AC1-AC4 as suite checks over the recovered section.
- [ ] T3. The version-skewed record case and the unreadable store directory
      case, with their report counts and clauses.
- [ ] T4. The two per-field mutants under `--self-test`.
- [ ] T5. `site/books.qmd` and `cairn/DESIGN.md` where the new evidence changes
      what is claimed; the KI dispositions this milestone closes or narrows.

## Work log

- 2026-08-30: created by /milestone-plan, as the second half of the M064 split.
- 2026-08-30: plan gate chose splitting this from M064 over one milestone carrying both, which crossed both split tripwires and the 150-line cap, and over one milestone with a narrower promise that refuses the richer mark forms outright and ships a documented hole; falsified by M064 landing and this work proving to be a handful of manifest edits rather than a sitting.
- 2026-08-30: criteria audit ran in FULL mode ([O], fresh context, user-facing tier) over M064's draft; findings 5, 6 and 10 — one exemplar standing in for the recovered-form family, and one unusable-record cause standing in for four — are what this milestone exists to answer.

## Decisions

## Review
