# M093: The label and language paths are exercised where no render reached them

- **Status:** review
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
- One change passed that gate on 2026-09-11. Under a locale whose `%a` reads
  bytes above 0x7F as letters, `en_US.UTF-8` on macOS among them, a `lang:`
  tag with a non-ASCII letter in a later subtag, such as `es-êê`, printed its
  primary subtag's words. After T6 it prints English, as the C locale did.
  `CHANGELOG.md` records the change.

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
- [ ] AC6: Under `fr_FR.ISO8859-1`, a locale in which
      `("\195\170"):match("^%a%a$")` succeeds (bytes 0xC3 0xAA, the UTF-8
      `ê`), `resolve` in `languages.lua` returns `nil` and the token
      `"malformed"` for the tag written `êê` and for the tag written `es-êê`.
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

- [x] T1: KI183. Add an unknown key and an empty word value to one per-index
      map in `examples/index-labels-misuse.qmd`. Add needles naming that
      index beside the M56 misuse counts, with the arithmetic shown in the
      comment. Re-derive the misuse render's total extension-warning count.
- [x] T2: KI189. Add a small book under `examples/` that declares `lang: it`,
      rather than editing a book other legs pin. It needs an entry in the
      non-letter group for `symbols` and cross-reference marks for `see` and
      `see-also`. A book goes in no `site/gallery.yml` list, because
      `tests/gallerycheck.py listing` reads single `.qmd` files only. Render
      it to HTML and EPUB through `capture`, and read each index with
      `tests/htmlindex.py` and `tests/epubindex.py` against a manifest whose
      words are copied from the reference page, not from the render.
- [x] T3: KI196. Capture `examples/index-labels-clash.qmd` to EPUB. Repeat the
      M59-AC4 clash, no-clash and total counts over that log.
- [x] T4: KI197. Write one double-quoted fixture value per non-ASCII `BLANKS`
      character, generated from a list of Unicode character names in the
      suite (`unicodedata.lookup`). Assert one report per character, each
      identified by the index and key it names. Show that the fixture's
      values are the 23 named characters before the count reads. Add a
      `--self-test` plant: a scratch copy of the extension with the 23
      entries removed from `BLANKS` draws none of those 23 reports.
- [x] T5: KI184, KI187, KI188. Delete `OUTCOMES` (`languages.lua` near line
      85) and `M["TITLE_KEY"]` (`indexes.lua` near line 547). Keep the heading
      word out of the table that `label()` reads (`indexes.lua` near line
      434). Add a `pandoc lua` probe, run from `modules/` with
      `require("./indexes")`, that reads `lang: it` metadata and calls
      `label(nil, "title", fb)`. Do not add a source scan to the suite
      (D-011).
- [x] T6: KI185. Replace `%a` and `%w` in `well_formed` (`languages.lua` near
      lines 111-115) with `[A-Za-z]` and `[A-Za-z0-9]`. Add a `quarto pandoc
      lua` probe that calls `os.setlocale("fr_FR.ISO8859-1")`, first asserts
      that `("\195\170"):match("^%a%a$")` succeeds and that the lowercased
      pair does too, then calls `resolve` on `êê` and `es-êê`. The probe fails
      loudly if the locale is missing and never skips. Add the `CHANGELOG.md`
      entry for the `es-êê` change that Scope Out names.
- [x] T7: Strike KI183, KI184, KI185, KI187, KI188, KI189, KI196 and KI197 from
      `cairn/DESIGN.md` per D-013.
