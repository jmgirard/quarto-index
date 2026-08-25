<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M35: The non-Latin-1 checks fail on the defects they claim to catch

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Branch/PR:** m035-non-latin1-check-hardening · PR #35 (https://github.com/jmgirard/quarto-index/pull/35)   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The six readings, guards and controls M33 and M34 built for terms outside
Latin-1 discriminate the defects their prose claims, each shown red on an
input of the class it names.

## Scope
<!-- owner: plan · create/amend-via-gate -->

Surface tier: **internal** — the deliverable is this repo's own acceptance
suite, which no consumer of the extension installs or runs.

**In:** six repairs the M33 and M34 reviews left on one ROADMAP row.
`tests/unicodeprint.py`'s `entries` and `absent` gain the index level, which
they read past today; `stopped` requires its stop signature and its named
character to come from one error rather than from the log independently, and
is shown red on a LaTeX log rather than on Quarto stdout. In
`tests/run-tests.sh`: the font guard covers every face the fixture's
`mainfontoptions` names rather than `-Regular` alone; control (d) reads which
engine produced its capture; and README's copyable recipe block is held to a
stated line list instead of a one-directional containment test.

**Out:** every other item on the acceptance-suite hardening rows (KI27-KI74,
KI81-KI85) → that clustered candidate row. Any change to what the extension
emits, to README's recipe, or to `examples/unicode.qmd`'s term set → not this
milestone; a term printing wrongly under the recipe is an IP2 defect and takes
its own milestone.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `entries` and `absent` hold a term to an entry line's level as well
      as its text. Each reading reports red, naming the level clause, on an
      input stating a term at a level the render under it does not print that
      term at.
- [x] AC2: `stopped` reports red, naming its one-error clause, on a LaTeX log
      whose stop signature and whose `Unicode character` line belong to
      different errors.
- [x] AC3: `stopped` reports red, naming its signature clause, on a LaTeX log
      that carries no rejection at all.
- [x] AC4: the suite's font guard stops the run, naming the missing TeX Live
      package, when any font file named by `examples/unicode.qmd`'s
      `mainfontoptions` block — the guard parsing that block for its list — is
      unfindable by `kpsewhich`.
- [x] AC5: control (d) reads its own capture's producer and reports red when
      that producer does not name the engine README's third path states;
      shown red on a capture this suite already writes under another engine.
- [x] AC6: the README recipe-block check reports red when the block's
      non-blank lines are not exactly the recipe lines the suite states, and
      red when a stated line is absent from `examples/unicode.qmd`.
- [x] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
      0, and the milestone states the check counts before and after.

## Coverage
<!-- owner: plan · create/amend-via-gate; review reads to fence evidence. -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: give `cmd_entries` and `cmd_absent`'s present-term signal the
      `(level, term)` pair `pdfindex.rows()` already returns
      (`tests/pdfindex.py:224`), taking each stated term's level from the
      suite. Assert `pdfindex.columns_carry_top_level` on the read set first,
      so a column of nothing but sub-entries cannot make the level reading
      lie (`tests/pdfindex.py:207`).
- [x] T2: state the level beside the term list in `tests/run-tests.sh:609`
      under the ORACLE RULE that governs `M33_TERMS`, and update the four
      call sites (`tests/run-tests.sh:4249`, `:4353`, `:4366`, `:4380`).
      Plant, per reading, a term stated at a level the render does not print
      it at.
- [x] T3: in `cmd_stopped` (`tests/unicodeprint.py:140`), match the stop
      signature and the `Unicode character` line within one error block rather
      than searching the whole log for each. Rebuild the two plants
      (`tests/run-tests.sh:11953`, `:11961`) on the engine control's LaTeX log:
      one with the rejection deleted, one splitting the signature and the
      character into separate errors.
- [x] T4: replace the single `kpsewhich STIXTwoText-Regular.otf` guard
      (`tests/run-tests.sh:1373`) with a parse of `examples/unicode.qmd`'s
      `mainfontoptions` block into font filenames, each probed. Show the guard
      red with one face made unfindable, and show its parse non-empty.
- [x] T5: add `pdfinfo` to the tool guards beside `pdftotext`
      (`tests/run-tests.sh:1365`), and read the no-engine capture's producer
      at control (d) (`tests/run-tests.sh:4380`), held to a producer string
      the suite states. Show it red against the recipe capture, which this
      suite writes under xelatex.
