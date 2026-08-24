<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M32: An index follows the bibliography where the author puts it

- **Status:** in-progress
- **Priority:** low
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP4, GP6
- **Branch/PR:** `m032-index-after-references` — [PR #32](https://github.com/jmgirard/quarto-index/pull/32)

## Goal

An author who wants the index after the references can have it, and the README
says what to write.

## Scope

Surface tier: **user-facing** — a documented recipe and the fixture that holds
it true.

**In:** the README states that "in a document with a bibliography the index
currently prints before the references" (`README.md:544`), because Quarto
appends the reference block after filters run and the marker has already placed
`\printindex`. An author-written empty `#refs` div above the marker settles the
order without any filter change — probed 2026-08-24, `\printindex` after
`\end{CSLReferences}` in the `.tex`, and `#qi-index` after `#refs` in the HTML.
This milestone commits the fixture that holds that true in both formats and
replaces the README's statement of current behavior with the recipe.

**Out:**
- Any filter change that moves the index relative to content Quarto adds after
  filters run → ROADMAP candidate row, promoted on evidence Quarto exposes an
  ordering hook a filter can reach.
- Placing the bibliography for an author who writes no `#refs` div → out; the
  default order is unchanged and stays documented.

## Acceptance criteria

- [x] AC1: In the LaTeX Quarto renders from a committed fixture carrying
      citations, a bibliography, an empty `#refs` div and an index placement
      marker below it, `\printindex` follows the reference environment.
- [x] AC2: In the HTML rendered from that same fixture, the index section
      follows the element carrying the references, asserted by element identity
      — id and class — rather than by text position alone.
- [ ] AC3: In a fixture with the same citations and bibliography but no `#refs`
      div, the index still precedes the references in both formats — the
      unchanged default, held so the recipe is shown to be what moves it.
- [x] AC4: `tests/run-tests.sh --self-test` completes clean.

## Coverage

- AC1 → T1, T2, T5, T6
- AC2 → T1, T2, T5, T6
- AC3 → T1, T2, T5, T6
- AC4 → T4

## Tasks

- [x] T1: Add `examples/references.qmd` and its twin without the `#refs` div,
      plus a small `.bib`, following the existing twin-fixture naming
      (`examples/*-twin.qmd`).
- [x] T2: Add the render and the ordering checks to `tests/run-tests.sh`,
      reading captured artifacts (M24) and asserting element identity in the
      HTML rather than raw offsets in text.
- [x] T3: Replace the README's bibliography sentence with the recipe, naming
      what an author writes and what happens without it.
- [x] T4: Run `tests/run-tests.sh --self-test`; strike KI3 (its candidate row
      was absorbed into this milestone at the plan gate).
- [x] T5: Make the placement marker load-bearing in the fixture pair — a
      section written after the marker in both halves, so an index at the
      marker and an index at the end of the body are different positions — and
      prose that reads true of the twin as well as of the fixture (F1, F10).
- [x] T6: Move the three readers into `tests/m32refs.py`, delete the `#refs`
      block rather than its fences in the twin derivation, and commit a
      planted defect for each reader, the marker-less render among them
      (F4, F5).
- [x] T7: README says what the recipe costs in HTML and where the References
      heading comes from, and the recipe paragraph stops orphaning the
      marker's six rules (F2, F7).
- [x] T8: Restore KI3 at its residual gap with the candidate row pointing at
      it; record the two gate choices in this file's Decisions and name the
      end-to-end principle in the header (F3, F6, F9).

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan gate chose documenting an author-side recipe over changing the filter to move the index, because Quarto adds the reference block after filters run and no ordering hook a filter can reach is known; falsified by Quarto exposing such a hook, which the Out row is promoted on.
- 2026-08-24: plan chose committing a no-`#refs` twin over testing the recipe alone, because a fixture built only from the shape a milestone changes cannot show the change is what moved anything (M11); falsified by the two fixtures proving to differ in more than the div.
- 2026-08-24: T1 — added `examples/references.qmd`, `examples/references-twin.qmd` and `examples/references.bib`; the twin is generated as the fixture with the `#refs` div block deleted and nothing else. Renders confirm the pair: `\printindex` after `\end{CSLReferences}` with the div and before `\begin{CSLReferences}` without it; `div#refs` before `section#qi-index` with the div and after it without.
- 2026-08-24: question gate chose asserting the order in the LaTeX Quarto writes over compiling the fixture to PDF and reading the printed pages, because a PDF leg widens the criteria set past what the plan promised and the typeset-print gap is already a backlog row.
- 2026-08-24: criteria audit ran in **full** mode (user-facing tier), inline rather than in a fresh-context [O] reader — this session is under a standing instruction not to spawn subagents. It returned one finding, fixed before the criteria were written: AC2 originally asserted the index "appears after the references" in the HTML text, which a check reading raw offsets satisfies without knowing which element carries either; it now asserts element identity (M07).
- 2026-08-24: T2 — the suite renders both fixtures to LaTeX and HTML through `capture`, checks the twin is the fixture with its `#refs` div block deleted, and asserts the two orders: `\printindex` against the `CSLReferences` environment in the `.tex`, and the generated index section against the `refs` div in the HTML, the latter by id plus the bibliography classes and by the section being the one the index heading sits in. Five plants ran red, each naming its own defect: the two artifacts swapped in each format, a twin identical to the fixture, a fixture carrying no `#refs` div, and a `refs` div stripped of its bibliography classes. Full suite: 305 checks, all passing.
- 2026-08-24: T3 — README's *Placing the index* section gains the recipe: the empty `#refs` div, why Quarto's ordering makes it work, what each back-end then does, and that writing no div leaves the default order. The *What it emits* sentence that stated the old order as fixed now points at that section, and the retired sentence joined the suite's must-be-gone set. Six claim rows pinned verbatim against README, beside the fixture pair that enforces them.
- 2026-08-24: T4 — `tests/run-tests.sh --self-test` exits 0 on 442 checks. KI3 struck from DESIGN's known issues: the order is now the author's to set and README says how. One candidate row added for the Scope Out item — a filter-side move of the index relative to content Quarto adds after filters run.

- 2026-08-24: review returned M32 to in-progress. F1 — the fixture pair never exercises the marker half of the documented recipe: with the `::: {.qi-index-here}` block deleted from `examples/references.qmd`, `\printindex` still lands at 248 after `\end{CSLReferences}` at 246, so the whole M32 battery passes on a marker-less tree and AC3's "held so the recipe is shown to be what moves it" is false. F2 — following the recipe drops the HTML References heading and the `quarto-appendix` wrapper (`quarto-appendix` and `doc-bibliography` present in the twin, absent in the fixture) and the README does not say so. Defect returns to date: 1.
- 2026-08-24: return gate chose recording the method AC2's index half is checked by, and recording the end-to-end-verification trade with the principle named in the header, over amending either criterion — the criteria set is held where it was planned (F6, F9).
- 2026-08-24: T5 — the fixture pair gains an `Afterword` section after the placement marker, which is what tells an index at the marker apart from one at the end of the body; the twin's prose no longer claims to carry the div. Coverage rows for AC1-AC3 extended to name T5 and T6.
- 2026-08-24: T6 — the derivation, LaTeX and HTML readers moved into `tests/m32refs.py`; the derivation now deletes the `#refs` block whole, refusing an unclosed one, rather than skipping its fences. Fifteen planted defects committed beside them, each required to fail for its own reason: five on the derivation, four on the LaTeX order, six on the HTML order and the recipe's HTML cost. Two are the marker-less document F1 named, rendered rather than mutated — the fixture with its marker block deleted and nothing else, which both readers now refuse.
- 2026-08-24: T7 — the recipe paragraph moved below the marker's six rules and the `imakeidx` paragraph, so the rules keep their lead-in; the recipe now writes a References heading of its own, and README says why: rendering both halves shows Quarto's appendix wrapper and its **References** heading present in the twin and absent in the fixture, so an author following the recipe supplies the heading. Two claim rows added, and the pinned recipe row updated to the heading-carrying shape.
- 2026-08-24: T8 — KI3 restored under the LaTeX back-end, reworded from "README states the current behavior" down to the residual gap: the filter still cannot place the index relative to content Quarto adds after filters run, and the recipe that works around it costs an HTML author the appendix wrapper and heading. The candidate row for a filter-side move now points at it. Two milestone-local decisions recorded, and GP6 named in the header.

## Decisions

- **AC2's index half is guarded by id plus heading-section identity, not by class.**
  Quarto's bibliography div carries stable classes (`references`,
  `csl-bib-body`) that make id-plus-class a real identity check; the generated
  index section's own classes are this extension's to change, so a class check
  there would assert the extension's current output against itself. Requiring
  the `qi-index` element to be the same node `htmlindex.index_section` finds
  the index heading in is the identity assertion AC2 asks for, on the fact that
  does not derive from the artifact under test. Recorded rather than amended:
  the criterion's promise — identity, not text position — is met.