- [x] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (full mode, fresh [O] reader) returned findings, all fixed before the gate: AC1 and AC4 named an "empty-value" report that is the same report as the blank-value one; AC4's unquoted values arrive trimmed (probed under `quarto render`), so values are double-quoted and T4 plants `BLANKS` without the 23; AC5's `label(nil, "title", fb)` was already true, so it now reads `lang: it` first; AC6 called the private `well_formed`, now `resolve`, with a later-subtag case; AC2 cites the reference page; AC3 says exactly once; T2 no longer lists a book in `site/gallery.yml`.
- 2026-09-11: plan gate chose fixing KI185 with a locale-switching `pandoc lua` probe over leaving it open, because the switch was shown to part `%a` on byte 0xE9 on this machine; falsified by the probe's locale missing on a machine that runs the suite.
- 2026-09-11: implement started on branch `m093-label-language-coverage`. Question gate: T5 splits each `languages.lua` row into a `words` table and a `title` field, rather than filtering keys in `indexes.lua`. T4's generated fixture fills the last two of its 25 key slots with visible non-ASCII words that must draw no report.
- 2026-09-11: T1 done. The `figures` map in the misuse fixture writes the document map's unknown `symbol` and empty `see`. Two per-index needles, four self-test plants that swap the index phrase for the document's, and the misuse total re-derived from 18 to 20. `tests/run-tests.sh --self-test` passed 1478 checks.
- 2026-09-11: AC6 as planned did not fail on today's code. `pandoc.utils.stringify` turns a raw 0xE9 byte into U+FFFD, so both planned tags already returned `malformed` under `quarto pandoc lua` (pandoc 3.10). The mini gate chose the UTF-8 tags `êê` and `es-êê`. Under `fr_FR.ISO8859-1` they return `miss` and `subtag` today.
- re-audit: AC6 (full) — five findings, all fixed in the second wording. The locale clause named every locale, but the probe tests one. The byte escape needed a gloss. `:lower()` turns 0xC3 into 0xE3, so "carries those bytes" was open to dispute. The outcome token was not quoted. T6 still named the `\233` precondition.
- re-audit: AC6 (full) — the wording holds, and today's code fails it while a fixed copy passes. One finding: under `en_US.UTF-8`, `lang: es-êê` prints Spanish index words today and English after the fix (render confirmed). KI185's "Both outcomes print English" is false for that tag. Optional: assert the lowercased bytes too.
- 2026-09-11: amendment gate. The second re-audit line is the stop, so the user decided. AC6 takes the `fr_FR.ISO8859-1` wording, and Scope Out records the `es-êê` output change. T6 also asserts the lowercased bytes and adds a `CHANGELOG.md` entry. T7 strikes KI185, whose false sentence this log records. The probes run through `quarto pandoc lua`, so the suite needs no separate `pandoc` binary.
- 2026-09-11: T2 and T3 done in one commit, because both edit `tests/run-tests.sh`. T2 adds `examples/book-lang/`, three chapters with `lang: it` and an undeclared index. The M57 block renders it to HTML and EPUB against manifests copied from ledger rows W-IT1 to W-IT4, and two plants hold it to the English words. The first run failed M14's target roster, which did not list the two chapters. They are listed at 0, since every target resolves in the book. T3 captures the clash fixture to EPUB and repeats the three M59-AC4 counts, with three plants. `tests/run-tests.sh --self-test` passed 1490 checks.
- 2026-09-11: T4 done. A new M093 section generates a document under `$WORK` from 23 Unicode names, five indexes of five keys each, with MIDDLE DOT and SECTION SIGN in the last two places. It reads each value back through PyYAML before counting one report per blank place and none per visible one, 23 in total. The plant renders against a copy whose `BLANKS` keeps its 4 ASCII entries, and all 23 counts go red. The first run failed M075's section scan, because the banner had no closing rule and no `section` call. `site/examples.qmd` gains a sentence naming `examples/book-lang/` (T2). `tests/run-tests.sh --self-test` passed 1493 checks.
- 2026-09-11: T5 and T6 done in one commit, because both edit `languages.lua`. Each language row now holds `words` and a separate `title`. `indexes.lua` reads `row.words` into the cell `label` reads and `row.title` into the untitled heading. `OUTCOMES` is gone, and its token list moves into `resolve`'s comment. `TITLE_KEY` and its export are gone. `well_formed` tests `[A-Za-z]` and `[A-Za-z0-9]`. Two `quarto pandoc lua` probes run in the M57 block. The title probe printed `Indice analitico` before the change, and the tags gave `miss` and `subtag`. Two plants restore each defect in a copy of the modules. CHANGELOG gains an Unreleased Output entry for `es-êê`. `tests/run-tests.sh --self-test` passed 1499 checks.
- 2026-09-11: T7 done. KI183, KI184, KI185, KI187, KI188, KI189, KI196 and KI197 are struck from `cairn/DESIGN.md`. No candidate row, lesson or other file named any of them. KI185's false sentence "Both outcomes print English" goes with its entry, as the amendment-gate line above records.
- 2026-09-11: T8: `tests/run-tests.sh --self-test` passed 1499 checks at the T7 commit.
- claim audit: 53 claims read, 3 corrected — CHANGELOG.md, _extensions/index/modules/indexes.lua, _extensions/index/modules/languages.lua, examples/book-lang/, examples/index-labels-misuse.qmd, site/examples.qmd, tests/run-tests.sh
- 2026-09-11: the claim audit corrected three suite comments. The probes load modules through plain Lua `require` from the working directory, not through Quarto's own `require`. The `subtag` and `miss` controls are M57-AC2's alone. Most blanks written unquoted arrive trimmed, not all. It also fixed three older lines the new work made stale, in the M14 fail text, an `indexes.lua` comment and the misuse fixture's prose. The same reader re-read all six, and all six hold. A later suite run stopped on a Deno segmentation fault while rendering `resolving-xref.qmd` to gfm, which this branch does not touch. The rerun passed 1499 checks.

## Decisions

## Review
