# M073: A store report names the record it met as the record it was

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1
- **Resolves:** —
- **Branch/PR:** `m073-store-report-wordings` / https://github.com/jmgirard/quarto-index/pull/73

## Goal

In an HTML book, a record no render has written whose chapter's source also
cannot be read is reported as one no render has written rather than as one that
could not be read, and a record file that decodes to a table carrying no
version number this render recognizes is reported as one that could not be read
rather than as one another version of this extension wrote.

## Scope

Surface tier: **user-facing** — the deliverable is the warning text an
installed extension prints to an author, and the site prose about it.

**In:** the two record states the code mis-names. A sixth wording for a
never-written record whose chapter source cannot be read, drawn where the other
never-written wordings are drawn today; and a version test that fires only on a
record carrying a version number this render does not write, so a truncated or
hand-emptied record joins the wordings for a record that could not be read.
The superseding decision each change needs, the site and changelog prose, and
the suite legs and planted defects for both.

**Out:** where the never-written reports are drawn and how often → M074.
The n(n-1) source parsing a store-less book pays (KI227) → stands.
The `first == nil` gate half never exercised for a refused entry (KI237) →
stands as its known issue.

## Acceptance criteria

- [x] AC1: In an HTML book, a chapter that reads the store, meets a record no
      listing of the store directory carries, and cannot read that chapter's
      own source draws a report naming the chapter, saying no render has
      written a record for it and that its source could not be read either;
      the message is neither equal to nor a prefix of any other `warn()`
      message in the filter source, which `tests/scans/warn-distinct.py`
      holds. Evidence: the `m069-lostsource` leg (`tests/run-tests.sh:9071`)
      counts the new wording's grep key once and `WARN_STORE_UNREADABLE_LOST`
      zero times.
- [x] AC2: A record that WAS written, cannot be decoded, and whose chapter's
      source also cannot be read keeps the wording naming both. Evidence: a
      new leg over a copy of `examples/book-placement` that overwrites one
      chapter's record with bytes that do not decode as JSON and breaks that
      same chapter's source, rendering one named other chapter alone, counts
      `WARN_STORE_UNREADABLE_LOST` once and AC1's key zero times.
- [x] AC3: A record file that decodes to a JSON table whose `version` field is
      absent, and one whose `version` is not a number, are both reported by
      the wordings for a record that could not be read and by none of the
      three different-version wordings. Evidence: three new legs over a filled
      `examples/book-extensions` copy rewriting `one.qmd`'s record — the
      `version` field deleted and every other field left as written, `version`
      as a string, `version` as a boolean — each rendered from `index.qmd`
      alone, counting the three `WARN_STORE_STALE_*` keys at zero and
      `WARN_STORE_UNREADABLE_RECOVERED` at one.
- [x] AC4: A record carrying a numeric `version` this render does not write is
      still reported as one a different version of this extension wrote, at
      the count it has now. Evidence: the `m072` `version` leg
      (`tests/run-tests.sh:24505`) passes with its counts unchanged.
- [x] AC5: The store-reports section of `site/books.qmd` and the unreleased
      section of `CHANGELOG.md` state the wording set and the version-field
      partition as the shipped code has them: a grep over those two regions
      returns no sentence saying a record carrying no version is read as one
      another version wrote, and the books page's claim ledger
      (`tests/run-tests.sh:21763`) carries a row for each sentence added.
- [x] AC6: `tests/run-tests.sh` passes; `tests/run-tests.sh --self-test`
      passes, and its M073 battery shows red against the pre-fix code each
      plant names: (a) the never-written-and-unreadable-source branch
      collapsed back into the shared could-not-be-read wording, (b) the
      classification test at `book.lua:1008` restored to
      `data.version ~= STORE_VERSION`, pinned by its `ok and type(data) ==
      "table"` context rather than by the same text in `valid_record`, and
      (c) that test made nil-only, so a non-number version still reads as
      skew.

## Coverage