- **GP6 traded: the order is asserted in the LaTeX Quarto writes, not in a
  compiled PDF.** A PDF leg would have to read the printed page sequence to say
  the index follows the references, which is the typeset-print gap already
  carried as a backlog row rather than this milestone's promise; widening the
  criteria set to reach it was refused at the question gate. What the `.tex`
  shows is the command order this extension controls, which is the whole of
  what the recipe changes. Falsified by a case where `\printindex` after
  `\end{CSLReferences}` prints on a page before the references.

## Review

PR: [#32](https://github.com/jmgirard/quarto-index/pull/32). Reviewed 2026-08-24
on `m032-index-after-references`, branch containing `origin/main` at 835882a —
no merge needed.

### Acceptance criteria

- **AC1 — verified.** `tests/run-tests.sh --self-test` reports
  `M32-AC1/AC3: \printindex follows \end{CSLReferences} in the fixture that
  writes an empty #refs div, and precedes \begin{CSLReferences} in the twin
  that writes none`. The check requires exactly one occurrence of each of the
  three names in each artifact before stating any order. Corroborated by an
  independent render at review time: in `examples/references.tex`
  `\begin{CSLReferences}` at line 239, `\end{CSLReferences}` at 247,
  `\printindex` at 249.
- **AC2 — verified.** The suite reports `M32-AC2/AC3: the generated index
  section follows the bibliography div in the fixture that writes an empty
  #refs div (37 then 43)`. Identity, not offset: the references element is the
  one carrying id `refs` **and** the classes `csl-bib-body` and `references`,
  and the index element is the one carrying id `qi-index` **and** required to
  be the same node `htmlindex.index_section` finds the index heading in.
  Corroborated by an independent render: in `examples/references.html`
  `id="refs"` at byte 3794, `id="qi-index"` at 4183.
- **AC3 — NOT verified (unticked at review; see F1).** The two orders below
  are real and were reproduced independently, but the criterion's operative
  clause is not met. Both halves come from the same two suite lines. LaTeX:
  `\printindex` precedes `\begin{CSLReferences}` in the twin (independent
  render: 238 against 241). HTML: the index section precedes the bibliography
  in the twin, `37 then 54` in document order (independent render: `id="qi-index"`
  at 3864, `id="refs"` at 4481). The pair is load-bearing, so the suite first
  proves the twin is the fixture with its `#refs` div block deleted and
  nothing else — `ok M32: the twin fixture is the references fixture with the
  \`#refs\` div block deleted, and nothing else` — and refuses a fixture that
  writes any count of `#refs` blocks other than one, which closes the vacuous
  case where a byte-identical twin would satisfy the derivation.
- **AC4 — verified.** `tests/run-tests.sh --self-test` exits 0 on 442 checks,
  run fresh at review time; its planted-defect leg ran 24 plants, each failing
  the check that names it.

### Consistency gate

- `cairn_validate.py` — exit 0, all checks passed; no advisory fired,
  `release window` included.
- `cairn_impact.py` — not run: this milestone changed no DESIGN principle
  (the DESIGN edit strikes a Known-issues entry, KI3).
- Toolchain checks — the `generic` profile's `consistency-gate` slot names
  none, so this half is a clean no-op. `verify` is `tests/run-tests.sh`, run
  above.
- README claims independently re-verified at review time: all six
  `README_REFS_CLAIMS` strings present verbatim in `README.md`, and the
  retired sentence absent.

### Independent review

The declared tier is user-facing and the diff touches `tests/run-tests.sh`, so
the full three-lens fan-out ran; the standing no-subagent instruction was
lifted for this step at the user's explicit direction (2026-08-24).

- **[S] blame-history — no findings.** Traced the deleted README sentence to
  `0714487e` (M22) and KI3's formalization to `66fc8e6d` (M27, from M01 review
  P2), and judged the strike genuine rather than a restatement: the order is no
  longer fixed. Confirmed `README_STALE` used as `9f1eb4ae` (M03) established
  it, `capture` used per `334837c1` (M24) with four distinct slugs, and the
  twin-fixture derivation check honouring the M11 lesson `check-design.md`
  records. `grep` finds no dangling `KI3` reference. It also noted, as
  out-of-scope working-tree state, the uncommitted PR-link edit to this file —
  which is this review's own step-2 edit.
