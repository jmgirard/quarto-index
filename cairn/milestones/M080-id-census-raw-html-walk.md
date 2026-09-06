# M080: The id census reads a page's raw HTML the way a browser does

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is which id an author's mark keeps on their rendered page, and whether a link they wrote to it still lands
- **Branch/PR:** `m080-id-census-raw-html-walk` / https://github.com/jmgirard/quarto-index/pull/80

## Goal

No `id=` an element of the rendered page actually carries goes uncounted by the
id census, and no `id=` written where the page renders no element is counted
against a mark.

## Scope

**In:** `note_raw` inside `taken_identifiers` (`_extensions/index/modules/html.lua:520-608`),
which today walks a raw HTML string wrongly in four shapes: a closing tag is
re-read as an opening one, so a `script` or `style` element aborts the walk and
every later `id=` goes uncounted; only `script` and `style` have their content
treated as text, so an `id=` inside `xmp`, `iframe`, `noembed`, `noframes` or
`textarea` is counted though the page carries no such element; a closing tag's
attributes are read, so `</p id="x">` counts `x`; and the skip's end-tag search
matches by prefix, so `</scriptx>` ends a script early. The census gains one
declared **skip list** — `script`, `style`, `xmp`, `iframe`, `noembed`,
`noframes`, `textarea` — whose content it steps over. `tests/htmlindex.py`
learns the same seven, its parser today treating only `script` and `style` as
character data. `examples/id-collision.qmd` and the M079-AC1 leg's hand-derived
tables grow the cases; `site/html.qmd` and `CHANGELOG.md` restate the rule.

**Out:** an id Quarto's own writer generates after the filter runs — `fn1`,
`cb1`, `title-block-header` — which needs a reading of the written page rather
than of the AST → KI255 and its candidate row, untouched. `title`, `noscript`
and `plaintext`, which no case can exercise on a rendered page → the narrowed
KI254 entry T10 writes, and the census candidate row. An untagged mark keeping
a contested id → KI253, untouched. Proving the AC1 sweep and the EPUB `unique`
sweep can go red → the suite's self-test-plants candidate row.

## Acceptance criteria

- [x] AC1: For each of the seven elements of the skip list,
      `examples/id-collision.qmd` writes that element closed and, after it in
      the same raw HTML block, an `id=` attribute of an ordinary tag, plus a
      mark carrying that name. On the rendered page each of the seven names is
      carried by exactly one element, the author's; the yielding mark's anchor
      is a minted id — on its own span, or, for the one case whose mark is
      written inside a heading, on the empty span emitted after that heading —
      and the render log carries one refusal report naming that mark's term and
      the id it gave up.
- [x] AC2: For each of the seven elements of the skip list,
      `examples/id-collision.qmd` writes an `id=` attribute of a tag inside that
      element's content, and a mark carrying that name. On the rendered page
      each of the seven names is the id of the span printing its mark's term and
      is on no other element, and no refusal report in the render log names any
      of those seven terms.
- [x] AC3: For `script` and for `textarea`, `examples/id-collision.qmd` writes
      inside that element's content the string `</` + the element's name + a
      further letter + `>`, which is not that element's end tag, followed by an
      `id=` attribute of a tag and a mark carrying that name; and separately
      closes such an element with a real end tag written `</` + the name + a
      space + `>`, followed by an `id=` attribute of a tag and a mark carrying
      that name. On the rendered page each of the first two names is the id of
      the span printing its mark's term with no refusal report naming that term,
      and each of the second two is carried by exactly one element — the
      author's — its mark anchored on a minted id and reported once.
- [x] AC4: At a point in `examples/id-collision.qmd` where no `p` and no `em`
      element is open, a raw HTML block writes a `</p>` closing tag carrying a
      double-quoted `id=` attribute and an `</em>` closing tag carrying an
      unquoted one, plus a mark carrying each of those two names. On the
      rendered page each of the two names is the id of the span printing its
      mark's term, and no refusal report names either term.
