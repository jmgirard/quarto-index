# M080: The id census reads a page's raw HTML the way a browser does

- **Status:** review
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
- [x] AC6: `site/html.qmd` and `CHANGELOG.md` each state that an `id=` written
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
- [x] T12: Correct the false sentence where it stands: `site/html.qmd`,
      `CHANGELOG.md`, and `cairn/DESIGN.md`'s KI254, which calls `title` "the
      one" and four lines later names `noscript` and `plaintext` "the same
      shape". The M079-AC5 claim row `census misses a name in a title element`
      pins the false wording and moves with them. Per the amendment gate the
      two pages also name the two states the reading still gets wrong — a
      bogus comment and the script double-escape — so neither page ships a
      sentence false in a state this milestone knows about.
- [x] T13: The four wording repairs and two wrap slips the review found: the
      `note_raw` comments claiming browser parity a per-raw-string walk cannot
      have; `tests/htmlindex.py`'s claim that reader and code disagree about no
      page, which `</textarea/>` and `<iframe/>` falsify; the reader plant's
      header comment presenting three assertions that can never fail as defects
      it catches; the pre-M080 rule still at `examples/id-collision.qmd:166`;
      and the two lines over ~80 columns in `site/html.qmd` and `DESIGN.md`.
- [x] T14: File the four out-of-scope gaps as candidate rows, search-first
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
- 2026-09-06: T12 corrected the false sentence where it stands. `site/html.qmd` and `CHANGELOG.md` now state the residue as a rule over the text-content elements the skip list does not name, with `title` as one such element and no count of them or of the names the reading misses; both also name the two shapes the walk still misreads, a bogus comment and the script double-escape, verified against `note_raw` in a `pandoc lua` harness (`<!ok …>`, `<?…?>`, `<![CDATA[…]]>` and `<script><!--<script></script><p id="ghost">` each claim a name the page carries no element for; a plain `<!-- … -->` and an ordinary tag are the controls). `cairn/DESIGN.md`'s architecture sentence and KI254 are corrected in place, KI256-KI259 added for the review's F2, F3, F4 and F8, and the M079-AC5 claim rows moved with the prose: the `title` row is replaced by three pinning the rule, the instance and the absent count, two more pin the misread shapes, and the numbering row's comment clause is qualified. `sitecheck.py claims` reads all 21 rows against the page, and reddens on the retired sentence when it is planted back.
- 2026-09-06: T13 made the four wording repairs and the two wrap slips. `note_raw`'s comments no longer claim the walk reads a string exactly as a browser does; they state the shape the walk does model and name the limit — each raw string starts in the same state, so a block ending mid-`<script>` leaves a browser reading the Pandoc-generated markup after it as script text and this walk reading it as markup — and the stale "attribute of a tag" line becomes "of an opening tag". `tests/htmlindex.py`'s agreement claim is narrowed to the pages the fixtures write, with the two shapes that part reader from census named and each direction stated: `</textarea/>` ends the element for the census and not for Python (verified by running the reader), `<iframe/>` opens a raw-text element for the census and is self-closing for Python. The reader plant's header comment now names the five `buried-*` names as its discriminating power — measured by putting `CDATA_CONTENT_ELEMENTS` back to two, which returns exactly those five — and says the other negative names cannot fail there. `examples/id-collision.qmd:166` takes the opening-tag rule. `site/html.qmd`'s 106-column line and `cairn/DESIGN.md`'s 95-column one are rewrapped.
- 2026-09-06: T14 filed the follow-ups, search-first against the census and instrument-hardening rows. Two candidate rows added — the three over-collection shapes in `note_raw`, and the missing fixture case for an `id=` on a raw-text element's own opening tag — with KI256-KI259 carrying the findings themselves per D-013. To hold ROADMAP under its line cap the three M075 suite-run-shape rows (parallel legs, named-subset run, per-render timing) were clustered into one; the file is 59 lines / 13,565 bytes.
- 2026-09-06: T12's commit swept T13's and T14's working-tree changes in with it, so their code landed one commit before their checkboxes and these lines. Nothing outside this milestone was in the tree.
- 2026-09-06: T11-T14 verified. `tests/run-tests.sh` green, 773 checks; `tests/run-tests.sh --self-test` exit 0, 1413 checks. The plain run finished clean (773 checks, no FAIL line) but lost its exit code when the desktop app closed mid-run, and the self-test was cut off and re-run whole. All fourteen tasks done, status back to review; AC6 stays unticked for review to verify against the amended wording.
- 2026-09-06: review round 2 opened after the amendment return. Branch synced with `main` (unmoved since the cut) and pushed; PR #80 already open as a draft. Fresh suite runs taken this session: plain exit 0, 773 checks; `--self-test` exit 0, 1413 checks. Consistency gate run — `cairn_validate.py` exit 0, all sixteen PASS, only the sizing advisory (14 tasks). No principle text in the diff, so `cairn_impact` skipped. Round-2 evidence recorded for AC1-AC7 and AC6 ticked against the amended wording. Three review lenses spawned; blame-history and prior-review reported back, diff-bug still running.
- 2026-09-06: round-2 fix-now work committed. R1, R2, R4, R6, R8, R9 and R10 repaired on the branch — the false count of misread shapes dropped from both pages and this repo's architecture sentence, the three comment claims corrected in `html.lua` and `tests/htmlindex.py`, the fourth bogus-comment shape added, two wrap slips and two run-together work-log lines fixed. R5 and R2's behaviour recorded as KI260 and KI261, R7 as KI262 absorbed into the instrument candidate row, and the census candidate row extended to the new shapes. R3 rejected: this round's own plain run exits 0. Verification of the repaired tree in flight.
- 2026-09-06: step-7 approval: PR #80 approved for merge. The gate saw all seven criteria met on fresh evidence, the suite green both ways on the repaired tree, the ten round-2 findings with their dispositions, and an empty PR conversation.

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

