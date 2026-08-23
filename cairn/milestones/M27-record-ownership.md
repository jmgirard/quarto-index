# M27: A finding about today's behavior is a known issue, not a candidate row

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m027-record-ownership`

## Goal

Refile the findings that review has been appending to `cairn/ROADMAP.md`
candidate rows and `cairn/LESSONS.md` lines into the records that own them, so
both files fall back under their budgets and stop refilling.

## Scope

Internal tier: the deliverable is this repo's own tracking records, on which no
external consumer of the repo relies.

**In:** classifying every candidate row and lesson line by what it actually
holds; moving findings about current behavior into `cairn/DESIGN.md`'s
`## Known issues`; graduating the sixteen `cairn/LESSONS.md` lines that teach
how to build a check, an oracle or a criterion into `cairn/check-design.md`, a
repo doctrine module carrying its own line and byte budget in its header;
writing the boundary rule as a `cairn/DECISIONS.md` entry and pointing both
files' header comments at it.

**Out:** dropping any candidate row outright — the plan gate kept everything,
so a row either shrinks to its proposal or its content moves. Mechanizing the
byte budgets — `cairn_validate` is the plugin's, not this repo's, so the
budgets stay hand-checked at hygiene passes. Rewriting any graduated line —
the module carries the sixteen as they stand. Any change under `tests/` or
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
      `cairn/LESSONS.md` is absent from all of `cairn/DESIGN.md`,
      `cairn/check-design.md`, and this file's `## Decisions` section. Domain:
      every removed line in `git diff <merge-base>..HEAD -- cairn/ROADMAP.md
      cairn/LESSONS.md`, read whole.
- [ ] AC4: Every `- ` row under `## Candidates` in the committed
      `cairn/ROADMAP.md` states work this repo might do and carries no finding
      about how the extension behaves today. Domain: every such row in the
      committed file, read in order.
- [ ] AC5: `cairn/DECISIONS.md` carries a new entry stating which record holds
      a finding about current behavior and which holds proposed work, and the
      `## Candidates` comment in `cairn/ROADMAP.md` and the header comment in
      `cairn/LESSONS.md` each name that entry by its id.
- [ ] AC6: The sixteen `cairn/LESSONS.md` lines about how to build a check, an
      oracle or a criterion are absent from that file and present verbatim in
      `cairn/check-design.md`. Domain: every line the diff of
      `cairn/LESSONS.md` removes, compared byte for byte against the module's
      own lines.

## Coverage

- AC1 → T3, T4, T5, T6
- AC2 → T6
- AC3 → T1, T3, T4, T5
- AC4 → T1, T4
- AC5 → T2
- AC6 → T1, T5

## Tasks

- [x] T1: Read every `- ` row under `## Candidates` in `cairn/ROADMAP.md` (37
      at the merge base) and every `- ` line in `cairn/LESSONS.md` (41).
      Classify each clause as proposed work (stays), a finding about current
      behavior (moves to `## Known issues`), or lesson content a named check
      already enforces (retires). Commit the ledger to `## Decisions` here.
- [x] T2: Write the boundary entry in `cairn/DECISIONS.md`; point the
      `## Candidates` comment in `cairn/ROADMAP.md` and the header comment in
      `cairn/LESSONS.md` at it by id.
- [x] T3: Move the classified findings into `cairn/DESIGN.md`'s
      `## Known issues` (currently `_None._`), one entry per finding, each
      naming the review it came from. Start with the two heaviest rows —
      acceptance-suite hardening (7,601 bytes) and `marks_seen` (2,412).
