# M078: A recovered locator lands on the id its author wrote

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — it changes where an author's index link lands in a rendered book
- **Branch/PR:** `m078-recovered-locator-author-id` / https://github.com/jmgirard/quarto-index/pull/78

## Goal

In an HTML book, a mark recovered from a chapter's source carries the Pandoc
identifier its author wrote on it, so the index links to that passage rather
than to the top of the chapter's page.

## Scope

**In:** `recovered_marks` carries a body mark's author-written `span.identifier`
as its `anchor`, so `mark_target` builds `<chapter>.html#<their id>`. The
identifier is taken only where the mark contributes a locator, and only from
the blocks walk. A recovered mark with no author id is unchanged: the page,
no fragment. A front-matter mark is unchanged whether or not it carries an
id — the page, no fragment — so the record and recovery routes keep filing
the one identical row (D-048). A D-entry supersedes D-041's no-fragment
clause; the docs and `CHANGELOG.md` follow.

**Out:**

- A fragment for a recovered mark whose author wrote no id. The anchor is
  minted against ids taken across the whole rendered page, which the source
  cannot know — this is why the candidate row narrowed to the author's own id,
  and it stays refused.
- An author id that collides with a minted `qi-mark-<n>` on the same page.
  `tests/fragments.py` checks a fragment's presence, not its uniqueness, so
  this needs an instrument it does not have, and it is a record-route defect
  first → candidate row.
- A recovered range's pairing verdict, and a recovered `mention=` role
  (D-009, D-021) → the existing locator-control candidate rows.
- Where a recovered locator points for a chapter declaring its own
  `output-file:` (KI216) → its own candidate row, untouched.
- A mark written in a chapter's `title:` (KI235) → its own candidate row.

## Acceptance criteria

- [x] AC1: In the HTML book render where `four.qmd`'s record is unusable and
      its marks are recovered from its source, the whole recovered `gamma`
      index section is asserted row by row in href form, and every row for a
      locator-contributing `four.qmd` body mark carries
      `four.html#<the Pandoc identifier that mark's author wrote>` where that
      mark carries one, and `four.html` with no fragment where it carries none.
- [x] AC2: In that render, a recovered `four.qmd` cross-reference mark
      carrying an author-written identifier contributes no locator — its row
      prints its see/see-also line and no page.
- [x] AC3: `tests/fragments.py resolve` over that render's index page exits 0
      — every fragment any locator on the page carries, the recovered rows'
      among them, names an id the page it names actually carries.
- [x] AC4: In that render, a `four.qmd` front-matter `abstract:` mark carrying
      an author-written identifier, on a term no other chapter of the fixture
      indexes, prints one locator — `four.html`, no fragment — identical to
      the row that same mark prints when `four.qmd` is read from its record;
      a second front-matter mark carrying no identifier prints the same shape.
- [x] AC5: A chapter in a subdirectory recovered from its source, whose body
      mark carries an author-written identifier, prints a locator whose href
      is that chapter's page under its directory followed by that identifier.
- [x] AC6: `site/books.qmd`, `cairn/DESIGN.md`, and a new `## Unreleased`
      entry in `CHANGELOG.md` each state that a recovered locator carries the
      identifier the mark's author wrote where they wrote one and the
      chapter's page alone otherwise. `site/books.qmd`'s list of what recovery
      does not return, its count sentence, and its sentence that both ends of
      a range print the one page are amended to match; no shipped release
      section of `CHANGELOG.md` is edited.
