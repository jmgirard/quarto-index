# M093: The label and language paths are exercised where no render reached them

**Status:** done (2026-09-11, PR #93 https://github.com/jmgirard/quarto-index/pull/93)

**Goal:** Every label and language shape that the M56-M59 fixtures leave unrendered gets a
render or a probe that fails on its defect, and the language module drops the surface that
nothing reads.

**Outcome:** Each `languages.lua` row holds `words` and a separate `title`, so `label()` never
reads the heading. `OUTCOMES` and the `TITLE_KEY` export are gone. `well_formed` tests
`[A-Za-z]` and `[A-Za-z0-9]`, so `lang: es-êê` keeps English words and the `Index` heading
under every locale (CHANGELOG, Unreleased). The suite gains per-index misuse needles under
`figures` (total 18 to 20). It renders the Italian book `examples/book-lang/` to HTML and EPUB
and the clash fixture to EPUB. It generates a document of the 23 non-ASCII `BLANKS` characters,
with a plant. Two `quarto pandoc lua` probes read the title and the tag letters, one under
`fr_FR.ISO8859-1`. KI183-KI185, KI187-KI189, KI196 and KI197 struck.

**Decisions:** none milestone-local. The amendment gate chose UTF-8 tags for AC6 and recorded
the `es-êê` output change in Scope Out.

**Review:** one pass, three-lens fan-out, 1499 checks. The history and prior-review lenses
found nothing. Of six diff findings, F2-F5 were fixed at the gate. The CHANGELOG names the
heading change, the ledger's German row sentence is corrected, two lines are rewrapped.
F1 (the locale probe fails where `fr_FR.ISO8859-1` is missing) went to KI279. F6 rejected.
Re-run 1499 checks, CI green on PR #93. No lesson. Nothing graduated or retired.
