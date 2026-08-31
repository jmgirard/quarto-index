<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M064: A chapter's terms reach the book index when its record cannot be read

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m064-book-source-recovery`

## Goal

In an HTML book, a chapter whose sidecar record the building chapter opened but
could not use contributes its authored terms and its placement markers to the
book's index anyway, recovered by parsing that chapter's own source.

## Scope

Surface tier: **user-facing** — the deliverable is the index a reader of an
authored book reads.

**In:**

- A recovery reader in `_extensions/index/modules/book.lua`, firing only where
  `store_read` OPENED a record and could not use it — undecodable, structurally
  refused, or version-skewed. A record file that is simply absent keeps today's
  behavior, so a first render stays the one `site/books.qmd` documents.
- What it recovers, by reading `<project>/<chapter>` and `pandoc.read`-ing it,
  then walking the parse with the extension's own mark reader: each mark's
  index name and printed levels, and whether the chapter carries a placement
  marker and for which indexes. These are the author's own values; a chapter's
  own conclusions — anchor, resolved role, pairing verdict — are not recovered
  and are not invented (the M21 lesson, D-009).
- A recovered mark's locator links to the chapter's page — the `output-file:`
  its own front matter declares, otherwise its source stem plus the output
  extension — and carries no fragment.
- Recovered markers join `placing`, so `first` is settled from the book's
  chapters rather than only from the records that could be read (KI214).
- A superseding D-entry reversing D-040's declined clause for this use.
- `cairn/DESIGN.md`'s Architecture book paragraph, `site/books.qmd`, the
  changelog; KI205 and KI214 struck or narrowed.

**Out:**

- A fragment for a recovered mark → stays a known issue; recovering one needs
  the anchor minting another chapter's process ran, and a computed fragment
  that misses links to nowhere in silence.
- Cross-chapter range pairing and mention roles → D-009 and D-021 stand; a
  recovered mark indexes as though `range=` and `role=` were absent.
- Fencing the richer mark forms a recovered chapter may carry (`entry=`,
  `sort=`, `see=`, `see-also=`), the other two ways a record goes unusable, the
  store reports' post-recovery counts, and the degradation an include-borne or
  render-dropped mark gets → M065, planned now, depends on this.
- Recovery on an absent record, which would complete a book's FIRST index →
  candidate row; it falsifies `site/books.qmd`'s render-twice guidance and is
  a larger milestone than this one. This is why KI205 narrows rather than
  closes: a read-only project tree that has never been rendered leaves every
  record absent, and nothing here recovers those.
- Replacing the store → the store stays the primary route.

## Acceptance criteria

- [ ] AC1. With `examples/book-placement/`'s `four.qmd` store path held by a
      directory — the arrangement `tests/run-tests.sh`'s M063-AC3 case already
      makes — two consecutive whole-book HTML renders each print exactly three
      index sections, `alpha` in `index.html`, `beta` in `three.html` and
      `gamma` in `five.html`, and the `gamma` section carries `Dovetail`,
      `Escutcheon`, `Gantry` and `Gondola` — the four terms the fixture's
      chapters file in `gamma`, `Dovetail` living only in `four.qmd`. Each
      render exits 0. (RB tripwire: ip-touching)
- [ ] AC2. In those same two renders, the `gamma` entry for `Dovetail` links to
      `four.html` with no `#` in its href, and each of `Escutcheon`, `Gantry`
      and `Gondola` links to a page href whose `#` fragment names an id that is
      present on that rendered page.
- [ ] AC3. With the store paths of both `index.qmd` and `three.qmd` held by
      directories — KI214's own observation, which today prints no `gamma`
      section on any page — two consecutive whole-book HTML renders each print
      the same three sections AC1 names, the `gamma` section carrying the same
      four terms, and each exits 0. (RB tripwire: ip-touching)
- [ ] AC4. Against a copy of the tree whose only change disables the recovery
      reader, AC1's arrangement leaves `Dovetail` out of `five.html`'s `gamma`
      section and AC3's arrangement prints no `gamma` section on any of the
      book's five pages; both mutant renders run to completion and exit 0, so
      each failure is the recovery being absent rather than a render that did
      not happen.
- [ ] AC5. With a copy of `examples/book-placement/` whose `four.qmd` store
      path is held by a directory and whose `four.qmd` carries a `\x80` byte —
      which the chapter's own render replaces with the Unicode replacement
      character and completes, and which `pandoc.read` refuses — two
      consecutive whole-book HTML renders each complete and exit 0, and each
      prints `alpha` in `index.html` carrying `Aardvark` and `Bramble`, `beta`
      in `three.html` carrying `Cardamom` and `Coriander`, and `gamma` in
      `five.html` carrying `Escutcheon`, `Gantry` and `Gondola` and not
      `Dovetail`. On each render the report naming `four.qmd` and saying its
      source could not be read either is drawn four times, once per chapter
      that reads the held path; `four.qmd` reads no record of its own and draws
      no such report, its own write still failing on the held path.