- [x] AC7: `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T1, T3, T4
- AC2 → T1, T3, T4
- AC3 → T3, T4
- AC4 → T1, T3, T4
- AC5 → T2, T3, T4
- AC6 → T6, T7
- AC7 → T3, T4, T5

## Tasks

- [x] T1: Author the fixture forms in `examples/book-placement/four.qmd`, each
      on a term no other chapter of that fixture indexes: a body mark with an
      author id; a body mark without one (control); a cross-reference mark
      with an id; a heading mark with an id (relocated after the heading on
      the render route, `html.lua:520-551`); a `range=` pair with an id on
      each end; a second `range=` pair with an id on the open end only; a
      `mention="principal"` mark with an id; and YAML front matter carrying an
      `abstract:` mark with an id and one without. Mirror the forms
      `examples/placement.qmd:36-48` already exercises on the record route.
- [x] T2: Give the subdirectory chapter a body mark carrying an author id, in
      the nested-chapter fixture M068's legs recover (`examples/book`'s
      `sub/two.qmd`), so the nested href path is exercised with a fragment.
- [x] T3: Carry the identifier in `recovered_marks`'s `collect`
      (`_extensions/index/modules/book.lua:731-790`): capture `span.identifier`
      where non-empty, gated on `#surviving == 0` so a cross-reference mark
      still contributes no locator through `html.lua:184`, and only from the
      blocks walk (`book.lua:823-824`), never the metadata walk, so D-048's
      front-matter rule stands on both routes. No `STORE_VERSION` bump —
      `anchor` is already a validated record field (`book.lua:415`).
- [x] T4: Rebaseline the recovered-section manifests the change moves —
      `M065_GAMMA_ROWS` (`tests/run-tests.sh:9281`) and its `_FLAT` and
      `_NOSORT` variants — and add per-term assertions for the
      cross-reference, mixed-range, principal, front-matter and subdirectory
      legs with `check_entry_locators` (`tests/run-tests.sh:1374`). Find every
      other manifest the change moves by running the suite, not by listing
      them here.
- [x] T5: Self-test plants, each shown red against its own mutant: one
      dropping the recovered identifier, one carrying a front-matter
      identifier into its locator, and one removing the `#surviving == 0`
      gate so a cross-reference mark contributes a locator.
- [x] T6: Append the D-entry superseding D-041's no-fragment clause and
      leaving D-048's front-matter rule standing; narrow KI205's remainder and
      update the recovery prose at `cairn/DESIGN.md:481-487`.
- [x] T7: Docs: `site/books.qmd`'s "No fragment" item, its count sentence and
      its range sentence (`site/books.qmd:126-129`, `:148-153`); the
      unqualified promise at `site/html.qmd:20`; and a new `## Unreleased`
      entry in `CHANGELOG.md`.

## Work log