- [x] T4: Rewrite each affected ROADMAP row down to the work it proposes, with
      a pointer to its `## Known issues` entry. Bound the pass with a command,
      not by eye (M17's lesson): require every clause the diff removes to
      appear in `cairn/DESIGN.md` or the T1 ledger before committing.
- [x] T5: Move the sixteen check-, oracle- and criterion-design lines out of
      `cairn/LESSONS.md` into `cairn/check-design.md` verbatim, giving the
      module a header that states its scope and its own line and byte budget.
      Confirm the move byte for byte, and run `tests/run-tests.sh --self-test`
      once to confirm no code moved.
- [x] T6: Re-measure `wc -c -l` on both files against AC1, run
      `cairn_validate.py`, and run `tests/run-tests.sh --self-test` once to
      confirm no code moved.

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: criteria audit ran in reduced mode (internal tier), in-session rather than in a spawned fresh-context reader, because this session is instructed not to spawn agents — the weaker arrangement M26 also hit. One finding: a draft AC3 promised removed text would appear "in the archive summary", which binds a record of verification rather than the records themselves; narrowed to `cairn/DESIGN.md` and this file's `## Decisions`. A draft AC6 promised `tests/plantdefect.py` fails on each planted defect, a test-harness property; narrowed to the lesson content, with the self-test run moved to T5.
- 2026-08-23: T2 wrote D-013 in `cairn/DECISIONS.md`; the `## Candidates` comment in `cairn/ROADMAP.md` and the header comment in `cairn/LESSONS.md` each name it. Verify slot green (275 checks).
- 2026-08-23: T3 wrote `cairn/DESIGN.md`'s `## Known issues` — 79 entries, KI1-KI79, grouped by area, each naming its review. Verify slot green (275 checks).
- 2026-08-23: T4 rewrote the candidate list to 28 rows, each stating work and pointing at its KI labels; six single-item suite rows folded into the acceptance-suite row. The pass was bounded by a vocabulary command over the removed lines, which found four real losses (KI10's accumulator names, two split hyphenated words, two dropped promotion conditions), all repaired; it now reports zero. ROADMAP is 7,064 bytes / 49 lines. Verify slot green (275 checks).
- 2026-08-23: T5 found the plan's retirement lever absent. `tests/run-tests.sh --self-test` passes 409 checks, and all 84 of its self-test assertions target a specific milestone's own readers (M20-M23), the fixture-check, and the warning-count discrimination helper; for six of the "prove a check discriminating" lesson's eight shapes it holds no assertion whose subject is the mistake, so there is nothing to plant into. Retiring only what it covers frees about 260 of the ~2,500 bytes AC1 needs — the falsifier the plan gate named for that route.
- 2026-08-23: amendment (substantive, taken at a mini gate): Scope In loses "retiring lesson content the acceptance suite's self-test already enforces" and gains graduating the sixteen check-, oracle- and criterion-design lines into `cairn/check-design.md` under the maturation exit; Scope Out gains "Rewriting any graduated line — the module carries the sixteen as they stand"; AC6 is replaced. The criteria set stays at six. Amended AC6: "The sixteen `cairn/LESSONS.md` lines about how to build a check, an oracle or a criterion are absent from that file and present verbatim in `cairn/check-design.md`. Domain: every line the diff of `cairn/LESSONS.md` removes, compared byte for byte against the module's own lines."
- 2026-08-23: the amended AC6 wording was audited in reduced mode (internal tier), in-session rather than by a spawned fresh-context reader, because this session is instructed not to spawn agents — the same weaker arrangement M26 and this milestone's plan recorded. The audit changed the instrument: the first draft bound the move with T4's word-level check, but Scope Out now fixes the lines as verbatim, so a byte-for-byte line comparison is available and strictly stronger; the draft's reliance on a scratch script review could not run was what the "read a criterion's named procedure against what the repo can actually run" lesson asks about, and the byte comparison removes it.
- 2026-08-23: T5 graduated the sixteen lines into `cairn/check-design.md` with a header stating its scope and a budget of under 40 lines and under 18,000 bytes. `cairn/LESSONS.md` is 7,796 bytes / 34 lines (AC1 wants <= 16,000 / <= 44); the module is 11,752 / 33. The byte-for-byte check reports 16 lines removed, 0 absent from the module, 0 still in LESSONS. Verify slot green with the self-test (409 checks).
- 2026-08-23: amendment (substantive, taken at a mini gate): AC3's destination set gains `cairn/check-design.md`, the module the earlier amendment created — the criterion had listed only `cairn/DESIGN.md` and this file's `## Decisions`, so the sixteen graduated lines failed it on a destination that did not exist when it was written. Same promise, three records instead of two; nothing widened or dropped. Amended AC3: "No text this milestone removes from `cairn/ROADMAP.md` or `cairn/LESSONS.md` is absent from all of `cairn/DESIGN.md`, `cairn/check-design.md`, and this file's `## Decisions` section. Domain: every removed line in `git diff <merge-base>..HEAD -- cairn/ROADMAP.md cairn/LESSONS.md`, read whole."
- 2026-08-23: the amended AC3 wording was audited in reduced mode (internal tier), in-session rather than by a spawned fresh-context reader, for the reason the earlier audit line gives. No finding: the amendment changes the destination set and no promise, and the procedure it names is one the repo runs.
- 2026-08-23: T6 measured `cairn/ROADMAP.md` at 7,064 bytes / 49 lines and `cairn/LESSONS.md` at 7,928 / 36, against AC1's 18,000 / 52 and 16,000 / 44. `cairn_validate.py` passes all 16 checks with all 7 advisories OK. `tests/run-tests.sh --self-test` passes 409 checks, unchanged from the merge base, so no code moved. The removed-text bound over both files reports 54 removed lines and zero uncovered words.
- 2026-08-23: plan gate chose refiling findings into `cairn/DESIGN.md`'s `## Known issues` with a recorded boundary rule over compressing row prose in place, because compression leaves the append-a-finding-to-a-work-row mechanism intact and both files return to their caps in roughly five milestones at the observed ~500 bytes per milestone; falsified by the files climbing back toward their caps after this milestone without any row gaining a finding clause.
- 2026-08-23: T1 classified all 37 candidate rows and framed the lesson exits; the ledger is in `## Decisions`. Findings take labels KI1-KI79 in `cairn/DESIGN.md`; six single-item suite rows fold into the acceptance-suite-hardening row. Verify slot green (275 checks).
- 2026-08-23: plan gate chose retiring the enforced variations of the "prove a check discriminating" lesson over keeping the line whole and cutting mid-sized lessons instead, because the line is 2,995 bytes of 18,439 and the repo now runs a planted-defect self-test; falsified by a self-test run that passes with a variation's defect planted.

## Decisions

### T1 classification ledger (2026-08-23)

Every `- ` row under `## Candidates` (37 at the merge base) and every `- ` line
in `cairn/LESSONS.md` (41), classified as proposed work (stays in ROADMAP), a
finding about current behavior (moves to `cairn/DESIGN.md`'s `## Known issues`
as `KI<n>`), or content a named check already enforces (retires). Findings are
carried into `## Known issues` in full; this ledger is the map from each source
row to the labels its content became, so no removed clause is unaccounted for.

**Candidate rows → dispositions.** Left column is the row's opening words at
the merge base.

| Row | Findings moved | Proposal kept |
|---|---|---|
| M13 review follow-ups | KI75, KI73 | dedupe `examples/.gitignore`; make the claim check assert emission |
| Reconcile the example corpus | KI72 | reconcile the corpus |
| Emptied-place report follow-ups | KI21, KI22, KI23 | settle what a block position is measured over |
| Module-split follow-ups | KI76, KI77 | rewrap under 80 columns; narrow module exports |
| Release bundle | — | unchanged |
| Chapter-based locator labels | — | unchanged |
| Locator-control follow-ups | KI5, KI74 | the three author-control items |
| A range spanning two chapters | KI19, KI20 | pair them, on the record shape |
| Book sidecar-store follow-ups | KI16, KI17, KI18 | prune; stabilize key order; decide the non-`book.render` page |
| A leftover `.ind` | KI4 | cover it with a gobbling stand-in |
| Multiple named indexes | — | unchanged |
| Quarto version floor + CI matrix | KI79 | the floor and the matrix |
| Non-Latin-1 scripts | KI6 | the engine/font decision |
| Acceptance-suite hardening | KI27–KI74 | close them; absorbs six single-item suite rows below |
| Windows checkouts | KI78 | support them |
| `marks_seen` | KI10 | guard a cell added after M26 joining no `reset` |
| `\index` in a moving argument | KI2 | probe it; protect `\quartoindexregister` |
| see-also entries keep their locators | KI9 | settle the semantics and the repeated `\seename` |
| Escaping probe covers singly | KI71 | absorbed into acceptance-suite hardening |
| `[` and `]` not in the escape table | KI1 | add them |
| Bare unquoted values | KI70 | absorbed into acceptance-suite hardening |
| Demo manifests have no count | KI67 | absorbed into acceptance-suite hardening |
| Demo's makeindex acceptance | KI68 | absorbed into acceptance-suite hardening |
| `\printindex` precedes the bibliography | KI3 | move it after |
| PDF cross-reference substring checks | KI69 | absorbed into acceptance-suite hardening |
| Attribute values in pass-through formats | KI15 | settle whether the residue is acceptable |
| Planted-defect self-test is `.tex`-only | KI66 | absorbed into acceptance-suite hardening |
| Marker in YAML `abstract:` | KI11 | reach it |
| `resolve_markers` rebuilds every list | KI12, KI52 | restore byte-level evidence |
| Headings consumed by Quarto constructs | KI13 | pin the invariant |
| Locator hrefs cannot be escaped | KI14 | handle `#`/`?` in a chapter filename |
| Sort-key paths keyed unclamped | KI7 | key them on what the back-end prints |
| An empty entry tree | KI8 | report it |
| Hard-coded English strings | KI26 | adopt a `lang` policy |
| A mark whose `entry=` is all empty | KI24 | absorbed into acceptance-suite hardening |
| The chapter-count report's numbers | KI25 | absorbed into the emptied-place row |
| The two range traversals | KI20 | absorbed into the two-chapter range row |

**Lesson lines.** A lesson stays where it states transferable craft about
Pandoc, LaTeX, makeindex or check design that no `cairn/` file owns and no test
fires on. It leaves on one of two exits: **ownership**, where the line is a
statement about how this repo behaves today, which `## Known issues` now owns
under the boundary entry T2 writes; or **enforcement**, where a named check in
`tests/run-tests.sh` fails on the mistake the line warns about. Which lines
those are is settled at T5 against a `tests/run-tests.sh --self-test` run, and
recorded there with the covering check named; nothing is retired on this
ledger's authority alone.

### T4 bound, and what it left (2026-08-23)

The rewrite was bounded by a command, not by eye (M17's lesson): for every line
this milestone removes from `cairn/ROADMAP.md`, every word of four or more
characters in it must appear in `cairn/DESIGN.md`, this file, the rewritten row
that replaced it, or a lesson line that stayed. A substring bound was tried
first and rejected — the move rewrapped and reworded the prose, so it flagged
reflow as loss and could not distinguish the two. The vocabulary bound found
four real ones: `KI10` had summarized the accumulator row as "17 accumulators"
and dropped every name and mechanism (restored in full); `KI7` and `KI25` had
each split a hyphenated word across a line (rewrapped); and two promotion
conditions had been dropped from their rewritten rows — that pairing by entry
cannot tell two overlapping ranges of one term apart, and that the two-chapter
range promotes on a derivation path reading the mark's rewritten content (both
restored). What the bound still reports is accounted for here.

**Two rows' own narrowing history.** Neither a finding nor proposed work, so
D-013 sends it to git rather than to `## Known issues`; it is recorded here so
nothing removed is unaccounted for.

- The M13 row read: "added 2026-08-19, widened 2026-08-20, narrowed 2026-08-21
  (M19 absorbed both depth-versus-drop wording items, the extra-sort report's
  and M18's fold-rewritten-target report's)". Its `claim check asserting a
  string is in README` clause survives as KI73.
- The acceptance-suite row read, as of M25's correction: "NARROWED 2026-08-23:
  M24 absorbed every item whose cause is a check reading a working-tree
  `examples/` artifact (members in the milestone file, in git), and M25 absorbed
  the bare-`(W)` controls and the source-shape scans (the twelve-scan pin; the
  four FIRST-match scans, plus `store-names`, `latex-escape-table` and
  `m15-joined-messages`) under D-011 — corrected M25 review, which struck the
  clauses M25 closed and restored three this row wrongly listed as absorbed
  (`:format(` blindness, out by M25's Scope; the one-of-nine probe and M17-AC1
  unguarded, neither given a check), all three open below; what follows is the
  remainder, plus the residual risk D-004 and D-011 each record here." The three
  restored items are KI58, KI55 and KI57; the residual risks are KI52. Also
  removed from that row: "the script-exit-code item shipped in M01 and
  `\printindex` ordering has its own row", and "and again by that review's
  three-lens fan-out (full text in M24's Review section)".

**Accepted word-level residue.** Three words the bound reports whose content did
land, in different grammar: `mirrors` (KI69 writes "the approach mirrors M02's
own AC6"), `etc.` (KI15 writes "`data-see` and its siblings in gfm"), and
`author-terms` (the M07 row's cross-reference to the non-Latin-1 row, which KI26
carries as "Distinct from KI6, which is about what an author writes").

### T5 disposition of the lesson family (2026-08-23)

The T1 ledger left the lesson exits to be settled here against a self-test run.
The run settles them against the plan's expectation: the enforcement exit does
not reach the family, because the self-test's subject is a past milestone's own
readers rather than the mistakes the lines warn about, and the ownership exit
reaches only fragments. The exit the family does meet is maturation — it teaches
transferable craft, it had been extended or consolidated many times over, and
neither other exit applies — so all sixteen lines graduate whole into
`cairn/check-design.md`, verbatim, with their dates and milestone attributions
intact. Nothing is retired and nothing is rewritten. The two shapes the
self-test does cover are named here for the record: the "a grep matching any
instance of a warning fences nothing" clause is enforced by the
`warn_discrimination` helper in `tests/run-tests.sh`, which fails a warning
check that still passes on a log with its pattern removed or duplicated; and
the "where the property is positional, assert it by breaking it and rendering"
prescription is enacted by the M23 self-test, which renders nine broken trees
and requires each break to change what the fixture renders. Both stay in the
module rather than being cut, since the module carries the family whole.

## Review
