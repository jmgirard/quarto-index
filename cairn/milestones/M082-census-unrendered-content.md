# M082: The id census stays out of content the page does not render as markup

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M081
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the census decides which id an author's mark keeps on the rendered page, and two author-facing pages state the rule.
- **Branch/PR:** m082-census-unrendered-content

## Goal

Two shapes whose content a browser does not render as page markup are read the
way a browser reads them in ordinary HTML — a `template` element's contents,
which a browser parses into a fragment of its own, and a `script` element's
escaped and double-escaped states, in which a `<!--` and a nested `<script>`
keep a browser inside the outer element past the first `</script>` — and the
fixture gains the case for an `id=` on a raw-text element's own opening tag,
which the census must still claim.

## Scope

**In:** `note_raw`'s reading of `template` and of a `script` element's content
(`_extensions/index/modules/html.lua:545-653`); the same two shapes in
`tests/htmlindex.py`, whose reader parses a `template`'s content as page
markup and ends a `script` at its first `</script>`, so the names the census
must leave alone come back from it as elements of the page; new cases in
`examples/id-collision.qmd` and their rows in the M079-AC1 expectation dicts;
a plant per repair; the matching paragraphs of `site/html.qmd` and
`CHANGELOG.md`, the M079-AC5 claim rows that pin the retired reading — the
skipped-elements row extended to quote the seven element names rather than
"those seven elements" — and the forbidden-phrase list; striking KI256, KI258,
KI259 and KI262 from `DESIGN.md`.

**Out:** the two comment shapes → M081, which this depends on: bounding a
`template`'s content means finding its matching `</template>`, and one written
inside a comment must not close it, which is only correct on top of M081's
comment reading. A `style` or `script` inside `svg` or `math` → stays KI261 on
its candidate row; confirming it needs a browser this repo does not run. KI254
and KI255 → their existing candidate rows.

## Acceptance criteria

- [ ] AC1: In the HTML render of `examples/id-collision.qmd`, each mark written
      with a name the fixture writes inside a `template` element's content —
      one directly inside, one inside a `template` nested in another, and one
      between the inner and the outer `</template>` — keeps that name on its
      own span, with no refusal report naming its term.
- [ ] AC2: In that same render, the mark written with the name the fixture puts
      on a rendered element standing after the outer `</template>` in that same
      raw block, the mark written with the name on a `template`'s own opening
      tag, and the mark written with the name on a rendered element standing
      after a `template` whose content holds a `</template>` inside a comment,
      are each anchored on a minted `qi-mark-` id with their refusal reports in
      the render log.
- [ ] AC3: In that same render, the mark written with the name the fixture
      writes after the first `</script>` of a double-escaped `script` element
      keeps that name on its own span, with no refusal report naming its term;
      and the marks written with the two names the fixture puts after the
      second `</script>` of that element and after the `</script>` of a merely
      escaped script — one whose `<!--` is followed by no nested `<script>` —
      are each anchored on a minted `qi-mark-` id with their refusal reports in
      the log.
- [ ] AC4: In that same render, the mark written with the name the fixture
      writes on a `style` element's own opening tag is anchored on a minted
      `qi-mark-` id with its refusal report in the log.
- [ ] AC5: `site/html.qmd` and `CHANGELOG.md` each state that the census reads
      both shapes the way a browser reads them in ordinary HTML; the sentences
      each carries today naming a `template`'s content or a script's
      nested-script state as ones the reading gets wrong are gone from both;
      and the residue sentence each carries about how many such shapes there
      are is removed or restated against what remains.
- [ ] AC6: `tests/run-tests.sh` passes, and passes with `--self-test`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T1
- AC5 → T5
- AC6 → T4, T5

## Tasks

