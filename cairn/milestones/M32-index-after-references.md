<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M32: An index follows the bibliography where the author puts it

- **Status:** review
- **Priority:** low
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP4
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
- [x] AC3: In a fixture with the same citations and bibliography but no `#refs`
      div, the index still precedes the references in both formats — the
      unchanged default, held so the recipe is shown to be what moves it.
- [x] AC4: `tests/run-tests.sh --self-test` completes clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
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

## Decisions

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
- **AC3 — verified.** Both halves come from the same two suite lines. LaTeX:
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
- **[O] diff-bug — pending at this checkpoint.**

### Findings

Pending the [O] lens.

