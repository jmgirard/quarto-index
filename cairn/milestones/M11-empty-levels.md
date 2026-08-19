<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M11: Empty index levels never lose the entry

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP2, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m11-empty-levels · https://github.com/jmgirard/quarto-index/pull/11   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1 — In the compiled `examples/empty-levels.pdf`, every entry the
      fixture writes with a leading empty level prints with that level gone and
      a locator beside it (`entry="!Cats"` prints as the top-level entry
      `Cats`). Evidence: the (level, text) rows `tests/pdfindex.py` reads from
      the PDF, compared against the fixture's hand-derived manifest.
- [x] AC2 — A scan over every `\index{...}` argument in
      `examples/empty-levels.tex` and `examples/self-xref.tex` finds no null
      field: no argument begins with an unquoted `!`, ends with one, or
      contains two adjacent unquoted `!`.
- [x] AC3 — The two back-ends print the same paths: the level paths
      `tests/htmlindex.py` reads from `examples/empty-levels.html` and the
      paths the scan of AC2 reads from `examples/empty-levels.tex` correspond
      one-to-one.
- [x] AC4 — A mark written `entry="!"` with visible text indexes under that
      visible text: the term appears in the printed index of both
      `examples/empty-levels.tex` and `examples/empty-levels.html`.
- [x] AC5 — Warnings: rendering `examples/empty-levels.qmd` to latex, html and
      gfm emits the empty-level warning once per empty level the fixture
      writes, in each format, and the message states the level was dropped; and
      every warning count the change moves in the `self-xref.qmd` block
      (`WARN_FOLD_DEPTH`, `WARN_FOLD_SELF`, `WARN_SELF_XREF` at
      `tests/run-tests.sh:2743`, `:2750`, `:5509`) is re-derived from the
      fixture with the comment backing it rewritten.
- [x] AC6 — README's "Sub-entry levels" section states that an empty level is
      dropped in every format and why; README's HTML-back-end bullet no longer
      claims an empty filing string files under `Symbols`; DESIGN's Span-pass
      paragraph records the drop; the M10-F8 fold-warning ROADMAP row is
      retired.
- [x] AC7 — `tests/run-tests.sh --self-test` passes in a working tree whose
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
- [x] T7 — README "Sub-entry levels" (`README.md:60`) and the Symbols bullet
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
- 2026-08-18: T7 — README's sub-entry-levels section rewritten (the drop, why the LaTeX index tool makes it necessary, the unspellable middle level, the all-empty fallback, the sort pairing), the ceiling paragraph's dangling-separator sentence replaced by depth-counted-after-the-drop, and the letter-group bullet's empty filing string removed; DESIGN's Span-pass and shared-layer paragraphs updated; the M10-F8 candidate row retired.
- 2026-08-18: T7 — two suite consequences of the docs edit: the M07-AC6 README pin quoted the letter-group sentence I changed and was re-pinned, and a README_EMPTY_CLAIMS pin was added on the same M06/M07 pattern so the eight new documented claims cannot drift from what the fixture exercises.
- 2026-08-18: verify slot clean — `tests/run-tests.sh --self-test`, 182 checks, all passed.
- 2026-08-18: review return 1 (defect) — three fresh-context reviewers spawned at the user's direction; the diff-bug lens found F1, a regression confirmed by probe on entries with NO empty level: `sort_levels` computes `last` over the realigned sort list instead of over what the author wrote, so positional filler becomes a declaration, a second mark's genuine sort key is lost and a spurious rival-key report fires. F2 (a sort key for a dropped level is discarded silently) and F3 (the all-empty fallback re-aligns every sort level, making the README/DESIGN sort-pairing sentence false) travel with it. User directed return-to-in-progress and a joint fix; status back to `in-progress`.
- 2026-08-18: criteria audit ran in FULL mode (surface tier user-facing) but NOT in a fresh context — this session carries a standing directive against spawning subagents, so the author read their own criteria; deviation recorded rather than skipped. Two findings, both fixed before writing: a draft AC1 promising makeindex's `.ilg` report "0 rejected entries" was unreachable as evidence (Quarto does not surface the `.ilg`) and was rewritten onto the compiled PDF; and a draft AC "reverting the drop makes the checks fail" bound a property of the instrument rather than of the deliverable (D-118) and moved to T6.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

### Evidence (fresh, 2026-08-18; `tests/run-tests.sh --self-test`, 182 checks, exit 0)

