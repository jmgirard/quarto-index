# M29: A marker report in a book names its chapter

- **Status:** review
- **Priority:** normal
- **Depends on:** M28
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** `m029-book-chapter-in-report` / https://github.com/jmgirard/quarto-index/pull/29

## Goal

A placement-marker report drawn while rendering a book chapter to HTML names
the chapter file it is about, as the book-aware marker warnings already do.

## Scope

Surface tier: **user-facing** — the deliverable is warning text authors read.

**In:** the emptied-place report (`marker.lua:206`) and the duplicate-marker
report (`marker.lua:246`) carry the chapter file when one is known. Marker
resolution runs at `index.lua:65`, before `book_context` is computed at
`index.lua:70`, so making the chapter file available there is the milestone's
one structural change. Absorbed from M28's review: KI80 — the duplicate-marker
report introduces the shared position clause with "Both numbers are", so its
source-divergence tail misdescribes the marker ordinal, which is no position.
The repair renames that introduction to the block position; the shared
`POSITION_BASIS` string (`marker.lua:31`) is NOT split, so D-014's consequence
that the two reports cannot drift apart survives, and D-014's own "each is
named where it is printed" is what licenses naming the ordinal separately. A
book fixture exercises the emptied-place report in `examples/book/sub/two.qmd`
and the duplicate-marker report in `examples/book/last.qmd`. The two chapters
differ deliberately: `sub/two.qmd` gives the clause a subdirectory path to
carry, and `last.qmd` is the only chapter a second placement marker can go in
without becoming the book's placing chapter and moving the index. The pdf book
render pins that both reports carry no chapter clause.

**Out:** the incomplete-metadata HTML case (`index.lua:75-78`), where Quarto
supplies too little for `book_context` to return a chapter — no fixture can
produce that state without fabricating metadata Quarto does not emit, which is
the private-structure modelling M12's gate refused; it stays uncovered and gets
its own Known-issues entry. KI82's three-copy suite duplication of the position
clause is accepted, not repaired: M28's review filed it as cost rather than a
hole, T3 adds a fourth copy, and ownership stays on the acceptance-suite
hardening candidate row. Naming the sequence a number counts → M28, which this
milestone depends on.

## Acceptance criteria

- [x] AC1: In the html render of `examples/book`, a nested marker that empties
      its place in the chapter `sub/two.qmd` draws an emptied-place report
      whose whole emitted line names that chapter's path as `sub/two.qmd` —
      root-relative, as the book-aware marker warnings name `ctx.file` —
      immediately after its block position, and is otherwise the emptied-place
      report's no-chapter text of AC3 with only its block number free to differ.
- [x] AC2: In that same html render, a second top-level marker in `last.qmd`
      draws a duplicate-marker report whose whole emitted line names that
      chapter's path as `last.qmd` immediately after its block position, and is
      otherwise the duplicate-marker report's no-chapter text of AC3 with only
      its block number and marker ordinal free to differ.
- [x] AC3: In the pdf render of `examples/book`, the emptied-place and
      duplicate-marker reports each emit a line carrying no chapter clause,
      and each such line is the text M28 shipped except for AC4's change.
- [x] AC4: In the html, latex and gfm renders of `examples/marker-misuse.qmd`,
      the duplicate-marker report's whole emitted line introduces the shared
      position clause as being about its block position rather than about both
      of its numbers, so the source-divergence tail no longer describes the
      marker ordinal (KI80).
- [x] AC5: Every warning line in the captured logs of `examples/marker-shapes.qmd`
      in html, latex and gfm, and of `examples/book` in html and pdf, is either
      one of those fixtures' known other warnings or one of this milestone's two
      report templates with only its block number, marker ordinal and chapter
      clause varying — judged line by line over the whole of each log.
- [x] AC6: `tests/run-tests.sh` passes, and `tests/run-tests.sh --self-test`
      passes.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T2, T4
- AC3 → T2, T4
- AC4 → T3, T4
- AC5 → T4
- AC6 → T4

## Tasks

- [x] T1: make the chapter file available where marker resolution runs —
      either by deriving it before `qi_marker.resolve_markers` at
      `index.lua:65` or by passing it in — without moving the book-path
      decisions that read the full `book_context` (`index.lua:70`). The file
      is available only where a chapter is genuinely known, so the pdf book
      render reaches the no-chapter wording by the same path a single document
      does.
- [x] T2: splice the file clause into the two reports (`marker.lua:206`,
      `marker.lua:246`), keeping M28's wording verbatim where no chapter is
      known, apart from T3's repair.
