# M01: LaTeX index extension skeleton

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, IP3, GP1, GP4, GP5, GP6
- **Branch/PR:** `m01-latex-index-skeleton` · https://github.com/jmgirard/quarto-index/pull/1

## Goal

Ship the quarto-index extension skeleton: a Lua filter that turns span-syntax
index marks into LaTeX `\index{}` commands with automatic preamble and
`\printindex` injection, verified end-to-end to a compiled PDF. User-facing
tier: the span markup and rendering behavior are the exported API extension
users consume.

## Scope

**In:**
- Extension scaffold `_extensions/index/` (`_extension.yml`, Lua filter),
  consumed by the examples the way a user would (via `_extensions/`).
- Span syntax only — the four forms AC4 fences and the README documents;
  no shortcode or other parallel syntax (GP5).
- Entry semantics (IP1, D-001): entry values are structured, format-neutral
  data — never raw LaTeX. `entry="..."` parses into `!`-separated levels,
  longest-match, `!!` a literal `!`; a trailing empty level is warned about
  and emitted as written, except inside a folded tail where it is dropped
  (leading/medial empties are a known makeindex failure → ROADMAP). Each level
  is literal text — of a visible term or an `entry=` value alike — that the
  extension emits as correct LaTeX itself (mechanism: the Decisions entries).
- `latex`/`pdf` output only (beamer excluded — it has no `theindex`
  environment): emit `\index{}` at the mark's position; makeindex stores
  three levels, so deeper entries fold into the third, joined with `, `,
  and warned about — never silently dropped. When ≥1 mark exists, inject
  `\usepackage{imakeidx}` + `\makeindex` into the preamble and append one
  `\printindex` at document end (auto placement; no marks → no injection).
- Pass-through check (verification only): the two back-end-less formats
  verified here — HTML and beamer — keep the visible text, gain none of
  `\index`, `imakeidx`, `\makeindex`, `\printindex`, and never fail to
  render (IP2); one shared format gate covers all such formats.
- Demo, control, escaping and content-probe examples, test script, README,
  TinyTeX install for local PDF verification.

**Out:** (each a ROADMAP candidate row): HTML index generation (span text
stays visible in HTML; index behavior there undefined for now); sort keys
and locator styling (`@ | "` stay ordinary literal characters, future
sort/styling arriving as separate span attributes); multi-chapter book
(cross-file) support; release prep / first tagged release (window
user-declared); explicit index-placement option and shortcode syntax.

## Acceptance criteria

`tests/run-tests.sh` is normative for M01: it declares the supported-forms
list, the escaping probe set, and four hand-derived manifests (demo entries,
control tokens, visible terms, PDF terms). The script header states the
by-hand derivation rule (never copied from filter output); review re-derives
the escaping-probe, sub-entry and `!!`-run rows independently of it.

- [ ] AC1: The script renders `examples/demo.qmd` to LaTeX via the installed
      extension with exit 0 and the `.tex` matches the expected-entries
      manifest exactly: each row's `\index{<entry>}` text matches its expected
      count, the total `\index` count equals the manifest total (extra or
      missing commands fail), and the manifest is non-empty.
- [ ] AC2: The demo `.tex` contains `\usepackage{imakeidx}` (with or without
      options) followed later by `\makeindex`, both before `\begin{document}`,
      and exactly one `\printindex`, after all body content and before
      `\end{document}`.
- [ ] AC3: `examples/control.qmd` — no marks, but mark-like text in a fenced
      code block and inline code — renders to LaTeX with exit 0 and a
      non-empty `.tex` with no `\index{`, `imakeidx`, `\makeindex`, or
      `\printindex`. Mark-like text survives as content: every control-manifest
      token — for each mark, an escape-free token containing that mark's own
      `entry=` value or visible text — matches its exact count.
