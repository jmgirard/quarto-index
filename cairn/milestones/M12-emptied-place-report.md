# M12: A marker that leaves nothing behind is reported without naming what held it

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1, GP5
- **Branch/PR:** m12-emptied-place · https://github.com/jmgirard/quarto-index/pull/12

## Goal

An author whose nested placement marker was the only thing written where it
stood is told so, in a message that names no element the extension cannot
honestly name.

## Scope

Surface tier: **user-facing** — the deliverable is a warning an author of any
Quarto document reads, so GP1's doc, test and edge-case commitments apply.

**In:** the emptied-place report descoped from M08 at its third review return,
rebuilt on the opposite naming decision. M08's recursive `empties` rule is
kept — it was verified correct on ten adversarial shapes — and everything that
named the container (`CONTAINER_NAMES`, `check_emptied`,
`report_emptied_containers`) stays deleted. The report instead fires from the
block list a marker is stripped out of, in `strip_nested_markers`, carries the
marker's top-level block position, and claims only that nothing the author
wrote remains where the marker stood. That claim is true of a Quarto callout,
a tabset and a captioned figure, each of which still renders its title bar or
caption — which is what made every naming attempt say something false.

The four shapes the ROADMAP row records as defeating M08 are answered by the
approach rather than case by case: a scaffold div is never named, so it cannot
be named wrongly; figure captions and table cells stop going unreported
because Pandoc's `Blocks` walk reaches them like any other block list
(verified, Pandoc 3.10.2); a bullet list emptied through its only item no
longer claims to be a list item; and the per-kind `div` check that could not
tell a container from the marker div inside it is gone with the naming.

**Out:** rewording M04's nested-marker warning, which keeps the text it has
always had and fires beside the new one → not planned; raise it if the pair
reads badly. Reporting a container the *author* left empty with no marker in
it → out of the extension's business entirely, and pinned as a non-report
here. A source line or file position for any warning → Pandoc gives filters
none; not plannable.

## Acceptance criteria

- [ ] AC1: Every emptied-place report the run emits is the single message
      template `index placement marker in top-level block N was the only thing
      written where it stood; the marker is removed, so nothing you wrote
      remains there`, with the block index its only variable part. Evidence: a
      full-line equality check over every report line the renders emit, so no
      report can carry an element kind, a class or an id.
- [ ] AC2: For each of the three renders of `examples/marker-shapes.qmd`
      (html, latex, gfm), the multiset of emptied-place report lines equals
      the expected list derived in the fixture's manifest comment — positives
      and non-reports settled by one comparison, so a report that fires where
      none is expected fails as loudly as one that goes missing.
- [ ] AC3: A block list whose owner is itself a marker draws no report: the
      doubly-nested and triply-nested marker shapes each draw exactly one
      report, at the position of the outermost marker, and never one per
      level. Evidence: those shapes' lines in AC2's comparison.
- [ ] AC4: Four mutations, each applied after the fix is committed and
      reverted after, each making a check fail: deleting the report call;
      widening the rule to fire for any block list that merely contains a
      marker; shifting the reported position by one; and stopping markers
      being stripped at all, so a marker div survives into a body and AC5's
      residue check fails.
- [ ] AC5 (IP2): `examples/marker-shapes.qmd` renders without error to html,
      latex and gfm, and no output carries `qi-index-here` anywhere but the
      title span Quarto emits from the fixture's own YAML title — html and gfm
      carry that one, latex carries none. Occurrences are located, not counted,
      so a marker div surviving into a body fails the check; AC4's fourth
      mutation plants exactly that, to prove it can.
- [ ] AC6: `tests/run-tests.sh --self-test` clean.
- [ ] AC7: README and `cairn/DESIGN.md` state the report, that it names no
      container by design, and why — a callout holding only a marker still
      renders its title bar, so a message calling it empty is false.

## Coverage

- AC1 → T2, T3
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T5
- AC5 → T1, T4
- AC6 → T4
- AC7 → T6

## Tasks

- [x] T1: Extend `examples/marker-shapes.qmd` with the shapes this milestone
      is about, one emptied place per top-level block so two reports can never
      be byte-identical, and head the file with a manifest comment deriving
      the expected report line for each — derived from the fixture's own
      structure, never copied from a render (M06 lesson). Emptying shapes: a
      Quarto callout, a tabset, a captioned figure, a bullet list whose only
      item holds only the marker, a block quote, a footnote body, a marker div
      alone inside a marker div, and a marker three deep. Non-reporting
      shapes: the existing `#keeps-content` div, a marker with a non-marker
      sibling, a marker whose only sibling is whitespace, a top-level marker,
      and a container the author left empty with no marker in it — the M11
      lesson, since a fixture built only from the shapes that change cannot
      catch a regression in the ones that do not.
