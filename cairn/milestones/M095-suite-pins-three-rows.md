# M095: Three candidate rows' unasserted fixture facts get checks

- **Status:** in-progress
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
  outside the index section, and `Bramble`'s record anchor on the old-store
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
- [ ] AC3: The `place-second` record-route leg asserts `Quoin`'s href by
      value. A leg over the recovered `four.html` asserts with
      `tests/fragments.py outside` that `mullion-passage` sits outside
      `title-block-header`, as the M071-AC3 legs do for a body mark. The
      M063-AC2 old-store leg asserts that `Bramble` links to the anchor that
      `two.qmd`'s record carries. Each assertion fails under a `--self-test`
      plant that changes the value it reads.
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

- [ ] T1: KI72 fixtures. List every target in both files from the attribute
      values (`examples/demo.qmd` lines 37-51, `examples/xref-conflict.qmd`
      lines 32-96). Point each incidental target at a term the file already
      indexes where the target's own characters are not what a probe tests.
      Otherwise add an invisible mark for it, as M091 did. Keep `rho`'s
      target. An added mark must not contest a cross-reference mark's key (M15).
- [ ] T2: KI72 suite. Set the corpus rows (near lines 14019 and 14054) to 0
      and 1 and rewrite their derivation comments (near lines 13900-13912).
      Update `DEMO_HTML_INDEX`, `XREF_HTML_INDEX`, `DEMO_ENTRIES`,
      `XREF_ENTRIES` (near line 705), `CONFLICT_PDF_INDEX` and `PDF_TERMS`
      for the entries that now link or are added, deriving from the source,
      never from the render. Add a check that the one remaining report names
      `Note: on birds`.
- [ ] T3: KI273. Add an `hrefs` check for `Quoin` on the `place-second` render
      (near lines 8293-8299). Add a `tests/fragments.py outside` call for
      `mullion-passage` against `title-block-header` on `four.html` (near line
      8898). `four.html` carries no index section. Read the M078 review
      findings F3 and F11 first to confirm this is the containment they meant.
      Add an `htmlindex.py` read of `Bramble`'s href on the old-store page
      (near line 11189) against the id read from `two.qmd`'s stored record.
      Add one plant each. Rewrite the comment near lines 11184-11188.
- [ ] T4: KI10 fixture. Add a probe fixture that declares `indexes:`,
      `index-labels:` and a non-default `lang:`. Extend
      `tests/state-pollute.lua` so that it reads a different declaration
      through `qi_indexes.reset`, so each of the six cells holds a value that
      differs from the fixture's own.
- [ ] T5: KI10 probe. Add the six cells to `CELLS` in `tests/stateprobe.py`
      with module `indexes`, and a whole-module `reset:indexes` probe. Show
      each probe moving when its restore is deleted, or record why it cannot.
      `order` and `titles` are emptied again by `read` when a fixture
      declares a usable index, so derive a fixture per cell where needed.
      `EXEMPT` holds one name today and becomes a set if more than one cell
      joins it. Rewrite KI10's inventory
      sentence and the cell count the M26 leg states.
- [ ] T6: Strike KI72, KI273 and KI10 from `cairn/DESIGN.md` per D-013, or
      narrow any part a task leaves open, marked `narrowed M095`. KI273's
      entry names only `Bramble`. The `Quoin` and `mullion-passage` items
      came from its ROADMAP row, which this plan removes, so the archive
      summary records all three.
- [ ] T7: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan; absorbs the ROADMAP candidate rows naming KI72, KI273 and KI10.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: AC1 omitted the demo's LaTeX and PDF manifests; AC3's `outside` container was the gamma section, which `four.html` does not carry (now `title-block-header`, the M071-AC3 precedent); AC4 could not hold for `language_words`, which `read` always reassigns, so a cell may be held as expected-to-pass with its reason; T6 notes that KI273's entry names only `Bramble`.
- 2026-09-11: plan chose one milestone for KI72, KI273 and KI10 over splitting KI10 out, because the three share no code and total five criteria; falsified by KI10's per-cell fixtures growing past one working session.
- 2026-09-11: plan chose pointing `demo.qmd`'s incidental targets at terms it already indexes, with invisible marks only where a target's characters are probed, over M091's marks-only approach, because `demo.qmd` is the gallery's shown source; falsified by an M02 or M14 leg that reads a retargeted attribute's original text.

## Decisions

## Review
