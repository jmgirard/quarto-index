<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M111: Three suite checks tell apart what they now read alike

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP6   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — acceptance-suite checks and self-test plants, which no user of the extension runs   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m111-suite-checks-tell-apart   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Three acceptance-suite checks that now pass or fail alike on two different
states each tell those states apart.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a cluster of the older acceptance-suite backlog, the three entries
KI275, KI276 and KI277 in `cairn/DESIGN.md`. `check_warning_count` fails on a
log that does not exist (KI277), with a self-test case for it and a repair of
any call site the full run shows reading a log no render writes. The M079-AC1
leg checks which of the two refusal wordings each yielding mark's report
carries (KI275), with a plant that swaps them. The M090 T3 plant also fails on
the line the T2 plant expects (KI276). The three entries are removed from
`cairn/DESIGN.md`.

**Out:**
- KI274, a plant reaching the leg's grouped exactly-one clause: left out at
  this plan gate, M090's gate choice standing until a rendered case reaches
  two minted anchors on one printed term. The entry stays a known issue.
- Every other entry under the two acceptance-suite subheadings: stays there,
  under the backlog candidate row, for a later named cluster.
- Other helpers in `tests/run-tests.sh` that count over a log: not swept here.
  One found in passing becomes a known issue.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [ ] AC1: `check_warning_count` in `tests/run-tests.sh` fails with a message
      naming the log path when the log it is given does not exist, both for an
      expected count of 0 and for a positive one; on a log that exists it
      counts occurrences as it does now.
