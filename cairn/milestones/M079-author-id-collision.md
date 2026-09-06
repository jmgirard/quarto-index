# M079: An author-written mark id never leaves two elements sharing it

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is an author's rendered page and where its index links land
- **Branch/PR:** m079-author-id-collision / https://github.com/jmgirard/quarto-index/pull/79

## Goal

An author-written id on an index mark never leaves two elements of one page carrying that id, so every index locator lands on the element its author marked.

## Scope

**In:** the id census and anchor assignment in the HTML back-end (`_extensions/index/modules/html.lua:485` and `:579`), which serves the HTML and EPUB routes alike; a report naming an author-written id the extension did not use as a mark's anchor; `examples/id-collision.qmd` extended with both collision shapes and the non-colliding controls; suite legs on the HTML and EPUB renders; an exactly-once assertion in `tests/fragments.py resolve`; `site/html.qmd` and `CHANGELOG.md`.

**Out:** a mark recovered from another chapter's source, whose author-written id the recovery route cannot settle against a rendered page it never sees (D-055) — that overlap is held by the candidate row added 2026-09-05 from M078's review. Renaming an id on an element that is not a mark — the extension writes only its own spans; the colliding element keeps what its author wrote. The LaTeX back-end, whose `\index` emission carries no ids. A book chapter render: each chapter is one page with one id space, and the shared code path is proven on the two format routes instead.

## Acceptance criteria

- [x] AC1: Rendering `examples/id-collision.qmd` to HTML produces a captured page carrying no id more than once, counted by a sweep over every `id=` attribute of that page. The fixture carries both collision shapes: a mark whose author-written id names a non-mark element, written across the five id spellings the census reads (a Pandoc attribute; raw HTML double-quoted, unquoted and uppercase `ID=`; a raw inline, single-quoted) and once as a name the extension would otherwise mint; and two marks sharing one author-written id. No colliding id is written on a heading, whose id Quarto derives further copies from. The same sweep over that fixture rendered at the branch's merge-base reports a repeat for every colliding id the fixture carries.
- [x] AC2: Rendering the same fixture to EPUB produces a publication in which no XHTML document the package manifest lists carries an id more than once, and every link inside a generated index section resolves to an id its target document carries exactly once — both read through `tests/epubindex.py`, over at least one document carrying a generated index section. The same reading at the merge-base reports a repeat.
- [x] AC3: On AC1's captured render, every mark whose author-written id the extension refused carries a minted `qi-mark-<n>` instead — on the mark's own span, or, where the mark is written inside a heading, on the empty span the extension emits after that heading, no anchor of any kind being left where the table of contents copies it. Where such a mark files a locator, that locator's fragment names its own minted id; where it is a cross-reference mark it files no locator at all. Where two marks that both file locators are written with one author-written id, the one written first in the document keeps it.
- [x] AC4: On AC1's render the run writes one warning per mark whose author-written id it refused, naming that id and that mark's printed term, and writes no such warning for any other mark. The same fixture's marks whose author-written ids collide with nothing — one nothing else carries, one inside a heading, and one spelled as a name the extension would otherwise mint — each still carry the author's id, with the mark's locator fragment naming it.
- [x] AC5: `site/html.qmd` states which element keeps a contested id, what a refused mark gets instead, and that a refusal is reported; its present sentence promising a mark keeps an id of the author's own (line 20) no longer stands unqualified. `CHANGELOG.md` carries an entry whose statement of the behavior is true of AC1's captured render.
- [x] AC6: `tests/run-tests.sh` runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T4
- AC3 → T1, T2
- AC4 → T1, T3
- AC5 → T6
- AC6 → T1, T2, T3, T4, T5

## Tasks

- [x] T1: Extend `examples/id-collision.qmd` with both collision shapes across the axes AC1 names, plus the three non-colliding author-id marks AC4's control needs; add the suite leg sweeping the captured HTML page for a repeated id, and record it red at the merge-base before the fix lands.
- [x] T2: Count occurrences in the id census (`taken_identifiers`, `html.lua:485`) and make `assign_anchors` (`html.lua:579`) refuse a mark's author-written id that another element carries, minting one instead; among marks sharing an id the first in document order keeps it. (RB tripwire: ip-touching)
- [x] T3: Add the refusal report naming the refused id and the mark's printed term; add the leg asserting the whole warning set on AC1's render and the intact author ids and locators of the three non-colliding marks.
- [x] T4: Add the EPUB leg reading the publication through `tests/epubindex.py` for a repeated id and for an index-section link whose target id is not unique, with the member count asserted non-zero.
- [x] T5: Make `tests/fragments.py resolve` (`fragments.py:80`) assert a fragment's target id is on its page exactly once; prove it red by planting a duplicate in both collision shapes and at more than one capture site.
- [x] T6: Correct `site/html.qmd`'s id paragraph and write the `CHANGELOG.md` entry, both against AC1's observed render.
- [x] T7: Update `DESIGN.md`'s account of id assignment (line 364), which today states only that a minted id steps over an author's.

- [x] T8: Stop an `id=` written inside an HTML comment from counting as a carrier in the id census, so a mark keeps a name no element of the rendered page holds and no refusal is reported for one; add the fixture case and the suite leg, recorded red before the fix.
- [x] T9: Settle the cross-reference and page-only mark case, which carries no pending tag and so keeps a contested id unwarned: either bring such marks under the refusal rule or state the exception where an author reads it; add the fixture case either way.
- [x] T10: Narrow the claims in `CHANGELOG.md` and `site/html.qmd` to what the code does — the recovery route reads a chapter without its rendered page, the cross-reference exception, and the report naming a mark's `entry=` where it carries one rather than the term it prints.
- [x] T11: Add the step naming M079 to the warning-count comment in `tests/scans/warn-distinct.py`, which stops at M073's `83 + 1 = 84`.

