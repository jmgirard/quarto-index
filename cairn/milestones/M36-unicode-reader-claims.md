# M36: The non-Latin-1 readers stop reading text that belongs to no error

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m036-unicode-reader-claims`

## Goal

`tests/unicodeprint.py`'s readers no longer let text outside an error report,
or a level spec its callers never read, satisfy a clause that claims to hold
them.

## Scope

**Surface tier: internal** — the deliverable is the acceptance suite's own
readers and their planted-defect probes; no consumer outside this repo reads
them.

**In:** five of the sixteen findings M35's Review section filed, all in
`tests/unicodeprint.py`. F1: `error_blocks` closes an unterminated final `! `
block at EOF, so a `Unicode character` mention in trailing chatter is absorbed
into it and `cmd_stopped` reports "in one error report" — a green that says
nothing. F10: `stated()` accepts a non-ASCII digit as a level (`'٣:foo'` →
`(3, 'foo')`) and an empty term. F11: `cmd_marks` requires the `<level>:<term>`
pair and discards the level, with no plant on that argv contract. F9: the pass
line beside the plants claims a plant per clause while `levelled()`'s
`columns_carry_top_level` clause and `read_entries`' no-entry-lines branch have
none. F16: `error_blocks` opens a block only on `! `, so `!pdfTeX error:` opens
none.

Under the checker-regress disposition the gate took, F9 and F16 are closed by
narrowing what the suite claims, not by widening what it reads: neither is
criterion-bound, because a promise about a check's own prose binds an
instrument (D-118).

**Out:** the eleven `tests/run-tests.sh` findings (F3–F8, F12–F15, F17) → M37.
The rest of the acceptance-suite hardening cluster — KI24, KI27–KI74, KI81–85,
KI87 — stays on its candidate row.

## Acceptance criteria

- [ ] AC1. `error_blocks` returns no block for an unterminated final `! ` line,
      so text following one belongs to no error report; `cmd_stopped` reports
      red on a log whose only `Unicode character` mention sits in that trailing
      text, and the self-test plants such a log.
- [ ] AC2. `stated()` refuses a level written in non-ASCII digits and refuses
      an empty term, each with its own message; the self-test plants both
      specs, one of them through `cmd_marks`, whose `<level>:<term>` argv
      contract is unplanted today.
- [ ] AC3. `tests/run-tests.sh` exits 0 in both plain and `--self-test` modes
      (the `generic` profile's verify slot, plus its self-test).

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T6

## Tasks

- [x] T1. Drop `error_blocks`' EOF tail (`tests/unicodeprint.py:224-225`), so
      an unterminated final `! ` line yields no block, and rewrite the
      docstring's "or to the next `! ` line" sentence to say what now closes a
      block.
- [x] T2. Plant it: a copy of the engine control log with its final error
      unterminated and a `Unicode character` line in the chatter after it;
      assert `stopped` red on it and green on the unmutated log.
- [x] T3. Narrow `stated()` (`tests/unicodeprint.py:90-101`): refuse a level
      that is not ASCII-digit, refuse an empty term, each with its own message.
- [x] T4. Plant both: `'٣:foo'` through `entries`, `'0:'` through `marks` —
      the second exercising `cmd_marks`' argv contract, which F11 records as
      unplanted.
- [ ] T5. F9 and F16, narrow-not-widen: cut the per-clause plant claim from the
      pass line beside the `tests/unicodeprint.py` plants down to the clauses
      that have one, and state in `error_blocks`' docstring that it reads
      `! `-opened reports only, so `!pdfTeX error:` is named as outside its
      domain. Record both dispositions, and F11's fold into T4, in the
      Decisions section.
- [ ] T6. Run both suite modes; state the resulting counts against the merge
      base (352 / 491) in the work log.

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan gate chose narrowing each check's claim over widening what it reads, because the checker-regress shape fired (M35 shipped these checks; `check_recipe_block` and the plant-coverage findings verify repo-internal artifacts); falsified by a finding on this list turning out to be reachable from a real render rather than only from a hand-built input.
- 2026-08-24: plan gate chose splitting the sixteen findings by file over one milestone, because the eight-criterion draft tripped the >~7 split tripwire; falsified by M37 proving unreviewable apart from M36's reader changes.
- 2026-08-24: reduced criteria audit ran twice, mode reduced both times (internal tier, no RB-tripwire tag). Round 1 over 8 pre-gate criteria returned one finding: AC8 bound a work-log recording act and a check count, both instruments; fixed by cutting both clauses. Round 2 over the 10 post-gate simplify-wording criteria returned three: M36-AC3 and M37-AC5 bound a checker's own prose, M37-AC2 bound an unenumerated universal and a check count; all three fixed, M36-AC3 and M37-AC5 cut to tasks and M37-AC2 rewritten as a state-of-the-file promise. Seven criteria clean.
- 2026-08-25: T1: `error_blocks` no longer closes an unclosed final `! ` report at EOF; run against a two-error string, a log whose second `! ` line is never closed now returns only the closed first block. Docstring rewritten to say what closes a block and what the tail after an unclosed one is. Plain suite 352 checks, exit 0.
- 2026-08-25: T2: self-test plants a copy of the engine control log with every real error report removed and the signature and `Unicode character θ` stated only in chatter after an unclosed `! ` line; run against both readers, the pre-T1 reader is green on it and the post-T1 reader red at the one-error clause. The unplanted engine log is now asserted green alongside `marks` and `entries`. The one-error failure message widened to cover text in no error report at all, which is what this input is. Self-test 491 checks, exit 0.
- 2026-08-25: T3: `stated()` now has three refusals with three messages — no level stated, a level not written in ASCII digits, an empty term. Run over six specs: `0:Ascii` reads, `Ascii` and `:foo` take the pair message, `٣:foo` and `ab:foo` the ASCII-digit message, `0:` the empty-term message. Gate chose refusing only a truly empty term, not a spaces-only one, so the reader does not judge whitespace. Plain suite 352 checks, exit 0.
- 2026-08-25: T4: two plants added — a level written as U+0663 through `entries`, and a level with an empty term through `marks`, the reading whose `<level>:<term>` argv contract had no plant. The U+0663 level is written literally, since this repo builds on bash 3.2 whose quoting has no `\u` escape. Self-test 491 checks, exit 0.

## Decisions

## Review
