# RB01: Per-locator emphasis in the LaTeX index back-end (M20)

- **Date:** 2026-08-21
- **Output required:** write findings to `cairn/reviews/RR01-principal-locator-encapsulation.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

**The project.** `quarto-index` is a Quarto extension implemented entirely as a
Pandoc Lua filter (`_extensions/index/index.lua` plus `_extensions/index/modules/`).
An author writes an index mark inline as a Pandoc span: `[cats]{.index}`, with
optional attributes `entry=`, `sort=`, `see=`, `see-also=`. The filter has three
back-ends:

- **LaTeX/PDF** — each mark emits one `\index{...}` command; the document loads
  `imakeidx`, and Quarto's PDF pipeline runs `makeindex` and typesets
  `\printindex`. `hyperref` is loaded by Quarto's default template.
- **HTML** — the filter builds the index section itself out of collected mark
  records, emitting its own anchors and locator links. No index tool involved.
- **Pass-through** (gfm and any other format) — marks emit nothing; the visible
  text passes through with the span's attributes data-prefixed by Pandoc.

**The milestone.** M20 adds one format-neutral mark attribute, `mention="principal"`,
naming the role an occurrence plays: the term's principal discussion, as against
its passing mentions. Both back-ends were to print that one occurrence's locator
emphasized while the term's other locators stay plain. In HTML this works and is
verified. In LaTeX it is implemented as a makeindex **encapsulation**: the
principal mark emits `\index{cats|quartoindexprincipal}` where an ordinary mark
emits `\index{cats}`, and `\providecommand*\quartoindexprincipal` is injected
into the preamble only in a document that uses it, so an author can redefine the
emphasis.

**The defect that returned the milestone.** When a term's principal mark and any
other locator mark of the *same index key* land on the *same page*, the render
fails. Reproduced directly:

```
---
title: "same-page rival encapsulation probe"
from: markdown-smart
format:
  pdf:
    latex-clean: false
filters:
  - index
---

Both marks of one term in one sentence, on one page: [cats]{.index} are
discussed at length, and [cats]{.index mention="principal"} principally here.
```

`quarto render` on this exits 1 with:

```
ERROR:
compilation failed- error generating index
Conflicting entries: multiple encaps for the same page under same key.
```

The `.idx` handed to makeindex is:

```
\indexentry{cats|hyperpage}{1}
\indexentry{cats|hyperxindexformat{\quartoindexprincipal}}{1}
```

Note that `hyperref` has rewritten the ordinary mark's *absent* encapsulation
into `|hyperpage` and the principal one into `|hyperxindexformat{...}`.

makeindex itself only **warns** here (exit 0) and writes a correct `.ind`:

```
\item cats, \hyperpage{1},
        \hyperxindexformat{\quartoindexprincipal}{1}
```

The `.ilg` records `## Warning ... Conflicting entries: multiple encaps for the
same page under same key.` Quarto's PDF pipeline escalates that warning into a
failed render.

**What was probed next, and is the crux.** Running `makeindex` directly on
hand-written `.idx` files (makeindex 2.18, TeX Live 2026) establishes the rule:

| `.idx` contents | result |
|---|---|
| `\indexentry{cats}{1}` + `\indexentry{cats\|quartoindexprincipal}{1}` | **conflict warning** (`\item cats, 1, \quartoindexprincipal{1}`) |
| `\indexentry{cats\|hyperpage}{1}` twice | **no warning**; folded into `\item cats, \hyperpage{1}` |

So the conflict is triggered by **any** difference in the encapsulation string
for one key on one page, including bare-versus-encapsulated — it is not an
artifact of hyperref's rewriting, and it is not avoidable by choosing different
command names. Identical encapsulations are deduplicated silently.

**Why this is not a patch.** The filter runs before typesetting and has no page
numbers; it cannot know which marks will share a page. The only encapsulation
rule guaranteed conflict-free is therefore *every locator of a key carries the
identical encapsulation document-wide*, which is exactly "no per-locator
emphasis". The milestone's own recorded falsifier for its clash-rule choice is
already spent: it was measured on makeindex in isolation, where this is a
warning at exit 0, and is wrong about Quarto.

**Why it needs independent review.** It touches IP2 (never break the document),
which the project treats as its highest-severity class, and the disposition
ranges from "drop the LaTeX half of the feature" to "build a LaTeX-side
subsystem". The implementing session should not author that verdict alone.

## Materials

Read these, in the repository root:

- `cairn/DESIGN.md` — the principles quoted under **Constraints** below, plus
  the LaTeX back-end description.
- `cairn/DECISIONS.md` — D-003 and D-004 in full (quoted in part below).
- `cairn/milestones/M20-principal-locators.md` — Goal, Scope, Acceptance
  criteria, Tasks, Work log, and the `## Review` section (finding F1 is this
  question; F2/F9/F11/F12 and AC5 have since been repaired).