- 2026-09-05: created by /milestone-plan.
- 2026-09-05: implement started on `m078-recovered-locator-author-id`; question gate skipped — the plan gate settled the four open choices (which id form to carry, two rows for a recovered range, leaving `tests/fragments.py` alone, the probe matrix), and nothing else was open.
- 2026-09-05: checkpoint, T1/T2/T3 written and unverified — the suite run that rebaselines T4's manifests had not finished when the turn ended, so no task is checked off. `four.qmd` gained front matter with two `abstract:` marks and six body forms carrying author ids; `sub/two.qmd` gained one; `recovered_marks` carries `span.identifier` as `anchor` from the blocks walk only, gated on `#surviving == 0`, with `page_locator` kept beside it.
- 2026-09-05: T4 rebaselined the manifests the change moves, found by running the suite: the five identical `PLACE_TERMS*` term lists and `M063_TERMS_REFUSED` gained the eight new gamma terms; `M065_GAMMA_ROWS`, `M069_GAMMA_ROWS_COLD` and the `_FLAT`/`_NOSORT` variants gained their rows; `BOOK_HTML_INDEX`, `BOOK_EPUB_INDEX`, `BOOK_PDF_TERMS` and the three `check_letter_sweep` calls gained `Meridian`; seven count sentences went from eleven entries to nineteen.
- 2026-09-05: T6 amended — the plan's "narrow KI205's remainder" clause does not apply. KI205's remainder is the absent-record gate leaving a chapter that prints nothing with a store one chapter short; the missing fragment on a recovered locator was never recorded as a known issue, being D-041's stated design. D-055 and the DESIGN recovery prose carry T6's substance; no KI is edited.
- 2026-09-05: checkpoint, D-055 and the docs written, `tests/run-tests.sh --self-test` running and unverified. A mid-run edit to `tests/run-tests.sh` cost one suite run, which was stopped rather than trusted: bash reads a script as it executes it.
- 2026-09-05: criteria audit ran in FULL mode (surface tier user-facing) and returned twelve findings. Seven fixed here and reported at the gate: AC1's universal was unsatisfiable over see=/see-also= rows and now covers locator-contributing marks only; its "one mark of each kind" clause was a hand-list and moved to T1; no criterion required superseding D-041, now T6; AC2 as drafted passed identically before and after the change and was rewritten; AC3 was underdetermined on field, term and page and now names abstract: and a term marked nowhere else; AC4 was half-true before any work and pointed at shipped release sections, now a new Unreleased entry; the --self-test half of the suite criterion binds the harness and its plants moved to T5. Three routed to the gate as questions. Two recorded and not acted on: proportionality clean throughout, and IP1/IP3/GP5 untouched since an author-written Pandoc id is already honored on the record route.
- 2026-09-05: plan gate chose carrying the author's Pandoc `{#id}` over adding an `id=` mark attribute because the identifier is already read and kept on the record route (`html.lua:582`) and a new attribute would be a syntax form expressing nothing the existing mechanism cannot (GP5, IP3); falsified by an author needing an index anchor on a mark whose id is already claimed by another consumer.
- 2026-09-05: plan gate chose two rows for a recovered range whose ends both carry ids over collapsing them to one or refusing ids on range marks, because a recovered mark already indexes as though `range=` were absent and the record route prints two locators for two marks of one term; falsified by an author reporting a recovered range printing twice is a defect.
- 2026-09-05: plan gate chose leaving `tests/fragments.py` alone over adding a resolve mode scoped to one chapter's rows, because AC1's manifest pins each recovered row's href byte for byte and a scoped mode widens an in-repo checker; falsified by a wrong fragment passing the manifest.
- 2026-09-05: plan gate chose the core probe matrix plus the axes whose code path differs — nested href, mixed range, principal — over the core alone and over adding hostile ids, because an id colliding with a minted anchor needs an instrument the repo lacks; falsified by a defect reached through an id form the matrix omits.
- 2026-09-05: the first `--self-test` run found `m064_hide_all_marks` refusing four.qmd: the helper wraps the body below the chapter's `# ` heading and leaves YAML front matter outside it, so the two `abstract:` marks T1 adds would have stayed reachable and the case they stand in — a source that parses and reaches no mark — would have been about nothing. The helper now removes the front-matter block as well, and reports how many marks went with it.
- 2026-09-05: the M065-AC4 self-test asserted an invariance the author ids take away: the carryrange plant carries `range=` into a recovered mark and re-derives the pairing, and with both ends of a range on one destination the section it printed was identical to the unmutated one. A range whose ends carry ids has two destinations, so the pairing is now visible. The plant keeps its mutation and gains a manifest of its own, `M065_GAMMA_ROWS_PAIRED`, in which each id-bearing range folds to its opening locator while `Ingot`, whose ends carry no id, prints one locator either way.
- 2026-09-05: the docs-claim registry `site/books.qmd` is held to follows T7's rewording: the count claim goes from five to four, the `no fragment` claim is replaced by two — one that an author's id comes back and one that a term with no id gets the page alone — and the range claim takes its new wording.
- 2026-09-05: `recovered_marks` takes the walk flag as `collect`'s own argument passed by two thin wrappers, rather than as a flag one walk sets for the other. M070's walk-order plant swaps the two walk lines, and a statement between them broke its substitution; with the wrappers the lines stay adjacent, the plant swaps them and keeps planting only the sort-key precedence defect it is about.
- 2026-09-05: `tests/run-tests.sh --self-test` exited 0 with the three T5 plants each red against its own mutant and the gamma section's fragment sweep covering 9 locators where it covered 3. Added after it: AC5's own assertion on both M068 nested legs — `Meridian` at `sub/two.html#meridian-passage`, which `Beacon` beside it cannot show, carrying no id — and three pass lines whose prose still said every recovered locator carries no fragment.
- 2026-09-05: both `tests/run-tests.sh` and `tests/run-tests.sh --self-test` exited 0 at 2e7a085. AC3 then gained the instrument it names: `tests/fragments.py resolve` over five.html on both blocked renders, which sweeps every generated section on the page rather than the one section `check_locator_fragments` beside it names.
- 2026-09-05: `--self-test` exited 0 at 9ad1b0c, with `fragments.py resolve` reporting on both blocked renders that every fragment among five.html's 17 locators across 1 section names an id the page it links to carries (9 fragments, 4 pages read). The run before it failed on a Quarto segmentation fault in M074-AC3's render, which did not recur.
- 2026-09-05: review — the plain suite needed four attempts to exit 0, three runs dying on a Quarto/Deno segfault in a different render each time (M38-AC1, M04-AC5, M17-AC3) and one `--self-test` run at M41/M40-AC1; five distinct renders across four runs, none a fixture this milestone touches. Both modes green at 416658f.
- 2026-09-05: step-7 approval: PR #78 approved for merge, with findings 1, 2 and 4-8 fixed on the branch first.
- 2026-09-05: every task done. `tests/run-tests.sh` exits 0 (770 ok lines) and `tests/run-tests.sh --self-test` exits 0; status to review.

