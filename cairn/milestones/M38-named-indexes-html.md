# M38: Marks name which index they belong to, and the HTML back-end prints each

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP4, GP5
- **Branch/PR:** m038-named-indexes-html · https://github.com/jmgirard/quarto-index/pull/38

## Goal

An author can send index marks to more than one named index, which the HTML
back-end prints as one section each.

## Scope

Surface tier: **user-facing** — the deliverable is new author-written syntax
and new rendered output, which the general Quarto community reads.

**In:** an `indexes:` metadata list declaring each index's name and printed
title in order, the first declared being the one an unnamed mark files in;
an `index=` attribute on a mark and on a placement marker; per-index keying
of the format-neutral accumulators, so a cross-reference target, a sort key
and a range pair are all settled within one index; an HTML back-end that
builds one entry tree per declared index and emits one section each, in
declared order, with its own title, section id and entry ids; a PDF render
and a book chapter that index every named-index mark in the document's one
index and report that they did; README and the DESIGN convention line.

**Out:** more than one index in a PDF — Quarto's PDF loop builds only the
main `.idx`, so the design fork (imakeidx's own shell-escape run against a
documented one-index limit) is unsettled → `candidate` row, promoted on that
fork being settled. More than one index across a book's chapters, which
needs the sidecar store's record format and version → `candidate` row,
promoted once this milestone lands. Per-index index styles, headers or
collation rules — nothing here changes how one index is ordered or printed.

## Acceptance criteria

- [x] AC1: An HTML render of `examples/named-indexes.qmd`, whose metadata
      declares two indexes, prints one section per declared index in declared
      order. `tests/htmlindex.py` reads the captured page and asserts, for
      each declared index, the section heading's tag and text, the section
      id, and the exact set of top-level entry texts listed under it, against
      a manifest derived from that fixture's marks.
- [x] AC2: A cross-reference target resolves only within its own index. In
      that fixture a `see=` on a mark of the second index whose target names
      a term marked only in the first draws the dangling-target report, and a
      `see=` on a mark of the first index naming that same term draws none;
      both readings come from the captured render log, greped by the report's
      own key.
- [x] AC3: The sort-key registry and range pairing are keyed within one
      index. In that fixture a term carrying `sort=` in the first index sits
      in the letter group its key selects while the same term with no sort
      key in the second index sits in the letter group its own text selects;
      and a `range="open"` in the first index with a `range="close"` on the
      same term in the second leaves the never-closed report for the opening
      and the never-opened report for the closing in the captured log, each
      of the two marks printing an ordinary locator in the captured HTML.
- [x] AC4: A placement marker names the index it places, and the
      first-marker rule applies per index. In a fixture writing three markers
      — one per declared index, plus a second for the first index — the
      captured HTML carries each index's section at its own marker's
      position, asserted by the id of the element preceding the section, and
      the captured log carries exactly one duplicate-marker report, naming
      the repeated index.
- [x] AC5: A named index outside HTML degrades without loss. A PDF render of
      the same fixture leaves in the captured `.tex` an `\index{}` command
      for every mark the fixture's manifest lists, each carrying the argument
      the default index gives it, exactly one `\printindex`, and no marker
      residue; the captured log carries one report per named-index mark and
      one per named-index marker, each naming the index and saying the mark
      was indexed in the document's one index instead. The same two
      properties hold for a chapter of `examples/book/` rendered to HTML.
- [x] AC6: README's new section states the metadata declaration form, the
      `index=` attribute on a mark and on a placement marker, the rule that
      an unnamed mark files in the first declared index, and that a PDF
      render and a book index everything in one index for now; every fixture
      path and command that section names exists in the repo and runs clean.
- [x] AC7: `tests/run-tests.sh --self-test` passes, with a planted defect for
      each clause of each reader this milestone adds shown red before its
      green is trusted.

## Coverage

- AC1 → T1, T2, T5, T7, T8
- AC2 → T3, T7, T8
- AC3 → T3, T7, T8
- AC4 → T4, T7, T8
- AC5 → T6, T7, T8
- AC6 → T10
- AC7 → T9

## Tasks

<!-- T1-T10 were the original cut; each is done and its outcome is the work-log
     line naming it, so the text here is compressed to what the task was.
     T11-T17 were added at the 2026-08-25 review gate. -->

- [x] T1: Read `indexes:` into an ordered name->title table, first name the
      default, reporting a malformed, empty or repeating declaration; no
      `indexes:` key keeps today's single unnamed index.
