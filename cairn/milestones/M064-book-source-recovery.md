<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M064: A chapter's terms reach the book index when its record cannot be read

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m064-book-source-recovery` — https://github.com/jmgirard/quarto-index/pull/64

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
- A block or span carrying `.content-visible` or `.content-hidden` leaves the
  parse whole before anything is read, whatever its `when-`/`unless-`
  attributes say, so a mark inside one is not recovered even where this render
  would have printed it (D-042).
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
      cell, anything inside a block or span carrying Quarto's
      `.content-visible` or `.content-hidden` class, which the paragraph says
      is taken out whole whatever its `when-` or `unless-` attributes say so
      that a mark there is left out even where this render would have printed
      it, and anything in a chapter source Pandoc's markdown reader cannot
      read.
- [ ] AC7. `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T2, T3, T4, T7
- AC2 → T2, T4, T7
- AC3 → T3, T5, T7
- AC4 → T7
- AC5 → T3, T7
- AC6 → T8, T12
- AC7 → T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12

## Tasks

- [x] T1. The D-entry superseding D-040's declined clause, and DESIGN's
      Architecture book paragraph made conditional on the store being usable.
- [x] T2. `book_context` gains `root`, and a helper derives another chapter's
      page href from its front-matter `output-file:` or its source stem.
- [x] T3. `recover_record(ctx, file)`: read and `pandoc.read` the source in one
      `pcall`, walk it for marks and markers, return the author's values only —
      no anchor, role or pairing verdict; a failure returns nothing.
- [x] T4. Call it from `store_read`'s unusable branches and from neither absent
      one; the HTML locator emits a bare page href for an anchorless mark.
- [x] T5. Recovered markers reach `marker_chapter`, settling `placing`/`first`.
- [x] T6. Both record reports say what recovery returned for that chapter.
- [x] T7. Suite: AC1/AC2 on the extended M063-AC3 case, AC3's two held paths,
      AC5's unreadable source, AC4's two mutants, and the version-skewed
      record's recovery reports.
- [x] T8. `site/books.qmd`, the changelog, and the KI205/KI214 dispositions.
- [ ] T9. Recovery drops every `.content-visible`/`.content-hidden` block and
      span before reading a mark or marker (F1); the suite holds the terms
      inside them out of every index section.
- [ ] T10. `build_entry_tree` prints one locator per destination and role
      (F2); the suite holds a recovered chapter marking one term twice to a
      single link.
- [ ] T11. A third report wording for a source that parses and reaches no mark
      (F3), and a term manifest for the cold first render, so recovery on an
      absent record would turn the suite red (F4).
- [ ] T12. The AC6 and Scope amendments, D-042, the `books.qmd`, DESIGN and
      changelog sentences the repairs falsify (F8, F9), and KI217/KI218.

## Work log

