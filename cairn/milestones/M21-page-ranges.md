# M21: A discussion spanning pages prints as one page range

- **Status:** review
- **Priority:** normal
- **Depends on:** M20
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP5, GP6
- **Branch/PR:** `m21-page-ranges` / [#21](https://github.com/jmgirard/quarto-index/pull/21)

## Goal

An author can mark where a term's discussion begins and where it ends, and the index
prints one locator spanning the two rather than a locator at each.

## Scope

Surface tier: **user-facing** — it adds an authoring attribute, changes what both
back-ends emit, and is documented in README.

**In:** one new format-neutral mark attribute, `range="open"` / `range="close"`, paired by
the entry the two marks index, so the common case needs nothing else written; the LaTeX
range encapsulations, carrying on both ends whichever role M20's attribute puts on the
opening mark, since makeindex warns when the two ends differ, and — where that role is
principal — the registration that puts the range's own printed page string into M20's
typeset-time registry, since a range prints as one string no per-page registration matches;
the HTML realization, where
the pair contributes one locator link pointing at the opening mark's anchor; the reports for
the five misuse shapes; fixtures, suite section, planted-defect entries, README.

An ordinary mark of a term that falls inside that term's own range is folded into the
range by makeindex, silently and with no warning even in its own transcript. The extension
cannot know page numbers, so it cannot tell which marks are affected — a warning would
fire on marks outside the range too. It is documented instead, which is what GP2 asks of a
toolchain behavior the extension does not cause.

**Out:** a range spanning two chapters of an HTML book → M22 candidate row (D-009). A range
pairs within one Pandoc process: a single document is one, and a PDF book is one merged
document, but an HTML book renders each chapter in its own and the pairing has to be
re-derived from a sidecar store. Three review rounds each found one defect in that
re-derivation and each was the same mistake, so in an HTML book a `range=` mark indexes as
though the attribute were absent and the book says so once. An author-written id
disambiguating two overlapping ranges of one term → ROADMAP
candidate row, promoted on evidence that authors write overlapping ranges of one term;
until then the shape is reported. Author control over the range dash → candidate row; the
back-end's own convention stands. A range on a page Quarto presents as a book chapter
without the metadata the store needs → that page already falls back to indexing itself
alone, and the range is reported as unpaired there rather than silently spanning nothing.

## Acceptance criteria

- [x] AC1: The PDF render of `examples/range.qmd` produces a `.ind` in which the ranged
      term's entry shows one page range spanning the pages of its opening and closing
      marks, and a `.ilg` carrying no unmatched-, extra- or inconsistent-range warning for
      that entry's key.
- [x] AC2: A range whose opening mark carries `mention="principal"` emits the same
      encapsulator on its closing `\index` command as on its opening one, and for
      `examples/range.qmd` the page string that entry's locator carries in the `.ind` is
      registered as principal in the `.aux` under that encapsulator's own ordinal — the
      chain that prints the range emphasized, whose last link no `.ind` can show.
- [x] AC3: In the HTML render of `examples/range.qmd`, the ranged term's index entry
      carries exactly one locator link, whose href is the opening mark's anchor; where the
      opening mark is principal that one link carries the principal class and emphasis; the
      closing mark contributes no locator link and emits no text of its own beyond the
      author's visible text, read at its anchor by `tests/htmlindex.py`.
- [x] AC4: Each of the five misuse shapes exercised by `examples/range-misuse.qmd` — an
      opening never closed, a closing with no opening, a second opening for a term whose
      range is still open, a range mark also carrying `see=` or `see-also=`, and a `range=`
      value that is neither an opening nor a closing — draws exactly one warning naming the
      mark and saying what the index will show instead, in the LaTeX render, the HTML
      render, and a format with no index back-end.
- [ ] AC5: On a clean full render of the HTML book under `examples/book/`, the two marks of
      `Ranged Term` each contribute their own locator to its entry — `one.qmd`'s at its own
      anchor, and `sub/two.qmd`'s at its own, carrying the principal class and emphasis its
      `mention=` asks for — and the book draws exactly one report, naming both marks, saying
      that ranges are not paired across an HTML book's chapters; the PDF render of the same
      book gives `Ranged Term` exactly one locator, since a PDF book is one merged document.
- [x] AC6: In gfm, an opening and a closing mark pass their visible text through with no
      artifacts beyond the span attribute residue Pandoc passes through for the mark's own
      attributes, `range=` included.
- [x] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1, T3, T6
- AC2 → T1, T3, T6
- AC3 → T1, T4, T6
- AC4 → T1, T2, T6
- AC5 → T1, T5, T6, T11
- AC6 → T1, T6
- AC7 → T6, T7, T8

## Tasks

Completed tasks are one line each; what each did, and why, is in the work log below.

- [x] T1: Fixtures — `examples/range.qmd` (six slots) and `examples/range-misuse.qmd` (one
      mark per AC4 shape plus two controls), both registered in the dangling-target corpus.
- [x] T2: `core.lua` gains the attribute and its two values; `marks.lua` judges each mark's
      end and pairs a set, so the five reports fire in every format.
- [x] T3: `latex.lua`/`passes.lua` — the range delimiters in the encapsulation channel,
      composed with M20's role, the `.aux` registration that emphasizes a whole range, and
      composition with the contested-key bookkeeping.
- [x] T4: `html.lua` — a closing contributes no locator; the merged locator carries the
      range's role.
- [x] T5: `book.lua`: the range end the author wrote travels in the per-chapter record as an
      optional field with a named fallback, leaving the store version alone (the M14 lesson).
      Nothing pairs on it — the last chapter in book order uses it only to report, once per
      render, that ranges are not paired across an HTML book's chapters, naming the marks it
      found. The book fixture keeps its two marks, which now index on their own.
- [x] T6: The suite's range section and its readers in `tests/m21probes.py`.
- [x] T7: Planted defects for every check T6 adds, varying form as well as site.
- [x] T8: README's `range=` section, the normative supported-forms list, and a claims array.
- [x] T9: Review round 1's nine findings, each with the check that would have caught it.
- [x] T10: Review round 2's seven findings, the two plant readers moved into
      `tests/m21probes.py` so the run and the self-test share one reader.
- [x] T11: The narrowing (D-009) and review round 3's twelve findings. Remove the
      cross-chapter pairing and its checks, plants and manifest rows; add the book's
      not-paired report and its key to `tests/scans/mark-report-keys`; fence the report by
      form — fires twice, fires from the wrong chapter, names the wrong mark — using
      `examples/book-order/`, whose marker sits in its first chapter, for the attribution.
      README's cross-chapter paragraph becomes the stated limitation and its false
      refusal lead-in is corrected, both pinned. Then the ten smaller round-3 findings.

## Work log

- 2026-08-21: created by /milestone-plan.
- 2026-08-21: plan gate chose pairing by the entry the two marks index over an author-written pair id because the common case then needs nothing extra written (GP4); falsified by evidence that authors write overlapping ranges of one term, which pairing by entry cannot tell apart.
- 2026-08-21: plan gate chose documenting the folded-in ordinary mark over warning about it because the extension knows no page numbers and the warning would fire on marks outside the range as well; falsified by evidence that authors hit the silent loss and cannot find it from the README.
- 2026-08-21: plan gate chose shipping the principal role first (M20) over ranges first because the arbitration over makeindex's single encapsulation channel is shared and the smaller half builds it; falsified by evidence that the arbitration is range-shaped and had to be rewritten for M20's simpler case.
- 2026-08-21: criteria audit ran in full mode (user-facing tier) and returned findings on the drafted AC2, AC3, AC5, AC6 and the README criterion; the role's end was named, the closing-mark promise was narrowed off the whole page body, the cross-chapter range was reconciled against the unmatched-opening report, the residue clause was reworded to include the new attribute, and the README criterion was descoped to T8.
- 2026-08-22: implement gate settled three open choices: correct AC2's attribute name; emphasize a principal range by registering the composed printed range string rather than by matching either endpoint; and compose a range with a same-key cross-reference (the cross-reference folds into the printed text as it already does) rather than dropping the range.
- 2026-08-22: criteria audit ran in full mode on the amended AC2 and returned three findings — the `.ind` can show no emphasis at all, D-007's consequences leave the emphasis promise unfunded by Scope and T3, and no criterion covered the HTML side of a principal range; bounded-promise, probe and instrument questions clean. All three disposed at the mini gate.
- 2026-08-22: amendment: AC2 reworded (attribute name and evidence locus), AC3 widened with the HTML principal-range clause, Scope In and T3 extended with the range registration. Criteria widened or added: AC3. D-008 records the channel extension.

- 2026-08-22: T1 — `examples/range.qmd` (five slots: plain range, principal range, role-free control, range on a cross-referenced key, same-page range) and `examples/range-misuse.qmd` (one mark per AC4 shape, plus a well-formed range and an ordinary mark as controls); both registered in the dangling-target corpus. The book fixture's range moved to T5 (minor amendment: it changes the book manifest T5 owns). Suite green, 228 checks.

- 2026-08-22: T2 — `range="open"`/`range="close"` in `core.lua`; a format-neutral `CollectRanges` pass with a document hook, since whether an opening is ever closed takes the whole document to know and makeindex warns (and Quarto fails the render) on an unmatched range; `marks.lua` splits the judgement in two, `range_end` per mark and `pair_ranges` over whatever set is the right one, so the book can reuse the pairing. All five reports fire once each in gfm.
- 2026-08-22: T3 — landed with T2, which it cannot be verified apart from. Range delimiters compose into the encapsulation channel at the one place it is written; the registration channel gains four commands in a block of its own, injected only where a range registers. Composed rather than reported against a cross-referenced key, per the gate: `dybbuk` prints `dybbuk, \see{centaur}{}, 10--12`. Reports built as findings and worded at their own `warn()` call, because a message composed elsewhere is text the distinctness scan cannot read (the M13/M19 lesson); its pinned count moves 42 → 47.
- 2026-08-22: T2/T3 evidence — `examples/range.pdf` prints `alicorn, 1–3`, `banshee, [P:4–6]`, `centaur, 7, 9`, `dybbuk, see centaur, 10–12`, `erlking, [P:14]`, and the `.ilg` logs 0 warnings. Suite green, 228 checks.

- 2026-08-22: T4 — one condition in `build_entry_tree`: a mark whose verdict is a closing contributes no locator. The merged locator carries the opening mark's own role with no further work, since the closing contributes nothing to carry one. `examples/range.html` shows one locator per ranged entry, `banshee` and `erlking` emphasized and classed, `centaur` untouched with two.
- 2026-08-22: T5 — the per-chapter record gains an optional `range` holding the end the AUTHOR wrote (never the chapter's own verdict), no store-version bump (the M14 lesson); `book_ranges` pairs across every record in book order, the placing chapter reading its verdicts and the last chapter in book order drawing its reports, as the dangling-target report already is. Book fixture: a range opened in `one.qmd` and closed in `sub/two.qmd` contributes one locator at `one.html#qi-mark-4`, and neither chapter warns. Book HTML manifest, its derivation note and the three letter sweeps updated. Suite green, 228 checks.

- 2026-08-22: T6 — `tests/m21probes.py` (five readers: `.ind`+`.ilg`+`.aux`, the emitted `.tex`, the HTML index, the gfm spans, the book PDF), reusing `m20probes`' brace and locator-group readers rather than writing a second reader of one artifact (the M16 lesson). Extent is asserted in PAGES SEPARATED, never in folios — the one fact the fixture's source states and no artifact can move. Also a preamble check that the four range commands reach only a document registering a range, and a compiled-PDF check reading emphasis through the fixture's own `[P:…]` redefinition, which is the AC2 link no `.ind` can carry. Suite green, 243 checks.

- 2026-08-22: T7 — fourteen planted defects, each shown to fail its own reader: a lost pairing, a wrong extent, a registration composing the wrong string, one naming an ordinal no locator carries, a transcript warning, ends disagreeing on their encapsulator and (a different fault) on their key, an end emitted with no delimiter, a closing that registers nothing, a locator at the wrong end, a second locator, a wrongly emphasized range, a report naming the wrong mark, and a report naming the control. The three mutation helpers were renamed `probe_*` — they are the run's, not one milestone's, and M21 reuses all three rather than copying them. Self-test green, 349 checks.

- 2026-08-22: T8 — README gains "A discussion that spans pages" (what an author writes, what each back-end prints, pairing by entry, the principal range, the cross-chapter case, the folded-in ordinary mark and why it cannot be warned about, and the five refusals); the syntax table goes from seven forms to nine; the principal section's degradation paragraph is narrowed in place to a range makeindex FOLDED, since a range the author wrote now prints emphasized whole; a ninth back-end-difference row; `index.lua`'s syntax header gains the attribute. Eighteen claims pinned in a new `README_RANGE_CLAIMS` array, both authoring forms added to the normative supported-forms list.
- 2026-08-22: review returned the milestone to in-progress on nine findings from a three-lens fan-out. All seven criteria verified with fresh evidence and ticked; the return is taken on the load-bearing-defect limb, not a criterion failure. What failed: a book pairs a range on the raw attribute and silently drops a locator whose mark's range was refused (F1); `mention="principal"` on a closing mark alone is dropped in silence (F2); a stale `.aux` naming a range command the next run does not inject fails the render (F3); the book range report has no positive coverage (F4); the misuse fixture never reaches makeindex (F5); the five new report keys are not passed to `mark-report-keys` (F6); `'' in '()'` makes the tex reader treat an unencapsulated command as a range end (F7); DESIGN.md still describes three passes and omits `data-range` (F8); a stray comma in a comment (F9). First defect return.
- 2026-08-22: all tasks done. `tests/run-tests.sh` passes at 245 checks and `--self-test` at 351 (merge base: 228 and 335). Status set to review.

- 2026-08-22: T9 (F1) — the HTML record's `range` is now written only for a mark that contributes a locator, the same `#xrefs == 0` the anchor is gated on; recorded raw, a book paired an end the chapter had already refused and suppressed the other end's locator, so the entry printed its cross-reference alone while the report said the mark indexes as it would without the range. Reproduced before and after on the book fixture. Checked by a `Spanned` row in the book-order manifest, whose closing keeps its locator a chapter after its opening was refused.
- 2026-08-22: T9 (F2) — the implement gate chose to honour a role written on either end, so `pair_ranges` ORs the two and writes the result back onto the opening's verdict, `register_inline` reads `range.principal` for both ends rather than each end's own `role`, and the HTML record's role is the resolved one. Reproduced before and after. Checked by a sixth slot in `examples/range.qmd` whose closing declares the role, which every existing range clause then reads. README's "you do not write the role twice" was false after this and is corrected in place, its claim pin with it.
- 2026-08-22: T9 (F3) — the four range commands fold back into `PRINCIPAL_SUBSYSTEM`. Verified the hazard first: a stale `.aux` naming a command the next run does not inject gives `! Undefined control sequence` and pdflatex exit 1, which is the IP2 break the subsystem exists to avoid. The M20-level half — a document losing its last principal mention — is unchanged and is now a candidate row.
- 2026-08-22: T9 (F4/F5) — the book's unpaired-range report gains positive coverage in `examples/book-order/`, whose index is built in its FIRST chapter, so the report is proved drawn by the chapter that has seen every record rather than by the marker chapter; and the misuse fixture's emitted LaTeX is now read, since nothing held the claim that a refused range never reaches the index tool. That check caught a wrong premise of its own author on the first run: `hydra`'s first opening does pair, so the fixture has two well-formed ranges, not one.
- 2026-08-22: T9 (F6/F7/F8/F9) — every mark-report key moves to one block above every section that uses one, with M20's three and M21's five added to the scan that sweeps them, and the scan now refuses an empty key (a key read before its assignment expanded to nothing and would have swept every message); `channel[:1] in ('(', ')')` in the tex reader, since `'' in '()'` is True in Python; DESIGN.md's pass count, module row, residue list and D-007 paragraph; a stray comma.
- 2026-08-22: review fixes complete. `tests/run-tests.sh` 247 checks and `--self-test` 359 (before the fixes: 245 and 351). Three new planted defects, each shown to fail its own check.

- 2026-08-22: review round 2 returned the milestone to in-progress on seven findings. All seven criteria re-verified on fresh artifacts and the self-test green at 359; two of three lenses reported nothing. What failed: the role-on-either-end repair does not reach the book path, so a cross-chapter range whose closing declares the role prints a plain locator (R2-F1, reproduced, the round-1 F2 defect on a sibling path); no book fixture marks a range principal, which is why it was reachable (R2-F2); two of the three plants added last round are proved against paraphrase readers rather than the checks that run (R2-F3); README's "Under the hood" still requires the role on the opening mark (R2-F4); `_index_commands`' docstring states a rule its code does not implement (R2-F5); `pair_ranges` orders its never-closed findings by each key's first opening (R2-F6); the book-report counts sit between an unrelated render and its assertion (R2-F7). Second defect return.

- 2026-08-22: T10 (R2-F1/F2) — `book_ranges` returns each verdict whole and `book_marks` resolves `role` from it, mirroring the single-document path; a book is the one place where the end that declares the role and the end that carries the locator can be in different chapters, so neither chapter can resolve it alone. `examples/book/sub/two.qmd`'s closing now declares it, and a new `bookhtml` reader pins the class and emphasis on `one.html#qi-mark-4`. Reproduced plain before the fix, emphasized after.
- 2026-08-22: T10 (R2-F3) — the misuse and preamble readers move into `tests/m21probes.py`; the run and the self-test now call the SAME reader, where before each plant was proved against a weaker stand-in that could not see the clauses the real check carries. Two further plants aimed at exactly those clauses — a refused mark emitting a CLOSING rather than an opening, and a command defined twice rather than absent — both discriminate.
- 2026-08-22: T10 (R2-F4/F5/F6/F7) — README's "Under the hood" sentence corrected and pinned in the claims array; `_index_commands`' docstring rewritten to state the rule its code implements; `pair_ranges` records the opening's position rather than its key, so the never-closed findings are ordered by the opening still pending; the book-report counts moved beside the render they read.
- 2026-08-22: T10 — two ordering traps surfaced while fixing, both caught loudly rather than silently: the new book reader first read an artifact a later hardening step deliberately corrupts, and `HTML_PRINCIPAL_CLASS` was defined thousands of lines below its new first use, which `set -u` turned into an unbound-variable failure. The reader moved to the render it is about and the constant joined the other pinned HTML identifiers at the top.
- 2026-08-22: round-2 fixes complete. `--self-test` 363 checks (before: 359).

- 2026-08-22: review round 3 returned twelve findings; all seven criteria held and both runs were green. Two mattered: README's refusal lead-in is false for the cross-reference case and the claims array pins it (R3-F1), and the per-chapter record stores the RESOLVED role beside the RAW range end, so a book re-pairing from those records emphasizes locators the author never marked (R3-F3, reproduced in a three-chapter book). R3-F3 is the third instance of one mistake — a resolved value where the raw one belongs, repaired on one path and left on its sibling — and all three have been in the book realization. Third defect return; at the gate the user chose the thrash rule's descope over a fourth repair.

- 2026-08-22: amendment (descope, chosen at review round 3's gate). Scope In loses the cross-chapter clause; Scope Out gains the HTML book case with its exit; AC5 narrows to what a book does without pairing; T5 rewritten and T11 added; Coverage maps AC5 to T11 as well. Criteria widened or added: AC5 — its new wording binds a `mention=` role in a book and binds the book PDF, neither of which any criterion bound before; both are disclosed here per the amendment convention, and both are funded by checks that already exist. D-009 records the decision and the ROADMAP carries the candidate row it promotes from.
- 2026-08-22: the amended AC5 went to two fresh-context [O] criteria audits in full mode. The first returned six blocking findings (an unsatisfiable counterfactual baseline, an unanchored referent, an unbounded render domain, a missing plant plan, a README gap, and one undisclosed widening); the second, on the corrected draft, returned three more — the counterfactual was still instrument-built, "the last chapter in book order" cannot discriminate in a fixture whose marker IS its last chapter, and "one page range" pinned an extent pagination decides where the reader asserts one locator. The third draft applies every repair, and the wording decision went to the user, which is where the second re-entry sends it.
- 2026-08-22: Tasks compressed in one pass to hold the 150-line cap; ROADMAP's three book-sidecar rows clustered to hold its 60-line cap.

- 2026-08-22: correction — T8's work-log line above says "a ninth back-end-difference row"; README numbers it eight. The line stands (IP4) and this supersedes its count.

- 2026-08-22: T5/T11 — the cross-chapter pairing is gone. `book_ranges` and every consumer of a book-level verdict are removed; what stays is the store's `range` field and this chapter's own `paired` verdict, both carried through, and one report from the last chapter in book order naming every range end no chapter could pair. A chapter IS one Pandoc process, so a range whose two marks share a chapter still pairs there — `examples/book/last.qmd` gains exactly that, and `Chapter Range` prints one locator while `Ranged Term`, split across two chapters, prints two, the closing's carrying the principal class its own mention= declares.
- 2026-08-22: T11 — the ten smaller round-3 findings: `_bookhtml` gains three plants and the book report two more, so the reader the round-2 return was taken on is finally shown discriminating (R3-F2); D-009 supersedes D-008's count of the `.aux`-borne commands and DESIGN.md's inverted description is corrected (R3-F4); the report's attribution is proved in `examples/book-order/`, whose marker sits in its FIRST chapter (R3-F5); `examples/range.tex` is removed before its render and size-checked like its siblings (R3-F6); `_ind` reads the `.aux` as lists and refuses a repeated registration (R3-F7); the range-start slot is cleared once used, so the stale-`.aux` guard means what its comment says for a second range of one key (R3-F8); `range=""` is exercised (R3-F10); a work-log count is superseded (R3-F11); two dead guards removed (R3-F12). R3-F9 — nested marks desyncing the passes through `span_text` — is left: round 2's lens cleared it and round 3's flagged it as narrow, and it is a candidate row rather than a change made on a split verdict.
- 2026-08-22: narrowing complete. `tests/run-tests.sh` 249 checks, `--self-test` 367. The book's warning count check now names both of the two warnings the fixture emits rather than pinning one.

## Decisions

## Review

Reviewed 2026-08-22 on `m21-page-ranges` at PR #21. Evidence is from renders and runs made
in this review session, never from the implementation session's record.

**Consistency gate.** `cairn_validate` passes all 16 checks, exit 0. No `DESIGN.md`
principle changed in the diff, so `cairn_impact` is skipped. The `generic` profile names no
toolchain checks, so that half is a clean no-op. This repo has no CI workflows; the local
suite is the whole gate.

**AC1** — verified. Fresh PDF render of `examples/range.qmd`. The `.ind` gives one locator
per range: `alicorn, \hyperpage{1--3}`, `banshee, …{qi1}}{4--6}`, `dybbuk, \see{centaur}{},
\hyperpage{10--12}`, `erlking, …{qi2}}{14}`, each spanning its own two marks; the range-free
control prints `centaur, 7, 9`, two separate pages. The `.ilg` reads `done (21 lines
written, 0 warnings)`, taken as a number rather than by substring, and carries none of the
four range-fault phrases. Extent is asserted in pages-separated (3, 3, 3, 1 — the fixture's
own structure), never in folios.

**AC2** — verified. Emitted `.tex`: `\index{banshee|(quartoindexlocator{qi1}}` against
`\index{banshee|)quartoindexlocator{qi1}}` — one key, byte-identical encapsulator on both
ends; likewise `erlking`/`qi2`; the non-principal `alicorn` carries `|(`/`|)` with no
encapsulator at all. The `.aux` holds `\quartoindexrangeat{qi1}{4}` and
`\quartoindexrangeto{qi1}{6}`, composing `4--6` — which is exactly the page string `qi1`'s
locator carries in the `.ind`; `qi2` registers `14`/`14` and its printed single page `14`
matches the opening registration. Beyond what the criterion asks: the compiled PDF, read
through the fixture's own `\quartoindexprincipal` redefinition, prints `banshee, [P:4–6]`
and `erlking, [P:14]` with `alicorn`, `centaur` and `dybbuk` plain — two emphasized, which
is the number of principal openings the fixture writes.

**AC3** — verified. `examples/range.html`: `alicorn`, `banshee`, `dybbuk` and `erlking` each
carry exactly one locator link, at `#qi-mark-1`, `#qi-mark-3`, `#qi-mark-7` and `#qi-mark-9`
— their opening marks. `banshee`'s and `erlking`'s carry `class="qi-principal"` and a
`<strong>`; `alicorn`'s and `dybbuk`'s carry neither. The four closing marks
(`qi-mark-2/4/8/10`) each keep an anchor, render exactly their own visible text, and hold no
link. The range-free control keeps both of its plain locators.

**AC4** — verified. `examples/range-misuse.qmd` rendered to latex, html and gfm: exactly
five range reports in each, one per shape, each naming its own mark — `"jinn"`, `"imp"`,
`"hydra"`, `"golem"`, `"fenrir"` — and each saying what the index shows instead (three
"indexes as an ordinary page number", one "as though the attribute were absent", one "the
range is dropped and the mark indexes as it would without it"). The two controls in the same
document, the well-formed `lamia` range and the ordinary `kelpie` mark, are named zero times
in all three formats, and the well-formed fixture draws none of the five in any format.

**AC5** — verified on a clean full render of `examples/book/`. `Ranged Term` carries exactly
one locator, `<a href="one.html#qi-mark-4">` — the opening chapter's page and the opening
mark's anchor — and the whole-book render log carries zero range reports, so neither
`one.qmd` nor `sub/two.qmd` warned about its half. The merged book PDF prints
`Ranged Term, 4–5`, one page range across the two chapters. Read on a clean render
deliberately: later suite steps corrupt and re-plant `one.qmd`'s record and re-render
`last.qmd` alone, so the artifact left in the working tree at the end of a run is not the
state this criterion is about; the manifest check reads it at the render.

**AC6** — verified. `examples/range.md` carries 11 index spans, in document order and byte
for byte against the hand-derived manifest, each with only its own attributes data-prefixed
(`data-range`, plus `data-mention`/`data-see` where written). No `|(`, `|)`, `\index{`,
`qi-`, or any of the eight locator/registration command names appears anywhere in the file.

**AC7** — verified by fresh runs on this branch: `tests/run-tests.sh` exits 0 at 245 checks
and `tests/run-tests.sh --self-test` exits 0 at 351 (merge base 228 and 335). The self-test
shows 58 planted defects discriminating, 14 of them this milestone's.

### Findings

Three fresh-context reviewers ran in parallel: an [O] diff-bug lens, an [S] blame-history
lens, and an [S] prior-review-record lens. The prior-review lens reported no findings — the
GitHub inline-comment probe returned empty, and it found no place where the diff
reintroduces or contradicts a point archived reviews raised on the touched files. The
blame-history lens reported one finding (F9 below) and cleared seven areas, among them the
store-version rule, the contested-key composition, the `probe_*` rename and the
`warn-distinct` count. The diff-bug lens reported nine, ranked. Every finding below was
re-verified against the implementation rather than accepted on its reporter's account.

Triaged at the merge gate 2026-08-22. The user chose to return the milestone rather than
fix at the gate, so every disposition below is *fix on return*.

- **F1 (fix)** — a book pairs a range on the RAW `range=` attribute, so a mark whose range
  was refused for carrying a cross-reference is still paired across chapters and the
  closing's locator is suppressed. Reproduced: `see="Alpha"` on the book fixture's opening
  makes the book index print `Ranged Term, see Alpha` with no locator at all, while the
  report tells the author the mark "indexes as it would without it". The record's `range`
  must be gated on the mark contributing a locator (`#xrefs == 0`), the same condition two
  lines below it already gates the anchor on. `role` on the same record is the RESOLVED
  role, which is the inconsistency that made this reachable.
- **F2 (fix)** — `mention="principal"` on a range's CLOSING mark alone is dropped in
  silence. Reproduced: both ends encapsulate with the key's ordinal, nothing registers, the
  range prints plain and no report fires. Every other unusable role is reported (M20), so
  the silence is the outlier. Repair is a report, or taking the role from either end.
- **F3 (fix, plus a candidate row)** — a stale `.aux` naming a range command the next run
  does not inject raises `Undefined control sequence` and fails the render (verified:
  pdflatex exits 1 at `l.13 \quartoindexrangeat`). The class is M20's — the same holds for
  `\quartoindexprincipalpage` — but M21 quadruples its members and the new preamble check
  pins the narrow injection in place. Fold the range block back into `PRINCIPAL_SUBSYSTEM`,
  which strictly reduces exposure, and record M20's remaining half as a candidate row.
- **F4 (fix)** — `report_book_ranges` is asserted only NOT to fire; deleting the call leaves
  the suite green, while Scope promises a range on a degraded book page is reported. Needs a
  book fixture carrying an unpaired range and a count pinned at 1 in the last chapter.
- **F5 (fix)** — `examples/range-misuse.qmd` never reaches makeindex, so the justification
  for every refusal is untested. Assert the emitted `.tex` carries exactly one `|(` and one
  `|)` (the well-formed control's), or render it to PDF and pin its `.ilg` at zero warnings.
- **F6 (fix)** — the five new report keys are not passed to `tests/scans/mark-report-keys`,
  the scan whose own comment says a key not passed to it leaves every zero-expectation
  control resting on it vacuous (M18 review F3). Ten such controls rest on them. Verified
  the five pass the scan as written, so this is a one-line change; M20's three keys are
  missing on the same terms and go in with them.
- **F7 (fix)** — `tests/m21probes.py:260` writes `channel[:1] in '()'`, and `'' in '()'` is
  True in Python, so an unencapsulated `\index` counts as a range end; planted defect (viii)
  currently fails by traceback rather than by its own diagnostic.
- **F8 (fix)** — `DESIGN.md` was not touched: it still says three passes, omits `data-range`
  from the pass-through residue list AC6's manifest pins, and still ends its D-007 paragraph
  "Ranges are M21's". `passes.lua`'s own header says "The three Span passes".
- **F9 (fix)** — a stray comma on a comment line in `core.lua:203`, found independently by
  two lenses.

No finding demonstrates an acceptance criterion failing: all seven are satisfied as written,
and F1–F3 sit in the gaps between them. The return is taken under the load-bearing-defect
limb of the return floor, on F1 and F2 — each a silent loss of something the author wrote.
This is M21's first defect return.

### Round 2 (2026-08-22)

Re-verified after the nine repairs. `cairn_validate` passes, `main` has not moved, no
`DESIGN.md` principle changed. `tests/run-tests.sh --self-test` exits 0 at 359 checks.

All seven criteria hold on fresh artifacts. AC1/AC2: the `.ind` now carries six entries —
`alicorn, 1--3`, `banshee …{qi1}}{4--6}`, `centaur, 7, 9`, `dybbuk, \see{centaur}{}, 10--12`,
`erlking …{qi2}}{14}` and `firebird …{qi3}}{15--17}` — at `done (25 lines written, 0
warnings)`; every principal range registers both ends (`rangeat`/`rangeto` for qi1, qi2,
qi3) and each composed string is the one its locator prints. AC3: six entries, one locator
each for the five ranges, at `#qi-mark-1/3/7/9/11`, with `banshee`, `erlking` and `firebird`
classed and emphasized; all five closings keep an anchor and their own text. AC4, AC5, AC6,
AC7 as recorded above, with the book's two pairing reports now positively pinned.

Three fresh reviewers ran again over the whole branch. The blame-history and
prior-review-record lenses each reported no findings, both confirming the nine repairs hold
and that the deliberate weakening of M20's "injected only where used" is disclosed in
D-008, the ROADMAP row and the code. The diff-bug lens reported seven, ranked; each was
re-verified here, R2-F1 by reproduction.

- **R2-F1 (fix)** — the F2 repair is unfixed on the BOOK path. `book_ranges` returns only
  each verdict's `ending`, and `book_marks` then takes `role` from the chapter's own record
  — a chapter that could not see the other end. Reproduced: `mention="principal"` on the
  closing of the cross-chapter range prints a plain locator with no class and no emphasis,
  where the same input in one document prints it emphasized, and README promises the
  opposite twice. Repair: return the verdict rather than its ending, and resolve `role` from
  it exactly as `passes.lua` does.
- **R2-F2 (fix)** — no fixture puts `mention=` on a range in either book, which is why
  R2-F1 was reachable: the role-on-either-end repair was exercised in the single-document
  slot alone. Repair: mark the cross-chapter range principal and pin the class.
- **R2-F3 (fix)** — two of the three plants the review's own repairs rest on are proved
  against paraphrase readers rather than the checks that run: the leak plant asserts only
  the opening set where the real check also reads closings, per-term counts and the refused
  set, and the preamble plant uses `re.search` where the real check demands exactly one
  definition. So a defect those checks would catch and their stand-ins would not is not
  fenced. Repair: move both bodies into `tests/m21probes.py` and call the same reader from
  the run and from the self-test.
- **R2-F4 (fix)** — README's "Under the hood" still says "Where the opening mark is also the
  principal mention", contradicting the corrected authoring claim sixty lines above and the
  code; nothing pins it, which is how it survived the F2 repair.
- **R2-F5 (fix)** — `_index_commands`' docstring claims it splits at the LAST `|` by brace
  counting; it splits at the first, which is correct here. A reader stating a rule it does
  not implement is the class the M01 and M16 lessons are about.
- **R2-F6 (fix)** — `pair_ranges` appends to `waiting` at every opening, so its never-closed
  findings are ordered by each key's first opening rather than by the opening still pending;
  the comment asserts otherwise. Message ordering only.
- **R2-F7 (fix)** — the three book-report counts sit between the `book-nostore` render and
  its own assertion, reading a log written earlier; a failure inside them leaves a stray
  store file behind.

R2-F1 is the round-1 F2 defect left standing on a sibling code path. Triaged at the gate
2026-08-22: the user chose to return rather than fix at the gate, so all seven are fixed on
return. Second defect return; a third meets the thrash rule's descope-or-park threshold.

### Round 3 (2026-08-22)

`cairn_validate` passes, `main` has not moved, no principle changed. `tests/run-tests.sh`
exits 0 at 249 checks and `--self-test` at 363. All seven criteria hold on fresh artifacts:
the `.ind` carries six entries at `done (25 lines written, 0 warnings)`; the `.aux` registers
three ranges and each composed string is the one its locator prints; the compiled PDF prints
`alicorn, 1–3`, `banshee, [P:4–6]`, `centaur, 7, 9`, `dybbuk, see centaur, 10–12`,
`erlking, [P:14]` and `firebird, [P:15–17]` — the last a range whose role was written on its
CLOSING mark; the gfm render carries thirteen spans against the manifest (round 1's evidence
line said eleven, which was true of the fixture then); the book prints one emphasized
locator for its cross-chapter range and `Ranged Term, 4–5` in the merged PDF.

The blame-history and prior-review-record lenses each confirmed all sixteen earlier repairs
hold and reported nothing beyond one stale figure, noted above. The diff-bug lens reported
twelve. Two matter.

- **R3-F1** — README's lead-in to the five refusals says each mark "still indexes its term as
  an ordinary page number", which is false for the one carrying a cross-reference: it
  indexes as a cross-reference and contributes no page number. The filter's own warning says
  something different, and the suite's own AC4 count expects that phrase three times, not
  five — so the split is already encoded a few lines away. The claims array pins the false
  sentence, so nothing can catch it.
- **R3-F3** — the per-chapter record stores the RESOLVED role beside the RAW range end. This
  is the F1 inconsistency on the sibling field: a chapter that pairs a range internally
  writes `role="principal"` onto BOTH its records, and the book then re-pairs from them.
  Reproduced in a three-chapter book: with a stray opening in the first chapter and a
  complete range in the second whose closing declares the role, the printed index emphasizes
  BOTH locators, though the author wrote the role on one mark that contributes no locator at
  all. Repair: store the mark's own pre-range role, as `range` is already stored raw, and let
  `book_ranges` do the OR.

Ten are smaller and all real: `_bookhtml` — the reader the round-2 return was taken on — has
no planted defect (R3-F2); D-008 and DESIGN.md miscount the `.aux`-borne commands as one
where there are two (R3-F4); the `book-order` fixture puts both unpaired marks in the last
chapter, so it does not discriminate everything its comment claims (R3-F5);
`examples/range.tex` is neither removed before its render nor size-checked, unlike every
other artifact in the section (R3-F6); `_ind` collapses duplicate `.aux` registrations
through `dict()` (R3-F7); `\qi@f@<ordinal>` is never cleared, so the stale-`.aux` guard
covers less than its comment claims (R3-F8); nested marks could desync the two passes
through `span_text`, which round 2's lens cleared and round 3's did not (R3-F9); `range=""`
is documented and pinned but exercised nowhere (R3-F10); a work-log line says "ninth"
back-end-difference row where README numbers it eight (R3-F11); two dead guards in the
readers (R3-F12).

R3-F3 is the third instance of one pattern: a resolved value stored or read where the raw
one belongs, repaired on one path and left on its sibling. F1 was the record's `range`
field, R2-F1 the book's verdict, R3-F3 the record's `role`. All three live in the book
realization, which is also the only part of the milestone that has needed a repair in every
round; the LaTeX and single-document HTML sides have been stable throughout. Third defect
return: the thrash rule's descope-or-park threshold. Triaged at the gate 2026-08-22 — the
user chose to NARROW the milestone rather than repair the book path a fourth time. The
cross-chapter book realization leaves M21's scope; the ten smaller findings are fixed on the
way out, and R3-F3 is dispositioned by the narrowing itself, since it lives entirely in the
book path.