- AC1 → T1, T4
- AC2 → T4
- AC3 → T2, T4
- AC4 → T2, T4
- AC5 → T6, T8
- AC6 → T5, T7

## Tasks

- [x] T1: Add the sixth wording in `store_read`
      (`_extensions/index/modules/book.lua:1057-1071`) on the
      `never_written and rebuilt == nil` path, sharing no prefix with the five
      standing wordings; add its grep key beside the others
      (`tests/run-tests.sh:871-889`) and raise `warn-distinct.py`'s
      `EXPECTED` 83 → 84 with its own arithmetic line.
- [x] T2: Narrow the classification test at `book.lua:1008` to a record whose
      `version` is a number other than `STORE_VERSION`; leave `valid_record`
      (`book.lua:365`) alone, so a decoded table with no version still fails
      validation and takes the unusable path.
- [x] T3: Re-read all six store wordings and the prose naming their states
      against the narrowed sets, per the M38 lesson — a clause goes false in
      silence when what it is computed over changes.
- [x] T4: Suite legs: extend `m069-lostsource`'s assertions (AC1); the
      undecodable-plus-broken-source leg over `examples/book-placement`
      (AC2); the three version-form legs over `examples/book-extensions`
      (AC3), reading `STORE_VERSION` through `run_scan store-version` rather
      than spelling it (the M06 lesson). Hand-derive every count.
- [x] T5: The three planted defects of AC6 under `--self-test`, each shown red
      before its fix, each a single substitution (`spliced_copy` fails a
      zero-match plant).
- [x] T6: `site/books.qmd`, `CHANGELOG.md`, the books claim-ledger rows, and
      the recovery prose plus KI230 and KI236 in `cairn/DESIGN.md`.
- [x] T7: Full `tests/run-tests.sh` and `--self-test` runs; D-entry
      superseding D-045's clause that a never-written record whose source
      cannot be read draws the existing wording for that outcome, and
      recording the version-field partition.

Added after the review return of 2026-09-03, one per finding disposed to
implement:

- [x] T8: `site/books.qmd` — the clarifying clause on why the never-written
      report names the source alone (F5), and claim-ledger rows for that clause
      and for the sentence saying why the wording for a record that WAS written
      is not reused on this path (F1, AC5's failing clause); the claim-list
      self-test's pinned row count 37 → 39.
- [x] T9: `cairn/DESIGN.md`'s recovery paragraph corrected in place (F2): six
      wordings rather than five, the one added here named among them, and the
      version clause narrowed to a `version` this render reads as a number.
- [x] T10: The draw site the narrowing moved (F3, F4): two `one.qmd` legs over
      a record carrying no version — an ordinary chapter's and the refused
      notebook chapter's — each shown red under the wide-test plant read on the
      count axis, and the changelog sentence stating the move.
- [x] T11: Plant hygiene (F6, F8, F9, F10): the AC2 plant's overwrite guard,
      the version plant's comparison made one that can fail and its
      `encoding='utf-8'`, and the boolean nil-test plant's missing zero
      companion.
- [x] T12: D-051 recording the reassignment F3 and F4 found unstated; a
      candidate row for the suite-wide zero-control sweep (F11).
- [x] T13: Full `tests/run-tests.sh` and `--self-test` runs over the repaired
      tree.

## Work log

- 2026-09-03: created by /milestone-plan, promoting the held store-reports candidate row (its KI230 and KI236 halves); the other two halves are M074.
- 2026-09-03: plan gate chose a sixth wording, drawn where the never-written wordings already are, over reusing the could-not-be-read wording, because the latter asserts a record existed; falsified by an author reporting the two states read the same to them.
- 2026-09-03: plan gate chose reading a versionless record as one that could not be read over giving it a wording of its own, because a seventh sentence buys a distinction no author acts on differently; falsified by an author reporting they needed to know the file held a record's bytes rather than a damaged record.
- 2026-09-03: implement gate chose the sixth wording's own opening clause over sharing the never-written recovery wording's, because that clause is the grep key the suite counts that report by and a shared opening would make one key count both; falsified by an author reporting the two never-written reports read as unrelated to them.
- 2026-09-03: criteria audit ran in full mode over two passes ([O], fresh context); pass 1 returned four instrument-bound criteria and one unreachable approach, pass 2 returned eight findings over the rewrite — an unenumerable "opening" clause, two counts stated per render that are per reading chapter, `{}` conflating two probe forms, an ambiguous plant site, a missing nil-only plant, and two documentation promises over whole files — all disposed into the criteria above.

- 2026-09-03: T1-T3 — the sixth wording added on the `never_written and rebuilt == nil` path with its own opening clause, its grep key beside the others, `warn-distinct.py`'s EXPECTED 83 → 84; the classification test narrowed to `type(data.version) == "number"`; `valid_record` left alone with a note saying the divergence is deliberate.
- 2026-09-03: T3 re-read found the M072 `refusefirst` plant's needle sitting on the line the narrowing moved, and KI216's clause saying no route recovers an `output-file:` chapter's terms, false since M069 — the plant re-anchored, KI216 corrected in place, a candidate row added for where that recovered locator points.
- 2026-09-03: T4 — `m069-lostsource` re-pointed at the new wording (AC1); the undecodable-record-plus-broken-source leg over `examples/book-placement` (AC2); the three version-form legs over a copy of the filled `examples/book-extensions` store, reading `STORE_VERSION` through `run_scan store-version` (AC3). All counts hand-derived.
- 2026-09-03: T5 — three plants under `--self-test`: the new branch made unreachable, the version test back to inequality alone, and the same test narrowed to nil rather than to a number; the third is run over all three version forms, the deleted-version form staying green under it being the point.
- 2026-09-03: T6 — `site/books.qmd`, `CHANGELOG.md`, four claim-ledger rows, KI230 and KI236 marked resolved in place.
- 2026-09-03: T7 — D-050 recorded. Suite runs 1-4 each surfaced one defect in this milestone's own additions: the two self-test renders missing their `capture` calls (M24 scan), the claim-list self-test's pinned row count 33 → 37, and the M070 `lostwording` plant asserting the old wording over a cold tree, where the never-written one is now the true report. Run 1 was invalid — the script was edited while it ran; see the LESSONS line.
- 2026-09-03: `tests/run-tests.sh --self-test` exits 0, all 1260 checks passed (run 5, tree at 79f2855).
- 2026-09-03: review returned M073 to in-progress — AC5's clause requiring the books-page claim ledger to carry a row for each sentence added fails: `site/books.qmd:178` is added and unpinned. AC1-AC4 and AC6 verified with fresh evidence (suite 675 checks, self-test 1260 checks, both exit 0); consistency gate clean. Nine further findings logged in the Review section, F2 (DESIGN.md still states five wordings and the falsified version clause) and F3 (the versionless record's report count moved, untested and not in the changelog) the substantive ones.
- 2026-09-03: return gate chose leaving AC1/AC4/AC5's drifted line citations as recorded over amending them, and holding the criteria set while covering the moved report count with a test leg, a changelog sentence and a D-entry, over adding a seventh criterion for it.
- 2026-09-03: CHECKPOINT, tasks not ticked — T8-T13 added for the review's implement-bound findings and every edit written (books page clause and two ledger rows, DESIGN.md paragraph corrected in place, two one.qmd count legs with their wide-test plants, four plant-hygiene fixes, D-051, the zero-control candidate row), but the full suite and self-test are still running, so no task is checked off yet. cairn_validate: all 16 checks PASS, the sizing advisory now WARNs at 13 tasks — the return's repair tasks, not a milestone that grew a second goal.
- 2026-09-03: T8 — the books page's clause on why the never-written report names the source alone, and two claim-ledger rows: one for that clause, one for the sentence AC5's ledger clause failed on; the claim-list self-test's pinned count 37 → 39, and `sitecheck.py claims` green over all 39.
- 2026-09-03: T9 — the DESIGN.md recovery paragraph corrected in place: six wordings, the M073 one named among them, the version clause narrowed to a `version` this render reads as a number, and the moved draw site stated.
- 2026-09-03: T10 — two `one.qmd` legs over a record carrying no version, planted on `two.md` and on `five.ipynb`, the plant helper parametrized by chapter; both shown red under a fourth wide-test plant that renders `one.qmd` and asserts every count at zero. Changelog sentence for the move.
- 2026-09-03: T11 — the AC2 plant given the `[ -f ]` guard its siblings carry; the version plant's pre-image read from the file rather than shallow-copied from the object it mutates, and `encoding='utf-8'` on every open; the boolean nil-test plant given the zero companion the string form asserts.
- 2026-09-03: T11 evidence — the old comparison was blind to a nested mutation only, not to every mutation as the finding stated: `dict(record)` is a shallow copy, so a top-level reassignment was already red. Run out of tree over the helper's own body, the old form stayed green on `marks[0].term` changed and the new form is red on it, and both are red on a top-level field.
- 2026-09-03: T12 — D-051 recording the reassignment; the zero-control candidate row added, search-first over the candidates finding no overlap.
- 2026-09-03: T13 — `tests/run-tests.sh` exits 0, 680 checks passed; `tests/run-tests.sh --self-test` exits 0, 1268 checks passed. cairn_validate: all 16 checks PASS, 7 advisories, the sizing one now WARNing at 13 tasks — six of them the review return's repairs, not a second goal.
- 2026-09-03: review round 2 gate chose fixing all seven confirmed findings on the branch and then merging, over fixing the two code comments alone or merging as it stands.
- 2026-09-03: CHECKPOINT — round 2's seven fixes written (both book.lua state enumerations, the DESIGN.md ordinals restored so the refusal is the fifth wording again and M073's the sixth, the books page's numeric-version qualifier, D-052 correcting D-050's family count, the store key-count comments back to a monotone 7-8-9, two claim-ledger rows taking the pinned count 39 → 41); the gating suite and self-test runs are still in flight, so the approval marker is unwritten and nothing is merged.
- 2026-09-03: round 2's seven fixes verified — `tests/run-tests.sh` exits 0, 680 checks; `--self-test` exits 0, 1268 checks; claim ledger 41 rows, warn-distinct 84 messages.
- 2026-09-03: step-7 approval: PR #73 approved for merge
- 2026-09-03: review opened — branch pushed, draft PR #73; consistency gate clean (cairn_validate 16 PASS / 7 advisories OK; generic profile names no toolchain checks; no principle changed, so no impact scan). Criteria evidence pending the full suite and self-test re-run.