### Round 2 — after the amendment return

Evidence gathered 2026-09-06 against branch head `7e22786` on PR #80, from a
fresh pair of suite runs taken this session (`tests/run-tests.sh` exit 0, 773
checks; `--self-test` exit 0, 1413 checks; no FAIL line in either log). The
page facts are read from that run's own capture,
`tests/.work/cap/id-collision-html/id-collision.html`, and its render log
`tests/.work/id-collision-html.log`, with `tests/htmlindex.py` as the reader.

- AC1 — met. Each of `beyond-script`, `beyond-style`, `beyond-xmp`,
  `beyond-iframe`, `beyond-noembed`, `beyond-noframes` and `beyond-textarea`
  is on exactly one element, an author's `p` whose text opens "Raw HTML after
  a … element". Each of the seven marks draws exactly one refusal report
  naming its term and the id it gave up, and is anchored on a minted id,
  `qi-mark-18` through `qi-mark-24`; `qi-mark-24`, the heading case
  `after-textarea`, is on a span carrying no text.
- AC2 — met. Each of `buried-script`, `buried-style`, `buried-xmp`,
  `buried-iframe`, `buried-noembed`, `buried-noframes` and `buried-textarea`
  is on exactly one element, a `span.index` whose text is its mark's term
  (`inside-script` and so on), so it is the span printing the mark. No refusal
  report names any of the seven terms.
- AC3 — met. `veiled-script` and `veiled-textarea` are each on the
  `span.index` printing `false-end-script` and `false-end-textarea`, with no
  report naming either term. `past-spaced-script` and `past-spaced-textarea`
  are each on exactly one element, an author's `p`, their marks
  `spaced-end-script` and `spaced-end-textarea` anchored on `qi-mark-25` and
  `qi-mark-26` and reported once each.
- AC4 — met. `closing-p` and `closing-em` are each on the `span.index`
  printing `on-closing-p` and `on-closing-em`, and no report names either
  term.
- AC5 — met. The twelve yielding terms are each reported exactly once; the
  nine keeping terms draw no report and each still carries the id it was
  written with, on exactly one element (`twin`, `solo`, `in-heading`,
  `qi-mark-9`, `in-comment`, `in-raw-comment`, `twin-xref`, `in-script`,
  `xref-solo`). `nu`'s `in-heading` and `untagged-in-heading` are each on a
  span carrying no text, so both sit outside their headings. No id on the page
  is carried twice, across all 158. The render log holds 21 refusal reports in
  total, which is the twelve plus AC1's seven plus AC3's two and nothing else.
  In the EPUB the same fixture renders to, the sweep reads 16 documents with no
  id carried twice and 44 index fragments each naming an id its document
  carries once.
- AC6 — met, against the amended wording. `site/html.qmd` and `CHANGELOG.md`
  each state the skip-list and closing-tag rule; each states that an element
  whose content a browser reads as text but which the reading does not step
  over is not covered, that a name written inside one is counted against a
  mark which then yields it to a carrier the page does not have, that `title`
  is one such element, and that how many others there are is not stated —
  neither page counts those elements or the names the reading misses, the
  retired "Two names are still missed" sentence being gone from `CHANGELOG.md`.
  `site/html.qmd` no longer carries the sentence about a name after a `script`
  or `style` element going unseen; a grep for it comes back empty. The suite's
  `M079-AC5` claim rows pin all three clauses and read green in this run, and
  planting the retired `title` sentence back into the row list turns that check
  red, so it discriminates.
- AC7 — met. `tests/run-tests.sh` exit 0, 773 checks; `tests/run-tests.sh
  --self-test` exit 0, 1413 checks. Both runs clean on the first attempt this
  session.

