# M39: The sort-key rival and dangling-target reports name the index they judge

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m039-report-index-scope`

## Goal

In a document that declares several indexes, the sort-key rival report says which index the rivalry is inside, and the dangling-target report's remedy names the index the term has to be marked in.

## Scope

Surface tier: **user-facing** — the deliverable is warning text an author of an indexed document reads.

**In:** the two reports D-021 left short of its own rule. `sortkeys.register_sort` gains a second `warn()` shape carrying `qi_indexes.scope_phrase`'s index words, fired only where a document declares several indexes and the back-end does not fold; `marks.report_dangling` gains a second shape whose remedy names that index instead of the shared "mark that term somewhere". A new fixture `examples/named-indexes-rival.qmd` carries the rival probe. The suite gains needles for the clause that VARIES in each report, not only the tail they share (the M38 lesson). An annotating D-entry records that D-021's accepted cost is paid.

**Out:** narrowing the remedy for the document, book and chapter scopes, which have one namespace and one remedy already — no work is planned; a candidate row is not opened for it, since the shared wording is correct there. Naming the index in any report beyond these two → no row: the report-scope candidate row named exactly these two, so this milestone absorbs it whole and the row is retired. Per-record index names for a book's chapters → the book-chapters candidate row.

## Acceptance criteria

- [ ] AC1: The HTML render of `examples/named-indexes-rival.qmd` — a document declaring two indexes, whose second files two different sort keys under one printed level path — draws exactly one sort-key rival report, whose line carries the scope phrase `index "<second declared name>"` exactly as `qi_indexes.scope_phrase` spells it, alongside the two rival keys the report already names; and no line of that log carries the one-namespace rival shape.
- [ ] AC2: The HTML render of `examples/named-indexes.qmd` draws exactly one dangling-target report — for the `entry="Stranger"` mark of its second declared index — whose remedy names that index as the place to mark the term; no line of that log carries the shared remedy text `mark that term somewhere`.
- [ ] AC3: A diff of the two message literals against the pre-milestone filter source shows the shared dangling-target message and the existing one-namespace rival message unchanged byte for byte; and the folded LaTeX render of `examples/named-indexes-rival.qmd` draws exactly one rival report, in that unchanged one-namespace shape, with no line carrying the new multi-index shape.
- [ ] AC4: The two message shapes this milestone adds are each distinct from every other `warn()` message template `tests/scans/warn-distinct.py` reads over the Lua source set, and neither is a prefix of any other template nor has any other template as a prefix.
- [ ] AC5: `tests/run-tests.sh --self-test` runs clean (the `verify` slot's fuller pre-review check).

## Coverage

- AC1 → T1, T2, T4, T5
- AC2 → T3, T4, T5
- AC3 → T1, T2, T3, T4, T5
- AC4 → T2, T3, T4, T5
- AC5 → T4, T5, T6

## Tasks

- [x] T1: New `examples/named-indexes-rival.qmd` — two declared indexes; in the SECOND, two marks of one printed level path with different `sort=` values. Constraints the audit fixed: the FIRST index carries no `sort=` on that path, or HTML draws two reports and the folded LaTeX render disagrees with HTML about which key wins; every term is one no other mark in the file indexes (M13 lesson); no `see=`/`see-also=`, or the dangling-corpus roster diff at `tests/run-tests.sh:8263` needs a manifest row.
- [x] T2: `_extensions/index/modules/sortkeys.lua:40` `register_sort` takes the caller's outer word, routes `index` through `qi_indexes.scope_phrase`, and emits a second `warn()` — its own single literal — only where the phrase differs from that word. The scope clause is inserted mid-message, BEFORE the `written here cannot apply as well` tail, so neither template is a prefix of the other. Update the `passes.lua:74` caller.
- [x] T3: `_extensions/index/modules/marks.lua:190` `report_dangling` gains a second `warn()` for the per-index scope, its remedy naming the index. It must diverge before the `;` so it does not carry the existing `SINGLE_LITERAL` needle `%s= on %s points at "%s", which no index mark in this %s indexes;` — the two calls sit inside that scan's 400-character window, so the new head must not be added to `SINGLE_LITERAL` either.
- [x] T4: Suite. Split `WARN_DANGLING` (`tests/run-tests.sh:2071`) into the shared and per-index remedy needles and update `dangling_report()`; re-needle the M38 block at `12466-12472`, whose count goes 1 → 0 against the old tail. Add the rival scope needle beside `WARN_SORT_CONFLICT` (`3172`) — `WARN_SORT_RIVAL` (`7598`) pins nothing, being used once at count 0. Render and capture the new fixture in HTML and LaTeX with its checks. Bump `warn-distinct` `EXPECTED` 64 → 66.
- [x] T5: Full `tests/run-tests.sh --self-test` green; record the evidence line for each criterion.
- [x] T6: Annotating D-entry on D-021 — the accepted cost is paid, the scope-word rule is unchanged, and the deferral pointer (which named the suite-hardening row) is corrected to the report-scope row. Update the DESIGN Reports section where it describes the scope words.

## Work log

- 2026-08-25: created by /milestone-plan.
- 2026-08-25: criteria audit ran in FULL mode (user-facing tier). Pass 1 returned six findings + one hazard: AC1's index grep pinned a bare string a term or key could supply; an appended scope clause would make the one-namespace template a strict prefix of the multi-index one; AC2's "the one report" was uncounted once `$WARN_DANGLING` stops matching; AC3 named `$WARN_SORT_RIVAL`, which is used once at count 0 and pins nothing; AC4 quantified over emitted text where the scan reads templates, and held unchanged pre-change; and the `SINGLE_LITERAL` 400-character window collides with a second dangling call however worded. Pass 2, over the three criteria the gate changed, returned two more: AC1 pinned no zero for the old shape, and AC3's first clause was unsatisfiable with intent (b) and had its domain defined by the instruments — "shrinking a needle's use satisfies the AC without the deliverable text being preserved". All fixed in the wording above; AC3 rebound to a byte diff of two literals plus one render's count, per D-118.
- 2026-08-25: plan gate chose a second rival message shape, fired only where the scope differs, over threading `scope_phrase(index, "document")` into the single existing message, because the latter adds a scope clause to the common zero-config case (GP4) that the mark's own context already locates and reworks every pinned rival render; falsified by an author report that the two rival shapes read as two different findings.
- 2026-08-25: plan gate chose a new `examples/named-indexes-rival.qmd` over extending `examples/named-indexes.qmd`, because the latter perturbs M38's pinned section manifest and letter sweep and walks into the M13 lesson's trap; falsified by the suite's render count becoming the binding cost.
- 2026-08-25: T1 — `examples/named-indexes-rival.qmd` written: `main`/`authors` declared, `Quokka` in the first with no sort key, `Ptarmigan` marked twice in the second with rival keys `Zebra` and `Yak`, no cross-reference target, a marker per index. Baseline render draws exactly one rival report in HTML and one in LaTeX, both in the one-namespace shape.
- 2026-08-25: T2 — `register_sort` takes an `outer` word (the caller passes `"document"`) and routes the index through `scope_phrase`; where the phrase differs it draws a second `warn()`, one literal, with the scope clause between the winning key and the shared tail. HTML render of the new fixture now reads `already sorted as "Zebra" in index "authors";`, the LaTeX render still reads the unchanged shape. `warn-distinct` EXPECTED 64 -> 65 here rather than in T4, so this task's verify run is clean; T4 takes it to 66. `tests/run-tests.sh` green, 378 checks.
- 2026-08-25: T3 — `report_dangling` now takes `(paths, xrefs, outer, index)` and calls `scope_phrase` itself, mirroring `register_sort`; the book's aggregated call passes no index and keeps its word. The one-namespace `warn()` is written FIRST and the per-index one second, so the distinctness scan's 400-character window around the named needle holds one owner. `warn-distinct` EXPECTED 65 -> 66.
- 2026-08-25: T3 and T4 share one checkpoint commit: the suite pins the message text T3 changes, so T3 alone cannot leave `verify` clean. Both task boxes and this line land with it.
- 2026-08-25: T4 — `WARN_DANGLING` kept for the shared shape and `WARN_DANGLING_INDEX` added for the per-index remedy, with `dangling_report_index()` beside `dangling_report()`; the M38-AC2 block now reads the per-index needle at 1, the whole per-index report at 1 and the shared remedy at 0. `WARN_SORT_RIVAL_SCOPED` added beside `WARN_SORT_CONFLICT`; the one-namespace rival shape has no needle of its own (a bare `";` sits inside the per-index shape too) and is pinned by its whole text instead. New M39 block renders and captures the rival fixture in HTML and LaTeX, each shape pinned at 1 on its own log and 0 on the other, over a `WARN_SORT_CONFLICT` count of 1 that holds the rivalry to one report. `tests/run-tests.sh` green, 381 checks.
- 2026-08-25: check discrimination — with `scope_phrase` short-circuited to the outer word in `sortkeys.lua`, the HTML rival counts read scoped 0 (wants 1) and plain 1 (wants 0); with the same plant in `marks.lua`, the HTML dangling counts read per-index 0 and whole-report 0 (each wants 1) and shared 1 (wants 0). Both plants reverted.
- 2026-08-25: T6 — D-022 appended, annotating D-021: the second of its two accepted costs is paid, the scope-word rule is unchanged, and its deferral pointer is corrected from the suite-hardening row to the report-scope row M39 absorbed. DESIGN's per-index bullet extended so the rule covers the remedy a report offers, not only the set it names.
- 2026-08-25: a comment added in T3 wrote the token `warn(` with no closing paren; `tests/scans/m15-joined-messages.py` reads raw source and balances parens from every `warn(`, so on the M16-AC3 moved tree that comment swallowed the next file and read one message as carrying both replacement-report shapes. Caught by `--self-test`, not by the plain run, because the moved tree reorders which file follows `marks.lua`. Comment reworded to `warn()`; the scan reads 70 messages on the moved tree and 66 on the shipped one.
- 2026-08-25: T5 evidence. AC1 — `named-indexes-rival-html.log`: `WARN_SORT_CONFLICT` 1, the whole scoped report `index entry in term "Ptarmigan" is already sorted as "Zebra" in index "authors"; the sort key "Yak" ...` 1, the whole one-namespace report 0. AC2 — `named-indexes-html.log`: `WARN_DANGLING_INDEX` 1, the whole per-index report for `entry="Stranger"` naming `index "authors"` twice 1, `WARN_DANGLING` 0. AC3 — `diff` of the shared dangling literal and of the one-namespace rival literal against `origin/main` is empty for both; `named-indexes-rival-latex.log`: `WARN_SORT_CONFLICT` 1, the whole one-namespace report 1, `WARN_SORT_RIVAL_SCOPED` 0. AC4 — `warn-distinct` reads 66 templates, all mutually distinct with no prefix relation, over the whole Lua source set. AC5 — `tests/run-tests.sh --self-test` exit 0, 562 checks.
- 2026-08-25: plan gate chose an annotating D-entry over letting the milestone record carry it, because D-021's Consequences state the shared-remedy cost as accepted and would otherwise read as standing; falsified by a convention that a paid cost needs no entry.

## Decisions

## Review