- [ ] AC6. `site/books.qmd`'s paragraph on a record that cannot be read states
      what recovery returns — the chapter's authored terms, each linking to
      that chapter's page — and the four things it does not: a fragment,
      anything reaching the chapter through an include shortcode or an executed
      cell, anything in content the HTML render drops, and anything in a
      chapter source Pandoc's markdown reader cannot read.
- [ ] AC7. `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T2, T3, T4, T7
- AC2 → T2, T4, T7
- AC3 → T3, T5, T7
- AC4 → T7
- AC5 → T3, T7
- AC6 → T8
- AC7 → T1, T2, T3, T4, T5, T6, T7, T8

## Tasks

- [x] T1. Append the D-entry superseding D-040's declined clause, and update
      `cairn/DESIGN.md`'s Architecture book paragraph, whose "no chapter can
      see another's" sentence becomes conditional on the store being usable.
- [x] T2. `book_context` gains `root`; add a helper deriving another chapter's
      page href from that chapter's front-matter `output-file:` where it
      declares one, otherwise its source stem plus the output extension.
- [x] T3. `recover_record(ctx, file)`: read and `pandoc.read` the chapter
      source inside a `pcall`, walk the parse for marks and for placement
      markers, and return a record carrying the author's values only — no
      anchor, no role, no pairing verdict. A failure returns nothing and
      leaves the render standing (AC5).
- [x] T4. Call it from `store_read`'s unusable branches and from none of the
      absent branch; teach the HTML locator to emit a bare page href where a
      mark carries no anchor.
- [x] T5. Recovered markers reach `marker_chapter`, so `placing` and `first`
      are settled from them.
- [x] T6. The record-unreadable and record-stale reports gain a clause saying
      what recovery returned for that chapter.
- [x] T7. Suite: extend the M063-AC3 blocked case to AC1 and AC2; add AC3's
      two-held-paths case and AC5's unreadable-source case; add AC4's two
      mutants under `--self-test`; and cover the version-skewed record's two
      recovery reports, which no criterion exercises.
- [ ] T8. `site/books.qmd`, the changelog, and the KI205/KI214 dispositions.

## Work log

- 2026-08-30: created by /milestone-plan.
- 2026-08-30: plan gate chose reading another chapter's `.qmd` and parsing it over reading Quarto's `.quarto/idx/<chapter>.json` cache, which carries the same markdown and adds a dependency on a Quarto internal, and over reading the chapter's rendered HTML, which a probe showed is not on disk during any chapter's filter run; falsified by a Quarto release where a chapter's source is not readable from a sibling chapter's process, or where the output tree is populated mid-render.
- 2026-08-30: plan gate chose a page href with no fragment for a recovered mark over re-deriving the anchor by re-running the minting on the reparse, which matches only where the reparse sees what that chapter's process saw and otherwise links to a fragment that is not on the page; falsified by evidence that the minting is reproducible across shortcodes, includes and cell output.
- 2026-08-30: plan gate chose firing recovery only where a record was opened and could not be used over firing on an absent record too, which would complete a book's first index but falsify `site/books.qmd`'s render-twice guidance and move existing first-render manifests; falsified by an author report that a first render's short index is the more costly failure.
- 2026-08-30: T1 — D-041 was appended at plan time and stands unchanged; this task's remainder is `cairn/DESIGN.md`'s Architecture book paragraph, whose "no chapter can see another's" sentence is now conditional on the store being usable, with recovery, its boundary and KI214's narrowing stated. Suite green (525 ok lines, exit 0) after one re-run: the first run died on a Quarto deno segfault in M20-AC1's PDF render, unrelated to the branch.
- 2026-08-30: T2 — `book_context` returns `root`, and `chapter_href`/`output_extension` derive another chapter's page from its own front-matter `output-file:` or from its source stem. Probed on this fixture: `output-file: custom-four.html` produced `custom-four.html` and `output-file: bare-two` produced `bare-two.html`, so a declared name is taken as written where it carries an extension and given the output extension where it does not. The same probe found `quarto.doc.output_file` for such a chapter naming a path outside the output directory, so `book_context` refuses it and it writes no record at all — filed as KI216, and it makes the `output-file:` branch reachable only where an earlier render left a record this version can no longer use. Suite green, exit 0.
- 2026-08-30: T3 — `recover_record` reads `<root>/<chapter>` and `pandoc.read`s it inside one `pcall`, returning a record whose marks carry levels, surviving cross-reference targets, naming context and index name, and whose `marker` is the chapter's top-level placement markers deduped per index. No anchor, role, pairing verdict or sort key. A locator-contributing recovered mark is flagged `page_locator`, which is what tells it from a cross-reference mark, since neither has an anchor. Defined and unused at this commit; suite green, exit 0.
- 2026-08-30: T4-T6 code landed (checkpoint, tasks not ticked): `store_read` calls `recover_record` on both unusable branches and on neither absent one; `book_marks` carries `page_locator`; `html.lua`'s `mark_target` returns a bare page href where a mark has no anchor and its locator gate accepts `page_locator`; the unreadable- and stale-record reports each split into a recovered and a not-recovered wording. T5 needed no code of its own — `marker_chapter` reads `record.marker`, which a recovered record carries. The suite still pins the pre-recovery behavior, so it is red until T7.
- 2026-08-30: T8 landed (checkpoint, task not ticked until the suite reports): `site/books.qmd`'s record paragraph states what recovery returns and the four things it does not; the changelog gains its entry under Output; KI205 and KI214 both narrow to the ABSENT record, which recovery does not read. The include boundary is probed rather than asserted: on a scratch copy whose `four.qmd` reaches `Dovetail` through `{{< include _dove.qmd >}}`, a warm render printed the term and the same render with four.qmd's store path held printed it nowhere, the four recovery reports still drawn. The render-dropped clause is D-041's stated boundary and is not separately probed.
- 2026-08-30: T4-T7 green. Suite exits 0 twice over the branch: 549 checks plain (524 on the default branch), 1018 with `--self-test` (988). The rebuilt expectations, each derived from an observed render: M55-AC5 and M60-AC5 now print all three declared indexes because the refused record's chapter is recovered, `Turing` linking to `one.html` with no fragment; M063 T2's self-test moves from a lost term to a lost ANCHOR, since recovery returns `Bramble` and only two.qmd's record carries the id it was marked at; the blocked-record case gains `Dovetail` and two locator checks. New cases: AC3's two held marker-chapter paths (8 recovery reports, 2 write failures, 2 marker-position reports, 12 lines per render, twice), AC5's held path plus a `\x80` byte (4 unrecovered-record reports, terms short only `Dovetail`, twice), and the version-skewed record's two recovery reports over a single-chapter render of five.qmd. Under `--self-test`, two mutants returning nil from `recover_record` reproduce the pre-branch manifests for both arrangements, each exiting 0.
- 2026-08-30: amendment (substantive) — AC5's wording. Observed on a scratch copy of `examples/book-placement/`: the arrangement draws the report four times, once per chapter that reads the held path, where AC5 said "one warning names that chapter". A fresh-context [O] criteria audit of the proposed replacement ran in FULL mode and returned 7 findings; 6 fixed in the wording before it was written (name a copy of the fixture rather than the shipped tree; pin the `alpha` and `beta` terms, not only `gamma`'s; two consecutive renders as AC1 and AC3 ask; count the report over the log rather than attribute one per chapter, since the marker-position reports also name `four.qmd`; say `four.qmd` draws no SUCH report while its own write still fails; name the byte and the asymmetry that makes the case reachable). Its probe-adequacy finding went to the gate, which chose keeping the criterion at the one failure shape and covering the version-skewed record's two recovery reports as T7 test work instead.
- 2026-08-30: T7 gains the version-skewed record's two recovery reports, which no criterion exercises (minor amendment, from the AC5 audit).
- 2026-08-30: implementation gate chose leaving a recovered chapter's declared sort keys out of recovery (M065 fences the richer mark forms), extending the existing unreadable-record report with a clause rather than adding a second warning, and one guard around the whole read-parse-walk proven by AC5 rather than escalating the IP2 tripwire.
- 2026-08-30: criteria audit ran in FULL mode ([O], fresh context, user-facing tier plus two `ip-touching` tags) and returned 12 findings. Fixed at the gate: the criteria name the `gamma` terms rather than deferring to a manifest this milestone writes; they assert the whole book's section map rather than one section; AC4 states the observable page outcome rather than a harness verdict; AC2 asserts a fragment present on the rendered page rather than one matching the sidecar JSON; AC5 (both record and source unreadable) and the report-clause task were added. Its href-derivation finding was answered by probe — `book.render` carries no output path, but the chapter's own front-matter `output-file:` does. Findings 5, 6 and 10 (probe adequacy over the unusable-record causes and the recovered mark forms) became the sizing question and are M065.

## Decisions

## Review