- [x] AC5: The twenty-two marks `examples/id-collision.qmd` carried before this
      milestone keep their outcome, on the rendered page and in the EPUB the
      same fixture renders to. The twelve printing `alpha`, `beta`, `gamma`,
      `delta`, `epsilon`, `theta`, `lambda`, `psi`, `rho`, `sigma`, `tau` and
      `phi` still yield the author id each was written with and are still each
      reported once; the nine printing `kappa`, `mu`, `nu`, `xi`, `omicron`,
      `pi`, `chi`, `omega` and `upsilon` still carry theirs and draw no report,
      `nu`'s on the empty span after the heading it is written in; and the
      untagged mark's `untagged-in-heading` is still on an element outside its
      heading.
- [ ] AC6: `site/html.qmd` and `CHANGELOG.md` each state that an `id=` written
      in the text content of one of the elements the census's skip list names,
      or on a closing tag, is on nothing the rendered page carries and so
      contests nothing; each states that an `id=` written inside an element
      whose content a browser reads as text rather than as markup but which
      the skip list does not name is counted against a mark, which then yields
      the name to a carrier the page does not have, names `title` as one such
      element, and states no count of them nor of the names the reading
      misses; and `site/html.qmd` no longer carries its sentence that a name
      written in a raw HTML block after a `script` or `style` element in that
      same block is not seen.