- [x] T2: Add the failing checks to `tests/run-tests.sh` — full-line equality
      per report line and the per-render set comparison against T1's manifest
      — and watch them fail against the current filter.
- [x] T3: Restore `empties` in `_extensions/index/index.lua` beside
      `marker_content` (`_extensions/index/index.lua:1546`) and emit the
      report from `strip_nested_markers`, once per emptied block list whose
      owner is not a marker, threading the top-level position
      `resolve_markers` already loops with (`index.lua:1572`). Write the
      message as one literal so a scan reading each `warn()` call's first
      literal sees the whole of it (M10 lesson). Commit.
- [x] T4: `tests/run-tests.sh --self-test` clean; confirm the three renders
      and the absence of `qi-index-here` in each output.
- [x] T5: Run the four AC4 mutations, each against the committed fix, never
      with uncommitted work in the tree (M08 lesson: `git checkout --` inside
      a probe destroys it).
- [x] T6: Document the report in README and the marker paragraph of
      `cairn/DESIGN.md` — what it says, that it names no container by design,
      and the callout title-bar reason it does not.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: plan gate chose reporting at the marker without naming the container over naming it with Quarto-scaffold resolution, because naming requires the filter to model Quarto's private, undocumented, version-drifting construct wrapping for a name the marker's own position already supplies; falsified by author reports that a positioned but unnamed report is unactionable, which would argue the name back in.
- 2026-08-18: plan gate chose a second warning beside M04's nested-marker message over folding the two together, because M08's reason still holds — the M04 wording and every check pinned to it stay untouched; falsified by the pair reading redundantly to an author who sees both fire on one marker.
- 2026-08-18: plan gate chose claiming the marker's own place is empty over claiming the container is, because a callout, a tabset and a captioned figure still render a title bar or caption; falsified by a shape where the marker's place and the container coincide and the wording reads as evasive.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader over the final drafted wording. Returned 15 findings across AC1-AC6 (AC7 clean); every one had a clear right answer and was fixed before writing, none escalated to a gate question.
- 2026-08-19: T1 — fixture extended with nine emptying shapes and four non-reporting ones; the manifest's hand-derived positions 12 13 14 15 16 17 18 20 22 were confirmed against the post-Quarto AST by a throwaway dump filter, which also showed the marker-owned subtraction is what keeps the doubly- and triply-nested shapes at one report each and the top-level placement marker at none. The plan's "marker whose only sibling is whitespace" non-report shape was dropped: markdown whitespace produces no block, so that shape is the reporting case, not a negative. Suite green, 165 checks.
- 2026-08-19: T2 — the set-equality check and the residue check added; against the current filter all three formats report 0 of the manifest's 9, so the check fails for the reason it exists. The manifest's must-not-report rows were reworded to carry no bare leading number, so the parse that reads the reporting rows cannot pick them up — the first draft's parse did, and the two halves of the manifest disagreed.
- 2026-08-19: amended AC4 and AC5 at a mini gate. AC5 as planned promised no output carries qi-index-here; the fixture's own YAML title carries the class and Quarto emits it into the html and gfm output, which is metadata the marker machinery never reaches (M08) and predates M12. AC5 narrowed to that one located occurrence; AC4 grew a fourth mutation so the located-residue check has a discrimination proof. A fresh-context [O] reader audited the amended wording in full mode before it was written and returned three findings — a false "each of the three carries one" implication, a mechanism claim over all metadata, and an unprobed counterfactual — all three folded into the adopted text.
- 2026-08-19: T3 — the report emits from strip_nested_markers, counted as every emptying block list minus every one a marker owns, which needs no per-container code and so reaches a figure caption and a table cell like any other list. The plan's Note handler was dropped after a probe: on Pandoc 3.10.2 the Block filter reaches a footnote's blocks unaided, so M08's Note handler would double-count and under-report a marker nested inside a marker inside a footnote — that shape is now in the fixture, which is how the double count was found. All three formats emit the manifest's 10 reports.
- 2026-08-19: T4 — `tests/run-tests.sh --self-test` clean at 187 checks, the planted-defect pass included. All three renders produce the manifest's 10 reports and the located-residue check passes.
- 2026-08-19: T5 — all four AC4 mutations caught. Deleting the report call, widening the rule to any list merely containing a marker, and shifting the position by one each fail the set-equality check; stopping markers being stripped at all fails the located-residue check. The harness refuses to run against a dirty tree, since it reverts with `git checkout --` (M08 lesson).
- 2026-08-19: T6 — README gains a sixth marker rule and DESIGN's marker paragraph gains the report, both stating that it names no container and why. Self-test clean at 187 checks after the docs change. Status to review.
