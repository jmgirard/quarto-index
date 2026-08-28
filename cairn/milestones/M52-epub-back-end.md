<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M52: EPUB gets an index back-end

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP6
- **Branch/PR:** `m052-epub-back-end` / https://github.com/jmgirard/quarto-index/pull/52

## Goal

A document or book rendered to EPUB gets a real index — the entry tree, letter
groups, cross-references and locator links the HTML back-end already builds —
instead of passing its marks through untouched.

Surface tier: **user-facing**. The deliverable is output an author's readers
read, and the docs site describes it.

## Scope

**In:** a third format predicate (`is_epub`) and a combined `builds_ast_index`
routing EPUB onto the AST index path at the four sites that build one
(`indexes.builds_index`, `passes.lua:497`, `index.lua:197`, and the predicate's
own definition in `core.lua`), with `is_html` left as the sole gate on the book
sidecar store, the fold, and the chapter-scope wording — because Quarto renders
an EPUB book as ONE Pandoc process, like PDF. An EPUB leg for the `demo` and
`book` fixtures; a `tests/epubindex.py` reader over the existing
`tests/htmlindex.py`; a `site/epub.qmd` page and the site/README edits a third
back-end forces.

**Out:**
- An EPUB leg in the version matrix → noted on the existing version-portability
  candidate row; M51 has just restored the PDF leg and it has not run a full
  schedule cycle clean.
- A `site/gallery/` entry for the EPUB fixture → the existing gallery-extension
  candidate row.
- An EPUB stylesheet — GP4 keeps the back-end a hook, not a stylesheet, exactly
  as HTML is; no change.
- revealjs, beamer, gfm and every other format: still pass-through, unchanged.

## Acceptance criteria

- [x] AC1 — `examples/demo.qmd` rendered to EPUB carries exactly one section
      with id `qi-index` across the XHTML documents its `content.opf` manifest
      lists, and the entry rows `tests/htmlindex.py` returns from that section —
      level, term text, locator count, cross-reference kind and target, in
      document order — are identical to the rows the same reader returns from
      the HTML render of the same fixture, which `tests/run-tests.sh` manifest 1e
      already pins by hand from the `.qmd` source.
- [x] AC2 — for every locator link the reader collects from that EPUB's index
      section, the href's `<file>` part names an XHTML document listed in the
      EPUB's `content.opf` manifest and that document carries an element with
      the href's `<id>`. Unresolved links: zero, over the links the reader
      collected.
- [x] AC3 — `examples/book/` rendered to EPUB carries one section per name its
      `indexes:` metadata declares (`qi-index-main`, `qi-index-people`), each
      headed with that declaration's own title; the book's `index="people"` mark
      files under `qi-index-people` and its term appears in no other index
      section; and a sweep of the render's captured warning stream finds no
      occurrence of the fold sentence `this output has one index only`.
- [x] AC4 — a `gfm` and a `revealjs` render of `examples/demo.qmd` carry no
      index section and no `qi-` identifier: a grep of each rendered file for
      `qi-` returns nothing outside any run of that string the fixture's own
      prose puts there, which the check states as a literal exclusion list
      derived from the fixture source, not from the render.
- [x] AC5 — `site/epub.qmd` exists and states both ways EPUB differs from HTML
      (one Pandoc process, so nothing folds and every declared index prints;
      locators are per-entry sequence numbers, not pages), pinned by a
      `tests/sitecheck.py` clause naming that page; and a sweep of `README.md`
      and the tracked `.qmd` files under `site/` for the string `two back-ends`
      returns nothing.
- [x] AC6 — `tests/run-tests.sh --self-test` clean (the `verify` slot's fuller
      pre-review check).

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T3, T4
- AC3 → T1, T2, T3, T5, T4
- AC4 → T1, T4
- AC5 → T6, T7
- AC6 → T1, T2, T3, T4, T5, T6, T7

## Tasks

- [x] T1 — `core.lua`: add `is_epub` (matching FORMAT `epub`, `epub2`, `epub3`)
      and `builds_ast_index` (`is_html` or `is_epub`); export both. Route
      `indexes.lua:87`, `passes.lua:497` and `index.lua:197` through
      `builds_ast_index`; leave `index.lua:133/135/166/192` and
      `indexes.lua:199` (`folded`) on `is_html`. Correct `core.lua:417`'s
      comment, which says epub passes through.