- [x] T12: Restore relocation for an `.index` span carrying an author-written id that the Span pass never tagged (the `"keep"` disposition at `passes.lua:463`), which T9 dropped from `html.lua:574` and which leaves such an id in a heading and in Quarto's copy of it. Add the fixture case and the suite leg, recorded red before the fix.
- [x] T13: Make the census's comment cut (`html.lua:525`) track HTML's comment grammar, so a `<!--` inside a quoted attribute value or script text no longer discards every `id=` after it in that raw string. Add the fixture case and the suite leg, recorded red before the fix.
- [x] T14: Take AC3's minted-id clause through the gated criterion-amendment protocol so it holds for a mark inside a heading, whose anchor relocates onto an empty span the mark itself does not carry; then drop the AC1 leg's `RELOCATED` exemption or state on the criterion what the exemption leaves unproven.
- [x] T15: Narrow `site/html.qmd:56-60`'s promise that the generated numbering steps over any name written in the source, false after T8 for a name only an HTML comment holds, and add a claim row holding the narrowed form.
- [x] T16: Supersede D-055's two sentences this branch made false — that `assign_anchors` never renames an author's id, and that `tests/fragments.py` does not check a fragment resolves uniquely — with one D-entry.
- [x] T17: Write the milestone's `## Decisions` entries for the two user-visible rules the branch ships with only work-log lines behind them: a cross-reference mark yielding a contested id, and a locator-contributing mark outranking a cross-reference mark for a shared name.
- [x] T18: State the front-matter mark of an HTML book chapter, which keeps a contested id unreported, in `CHANGELOG.md` and `site/html.qmd`; the exception stands in `DESIGN.md` and `passes.lua` and in neither shipped page.
- [x] T19: Correct the AC1 leg's derivation banner (`tests/run-tests.sh:3930-3941`), which still says seven contested names, six uncontested and "all thirteen" where its dicts hold 11 and 8, and re-wrap `cairn/DESIGN.md:382`.

## Work log

- 2026-09-05: created by /milestone-plan.
- 2026-09-05: defect reproduced before planning — a 15-line probe rendered `shared` and `twin` twice each, with locator hrefs `#shared`, `#twin`, `#twin`; those were the only repeated ids on the page.
- 2026-09-05: criteria audit ran in full mode (user-facing tier), two rounds in one fresh-context [O] reader. Round 1 returned 11 findings, round 2 a further 10 on the revised wording; all were disposed at the plan gate — six fixed in the draft before the gate, three posed as gate questions, the rest fixed after it. Largest: the criterion binding `tests/fragments.py` bound an instrument rather than the deliverable and was demoted to T5; a control criterion for the kept case was missing entirely; and a criterion asserting `[x]{#qi-mark-3 .index}` alone yields a duplicate was false, the census already collecting the mark's own id.
- 2026-09-05: plan gate chose refusing the mark's id with the first carrier in document order keeping it over every colliding mark yielding, because an id the author wrote stays on the page and their own link to it still resolves; falsified by a report that the order-dependence surprised an author, or a case where the first carrier is the wrong element to keep.
- 2026-09-05: plan gate chose warn-and-mint over reporting the collision and changing nothing, because two elements on one id is output the contract calls incorrect and the locator still lands wrong; falsified by evidence an author relies on a mark keeping its id when contested.
- 2026-09-05: plan gate chose sweeping every id on the page over sweeping only extension-written ids, because the case that started this is a mark colliding with an element the author wrote; falsified by a Quarto release repeating an id in its own scaffold.
- 2026-09-05: implement opened on branch `m079-author-id-collision`; the merge-base capture carries no page-wide duplicate id outside the fixture's own, so AC1's whole-page sweep has a clean floor.
- 2026-09-05: plan gate chose HTML plus EPUB coverage over adding a book chapter leg, because the shared code path is proven on the two format routes and the book route's author-id handling is covered elsewhere; falsified by a book chapter render showing a duplicate the two legs miss.
- 2026-09-05: implement gate chose the mark yielding to any element that is not a mark, with document order deciding only between two marks, because the plan gate's "first carrier wins" leaves the page carrying a repeated id whenever the mark is written first and the extension renames no element of the author's that is not a mark; falsified by a case where the element that is not a mark is the wrong one to keep.
- 2026-09-05: implement gate chose leaving a cross-reference mark's author-written id untouched, because no generated link points at such a mark, so refusing its id would break an author's own link and repair no locator; falsified by an author reporting a duplicate id that came from a cross-reference mark.

- 2026-09-05: T1-T7 written. At the merge-base the extended fixture's HTML render repeats seven ids — the five id spellings, the mint-shaped name and the two-mark case — and the EPUB render fails the new uniqueness check on 15 clauses across three documents; with the fix both are clean and seven refusal reports name their id and term. `tests/fragments.py resolve` now holds a target id to exactly one element, proven red by a plain element claiming a cross-page locator's id and by a second mark claiming a same-page one, green on the unplanted capture.
- 2026-09-05: the pinned filter warning count moves 84 -> 85 for the refusal report (`tests/scans/warn-distinct.py`), which a first whole-suite run caught.
- 2026-09-05: KI252 records a pre-existing shell-quoting defect in one `tests/run-tests.sh` message, found in that run's output; a candidate row states the work.
- 2026-09-05: checkpoint with tasks unticked: the whole-suite `--self-test` run that verifies them is still in flight. Its three M079 legs have already passed in it.

- 2026-09-05: whole suite green with `--self-test` on this tree: 1412 checks, 1766s across 158 sections, exit 0, no failure. Tasks T1-T7 ticked; status to review.

- 2026-09-05: review opened; draft PR #79. Merge-base floor re-rendered fresh from this branch's fixture: HTML repeats the seven contested ids, the EPUB reading reports 15 clauses across three documents. Whole-suite run and the three fresh-context reviewers still in flight.

- 2026-09-05: review evidence gathered; AC1-AC6 all green (whole suite 1412 checks, exit 0) and cairn_validate clean. Three fresh-context lenses returned 13 findings; two verified by reproduction against the implementation — an id inside an HTML comment counted as a carrier, which kills an author's own link, and a cross-reference mark still leaving two elements on one id unwarned. Disposition put to the maintainer at the gate.

- 2026-09-05: review returned the milestone to in-progress at the maintainer's decision. What failed is not a criterion — AC1-AC6 were green with fresh evidence — but a regression the branch introduces: an `id=` inside an HTML comment counts as a carrier in the census, so a mark yields a name no element holds, the author's own link to it goes dead, and the refusal report names a carrier that is not there. With it: a cross-reference mark still leaving two elements on one id unwarned, and four sentences in `CHANGELOG.md` and `site/html.qmd` reaching past the code. T8-T11 written; the criterion ticks were removed, the fix changing the census the evidence was read against. Defect return 1. PR #79 stays open as a draft.

- 2026-09-05: T8 written. An `id=` inside an HTML comment no longer counts as a carrier: the census cuts complete comments and an unterminated `<!--` out of each raw HTML string before reading attributes. On the fixture's two new comment cases the branch previously moved `omicron` to `qi-mark-13` and `pi` to `qi-mark-14`, reporting a refusal for each, with `in-comment` and `in-raw-comment` then on 0 elements of the page and the author's own links to them dead; the AC1 leg names that state red. With the cut the render carries 7 refusal reports rather than 9, no id among the page's 56 twice, and both marks keep the names their author wrote. Task box unticked until the whole-suite run.

