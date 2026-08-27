# M48: The version matrix's readers say what they read

- **Status:** review
- **Priority:** normal
- **Depends on:** M47
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m048-matrix-readers`

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

- [ ] AC1: The section row `tests/indexdump.py html` emits carries no `after` component ([htmlindex.py:246](tests/htmlindex.py:246), [htmlindex.py:273](tests/htmlindex.py:273)).
- [ ] AC2: `EXACT` is defined exactly once across `tests/versioncheck.py` and `tests/pagescheck.py`.
- [ ] AC3: Every member of `tests/indexdump.py`'s `minted` tuple (the tuple `dump_html` builds, [indexdump.py](tests/indexdump.py)) is asserted against the rendered fixture the dump reads — today the section id it finds the index under, the anchor each locator points at, and the id each entry carries — so a stale identifier makes the dump fail loudly, naming the identifier it did not find, rather than printing rows the render no longer matches.
- [ ] AC4: The fixture names `.github/workflows/versions.yml`'s render step renders equal the fixture names the suite's local comparison control covers.
- [ ] AC5: A failing `tests/indexdump.py` under the suite makes the suite exit non-zero with the reader's own `FAIL:` line on the suite's output.
- [ ] AC6: `tests/run-tests.sh` completes at exit 0, and `tests/run-tests.sh --self-test` completes at exit 0.

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

## Decisions

## Review