Consistency gate: `cairn_validate.py` exit 0, all sixteen checks PASS, every
advisory OK except `sizing`, which warns that M080 carries 14 tasks against a
10-task tripwire — the four the amendment return added. No IP or GP principle
text is added or removed by the diff, so `cairn_impact.py` was not run. The
active profile is `generic`, whose consistency-gate slot names no toolchain
checks.

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


### Findings — round 2

Three fresh-context reviewers, distinct evidence bases. The blame-history lens
found no erosion of prior intent: every deletion it traced to M079's commit is
a widening of the same rule rather than a rollback, the retired `site/html.qmd`
sentence is superseded rather than dropped, and D-011 does not reach this file
(it governs source-shape scans, not the extension's own logic). The
prior-review lens reported the GitHub inline-comment probe empty and, against
the round-1 record, confirmed each recorded disposition was carried out — F1,
F5, F6, F7, F9 and F11 fixed, F2, F3, F4 and F8 filed as KI256-KI259 and the
candidate rows, F10 left alone as recorded. The diff-bug lens lifted `note_raw`
into a `pandoc lua` harness, ran about forty shapes past it, and reports the
four repairs correct on all of them, the loop always advancing; it confirmed
the reader plant goes red on exactly the five `buried-*` names its comment
claims, and returned ten findings.

- R1 (diff-bug, ranked first; found independently in the AC6 read) — both
  shipped pages said "Two shapes this reading gets wrong today", then named the
  bogus comment and the script double-escape. `template` content is a third of
  exactly that kind, recorded on this same branch as KI256, and this file's own
  architecture sentence said three. A fixed count written from recall is the
  failure that produced the AC6 amendment return, one paragraph after the
  sentence that refuses to count the residue. AC6 mandates no count of misread
  shapes, so this is not a criterion failure. Disposition: fixed now — both
  pages drop the count, name `template` as a further shape, and say how many
  there are is not stated; two claim rows follow the prose and two are added.
- R2 (diff-bug) — the rewritten comment at `html.lua:557` claimed an
  unterminated `<!--` runs to the end of the raw string "as it does for a
  browser". A browser also ends a comment at `<!-->`, at `<!--->` and at a
  `--!>` close, none of which this walk ends, so each abandons the rest of the
  string and every later `id=` goes uncounted. Verified in the harness: all
  three claim nothing where `<!-- c -->` claims the name after it. The
  behaviour is pre-existing; the false sentence is new in this diff.
  Disposition: fixed now — the comment states the divergence — plus KI260.
- R3 (diff-bug) — AC7's plain-run clause had no observed exit code, the
  implement-side run having lost it when the desktop app closed. Disposition:
  rejected as already answered — this round took a fresh plain run at exit 0,
  773 checks, recorded in the AC7 evidence line above.
- R4 (diff-bug) — `html.lua:535` said "A comment is stepped over" unqualified,
  which KI257 and the shipped pages both contradict. Disposition: fixed now,
  "A comment spelled `<!--` is stepped over".
- R5 (diff-bug, the reviewer rating it low and uncertain) — inside `svg` or
  `math` a browser is reported not to enter raw-text mode for `style`, so an
  HTML breakout tag written there produces a real element the walk steps over.
  Verified on this side only: the census claims nothing there. Disposition:
  KI261, which records the census behaviour as verified and the browser half as
  the review's unconfirmed reading.
- R6 (diff-bug) — `tests/htmlindex.py` described the `<iframe/>` divergence
  backwards: the census does not stop at it where an `</iframe>` follows in the
  same string, it steps over the content and resumes. Verified in the harness.
  Disposition: fixed now, the comment states what each side does.
- R7 (diff-bug) — nothing pins two facts the documentation rests on: AC6's
  absence clause has no guard, though `sitecheck.py phrase-absent` exists, and
  the claim rows quote "those seven elements' content" without the seven names,
  so the page's enumeration can drift from `RAW_TEXT_ELEMENTS` unnoticed.
  Disposition: follow-up — KI262, absorbed into the id-census instrument
  candidate row rather than a new row, the ROADMAP being at its line cap.
- R8 (diff-bug) — KI257 and its row under-named the bogus-comment family: `</`
  followed by a non-letter is a fourth shape, verified claiming in the harness.
  Disposition: fixed now, added to KI257's examples and to both pages.
- R9 (diff-bug) — two wrap slips of the class T13 repaired: an orphan line
  inside `html.lua`'s comment paragraph and a ragged line in this repo's
  `DESIGN.md`. Disposition: fixed now.
- R10 (diff-bug) — two work-log lines each held two entries run together, the
  newline lost by the script that appended them. Verified by counting entry
  openings per line. Disposition: fixed now; the text of each entry is
  unchanged.

conversation: PR #80 — read once before the gate across all three surfaces:
no reviews, no conversation comments, and no review threads at all, so none
unresolved. Nothing to triage.
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