- [ ] AC2: The M079-AC1 leg in `tests/run-tests.sh` fails with a message
      naming the term when a refusal report naming a term of its
      `CONTESTED_XREF` set lacks the cross-reference wording's clause (`this
      mark files a cross-reference rather than a locator`) or carries the
      locator wording's clause (`its index locator links there`), or when a
      report naming any other term of its `REFUSED` set lacks the locator
      clause or carries the cross-reference clause.
- [ ] AC3: Under `tests/run-tests.sh --self-test`, the self-test reports a
      failure for the M090 T3 plant (a locator mark no longer outranking a
      cross-reference mark for a shared name) when the M079-AC1 leg's output
      under that plant holds the line the M090 T2 plant expects (`the
      contested id 'xref-dup' is still on the span printing 'rho'`), as well as
      when that output lacks the T3 plant's own `chi` line.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1, T2, T7
- AC2 → T3, T4, T7
- AC3 → T5, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: In `check_warning_count` (`tests/run-tests.sh:2076`), fail naming
      the path when the log is not a file, before the grep; update its
      comment. Add a self-test case that calls it in a subshell over a path
      under `$WORK` that does not exist, with want 0 and with want 1, and
      asserts each exits non-zero with a `FAIL:` line naming that path, plus a
      control over an existing log with its right count that passes.
- [x] T2: Run the full suite. Each call the change turns red because its log
      is never written is repaired at its call site (the log the render
      writes), or removed where no render writes it, with one work-log line
      per site naming it. Every literal path existed after the 2026-10-10 run;
      the variable-built paths (`$fmt`, `$slug` and others) are unchecked.
- [x] T3: In the leg's refusal-report block (`tests/run-tests.sh` near
      `:4566`), hold each wording's clause in one variable, read by the leg
      and by T4's plant (the M076 lesson). Per report: a `CONTESTED_XREF` term
      needs the cross-reference clause and not the locator one; any other
      `REFUSED` term the reverse; a failure names the term.
- [x] T4: Plant through `m081_census_plant`, one substitution in
      `modules/html.lua:658` (`if record and record.anchorless then` made
      false), which gives every cross-reference mark the locator wording.
      Expect a message naming a `CONTESTED_XREF` term. Show the plant green
      against the leg before T3 and red after it.
- [x] T5: Give `m081_census_plant` an optional substring the leg's output
      must not hold; pass the T2 plant's expected line as the T3 plant's. Keep
      that line in one variable read by both plants. Rewrite the comment at
      `:4738-4750` that says T3's red does not tell its defect from T2's. Show
      the new branch fire once by a scratch run of the T3 assertion over the
      T2 substitution, recorded in the work log and not committed.
- [x] T6: Remove KI275, KI276 and KI277 from `cairn/DESIGN.md` (D-013); no
      ROADMAP row names them. Re-read the leg's and plants' comments for a
      count or a list the change made false (the M080 and M081 lessons).
- [x] T7: `bash -n tests/run-tests.sh`, then a full
      `tests/run-tests.sh --self-test` green. Make no edit to the script while
      a run is in flight (the M073 lesson).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete.
     A milestone of a feature series also carries the plan's
     `feature series: M<a> -> M<b>[ -> …]` line (tracking-rules "Feature series"). -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — suite code changes across three known issues, more than one sitting.
- 2026-10-18: collision check: absorbs part of the candidate row on the older acceptance-suite backlog (KI275-KI277 only); no planned or active milestone overlaps; M090's plan gate declined KI274 (falsifier: a rendered case reaching two minted anchors on one term, not seen) and kept KI275 a known issue only to hold scope; D-011 does not reach these checks, which read rendered output and render logs, not filter source.
- 2026-10-18: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-18: checker-regress shape judged not to fire: the three checks verify the extension's rendered HTML and its render logs, not repo-internal artifacts.
- 2026-10-18: reduced criteria audit ([O], fresh context): AC1's "whatever count the call expects" claimed a domain no named procedure enumerates, narrowed to "an expected count of 0 and a positive one"; AC2 and AC3 no finding. The audit noted AC3's new branch fires in no normal run, so T5 adds one scratch demonstration.
- 2026-10-18: question set: which cluster — the warning and id checks (KI275-KI277); add KI274 anyway — no, left out.
- 2026-10-18: plan gate chose a plant-side forbidden line for KI276 over a fixture case only T3 reaches, because T2's plant already prints a line (`xref-dup` on `rho`) T3's never does; falsified by the T3 plant's output holding that line on an unplanted fixture.
- 2026-10-18: plan gate chose failing `check_warning_count` on a missing log over a per-call existence check at each zero count, because one helper change covers all its call sites; falsified by a call that must count over a log some runs legitimately do not write.
- 2026-10-18: implement started on branch m111-suite-checks-tell-apart; tree clean.
- 2026-10-18: T1 code: `check_warning_count` fails naming a missing log before its grep, plus a `--self-test` case in the M02-AC5 section. A scratch harness showed the HEAD helper passing want 0 over a missing log (grep exit 2 swallowed by `|| true`) and failing want 1 as "got 0"; the new one fails both naming the log. Unticked until the full run (T7).
- 2026-10-18: T3-T5 code: the leg's two clauses are exported once (`M111_XREF_CLAUSE`, `M111_LOCATOR_CLAUSE`) and read via `os.environ`; per-report wording check; `m081_census_plant` takes an optional sixth argument, a line it must not print; T3 plant passes `$M090_T2_LINE`, also T2's expectation; new plant `xref-locator-wording`. Self-test header now counts eleven plants. KI tags kept out of code comments, as for KI284-KI287 closed by M105.
- 2026-10-18: scratch probes (not committed), each a render of `id-collision.qmd` with one substitution: under T4's the HEAD leg exits 0 and the new leg fails with "the refusal report naming 'rho' lacks <<this mark files a cross-reference rather than a locator>>" (four such lines, rho/sigma/tau/phi); under T3's the leg prints the `chi` line and not `xref-dup` on `rho`; under T2's it prints both. The helper, stubbed to read T2's output, failed T3's plant with "the check also printed <<the contested id 'xref-dup' ...>>" (the AC3 demonstration). A scratch log with the wordings swapped or doubled turned the leg red on each of the four shapes.
- 2026-10-18: T6: KI275, KI276, KI277 removed from `cairn/DESIGN.md`; `grep -rn 'KI27[567]'` outside milestone files finds nothing. Full run next.
- 2026-10-18: first full `--self-test` run stopped at check 142 on PyYAML missing: `python3` now resolves to Python 3.14.6 in `/usr/local/bin`, without PyYAML; `/usr/bin/python3` (3.9.6) has it. The M111 T1, M090 T3 and M111 T4 self-test lines had already passed. Not an M111 defect; the user's environment was left unchanged.
- 2026-10-18: T2/T7: `bash -n` clean; `PATH="/usr/bin:$PATH" tests/run-tests.sh --self-test` green, "All checks passed (1767 checks)", 0 FAIL, 9 skips (D-065: local Quarto 1.10.19, pinned 1.10.18; none in the M079-AC1 leg or its plants). No call over a never-written log, so T2 repaired no call site. T1-T7 ticked.
- 2026-10-18: claim audit: not owed — internal tier.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->
