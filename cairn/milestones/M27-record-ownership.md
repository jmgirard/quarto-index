# M27: A finding about today's behavior is a known issue, not a candidate row

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Refile the findings that review has been appending to `cairn/ROADMAP.md`
candidate rows and `cairn/LESSONS.md` lines into the records that own them, so
both files fall back under their budgets and stop refilling.

## Scope

Internal tier: the deliverable is this repo's own tracking records, on which no
external consumer of the repo relies.

**In:** classifying every candidate row and lesson line by what it actually
holds; moving findings about current behavior into `cairn/DESIGN.md`'s
`## Known issues`; retiring lesson content the acceptance suite's self-test
already enforces; writing the boundary rule as a `cairn/DECISIONS.md` entry and
pointing both files' header comments at it.

**Out:** dropping any candidate row outright — the plan gate kept everything,
so a row either shrinks to its proposal or its content moves. Mechanizing the
byte budgets — `cairn_validate` is the plugin's, not this repo's, so the
budgets stay hand-checked at hygiene passes. Any change under `tests/` or
`_extensions/` — this milestone touches records only.

## Acceptance criteria

- [ ] AC1: `wc -c -l cairn/ROADMAP.md cairn/LESSONS.md` at the branch head
      reports `ROADMAP.md` at or under 18,000 bytes and 52 lines, and
      `LESSONS.md` at or under 16,000 bytes and 44 lines. (Arithmetic:
      ROADMAP is 23,276 bytes / 56 lines and LESSONS 18,439 / 49 at the merge
      base, so ≥ 5,276 bytes and 4 rows leave the first, ≥ 2,439 bytes and 5
      lines the second.)
- [ ] AC2: `python3 ~/.claude/skills/cairn/scripts/cairn_validate.py` reports
      every check passing and no advisory firing.
- [ ] AC3: No text this milestone removes from `cairn/ROADMAP.md` or
      `cairn/LESSONS.md` is absent from both `cairn/DESIGN.md` and this file's
      `## Decisions` section. Domain: every removed line in
      `git diff <merge-base>..HEAD -- cairn/ROADMAP.md cairn/LESSONS.md`,
      read whole.
- [ ] AC4: Every `- ` row under `## Candidates` in the committed
      `cairn/ROADMAP.md` states work this repo might do and carries no finding
      about how the extension behaves today. Domain: every such row in the
      committed file, read in order.
- [ ] AC5: `cairn/DECISIONS.md` carries a new entry stating which record holds
      a finding about current behavior and which holds proposed work, and the
      `## Candidates` comment in `cairn/ROADMAP.md` and the header comment in
      `cairn/LESSONS.md` each name that entry by its id.
- [ ] AC6: Every variation this milestone removes from the "prove a check
      discriminating" lesson is one the acceptance suite's self-test covers,
      with the covering check named beside it in this file's `## Decisions`
      section. Domain: every clause the diff of that line removes.

## Coverage

- AC1 → T3, T4, T5, T6
- AC2 → T6
- AC3 → T1, T3, T4, T5
- AC4 → T1, T4
- AC5 → T2
- AC6 → T1, T5

## Tasks

- [ ] T1: Read every `- ` row under `## Candidates` in `cairn/ROADMAP.md` (37
      at the merge base) and every `- ` line in `cairn/LESSONS.md` (41).
      Classify each clause as proposed work (stays), a finding about current
      behavior (moves to `## Known issues`), or lesson content a named check
      already enforces (retires). Commit the ledger to `## Decisions` here.
- [ ] T2: Write the boundary entry in `cairn/DECISIONS.md`; point the
      `## Candidates` comment in `cairn/ROADMAP.md` and the header comment in
      `cairn/LESSONS.md` at it by id.
- [ ] T3: Move the classified findings into `cairn/DESIGN.md`'s
      `## Known issues` (currently `_None._`), one entry per finding, each
      naming the review it came from. Start with the two heaviest rows —
      acceptance-suite hardening (7,601 bytes) and `marks_seen` (2,412).
- [ ] T4: Rewrite each affected ROADMAP row down to the work it proposes, with
      a pointer to its `## Known issues` entry. Bound the pass with a command,
      not by eye (M17's lesson): require every clause the diff removes to
      appear in `cairn/DESIGN.md` or the T1 ledger before committing.
- [ ] T5: Trim the "prove a check discriminating" lesson to the variations the
      self-test does not cover, confirming each removal by running
      `tests/run-tests.sh --self-test` and naming the covering check. Retire
      any other lesson meeting the enforcement or ownership exit.
- [ ] T6: Re-measure `wc -c -l` on both files against AC1, run
      `cairn_validate.py`, and run `tests/run-tests.sh --self-test` once to
      confirm no code moved.

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: criteria audit ran in reduced mode (internal tier), in-session rather than in a spawned fresh-context reader, because this session is instructed not to spawn agents — the weaker arrangement M26 also hit. One finding: a draft AC3 promised removed text would appear "in the archive summary", which binds a record of verification rather than the records themselves; narrowed to `cairn/DESIGN.md` and this file's `## Decisions`. A draft AC6 promised `tests/plantdefect.py` fails on each planted defect, a test-harness property; narrowed to the lesson content, with the self-test run moved to T5.
- 2026-08-23: plan gate chose refiling findings into `cairn/DESIGN.md`'s `## Known issues` with a recorded boundary rule over compressing row prose in place, because compression leaves the append-a-finding-to-a-work-row mechanism intact and both files return to their caps in roughly five milestones at the observed ~500 bytes per milestone; falsified by the files climbing back toward their caps after this milestone without any row gaining a finding clause.
- 2026-08-23: plan gate chose retiring the enforced variations of the "prove a check discriminating" lesson over keeping the line whole and cutting mid-sized lessons instead, because the line is 2,995 bytes of 18,439 and the repo now runs a planted-defect self-test; falsified by a self-test run that passes with a variation's defect planted.

## Decisions

## Review
