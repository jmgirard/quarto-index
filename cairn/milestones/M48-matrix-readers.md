# M48: The version matrix's readers say what they read

- **Status:** review
- **Priority:** normal
- **Depends on:** M47
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m048-matrix-readers` — https://github.com/jmgirard/quarto-index/pull/48

## Goal

Close the remaining M43 findings on the readers around the version matrix: the
compared row's borrowed id, the duplicated pattern, the unbound identifiers, the
control's short fixture set, and the swallowed failure line.

## Scope

**In:** Surface tier **internal** — the deliverable is this repo's own suite
readers over its own fixture renders; no external consumer of the repo relies on
them. Drop the `after` id from the compared section row. Give `EXACT` one home.
Bind `tests/indexdump.py`'s `minted` identifiers to a rendered fixture. Align the
suite's local comparison control with the workflow's fixture set. Stop `m43_dump`
discarding the reader's `FAIL:` line. Correct the workflow header's claim that
nothing checks its own source, and state in `check_floor`'s own header what it
reads and does not, narrowing its bare substring document test and closing its
file handles in the same pass.

**Out:** the PDF half of the matrix → M47, which this depends on because the
control's fixture set is aligned against the render step M47 leaves behind.
Moving the floor version, or deleting `check_floor`'s `FLOOR:` read → neither;
D-011 licenses a scan narrowed to what it reads with its header comment saying
so, and this milestone writes that comment.

## Acceptance criteria

- [x] AC1: The section row `tests/indexdump.py html` emits carries no `after` component ([htmlindex.py:246](tests/htmlindex.py:246), [htmlindex.py:273](tests/htmlindex.py:273)).
- [x] AC2: `EXACT` is defined exactly once across `tests/versioncheck.py` and `tests/pagescheck.py`.
- [x] AC3: Every member of `tests/indexdump.py`'s `minted` tuple (the tuple `dump_html` builds, [indexdump.py](tests/indexdump.py)) is asserted against the rendered fixture the dump reads — today the section id it finds the index under, the anchor each locator points at, and the id each entry carries — so a stale identifier makes the dump fail loudly, naming the identifier it did not find, rather than printing rows the render no longer matches.
- [x] AC4: The fixture names `.github/workflows/versions.yml`'s render step renders equal the fixture names the suite's local comparison control covers.
- [x] AC5: A failing `tests/indexdump.py` under the suite makes the suite exit non-zero with the reader's own `FAIL:` line on the suite's output.
- [x] AC6: `tests/run-tests.sh` completes at exit 0, and `tests/run-tests.sh --self-test` completes at exit 0.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T7

## Tasks

- [x] T1: Drop the `after` component from the section row ([htmlindex.py:246](tests/htmlindex.py:246), [htmlindex.py:273](tests/htmlindex.py:273)) — it is an id Quarto mints, not one this extension does, so an upstream wrapper change reads as a difference in this extension. Update every reader of that row.
- [x] T2: Give `EXACT` one home and import it in the other ([versioncheck.py:74](tests/versioncheck.py:74), [pagescheck.py:102](tests/pagescheck.py:102)).
- [x] T3: Assert each member of `minted` against the rendered fixture `dump_html` reads; plant a changed value for each, one substitution per plant.
- [x] T4: Align the local control's fixture set with the render step M47 leaves — `html-index` currently has no unplanted control ([run-tests.sh:15664](tests/run-tests.sh:15664)).
- [x] T5: Stop `m43_dump` discarding the reader's stderr ([run-tests.sh:15643](tests/run-tests.sh:15643)); plant a failing dump and assert the `FAIL:` line reaches the suite's output.
- [x] T6: Correct the workflow header's "Nothing checks this workflow's own steps" sentence to name `check_floor`'s `FLOOR:` read ([versioncheck.py:260](tests/versioncheck.py:260)), and state in `check_floor`'s own header what it reads and does not. In the same pass narrow that reader's bare substring document test — `version not in body` matches `1.4.549` inside a longer version string — and close the file handles it leaves open.
- [x] T7: Full run plus `--self-test`; dispatch the Versions workflow and record the run URLs as evidence.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose correcting the workflow header sentence over deleting `check_floor`'s `FLOOR:` read, because D-011 licenses a scan narrowed to what it reads with its header comment saying so, and deleting the read would leave the floor version either unnamed or written twice; falsified by that read certifying a property it does not assert.
- 2026-08-27: T1 — `section_rows` writes the `id it follows` field in the count form only, so the row `tests/indexdump.py html` prints no longer carries it; the count form the suite's section manifests read is unchanged, and with it the M38 evidence about where on the page a generated section sits. Suite green, 386 checks.
- 2026-08-27: T2 — the exact-dotted-version pattern lives in `tests/pagescheck.py`, the reader that judges the Pages workflow's pin and documents why a channel name is not one; `tests/versioncheck.py` imports it. Suite green, 386 checks.
- 2026-08-27: T3 — `dump_html` holds all three minted identifiers against the page it read: the section id by the existing no-section clause, the anchor and entry prefixes by `minted_carried`, which fails naming the prefix and the variable that supplied it. Two plants added, one prefix renamed per plant. The M45 hand-written control pages now carry the anchor their locator links at, as a render does, and the expected one-entry dump lost the field T1 removed. Suite green: 386 checks, 694 with --self-test (from 692).
- 2026-08-27: T4 — the four fixtures the matrix renders are one table in the suite, `html-index` among them for the first time; the same table drives the local dumps, the legs tree the comparison control reads, and the names handed to a new `versioncheck.py fixtures` mode, which reads the workflow's `indexdump.py html` invocations and their extraction targets and holds the two sets equal. Four plants. Suite green: 388 checks, 700 with --self-test.
- 2026-08-27: T5 — `m43_dump` no longer sends the reader's stderr to /dev/null, so a failing dump puts `indexdump.py`'s own `FAIL:` line on the suite's output beside the control's. Proved under --self-test by running the control over the planted no-section page and reading both lines off its combined output. Suite green: 387 checks, 701 with --self-test.
- 2026-08-27: correction — the T4 line above states 388 checks for the plain run. That figure was not measured; the plain run after T4 reported 387, as it does after T5. The --self-test figure it states, 700, is what that run reported.
- 2026-08-27: T6 — the workflow header no longer says nothing checks its steps: it names the `FLOOR:` read and the render step's extraction-target read, says each states its own domain, and keeps D-011's refusal of a wider scan. `check_floor`'s header states what it reads of the workflow and of each document and what it does not; its document test is bounded over digits and dots, so `1.4.5490` no longer counts as naming `1.4.549`, with a plant for that bound; both file handles are closed. Suite green: 387 checks, 702 with --self-test.
- 2026-08-27: T7 — `tests/run-tests.sh` exits 0 at 387 checks and `--self-test` exits 0 at 702. The Versions workflow ran on this branch twice, both green: the push run https://github.com/jmgirard/quarto-index/actions/runs/33122263299 (floor 1.4.549 and pinned 1.10.18) and a dispatched run https://github.com/jmgirard/quarto-index/actions/runs/33122267854, which adds the release-channel leg. The dispatched run's comparison reports 8 comparisons over 4 fixtures — book, demo, html-index, named-indexes — every one byte-identical to the pinned leg.
- 2026-08-27: status set to review.
- 2026-08-27: amendment gate — AC3 re-aimed from the dump's printed rows to the rendered fixture the dump reads. `qi-entry-` never reaches the printed rows (`htmlindex.row()` prints depth, term, locator hrefs and cross-reference targets, and no entry id), so the criterion as written was reachable only by adding a field to the href row form the hand-written book manifests also read. T3's wording follows the criterion.
- 2026-08-27: criteria audit of the amended AC3 ran in reduced mode (internal tier), fresh-context [O], the reader having authored none of it. No finding on any of the three questions. Two cautions disposed here: the three-item gloss now reads "today the section id …" so a fourth member could not be read as already covered, and the loud-failure clause names `indexdump.py`'s own failure rather than the suite assertion's message text.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). It returned four findings on the draft these criteria come from — an unbounded "every HTML identifier this reader matches" domain, a disjunct satisfiable by editing a prose comment, helper-plumbing wording on the `FAIL:`-line criterion, and a green-CI-matrix promise spanning the environment boundary. All four were fixed before the criteria above were written: the domain is now the `minted` tuple, the header correction moved to T6 with no criterion bound to it, the `FAIL:` promise binds the suite's own exit and output, and the workflow runs became T7 evidence.
- 2026-08-27: review — all six criteria verified with fresh evidence (387 checks, 702 under `--self-test`, both exit 0; `cairn_validate` clean; PR CI green). Three lenses: blame-history and prior-review found nothing, diff-bug returned seventeen ranked findings, none reaching the return floor.

## Decisions

## Review

Reviewed 2026-08-27 on branch `m048-matrix-readers`, PR
https://github.com/jmgirard/quarto-index/pull/48. The branch was current with
`origin/main` (`57ac888`) at review; nothing to merge in.

### Acceptance-criteria evidence

- AC1 — `tests/indexdump.py html` run on a hand-built page in the M45 control's
  shape prints `section<TAB>qi-index<TAB>h1<TAB>Index` and nothing further on
  that row; `section_rows` appends the `id it follows` field only under `not
  hrefs` ([htmlindex.py:283](tests/htmlindex.py:283)) and `dump_html` calls it
  with `hrefs=True`. The suite's own M45 one-entry control compares the dump
  byte for byte against that four-field row and passed under `--self-test`.
- AC2 — `grep -n EXACT tests/versioncheck.py tests/pagescheck.py`: one
  definition, [pagescheck.py:107](tests/pagescheck.py:107); `versioncheck.py:92`
  binds `EXACT = pagescheck.EXACT`. No second definition across the two files.
- AC3 — `--self-test` green on the M43 block: the section id by the
  `nosection.html` plant, the anchor prefix by `staleanchor.html` and the entry
  prefix by `staleentry.html`, one substitution per plant, each red naming the
  prefix it did not find. Every member of the `minted` tuple planted on its own.
- AC4 — the plain run reports `.github/workflows/versions.yml extracts 4
  fixture(s) — book, demo, html-index, named-indexes — and the suite dumps that
  same set locally`; under `--self-test` each clause of the new `fixtures` mode
  is planted red on its own (extractions written by another command, no name to
  hold against, a name missing from the suite's set, a name the workflow does
  not extract).
- AC5 — `--self-test` green on `M48-AC5: a failing dump under the suite exits
  non-zero carrying both the reader's own FAIL: line naming what it found and
  the control's line naming which dump it was running`, run through `m43_dump`
  over the planted no-section page with stdout and stderr together.
