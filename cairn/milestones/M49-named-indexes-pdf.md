# M49: A PDF render builds every index the document declares

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** `m049-named-indexes-pdf`

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

- [ ] AC1: Rendering `examples/named-indexes.qmd` to PDF on the toolchain
      `tests/run-tests.sh` runs exits 0, and the produced PDF prints two index
      sections headed `Index` and `Index of Authors` whose entry sets are each
      exactly the set that index's own marks derive. A new acceptance-suite
      check states each derived set and compares it against the section's
      extracted entries in both directions.
- [ ] AC2: `examples/named-indexes.qmd` carries all four below-marker cells —
      a mark for a named index below that index's own marker, a mark for the
      default index below the default marker, a mark for the default index
      below a named index's marker, and a mark for a named index below the
      default index's marker. On the same toolchain, each of those terms is
      present in or absent from its own printed index exactly as a new check
      states cell by cell.
- [ ] AC3: Rendering `examples/book/` to PDF exits 0, and the extracted text
      carries one printed section per index that book declares, headed with that
      index's declared title, each section carrying at least one stated entry
      that only that index's own marks can produce.
- [ ] AC4: Each of the four per-index judgements — cross-reference resolution,
      sort-key rivalry, range pairing, and the printed-path collision the
      three-level fold produces — draws at least one report in each of
      `examples/named-indexes.qmd`'s two indexes; the reports a LaTeX render of
      that fixture draws are exactly the set a new check states verbatim; and
      each of those eight reports names the index its judgement was made in
      rather than the word "document".
- [ ] AC5: No tracked page under `site/` carries the string
      `A LaTeX or PDF render builds a single index` or the string
      `Quarto's PDF loop builds only the main entry file`, over a domain a new
      check enumerates itself and whose size it reports. `site/named-indexes.qmd`
      still states that an HTML book builds a single index and why, and states
      what a PDF render needs from the author's TeX installation for each index
      after the first to be built and what happens where it does not.
      `site/books.qmd` and `examples/book/_quarto.yml`'s declaration comment
      scope their one-index-per-book claim to the HTML book.
- [ ] AC6: `tests/run-tests.sh` is clean.

## Coverage

- AC1 → T1, T2, T3, T5, T6, T9
- AC2 → T1, T5, T6, T7, T9
- AC3 → T2, T5, T6, T9
- AC4 → T1, T4, T9
- AC5 → T8
- AC6 → T1, T2, T3, T4, T5, T6, T7, T8, T9

## Tasks

- [x] T1: Extend `examples/named-indexes.qmd` — the four below-marker cells AC2
      names, and marks drawing each of the four per-index judgements in each
      index. Derive every expected entry from the marks, never from a rendered
      artifact (M30).
- [x] T2: Lift the fold — `qi_indexes.reset` sets `folded` for an HTML book
      alone (`_extensions/index/modules/indexes.lua:194`); `title` and
      `scope_phrase` follow.
- [x] T3: Emit `\index[<name>]{...}` at the four sites in `passes.lua`, the
      default index keeping the bare form.
- [x] T4: Namespace `latex.lua`'s `contested_keys`, `principal_keys` and the
      printed-path collision map per index; `reset` empties each.
- [x] T5: Preamble and the close — `\makeindex[intoc,noautomatic]` plus one
      `\makeindex[name=,title=]` per named index in `index.lua`, and the default
      index's `\printindex` wrapped in a group setting imakeidx's
      `disableautomatic` flag, guarded by `\ifcsname` so a version without that
      internal renders rather than errors (IP2).
- [x] T6: `place_index` places each index at its own marker
      (`modules/marker.lua`), named indexes keeping M38's per-index first-marker
      rule.
- [x] T7: Report a mark of index X written below X's own placement marker, which
      imakeidx's close drops; one `warn()` literal, distinct from every other.
- [x] T8: Rewrite `site/named-indexes.qmd`'s "One index outside HTML, for now"
      section; scope `site/books.qmd`'s and `examples/book/_quarto.yml`'s
      one-index claims to the HTML book; add the self-enumerating sweep check
      for the two retired strings; append the D-entry annotating GP2.
