<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M59: The words an author writes are refused when a reader cannot read them

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, IP3, GP1
- **Branch/PR:** m059-index-label-refusals — https://github.com/jmgirard/quarto-index/pull/59

## Goal

Every unusable `index-labels:` value an author can write is reported and falls
back, which is what the surface already promises and four shapes do not do.

## Scope

User-facing tier: the deliverable is what an author writes under
`index-labels:` and what the extension says back to them.

**In:** four shapes that install or vanish in silence today, each confirmed by
render on 2026-08-29 (Quarto 1.10.18) except where noted. A value that prints
no visible character — `&nbsp;`, a zero-width space — is installed as the
printed word. A value written as a nested map, the likely over-indentation
mistake, is flattened to its joined leaf values and printed; one written as a
list is flattened too. An `indexes:` entry refused for any other reason drops
the `index-labels:` map inside it with no message of its own. A `symbols:`
word that a printed letter group also heads prints two groups under one
heading with no report. Also in: the fixture cases, suite checks and planted
defects fencing each, the two documentation pages, and the changelog.

**Out:** the checks fencing this surface that are weak rather than wrong —
the ordering `read` deliberately has, the manifest row folding word and
target, the state-reuse cells, the plant that re-implements its own
comparison, the unpinned report total, the block-ending derivation, the
per-index message shapes, the unread outcome table, the locale-dependent
subtag match, the diff-header filter, the unread export, the language row a
title key would reach, the missing book language fixture — all stay on the
three existing candidate rows they are already recorded under. A way for an
author to ask for no word at all in front of a cross-reference target — which
refusing an invisible value takes away — becomes its own candidate row. The
index `title:` key keeps flattening a map, since nothing here reads it.

## Acceptance criteria

- [x] AC1. The two invisible values `examples/index-labels-misuse.qmd` adds —
      a `&nbsp;` under `see-also:` at the document level and a zero-width
      space under `symbols:` in one `indexes:` entry — each draw the report an
      empty value draws, naming their own key and their own level, and each
      word prints as the English one. The characters counted as invisible are
      listed at one site in `_extensions/index/modules/indexes.lua`.
      (RB tripwire: ip-touching)
- [x] AC2. The two flattened values that fixture adds — a `see:` written as a
      nested map and a `symbols:` written as a list — each draw a report
      naming their own key and their own level, and each word prints as the
      English one. Today the map case installs the map's joined leaf values
      with no report (`read_labels`, `indexes.lua`).
- [x] AC3. For each of the four ways an `indexes:` entry is refused that can
      still carry a label map — no `name:`, an empty `name:`, a name of the
      wrong shape, a repeated name — the fixture writes one such entry
      carrying an `index-labels:` map, and each draws, beside the entry's own
      refusal message, one further message saying that map sets no word. The
      four messages are asserted whole, not by prefix.
- [x] AC4. On a new fixture, an index whose `symbols:` word a printed letter
      group also heads draws a report naming the word and the index, and
      still prints both groups; a second index in the same fixture, whose
      `symbols:` word heads no letter group, draws no such report.
- [x] AC5. `site/letter-groups.qmd` and `site/cross-references.qmd` each state
      which label values are refused — empty, invisible, a map, a list — and
      what a refused value falls back to; `CHANGELOG.md` carries one entry per
      behavior change, each naming a test that fails without it.
- [x] AC6. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
      0 over the merged tree.

## Coverage

- AC1 → T1, T4, T6
- AC2 → T1, T4, T6
- AC3 → T2, T4, T6
- AC4 → T3, T5, T6
- AC5 → T8
- AC6 → T6, T7, T9

## Tasks

- [x] T1. In `read_labels` (`_extensions/index/modules/indexes.lua`), refuse a
      stringified value holding no visible character, against a list of the
      invisible characters written at one site, and refuse a value whose
      Pandoc type is a map or a list. Each reports its key and its level and
      falls back, on the discipline the surrounding code already states.
- [x] T2. In `read_declaration` (same file), draw one further message where a
      refused entry carries an `index-labels:` key, on every refusal branch
      that can reach one. The map is not read — the message says it sets no
      word and stops.
- [x] T3. In `grouped_blocks` (`_extensions/index/modules/html.lua`), report
      where the printed non-letter heading equals a letter group's heading in
      the same index, once per index per render, naming the word and the
      index. What prints is unchanged.
- [x] T4. Extend `examples/index-labels-misuse.qmd` with the two invisible,
      two flattened and four refused-entry cases; give every new mark a term
      no other mark in that file indexes. Update its derived twin, its section
      manifest and its pinned report total.
- [x] T5. Add the letter-clash fixture: two indexes, one whose `symbols:` word
      a printed letter group also heads with a term filing under that letter,
      one whose word heads no letter group. Manifest and pinned report total
      with it.