- **[S] prior-review — no prior-review evidence bearing on the diff.** Swept
  the archived `## Review` sections touching `README.md` and
  `tests/run-tests.sh` and read `LESSONS.md` in full; the probe
  `gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1` returned `[]`,
  so the PR-thread walk was not paid for. Zero findings, clean no-op.
- **[O] diff-bug — ten findings, ranked. Two verified at the gate as
  floor-qualifying; dispositions below.**

### Findings

Every reported finding is logged with its disposition. F1 and F2 were
re-verified at review time against the implementation, not against the
reviewer's account of it.

- **F1 — the fixture pair never exercises the marker half of the recipe.
  RETURN (defect).** The marker is the last block of both fixtures, which is
  where the extension already places `\printindex` when a document has no
  marker at all. Verified at review: rendering `examples/references.qmd` with
  the `::: {.qi-index-here}` block deleted and nothing else gives
  `\begin{CSLReferences}` 238, `\end{CSLReferences}` 246, `\printindex` 248 —
  the same order, so the entire M32 battery stays green on a fixture carrying
  no marker. This falsifies AC3's operative clause, *held so the recipe is
  shown to be what moves it*: the pair shows the `#refs` div moves the index
  and shows nothing at all about the marker the README tells the author to
  write. `examples/marker-nomarks.qmd:14` states the house idiom this breaks —
  "Prose after the marker, so its removal is visible as an absence rather than
  as the end of the document."