- [x] T6: replace the block-in-fixture containment test
      (`tests/run-tests.sh:4417`) with a stated recipe-line list the block
      must equal, each line also required in the fixture. Plant a dropped
      `pdf-engine:` line in a copy of README and show it red.
- [x] T7: run both suite modes; record the check counts; update the M33
      section comments that describe what each reading now reads, and the
      `pass` lines that summarize it.
- [x] T8: move the PDF tool guard (`require_pdf_tools`, which carries T4's font
      guard) from the AC6 section to the head of the M33 section, ahead of the
      first compile in the run, so a face this machine cannot find stops the
      run at the guard rather than at the render the guard exists to protect.
      Added 2026-08-24 from the review return on AC4.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-24: created by /milestone-plan; absorbs the ROADMAP's "M33 suite-hardening (clustered; corrected M34)" row, which is removed in the same commit.
- 2026-08-24: plan-gate criteria audit ran in REDUCED mode (internal tier) and returned two findings, both fixed before the questions were composed — a criterion binding the plant matrix rather than the check was rewritten as AC3 (a check-behavior promise), and a criterion hand-listing four font faces was rewritten as AC4, whose domain the guard's own parse of the fixture enumerates.
- 2026-08-24: audit deviation — this session is configured to not spawn subagents, so the audit ran inline in the authoring context rather than in a fresh-context [O] reader; the reader-freshness the instrument depends on was not obtained.
- 2026-08-24: plan gate chose reading the capture's producer with `pdfinfo` over keeping control (d)'s LaTeX log and reading its engine banner, because the producer is read from the captured artifact rather than a build scratch file (M24's capture rule) and was already the probe used by hand at M34's review; falsified by a Quarto or engine that writes no usable producer string into the PDF.
- 2026-08-24: plan gate chose simplifying README's recipe-block check to a stated line list over hardening it into a two-directional file comparison, because the checker-regress shape recommends simplifying a repo-internal checker and the stated list closes the reported hole with fewer moving parts; falsified by a recipe whose copyable block cannot be stated as a fixed line list — one carrying a value that legitimately varies between README and the fixture.
- 2026-08-24: plan gate chose one milestone over splitting the reader repairs from the guard-and-control repairs, because both halves edit one test section and the split's second half would wait on the first; falsified by the implementation running past three sittings or over the 150-line plan cap.
- 2026-08-24: T1+T2 landed together — the reader change and its call sites cannot be green apart, so one commit ticks both; `entries` and `absent` now take `<level>:<term>`, assert `columns_carry_top_level` before reading a level, and three new plants cover the two level clauses and the pair form (15 M33 plants -> 18); suite 351 checks, exit 0.
- 2026-08-24: T3 — `stopped` now parses the log into TeX error reports (`! ` opens one, the echoed `l.<n>` line closes it) and requires the signature and an indexed character in the SAME report; its three plants are all mutations of the engine control's LaTeX log — rejection deleted, character replaced, the two split into separate errors. The M33 plant summary said "fifteen plants over fifteen reachable clauses" while the file held sixteen plants naming fourteen distinct clauses; it now states the counts the file has (twenty plants, eighteen distinct clauses). Self-test 487 checks, exit 0.
- 2026-08-24: T4 — the font guard now parses `examples/unicode.qmd`'s `mainfont:` stem and `mainfontoptions:` `*Font=` lines into filenames (4 faces here, was 1 hardcoded) and probes each with `kpsewhich`; four plants show it red on a copy of the fixture with a face renamed to a file no TeX tree carries, with no `*Font=` key, with no options block, and with no `mainfont:`, and the unplanted fixture is required green first. Self-test 488 checks, exit 0.
- 2026-08-24: T5 — `pdfinfo` joined the tool guards at a question gate and is recorded as D-020; control (d) now reads its own capture's `Producer` line and requires it to name `LuaTeX`, with two plants — this suite's own xelatex recipe capture, and a file carrying no `Producer` line. Self-test 490 checks, exit 0.
- 2026-08-24: T6 — the README recipe block is now held to `README_RECIPE_LINES`, eight lines the suite states under an ORACLE RULE, equal in both directions and in order, with each stated line still required in the fixture; four plants show it red on a dropped `pdf-engine:` line, a reordering, an unstated line, and a stated line the fixture no longer carries. The `README_UNICODE_CLAIMS` header comment saying control (d) never reads which engine produced its render was corrected in the same commit — T5 made it false. Self-test 491 checks, exit 0.
- 2026-08-24: T7 — the M33-AC3 and M33-AC4 section comments now describe the level-qualified positive signal, control (d)'s producer reading, and the two-directional block check. Check counts: merge base 351 plain / 487 self-test; this branch 352 plain / 491 self-test (+1 plain, the producer reading's own line; +4 self-test, that line plus the three new M35 plant summaries). One plain run died on a Quarto segfault rendering marker-sites.qmd to gfm, unrelated to this branch; the immediately following self-test run and a re-run of plain mode both passed clean.
- 2026-08-24: review returned M35 to in-progress — AC4 fails: the font guard sits in `require_pdf_tools`, called at `tests/run-tests.sh:4896`, after the M33 renders at `:4385`; with an unfindable face planted in `examples/unicode.qmd` the run died at "M33-AC1: ... failed to render to PDF under the documented recipe" and the guard, and its `stix2-otf` message, never ran. AC1/AC2/AC3/AC5/AC6/AC7 verified with fresh evidence; 13 further diff-lens findings recorded in the Review section, untriaged.