- [x] T9: Acceptance-suite checks for AC1-AC4, each reading a captured artifact
      (M24) and each fenced by a planted defect.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: criteria audit re-ran in FULL mode over the two criteria the gate changed and returned nine findings across five, all with one clear answer and all fixed before implement: the extracted side of AC1's comparison now normalizes too; AC1's NFC/NFD-differing term is dropped rather than forcing the fixture to carry the D-016 engine-and-font recipe, which put its own criterion out of reach; AC1, AC2 and AC5 each stop binding an instrument's shape and bind the deliverable; AC2 gains the fourth below-marker cell, a named-index mark below the default marker, which is the one T5 does not imply; AC4 requires each judgement to draw a report in each index, the succeeding side drawing none; AC5 names the HTML-book claim rather than a sentence whose "too" is anaphoric on a retired one, and reaches `site/books.qmd` and the book fixture's declaration comment, which AC3 makes stale. AC3 passed all six; AC6 is instrument-bound by construction as the tier-wide regression criterion.
- 2026-08-27: criteria audit ran in FULL mode (user-facing tier); the fresh-context [O] reader returned twelve findings — ten fixed at the gate and reported in chat, two raised as gate questions (the filter warning against GP2/D-016, and IP2 versus GP2 as the condition's home).
- 2026-08-27: plan gate chose docs-only for the toolchain condition over a filter warning on every multi-index PDF render, because GP2 makes a toolchain failure a documentation surface "never detected or managed" and D-016 settled the matching font case the same way; falsified by an author report that the short second index was unattributable from the docs alone.
- 2026-08-27: plan gate chose a D-entry annotating GP2 over amending IP2, because IP2's promise is about a marked term's characters printing correctly and contains no clause about which indexes get built; falsified by a mark whose index never prints being read as the silent corruption IP2 forbids.
- 2026-08-27: plan gate chose reporting the below-marker close hazard over placing named indexes at the end of the document, because the marker is the author's own syntax and M38's per-index first-marker rule is already shipped and documented; falsified by the report proving unactionable — an author who cannot move the marker below the last mark.
- 2026-08-27: plan gate chose the probe-D preamble (per-index `noautomatic` on the default index, auto-run left on for named ones, the close suppressed by a group-local flag) over suppressing the close package-wide, because probe C showed a package-wide suppression lets the auto-run read an unflushed `.idx` and overwrite a good `.ind` with an empty one; falsified by an imakeidx release moving or renaming the `imki@disableautomatic` flag.
- 2026-08-27: implement gate confirmed the plan's preamble on this toolchain (Quarto 1.10.18, lualatex, TinyTeX): imakeidx loaded with no package-wide option, `\makeindex[intoc,noautomatic]` for the default index and `\makeindex[name=,title=]` per named index prints both indexes, the named one built by imakeidx's own makeindex call under TeX's RESTRICTED shell escape, which TeX Live and TinyTeX permit by shipping makeindex on `shell_escape_commands`; no `-shell-escape` is needed, and that permission is the toolchain condition AC5's docs state. The default index's `\printindex` wrapped in a group setting `\imki@disableautomatictrue` leaves its `.idx` open, so a mark below the default marker still reaches the index, while a named index's `.idx` is closed at its own `\printindex` and a mark of that index below that marker is dropped.
- 2026-08-27: implement gate chose to build M49 now rather than first promote the candidate row of M50 check gaps, because the one gap M49 falsifies — `tests/editorfixture.py`'s `folded` clause, which claims a two-index document prints one merged index — is repaired inside M49, and the other four are latent and touch files this milestone does not.
- 2026-08-27: implement gate chose to flip the begin-document imakeidx guard rather than retire it: it now reports a template that loaded imakeidx in a mode disabling the automatic index build in a document declaring more than one index, which is the preamble collision that now loses an index silently.
- 2026-08-27: implement gate chose to restate M50's `folded` PDF clause as the two-section claim — the term written for the second index prints in that index's own section and the plain terms in the first — rather than drop it, keeping M50-AC4's PDF evidence.
- 2026-08-27: minor amendment — T2 through T6 ship in one commit, no intermediate state among them rendering a document (lifting the fold without the preamble emits two `\printindex` against one `.idx`); each keeps its own checkbox and the suite is run clean before all five are ticked.
- 2026-08-27: T2-T6 — `qi_indexes.reset` folds for an HTML book alone; `latex.lua` gained `index_command` (bare `\index` for the default index, `\index[<name>]` for a named one) and `escape_title`, and namespaced `contested_keys` and `principal_keys` per index with the ordinal counter left document-wide so two indexes cannot mint one id; `index.lua` writes `\makeindex[intoc[,noautomatic][,title={…}]]` for the default index and one `\makeindex[intoc,name=,title={…}]` per named one, loads imakeidx with no package-wide option, wraps the default index's `\printindex` in an `\ifcsname`-guarded group setting `\imki@disableautomatictrue`, and emits one `\printindex` per declared index through the `place_index` map M38 already built. Suite clean.
- 2026-08-27: T7 — `report_below_marker` counts the `\index[<name>]` commands standing below each named index's surviving marker and reports them once per index, naming the marker's top-level block and the shared position basis.
- 2026-08-27: implement gate's flipped guard shipped: the begin-document check now fires on an imakeidx preloaded WITH `noautomatic` in a document declaring more than one index, held by the new `examples/named-indexes-preloaded.qmd` (the warning fires, `authors.idx` is written and no `authors.ind` is built) and by `examples/marker-preloaded.qmd`, whose term below the marker now survives because the close is suppressed by a group rather than by a package option.
- 2026-08-27: T1 — `examples/named-indexes.qmd` extended: AC2's four below-marker cells (Underwood, Vesalius, Ockham present; Petrarch absent) and all four per-index judgements written wrongly in BOTH indexes, so a LaTeX render draws eight index-naming reports. Each index gets a page of its own so a bounded PDF read is possible.
- 2026-08-27: T9 — `tests/namedpdf.py` (entries/cells/reports) over the captured PDF and LaTeX log, each clause fenced by a planted manifest under `--self-test`; `pdfindex.read` gained a `stop` bound that refuses an unbounded read when one was asked for, `tests/indexdump.py pdf` a matching third argument, and `tests/run-tests.sh`'s `index_args` now reads `\index[<name>]{}` too. AC3 reads the book PDF's two sections; AC5 sweeps the tracked `site/*.qmd` pages it enumerates from `git ls-files`.
- 2026-08-27: minor amendment — M50's `folded` clause became `split`, reading one row dump per declared index, and its three plants became five; M04-AC2/AC4, M21-AC5, M29's book-pdf partition, M32's LaTeX plant mutations, M38-R2/R4 (`check_folded_site`/`check_folded_second` → `check_split_site`/`check_split_second`), M38-AC5, M39-AC3, M15's joined-message scan and `warn-distinct`'s EXPECTED (66 → 70) all follow the lifted fold.
- 2026-08-27: T8 — `site/named-indexes.qmd`'s one-index section replaced by three: who builds each index and what the TeX installation must permit, the below-marker rule, and the HTML book's fold. `site/books.qmd` and `examples/book/_quarto.yml` scope their one-index claims to the HTML book; the docs claim manifest gained seven rows; D-031 annotates GP2; CHANGELOG gained an Output section.
- 2026-08-28: `escape_title` gained a case: `examples/named-indexes-foldsite.qmd`'s second declared title now carries an `&` and a comma, and `check_split_site` holds the emitted `\makeindex[intoc,name=authors,title={Index of Authors \& Editors, Second}]` line, so the brace and the escape are held by a render rather than by reading.
- 2026-08-28: self-test repairs found by running it — M15's joined-message scan asserts the absence claim before its head-and-shape control, so M16-AC3's plant reaches the clause it is about; the M38 placement plants were rewritten for the split readers (five and four clauses, each verified to fire its own), and the readers now count each index's command so a duplicate cannot collapse into one; the M49 entries plant that emptied every `index` row was split into an orphan-row case and an empty manifest; the M49-AC5 sweep plant appends the retired sentence rather than substituting across a line break; M50's `nonamed` plant substitutes a term rather than emptying the section, and a sixth plant holds the strayed-term clause; `examples/named-indexes-preloaded.qmd` was declared under `site/gallery.yml`'s `not-shown:`.
- 2026-08-28: `tests/run-tests.sh` clean at 406 checks; `--self-test` clean at 790.
- 2026-08-28: a PDF book render leaves `<name>.idx`, `.ilg` and `.ind` per named index in the project directory, where `examples/*.idx` does not reach and Quarto's `latex-clean` knows only the main jobname; three such files reached the first commit and are untracked again, and `.gitignore` now covers `examples/book*/*.{idx,ilg,ind}` so the pre-render clean removes them.

## Decisions

## Review