- [x] T6. Add the suite checks for the new messages and manifests, each
      message asserted whole, each with a zero-expectation control on a
      fixture writing none of these shapes.
- [x] T7. Plant one defect per new clause under `--self-test`, each built with
      a single substitution and shown red before its green is trusted.
- [x] T8. Write the documentation sentences on the two pages and the changelog
      entries, each against the renders T4 and T5 produce.
- [x] T9. Correct the known-issue entries this milestone closes, and run the
      suite plain and with `--self-test` over the merged tree.

## Work log

- 2026-08-29: created by /milestone-plan.
- 2026-08-29: criteria audit ran in reduced-context form inside this session, not in a fresh reader — subagents are disabled here; four findings, all fixed before the criteria were written: three promises quantified over domains no named render enumerates (narrowed to the spellings and branches the fixture writes), and one would have needed a widened source scan, which D-011 forbids. Two further instrument-bound clauses moved from AC4 and AC6 to T6 and T7.
- 2026-08-29: KI173's recorded trigger is wrong and is corrected in DESIGN.md with this plan — `see: " "` already draws the empty-value report, since Pandoc parses a whitespace-only metadata value to empty inlines; what installs is an invisible non-empty value.
- 2026-08-29: plan gate chose refusing an invisible-only value over keeping it as the way to print no word, because a reader cannot tell a `see` from a `see also` when the word is invisible; falsified by an author reporting they relied on it, which the new candidate row is for.
- 2026-08-29: plan gate chose refusing a map or list label value over leaving it to match the index `title:` key, because the over-indentation it catches is the likeliest mistake on a nested-map surface; falsified by an author writing a structured label value this refusal blocks.
- 2026-08-29: plan gate chose reporting the letter clash where the index is printed over reporting the value's shape where it is read, because only the printing site knows whether a clashing letter group exists and the read site would fire on PDF, which prints no letter groups; falsified by the report proving unreachable per index in a book's several processes.
- 2026-08-29: plan gate chose one message that a refused entry's label map sets no word over also reading that map, because messages about a map that will not be used are noise beside a declaration the author must fix first; falsified by an author fixing the declaration and meeting the map's own errors only on the next render.
- 2026-08-29: question gate — three choices, each taken as recommended. A value made only of blank characters is refused against a written-out list covering every blank character, not only the zero-width ones. The refusal covers the two punctuation keys as well as the three word keys, so one rule, one message and one list serve all five. The letter clash is compared character for character, so `symbols: "A"` is reported in an index with an A group and `symbols: "a"` is not.
- 2026-08-29: T1 — `read_labels` refuses a value whose Pandoc type is a map or a list, naming the shape the author wrote, and a stringified value holding no character outside `BLANKS`, a 27-entry list written at one site in `indexes.lua` and spelled with `\u{}` escapes so the source stays ASCII.
- 2026-08-29: T1 — the empty-value report is reworded from "an empty value, which is no word a reader can read" to "a value with no character a reader can see", since AC1 has the invisible case draw that same report and the old words would have called a non-breaking space empty. Three needles in `tests/run-tests.sh` (M56-AC5, M58-AC4 twice) move with it.
- 2026-08-29: T2 — `report_dropped_labels` draws one further message from all four `read_declaration` refusal branches an entry carrying a label map can reach. One call site rather than four: the four emitted lines differ by the entry position they name, and one literal is one message the `warn-distinct` scan reads whole.
- 2026-08-29: T3 — `grouped_blocks` collects the headings it prints and reports where the non-letter group's heading is character-for-character one of the letter headings of the same index. Drawn at the printing site, so it fires once per index per render for HTML and EPUB and never for a format with no letter groups.
- 2026-08-29: T4 — `examples/index-labels-misuse.qmd` grows a fourth declared index and four entries refused as declarations; its report total is pinned at 18, derived per writing site in the M59 block's oracle comment. The zero-width space is written `"\u200B"` rather than as a literal, so no invisible character sits in a fixture a human reads.
- 2026-08-29: T5 — `examples/index-labels-clash.qmd` added: two indexes, one naming its non-letter group after a letter it also files a term under and one after a letter it does not. Listed under `not-shown:` in `site/gallery.yml`; it writes no cross-reference target, so it is not in the dangling corpus.
- 2026-08-29: T6 — the M59 block adds whole-message assertions for the four value shapes, the four refusals and the four dropped-map messages, each with a zero-expectation control on `examples/index-labels.qmd`, plus the clash report, its silent twin, both render totals and the printed-heading manifest. The `warn-distinct` pin moves 74 → 77.
- 2026-08-29: T7 — six plants, each one substitution on a copy of an artifact this run produced: four logs with one message deleted, one log with one message added, and one captured page whose author-named group heading is put back to `Symbols`. Each shown red, and red for its own reason, before its green was trusted.
- 2026-08-29: T8 — the refusal sentences added to `site/letter-groups.qmd` and `site/cross-references.qmd` and three `CHANGELOG.md` entries, each naming the check that fails without it, all written against the two renders T4 and T5 produce.
- 2026-08-29: T9 — KI173, KI174, KI175 and KI176 removed from `cairn/DESIGN.md` as closed, and the `indexes.lua` architecture line extended to name the label surface it owns. Suite green over the branch: 486 checks plain, 934 with `--self-test`, both exit 0; the default branch has not moved since the branch was cut, so this tree is the merged tree.
- 2026-08-29: noticed out of scope and not touched — DESIGN.md's KI26 still says the reader-facing-words policy is "settled and unimplemented", which M56-M58 falsified.