- `_extensions/index/modules/latex.lua` — the whole file (292 lines). Note
  especially `mark_encap` (line ~199) and its comment block explaining why the
  role is deliberately *not* routed through the contested-key machinery, and the
  "Contested keys" comment block (lines ~86–102) describing the repair M15 built
  for the analogous cross-reference collision.
- `_extensions/index/modules/passes.lua` — `principal_encap` (line ~109) and the
  emission branches in `Span` (lines ~285–345), which show where the role is
  applied on top of whichever shape contestation chose.
- `_extensions/index/modules/core.lua` — `PRINCIPAL_COMMAND`, `PRINCIPAL_DEFINITION`,
  `MENTION_ATTR`, `MENTION_ROLES`.
- `_extensions/index/index.lua` — the Pandoc pass that injects the preamble
  definitions.
- `examples/principal.qmd` — the milestone's fixture; note that its three
  `basilisk` marks are on three separate pages precisely to avoid this collision.
- `tests/run-tests.sh` lines 1–30 (the suite's ORACLE RULE) and its M20 section
  (search `M20-AC1`), plus `tests/m20probes.py`.

To reproduce the failure, write the `.qmd` quoted above to `examples/` and run
`quarto render examples/<name>.qmd --to pdf`; the `.ilg` beside it carries the
warning. To probe makeindex alone, write `.idx` files by hand and run
`makeindex` on them (TinyTeX's binaries are on the user's path under
`~/Library/TinyTeX/bin/universal-darwin` or `~/.TinyTeX/bin/universal-darwin`).

## Questions

1. **Is any emission-level rule sufficient?** Given a filter that sees the whole
   document but no page numbers, is there *any* rule for choosing `\index`
   arguments and encapsulations that realizes per-locator emphasis in this
   back-end and cannot produce two differing encapsulations for one key on one
   page? Consider rules that rewrite the key, the printed field, the sort field,
   or the encapsulation. If there is none, say so definitively and explain the
   argument, since the rest of the disposition rests on it.

2. **Evaluate the deferred-styling mechanism.** The one alternative the session
   identified: emit a *uniform* encapsulation for every locator of every key (so
   makeindex never sees a difference), have the principal mark additionally write
   its key and `\thepage` into the `.aux`, and, when `\printindex` typesets the
   index on a later pass, emphasize exactly the registered (key, page) pairs by
   wrapping the command that prints a locator. Assess soundness and cost,
   specifically:
   a. How can the locator-printing command learn *which entry* it is inside?
      `theindex` gives `\item`/`\subitem`/`\subsubitem` the entry's **printed**
      text, while the key written from Lua is the **filing** key — this back-end
      emits `sortkey@printed` when a sort key is declared, and folds level paths
      deeper than three into the third level joined with `, `. What is the robust
      way to reconstruct the identity, and what does it cost?
   b. Does `\thepage` at the mark's location reliably agree with the page number
      makeindex records for that same `\index` command, including inside floats,
      footnotes, and at page boundaries?
   c. What breaks under `hyperref` (which already redefines `\hyperpage`),
      `imakeidx`, and Quarto's own multi-pass PDF build? How many compilation
      passes would be required, and does Quarto run enough of them?
   d. Would this mechanism survive an author redefining the emphasis command, as
      the current design promises?

3. **Is there a third mechanism?** Consider anything neither option above names:
   makeindex style (`.ist`) facilities, a different encapsulation discipline,
   `imakeidx` features, `splitidx`, `xindy`/`texindy`, `upmendex`, or emitting a
   second index entry. For each, say whether it is available within GP3 (packages
   bundled in mainstream TeX distributions, no runtime dependency beyond Quarto)
   and whether Quarto's PDF pipeline can be made to use it.

4. **Disposition, if no mechanism is sound at acceptable cost.** Rank these and
   name the one you would take, with reasoning:
   a. **Drop the LaTeX realization.** `mention=` stays a format-neutral attribute
      realized in HTML; the LaTeX back-end reports it as unrealized and indexes
      the mark plainly. IP1 explicitly allows this ("A feature's semantics must be
      format-neutral even when only one back-end realizes it yet; unrealized
      formats degrade gracefully"). Costs the milestone two acceptance criteria
      and its stated goal of "both back-ends".
   b. **Keep the current emission and document the collision** as a known failure
      mode under GP2's "known failure modes documented". The session reads this
      as violating IP2 and D-003; say plainly if you disagree, and if so, on what
      grounds.
   c. **Remove `mention=` entirely** and abandon the feature in both back-ends.
   d. Something else you name.

5. **Is the plan gate's premise recoverable?** makeindex warns at exit 0; it is
   Quarto that escalates. Is there any supported configuration — a Quarto option,
   a `makeindex` invocation flag, an `imakeidx` option — under which this specific
   warning does not fail the render, and would relying on it be inside GP2 and
   D-003 (which license changing what the extension *emits* when its own output
   is unusable, but not detecting or managing a toolchain failure the emission
   did not cause)? Note that any blanket warning suppression would also mask the
   genuine collision M15 exists to prevent; say whether a narrower lever exists.

6. **Is the emission correct at all?** Independently of the collision: is
   `\index{key|command}` with a `\providecommand`-defined single-argument command
   the right way to encapsulate a locator under `hyperref` + `imakeidx`, and does
   `\hyperxindexformat{\quartoindexprincipal}` behave as intended in the `.ind`?

## Constraints

Fixed; flag disagreement explicitly rather than silently working around it.

- **IP1 — Format-neutral marking.** "The index-mark syntax and all attribute
  values carry format-neutral meaning; back-ends realize them per format. A mark
  value is never raw back-end code (no raw LaTeX or HTML pass-through; D-001). A
  feature's *semantics* must be format-neutral even when only one back-end
  realizes it yet; unrealized formats degrade gracefully (IP2)."
- **IP2 — Never break the document.** "A document using this extension never
  fails to render, and never silently corrupts output, because of a marked term
  … An escaping bug, a crash on exotic input, or garbage in a back-end-less
  format is the highest-severity bug class and earns a regression test forever."
- **IP3 — Post-release syntax stability.** Not yet binding: the project is
  pre-release, so `mention=`'s spelling is still fluid.
- **GP2 — The contract ends at correct emitted output.** "Per format, the job is
  correct output (e.g., valid `\index{}` LaTeX); whether the user's toolchain
  then builds the index is a documentation surface — known failure modes
  documented, never detected or managed."
- **GP3 — Pure Pandoc-Lua, self-contained.** "Zero runtime dependencies beyond
  Quarto; `quarto add` is the entire install story. LaTeX-side needs stay within
  packages bundled in mainstream TeX distributions." Injecting `\providecommand`
  definitions into the preamble is established practice in this extension and is
  not a violation.
- **GP5 — Minimal API surface.** "Prefer one composable mechanism over parallel
  syntaxes."
- **GP6 — End-to-end verification.** "Acceptance evidence for output-producing
  features runs to the final compiled artifact (a PDF with a real index), not
  only intermediate output."
- **D-003 (2026-08-19): Output the index tool cannot consume is the extension's,
  not the toolchain's.** "A pair of commands the documented index tool provably
  cannot process is incorrect emitted output, not a toolchain failure, so
  repairing it sits inside GP2 rather than trading against it. The reading is
  deliberately narrow: it licenses changing what the extension emits when the
  extension's own output is unusable, never detecting or working around a failure
  the emission did not cause."
- **D-004 (2026-08-20)** rejected byte-level output comparison as a refactor
  oracle; the acceptance suite is the sole oracle for output neutrality. Do not
  propose restoring a byte-diff.
- The acceptance suite's ORACLE RULE: manifest rows are derived by hand from the
  `.qmd` and the documented semantics at each layer, never copied from filter
  output.
- Package choices are not commitments: DESIGN states that "principles bind 'the
  LaTeX back-end,' and swapping its implementation is an" open option — so
  replacing `imakeidx` or `makeindex` is on the table if it is within GP3 and
  Quarto's pipeline supports it.

## Output format

In `RR01-principal-locator-encapsulation.md`: answer each question by number with
your reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: this brief's header slot
says `not requested`, so emit no `## Binding criteria` section.
