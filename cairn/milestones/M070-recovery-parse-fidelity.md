<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M070: A recovered chapter is read as the file it is, and everywhere its own render reads it

- **Status:** in-progress
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

- An extension test in `recover_record` (`book.lua:783`) before
  `pandoc.read(text, "markdown")`: a chapter source whose extension is not one
  of the markdown ones Quarto books take is not parsed at all, and its chapter
  is reported rather than refiled. KI219 records what happens today — a
  one-cell `.ipynb` chapter's raw JSON is accepted, its span's `index`
  attribute arrives seven characters long with the JSON escaping inside it,
  `mark_index` matches no declared index of that name, and the term is filed
  into the book's first index with nothing said, because recovery resolves the
  name before `fold_undeclared` would draw the refiling report.
- The report for such a chapter: a wording naming the file and saying its
  source was not read, beside the wordings `book.lua:887-891` and M069 draw.
- `recovered_marks` (`book.lua:693`) reaches a mark a chapter writes in its
  YAML front matter, which the ordinary render already indexes: probed
  2026-09-02 under pandoc 3.11, a filter table carrying a `Span` function
  visits a span in `abstract:` exactly as it visits one in the body, and visits
  it before the body, while the recovery walk is over `parsed.blocks` alone.
  Front matter is read through the same conditional-content drop the blocks go
  through, so a mark inside `.content-visible` or `.content-hidden` is left out
  there as it is in the body. `recovered_markers` (`book.lua:762`) is not
  widened with it: `resolve_markers` reads `doc.blocks` alone, so a marker in
  front matter places nothing in the ordinary render either, and reading one
  here would be the recovery route departing from the render.
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

- [ ] AC1. A book chapter whose source file's extension is not one the recovery
      parse accepts, and whose record is neither opened-and-usable nor read for
      any other reason, has none of its terms in any index section of the
      rendered book, and its reading chapter draws a report naming that
      chapter's file and saying its source was not read — asserted
      message-whole, on both entry paths: a record that is unopenable and
      listed, and a record no render has written.
- [x] AC2. The extensions the parse accepts are `.qmd`, `.md`, `.markdown` and
      `.Rmd`; a fixture carrying one recovered chapter per accepted extension
      has each of those chapters' terms in the book's index, held row by row in
      href form against a hand-derived manifest.
- [x] AC3. A mark written in a chapter's YAML front matter reaches the book's
      index by the recovery route under the same printed entry and in the same
      declared index as it reaches it when that chapter's record is read, its
      locator a link to that chapter's page with no fragment; the record-route
      half is asserted on its own render of the same fixture as the control.
- [x] AC4. `site/books.qmd` and `CHANGELOG.md` each state which chapter source
      files the recovery route reads and which it refuses, and that a recovered
      chapter's front-matter marks reach the index with its body's.
- [ ] AC5. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

## Coverage

- AC1 → T1, T2, T4, T8, T9
- AC2 → T1, T4
- AC3 → T3, T5, T7, T10
- AC4 → T6, T11
- AC5 → T4, T5, T6, T7, T8, T9, T10, T11

## Tasks

- [x] T1. The extension test in `recover_record` (`book.lua:783`), before the
      read: the accepted set as a named table, the comparison on the chapter
      path's own extension lowercased, and a refusal the caller can tell from
      a failed read. A name carrying no extension is refused with the rest.
- [x] T2. The refusal wording beside `book.lua:887-891` and M069's, drawn once
      per reading chapter; `tests/scans/warn-distinct.py`'s EXPECTED moves with
      it.
- [x] T3. `recovered_marks` over the chapter's metadata as well as its blocks,
      with `drop_conditional` applied to both, and document order settled —
      metadata before blocks, the order the ordinary render uses — so a
      front-matter mark's declared sort key beats a body mark's exactly where
      the ordinary render lets it. `recovered_markers` stays over the blocks
      alone, matching `resolve_markers`.
- [x] T4. The AC1/AC2 fixture: a copy of `examples/book` gaining a one-cell
      `.ipynb` chapter that marks a term, and one chapter per accepted
      extension; the refusal asserted message-whole on both entry paths, and
      the accepted chapters' terms held against the href-form manifest.
- [x] T5. The AC3 fixture and its control: a chapter marking a term in
      `abstract:` and nowhere else, rendered once with its record readable and
      once with it recovered, the two asserted to file the same entry in the
      same index; the record route's locators carry fragments and the recovered
      one does not, and it carries more of them, because Quarto copies the
      abstract into the chapter's body before this filter runs.
