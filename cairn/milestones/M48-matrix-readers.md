# M48: The version matrix's readers say what they read

- **Status:** planned
- **Priority:** normal
- **Depends on:** M47
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

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
reads and does not.

**Out:** the PDF half of the matrix → M47, which this depends on because the
control's fixture set is aligned against the render step M47 leaves behind.
Moving the floor version, or deleting `check_floor`'s `FLOOR:` read → neither;
D-011 licenses a scan narrowed to what it reads with its header comment saying
so, and this milestone writes that comment.

## Acceptance criteria

- [ ] AC1: The section row `tests/indexdump.py html` emits carries no `after` component ([htmlindex.py:246](tests/htmlindex.py:246), [htmlindex.py:273](tests/htmlindex.py:273)).
- [ ] AC2: `EXACT` is defined exactly once across `tests/versioncheck.py` and `tests/pagescheck.py`.
- [ ] AC3: Every member of `tests/indexdump.py`'s `minted` tuple ([indexdump.py:95](tests/indexdump.py:95)) is asserted present in the dump of a rendered fixture, so a stale identifier fails rather than yielding an empty section.
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

- [ ] T1: Drop the `after` component from the section row ([htmlindex.py:246](tests/htmlindex.py:246), [htmlindex.py:273](tests/htmlindex.py:273)) — it is an id Quarto mints, not one this extension does, so an upstream wrapper change reads as a difference in this extension. Update every reader of that row.
- [ ] T2: Give `EXACT` one home and import it in the other ([versioncheck.py:74](tests/versioncheck.py:74), [pagescheck.py:102](tests/pagescheck.py:102)).
- [ ] T3: Assert each member of `minted` against a rendered fixture's dump; plant a changed value for each, one substitution per plant.
- [ ] T4: Align the local control's fixture set with the render step M47 leaves — `html-index` currently has no unplanted control ([run-tests.sh:15664](tests/run-tests.sh:15664)).
- [ ] T5: Stop `m43_dump` discarding the reader's stderr ([run-tests.sh:15643](tests/run-tests.sh:15643)); plant a failing dump and assert the `FAIL:` line reaches the suite's output.
- [ ] T6: Correct the workflow header's "Nothing checks this workflow's own steps" sentence to name `check_floor`'s `FLOOR:` read ([versioncheck.py:260](tests/versioncheck.py:260)), and state in `check_floor`'s own header what it reads and does not.
- [ ] T7: Full run plus `--self-test`; dispatch the Versions workflow and record the run URLs as evidence.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose correcting the workflow header sentence over deleting `check_floor`'s `FLOOR:` read, because D-011 licenses a scan narrowed to what it reads with its header comment saying so, and deleting the read would leave the floor version either unnamed or written twice; falsified by that read certifying a property it does not assert.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). It returned four findings on the draft these criteria come from — an unbounded "every HTML identifier this reader matches" domain, a disjunct satisfiable by editing a prose comment, helper-plumbing wording on the `FAIL:`-line criterion, and a green-CI-matrix promise spanning the environment boundary. All four were fixed before the criteria above were written: the domain is now the `minted` tuple, the header correction moved to T6 with no criterion bound to it, the `FAIL:` promise binds the suite's own exit and output, and the workflow runs became T7 evidence.

## Decisions

## Review
