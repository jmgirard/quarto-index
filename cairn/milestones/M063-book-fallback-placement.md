# M063: A book puts an index no marker names in the same chapter on every render

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** `m063-book-fallback-placement`

## Goal

An HTML book builds the section for an index no placement marker names in the book's
last chapter, so no render can print that section in two chapters or in none.

## Scope

User-facing tier: the deliverable is which chapter of a rendered book carries an index
section. IP3 is worked under rather than changed — D-037 narrows it to "syntax forms
rather than printed defaults", which is what licenses moving a printed default after
the 0.1.0 release.

**In:**

- The placement rule for an index no marker names becomes the book's last chapter,
  provided some chapter of the book places an index. It stops being computed from the
  sidecar store's picture of which chapter placed the last index
  (`_extensions/index/modules/book.lua:958-984`), which each chapter derives from a
  different mixture of this render's and the previous render's records and so
  disagrees about within one render — KI199's mechanism.
- The unplaced-section report (`book.lua:1040`) and the doubled-section report
  (`book.lua:1067`) are retired with the state they read: `record.unseen`,
  `record.adopted`, the `later` gate, `store_read`'s unseen pass and `valid_record`'s
  two-field validation. Under the new rule the book's last chapter always adopts and
  always has an empty `unseen`, so neither report can fire. `STORE_VERSION` does not
  move: a record carrying the two retired fields stays valid and keeps its chapter's
  terms (the M14 lesson).
- A `cairn/DECISIONS.md` entry superseding M55's gate choice ("an index no marker
  names goes to the last chapter that places one, not the book's last chapter").

**Out:**

- Recovering the terms of a chapter whose record can never be written, which the new
  rule leaves out of a section it now prints → KI205 is rewritten to that narrower
  complaint and a new `candidate` ROADMAP row carries the work.
- Pruning records for chapters no longer in the book, the declared-key map's order,
  and a page outside `book.render` → the standing book sidecar-store candidate row.
- KI206 and KI207, M061's two check gaps → they stay known issues.

## Acceptance criteria

- [ ] AC1. Over a scratch copy of `examples/book-placement/` whose `four.qmd` has
      gained a `gamma` placement marker between renders — KI199's own case, which today
      prints two `gamma` sections — the whole-book HTML render made immediately after
      matches the section manifest naming `four.html` as the one page carrying a `gamma`
      section, and the whole-book render after that matches the same manifest. The
      manifest is compared by the sweep that walks every `.html` under the book's output
      directory (`check_book_sections`, `tests/run-tests.sh:6282`), so a section on any
      other page fails it. Both renders exit 0. Shown red against a copy of the tree
      whose only change restores the superseded rule.
- [ ] AC2. From an empty store, the whole-book HTML render of
      `examples/book-placement/` matches the section manifest naming `five.html` as the
      page carrying `gamma`, `index.html` `alpha` and `three.html` `beta` — each marked
      index in the chapter carrying the first marker that names it — and the whole-book
      render after that matches the same manifest, so the two renders no longer differ.
      Both exit 0, and neither draws the retired reports, whose message keys no longer
      match any warning the filter emits. Shown red against the same restored-rule copy.