## Decisions

## Review

Evidence dated to the tree at `f4dd721`; a re-review re-runs it.

**Runs.** `tests/run-tests.sh` exits 0, 675 checks passed.
`tests/run-tests.sh --self-test` exits 0, 1260 checks passed. An earlier
`--self-test` invocation died at an M14 gfm render with `Segmentation fault:
11` inside Quarto's Deno binary, ~570 checks in and nothing to do with the
store; the re-run above passed the same leg, so it was an environment flake.

**AC1 — verified.** The `m069-lostsource` leg counts the new wording's grep key
`WARN_STORE_NEVER_LOST` once and `WARN_STORE_UNREADABLE_LOST` zero times, and
asserts the report names `four.qmd`; `WARN_STORE_NEVER_RECOVERED` stays at 3,
so the new opening clause is its own. `tests/scans/warn-distinct.py` passes at
84 messages, mutually distinct as whole messages and under its prefix check.

**AC2 — verified.** The new `m073-undecodable` leg (a written record whose
bytes do not decode, over a copy of `examples/book-placement` whose `four.qmd`
source is also broken, `five.qmd` rendered alone) counts
`WARN_STORE_UNREADABLE_LOST` once naming `four.qmd`, `WARN_STORE_NEVER_LOST`
zero, and the three other store wordings zero; `five.html` does not carry
`Dovetail`, so nothing was recovered.