- AC6 — `tests/run-tests.sh` exit 0, 387 checks (7m00s);
  `tests/run-tests.sh --self-test` exit 0, 702 checks. Both fresh at review.

### Consistency gate

`cairn_validate.py` exit 0, all checks passed, every advisory OK — the `release
window` advisory did not fire. No `DESIGN.md` principle changed, so
`cairn_impact.py` was skipped. The `generic` profile names no toolchain checks,
so that half of the gate is a no-op. PR CI green on every job: build, plan, the
floor and pinned render legs, and compare.

### Independent review

Three fresh-context lenses, none having authored the work.

- **[S] blame-history** — no finding. It confirmed the dropped `after` field is
  the diff's declared purpose and that the count form the M38 placement evidence
  reads is preserved untouched; that the removal of `2>/dev/null` acts on a
  recorded lesson rather than against one; and that nothing here contradicts a
  recorded decision, D-011 included.
- **[S] prior-PR-comments** — no finding. Its GitHub probe returned no inline
  review comments anywhere in the repo, so the per-PR walk was skipped; the
  archived `## Review` sections of M43, M45 and M47 record no defect this diff
  reintroduces.
- **[O] diff-bug** — seventeen ranked findings, listed with their disposition
  below.

### Findings and disposition

Ranked as the lens reported them. Every claim below was re-verified against the
implementation before triage; F1, F6, F7 and F10 were confirmed by running the
code, F3 by dumping a page whose only locator points at an anchor it does not
carry.