- [x] T2: Read `index=` on a mark and on a placement marker; report a value
      naming no declared index and file the mark in the default index.
- [x] T3: Key the format-neutral accumulators per index — `marked_paths`,
      `pending_xrefs`, `clamped_paths`, `sort_keys` and `pair_ranges`'
      pending/waiting maps — with `reset` still emptying each in place.
- [x] T4: Make `resolve_markers` and `place_index` per index: one surviving
      marker per name, the duplicate report naming the index it repeats, and
      `place_index` taking a per-index block map.
- [x] T5: `html.lua`: one entry tree and one section per index in declared
      order, section ids and entry ids minted from the shared `taken` set.
- [x] T6: `latex.lua`/`index.lua` and `book.lua`: fold every named-index mark
      into the default index, report each mark and marker, keep one
      `\printindex` and one book index.
- [x] T7: `examples/named-indexes.qmd` and its manifest, plus the single-index
      twin whose captured output must not change.
- [x] T8: The AC1-AC5 checks in `tests/run-tests.sh` and `tests/htmlindex.py`,
      each over a captured artifact.
- [x] T9: Self-test entries planting one defect per clause of each reader T8
      adds, each shown red.
- [x] T10: README's `### Named indexes` section, the DESIGN convention line,
      and the ROADMAP row edits.
- [x] T11: Validate a declared index name as an HTML id fragment: report a name
      that cannot be one and refuse to build a section id from it, so no render
      emits an invalid `id` silently (R1).
- [x] T12: In `resolve_markers`, settle a marker's placement slot so a folded
      marker naming a second index cannot take the default index's slot, and
      the author's own default marker is never reported as its duplicate (R2).
- [x] T13: Head a folded union index with something that does not claim to be
      one declared index, matching the reason `section_id` keeps its id neutral
      (R3). Correct `DESIGN.md`'s KI10 inventory in the same task, marked
      `corrected M38`, to carry `indexes.lua`'s four cells (R13).
- [x] T14: Report a second marker naming the same non-default index under fold,
      rather than dropping it silently, so README's claim holds in PDF and in
      books (R4).
- [ ] T15: Give the declared-order rule a fixture that marker order cannot
      satisfy — the markerless append path, and a document whose marker order
      differs from its declared order (R5).
