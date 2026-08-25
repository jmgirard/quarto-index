# M38: Marks name which index they belong to, and the HTML back-end prints each

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP4, GP5
- **Branch/PR:** m038-named-indexes-html

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

- [ ] AC1: An HTML render of `examples/named-indexes.qmd`, whose metadata
      declares two indexes, prints one section per declared index in declared
      order. `tests/htmlindex.py` reads the captured page and asserts, for
      each declared index, the section heading's tag and text, the section
      id, and the exact set of top-level entry texts listed under it, against
      a manifest derived from that fixture's marks.
- [ ] AC2: A cross-reference target resolves only within its own index. In
      that fixture a `see=` on a mark of the second index whose target names
      a term marked only in the first draws the dangling-target report, and a
      `see=` on a mark of the first index naming that same term draws none;
      both readings come from the captured render log, greped by the report's
      own key.
- [ ] AC3: The sort-key registry and range pairing are keyed within one
      index. In that fixture a term carrying `sort=` in the first index sits
      in the letter group its key selects while the same term with no sort
      key in the second index sits in the letter group its own text selects;
      and a `range="open"` in the first index with a `range="close"` on the
      same term in the second leaves the never-closed report for the opening
      and the never-opened report for the closing in the captured log, each
      of the two marks printing an ordinary locator in the captured HTML.
- [ ] AC4: A placement marker names the index it places, and the
      first-marker rule applies per index. In a fixture writing three markers
      — one per declared index, plus a second for the first index — the
      captured HTML carries each index's section at its own marker's
      position, asserted by the id of the element preceding the section, and
      the captured log carries exactly one duplicate-marker report, naming
      the repeated index.
- [ ] AC5: A named index outside HTML degrades without loss. A PDF render of
      the same fixture leaves in the captured `.tex` an `\index{}` command
      for every mark the fixture's manifest lists, each carrying the argument
      the default index gives it, exactly one `\printindex`, and no marker
      residue; the captured log carries one report per named-index mark and
      one per named-index marker, each naming the index and saying the mark
      was indexed in the document's one index instead. The same two
      properties hold for a chapter of `examples/book/` rendered to HTML.
- [ ] AC6: README's new section states the metadata declaration form, the
      `index=` attribute on a mark and on a placement marker, the rule that
      an unnamed mark files in the first declared index, and that a PDF
      render and a book index everything in one index for now; every fixture
      path and command that section names exists in the repo and runs clean.
- [ ] AC7: `tests/run-tests.sh --self-test` passes, with a planted defect for
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

- [x] T1: Read the `indexes:` metadata into an ordered name→title table with
      the first name the default, in `core.lua` beside the other constants
      and called from `index.lua`'s `Pandoc`; report a declaration that is
      malformed, empty, or repeats a name. A document with no `indexes:` key
      yields the one unnamed index titled `Index`, exactly today's behavior.
- [x] T2: Read `index=` on a mark in all four Span passes
      (`passes.lua:42,83,163,318`) and on the marker div in `marker.lua`;
      report a value naming no declared index and file the mark in the
      default index.
- [x] T3: Key the format-neutral accumulators per index — `marked_paths`,
      `pending_xrefs` and `clamped_paths` in `marks.lua`, `sort_keys` in
      `sortkeys.lua:21`, and the `pending`/`waiting` maps inside
      `pair_ranges` — one namespace per index rather than one per document,
      with `reset` still emptying every one of them in place.
- [x] T4: Make `resolve_markers` and `place_index` in `marker.lua` per index:
      one surviving marker per index name, the duplicate report naming the
      index it repeats, and `place_index` taking a per-index block map so
      both back-ends still share one placement rule.
- [x] T5: `html.lua`: build one entry tree per index and emit one section
      each in declared order, each minting its section id and entry-id prefix
      from the shared `taken` set so two sections cannot collide.
- [x] T6: `latex.lua`/`index.lua` and `book.lua`: file every named-index mark
      in the default index, emit one report per such mark and per such
      marker, and keep exactly one `\printindex` and one book index.
- [ ] T7: `examples/named-indexes.qmd` and its manifest, covering the
      two-index shape, the cross-index `see=`, the cross-index sort key, the
      cross-index range pair and the three markers — plus one shape this
      milestone leaves untouched: a single-index document with no `indexes:`
      block whose captured output must not change.
- [ ] T8: The checks for AC1–AC5 in `tests/run-tests.sh` and
      `tests/htmlindex.py`, each reading a captured artifact rather than the
      working tree.
- [ ] T9: Self-test entries planting one defect per clause of each reader T8
      adds, each shown red.
- [ ] T10: README's new section under `## Syntax`, the DESIGN convention line
      naming the per-index scoping rule, and the ROADMAP row edits.

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

## Review
