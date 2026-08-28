# M49: A PDF render builds every index the document declares

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** —

## Goal

The LaTeX back-end stops folding every declared index into one, and a PDF render
prints each declared index with its own entries.

## Scope

Surface tier: **user-facing** — the deliverable is index output an author reads
and documentation they follow.

**In:** lifting the LaTeX fold so `qi_indexes` folds for an HTML book alone;
`\index[<name>]{...}` at the four emission sites in
`_extensions/index/modules/passes.lua:570,585,604,612`; per-index namespacing of
`latex.lua`'s `contested_keys`, `principal_keys` and the printed-path collision
map, which today key on the emitted argument string alone and so merge two
indexes that share one; the preamble
(`\makeindex[intoc,noautomatic]` for the default index, `\makeindex[name=,title=]`
per named index, and the default index's `\printindex` wrapped so imakeidx does
not close the `.idx`); placement of each index at its own marker; a report for a
mark written below its own index's marker; PDF-book evidence, a PDF book being
one Pandoc process (M29); and the docs rewrite plus a D-entry annotating GP2 that
records the toolchain condition.

**Out:** the HTML book, which folds because the sidecar record carries no index
name → its existing ROADMAP candidate row, unchanged. A filter warning naming
the toolchain condition → refused at this gate under GP2 and D-016, recorded as
a D-entry, not deferred. A `site/gallery/` page for the new fixture → candidate
row. Restoring the acceptance suite's PDF version-matrix leg → its existing
candidate row.

## Acceptance criteria

- [ ] AC1: `examples/named-indexes.qmd` gains at least one term per declared
      index whose NFC and NFD spellings differ. Rendering it to PDF on the
      toolchain `tests/run-tests.sh` runs exits 0, and the text extracted from
      the produced PDF carries two index sections headed `Index` and
      `Index of Authors`. A new acceptance-suite check states each section's full
      entry list in NFC precomposed form and compares each section's extracted
      entries against its stated list in both directions.
- [ ] AC2: `examples/named-indexes.qmd` carries, for each declared index, at
      least one mark written below that index's own placement marker, and at
      least one mark for the default index written below a marker naming the
      other index. On the same toolchain, every one of those terms that the
      close does not drop appears in its own printed index; the check states
      those terms and the expected presence or absence of each, and the milestone
      states what the guard path in T5 does with them where imakeidx's
      close internal is absent.
- [ ] AC3: Rendering `examples/book/` to PDF exits 0, and the extracted text
      carries one printed section per index that book declares, headed with that
      index's declared title, each section carrying at least one stated entry
      that only that index's own marks can produce.
- [ ] AC4: The reports a LaTeX render of `examples/named-indexes.qmd` draws are
      exactly the set a new check states verbatim, the fixture exercises all four
      per-index judgements in both indexes (cross-reference resolution, sort-key
      rivalry, range pairing, and the printed-path collision the three-level fold
      produces), and each of those reports names the index the judgement was made
      in rather than the word "document".
- [ ] AC5: `site/named-indexes.qmd` carries neither the string
      `A LaTeX or PDF render builds a single index` nor the string
      `Quarto's PDF loop builds only the main entry file`, retains its sentence
      about an HTML book building a single index, and states both what a PDF
      render must have from the author's TeX installation for each index after
      the first to be built and what happens where it does not. The check sweeps
      the tracked pages under `site/` for the two retired strings.
- [ ] AC6: `tests/run-tests.sh` is clean.

## Coverage

- AC1 → T1, T2, T3, T5, T6, T9
- AC2 → T1, T5, T7, T9
- AC3 → T2, T5, T6, T9
- AC4 → T1, T4, T9
- AC5 → T8
- AC6 → T1, T2, T3, T4, T5, T6, T7, T8, T9

## Tasks

- [ ] T1: Extend `examples/named-indexes.qmd` — a term per index whose NFC and
      NFD spellings differ, the three below-marker marks AC2 names, and marks
      exercising all four per-index judgements in both indexes. Derive every
      expected entry from the marks, never from a rendered artifact (M30).
- [ ] T2: Lift the fold — `qi_indexes.reset` sets `folded` for an HTML book
      alone (`_extensions/index/modules/indexes.lua:194`); `title` and
      `scope_phrase` follow.
- [ ] T3: Emit `\index[<name>]{...}` at the four sites in `passes.lua`, the
      default index keeping the bare form.
- [ ] T4: Namespace `latex.lua`'s `contested_keys`, `principal_keys` and the
      printed-path collision map per index; `reset` empties each.
- [ ] T5: Preamble and the close — `\makeindex[intoc,noautomatic]` plus one
      `\makeindex[name=,title=]` per named index in `index.lua`, and the default
      index's `\printindex` wrapped in a group setting imakeidx's
      `disableautomatic` flag, guarded by `\ifcsname` so a version without that
      internal renders rather than errors (IP2).
- [ ] T6: `place_index` places each index at its own marker
      (`modules/marker.lua`), named indexes keeping M38's per-index first-marker
      rule.
- [ ] T7: Report a mark of index X written below X's own placement marker, which
      imakeidx's close drops; one `warn()` literal, distinct from every other.
- [ ] T8: Rewrite `site/named-indexes.qmd`'s "One index outside HTML, for now"
      section; add the sweep check for the two retired strings; append the
      D-entry annotating GP2.
- [ ] T9: Acceptance-suite checks for AC1-AC4, each reading a captured artifact
      (M24) and each fenced by a planted defect.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: criteria audit ran in FULL mode (user-facing tier); the fresh-context [O] reader returned twelve findings — ten fixed at the gate and reported in chat, two raised as gate questions (the filter warning against GP2/D-016, and IP2 versus GP2 as the condition's home).
- 2026-08-27: plan gate chose docs-only for the toolchain condition over a filter warning on every multi-index PDF render, because GP2 makes a toolchain failure a documentation surface "never detected or managed" and D-016 settled the matching font case the same way; falsified by an author report that the short second index was unattributable from the docs alone.
- 2026-08-27: plan gate chose a D-entry annotating GP2 over amending IP2, because IP2's promise is about a marked term's characters printing correctly and contains no clause about which indexes get built; falsified by a mark whose index never prints being read as the silent corruption IP2 forbids.
- 2026-08-27: plan gate chose reporting the below-marker close hazard over placing named indexes at the end of the document, because the marker is the author's own syntax and M38's per-index first-marker rule is already shipped and documented; falsified by the report proving unactionable — an author who cannot move the marker below the last mark.
- 2026-08-27: plan gate chose the probe-D preamble (per-index `noautomatic` on the default index, auto-run left on for named ones, the close suppressed by a group-local flag) over suppressing the close package-wide, because probe C showed a package-wide suppression lets the auto-run read an unflushed `.idx` and overwrite a good `.ind` with an empty one; falsified by an imakeidx release moving or renaming the `imki@disableautomatic` flag.

## Decisions

## Review
