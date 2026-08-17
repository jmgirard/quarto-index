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
- Span syntax only: `[term]{.index}` indexes the visible term;
  `[term]{.index entry="..."}` customizes the entry; `[]{.index entry="..."}`
  makes an invisible entry.
- Entry semantics (IP1, D-001): all entry values are structured,
  format-neutral data. `entry="..."` is parsed by the extension as
  `!`-separated sub-entry levels, scanned left-to-right longest-match:
  each `!!` yields a literal `!`, each remaining single `!` starts a new
  level; an empty level (leading, medial, trailing) is emitted as written
  and warned about, never repaired. Each level is literal text. The
  extension emits correct LaTeX itself — specials escaped, `@ | ! "` made
  literal (mechanism: the Decisions entry) — for derived and explicit
  entries alike. No raw LaTeX pass-through.
- LaTeX-derived formats only: emit `\index{}` at the mark's position;
  when ≥1 mark exists, inject `\usepackage{imakeidx}` + `\makeindex` into
  the preamble and append one `\printindex` at document end (auto
  placement; no marks → no injection).
- HTML pass-through check (verification only): marks degrade gracefully in
  HTML — visible text preserved, no LaTeX artifacts (IP2).
- Demo + control example documents, test script, README, TinyTeX install
  for local PDF verification.

**Out:** (each a ROADMAP candidate row): HTML index generation (span text
stays visible in HTML; index behavior there undefined for now); sort keys
and locator styling (`@ | "` stay ordinary literal characters, future
sort/styling arriving as separate span attributes); multi-chapter book
(cross-file) support; release prep / first tagged release (window
user-declared); explicit index-placement option and shortcode syntax.

## Acceptance criteria

`tests/run-tests.sh` is normative for M01: it declares the supported-forms
list, the escaping probe set, and four hand-derived manifests (demo entries,
control tokens, visible terms, PDF terms). Manifest rows are derived by hand
from the `.qmd` and the documented semantics at each layer — Pandoc attribute
unescaping, then the `!`/`!!` level parse, then LaTeX escaping and makeindex
quoting — never copied from filter output; the script header states this
rule, and review re-derives the escaping-probe, sub-entry and `!!`-run rows
independently of the script.

- [x] AC1: The script renders `examples/demo.qmd` to LaTeX via the installed
      extension with exit 0 and the `.tex` matches the expected-entries
      manifest exactly: each row's `\index{<entry>}` text matches its expected
      count, the total `\index` count equals the manifest total (extra or
      missing commands fail), and the manifest is non-empty.
- [x] AC2: The demo `.tex` contains `\usepackage{imakeidx}` (with or without
      options) followed later by `\makeindex`, both before `\begin{document}`,
      and exactly one `\printindex`, after all body content and before
      `\end{document}`.
- [x] AC3: `examples/control.qmd` — no marks, but mark-like text in a fenced
      code block and inline code — renders to LaTeX with exit 0 and a
      non-empty `.tex` with no `\index{`, `imakeidx`, `\makeindex`, or
      `\printindex`. Mark-like text survives as content: every control-manifest
      token — for each mark, an escape-free token containing that mark's own
      `entry=` value or visible text — matches its exact count, any mismatch
      failing; this manifest is the whole positive check.
- [x] AC4: The supported-forms list is normative — visible-term, custom-entry
      (single-level `entry=`), sub-entry (`!`-separated levels, literal `!` via
      `!!`), and invisible-entry spans — and the probe set puts visible terms
      and `entry=` levels *each independently* through every character of
      `% & # _ { } \ ~ ^ $ @ | ! "`, across leading, medial and trailing
      positions (union coverage, not the cross-product), plus `!!`
      leading/medial/trailing, one odd-length `!` run, one empty level, a
      level whose literal text is one backslash (typed `\\`), and one pinning
      that `\!` yields two levels. Each form has ≥1 counted instance in
      `examples/demo.qmd` under AC1's manifest; the README documents exactly
      those four span forms and no others, plus how a literal backslash and
      `"` are written inside `entry=` (reviewer-verified against the list).