- [x] T3: repair KI80 — rename the duplicate-marker report's introduction of
      the shared clause from both numbers to its block position, leaving
      `POSITION_BASIS` (`marker.lua:31`) one shared string (D-014).
- [x] T4: suite — add the emptied-place shape to `examples/book/sub/two.qmd`
      and the duplicate shape to `examples/book/last.qmd`; update the
      `BOOK_WARNINGS` count (`tests/run-tests.sh:4631`); assert both reports
      whole in
      `$WORK/book-html.log` and `$WORK/book-pdf.log`; extend the whole-warning
      line partition to both book logs; replace the substring pin
      `WARN_MARKER_DUP` (`tests/run-tests.sh:2742`) with a whole-line
      comparison; update the three existing copies of the position clause
      (`run-tests.sh` twice, `tests/m28pos.py` once) for T3's reword; pass
      every new grep key to the key-distinctness scan (M18).
- [x] T5: in `cairn/DESIGN.md`, rewrite KI22 to keep its chapter-local
      position half and strike its names-no-file half, strike KI80, and add
      the Known-issues entry for the uncovered incomplete-metadata HTML case;
      rewrite any candidate row pointing at them, in the same commit (D-013).

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan gate chose narrowing the fallback criterion to the non-HTML book render over building a fixture for the incomplete-metadata HTML case because that state needs metadata Quarto does not emit; falsified by a real Quarto configuration that reaches `index.lua:75-78` on its own.
- 2026-08-23: criteria audit for this milestone ran in FULL mode ([O] fresh- context reader, user-facing tier) in the same round as M28's; its findings on M29-AC3, AC4 and AC5 are recorded in M28's work log with the rest.
- 2026-08-24: amended by /milestone-plan. Gate absorbed KI80 into scope over leaving it standing as a homeless known issue, because M29's T2 already rewrites that warning's format string; falsified by the repair proving to need a D-014 supersession. Gate accepted KI82 over deduping the suite's three copies, because M28's review judged it cost rather than a hole; falsified by a reword landing that the three-copy coupling lets drift through silently.
- 2026-08-24: criteria audit ran again in FULL mode ([O] fresh-context reader, user-facing tier) over the amended criteria and returned twelve findings. Fixed at the gate: the chapter probe moved to `sub/two.qmd` so its path form varies as well as its position; AC2 now requires the same non-first chapter as AC1; AC3 names `examples/book` and the pdf render rather than "a non-HTML format", and T1 now states the gate that makes the no-chapter state reachable; AC1-AC4 rewritten to bind the emitted line rather than the comparison method, which moved to T4; AC5's partition extended to the book logs, which no criterion previously covered; T5 rewrites KI22 rather than striking it, since AC1 repairs only its second half. The auditor's finding that KI80 and D-014 cannot both hold was refuted at the gate: renaming the duplicate report's introduction of the shared clause satisfies both without splitting the string. AC6 was kept instrument-bound against the audit's reading, as the regression gate every milestone in this repo carries.
- 2026-08-24: implement gate chose attaching the chapter to the block position ("top-level block 5 of sub/two.qmd") over a leading or trailing clause, because scoping the number is what the clause is for and it states KI22's chapter-local half in the text; falsified by an author reading the position as the book's rather than the chapter's anyway.
- 2026-08-24: T1 — hoisted `book_context` above `resolve_markers` in `index.lua` and passed `book and book.file` down, leaving the `is_html` gate and the post-resolution book decisions where they were; the gate is what keeps a pdf book on the no-chapter path.
- 2026-08-24: T2 — added `in_chapter` beside `POSITION_BASIS` in `marker.lua` and threaded `chapter` through `resolve_markers` and `strip_nested_markers`; nil chapter emits the empty string, so every non-book render is byte-identical to M28.
- 2026-08-24: T3 — KI80 repaired by renaming the duplicate report's introduction of the shared clause from "Both numbers are" to "Block positions are"; `POSITION_BASIS` stays one string, so D-014's no-drift consequence holds. Rejected splitting the string into a per-report tail because that is the drift D-014 names; falsified by a later report needing a divergence clause the block-position wording cannot carry.
- 2026-08-24: amendment (substantive, gated). A render showed a second top-level marker in `sub/two.qmd` would make it the book's placing chapter over `last.qmd` and move the index, so AC2's duplicate probe moved to `last.qmd`; Scope and T4 retargeted with it. Two fresh-context [O] readers audited the amended wording in FULL mode; their findings fixed before writing: "unchanged" became "free to differ" (the pdf book concatenates chapters, so the block number and ordinal cannot match), the path form pinned as root-relative, and the clause pinned to sit immediately after the block position. AC1 and AC2 are the only criteria whose text changed.
- 2026-08-24: T4 — added `tests/m29book.py`, which partitions every extension warning in a log against the fixture's other known warnings and two end-anchored report patterns whose only free parts are the block position, the marker ordinal and the chapter clause; run over the HTML book, the PDF book and the three misuse logs. Five planted logs prove it able to fail — clause moved off the position, clause dropped where a chapter is known, clause added where none is, a warning in neither partition, and a log with none of our warnings — each asserted to fail for its own reason. `BOOK_WARNINGS` 4 to 7. The M28 both-numbers assertion was rewritten to AC4's claim, with a control that fails if "Both numbers are" returns.
- 2026-08-24: T4 — the fixture edits to `examples/book/sub/two.qmd` and `examples/book/last.qmd` were in the working tree when T1-T3 was committed, so they landed in 77c5ab5 rather than the T4 commit.
- 2026-08-24: T4 — no new shell grep key was introduced, so the M18 key-distinctness scan's argument list is unchanged; `tests/m29book.py` matches by its own end-anchored patterns rather than by a `WARN_` constant. `tests/m28pos.py` needed no edit either: it holds the shared clause tail only, not the duplicate report's lead-in, so KI82's three copies cost two edits here rather than three.
- 2026-08-24: T4 — the PDF book render confirmed what the amendment's wording rests on: the merged document reports block 26 and block 34 where the HTML chapters report 8 and 5, and the marker ordinal is 2 in both, so "free to differ" is the satisfiable form and a flat "unchanged" would not have been.
- 2026-08-24: T5 — KI22 struck whole rather than half-rewritten as the task said: attaching the clause to the position ("top-level block 5 of sub/two.qmd") states the chapter-local half in the text as well, so neither half survives. KI80 struck. KI83 added for the unprobed incomplete-metadata HTML path. No candidate row pointed at either struck entry, so none needed rewriting; the ROADMAP's hygiene stamp names KI80 as a record of the last pass and is replaced, not edited, at the next one.
- 2026-08-24: T5 — DESIGN.md's marker-resolution paragraph updated to say the reports carry the chapter and that a chapter is known only in an HTML book.
- 2026-08-24: all five tasks done; `tests/run-tests.sh` passes 296 checks and `tests/run-tests.sh --self-test` passes 430. Status to review.

