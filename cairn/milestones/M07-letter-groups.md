<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M07: Letter-group headings in the HTML index

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP4, GP6
- **Branch/PR:** m07-letter-groups

## Goal

The HTML index partitions its top-level entries into letter groups — one
Symbols group first, then A–Z — each introduced by a stylable heading block.

## Scope

Surface tier: **user-facing** — the deliverable is rendered index output read
by document readers.

**In:** group ranking of top-level HTML index entries (Symbols first, then
letters; fold-then-codepoint collation within a group — a deliberate
correction of the HTML top-level collation rule); `qi-letter` Div headings,
always on, top level only; the same grouping in book indexes via the shared
builder; instrument support (heading rows in `tests/htmlindex.py`, a
whole-document class sweep); README + DESIGN + code-comment corrections of
the collation rule.

**Out:** LaTeX-side letter headings (makeindex styling; nobody has asked —
returns via a candidate row if wanted); letter-group anchors/links in the
headings (plain labels only; extend later if navigation evidence demands);
chapter-based locator labels (existing candidate row); any CSS (GP4 —
class hooks only, unchanged).

## Acceptance criteria

- [ ] AC1: In every HTML index the acceptance suite renders, top-level
      entries are partitioned into groups in rendered order: one Symbols
      group first (present exactly when a non-letter-filing top-level entry
      exists), then one group per ASCII letter present, in A–Z order; each
      group is introduced by exactly one heading block — a Div carrying class
      `qi-letter` and the group's label text, never a Header — and within a
      group, entries keep the fold-then-codepoint collation; nested levels
      carry no headings and keep the existing collation unranked. Verified
      structurally by `tests/htmlindex.py` — headings as distinct ordered
      manifest rows where a render has an ordered manifest, and a
      hand-derived heading list for the set-checked renders (escaping,
      sort-escaping). At least one verified render's manifest carries no
      Symbols heading row.
- [ ] AC2: A top-level entry's group label is `Symbols` unless the string it
      files under — its registered sort key where one exists, its printed
      text otherwise — begins with an ASCII letter, in which case the label
      is that letter uppercased; an empty filing string labels `Symbols`.
      Verified probes cover: both derivation paths (sort key / printed text)
      reaching both label outcomes (letter / Symbols); one below-`a` and one
      above-`z` symbol-initial top-level entry adjacent in one verified
      render's Symbols group (pinning group ranking against unchanged
      codepoint order); a non-ASCII-initial entry filing in the leading
      Symbols group; and an empty top-level filing string. These probes land
      outside the fixture serving AC1's no-Symbols negative.
- [ ] AC3: A whole-document class sweep of each verified render finds
      `qi-letter` exactly on that render's expected heading rows, in order,
      with every hit outside any entry list item.
- [ ] AC4: The book fixture's aggregated index groups identically, including
      one letter group containing entries contributed by two different
      chapters — verified against the book manifest's heading rows.
- [ ] AC5: The filter change alone changes no LaTeX output: each fixture in
      `tests/byte-diff.sh`'s merge-base list renders byte-identical `.tex`
      under this branch's filter and the merge base's (empty diff; book LaTeX
      sits outside that procedure's list and is covered by the suite's book
      checks). The gfm and no-mark control renders contain no `qi-letter`
      class and no group-label residue — verified by the suite's negatives.
- [ ] AC6: The README documents the grouping rule — label derivation and
      sort-key precedence, Symbols-first group order, always-on behavior,
      top-level-only headings — each documented sentence pinned as a
      `README_LETTER_CLAIMS` row checked by the suite; the existing
      `collation rule` claim row is replaced (old sentence moved to
      `README_STALE`, new sentence stating top-level ranking plus
      within-group collation).
- [ ] AC7: The acceptance suite (`tests/run-tests.sh`) passes clean.

## Coverage

- AC1 → T2, T4
- AC2 → T2, T3
- AC3 → T1, T4
- AC4 → T5
- AC5 → T6
- AC6 → T7
- AC7 → T8

## Tasks

- [x] T1: Instrument: `tests/htmlindex.py` yields heading records in rendered
      order as distinct manifest rows, plus a whole-document `qi-letter`
      sweep helper (count, order, text, outside-any-`li`).
- [ ] T2: Implement grouping in `_extensions/index/index.lua`: group rank
      (Symbols, then A–Z) ahead of `collate` in `number_entries`' top-level
      comparator only; label derivation from the filing string's first
      character (ASCII-letter test); `qi-letter` Div emission in
      `entry_list`/`html_index_blocks` at top level only; update the
      normative collation comment (index.lua:759).
- [ ] T3: AC2 probe fixtures — sort-key/Symbols/non-ASCII/empty-filing
      probes plus adjacent below-`a` and above-`z` entries, landed outside
      `examples/html-index.qmd` (which stays the no-Symbols negative);
      hand-derive their manifest rows.
- [ ] T4: Update every HTML index manifest with heading rows and any
      ranking-reordered entry rows; hand-derive heading lists for the
      set-checked escaping and sort-escaping renders and wire the sweep
      check across all verified renders.
- [ ] T5: Book fixture: add a same-letter entry in a second chapter;
      re-derive book HTML manifest (heading rows) and book PDF terms
      manifest.
- [ ] T6: Run `tests/byte-diff.sh` (expect empty); extend gfm/control
      negatives to assert no `qi-letter` and no group-label residue.
- [ ] T7: README grouping section + `README_LETTER_CLAIMS` rows; replace the
      `collation rule` claim row (old sentence → `README_STALE`); correct
      DESIGN.md Conventions collation bullet (marked corrected M07).
- [ ] T8: Full suite run; fix fallout.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046). -->

- 2026-08-18: created by /milestone-plan; criteria audit ran twice in full mode (user-facing tier), fresh [O] reader: pass 1 nine findings (instrument-blind manifests, unsatisfiable byte-diff claim, unbounded no-X claims, probe gaps, unverifiable README provenance, block kind) — eight fixed in wording, one to the gate; pass 2 on gate-revised wording four findings (stale pinned collation claim, set-checked fixtures outside the domain, missing no-Symbols negative, missing ranking-vs-order discriminator) — all four fixed in wording.
- 2026-08-18: plan gate chose one leading Symbols group over run-based headings because print/makeindex convention and reader expectation outweigh order conservatism (two-run Symbols reads as a bug); falsified by author reports needing a sort key to place an entry across the group boundary.
- 2026-08-18: plan gate chose a `qi-letter` Div over a real H2 heading because Quarto copies heading inlines into the TOC (the M03 defect class) and minted heading ids would enter the uniqueness-checked namespace; falsified by accessibility evidence that non-heading group labels impede assistive navigation.
- 2026-08-18: plan gate chose always-on headings over a ≥2-group threshold or opt-in metadata because zero-config default (GP4) and print convention; falsified by reader evidence that headings on very small indexes hurt.
- 2026-08-18: plan chose stating book LaTeX outside `tests/byte-diff.sh`'s domain over extending its `ls-tree` to recursive because the checker's promise stays untouched (checker-regress doctrine); falsified by a filter-caused book-LaTeX drift the suite's book checks miss.
- 2026-08-18: /milestone-implement started; branch m07-letter-groups cut from main at 89af3d5.
- 2026-08-18: implement gate chose `letter<TAB><label>` heading rows (no collision with depth-digit entry rows), a bare text block inside the `qi-letter` container, and a new `examples/letter-groups.qmd` for the AC2 probes.
- 2026-08-18: T1 done — `tests/htmlindex.py` yields kind-tagged records (heading rows in rendered order) and a whole-document `letter_sweep`; suite still 104 checks clean.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md. -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. -->