Recommended **fix now** — defects in what this milestone shipped, each cheap:

- F1: `EXTRACTION` requires a `\` line continuation between the `indexdump.py
  html` call and its redirect, so a fixture added to the render step on one line
  is invisible to the fixture-set check and ships with its extraction
  unexercised. Confirmed: appending a single-line invocation to the real
  workflow leaves `findall` returning the same four names.
- F6: `versioncheck.py` now imports `pagescheck`, whose module body imports
  `site/build_gallery.py`, so the matrix's `plan` and `compare` jobs die on an
  unrelated docs-site import error. AC2 does not name a direction; defining
  `EXACT` in the lighter module and importing it into `pagescheck` satisfies the
  criterion without the coupling.
- F10: the new fixture-set check prints under `M43-AC4`, which M43's archive
  already uses for its workflow-plant criterion; it is M48's AC4.
- F8: the workflow header and the reader's own comment both say the extraction
  read is scoped to the render step; `findall` scans the whole file.
- F9: the suite's failure line says the matrix *renders* a different set, where
  the check reads redirect targets and says so itself.
- F7: `version_named`'s docstring claims a longer version containing the floor
  cannot count; `1.4.549-rc1` and `1.4.549b` both count. The bound is over
  digits and dots, which is narrower than the docstring's claim.
- F2 (prose half): the file-header comment says a renamed prefix would leave the
  command reading the page through names it no longer uses; after T1 neither
  prefix reaches the href output at all, which `minted_carried`'s own docstring
  states correctly.
- F4: the same comment implies the no-section clause catches any renamed section
  id; `index_sections` also matches `prefix + '-'`, so a rename to a dash suffix
  still matches.
- F15: `section_rows`' new paragraph calls the `id it follows` field the only
  evidence the suite has of where a section sits, which nothing in the diff
  establishes.
- F14: `m43_dump` now runs inside a `while read` loop fed by a here-string with
  its stdin inherited; a future step reading stdin would eat the remaining
  fixture rows and every downstream domain would shrink in lockstep, staying
  green.
- F16: two consecutive blank lines between the new plants.

Recommended **follow-up** — real gaps wider than this milestone:

- F3: `minted_carried` is an existence test, so a dangling locator or a partial
  rename passes. Verified: a page carrying `qi-mark-1` whose only locator points
  at `#qi-mark-99` dumps at exit 0.
- F13: both sides of the fixture-set comparison are `set()`s, so two render
  targets written to one extraction name read as agreement while one fixture's
  extraction is silently overwritten.
- F11: the comparison report's count assertion is now derived from the same list
  that produced the files it counts, where it was an independent literal.
- F5: the anchor clause couples each fixture's dump to that fixture happening to
  carry a mark; removing the book's one mark would redden the matrix with a
  false reason.
- F12: the M43 plant helper checks exit status, message substring and absence of
  a traceback, but not that the message sits on a `FAIL: ` line.

Recommended **reject**:

- F2 (behavior half): a renamed prefix reddening every leg is the loud failure
  AC3 asks for, not a false report of a version disagreement — the reader fails
  naming the prefix, never reporting a comparison.
- F17: AC2 is enforced by no standing check. That is D-011's refusal of a
  source-shape scan, not a gap; the criterion is verified by reading at review,
  which is the evidence recorded above.

No finding demonstrates an acceptance criterion failing: AC4's two sets are
equal today (four names, verified), and AC3 asks that each member of `minted` be
asserted and that a stale identifier fail loudly naming it, which all three
plants show. The return floor is not reached.
