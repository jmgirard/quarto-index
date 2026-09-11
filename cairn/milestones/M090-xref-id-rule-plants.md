<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M090: M079's cross-reference id rules each turn the id-collision leg red

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP6   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — acceptance-suite plants and a self-test removal, which no user of the extension runs   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m090-xref-id-rule-plants   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Each of M079's three cross-reference id rules is shown to turn the M079-AC1 leg
red when reverted, with no self-test left claiming to fence a copy of that
leg's read.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** three planted-defect cases under `--self-test`, one per rule M079 gave
cross-reference marks (`examples/id-collision.qmd`'s `rho`/`sigma`/`tau`/`phi`
yield cases, the `phi`/`chi` locator-outranks pair, the `upsilon` control), each
rendering the fixture with one rule reverted in a copy of the extension and
holding the M079-AC1 leg to it; the plant helper taking the module it
substitutes into; removal of the M084 T2 self-test; two `DESIGN.md` known-issue
entries for the gaps the gate chose to record.

**Out:**
- A plant or rendered case reaching the leg's grouped exactly-one clause (a
  term whose marks carry two minted anchors) — dropped at this plan gate with
  the self-test; the gap is recorded as a known issue by T6.
- Telling the cross-reference refusal wording apart from the locator one — a
  known issue by T6, no candidate row (the gate found no promotion trigger).
- The untagged mark keeping a contested id — KI253 stands.
- Scoping the M083 EPUB plants' derived locator — its own candidate row.
- `tests/epubcheck.py links` over `id-collision.epub` — KI267 stands.

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

- [x] AC1: Under `tests/run-tests.sh --self-test`, a copy of the extension in
      which a cross-reference mark is no longer tagged to contest its
      author-written id (one substitution at `contestable_xref` in
      `modules/passes.lua`) renders `examples/id-collision.qmd`, and the
      M079-AC1 leg, run from the file the unplanted run wrote, exits non-zero
      with a message naming `xref-dup`, the id the fixture's `rho` mark shares
      with a div.
- [x] AC2: Under the same run, a copy in which a locator mark no longer
      outranks a cross-reference mark for a shared name, the first in document
      order keeping it instead (one substitution in `keepable_author_ids`,
      `modules/html.lua`), renders the same fixture, and the leg exits non-zero
      with a message naming the term `chi`.
- [x] AC3: Under the same run, a copy in which a cross-reference mark gives up
      its author-written id whether or not anything else carries it (one
      substitution in `assign_anchors`, `modules/html.lua`), renders the same
      fixture, and the leg exits non-zero with a message naming `xref-solo`,
      the id of the fixture's uncontested cross-reference mark `upsilon`.
- [x] AC4: The M084 T2 self-test leg, which holds a copy of the M079-AC1 leg's
      minted-anchor grouping read, is removed from `tests/run-tests.sh` along
      with its `text_keyed` and `grouped` helpers, and the M079-AC1 leg's own
      grouping read is left in place.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1, T2, T7
- AC2 → T1, T3, T7
- AC3 → T1, T4, T7
- AC4 → T5, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: Give `m081_census_plant` (`tests/run-tests.sh:4573`) the module file
      it substitutes into, which it now hardcodes as `modules/html.lua`
      (`:4579`); the seven existing plants keep what they plant and expect.
- [x] T2: Plant AC1 through the helper: `contestable_xref`
      (`passes.lua:624`) made false. Expect a whole leg message naming
      `xref-dup` (e.g. its "is on 2 element(s), want 1" line, `:4222`), not
      the bare id.
- [x] T3: Plant AC2: the outrank clause at `html.lua:847` removed so the
      first holder stands. Expect a message long enough to be the `chi` case
      (e.g. "the locator for 'chi' names", `:4279`) — bare `chi` matches too
      much.
- [x] T4: Plant AC3: `assign_anchors` (`html.lua:885`) refusing an anchorless
      mark's id whatever `keeper` says. Expect the `xref-solo` control message
      (`:4374`).
- [x] T5: Remove the M084 T2 self-test (`tests/run-tests.sh:4415-4540`);
      `grep -n 'M084 T2\|def text_keyed\|def grouped' tests/run-tests.sh`
      prints nothing, and `minted.setdefault(printed, []).append(name)` is
      still in the leg. Keep the leg's grouping read (`:4322-4335`) and amend
      its comment (`:4316-4321`) to say no rendered case reaches a term with
      two minted anchors and no plant holds that clause.
- [x] T6: Add two entries under `DESIGN.md`'s acceptance-suite coverage gaps:
      the leg's grouped exactly-one clause is reached by no rendered case and
      held by no plant (M084 review F1); and no check tells the
      cross-reference refusal wording from the locator one
      (`html.lua:907-913`), so a swap between them ships green.
- [x] T7: Run `tests/run-tests.sh --self-test` alone (never two at once);
      the unplanted control and each new plant print their pass lines, and
      the run exits 0.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete. -->