- 2026-08-29: review opened — branch pushed, draft PR #59, consistency gate green (`cairn_validate` exit 0, no principle change so no impact report, `generic` profile names no toolchain checks). Acceptance evidence and the three review lenses in flight.
- 2026-08-29: review — three lenses ran; blame-history and prior-review found nothing, the diff-bug lens nine, none meeting the return floor. Four fixed at the gate: a refused entry's further message asserting a shape the code never reads, a fallback ladder running the two punctuation marks through `lang:` in the changelog and on both pages, a stale count of six in a live self-test comment, and a docblock left on the wrong function. One rejected, four deferred. Suite re-run over the fixed tree: 486 plain, 934 with `--self-test`, both exit 0.

## Decisions

- 2026-08-29 (T1): a label value made only of blank characters is refused, against a written-out list of 27 characters rather than a character property. The Lua Pandoc embeds ships no Unicode category tables, and `%s` follows the C locale, which would decide U+2007 one way on one machine and another way elsewhere. The list is the one site that says what blank means; a character nobody thought of prints and is not refused, which is the failure direction that leaves a reader with something to read.
- 2026-08-29 (T1): the refusal covers all five writable keys, the two punctuation ones included. An author who wanted a non-breaking space between a term and its locators is refused and gets the ASCII comma back; the candidate row for a way to ask for no word at all is where that request goes.
- 2026-08-29 (T3): the letter clash is compared character for character, not case-insensitively. A letter group always heads a capital, so `symbols: "a"` prints a heading a reader can tell from the `A` group's and draws nothing.

## Review

Reviewed 2026-08-29 against PR #59. Every figure below is from a run over the
tree that ships — the suite was re-run after the gate fixes recorded further
down, and the earlier run's figures are superseded by these. No `Driving RR:`,
so no projection to juxtapose.

### Acceptance criteria

- AC1 — green. `M59-AC1/AC2` counts the whole `see-also` message naming this
  document's own metadata and the whole `symbols` message naming the entry
  declaring `strata` at exactly 1 each in the misuse render's log, and at 0
  each in `examples/index-labels.qmd`'s. The fallback half is the
  `M59-AC1/AC2 (fallback)` manifest: 4 index sections, all 31 rows in order,
  `strata` heading its non-letter group `Symbols` and printing `see` in front
  of its one target, so neither the non-breaking space nor the zero-width one
  reached a reader. The invisible characters are listed at one site,
  `BLANKS` in `_extensions/index/modules/indexes.lua`, 27 entries.

- AC2 — green. The same `M59-AC1/AC2` block counts the whole `symbols` message
  naming this document's metadata and a value written as a list, and the whole
  `see` message naming the entry declaring `strata` and a value written as a
  map, at exactly 1 each in the misuse log and 0 each in the control fixture's.
  Both words print as the English ones, on the same 31-row manifest AC1 reads:
  the map case in particular used to install `vergleiche` from its joined leaf
  values with nothing said.

- AC3 — green. `M59-AC3` asserts eight whole messages, each at 1 in the misuse
  log and 0 in the control: the four refusal messages for entries 5-8 (no
  `name:`, an empty one, the name `2nd index`, a repeated `notes`) and, beside
  each, the further message that its `index-labels:` sets no word. None is
  matched by prefix. The whole-render pin `M59-AC1/AC2/AC3 (total)` holds that
  render to 18 extension warnings, the figure the block's per-writing-site
  oracle table derives. One qualification: the gate fix for finding F2 below
  reworded that further message from "an index-labels: map" to "an
  index-labels: key", because the code never looks at the value's shape; for
  all four fixture entries, which write maps, the message still says the map
  the author wrote sets no word.

