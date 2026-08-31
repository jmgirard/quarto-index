<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M065: The forms a recovered chapter's marks take are fenced

- **Status:** review
- **Priority:** normal
- **Depends on:** M064
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m065-recovered-mark-forms` — PR #65 (https://github.com/jmgirard/quarto-index/pull/65)

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

- [x] AC1. In a whole-book render with the enriched chapter's store path held
      by a directory, the recovered section prints its multi-level `entry=`
      mark as a subentry under the parent term the mark names, and prints the
      parent term once.
- [x] AC2. In that same render, the mark carrying a declared `sort=` prints at
      the position its sort key gives it rather than the position its printed
      term would give it, and the two positions differ.
- [x] AC3. In that same render, the recovered `see=` mark and the recovered
      `see-also=` mark each print a cross-reference line naming its target,
      and neither prints a locator.
- [x] AC4. In that same render, the recovered `range=` pair prints one plain
      locator for the chapter's page — the locator either end alone would
      print, since neither end is resolved as a range — and the mark
      declaring `mention="principal"` prints the locator an undeclared role
      gets, with no principal styling: the degradation D-041 requires of a
      value no other process resolved.
- [x] AC5. A whole-book render in which one chapter's record carries a
      `version` this extension does not write prints that chapter's terms in
      their sections and draws the record-stale report once for that chapter,
      naming what recovery returned; a whole-book render in which the store
      directory itself cannot be read prints every chapter's terms and exits 0.
- [x] AC6. Against copies of the tree whose only change is, in turn, folding a
      recovered mark's levels to its first and dropping the recovered
      placement markers, AC1's section loses its sub-entry and a render with
      both marker-carrying chapters' store paths held by directories loses the
      section for the index no marker names, respectively; each of the two
      mutant renders runs to completion and exits 0.
- [x] AC7. `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
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
- [x] T5. `site/books.qmd` and `cairn/DESIGN.md` where the new evidence changes
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
- 2026-08-31: T5 — `site/books.qmd` states what recovery returns for the richer forms and grows a fifth not-returned bullet for the range pairing and the principal role, plus the store-directory case; `CHANGELOG.md` gains the same two facts under Unreleased; `cairn/DESIGN.md`'s recovery paragraph is corrected (it said recovery carries no declared sort key) and KI205 and KI214 narrow again, both now standing only where the store directory is absent or reads perfectly well.
- 2026-08-31: all tasks done; `tests/run-tests.sh --self-test` 1069 checks, exit 0. Status to review.

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

Fresh evidence, 2026-08-31, on `m065-recovered-mark-forms` at the pre-gate
checkpoint, PR #65. Both suite runs executed for this review: `tests/run-tests.sh`
579 ok lines / 578 checks, exit 0; `tests/run-tests.sh --self-test` 1069 checks,
exit 0. Driving RR is `—`, so there are no carried projections to set beside a
measured outcome.

- **AC1 — green.** In both renders of the held-record arrangement,
  `check_index_sections` matched all 21 rows of five.html's gamma section in
  rendered order: `Woodwork` at depth 0 with an empty locator field, `Joinery`
  under it at depth 1 linking to `four.html`, and one `Woodwork` row, so a
  parent printed per mark would fail on the row count and order. The check
  discriminates: the `m065-flatlevels` mutant, which folds a recovered mark's
  levels to its first, matches a 20-row manifest instead — the sub-entry gone
  and its parent holding the locator.
- **AC2 — green.** The same 21-row match carries the group headings, so
  `Zephyr` is asserted under the letter `A`, at the head of the section, where
  the `sort="Abacus"` its mark declares puts it; no `Z` heading appears in the
  section at all, so the two positions differ. The check discriminates: the
  `m065-nosorts` mutant, which drops the recovered sort keys, matches a
  manifest with `Zephyr` under `Z` at the tail.
- **AC3 — green.** In the same 21-row match, `Ferrule` carries an empty locator
  field and one `see-link` naming `Escutcheon`, and `Hasp` an empty locator
  field and one `also-link` naming `Escutcheon`. The manifest rows state the
  locator field and the cross-reference target separately, so a row printing a
  page beside its cross-reference fails on the locator field.
- **AC4 — green, both halves.** Range: in the same 21-row match `Ingot`, marked
  as the two ends of a range, is one row with one locator, `four.html` — the
  href either end alone would print. Role: `check_locator_role` reports the
  single locator link of `Jetty` printing in the plain role in both renders,
  against a control on the record route reporting the same term's locator
  printing in the principal role, so the class name the assertion turns on is
  shown able to appear. The range half is fenced by invariance: the
  `m065-carryrange` mutant carries `range=` into the recovered record and
  re-derives the pairing, and the section matches the same 21 rows unchanged.
