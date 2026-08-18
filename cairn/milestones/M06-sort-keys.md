# M06: Sort keys

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP4, GP5, GP6
- **Branch/PR:** `m06-sort-keys`

## Goal

An author can give an index term a sort key separate from its printed text,
via a format-neutral `sort=` span attribute honored by the LaTeX back-end, the
HTML back-end, and a book's aggregated HTML index.

## Scope

Surface tier: **user-facing** — the deliverable is new author-visible mark
syntax plus its README documentation, consumed outside the repo.

**In:** a `sort=` span attribute parsed with the level syntax `entry=` uses
(`!` separator, `!!` literal); positional per-level alignment, a level with no
sort key sorting by its own printed text; a warning when `sort=` carries more
levels than the entry has, when it appears on a mark with nothing to index,
and when one printed index key is given two different sort keys (first mark in
document — in a book, book — order wins); makeindex `sortkey@printed`
emission with `@` still quoted everywhere the extension does not write the
separator itself; HTML collation on the sort key while the printed text is
what prints; the sort key carried through the book sidecar record with
`STORE_VERSION` bumped; README, fixtures, and acceptance-suite coverage.

**Out:**
- Alphabet (A/B/C) headings in the HTML index → stays a ROADMAP candidate row;
  its own milestone once this lands.
- Language- or locale-aware collation of accented and non-Latin text → stays
  the existing ROADMAP candidate row; `sort=` is the manual workaround, and
  this milestone claims no automatic collation.
- Sort keys on `see=` / `see-also=` values → not offered. A target is prose
  naming another entry, and that entry carries its own sort key
  (`_extensions/index/index.lua:198-206`).
- Page ranges and locator styling → the existing "Page-range & styling
  control" candidate row.

## Acceptance criteria

- [ ] AC1: Rendering `examples/sortkey.qmd` to PDF produces an index in which
      each term the fixture's manifest names appears at the position its sort
      key dictates, read within the `pdftotext` index region; a boundary term
      names the one neighbour it has. The suite fails unless the manifest
      names every `sort=` occurrence in the fixture, derived from the fixture
      by construction rather than hand-listed. The fixture includes an entry
      whose sort key covers only its second level.
- [ ] AC2: Rendering `examples/sortkey.qmd` to HTML produces a `qi-index`
      section whose entry order **at every level** equals the order its
      manifest states (read structurally by `tests/htmlindex.py`), and that
      order differs from the order the same printed terms take in a
      sort-stripped twin fixture the suite also renders.
- [ ] AC3: For each printable ASCII character `tests/run-tests.sh` derives for
      the `examples/escaping.qmd` domain, a companion fixture places that
      character in a `sort=` value; the suite renders it with the engine the
      PDF build uses and confirms the index tool accepted every entry,
      renders it to HTML and confirms every entry is present in the
      `qi-index` section, and renders it to gfm and confirms the visible text
      passes through with no `sort=` residue (IP2).
- [ ] AC4: Three diagnostics fire with the message text recorded in this
      milestone's Decisions section: (a) `sort=` on a mark with no indexable
      text, (b) a `sort=` value with more levels than the mark's entry has,
      (c) one printed index key given two different sort keys — probed both
      within one document and across two chapters of one book. Each is
      asserted by a suite check proved discriminating by reverting the
      diagnostic and observing the check fail, and each has a control render
      that does not fire it.
- [ ] AC5: A book's aggregated HTML index honors a sort key written in a
      chapter other than the marker's: `examples/book/` gains such a sort key
      and `tests/htmlindex.py` asserts the aggregated index orders that term
      by its sort key rather than its printed text.
- [ ] AC6: README documents `sort=` — syntax, per-level alignment, the
      fallback for a level with no sort key, and the three diagnostics — and
      the suite asserts verbatim one normative sentence per documented
      behavior, following the existing `README_HTML_CLAIMS` precedent. The
      sentence declaring sort keys out of scope (README.md:163-165) is gone,
      asserted absent like `README_STALE`, and the pinned HTML collation
      sentence (README.md:303-305) is updated in `README_HTML_CLAIMS` rather
      than left contradicting what ships.