- 2026-08-30: created by /milestone-plan.
- 2026-08-30: plan gate chose reading another chapter's `.qmd` and parsing it over reading Quarto's `.quarto/idx/<chapter>.json` cache, which carries the same markdown and adds a dependency on a Quarto internal, and over reading the chapter's rendered HTML, which a probe showed is not on disk during any chapter's filter run; falsified by a Quarto release where a chapter's source is not readable from a sibling chapter's process, or where the output tree is populated mid-render.
- 2026-08-30: plan gate chose a page href with no fragment for a recovered mark over re-deriving the anchor by re-running the minting on the reparse, which matches only where the reparse sees what that chapter's process saw and otherwise links to a fragment that is not on the page; falsified by evidence that the minting is reproducible across shortcodes, includes and cell output.
- 2026-08-30: plan gate chose firing recovery only where a record was opened and could not be used over firing on an absent record too, which would complete a book's first index but falsify `site/books.qmd`'s render-twice guidance and move existing first-render manifests; falsified by an author report that a first render's short index is the more costly failure.
- 2026-08-30: T1 — D-041 was appended at plan time and stands unchanged; this task's remainder is `cairn/DESIGN.md`'s Architecture book paragraph, whose "no chapter can see another's" sentence is now conditional on the store being usable, with recovery, its boundary and KI214's narrowing stated. Suite green (525 ok lines, exit 0) after one re-run: the first run died on a Quarto deno segfault in M20-AC1's PDF render, unrelated to the branch.
- 2026-08-30: T2 — `book_context` returns `root`, and `chapter_href`/`output_extension` derive another chapter's page from its own front-matter `output-file:` or from its source stem. Probed on this fixture: `output-file: custom-four.html` produced `custom-four.html` and `output-file: bare-two` produced `bare-two.html`, so a declared name is taken as written where it carries an extension and given the output extension where it does not. The same probe found `quarto.doc.output_file` for such a chapter naming a path outside the output directory, so `book_context` refuses it and it writes no record at all — filed as KI216, and it makes the `output-file:` branch reachable only where an earlier render left a record this version can no longer use. Suite green, exit 0.
- 2026-08-30: T3 — `recover_record` reads `<root>/<chapter>` and `pandoc.read`s it inside one `pcall`, returning a record whose marks carry levels, surviving cross-reference targets, naming context and index name, and whose `marker` is the chapter's top-level placement markers deduped per index. No anchor, role, pairing verdict or sort key. A locator-contributing recovered mark is flagged `page_locator`, which is what tells it from a cross-reference mark, since neither has an anchor. Defined and unused at this commit; suite green, exit 0.
- 2026-08-30: T4-T6 code landed (checkpoint, tasks not ticked): `store_read` calls `recover_record` on both unusable branches and on neither absent one; `book_marks` carries `page_locator`; `html.lua`'s `mark_target` returns a bare page href where a mark has no anchor and its locator gate accepts `page_locator`; the unreadable- and stale-record reports each split into a recovered and a not-recovered wording. T5 needed no code of its own — `marker_chapter` reads `record.marker`, which a recovered record carries. The suite still pins the pre-recovery behavior, so it is red until T7.
- 2026-08-30: T8 green and the milestone set to review. Suite exits 0 twice over the branch as it stands: 549 checks plain, 1018 with `--self-test`.
- 2026-08-30: T8 landed (checkpoint, task not ticked until the suite reports): `site/books.qmd`'s record paragraph states what recovery returns and the four things it does not; the changelog gains its entry under Output; KI205 and KI214 both narrow to the ABSENT record, which recovery does not read. The include boundary is probed rather than asserted: on a scratch copy whose `four.qmd` reaches `Dovetail` through `{{< include _dove.qmd >}}`, a warm render printed the term and the same render with four.qmd's store path held printed it nowhere, the four recovery reports still drawn. The render-dropped clause is D-041's stated boundary and is not separately probed.
- 2026-08-30: T4-T7 green. Suite exits 0 twice over the branch: 549 checks plain (524 on the default branch), 1018 with `--self-test` (988). The rebuilt expectations, each derived from an observed render: M55-AC5 and M60-AC5 now print all three declared indexes because the refused record's chapter is recovered, `Turing` linking to `one.html` with no fragment; M063 T2's self-test moves from a lost term to a lost ANCHOR, since recovery returns `Bramble` and only two.qmd's record carries the id it was marked at; the blocked-record case gains `Dovetail` and two locator checks. New cases: AC3's two held marker-chapter paths (8 recovery reports, 2 write failures, 2 marker-position reports, 12 lines per render, twice), AC5's held path plus a `\x80` byte (4 unrecovered-record reports, terms short only `Dovetail`, twice), and the version-skewed record's two recovery reports over a single-chapter render of five.qmd. Under `--self-test`, two mutants returning nil from `recover_record` reproduce the pre-branch manifests for both arrangements, each exiting 0.
- 2026-08-30: amendment (substantive) — AC5's wording. Observed on a scratch copy of `examples/book-placement/`: the arrangement draws the report four times, once per chapter that reads the held path, where AC5 said "one warning names that chapter". A fresh-context [O] criteria audit of the proposed replacement ran in FULL mode and returned 7 findings; 6 fixed in the wording before it was written (name a copy of the fixture rather than the shipped tree; pin the `alpha` and `beta` terms, not only `gamma`'s; two consecutive renders as AC1 and AC3 ask; count the report over the log rather than attribute one per chapter, since the marker-position reports also name `four.qmd`; say `four.qmd` draws no SUCH report while its own write still fails; name the byte and the asymmetry that makes the case reachable). Its probe-adequacy finding went to the gate, which chose keeping the criterion at the one failure shape and covering the version-skewed record's two recovery reports as T7 test work instead.
- 2026-08-30: T7 gains the version-skewed record's two recovery reports, which no criterion exercises (minor amendment, from the AC5 audit).
- 2026-08-30: implementation gate chose leaving a recovered chapter's declared sort keys out of recovery (M065 fences the richer mark forms), extending the existing unreadable-record report with a clause rather than adding a second warning, and one guard around the whole read-parse-walk proven by AC5 rather than escalating the IP2 tripwire.
- 2026-08-30: criteria audit ran in FULL mode ([O], fresh context, user-facing tier plus two `ip-touching` tags) and returned 12 findings. Fixed at the gate: the criteria name the `gamma` terms rather than deferring to a manifest this milestone writes; they assert the whole book's section map rather than one section; AC4 states the observable page outcome rather than a harness verdict; AC2 asserts a fragment present on the rendered page rather than one matching the sidecar JSON; AC5 (both record and source unreadable) and the report-clause task were added. Its href-derivation finding was answered by probe — `book.render` carries no output path, but the chapter's own front-matter `output-file:` does. Findings 5, 6 and 10 (probe adequacy over the unusable-record causes and the recovered mark forms) became the sizing question and are M065.
- 2026-08-30: return-1 gate chose skipping every `.content-visible`/`.content-hidden` block and span whole over deciding per block whether the format in hand keeps it, which re-implements Quarto's visibility rules inside this extension and returns the defect wherever the two disagree; falsified by an author reporting a term lost from a recovered index because it sat in a block that render kept. Also chose holding the criteria set rather than adding criteria for F1 and F2 (D-118's direction on a milestone already returned once), and putting the new cases in scratch copies rather than growing `examples/book-placement/`, whose growth is M065's own task.
- 2026-08-30: amendment (substantive) — AC6's third boundary item and one Scope In bullet. The repair makes AC6's "anything in content the HTML render drops" a promise nothing enumerates, so it narrows to the two conditional-content classes the reader does enumerate; the Scope bullet states the same skip. A fresh-context [O] criteria audit of the proposed AC6 wording ran in FULL mode and returned 7 findings; 4 fixed in the wording before it was written (name the two classes rather than the mechanism, since a bare `.content-visible` is skipped and other drop routes are not; fold the em-dash aside into what the paragraph states, so the criterion is settled by reading rather than by probe; drop "the render in hand" for plain wording; keep the list's four items parallel). Its finding that `cairn/DESIGN.md`, `CHANGELOG.md` and D-041 carry the same falsified clause went to T12 and D-042 rather than to a new criterion, and its probe-adequacy finding to T9's suite check, both per the gate's hold-the-set choice. Every criterion box is unticked: the Review section's evidence predates these repairs.
- 2026-08-30: review return 1 (defect) — F1: a mark inside a `.content-visible when-format="pdf"` div is recovered into the book index linking to a page that does not carry it, probed on a scratch copy of `examples/book-placement/` (`Wainscot` in `five.html`'s `gamma` linking to `four.html`), which is D-041's own stated falsifier and makes the "nothing in content the HTML render drops" clause of `site/books.qmd`, `cairn/DESIGN.md` and `CHANGELOG.md` false; F2: a recovered chapter marking one term twice prints two identical page locators, `build_entry_tree` deduping cross-references and not locators; F3: the recovered-from-source report is drawn on any successful parse, including one that recovered nothing; F4: no check asserts a cold first render is still short its later chapters' terms, so recovery on an absent record would leave the suite green. Gate chose sending the milestone back over merging as-is or correcting the wording alone.

## Decisions

## Review

Fresh evidence, 2026-08-30, over the branch at its pre-gate state. The
acceptance suite is the profile's `verify` command; every criterion below cites
the run that produced its result.

**AC1** — green. `tests/run-tests.sh` exits 0; the M063-AC3/M064-AC1 case holds
two consecutive whole-book renders of `examples/book-placement/` with
`four.qmd`'s store path held by a directory to one section manifest —
`index.html qi-index-alpha`, `three.html qi-index-beta`, `five.html
qi-index-gamma`, `two.html` and `four.html` no section — and to one term
manifest putting `Dovetail`, `Escutcheon`, `Gantry` and `Gondola` in
`five.html`'s `gamma`. Both renders exit 0 and draw the same seven warnings.

**AC2** — green. In each of those two renders the `gamma` entry for `Dovetail`
links to `four.html` with no `#`, and all three of the section's other locators
carry a fragment naming an id the page it points at holds — checked against the
rendered page, not against the sidecar record.

**AC3** — green. With the store paths of `index.qmd` and `three.qmd` both held,
two consecutive renders each match the same section manifest AC1 names and the
same four `gamma` terms, each exiting 0, each drawing twelve warning lines —
eight recovery reports, two marker-position reports and two write failures.

**AC4** — green. Under `--self-test`, two mutant copies of the tree whose only
change is a `do return nil end` at the top of `recover_record` reproduce the
pre-branch outcome. AC1's arrangement then prints three sections and seven
terms — `Dovetail` absent from `five.html`'s `gamma`, where the AC1 manifest
requires it. AC3's arrangement prints two sections, no `gamma` on any of the
book's five pages, which is KI214's own observation. Both mutant renders run to
completion and exit 0, so each failure is the recovery being absent rather than
a render that did not happen.

**AC5** — green. On a copy of the fixture whose `four.qmd` store path is held
and whose source carries a `\x80` byte, both renders complete and exit 0 and
print `Aardvark`/`Bramble` in `index.html`'s `alpha`, `Cardamom`/`Coriander` in
`three.html`'s `beta`, and `Escutcheon`/`Gantry`/`Gondola` — not `Dovetail` —
in `five.html`'s `gamma`. The report naming `four.qmd` and saying its source
could not be read either is drawn four times per render; the recovery wording
is drawn zero times; `four.qmd` draws one write failure of its own and no such
report. The suite also guards the asymmetry the case rests on: the planted file
must fail to decode as UTF-8 while the chapter's own render completes.

**AC6** — green. `site/books.qmd` (read at HEAD) states that where the record
was there to open and could not be used, the chapter's `.qmd` is parsed and the
terms it marks and the markers it carries join the index, and that the report
says the terms came from source; four bulleted paragraphs then state what
recovery does not return — no fragment, nothing reaching the chapter through an
include shortcode or an executed cell, nothing in content the HTML render
drops, and nothing at all where Pandoc's markdown reader cannot read the
source. A closing paragraph states that an absent record is not recovered.

**AC7** — green. Both runs made 2026-08-30 over the branch at its pre-gate
state: `tests/run-tests.sh` reported "All checks passed (549 checks)" and exited
0; `tests/run-tests.sh --self-test` reported "All checks passed (1018 checks)"
and exited 0. The default branch stands at 524 and 988.

## Consistency gate

- `cairn_validate.py` — exit 0, every check PASS, every advisory OK. The
  `release window` advisory did not fire.
- `cairn_impact.py` — skipped: the branch changes no `DESIGN.md` IP/GP
  principle text (`git diff main...HEAD -- cairn/DESIGN.md` matches no
  principle line), only the Architecture book paragraph and the Known issues
  entries.
- Toolchain checks — the active `generic` profile names none, so this half of
  the gate is a clean no-op.
- Default branch — `origin/main` had not moved since the branch was cut (0
  commits behind), so no merge or re-run was needed before gathering evidence.

## Review findings

Three fresh-context lenses ran on the diff (`git diff main...HEAD`), none having
seen the implementation. The [S] blame-history lens reported no findings. The
[S] prior-review lens reported one. The [O] diff-bug lens reported eleven.
Ranked most severe first, each with its verification and its proposed
disposition; the gate decides.

**F1 — CONFIRMED by probe. A recovered term reaches the index where the
rendered page does not carry it.** `recovered_marks` walks every `Span` of the
whole `pandoc.read` parse and knows nothing of what the render emits, so a mark
inside `::: {.content-visible when-format="pdf"}` is recovered. Probed
2026-08-30 on a scratch copy of `examples/book-placement/` with a `Wainscot`
mark in such a div in `four.qmd` and that chapter's store path held by a
directory: `five.html`'s `gamma` section printed `Wainscot` linking to
`four.html`, a page that does not contain it. The same render with a usable
record printed it nowhere, and a mark inside an HTML comment was not recovered
in either. This is the falsifying condition D-041 states for itself. It also
makes the third of the four boundary claims `site/books.qmd`, `cairn/DESIGN.md`
and `CHANGELOG.md` each assert — "nothing in content the HTML render drops" —
false as written. Proposed: return to `in-progress`.

**F2 — CONFIRMED by probe. A recovered chapter marking one term twice prints
two identical locators.** `build_entry_tree` appends locators with no dedup,
where it dedupes cross-references three lines below; with anchors the two are
distinct targets, recovered they are the same bare page href. Probed on the
same tree with a second `Dovetail` mark added to `four.qmd`: the `gamma` entry
printed `<a href="four.html">1</a>, <a href="four.html">2</a>`. A range's two
ends reach this the same way, `paired` not being recovered by design. Proposed:
return to `in-progress`.

**F3 — CONFIRMED by reading, and by this milestone's own T8 probe.** The
"terms were recovered from its own source instead" report is drawn on any
successful parse: `recover_record` returns a record whatever the walk yields,
and `store_read` keys the wording on `rebuilt ~= nil`. A chapter reaching its
terms through an include shortcode parses to zero marks, and the T8 work-log
entry records exactly that — the term printed nowhere while "the four recovery
reports [were] still drawn". The author is told terms came back when none did.
Proposed: return to `in-progress` with F1 and F2.

**F4 — CONFIRMED by reading. The milestone's headline boundary has no
discriminating check.** No check asserts a cold first render is still short its
later chapters' terms: `place-first` runs `check_book_sections` and
`check_extension_warning_count` only, and every one of the seven
`check_book_terms` call sites is a warm or blocked arrangement. Moving the
`recover_record` call into `store_read`'s absent path would leave the suite
green, though Scope Out says that change falsifies `site/books.qmd`'s
render-twice guidance. Proposed: fix with F1-F3 — a term manifest for the cold
render.

**F5.** An undeclared `index=` on a recovered mark is refiled silently:
`mark_index(..., false)` folds the unknown name before the record is handed on,
so `fold_undeclared` never adds the chapter to `refiled`. A stored record in
the same position draws the "which this book does not declare" report.
Proposed: follow-up.

**F6.** The four-item boundary list omits `sort=` and `mention=`, neither
recovered. A dropped sort key moves an entry in the printed order with nothing
said. AC6 asks for four, so this is a gap rather than a failure. Proposed:
follow-up to M065, which fences the richer mark forms.

**F7.** A `STORE_VERSION` bump makes every record stale, so the first render
after an upgrade has each of n chapters read and `pandoc.read` the other n-1
sources — n(n-1) parses per whole-book render. Fine at five chapters,
unmeasured at scale, and named nowhere. Proposed: Known issues entry.

**F8.** `cairn/DESIGN.md` says recovery carries the printed levels, the index
each mark files in, and which indexes the chapter places; the code also
recovers `see=`/`see-also=` targets, which reach both the index and
`report_book_dangling`. The recovery is load-bearing — a surviving target is
what decides whether a mark contributes a locator — so the defect is the
summary, not the code. Proposed: fix the sentence with F1-F3.

**F9.** `site/books.qmd`'s "Either report repeats: the book draws it once for
every chapter that builds an index section" is drawn per chapter that READS,
not per chapter that builds; AC5's own count is four reports in a book with
three building chapters. Pre-existing text (KI215 covers a narrower version),
but the branch rewrote the paragraph above it and AC5 makes the mismatch
concrete. Its "Either" also no longer has a nearby antecedent. Proposed: fix
the sentence with F1-F3.

**F10.** `chapter_href` concatenates a declared `output-file:` with no
validation, so `.html` becomes `.html.html` and an absolute or `../` value is
joined as written. Reachable only through a version-skewed leftover (KI216),
which the code comment says. Proposed: reject — near-unreachable, and the
branch names the reachability condition.

**F11.** `page_locator` is copied out of a record in `book_marks` but not
policed by `valid_record`, where every other mark field is. Records are
extension-written and the worst case is a bare page link. Proposed: reject —
theoretical.

**F12 ([S] prior-review lens).** The diff adds five names to `book.lua`'s
export table — `output_extension`, `chapter_href`, `recovered_marks`,
`recovered_markers`, `recover_record` — none reached from outside the module
(confirmed by grep over `tests/` and the other filter modules). This grows the
surface KI77 describes rather than narrowing it. Proposed: reject as already
tracked — the standing candidate row on narrowing each module's exports covers
it, and a second row would duplicate it.

**On AC6.** AC6 asks that `site/books.qmd` state four things recovery does not
return, and it states them; the criterion passes as written and is not
reinterpreted here. F1 records that the third of the four is false of the code.

## Gate disposition

2026-08-30. Presented at the merge gate with all seven criteria green, the
consistency gate clean and CI green on PR #64. The maintainer judged F1 and F2
load-bearing defects in what the extension does for a reader of an authored
book and sent the milestone back to `in-progress` rather than merging as-is or
correcting the wording alone. This is defect return 1 for M064.

Dispositions taken: F1, F2, F3 and F4 return to implementation, F8 and F9 fix
with them, F5 and F6 follow-up (F6 to M065), F7 a Known issues entry, F10, F11
and F12 rejected as recorded above. No merge, no approval marker written, and
the draft PR stays open on the branch.