- [ ] T1: Write the fixture cases into `examples/id-collision.qmd` — a
      `template` holding a name directly, a nested `template` holding one, a
      name between the two closes, a name on a rendered element after the outer
      close, a name on a `template`'s own opening tag, a `template` whose
      content holds a `</template>` inside a comment with a name on a rendered
      element after the real close; a double-escaped `script` with names after
      its first and second `</script>`; a merely escaped `script` with a name
      after its `</script>`; and an `id=` on a `style` element's own opening
      tag. Each gets its mark. Add their rows to the M079-AC1 expectation dicts
      and rewrite the derivation comment's arithmetic whole (the M080 lesson).
      Run the leg first and record which new rows are red before any repair.
- [ ] T2: Repair the `template` reading in `note_raw`: an `id=` inside a
      `template` element's content is not claimed, nesting is tracked rather
      than stopping at the first `</template>`, and the walk resumes after the
      matching close. Teach `tests/htmlindex.py` the same reading, so the
      suite's own reader stops returning a template's content as elements of
      the page.
- [ ] T3: Repair the script escape state: inside a `script` element's content a
      `<!--` followed by a nested `<script>` keeps the walk inside the outer
      element past the first `</script>`; a `</script` returns it to the
      escaped state and a `-->` before any nested tag leaves that state. Teach
      `tests/htmlindex.py` the same states, its reader ending a `script` at the
      first `</script>` today.
- [ ] T4: Add one `--self-test` plant per repair — one substitution each into
      `note_raw`, re-rendering the fixture and requiring the M079-AC1 leg red
      with a named string (M32's per-clause rule, not one plant for the
      census).
- [ ] T5: Rewrite the matching paragraphs of `site/html.qmd` and
      `CHANGELOG.md`, restating or removing each page's residue sentence rather
      than leaving it counting shapes that are gone; replace the M079-AC5 claim
      rows that pin the retired reading; extend the skipped-elements claim row
      (`tests/run-tests.sh:4375`) to quote the seven element names; and add each
      retired `site/html.qmd` sentence to the forbidden-phrase list with its
      plant.
- [ ] T6: Strike KI256, KI258, KI259 and KI262 from `DESIGN.md`, rewrite the
      census paragraph there, and rewrite the candidate rows pointing at them.

## Work log

- 2026-09-06: created by /milestone-plan.
- 2026-09-06: plan gate chose pinning the docs page's seven element names in the suite's own claim row over a scan reading `RAW_TEXT_ELEMENTS` out of the Lua source, because D-011 refuses widening a source-shape scan and the rendered fixture already reddens on a change to that table (dropping `noembed` reddens the `after-noembed` row); falsified by a change to the documented list that no rendered case distinguishes.
- 2026-09-06: plan gate chose adding rows to the standing forbidden-phrase check over leaving the retired sentences unpinned, D-027 having retired the claim-container registry while keeping exactly this standalone shape and D-028 keeping checks that name their own page; falsified by the list growing into a registry of pinned prose rather than a handful of retired sentences.
- 2026-09-06: criteria audit ran in full mode over the split wording. Four findings, all fixed: the goal needed bounding to non-foreign content and did not cover the raw-text opening-tag case it ships; AC1's nested-`template` probe did not discriminate depth-tracking from a naive skip to the first close, so the between-the-two-closes mark was added; AC4 left its element unnamed and could conflate with AC3's script, so it names `style`; AC5 did not reach the residue sentence both pages carry about how many misread shapes remain. The auditor also found the M082-on-M081 dependency to be substantive rather than editorial — a `</template>` inside a comment must not close the template — and that case is now in AC2.
- 2026-09-06: implement gate chose restating the two pages' residue sentence toward the one shape that remains — a `<![CDATA[…]]>` inside `svg` or `math`, which a browser runs to `]]>` and this reading ends at the first `>` — over removing it, and chose stopping at the end of a raw string on an unclosed `<template>` (as for an unclosed comment) with no fixture case for it.
- 2026-09-06: amendment (substantive, Scope In): `tests/htmlindex.py` added to Scope. Its reader parses a `template`'s content as page markup and ends a `script` at its first `</script>`, so every name AC1 and AC3 require the census to leave alone comes back from it as a second element carrying that name and the fixture cannot express the criteria; verified by parsing both shapes through `htmlindex.parse_text` before the gate. Chosen over re-planning at the mini gate.

## Decisions

## Review