## Decisions

## Review

- AC1 (verified 2026-09-05): the green `--self-test` run's
  `M065-AC1/AC2/AC3/AC4 (render one)` and `(render two)` each report
  "1 generated index section(s) and all 37 manifest rows match, in order"
  over `M065_GAMMA_ROWS`, which pins the whole recovered gamma section in
  href form: `Keystone four.html#keystone-passage`,
  `Mullion four.html#mullion-passage`, `Purlin four.html#purlin-passage`,
  `Newel four.html#newel-opens four.html#newel-closes`,
  `Oriel four.html#oriel-opens four.html`, and `Dovetail`, `Quoin`,
  `Rafter` each `four.html` with no fragment.
- AC2 (verified 2026-09-05): the same 37-row match pins
  `Lintel		see-link Escutcheon` — a see-line and no page. Read directly out
  of the render as well: in `place-blocked-one/_book/five.html` and
  `place-blocked-two/_book/five.html` the `Lintel` item carries the single
  href `#qi-entry-3` (its see-link into the index) and no locator, identical
  to the record route's `place-warm`.
- AC3 (verified 2026-09-05): `tests/fragments.py resolve` over the index page
  of each blocked render exits 0 — "five.html: every fragment among its 17
  locator(s) across 1 section(s) names an id the page it links to carries
  (9 fragment(s), 4 page(s) read)", on render one and render two alike.
- AC4 (verified 2026-09-05): read out of the captures of the same run rather
  than from a manifest, the suite pinning the record route's `Quoin` by
  page/section/term only. In `place-warm/_book/five.html` — four.qmd read
  from its record — the `Quoin` item is "Quoin, 1" carrying the single href
  `four.html`; in `place-blocked-one` and `place-blocked-two` it is the
  identical item, same text and same lone href. `Rafter`, the front-matter
  mark carrying no identifier, is `four.html` on all three. `Quoin` is marked
  in no other chapter of the fixture.
- AC5 (verified 2026-09-05): on both M068 nested legs — the unlistable store
  directory and the unopenable record one level down — "the term the
  subdirectory chapter marks with an id of its author's own points at that
  chapter's page under its directory, followed by that id: the entry
  'Meridian' links to <<sub/two.html#meridian-passage>>".
- AC6 (verified 2026-09-05): `git diff main..HEAD` over the three surfaces.
  `CHANGELOG.md` gains an entry under `## Unreleased` → `### Output` stating
  the author-id rule, the no-id fallback and both exceptions; the diff over
  that file deletes zero lines, so no shipped release section is edited.
  `cairn/DESIGN.md:478-496` states the rule and its blocks-walk restriction.
  `site/books.qmd` states it in the "what comes back" paragraph, drops the
  "No fragment" item, and its count sentence reads "Four things recovery does
  not return" over a list that now holds exactly four items; the range
  sentence reads "both ends of a range print that chapter's page, each at the
  id you wrote on it where you wrote one".

- AC7 (verified 2026-09-05): `tests/run-tests.sh --self-test` exits 0 —
  "All checks passed (1409 checks)", the three T5 plants each red against its
  own mutant. `tests/run-tests.sh` exits 0 — "All checks passed (769
  checks)", 770 `ok` lines. Both greens are on 416658f with only the review's
  own tracking commits since. Reached on the fourth plain attempt: three
  earlier runs exited 1 without any assertion failing, each on a Quarto/Deno
  `Segmentation fault: 11` (exit 139) in a DIFFERENT render — `M38-AC1`
  (named-indexes-twin to HTML), `M04-AC5` (the marker fixture to beamer) and
  `M17-AC3` (the inst book to HTML) — and one `--self-test` run died the same
  way at `M41`/`M40-AC1`. Five distinct renders across four runs, none of
  them a fixture this milestone touches, and the same crash is recorded
  mid-implementation against a sixth (`M074-AC3`). Attributed to the
  toolchain, not the diff.