- **AC1 — the entry survives to the compiled index.** `examples/empty-levels.pdf`
  rendered and read by `tests/pdfindex.py`: all 8 manifest rows print in the
  index tool's own collation order, `Zebra` leading on its surviving sort key
  `aardvark`, each row carrying a locator except the `Birds` parent whose
  locator hangs off its child. The emitted `\index{!Cats}` of the pre-fix
  filter is now `\index{Cats}`. Checks: "the compiled index prints all 8
  manifest entries in order, each with a locator"; "every entry written with an
  empty level survives to the compiled index".
- **AC2 — no null field.** `check_no_null_field` scans every `\index` argument
  in each fixture while its own `.tex` still exists: 7 arguments in
  `examples/empty-levels.tex` and 10 in `examples/self-xref.tex`, no empty
  field at any level in either. Limit recorded at T6 and not papered over: a
  leading empty level carrying a sort key emits no empty FIELD, so this scan
  cannot see it — AC1's manifest comparison is what catches that shape.
- **AC3 — the two back-ends agree.** The HTML index matches all 15 manifest
  rows in order across 7 letter groups (A, B, C, D, F, O, S), every id unique
  and all 7 links resolving; and the back-ends are compared directly against
  each other, not each against its own manifest — each of the 7 LaTeX level
  paths is printed by the HTML index, which prints none the LaTeX one does not
  reach.
- **AC4 — the all-empty fallback.** `[Ferrets]{.index entry="!"}` emits
  `\index{Ferrets}` in the LaTeX render (read from the rendered `.tex`) and
  prints as the depth-0 entry `Ferrets` with one locator in the HTML index
  (read by `tests/htmlindex.py`).
- **AC5 — the warnings.** In each of latex, html and gfm: 6 empty-level
  warnings across 5 marks (2 of them on `entry="!Sub!"`, which is what says the
  warning is per level and not per mark), 1 all-empty fallback message, 1
  all-empty nothing-to-index message, 1 self-reference, and 0 fold-depth. Every
  self-xref count re-derived from the fixture with its backing comment
  rewritten: the self-reference count stays 6 and the fold-induced count stays
  3 — both predictions in the T5 plan text were wrong and are corrected in the
  work log — while the fold-DEPTH count falls 4 to 3, which is the
  double-warning row this milestone retires.
- **AC6 — the docs.** README's sub-entry-levels section states the drop and its
  reason; 8 documented empty-level claims are pinned verbatim by a new
  `README_EMPTY_CLAIMS` drift check on the M06/M07 pattern. README's letter-group
  bullet no longer lists an empty string among the Symbols cases. DESIGN's Span-pass
  paragraph records the drop and the shared-layer sentence names it. The M10-F8
  fold-warning ROADMAP row is deleted.
- **AC7 — the verify slot.** `tests/run-tests.sh --self-test` exits 0 with 182
  checks passing, in a working tree whose fixtures have been rendered (the bar
  the plan set; a clean checkout stays the acceptance-suite-hardening row's
  business and is out of scope here).

### Consistency gate

- `cairn_validate` exits 0 — every check PASS/OK, `coverage complete` and
  `roadmap<->disk orphans` included.
- `cairn_impact` skipped: the DESIGN.md diff changes no `IPn`/`GPn` principle
  text (the milestone works under IP1, IP2 and GP6, and amends neither).
- Toolchain checks: the active profile is `generic`, whose `consistency-gate`
  slot names none — a clean no-op.

### Independent review

Three fresh-context reviewers, none of which saw the implementation. Spawned at
the user's explicit direction: this session carries a standing instruction
against subagents, and the alternative was self-review of a diff I wrote.

- **[S] prior-review lens — 0 findings.** Read all ten archived milestone
  summaries and LESSONS.md; the GitHub comment probe returned `[]`, so the
  archived `## Review` sections were the whole surface. Confirmed both M10-review
  rows this milestone acts on are resolved and four lessons this diff could have
  regressed are honoured.
- **[S] blame-history lens — 1 minor finding (F-h1), no silent undo.** Traced
  seven items; corrected my briefing on one point (the `clamp_levels` empty-level
  skip originated in M01 `22faf8e`, not M10).
- **[O] diff-bug lens — 10 findings, one of them a confirmed regression.**