**AC3 — verified.** The three `m073_version_form` legs — `version` deleted,
`version` as the string `"4"`, `version` as a boolean — each render
`index.qmd` alone over a copy of the filled `examples/book-extensions` store.
Each counts the three `WARN_STORE_STALE_*` keys at zero and
`WARN_STORE_UNREADABLE_RECOVERED` at one naming `one.qmd`, with the plant
asserting the record differs from the written one in the `version` field
alone. `STORE_VERSION` is read through `run_scan store-version`, not spelled.

**AC4 — verified.** The `m072` `version` leg is untouched by this branch
(`git diff origin/main...HEAD -- tests/run-tests.sh` shows no change in it) and
passes with its counts unchanged: the refusal drawn once by the chapter that
builds a section, not at all by the chapter that builds none.

**AC5 — FAILED, on its claim-ledger clause.** The grep clause passes: neither
`site/books.qmd`'s store-reports section nor `CHANGELOG.md`'s unreleased
section carries a sentence saying a record carrying no version is read as one
another version wrote — the old clause is gone from both, and the ledger check
passes at 37 rows. The ledger clause does not. Four rows were added; the diff
adds two wholly new sentences to `site/books.qmd`, and the second —
`site/books.qmd:178`, "The report for a record that WAS written and could not
be read says a record was there, which on this path would be a file no render
ever made." — carries no row. `sitecheck.py claims` asserts only that each
row's needle is present, never the converse, so nothing in the suite catches
this; it is a review-side reading of the criterion as written.

**AC6 — verified.** Both runs above. The M073 battery under `--self-test` shows
red against each pre-fix shape: (a) `m073-collapsed`, the new branch made
unreachable by `elseif never_written and false then`, draws
`WARN_STORE_UNREADABLE_LOST` once and `WARN_STORE_NEVER_LOST` zero — the
inverse of the AC1 counts; (b) `m073-widetest`, the classification test back to
inequality alone, reports a version-deleted record as another version's; (c)
`m073-niltest`, the same test made nil-only, leaves the deleted-version leg
green while the string and boolean forms both report as another version's,
which is the plant's point. All four plant needles match exactly once against
the shipped `book.lua`, the M072 `refusefirst` plant's re-anchored needle
included; it carries the `ok and type(data) == "table"` context, so it cannot
match `valid_record`.

**Consistency gate — passed.** `cairn_validate.py` exits 0: all 16 checks PASS,
all 7 advisories OK, `release window` not fired. The `generic` profile's
`consistency-gate` slot names no toolchain checks. No `DESIGN.md` principle
changed — only Known-issues entries — so `cairn_impact.py` is skipped.

**Independent review.** Surface tier user-facing and the diff touches
executable surface, so the full three-lens fan-out ran, fresh context, distinct
evidence bases. [S] blame-history: no findings. [S] prior-PR-comments: no
findings; the GitHub inline-comment probe returned `[]`, so that surface was
skipped, and the archived review records on these files show this diff closing
KI230 (M069 F3) and KI236 (M072 F1) rather than regressing either. [O] diff-bug
returned ten, ranked; F1 below is the review session's own.