- **AC5 — green, both arrangements.** Version-skewed record: with two.qmd's
  record moved to superseded version 3, the whole-book render prints all 15 of
  the book's terms across its 5 pages, each in the section the manifest names;
  the stale-record report is drawn exactly once and names two.qmd; the
  recovered `Bramble` links to `two.html` rather than to the anchor the refused
  record carried; and the render's whole warning output is 3 lines, each one the
  suite names. Unreadable store directory: with the store directory replaced by
  a regular file, the render exits 0, prints all 15 terms across all 5 pages,
  and draws exactly the 27 warnings the four record paths and one write per
  chapter account for — 20 recovery, 5 write-failure, 2 marker-position. The
  arrangement discriminates: the `m065-noprobe` mutant, which disables the
  store-directory probe, leaves the same broken store recovering nothing, each
  index holding only its own chapter's marks (2 printed terms, not 15) and the
  index no marker names printing on no page.
- **AC6 — green, both mutants.** Each is one substitution against a copy of the
  tree, `m061_mutant` failing the run if the substitution changed nothing.
  Levels folded to the first: the gamma section matches the 20-row manifest, so
  it loses AC1's sub-entry, and the render exits 0. Recovered placement markers
  emptied: with both marker-carrying chapters' store paths held by directories,
  the 5 rendered pages carry 2 index sections rather than 3 — the section for
  the index no marker names is gone — and the render exits 0.
- **AC7 — green.** Both runs executed sequentially for this review at the
  branch head: `tests/run-tests.sh` reported 578 checks passed, exit 0;
  `tests/run-tests.sh --self-test` reported 1069 checks passed, exit 0.

### Consistency gate

`cairn_validate.py` exit 0 — every check PASS, every advisory OK, the release
window advisory among them. No `DESIGN.md` principle changed on this branch, so
`cairn_impact.py` does not apply. The active profile is `generic`, whose
`consistency-gate` slot names no toolchain checks, so that half is a clean
no-op.

### Independent fresh-context review

The declared surface tier is user-facing and the diff touches executable
surface (`_extensions/index/modules/book.lua`, `tests/run-tests.sh`), so the
full three-lens fan-out ran, each lens fresh-context and with its own evidence
base. The [S] blame-history lens read `git log`/`git blame` on the modified
lines and reported no findings, naming five classes it checked clean. The [S]
prior-review lens read the archived `## Review` sections, `LESSONS.md` and the
Known-issues entries on the touched functions, ran the GitHub inline-comment
probe (empty, so the thread walk was skipped) and reported "no prior-review
evidence". The [O] diff-bug lens reported ten findings, ranked; all ten are
recorded below with their disposition.

Return floor: no finding demonstrates an acceptance criterion failing inside
the domain its wording quantifies over. F1 is the one that comes closest and is
put to the maintainer explicitly — AC5 quantifies over a store directory that
"cannot be read", and the state F1 names is one that reads (lists) perfectly
well, so it falls outside AC5 rather than falsifying it.

Findings, in the lens's own ranking:

- **F1 — the store-directory probe tests the read bit, but opening a record
  needs the search bit; the docs claim "permissions cleared" is covered.**
  Verified at review: on a store directory left `a-x` (read kept, execute
  cleared), `pandoc.system.list_directory` succeeds while `io.open` on a record
  inside it returns nil, so the probe reads the store as absent and every
  chapter silently loses its terms from every other chapter's index. On `chmod
  000` the listing fails and the probe fires correctly. The same family covers a
  single record file that exists and cannot be opened. **Disposition: fix the
  prose now** — `DESIGN.md`, `site/books.qmd` and `CHANGELOG.md` say what the
  probe actually tests (a store directory that cannot be listed) — **plus a
  Known-issues entry and a candidate row** for the wider present-but-unopenable
  predicate, which changes D-043's decided trigger and is plan work, not a
  review-side patch. Not a floor return: outside AC5's domain, and it narrows
  KI205 rather than regressing anything.
- **F2 — the milestone's central decision (declared, not resolved, sort keys)
  has no check that can fail.** The fixture gives every mark a term no other
  mark in the corpus indexes, and a shared printed level path across two
  chapters is the only arrangement in which a resolved key differs observably
  from a declared one. Verified: `register_recovered_sort` returns early on a
  nil value, so a resolved-key variant would register printed-text keys that
  match the declared fallbacks everywhere the fixture reaches, and the 21-row
  oracle would not move. **Disposition: follow-up candidate row.** Closing it
  needs a fixture term marked in two chapters, which the fixture's stated
  invariant forbids — a fixture change, not a review fix.
- **F3 — the `m065-carryrange` mutant is two substitutions behind one
  `cmp` guard, and asserts only invariance.** If the second substitution stops
  matching after a refactor, the first still fires, `cmp` still sees a change,
  and the mutant degrades to carrying `range=` without pairing while staying
  green. **Disposition: follow-up candidate row** — the guard belongs on
  `m061_mutant`, which every mutant in the suite uses. The invariance half was
  disposed of deliberately at the implement gate and is recorded there.
- **F4 — `examples/book-placement/index.qmd`'s stated fixture invariant is now
  false.** It says every term in the book is marked once, and `four.qmd` now
  marks `Ingot` twice as the two ends of a range. The diff made the sentence
  false. **Disposition: fix now** — narrow it to the cross-chapter property the
  sort-key work actually relies on.
- **F5 — "a report per chapter" undercounts the store-directory reports.** A
  broken store draws one report per reading-chapter/other-chapter pair — 20 for
  this five-chapter fixture, as the suite asserts — not 5. `site/books.qmd`
  corrects itself a few lines later; `CHANGELOG.md` does not. **Disposition:
  fix now** in `CHANGELOG.md`.
- **F6 — `site/books.qmd` offers a fix that applies to only one of the two
  cases it names.** "Taking away whatever stands in the directory's place"
  is no fix for a permissions case. **Disposition: fix now**, with F1's prose.
- **F7 — `m065_break_store` hard-codes the chapter count** (`[ "$held" = "5" ]`),
  so a sixth chapter would fail it with a message about a store short records.
  **Disposition: reject** — it fails loudly rather than silently, and the
  fixture's five-chapter count is pinned in dozens of manifests already, so this
  guard is not where that change would first be felt.
- **F8 — a dangling symlink at the store path fires recovery on a tree that was
  never rendered**, which is a literal counter-example to D-043's recorded
  falsifier. **Disposition: follow-up**, recorded in the same Known-issues entry
  as F1's remainder; Quarto never creates such a link, so it is not reachable
  by the route the extension supports.
- **F9 — no version guard on `pandoc.system.list_directory`.** Absent the
  function, both `pcall`s fail and the probe returns false — the pre-D-043
  behavior, safe and silent. **Disposition: reject** — not a defect on any
  Pandoc this extension supports.
- **F10 — prose and count slips.** (a) The suite comment at the `PLACE_TERMS`
  manifest says "eight of them four.qmd's six mark forms"; `Dovetail` is the
  pre-existing bare mark, so seven of the eight come from the forms —
  **fix now**. (b) `DESIGN.md`'s edited paragraphs carry ragged mid-sentence
  line breaks no other paragraph in the file has — **fix now**; the same
  finding's complaint about "narrowed M065" is **rejected**, since it matches
  the "narrowed M063, narrowed M064" convention the entry already uses. (c) The
  new `site/books.qmd` prose is not registered in the `books-claims.txt` set, so
  it is unguarded against drift — **follow-up candidate row**; M064's recovery
  prose is unregistered on the same footing, so this is a standing gap rather
  than one this diff opened.

- 2026-08-31: review — all seven criteria green on fresh evidence (578 checks
  plain, 1069 with `--self-test`, both exit 0), the consistency gate clean, and
  ten findings from the diff-bug lens; the blame-history and prior-review lenses
  none. No finding met the return floor. Dispositions above; the fix-now work
  and the durable records it writes land after the gate.

### Fix-now work at the gate

The maintainer chose fix-six-then-merge. Six corrections landed, none touching
executable behavior: `cairn/DESIGN.md`, `site/books.qmd` and `CHANGELOG.md` now
say the probe tests whether the store directory can be LISTED, and name a store
directory that still lists as read-as-absent (F1); `site/books.qmd` names both
repairs rather than the one (F6); its "a report per chapter" and the CHANGELOG's
are replaced by what the reports actually do (F5); `examples/book-placement/index.qmd`'s
invariant is narrowed to the cross-chapter property, since `four.qmd` now marks
`Ingot` twice (F4); the `PLACE_TERMS` comment's "eight of them four.qmd's six
mark forms" is corrected to seven from the forms plus the pre-existing
`Dovetail` (F10a); and the ragged mid-sentence line breaks in the edited
`DESIGN.md` paragraphs and in KI205/KI214 are rewrapped (F10b). `KI221` records
F1's remainder — a record file that exists and cannot be opened behind a store
directory that still lists — and F8's dangling-symlink mirror case.

Both suite legs were re-run against the edited fixture and comment:
`tests/run-tests.sh` 578 checks, exit 0; `tests/run-tests.sh --self-test` 1069
checks, exit 0. `cairn_validate.py` re-run over the completed edits, exit 0.
- 2026-08-31: gate — maintainer chose fix-six-then-merge; the six corrections landed, KI221 written, and both suite legs plus `cairn_validate` re-run green over them.