- [ ] T16: Make AC6's command check read what the suite runs rather than
      matching a substring of its text, and pin the `indexes:` declaration
      block the criterion names (R6, R12's five-row comment).
- [ ] T17: Plant a section heading at the wrong level, so the section reader's
      tag comparison is shown red on its own clause (R7).

## Work log

- 2026-08-25: created by /milestone-plan; absorbs the "Multiple named indexes" candidate row added 2026-08-16.
- 2026-08-25: criteria audit ran in REDUCED-scope in-context mode, not the fresh-context reader — the session carries a standing directive against spawning subagents unless asked, reported at the gate. It returned one finding: AC6 as drafted promised "each documented claim is asserted by a check in tests/run-tests.sh", which binds the test harness rather than the deliverable; fixed before the gate by narrowing AC6 to README's own text plus the requirement that every path and command it names exists and runs, with the per-claim check moved to T10.
- 2026-08-25: plan gate probed Quarto 1.10.18 with a two-index imakeidx document: with `noautomatic` the loop built only `probe.idx`, leaving `authors.idx` unprocessed and the second index empty at exit 0; without it, imakeidx ran makeindex itself under restricted shell escape and the second index printed.
- 2026-08-25: plan gate chose YAML metadata declaration over declaring on the placement marker because a book needs one chapter-wide channel and an unmarkered document needs a stated print order; falsified by evidence that authors keep the declaration and the markers out of sync often enough to cost more than the missing order does.
- 2026-08-25: plan gate chose HTML-first with PDF degrading loudly over shipping both back-ends together because the PDF path's design fork is unsettled; falsified by evidence that authors reach for a second index only in print, which would make an HTML-only release useless.
- 2026-08-25: plan gate chose warn-and-fold in books over including book support here because the store's record format and version bump would roughly double this milestone; falsified by evidence that the named-index feature is wanted mainly in books.
- 2026-08-25: plan gate chose "the first declared index is the default" over a reserved default name because a document declaring nothing keeps today's behavior with no reserved word; falsified by evidence that authors reorder the declaration for print order and silently move their default with it.
- 2026-08-25: status in-progress; branch m038-named-indexes-html cut from a synced main. Question gate settled three open implementation choices; recorded below under Decisions.
- 2026-08-25: T1 — `indexes:` metadata read into an ordered name->title table. Two minor task edits: the table lives in a new `modules/indexes.lua` rather than in `core.lua` (core requires nothing and holds constants, not per-document state), and it is read from `passes.Reset` rather than `index.lua`'s `Pandoc`, because the Span passes record marks long before that pass runs. Nine reports cover a non-list, an empty list, a non-map entry, a missing/empty name, a repeated name, a missing/empty title, and a declaration no entry of which is usable; each probed by render. Suite green, 354 checks; warn-distinct's pinned message count 48 -> 61.
- 2026-08-25: T2 — the emitting Span pass and every top-level placement marker read `index=` and report a value naming no declared index; a folded back-end (PDF, or an HTML book) reports each named-index mark and marker and files it in the document's one index. Minor task edit: the three collecting passes read the attribute in T3, where the accumulators they feed are keyed by it, rather than here where the value would have no consumer. Probed by HTML and PDF renders of a two-index fixture; suite green, 354 checks.
- 2026-08-25: T3 — `marked_paths`, `pending_xrefs`, `clamped_paths`, `sort_keys` and `pair_ranges`' pending map are one namespace per index, through a new `qi_core.namespace`; the three collecting passes read `index=` silently and the emitting pass reports it. Probed: a `see=` across indexes dangles while the same target within its own index resolves, and an opening in one index with a closing in the other draws the never-closed and never-opened reports. The M26 pollution probe caught the first cut leaving the module with no index before `reset` ran — a nil accumulator key that failed the synthetic drive and would have made every state-reuse comparison vacuous; the declaration now installs the unnamed index and `reset` restores exactly it. Suite green, 354 checks.
- 2026-08-25: T4 — the first-marker rule is per index: one marker survives per index name, the duplicate report names the index it repeats in a document that declares any, and `place_index` takes a name->blocks map and appends any index no marker names at the end in declared order. Minor task edit: `resolve_markers` keeps its boolean return, since `place_index` reads each surviving marker's index off the marker itself. A marker a folded back-end moves to the document's one index draws its fold report and no duplicate report, so an author is not told of a second marker they never wrote. The suite's duplicate-marker grep key was narrowed from the shared position clause to the half that identifies it, and the new report's key added to the distinctness scan. Suite green, 354 checks.
- 2026-08-25: T5 — `html_index_blocks` returns a name->blocks map, one entry tree and one section per index that has marks, headed with that index's title and identified by `qi-index-<name>`; the entry-id counter runs across every index and every id is checked against the one taken set. Probed on a two-index fixture: two sections, each at its own marker, ids qi-index-authors and qi-index-main, entry ids 1 and 2 across the two. An index with a marker but no marks emits no section rather than a heading over an empty list. Suite green, 354 checks.
- 2026-08-25: T6 — no further code was needed: the fold is one rule, applied where a mark's and a marker's index is resolved, so a LaTeX-derived render and an HTML book both file every named-index mark in the default index and report each. Verified by render — a two-index document to latex leaves exactly one `\printindex` at the first surviving marker, `\index{cat}` and `\index{Knuth}` with their default-index arguments, and no marker residue; a scratch two-chapter HTML book declaring two indexes draws one report for its named mark and one for its named marker, and builds one index carrying all three terms. Suite green, 354 checks.
- 2026-08-25: T7 — `examples/named-indexes.qmd` declares two indexes and carries the cross-index `see=`, the cross-index sort key, the cross-index range pair and three markers; `examples/named-indexes-twin.qmd` is the same terms written by a document that declares none. `examples/book/` gained the declaration, one named mark and one named marker, which is what AC5's book half reads. A folded render now keeps the bare `qi-index` section id: it holds every index's marks, so naming it after one declared index would claim it is that index rather than the union. Suite green, 354 checks, after updating the book's entry manifest (Turing, one.qmd's fifth minted anchor), its letter sweep, its warning count 7 -> 9, the dangling corpus rows for both new fixtures, m29book's duplicate-report pattern and known-warning sets, and the spurious-chapter plant's anchor. The AC1-AC5 manifests themselves are T8's.
- 2026-08-25: T8 — thirteen checks for AC1-AC5, each over a captured artifact. `tests/htmlindex.py` gained `index_sections`/`section_rows`, which read every generated section on a page — id, heading element, heading text, the last authored id before it, and the section's own entry and letter rows — so a page printing the wrong number of sections cannot match a manifest naming each by id; `preceding_authored_id` walks document order rather than siblings, since the writer nests a lower heading's section inside the higher one before it. Two grep keys were added for the fold reports and registered with the distinctness scan, and `check_html_index_links` gained an optional section id. Suite green, 367 checks (was 354).
- 2026-08-25: T9 — eight plants for the section reader, each on a copy of this run's own captured page through the no-op-refusing helper: a section id, a section dropped out of the set, a heading turned into a non-heading element, a heading's text, the authored element a section follows, an entry's text, plus a manifest naming no section and an empty one; a control asserts the reader passes unplanted first. The reader now reports an unreadable section as a finding rather than a traceback. M23's `advance` and `resetmoved` splices were re-anchored on `plan_range`'s new signature. `tests/run-tests.sh --self-test` green, 519 checks.
- 2026-08-25: T10 — README gained a `### Named indexes` section under `## Syntax`, a tenth supported form and a fixture line under Examples; DESIGN gained the per-index scoping convention. The AC6 check reads the section rather than a written-down list: its five claims are compared whitespace-normalized, every `examples/*.qmd` it names must exist, and every command it shows must appear in the suite that runs it. The bibliography-recipe check's section bound was widened from `^## ` to `^#{2,3} `, since the new `###` is the first heading after it. The two follow-up candidate rows the plan added stand as written. Suite green, 368 checks.