- [x] AC7: `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T1, T3, T5, T8
- AC2 → T1, T2, T4, T6, T8
- AC3 → T1, T4, T6, T8
- AC4 → T1, T3, T7, T8
- AC5 → T5, T6, T7, T8
- AC6 → T12
- AC7 → T2, T8, T9, T10

## Tasks

Detail for the ten finished tasks is in the work log; these lines name the work,
not its findings.

- [x] T1: Reproduce all four wrong shapes against today's `note_raw` in a scratch harness.
- [x] T2: Teach `tests/htmlindex.py` the same seven text-content elements, planted first.
- [x] T3: `note_raw`: tell an opening tag from a closing one, so the skip fires only on an opener and a closing tag's attributes claim nothing.
- [x] T4: `note_raw`: the two-name test becomes the seven-element skip list, its end tag matched by name rather than by prefix.
- [x] T5: AC1's seven cases in `examples/id-collision.qmd`, each element and its carrier in ONE raw block, one of them inside a heading.
- [x] T6: AC2's seven content cases and AC3's four end-tag cases, some as raw inlines, the four `id=` spellings distributed.
- [x] T7: AC4's two closing-tag cases, written where no `p` and no `em` is open.
- [x] T8: The M079-AC1 leg's hand-derived tables and its whole-log refusal count, in the fixture's commit.
- [x] T9: Revert each of T3's and T4's four repairs singly, recording the check each reddens.
- [x] T10: `site/html.qmd`, its claim rows and `CHANGELOG.md`; narrow KI254 in `cairn/DESIGN.md`; correct the architecture sentence.
- [x] T11: Amend AC6 through the gated criterion-amendment protocol so the
      residue is stated as the text-content elements the census's skip list
      does not name, `title` given as one such element and no count claimed.
      Added by the review return 2026-09-06.
- [ ] T12: Correct the false sentence where it stands: `site/html.qmd`,
      `CHANGELOG.md`, and `cairn/DESIGN.md`'s KI254, which calls `title` "the
      one" and four lines later names `noscript` and `plaintext` "the same
      shape". The M079-AC5 claim row `census misses a name in a title element`
      pins the false wording and moves with them. Per the amendment gate the
      two pages also name the two states the reading still gets wrong — a
      bogus comment and the script double-escape — so neither page ships a
      sentence false in a state this milestone knows about.
- [ ] T13: The four wording repairs and two wrap slips the review found: the
      `note_raw` comments claiming browser parity a per-raw-string walk cannot
      have; `tests/htmlindex.py`'s claim that reader and code disagree about no
      page, which `</textarea/>` and `<iframe/>` falsify; the reader plant's
      header comment presenting three assertions that can never fail as defects
      it catches; the pre-M080 rule still at `examples/id-collision.qmd:166`;
      and the two lines over ~80 columns in `site/html.qmd` and `DESIGN.md`.
- [ ] T14: File the four out-of-scope gaps as candidate rows, search-first
      against the existing census and instrument-hardening rows: a `template`
      element's content counted; a bogus comment (`<!…>`, `<?…>`,
      `<![CDATA[…]]>`) read as markup; the script double-escape state
      unmodelled; and no fixture case writing an `id=` on a raw-text element's
      own opening tag.

## Work log

- 2026-09-06: created by /milestone-plan.
- 2026-09-06: criteria audit ran in FULL mode (surface tier user-facing), two rounds, fresh-context [O] readers. Round 1 returned findings on all five drafted criteria — AC2 unsatisfiable against `tests/htmlindex.py`'s parser, AC1's promise under-naming its family, AC4 instrument-bound and fighting the leg's whole-log count, AC3's free element names truncating the parse tree, AC5's unbounded absence claim, CHANGELOG drift — all six fixed and reported at the gate. Round 2, over the post-gate wording, returned nine more: AC1 unsatisfiable for its heading case, AC5 misstating `nu`'s kept-id location, the leg's refusal count contradicting AC1, AC6 contradicting a live claim row, "raw HTML block" excluding the mandated raw inlines, the `title` residue unnamed, AC3 leaving the whitespace-terminated end tag unvaried, AC4's `</em>` placement, and the EPUB co-render unstated. All nine disposed into the wording above and into T2, T8 and T10.
- 2026-09-06: plan gate chose the seven exercisable skip-list elements over the full HTML5 text-content family (adding `title`, `noscript`, `plaintext`) because no case can exercise those three on a rendered page and the criteria would then promise over members no procedure sweeps; falsified by an author reporting an id written in a `title` or `noscript` element lost or contested.
- 2026-09-06: plan gate chose taking the end-tag match rule in scope over recording it as a fresh known issue, because the skip list gaining five members makes the early-close shape live for five more elements at no extra code cost; falsified by the stricter match rejecting an end tag a browser accepts.
- 2026-09-06: plan gate chose distributing the four `id=` spellings, two raw-inline cases and one heading case across the new marks over one shape and one spelling throughout, because a single exemplar standing for a family is the probe blindness M079's own review left behind; falsified by a defect the distributed cases miss that a full cross-product would have caught.
- 2026-09-06: plan chose repairing `tests/htmlindex.py`'s parser over writing the AC2 cases in shapes both readers already agree on, because the suite's reader is meant to model a browser and today reads `textarea` content as markup; falsified by the repair changing an existing leg's reading of any captured page.
- 2026-09-06: T1 reproduced all four wrong shapes against today's `note_raw` in a scratch harness (`pandoc lua`, the function lifted verbatim with a stub `claim`). `<script>var a = 1;</script><p id="after-script">y</p>` claims nothing, want `after-script` (same for `style`); `<textarea><p id="ghost-textarea">x</p></textarea>` claims `ghost-textarea`, want nothing (same for `iframe`, `xmp`, `noembed`, `noframes`); `</p id="on-closing-p">` claims `on-closing-p`, want nothing; `<script>a</scriptx> <p id="early">z</p></script><p id="after-false">w</p>` claims `early`, want `after-false`. A fifth shape falls out of the first: `</script >` with a space is matched by prefix, re-read as an opener, and everything after it goes uncounted. The M079-AC1 leg can see none of the four — the fixture's only skip-list element is the one `<script>` at line 178, whose raw block ends with it, and it writes no closing tag carrying attributes and no end-tag lookalike.
- 2026-09-06: baseline before any change on this branch — `tests/run-tests.sh` exit 0, 773 checks, 21m18s.
- 2026-09-06: question gate chose descriptive names for the twenty new marks (`after-script`, `inside-textarea`) over a second alphabet, one new fixture section per rule over one combined section, and overriding Python's parser list of text-content elements over hand-written skipping in `tests/htmlindex.py`.
- 2026-09-06: T2 gave `tests/htmlindex.py` a `RAW_TEXT_ELEMENTS` list of the same seven and named it as `_Builder.CDATA_CONTENT_ELEMENTS`; Python's parser reads that list off the instance, so the five it did not know now get its own `script` rule, end-tag match included. A new suite section before M079-AC1 plants the defect: with the reader holding only `script`/`style` it reports `buried-xmp`, `buried-iframe`, `buried-noembed`, `buried-noframes` and `buried-textarea` as elements of its tree, and reports none of them after, while still reading the nine ids an element really carries.
- 2026-09-06: T3 and T4 rewrote `note_raw`. A tag now records whether it is a closing one, so attributes are read to find the `>` but claim nothing on a closing tag, and the character-data skip fires on opening tags only; the two-name `script`/`style` test became a declared `RAW_TEXT_ELEMENTS` table of the seven, and the end tag is matched as `</` + name followed by whitespace, `/` or `>` rather than by prefix. Against T1's matrix the function now returns the browser's answer on all sixteen cases, the comment, quoted-attribute-value and unterminated-script controls unchanged.
- 2026-09-06: T2, T3 and T4 were verified by one suite run rather than three, the run costing 21 minutes and the two `note_raw` repairs being halves of one rewrite; T9 reverts each of the four singly. `tests/run-tests.sh` exit 0, 773 checks (772 before this branch, the reader plant being the one added).
- 2026-09-06: T5, T6 and T7 appended four sections to `examples/id-collision.qmd`, one per rule, with twenty new marks named for the shape each tests (`after-script`, `inside-textarea`, `false-end-script`, `on-closing-p`). Seven AC1 cases each write their element and its carrier in one raw block, the `textarea` one marked inside a heading; seven AC2 cases write an `id=` inside the element's content, two of them as raw inlines; AC3's four cover the end-tag lookalike and the space-spelled real end tag for `script` and `textarea`, one a raw inline; AC4's two write a `</p>` and an `</em>` carrying attributes where neither element is open. The four `id=` spellings are spread across the new cases.
- 2026-09-06: T8 grew the M079-AC1 leg's hand-derived tables with `CONTESTED_RAW` (nine) and `KEPT_RAW` (eleven), added `after-textarea` to `RELOCATED`, and gave the locator sweep a relocated branch: a refused locator mark written inside a heading has its anchor on the empty span after it, so the sweep reads the anchor's emptiness and the heading sweep then holds that span's id to the one the locator names. The whole-log refusal count follows the tables and is now 21.
- 2026-09-06: T9 reverted each of the four repairs singly against the extended fixture, rendering and running the leg in a scratch loop rather than the whole suite (the profile's own guidance for needing one check's behavior). Claiming from a closing tag again: `closing-p` and `closing-em` on 0 elements, their locators minted, two spurious refusal reports. The skip firing on a closing tag again: nine ids on 2 elements each (`beyond-script`, `beyond-style`, `beyond-xmp`, `beyond-iframe`, `beyond-noembed`, `beyond-noframes`, `beyond-textarea`, `past-spaced-script`, `past-spaced-textarea`) with their locators still naming the contested id. The skip list back to `script`/`style`: `buried-xmp`, `buried-iframe`, `buried-noembed`, `buried-noframes`, `buried-textarea` and `veiled-textarea` on 0 elements. The end tag matched by prefix again: `veiled-script` and `veiled-textarea` on 0 elements with spurious refusals. Each revert reddens M079-AC1 on its own set of names.
- 2026-09-06: T5-T9 verified by one suite run, the fixture rows and the leg tables having to move together; `tests/run-tests.sh` exit 0, 773 checks, M079-AC1 reading 158 ids on the page with 21 refused and 20 kept.
- 2026-09-06: T10 checkpoint, verify still running. `site/html.qmd` now states the rule over an opening tag, the seven text-content elements, the markup after one of them, and the closing tag, drops its sentence about a name after a `script` block going unseen, and names `title` as the residue; the numbering paragraph follows. Five claim rows replace the retired one in the M079-AC5 list, and `tests/sitecheck.py claims` reads all 17 against the page. `CHANGELOG.md`'s unreleased entry restates the same rule and the two names still missed. `cairn/DESIGN.md`'s architecture sentence is corrected and KI254 is narrowed in place to the `title` residue, with `noscript` and `plaintext` named as the same shape. The census candidate row already reads as what remains, so it is left as the plan narrowed it.
- 2026-09-06: T10 verified. `tests/run-tests.sh` exit 0, 773 checks; `tests/run-tests.sh --self-test` exit 0, 1413 checks (1412 before this branch). All ten tasks done, status to review.
- 2026-09-06: plan chose keeping every new case in `examples/id-collision.qmd` over a sibling fixture, because that page's whole-page duplicate-id sweep is the procedure AC1's and AC2's universals name and a second page would sit outside it; falsified by that render becoming a named cost in the suite's timing profile.
- 2026-09-06: review opened. Branch synced with `main` (unmoved since the cut, no merge needed) and pushed; draft PR #80 opened and recorded in the header. Consistency gate's universal checks run: `cairn_validate.py` exit 0, all sixteen PASS, every advisory OK. No IP/GP principle text changed, so `cairn_impact` is skipped. Suite runs for AC7 in flight; three review lenses spawned.
- 2026-09-06: review step 3 evidence recorded for AC1-AC5 and AC7 against the suite's own capture and render log, and those six ticked; AC6 left unticked. Suite green alone: plain exit 0, 773 checks; --self-test exit 0, 1413 checks. An earlier plain run exited 1 on a quarto Deno segfault in the M14 review-F9 book render while three review subagents shared the machine; re-run clean.
- 2026-09-06: amendment return: AC6 — "each names `title` as the one such element the rule does not cover". The clause enumerates the text-content elements the skip list does not cover and names no procedure that decides that membership; `noscript` and `plaintext` are the same shape and are also uncovered, so the criterion mandates a false sentence in two shipped pages. The only repair widens the enumeration, so this counts on the amendment-return track and not toward defect returns. Status to in-progress for that amendment; review stops.
- 2026-09-06: review gate chose sending M080 back with the full fix pass over wording only, merging as it stands, or stopping: the criterion amendment, the three corrected surfaces, the four wording repairs and the four follow-up rows are convened as T11-T14. PR #80 stays open as a draft, unmerged.
- 2026-09-06: the Tasks section was compressed in one rewrite to hold the plan-owned body under its cap once T11-T14 were added; the ten finished tasks keep their ids and the work log keeps their detail.
- 2026-09-06: re-audit: AC6 (full) — seven findings on the first amended draft: the residue clause's universal false for a closing tag and for a comment inside a non-skip element, T11 and T12 still mandating the rejected widening, the promise stopping at "counted" without the consequence to the author's mark, "no bound" naming two different page states, the M079-AC5 claim row pinning the retired sentence unnamed, Coverage still reading AC6 → T10, and the skip-list clause unqualified against the script double-escape state. Four repaired into a second draft; the rest went to the gate.
- 2026-09-06: re-audit: AC6 (full) — six findings on the second draft, its own fresh reader: the residue domain read as the complement over ALL elements, so the mandated sentence is false for an ordinary `div`; `CHANGELOG.md`'s "two names are still missed" surviving the no-count clause; Coverage crediting T11, which writes no page state; the absence clause decided by paraphrase; the count "seven" fixed against a list the same clause names intensionally; and the shipped comment sentence false for a bogus comment. Findings 1, 2, 3 and 5 repaired into the wording below; 4 and 6 went to the gate. This is the criterion's second re-audit line and its stop.
- 2026-09-06: amendment return: AC6 — "each states that an `id=` written inside an element whose content a browser reads as text rather than as markup but which the skip list does not name is counted against a mark, which then yields the name to a carrier the page does not have, names `title` as one such element, and states no count of them nor of the names the reading misses". The return was classified under the widening test, so the repair narrows the promise to what a stated procedure settles — the skip list the code declares — rather than naming three elements instead of one. Coverage moves to AC6 → T12; T11 and T12 are reworded to match.
- 2026-09-06: amendment gate chose stating the residue as a rule over the text-content elements the skip list does not name, over dropping the residue sentence, and chose naming on both pages the two states the reading still gets wrong — a bogus comment and the script double-escape — over shipping those two rules unqualified with the gaps recorded alone.
## Decisions

## Review

Evidence gathered 2026-09-06 against branch head on PR #80. The page facts
below are read from the suite's own capture of `examples/id-collision.qmd`
(`tests/.work/cap/id-collision-html/id-collision.html`) and its render log,
with `tests/htmlindex.py` as the reader — the reader the M080-AC2 (reader)
section plants a defect against and proves able to report it.

- AC1 — met. Each of the seven names `beyond-script`, `beyond-style`,
  `beyond-xmp`, `beyond-iframe`, `beyond-noembed`, `beyond-noframes` and
  `beyond-textarea` is carried by exactly one element of the rendered page, the
  author's. Each of the seven marks draws exactly one refusal report naming its
  term and the id it gave up, and is anchored on a minted id — `qi-mark-18`
  through `qi-mark-24`. The heading case, `after-textarea`, has its `qi-mark-24`
  on an empty span, read back as carrying no text.
- AC2 — met. Each of `buried-script`, `buried-style`, `buried-xmp`,
  `buried-iframe`, `buried-noembed`, `buried-noframes` and `buried-textarea` is
  on exactly one element, and that element's text is its mark's term
  (`inside-script` and so on), so it is the span printing the mark. No refusal
  report in the render log names any of the seven terms.
- AC3 — met. Past the two end-tag lookalikes, `veiled-script` and
  `veiled-textarea` are each the id of the span printing `false-end-script` and
  `false-end-textarea`, with no report naming either term. Past the two real end
  tags spelled with a space, `past-spaced-script` and `past-spaced-textarea` are
  each carried by exactly one element, the author's `p`, and their marks
  `spaced-end-script` and `spaced-end-textarea` are anchored on `qi-mark-25` and
  `qi-mark-26` and reported once each.
- AC4 — met. `closing-p` and `closing-em` are each the id of the span printing
  `on-closing-p` and `on-closing-em`, and no report names either term.
- AC5 — met. All twelve yielding terms (`alpha`, `beta`, `gamma`, `delta`,
  `epsilon`, `theta`, `lambda`, `psi`, `rho`, `sigma`, `tau`, `phi`) are
  reported exactly once each; all nine keeping terms (`kappa`, `mu`, `nu`, `xi`,
  `omicron`, `pi`, `chi`, `omega`, `upsilon`) still carry the id each was
  written with, on exactly one element, with no report. `nu`'s `in-heading` is
  on an empty span, and `untagged-in-heading` is likewise on an element carrying
  no text, so both sit outside their headings. No id on the page is carried
  twice, across all 158. In the EPUB the same fixture renders to, the `unique`
  sweep reads 16 documents with no id carried twice and 44 index fragments each
  naming an id its document carries once.
- AC6 — NOT ticked. Both pages carry the wording the criterion mandates:
  `site/html.qmd` and `CHANGELOG.md` each state that an `id=` in the text
  content of one of the seven, or on a closing tag, is on nothing the page
  carries, and each names `title` as the one such element the rule does not
  cover; and `site/html.qmd` no longer carries its sentence about a name after a
  `script` or `style` element going unseen. The mandated sentence is false —
  see F1 below — so the criterion is met as written while promising the reader
  something untrue. This is the amendment return recorded below.
- AC7 — met. `tests/run-tests.sh` exit 0, 773 checks; `tests/run-tests.sh
  --self-test` exit 0, 1413 checks. An earlier plain run exited 1 on a quarto
  Deno segmentation fault in the M14 review-F9 book render, taken while three
  review subagents shared the machine; the clean re-run alone is the one
  recorded here, and no check disagreed in either run.

Consistency gate: `cairn_validate.py` exit 0, all sixteen checks PASS and every
advisory OK, including `coverage complete` and `release window`. No IP or GP
principle text changed, so `cairn_impact.py` was not run. The active profile is
`generic`, whose consistency-gate slot names no toolchain checks.

### Findings

Three fresh-context reviewers, distinct evidence bases. The prior-review lens
reported no prior-review evidence contradicted: the GitHub inline-comment probe
came back empty, and against the archived `## Review` records it found the
branch repairs exactly what M079 deferred and touches none of M079's fixed
expectations. The blame-history lens found no erosion of prior intent and one
cosmetic issue (F11 below). The diff-bug lens lifted `note_raw` into a
`pandoc lua` harness and confirmed the four repairs correct over the whole
fixture and against the HTML5 tokenizer states, and returned eleven findings.

