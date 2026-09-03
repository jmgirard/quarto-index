<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M070: A recovered chapter is read as the file it is, and everywhere its own render reads it

- **Status:** review
- **Priority:** normal
- **Depends on:** M069
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Branch/PR:** m070-recovery-parse-fidelity / https://github.com/jmgirard/quarto-index/pull/70

## Goal

The recovery parse is given only a chapter source Pandoc's markdown reader is
the right reader for, and reads a mark wherever that chapter's own render reads
one, so a recovered chapter's terms are neither silently refiled into the wrong
index nor silently left out of every index.

## Scope

Surface tier: **user-facing** — the deliverable is which of an author's terms
reach the book index and what the render tells them when some cannot.

**In:**

- An extension test in `recover_record` before `pandoc.read(text, "markdown")`:
  a chapter source whose extension is not one of the markdown ones Quarto books
  take is not parsed at all, and its chapter is reported rather than refiled.
  KI219 records what happens today — a one-cell `.ipynb` chapter's raw JSON is
  accepted, the span's `index` attribute arrives with the JSON's own escaping
  inside it, no declared index answers to that name, and the term is filed into
  the book's first index with nothing said.
- The report for such a chapter: a wording naming the file and saying its
  source was not read, beside the four wordings already there.
- `recovered_marks` reaches a mark a chapter writes in its YAML front matter,
  which the ordinary render already indexes: probed 2026-09-02 under pandoc
  3.11, a filter table carrying a `Span` function visits a span in `abstract:`
  as it visits one in the body, and visits it first. Front matter goes through
  the same conditional-content drop the blocks do, so a mark carrying or inside
  `.content-visible` or `.content-hidden` is left out there as in the body.
  `recovered_markers` is not widened with it: `resolve_markers` reads
  `doc.blocks` alone, so a marker in front matter places nothing in the
  ordinary render either, and reading one here would be a departure from it.
- Acceptance-suite fixtures for both edges, and `--self-test` plants over each
  axis they are free in.
- `site/books.qmd`, `CHANGELOG.md` and `cairn/DESIGN.md` with KI219 retired and
  KI11 corrected where recovery bears on it.

**Out:**

- Narrowing the ordinary render so that a front-matter mark is not indexed at
  all. The plan gate chose to make recovery match the render rather than the
  render match recovery; the alternative and its falsifier are in the work log.
- A chapter whose front matter carries a placement marker rather than a mark.
  KI11 records it as filter residue of its own class; nothing here changes it.
- Refiling a recovered mark whose index name the book does not declare, which
  is silent for a reason of its own (KI218). Stays the reads-repair candidate
  row.
- Minting a fragment for a recovered locator. Stays the recovery-follow-ups
  candidate row.

## Acceptance criteria

- [x] AC1. A book chapter whose source file's extension is not one the recovery
      parse accepts, and whose record is neither opened-and-usable nor read for
      any other reason, has none of its terms in any index section of the
      rendered book, and its reading chapter draws a report naming that
      chapter's file and saying its source was not read — asserted
      message-whole, on both entry paths: a record that is unopenable and
      listed, and a record no render has written.
- [x] AC2. The extensions the parse accepts are `.qmd`, `.md`, `.markdown` and
      `.Rmd`; a fixture carrying one recovered chapter per accepted extension
      whose only mark is in that chapter's body has each of those chapters'
      terms in the book's index, held row by row in href form against a
      hand-derived manifest.
- [x] AC3. A mark written in the YAML front matter of a chapter whose source
      file's extension is one the recovery parse accepts, written in the file on
      disk, naming an index the book declares, and neither carrying nor inside a
      block or span carrying `.content-visible` or `.content-hidden`, that
      reaches the book's index when that chapter's record is read, reaches it
      under the same printed entry and in that same index when no record of that
      chapter has been written and it is recovered from its source instead; and
      the recovered mark's locator, where it contributes one, is a link to that
      chapter's page with no fragment.
- [x] AC4. `site/books.qmd` and `CHANGELOG.md` each state which chapter source
      files the recovery route reads and which it refuses, and that a recovered
      chapter's front-matter marks reach the index with its body's.
- [x] AC5. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

## Coverage