- [x] T6. `--self-test` plants over each axis, each shown red against the check
      that fences it, and then `site/books.qmd`, `CHANGELOG.md` and
      `cairn/DESIGN.md`.
- [ ] T7. The conditional-content removal over the front matter as well as the
      blocks, a fixture chapter marking inside a conditional span and a
      conditional block there, and a plant reading the front matter raw.
- [ ] T8. The refusal asserted to name the chapter's file, beside the count, on
      both entry paths — the precedent `M60-AC4` and `M064-AC5` set.
- [ ] T9. The refusal wording asserting nothing about a record, since it is
      drawn where none was written; and its departure from the silence rule —
      a refused chapter reports on every path — named in `DESIGN.md`.
- [ ] T10. The walk order fenced rather than asserted in a comment: a chapter
      whose front matter and body declare rival sort keys for one term, and a
      plant turning the two walks round.
- [ ] T11. `DESIGN.md`'s recovery-contract paragraph; the dead nil guard; the
      retired known-issue citations in the filter and the suite; KI232 widened
      to the reflection that causes it; the notebook fixture's cell id.

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

## Decisions

## Review

_Reviewed 2026-09-02 against PR #70. **Outcome: returned to `in-progress`** — two
findings meet the return floor. AC2, AC3 and AC4 are verified below; AC1 and AC5
are not._

### Acceptance criteria

- **AC1 — not verified (F2).** The behavior is right on both entry paths: the
  cold leg and the dangling leg each draw the refusal exactly once and file none
  of `five.ipynb`'s terms (`plain.log:717-723`, 18 manifest rows in href form,
  in order, on both). But the criterion also asks that the report *name that
  chapter's file*, asserted message-whole, and no check asserts that half:
  `WARN_STORE_KIND_REFUSED` is the six-word substring `is not one this route
  reads`, carrying no `%s`, and no M070 check greps the refusal line for
  `five.ipynb`. The suite's own precedent pairs the two — `M60-AC4`
  (`tests/run-tests.sh:6794`) and `M064-AC5` (`:7544`) each add
  `grep -qF <chapter>` beside the count. Dropping `:format(file)` from the new
  message passes every M070 check today.
- **AC2 — verified.** One chapter per accepted extension (`.qmd`, `.md`,
  `.markdown`, `.Rmd`), each recovered and its term in the book's index, held
  row by row in href form against the hand-derived manifest: `plain.log:718`,
  "2 generated index section(s) and all 18 manifest rows match, in order".
- **AC3 — verified.** `six.qmd`'s front-matter mark files `Hasp` under H in
  `qi-index-main` by both routes over the same fixture — recovered
  (`plain.log:718`, locator `six.html`, no fragment) and read from the chapter's
  own record as the control (`plain.log:724`, locators
  `six.html#qi-mark-1..3`). Same printed entry, same declared index; the routes
  differ in the locator's fragment and, as KI232 records, in locator count.
- **AC4 — verified by reading both pages.** `site/books.qmd:93-99` states the
  accepted set and the refusal; `:104-107` states that a front-matter mark comes
  back with the body's. `CHANGELOG.md:29-43` states both in its unreleased
  section.
- **AC5 — not verified.** `tests/run-tests.sh` plain exits 0, 640 checks
  (up from 631 on the default branch). The `--self-test` half was **not run this
  review**: the fix for F1 and F2 changes both the filter and the suite, so that
  evidence would be stale before it was recorded.

### Consistency gate

`cairn_validate.py` exit 0 — 16 PASS, 7 advisories clean, `coverage complete`
and `binding criteria` among them. No `DESIGN.md` principle text changed, so
`cairn_impact` is skipped. The `generic` profile names no toolchain checks, so
the universal cairn-file checks are the whole gate. PR #70's CI is green
(`compare`, `render (floor, 1.4.549)`, `render (pinned, 1.10.18)`).

### Independent review

User-facing tier, executable diff → the full three-lens fan-out, all
fresh-context. **[S] blame-history: no defects** — the extension gate and the
metadata walk are additive, `recovered_markers` staying blocks-only matches
KI11, and D-041/042/043/044/045 are untouched. **[S] prior-review record: zero
findings** — the GitHub inline-comment probe returned empty, so that surface was
skipped by its own gate; against the archived `## Review` sections of M06, M062,
M063, M064, M065 and M069 nothing in the diff reintroduces or contradicts a
recorded finding. **[O] diff-bug: 12 findings**, below.