## Decisions

- 2026-08-25 (gate): An index is declared as a list entry carrying `name:` and
  `title:`, rather than as a one-key `name: title` pair, so a later per-index
  setting is a third field rather than a change to syntax authors have already
  written. A placement marker naming no index places the first declared index,
  the same index an unnamed mark files in, so one rule covers marks and markers
  alike; a declared index no marker names goes at the end of the document in
  declared order, which is what a marker-less document does today. Each
  section's id is derived from the index's own name — `qi-index-<name>` — so a
  link keeps pointing at the same index when the declaration is reordered; a
  document declaring no indexes keeps the bare `qi-index` it has today.
- 2026-08-25 (return gate): A declared index name must be usable as an HTML id
  fragment — ASCII letters, digits, `-`, `_` and `.`, beginning with a letter —
  and a name that cannot be one is refused with its own report, exactly as an
  empty or repeated name is, so the document keeps the indexes it declared
  usably and never emits a section whose `id` no link resolves against. Under
  fold the one index is placed at the first marker naming the default index
  where the document writes one, and only otherwise at the first folded marker,
  so the author's own default marker is never reported as the duplicate of a
  marker they never wrote; the folded section is headed `Index`, the heading a
  document declaring nothing prints, for the same reason `section_id` keeps its
  id bare — the section holds every index's marks, so one declared index's
  title would claim it is that index. AC6's "runs clean" is read off a ledger
  the suite writes as it renders, each documented command required to appear
  there with exit status 0, rather than off a substring of the suite's own text.

- 2026-08-25: return gate settled four open choices for T11-T17; recorded under Decisions above.
- 2026-08-25: T11 — a declared name must match `^[A-Za-z][A-Za-z0-9._%-]*$`; a name that cannot be an HTML id fragment is refused with its own report, so the document keeps the indexes it declared usably. `examples/named-indexes-misuse.qmd` writes four entries of which two are refused and one has no title; the M38-R1 check reads the refusal by name, matches the two sections the two usable entries leave, and asserts no id on the whole rendered page holds a space, a `#`, a `<` or a `>` — probed red by planting `id="qi-index-my people"` into this run's own capture. warn-distinct's pinned count 62 -> 63. Suite green, 370 checks (was 368).

- 2026-08-25: T12 — `resolve_markers` reads every top-level marker's authored index in a pass of its own, then settles the one place a folded back-end has for its one index: the author's own marker for the index that IS built holds it wherever it stands, and only where the document writes no such marker does the first marker of any name hold it. `placed` is keyed by the authored index rather than the built one, so a marker naming a second index is no longer a duplicate of the first. The fold report for a marker gained a second shape for the marker that does not hold the place, and a third state that stays quiet where a duplicate report says the same thing with the marker it lost to. `examples/named-indexes-foldsite.qmd` writes the `authors` marker before the built index's own, and the M38-R2 check reads off the captured `.tex` that the single `\printindex` follows `site-main` and that no duplicate report of either wording is drawn — the reader probed red on a copy of that capture with `\printindex` moved under `site-authors`. m29book's book-html/book-pdf partition and AC5's marker counts moved to the new shape, which is the one `examples/book/last.qmd` and `named-indexes.qmd` both draw. warn-distinct 63 -> 64. Suite green, 372 checks.

