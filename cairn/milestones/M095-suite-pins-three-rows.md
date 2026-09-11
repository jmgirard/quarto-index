# M095: Three candidate rows' unasserted fixture facts get checks

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** user-facing — `examples/demo.qmd` is shown on the docs site's gallery page, so its source and rendered index change for readers
- **Branch/PR:** m095-suite-pins-three-rows

## Goal

The suite asserts three fixture facts that three candidate rows left
unchecked: the demo fixtures' cross-reference targets, three book locators,
and the six `indexes.lua` cells outside the state probe.

## Scope

**In:** the three ROADMAP candidate rows that name KI72, KI273 and KI10,
which this plan absorbs and removes.

- KI72 (under "The acceptance suite: coverage gaps"). Each incidental
  `see=`/`see-also=` target in `examples/demo.qmd` and
  `examples/xref-conflict.qmd` names a term that the file indexes. `rho`'s
  `see="Note: on birds"` in `examples/xref-conflict.qmd` dangles on purpose
  and stays.
- KI273. The `Quoin` href on the record route, `mullion-passage` sitting
  outside its heading, and `Bramble`'s record anchor on the old-store
  page.
- KI10. The `indexes.lua` cells `order`, `titles`, `declared`,
  `language_words`, `doc_labels` and `index_labels` join the M26 state
  probe. The probe is a render comparison, which D-011 and D-012 allow.

Each closed entry is struck from `cairn/DESIGN.md`, or narrowed where a part
stays open.

**Out:**
- The other dangling targets in the M14 corpus dangle on purpose. They are
  the report's subject and get no work.
- A source scan over `indexes.lua` is refused by D-011 and is not added.

## Acceptance criteria

- [ ] AC1: Rendered to gfm, `examples/demo.qmd` draws no dangling-target
      report, as the M14 corpus row for that file in `tests/run-tests.sh`
      reads. Its HTML index manifest, its LaTeX `\index{}` manifests, its PDF
      terms manifest and the gallery checks (`tests/gallerycheck.py`) pass
      with the entries that now link.
- [ ] AC2: Rendered to gfm, `examples/xref-conflict.qmd` draws exactly one
      dangling-target report, and it names `Note: on birds`, as its M14
      corpus row and a report-identity check read. Its HTML and PDF index
      manifests pass.
- [ ] AC3: The `place-second` record-route leg asserts that `Quoin`'s href
      on `five.html` is `four.html`. In each of the captures
      `place-blocked-one` and `place-blocked-two`, a leg asserts that
      `four.html` carries `mullion-passage` once, inside the `<section>`
      carrying `a-mullion-in-a-heading`, and neither on nor within that
      section's child `<h2>`. The `place-oldstore` leg asserts that
      `Bramble`'s href on `index.html` is `two.html#qi-mark-1`, the anchor of
      `two.qmd`'s first mark, derived from the source. Each of the Quoin and
      Bramble assertions fails under a `--self-test` plant that changes the
      href it reads. The `mullion-passage` assertion fails under each of three
      plants that move the id rather than copy it: onto the `<h2>`, into the
      `<h2>`, and out of the section.
- [ ] AC4: For each of the six `indexes.lua` cells, `tests/stateprobe.py`
      either finds that deleting that cell's restore statement from `reset`
      changes the compared output of a probe fixture, or holds the cell as
      expected to pass with the reason stated, as it holds
      `range_pair_found`. A cell that `read` always reassigns
      (`language_words`, `indexes.lua` near line 333) is one such reason.
- [ ] AC5: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4, T5
- AC5 → T6, T7

## Tasks

- [x] T1: KI72 fixtures. List every target in both files from the attribute
      values (`examples/demo.qmd` lines 37-51, `examples/xref-conflict.qmd`
      lines 32-96). Write one invisible mark per distinct incidental target,
      as M091 did (minor amendment 2026-09-11). Keep `rho`'s target. An added
      mark must not contest a cross-reference mark's key (M15).
