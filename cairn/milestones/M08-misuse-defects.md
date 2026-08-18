# M08: Reachable mark and marker misuse defects

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** m08-misuse-defects · https://github.com/jmgirard/quarto-index/pull/8

## Goal

Four author-reachable misuse cases the earlier reviews left latent — a document
claiming the index section's id, a cross-reference pointing at its own entry,
the placement-marker class written where it cannot place an index, and a nested
marker that empties its container — are each reported and handled rather than
silently mishandled.

## Scope

Surface tier: **user-facing** — every deliverable here is either a warning an
author reads or markup an HTML reader receives.

**In:**
- The HTML index section's id is minted past ids already taken in the document,
  as anchor and entry ids already are (`html_index_blocks`, index.lua:1219).
- A cross-reference target equal to the mark's own entry is reported and that
  target dropped, before the back-end branch (`Span`, index.lua:629).
- The marker class on a block that is not a Div, or on an inline span, is
  reported; the element itself is left untouched (`is_marker`, index.lua:1239).
- A nested marker that was its container's only content is reported as having
  left that container empty; the container is kept (`strip_nested_markers`,
  index.lua:1273).
- Fixtures and checks for all four, each shown to fail when its fix is reverted.

**Out:**
- Sort keys registered against unclamped level paths while LaTeX writes clamped
  ones → M09.
- Resetting module-level filter state between documents → candidate row; Quarto
  renders each document in its own process, so it is unreachable today.
- An empty entry tree rendering a bare `Index` heading → candidate row;
  unreachable, every path building the section is gated on a mark.
- Percent-escaping locator hrefs for chapter filenames holding `#` or `?` →
  candidate row; not fixable at the filter layer (M05 review F11).

## Acceptance criteria