- 2026-08-24: review opened; draft PR #29 recorded in the header. Suite run and the three review lenses are in flight.
## Decisions

## Review

Fresh evidence, 2026-08-24, branch `m029-book-chapter-in-report` at 2875f2e,
PR #29. Whole suite run: `tests/run-tests.sh`.

- AC1 — met. The HTML book render emits, whole: `index placement marker in
  top-level block 8 of sub/two.qmd was the only thing written where it stood;
  the marker is removed, so nothing you wrote remains there. Block positions
  are counted over the document as this filter received it, ...`. The clause
  sits immediately after the block position, names the chapter root-relative,
  and the line is otherwise AC3's pdf text with only `8` against `26` free to
  differ. Pinned by `tests/m29book.py` in `book-html` mode with an end-anchored
  whole-line pattern; two planted logs prove it able to fail (clause moved to
  the line's end, clause dropped), each failing for its own reason.
- AC2 — met. Same render, whole: `index placement marker 2 in document order
  (top-level block 5) of last.qmd is ignored; the index is placed at the first
  marker. Block positions are counted over ...`. Clause immediately after the
  block position; otherwise AC3's pdf duplicate text with only the block number
  (5 against 34) free to differ, the ordinal being 2 in both. Same partition
  check, same planted-defect proofs.
- AC3 — met. The pdf book render emits both reports with no chapter clause:
  `... in top-level block 26 was the only thing written where it stood; ...`
  and `... marker 2 in document order (top-level block 34) is ignored; ...`.
  Each is M28's shipped text but for AC4's reword of the duplicate report's
  lead-in. `tests/m29book.py` in `book-pdf` mode requires the clause absent; a
  planted pdf log carrying `of last.qmd` fails with `want None`.
- AC4 — met. In all three misuse renders the duplicate report reads `... is
  ignored; the index is placed at the first marker. Block positions are ...`;
  the suite asserts that lead-in, asserts the ordinal is still named by `in
  document order`, and carries a control that fails if `Both numbers are`
  returns. KI80 closed.
- AC5 — met, line by line over each of the five logs. The three
  `marker-shapes` logs: M12's partition, `of 34 warnings, the 13 that are not
  the fixture's two known ones are exactly the manifest's emptied-place
  reports`, in html, latex and gfm. The two book logs: `tests/m29book.py`,
  7 warnings in the html book partitioning into the fixture's known others and
  the two reports naming `last.qmd` and `sub/two.qmd`, and 4 in the pdf book
  naming no chapter. Two further planted logs prove the book partition closed
  rather than a template search — an extra warning belonging to neither
  partition, and a log holding none of our warnings at all.
- AC6 — met. `tests/run-tests.sh` exit 0, 296 checks. `tests/run-tests.sh
  --self-test` exit 0, 430 checks.

Consistency gate: `cairn_validate` exit 0, all 16 checks PASS and 7 advisories
OK. No IP/GP principle text changed, so `cairn_impact` does not apply. Active
profile is `generic`, whose `consistency-gate` slot names no toolchain checks.

### Independent fresh-context review

Three lenses, none having seen the implementation. [S] blame-history: no
findings — it checked for a data dependency the `book_context` hoist could
break and found `book_context` reads only `doc.meta`, `quarto.project` and
`quarto.doc`, none of which marker resolution mutates. [S] prior-review
record: no findings; `gh api .../pulls/comments` returned `[]`, so the PR-thread
walk was correctly skipped and the archived `## Review` sections were the whole
evidence base. [O] diff-bug: fifteen findings, below in its own ranking.

- F1 (rejected, refuted against the implementation). "The partition is only
  tail-anchored, so text prepended to a report passes." Tested: a dup line with
  `chapter last.qmd: ` prepended fails `book-pdf` mode with `dup report matched
  0 line(s) ... want exactly 1`. `tests/.work/warn-patterns.txt` anchors every
  pattern at `^\(W\) `, so a prepended clause drops the line out of the set the
  partition is taken over, and a report count of 0 is itself a failure.
- F2 (fix now). The duplicate report puts the chapter clause outside the
  parenthesis holding the position — `(top-level block 5) of last.qmd` — where
  the emptied report reads `top-level block 8 of sub/two.qmd`.
- F3 (rejected). "The ordinal still says `in document order` inside a book
  chapter." In an HTML book the chapter IS the Pandoc document the filter
  received, which is what `POSITION_BASIS` says the numbers are counted over.
- F4 (fix now, confirmed by experiment). The `moved.log` planted probe runs two
  `sed` expressions; the second alone rewrites the duplicate line too and
  produces the expected `warning in neither partition`, so the probe would pass
  with the first expression no-oping.
- F5 (fix now). `KI82` says the position clause is written out three times in
  the suite; `tests/m29book.py` makes four, exactly as this milestone's Scope
  predicted.
- F6 (fix now). The three `misuse-$fmt` partitions are labeled `M29-AC3`, which
  is scoped to the pdf book render; they are AC4/AC5's no-book control.
- F7 (fix now). `tests/m29book.py` does not strip ANSI escapes, where the M12
  partition it extends does.
- F8 (follow-up). `(?P<chapter> of \S+)?` cannot express a chapter path holding
  a space, and `examples/book-order/` already ships `later chapter.qmd`.
- F9 (fix now). README's two marker bullets describe the reports without the
  chapter, on a user-facing-tier milestone.
- F10 (rejected). "The basis clause says `the document` while the same sentence
  names a chapter." The chapter is that document; F3's reason.
- F11 (follow-up). Only `book-html.log` carries a total extension-warning pin,
  so a repeated known-other warning in the pdf book or the misuse logs would
  pass the partition.
- F12 (rejected). The work log's "no new shell grep key was introduced" is
  about the `WARN_` constants the M18 distinctness scan takes as arguments, and
  none were added; the three new inline needles are not keys.
- F13 (fix now, as a work-log line). T4 said the `WARN_MARKER_DUP` substring pin
  would be replaced by a whole-line comparison; the whole-line comparison was
  added in `tests/m29book.py` and the substring pin left standing.
- F14 (rejected). `KI83` sits in the slot the struck `KI22`/`KI80` vacated,
  which is where it belongs thematically; labels are never reused, order is not
  a rule.
- F15 (fix now). The misuse pass line says "both marker reports" where that mode
  has one, and one `cairn/DESIGN.md` line runs to 106 columns.

No finding demonstrates an acceptance criterion failing, and none is a
load-bearing defect in what the extension does for authors, so the return floor
is not reached.