- 2026-08-24: T8 — the whole PDF tool guard moved from `tests/run-tests.sh:4894` (the AC6 section) to `:4391`, immediately before the M33 recipe render, which is the first compile in the run; the AC6 header comment now points at the new call site and the later re-call at `:9329` is untouched. Re-planting the defect AC4 names — `BoldFont=*-Bold` changed to a face no TeX tree carries — the run now dies at "FAIL: STIXTwoText-NoSuchFaceHere.otf is not findable by kpsewhich" followed by the guard's `tlmgr install stix2-otf` line, with no M33 render attempted; the fixture was restored and both modes re-run clean at 352 plain / 491 self-test, the same counts T7 recorded.
- 2026-08-24: minor plan amendment — T8 added to the task list as the discovered repair for the AC4 return; Goal, Scope, Acceptance criteria and Coverage untouched, AC4 still mapping to T4.
- 2026-08-24: the 13 diff-lens findings the review recorded unactioned stay unactioned by user selection at this session's question gate, for triage at the re-review gate.
- 2026-08-24: review round 2 — all seven criteria met with fresh evidence, AC4 ticked; consistency gate clean; three lenses returned 18 consolidated findings, none meeting the return floor (F1 falls outside AC2's domain, F3/F4 outside AC4's, both verified against the implementation); dispositions taken at the merge gate.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-08-24 against PR #35. Suite run fresh on this branch: plain
mode 352 checks exit 0; `--self-test` 491 checks exit 0.

**Criterion evidence.**

- AC1 — met. `entries` run by hand on this run's recipe capture with `Ascii`
  stated at level 1 exits 1 with "prints at level [0], not at level 1, the
  level the suite states for it"; `absent` with the same present-term spec
  exits 1 with "not at level 1, the level the control states for its
  present-term". Suite line: "all 8 terms print as their own entry at the
  level the suite states".
- AC2 — met. `stopped` run on a copy of this run's engine control log with the
  `Unicode character` error closed early and a second error opened around the
  signature exits 1 with "but never in one error: the rejection that stopped
  this render and the character this fixture indexes are separate errors".
  The unmutated log passes on the same call.
- AC3 — met. `stopped` on a copy of that log with every `! ` line removed
  (0 errors, 0 signature lines) exits 1 with "does not carry 'not set up for
  use with LaTeX'".
- AC4 — NOT met. See the return below.
- AC5 — met. Self-test: control (d)'s producer reading names LuaTeX on the
  no-engine capture and goes red both on this suite's own xelatex recipe
  capture ("does not name") and on a file carrying no Producer line.
- AC6 — met. Self-test: the block check holds README's block to the 8 stated
  lines in both directions and goes red on a dropped `pdf-engine:` line, a
  reordering, an unstated line, and a stated line the fixture no longer
  carries. Plain run line 159: the 8 lines are exactly the stated ones, in
  order, each also verbatim in the fixture.
- AC7 — met. Both modes exit 0 at 352 / 491 checks; the work log states the
  merge-base counts (351 / 487) beside them.

**Consistency gate.** `cairn_validate.py` exit 0, all checks passed, no
advisory fired. No DESIGN principle changed, so `cairn_impact.py` was not run.
The `generic` profile names no toolchain checks.

