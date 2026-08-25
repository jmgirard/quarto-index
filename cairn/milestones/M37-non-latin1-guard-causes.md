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
- [x] T3. Delete the two unreachable clauses (`:1511`, `:4597`) and the pass
      lines that only they could reach.
- [x] T4. Make `pdf_producer_names` (`:1447`) hold its own status — read
      `pdfinfo` into a variable and test it, rather than returning a pipeline's
      — and add a self-test call outside any `&&`/`||` list.
- [x] T5. Bound the two `sed` plants: the "no options block" mutation to the
      `mainfontoptions:` block by its own extent, the extra-line README
      mutation to the `### Terms outside Latin-1` section as its sibling
      reordering plant already is.
- [x] T6. Make the `grep -v … > norejection.log` mutation assert it emitted
      lines, and show each of the three plants failing loudly on a fixture
      where its old form would have gone silent or mutated the wrong region.
- [x] T7. F6, F8 and F12, narrow-not-widen: print the face list on a green run;
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

- 2026-08-25: T3 — both unreachable clauses removed. `[ -n "$faces" ]` sat after a `require_recipe_fonts` that exits 1 on an empty list, and `if not stated:` after a `printf` over a literal array `set -u` would have stopped. Neither had a pass line of its own. The recipe-line list's non-emptiness is now stated where it is read, pointing at the self-test plants that each name one of those lines; the face list's is covered by T7's printed domain. Self-test green at 491 checks.

- 2026-08-25: T4 — `pdf_producer_names` reads `pdfinfo` into a variable and absorbs its status there, so its two `return`s are the only statuses it produces. The self-test call was first written as `( set -eo pipefail; ... ) && rc=0 || rc=$?` and was green on the OLD form: bash suppresses errexit inside a subshell sitting in an `&&`/`||` list even when the subshell sets it again, so that shape reproduces the shielding the check exists to escape. Rewritten to background the subshell and read its status with `wait`, which leaves the call unshielded; on the old form planted back it goes red with <<printed no carries no Producer line report>>, and green on the repair at 491 checks.

- 2026-08-25: T5+T6 — the three mutations are named builders (`m37_drop_options_block`, `m37_add_unstated_line`, `m37_strip_error_reports`), each bounded to the region its label names and each exiting non-zero, naming what it could not find, over an input carrying no such region. The two M35 forms are kept beside them as `*_m35_form`, used by nothing but the demonstrations. Three demonstrations added: the options block on a fixture with `filters:` renamed, the README insertion on a document carrying a second `Extension=.otf` line in an appendix, and the log strip on a log carrying no error report. Each demonstration also asserts the M35 form differs there, so a fixture that stopped discriminating would be caught rather than pass.
- 2026-08-25: T6 — the `grep -v` form AC4 was written against is already gone: M35's own review commit 7680a3d replaced it with the python builder, which counts what it removed. What was owed was the demonstration, not the assertion.
- 2026-08-25: each of the three demonstrations planted and shown red. Strip builder with its zero-count clause removed: <<reported success over a log carrying no error report>>. Options demonstration fed the M35 form: <<the bounded mutation changed bytes outside the `mainfontoptions:` block: it emitted 111 character(s) against the 1268 the fixture carries with that block cut out>> — the M35 range deleted the document's body, which is M35-F13 measured. README demonstration fed the M35 form: <<the bounded form added 2 unstated line(s)>>. Unplanted, the self-test is green at 494 checks, up from 491.

- 2026-08-25: T7 — the face list is printed on a green run (4 faces, named), the recipe-block check's comment and both pass lines now say the fixture direction is a whole-file substring search rather than a front-matter line test, and the `M33_NOENGINE_PRODUCER` ORACLE RULE comment states that it and README's `lualatex` are two hand statements no check compares. All four dispositions, F3's fold into T1 among them, are in the Decisions section above. Self-test green at 496 checks.

## Decisions

- 2026-08-25 (F3, folded into T1). A `mainfont:` in quotes, a flow-style
  `mainfontoptions:`, or a block with no `Extension=` are all shapes
  `recipe_font_files` mis-parses. The parser is not widened. Each of them now
  surfaces as the face the guard could not assemble — a `kpsewhich` miss naming
  a filename the machine does not carry — which is a thing the reader can look
  at and act on, where a parse report would name a YAML shape the fixture is
  free to change. The fixture is one file in this repo, written by whoever
  changes the recipe; a parser covering every YAML spelling of it would be
  checker-regress on an input class nobody is going to write.
- 2026-08-25 (F6). The face list is printed on a green run rather than
  discarded. It is the guard's domain, parsed out of the fixture, so a run that
  probed one face and a run that probed four are otherwise the same green line.
  No criterion binds this: it is what a check prints, not what the suite
  certifies.
- 2026-08-25 (F8). The recipe-block check's fixture direction stays a
  whole-file substring search, and its comment and pass line now say so — each
  stated line occurs somewhere in the `.qmd`, not necessarily in its front
  matter. Narrowing the claim, not widening the check: what this clause is for
  is catching a stated line the fixture no longer carries at all, and the front
  matter is read for real by `recipe_font_files` and by the render the
  typeset-print check judges.
- 2026-08-25 (F12). `M33_NOENGINE_PRODUCER` and README's `lualatex` stay two
  hand statements, and the ORACLE RULE comment now says that no check compares
  them. They are not the same string — one is the Producer name LuaTeX writes,
  the other the engine word a reader sets — so a comparison would encode a rule
  about LuaTeX's own naming that this suite has no independent statement of.
  Keeping them in step is a maintainer's job, and the comment is where a
  maintainer would look.

## Review