- **F2 — the recipe's HTML cost is undocumented. RETURN (load-bearing defect
  in a user-facing deliverable).** Verified at review by rendering both
  fixtures to HTML: without the `#refs` div Quarto builds a
  `quarto-appendix` block with `role="doc-bibliography"` and an
  `<h2 class="anchored quarto-appendix-heading">References</h2>`; with the div,
  `quarto-appendix` and `doc-bibliography` are both absent and there is no
  References heading at all. An author who follows the README recipe silently
  loses the References heading and the appendix wrapper in HTML, and the README
  does not say so. (The pinned sentence *Write no `#refs` div and nothing
  changes* is itself true — it describes the no-div case. The defect is the
  omission on the other side of the recipe, not a false claim.) GP1 holds
  README to discovery-surface quality; the M32 HTML check reads only the `refs`
  element's position and classes, so no check can see this.
- **F3 — KI3 struck while the behavior it records still stands, and the
  replacement row cites no KI. FIX ON RETURN.** The filter still cannot place
  the index relative to content Quarto adds after filters run; what changed is
  that a workaround is now documented, and F2 shows the workaround has a cost.
  D-013 puts a statement about how the extension behaves today in Known issues
  and has the candidate row point at it; 23 of the 27 candidate rows cite a
  `KI<n>` and the new one does not. The shape to restore is a KI3 reworded down
  to the residual gap, with the new row pointing at it.
- **F4 — no planted-defect check is committed for any of the new readers.
  FIX ON RETURN.** The work log records five plants run by hand at T2; none is
  in the tree, so nothing holds the new checks' discrimination over time.
  Recent milestones commit theirs (`M29_PLANT`, `tests/run-tests.sh:11062`).
  F1 is the case this would already have caught.
- **F5 — the twin-derivation check deletes the div's fences, not its block.
  FIX ON RETURN.** In the loop at `tests/run-tests.sh:3768`, a line inside the
  div that is not exactly `:::` falls through to `out.append(line)`, and a
  nested `:::` closes the skip early. Harmless while the div is empty, but both
  the failure message and the `ok` line claim the block was deleted. The
  `cut != 1` guard does not cover it.
- **F6 — AC2 says "id and class"; the index half is asserted by id plus
  heading-section identity. OPEN — maintainer's call.** `REF_CLASSES` guards
  the references element by id and class as AC2 says. The index element is
  guarded by `find_id(doc, 'qi-index')` plus `H.index_section(doc) is section`,
  which is structurally stronger but is not the clause AC2 wrote, and the
  substitution is recorded nowhere. Under the never-reinterpret rule this is
  either an equivalent method to be recorded or an amendment return on AC2's
  wording; it is not review's to decide charitably.
- **F7 — the README recipe paragraph orphans the "Six rules" lead-in. FIX ON
  RETURN.** The paragraph was inserted between "Both back-ends honour the same
  marker…" and "Six rules, each of which warns rather than breaking your
  build:". The six rules are the *marker's* rules; a reader arriving from the
  bibliography paragraph reads them as rules about the `#refs` recipe, and the
  first is "Top level only", which plausibly reads that way. GP1.
- **F8 — a 92-character README line at `README.md:564`. REJECTED**,
  out-of-scope taxonomy: a pure style point a formatter would carry, and
  README already holds several such lines.
- **F9 — the milestone's `## Decisions` is empty while the work log records two
  gate choices. FIX ON RETURN.** Review found the same tension independently:
  the question gate traded GP6 — *acceptance evidence for output-producing
  features runs to the final compiled artifact, not only intermediate output* —
  by asserting order in the `.tex` rather than a PDF, on a user-facing tier,
  and "Principles touched" lists GP1 and GP4 without GP6. Whether that warrants
  a D-entry or only an honest header line is the maintainer's call, but it
  currently has no record outside the work-log prose.
- **F10 — the twin fixture's body asserts something false about itself. FIX ON
  RETURN.** `examples/references-twin.qmd:17` reads "This fixture carries the
  div", which is untrue in the twin. Forced by the byte-derivation rule, so the
  wording has to read correctly in both halves.

### Disposition

**Returned to `in-progress`.** F1 falsifies AC3's operative clause, and F2 is a
load-bearing defect in the milestone's headline deliverable — the documented
recipe — both verified at the gate rather than taken on report. AC3's checkbox
is unticked; AC1, AC2 and AC4 keep their recorded evidence, with F6 left open
against AC2's wording. No merge was put to the user and no approval marker was
written.