- [ ] AC3. Where the store path `examples/book-placement/`'s `four.qmd` record would
      occupy is held by a directory, so that record can never be written, two consecutive
      whole-book HTML renders each match AC2's manifest — the `gamma` section is printed
      rather than lost — and each draws the write-failure report for `four.qmd` once and
      the unreadable-record report for `four.qmd` once per index section that record
      costs (M062's rule). The raw count of the render's warning lines is asserted
      beside the by-kind counts, KI206's escape making the anchored patterns miss one.
- [ ] AC4. Two consecutive whole-book HTML renders of `examples/book-nomarker/`, whose
      chapters carry index marks but no placement marker, match a section manifest whose
      every row is bare: a book that places no index grows no section in its last chapter
      either. Shown red against a copy of the tree whose only change drops the
      "some chapter places an index" proviso.
- [ ] AC5. Two consecutive whole-book HTML renders of `examples/book/`, whose two
      markers both sit in `last.qmd` and which is therefore its own fallback chapter,
      match the section manifest M05 and M55 pinned for it, `places` included.
- [ ] AC6. `site/books.qmd`, `site/placing-the-index.qmd` and `CHANGELOG.md` state
      which chapter of a book carries an index no marker names, written against a render
      AC1-AC5 captured; every sentence stating the superseded rule is corrected, and the
      pinned claim rows for the two site pages with them. Each page's new claim is shown
      red against a copy of that page whose claim names the superseded chapter rule
      rather than being absent.
- [ ] AC7. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit 0.

## Coverage

- AC1 → T1, T4, T5
- AC2 → T1, T4, T6
- AC3 → T1, T4, T7
- AC4 → T1, T8
- AC5 → T8
- AC6 → T9
- AC7 → T1, T2, T3, T4, T5, T6, T7, T8, T9, T10

## Tasks

- [ ] T1. `html_book` builds an index no marker names in the book's last chapter,
      gated on some chapter of the book placing one; the `ctx.position == last`
      adoption branch (`_extensions/index/modules/book.lua:973-984`) goes.
      (RB tripwire: ip-touching)
- [ ] T2. `record.unseen`, `record.adopted`, the `later` gate, `store_read`'s unseen
      pass (`book.lua:500-546`) and `valid_record`'s two-field loop (`book.lua:268`)
      are retired; `STORE_VERSION` is unchanged and a record still carrying either
      field keeps its chapter's terms.
- [ ] T3. The unplaced-section and doubled-section reports are deleted with their
      `WARN_DEFER`/`WARN_DOUBLED` keys (`tests/run-tests.sh:872,875`) and their rows in
      the report-key scan (`tests/run-tests.sh:3596`); the filter's pinned warning count
      is re-derived by hand and the arithmetic shown.
- [ ] T4. Every `examples/book-placement/` manifest and warning count is re-derived by
      hand and shown: `PLACE_SECTIONS_FIRST` and `PLACE_SECTIONS_SECOND` become one
      manifest, `PLACE_SECTIONS_DOUBLED` goes, `PLACE_SECTIONS_MARKED` becomes AC1's,
      and the stale oracle comment at `tests/run-tests.sh:6331` is corrected to the
      four indexes the fixture declares.
- [ ] T5. AC1's check: the marker appended to `four.qmd` over a copied tree, both
      renders held to the manifest, shown red against a one-substitution mutant
      restoring "the last chapter that places one".
- [ ] T6. AC2's check: both renders from an empty store held to one manifest, shown red
      against the same mutant, and the retired keys shown matching no live warning.
- [ ] T7. AC3's check: the held store path, both renders held to the manifest, the two
      report kinds counted by kind and the raw warning-line count asserted beside them.
- [ ] T8. AC4's and AC5's checks: `examples/book-nomarker/` held to an all-bare
      manifest and shown red against a mutant dropping the proviso; `examples/book/`
      held to its pinned manifest across two renders.
- [ ] T9. `site/books.qmd:40,47-56`, `site/placing-the-index.qmd:37` and
      `CHANGELOG.md:133-137` state the new rule and lose the superseded sentences; the
      pinned claim rows (`tests/run-tests.sh:19066-19079`) move with them, and each page
      is shown red against a copy whose claim states the superseded rule.
- [ ] T10. `cairn/DESIGN.md`: KI199 struck, KI205 rewritten to the section that prints
      short an unwritable chapter's terms, the book paragraph's report count and its
      account of what a chapter records corrected; a `cairn/DECISIONS.md` entry
      supersedes M55's placement choice; a `candidate` ROADMAP row carries KI205's
      remainder.

## Work log

- 2026-08-30: created by /milestone-plan.
- 2026-08-30: criteria audit ran in FULL mode (user-facing tier), fresh-context [O] reader, on the drafted M063 criteria. Returned 14 findings and 4 factual corrections; 13 fixed at the gate (AC1 unsatisfiable — a marker-named index prints at its marker, not at the fallback chapter; three promises restated as whole-book section manifests compared by the sweep that enumerates the pages; AC2's wrong account of why `beta` prints in `three.html`; AC3's two report kinds named separately with the raw line count beside them; shown-red controls added for the rule and for the proviso; the instrument-bound AC5 deleted and its warning enumeration folded into AC3; `CHANGELOG.md` dropped from the claims-file clause; AC6's control changed from an absent claim to one stating the superseded rule; AC6 made to require the superseded sentences corrected; an `examples/book/` regression leg added as AC5). One posed as a gate question (the fate of the two reports the new rule makes unreachable).
- 2026-08-30: plan gate chose the book's last chapter over reading later chapters' `.qmd` source for a marker and over a per-render store snapshot, because the last chapter is `ctx.chapters[#ctx.chapters]` in every chapter's process and so cannot be disagreed about, where a source read recognizes a marker by text and is blind to one arriving via an include or an executable cell and a snapshot adds a store artifact and a one-render lag; falsified by a book whose last chapter is a place an author will not accept an index section in.
- 2026-08-30: plan gate chose retiring the unplaced-section and doubled-section reports outright over keeping them as guards for a partial-render path, because neither can fire once the last chapter always adopts and a check over a report nothing reaches is vacuous (the M38 lesson); falsified by a render path reaching either report with the new rule in place.
- 2026-08-30: plan gate chose leaving the terms of an unwritable chapter's record out of scope over recovering them here, because reaching them needs a route that does not go through the sidecar store at all; falsified by the store gaining a second read path for a reason of its own.
- 2026-08-30: /milestone-implement opened; branch `m063-book-fallback-placement` cut from main.

## Decisions

## Review
