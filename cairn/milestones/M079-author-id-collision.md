# M079: An author-written mark id never leaves two elements sharing it

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is an author's rendered page and where its index links land
- **Branch/PR:** m079-author-id-collision

## Goal

An author-written id on an index mark never leaves two elements of one page carrying that id, so every index locator lands on the element its author marked.

## Scope

**In:** the id census and anchor assignment in the HTML back-end (`_extensions/index/modules/html.lua:485` and `:579`), which serves the HTML and EPUB routes alike; a report naming an author-written id the extension did not use as a mark's anchor; `examples/id-collision.qmd` extended with both collision shapes and the non-colliding controls; suite legs on the HTML and EPUB renders; an exactly-once assertion in `tests/fragments.py resolve`; `site/html.qmd` and `CHANGELOG.md`.

**Out:** a mark recovered from another chapter's source, whose author-written id the recovery route cannot settle against a rendered page it never sees (D-055) — that overlap is held by the candidate row added 2026-09-05 from M078's review. Renaming an id on an element that is not a mark — the extension writes only its own spans; the colliding element keeps what its author wrote. The LaTeX back-end, whose `\index` emission carries no ids. A book chapter render: each chapter is one page with one id space, and the shared code path is proven on the two format routes instead.

## Acceptance criteria

- [ ] AC1: Rendering `examples/id-collision.qmd` to HTML produces a captured page carrying no id more than once, counted by a sweep over every `id=` attribute of that page. The fixture carries both collision shapes: a mark whose author-written id names a non-mark element, written across the five id spellings the census reads (a Pandoc attribute; raw HTML double-quoted, unquoted and uppercase `ID=`; a raw inline, single-quoted) and once as a name the extension would otherwise mint; and two marks sharing one author-written id. No colliding id is written on a heading, whose id Quarto derives further copies from. The same sweep over that fixture rendered at the branch's merge-base reports a repeat for every colliding id the fixture carries.
- [ ] AC2: Rendering the same fixture to EPUB produces a publication in which no XHTML document the package manifest lists carries an id more than once, and every link inside a generated index section resolves to an id its target document carries exactly once — both read through `tests/epubindex.py`, over at least one document carrying a generated index section. The same reading at the merge-base reports a repeat.
- [ ] AC3: On AC1's captured render, every mark whose author-written id the extension refused carries a minted `qi-mark-<n>` instead, and that mark's index locator's fragment names that minted id; of the two marks sharing one author-written id, the one written first in the document is the one that keeps it.
- [ ] AC4: On AC1's render the run writes one warning per mark whose author-written id it refused, naming that id and that mark's printed term, and writes no such warning for any other mark. The same fixture's marks whose author-written ids collide with nothing — one nothing else carries, one inside a heading, and one spelled as a name the extension would otherwise mint — each still carry the author's id, with the mark's locator fragment naming it.
- [ ] AC5: `site/html.qmd` states which element keeps a contested id, what a refused mark gets instead, and that a refusal is reported; its present sentence promising a mark keeps an id of the author's own (line 20) no longer stands unqualified. `CHANGELOG.md` carries an entry whose statement of the behavior is true of AC1's captured render.
- [ ] AC6: `tests/run-tests.sh` runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T4
- AC3 → T1, T2
- AC4 → T1, T3
- AC5 → T6
- AC6 → T1, T2, T3, T4, T5

## Tasks

- [ ] T1: Extend `examples/id-collision.qmd` with both collision shapes across the axes AC1 names, plus the three non-colliding author-id marks AC4's control needs; add the suite leg sweeping the captured HTML page for a repeated id, and record it red at the merge-base before the fix lands.
- [ ] T2: Count occurrences in the id census (`taken_identifiers`, `html.lua:485`) and make `assign_anchors` (`html.lua:579`) refuse a mark's author-written id that another element carries, minting one instead; among marks sharing an id the first in document order keeps it. (RB tripwire: ip-touching)
- [ ] T3: Add the refusal report naming the refused id and the mark's printed term; add the leg asserting the whole warning set on AC1's render and the intact author ids and locators of the three non-colliding marks.
- [ ] T4: Add the EPUB leg reading the publication through `tests/epubindex.py` for a repeated id and for an index-section link whose target id is not unique, with the member count asserted non-zero.
- [ ] T5: Make `tests/fragments.py resolve` (`fragments.py:80`) assert a fragment's target id is on its page exactly once; prove it red by planting a duplicate in both collision shapes and at more than one capture site.
- [ ] T6: Correct `site/html.qmd`'s id paragraph and write the `CHANGELOG.md` entry, both against AC1's observed render.
- [ ] T7: Update `DESIGN.md`'s account of id assignment (line 364), which today states only that a minted id steps over an author's.

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

## Decisions

## Review