- 2026-08-25: T14 — the duplicate report follows from T12's authored-index keying: a second marker naming the same folded-away index is now the second marker of THAT index rather than a marker of the built one, so it draws the duplicate report naming it instead of being dropped. `examples/named-indexes-foldsecond.qmd` writes two `authors` markers and no marker for the built index, which is also the one fixture drawing the fold shape for the marker that DOES place the one index; the M38-R4 check reads off the captured `.tex` that `\printindex` follows the first site alone, counts the two fold shapes 1 and 0, and reads the one duplicate report by the index it names. Suite green, 375 checks.

- 2026-08-25: T13 — `indexes.title` returns the neutral `Index` wherever a declaring document folds, the same reason `section_id` keeps that section's id bare; the code landed with T11's commit, its check and the DESIGN correction here. `examples/book/`'s first declaration was retitled `Index of Subjects` so the fixture can tell the two apart, and the M38-R3 check reads the one section off the captured book page — one section, bare id, `h1`, headed `Index` — probed red by planting `Index of Subjects` into that heading on a copy of this run's capture. KI10's inventory was corrected against `tests/stateprobe.py`'s `CELLS`: 15 cells there plus `indexes.lua`'s four is 19, not the 17 the entry claimed, whose prose named neither `contested_keys` nor the new four. The entry now also records that M26's probe proves 15 of the 19 — the four new cells are reset per document but sit outside its enumeration, and the fixtures it drives declare no indexes, so a removed reset for them would show nothing to compare; that gap is a follow-up, not a repair this return covers. Suite green, 376 checks.

## Review

Reviewed 2026-08-25 on m038-named-indexes-html at d9ac001 (+ this section),
PR #38. `main` had not moved since the branch was cut, so no merge was needed.
Fresh evidence: one full `tests/run-tests.sh --self-test` run, exit 0, 520
checks; plus direct reads of the captured artifacts named below.

### Acceptance criteria

- AC1 — PASS. The captured `named-indexes.html` carries exactly two generated
  sections; `check_index_sections` matched all 18 manifest rows in order
  (`M38-AC1`), and a direct read of `section_rows` over the same capture gives
  `qi-index-main` / h1 / "Index" then `qi-index-authors` / h1 / "Index of
  Authors" — declared order, each heading tag, text, id and top-level entry set
  as the fixture's manifest states. Link and letter-group sweeps over both
  sections passed (4 and 3 links resolved; 8 letter groups in order).
- AC2 — PASS. Over the captured HTML render log, greped by the
  dangling-target report's own key: exactly one such report, and it names
  `Stranger`, the second index's mark whose `see=` targets `Aardvark` — a term
  only the first index carries. The first index's `Neighbour`, whose `see=`
  names that same `Aardvark`, draws none and renders as a resolved
  `see-link`, while `Stranger` renders as `see-plain`.
- AC3 — PASS. Both halves read from the same capture. Sort keys: the direct
  `section_rows` dump shows `Hague` under letter group Z in `qi-index-main`
  (where a mark writes `sort="Zebra"`) and under H in `qi-index-authors` (where
  no mark writes one). Range pairing: the captured log carries exactly one
  never-closed report and exactly one never-opened report, and the section
  manifest AC1 matched lists both `Cantor` marks with an ordinary locator
  (locator count 1 in each section), so neither half printed a range.
- AC4 — PASS. In the same capture each section's `after` field — the last
  author-written id before it, minted ids skipped — is `site-main` for
  `qi-index-main` and `site-authors` for `qi-index-authors`, so each index sits
  at its own marker. The captured log carries exactly one duplicate-marker
  report; a grep by the report's key confirms it names the repeated index, and
  a second grep confirms the unnamed-index wording a declaring document must
  not use is absent.