- [ ] AC4: The supported-forms list is normative — visible-term, custom-entry
      (single-level `entry=`), sub-entry (`!`-separated levels, literal `!` via
      `!!`), and invisible-entry spans — and the probe set puts visible terms
      and `entry=` levels *each independently* through every character of the
      escape domain (Pandoc's LaTeX-writer escapes plus makeindex's actives `!
      @ | "`), which the script pins to the filter's own escape table and
      requires in both contexts of the demo; across leading, medial and
      trailing positions (union coverage, not the cross-product), plus `!!`
      leading/medial/trailing, one odd-length `!` run, a level whose literal
      text is one backslash (typed `\\`), one entry deeper than three levels
      ending in an empty level, whose render log must carry both the fold and
      empty-level warnings, one Latin-1 accented term as a visible term and one
      inside an `entry=` level (the range pdflatex's default fonts cover; other
      scripts await an engine decision → ROADMAP), and one pinning that `\!`
      yields two levels. Each form has ≥1 counted instance in
      `examples/demo.qmd` under AC1's manifest; the README documents exactly
      those four span forms and no others, plus how a literal backslash and `"`
      are written inside `entry=`, and the three-level ceiling with its
      folding. Separately (sharing AC6's toolchain precondition),
      `examples/escaping.qmd` covers every printable ASCII character except the
      space — each as its own term and its own level, a literal `!` written
      `!!` — and compiles, has every entry accepted by makeindex with none
      rejected, and typesets every escape-domain character in its index.
- [ ] AC5 (tracking hygiene): `cairn/PROFILE.md`'s `verify` slot names
      `tests/run-tests.sh`; the script fails loudly (`set -euo pipefail`) and
      passes a self-test: against a deliberately broken fixture (one
      manifest-expected `\index` command removed, one altered, one spurious
      `\index` added) it exits non-zero and names the mismatching row(s).
- [ ] AC6: With TinyTeX installed (user-approved at the plan gate; requires
      network), `quarto render examples/demo.qmd --to pdf` exits 0 and
      `pdftotext -layout` output, whitespace-normalized, has an index heading,
      and the text following it lists every PDF-manifest term (the
      derived-from-visible-text, single-level, non-`entry=` terms), including
      the escaping probes with their special characters literally and in
      order. The script fails loudly if `tinytex`, `makeindex`, or `pdftotext`
      is missing, so this can never pass unrun; explicit `entry=` entries are
      verified by AC1 instead.
- [ ] AC7: `examples/demo.qmd` renders to HTML with exit 0, and to beamer
      (sharing AC6's toolchain precondition) with exit 0 whose kept `.tex` is
      free of `\index`, `imakeidx`, `\makeindex`, `\printindex` while
      retaining visible text — the regression test for the IP2 failure review
      found, where any mark aborted a beamer render. In HTML each visible term
      appears as rendered text — markdown backslash-escapes consumed, then
      `&`, `<`, `>` as HTML entities — per the visible-terms manifest, every
      row's count checked against the rendered `.index` spans, pinned
      complete: the manifest's count total must equal `]{.index` minus
      `[]{.index` occurrences. The `.html` carries none of those four tokens,
      and with tags stripped its body text contains no value from the script's
      `entry=` no-leak manifest, which the script pins by sweeping every
      `entry=` value in the `.qmd`: each must be listed there or be a
      substring of a visible term. Surviving span attributes are permitted.
## Coverage

- AC1 → T2,T4,T5 · AC2 → T3,T5 · AC3 → T2,T3,T4,T5 · AC4 → T4,T5,T6 · AC5 → T5 · AC6 → T3,T5 · AC7 → T2,T4,T5

## Tasks

- [x] T1: Scaffold `_extensions/index/` (`_extension.yml`, filter
      registration); examples consume it via `_extensions/`.
- [x] T2: Span recognition (`.index`) and the entry semantics stated in
      Scope: level parse, per-character escaping, depth fold, invisible
      entries, warn-and-continue, emission only for `latex`/`pdf`.
- [x] T3: Conditional injection — `\usepackage{imakeidx}` + `\makeindex` in
      the preamble and one `\printindex` at document end when a document has
      marks; nothing at all when it has none.
- [x] T4: Author `examples/demo.qmd` (every form, the full probe set, a term
      marked three times) and `examples/control.qmd` (mark-like text in
      fenced and inline code).
- [x] T5: Install TinyTeX; write `tests/run-tests.sh` — hand-derived
      manifests, probe-set pin, tool guard, planted-defect self-test —
      implementing AC1-AC7; fill the PROFILE `verify` slot.
- [x] T6: README: install, the normative syntax forms, `!`/`!!`, the Pandoc
      backslash layer, the three-level ceiling, auto-placement, and the
      pre-release notice (IP3).

## Work log

- 2026-08-16: created by /milestone-plan.
- 2026-08-16: criteria audit ran in full mode (fresh [O] reader, user-facing tier): ~15 findings + 3 gaps; clear-fix findings applied to the AC wording (manifest with count equality, \makeindex token, control-doc render guards, negative-control code probes, escaping probe, installability via _extensions/, script self-test, AC6 layout/preconditions/disposition); judgment calls disposed at the plan gate.
- 2026-08-16: plan gate chose span-only syntax over shortcode (and both) because one pandoc-native mechanism covers visible/custom/invisible entries with half the API surface; falsified by user demand for a form spans cannot express.
- 2026-08-16: plan gate chose TinyTeX install over .tex-only verification because end-to-end PDF proof covers the compile+makeindex path that .tex inspection cannot; falsified by TinyTeX proving unusable in this environment (install or network failure).
- 2026-08-16: plan gate chose auto \printindex at document end over an explicit placement marker because zero-config covers the common case and a placement option can be added compatibly later; falsified by demand for mid-document placement no compatible option can serve.
- 2026-08-16: plan (autonomous) chose escaped derived-entries + raw entry= pass-through over uniform raw pass-through because visible-text terms containing LaTeX specials must not break builds while power users keep full \index syntax; falsified by an escaping bug class the probe term fails to catch.
- 2026-08-16: design interview adopted format-neutral entry= semantics (structured data the extension parses, never raw LaTeX pass-through) — the Scope's raw-pass-through escaping design needs a gated plan amendment before implementation starts.
- 2026-08-16: plan amendment (per D-001/IP1): structured entry= semantics replace raw pass-through — Scope, AC1–AC7, T2/T4/T5/T6 amended; AC7 (HTML pass-through) added to close an IP2 coverage gap.
- 2026-08-16: criteria audit ran in full mode (fresh [O] reader, user-facing tier) on the amended criteria: 5 clear-fix groups applied (AC2 ordering/placement, AC3 positive verbatim check, AC4 probe set + entry= probe + IP1 README framing, AC5 self-test specificity, AC6 D-001 wording/definitions/literal-character check), 1 IP2 coverage gap closed (AC7), 3 judgment calls disposed at the gate; gate-changed wording (AC1 manifest rule, AC6 tool guard) is the auditor's own proposed fix text.
- 2026-08-16: amendment gate kept parsed `!` sub-entry levels (with `\!` escape) over deferring hierarchy because the plan promised sub-entries and the parse is small; falsified by a level-separator collision class the `\!` escape cannot express.
- 2026-08-16: amendment gate chose literal-forever `@ | "` (future sort/styling as separate attributes) over reserve-with-error because attributes are more format-neutral than inline sigils and errors sit uneasily beside IP2; falsified by a future inline-sigil need no attribute form can express.
- 2026-08-16: amendment gate chose hand-authored manifest (oracle, rule in script header) over accepting snapshot circularity; falsified by hand-derivation proving too error-prone to maintain.
- 2026-08-16: amendment gate chose fail-loudly tool guard (tinytex/makeindex/pdftotext) over conditional skip with logged deferral; falsified by a supported dev environment where TinyTeX genuinely cannot install.
- 2026-08-16: /milestone-implement started; status → in-progress; branch `m01-latex-index-skeleton` cut from pushed `main`.
- 2026-08-16: probe established Pandoc consumes one backslash level in quoted span-attribute values (`\!`→`!`, `\\`→`\`, `\"`→`"`); all 13 probe characters are expressible inside `entry=`.
- 2026-08-16: question gate chose `!!` doubling over filter-level `\!` for a literal `!` because source and filter then agree with no backslash counting; falsified by a level-syntax need doubling cannot express. Supersedes the escape named in the 2026-08-16 amendment-gate line above (that line stands as history, IP4).
- 2026-08-16: question gate chose index-in-TOC (`\makeindex[intoc]`) and warn-and-continue on a mark with nothing to index.
- 2026-08-16: cap remedy at the amendment gate: Scope Out-list compressed to a cross-reference of the existing ROADMAP candidate rows (promise unchanged, nothing moved between In and Out); plan-owned body 155 → 149.
- 2026-08-16: T1 done — `_extensions/index/` (`_extension.yml` + `index.lua` stub) scaffolded; `quarto render examples/demo.qmd --to latex` exits 0. Quarto resolves filters only from the input file's own directory absent a project file, so `examples/_extensions` is a symlink to the repo-root `_extensions/`, letting examples consume the extension exactly as an installed user does.
- 2026-08-16: minor amendment — `tests/run-tests.sh` is grown from T2 onward rather than authored whole at T5, so each task has a real verify gate; T5 still owns the manifest, tool guard, self-test, and PROFILE slot.
- 2026-08-16: substantive amendment (`!!` escape): Scope entry-semantics bullet, AC1 manifest-derivation clause, AC4, T2, T6 amended; amended AC-wording audited in full mode by a fresh [O] reader that did not author it — 10 findings, 8 applied as clear fixes, finding 5 resolved by probe (`"` is expressible), findings 9-history and 10 disposed per append-only and documented-claim-owes-a-test.
- 2026-08-16: substantive amendment (AC3, AC7 unsatisfiable as written): renders proved Quarto LaTeX-escapes code content (`\{`, `{[}`, escaped spaces) and Pandoc HTML-escapes `&`→`&amp;` while consuming markdown backslash-escapes, so both byte-verbatim containment clauses were unreachable; replaced with count-checked manifests. Fresh [O] audit returned 7 findings, 6 clear fixes applied.
- 2026-08-16: gate chose one-pass compression of the whole criteria section (enumerations delegated to the normative `tests/run-tests.sh`) over trimming other sections or a cap exception; and chose to permit surviving `.index` HTML span attributes, AC7 constraining rendered text only.
- 2026-08-16: second fresh [O] audit of the recompressed criteria set returned 11 findings; all 9 clear fixes applied — restored AC1's "via the installed extension" anchor, fixed AC7's entry-leak clause (the one-backslash entry value is a substring of body text, so the naive rule was unsatisfiable) and its ambiguous row-count pin (now count-total, occurrences not lines), scoped AC6 to text after the index heading (whole-output matching passed even with an empty index), added AC5's spurious-`\index` planted defect, anchored AC3's token choice to each mark's own payload, and disambiguated AC4's "independently". Finding 11 taken as option (i): empty-level probe added to AC4 and `examples/demo.qmd`.
- 2026-08-16: cap remedy — Coverage compressed to two lines and T2's restated semantics trimmed (Scope and AC4 own them); plan-owned body 149.
- 2026-08-16: T2 done — `.index` span recognition, `!`/`!!` level parse, per-character LaTeX escaping and makeindex quoting, invisible entries, warn-and-continue on an empty mark (element dropped so no empty group is left) and on an empty level; emission gated to LaTeX-derived formats.
- 2026-08-16: T3 done — `quarto.doc.use_latex_package("imakeidx")` + `\makeindex[intoc]` via in-header include, one `\printindex` appended; verified ordered `\usepackage` → `\makeindex` → `\begin{document}` and `\printindex` before `\end{document}`; no injection when a document has no marks.
- 2026-08-16: T4 done — `examples/demo.qmd` (21 marks: all four forms, `!!` leading/medial/trailing, odd `!` run, empty level, one-backslash level, `\!` pin, full 13-character probe across visible terms and `entry=` levels) and `examples/control.qmd` (mark-like text in fenced and inline code). `from: markdown-smart` is set on both: with Quarto's default smart typography a typed `"` becomes a curly quote, leaving makeindex's quote character unexercised.
- 2026-08-16: AC6 caught a real IP2 escaping bug — hyperref rewrites an index argument at its first `|` before makeindex runs and ignores makeindex quoting, so a literal `|` in a term corrupted the entry; a quoted `""` also typeset as a curly quote. `|` and `"` now emit as `\textbar{}`/`\textquotedbl{}`. See the Decisions entry. Visible probe terms were split into five short ones so none wraps across the two-column index (AC4 requires the visible-term context to cover all 13 characters, not one term to carry them).
- 2026-08-16: T5 done — `tests/run-tests.sh` (oracle rule in header, four hand-derived manifests, tool guard, planted-defect self-test) passes AC1-AC7 with exit 0; PROFILE `verify` slot filled. The self-test first exposed a gap in the checker itself: unexpected entries were only listed when the total count mismatched, so three planted defects that cancel in the total went unnamed; extras now always fail.
- 2026-08-16: T6 done — README documents exactly the four span forms, `!`/`!!`, the Pandoc backslash layer (`\\`, `\"`, and `\!` being no escape), auto-placement, and the pre-release at-your-own-risk notice. A License section was written and removed: no LICENSE file exists, so the claim had no basis; added as a ROADMAP candidate (user decision).
- 2026-08-16: all tasks complete; `tests/run-tests.sh --self-test` exits 0 with AC1-AC7 all green; status → review.
- 2026-08-16: minor amendment — Scope and T2 described `|`/`"` as makeindex-quoted, which the bug fix made false; wording corrected to "made literal" with the mechanism cross-referenced to the Decisions entry. The promise is unchanged.

- 2026-08-16: catch-up — commit e416c6a carried T2/T4 implementation (index.lua +159, control.qmd) under an amendment-titled message while those tasks were still unticked; the "T2/T4 done" lines landed two commits later in db6204e. Tracking-travels-with-code was not honoured there. Recorded, not rewritten (IP4).
- 2026-08-16: review returned M01 to in-progress (defect return #1). AC7 fails inside its own named procedure: tests/run-tests.sh:394 checks visible-term presence only, discarding the per-row counts AC7 requires. Two IP2 violations also block: `--to beamer` renders fail fatally when a document has any mark (no theindex environment; reproduced exit 1), and entries deeper than three levels are silently discarded by makeindex while the build stays green (reproduced). AC1-AC6 verified clean; evidence retained above.

- 2026-08-16: review-return fixes. R1 (IP2): beamer dropped from the LaTeX back-end — `is_latex_derived()` now matches `latex` only, so beamer passes through; verified exit 0 with zero index tokens in its kept `.tex`, where before any mark aborted the render. R2 (IP2): levels past the third are folded into the third, joined with `, `, with a warning naming the entry, instead of being silently rejected by makeindex. R3: AC7 now counts each visible term inside the rendered `.index` spans; proved non-vacuous by a discriminating test that perturbs two manifest rows while holding the total constant — presence-only checking passes that, count-checking fails both rows. Also R7 (`<`/`>` added to the escape table), R8 (`quarto.doc` guarded), R9 (Latin-1 probes in both contexts), R4/R5/R6 (superseded comments corrected).
- 2026-08-16: substantive amendment after the return, audited full-mode by a fresh [O] reader (11 findings, 9 clear fixes applied). The fold clause moved out of the format-neutral entry-semantics bullet into the back-end bullet: `clamp_levels` runs only on the LaTeX branch, so stating it as mark semantics was empirically false for HTML and leaked a back-end limit into IP1. The `, ` join is now documented, since AC1's manifest row was otherwise underivable by hand. AC4's character list was re-anchored from a recall-fixed enumeration to the escape domain, pinned in the script against the filter's own table (closing R10). AC4 now requires the fold warning to appear — the warning is the whole IP2 justification for folding and nothing asserted it. AC7's beamer clause checks the kept `.tex`, not just exit 0: an `\index`-only regression exits 0 because `\index` is a no-op without `\makeindex`. AC7's no-leak list is now pinned by sweeping the `.qmd`. Non-ASCII narrowed to Latin-1 with the pdflatex font limit stated.
- 2026-08-16: cap remedy — acceptance-criteria preamble compressed and the Tasks section rewritten to one short entry per task (the work log carries what each did); plan-owned body back under 150.
- 2026-08-16: all seven criteria unticked. The prior review's evidence predates the filter, example and manifest changes above, so it is stale; re-review gathers fresh evidence for every criterion.

- 2026-08-16: review-return fixes complete; `tests/run-tests.sh --self-test` exits 0 from clean artifacts with three new checks (probe-set pin, fold warning, beamer token check); status → review.

### Independent review — pass 2

Three fresh lenses again. Defect return #2. Prior blockers R1-R3 all
re-verified as genuinely fixed by two independent lenses; the suite is green,
which is the problem — the green was under-scoped.

**Return-forcing (each reproduced by this session):**
- N1 [O] An unbalanced `{` or `}` in any term or `entry=` aborts the PDF
  render. `\index` reads its argument under `\@sanitize`, which sets `\` to
  catcode 12, so `\{`/`\}` are NOT escapes there — they are real group
  characters. Reproduced: `[open \{ only]{.index}` emits
  `\index{open \{ only}` and the render exits 1, "Paragraph ended before
  \@wrindex was complete". The demo probes braces only in balanced pairs, so
  they cancel and AC6 passed by accident. Same class as the `|` bug; wants
  `\textbraceleft{}`/`\textbraceright{}` plus an unbalanced probe in both
  contexts. IP2 fatal-render violation.
- N2 AC4 fails inside its own promise: it requires visible terms and `entry=`
  levels *each independently* to cover every character of the escape domain,
  but no `entry=` probe contains `<` or `>` — the R7 widening added them to
  the filter table, `PROBE_CHARS` and a visible term only. Found independently
  by this session's re-derivation and by [O].
- N3 [O] The depth fold silently repairs a trailing empty level and swallows
  its warning, contradicting Scope and README ("emitted as written and warned
  about, never repaired"). Reproduced: `entry="A!B!C!D!"` yields
  `\index{A!B!C, D, }` with only the depth warning and a dangling `, ` in the
  printed index. `clamp_levels` runs before the per-level empty check.

**Fix-now (queued with the return):**
- N4 [O] The probe pin does not deliver what AC4 and the script comment claim:
  it compares `PROBE_CHARS` to the filter table and never to
  `examples/demo.qmd`, so a character can be in both and probed nowhere — N2
  is the live instance. The pin must check per-context coverage in the demo.
- N5 [O] R4 only half fixed: `index.lua`'s file header still says the back-end
  "quotes makeindex-active characters", false for `|` and `"` since the AC6 fix.
- N6 [O] R7 only half fixed: README still lists a 14-character set; the escape
  domain is 16.
- N7 [S] Three first-pass dispositions were recorded but never executed — R16,
  R17 and R19 have no ROADMAP row, no fix and no work-log line.
- N8 [S] AC7's beamer clause silently inherits AC6's TeX-toolchain
  precondition; unlike AC6, AC7's wording does not disclose it.

**Follow-up candidates:**
- N9 [O] The `entry=` no-leak sweep only matches quoted values; Pandoc accepts
  bare `entry=Foo!Bar`, which the sweep would miss.
- N10 [O] `index_args`' brace scanner ignores `\{`/`\}` — R14's "benign today"
  no longer holds once N1's unbalanced probe lands; the harness needs fixing
  first.
- N11 [O] AC4's "escape domain" nominally includes `[`/`]` (Pandoc escapes
  them) but neither the filter table nor `PROBE_CHARS` has them; verified
  harmless in practice.
- N12 [O] The ANSI-stripping `sed` in the tool guard is a GNU extension; on
  BSD sed it fails safe (loud), never falsely green.
- N13 [O] AC7's completeness pin counts the `]{.index` substring, so
  `[x]{#id .index}` would not be counted.
- N14 [O] The plain-pandoc guard checks `use_latex_package` but not
  `include_text`.

**Logged, no action:** [S] the cap-remedy compression dropped three
disambiguating prose clauses (AC3 "whole positive check", AC7 "occurrences,
not matching lines", AC4 "reviewer-verified") without per-clause work-log
lines; no coverage changed. [O] warning wording says "the last one" where
"the third" is clearer; `entry=""` mislabels a warning context.

- 2026-08-16: review pass 2 returned M01 to in-progress (defect return #2). AC4 fails inside its own promise — no `entry=` probe covers `<` or `>`, so the two contexts are not each independently swept. Two IP2 defects also block: an unbalanced `{` or `}` in a term or entry aborts the PDF render (`\index` reads under `\@sanitize`, so `\{` is not an escape), and the depth fold repairs a trailing empty level while swallowing its warning, contradicting Scope and README. Prior blockers R1-R3 re-verified fixed. One further return trips the thrash threshold.

- 2026-08-16: return-2 fixes. N1: `{`/`}` emit as `\textbraceleft{}`/`\textbraceright{}` — reproduced the abort first (`[open \{ only]{.index}` → "Paragraph ended before \@wrindex was complete"), then confirmed the fix compiles. N3: the empty-level warning moved ahead of clamping, and the demo's deep probe now ends in an empty level, so the interaction that broke is the one probed; both warnings are asserted. N2/N4: `<`/`>` added to the demo's `entry=` probe, and the probe check now requires every escape-domain character in BOTH contexts of the demo rather than only matching the filter table. N5/N6: the filter's file header and the README character list corrected.
- 2026-08-16: `examples/escaping.qmd` replaces the hand-listed probe with a procedurally-defined one: every printable ASCII character except the space, each as its own term and its own level, compiled for real. The suite checks all three ways an escaping bug reaches a reader — the build breaks, makeindex rejects the entry, or it fails to typeset — with a second pdflatex pass so the generated index is actually set. 188 entries accepted, 0 rejected, every escape-domain character present in the typeset index. This ends the recurring class where a character was missing from a recall-fixed list.
- 2026-08-16: amendment audited full-mode by a fresh [O] reader (9 findings, all applied). It caught that the new probe file was itself unpinned (its expected count was derived from the file, so deleting probes shrank the expectation), that the empty-level warning was asserted by nothing while its failing case was probed nowhere, that compiling proves a character *reads* but not that it *prints*, and that the Scope compression had dropped "for derived and explicit entries alike" and weakened "emits correct LaTeX" to "makes safe". All four are fixed; the domain is now procedural, which was the auditor's recommended option over widening the list a third time.
- 2026-08-16: cap remedy — Coverage folded to one line, AC3/AC4/AC6 tightened and AC4/AC7 reflowed; plan-owned body 149.
- 2026-08-16: return-2 fixes complete; `tests/run-tests.sh --self-test` exits 0 from clean artifacts with 12 checks; status → review.

### Independent review — pass 3

Defect return #3; the thrash threshold is reached. Prior blockers R1-R3 and
N1-N2/N4-N7 all re-verified fixed by two lenses; the suite's 12 checks are
green. What follows is what the green does not cover.

**Return-forcing (each reproduced by this session):**
- P1 [O] A mark whose content stringifies to empty DELETES that content in
  every format. `[![](pic.png)]{.index}` renders as "Before after" — the
  image is gone, because the nothing-to-index guard tests
  `stringify(content) == ""`, true for an image with empty alt text. IP2
  silent corruption; nothing in the suite probes non-text span content.
- P2 [O] `\printindex` is inserted before the bibliography, not at document
  end. Reproduced: `\printindex` at line 215, `\begin{CSLReferences}` at 218.
  README claims "one `\printindex` at the end of the document". AC2 passes
  only because the demo has no bibliography — the criterion is satisfied by a
  document that dodges the failing case. Filed as follow-up R13 in pass 1;
  that disposition was wrong, it is a shipped user-visible defect.
- P4 [O] N3 is only half fixed. The warning was restored but the dangling
  separator was not: the typeset demo index reads `Three, Four, Five, ,` and
  `run-tests.sh` now pins that string as expected, so the artifact is pinned
  rather than repaired. README's "left as written ... rather than silently
  repaired" is false for a >3-level entry, whose empty level is merged away.
- P6 [O] The escaping evidence is gathered under the wrong engine. Quarto
  renders PDF with lualatex here; the escaping probe compiles with pdflatex
  directly, and `escaping.qmd` never goes through Quarto's PDF path. The
  milestone's central IP2 claim rests on an engine no criterion exercises.
  `require_pdf_tools` also does not guard `pdflatex`, which that block invokes.
- P7 [O] AC5 is self-certifying: it requires the script to exit non-zero on a
  broken fixture, but the self-test wraps the call in `set +e` and asserts
  only that the helper function returned non-zero. The script exits 0.

**Fix-now (queued with the return):**
- P3 [O] The N3 regression grep does not fence what its comment claims: it
  matches any empty-level warning, and the 2-level probe `A!!B!` warns under
  either ordering. Verified by reverting the fix in a scratch copy — both
  greps still pass. It must assert the warning names the deep entry.
- P5 [O] README overclaims: "confirms each character actually typesets" is
  true of the 16 escape-domain characters, not all 94; and "every printable
  ASCII character" excludes the space, which is excluded by construction.
- P8 [O] The no-leak manifest tests source-form values (`Wow!!Really`), not
  the parsed values a leak would emit (`Wow!Really`), so 6 of 12 rows could
  not catch the leak they exist for; the `Specials` row is vacuous besides.
- P9 [O] The tag-stripping regex assumes no raw `>` inside a tag; Pandoc
  leaves `<`/`>` raw in attribute values, so it mis-parses.
- P12 [O] `examples/demo.qmd:45` still lists 14 characters; the domain is 16.
- B1 [S] The work-log line claiming the audit restored "emits correct LaTeX"
  is inaccurate — the final Scope reads "emits correctly itself". Superseded
  by the correcting line below rather than edited (IP4).
- B2 [S] Pass 2's follow-ups N9, N10, N12, N13, N14 have no ROADMAP row — the
  exact gap N7 raised, recurring in the round that fixed N7.
- B3 [S] The ROADMAP row for R14 is now stale: the brace scanner is no longer
  "benign today".

**Follow-up:** P10 [O] AC1/AC7 manifest coverage can shrink silently — unlike
the ASCII probe, the demo manifests have no independent count, so deleting a
mark and its rows leaves the suite green; several AC4 probes are unfenced this
way. P11 [O] The demo's own makeindex acceptance is never asserted, so a
rejected entry would vanish with the build green.

**Closed:** [O] confirms the `entry=""` warning-context mislabel is
unreachable; `\index` in headings and table cells verified harmless under this
engine; `escape_level` verified UTF-8-safe by construction.

- 2026-08-16: review pass 3 returned M01 to in-progress (defect return #3 — thrash threshold reached). AC5 fails literally: the self-test asserts the helper returns non-zero while the script exits 0. Two IP2 defects reproduced: a mark whose content stringifies to empty deletes that content (an image with empty alt text disappears from the document), and the >3-level fold still leaves a dangling separator in the typeset index, which the manifest now pins rather than repairs. `\printindex` also precedes the bibliography, contradicting the README, and the escaping evidence is gathered under pdflatex while Quarto ships lualatex here.
- 2026-08-16: supersedes the 2026-08-16 line claiming the audit restored "emits correct LaTeX" to Scope: it did not — the final Scope reads "emits correctly itself", and the "No raw LaTeX pass-through" sentence was dropped (its substance survives as "never raw LaTeX" earlier in the bullet).

- 2026-08-16: descope round (thrash disposition: narrow to what is verified, promise only what is tested). Shipping defects fixed rather than deferred: P1 a mark whose content yields no text no longer deletes that content — only a genuinely empty span is dropped, and an image with empty alt text now survives (verified); P4 an empty level inside a folded tail is dropped rather than left as a dangling separator, so the printed index reads `A!B!C, D`. P7 AC5 now asserts the script's own exit code via an internal `--fixture-check` mode; the script exits 1. P3 the regression grep now names the deep entry — proved by reverting the fix in a scratch copy and watching the suite fail with the right message. P6 the escaping probe compiles through Quarto's own PDF engine, so the evidence is gathered under the engine that ships. P8/P9 the no-leak check tests parsed as well as source forms and strips tags without breaking on raw `<`/`>` in attributes.
- 2026-08-16: promises matched to evidence rather than narrowed by dropping criteria — all seven still pass as written. README no longer claims every printable character is typeset-checked (16 are; the rest are compile- and acceptance-checked), and now states plainly that the index prints before the references in a document with a bibliography. That ordering, the unfenced-coverage items and pass-2's remaining follow-ups are ROADMAP rows, not M01 work.
- 2026-08-16: no acceptance-criterion wording changed this round, so no criteria audit was owed; the Scope entry-semantics bullet was amended (folded-tail empty level) and is shown verbatim at the gate.

- 2026-08-16: gate fixes (review pass 4, no return). P1's content-preservation fix had no regression test, which IP2 requires for this class: `examples/content.qmd` now probes a mark wrapping an image with empty alt text, asserting the image survives in HTML and LaTeX and that only the `entry=` mark emits an `\index`. Proved discriminating by reverting the fix — the suite then fails with "marking an image removed it from the HTML output". `pdflatex` added to the tool guard, since the escaping block invokes it directly. Two ROADMAP rows trimmed: the script-exit-code item was completed in M01, and the R14 brace-scanner row now says why it is no longer benign.
- 2026-08-16: annotating the 2026-08-16 supersession line about Scope wording — the descope commit changed that clause again, from "emits correctly itself" to "emits as correct LaTeX itself", restoring the phrasing an earlier audit asked for. The supersession line names a text that no longer stands; this line records the final wording. Also, for precision: the descope round did narrow one Scope promise — a trailing empty level inside a folded tail is now dropped rather than emitted as written — which is a promise change, not only a re-match to evidence.

## Decisions

- 2026-08-16: braces join `|` and `"` as characters that cannot be
  backslash-escaped inside `\index{}`. LaTeX reads that argument under
  `\@sanitize`, which gives `\` catcode 12, so `\{` escapes nothing and the
  brace stays a group character: `[open \{ only]{.index}` aborted the render
  with "Paragraph ended before `\@wrindex` was complete". They are emitted as
  `\textbraceleft{}`/`\textbraceright{}`. The general lesson, and why
  `examples/escaping.qmd` now exists: per-character review of an escape table
  cannot establish that a character survives, because the failure depends on
  how LaTeX *reads* the argument, not on the character alone. Only compiling
  each character settles whether it survives; only typesetting the resulting
  index settles whether it prints. `examples/escaping.qmd` does both, one
  character at a time, over printable ASCII — combinations remain untested.

- 2026-08-16: LaTeX escaping strategy — makeindex quoting is used only for
  `!` and `@`; `|` and `"` are emitted as `\textbar{}` and `\textquotedbl{}`.
  hyperref rewrites an index argument at its first `|` before makeindex runs
  and does not honour makeindex's `"` quoting, so `"|` silently corrupted the
  entry (observed in demo.idx: `{Alpha ... "@ "|hyperxindexformat{\ "! ""
  Omega}}`); and a makeindex-quoted `""` reaches LaTeX as a bare `"`, which
  typesets as a curly closing quote, not the straight quote the term holds.
  Both are IP2 escaping bugs, so both keep a probe in `examples/demo.qmd`.

## Review

Reviewed 2026-08-16 on `m01-latex-index-skeleton`, PR #1. Evidence is a fresh
`tests/run-tests.sh --self-test` run (exit 0) after deleting every render
artifact, plus the reader checks noted per criterion.

- AC1 — demo rendered to LaTeX via `examples/_extensions` (presence asserted
  before the render), exit 0; `.tex` matched the expected-entries manifest
  exactly: 19 rows, 21 `\index` commands, totals equal, no unexpected entry.
  Per this section's preamble, review re-derived the escaping-probe,
  sub-entry and `!!`-run rows independently of the script from the `.qmd` and
  the documented layer semantics; all matched, incl. `A!!!B` -> `A"!!B`,
  `A!!B!` -> `A"!B!`, and the 13-character `entry=` specials probe.
- AC2 — `\usepackage{imakeidx}` precedes `\makeindex[intoc]`, both before
  `\begin{document}`; exactly one `\printindex`, with no `\index{` or
  `\section{` after it and before `\end{document}`.
- AC3 — control rendered exit 0, non-empty `.tex`, none of `\index{`,
  `imakeidx`, `\makeindex`, `\printindex`; all 7 control-manifest tokens
  matched their exact counts.
- AC4 — forms list and probe characters declared in `tests/run-tests.sh` and
  printed by every run. Reader check against `examples/demo.qmd`: visible
  terms cover all 13 characters across five short probes, `entry=` levels
  cover all 13 in one probe; leading/medial/trailing all occupied; `!!`
  leading/medial/trailing; odd `!` run; empty level; one-backslash level;
  `\!` pin. README documents exactly the four span forms and no others,
  plus `\\`, `\"` and `!!` inside `entry=`.
- AC5 — PROFILE `verify` slot names `tests/run-tests.sh`; script sets
  `set -euo pipefail`; planted-defect self-test (one removed, one altered,
  one spurious) exits non-zero and names all three rows.
- AC6 — TinyTeX installed; PDF render exit 0; `pdftotext -layout` output has
  an `Index` heading and the text after it lists all 8 PDF-manifest terms
  with special characters literal and in order (`dollar $ at @ bar |`,
  `bang ! quote "`). Guard re-verified by stubbing `quarto list tools` to
  report TinyTeX absent: exits 1 naming the missing tool, never skips.
- AC7 — NOT VERIFIED (corrected after independent review). HTML render exit
  0; completeness pin holds (18 rows totalling 20 marks = 21 `]{.index`
  minus 1 `[]{.index`); no LaTeX tokens; no `entry=` leakage. But the
  per-row counts AC7 requires are not checked at all —
  `tests/run-tests.sh:394` tests presence only. Criterion unticked; see R3.

### Consistency gate

- `cairn_validate.py`: exit 0, all checks pass.
- Toolchain `consistency-gate` slot (profile `generic`): none — clean no-op.
- No `DESIGN.md` principle changed, so `cairn_impact.py` was not run.

### Independent review

Three fresh-context lenses (user-facing tier, executable surface). Findings
below are every candidate reported, with disposition. Defect return #1.

**Return-forcing (verified by this session, not taken on report):**
- R1 [O] `--to beamer` fails fatally with one mark: beamer has no `theindex`
  environment and `\printindex` lands inside the last frame. Reproduced —
  exit 1, "Environment theindex undefined"; identical file without the mark
  exits 0. Direct IP2 violation (a marked term must never break a render).
  `is_latex_derived()` opts beamer in at `index.lua:54`; no AC renders it.
- R2 [O] Entries deeper than three levels are silently discarded: makeindex
  caps at 3, rejects `A!B!C!D` ("0 entries accepted, 1 rejected") and still
  exits 0, so the build is clean and the entry vanishes. Reproduced. IP2
  "silently corrupts output". `Top!Middle!Leaf` sits exactly at the cap, so
  the suite cannot catch it. No filter warning, no README ceiling.
- R3 [O] AC7's per-row counts are never checked: `run-tests.sh:394` is a
  presence test (`t not in html`); each row's count is parsed, summed for the
  completeness pin, then discarded. AC7 requires "term x count, as in AC1".
  Criterion fails inside its own named procedure — the floor return.

**Fix-now (queued with the return, no separate status change):**
- R4 [S] `index.lua:17-20` still says `! @ | "` are makeindex-quoted; the AC6
  fix made that false for `|` and `"`. Verified.
- R5 [S] `run-tests.sh:13` oracle rule says "makeindex quoting of each literal
  level" — same superseded terminology. Verified.
- R6 [O] `index.lua:146-147` claims imakeidx builds the index in the same
  LaTeX run; it only does so under `-shell-escape`, which Quarto does not
  enable. README gets this right, so the source comment contradicts the docs.
- R7 [O] `<` and `>` are absent from `LATEX_LITERAL`; Pandoc's own writer
  escapes both. Latent under T1 fontenc, but README:66-69 claims flatly that
  no character needs user escaping.
- R8 [O] `quarto.doc.use_latex_package` at `index.lua:154-155` is unguarded
  while `warn()` guards `quarto.log`; plain pandoc errors on a nil global.
- R9 [O] No non-ASCII probe anywhere, though IP2 names non-ASCII explicitly
  and says the class earns a regression test forever. Code verified
  byte-safe; the missing probe is the gap.

**Follow-up candidates (ROADMAP rows, not M01):**
- R10 [O] `PROBE_CHARS`/`SUPPORTED_FORMS` are printed, never asserted against
  the demo — probe coverage can drift green.
- R11 [O] AC5's self-test asserts the helper returns non-zero, not that the
  script exits non-zero.
- R12 [O] Leading/medial empty levels ("Illegal null field") destroy the whole
  entry; the demo probes only the benign trailing case.
- R13 [O] `\printindex` may precede a bibliography, since later Quarto stages
  append blocks; AC2 verifies only the no-bibliography case.
- R14 [O] `index_args`'s brace scanner ignores `\{`/`\}`; benign today.
- R15 [O] The `>=1.4.0` floor is an untested contract claim (DESIGN calls the
  minimum version part of the contract).
- R16 [O] `marks_emitted` is module-level, latent under reused Lua state.
- R17 [O] `\index` in a moving argument (section heading) is unprobed.
- R18 [O] `examples/_extensions` is a symlink; a Windows checkout without
  symlink support breaks example resolution.
- R19 [O] Whitespace-only term emits `\index{ }` with no warning; empty-level
  warning fires only on the LaTeX branch.

**Rejected:**
- [O] README's four-form table listing `entry=` with and without `!` as
  separate rows — intentional, matches the normative list AC4 fences.
- [O] The vacuous `Specials ...` no-leak row and AC6's "in order" phrasing —
  real but pre-existing wording, no defect in the diff.
- [S] Work log citing IP4 — IP4 is the cairn rulebook's history-immutability
  principle, correctly cited; not a repo DESIGN principle.
- [S] `e416c6a` carried T2/T4 implementation under an amendment-titled commit
  with those tasks still unticked. Real process slip; history is append-only,
  so it is corrected by the catch-up work-log line below, not a rewrite.