**Fresh-context review.** Three lenses, distinct evidence bases. The
blame-history lens and the prior-review lens each reported zero findings; the
prior-review lens confirmed the diff implements what M33's R4/R6/R8/R12 and
M34's F2/F9 asked for. The diff-bug lens reported 14 ranked findings; its
first is the return below. The remaining 13 stand unactioned pending the
re-review gate, and are recorded here rather than triaged now, since the gate
was not reached: (2) `error_blocks` ends the final block at EOF, so trailing
text after an unterminated `! ` error is absorbed into it; (3) no plant
reaches `require_pdf_tools`' own package-naming `fail` line; (4) the parsed
face list is captured and discarded, so a plain run never prints the guard's
domain; (5) the "no rejection" plant deletes only the signature line, leaving
the inputenc error, so its label overstates the input; (6) `levelled()`'s
`columns_carry_top_level` clause is reachable but unplanted while the summary
line claims a plant per clause; (7) the fixture-direction check is a substring
search over the whole `.qmd`, not a front-matter line test; (8) the
`fail-noengine-engine` claim row's Quarto-version qualifier is not read;
(9) the "no options block" plant's `sed` range depends on `filters:` following
the font block; (10) a missing `Extension=` yields extensionless probe names
and a misdirected `tlmgr` message; (11) `pdf_producer_names`' pipeline status
is safe only because both call sites sit in `&&`/`||` lists; (12) `cmd_marks`
requires the level prefix but never reads it, and no plant exercises it;
(13) `M33_NOENGINE_PRODUCER` and README's `lualatex` word are independent hand
statements with no asserted correspondence; (14) `stated()` accepts non-ASCII
digits.

**Return.** AC4 fails inside its own domain. The font guard lives in
`require_pdf_tools`, which `run_all_checks` calls at `tests/run-tests.sh:4896`
— after the four M33 renders at `:4385` and `:4425-4538` that it exists to
protect. Verified by planting the defect the criterion names: with
`examples/unicode.qmd`'s `BoldFont=*-Bold` changed to a face no TeX tree
carries, the suite died at `FAIL: M33-AC1: examples/unicode.qmd failed to
render to PDF under the documented recipe`, the string `stix2-otf` appeared
nowhere in the run, and the guard never executed. The criterion promises the
guard stops the run naming the missing package; on the one input class it
quantifies over, a different check stops the run naming something else.


### Round 2 — 2026-08-24

Re-reviewed against PR #35 after the AC4 return. `main` had not moved since the
branch was cut, so no merge was needed. Suite run fresh on this branch: plain
mode 352 checks exit 0; `--self-test` 491 checks exit 0.

**Criterion evidence.** Every criterion re-executed this round; AC4 is ticked
here for the first time.

- AC1 — met. `entries` on this round's recipe capture with `Ascii` stated at
  level 1 exits 1 with "prints at level [0], not at level 1, the level the
  suite states for it"; `absent` on the no-font capture with the same
  present-term spec exits 1 with "not at level 1, the level the control states
  for its present-term". Plain run: "all 8 terms print as their own entry at
  the level the suite states".
- AC2 — met. `stopped` on a copy of this round's engine control log with the
  `Unicode character` error closed early and a second error opened around the
  signature exits 1 with "but never in one error … (3 error report(s) in the
  log)". The unmutated log passes the same call, naming U+03B8 in one report —
  shown to pass for the claim's reason, not merely to pass.
- AC3 — met. `stopped` on a copy of that log with every error report removed
  whole (0 `! ` lines, 0 signature lines) exits 1 with "does not carry 'not set
  up for use with LaTeX'".
- AC4 — met. Planted the defect the criterion names: `BoldFont=*-Bold` in
  `examples/unicode.qmd` changed to a face no TeX tree carries. The run died at
  "FAIL: STIXTwoText-NoSuchFaceHere.otf is not findable by kpsewhich" followed
  by the guard's `tlmgr install stix2-otf` line, with no M33 render attempted —
  the last green line before it is the marks check. Fixture restored, tree
  clean. The unplanted parse prints the fixture's four faces.
- AC5 — met. Plain run: the no-engine capture "was produced by LuaTeX-1.24.0,
  which names LuaTeX". Self-test: red on this suite's own xelatex recipe
  capture and on a file carrying no Producer line.
- AC6 — met. Plain run: the 8 block lines are exactly the stated ones, in
  order, each verbatim in the fixture. Self-test: red on a dropped
  `pdf-engine:` line, a reordering, an unstated line, and a stated line the
  fixture no longer carries.
- AC7 — met. Both modes exit 0 at 352 / 491 checks, against merge base
  351 / 487.

**Consistency gate.** `cairn_validate.py` exit 0, every check passed, no
advisory fired. No DESIGN principle changed, so `cairn_impact.py` was not run.
The `generic` profile names no toolchain checks.