- 2026-09-05: T9 written, narrowed. A cross-reference mark carrying an author id is now tagged by the Span pass, so a contested name is refused, minted over and reported for it too; `anchorless` on the record keeps that id from being written back as an anchor, which would turn the cross-reference into a locator. A front-matter mark of an HTML book chapter is deliberately left out — D-048 keeps it anchorless because the filter cannot see which title-block fields Quarto prints, and a book chapter render is out of scope. The fixture gains four cross-reference marks (a `see=` against a div, a `see-also=` against raw HTML, one inside a heading whose anchor relocates, and an uncontested control); without the tag the leg reports `xref-dup`, `xref-raw` and `xref-heading` each on two elements with no report drawn, and with it the render carries 69 ids, none twice, 10 refusals and 4 cross-reference entries filing no locator.

- 2026-09-05: T11 written. The refusal report is two wordings, not one — a cross-reference mark has no locator to move with the anchor — so the pinned count in `tests/scans/warn-distinct.py` is `84 + 2 = 86`, and the task's wording was corrected from `84 + 1 = 85` to match. The scan runs clean at 86.

- 2026-09-05: supersedes the implement-gate decision of 2026-09-05 that left a cross-reference mark's author-written id untouched. Its own falsifier fired: the review's F2 showed `[cat]{#dup .index see="dog"}` beside `::: {#dup}` rendering `id="dup"` on two elements in silence. Such a mark now yields a contested id and is reported, with a wording of its own because it has no locator to move; `DESIGN.md`'s sentence that its id is untouched is corrected in place.