- F1 (diff-bug, ranked first) — the shipped claim that `title` is the ONE
  text-content element the rule does not cover is false. `noscript` content is
  raw text with scripting enabled and `plaintext` runs to end of file, so
  neither renders an element for an `id=` written inside it, and neither is in
  the census's skip list. `cairn/DESIGN.md`'s narrowed KI254 contradicts itself
  in one entry, calling `title` "the one" and then naming `noscript` and
  `plaintext` "the same shape". Verified by reading: neither name is in
  `RAW_TEXT_ELEMENTS`, so an `id=` inside either is claimed. An author writing
  `<noscript><p id="mine">` and a mark on `mine` is told a refusal that the
  page's own rule says cannot happen, and their `#mine` link breaks.
  Disposition: amendment return on AC6 — the criterion's own wording mandates
  the false sentence, so it cannot be repaired review-side.
- F2 (diff-bug) — a `<template>` element's content is counted, though its
  contents live in a separate document fragment and no element of the page
  carries the id. Inside the Goal's second half, named nowhere in Scope, KI254
  or the candidate rows. Disposition: follow-up — a DESIGN.md Known issues
  entry and a candidate row.
- F3 (diff-bug) — a bogus comment (`<!…>`, `<?…>`, `<![CDATA[…]]>`) is read as
  markup, so ids inside one are counted; only the literal `<!--` is treated as
  a comment. Pre-existing, same over-collection class as the closing-tag shape
  this milestone repaired. Disposition: follow-up — Known issues entry and
  candidate row.
