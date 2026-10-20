# M121: Three anchor checks read clashing ids

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — it changes acceptance-suite checks and one test fixture, which no external consumer of the repo relies on
- **Branch/PR:** m121-clashing-id-anchor-checks

## Goal

Three acceptance-suite checks of index anchors fail on a defect that a page
with clashing element ids can hide from them today.

## Scope

**In:** The candidate row "Cover clashing ids in anchor checks", from KI274,
KI267 and KI126. The M079-AC1 leg requires exactly one minted anchor per
contested cross-reference term, but on `examples/id-collision.qmd` each such
term prints once, so a first-wins grouping passes. `tests/epubcheck.py links`
raises on the id-collision EPUB, because the fixture's author claims the
section prefix on elements with no heading, so the suite never runs it there.
`tests/indexdump.py`'s `minted_carried` passes a page that carries any id
with a minted prefix, so a locator whose own anchor is missing passes. If a
new case shows the extension itself is wrong, this milestone fixes it when
the fix fits one sitting, with a changelog entry. A larger fix stops the run.

**Out:** The named-index forms of the merged-entry reports and the book
`role` round trip, which M122 takes. The rest of the acceptance-suite
backlog stays under the candidate row "Older acceptance-suite backlog".

## Acceptance criteria

- [ ] AC1: `examples/id-collision.qmd` holds one contested cross-reference
      term that two marks outside any heading print. Each of the two marks
      writes an id that another element of the page also carries. The
      M079-AC1 leg in `tests/run-tests.sh` reads each term that
      `CONTESTED_XREF` names and `RELOCATED` does not. For each such term, it
      counts the elements that `htmlindex.minted_anchors` returns printing
      that term. It holds each count to a hand-stated number: two for the
      new term, one for each other term. It fails naming each term whose
      count differs.
- [ ] AC2: The suite runs `tests/epubcheck.py links` over the EPUB of
      `examples/id-collision.qmd` that it renders. If the generated index
      section holds no link, or every link in it leaves the publication, the
      run fails. The run also fails naming each link inside that section
      that resolves to no element of the publication. The fixture's author
      wrote five ids with the section prefix: `qi-index`, and `qi-index-1`
      to `qi-index-4`. `links` does not read the elements with those ids as
      index sections. On a copy of that EPUB whose generated index section
      has its heading removed, `links` still fails.
- [ ] AC3: For each page it dumps, `tests/indexdump.py`'s HTML dump reads
      each link inside each section that `htmlindex.index_sections` returns
      for that page, where the link's href names no file. It takes each such
      link whose fragment begins with `qi-mark-` or `qi-entry-`. If the page
      does not carry exactly one element with that id, the dump fails naming
      that link.
- [ ] AC4: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T1, T2, T3, T4

## Tasks

- [ ] T1: In `examples/id-collision.qmd`, add one new contested
      cross-reference term after the existing marks, printed by two marks
      outside any heading. Give each mark an id that another element also
      carries. Change `CONTESTED_XREF` (`tests/run-tests.sh:4332`) and the
      exactly-one read (`tests/run-tests.sh:4552-4566`) to hold the
      hand-stated count per term. Rewrite the comment at
      `tests/run-tests.sh:4546-4551` that says no case reaches a group of
      two. Update the fixture's hand-derived counts, its `DANGLING_CORPUS`
      row (`tests/run-tests.sh:15163`), and `site/gallery.yml` if needed.
      Before the first run, grep the self-tests for want strings that the
      new marks move (the M117 lesson). Add `--self-test` plants that leave
      the new term with one minted anchor and with three.
- [ ] T2: Let `tests/epubcheck.py links` take the ids an author wrote with
      the section prefix, and pass them to the section finder so it skips
      those elements. Keep the raise for any other prefixed element with no
      heading (`tests/htmlindex.py:419-427`). Run it in the suite over the
      id-collision EPUB capture (`tests/run-tests.sh:4874-4877`), reading the
      count it prints. Rewrite the comment at `tests/run-tests.sh:25528-25532`.
      Add plants: a copy with one index link's target id removed, and a copy
      with the generated section's heading removed.
- [ ] T3: In `dump_html` (`tests/indexdump.py:142-156`), check each
      same-page link with a minted-prefix fragment against
      `htmlindex.count_id`. Keep or replace `minted_carried`
      (`tests/indexdump.py:116-139`) and update its docstring and the comment
      at `tests/indexdump.py:65-68`. Add plants that remove one
      `id="qi-mark-N"` from a captured page and that write one twice.
- [ ] T4: Strike KI274, KI267 and KI126 in `cairn/DESIGN.md`. Run
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` green.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which ready work to plan — both candidate rows, as two milestones, this one first.
- 2026-10-20: question set: what to do if a new case shows the extension is wrong — fix it in the milestone if it fits one sitting, with a changelog entry; a larger fix stops the run.
- 2026-10-20: promoted the candidate row "Cover clashing ids in anchor checks" (KI274, KI267, KI126) in full.
- 2026-10-20: collision check: M079, M084, M085 and M090 shipped these checks; this plan extends them. D-068 permits the work, since each gap can let an extension defect pass. No open issue or PR on GitHub.
- 2026-10-20: checker-regress shape considered and not taken: the three checks read the extension's rendered output, not repo-internal tracking files.
- 2026-10-20: criteria audit (reduced, internal tier): fresh Opus reader returned 3 findings here. AC1 narrowed to the terms `CONTESTED_XREF` names; AC2's no-link clause matched to `cmd_links`' two conditions; AC3 narrowed to the sections `htmlindex.index_sections` returns.
- 2026-10-20: plan gate chose passing the author's prefixed ids to `links` over finding sections by heading as `unique` does, because `links` also reads books and named indexes whose headings differ, and over dropping the raise, which guards a section that lost its heading; falsified by a generated section that a hand-stated id list cannot tell from an author's element.
- 2026-10-20: lessons surfaced: M079 (cases in one unit), M117 (plants resting on old output), M118 (apply plant substitutions by script), M073 (no suite edits mid-run), M082 (run with `PATH=/usr/bin:$PATH`), M116 (fixture registration).
- 2026-10-20: implement started on branch m121-clashing-id-anchor-checks.
- 2026-10-20: T1 written: two `iota` marks appended to `examples/id-collision.qmd`, so no earlier minted number moves; `CONTESTED_XREF` maps each term to its marks' ids, and the leg counts yields per mark. A scratch render showed the extension right (both marks yield, `qi-mark-42` and `qi-mark-43`); the leg passes on it and is red on both plants and on a first-wins read. `DANGLING_CORPUS` stays 0 and the gallery does not show the fixture.
- 2026-10-20: implement choice: the verify slot runs once over T1 to T3 together, since bash reads `tests/run-tests.sh` lazily and no task can be edited while a run is in flight (the M073 lesson).
- 2026-10-20: T2 written: `htmlindex.index_sections` takes `authored` ids it skips, threaded through `epubindex` and `epubcheck.py links --authored`; `links` now prints a FAIL line where the finder raises, not a traceback. On a scratch EPUB it resolves 70 of 70 links with the five ids named, and is red on both plants (a dangling fragment, the `qi-index-5` heading removed).
- 2026-10-20: T3 written: `minted_links_land` in `tests/indexdump.py` holds each same-page index link with a minted-prefix fragment to one carrying element; `minted_carried` stays for the renamed-prefix case. Green on the last run's demo capture; red on both new plants (`qi-mark-1` gone, `qi-mark-1` carried twice).

## Decisions

## Review