- Consistency gate (verified 2026-09-05): `cairn_validate.py` exits 0, all 16
  PASS checks including `coverage complete` and `binding criteria`, and the 7
  advisories OK — `release window` did not fire. No `IP`/`GP` principle line
  appears in `git diff main..HEAD -- cairn/DESIGN.md`, so `cairn_impact` is
  not run. The `generic` profile's `consistency-gate` slot names no toolchain
  checks, so the universal checks are the whole gate.

### Independent fresh-context review

Surface tier is user-facing, so the full three-lens fan-out ran, each lens on
its own evidence base and none having seen the implementation.

**[S] blame-history — no regression.** Verified `assign_anchors`
(`html.lua:579-599`) mints only where `span.identifier == ""`, so D-055's
premise that an author id is never renamed holds; verified `from_meta` passes
`in_blocks = false` unconditionally, so D-048 stands whole on both routes;
verified only D-041's no-fragment clause is superseded and D-042/D-045/D-046
are untouched. Its one flagged item is the id-collision risk, which D-055's
own Consequences already records as accepted and unfenced.

**[S] prior-PR-comments — no prior-review evidence contradicted.** The probe
`gh api repos/jmgirard/quarto-index/pulls/comments?per_page=1` found no real
inline review threads, so the GitHub walk was skipped as the lens prescribes;
the archived `## Review` sections were the evidence base. Confirmed KI235 and
KI216 stay out of scope as their prior triage left them, M064's
duplicate-locator fix is untouched (only its comment moved), and the
"Five things" -> "Four things" count moved in the same diff as the bullet it
counts, which is the M073/M38 stale-enumeration lesson kept.

**[O] diff-bug — the Lua change correct, eleven peripheral findings.** It
verified the new gate matches the record route's own gate at
`passes.lua:622` (whose `xrefs` is post-self-target-drop exactly as
`surviving` is), and that `html.lua`'s diff is comments only. Findings, as
ranked by the lens:

1. `book.lua:1158`, `:1642`, `:1666` — all three recovery warnings still tell
   the author the recovered terms "are in the index without the links into
   its page that a record carries", false for every mark whose author wrote
   an id. Pinned in `tests/run-tests.sh:9002,9228`.
2. `site/books.qmd:167` — "with the same limits every recovered chapter
   carries, the missing fragment among them" survives AC6's rewrite and says
   the opposite of the page above it. Not held by the docs-claim registry.
3. AC4's identity half is pinned by no href-form assertion on the record
   route; every `Quoin four.html` manifest row is a recovery-route one.
4. `tests/run-tests.sh:7975` — pass line says "all eleven of its entries"
   where the manifest holds nineteen.
5. `tests/run-tests.sh:7768`, `:7786` — the AC1 manifest's header comment
   says "six forms" (now fourteen) and "three anchored hrefs" (now nine).
6. `tests/run-tests.sh:6890-6891`, `:9010`, `:9092-9094`, `:9322`, `:9784`,
   `:9806` — six more "eleven"/"eight" counts; `:9784` and `:9806` are
   `check_index_sections` labels, so the wrong number prints on failure.
7. `tests/run-tests.sh:1374-1376` — `check_entry_locators`'s header comment
   still says a recovered mark "has no anchor".
8. `cairn/DECISIONS.md:302` — D-041's Consequences "The store stays the
   primary route and the only one carrying anchors" is falsified and unnamed
   by D-055, which supersedes a clause of the Decision paragraph only.
9. `book.lua:820-828` — the walk wrappers' comment justifies a production
   shape by the self-test's `sed` mechanics.
10. `four.qmd:73` — `Mullion`, `Hasp`, `Ingot`, `Ferrule` now name marks in
    two fixtures; no check crosses them.
11. (uncertain) nothing on the recovery leg asserts `mullion-passage` sits
    outside four.html's heading; `fragments.py outside` was available.

