<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M11: Empty index levels never lose the entry

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP2, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m11-empty-levels   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

An empty sub-entry level is dropped once, at the shared level-derivation layer,
so a leading empty level can no longer hand makeindex a null field that
silently destroys the whole entry.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable changes emitted output in both
back-ends and the documented meaning of `entry=`.

The defect, probed directly at plan time (makeindex 2.18, TeX Live 2026): an
`.idx` line `\indexentry{!Cats}{1}` is rejected with "Illegal null field", the
entry never reaches the `.ind`, and makeindex still prints "0 warnings" and
exits 0 — so Quarto's build is clean and the entry is simply gone. `index.lua`
emits exactly that today: `parse_levels` keeps the empty level, and
`index_argument` joins levels with an unquoted `!`. This is the silent
corruption IP2 forbids, and the same failure shape `clamp_levels` already
refuses for over-deep entries. The grammar can spell only two empty-level
shapes — leading and trailing — because `!!` is a literal `!`, so two adjacent
separators cannot be written; only the leading one is destructive.

**In:**
- `derive_levels` drops empty levels from a parsed `entry=` value before any
  back-end sees them; a value whose levels are all empty falls back to the
  span's visible text, as `entry=""` already does.
- `sort=` levels realign onto the surviving entry levels. Empty *sort* levels
  keep their documented "leave this level alone" meaning and are not dropped.
- The empty-level warning fires before the drop and says the level was dropped,
  not that it is "kept as written".
- A new `examples/empty-levels.qmd` fixture and its suite block; the fixtures
  and manifests the change moves (`letter-groups.qmd`, `self-xref.qmd`).
- The two ROADMAP rows this code path carries: the M10-F8 double fold-warning
  on `entry="P!Q!R!"`, and the untested M10-F2/F5 `entry="!Cats" see="Cats"`
  shape.
- README and DESIGN.

**Out:**
- The dangling cross-reference-target report (M10-F9) → existing candidate row.
- Acceptance-suite hardening, including the clean-checkout failure → existing
  clustered candidate row; this milestone's verify bar is stated against a
  rendered working tree, not a clean checkout (the M10 lesson).
- Non-Latin-1 terms and collation → existing candidate row.
- Any change to `sort=` empty-level semantics → stays as documented.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1 — In the compiled `examples/empty-levels.pdf`, every entry the
      fixture writes with a leading empty level prints with that level gone and
      a locator beside it (`entry="!Cats"` prints as the top-level entry
      `Cats`). Evidence: the (level, text) rows `tests/pdfindex.py` reads from
      the PDF, compared against the fixture's hand-derived manifest.
- [ ] AC2 — A scan over every `\index{...}` argument in
      `examples/empty-levels.tex` and `examples/self-xref.tex` finds no null
      field: no argument begins with an unquoted `!`, ends with one, or
      contains two adjacent unquoted `!`.
- [ ] AC3 — The two back-ends print the same paths: the level paths
      `tests/htmlindex.py` reads from `examples/empty-levels.html` and the
      paths the scan of AC2 reads from `examples/empty-levels.tex` correspond
      one-to-one.
- [ ] AC4 — A mark written `entry="!"` with visible text indexes under that
      visible text: the term appears in the printed index of both
      `examples/empty-levels.tex` and `examples/empty-levels.html`.
- [ ] AC5 — Warnings: rendering `examples/empty-levels.qmd` to latex, html and
      gfm emits the empty-level warning once per empty level the fixture
      writes, in each format, and the message states the level was dropped; and
      every warning count the change moves in the `self-xref.qmd` block
      (`WARN_FOLD_DEPTH`, `WARN_FOLD_SELF`, `WARN_SELF_XREF` at
      `tests/run-tests.sh:2743`, `:2750`, `:5509`) is re-derived from the
      fixture with the comment backing it rewritten.
- [ ] AC6 — README's "Sub-entry levels" section states that an empty level is
      dropped in every format and why; README's HTML-back-end bullet no longer
      claims an empty filing string files under `Symbols`; DESIGN's Span-pass
      paragraph records the drop; the M10-F8 fold-warning ROADMAP row is
      retired.
- [ ] AC7 — `tests/run-tests.sh --self-test` passes in a working tree whose
      fixtures have been rendered.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T2, T3, T4
- AC3 → T2, T3, T5
- AC4 → T1, T2, T3
- AC5 → T2, T3, T5
- AC6 → T7
- AC7 → T5, T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1 — Add `examples/empty-levels.qmd` covering every spellable shape:
      leading (`entry="!Cats"`), trailing (`entry="Dogs!"`), leading with a
      cross-reference (`entry="!Owls" see="Owls"`, the M10-F2/F5 shape),
      all-empty with visible text (`entry="!"`), a leading empty level carrying
      a `sort=`, and a control with no empty level.
- [x] T2 — Tests first: add the suite block rendering the fixture to latex,
      pdf, html and gfm with hand-derived manifests asserting the post-fix
      behaviour, and confirm each new check FAILS against the current filter.
- [x] T3 — Drop empty levels in `derive_levels`
      (`_extensions/index/index.lua:601`), letting the all-empty case fall
      through to the visible-text branch; rework `warn_empty_levels` (`:262`)
      to fire before the drop and say the level was dropped.
- [x] T4 — Realign `sort_levels` (`:284`) onto the surviving levels; remove the
      now-unreachable empty-level skip in `clamp_levels` (`:212`) and the
      `nonempty_levels` calls in the self-target comparisons (`:756`, `:814`)
      the drop makes redundant.