- F4 (diff-bug) — the script double-escape state is not modelled, so
  `<script><!--<script></script><p id="ghost">` counts a phantom id. Obscure but
  reachable. Disposition: follow-up — Known issues entry and candidate row.
- F5 (diff-bug) — the new comments at `html.lua:549-551` and `:631-633` claim
  the walk reads "exactly as a browser reads it", which a per-raw-string walk
  cannot promise: a raw block ending mid-`<script>` leaves a browser in script
  state across the Pandoc-generated markup after it. Disposition: fix now,
  comment wording only.
- F6 (diff-bug) — `tests/htmlindex.py`'s "the reader and the code under test
  disagree about no page" is stronger than what holds: `</textarea/>` and
  `<iframe/>` are two real divergences, neither in the fixture. Disposition:
  fix now, comment wording only.
- F7 (diff-bug) — three of the reader plant's negative assertions
  (`closing-p`, `closing-em`, `veiled`) can never fail, so the section's
  discriminating power is the five `buried-*` names; its header comment presents
  all of them as the defect it must catch. Disposition: fix now, comment
  wording only.
- F8 (diff-bug) — no fixture case writes an `id=` on a raw-text element's own
  opening tag (`<style id="x">`), which must still be claimed, so moving the
  `claim` inside the skip guard would redden nothing. Disposition: follow-up —
  candidate row.