- [x] AC5 (tracking hygiene): `cairn/PROFILE.md`'s `verify` slot names
      `tests/run-tests.sh`; the script fails loudly (`set -euo pipefail`) and
      passes a self-test: against a deliberately broken fixture (one
      manifest-expected `\index` command removed, one altered, one spurious
      `\index` added) it exits non-zero and names the mismatching row(s).
- [x] AC6: With TinyTeX installed (user-approved at the plan gate; requires
      network), `quarto render examples/demo.qmd --to pdf` exits 0 and
      `pdftotext -layout` output, whitespace-normalized, has an index heading,
      and the text following it lists every PDF-manifest term (the
      derived-from-visible-text, single-level, non-`entry=` terms), including
      the escaping probes with their special characters literally and in
      order. The script fails loudly if `tinytex`, `makeindex`, or `pdftotext`
      is missing, so this can never pass unrun. Explicit `entry=` entries are
      verified by AC1 instead.
- [x] AC7: `examples/demo.qmd` renders to HTML with exit 0. Each visible term
      appears as rendered text — markdown backslash-escapes consumed, then
      `&`, `<`, `>` as HTML entities — per the visible-terms manifest
      (term × count, as in AC1), pinned complete: the manifest's count total
      must equal `]{.index` occurrences minus `[]{.index` occurrences
      (occurrences, not matching lines) in the `.qmd`, or the run fails. The
      `.html` has none of `\index`, `imakeidx`, `\makeindex`, `\printindex`,
      and with tags stripped the body text contains no `entry=` value from the
      `.qmd` that is not also a substring of some visible term. Surviving span
      attributes are permitted; only rendered text is constrained.

## Coverage

- AC1 → T2, T4, T5 · AC2 → T3, T5 · AC3 → T2, T3, T4, T5
- AC4 → T4, T5, T6 · AC5 → T5 · AC6 → T3, T5 · AC7 → T2, T4, T5

## Tasks

- [x] T1: Scaffold `_extensions/index/` (`_extension.yml`, Lua filter
      registration); `examples/` consumes it via `_extensions/` as an
      installed user would; a bare render passes.
- [x] T2: Implement span recognition (`.index` class) and the entry semantics
      stated in Scope: derived and `entry=` levels LaTeX-escaped with
      makeindex-active characters made literal, invisible entries, and
      warn-and-continue on an empty level or a mark with nothing to index
      (never fail the render, IP2); `\index` emission only for
      LaTeX-derived formats, visible text passed through elsewhere.
- [x] T3: Conditional injection: with ≥1 mark, `\usepackage{imakeidx}` +
      `\makeindex` via header-includes and one `\printindex` appended at
      document end; with none, no injection at all.
- [x] T4: Author `examples/demo.qmd` (every supported form incl. sub-entry
      span, the escaping probe set with full character and position
      coverage, and one term marked multiple times) and
      `examples/control.qmd` (mark-like text in fenced and inline code).
- [x] T5: Install TinyTeX (`quarto install tinytex`); write
      `tests/run-tests.sh` with the hand-authored expected-entries manifest
      (rule stated in header) implementing AC1–AC4, AC6, and AC7 checks,
      the tool-presence guard, and the broken-fixture self-test naming
      mismatching rows; fill the PROFILE `verify` slot.
- [x] T6: README: install (`quarto add`), the normative syntax forms incl.
      `!`/`!!` level syntax as extension-own semantics, how a literal
      backslash and `"` are written inside `entry=` (Pandoc eats one
      backslash level; `\!` is not an escape), escaping and literal-`@ | "`
      behavior, auto-placement, and the pre-release at-your-own-risk
      sentence (IP3).

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

## Decisions

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
- AC7 — HTML render exit 0; 18 visible-term rows totalling 20 marks, equal
  to `]{.index` occurrences (21) minus `[]{.index` (1); none of `\index`,
  `imakeidx`, `\makeindex`, `\printindex`; no `entry=` value in
  tag-stripped body text.

### Consistency gate

- `cairn_validate.py`: exit 0, all checks pass.
- Toolchain `consistency-gate` slot (profile `generic`): none — clean no-op.
- No `DESIGN.md` principle changed, so `cairn_impact.py` was not run.

### Independent review