- [x] T5 — Update what the change moves: `examples/letter-groups.qmd`'s
      `!windmill` mark and its manifest (`tests/run-tests.sh:5121`), and
      `examples/self-xref.qmd`'s M10-AC6 derivation comment plus every warning
      count named in AC5.
- [x] T6 — With T3–T5 committed, revert the drop and confirm the AC1 and AC2
      checks fail naming the lost entry, then restore. (Commit first: the M08
      lesson.)
- [ ] T7 — README "Sub-entry levels" (`README.md:60`) and the Symbols bullet
      (`:421`); DESIGN's Span-pass paragraph; retire the M10-F8 ROADMAP row.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: plan gate chose dropping empty levels format-neutrally over repairing only the LaTeX back-end because the shared parse layer exists to stop the back-ends printing different paths for one mark; falsified by evidence that an author depends on HTML's empty top-level Symbols entry.
- 2026-08-18: plan gate chose falling back to visible text for an all-empty `entry=` over reporting and indexing nothing because IP2 forbids losing the term and `derive_levels` already routes `entry=""` that way; falsified by an author report that the fallback hides a typo.
- 2026-08-18: plan gate chose compiled-PDF evidence over reading the emitted `.tex` alone because the M01 lesson is that reading an argument cannot establish that the consumer accepts it — which is exactly how this defect survived; falsified by the added PDF render proving too slow or flaky for the suite.
- 2026-08-18: implement gate settled three open items: a sort level pairs with the entry level it was written for and is dropped with it; the empty-level warning reads "an empty level prints nothing, so it is dropped and the entry indexes at the levels that remain"; an `entry=` that is only empty levels gets its own message rather than the existing "no entry=" one, which would be false about it.
- 2026-08-18: T1 — `examples/empty-levels.qmd` added; rendered against the unchanged filter to record the pre-fix behaviour. Beyond the planned defect it exposed an unplanned one: `sort_for` keys a level's sort key on its printed level path and a leading empty level's path is the empty string, so the `mmm` declared by one mark filed four unrelated entries under it with no rival-key report — visible as `\index{zzz@!Cats}` in the pre-fix render. The drop removes it at the root, since no surviving level path can be empty.
- 2026-08-18: T2 — M11 suite block added (manifest 1r: emitted LaTeX arguments, compiled-PDF rows, HTML letter-grouped rows, five warning counts per format, a null-field scan over both empty-level fixtures, and a direct back-end-against-back-end path comparison). Run against the unchanged filter: the suite reaches M11 clean and fails on its first check, 0 of 6 expected empty-level warnings.
- 2026-08-18: T3+T4 landed in one commit — the drop alone leaves the suite red until the sort realignment lands with it, so the verify slot could not be clean between them (minor amendment, task order only). `warn_empty_levels` became `drop_empty_levels`, which warns per empty level and returns the surviving levels, each one's ORIGINAL index and the depth the author wrote; `derive_levels` routes an all-empty value to the visible text or to nothing with its own message and suppresses the generic "no entry=" ones; `sort_levels` picks its levels through the surviving indices and counts ignored levels against the written depth; `nonempty_levels` and the empty-level skip in `clamp_levels` are gone as unreachable.
- 2026-08-18: T5 — two predictions I made about self-xref were wrong and are corrected here: `entry="P!Q!R!"` was ALREADY caught by the format-neutral self-target pass before this milestone, so the self-reference count stays 6 and the fold-induced count stays 3. What M11 actually moves there is the fold-DEPTH count, 4 to 3, which is the double-warning row. Also moved: the demo LaTeX and HTML manifests (`A!!B!` and the depth-6 probe each lose a level), the letter-groups fixture and manifest (`!windmill` files under W, not the empty string in Symbols), and the M10 HTML checks, which located two entries by the empty-level child that no longer exists.
- 2026-08-18: T5 — the M11 null-field scan moved into a `check_no_null_field` helper called beside each fixture's own latex render: reading `examples/self-xref.tex` from the M11 block failed because the later PDF render of that fixture removes it (the M05 lesson).
- 2026-08-18: verify slot clean — `tests/run-tests.sh`, 164 checks, all passed.
- 2026-08-18: T6 — revert probe against the committed fix. With the drop removed, AC1 fails naming all seven wrong arguments against the manifest, and AC2 fails naming four null fields (`\index{Dogs!}`, `\index{mmm@!Sub!}` and two `\index{mmm@!}`). Both restored clean afterwards.
- 2026-08-18: T6 turned up the limit of AC2's scan, recorded rather than papered over: `\index{mmm@!Cats}` has no empty FIELD, so the null-field scan passes it, and makeindex accepts it too — probed directly, it prints `mmm` as a parent term the author never wrote, falling back to the sort key where the printed half is empty. A leading empty level carrying a sort key is therefore corruption of a different kind than a null field, and AC1's manifest comparison is what catches it.
- 2026-08-18: criteria audit ran in FULL mode (surface tier user-facing) but NOT in a fresh context — this session carries a standing directive against spawning subagents, so the author read their own criteria; deviation recorded rather than skipped. Two findings, both fixed before writing: a draft AC1 promising makeindex's `.ilg` report "0 rejected entries" was unreachable as evidence (Quarto does not surface the `.ilg`) and was rewritten onto the compiled PDF; and a draft AC "reverting the drop makes the checks fail" bound a property of the instrument rather than of the deliverable (D-118) and moved to T6.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