- [x] AC1: In an HTML render of `examples/id-collision.qmd`, whose own elements
      claim the ids `qi-index` (a Pandoc attribute on a Div, never a heading —
      Quarto migrates a heading's id to its wrapper `<section>`), `qi-index-1`,
      `qi-index-2` and `qi-index-3` (a `{=html}` raw block, spelled
      double-quoted, unquoted and uppercase `ID=`) and `qi-index-4` (a `{=html}`
      raw inline, single-quoted): `tests/htmlindex.py`'s scan of every `id`
      attribute in the rendered page reports no `qi-`-prefixed id carried by two
      elements; each of the five claimed ids appears exactly once, on the
      element that claimed it; and the index section, located by the heading
      whose text is `Index`, carries an id distinct from all five.
- [x] AC2: In a LaTeX, an HTML and a gfm render of `examples/self-xref.qmd`,
      carrying four marks — a single-level `see=` naming its own entry, a
      `see-also=` naming its own two-level `entry=` path, a self-target on a
      mark whose entry comes from its visible text rather than `entry=`, and a
      mark carrying both attributes of which only the `see=` is self-targeting —
      exactly four warnings naming a self-referential target appear per render,
      one per self-targeting attribute. In the LaTeX render the first three
      marks each emit one `\index{}` on their own key carrying no encap, and the
      fourth emits one `\index{}` carrying only its surviving `seealso` encap.
      In the HTML render the first three entries each carry a locator link, the
      fourth carries its cross-reference and no locator, and a scan of every
      locator and cross-reference link inside the index section finds none whose
      href is the id of the entry that contains it.
- [x] AC3: In a LaTeX, an HTML and a gfm render of `examples/marker-sites.qmd`,
      which writes the marker class on a Header, on an inline span and on a
      fenced code block and holds one real top-level marker, each of the three
      sites is reported exactly once per render by a warning naming that site
      kind, and the index lands at the real marker in the LaTeX and HTML
      renders. In the HTML render all three elements survive carrying the class
      and their content unchanged; in the gfm render their visible content
      survives and no index, anchor or back-end token appears — gfm drops a
      header's attributes itself, so class survival is claimed only of HTML.
- [x] AC4: In the same three renders of `examples/marker-sites.qmd`, which also
      holds two containers of different kinds (a Div and a blockquote) whose
      only content is a nested placement marker, exactly two warnings per render
      say that removing a marker left its container empty, one per container; no
      index is placed at either container's position; and both containers are
      still present, structurally, in the HTML output.
- [x] AC5: `tests/run-tests.sh --self-test` clean (the `verify` slot).

## Coverage

- AC1 → T4, T5
- AC2 → T6, T7
- AC3 → T1, T2
- AC4 → T1, T3
- AC5 → T1, T4, T6

## Tasks

<!-- Positions 1-7 are load-bearing: the Coverage map above indexes tasks
     positionally. Detail for a finished task lives in the work log. -->

- [x] T1: `examples/marker-sites.qmd` (three misplaced-class sites, two
      sole-content nested containers) + the AC3/AC4 checks, failing. A fresh
      fixture: run-tests.sh:2308 pins the duplicate-marker message with its
      block position and :2323 pins the nested count.
- [x] T2: Report the marker class on any non-Div block and any inline span,
      naming the site kind; leave the element untouched.
- [x] T3: Report a nested marker that leaves its container with no content;
      keep the container.
- [x] T4: `examples/id-collision.qmd` (five id claims) + `index_section` and
      `duplicate_ids` in `tests/htmlindex.py` + the AC1 check, failing.
- [x] T5: Mint the HTML index section id against the taken-id table.
- [x] T6: `examples/self-xref.qmd` (four self-reference shapes + a control)
      + the AC2 checks, failing.
- [x] T7: Drop a cross-reference target equal to the mark's own entry levels,
      before the back-end branch.
- [x] T9: README for the three new behaviors + the falsified section-id
      sentence; pin each in the suite's normative arrays.
- [x] T10: `examples/marker-shapes.qmd` — the shapes the reports must NOT fire
      on, beside the one they must (F1-F4, F11).
- [x] T11: F1 — report an emptied container only when every marker is empty.
- [x] T12: F2 — do not check the top-level block when it is itself a marker.
- [x] T13: F4 — walk `doc.blocks`, not `doc`.
- [x] T14: F3 — report an emptied footnote; ROADMAP row for what is uncovered.
- [x] T15: F5 — narrow the both-attributes warning and its README sentence.
- [x] T16: F6, F9 — DESIGN Architecture prose; README's `qi-index` claim.
- [x] T17: R1/R2 root cause — `check_emptied` skips any marker at every depth,
      and "leaves nothing behind" becomes recursive: a marker whose content
      itself empties contributes nothing.
- [x] T18: R3 — report an emptied definition-list definition; re-word the
      ROADMAP row to name what is and is not covered.
- [x] T19: R1/R2/R5 — fixtures and checks for the two shapes that fooled the
      report, each naming the container it is about.
- [x] T20: R6/R7/R8 — DESIGN prose: the report's real reach, the self-target
      caveat, the marker exclusion, the line wrap.
- [x] T21: R9/R10 — pin the reworded both-attributes tail; fix the stale
      sentence-count in the README-pin check message.
- [x] T8: Revert each fix alone and record the failing check. Process evidence,
      deliberately mapped to no criterion: a criterion binding the harness
      rather than the emitted output is the instrument-bound shape the plan
      audit rejected.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), two passes, fresh-context [O] reader; pass 1 returned findings on all five drafts — AC1 self-contradictory (one id string claimed twice could be neither unchanged nor unduplicated), AC2 absence-only and satisfiable by dropping the mark, AC3 an ambiguous count with no residue claim, AC4 leaving the deliverable undetermined, AC5 instrument-bound (deleted) — and pass 2 over the final wording returned AC2 unsatisfiable for the fourth mark (index.lua:720: one \index carries the encap, and no anchor is minted for a mark with an xref), AC3's gfm survival clause false of the writer rather than the filter, T1 breaking run-tests.sh:2308 and :2323, and probe-variety gaps in AC1 and AC4; all disposed in the criteria above, none left to the gate.
- 2026-08-18: plan gate chose warning without editing the element over stripping the misplaced marker class, because the extension otherwise never edits an element the author wrote and the residue is cosmetic; falsified by evidence that the residual class changes rendering or is picked up by styling the extension's own class names invite.
- 2026-08-18: plan gate chose keeping the emptied container and warning over removing it, because deleting a container the author wrote goes beyond removing the marker they asked to be removed; falsified by evidence that an empty container renders as furniture readers read as broken.
- 2026-08-18: plan gate chose warn-and-drop the self-referential target over keeping it (which leaves useless "cats, see cats" output) and over dropping the whole mark (which loses the term, the IP2 corruption class this milestone targets); falsified by an authoring case where a self-target carries meaning, such as a printed form differing from its sort form.
- 2026-08-18: plan chose four defects here with the sort-key clamp as M09 over one five-defect milestone, which reached ~13 tasks past the sizing tripwire; falsified if M09 turns out to share fixtures or code paths with M08 such that splitting duplicates the work.