- [ ] AC7: `tests/run-tests.sh --self-test` clean (the `verify` slot of
      `cairn/PROFILE.md`, plus the planted-defect self-test the pre-review
      check uses), and every `.qmd` fixture the merge base carries at the top
      level of `examples/` emits byte-identical LaTeX — `tests/byte-diff.sh`
      (whose own header declares it review-time evidence, not a suite check)
      reports no difference over the domain it enumerates via `git ls-tree`.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T4, T6
- AC3 → T2, T4, T7
- AC4 → T1, T5, T8
- AC5 → T5, T6
- AC6 → T9
- AC7 → T9

## Tasks

- [x] T1: Parse `sort=` in the Span pass beside `entry=`
      (`index.lua:341`), reusing `parse_levels` (`index.lua:139-159`), and
      align it positionally against the derived levels before the back-end
      branch (`index.lua:399-402`) so both back-ends see one representation.
      A level with no sort key falls back to its printed text. Amended in
      flight: the parse moved into a third filter pass ahead of the emitting
      one — see this file's Decisions.
      *(RB tripwire: ip-touching — IP1 format-neutrality of the new syntax.)*
- [x] T2: LaTeX emission: extend `index_argument` (`index.lua:236-242`) to
      write `sortkey@printed` per level, keeping `LATEX_LITERAL`'s `"@`
      quoting (`index.lua:92`) for every `@` the extension does not itself
      write as the separator.
- [x] T3: `examples/sortkey.qmd` fixture (multi-level entries, a
      second-level-only sort key, terms whose sort order differs from printed
      order) and its sort-stripped twin; PDF check in `tests/run-tests.sh`
      with the manifest derived from the fixture by construction.
- [x] T4: HTML collation: carry the sort key onto the entry-tree node
      (`new_entry`, `index.lua:534-536`; `build_entry_tree`,
      `index.lua:547-580`) without changing node identity — `children` stays
      keyed by printed level text — and compare sort keys in
      `number_entries`' `table.sort` (`index.lua:593`), ties falling through
      to `collate` on the printed text.
- [ ] T5: Book path: add the sort key to the sidecar mark record
      (`index.lua:1056-1057`), accept it in `valid_record`
      (`index.lua:1093-1121`), bump `STORE_VERSION` to 2 (`index.lua:970`);
      add a cross-chapter sort key to `examples/book/` and a cross-chapter
      conflicting-sort-key fixture.
- [x] T6: HTML checks for the sortkey fixture and its twin in
      `tests/htmlindex.py` + `tests/run-tests.sh`, asserting order at every
      level.
- [ ] T7: Extend the escaping probe to `sort=` values across PDF, HTML and
      gfm legs.
- [ ] T8: The three diagnostics, their message text recorded in this file's
      Decisions section, their control renders, and the reversion proof for
      each.