- [x] T2: KI72 suite. Set the corpus rows (near lines 14019 and 14054) to 0
      and 1 and rewrite their derivation comments (near lines 13900-13912).
      Update `DEMO_HTML_INDEX`, `XREF_HTML_INDEX`, `DEMO_ENTRIES`,
      `XREF_ENTRIES` (near line 705), `CONFLICT_PDF_INDEX` and `PDF_TERMS`
      for the entries that now link or are added, deriving from the source,
      never from the render. Add a check that the one remaining report names
      `Note: on birds`.
- [x] T3: KI273. Add an `hrefs` check for `Quoin` on the `place-second`
      render. Add a `tests/fragments.py outside-heading` mode, which finds a
      section's child heading by element, and call it for `mullion-passage`
      in `a-mullion-in-a-heading` on `four.html` in both `place-blocked`
      captures. Check `Bramble`'s href on the `place-oldstore` page against
      `two.html#qi-mark-1`, derived from `two.qmd`'s mark order. Add one plant
      each for `Quoin` and `Bramble` and three for `mullion-passage`. Rewrite
      the comment above the old-store `resolve` call (minor amendment
      2026-09-11).
- [x] T4: KI10 fixture. Add a probe fixture that declares no index and
      carries a mark naming an undeclared index and a cross-reference mark.
      Extend `tests/state-pollute.lua` so that, after its existing drive, it
      reads a declaration of two labelled indexes through
      `qi_indexes.reset`, so each of the six cells holds a value that differs
      from the fixture's own (minor amendment 2026-09-11).
- [x] T5: KI10 probe. Add the six cells to `CELLS` in `tests/stateprobe.py`
      with module `indexes`, and a whole-module `reset:indexes` probe. Show
      each probe moving when its restore is deleted, or record why it cannot.
      `order` and `titles` are emptied again by `read` when a fixture
      declares a usable index, so derive a fixture per cell where needed.
      `EXEMPT` holds one name today and becomes a set if more than one cell
      joins it. Rewrite KI10's inventory
      sentence and the cell count the M26 leg states.
- [x] T6: Strike KI72, KI273 and KI10 from `cairn/DESIGN.md` per D-013, or
      narrow any part a task leaves open, marked `narrowed M095`. KI273's
      entry names only `Bramble`. The `Quoin` and `mullion-passage` items
      came from its ROADMAP row, which this plan removes, so the archive
      summary records all three.