- AC5 — PASS, both halves. LaTeX: the captured `named-indexes.tex` carries 8
  `\index{}` commands matching all 7 manifest rows, exactly one `\printindex`,
  and zero occurrences of the marker id — read directly off the capture as well
  as by the suite's manifest and token checks. Each named-index mark carries
  the argument the default index gives it, including `Zebra@Hague` for the
  second index's `Hague`, which writes no sort key of its own. The captured log
  carries one fold report per named-index mark (4) and one per named-index
  marker (1), each naming the index the author wrote. Book: the captured
  `book-html/_book/last.html` carries exactly one generated section, keeping the
  bare `qi-index` id since it holds every index's marks, and `Turing` — the
  chapter's `index="people"` mark — is listed in it; the captured book log
  carries one fold report for that mark and one for the named marker.
- AC6 — PASS. Read directly from `README.md`'s `### Named indexes` section: it
  shows the `indexes:` metadata form with `name`/`title` and says what each
  does; shows `index=` on a mark and on a placement marker, each with an
  example; states that a mark or marker naming none takes the first declared
  index; and states under its own subheading that a LaTeX or PDF render and an
  HTML book each build a single index for now, folding and reporting every
  named-index mark and marker. The suite's `M38-AC6` check confirmed the
  section's pinned claims are present, that the 2 fixture paths it names exist,
  and that the 2 commands it shows are commands this suite runs — the suite
  being green is what "runs clean" reports.
- AC7 — PASS. `tests/run-tests.sh --self-test` exited 0 with 520 checks. The
  eight plants for this milestone's section reader each ran red on its own
  clause — a section id, a section dropped from the set, a heading turned into
  a non-heading element, a heading's text, the authored element a section
  follows, an entry's text, plus a manifest naming no section and an empty one
  — and a control asserted the reader passes on the same captured page
  unplanted before any of them. Every plant is applied to a copy of this run's
  own capture through the no-op-refusing helper, so a plant that changed
  nothing would itself fail.

### Consistency gate

- `cairn_validate.py` exit 0 — every check PASS, every advisory OK; the
  `release window` advisory did not fire.
- Toolchain checks: the active `generic` profile names none, so this half is a
  clean no-op.
- `cairn_impact.py` not run: the milestone added a `DESIGN.md` convention
  bullet and changed no numbered principle's text.

### Independent review

Three fresh-context reviewers, each on a distinct evidence base, spawned at the
user's explicit direction (the session carries a standing directive against
spawning subagents unless asked; the directive was put to the user at this
gate and they chose the full fan-out).

- [S] prior-PR-comments lens: no findings. It read the archived `## Review`
  sections touching these files (M03, M04, M05, M08, M17, M19, M20, M22, M23,
  M25, M26, M28, M29, M31) and probed the GitHub inline-comment surface, which
  returned empty, so the per-PR walk was not paid for.
- [S] blame-history lens: one finding (R13 below); no D-entry contradicted, no
  guard weakened, M26's reset invariant intact.
- [O] diff-bug lens: twelve findings (R1-R12 below).

Findings, ranked as reported, with the disposition each was given. R1-R4 were
re-verified in this session by probe renders against the shipped extension in a
scratch copy, never against the reviewer's account of it.

- R1: An index name is never validated as an HTML id fragment, so a declared
  name with a space emits an invalid `id`. Confirmed by probe: a document
  declaring `name: "my index"` renders `<section id="qi-index-my index">`, with
  no report drawn. An id carrying whitespace is invalid HTML and no link to it
  resolves. `#`, `"` and `<` are the same hole.
- R2: In a folded render, a marker naming a second index takes the default
  index's placement slot, and the author's own default marker is then reported
  as its duplicate. Confirmed by probe: a two-index document whose `authors`
  marker precedes its unnamed marker renders `\printindex` under the `authors`
  marker's heading, and the log says the author's single `main` marker "is a
  second marker for the index named main". The comment at `marker.lua:252-256`
  says the design avoids exactly this false report; it avoids it only in the
  marker ordering `examples/named-indexes.qmd` happens to use.
- R3: A folded union index is headed with the first declared index's title,
  contradicting the reason its id is kept neutral. Confirmed by probe: a book
  declaring `people` first and `main` second heads its single union section
  `Index of People` while carrying `main`'s marks, under the neutral id
  `qi-index` that `indexes.lua:264-266` keeps neutral precisely so the section
  does not claim to be one declared index.
- R4: Two markers naming the same non-default index draw no duplicate report at
  all under fold; one is silently dropped. Confirmed by probe: two
  `index="authors"` markers in a LaTeX render draw two fold reports and no
  duplicate report. README's "A second marker for one index is reported and
  places nothing" is false for that shape in PDF and in books.