- [x] T2 — add `epub:` to `examples/demo.qmd`'s and `examples/book/_quarto.yml`'s
      formats; render both in `tests/run-tests.sh`; `.epub` is already in
      `CAPTURE_EXTS` (`run-tests.sh:171`).
- [x] T3 — `tests/epubindex.py`: open an `.epub` with `zipfile`, read
      `META-INF/container.xml` → `content.opf` → the manifest's XHTML
      documents, hand each to `htmlindex.parse`, and expose the index sections,
      entry rows and locator hrefs the checks read. Its header says where it
      reads from and what it holds, per the suite-readers doctrine; it produces
      no expected values.
- [x] T4 — the AC1–AC4 checks, each proven able to fail by a planted defect
      that varies form as well as location: T1's routing reverted (no section);
      a locator href pointed at an id no document carries (AC2); `folded`
      forced true for EPUB (AC3); a `qi-` id injected into the gfm render
      (AC4). Watch the M41/M44/M45 residue lesson on AC4 — the demo's prose
      prints filter strings as content a reader is meant to see.
- [x] T5 — the hand-derived manifest for the book's two EPUB index sections,
      from the `.qmd` sources under `run-tests.sh`'s ORACLE RULE, never from
      the rendered artifact.
- [x] T6 — docs: new `site/epub.qmd` + `site/_quarto.yml` nav; edit README,
      `site/index.qmd`, `site/output.qmd`, `site/back-end-differences.qmd`,
      `site/other-formats.qmd`; `CHANGELOG.md`; `cairn/DESIGN.md` Architecture
      (the format tests in the `core.lua` bullet, and line 366's "Every other
      format — beamer, revealjs, epub, gfm" sentence). `site/principal-mention.qmd`
      joins the swept pages: its "between the two back-ends" sentence is one of
      the six AC5 binds.
- [x] T7 — the `tests/sitecheck.py` clause for `epub.qmd`'s two claims and the
      `two back-ends` sweep, each with a planted defect showing it red.

## Work log

- 2026-08-28: created by /milestone-plan, promoting the candidate row "An EPUB index, or whatever one can be" (added 2026-08-27, user request), whose promotion condition — a reading of what an EPUB reader can do with an index and of what Pandoc's EPUB writer will carry — was met by the plan-gate probes; the row is absorbed and removed.
- 2026-08-28: criteria audit ran in FULL mode (user-facing tier) and returned one finding — a drafted AC3 clause promising "no per-chapter sidecar record is written during the render" is unobservable, the suite rendering the same fixture to HTML in the same tree; fixed at the gate by replacing it with a bounded sweep of the captured warning stream for the fold sentence. The audit ran in-session, not in a fresh-context [O] reader: this session carries a standing instruction not to spawn subagents.
- 2026-08-28: plan gate chose a distinct `builds_ast_index` predicate over widening `is_html()` to match epub because a scratch probe showed the widening engages the sidecar store on a merged single-process book, folding both declared indexes and drawing three reports that say "an HTML book aggregates its chapters through a per-chapter record", which is false of EPUB; falsified by evidence that Quarto renders an EPUB book per chapter rather than in one Pandoc process.
- 2026-08-28: plan gate chose a thin `epubindex.py` over `htmlindex.py` rather than a standalone EPUB reader because the EPUB's XHTML parses with the existing structural reader and the demo's 41 entry rows came back identical to the HTML render's; falsified by an EPUB writer change producing markup `htmlindex.py` mis-parses.
- 2026-08-28: plan gate chose a hand-derived manifest over comparing the EPUB index against the PDF book's index because the M30 and M33 lessons put engine and font differences in a PDF's text layer; falsified by an extraction shown engine-neutral, which is the existing version-portability row's own promotion condition.
- 2026-08-28: amendment — AC1's citation of `run-tests.sh` "manifest 2" named the control-token manifest (`run-tests.sh:632`); the demo's HTML index rows are pinned by manifest 1e (`DEMO_HTML_INDEX`, `run-tests.sh:439`). Corrected at the implement question gate on the maintainer's selection; the criterion's promise is unchanged. Amended wording was not read by a fresh-context [O] reader: this session carries a standing instruction not to spawn subagents.
- 2026-08-28: amendment — AC5's sweep domain narrowed from all tracked `.qmd`/`.md` files to `README.md` and the tracked `.qmd` files under `site/`, on the maintainer's selection at the same gate. As written the criterion could not pass: `two back-ends` occurs in `cairn/DESIGN.md:304` and twice in this milestone file, where AC5 itself states the string. Six reader-facing sentences still bind (README.md:37, site/index.qmd:58, site/back-end-differences.qmd:2 and :5, site/output.qmd:10, site/principal-mention.qmd:64); `DESIGN.md`'s is fixed under T6 without the criterion binding it.
- 2026-08-28: T1 — `core.lua` gains `is_epub` (matching `epub` in FORMAT, which covers `epub`, `epub2` and `epub3`) and `builds_ast_index` (`is_html` or `is_epub`), both exported; `indexes.builds_index`, `passes.lua`'s per-mark HTML record branch and `index.lua`'s AST back-end branch route through it, while the book context, the degraded-book warning, the dangling-report gate, the range-scope word and `folded` stay on `is_html`. The `is_html` comment no longer says epub passes through. `tests/run-tests.sh` green, 407 checks.
- 2026-08-28: T2/T3 — one checkpoint for both, verified by one suite run rather than two: `run-tests.sh` does `rm -rf "$WORK"` at startup and refuses concurrent invocations, so a per-task run costs a further 8.5 minutes and asserts nothing the combined one does not. `run-tests.sh` renders `examples/demo.qmd` to EPUB and to revealjs and `examples/book/` to EPUB, each captured under a slug of its own; `demo.qmd` declares no formats, so only the book's `_quarto.yml` needed an `epub:` entry, and AC4's gfm half reads the `demo-gfm` capture M03-AC6 already makes rather than rendering a second time. `tests/epubindex.py` reads the container, the package document and the manifest's XHTML members through `htmlindex.parse_text` — a new entry point `htmlindex.parse` now calls, so one builder serves both — and exposes the sections, rows, links and unresolved links. Suite green, 410 checks.
- 2026-08-28: T5/T4 — T5 written before T4, which needs its manifest: a minor reorder. Manifest 10 states the book's two EPUB index sections in locator COUNTS, not hrefs — an EPUB's link targets are the files Pandoc's writer split the book into, which is not derived from the `.qmd` sources — and it matched the artifact on the first comparison, the merged-process range pairing (`Ranged Term` one locator here, two in the HTML book) included. The AC1-AC4 checks live in a new `tests/epubcheck.py` beside the reader, so the plants can run the same clause against a broken artifact; each of the four is planted in a different form and place — routing removed from the filter, a link target removed from a rendered container, the fold predicate widened in the filter, an identifier added to a rendered file — and shown red, and the folded render is shown to write the sentence the AC3 sweep looks for. Two plant renders needed a `capture` call after them (M24-AC3), and the folded book's scratch tree needed its `_extensions` symlink removed before the spliced copy went in, or it rendered through the repository's own filter. `run-tests.sh --self-test` green, 811 checks.
- 2026-08-28: T6/T7 — `site/epub.qmd` is new and the site nav, `site/output.qmd` and `site/index.qmd` link it; `site/back-end-differences.qmd` is retitled "Where the back-ends differ" and says at the top that every "in HTML" row below is true of EPUB, with the two places EPUB parts company on the new page; `site/principal-mention.qmd` and `site/other-formats.qmd`, `README.md`, `CHANGELOG.md` and `cairn/DESIGN.md` (the `core.lua` bullet's format tests, a third back-end bullet, and the pass-through sentence, which no longer names epub) follow. `tests/sitecheck.py` gains two modes — `claims`, holding a named page to a hand-written list, and `phrase-absent`, sweeping the tracked `site/` pages plus README for a forbidden phrase over the same enumerated domain and stated floor the retired-sentence sweep uses — each planted and shown red, with a passing overlay control for the sweep. `run-tests.sh --self-test` green, 820 checks.
- 2026-08-28: T6 fallout — retitling the back-end page broke the M40 heading-move self-test, whose pre-move README fixture carries `### Where the two back-ends differ` and which requires every moved heading to be carried under `site/`. The fixture is a record of what that README said, so it is not edited; `sitecheck.py` gains a `RENAMED_HEADINGS` map instead (see this file's Decisions), and the check's own ok line now says how many it treats as renamed.
- 2026-08-28: review opened — branch pushed, draft PR #52 opened, `cairn_validate` clean (16 PASS, 7 advisories OK, `release window` did not fire). At the maintainer's selection the three-lens fresh-context fan-out was authorised for this phase, lifting for review the standing no-subagent instruction the plan and implement phases logged.

## Decisions

### A heading renamed after the documentation move is recorded, not backfilled (2026-08-28)

`tests/sitecheck.py`'s `headings` mode states a migration invariant: every
`##`/`###` heading the pre-move README carried is gone from README and is
carried by a heading under `site/`. Its pre-move README is a fixture inside
`run-tests.sh`, and it names `### Where the two back-ends differ` — a page
title this milestone had to change, EPUB making the count wrong and AC5
forbidding the phrase on any page a reader meets.

Editing the fixture would make it a record of a README that never existed, and
the invariant is about loss, which a rename is not. So the module carries a
`RENAMED_HEADINGS` map instead — one entry, from the old heading text to the
text now carried — and looks for the replacement where the map has one. The
fixture keeps saying what the old README said; the map says what became of it.


### The fold sentence is held to the filter's wording in the run, not by a source scan (2026-08-28)

AC3 sweeps the book's EPUB warning stream for `this output has one index only`,
the sentence all three fold reports share. It cannot be a `mark-report-keys`
grep key: that scan holds a key to matching exactly one filter warning, and
matching all three is what makes a sweep for this sentence a sweep for "did
anything fold at all". A scan of its own under `tests/scans/` would be the
M16-doctrinal home, and would also owe `movedefs.py` and `plantdefect.py` an
entry apiece for a single sentence. It is pinned inline instead, through the
same `filtersrc` source set the scans read, by requiring the sentence to occur
in the filter source exactly three times — where the three fold reports write
it. Beside it the run sweeps the same log for the three fold reports' own
pinned keys at zero occurrences each, so a reworded sentence fails at the pin
rather than leaving the sweep looking for text nothing writes.

## Review

Evidence is fresh, gathered 2026-08-28 on branch `m052-epub-back-end` at
`c4ace1a` from one `tests/run-tests.sh --self-test` run (820 checks, exit 0)
and from commands run beside it. Summaries only; the run's own output is not
pasted here.

### Acceptance criteria

- **AC1 — met.** `examples/demo.qmd` renders to EPUB at exit 0.
  `tests/epubcheck.py sections` finds exactly one generated index section
  across the manifest-listed XHTML documents — `qi-index`, titled `Index`, in
  `EPUB/text/ch005.xhtml` — and its 54 entry and letter rows match the
  manifest. `tests/epubcheck.py same` then finds those 54 rows identical to
  the rows the same reader returns from the HTML render of the fixture, and
  both identical to manifest 1e (`DEMO_HTML_INDEX`), which is hand-derived
  from the `.qmd` source. Planted red: the AST routing reverted in the filter,
  so the EPUB carries no section.

- **AC2 — met.** `tests/epubcheck.py links` collected 25 locator links inside
  the demo EPUB's generated index section; all 25 resolve — each names one
  of the 3 manifest-listed documents and an element that document carries.
  Unresolved: zero. Planted red: one link target removed from a rendered
  container.

- **AC3 — met.** `examples/book/` renders to EPUB at exit 0 and carries two
  generated sections, one per declared name, each under its declaration's own
  title: `qi-index-main` (Index of Subjects) in `EPUB/text/ch005.xhtml` and
  `qi-index-people` (Index of People) in `EPUB/text/ch006.xhtml`. Their 25 rows
  match manifest 10, which is exhaustive per section and derived by hand from
  the `.qmd` sources — so `Turing`, the book's `index="people"` term, appearing
  in the main section would fail as an extra row. The sweep of the render's
  captured warning stream (29 lines) found no occurrence of `this output has
  one index only`. Planted red: the fold predicate widened for EPUB — and the
  folded render is separately shown to write the sentence the sweep looks for,
  so the sweep is not looking for text nothing writes.

- **AC4 — met.** The exclusion list is derived from `examples/demo.qmd`, which
  writes no run of `qi-` of its own, so the list is empty and every occurrence
  in a render would be the filter's. The revealjs render
  (`demo-revealjs/demo.html`) and the gfm render (`demo-gfm/demo.md`) each
  carry no occurrence of `qi-` outside those 0 strings. The swept token is
  taken off the pinned section id rather than written down, and the run refuses
  an empty token. Planted red: a `qi-` identifier injected into a rendered
  pass-through file.

- **AC5 — met as written.** `site/epub.qmd` exists (44 lines) and
  `tests/sitecheck.py claims` holds it to 4 hand-written claims, all present,
  including both differences the criterion names: a book is one Pandoc process
  so nothing folds and every declared index prints, and locators are per-entry
  sequence numbers rather than pages. `tests/sitecheck.py phrase-absent` swept
  22 files — every tracked `.qmd` under `site/` plus `README.md`, enumerated by
  `git ls-files` against a stated floor — and found no occurrence of `two
  back-ends`; the same sweep run by hand at review returns nothing. Both
  clauses planted red (a claim removed from the page; an overlay page carrying
  the phrase), each with its vacuous-list guard planted too, and the sweep has
  a passing overlay control. Finding F1 below reports that the sweep is
  case-sensitive and two reader-facing sentences still read `Two back-ends
  ship`; that is a defect in the docs, not a failure of this criterion as
  written.

- **AC6 — met.** `tests/run-tests.sh --self-test` ran to completion at exit 0,
  820 checks, all passed. Run fresh at review on this branch head.

### Consistency gate

- `cairn_validate.py` — exit 0. 16 PASS, 7 advisories OK; `release window` did
  not fire.
- `cairn_impact.py --changed` — skipped: this milestone changed no `DESIGN.md`
  IP/GP principle. The `DESIGN.md` edits are Architecture prose only.
- Toolchain checks — the `generic` profile's `consistency-gate` slot names
  none, so this half is a clean no-op. The `verify` slot's command is AC6.
- Default-branch sync — `git fetch` then compare: branch 0 behind
  `origin/main`, `main` 0 ahead of `origin/main`; no merge needed.

### Independent review

Three fresh-context reviewers, distinct evidence bases, none having seen the
implementation. The standing no-subagent instruction was lifted for this phase
at the maintainer's selection (work log above).

- **[S] blame-history** — zero findings. Cleared five candidates, each traced
  to this milestone's own recorded scope or `## Decisions`: the deliberate
  `is_html`/`builds_ast_index` split, the `RENAMED_HEADINGS` map against M40's
  invariant, the behavior-preserving `htmlindex.parse` refactor, the reworded
  `is_html` comment, and the book's `epub:` format entry.
- **[S] prior-review record** — one finding (F14). Read the archived review
  records and `LESSONS.md`; ran no GitHub probe, reporting that this repo's
  findings record lives in the archive rather than in PR threads. Ruled out one
  candidate itself: the new readers catch `OSError` and not `UnicodeDecodeError`,
  which is parity with the sibling sweep's deliberately unfixed baseline (D-029),
  not a regression.
- **[O] diff-bug** — thirteen findings (F1-F13). Found no functional defect in
  the filter routing; verified the three AST sites are reached and the five
  `is_html` sites are not.

### Findings

Ranked as reported, most severe first. Each verified at review against the
implementation, not against the reporter's account of it. Dispositions are
proposals put to the maintainer at the gate; the gate's decision is recorded
below it.
- **F1 — `README.md:5` and `site/index.qmd:9` still read "Two back-ends ship:
  LaTeX/PDF and HTML", and AC5's sweep is case-sensitive so it cannot see
  them.** Confirmed: the same `git ls-files` sweep with `-i` returns both
  lines; without it, nothing. These are the first paragraph of the repository
  front page and of the documentation landing page, and they name EPUB
  nowhere. The milestone's own T6 header is "the docs describe a third
  back-end". Proposed disposition at the gate: **fix before merge.**
- **F2 — `site/books.qmd` states the HTML per-chapter model as what "a Quarto
  book" gets, which this branch makes false for an EPUB book.** Confirmed: the
  page qualifies the PDF book explicitly ("The PDF book needs none of this")
  and has no such qualification for EPUB, so "Put that chapter last", "Render
  the whole book when you publish" and "Each chapter records its marks in
  `.quarto/quarto-index/`" all read as applying to an EPUB book, where none of
  them is true. `site/epub.qmd` sends the reader to this page for the
  aggregation. T6 did not list `books.qmd`. Proposed disposition at the gate: **fix before
  merge.**
- **F3 — AC2's `<file>`-part arm is not shown to run over a non-empty
  domain.** Confirmed in `tests/epubindex.py:203`
  (`name = link['file'] or link['document']`): a bare same-file fragment falls
  back to its own document, which is in the manifest by construction, so the
  manifest-membership arm is vacuous for such a link and the plant exercises
  the id arm only. Measured at review: all 25 demo links carry a non-empty
  file part today, so the arm is exercised now — nothing asserts it stays so.
  Proposed disposition at the gate: **file** (the repo's silently-emptying-domain doctrine).
- **F4 — the book EPUB's locator links are never resolution-checked, though
  `site/epub.qmd` and `CHANGELOG.md` both claim they resolve inside the
  book.** Confirmed: `run-tests.sh:17115` runs `epubcheck.py links` on the
  demo capture only; the book capture is read for sections and never for
  links. `examples/book/sub/` is a subdirectory chapter, the case where a
  relative href could differ. Measured by hand at review: the book EPUB's 14
  links all carry file parts and all resolve, so the shipped claim is true —
  it is the check that is missing. Proposed disposition at the gate: **fix before merge** (one
  added invocation).
- **F5 — `site/placing-the-index.qmd:15` and `site/sorting.qmd:85` say "both
  back-ends".** Confirmed. Each sentence is true of EPUB as well, so the
  content is right and the count is wrong. Proposed disposition at the gate: **fix before
  merge.**
- **F6 — `indexes.builds_index`'s new EPUB arm is unreachable in production,
  and `DESIGN.md:369` and the Scope section describe it as a site an EPUB
  render builds an index at.** Confirmed: `builds_index()` is called only at
  `indexes.lua:279` and `:323`, both under `if folded and ...`, and `folded`
  requires `is_html()`. The routing is harmless and defensive; the prose
  overstates. Proposed disposition at the gate: **file.**
- **F7 — `epubcheck.cmd_same`'s third comparison cannot fail.** Confirmed at
  `tests/epubcheck.py:138`: `epub_rows` and `html_rows` have both already been
  compared equal to `expected`. AC1's headline clause is carried by the two
  manifest comparisons; the call that names it adds no discrimination. Over-
  determined, not under-determined. Proposed disposition at the gate: **file.**
- **F8 — `sitecheck.py`'s `phrase-absent` duplicates the inline M44 sweep line
  for line rather than the M44 sweep being routed through the new module.**
  Confirmed. Two copies of one domain definition, each printing an `ok` line
  naming "every tracked page under site/ plus README.md". Proposed disposition at the gate:
  **file.**
- **F9 — `epubindex.section_rows` is reached by no check, and its docstring
  claims a form manifest 10 does not use.** Confirmed: it delegates to
  `htmlindex.section_rows`, which appends a trailing field manifest 10 omits;
  `epubcheck.py` uses its own 4-field rows. Proposed disposition at the gate: **file.**
- **F10 — `cmd_absent`'s two allowed-string guards have never executed**, both
  living inside `for text in allowed` and every call site passing an empty
  list. Confirmed. Proposed disposition at the gate: **file.**
- **F11 — `RENAMED_HEADINGS` is an unverified assertion that no page was
  lost.** Confirmed at `tests/sitecheck.py:374`: `want` is substituted
  unconditionally, nothing checks the old heading is genuinely absent or that
  the new one is on the same page, and no self-test plants a map entry over a
  heading that was actually deleted. Proposed disposition at the gate: **file.**
- **F12 — `epubindex.read` raises rather than reporting on a member it cannot
  decode or address** (`tests/epubindex.py:112`), which the suite's own plant
  helper treats as a disqualifying outcome elsewhere. Confirmed by reading.
  Proposed disposition at the gate: **file.**
- **F13 — `epubindex.links` would report an external href as unresolved**,
  joining it onto the document's directory. Confirmed by reading; not reachable
  today. Proposed disposition at the gate: **file.**
- **F14 — `tests/sitecheck.py`'s `flatten` omits the blockquote-marker strip
  its sibling has, regressing a lesson M41 taught and M45 extended.**
  Confirmed: `tests/run-tests.sh:1497` strips `^[ \t]*>[ \t]?` per line before
  flattening and says so in its ok line and in a comment block giving the
  reason; `tests/sitecheck.py:474` is `' '.join(text.split())` with no strip,
  doing the same job over the same domain. Latent: no page in the swept domain
  carries a blockquote line today (measured at review). No plant covers the
  shape. Proposed disposition at the gate: **fix before merge.**

