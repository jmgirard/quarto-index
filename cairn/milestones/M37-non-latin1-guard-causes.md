# M37: The non-Latin-1 guards report the cause they hit

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M36
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** m037-non-latin1-guard-causes

## Goal

The font guard, the producer reading and the README recipe-block check in
`tests/run-tests.sh` each name the cause they actually hit, and the clauses
they cannot reach are gone.

## Scope

**Surface tier: internal** — the deliverable is the acceptance suite's own
guards, readings and planted-defect probes; no consumer outside this repo
reads them.

**In:** the eleven `tests/run-tests.sh` findings M35's Review section filed.
F4: all four `require_recipe_fonts` failure classes report one hardcoded
"the TeX Live `stix2-otf` package is missing … the face is named on the line
above" (`:1509`), false for the three where no face is named. F3: a quoted or
multi-word `mainfont:`, a flow-style `mainfontoptions:`, or a block with no
`Extension=` mis-parses into that same message. F5: `[ -n "$faces" ]`
(`:1511`) is unreachable — `recipe_font_files` already exits 1 on an empty
list. F17: `check_recipe_block`'s `if not stated:` clause is likewise
unreachable. F7: `pdf_producer_names`' pipeline status is safe only because
both call sites sit in `&&`/`||` lists. F13, F14, F15: three plants that do not
build the input class their labels claim. F6: the parsed face list is captured
and discarded, so a green run never prints the guard's domain. F8: the
recipe-block check's fixture direction is a whole-file substring search.
F12: `M33_NOENGINE_PRODUCER` and README's `lualatex` are two hand statements
with no asserted correspondence.

Under the checker-regress disposition the gate took, F3 is closed by F4's
message repair rather than by widening the parser — a mis-parse then surfaces
as the face it could not find, which is readable. F6, F8 and F12 are closed by
narrowing what the suite claims and are not criterion-bound, a promise about a
check's own prose or output wording binding an instrument (D-118).

**Out:** the five `tests/unicodeprint.py` findings (F1, F9, F10, F11, F16) →
M36. The rest of the acceptance-suite hardening cluster — KI24, KI27–KI74,
KI81–85, KI87 — stays on its candidate row.

## Acceptance criteria

- [ ] AC1. Each of `require_recipe_fonts`' four failure paths reports the cause
      it actually hit — no `mainfont:`, no `mainfontoptions:` block, no `*Font=`
      face, or the specific face `kpsewhich` could not find — and only the last
      names the `stix2-otf` package. Each of the four is shown red by the
      self-test.
- [ ] AC2. The `[ -n "$faces" ]` clause in `require_pdf_tools`
      (`tests/run-tests.sh:1511`) and the `if not stated:` clause in
      `check_recipe_block` (`:4597`) are removed.
- [ ] AC3. `pdf_producer_names` returns a status of its own rather than its
      pipeline's: the self-test calls it outside an `&&`/`||` list on a file
      carrying no Producer line, and the run reports red rather than dying
      under `pipefail`.
- [ ] AC4. Each of the three plants M35-F13, F14 and F15 name builds the input
      class its label claims. The "no options block" mutation is bounded to the
      `mainfontoptions:` block by that block's own extent rather than by the
      `filters:` line that happens to follow it, and the extra-line README
      mutation to the `### Terms outside Latin-1` section; each is shown, on a
      fixture where its old form mutated a region outside that bound, to leave
      every byte outside its own bound unchanged. The `norejection.log`
      mutation asserts it removed at least one error report. Each of the three
      fails loudly, naming what it could not find, on an input carrying no
      region of the kind its label names.
- [ ] AC5. `tests/run-tests.sh` exits 0 in both plain and `--self-test` modes
      (the `generic` profile's verify slot, plus its self-test).

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5, T6
- AC5 → T8

## Tasks

- [x] T1. Give each `require_recipe_fonts` failure path its own message: the
      three `recipe_font_files` exits already say what they could not read, so
      surface them rather than replacing them, and reserve the `stix2-otf`
      sentence for the `kpsewhich` miss (`tests/run-tests.sh:1503-1509`).
- [x] T2. Plant all four: a fixture with no `mainfont:`, one with no
      `mainfontoptions:` block, one whose block names no `*Font=`, and one
      naming an unfindable face. Assert each red with its own cause named.
- [ ] T3. Delete the two unreachable clauses (`:1511`, `:4597`) and the pass
      lines that only they could reach.
- [ ] T4. Make `pdf_producer_names` (`:1447`) hold its own status — read
      `pdfinfo` into a variable and test it, rather than returning a pipeline's
      — and add a self-test call outside any `&&`/`||` list.
- [ ] T5. Bound the two `sed` plants: the "no options block" mutation to the
      `mainfontoptions:` block by its own extent, the extra-line README
      mutation to the `### Terms outside Latin-1` section as its sibling
      reordering plant already is.
- [ ] T6. Make the `grep -v … > norejection.log` mutation assert it emitted
      lines, and show each of the three plants failing loudly on a fixture
      where its old form would have gone silent or mutated the wrong region.
- [ ] T7. F6, F8 and F12, narrow-not-widen: print the face list on a green run;
      reword the recipe-block check's fixture-direction pass line to say each
      stated line appears somewhere in the fixture, not in its front matter;
      and state in the `M33_NOENGINE_PRODUCER` ORACLE RULE comment that it and
      README's engine word are two hand statements. Record all three
      dispositions, and F3's fold into T1, in the Decisions section.
- [ ] T8. Run both suite modes; state the resulting counts against the merge
      base in the work log.

## Work log

- 2026-08-24: created by /milestone-plan alongside M36; the gate's rejected alternatives and both criteria-audit rounds are recorded in that file's work log and cover this milestone too.
- 2026-08-25: branch m037-non-latin1-guard-causes cut from main at a631685; status in-progress.
- 2026-08-25: amendment gate — AC4's "fail loudly instead" ending was unsatisfiable for the two mutations bounded by construction: such a mutation succeeds correctly on the very fixture where its unbounded old form went wrong. Amended at the user's selection to bind those two to byte-identity outside their own bound on that fixture, and all three to a loud failure on an input carrying no region of the kind their label names; the third mutation is named `norejection.log` rather than `grep -v`, the form M35's own review commit 7680a3d replaced. No criterion added; AC4's promise narrows on the loud-failure half and is stated per mutation.
- 2026-08-25: criteria audit (reduced mode, internal tier) by a fresh [O] reader over the amended AC4: one finding — "bounded to the `mainfontoptions:` block whatever follows it" quantified over every possible continuation of the front matter, a domain no procedure the criterion names enumerates. Fixed before writing, to "by that block's own extent rather than by the `filters:` line that happens to follow it". Proportionality and instrument questions passed.

- 2026-08-25: T1+T2 in one commit — T1's message change moves the text T2's plants assert, so neither is green alone. `require_recipe_fonts` now reports the missing face with the `stix2-otf` sentence and the fixture name; the three front-matter causes reach the terminal as `recipe_font_files`' own exits, and `require_pdf_tools`' fail line points at them instead of restating one of them. Each of the four plants now also asserts whether the package is named: planting the M35 defect (the package sentence added to the no-`mainfont:` exit) turned the no-main-font plant red on that clause; unplanted, the self-test is green at 491 checks.

## Decisions

## Review