- AC1 → T1, T2, T4, T8, T9
- AC2 → T1, T4, T16
- AC3 → T3, T5, T7, T10, T12, T16
- AC4 → T6, T11, T13
- AC5 → T4-T16

## Tasks

- [x] T1. The extension test in `recover_record` before the read: the accepted
      set named, the comparison lower-cased, a refusal the caller tells from a
      failed read, and a name carrying no extension refused with the rest.
- [x] T2. The refusal wording beside the four already there, once per reading
      chapter; `tests/scans/warn-distinct.py`'s EXPECTED moves with it.
- [x] T3. `recovered_marks` over the chapter's metadata as well as its blocks,
      the conditional drop over both, metadata first — the render's own order,
      so a front-matter sort key beats a body one where the render lets it.
      `recovered_markers` stays over the blocks, matching `resolve_markers`.
- [x] T4. The AC1/AC2 fixture: `examples/book` copied, gaining a one-cell
      `.ipynb` chapter and one chapter per accepted extension; the refusal
      asserted message-whole on both entry paths and the accepted chapters'
      terms held against the href-form manifest.
- [x] T5. The AC3 fixture and its control: a chapter marking only in
      `abstract:`, rendered once from its own record and once recovered, both
      filing the same entry in the same index.
- [x] T6. `--self-test` plants over each axis, each shown red against the check
      that fences it; then `site/books.qmd`, `CHANGELOG.md`, `cairn/DESIGN.md`.
- [x] T7. The conditional-content removal over the front matter too, a fixture
      chapter marking inside a conditional span and block there, and a plant
      reading the front matter raw.
- [x] T8. The refusal asserted to name the chapter's file beside the count, on
      both entry paths — the precedent `M60-AC4` and `M064-AC5` set.
- [x] T9. The refusal asserting nothing about a record, and its departure from
      the silence rule named in `DESIGN.md`.
- [x] T10. The walk order fenced rather than commented: a chapter whose front
      matter and body declare rival sort keys, and a plant turning the walks
      round.
- [x] T11. `DESIGN.md`'s recovery-contract paragraph; the dead nil guard; the
      retired known-issue citations; KI232 widened; the fixture's cell id.
- [x] T12. The front-matter conditional-drop plant's label: an ordinary render
      does index its two marks, so the label states the decision instead.
- [x] T13. The refused-chapter claim on `site/books.qmd` and in `CHANGELOG.md`,
      narrowed to the states the refusal branch is reached in, its pinned claim
      rows moving with it.
- [x] T14. The refusal's check key made unique to its own wording, and the
      copied-fixture store assertion made one that can fail.
- [x] T15. The durable records: a D-entry for each of this milestone's two
      narrowings of the recovery decision; KI218 corrected and KI220's citation
      repaired; KI233 and KI234 added; the follow-up candidate row.
- [x] T16. AC3's probe axes in one chapter: a non-`.qmd` extension, a field
      other than `abstract:`, an entry from the attribute rather than the
      visible words, and the book's second index; manifests, counts and plants
      moving with it, and a `.content-visible` mark beside the hidden pair.

## Work log