- [ ] T9: README `sort=` section; update `README_HTML_CLAIMS` and add the
      `README_STALE` absence assertion; run `tests/byte-diff.sh` and
      `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-17: created by /milestone-plan.
- 2026-08-17: implementation started on `m06-sort-keys`, cut from main at 6be9f93.
- 2026-08-17: implement gate — user chose to proceed on the `ip-touching` tripwire without escalation, and chose format-neutral scope for the sort-key conflict warning over index-building formats only.
- 2026-08-17: T1 done — `sort=` parsed with `entry=`'s level syntax, aligned per level with printed-text fallback, plus `levels_key`, `sort_levels`, `register_sort`/`sort_for`, `clamp_sort`, and a shared `derive_levels` used by both Span passes.
- 2026-08-17: T1 minor amendment — parse moved into a new `CollectSort` pass ahead of the emitting pass; task text updated, rationale in this file's Decisions.
- 2026-08-17: T6 done — exhaustive HTML manifests 1o/1p for the fixture and its twin, compared in order at every depth, plus a check asserting the two manifests disagree at every position so neither could be satisfied by an index that ignored sort keys. Suite 83 -> 87 checks.
- 2026-08-17: T4 done — the entry-tree node carries a `sort` field, node identity stays keyed on printed text, and `number_entries` collates on the sort key with a printed-text tie-break; the rendered HTML index now matches the PDF order, sub-entry reversal included. All 83 checks still pass.
- 2026-08-17: T3 done — `examples/sortkey.qmd` + its derived twin, manifests 1m/1n, and four PDF checks; the manifest is checked against the fixture by construction and the twin proves the order is the sort keys' doing. Suite 79 -> 83 checks.
- 2026-08-17: T3 discovered sub-task (minor amendment) — `tests/pdfindex.py`: a two-column index interleaves under `pdftotext`/`-layout`, so printed order is read from `-bbox-layout` word positions instead; without it the AC1 check could not tell a sorted index from an unsorted one.
- 2026-08-17: T3 fixture repaired at authoring — the discrimination check found `von Neumann` occupying the same position with and without sort keys; a sixth keyed term (`Édouard Manet`) makes the two orders differ at every top-level position.
- 2026-08-17: T2 done — `index_argument` writes makeindex `sortkey@printed` per level, the separator `@` being the only unquoted one; all 79 existing suite checks pass unchanged.
- 2026-08-17: plan-gate criteria audit ran in **full** mode (user-facing tier), fresh-context [O] reader: 11 findings + 4 coverage gaps returned; all fixed in the criteria before writing (AC1 hand-list proxy, AC1 boundary/region wording, AC2 top-level-only domain, AC3 form-list proxy + LaTeX-only scope + non-printing sort key, AC4 single-document probe axis, the byte-identity criterion's unenumerable domain + misdescribed byte-diff.sh scope, the README criterion's instrument-bound converse claim + README_HTML_CLAIMS reachability conflict; gaps 1-3 folded into AC3/AC1/AC2, gap 4 posed at the gate). Criteria then renumbered when the byte-identity criterion merged into the verify-slot criterion to clear the >7 sizing tripwire; the merged wording was re-asked the audit's questions and passes (both halves name enumerating procedures).
- 2026-08-17: plan gate chose a separate `sort=` span attribute over an inline per-level delimiter inside `entry=` because D-001 forbids raw back-end code in mark values, `@` is a documented literal in `entry=` today (README.md:164), and README.md:164-166 already commits to separate span attributes; falsified by an authoring case per-level alignment cannot express that an inline delimiter can.
- 2026-08-17: plan gate chose breaking a sort-key tie by printed text through the existing collator over warning on the tie because two terms legitimately share one sort key; falsified by evidence that silent tie-breaking produces order a reader reads as nondeterministic.
- 2026-08-17: plan gate chose bumping `STORE_VERSION` to 2 over relying on `valid_record` tolerating an unknown field because a retained v1 record would be read as valid with no sort keys and silently produce a wrongly-ordered book index; falsified by evidence that a stale record cannot survive a version-bumping render.

## Decisions

### Sort keys are collected in a pass of their own, before marks are emitted

**Context:** T1 planned to parse `sort=` in the existing Span pass. That pass
emits `\index{...}` inline at the mark, because the mark's position is what
gives the entry its page. A sort key, though, belongs to the *entry*, not to
the mark: if one mark of "The Hague" carries `sort="Hague"` and another does
not, the two emit different makeindex keys and the term prints twice, in two
places, identically. Requiring `sort=` on every mark of a term would fix that
and contradict GP4.

**Decision:** A third filter pass, `{ Span = CollectSort }`, runs before the
emitting Span pass. It derives each mark's levels with the same code the
emitting pass uses (`derive_levels`, called with reporting off so no warning
fires twice), registers the entry's sort key, and reports a conflict; the
emitting pass then looks the resolved key up by printed levels and applies it
to every mark of that entry, whether or not that mark wrote `sort=`.

**Consequences:** `sort=` on any one mark of a term sorts all of them. The
levels derivation is now shared rather than duplicated, so the two passes
cannot drift on what an entry's levels are. The conflict report keeps
first-in-document-order-wins semantics and now fires before any emission, so
no mark is emitted under a key the report then contradicts.

## Review