- [x] T7: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan; absorbs the ROADMAP candidate rows naming KI72, KI273 and KI10.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: AC1 omitted the demo's LaTeX and PDF manifests; AC3's `outside` container was the gamma section, which `four.html` does not carry (now `title-block-header`, the M071-AC3 precedent); AC4 could not hold for `language_words`, which `read` always reassigns, so a cell may be held as expected-to-pass with its reason; T6 notes that KI273's entry names only `Bramble`.
- 2026-09-11: plan chose one milestone for KI72, KI273 and KI10 over splitting KI10 out, because the three share no code and total five criteria; falsified by KI10's per-cell fixtures growing past one working session.
- 2026-09-11: plan chose pointing `demo.qmd`'s incidental targets at terms it already indexes, with invisible marks only where a target's characters are probed, over M091's marks-only approach, because `demo.qmd` is the gallery's shown source; falsified by an M02 or M14 leg that reads a retargeted attribute's original text.
- 2026-09-11: implement gate chose three things. Invisible marks resolve both fixtures' targets (8 in `demo.qmd`, 12 in `xref-conflict.qmd`), because retargeting rewrites about 22 pinned manifest rows and breaks M15's `\see{Afar}` check. The KI10 probe fixture declares no index, because `read` hides `order`, `titles` and `declared` in a declaring one. AC3's `mullion-passage` clause moves from the title block to its heading, where the M078 review F3/F11 row (commit 5bc72fd) put the gap.
- 2026-09-11: minor amendment: T1 marks every incidental target with an invisible mark rather than retargeting. T4's fixture declares no index, and the pollution filter reads a declaration through `qi_indexes.reset` after its existing drive.
- 2026-09-11: re-audit: AC3 (full) — "the recovered `four.html`" named no capture, one plant stood in for three defect forms (id onto, into and out of the heading's section), and `fragments.py` containment never counts the container's own id. Wording corrected.
- 2026-09-11: re-audit: AC3 (full) — the corrected wording read `Bramble`'s expected anchor from an extension-written record at an unclear time (now derived from source as `qi-mark-1`), read "whose `five.html` carries" as a filter (captures now named), and left `Quoin`'s value unstated (now `four.html`). This second line is the stop, so the corrected wording goes to the user.
- 2026-09-11: T1/T2 edits in, unticked: 8 invisible marks in `demo.qmd` and 12 in `xref-conflict.qmd` with their gallery copies, `DEMO_ENTRIES`, `DEMO_HTML_INDEX`, `XREF_HTML_INDEX`, `CONFLICT_PDF_INDEX`, both letter sweeps, corpus rows 0 and 1, and a check naming `rho`'s report. Scratch renders match the HTML, conflict PDF and demo PDF manifests. The suite has not run.
- 2026-09-11: amendment adopted at the user's selection: AC3 now states `Quoin`'s href value, names the `place-blocked-one` and `place-blocked-two` captures, holds `mullion-passage` inside its section and outside its `<h2>`, derives `Bramble`'s `two.html#qi-mark-1` from source, and requires five plants. Scope's KI273 item reads "outside its heading". T3's wording follows.
- 2026-09-11: the claim audit returned three corrections. Two landed in `tests/stateprobe.py`: the indexes probe keeps the `read(doc.meta)` call as well as the two installation lines, and the `index_labels` reason names the unnamed cell no declaration can name. The third landed in `tests/run-tests.sh` once the run ended: a chapter numbers the anchors it mints per chapter in document order, skipping a mark that carries an id of its author's own, and `Bramble` is the first anchoring mark `two.qmd` writes. The re-read found corrections one and two supported and named a residual imprecision in the third, whose phrasing it supplied and which now stands.
- 2026-09-11: claim audit: 58 claims read, 3 corrected — tests/stateprobe.py, tests/run-tests.sh
- 2026-09-11: `tests/run-tests.sh --self-test` ran clean on the finished tree at 748a180: 1515 checks, exit 0, the two new `state-reuse-indexes` pairs among them. T7 ticked and the status set to review.
- 2026-09-11: the seven new probes ran and `tests/stateprobe.py` exited 0. `reset:indexes`, `order`, `doc_labels` and `declared` each move a `state-reuse` comparison, `titles` moves the new `state-reuse-indexes` fixture, and `index_labels` and `language_words` hold as expected-to-pass with their reasons in `EXEMPT`. The control passed with the new fixture in `PAIRS`. T4, T5 and T6 ticked, KI72 and KI273 struck from DESIGN and KI10 corrected there.
- 2026-09-11: `tests/run-tests.sh --self-test` ran clean at 8f0869d: 1511 checks, exit 0. It covers AC1's demo legs, AC2's corpus counts (0 and 1) and AC3's three assertions with their five plants. The AC2 report-identity check prints nothing when it passes, so it was read separately: its needle matches the captured corpus log once, and a needle naming `sigma` is refused. T1, T2 and T3 ticked.
- 2026-09-11: T3 edits in, unticked: `tests/fragments.py` gains `outside-heading`, and the suite gains the `Quoin`, `mullion-passage` (both captures) and `Bramble` checks with their five plants. On an earlier run's `four.html` the new mode passes, and it fails on each of three scratch plants with its own message. The suite has not run.

## Decisions

## Review
