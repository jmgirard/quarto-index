# M079: An author-written mark id never leaves two elements sharing it

- **Status:** in-progress
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

- [x] T1: Extend `examples/id-collision.qmd` with both collision shapes across the axes AC1 names, plus the three non-colliding author-id marks AC4's control needs; add the suite leg sweeping the captured HTML page for a repeated id, and record it red at the merge-base before the fix lands.
- [x] T2: Count occurrences in the id census (`taken_identifiers`, `html.lua:485`) and make `assign_anchors` (`html.lua:579`) refuse a mark's author-written id that another element carries, minting one instead; among marks sharing an id the first in document order keeps it. (RB tripwire: ip-touching)
- [x] T3: Add the refusal report naming the refused id and the mark's printed term; add the leg asserting the whole warning set on AC1's render and the intact author ids and locators of the three non-colliding marks.
- [x] T4: Add the EPUB leg reading the publication through `tests/epubindex.py` for a repeated id and for an index-section link whose target id is not unique, with the member count asserted non-zero.
- [x] T5: Make `tests/fragments.py resolve` (`fragments.py:80`) assert a fragment's target id is on its page exactly once; prove it red by planting a duplicate in both collision shapes and at more than one capture site.
- [x] T6: Correct `site/html.qmd`'s id paragraph and write the `CHANGELOG.md` entry, both against AC1's observed render.
- [x] T7: Update `DESIGN.md`'s account of id assignment (line 364), which today states only that a minted id steps over an author's.

- [ ] T8: Stop an `id=` written inside an HTML comment from counting as a carrier in the id census, so a mark keeps a name no element of the rendered page holds and no refusal is reported for one; add the fixture case and the suite leg, recorded red before the fix.
- [ ] T9: Settle the cross-reference and page-only mark case, which carries no pending tag and so keeps a contested id unwarned: either bring such marks under the refusal rule or state the exception where an author reads it; add the fixture case either way.
- [ ] T10: Narrow the claims in `CHANGELOG.md` and `site/html.qmd` to what the code does — the recovery route reads a chapter without its rendered page, the cross-reference exception, and the report naming a mark's `entry=` where it carries one rather than the term it prints.
- [ ] T11: Add the `84 + 1 = 85` step naming M079 to the warning-count comment in `tests/scans/warn-distinct.py`, which stops at M073's `83 + 1 = 84`.

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

## Decisions

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