- 2026-09-05: T9 addendum, from the amended criterion's re-audit. A cross-reference mark sharing a name with a locator mark would have kept it on document order, moving a locator off the author's name in favour of a mark nothing links to; a locator-contributing mark now outranks a cross-reference mark whichever is written first, order deciding only between two of a kind. Fixture case `phi`/`chi` added, red without the ranking (`chi`'s locator moved to `qi-mark-16` and `phi` kept `twin-xref`), green with it.

- 2026-09-05: re-audit: AC3 (full) — returned 8 findings on the first amended wording. The guard "where that mark contributes an index locator" excluded no front-matter mark of an HTML book chapter, which files a page locator, so the wording still bound a family D-048 keeps anchorless; the mint it required of that family runs against D-048 and D-055; and that family cannot appear on AC1's render at all, a book chapter render being out of scope. T9 was narrowed to cross-reference marks in response, and the wording redrawn.

- 2026-09-05: re-audit: AC3 (full) — returned 9 findings on the redrawn wording. Two were fixed in code and are logged above (the locator-versus-cross-reference ranking; the superseded `DESIGN.md` sentence). Two changed the wording taken to the gate: the hand-derivation clause stated a property of the check rather than of the render, and the order clause no longer picked out one pair. The rest — that no criterion pins the new fixture shapes or the uncontested control — went to the gate as the criteria-set question.

- 2026-09-05: amendment gate. AC3 amended: the locator-fragment promise binds only a refused mark that files a locator, a refused cross-reference mark promises it files none, and the document-order clause is scoped to two marks that both file locators. A narrowing on the clause that stood, forced — under the old wording every refused cross-reference mark makes AC3 unsatisfiable. The gate also chose holding the criteria set rather than widening AC1 and AC4 to name the new shapes (candidate row added), and read AC1's heading sentence as being about a heading's own id, which is the reason that sentence gives.

- 2026-09-05: T10 written against the observed render. `site/html.qmd` and `CHANGELOG.md` no longer promise the id-keeping rule holds for a chapter recovered from its source (that route sees no rendered page), no longer say a yielding mark's locator always follows the mint (a cross-reference mark has none), no longer settle two marks by document order alone, and name what the report actually names — the term the mark prints or the entry written for it. Both add the comment case. The pinned claim rows go from five to seven and all seven hold.

- 2026-09-05: noted rather than amended. Scope In's sentence enumerates the fixture as carrying "both collision shapes"; it now carries a third, a cross-reference mark against a contested name, in five cases. The files and the surface Scope In names are unchanged, and the amendment gate chose to hold the criteria set rather than widen it, so the sentence stands and this line is the handle for review.

- 2026-09-05: the checkpoint commit `fe68d72` swept three beamer render artifacts (`examples/marker.nav`, `.snm`, `.toc`) into the branch — written by the suite run then in flight and uncovered by `.gitignore`. Untracked here and added to the ignore list, which is the recurrence the candidate row added 2026-09-03 names for a different file family.

- 2026-09-05: the first whole-suite run after T9 stopped at M14 — `examples/id-collision.qmd` now writes `see=`/`see-also=` targets, so the roster read out of the corpus lists it and the pinned count manifest did not. Its row is 0: all five targets name `mu`, which the fixture indexes, and a gfm render draws no dangling-target report.

- 2026-09-05: whole suite green with `--self-test` on this tree: 1412 checks across 158 sections, 1284s, exit 0, no failure. T8-T11 ticked; status to review. Two runs before it did not finish — the first stopped at the M14 manifest gap (fixed, above), the second at a `Segmentation fault: 11` in Quarto's Deno binary during M065-AC5, a render process dying rather than a check failing; that leg had passed in the first run and the crash did not recur in the third. The acceptance-criterion boxes stay unticked for review to fill against fresh evidence.

- 2026-09-05: review round 2. AC1, AC2, AC4, AC5 and AC6 green with fresh evidence on this tree (whole suite 1412 checks, exit 0; merge-base floors re-rendered), boxes ticked; AC3 not ticked — its minted-id clause is false of `tau`, whose anchor relocates out of a heading, which is the criterion being wrong rather than the work. cairn_validate clean. Three lenses returned 13 findings; R1, R2 and R4 reproduced against the implementation. R1 is a regression this branch introduces: an `.index` span carrying an author id that the Span pass never tagged no longer relocates out of a heading, so the id lands on the page twice, unwarned. Disposition put to the maintainer at the gate.

- 2026-09-05: review round 2 returned the milestone to in-progress at the maintainer's decision, with every requested change taken. What failed is not a criterion — AC1, AC2, AC4, AC5 and AC6 were green with fresh evidence — but R1, a regression this branch introduces: an `.index` span carrying an author id that the Span pass never tagged no longer relocates out of a heading, so `#ghost` on a mark with no derivable entry renders twice where the merge-base renders it once, unwarned. With it R2, the comment cut discarding a raw string's tail after any `<!--` so a real collision goes unrefused; R3, AC3's minted-id clause being false of a mark whose heading anchor relocates, which routes to a gated criterion amendment; and R4-R8 and R10 in the shipped pages and the records. T12-T19 written; the criterion ticks stay, R1 and R2 changing neither the fixture render nor the readings they were taken against. R9 absorbed into the standing candidate row on this milestone's id-uniqueness instruments. Defect return 2. PR #79 stays open as a draft.

- 2026-09-05: T12 written. The `.index` span the Span pass never tagged is relocated out of a heading again: `relocate_heading_anchors` reads a mark's own id as well as the pending tag, as it did at the merge-base. A mark whose content yields no text and carries no `entry=` is returned untouched by the Span pass and reaches that walk untagged; on a 12-line probe `#ghost` rendered twice on this branch, once at the merge-base and once with the fix. The fixture gains `untagged-in-heading` and `toc: true` — without a table of contents nothing copies the heading's inlines, so the duplicate does not appear — and the AC1 leg gains three clauses: the id counted at one, the page-wide duplicate sweep reaching it, and no id of any kind left inside a heading, read over every heading rather than over the fixture's list. Red before the fix on all three, green after; 92 ids on the page, none twice, the 11 refusal reports unchanged. Task box unticked until the whole-suite run.

- 2026-09-05: T13 written. The census no longer pattern-matches the whole raw string: `note_raw` walks the markup, reading an `id=` only where it is an attribute of a tag, stepping over comments and over the character data of a `script` or `style` element, and reading a quoted attribute value as a value — so neither a `>` nor a `<!--` inside one ends the tag or opens a comment. The fixture gains `hidden-carrier`, a real carrier standing after a neighbour whose `title=` value contains `<!--`, and `in-script`, a name written only in script text; each in a raw block of its own so neither depends on the other's block being read. Before the fix the AC1 leg reports `hidden-carrier` on two elements with no refusal drawn for `psi`, and `in-script` on none with `omega` moved to `qi-mark-17` and its author's own link dead; after it, 99 ids on the page, none twice, 12 refusals and both marks settled the way they are written. Task box unticked until the whole-suite run.

- 2026-09-05: amendment return: AC3 — "every mark whose author-written id the extension refused carries a minted `qi-mark-<n>` instead — on the mark's own span, or, where the mark is written inside a heading, on the empty span the extension emits after that heading, no anchor of any kind being left where the table of contents copies it".

- 2026-09-05: T14 written. The mini gate chose amending the clause over recording the gap or returning to plan; the amendment narrows what the clause promises rather than widening it — the old wording put the minted id on the mark itself, which the heading relocation has never done. No fresh reader was spawned: this criterion already carries its two `re-audit: AC3` lines, which is the stop, so the wording went to the maintainer instead. The AC1 leg drops the `RELOCATED` by-name exemption for a positive check — the span printing `tau` carries no id at all, the first minted anchor after its heading is on an empty span, and no id of any kind is left inside a heading. Proven red on the captured render two ways: planting `qi-mark-99` on the span inside the heading fires the first two clauses, and deleting the relocated `qi-mark-15` makes the check reach `phi` and say so.

- 2026-09-05: T15 written. `site/html.qmd` no longer promises the generated numbering steps over any name written in the source: it steps over a name an element of the rendered page carries, and may mint one that only an HTML comment or a script's or stylesheet's own text holds — which displaces nothing, there being no element to displace. Read against a probe: with `qi-mark-1`, `qi-entry-1` and `qi-index` written only inside a comment, the render carries all three as minted names. The neighbouring paragraph now says an id counts where it is an attribute of a tag and names script and style text alongside comments. The pinned claim rows go from 7 to 10 and all 10 hold.

- 2026-09-05: T16 written. D-056 supersedes the two sentences of D-055 this branch made false — that `assign_anchors` never renames an author's id, and that a colliding author id is unfenced because `tests/fragments.py` does not check a fragment resolves uniquely. What D-055 decided stands; its reason changes, and the recovery-route gap it now leaves open is named and pointed at the standing candidate row.

- 2026-09-05: T17 written. The two user-visible rules the branch had recorded only in work-log lines are now entries in this file's Decisions section: a cross-reference mark yielding a contested id and being reported in a wording of its own, and a locator-contributing mark outranking a cross-reference mark for a shared name whichever is written first.

- 2026-09-05: T18 written, and widened by what the T12 gate settled. `CHANGELOG.md` and `site/html.qmd` now name three marks outside the id-yielding rule rather than one: a chapter recovered from its own source, a book chapter's front-matter mark, and a mark this filter cannot index at all — no visible text and no `entry=` — which keeps a contested name unreported. The third was verified on a probe: a mark `[![](dot.png)]{#ghost .index}` beside `::: {#ghost}` renders `ghost` on two elements with no refusal drawn. It is recorded as KI253 and its id is still relocated out of a heading, which is the part T12 restored. The pinned claim rows go from 10 to 12 and all 12 hold.

- 2026-09-05: T19 written. The AC1 leg's derivation banner is rewritten against the dicts below it — 22 hand-derived marks in three groups, 12 that yield a contested name, 9 that keep the name their author wrote, and the one this filter never tags — where it had said seven, six and "all thirteen". `cairn/DESIGN.md`'s id account is corrected with it: the census walks the raw HTML rather than pattern-matching it, two marks rather than one stand outside the yielding rule, and an untagged mark's author id relocates out of a heading like any other anchor. The 114-character line the T9 insertion left is re-wrapped; the file's three other over-long lines predate this branch.

- 2026-09-05: whole suite green with `--self-test` on this tree: 1412 checks across 158 sections, 1387s, exit 0, no failure. T12-T19 ticked; status to review. Every acceptance-criterion box is unticked, round 2's included: T12 and T13 changed the fixture and the census, so the render round 2's evidence was read against is gone — the page carries 99 ids where it carried 74, draws 12 refusal reports where it drew 11, and `site/html.qmd` holds 12 claim rows where it held 7. Review fills all six against fresh evidence.

## Decisions

- 2026-09-05: **a cross-reference mark yields a contested id, and is reported
  in a wording of its own.** The implement gate had left such a mark's id
  untouched, on the reasoning that no generated link points at one, so refusing
  the id would break an author's own link and repair no locator. The review
  showed the cost: a cross-reference mark beside an element carrying its name
  renders that name on two elements, silently, which is the output the goal
  calls incorrect whatever the elements are for. Such a mark is now tagged by
  the Span pass, yields a contested name, and is minted over; the record stays
  anchorless, so the id it ends up with never becomes a locator. Its report is
  a second wording rather than the locator mark's — what a cross-reference mark
  loses is only whatever the author pointed at the name themselves, there being
  no locator to move. Declined: leaving the case alone and stating the
  exception in the shipped pages, which would have shipped a documented way to
  get two elements under one id. Falsified by an author who relies on a
  cross-reference mark keeping a name something else on the page carries.

- 2026-09-05: **a mark that files a locator outranks a cross-reference mark for
  a name they share, whichever is written first.** Document order settles two
  marks of a kind, and did settle every pair until cross-reference marks came
  under the refusal rule. It is the wrong rule across the two kinds: a reader
  follows a locator, so leaving the author's name on the mark nothing links to
  and moving the locator off it is the worse of the two outcomes, and it is the
  one document order gives whenever the cross-reference is written first.
  Ranking decides between kinds and order decides within a kind. Declined:
  order alone, which the fixture's `phi`/`chi` pair shows moving a locator to a
  minted anchor while a cross-reference keeps the author's name. Falsified by a
  case where the cross-reference is the element a reader wants the name on.

## Review

### Acceptance criteria — fresh evidence (2026-09-05, HEAD 600d1e7)

- AC1: green. The suite's `M079-AC1` leg over the captured render reports no id among the page's 50 carried twice, the seven contested author ids each on exactly one element, and the four uncontested ones still their marks' anchors. Merge-base floor re-measured this review by rendering this branch's fixture in a scratch checkout of `origin/main`: 50 ids, seven repeated — `shared-attr`, `shared-dq`, `shared-uq`, `shared-up`, `shared-sq`, `qi-mark-3`, `twin` — one per colliding id the fixture carries.
- AC2: green. `tests/epubcheck.py unique` over the captured publication: none of the 7 manifest-listed documents carries an id twice, and each of the 14 fragments linked from the 1 generated index section names an id its document carries exactly once. The same reading at the merge-base fails with 15 clauses across three documents (7 repeated-id, 8 link-target).
- AC3: green. Read off the captured render: alpha→`#qi-mark-5`, beta→`#qi-mark-6`, gamma→`#qi-mark-7`, delta→`#qi-mark-8`, epsilon→`#qi-mark-10`, theta→`#qi-mark-11`, lambda→`#qi-mark-12`; the leg checks each minted anchor sits on the span printing that term. kappa keeps `#twin`, written before lambda.
- AC4: green. Seven refusal reports in the render log, one per yielding mark, each naming the term and the id given up; none names kappa, mu, nu or xi, whose locators are `#twin`, `#solo`, `#in-heading` and `#qi-mark-9`.
- AC5: green. `tests/sitecheck.py claims` holds `site/html.qmd` to all five claim rows, the first of them the qualified form of the sentence that stood unqualified through M078. `CHANGELOG.md` carries an Unreleased/Output entry. (Findings F3-F5 below are about claims in these two files that reach past the observed render.)
- AC6: green. `tests/run-tests.sh --self-test`: 1412 checks across 158 sections, exit 0, no failure.

### Consistency gate

`cairn_validate.py` exit 0, all 16 checks PASS, no advisory fired. No `DESIGN.md` principle changed, so `cairn_impact.py` did not apply. The `generic` profile's consistency-gate slot names no toolchain checks.

### Independent review — three fresh-context lenses

Findings ranked, most severe first. F1, F2 and F13 were reproduced against the implementation this review, not taken on the reviewer's account.

- F1 [O] `html.lua:507-527`: an `id=` inside an HTML comment counts as a carrier. `A [term]{#notes .index} here, and a [link](#notes).` followed by `<!-- old: <p id="notes">x</p> -->` renders on this branch with the mark moved to `qi-mark-1`, the only `id="notes"` left inside the comment, and the author's own link dead; the run reports "another element of this page carries too", which is false. The same source at the merge-base keeps `notes` on the mark and the link resolves. A regression this branch introduces. — disposition: maintainer, gate
- F2 [O] `html.lua:601-627` with `passes.lua:625-630`: only a locator-contributing mark carries the pending tag, so a cross-reference or page-only mark keeps a contested id and nothing is reported. `[cat]{#dup .index see="dog"}` beside `::: {#dup}` renders `id="dup"` on two elements, silently. The implement gate chose this and logged it; the Goal sentence and the shipped claims do not carry the exception. — disposition: maintainer, gate
- F3 [S-prior] `site/html.qmd:20-23`: the bullet says the id-keeping rule holds "whether the chapter is read from its record or recovered from its source". The recovery route never sees the rendered page, so a contested name is not seen there and the locator still points at the author's id, which by then is on the element that kept it — as `html.lua:143-148` states and Scope Out excludes. — disposition: maintainer, gate
- F4 [O] `CHANGELOG.md:5-16` and `site/html.qmd:26-35`: "no longer leaves two elements of a rendered page carrying it" is false under F2; "An id nothing else on the page carries is untouched" is false under F1. AC5 binds the entry to AC1's render, which carries neither case. — disposition: maintainer, gate
- F5 [O] `html.lua:657` with `marks.lua:60-67`: the refusal report interpolates `record.context`, which prefers `entry="..."` over the printed term. Consistent with every other report in the repo, but `site/html.qmd` and `CHANGELOG.md` both promise "the term the mark prints", and the AC1 leg matches on `term "<x>"`. — disposition: maintainer, gate
- F6 [S-blame] `tests/scans/warn-distinct.py:245-256`: the comment records the count's arithmetic per milestone through `83 + 1 = 84` (M073); the branch bumps `EXPECTED` to 85 with no `84 + 1 = 85` step naming M079. The number is right; its trail is broken. — disposition: maintainer, gate
- F7 [O] `tests/epubcheck.py:235-320`: `unique`'s repeated-id clause, which is what AC2's first half rests on, has no planted-defect leg showing it can go red, where `fragments.py resolve` got two. — disposition: follow-up candidate row
- F8 [O] `tests/run-tests.sh:3937-4058`: the AC1 sweep likewise has no in-suite red-proof; its discriminating half is the merge-base measurement, taken by hand at implement and again at this review. — disposition: follow-up candidate row (with F7)
- F9 [O] `tests/epubcheck.py` via `htmlindex.index_section`: only the first index section of a document is read, so a second section's links go unresolved while the verdict still names the count it swept. Not reached by the fixture. — disposition: follow-up candidate row
- F10 [O] `tests/epubcheck.py:293-297`: an external href carrying a fragment normalizes to a path no manifest lists and reports a spurious miss. Latent — no locator is external. — disposition: follow-up candidate row
- F11 [O] `html.lua:658`: the `record and record.context or "with no source entry"` fallback fires only if the record lookup fails, which the pending tag makes unreachable, and its wording differs from `describe`'s for the same condition. — rejected: unreachable branch, no behavior to fix
- F12 [O] `keepable_author_ids`: "document order" is AST order, so a mark inside a footnote in a heading could keep a name against the one a reader sees first. Speculative, no case shown. — rejected: the implement gate's own falsifier covers it
- F13 [O] `html.lua:143-148`: where a mark yields its id, a locator recovered from that chapter's source now lands on the element that kept the name, where before it landed on the mark. Fenced by Scope Out, D-055 and the candidate row added 2026-09-05. — noted, no action; F3 is the part that is not fenced
- F14 [S-blame], F15 [S-prior]: no case found of the branch undoing a past milestone's deliberate behavior, resurrecting a fixed bug, or contradicting a recorded decision; the archived `## Review` sections on the touched files turned up nothing the diff regresses beyond F3. The GitHub inline-comment probe returned empty, so no PR-thread walk was made. — no findings

### Round 2 — acceptance criteria, fresh evidence (2026-09-05, HEAD 4030fdf)

The round-1 evidence above was read at 600d1e7, before T8-T11; everything here
is re-measured on this tree. Merge-base floors re-rendered this review in a
scratch tree holding `origin/main`'s `_extensions` and this branch's fixture.

- AC1: green. The `M079-AC1` leg over the captured render reports no id among
  the page's 74 carried twice, the 11 contested author ids each on exactly one
  element with the yielding mark on a minted anchor, and the 8 uncontested ones
  still their marks' anchors. Merge-base floor: 74 ids, 11 repeated —
  `shared-attr`, `shared-dq`, `shared-uq`, `shared-up`, `shared-sq`,
  `qi-mark-3`, `twin`, `twin-xref`, `xref-dup`, `xref-raw`, `xref-heading` —
  one per colliding id the fixture carries.
- AC2: green. `tests/epubcheck.py unique` over the captured publication: none
  of the 10 manifest-listed documents carries an id twice, and each of the 22
  fragments linked from the 1 generated index section names an id its document
  carries exactly once. The same reading at the merge-base fails with 20
  clauses across 5 documents (11 repeated-id, 9 link-target).
- AC3: NOT MET as written, and not ticked. The clause "every mark whose
  author-written id the extension refused carries a minted `qi-mark-<n>`
  instead" is false of `tau`: on the captured render the span printing `tau` is
  `<span class="index" data-see="mu">tau</span>`, carrying no id at all, and
  the minted `qi-mark-15` sits on the relocated empty span after the heading.
  The leg exempts `tau` from that clause by name (`RELOCATED = {'tau'}`), so it
  proves something weaker than the criterion. The behavior is the deliberate
  heading-anchor relocation `DESIGN.md` and `site/html.qmd` both state and
  predates this milestone, so this is the criterion being wrong rather than the
  work — the never-reinterpret rule's case. Every other clause of AC3 is green:
  alpha->`#qi-mark-5`, beta->`#qi-mark-6`, gamma->`#qi-mark-7`,
  delta->`#qi-mark-8`, epsilon->`#qi-mark-10`, theta->`#qi-mark-11`,
  lambda->`#qi-mark-12`, kappa keeps `#twin`, and the 5 cross-reference marks
  file no locator.
- AC4: green. 11 refusal reports in the render log, one per yielding mark, each
  naming the term and the id given up; none names a mark whose author id
  nothing contests. The three controls hold: `mu` keeps `solo`, `nu` keeps
  `in-heading` inside a heading, `xi` keeps `qi-mark-9`, each its locator's
  fragment.
- AC5: green. `tests/sitecheck.py claims` holds `site/html.qmd` to all 7 claim
  rows, the first the qualified form of the sentence that stood unqualified
  through M078; `CHANGELOG.md` carries an Unreleased/Output entry true of AC1's
  captured render. R4 and R7 below are about claims in these files that reach
  past OTHER renders, which is outside what this criterion binds.
- AC6: green. `tests/run-tests.sh --self-test`: 1412 checks across 158
  sections, 1343s, exit 0, no failure.

### Round 2 — consistency gate

`cairn_validate.py` exit 0, all 16 checks PASS. One advisory, not a gate
failure: `sizing (split tripwires)` on 11 tasks. No `DESIGN.md` principle
changed, so `cairn_impact.py` did not apply. The `generic` profile's
consistency-gate slot names no toolchain checks.

### Round 2 — independent review, three fresh-context lenses

Ranked, most severe first. R1, R2 and R4 were reproduced against the
implementation this review, not taken on a reviewer's account; R2's severity
is lower than the reviewer stated, whose claim that the merge-base handles the
case correctly is false (it leaves the same page duplicated).

- R1 [O] `html.lua:574`: an `.index` span carrying an author-written id that
  the Span pass never tagged is no longer relocated out of a heading, so its id
  lands on the page twice. T9 replaced `if pending == nil and not marked_id`
  with `if pending == nil`, dropping the branch that covered such spans; they
  are reachable through `passes.lua:463`, which returns the span unchanged when
  `derive_levels` yields `"keep"`. Reproduced: `## A heading with
  [![](pic.png)]{#ghost .index} in it` renders `id="ghost"` twice on this
  branch — once in the `<h2>`, once in Quarto's sidebar copy — with no warning;
  the same source at the merge-base renders it once. A regression this branch
  introduces, in the class the Goal and `DESIGN.md`'s no-anchor-in-a-heading
  rule exist to prevent. Nothing in the fixture or the suite covers a `"keep"`
  mark. — disposition: maintainer, gate
- R2 [O] `html.lua:525`: the T8 comment cut is `gsub("<!%-%-.*$", " ")`, which
  discards the rest of the raw string after any `<!--`, including one inside a
  quoted attribute value or script text. Every `id=` past it leaves the census,
  so a mark written with that name keeps a contested id, unreported.
  Reproduced: a mark `[alpha]{#dup .index}` beside raw HTML
  `<p title="looks like <!-- a comment">first</p>` and `<p id="dup">` renders
  `dup` on two elements with zero refusal reports. Not a regression — the
  merge-base leaves the same page duplicated, never having refused anything —
  but the fix silently fails to fire, and the shipped claim is unqualified.
  — disposition: maintainer, gate
- R3 [O] AC3's minted-id clause against `tau`: recorded under AC3 above. The
  criterion is wrong rather than the work, so this routes to a gated criterion
  amendment, not a code fix. — disposition: maintainer, gate
- R4 [O] `site/html.qmd:56-60`: "Both kinds of generated id skip any name
  written in the document itself — on its elements, or inside raw HTML in its
  source — so writing `qi-mark-1` yourself is safe" is false after T8 for a
  name only an HTML comment holds. Reproduced: a document whose only
  `qi-mark-1`/`qi-entry-1` are inside a comment mints both on this branch and
  steps over them at the merge-base. Harmless in effect, since the comment
  renders nothing, but the sentence contradicts the paragraph T8 added twelve
  lines above it. — disposition: maintainer, gate
- R5 [S-blame] `cairn/DECISIONS.md:414`: D-055's Consequences state that
  "`tests/fragments.py` checks that a fragment resolves and not that it
  resolves uniquely, so this rule can put a second locator on a colliding id",
  which T5 made false — `fragments.py:92` now fails a target id carried on more
  than one element, including on the recovery-route captures D-055 is about.
  Its Context sentence "`assign_anchors` never renames an author's id" is false
  for the same reason. The branch corrected that sentence where it sits in
  `html.lua:140-148` and left the decision resting on it untouched; the diff
  adds no D-entry. — disposition: maintainer, gate
- R6 [O] the milestone's `## Decisions` section is empty while the branch ships
  two new user-visible rules recorded only in work-log lines — a cross-reference
  mark yielding a contested id (superseding the implement-gate choice logged
  above it), and a locator-contributing mark outranking a cross-reference mark
  for a shared name. — disposition: maintainer, gate
- R7 [O] the front-matter mark of an HTML book chapter is stated as an
  exception in `DESIGN.md:380-382` and `passes.lua:618-623` and in neither
  shipped page; `CHANGELOG.md`'s opening sentence is unqualified across it.
  — disposition: maintainer, gate
- R8 [O] `tests/run-tests.sh:3930-3941`: the AC1 leg's derivation banner still
  says seven contested names, six uncontested and "all thirteen", where the
  dicts below it hold 11 and 8. T9 grew the fixture without the banner. The
  pass line computes from the dicts, so only the hand-derivation prose — the
  thing the ORACLE RULE makes load-bearing — is wrong. — disposition:
  maintainer, gate
- R9 [O] `tests/run-tests.sh:4098-4105` keys minted anchors by element text
  (`minted.setdefault(H.text(el).strip(), name)`), which collides for two
  minted anchors on spans rendering the same text, every relocated anchor being
  empty. Latent; the fixture's terms are distinct. — disposition: follow-up
  candidate row
- R10 [O] `cairn/DESIGN.md:382` is a 114-character line in a paragraph wrapped
  at ~78; the T9 insertion did not re-wrap the sentence it split. —
  disposition: maintainer, gate
- R11 [O] AC1's sentence "No colliding id is written on a heading" read
  literally against `xref-heading`, which the fixture writes on a mark inside a
  heading. — rejected: the amendment gate read that sentence as being about a
  heading's own id, which is the reason the sentence itself gives, and settled
  it this milestone.
- R12 [O] F7-F10 of round 1 are still true of this tree. — noted, no action:
  each already has a candidate row.
- R13 [O] F11's unreachable `record and record.context or "with no source
  entry"` fallback at `html.lua:697` persists. — rejected again: unreachable
  branch, no behavior to fix.
- [S-blame] found no other case of the branch undoing a past milestone's
  deliberate behavior; it cleared the boolean-to-count census conversion at
  every reader, the removed `marked_id` branch as superseded (which R1 shows it
  is not, wholly), D-048's front-matter exclusion, and `record.anchorless` not
  reaching the book store.
- [S-prior] no prior-review evidence bearing on this diff: the archived
  `## Review` sections on the touched files record nothing this diff regresses,
  and the GitHub inline-comment probe returned empty, so no PR-thread walk was
  made. Zero findings.

### Round 3 — acceptance criteria, fresh evidence (2026-09-05, HEAD ab8d685)

Rounds 1 and 2 were read at 600d1e7 and 4030fdf; T12 and T13 changed the census
and the fixture, so every reading below is fresh on this tree. Merge-base
floors re-rendered this review in a scratch tree holding `origin/main`'s
`_extensions` and this branch's fixture, both readings taken with a real HTML
parser rather than a pattern match.

- AC1: green. The `M079-AC1` leg over the captured render reports no id among
  the page's 99 carried twice; read independently with `html.parser`, the page
  carries 99 id attributes and 99 distinct names. The 12 contested author ids
  each stayed on the element that kept them with the yielding mark on a minted
  id, the 9 uncontested ones are still their marks' anchors, and the 5
  cross-reference marks among them file no locator. Merge-base floor: 99 id
  attributes, 87 distinct, 12 repeated — `shared-attr`, `shared-dq`,
  `shared-uq`, `shared-up`, `shared-sq`, `qi-mark-3`, `twin`, `twin-xref`,
  `xref-dup`, `xref-raw`, `xref-heading`, `hidden-carrier` — one per colliding
  id the fixture carries, and one per refusal the branch draws.
- AC2: green. `tests/epubcheck.py unique` over the captured publication: none
  of the 12 manifest-listed documents carries an id twice, and each of the 24
  fragments linked from the 1 generated index section names an id its document
  carries exactly once. The same reading of the merge-base publication, taken
  with this branch's instrument, fails with 22 clauses across 6 documents — 12
  repeated-id, 10 link-target.
- AC3: green, the clause T14 amended now holding. Read off the captured render:
  alpha->`#qi-mark-5`, beta->`#qi-mark-6`, gamma->`#qi-mark-7`,
  delta->`#qi-mark-8`, epsilon->`#qi-mark-10`, theta->`#qi-mark-11`,
  lambda->`#qi-mark-12`, rho->`#qi-mark-13`, sigma->`#qi-mark-14`,
  phi->`#qi-mark-16`, psi->`#qi-mark-17`, each on the mark's own span. tau, the
  twelfth, is written inside a heading: its own span carries no id and its
  minted `qi-mark-15` sits on the empty span the extension emits after that
  heading — the shape the amendment added. Swept over every `<h1>`-`<h6>` of
  the page, no id of any kind is left inside a heading; `in-heading` (nu) and
  `untagged-in-heading` relocate the same way. The 5 cross-reference marks file
  no locator; kappa, written before lambda, keeps `twin`.
- AC4: green. 12 refusal reports in the render log, one per yielding mark, each
  naming the term and the id given up — alpha/`shared-attr`, beta/`shared-dq`,
  gamma/`shared-uq`, delta/`shared-up`, epsilon/`shared-sq`, theta/`qi-mark-3`,
  lambda/`twin`, rho/`xref-dup`, sigma/`xref-raw`, tau/`xref-heading`,
  phi/`twin-xref`, psi/`hidden-carrier` — and no such report names any other
  mark. The three controls the criterion names hold: mu keeps `solo`, xi keeps
  `qi-mark-9`, and nu, the one inside a heading, keeps `in-heading` on its
  relocated anchor, each its locator's fragment. Recorded rather than glossed:
  nu's own span carries no id, the anchor having relocated, so "still carry the
  author's id" is read here as the mark's anchor carrying it. AC4 states no
  "on the mark's own span" clause — that clause is what made AC3 false of tau
  and forced T14's amendment — so this reading adds nothing to the criterion;
  it is named at the gate rather than settled silently.
- AC5: green. `tests/sitecheck.py claims` holds `site/html.qmd` to all 12 claim
  rows, the first of them the qualified form of the sentence that stood
  unqualified through M078; `CHANGELOG.md` carries an Unreleased/Output entry.
  Every statement in that entry about AC1's captured render is true of it.
  Findings X1, X2, X3 and X6 below are about claims in these two files that
  reach past that render — a `script`-bearing raw block, a writer-generated id,
  and a book chapter — which is outside what this criterion binds.
- AC6: green. `tests/run-tests.sh --self-test`: 1412 checks across 158
  sections, 1340s plus 2s of setup, exit 0, no failure.

### Round 3 — consistency gate

`cairn_validate.py` exit 0, all 16 checks PASS. One advisory, not a gate
failure: `sizing (split tripwires)` on 19 tasks. No `DESIGN.md` IP/GP principle
line is touched by the diff, so `cairn_impact.py` did not apply. The `generic`
profile's consistency-gate slot names no toolchain checks.

### Round 3 — independent review, three fresh-context lenses

Ranked, most severe first. X1, X4 and X5 were reproduced against the
implementation this review by driving the census walker itself under
`pandoc lua`, not taken on the reviewer's account.

- X1 [O] `html.lua:594-601`: a `script` or `style` element in a raw HTML block
  discards every `id=` after it in that block, so a real collision goes
  unrefused and the page carries the name twice, silently. After the opening
  tag the walk jumps `pos` to the `</script`, then re-parses that CLOSING tag
  as an opening one — `tag_name` reads `script` again — and the skip branch
  fires a second time, finds no further `</script`, and breaks the whole walk.
  Driving the extracted walker: `<script>var x = 1;</script>` followed by
  `<p id="dup">` claims nothing at all, where `<p id="plain">` alone claims
  `plain=1`; `<style>` is identical. A mark written `[alpha]{#dup .index}`
  therefore keeps a contested id with no report. This is the class the Goal
  exists to forbid, it is introduced by T13's rewrite, and it is invisible to
  the suite because the fixture states outright that its script case and its
  carrier case are written in raw blocks of their own. — disposition:
  maintainer, gate
- X2 [O] `html.lua:487`: the census comment asserts Quarto's later ids are
  "derived from these", which is false of names the HTML writer generates —
  `fn1`, `cb1`, `title-block-header`. A mark written with one keeps it and the
  page carries it twice. Not a regression, the merge-base doing the same, and
  the census cannot see a name that does not exist when the filter runs; what
  is new is that `CHANGELOG.md:7` now promises the duplicate is gone without
  naming this class, where `site/html.qmd:74-77` carves render-time-injected
  ids out of the numbering promise only. — disposition: maintainer, gate (the
  claim; the code half is out of scope for this milestone)
- X3 [O] `CHANGELOG.md:26-29`: "a mark there keeps the name you wrote whatever
  else carries it" is false of the recovery route. That chapter is rendered by
  this filter like any other page, so its mark does yield a contested id; what
  survives is the recovered locator, which names the author's id and lands on
  whichever element kept it. `site/html.qmd:25-27` states this correctly ("it
  links to the id you wrote"), so the two shipped pages contradict each other.
  This is round 1's F3 fixed in one file and reintroduced in the other by T18.
  — disposition: maintainer, gate
- X4 [O] `html.lua:533-539, 541-601`: two over-collection shapes, both
  reproduced. RAWTEXT elements are parsed as markup — `<textarea><p id="ta">`
  claims `ta=1`, though a browser reads that content as text — so a mark
  written `#ta` yields to a carrier no element of the page holds and the report
  is false; `<title>` and `<xmp>` are the same class. And an unterminated
  `<!--` ends the walk of its own raw string only, where in the rendered
  document it comments out everything to the next `-->` in a later block. Both
  need hand-written raw HTML, and the second leaves the page broken anyway.
  — disposition: maintainer, gate
- X5 [O] `html.lua:541-543`: `^</?%a` admits a closing tag, whose attributes
  are then read. Reproduced: `</p id="weird">` claims `weird=1`. Browsers
  discard attributes on end tags, so this over-collects, but only from invalid
  HTML and the reviewer could construct no case an author would write.
  — disposition: follow-up candidate row
- X6 [O] `cairn/DESIGN.md:382` says "Two marks are outside all of this" while
  `CHANGELOG.md:23` says "Three marks stay outside" and `site/html.qmd:19-40`
  names three. The counts reconcile — DESIGN is scoped to one page render, so
  the recovery route is not among its cases — but neither side says so, and
  making the exception set match across the shipped pages was T18's whole
  point. — disposition: maintainer, gate
- X7 [O] `tests/run-tests.sh:3937-4058`: the census's discriminating cases are
  each isolated in a raw block of their own, so no leg exercises an `id=`
  standing after a comment, a script, a style, or a quoted-value `<!--` within
  one raw string. X1 is invisible to the suite for exactly this reason. Narrower
  than the standing candidate row on this milestone's id-uniqueness
  instruments, which covers red-proofs rather than domain. — disposition:
  follow-up candidate row
- [S-blame] zero findings. The two regressions round 2 caught are fixed
  history-consistently: T12 restores the `marked_id` branch in
  `relocate_heading_anchors` that M08 established, and T13's walker is a
  superset of the regex census M17 introduced rather than a narrowing. D-056
  supersedes exactly the two D-055 sentences this branch falsified and leaves
  the rest standing; D-048's front-matter carve-out is preserved.
- [S-prior] no prior-review evidence bearing on this diff. The archived
  `## Review` sections on the touched files record nothing the diff regresses,
  and the GitHub inline-comment probe
  (`gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1`) returned
  `[]`, so no PR-thread walk was made. Zero findings.
- Prior findings still true and not re-reported: F7-F10 and R9 each already
  carry the standing candidate row on this milestone's id-uniqueness
  instruments; F11/R13's unreachable `record.context` fallback persists at
  `html.lua:775` and is rejected a third time on the same grounds.

### Round 3 — PR conversation

PR #79 carries no reviews, no conversation comments and no review threads
(`pulls/79/reviews`, `issues/79/comments` and a `reviewThreads` GraphQL query
all empty). Nothing to triage; the blocking rule does not fire.