### Findings and dispositions

Two meet the return floor and carry the milestone back; the rest are logged with
their disposition. F1, F2, F5 were verified independently before triage.

- **F1 — fix now (floor: load-bearing defect).** A mark inside `.content-hidden`
  or `.content-visible` written in YAML front matter is now recovered and
  indexed. `recovered_marks` walks `parsed.meta` raw while blocks go through
  `drop_conditional`, and the code comment justifying that ("front matter
  carries no block of that kind") is false. Verified 2026-09-02 under pandoc
  3.11: a `::: {.content-hidden when-format="html"}` div and a
  `[Gamma]{.content-hidden .index}` span written in `abstract:` both survive
  into the metadata and are both visited by the walk. This falsifies the third
  of `site/books.qmd`'s "Five things recovery does not return" — a *pinned*
  claim, which `sitecheck.py claims` passes because it checks the sentence is
  present, not that it is true — as well as `DESIGN.md:491-494` and the tail of
  the report wordings themselves. It also breaks this milestone's own Goal: the
  ordinary render never sees such a mark, because Quarto settles conditional
  content before the extension runs, so recovery now indexes a term the
  chapter's own render would not.
- **F2 — fix now (floor: AC1 unevidenced).** See AC1 above.
- **F3 — fix now.** The refusal opens `the recorded index marks for %s could not
  be used` and is drawn on the cold path too, where no render ever wrote one.
  That is the inaccuracy M069's fourth wording exists to avoid, named in the
  comment eight lines above the new branch and in `DESIGN.md:496-497`. The
  one-wording-for-every-record-state choice was deliberate; the phrasing
  asserting a record existed is a defect inside it.
- **F4 — fix now (name it or narrow it).** A notebook chapter that marks nothing
  used to fall through to the deliberately silent branch and now reports. It
  fires only where that chapter's record is missing or unusable, not on every
  render as the finding states — a full book render writes the notebook's record
  like any other — but it still contradicts the silence rule at
  `DESIGN.md:498-500`, and the branch names the change nowhere.
- **F5 — fix now.** `DESIGN.md`'s recovery contract paragraph still says "Four
  wordings carry the outcome" (there are five), still gives an unreadable source
  as the only refusal-shaped case with no mention of the accepted extension set,
  and does not say a front-matter mark is recovered. Scope In names `DESIGN.md`
  a deliverable; AC4 binds only the other two pages, so nothing fenced it.
- **F6 — follow-up (reads-repair candidate row).** A refused chapter whose record
  is version-skewed never reaches the `stale` list, so the different-version
  wording is never drawn for it; and the refusal is drawn once per *reading*
  chapter where the stale family is drawn once per *building* chapter. No
  fixture pairs a refused chapter with a stale record.
- **F7 — fix now.** The meta-then-blocks walk order is load-bearing
  (`register_recovered_sort` is first-wins) and asserted only in a comment. T6
  reasons about a *doubled* walk being unfenceable but not a *reordered* one,
  and no fixture has a front-matter mark and a body mark competing for one sort
  key.
- **F8 — fix now (trivial, same region as F1).** `readable_source`'s `ext ~= nil`
  guard is dead: `pandoc.path.split_extension` returns `""`, never nil, for a
  name with no extension (verified 2026-09-02). The refusal comes from the table
  lookup missing.
- **F9 — fix now.** `book.lua:803` and `tests/run-tests.sh:23457,23689` cite
  KI219, which this branch deleted from `DESIGN.md`.
- **F10 — fix now, via the gated criterion/scope amendment.** Scope In and T3
  both say `recovered_markers` reaches front matter; it deliberately does not,
  and Scope Out says so — the reversal is in the work log but the plan-owned
  text was never amended. T3 also states the claim F1 falsifies, and T5 says the
  two routes "differ only in the locator's fragment" where they also differ in
  locator count.
- **F11 — fix now (cheap).** KI232 is written about `abstract:` specifically,
  but the tripling mechanism applies to any metadata field Quarto reflects into
  the chapter body.
- **F12 — fix now (cheap).** `examples/book-extensions/five.ipynb` declares
  `nbformat_minor: 5` but its cell carries no `id`, which 4.5 requires. It
  renders today; a stricter nbformat would take the M070 legs down as an
  environment failure rather than a check failure.

Defect returns for this milestone: 1. No thrash trigger.