- R5: AC1's "in declared order" is not what the check asserts. The fixture
  writes its markers in declared order, so section order equals marker order
  and declared order at once and the manifest cannot tell them apart; the
  markerless-append path, the one place declared order is actually the rule,
  is exercised by no fixture.
- R6: AC6's "every command runs clean" is a substring match over the whole
  suite file, comments included, and reads no exit status; the `indexes:` YAML
  block the criterion names is pinned by nothing.
- R7: The self-test's heading-element plant only exercises the no-heading
  guard, not the tag comparison — an `h2` where an `h1` belongs has no plant.
- R8: `index=""` is silently accepted in a document that declares nothing,
  while the same attribute in a declaring document is reported.
- R9: A declared index with a marker and no marks disappears with nothing said.
  A continuation of the pre-M38 whole-document silence, far easier to hit per
  index.
- R10: `latex.lua`'s `contested_keys` is the one accumulator M38 did not
  namespace — unreachable today, the sole exception to the DESIGN bullet's
  "every format-neutral accumulator is one namespace per index", and live the
  day the PDF fork lands.
- R11: Dangling-target reports are now grouped by index rather than emitted in
  document order — deterministic, user-visible, unnoted.
- R12: Bookkeeping — `warn-distinct.py`'s `EXPECTED` is 62 while the T1 work-log
  line records 48 -> 61; the `README_INDEXES_CLAIMS` comment says "four claims"
  over a five-row manifest; T1/T2's task text cites file positions the shipped
  code moved.
- R13: `DESIGN.md`'s KI10 says "M26 resets all 17 per document" and enumerates
  them through M23; `indexes.lua` adds four more module-level per-document cells
  (`order`, `titles`, `declared`, `folded`), all correctly reset by
  `indexes.reset` and confirmed so here, but KI10 is now an incomplete inventory
  of the surface it exists to document.
- R14 (this session, over AC6): the pinned-claim manifest carries no row for
  README's "A mark says which index it belongs to with `index=`" sentence or its
  example, so that claim — one AC6 enumerates — could be deleted from README
  without the check going red.

### Triage

Maintainer at the 2026-08-25 gate: send back, fixing the four confirmed output
defects and the three check gaps that let them through. R1 and R2 qualify under
the return floor as load-bearing defects in what the extension does for an
author — silently invalid HTML, and a wrong placement site paired with a report
accusing the author of a second marker they never wrote. Both sit inside
changes this milestone intentionally made, so the out-of-scope member for an
intentional change does not cover them.

- R1, R2, R3, R4 → fix now, on the branch, as T11-T14.
- R5, R6, R7 → fix now, as T15-T17: the checks that were supposed to fence this
  work and did not.
- R8, R9, R10, R11, R14 → follow-up. Filed as candidate rows or Known issues in
  the hygiene pass of whichever review merges this milestone; R9 is a Known
  issue (a fact about today's behavior, not proposed work).
- R12's comment and count slips → fixed with T15-T17. Its work-log citation
  (48 -> 61 against a shipped 62) is history and is superseded by the T11-T17
  work-log lines, never edited.
- R13 → fix now, with T11-T14, since the entry it corrects is about the state
  this milestone added.
- 2026-08-25: review — PR #38 opened; `main` had not moved. All seven criteria passed with fresh evidence (full suite --self-test, exit 0, 520 checks) and the consistency gate was clean. Returned to in-progress at the merge gate under the return floor: the independent review found, and this session re-verified by probe, that a declared index name is never validated as an HTML id fragment so a name with a space emits an invalid `id` with no report (R1), and that in a folded render a marker naming a second index takes the default index's placement slot while the author's own default marker is reported as its duplicate (R2). R3, R4 and the three check gaps R5-R7 ride the same return. Defect return 1 for this milestone; no amendment return, no criterion reinterpreted. Requested changes logged as T11-T17 at the gate's direction.
- 2026-08-25: the seven added tasks put the plan-owned body 4 lines over the cap; the Tasks section, the heaviest, was compressed in one rewrite — T1-T10 shortened to what each task was, their outcomes already standing in the work-log lines above. `cairn_validate` passes; the 17-task split tripwire is an advisory this milestone accepts, the seven added tasks being one round of gate-directed repair rather than new scope.