- 2026-08-18: implement gate — the emptied-container report is additive: the nested-marker message M04 pinned (run-tests.sh:2323) keeps its wording and its check, and the new message names only the extra consequence, so one mistake reads two lines rather than rewriting a pinned contract.
- 2026-08-18: implement gate — a self-target counts as self-referential when it matches what the entry PRINTS, not what it files under, because a reader sees "cats, see cats" whichever sort key the mark carries and the key never appears in the printed index.
- 2026-08-18: minor amendment — added T9 (README + its normative pins). Discovered at T1: README.md documents the marker rules and the cross-reference behavior in prose and README.md:329 states the section id is "fixed rather than minted", which AC1 falsifies; the suite compares named README sentences as bytes, so a documented claim owes a test.
- 2026-08-18: T1 — examples/marker-sites.qmd added (marker class on a heading, an inline span and a fenced code block; a div and a block quote each holding a nested marker as their only content; one real top-level marker with text after it) plus the AC3/AC4 checks. Suite red by design: the first new check reports 0 occurrences of a warning no code emits yet, and every pre-existing check passes.
- 2026-08-18: T2 — report_marker_sites walks the whole document before resolve_markers and reports the marker class on any non-Div block or inline span, naming the site kind (heading / inline span / code block, falling back to the Pandoc type name); the element is never edited. Format-neutral, so it fires in all three formats.
- 2026-08-18: T3 — report_emptied_containers reports, from the shape rather than from walk order, every non-empty block list whose every element is a marker; walk visits contents and never the element itself, so the top-level block is checked directly and its descendants by the walk. Covers Div, block quote, figure and list items, falling back to the type name.
- 2026-08-18: T1's gfm phrase check compared unwrapped text against a wrapped writer's output; the check now collapses whitespace before comparing, the token checks still reading raw source. Suite green: 133 checks.
- 2026-08-18: T4 — examples/id-collision.qmd claims qi-index through qi-index-4 in the five spellings taken_identifiers reads (Pandoc attribute; raw-block double-quoted, unquoted and uppercase ID=; raw-inline single-quoted); htmlindex.py gained index_section (locates the section by its Index heading and returns the wrapper section Quarto puts the id on) and duplicate_ids (prefix-scoped, so Quarto's own furniture is not this milestone's promise). Verified failing first: the render carried qi-index on two elements and the section took a claimed name.
- 2026-08-18: T5 — mint_section_id prefers the bare qi-index and otherwise counts past taken names, so a document with no collision keeps the id it has always had; the fixture's section now mints qi-index-5 and no qi- id is carried twice. Suite green: 135 checks.
- 2026-08-18: T6 — examples/self-xref.qmd carries the four self-reference shapes plus a fifth mark cross-referencing a DIFFERENT entry, the control that tells this check from one dropping every target. Verified failing first: the .tex carried \\index{Cats|see{Cats}}, \\index{Birds!Owls|seealso{Birds: Owls}}, \\index{ferrets|see{ferrets}} and \\index{Dogs|quartoindexseeboth{Dogs}{Pets}}.
- 2026-08-18: T7 — the self-target filter sits after warn_empty_levels and before the back-end branch, comparing levels_key of the target against levels_key of the mark's own levels, so it is format-neutral and compares printed text rather than the filing key. The four reports fire in all three formats; the .tex now carries the three plain keys, Dogs with only its surviving seealso, and Lynxes untouched. Suite green: 138 checks.
- 2026-08-18: T9 — README now states five marker rules (the div-only rule added, the top-level rule extended with the emptied container), documents that a self-referential target is dropped and judged on printed text, and replaces the "fixed rather than minted" section-id sentence with the minting rule. Seven new sentences pinned as bytes in README_MISUSE_CLAIMS and the falsified one in README_MISUSE_STALE. Suite green: 139 checks.
- 2026-08-18: T8 — each fix reverted alone, suite run, first FAIL recorded. T2 removed: "M08-AC3: expected 1 occurrence(s) of <<marker class is written on a heading>> ... got 0". T3 removed: "M08-AC4: expected 2 occurrence(s) of <<was the only content of the>> ... got 0". T5 reverted to the fixed id: "M08-AC1: ids carried by two elements: ['qi-index']; the claimed id 'qi-index' appears 2 time(s), not once; the index section took 'qi-index', a name the document already claimed". T7 reverted: "M08-AC2: expected exactly one \\index{Cats}, found 0; ... a self-referential encap survived: \\index{Cats|see{Cats}}" and seven further clauses. All four fenced; working tree restored clean after each.
- 2026-08-18: completion — tests/run-tests.sh --self-test clean, 153 checks (139 in the plain run). Status to review.
- 2026-08-18: REVIEW RETURN (defect return 1). No acceptance criterion failed as written — all five verified with fresh evidence — but the maintainer judged three findings load-bearing at the gate: the emptied-container report fires when the container keeps content spliced in from a non-empty marker (F1, falsifying the README sentence the suite pins), fires on the surviving top-level marker itself for a div that reaches no output (F2), and report_marker_sites walks doc.meta so a marker class in the title is reported as a misplaced site (F4). Actioned with them: F3 (footnote and table-cell containers emptied unreported, against README's unqualified promise), F5 (the both-attributes warning and README still say every usable target is kept, now false in the case AC2 exercises), F6 (DESIGN.md Architecture prose not updated), F9 (README:314 still calls the section id qi-index unconditionally), F11 (no check discriminates F1 or F2). Deferred to ROADMAP rows: F7, F8, F10. Status to in-progress; the eight actioned findings are the work.
- 2026-08-18: amendment — added T10-T16, the review return's eight actioned findings, as approved at the review gate's disposition chip (which showed the fix/defer split verbatim). No acceptance-criterion wording changes: F11's checks fence AC3/AC4 harder rather than restating them, so no criteria audit is owed.
- 2026-08-18: T10 — examples/marker-shapes.qmd probes the three shapes the reports must NOT fire on (a container whose marker has content, a top-level marker wrapping a nested one, the marker class in the title) beside the one they must (an emptied footnote), with counts pinned per format and the emptied kind named. Verified failing first: two emptied-container reports where one is right.
- 2026-08-18: T11/T12/T13/T14 — all_markers became all_empty_markers (a marker with content splices its content back, so it empties nothing); the top-level block is checked only when it is not itself a marker; report_marker_sites walks doc.blocks rather than doc, so metadata is not a placement site; a Note handler covers footnotes. Table cells remain uncovered — ROADMAP row added rather than over-promising.
- 2026-08-18: T15/T16 — the both-attributes warning now says neither target is dropped for being one of two, and README says so too with the self-target exception stated; README's unconditional "a section carrying the id qi-index" is now conditional; DESIGN.md's Architecture prose corrected in place (marked "corrected M08") for the two new reports, the dropped self-target and the minted section id. Three new README sentences pinned, two stale ones added to README_MISUSE_STALE.
- 2026-08-18: the first revert-probe run of these four fixes destroyed them — `git checkout -- index.lua` inside the probe restores HEAD, and the fixes were not yet committed. Reapplied and re-verified before committing; the probe is re-run after the commit, which is the only order that works.
- 2026-08-18: discrimination for the four review fixes, each reverted alone after committing. F1: "M08-AC4 (F1/F2): expected 1 occurrence(s) of <<was the only content of the>> ... got 2". F2: the same check, same count. F3: "M08-AC4 (F3): the emptied container was not reported as a footnote". F4: "M08-AC3 (F4): expected 0 occurrence(s) of <<marker class is written on>> ... got 1". All four fenced; tree clean after each.
- 2026-08-18: re-review — tests/run-tests.sh --self-test clean, 156 checks (153 before the return). Status back to review.
- 2026-08-18: REVIEW RETURN (defect return 2). No acceptance criterion failed as written; the maintainer judged R1/R2 load-bearing at the gate. Root cause named: check_emptied predicts the strip from the pre-strip shape and is called on marker divs as well as containers, so it reported a marker div while skipping the container that was genuinely emptied, and reported a container that kept its content. Actioned: R1, R2, R3, R5, R6, R7, R8, R9, R10. Deferred: R4 (a marker class in subtitle/abstract is reported nowhere) and R11 (no M08 fixture is in README's tour) — ROADMAP rows. Tasks T17-T21 added; approved at the gate's disposition chip.
- 2026-08-18: T17/T18 — `all_empty_markers` became `empties`, recursive: a list empties when every element is a marker whose content is empty or itself empties, which is what stripping actually does. `check_emptied` refuses any marker at any depth, so the top-level-only guard is gone. DefinitionList branch added. The probe fixture now reports exactly the emptied div, footnote and definition, and stays silent on the container that keeps a marker's content, the container that keeps its own text, and every marker div.
- 2026-08-18: T19 — marker-shapes.qmd gained the two shapes that fooled the previous fix (a container keeping text beside a marker-wrapping-marker; a container emptied through two marker levels) and a definition; the checks now assert one report per container KIND, so a count can no longer pass while the report names the wrong element.
- 2026-08-18: T20/T21 — DESIGN records the report's real reach (any attributed inline, not only spans), the metadata exclusion, the recursive emptying rule, the marker exclusion, and the self-target caveat that clamped and empty-level cases survive; WARN_BOTH now pins the whole reworded message rather than its prefix; the README-pin check message no longer claims all stale sentences were falsified by AC1. Deferred to the ROADMAP: the subtitle/abstract gap and the fixture tour.
## Decisions

## Review

Fresh evidence, `tests/run-tests.sh --self-test` on m08-misuse-defects at
ef1f98c+1908d03, 2026-08-18: exit 0, **153 checks** (139 in the plain run,
against 133 on main before the branch).

- **AC1** verified. The id-collision render reports no `qi-`-prefixed id carried
  by two elements, each of the five claimed ids appears exactly once on the
  element that claimed it, and the section — located by its `Index` heading, not
  by id — minted `qi-index-5` past all five. A second check confirms all 3 links
  inside the minted section still resolve to exactly one element each.
- **AC2** verified. Four self-referential-target reports per render in HTML,
  LaTeX and gfm, and the both-attributes report still fires. The `.tex` carries
  `\index{Cats}`, `\index{Birds!Owls}` and `\index{ferrets}` plain,
  `\index{Dogs|seealso{Pets}}` with only the surviving target, and the control
  `\index{Lynxes|see{Cats}}` untouched. In HTML the three dropped-target entries
  carry locators again, `Dogs` carries only its see-also and no locator, and no
  entry links to itself.
- **AC3** verified. Each of the three misplaced sites reports exactly once per
  render in all three formats; the `<h2>`, `<span>` and `<pre>` all reach HTML
  carrying the class with their content intact; in gfm the visible content
  survives with no `\index{`, `\printindex`, `qi-mark-` or `qi-entry-` token and
  no index section; and the index lands at the one real marker in both back-ends.
- **AC4** verified. Exactly two emptied-container reports per render in all three
  formats, one per container, alongside the two unchanged nested-marker reports
  M04 pinned; both containers — a div and a block quote — are still in the page
  and both are empty; no index is placed at either position.
- **AC5** verified. `tests/run-tests.sh --self-test` exit 0.

Consistency gate: `cairn_validate` all checks passed. No `DESIGN.md` principle
changed, so `cairn_impact --changed` does not apply. The `generic` profile names
no toolchain checks in its `consistency-gate` slot — a clean no-op.

Discrimination evidence (T8): each of the four fixes reverted alone and caught
by a check naming the defect; messages recorded in the work log.

Review fan-out — three lenses, fresh context.

- **[S] prior-PR-comments: no findings.** It confirmed the diff closes M03 F11
  and F13 and M04 F6/F7 as those rows describe, that the M04-pinned
  nested-marker message keeps its wording and its count with the new report
  additive beside it, and that the control mark in `self-xref.qmd` guards
  against the over-dropping failure class M03 pass 1 hit. The
  `gh api .../pulls/comments` probe returned empty, so the per-PR thread walk
  was skipped. It noted the four candidate rows are still on the ROADMAP, which
  is correct: rows graduate at completion, not at review.
- **[S] blame-history: no defects.** Verified the seven README byte-pins match
  verbatim and the falsified sentence is gone; M04's nested-marker message keeps
  its wording and count with the new report additive; M07's Div-not-Header rule
  untouched; the self-reference comparison runs before `sort_for`, so a sort key
  cannot influence it. Two coverage observations, both low severity: no fixture
  combines `sort=` with a self-referential target, and `CONTAINER_NAMES`'
  `Figure` branch is unexercised.
- **[O] diff-bug: 11 ranked findings**, five verified by running the filter at
  review. F1 the emptied-container report fires when the container is NOT left
  empty (`all_markers` tests only that every child is a marker, and a marker
  with content has its content spliced in) — falsifies the README sentence the
  suite pins. F2 the same report fires on the surviving top-level marker itself,
  naming a div that reaches no output. F3 containers that are not Blocks with a
  block-list `.content` (a footnote, a table cell) are emptied unreported,
  against README's unqualified promise. F4 `doc:walk` traverses `meta`, so a
  marker class in the title is reported as a misplaced site. F5 the
  both-attributes warning and README still say every usable target is kept,
  now false in exactly the case AC2 exercises. F6 DESIGN.md's Architecture prose
  is not updated. F7 clamping hides a self-reference (`entry="A!B!C!D"` +
  `see-also="A!B!C, D"` still emits a self-encap). F8 empty-level asymmetry
  hides another (`entry="Cats!"` + `see="Cats!"`). F9 README:314 still calls the
  section id `qi-index` unconditionally. F10 `index_section` takes the first
  `Index` heading. F11 no check discriminates F1 or F2.

### Re-review after the defect return

Fresh evidence, `tests/run-tests.sh --self-test` on m08-misuse-defects at
c9d40bf, 2026-08-18: exit 0, **156 checks** (153 before the return, 133 on main).
All five criteria re-verified by that run; the added checks fence AC3 and AC4
harder rather than changing what they promise.

- **F1, F2** closed and fenced. `examples/marker-shapes.qmd` holds a container
  whose marker carries content and a top-level marker wrapping a nested one;
  exactly one emptied-container report fires per render — the footnote — where
  two fired before. Structural check confirms `#keeps-content` is non-empty in
  the page, so the check proves the container really survives rather than
  agreeing with a wrong report.
- **F3** partially closed, deliberately. Footnotes are now reported by their own
  kind; table cells remain uncovered and carry a ROADMAP row rather than an
  over-promise.
- **F4** closed. Zero misplaced-class reports in a document whose title carries
  the marker class.
- **F5, F9** closed. The warning and README now say neither target is dropped
  for being one of two, with the self-target exception stated; README's section
  sentence is conditional. Three sentences pinned, two added to the stale list.
- **F6** closed. DESIGN.md's Architecture prose corrected in place in three
  places, marked `corrected M08`.
- **F11** closed. Each of the four fixes reverted alone after committing and
  caught by a check naming the defect; messages in the work log.

Deferred, on ROADMAP rows: F7 (clamping hides a self-reference, folded into the
sort-key clamp row M09 owns), F8 (empty-level asymmetry, new row), F10
(`index_section` first-match, folded into the acceptance-suite cluster).

**Re-review findings (fresh-context [O] on the repair commits).** F5, F6 (in
part), F9 and F11 confirmed closed; the `Note` handler verified not to
double-report; `doc.blocks:walk` verified to miss no body block; the "two
markers, one empty one not" and "empty marker plus other content" cases
verified correctly silent; all ten README pins verified verbatim. Eleven
findings, the first three verified here by running the filter:

- R1/R2 — one root cause. `check_emptied` predicts the strip from the pre-strip
  shape and is called on marker divs as well as containers. A container holding
  a marker that wraps an empty marker is skipped (its marker "has content")
  while the marker div itself reports — the message is right by coincidence,
  about the wrong element; and a container that keeps other content reports as
  emptied. The F2 guard was top-level only, so nested marker divs still report.
- R3 — a definition-list definition emptied by a marker is unreported; the
  ROADMAP row names only table cells.
- R4 — `doc.blocks:walk` fixes the title but leaves a marker class in
  `subtitle:`/`abstract:` reported nowhere, though Quarto renders both.
- R5 — reverting F1 and reverting F2 produce byte-identical failures.
- R6/R7/R8 — DESIGN prose: "any block that is not a div, or an inline span"
  understates a report that fires on any attributed inline; the self-target is
  called "reported and dropped" unqualified though F7/F8 survive; the F2
  exclusion is unstated; two lines break the file's wrap.
- R9 — `WARN_BOTH` matches only the message prefix, so the reworded tail is
  unpinned.
- R10 — a check message still says "the {n} sentence AC1 falsified" now that
  the stale list holds three.
- R11 — `marker-shapes.qmd` is absent from README's fixture tour, as all four
  M08 fixtures are; pre-existing.