- F9 (diff-bug) — `examples/id-collision.qmd:166` still states the pre-M080
  rule, "an `id=` counts where it is an attribute of a tag, and nowhere else",
  two sections above the new section stating the closing-tag rule; the fixture's
  prose renders into the gallery. Verified by reading. Disposition: fix now.
- F10 (diff-bug) — task T6's text says two of the eleven are raw inlines; the
  fixture writes three (`buried-noframes`, `buried-textarea`,
  `veiled-textarea`). More coverage than promised. Disposition: noted here, no
  change; the tasks are done and the record stands.
- F11 (diff-bug, and the blame-history lens's only finding) — `site/html.qmd:94`
  (106 chars) and `cairn/DESIGN.md:385` (95 chars) were left unwrapped against
  both files' own ~80-column habit. Disposition: fix now.

conversation: PR #80 carries no reviews, no comments and no unresolved
threads — the read came back empty.

### Amendment return

AC6 names no procedure that decides which text-content elements the rule does
not cover; its enumeration is fixed by author recall, and F1 shows it false.
The only repair widens that enumeration, so this is an amendment return rather
than a defect return, and it does not count toward the thrash rule's defect
returns. The plan gate's own record already knew the residue was three
elements — it names `title`, `noscript` and `plaintext` together — so the
defect is in AC6's wording and the two pages written to it, not in the scoping
choice.
