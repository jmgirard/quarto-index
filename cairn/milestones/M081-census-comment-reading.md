# M081: The id census reads a comment where a browser reads one

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the census decides which id an author's mark keeps on the rendered page, and two author-facing pages state the rule.
- **Branch/PR:** m081-census-comment-reading

## Goal

Two comment shapes the id census reads wrongly are read the way a browser
reads them in ordinary HTML: a construct a browser makes a comment and this
walk reads as markup (`<!ok>`, `<?ok>`, `<![CDATA[…]]>`, `</ ok>`), and the
three ways a browser ends a comment that this walk does not (`<!-->`,
`<!--->`, a `--!>` close). What a browser does with either inside `svg` or
`math` is outside this, nothing here being checked against a browser.

## Scope

**In:** the comment-open and comment-close reading in `note_raw`
(`_extensions/index/modules/html.lua:545-653`); new cases in
`examples/id-collision.qmd` and their rows in the M079-AC1 expectation dicts
(`tests/run-tests.sh:4043-4103`); the first `--self-test` plants over the
census; the comment paragraphs of `site/html.qmd` and `CHANGELOG.md`, the
M079-AC5 claim rows that pin the retired reading, and the forbidden-phrase
list; striking KI257 and KI260 from `DESIGN.md`.

**Out:** a `template` element's content, a `script` element's double-escape
state, and the missing case for an `id=` on a raw-text element's own opening
tag → M082. A `style` or `script` inside `svg` or `math` → stays KI261 on its
candidate row; confirming it needs a browser this repo does not run. A
text-content element outside the seven (KI254) and an id Quarto's writer makes
after the filter runs (KI255) → their existing candidate rows.

## Acceptance criteria

- [ ] AC1: In the HTML render of `examples/id-collision.qmd`, for each of the
      four bogus-comment spellings the fixture writes — `<!ok>`, `<?ok>`,
      `<![CDATA[…]]>`, `</ ok>` — the mark written with the name today's walk
      claims from a quoted `id=` inside that construct keeps that name on its
      own span, and the render log carries no refusal report naming that
      mark's term.
- [ ] AC2: In that same render, for each of those four spellings, the mark
      written with the name the fixture puts on a rendered element standing
      after that construct's first `>`, in that same raw block, is anchored on
      a minted `qi-mark-` id and its refusal report is in the render log.
- [ ] AC3: In that same render, for each of the three comment-end spellings the
      fixture writes — `<!-->`, `<!--->`, and a `--!>` close — the mark written
      with the name the fixture puts on a rendered element standing after that
      comment, in that same raw block, is anchored on a minted `qi-mark-` id
      and its refusal report is in the render log; and the mark written with
      the name the fixture writes inside a `--!>`-closed comment keeps that
      name on its own span, with no refusal report naming its term.
- [ ] AC4: `site/html.qmd` and `CHANGELOG.md` each state that the census reads
      both comment shapes the way a browser reads them in ordinary HTML, and
      the sentence each carries today naming a comment not spelled `<!--` as
      one the reading gets wrong is gone from both.
- [ ] AC5: `tests/run-tests.sh` passes, and passes with `--self-test`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T5
- AC5 → T4, T5

## Tasks

- [ ] T1: Write the fixture cases into `examples/id-collision.qmd` — for each
      of the four bogus-comment spellings, a quoted `id=` inside the construct
      and a second name on a rendered element after its first `>`, both in one
      raw block; for each of the three comment-end spellings, a name on a
      rendered element after the comment in one raw block; and one name inside
      a `--!>`-closed comment. Each gets its mark. Add their rows to the
      M079-AC1 expectation dicts and rewrite the derivation comment's
      arithmetic whole rather than patching one count (the M080 lesson). Run
      the leg first and record which new rows are red before any repair.
- [ ] T2: Repair the comment-open reading in `note_raw`: a `<` beginning `<!`
      other than `<!--`, a `<?`, or a `</` followed by a non-letter ends at the
      next `>`, and the walk resumes after it.
- [ ] T3: Repair the comment-close reading: a comment opened by `<!--` also
      ends at an immediate `>`, at an immediate `->`, and at a `--!>`.