- **F1 (AC5's ledger clause).** `site/books.qmd:178` is added and unpinned; see
  AC5 above. Disposition: **return** — this is the criterion failure.
- **F2 (a falsified clause left standing in DESIGN.md).** The recovery
  paragraph at `cairn/DESIGN.md:521-531` still says "Five wordings carry the
  outcome" — there are now six — and still says the version-skew report covers
  "any record that decodes and does not carry this version's number", the exact
  clause this milestone removed from `site/books.qmd`. T6 named that paragraph;
  the DESIGN diff reached only KI216, KI230 and KI236. This is the silent-false
  clause T3's re-read exists to catch, and it now sits eleven hundred lines
  above KI236's "*Resolved M073*". Disposition: **fix in implement**.
- **F3 (a report count moved, untested and unstated).** A record decoding to a
  table with no numeric `version` used to enter `stale` and be drawn only under
  `builds or first == nil` (`book.lua:1570`); it now falls through and is drawn
  inline by every chapter that reads the store. A chapter that builds no index
  section and said nothing about such a record now reports it. Verified against
  both branch sites. `site/books.qmd:228` states the new rule; `CHANGELOG.md`
  says only that the wording changes and that no record's usability changes.
  No leg covers it: all three AC3 legs render `index.qmd`, which builds both
  sections, so the count is 1 under the old and the new draw site alike — they
  discriminate on wording only. This is the axis M072 built its criteria on
  (`one.qmd` against `index.qmd`), and this milestone moves a record state
  across it with no `one.qmd` leg. Disposition: **fix in implement** — a
  `one.qmd` leg pinning the new count, and a changelog sentence.
- **F4 (the same move, for a refused chapter).** A refused chapter whose record
  decodes without a numeric `version` used to take `stale[..]={refused=true}`
  and draw `warn_source_refused` at the section-building site under D-049; it
  now takes the inline `elseif refused` branch, per reading chapter. Consistent
  with D-049's residual rule and with `site/books.qmd`, but D-050 does not
  record the reassignment and nothing tests it. Disposition: **fix in
  implement**, with F3.
- **F5 (`site/books.qmd` reads as contradicting itself).** `:142-145` says the
  never-written report "names the source alone"; `:176-179` says it says that
  no render has written the record and that the source could not be read
  either. The shipped sentence does both. The first is defensible read
  elliptically — "names the source alone *as unreadable*", against "names both
  files" for the fifth wording — but a fresh reader took it as a contradiction,
  and the new ledger row `a never-written record whose source is lost says so`
  pins that half in place. Disposition: **fix in implement** — a clarifying
  clause and its row.
- **F6 (the AC2 plant does not check it overwrites a record).** The `printf` at
  `tests/run-tests.sh:24629` creates `four.qmd`'s record if the fixture ever
  stopped carrying one, and the leg would then pass over a record the plant
  itself made. Every sibling plant guards: `m072_copy`'s `five.ipynb` check,
  `m073_version_form`'s `[ -f ]`, `m073_plant_version`'s version check.
  Disposition: **fix in implement** — one guard.
- **F7 (stale line citations in the criteria).** AC1 cites
  `tests/run-tests.sh:9071` where the leg's assertions are at 9086-9099; AC4
  cites `:24505`, now inside `m072_other_wordings_silent`, where the leg is at
  ~24533; AC5 cites `:21763` where the ledger heredoc opens at 21781. The
  criteria's substance holds; only the pointers drifted. Criterion text is
  plan-owned, so this is not a review-side edit. Disposition: **for implement's
  criterion-amendment gate**, if the criteria are opened there; otherwise it
  stands as recorded here.
- **F8 (a guard that cannot fire).** `m073_plant_version`'s "no field other
  than version changed" comparison (`tests/run-tests.sh:24700-24702`) takes
  `before = dict(record)` from the same object and mutates only `version`, so
  the two dicts minus `version` are equal by construction. It reads as a real
  guard and distinguishes nothing. Disposition: **fix in implement**.
- **F9 (a plant asserting half its pair).** The boolean nil-test plant
  (`tests/run-tests.sh:24912`) checks `WARN_STORE_STALE_RECOVERED` at 1 but
  omits the `WARN_STORE_UNREADABLE_RECOVERED` 0 companion the string form
  asserts immediately above; a mutation drawing both wordings would pass.
  Disposition: **fix in implement** — one assertion.
- **F10 (locale-dependent record I/O in the plant).** `json.load(open(path))`
  and `open(path, 'w')` at `tests/run-tests.sh:24686, 24707` pass no
  `encoding='utf-8'`, unlike `place_plant_marker`. Writing is safe —
  `json.dump` escapes non-ASCII — but reading a record carrying non-ASCII under
  a C locale would raise. Latent: `book-extensions`' terms are ASCII.
  Disposition: **fix in implement** — one keyword argument.
- **F11 (no zero-control for the sixth wording outside this milestone's legs).**
  `WARN_STORE_NEVER_LOST` appears only in the M069/M070/M073 legs this branch
  touched; the legs holding the other five store wordings at zero were not
  extended, so a regression drawing the new wording spuriously is caught only
  where `check_extension_warning_count` happens to be asserted. Disposition:
  **follow-up candidate row** — a suite-wide zero-control sweep, not this
  milestone's shape.

**Outcome: returned to `in-progress`.** AC5's claim-ledger clause fails on
fresh evidence (F1). F2-F6 and F8-F10 ride the same return; F7 is a criteria
matter and F11 a follow-up.

---

## Review — round 2 (2026-09-03)

Evidence dated to the tree at `a8825f8`, the repaired tree; round 1's evidence
above stands as the record of that round and is not re-dated.

**Runs.** `tests/run-tests.sh` exits 0, 680 checks passed.
`tests/run-tests.sh --self-test` exits 0, 1268 checks passed. Both run fresh in
this session over `a8825f8` with a clean tree.

**AC1 — verified.** The `m069-lostsource` leg runs green in the fresh run
(`M069-AC5` block), and `tests/scans/warn-distinct.py` passes at 84 messages,
mutually distinct as whole messages and under its prefix check
(`M02-AC5`). The M069 aggregate pass records the never-written wording drawn
and the could-not-be-read wording never, over the same fixtures.

**AC2 — verified.** The `m073-undecodable` leg passes: a record that was
written, does not decode, and whose chapter's source cannot be read either
keeps the wording naming both, the new never-written wording is not drawn
there, and that chapter's term is absent from the section `five.qmd` builds.

**AC3 — verified.** The three `m073_version_form` legs — `version` deleted,
the string `"4"`, a boolean — each pass with the three `WARN_STORE_STALE_*`
keys at zero and `WARN_STORE_UNREADABLE_RECOVERED` at one naming `one.qmd`,
and each plant reports the record differing from the written one in the
`version` field alone.

**AC4 — verified.** `git diff origin/main...HEAD -- tests/run-tests.sh` shows
no change inside the `m072` version leg, and that leg passes in the fresh run
with its counts unchanged: the refusal drawn once by the chapter that builds a
section and not at all by the chapter that builds none.

**AC5 — verified, both clauses.** Grep clause: every sentence containing "no
version" in the books page's store-reports region and in `CHANGELOG.md`'s
unreleased section states the opposite of the forbidden claim — such a record
is read as one that could not be used, "rather than as one written by a
different version of this extension". Ledger clause: six rows were added
across the branch, one per added or rewritten sentence, including
`why the written-record wording is not reused`, which pins the sentence round 1
failed on. The ledger stands at 39 rows, the claim-list self-test's pinned
count matches, and `sitecheck.py claims` passes over all 39.

**AC6 — verified.** Both runs above. The M073 battery under `--self-test`
shows red against each pre-fix shape, the fourth plant added this round
included: with the version test back to inequality alone, a chapter that
builds no index section says nothing about a record carrying no version,
neither the report nor the refusal.

**Consistency gate — passed.** `cairn_validate.py` exits 0: all 16 checks
PASS, 7 advisories, `release window` not fired. The `sizing` advisory WARNs at
13 tasks — six of them this milestone's return repairs. The `generic`
profile's `consistency-gate` slot names no toolchain checks. No `DESIGN.md`
principle changed, so `cairn_impact.py` is skipped.

**Independent review — round 2.** Surface tier user-facing and the diff
touches executable surface, so the full three-lens fan-out ran again, fresh
context, distinct evidence bases. [S] blame-history: no findings. [S]
prior-PR-comments: no findings; the inline-comment probe returned `[]`, so
that surface was skipped, and the archived review records show every round-1
repair present at HEAD. [O] diff-bug returned eight, ranked; each was verified
against the tree before triage, and R2-F8 did not survive verification as
stated.

- **R2-F1 (a false comment on the branch the milestone moved).**
  `book.lua:1011-1013` says "The other three states — never written, listed and
  unopenable, opened and undecodable — are drawn here, by every chapter that
  reads the store, the counts they have always had." After the narrowing a
  fourth state is drawn there — decodes to a table, carries no numeric
  `version` — and its count is the one that moved. Confirmed.
- **R2-F2 (the same, on the refused branch).** `book.lua:1046-1047` lists the
  same three states for the inline refusal. A refused chapter whose record
  decodes without a numeric `version` reaches it and is neither unopenable nor
  undecodable — the case the new `m073-count-refused` leg exercises. Confirmed.
- **R2-F3 (an ordinal contradiction introduced by T9).** `book.lua:1086` and
  `DESIGN.md:1646` both call the M073 wording the sixth; T9's edit to the
  recovery paragraph inserted it as a fifth and renumbered M070's refusal to
  sixth, which also breaks the following sentence, whose "That fifth" refers to
  the refusal. Confirmed.
- **R2-F4 (a qualifier dropped on the site).** `site/books.qmd:219` says "a
  `version` this render does not write … and only that", without the "can read
  as a number" qualifier `CHANGELOG.md` and `DESIGN.md` both carry; a `version`
  of `"4"` satisfies the clause as written and is not read that way. The colon
  clause that follows corrects it, so the page is not wholly false and AC5's
  grep clause still passes. Confirmed.
- **R2-F5 (a record overcounting a family).** D-050's Consequences say "The six
  wordings the never-written and could-not-be-read families now hold"; those
  two families hold five — three `WARN_STORE_UNREADABLE_*` and two
  `WARN_STORE_NEVER_*`. The sixth store wording is the refusal, in neither
  family. Confirmed; D-050 is history, so this takes a superseding entry.
- **R2-F6 (a running count out of order).** The store key-count comments read
  Seven (`:877`), Nine (`:883`), Eight (`:891`) — the M073 block was inserted
  between M069's and M070's. Confirmed.
- **R2-F7 (two added clauses carry no ledger row).** "the report names both
  files" and R2-F4's clause. Both sit inside sentences that do carry a row, so
  AC5 as written is met. Confirmed as stated; overlaps R2-F4.
- **R2-F8 (a missing zero-control) — did not survive verification as stated.**
  The `m069-AC2` quiet legs omit `WARN_STORE_NEVER_LOST` from their zero-control
  list, but they also assert `check_extension_warning_count … 0` over the same
  render, which already catches a spurious draw there. The gap is
  assert-identity-rather-than-count, not an uncaught regression; the finding's
  failure scenario overstates it.

**Round-2 triage and fixes.** The gate directed fix-all-seven-then-merge.
R2-F1 through R2-F7 fixed on the branch at `0b2a5bf`; R2-F8 rejected, its
stated failure scenario not surviving verification — the leg it names already
asserts a total-warning count of zero over the same render — and the
identity-vs-count remainder rides the zero-control candidate row F11 opened.
Dispositions: R2-F1 fix now; R2-F2 fix now; R2-F3 fix now; R2-F4 fix now;
R2-F5 fix now, as a superseding entry (D-052), D-050 being history; R2-F6 fix
now; R2-F7 fix now; R2-F8 reject, folded into the standing candidate row.

**Runs after the fixes.** `tests/run-tests.sh` exits 0, 680 checks passed;
`tests/run-tests.sh --self-test` exits 0, 1268 checks passed. The books claim
ledger passes at 41 rows and `warn-distinct.py` at 84 mutually distinct
messages, both over the repaired tree.

**Conversation read.** `pulls/73/reviews`, `issues/73/comments`, and the
unresolved-thread query all returned empty: no reviews, no comments, no
unresolved threads. Nothing to triage on that surface.

