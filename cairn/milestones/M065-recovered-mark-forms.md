<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M065: The forms a recovered chapter's marks take are fenced

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M064
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m065-recovered-mark-forms`

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
- [ ] AC3. In that same render, the recovered `see=` mark and the recovered
      `see-also=` mark each print a cross-reference line naming its target,
      and neither prints a locator.
- [ ] AC4. In that same render, the recovered `range=` pair prints one plain
      locator for the chapter's page — the locator either end alone would
      print, since neither end is resolved as a range — and the mark
      declaring `mention="principal"` prints the locator an undeclared role
      gets, with no principal styling: the degradation D-041 requires of a
      value no other process resolved.
- [ ] AC5. A whole-book render in which one chapter's record carries a
      `version` this extension does not write prints that chapter's terms in
      their sections and draws the record-stale report once for that chapter,
      naming what recovery returned; a whole-book render in which the store
      directory itself cannot be read prints every chapter's terms and exits 0.
- [ ] AC6. Against copies of the tree whose only change is, in turn, folding a
      recovered mark's levels to its first and dropping the recovered
      placement markers, AC1's section loses its sub-entry and a render with
      both marker-carrying chapters' store paths held by directories loses the
      section for the index no marker names, respectively; each of the two
      mutant renders runs to completion and exits 0.
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

- [x] T1. Grow the fixture's blocked chapters with the six mark forms, each on
      a term no other mark in the corpus indexes, and re-baseline every
      manifest the new marks move.
- [x] T2. Criteria AC1-AC4 as suite checks over the recovered section, and the
      recovery change AC2 needs: a recovered record carries the chapter's
      declared sort keys.
- [x] T3. The version-skewed record case and the unreadable store directory
      case, with their report counts and clauses.
- [x] T4. The per-field mutants under `--self-test`: the two AC6 names, one
      dropping the recovered sort keys, one carrying `range=` and its
      re-derived pairing into a recovered record, asserted to leave the
      recovered section unchanged, and one disabling the store-directory
      probe, asserted to leave every chapter's index short every other
      chapter's terms.
- [ ] T5. `site/books.qmd` and `cairn/DESIGN.md` where the new evidence changes
      what is claimed; the KI dispositions this milestone closes or narrows.

## Work log

- 2026-08-30: created by /milestone-plan, as the second half of the M064 split.
- 2026-08-30: plan gate chose splitting this from M064 over one milestone carrying both, which crossed both split tripwires and the 150-line cap, and over one milestone with a narrower promise that refuses the richer mark forms outright and ships a documented hole; falsified by M064 landing and this work proving to be a handful of manifest edits rather than a sitting.
- 2026-08-31: probe render of the enriched fixture, on the record route and the recovered route, settled what each of the six forms actually prints; AC1 and AC4's role half already hold, AC2's sort key does not survive recovery, and AC3's and AC4's planned clauses were false of the extension.
- 2026-08-31: amendment return: AC3 — "the recovered `see=` mark and the recovered `see-also=` mark each print a cross-reference line naming its target, and neither prints a locator."
- 2026-08-31: amendment return: AC4 — "the recovered `range=` pair prints one plain locator for the chapter's page — the locator either end alone would print, since neither end is resolved as a range — and the mark declaring `mention=\"principal\"` prints the locator an undeclared role gets, with no principal styling: the degradation D-041 requires of a value no other process resolved."
- 2026-08-31: criteria audit ran in FULL mode ([O], fresh context, user-facing tier) over the amended AC3 and AC4, twice; round 1 returned four findings (neither mark named as recovered, `mention="principal"` unnamed, an appositive deferring the promise to a docs page, and a vacuous range clause) and round 2 one (the range clause still unfalsifiable, and D-009/D-021 mis-cited for a within-chapter pair). All disposed in the wording above; T4 grew a range-invariance mutant, criteria set unchanged.
- 2026-08-30: criteria audit ran in FULL mode ([O], fresh context, user-facing tier) over M064's draft; findings 5, 6 and 10 — one exemplar standing in for the recovered-form family, and one unusable-record cause standing in for four — are what this milestone exists to answer.
- 2026-08-31: task order — T2's code half runs before T1, so the fixture's manifests are baselined once against the behavior they will ship with rather than twice.
- 2026-08-31: `recover_record` carries the chapter's declared sort keys, in `build_record`'s declared-key-per-printed-path shape, first mark in document order winning; a recovered `Zephyr` written `sort="Abacus"` now files under A as it does on the record route. Suite 562 checks, exit 0.
- 2026-08-31: T1 — four.qmd gained seven forms in eight marks (`entry="Woodwork!Joinery"`, `sort="Abacus"` on Zephyr, `see=`, `see-also=`, a `range=` pair, `mention="principal"`), each on a term no other mark in the book indexes; the five term manifests carrying four.qmd's share of `gamma` re-baselined from four entries to eleven, and `m064_hide_only_mark` became `m064_hide_all_marks`, wrapping the chapter's whole body so the no-marks cases still reach no mark. Suite 562 checks, exit 0.
- 2026-08-31: T2 — the blocked render's whole gamma section is held row by row in the href form (`check_index_sections`), which settles AC1's sub-entry and its once-printed parent, AC2's `Zephyr` under the letter A rather than Z, AC3's two empty locator fields beside their cross-reference rows, and AC4's single plain locator for the range pair; a new `check_locator_role` settles AC4's role half against the record route's own principal locator as its control. Shown red on all three defect classes it claims to catch — a recovered locator asserted principal, a record-route locator asserted plain, and an entry with no locator at all — and green on both controls. Suite 567 checks, exit 0.
- 2026-08-31: correcting two work-log lines above: the 2026-08-31 lines beginning `amendment return: AC3` and `amendment return: AC4` are written in the shape `/milestone-review` reserves for an amendment executing a defect return from review. No review has run on this milestone and neither amendment is a return; both were made at the implement question gate. The lines stand as history (IP4); the amendment-return count for this milestone is zero.
- 2026-08-31: T3 — AC5's two arrangements. The version-skewed record is planted on two.qmd, so index.qmd, which renders first and builds the section that chapter's term belongs to, is the one chapter that meets it: three warnings, `Bramble` recovered and linking to two.qmd's page rather than to the anchor the refused record carried. The store directory replaced by a regular file draws 20 recovery, 5 write-failure and 2 marker-position warnings, exits 0, and prints every term the book marks.
- 2026-08-31: AC6 amended at a mini gate — its second clause named an effect its mutant cannot produce, since the chapter AC5's version-skewed render refuses carries no placement marker and a marker moves where a section prints rather than which terms it holds. Criteria audit ran in FULL mode ([O], fresh context, user-facing tier) over the amended wording and returned four findings: an unbounded trailing quantifier and a referent reaching outside the file, both fixed in the wording; AC5's two routes losing their planted-defect coverage, answered by a fifth T4 mutant over the store-directory probe; and AC6 binding an instrument property without saying so, which is the shape the gate chose deliberately and is recorded here rather than in the criterion.
- 2026-08-31: D-043 written — an existing-but-unlistable store directory is told apart from an absent record, so every chapter is recovered from its source rather than silently dropped. Suite 578 checks, exit 0.
- 2026-08-31: T4 — five per-field mutants, each one substitution against a copy of the tree: folding a recovered mark's levels to its first loses the sub-entry and gives its parent the locator; emptying the recovered markers leaves the held-pair render with no section for the index no marker names; dropping the recovered sort keys moves `Zephyr` from the head of the section to its tail; carrying `range=` and a re-derived pairing leaves the section exactly as it stands; and disabling the store-directory probe leaves every index holding its own chapter's marks alone. Suite 1069 checks with `--self-test`, exit 0.

## Decisions

- 2026-08-31: a recovered record carries the chapter's DECLARED sort keys.
  M064 left them out, so a term written to file under a key filed under its
  printed text whenever the store failed and under the author's key otherwise
  — a difference in a book's index no author asked for. A declared `sort=` is
  a value the author typed, so it sits inside D-041's boundary exactly as the
  printed levels and the cross-reference targets do; what stays outside is the
  RESOLVED key, which has this chapter's fallbacks filled in and is that
  chapter's own conclusion (D-009, D-021) — the same reason `build_record`
  writes declarations rather than resolutions. Rejected: leaving the keys out
  and narrowing AC2 to the degradation, which is cheaper and ships the
  inconsistency.

## Review