**Fresh-context review.** Three lenses, distinct evidence bases. The
prior-review lens reported no prior-review evidence of reintroduction: the one
prior finding on these files is this milestone's own AC4 return, which T8
repairs, and the GitHub inline-comment probe returned empty, so the PR-thread
surface was not walked. The blame-history lens reported no violations — it
independently confirmed no PDF render precedes the guard's new call site, and
that T5 added control (d)'s engine reading beside the existing positive
assertion rather than replacing it (the M34 lesson against flipping a control).
Its two other items restate findings already on this list. The diff-bug lens
reported 18 ranked findings, a superset of the 13 the first round left
untriaged; the consolidated list is below, verified and triaged at the gate.

**Return floor.** No finding returns the milestone. The top-ranked finding (F1)
claims AC2 can pass green in its own domain; verified against the
implementation rather than the account: on a log where the signature and the
`Unicode character` line genuinely belong to two error reports, `stopped` still
reports red, because a `! ` line always closes the preceding block and two real
errors can never merge. The green case absorbs a `Unicode character` mention
that belongs to no error at all — a real gap in `error_blocks`, outside what
AC2 quantifies over. F3 and F4 likewise fall outside AC4's domain: on the
re-spelled fixtures the guard goes loudly red naming what it could not read,
never silently green, and today's `examples/unicode.qmd` is in the shape the
parse handles. Nothing on the list touches what the extension does for its
users; the declared tier is internal.

**Findings and disposition.** Ranked most severe first, as reported.

- F1: `error_blocks` closes an unterminated final error at EOF, so a
  `Unicode character` mention in trailing non-error chatter is absorbed into
  it and `stopped` reports "in one error report". Verified green on such a log.
- F2: the AC3 plant is `grep -v 'not set up for use with LaTeX'`, which deletes
  one continuation line and leaves the inputenc error standing; its label "a
  LaTeX log with the rejection deleted" overstates what it plants.
- F3: `recipe_font_files` parses only today's fixture shape — a quoted or
  multi-word `mainfont:`, a flow-style `mainfontoptions:`, a block with no
  `Extension=`, or an explicitly-named face each mis-parse. Verified: the
  quoted and flow-style fixtures both exit 1.
- F4: all four guard failure classes report the same hardcoded "the TeX Live
  `stix2-otf` package is missing … the face is named on the line above",
  which is false for the three where no face is named.
- F5: `[ -n "$faces" ] || fail "the font guard probed no faces at all"` is
  unreachable — `recipe_font_files` already exits 1 on an empty list.
- F6: the parsed face list is captured by command substitution and discarded,
  so a green run never prints the guard's domain; and no plant drives
  `require_pdf_tools`' own package-naming `fail` line.
- F7: `pdf_producer_names`' pipeline status is safe only because both call
  sites sit in `&&`/`||` lists; a bare third call site would die wordlessly
  under `pipefail`.
- F8: the fixture direction of the recipe-block check is a substring search
  over the whole `.qmd`, not a front-matter line test.
- F9: `levelled()`'s `columns_carry_top_level` clause and `read_entries`' "no
  entry lines" branch are reachable but unplanted, while the pass line claims
  a plant per clause.
- F10: `stated()` accepts non-ASCII digits as a level and an empty term.
  Verified: `'٣:foo'` → `(3, 'foo')`, `'0:'` → `(0, '')`.
- F11: `cmd_marks` requires the `<level>:<term>` pair and then discards the
  level, with no plant on that new argv contract.
- F12: `M33_NOENGINE_PRODUCER=LuaTeX` and README's `lualatex` are independent
  hand statements with no asserted correspondence, and the claim row's
  `Quarto 1.10` qualifier is read nowhere.
- F13: the "no options block" plant's `sed` range depends on `filters:`
  following the font block; moved or renamed, it deletes the fixture's body.
- F14: the extra-line README plant is not bounded to the `### Terms outside
  Latin-1` section, unlike its sibling reordering plant.
- F15: the bare `grep -v … > norejection.log` mutation would kill the run
  wordlessly under `set -e` if it ever emitted no lines.
- F16: `error_blocks` recognizes only `! ` with a following space, so
  pdfTeX's `!pdfTeX error:` opens no block.
- F17: `check_recipe_block`'s `if not stated:` clause is unreachable from any
  input the suite can produce.
- F18: the `M33_NOENGINE_PRODUCER` ORACLE RULE comment is ungrammatical and
  does not say what it governs.

Dispositions are recorded at the merge gate below.
