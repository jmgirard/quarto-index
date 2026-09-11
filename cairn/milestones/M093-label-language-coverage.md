# M093: The label and language paths are exercised where no render reached them

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M092
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** user-facing — it edits `languages.lua` and `indexes.lua`, which ship in the extension
- **Branch/PR:** `m093-label-language-coverage`

## Goal

Every label and language shape that the M56-M59 fixtures leave unrendered gets
a render or a probe that fails on its defect, and the language module drops
the surface that nothing reads.

## Scope

**In:** KI183, KI184, KI185, KI187, KI188, KI189, KI196 and KI197, all under
"The repo and its packaging" in `cairn/DESIGN.md`. The work items are these:

- Per-index unknown-key and empty-value reports in the misuse fixture.
- A book fixture that declares `lang:`, rendered to HTML and EPUB.
- The letter-clash fixture rendered to EPUB.
- A render for each non-ASCII blank that `BLANKS` lists.
- `OUTCOMES` and the `TITLE_KEY` export removed.
- The heading word kept out of the table that `label()` reads.
- `well_formed` written with ASCII ranges, with a locale probe.

Each closed entry is struck from `cairn/DESIGN.md`.

**Out:**
- The checks that cannot fail on their own defect (KI180-KI182, KI186,
  KI190-KI195) go to M092, which this milestone follows because both edit the
  M56-M59 blocks of `tests/run-tests.sh`.
- The ASCII entries of `BLANKS` (tab, newline, return, space) get no new
  render. YAML and Pandoc trim them before the filter reads a value, so the
  report for an empty value is the same report.
- A change to what an author sees printed or reported is not expected. If a
  task shows one, it goes through the amendment gate.

## Acceptance criteria

- [ ] AC1: In `examples/index-labels-misuse.qmd`, a per-index `index-labels:`
      map that carries an unknown key draws the unknown-key report, and one
      that carries an empty word value draws the report for a value with no
      character a reader can see. Each report names that index, as needles
      in `tests/run-tests.sh` read the HTML render's log.
- [ ] AC2: A book fixture that declares `lang: it` prints, in its HTML book
      index and in its EPUB index, the Italian `symbols`, `see` and
      `see-also` words that `cairn/references/index-words-by-language.md`
      gives.
- [ ] AC3: Rendered to EPUB, `examples/index-labels-clash.qmd` draws the
      letter-clash report exactly once and draws no no-clash report.
- [ ] AC4: For each of the 23 non-ASCII characters that `BLANKS` lists at
      plan time, a label value made only of that character, written as a
      double-quoted YAML scalar, draws the report for a value with no
      character a reader can see, naming the index and key it is written
      under.
- [ ] AC5: `languages.lua` holds no `OUTCOMES` table and `indexes.lua` exports
      no `TITLE_KEY`, as a `grep` of both modules at review reads. After
      `read` of metadata that declares `lang: it`, `label(nil, "title", fb)`
      returns `fb`.
- [ ] AC6: Under a locale in which `("\233"):match("%a")` succeeds,
      `resolve` in `languages.lua` returns its malformed outcome for a tag
      whose primary subtag carries byte 0xE9, and for a tag whose later
      subtag carries it.
- [ ] AC7: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7, T8

## Tasks

- [ ] T1: KI183. Add an unknown key and an empty word value to one per-index
      map in `examples/index-labels-misuse.qmd`. Add needles naming that
      index beside the M56 misuse counts, with the arithmetic shown in the
      comment. Re-derive the misuse render's total extension-warning count.
- [ ] T2: KI189. Add a small book under `examples/` that declares `lang: it`,
      rather than editing a book other legs pin. It needs an entry in the
      non-letter group for `symbols` and cross-reference marks for `see` and
      `see-also`. A book goes in no `site/gallery.yml` list, because
      `tests/gallerycheck.py listing` reads single `.qmd` files only. Render
      it to HTML and EPUB through `capture`, and read each index with
      `tests/htmlindex.py` and `tests/epubindex.py` against a manifest whose
      words are copied from the reference page, not from the render.
- [ ] T3: KI196. Capture `examples/index-labels-clash.qmd` to EPUB. Repeat the
      M59-AC4 clash, no-clash and total counts over that log.
- [ ] T4: KI197. Write one double-quoted fixture value per non-ASCII `BLANKS`
      character, generated from a list of Unicode character names in the
      suite (`unicodedata.lookup`). Assert one report per character, each
      identified by the index and key it names. Show that the fixture's
      values are the 23 named characters before the count reads. Add a
      `--self-test` plant: a scratch copy of the extension with the 23
      entries removed from `BLANKS` draws none of those 23 reports.
- [ ] T5: KI184, KI187, KI188. Delete `OUTCOMES` (`languages.lua` near line
      85) and `M["TITLE_KEY"]` (`indexes.lua` near line 547). Keep the heading
      word out of the table that `label()` reads (`indexes.lua` near line
      434). Add a `pandoc lua` probe, run from `modules/` with
      `require("./indexes")`, that reads `lang: it` metadata and calls
      `label(nil, "title", fb)`. Do not add a source scan to the suite
      (D-011).
- [ ] T6: KI185. Replace `%a` and `%w` in `well_formed` (`languages.lua` near
      lines 111-115) with `[A-Za-z]` and `[A-Za-z0-9]`. Add a `pandoc lua`
      probe that calls `os.setlocale("fr_FR.ISO8859-1")`, first asserts that
      `("\233"):match("%a")` succeeds, then calls `resolve` on the two tags.
      The probe fails loudly if the locale is missing and never skips.
- [ ] T7: Strike KI183, KI184, KI185, KI187, KI188, KI189, KI196 and KI197 from
      `cairn/DESIGN.md` per D-013.
- [ ] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: AC1 and AC4 named an "empty-value" report that is the same report as the blank-value one; AC4's unquoted values arrive trimmed (probed under `quarto render`), so values are double-quoted and T4 plants `BLANKS` without the 23; AC5's `label(nil, "title", fb)` was already true, so it now reads `lang: it` first; AC6 called the private `well_formed`, now `resolve`, with a later-subtag case; AC2 cites the reference page; AC3 says exactly once; T2 no longer lists a book in `site/gallery.yml`.
- 2026-09-11: plan gate chose fixing KI185 with a locale-switching `pandoc lua` probe over leaving it open, because the switch was shown to part `%a` on byte 0xE9 on this machine; falsified by the probe's locale missing on a machine that runs the suite.
- 2026-09-11: implement started on branch `m093-label-language-coverage`. Question gate: T5 splits each `languages.lua` row into a `words` table and a `title` field, rather than filtering keys in `indexes.lua`. T4's generated fixture fills the last two of its 25 key slots with visible non-ASCII words that must draw no report.

## Decisions

## Review
