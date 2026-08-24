<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M32: An index follows the bibliography where the author puts it

- **Status:** review
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
- [x] AC3: In a fixture with the same citations and bibliography but no `#refs`
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
- 2026-08-24: all eight fixes the review return named are in; the suite runs 457 checks clean under `--self-test` and `cairn_validate` exits 0. Status back to review.
- 2026-08-24: review round 2 — checkpoint. All four criteria verified on fresh evidence (suite green at 457 checks under `--self-test`, plus independent renders of both fixtures and of the marker-less variant outside the working tree); consistency gate clean, `cairn_validate` exit 0. AC3 ticked: the marker-less render now lands `\printindex` below `\label{qi-afterword}` and both readers refuse it by name, which is what F1 falsified. Three-lens fan-out spawned (no-subagent rule lifted at the user's explicit direction); findings and the merge gate still to come.
- 2026-08-24: review round 2 — gate triage: eleven findings fixed on the branch (R2-F1 to F8, F10, F11, F13), two sent to candidate rows (R2-F9, R2-F14), three rejected with reason (R2-F12, F15, F16). No finding met the return floor. Suite 471 checks clean under `--self-test`; `cairn_validate` exit 0.

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

PR: [#32](https://github.com/jmgirard/quarto-index/pull/32). Two rounds, both
on `m032-index-after-references`; at each the branch already contained
`origin/main` at 835882a, so no merge was needed. Round 1 returned the
milestone; round 2 is the current record and its evidence is the fresh
evidence the gate reads.

### Round 2 (2026-08-24)

#### Acceptance criteria

- **AC1 — verified.** `tests/run-tests.sh --self-test` reports
  `M32-AC1/AC3: \printindex sits at the placement marker in both artifacts,
  following \end{CSLReferences} in the fixture that writes an empty #refs div
  and preceding \begin{CSLReferences} in the twin that writes none`. The
  reader requires exactly one occurrence of each of `\begin{CSLReferences}`,
  `\end{CSLReferences}`, `\printindex` and `\label{qi-afterword}` in each
  artifact before stating any order. Corroborated by an independent render at
  review time, outside the suite and outside the working tree: in the fixture's
  `.tex`, `\begin{CSLReferences}` at line 243, `\end{CSLReferences}` at 251,
  `\printindex` at 253, `\label{qi-afterword}` at 255.
- **AC2 — verified.** The suite reports `M32-AC2/AC3: the generated index
  section sits at the placement marker in both, following the bibliography div
  in the fixture that writes an empty #refs div (41 then 47)`. Identity, not
  offset: the references element is the one carrying id `refs` **and** the
  classes `csl-bib-body` and `references`; the index element is the one
  carrying id `qi-index` **and** required to be the same node
  `htmlindex.index_section` finds the index heading in (the method recorded in
  this file's Decisions against round 1's F6). Corroborated by an independent
  render: `id="refs"` at byte 4017, `id="qi-index"` at 4400,
  `id="qi-afterword"` at 4826.
- **AC3 — verified.** The twin keeps the default order in both formats, and
  the pair now separates the two halves of the recipe, which is what round 1's
  F1 falsified. LaTeX, independent render of the twin: `\printindex` at 242,
  `\label{qi-afterword}` at 244, `\begin{CSLReferences}` at 253 — index
  first, at the marker. HTML, same render: `id="qi-index"` at 4087,
  `id="qi-afterword"` at 4513, `id="refs"` at 5071. The derivation is proved
  before either order is stated — `ok M32: the twin fixture is the references
  fixture with the \`#refs\` div block deleted, and nothing else` — over a
  cut that removes the block whole and refuses any count of `#refs` blocks
  other than one. The marker clause is now load-bearing and was reproduced
  independently: rendering the fixture with its `::: {.qi-index-here}` block
  deleted and nothing else puts `\printindex` at 260, below
  `\label{qi-afterword}` at 252, and both readers refuse it by name —
  `the marker half of the recipe is untested` from the LaTeX reader and from
  the HTML reader. The suite commits that same marker-less render as two of
  its plants.
- **AC4 — verified.** `tests/run-tests.sh --self-test` exits 0 on 457 checks,
  run fresh twice at review time. Its M32 leg contributes 21 lines: the three
  readers' `ok` lines, the composite pass, 15 planted defects each required to
  fail for its own reason, and the README claim check reporting all 8 pinned
  claims present verbatim.

#### Consistency gate

- `cairn_validate.py` — exit 0, all 16 PASS checks and 7 advisories clean; the
  `release window` advisory did not fire.
- `cairn_impact.py` — not run: this milestone changed no DESIGN principle. Its
  DESIGN edit rewords a Known-issues entry, KI3.
- Toolchain checks — the `generic` profile's `consistency-gate` slot names
  none, so this half is a clean no-op. Its `verify` slot is
  `tests/run-tests.sh`, run above with `--self-test`.
- README claims re-verified independently of the suite's own check: all eight
  `README_REFS_CLAIMS` strings present verbatim in `README.md`, and the retired
  sentence absent.

##### Independent review

The declared tier is user-facing and the diff touches `tests/run-tests.sh`,
`tests/m32refs.py` and `examples/`, so the full three-lens fan-out ran; the
standing no-subagent instruction was lifted for this step at the user's
explicit direction (2026-08-24). Each lens ran fresh-context, in parallel, on a
distinct evidence base, ref-based git only.

- **[S] prior-review — no prior-review evidence bearing on the diff.** Swept
  every archived `## Review` section for findings touching the nine files this
  diff changes and read `LESSONS.md` in full; `examples/references*.qmd`,
  `examples/references.bib` and `tests/m32refs.py` are new in this milestone
  and no archived review has touched them, and the prior findings on
  `README.md`, `cairn/DESIGN.md` and `tests/run-tests.sh` (M01, M10, M16, M17,
  M25-M28, M30) concern unrelated areas. It confirmed KI3's lineage back to M01
  review P2 is cited correctly. The probe
  `gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1` returned `[]`,
  so the PR-thread walk was not paid for. Zero findings, clean no-op.
- **[S] blame-history — two findings**, R2-F5 and R2-F11 below, plus one
  confirmed non-issue: the deleted README sentence traces to `0714487e` (M22)
  and KI3's wording to `66fc8e6d` (M27, from M01 review P2), and both the
  deletion and the reword are genuine rather than restatements. `capture`, the
  `*-twin.qmd` naming and the planted-defect idiom all match prior milestones.
- **[O] diff-bug — sixteen findings, ranked.** It reproduced the pair
  independently and confirmed the F1 and F2 fixes are genuine before reporting.

#### Findings (round 2)

Eighteen across the three lenses, consolidated and re-ranked; every one is
logged with its disposition. Each was re-verified at review time against the
implementation, not against the reviewer's account of it.
- **R2-F1 — the one clause AC2's Decision rests on is never shown able to
  fail.** `H.index_section(doc) is not section` in `m32refs.py:html_places` is
  the substitution this file's Decisions record for AC2's "class" wording, and
  none of the 15 plants exercises it. Eight further clauses are also unplanted:
  `refs is None`, `section is None`, `count(MARKER_OPEN) != 1`, the three
  `\end{CSLReferences}` / `\printindex` / `\label{qi-afterword}` count checks,
  `without[INDEX] < without[AFTER_TEX]`, `t_index < t_refs` and
  `t_index < t_after`. "A planted defect for each reader" holds at reader
  granularity, not at clause granularity — and `m32refs.py`'s own docstring
  states the rule this misses: a check never shown red covers nothing.
- **R2-F2 — M32's stale sentence is filed in a set whose check reports under
  another milestone and another subject.** The new `bibliography order fixed`
  row sits in `README_STALE` (`tests/run-tests.sh:302`), enforced at
  `tests/run-tests.sh:1371` under the label `M03-AC7: README.md does not
  describe the HTML back-end as this suite exercises it`, over a set whose
  header comment declares it to be "sentences that described a world with one
  back-end". An M32 regression would be reported as an M03 HTML-back-end
  failure. Verified at review: both the row and the label read as quoted.
- **R2-F3 — two derive plants share a want-string that names no token,
  including the one the F1 fix depends on.** `m32_planted derive ... 'the
  recipe under test writes exactly one'` is used for both `twice.qmd`
  (`tests/run-tests.sh:3852`) and `no-after.qmd` (`:3858`), and that string is
  in the count-check message for `::: {#refs}`, `::: {.qi-index-here}` and
  `{#qi-afterword}` alike, so the Afterword plant would pass its `case` even if
  the reader had died on the `#refs` count. The real message does name the
  token; the plant just does not assert it.
- **R2-F4 — the part of the recipe an author actually copies is unpinned.** The
  fenced `markdown` block at `README.md:539-547` — `# References`, `::: {#refs}`,
  `::: {.qi-index-here}` — is not in `README_REFS_CLAIMS`; only the surrounding
  prose is. The block can drift from `examples/references.qmd` with no check,
  which is the drift M13 (cited in that array's own comment) exists to prevent.
- **R2-F5 — the twin fixture's prose still reads false of the twin, the same
  class as round 1's F10.** `examples/references-twin.qmd:19-21` says "The
  `References` heading this document writes is its own: in HTML, Quarto
  supplies a heading and an appendix wrapper only when it appends the reference
  block itself." In the twin Quarto does append the block itself. Verified at
  review by rendering the twin: it carries **two** References headings — the
  author's `<h1>References</h1>` over an empty section, and Quarto's
  `<h2 class="anchored quarto-appendix-heading">References</h2>` inside
  `div#quarto-appendix`. Raised independently by both the [O] and the [S]
  blame-history lens, the latter adding that the twin is therefore not a clean
  model of "an author who writes no `#refs` div" but of one who wrote the
  recipe's heading and not its div. Forced by the byte-derivation rule, so any
  repair has to read true in both halves.
- **R2-F6 — the replacement "What it emits" sentence is incomplete and
  unpinned.** `README.md:569-571` says where `\printindex` lands "follows from
  where you put an empty `#refs` div". It follows from the div's position
  *relative to the marker*: with a div and no marker the index still lands
  after the references (verified at review — `\printindex` at 260,
  `\end{CSLReferences}` at 250 in the marker-less render). The sentence is not
  in `README_REFS_CLAIMS`, so nothing holds it.
- **R2-F7 — "The heading is yours to write because in HTML it has to be"
  understates the LaTeX case.** Verified at review in the twin's `.tex`: the
  appended bibliography sits at `references-twin.tex:253` under no `\section`
  of any kind, so a LaTeX author who writes no div also gets an unlabelled
  bibliography. README's stated reason is narrower than the fact and may read
  as "optional in LaTeX".
- **R2-F8 — a 92-character README line introduced by this diff.**
  `README.md:573`, produced by an incomplete re-wrap of the "What it emits"
  paragraph. Round 1's F8 rejected a long README line as pre-existing style;
  verified at review against `git diff origin/main...HEAD`, this one is an
  added line, so that rejection was wrong on the facts for this line.
- **R2-F9 — the marker-less plants read the render's working copy, not the
  capture.** The suite captures that render under `m32-nomarker-latex` /
  `m32-nomarker-html`, then the plants read `"$M32W/nomarker.tex"` and
  `"$M32W/nomarker.html"` directly. `suitescan.py reads` only flags paths under
  `examples/`, so this passes; the capture exists solely to satisfy
  `suitescan.py pairs` and is never read. M24's rule is met in letter.
- **R2-F10 — `cut_block`'s docstring states a contract the code does not
  keep.** It says "a nested fence closes the inner block", but
  `stripped.startswith(FENCE) and stripped != FENCE` increments depth for any
  non-bare-`:::` fence line, a `::::` closing a `:::: {.x}` opener included.
  Verified: that input dies with "never closes the ... block it opens" — loud
  rather than silent, so not a correctness hole today, but the documented
  behaviour is wrong.
- **R2-F11 — `m32refs.py`'s mode dispatch skips the usage-guard idiom every
  comparable reader here uses.** `m20probes.py`, `m21probes.py` and
  `m23probes.py` all validate `sys.argv[1]` against their mode set and exit 2
  with a `usage:` line; `m32refs.py:245` is a bare
  `{'derive': ..., 'latex': ..., 'html': ...}[mode](*args)`, so a bad or
  missing mode raises an uncaught `KeyError`/`IndexError`. Verified at review
  against all three siblings. Never exercised by the suite, which only calls
  valid modes.
- **R2-F12 — AC2 as written is still not literally what the check asserts.**
  AC2 says "element identity — id and class"; `REF_CLASSES` guards the
  references element by id and class, while the index element is guarded by id
  plus heading-section identity with no class assertion. Round 1 raised this as
  F6 and the return gate chose recording the method over amending the
  criterion; the [O] lens re-raises it under the instruction not to read
  charitably.
- **R2-F13 — the fixture squats the extension's own id namespace.**
  `examples/references.qmd:34` writes `{#qi-afterword}`; `qi-` is the prefix
  the extension mints ids under, and an author-written id in that namespace is
  what `examples/id-collision.qmd` exists to probe (verified at review — that
  fixture claims `#qi-index` and `#qi-index-1..4`). `#afterword` would carry
  identical weight for the marker clause.
- **R2-F14 — the HTML-cost check is stronger than the README claim it
  enforces.** `m32refs.py` fails the fixture if `find_id(fdoc,
  'quarto-appendix')` is non-None at all; README's claim is narrower — the
  *bibliography* gets neither heading nor wrapper. A fixture that later grew a
  footnote or a Citation block would make Quarto build `#quarto-appendix` for
  an unrelated reason and turn this check red while README stayed true.
- **R2-F15 — `m32_mutate` forwards all remaining args to `perl -0777 -pe
  "$@"`,** so a second expression would silently be read as a filename ahead of
  `$src`. Every current call site passes one expression, so this is latent.
- **R2-F16 — Coverage row `AC4 -> T4` is stale and Scope cites a line that no
  longer exists.** T4's recorded run was 442 checks and predates the T5-T8
  suite changes; the 457-check re-run lives only in the work log. Scope still
  cites `README.md:544` for a sentence this milestone deleted.

#### Disposition (round 2)

**No return.** No finding demonstrates an acceptance criterion failing, and
none is a load-bearing defect in what the extension does for its users — the
documented recipe works end to end, verified above. Triage at the gate, per the
return floor. Defect returns to date: 1 (round 1); amendment returns: 0.

At the gate the maintainer directed the eleven recommended fixes, committed on
the branch before the approval marker:

- **R2-F1 — FIXED.** Ten new plants, one per unexercised clause: the marker
  block's own count, the three LaTeX count clauses
  (`\end{CSLReferences}`, `\printindex`, `\label{afterword}`), the twin's own
  marker clause in both formats, `refs is None`, `section is None`, the twin's
  own HTML order clause, and — the one AC2's Decision rests on — the identity
  clause, planted by moving `id="qi-index"` onto the title block while leaving
  the index heading where it is, so `find_id` and `index_section` disagree. The
  M32 leg now runs 25 plants; the suite is 471 checks.
- **R2-F2 — FIXED.** The retired sentence moved out of `README_STALE` into its
  own `README_REFS_STALE`, checked in M32's own block under M32's own label.
- **R2-F3 — FIXED.** Both derive plants now assert the token their own defect
  is about — `writes 2 occurrences of \`::: {#refs}\`` and `writes 0
  occurrences of \`{#afterword}\`` — rather than the message the three tokens
  share.
- **R2-F4 — FIXED.** A new check extracts the fenced `markdown` block from the
  recipe section (bounded to that section) and requires every non-blank line of
  it to appear verbatim in `examples/references.qmd`; 5 lines held.
- **R2-F5 — FIXED.** The shared prose now reads: the heading is written by hand
  in both halves, with the div under it it labels the bibliography Quarto fills
  in place, and with the div gone it labels nothing while Quarto appends the
  references under an appendix heading of its own. True of both halves, and the
  byte derivation still holds.
- **R2-F6 — FIXED.** *What it emits* now says the position follows from the div
  **and the placement marker below it**, and the sentence is pinned as a claim
  row.
- **R2-F7 — FIXED.** The reason now covers both back-ends — "in neither
  back-end will anything else write one where you put the div", with the LaTeX
  half ("in LaTeX it appends the block under no sectioning command at all")
  pinned as its own claim row.
- **R2-F8 — FIXED.** The paragraph re-wrapped; no line this diff adds to
  README exceeds 88 columns.
- **R2-F10 — FIXED.** The docstring now states the contract the code keeps: any
  fence line that is not a bare `:::` is read as an opener, so a `::::`-closed
  block dies on the unclosed-block clause — loud, and narrower than "any nested
  fence".
- **R2-F11 — FIXED.** `READERS` plus the usage guard the three sibling readers
  use; a bad or missing mode prints `usage: ...` and exits 2, verified both ways.
- **R2-F13 — FIXED.** The fixture's section id is `afterword`, not
  `qi-afterword`; the extension's `qi-` prefix is left to the extension.

Sent to follow-up, both as candidate rows added in this milestone:

- **R2-F9 — FOLLOW-UP.** The pre-existing marker-less plants still read the
  render's working copy; the two added here read their captures, so this
  milestone does not extend the debt.
- **R2-F14 — FOLLOW-UP.** Narrowing the HTML-cost check to the bibliography's
  own wrapper, promoted on the fixture growing a footnote or Citation block.

Rejected, with reason:

- **R2-F12 — REJECTED.** Round 1's return gate already chose recording the
  method over amending AC2, and that Decision stands in this file. The
  criterion's promise — identity rather than text position — is met, and
  R2-F1's new identity plant now shows the clause able to fail.
- **R2-F15 — REJECTED**, out-of-scope taxonomy: latent only, and every call
  site passes one expression.
- **R2-F16 — REJECTED.** Coverage and Scope are plan-owned sections a review
  never edits, and `cairn_validate`'s `coverage complete` check passes; Scope
  describes the state at plan time, when `README.md:544` was accurate.

After the fixes: `tests/run-tests.sh --self-test` exits 0 on **471 checks**
(up from 457), and `cairn_validate.py` exits 0 with no advisory fired.


### Round 1 findings, re-verified as fixed

Each of the eight actioned findings was checked against the implementation at
review time, not against the work log's account of it. F1 — reproduced and now
refused (AC3 above). F2 — README states the cost in two pinned claims, and the
HTML reader asserts it both ways round: absent in the fixture, present in the
twin. F3 — KI3 restored under the LaTeX back-end, reworded to the residual gap,
with the candidate row citing it. F4 — 15 plants committed, all red for their
own reason. F5 — `cut_block` removes the block whole and fails loudly on an
unclosed one. F6 — recorded as a Decision rather than amended. F7 — the recipe
paragraph now sits at `README.md:532`, below the six rules at 499 and the
`imakeidx` paragraph at 526. F10 — the twin's prose no longer claims to carry
the div. F8 stays rejected; F9's header line names GP6.

### Round 1 (2026-08-24) — returned

#### Acceptance criteria

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

#### Consistency gate

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

#### Independent review

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

#### Findings

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

#### Disposition

**Returned to `in-progress`.** F1 falsifies AC3's operative clause, and F2 is a
load-bearing defect in the milestone's headline deliverable — the documented
recipe — both verified at the gate rather than taken on report. AC3's checkbox
is unticked; AC1, AC2 and AC4 keep their recorded evidence, with F6 left open
against AC2's wording. No merge was put to the user and no approval marker was
written.