- [ ] T4: Add one `--self-test` plant per repair — one substitution each into
      `note_raw`, re-rendering the fixture and requiring the M079-AC1 leg red
      with a named string. These are the repo's first plants over the census;
      one per repair, not one for the census (M32's granularity rule).
- [ ] T5: Rewrite the comment paragraphs of `site/html.qmd` and `CHANGELOG.md`,
      replace the M079-AC5 claim rows that pin the retired reading
      (`tests/run-tests.sh:4380-4385`), extend the forbidden-phrase list with
      each retired `site/html.qmd` sentence and plant it. `phrase-absent`
      sweeps `site/*.qmd` and `README.md` only, so `CHANGELOG.md` is held by
      its claim row, not by that list.
- [ ] T6: Strike KI257 and KI260 from `DESIGN.md`, rewrite the census paragraph
      there (`cairn/DESIGN.md:379-390`), and rewrite the two candidate rows
      pointing at them.

## Work log

- 2026-09-06: created by /milestone-plan.
- 2026-09-06: plan gate chose repairing the walk's own comment reading over widening the skip list or pattern-matching the raw string, because the walk already models a browser shape by shape and the alternatives reintroduce the over-collection M080 removed; falsified by a comment shape whose correct reading needs document-wide state the walk cannot carry across raw strings.
- 2026-09-06: plan gate chose two milestones over one covering all four shapes, because the four repairs are independently shippable and one file risked the 150-line cap; falsified by the two branches proving to need the same `note_raw` rewrite.
- 2026-09-06: criteria audit ran in full mode, twice. First pass: six findings — the goal claimed four shapes where six stand and opened with an unreachable universal; three criteria tested only that a hidden name stops being counted, so an implementation abandoning the rest of the raw string passed all three. All fixed pre-gate. Second pass over the split wording: the goal needed bounding to non-foreign content, AC3 needed the inside-a-`--!>`-comment mark, and AC4's negative half named a domain no procedure enumerates and reached `CHANGELOG.md`, which `phrase-absent` does not sweep. All fixed.
- 2026-09-06: T1 — twelve fixture marks written into `examples/id-collision.qmd` (four `bogus-*` inside a bogus-comment construct, four `beyond-*` after one, three `beyond-*-comment` after a comment-end spelling, one `hidden-bang-close` inside a `--!>`-closed comment) and their rows added to the M079-AC1 dicts as `CONTESTED_COMMENT`/`KEPT_COMMENT`; the derivation comment's arithmetic rewritten whole to fifty-four. Leg run before any repair: red on the four `bogus-*` names counted and their marks yielded, and on the three `beyond-*-comment` names uncounted and left on two elements; the four `beyond-*` bogus-comment names and `hidden-bang-close` already passed.
- 2026-09-06: T1 — the M079-AC1 check moved from a stdin heredoc into `$WORK/id-collision-ids.py`, run from there, so T4's plants can redden that same check rather than a stand-in (question gate).
- 2026-09-06: T2, T3 — `note_raw` now reads a `<!` opening anything but `<!--`, a `<?`, and a `</` before a non-letter as comments running to the next `>`, and ends a `<!--` at an immediate `>`, an immediate `->`, a `-->` or a `--!>`. Checked shape by shape in a `pandoc lua` harness over `note_raw` before the fixture render: all seven new shapes and the `<!-- … -->` control read as a browser reads them.
- 2026-09-06: T4 — two `--self-test` plants over the census, one per repair (bogus-comment opening read as markup; comment ended at `-->` only), each rendering the fixture from a mutated copy of the extension and requiring the same M079-AC1 check red with its own named string, behind a green control on an unmutated copy. Both verified red by hand against a scratch render before being written in.
- 2026-09-06: T5, T6 — comment prose rewritten in `site/html.qmd` and folded into the unreleased `CHANGELOG.md` entry (question gate chose editing that entry over adding a fourth); the retired M079-AC5 claim row replaced by three pinning the new reading; a new M081-AC4 `phrase-absent` sweep with its own list and plant, given its own list rather than a row under the back-end-count list whose FAIL message names that count by hand (minor deviation from T5's wording); KI257 and KI260 struck from `DESIGN.md`, the census paragraph rewritten, KI262's `phrase-absent` clause corrected, and the M079-instruments candidate row narrowed — no candidate row cited KI257 or KI260, so none needed rewriting.
- 2026-09-06: checkpoint with every task box still unticked: the full `tests/run-tests.sh --self-test` run that has to be clean before any of them is ticked was still in flight when this commit was made.

## Decisions

## Review
