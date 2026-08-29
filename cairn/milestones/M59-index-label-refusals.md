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

- [ ] AC1. The two invisible values `examples/index-labels-misuse.qmd` adds —
      a `&nbsp;` under `see-also:` at the document level and a zero-width
      space under `symbols:` in one `indexes:` entry — each draw the report an
      empty value draws, naming their own key and their own level, and each
      word prints as the English one. The characters counted as invisible are
      listed at one site in `_extensions/index/modules/indexes.lua`.
      (RB tripwire: ip-touching)
- [ ] AC2. The two flattened values that fixture adds — a `see:` written as a
      nested map and a `symbols:` written as a list — each draw a report
      naming their own key and their own level, and each word prints as the
      English one. Today the map case installs the map's joined leaf values
      with no report (`read_labels`, `indexes.lua`).
- [ ] AC3. For each of the four ways an `indexes:` entry is refused that can
      still carry a label map — no `name:`, an empty `name:`, a name of the
      wrong shape, a repeated name — the fixture writes one such entry
      carrying an `index-labels:` map, and each draws, beside the entry's own
      refusal message, one further message saying that map sets no word. The
      four messages are asserted whole, not by prefix.
- [ ] AC4. On a new fixture, an index whose `symbols:` word a printed letter
      group also heads draws a report naming the word and the index, and
      still prints both groups; a second index in the same fixture, whose
      `symbols:` word heads no letter group, draws no such report.
- [ ] AC5. `site/letter-groups.qmd` and `site/cross-references.qmd` each state
      which label values are refused — empty, invisible, a map, a list — and
      what a refused value falls back to; `CHANGELOG.md` carries one entry per
      behavior change, each naming a test that fails without it.
- [ ] AC6. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
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

## Decisions

- 2026-08-29 (T1): a label value made only of blank characters is refused, against a written-out list of 27 characters rather than a character property. The Lua Pandoc embeds ships no Unicode category tables, and `%s` follows the C locale, which would decide U+2007 one way on one machine and another way elsewhere. The list is the one site that says what blank means; a character nobody thought of prints and is not refused, which is the failure direction that leaves a reader with something to read.
- 2026-08-29 (T1): the refusal covers all five writable keys, the two punctuation ones included. An author who wanted a non-breaking space between a term and its locators is refused and gets the ASCII comma back; the candidate row for a way to ask for no word at all is where that request goes.
- 2026-08-29 (T3): the letter clash is compared character for character, not case-insensitively. A letter group always heads a capital, so `symbols: "a"` prints a heading a reader can tell from the `A` group's and draws nothing.

## Review