- 2026-09-10: created by /milestone-plan, absorbing the "Bind M079's cross-reference id shapes to criteria" candidate row whole.
- 2026-09-10: reduced criteria audit ([O], fresh context) found none on AC1-AC3; on the delete variant of AC4, a label grep standing in for the removal and a promise bound to that grep's output; a wording gap in the harden variant; and a full-suite exit-0 criterion binding the harness. All fixed: AC4 now promises the removal (the grep moved to T5), and the full run moved to T7.
- 2026-09-10: plan gate chose deleting the M084 T2 self-test over hardening it into one shared function with two plants, because it fences a copy of a read no rendered case reaches and hardening adds a checker over a checker; falsified by a rendered case reaching two minted anchors on one printed term.
- 2026-09-10: plan gate chose recording the undistinguished refusal wordings as a known issue over adding a leg clause and fourth plant, keeping scope to the candidate row; falsified by a swap of the two wordings shipping with the suite green and misleading an author.
- 2026-09-10: AC4's final removal wording re-audited ([O], reduced, fresh context): no finding; its note that T5's grep checked only the removal led T5 to also check the leg's own read stays.
- 2026-09-10: implement started on branch m090-xref-id-rule-plants; no question gate, the plan leaving no implementation choice open.
- 2026-09-10: T1-T6 edits written, unticked pending the `--self-test` run: helper takes a module argument; three plants each probed first in a scratch copy (unplanted control green, each plant red with its pinned line); M084 T2 self-test removed; KI274/KI275 added.
- 2026-09-10: claim audit: not owed — internal tier
- 2026-09-10: T1-T7 ticked against one `tests/run-tests.sh --self-test` run at f3e60b6's tree (1455 checks, 0 FAIL, exit 0): the unmutated-copy control green; M090 T2/T3/T4 plants each red on their pinned line; no M084 T2 line; T5's grep prints nothing and the leg's grouping read stays (line 4326). T2-T4 were checked off together with T1 and T5-T6 on that one run rather than a run per task, each run taking over 13 minutes.
- 2026-09-10: implement complete; status review.

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

**Sync.** 2026-09-10: `main` equals `origin/main` and is an ancestor of the branch; nothing to merge in.

**Suite run.** One `tests/run-tests.sh --self-test` at b865217 (code tree unchanged since f3e60b6; later commits are tracking only), 2026-09-10: "All checks passed (1455 checks)", exit 0. The unmutated-copy control ("M081 T4 self-test: an unmutated copy … leaves the check green") passed before the plants ran. The plant helper (`tests/run-tests.sh:4451-4484`) fails on a substitution that matches nothing or changes nothing, renders `id-collision.qmd` in the planted copy, runs `$WORK/id-collision-ids.py` (the leg file the unplanted run wrote), and passes only on a non-zero exit whose output contains the pinned text.

- AC1: pass line "M090 T2 self-test: a cross-reference mark no longer tagged to contest its author-written id: the check is red on <<the contested id 'xref-dup' is still on the span printing 'rho'>>"; the substitution is the one at `contestable_xref` in `passes.lua` (fifth helper argument `passes.lua`).
- AC2: pass line "M090 T3 self-test: a locator mark no longer outranking a cross-reference mark for a shared name: the check is red on <<the locator for 'chi' names>>"; the substitution drops the `anchoring and not standing.anchoring` clause in `keepable_author_ids`, `html.lua` (default module). The [O] reviewer's scratch render of the T2 plant also prints this line (finding F1 below); AC2 asks only for a message naming `chi`.
- AC3: pass line "M090 T4 self-test: a cross-reference mark giving up its author-written id when nothing contests it: the check is red on <<the uncontested id 'xref-solo' is on 'nothing', not on the span printing 'upsilon'>>"; the substitution is in `assign_anchors`, `html.lua`.
- AC4: `grep -n 'M084 T2\|def text_keyed\|def grouped' tests/run-tests.sh` prints nothing (exit 1), and the run log carries no M084 T2 line; the leg's own grouping read `minted.setdefault(printed, []).append(name)` is still at `tests/run-tests.sh:4326`, and the leg passed ("M079-AC1: no id among the page's 233 is carried twice …").

**Consistency gate.** `cairn_validate.py` exit 0, every check PASS/OK. No `DESIGN.md` principle changed (the diff adds KI274/KI275 only), so no impact report. Profile `generic`: no toolchain checks.

**Independent review** (three lenses, fresh context). [S] blame-history: no finding; the M084 T2 removal matches M084 review F1, and the leg's read it copied is untouched. [S] prior-review: no finding; no inline PR comments exist on the repo. [O] diff-bug: no correctness defect (each substitution matches once at HEAD; T2 and T4 pins appear only in their own plant's output), three findings, triage below.
- F1: the M090 plants' comment (`tests/run-tests.sh:4547-4555`) says each pinned line names that plant's own case "rather than a line a neighbouring plant also draws", which is false for T3: the T2 plant's output also prints "the locator for 'chi' names" (confirmed in the reviewer's scratch `t2.out`), and no line in T3's output is absent from T2's.
- F2: the helper's failure messages (`:4466`, `:4468`, `:4482`) still say "the census", which the three M090 plants do not touch; the temp file is still `html-spliced` when the module is `passes.lua`.
- F3: the section header comment (`:4418-4443`) still describes six plants over the census; there were seven before M090 and are ten now.
