# M36: The non-Latin-1 readers stop reading text that belongs to no error

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m036-unicode-reader-claims` — https://github.com/jmgirard/quarto-index/pull/36

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

- [x] AC1. `error_blocks` returns no block for an unterminated final `! ` line,
      so text following one belongs to no error report; `cmd_stopped` reports
      red on a log whose only `Unicode character` mention sits in that trailing
      text, and the self-test plants such a log.
- [x] AC2. `stated()` refuses a level written in non-ASCII digits and refuses
      an empty term, each with its own message; the self-test plants both
      specs, one of them through `cmd_marks`, whose `<level>:<term>` argv
      contract is unplanted today.
- [x] AC3. `tests/run-tests.sh` exits 0 in both plain and `--self-test` modes
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
- [x] T5. F9 and F16, narrow-not-widen: cut the per-clause plant claim from the
      pass line beside the `tests/unicodeprint.py` plants down to the clauses
      that have one, and state in `error_blocks`' docstring that it reads
      `! `-opened reports only, so `!pdfTeX error:` is named as outside its
      domain. Record both dispositions, and F11's fold into T4, in the
      Decisions section.
- [x] T6. Run both suite modes; state the resulting counts against the merge
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
- 2026-08-25: T5: the plant matrix rewritten to one row per plant (23 rows, the table having drifted to 15), the two unplanted clauses named at its foot, and the pass line narrowed to what each plant shows, its plant count counted at run time. `error_blocks`' docstring names the `! `-with-space shape as its whole domain. Self-test 491 checks, exit 0, the pass line printing 23.
- 2026-08-25: T6: both modes run on the final tree — plain 352 checks exit 0, `--self-test` 491 checks exit 0, the same counts as the merge base (1326635). Neither mode's count moves: the three new plants go through `m33_planted`, which reports only on failure, and the readings they exercise are already counted by the block's single pass line.
- 2026-08-25: gate triage applied — eleven prose findings fixed on the branch (findings 1, 3-9, 11-13), finding 2 absorbed into the acceptance-suite hardening candidate row, finding 10 rejected. Both suite modes re-run after the fixes: plain 352, self-test 491, both exit 0.

## Decisions

- **F9 — a clause with no plant is closed by narrowing the claim, not by adding
  a plant.** The pass line beside the `tests/unicodeprint.py` plants claimed a
  plant per clause. Two clauses have none: `entries` and `absent` refusing an
  index whose heading printed but whose entry list is empty, already named in
  that block's comment as unreachable through this extension; and `levelled`
  refusing a column that holds no top-level entry, for which no capture in this
  suite is such a PDF and nothing here builds a document whose index would break
  a column between a parent line and its sub-entries. The pass line now claims
  only that each plant makes its own clause's message appear, and names both
  unplanted clauses as claimed for by nothing. The count it prints is counted at
  run time rather than restated in prose.

- **F16 — `!pdfTeX error:` opening no block is closed by naming the domain, not
  by widening it.** `error_blocks` opens a report only on `! ` with its space,
  the shape LaTeX's own errors take and the only shape the rejection this module
  reads is written in. Widening it to pdfTeX's spelling would make the reader
  return blocks for a class of error no reading here holds anything to. The
  docstring now says the reader returns no block for such a line and that
  nothing here speaks about that class.

- **F11 — the `marks` argv contract folded into T4 rather than taken as its own
  task.** That contract is `stated()`, which `marks` calls and whose level half
  it then discards, so nothing in the reading's own output shows it parsed a
  spec at all. The plant that holds `marks` to it is the empty-term spec T3
  added a refusal for: one plant closes both.

## Review

### Acceptance criteria — fresh evidence (2026-08-25)

- AC1 — met. `error_blocks` run on a string whose second `! ` line is never
  closed returns 1 block, the closed first one. The self-test's own plant,
  rebuilt from `tests/.work/cap/m33-engine/engine.log` the same way, states the
  signature and `Unicode character θ` only in chatter after an unclosed `! `
  line: the merge-base reader (origin/main) is green on it and reports "in one
  error report"; the branch reader is red at the one-error clause, reading 0
  error reports. The self-test plants it at `tests/run-tests.sh:12297` and
  asserts it at 12334.
- AC2 — met. `stated()` run over four specs: `0:Ascii` reads `(0, 'Ascii')`;
  `٣:foo` is refused naming its level as not written in ASCII digits and giving
  the codepoint; `0:` is refused naming an empty term; `Ascii` keeps the
  existing no-level-stated message. The merge-base reader accepts the first two
  of those refusals as `(3, 'foo')` and `(0, '')`. Both specs are planted —
  `٣:foo` through `entries` at `tests/run-tests.sh:12192`, `0:` through `marks`
  at 12159, the reading whose argv contract had no plant.
- AC3 — met. `tests/run-tests.sh` exits 0 with 352 checks; `--self-test` exits 0
  with 491 checks, its M33 pass line printing 23 planted defects.

### Consistency gate

`cairn_validate.py` exit 0, all 16 checks PASS, 7 advisories OK. `generic`
profile's `consistency-gate` slot names no toolchain checks — clean no-op. No
principle changed, so no impact report.

### Independent review

Three fresh-context reviewers, none having seen the implementation.

- **[S] prior-PR-comments** — no findings. The GitHub inline-comment probe
  returned empty, so no per-PR walk. Against `cairn/milestones/archive/`'s M33
  and M35 Review sections: the diff addresses exactly the five findings M36
  scopes and re-opens none.
- **[S] blame-history** — no findings of regression. Each change traces to a
  finding M35's review filed; the D-118 citation it flagged is the cairn
  plugin's own decision id, a point M33's review already rejected on the same
  grounds.
- **[O] diff-bug** — 13 ranked findings, below.

### Findings and dispositions

1. **`error_blocks`' EOF-tail drop silently discards a real error report, and
   the docstring's justification is false for it.** TeX writes
   `!  ==> Fatal error occurred, no output PDF file produced!` as a complete
   one-line report with no `l.<n>` line; it is the last line of the engine
   control log, so `error_blocks` went from 2 blocks to 1 and now returns
   nothing for a report the log genuinely does carry. — Verified against the
   captured log: old 2 blocks, new 1, the dropped one being that fatal line.
   **Fix now** (prose): the docstring's claim is corrected to say what is
   dropped, the fatal-error shape named. AC1 is unaffected — it promises no
   block for an unterminated final `! ` line, which is what happens.
2. **The plain-suite `stopped` check is now dependent on the fatal-error
   trailer being present.** A log whose inputenc rejection is the last `! ` line
   with no `l.` echo and no fatal trailer after it would give 0 blocks and go
   red, blaming the recipe for a log-shape difference. — Verified: the inputenc
   block in the captured log is closed by the fatal `! ` line that follows it,
   not by an `l.` line. **Follow-up**: a candidate row; changing the reader here
   is the widening this milestone's gate declined.
3. **The block header still asserts "one plant per CLAUSE", which the rewritten
   matrix contradicts six lines later.** **Fix now.**
4. **"A clause carries more than one row where no single input shape isolates
   it" is untrue for two of the three duplicated pairs** — the two
   `entries missing` rows and the two `stopped one error` rows are two defect
   shapes reaching one clause, not one clause no shape isolates. **Fix now.**
5. **"nothing here or in the readings above it says anything about that class of
   error" overclaims, and points at the wrong readings.** `cmd_stopped` searches
   the signature and the character over the whole log before calling
   `error_blocks`, and is defined below it, not above. **Fix now.**
6. **The widened message can print "(0 error report(s) in the log)" for a log
   that visibly contains a `! ` line**, with no hint that unclosed is the
   reason. **Fix now.**
7. **The empty-term message describes a level the `marks` path never uses** —
   it reads "there is no term for this reading to hold to level 0" while the
   plant deliberately routes `0:` through the reading that discards the level.
   **Fix now.**
8. **A level that is not digits in any script changed message class.**
   `ab:foo` previously took the pair message and now takes the ASCII-digits
   one, which the docstring's rationale explains only for other scripts.
   **Fix now.**
9. **The matrix's `absent` rows are ordered silent / level / printed while the
   plants run silent / printed / level.** **Fix now.**
10. **The Scope cites `(D-118)`, which `cairn/DECISIONS.md` does not hold.**
    **Rejected**: D-118 is the cairn plugin's own decision id, cited by its
    tracking rulebook, not this repo's — the same point M33's review rejected
    on the same grounds.
11. **"(probed at T6)" now collides with M36's own T6.** The parenthetical was
    written for M33's task numbering and survived into a paragraph this branch
    rewrote. **Fix now**: the citation names its milestone.
12. **"one substitution per plant (M29)" is not backed by the new plant** —
    `unclosed.log` strips every error report and appends a tail. **Fix now**,
    with finding 3's rewrite of the same header.
13. **The pass line says the two unplanted clauses are "named above this
    block"; they are named inside this block's own header comment.**
    **Fix now.**

The reviewer separately verified as sound: both new plants discriminate against
the merge-base reader, `M33_PLANTED` counts 23 against 23 matrix rows, the
U+0663 literal is the right codepoint, no existing caller passes a spec the
narrowed `stated()` now refuses, and `bash -n` is clean.

No finding demonstrates an acceptance criterion failing inside its named
domain, and none is a defect in what this repo's extension does for its users —
every one is prose in the acceptance suite. No return floor is reached.

### Gate triage (2026-08-25)

The maintainer directed: fix the eleven prose findings, file finding 2, merge.
Applied on the branch — `error_blocks`' docstring now names the fatal-error
report it drops and the trade that drops it; the one-error failure message
reports how many `! ` lines it read blocks from and says an unclosed one opens
none; the empty-term message no longer names a level; the ASCII-digit rationale
covers every non-digit spelling; the block header's per-clause and
one-substitution claims are narrowed to what holds; the matrix's `absent` rows
run in the order the plants do; the T6 citation names M33; the pass line points
at the comment that opens its block. Finding 2 went to the acceptance-suite
hardening candidate row, promoted on a capture whose rejection is the log's
last `! ` line. Finding 10 rejected as recorded above. Both suite modes re-run
clean after the fixes.