Findings 1, 2, 4, 5, 6, 7 and 8 were confirmed by hand at review before being
brought to the gate. Finding 3 was closed at review by reading the record
route's own render (AC4's evidence line above) rather than by a manifest.

### Triage

Put to the maintainer at the step-7 gate, which chose "fix findings 1, 2 and
4-8 on the branch, re-run both suite modes, then merge".

- Finding 1 — FIXED NOW. The clause "without the links into its page that a
  record carries" becomes "with links into its page only where a mark's
  author wrote an id of their own", in all six copies: `book.lua:1158`,
  `:1642`, `:1666` and the three that pin them,
  `tests/run-tests.sh` `M068_RECOVERED_FOUR`, `M068_RECOVERED_SUBTWO` and
  `M074_INLINE_DRAW` (whose copy takes `\x27` for the apostrophe, the literal
  being a single-quoted shell string — a `bash -n` caught it).
- Finding 2 — FIXED NOW. The clause ", the missing fragment among them" is
  struck from `site/books.qmd`; the paragraph now ends "with the same limits
  every recovered chapter carries."
- Finding 3 — CLOSED AT REVIEW, no code change. The gap was in evidence, not
  behavior; AC4's evidence line above records the record route's own render
  read directly. The suite still pins the record route's `Quoin` by
  page/section/term only → candidate row.
- Findings 4, 5, 6 — FIXED NOW, against the manifest rather than recall.
  `M065_GAMMA_ROWS` holds 37 rows: one section row, 17 letter rows and 19
  entry rows, 16 of the entries four.qmd's, and 9 hrefs carrying a fragment —
  3 minted `#qi-mark-N` out of records and 6 ids four.qmd's author wrote.
  Corrected: the "eleven entries" at `:6890` and in the M064-AC3 pass line;
  "four.qmd's eight terms" at `:9010`, `:9092`, `:9322` and in the two
  `check_index_sections` labels at `:9784` and `:9806`; "the six forms
  four.qmd writes" and "the three anchored hrefs" in the AC1 manifest header.
  `:9092`'s "each of the eight linking to four.html with no fragment" was
  wrong twice over and now states the author-id case too.
- Also fixed, found while fixing 5 and of the same class: the M064-AC2 header
  comment said "where the gamma section's four locators point" and "the other
  three came out of records".
- Finding 7 — FIXED NOW. `check_entry_locators`'s header comment now says a
  recovered mark carries an anchor only where its author wrote an id.
- Finding 8 — FIXED NOW. D-055's Consequences names D-041's Consequences
  sentence: the store stays the primary route and is no longer the only route
  carrying an anchor.
- Finding 9 — REJECTED. The wrappers are clearer than the flag they replace
  and the comment states a real constraint on the two walk lines; the
  milestone's plan called the shape and a rationale mentioning the plant is
  not a defect in it.
- Finding 10 — REJECTED. Out-of-scope taxonomy: no check crosses the two
  fixtures, and `Mullion`/`Hasp`/`Ingot`/`Ferrule` naming marks in both
  `book-placement` and `book-front` predates this diff for three of the four.
- Finding 11 — FOLLOW-UP. `fragments.py outside` is not used on the recovery
  leg's heading mark, so a regression in `relocate_heading_anchors` would let
  `mullion-passage` resolve to a copy inside the heading. The relocation is
  separately fenced, so this is overlap rather than a hole → candidate row.

No finding met the return floor: none demonstrated an acceptance criterion
failing, and the maintainer took finding 1 as fix-now rather than as a
load-bearing defect. Status stays `review`.

### Re-verification after the actioned fixes

Both modes re-run at 43568b8, each green on its first attempt and no segfault
in either: `tests/run-tests.sh` "All checks passed (769 checks)" and
`tests/run-tests.sh --self-test` "All checks passed (1409 checks)", both
exit 0. This is the run that matters for finding 1 — the reworded warning is
pinned by `M068_RECOVERED_FOUR`, `M068_RECOVERED_SUBTWO` and the M074
mutation's own `M074_INLINE_DRAW` literal, and all three report checks pass
against the new text. `cairn_validate.py` re-run over the completed branch:
exit 0, 16/16 PASS.