- AC4 — green, on the new `examples/index-labels-clash.qmd`. `M59-AC4` counts
  the whole report naming the word `A` and the index `minerals` at exactly 1;
  `M59-AC4 (silence)` counts the report the `fossils` index would draw, spelled
  out in full, at 0, so a report firing on every declared word fails there; the
  render's own total is pinned at 1. `M59-AC4 (print)` holds the page to a
  10-row manifest across 2 sections, which shows both `A` groups still printed
  in their own places and both `fossils` groups likewise. The two clash needles
  also count 0 on both other label fixtures.

- AC5 — green, by reading the three files. `site/letter-groups.qmd` and
  `site/cross-references.qmd` each name the four refused shapes — empty,
  a value made only of characters that print nothing, a nested map, a list —
  and each states the fallback ladder a refused key takes; both ladder
  sentences were narrowed at the gate (finding F5) because they ran the two
  punctuation marks through `lang:`, which no language row holds.
  `CHANGELOG.md` carries three entries, one per behavior change, naming
  `M59-AC1/AC2`, `M59-AC3` and `M59-AC4` as the checks that fail without them.

- AC6 — green over the tree that ships. `tests/run-tests.sh` reports "All
  checks passed (486 checks)" and exits 0; `tests/run-tests.sh --self-test`
  reports 934 and exits 0. Both were re-run after the four gate fixes, and the
  six M59 T7 plants each ran red for their own named reason inside that second
  self-test run. `main` has not moved since the branch was cut (`git rev-list
  --left-right --count main...HEAD` is 0 ahead on the left), so this tree is
  the merged tree.

### Consistency gate

`python3 cairn_validate.py` — exit 0, every check PASS, every advisory OK; the
`release window` advisory did not fire. No `DESIGN.md` principle changed (the
diff touches the architecture module list and the Known-issues section only),
so no Sync Impact Report was owed. The `generic` profile's `consistency-gate`
slot names no toolchain checks, so that half is a clean no-op.

### Independent review

Three fresh-context lenses, each on its own evidence base. The blame-history
lens reported no findings: it traced the reworded empty-value report, the
74 -> 77 `warn-distinct` pin, the four closed Known-issues entries and the M56
total pin moving into the M59 block, and found each a documented supersession
rather than a silent regression. The prior-review lens reported no findings:
the four archived findings its subject matter overlaps — the read ordering
KI177 names, the per-index message coverage KI183 names, the whole-render pin
KI181 names and the plant-reimplementation lesson KI180 taught — are each
aligned with rather than reintroduced. The diff-bug lens reported nine, ranked;
it also re-ran the filter under plain pandoc in its own scratch copy and
independently reproduced the 18-warning and 1-warning totals and the two-`A`
clash page.

Four fixed at the gate:

- F2. `report_dropped_labels` emitted "also writes an `index-labels:` map"
  without looking at the value's shape, so an entry refused as a declaration
  that wrote a string or a list there was told about a map it never wrote.
  Fixed: the message names the key, not the shape. The four whole-message
  needles, the changelog entry and both documentation pages moved with it.
- F5. The fallback-ladder sentence this branch added to `CHANGELOG.md`,
  `site/letter-groups.qmd` and `site/cross-references.qmd` ran a refused value
  for either punctuation key through the document's `lang:`. No language row
  holds either key — which the M58 changelog entry and a later paragraph of
  `site/letter-groups.qmd` both already say. Fixed: each sentence now sends the
  two marks straight back to `,` and `;`.
- F4. A live self-test comment and its plant label still said the misuse
  fixture "reports six times"; this branch made that eighteen. Fixed, and the
  figure now cites the M59 block's own derivation rather than restating a count.
- F8. `read_declaration`'s docblock was left above the newly inserted
  `report_dropped_labels`, so it read as documenting that function. Fixed by
  moving the block to sit on `read_declaration` again.

One rejected:

- F7. The clash report names "this document" rather than an index in a document
  declaring fewer than two indexes, because it goes through `scope_phrase`.
  That is the repo's established convention for a scoped report (D-021, D-022),
  it is not a line this diff modified, and AC4's fixture declares two indexes.

Four deferred as Known-issues entries behind the existing candidate row for the
checks fencing the label surface, which this pass extends to name M59:

- F1. Ten of the twelve new zero-expectation controls cannot fail: the needles
  name `strata`, `minerals`, `fossils` and entries 5-8, none of which the
  control fixture declares, so no filter behavior could put those strings in
  its log. Only the two document-level controls discriminate.
- F9. No T7 plant fences the silence half of AC4 — the `M59_NOCLASH` zero-count
  and the clash render's total of 1 have not been shown red.
- F3. The changelog says the clash report fires for HTML and EPUB. The dispatch
  read supports it (`builds_ast_index` is `is_html() or is_epub()`), but the
  clash fixture is rendered to HTML only, so nothing would catch the sentence
  becoming false.
- F6. 25 of the 27 `BLANKS` entries are unexercised by any render; a transposed
  codepoint in the list would ship silently.
