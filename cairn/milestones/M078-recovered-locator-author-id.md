# M078: A recovered locator lands on the id its author wrote

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — it changes where an author's index link lands in a rendered book
- **Branch/PR:** `m078-recovered-locator-author-id`

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

- [ ] AC1: In the HTML book render where `four.qmd`'s record is unusable and
      its marks are recovered from its source, the whole recovered `gamma`
      index section is asserted row by row in href form, and every row for a
      locator-contributing `four.qmd` body mark carries
      `four.html#<the Pandoc identifier that mark's author wrote>` where that
      mark carries one, and `four.html` with no fragment where it carries none.
- [ ] AC2: In that render, a recovered `four.qmd` cross-reference mark
      carrying an author-written identifier contributes no locator — its row
      prints its see/see-also line and no page.
- [ ] AC3: `tests/fragments.py resolve` over that render's index page exits 0
      — every fragment any locator on the page carries, the recovered rows'
      among them, names an id the page it names actually carries.
- [ ] AC4: In that render, a `four.qmd` front-matter `abstract:` mark carrying
      an author-written identifier, on a term no other chapter of the fixture
      indexes, prints one locator — `four.html`, no fragment — identical to
      the row that same mark prints when `four.qmd` is read from its record;
      a second front-matter mark carrying no identifier prints the same shape.
- [ ] AC5: A chapter in a subdirectory recovered from its source, whose body
      mark carries an author-written identifier, prints a locator whose href
      is that chapter's page under its directory followed by that identifier.
- [ ] AC6: `site/books.qmd`, `cairn/DESIGN.md`, and a new `## Unreleased`
      entry in `CHANGELOG.md` each state that a recovered locator carries the
      identifier the mark's author wrote where they wrote one and the
      chapter's page alone otherwise. `site/books.qmd`'s list of what recovery
      does not return, its count sentence, and its sentence that both ends of
      a range print the one page are amended to match; no shipped release
      section of `CHANGELOG.md` is edited.
- [ ] AC7: `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
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

- [ ] T1: Author the fixture forms in `examples/book-placement/four.qmd`, each
      on a term no other chapter of that fixture indexes: a body mark with an
      author id; a body mark without one (control); a cross-reference mark
      with an id; a heading mark with an id (relocated after the heading on
      the render route, `html.lua:520-551`); a `range=` pair with an id on
      each end; a second `range=` pair with an id on the open end only; a
      `mention="principal"` mark with an id; and YAML front matter carrying an
      `abstract:` mark with an id and one without. Mirror the forms
      `examples/placement.qmd:36-48` already exercises on the record route.
- [ ] T2: Give the subdirectory chapter a body mark carrying an author id, in
      the nested-chapter fixture M068's legs recover (`examples/book`'s
      `sub/two.qmd`), so the nested href path is exercised with a fragment.
- [ ] T3: Carry the identifier in `recovered_marks`'s `collect`
      (`_extensions/index/modules/book.lua:731-790`): capture `span.identifier`
      where non-empty, gated on `#surviving == 0` so a cross-reference mark
      still contributes no locator through `html.lua:184`, and only from the
      blocks walk (`book.lua:823-824`), never the metadata walk, so D-048's
      front-matter rule stands on both routes. No `STORE_VERSION` bump —
      `anchor` is already a validated record field (`book.lua:415`).
- [ ] T4: Rebaseline the recovered-section manifests the change moves —
      `M065_GAMMA_ROWS` (`tests/run-tests.sh:9281`) and its `_FLAT` and
      `_NOSORT` variants — and add per-term assertions for the
      cross-reference, mixed-range, principal, front-matter and subdirectory
      legs with `check_entry_locators` (`tests/run-tests.sh:1374`). Find every
      other manifest the change moves by running the suite, not by listing
      them here.
- [ ] T5: Self-test plants, each shown red against its own mutant: one
      dropping the recovered identifier, one carrying a front-matter
      identifier into its locator, and one removing the `#surviving == 0`
      gate so a cross-reference mark contributes a locator.
- [ ] T6: Append the D-entry superseding D-041's no-fragment clause and
      leaving D-048's front-matter rule standing; narrow KI205's remainder and
      update the recovery prose at `cairn/DESIGN.md:481-487`.
- [ ] T7: Docs: `site/books.qmd`'s "No fragment" item, its count sentence and
      its range sentence (`site/books.qmd:126-129`, `:148-153`); the
      unqualified promise at `site/html.qmd:20`; and a new `## Unreleased`
      entry in `CHANGELOG.md`.

## Work log

- 2026-09-05: created by /milestone-plan.
- 2026-09-05: implement started on `m078-recovered-locator-author-id`; question gate skipped — the plan gate settled the four open choices (which id form to carry, two rows for a recovered range, leaving `tests/fragments.py` alone, the probe matrix), and nothing else was open.
- 2026-09-05: checkpoint, T1/T2/T3 written and unverified — the suite run that rebaselines T4's manifests had not finished when the turn ended, so no task is checked off. `four.qmd` gained front matter with two `abstract:` marks and six body forms carrying author ids; `sub/two.qmd` gained one; `recovered_marks` carries `span.identifier` as `anchor` from the blocks walk only, gated on `#surviving == 0`, with `page_locator` kept beside it.
- 2026-09-05: criteria audit ran in FULL mode (surface tier user-facing) and returned twelve findings. Seven fixed here and reported at the gate: AC1's universal was unsatisfiable over see=/see-also= rows and now covers locator-contributing marks only; its "one mark of each kind" clause was a hand-list and moved to T1; no criterion required superseding D-041, now T6; AC2 as drafted passed identically before and after the change and was rewritten; AC3 was underdetermined on field, term and page and now names abstract: and a term marked nowhere else; AC4 was half-true before any work and pointed at shipped release sections, now a new Unreleased entry; the --self-test half of the suite criterion binds the harness and its plants moved to T5. Three routed to the gate as questions. Two recorded and not acted on: proportionality clean throughout, and IP1/IP3/GP5 untouched since an author-written Pandoc id is already honored on the record route.
- 2026-09-05: plan gate chose carrying the author's Pandoc `{#id}` over adding an `id=` mark attribute because the identifier is already read and kept on the record route (`html.lua:582`) and a new attribute would be a syntax form expressing nothing the existing mechanism cannot (GP5, IP3); falsified by an author needing an index anchor on a mark whose id is already claimed by another consumer.
- 2026-09-05: plan gate chose two rows for a recovered range whose ends both carry ids over collapsing them to one or refusing ids on range marks, because a recovered mark already indexes as though `range=` were absent and the record route prints two locators for two marks of one term; falsified by an author reporting a recovered range printing twice is a defect.
- 2026-09-05: plan gate chose leaving `tests/fragments.py` alone over adding a resolve mode scoped to one chapter's rows, because AC1's manifest pins each recovered row's href byte for byte and a scoped mode widens an in-repo checker; falsified by a wrong fragment passing the manifest.
- 2026-09-05: plan gate chose the core probe matrix plus the axes whose code path differs — nested href, mixed range, principal — over the core alone and over adding hostile ids, because an id colliding with a minted anchor needs an instrument the repo lacks; falsified by a defect reached through an id form the matrix omits.

## Decisions

## Review
