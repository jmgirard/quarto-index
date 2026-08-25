<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M35: The non-Latin-1 checks fail on the defects they claim to catch

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: `entries` and `absent` hold a term to an entry line's level as well
      as its text. Each reading reports red, naming the level clause, on an
      input stating a term at a level the render under it does not print that
      term at.
- [ ] AC2: `stopped` reports red, naming its one-error clause, on a LaTeX log
      whose stop signature and whose `Unicode character` line belong to
      different errors.
- [ ] AC3: `stopped` reports red, naming its signature clause, on a LaTeX log
      that carries no rejection at all.
- [ ] AC4: the suite's font guard stops the run, naming the missing TeX Live
      package, when any font file named by `examples/unicode.qmd`'s
      `mainfontoptions` block — the guard parsing that block for its list — is
      unfindable by `kpsewhich`.
- [ ] AC5: control (d) reads its own capture's producer and reports red when
      that producer does not name the engine README's third path states;
      shown red on a capture this suite already writes under another engine.
- [ ] AC6: the README recipe-block check reports red when the block's
      non-blank lines are not exactly the recipe lines the suite states, and
      red when a stated line is absent from `examples/unicode.qmd`.
- [ ] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
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

- [ ] T1: give `cmd_entries` and `cmd_absent`'s present-term signal the
      `(level, term)` pair `pdfindex.rows()` already returns
      (`tests/pdfindex.py:224`), taking each stated term's level from the
      suite. Assert `pdfindex.columns_carry_top_level` on the read set first,
      so a column of nothing but sub-entries cannot make the level reading
      lie (`tests/pdfindex.py:207`).
- [ ] T2: state the level beside the term list in `tests/run-tests.sh:609`
      under the ORACLE RULE that governs `M33_TERMS`, and update the four
      call sites (`tests/run-tests.sh:4249`, `:4353`, `:4366`, `:4380`).
      Plant, per reading, a term stated at a level the render does not print
      it at.
- [ ] T3: in `cmd_stopped` (`tests/unicodeprint.py:140`), match the stop
      signature and the `Unicode character` line within one error block rather
      than searching the whole log for each. Rebuild the two plants
      (`tests/run-tests.sh:11953`, `:11961`) on the engine control's LaTeX log:
      one with the rejection deleted, one splitting the signature and the
      character into separate errors.
- [ ] T4: replace the single `kpsewhich STIXTwoText-Regular.otf` guard
      (`tests/run-tests.sh:1373`) with a parse of `examples/unicode.qmd`'s
      `mainfontoptions` block into font filenames, each probed. Show the guard
      red with one face made unfindable, and show its parse non-empty.
- [ ] T5: add `pdfinfo` to the tool guards beside `pdftotext`
      (`tests/run-tests.sh:1365`), and read the no-engine capture's producer
      at control (d) (`tests/run-tests.sh:4380`), held to a producer string
      the suite states. Show it red against the recipe capture, which this
      suite writes under xelatex.
- [ ] T6: replace the block-in-fixture containment test
      (`tests/run-tests.sh:4417`) with a stated recipe-line list the block
      must equal, each line also required in the fixture. Plant a dropped
      `pdf-engine:` line in a copy of README and show it red.
- [ ] T7: run both suite modes; record the check counts; update the M33
      section comments that describe what each reading now reads, and the
      `pass` lines that summarize it.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-24: created by /milestone-plan; absorbs the ROADMAP's "M33 suite-hardening (clustered; corrected M34)" row, which is removed in the same commit.
- 2026-08-24: plan-gate criteria audit ran in REDUCED mode (internal tier) and returned two findings, both fixed before the questions were composed — a criterion binding the plant matrix rather than the check was rewritten as AC3 (a check-behavior promise), and a criterion hand-listing four font faces was rewritten as AC4, whose domain the guard's own parse of the fixture enumerates.
- 2026-08-24: audit deviation — this session is configured to not spawn subagents, so the audit ran inline in the authoring context rather than in a fresh-context [O] reader; the reader-freshness the instrument depends on was not obtained.
- 2026-08-24: plan gate chose reading the capture's producer with `pdfinfo` over keeping control (d)'s LaTeX log and reading its engine banner, because the producer is read from the captured artifact rather than a build scratch file (M24's capture rule) and was already the probe used by hand at M34's review; falsified by a Quarto or engine that writes no usable producer string into the PDF.
- 2026-08-24: plan gate chose simplifying README's recipe-block check to a stated line list over hardening it into a two-directional file comparison, because the checker-regress shape recommends simplifying a repo-internal checker and the stated list closes the reported hole with fewer moving parts; falsified by a recipe whose copyable block cannot be stated as a fixed line list — one carrying a value that legitimately varies between README and the fixture.
- 2026-08-24: plan gate chose one milestone over splitting the reader repairs from the guard-and-control repairs, because both halves edit one test section and the split's second half would wait on the first; falsified by the implementation running past three sittings or over the 150-line plan cap.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