- 2026-09-02: created by /milestone-plan.
- 2026-09-02: plan gate chose to make recovery reach a front-matter mark over narrowing the ordinary render so neither reaches one, because the render's behavior is what a single-document author already gets and changing it would drop terms from documents that are not books at all; falsified by an author reporting a term in their front matter reaching the index as a defect rather than as what they asked for.
- 2026-09-02: plan gate chose an extension whitelist over sniffing the file's content, because Quarto names the chapter files and the set it accepts is small and enumerable, where a content sniff would be a second reader guessing at a format Quarto already knows; falsified by a Quarto release taking a book chapter whose extension is outside the set and whose source Pandoc's markdown reader reads correctly.
- 2026-09-02: criteria audit ran in FULL mode ([O], fresh context) and returned findings on all three drafted criteria — AC1 unbounded over "not markdown" with no enumerable set and its antecedent covering only one of two entry paths, AC2 unsatisfiable as written because a recovered locator carries no fragment by decision and its record-route baseline was unpinned, AC3 wholly instrument-bound and its single plant standing in for a family. All fixed before this file was written.
- 2026-09-02: T1 — `recover_record` refuses a chapter whose extension is not `.qmd`, `.md`, `.markdown` or `.Rmd` (lower-cased comparison over `pandoc.path.split_extension`), before anything is opened; a chapter whose name carries no extension is refused with the rest. The refusal returns a second value rather than the file, the plan's own shape: the caller already holds the file and names it itself. `tests/run-tests.sh` passed, 631 checks.
- 2026-09-02: T2 — one refusal wording for every state a refused chapter's record can be in, drawn in `store_read` ahead of the four wordings already there; a refused chapter is not handed on as a stale record, so it says one thing rather than two. The implementation gate chose the longer wording naming the accepted set and chose one sentence over two. `warn-distinct.py`'s EXPECTED moved 82 to 83, and the suite gained the `WARN_STORE_KIND_REFUSED` key. `tests/run-tests.sh` passed, 631 checks.
- 2026-09-02: T3 — `recovered_marks` takes the chapter's metadata and its blocks and walks them in that order, which is the order the ordinary render sees them in; `Meta` carries no `walk`, so the metadata walk is `pandoc.Pandoc({}, meta):walk`. Document order is stated by the two walks rather than read off Pandoc's traversal.
- 2026-09-02: T3 — `recovered_markers` is left over the blocks alone rather than widened to the metadata as the task's wording read: `resolve_markers` reads `doc.blocks` alone (KI11), so a marker in front matter places nothing in the ordinary render, and Scope Out already holds that chapter out of this milestone. Reading one here would be the recovery route departing from the render, which is the thing the goal forbids. `tests/run-tests.sh` passed, 631 checks.
- 2026-09-02: T4 and T5 landed together in one commit: both criteria are asserted over the one new fixture `examples/book-extensions` and one suite run, and splitting them would have been two runs over the same tree. The implementation gate chose a committed example book over a fixture the test script assembles.
- 2026-09-02: T4/T5 — three legs over that fixture: a cold store, a store holding a listed record that cannot be opened (planted for one.qmd and for five.ipynb, so the accepted chapter and the refused one are told apart by what is said about each), and a store holding six.qmd's own record as AC3's control. Suite 631 checks to 640.
- 2026-09-02: T5 found that a Quarto BOOK chapter's own render files a front-matter mark three times: probed 2026-09-02 under quarto 1.10.18, a filter placed immediately before this extension counted the mark once in the document's metadata and twice more in its blocks, Quarto having already copied the abstract into the chapter's body. The same fixture rendered through the filter as it stands on the default branch writes a record holding the same three marks, so it is not this branch's doing; the recovery route reads the source, where the mark is written once, and files it once. AC3 binds the entry and the index, which agree. Recorded as a known issue at T6.
- 2026-09-02: T6 checkpoint, not yet ticked — the five plants, `site/books.qmd`, `CHANGELOG.md`, KI219 retired and KI11 corrected in place, all written; `tests/run-tests.sh --self-test` was still running when this was committed, so nothing here is verified yet.
- 2026-09-02: T6 — the plan's fifth plant, the metadata walk applied twice, is not planted: a second locator onto a page a first already names is dropped where the entry is built, so no check downstream can tell one walk from two. Its place is taken by a plant removing the signal that tells a refused chapter from one whose source could not be read, which moves the wording and no printed page.
- 2026-09-02: T6 checkpoint 2 — the self-test found two things the first pass broke and neither was silent: T3's reindentation of `recovered_marks` left three M065/M066 plants anchored on the old column, which `spliced_copy` refused rather than passing; and rewriting a bullet in `site/books.qmd` dropped one of the 27 sentences that page is held to. Plants re-anchored; the pinned sentence restored verbatim and the new material given its own paragraph, with three claims pinned beside it (27 to 30). Re-running `--self-test`.
- 2026-09-02: T6 checkpoint 3 — the three claims pinned on `site/books.qmd` moved its count from 27 to 30, and the M063-AC6 self-test asserts the claim check's failure message names that count; expectation moved with it. An earlier run of the same suite died at M05 on a Quarto segmentation fault, an environment failure rather than a check, and was rerun.
- 2026-09-02: T6 — five plants, each shown red against the check that fences it: the extension test removed (the notebook chapter's term filed into the index its author did not name), the test inverted, one member taken out of the accepted set, the metadata walk removed, and the refusal's own signal removed so a refused chapter is reported as a source that could not be read. `site/books.qmd`, `CHANGELOG.md`, KI219 retired, KI11 corrected in place, KI232 added. `tests/run-tests.sh --self-test` passed, 1201 checks; the plain run before it passed at 640. A second Quarto segmentation fault, this time at M55, ended one run before it; the rerun was clean and both were in the long self-test mode while every plain run was clean.
- 2026-09-02: review step 2 — draft PR #70 opened against main (branch 9 ahead of origin/main, 0 behind, so no merge was needed); its three CI checks are green. Step 4's universal cairn-file checks passed; no DESIGN.md principle text changed, so `cairn_impact` is skipped, and the `generic` profile names no toolchain checks.
- 2026-09-02: review returned M070 to in-progress on two findings meeting the return floor. AC1 fails its own "asserted message-whole" clause: no check asserts the refusal names the chapter's file, and the suite's own precedent (M60-AC4, M064-AC5) does exactly that. And recovery now indexes a mark written inside `.content-hidden`/`.content-visible` in YAML front matter, because the new metadata walk bypasses `drop_conditional` — verified under pandoc 3.11 — which falsifies a pinned `site/books.qmd` claim, `DESIGN.md:491-494`, and the milestone's own Goal. AC2, AC3 and AC4 verified; AC5's plain half passed at 640 checks and its `--self-test` half was not run, the fix changing both the filter and the suite. Ten further findings logged in the Review section. First defect return for this milestone.
- 2026-09-02: probe run 2026-09-02 under pandoc 3.11 — a filter table carrying a `Span` function visits a span in `abstract:` as well as one in the body, confirming the asymmetry AC3 rests on before this milestone was written rather than leaving it for implementation.
- 2026-09-02: return round 1, implementation gate — both recommendations taken: the scope text is narrowed to promise only the front-matter MARK (the marker half stays out, matching `resolve_markers`), and the refusal's opening clause changes from "the recorded index marks for %s could not be used" to "no record of the index marks for %s could be used", which is true on the never-written path too. Amended text shown verbatim at the gate.
- 2026-09-02: amendment (substantive, gated) — Scope In's third bullet, T3 and T5 rewritten to say what was built: `recovered_marks` alone reaches front matter, the conditional-content drop reaches it, metadata is read before blocks, and the two routes differ in locator count as well as in the fragment. No acceptance criterion's wording changed. Tasks T7-T11 added for the return's findings, Coverage extended, and the Tasks section compressed in one pass to hold the 150-line cap (`cairn_validate` weight caps PASS).
- 2026-09-02: T7/T10 (checkpoint, not yet ticked) — `drop_conditional`'s filter is now a named table and a chapter's parsed metadata goes through it via `conditional_free_meta` before the mark walk; probed 2026-09-02 under pandoc 3.11, a `.content-hidden` span and a `.content-hidden` div written in `abstract:` are both removed by that walk and both survive without it. Fixture chapter `seven.qmd` added, carrying rival declared sort keys for one term across its front matter and body and two marks inside conditional classes in its front matter; two plants added, each rendered by hand and shown to move the printed index — the front matter read raw indexes `Jetsam` and `Kestrel`, the two walks turned round moves `Ingot` from the A group to a Z group.
- 2026-09-02: T8/T9 (checkpoint, not yet ticked) — `m070_refusal_names` greps the refusal line for the chapter's file beside the count, on both entry paths, the pairing `M60-AC4` and `M064-AC5` make. The refusal wording no longer asserts a record existed, and its departure from the silence rule is named beside the branch and in `DESIGN.md`: a refused source was never read, so nothing knows whether it marks a term, and guessing silence would cost its author every term of that chapter.
- 2026-09-02: T11 (checkpoint, not yet ticked) — `DESIGN.md`'s recovery-contract paragraph now states the accepted extension set, the metadata read and its order, the conditional drop over front matter, the fifth wording and the refused chapter's exemption from the silence rule; `readable_source`'s dead nil guard removed after verifying `pandoc.path.split_extension` returns `""` and never nil (2026-09-02, pandoc 3.11); the retired KI219 citations in the filter and the suite replaced; KI232 widened from `abstract:` to the metadata reflection that causes it; `five.ipynb`'s cell given the id its declared `nbformat_minor: 5` requires. The suite was still running when this was committed, so nothing here is verified yet.
- 2026-09-02: return round 1, first run — `tests/run-tests.sh` passed at 642 checks (640 on the returned branch) and `--self-test` at 1207 (1201), both exit 0, every M070 leg and all seven plants green, the two new plants among them. Three check labels still said "five chapters" where the fixture now has six; corrected, and both suites re-run over the corrected tree because a label is prose a reviewer reads. No task ticked until that pair lands.
- 2026-09-02: return round 1 complete, T7-T11 ticked — `tests/run-tests.sh` passed at 642 checks and `tests/run-tests.sh --self-test` at 1207, both exit 0 over the corrected tree, 25 M070 checks among them and all seven plants shown red against the check that fences each. Status back to `review`.
- 2026-09-02: review round 2 returned M070 to in-progress on two counts. Amendment return: AC3 — "A mark written in a chapter's YAML front matter, other than one inside a block or span carrying `.content-visible` or `.content-hidden`, reaches the book's index by the recovery route under the same printed entry and in the same declared index as it reaches it when that chapter's record is read" — the criterion as written quantifies over every front-matter mark, and this branch's own `seven.qmd` carries one it is false of: rendered by hand 2026-09-02 under quarto 1.10.18, that chapter's own record holds its `.content-hidden` `Jetsam` three times and the following render prints it, while recovery files it nowhere; the code is right (the ordinary render indexes a body `.content-hidden` span too, so recovery has diverged there since D-042 by decision) and the promise is what is wrong.
- 2026-09-02: review round 2, defect return — `site/books.qmd:98-100` (a pinned claim) and `CHANGELOG.md:33-34` say a refused chapter is reported "whatever state its record was in, and none of its terms reach any index", but the refusal branch sits inside `if unusable or never_written` (`book.lua:944,975`), so a notebook chapter whose record is present and usable is read from that record and its terms do reach the index — the ordinary whole-book case. AC1, AC2, AC4 and AC5 verified this round at 642 checks plain and 1207 with `--self-test`, both exit 0; AC3 unticked. Eight further findings logged in the Review section with their dispositions. Second defect return for this milestone; first amendment return.

## Decisions

## Review

_Reviewed 2026-09-02 against PR #70, round 3. **Outcome: all five acceptance
criteria verified.** Ten findings from the independent review, six taken
fix-now and applied on the branch before this evidence was gathered; none met
the return floor._

### Acceptance criteria

- **AC1 — verified.** Both entry paths draw the refusal exactly once, each
  naming the chapter's file, and none of `five.ipynb`'s terms are in either
  index section: `plain.log:717-727`. The cold leg and the listed-unopenable
  leg each match all 25 manifest rows in href form, in order (`:718`, `:724`);
  `m070_refusal_names` greps the refusal line for `five.ipynb` on both (`:719`,
  `:725`); the three could-not-be-read wordings are asserted absent (0 each);
  and the reading chapter's total warning count is pinned at 9 on each leg. The
  message-whole half is that key — now the unique substring `source is not one
  this route reads` — plus those zero-counts plus `warn-distinct`.
- **AC2 — verified.** One chapter per accepted extension (`.qmd`, `.md`,
  `.markdown`, `.Rmd`), each recovered and its body mark in the book's index,
  held row by row in href form against the hand-derived manifest:
  `plain.log:718`, "2 generated index section(s) and all 25 manifest rows
  match, in order". The `nomarkdown` plant takes `.markdown` out of the
  accepted set and that chapter's row is the one that leaves the manifest
  (`self.log:1290-1291`), so the set is fenced member by member and not only
  at its edges.
- **AC3 — verified.** Over `six.qmd` and `eight.Rmd`, whose only marks are in
  their front matter: each files the same printed entry in the same declared
  index by both routes — recovered (`plain.log:718`, locators `six.html`,
  `eight.html`, no fragment) and read from that chapter's own record as the
  control (`:726`, `six.html#qi-mark-1..3`, `eight.html#qi-mark-1..5`). The
  four axes AC3 is free in all move at once in `eight.Rmd`: a non-`.qmd`
  extension, `description:` beside `abstract:`, an entry taken from the
  attribute rather than the visible words, and the book's second declared
  index. The criterion's carve-out is fenced from the other side by
  `seven.qmd`, whose three conditional front-matter marks reach no index, and
  by the `rawmeta` plant, which puts all three back (`self.log:1296-1297`).
  The locator clause holds: every recovered row carries the chapter's page and
  nothing after it.
- **AC4 — verified by reading both pages.** `site/books.qmd:93-102` states the
  accepted set and the refusal, and scopes the refusal to the states its branch
  is reached in; `:105-115` states that a front-matter mark comes back with the
  body's, and now says where the two routes stop agreeing (R3-F4).
  `CHANGELOG.md:29-46` states both in its unreleased section.
- **AC5 — verified.** `tests/run-tests.sh` passed at 642 checks and
  `tests/run-tests.sh --self-test` at 1207, both exit 0, over this branch's
  head with the round-3 fix-now work applied. 25 M070 checks among them, and
  all seven plants shown red against the check that fences each
  (`self.log:1286-1299`).

### Consistency gate

`cairn_validate.py` exit 0 — 16 PASS, one advisory (`sizing`: 16 tasks against
the 10 tripwire, from two return rounds). No `DESIGN.md` principle text
changed — the diff's only IP2 mentions are Known-issues prose — so
`cairn_impact` is skipped. The `generic` profile names no toolchain checks, so
the universal cairn-file checks are the whole gate. PR #70's CI is green
(`compare`, `plan`, `build`, `render (floor, 1.4.549)`,
`render (pinned, 1.10.18)`).

### Independent review

User-facing tier, executable diff → the full three-lens fan-out, all
fresh-context, none having seen the implementation. **[S] blame-history: no
defects** — it traced every modified and removed line to the commit that wrote
it and found the new `refused` branch additive with all five prior store
outcomes intact, `recovered_markers` deliberately unwidened per D-047/KI11, and
the only deletions in the suite a mechanical reindent of two splice patterns.
**[S] prior-review record: zero findings** — the GitHub inline-comment probe
returned empty, so that surface was skipped by its own gate; against the
archived `## Review` sections and this milestone's own rounds 1-2, every fixed
finding is durably applied and none is reintroduced. **[O] diff-bug: 10
findings**, below.

### Findings and dispositions

R3-F1, R3-F2, R3-F4 and R3-F7 were verified independently before triage, by
reading the run's own captures and logs and by reading the implementation.

- **R3-F1 — fix now.** `KI232` and `KI233` both understated the front-matter
  locator defect, and KI233 named the wrong discriminator. KI233 attributed the
  dangling fragments to "a chapter metadata field Quarto does not reflect into
  the page body". Verified against this branch's own AC3 capture that a
  REFLECTED field does it too: `six.qmd` marks `Hasp` once in `abstract:`,
  `tests/.work/cap/m070-record/_book/six.html` carries `id="qi-mark-1"` alone,
  and the printed index links `six.html#qi-mark-1`, `#qi-mark-2` and
  `#qi-mark-3` — two of the three dead. `eight.html` carries `qi-mark-1..2`
  against five linked. The defect is the render's and pre-existing on the
  default branch, so it is not this diff's to fix; the records this milestone
  wrote about it are. Both known issues corrected and the follow-up candidate
  row's wording moved with them.
- **R3-F2 — fix now.** The fixture's `.Rmd` chapters make Quarto select the
  knitr engine, so the one leg that RENDERS such a chapter shells out to R
  (`m070-record-second.log` opens `processing file: eight.Rmd` /
  `output file: eight.knit.md`). The suite preflights makeindex, pdflatex,
  pdftotext, pdfinfo, shasum, kpsewhich and PyYAML and refuses to skip any of
  them; R was the one hard dependency with no guard, and its absence would have
  surfaced ~20 minutes in as `m070_render`'s failure message, which hard-coded
  the refusal framing for all four of its call sites — three of which render a
  chapter this route reads. Preflight added; the message unpinned from the
  refusal.
- **R3-F4 — fix now.** `site/books.qmd` said this route "reads a chapter's
  front matter as well as its body and the two agree". They agree on the entry
  and the index and not on the locator count — the record route files a
  reflected front-matter mark three times and this route once. Narrowed to say
  both halves. The pinned claim substring stops at "comes back with the marks
  in its body", so no claim row moved and the count stands at 31.
- **R3-F5 — fix now (trivial).** `recover_record`'s comment claimed "every step
  is inside one guard … (IP2)", which the file-kind test ahead of the `pcall`
  falsifies. The test touches no file — it reads the path string — which is why
  it is ahead of the guard; the comment now says so rather than overclaiming.
- **R3-F6 — fix now (trivial).** The conditional-content removal reaches
  `recovered_marks`'s two inputs at different levels: the blocks cleaned by the
  caller, the metadata cleaned inside. No live defect, but a second caller
  would inherit half the removal silently, and only the metadata half is
  planted. Stated at the boundary.
- **R3-F3 — reject (not a defect).** "AC3 is unticked while the milestone is at
  `review`." That is what AC fencing prescribes: a criterion box is ticked by
  review against recorded evidence, never by the implementer. It is ticked in
  this round, above.
- **R3-F7 — reject (refuted).** "Identical check counts across round 2 could be
  output copied forward." Re-derived from scratch this round: the plain suite
  reports 642 and `--self-test` 1207, the two numbers the round-2 work log
  claims. Round 2's new material is guards and a third render, which `fail`
  without incrementing.
- **R3-F8 — fix now (the fixture header) / reject (the rest).** The fixture's
  own header said "Nine chapters, eight of them read by the recovery route",
  counting `index.qmd`, which does the reading and supplies its own marks;
  every leg recovers seven. Corrected. Rejected with it: `site/books.qmd:86`'s
  generic "that chapter's own `.qmd`", which is an unmodified pinned line the
  diff did not introduce; the Coverage map's `AC2 → T16`, which is right
  because T16 moved AC2's manifest rows; and six lines running 80-82 columns,
  which is the formatter class a prior round already rejected.

Defect returns for this milestone: 2. Amendment returns: 1. No thrash trigger,
and none added this round — no finding demonstrated an acceptance criterion
failing, and the one user-facing defect among them (R3-F1's dead locator
fragments) is the ordinary render's, pre-existing on the default branch and
outside this milestone's scope, so what this diff owed was an accurate record
of it and that is what was corrected.
- 2026-09-02: return round 2, implementation gate — both recommendations taken: AC3 narrows to carve out a front-matter mark carrying or inside `.content-visible`/`.content-hidden` rather than widening recovery to index one against D-042, and the refused-chapter claim on `site/books.qmd` and in `CHANGELOG.md` is narrowed to the states the refusal branch is reached in rather than moving the refusal ahead of the record check.
- 2026-09-02: criteria audit over the amended AC3 ran in FULL mode ([O], fresh context, having authored none of it) and returned seven findings — the carve-out missing the mark span that carries the class itself, no antecedent scoping the promise to a chapter actually recovered, the promise reaching chapters the route refuses outright and so contradicting AC1, D-041's include/executed-cell boundary unnamed, an instrument-binding trailing clause about the fixture and its control, "its locator" ambiguous over the two routes, and one exemplar standing in for the four axes the domain is free in. Six fixed at the gate; the seventh became this round's question and the probes were taken.
- 2026-09-02: the wording fixed at that gate re-entered the questions once with its own fresh [O] reader, FULL mode, which returned six more — a locator promised for a cross-reference mark that contributes none, a mark neither route can index, an undeclared index name Scope Out holds out, the recovery entry path unnamed, AC2 falsified by the fixture's own conditional chapter, and `.content-visible` never planted in front matter. Further churn went to the user, who took the narrowed AC3 and the AC2 narrowing.
- 2026-09-02: amendment return: AC3 — "A mark written in the YAML front matter of a chapter whose source file's extension is one the recovery parse accepts, written in the file on disk, naming an index the book declares, and neither carrying nor inside a block or span carrying `.content-visible` or `.content-hidden`, that reaches the book's index when that chapter's record is read, reaches it under the same printed entry and in that same index when no record of that chapter has been written and it is recovered from its source instead; and the recovered mark's locator, where it contributes one, is a link to that chapter's page with no fragment"
- 2026-09-02: amendment (substantive, gated) — AC2 narrowed to the chapters it was written about, gaining "whose only mark is in that chapter's body"; the fixture's own `seven.qmd` falsifies it as it stood. No criterion was widened or added: both amendments narrow. Tasks T12-T16 added for the round's findings, Coverage extended, and the Tasks section and then Scope In each compressed in one pass to hold the 150-line cap (`cairn_validate` weight caps PASS).
- 2026-09-02: `ROADMAP.md` reached its 60-line cap when the round's follow-up row was added, so the chapter-filename row and the Windows-symlink row were clustered into one paths-and-filenames row rather than either being dropped.
- 2026-09-02: T12-T16 — the front-matter conditional-drop plant's label now states the decision (Quarto settles a span-level conditional after this extension's pass, so the chapter's own render does index those marks and recovery drops them by D-042) instead of crediting the render with settling them first; the refused-chapter claim narrowed on `site/books.qmd` and in `CHANGELOG.md`, its pinned rows moving with it, 30 claims to 31; `WARN_STORE_KIND_REFUSED` lengthened to `source is not one this route reads`, which matches one wording in the filter where the old six words matched three; and the copied-fixture store assertion moved off the path `rm -rf` had just removed to a `find` over the whole copy, shown red by hand against a store planted outside `.quarto` and shown blind in the old form.
- 2026-09-02: T16 — `examples/book-extensions` gains `eight.Rmd`, which moves all four axes AC3 is free in at once: a non-`.qmd` extension, a mark in `description:` as well as `abstract:`, an entry taken from the attribute rather than the visible words, and the book's second declared index. Its three terms are held in both manifests, the record-route half rendered from `eight.Rmd`'s own record beside `six.qmd`'s. `seven.qmd` gains a `.content-visible` front-matter mark so the conditional drop is not fenced on one of its two classes. Warning counts moved with the ninth chapter: 6 to 7 never-written on the cold leg, 5 to 6 on the dangling leg, 8 to 9 total on each, and 6 to 7 refusals under the inverted plant.
- 2026-09-02: return round 2 complete, T12-T16 ticked — `tests/run-tests.sh` passed at 642 checks and `tests/run-tests.sh --self-test` at 1207, both exit 0, 25 M070 checks among them and all seven plants shown red against the check that fences each. Status back to `review`.
- 2026-09-02: review round 3 (checkpoint, nothing verified yet) — the three fresh-context lenses ran: [S] blame-history and [S] prior-review returned no defects, [O] diff-bug returned 10 findings. None demonstrates an acceptance criterion failing and none is a defect in what the extension does for an author, so the return floor is not met and no return is made. Six taken fix-now and applied here before any evidence was recorded: KI232/KI233 corrected after verifying by hand against this branch's own AC3 capture that a REFLECTED field's extra locators are dead too (`six.html` carries `id="qi-mark-1"` alone while the index prints `#qi-mark-1`, `#qi-mark-2` and `#qi-mark-3`), which falsifies KI233's "a field Quarto does not reflect" discriminator, the follow-up candidate row moving with it; `site/books.qmd`'s unqualified "the two agree" narrowed to the entry and the index, saying the locator counts differ (the pinned substring stops short of that clause, so no claim row moved); an `Rscript` preflight for the `.Rmd` chapters, whose own render Quarto runs through knitr, and `m070_render`'s failure message unpinned from the refusal framing it hard-coded for all four call sites; `recover_record`'s IP2 comment narrowed to the steps that touch the file; the split conditional drop stated at its boundary; and the fixture header's chapter count corrected from eight to seven. Both suites re-running over the edited tree; no acceptance criterion is ticked until that pair lands.
- 2026-09-02: review round 3 complete — all five acceptance criteria verified against `tests/run-tests.sh` at 642 checks and `--self-test` at 1207, both exit 0 over the tree carrying the round's six fix-now edits; AC3 ticked, the last box. Ten findings from the three lenses, six fixed here and four rejected with reasons, all logged in the Review section. None met the return floor: no finding demonstrated an acceptance criterion failing, and the one user-facing defect among them is the ordinary render's dead front-matter locator fragments, pre-existing on the default branch, which this milestone owed an accurate record of rather than a fix. Defect returns stay at 2, amendment returns at 1.
- 2026-09-02: step-7 approval: PR #70 approved for merge.