**F1 (high, CONFIRMED by direct probe) — `sort_levels` turns positional filler
into a declaration, on entries with no empty level at all.** `last` ("the last
position the author actually wrote a key for") is computed over the realigned,
truncated `parsed` rather than over `written`, and compared against the
post-drop index instead of the original one. Probe: two marks on
`entry="A!B"`, one `sort="A!B!C"` and one `sort="A!zzz"`. `main` emits
`\index{A!zzz@B}` twice with no warning; the branch emits `\index{A!B}` twice
and adds `index entry in entry="A!B" is already sorted as "B"; the sort key
"zzz" written here cannot apply as well`. The second mark's genuine sort key is
lost. Contradicts README's "Restating a level's own text on the way to a deeper
one declares nothing for that level". `kept` is non-nil on every `entry=` path,
so the blast radius is wider than this milestone's scope, and no suite check
covers it.

**F2 (medium, CONFIRMED) — a sort key written for a dropped level is discarded
silently.** `entry="!Cats" sort="mmm"` emits `\index{Cats}` and says nothing
about `mmm`. The gate chose pair-and-drop knowing the key would go; it did not
decide the loss should be unreported, and every other unusable sort in this
filter warns.

**F3 (medium, CONFIRMED) — the all-empty fallback breaks this milestone's own
sort-pairing rule, making README and DESIGN false.** `derive_levels` returns
`{ visible }` with no `kept`, so every written sort level re-aligns onto the
fallback: `entry="!" sort="mmm!nnn"` emits `\index{mmm@Vis}`, putting `mmm` —
written for the empty first level — on a level it was never written for.

**F4 (medium-low) — the `explained` flag suppresses the cross-reference
diagnosis.** `[]{.index entry="!" see="Cats"}` no longer says the `see=` target
went with the entry, losing the actionable half of the message.

**F5 (medium-low) — `check_no_null_field` cannot see a trailing null field on an
argument carrying an encap, so AC2 is weaker than its wording claims.** The
`\index\{([^}]*)\}` capture stops at the first `}`, so `\index{Cats!|see{X}}`
is scanned as `Cats!|see{X`, whose last field is non-empty. AC2's claim happens
to hold for both fixtures, so the criterion is not falsified — the instrument is
weaker than the promise. This inherits the pre-existing brace-unaware-scanner
ROADMAP row while claiming a stronger property than the old scanner did.

**F6 (low)** — `kept` and `depth` are destructured in `Span` and never read.
**F7 (low)** — "sort= has 3 levels but the entry has 2" now describes the written
depth, not the entry as indexed. **F8 (low)** — a multi-empty value draws N
byte-identical warnings, neither naming which end went. **F9 (low, design
tension)** — DESIGN justifies a shared-layer drop partly by a makeindex property,
while the sibling constraint (`clamp_levels`) was deliberately kept inside the
LaTeX back-end for being back-end-specific. **F10 (low, process)** — the three
`entry=` semantics the implement gate settled live only in the work log, where
D-001 records exactly this class of choice.

**F-h1 (minor, blame lens)** — AC5's text cites `tests/run-tests.sh:2743`,
`:2750`, `:5509`; those constants now sit at 2808/2815/2816.

Reviewer categories that produced no findings: removed code was genuinely
unreachable (traced independently — no path delivers an empty level to
`clamp_levels` or either self-target comparison); the `explained` flag is
correctly scoped; the new manifests are genuine hand-derived oracles rather than
render read-backs, and the checks discriminate.

### Triage (2026-08-18, at the gate)

- **F1 — fix now. Return floor fires:** a load-bearing defect in what the
  extension emits for users, confirmed by probing the branch filter against
  `main`'s on one document. Status back to `in-progress`.
- **F2, F3 — fix now**, with F1: all three are the same gate decision and the
  same two functions.
- **F5 — fix now if cheap, else follow-up row.** AC2 is not falsified (the claim
  holds for both fixtures), so this is instrument strength, not a criterion
  failure.
- **F4, F6, F7, F8 — decide during the fix**; each is small and local.
- **F9 — reject or absorb into the fix's DESIGN wording**; the reviewer agrees the
  choice is right and objects only to which half of the justification leads.
- **F10 — decide during the fix**: whether the three `entry=` semantics warrant a
  D-entry beside D-001.
- **F-h1 — fix now** (stale line numbers in AC5's parenthetical citations; a
  criterion-text edit, so it goes through the amendment gate if the wording
  changes at all).

Every criterion tick above stands on evidence recorded before this triage; the
return is under the floor's second clause (a user-facing defect), not a criterion
failure, so no acceptance criterion is unticked by it.

