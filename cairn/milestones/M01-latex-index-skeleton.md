# M01: LaTeX index extension skeleton

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, IP3, GP1, GP4, GP5, GP6
- **Branch/PR:** `m01-latex-index-skeleton`

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
  extension emits correct LaTeX itself — LaTeX specials escaped,
  makeindex-active characters (`@ | ! "`) quoted — for derived
  (visible-term) and explicit entries alike. No raw LaTeX pass-through.
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

- [ ] AC1: `tests/run-tests.sh` renders `examples/demo.qmd` to LaTeX via the
      installed extension with exit 0, and the emitted `.tex` matches the
      script's expected-entries manifest exactly: each manifest row (expected
      `\index{<entry>}` text × count) matches its count in the `.tex`, the
      total `\index` count equals the manifest total (extra or missing
      commands fail), and the manifest is non-empty. Manifest rows are
      derived by hand from the `.qmd` source and the documented semantics at
      each layer — Pandoc attribute-value unescaping, then the extension's
      `!`/`!!` level parse, then LaTeX escaping and makeindex quoting —
      never copied from filter output, and the script header states this
      rule.
- [ ] AC2: The demo `.tex` contains `\usepackage{imakeidx}` (with or without
      options) followed later by `\makeindex`, both before
      `\begin{document}`, and exactly one `\printindex`, after all body
      content and before `\end{document}`.
- [ ] AC3: `examples/control.qmd` — no index marks, but mark-like text inside
      a fenced code block and inline code — renders to LaTeX with exit 0 and
      a non-empty `.tex` containing that mark-like text verbatim and no
      `\index{`, no `imakeidx`, no `\makeindex`, no `\printindex`.
- [ ] AC4: The supported-forms list declared in `tests/run-tests.sh` is
      normative for M01 — visible-term span, custom-entry span (single-level
      `entry=`), sub-entry span (`entry=` with `!`-separated levels; literal
      `!` via `!!`), invisible-entry span, and an escaping probe set:
      visible terms and `entry=` levels *each independently* containing
      every character of `% & # _ { } \ ~ ^ $ @ | ! "`, with special
      characters in leading, medial, and trailing positions across the
      probes (union coverage; the character × position cross-product is not
      required). The `entry=` probes also cover `!!` leading, medial, and
      trailing; one odd-length `!` run; a level whose literal text is one
      backslash (typed `\\`); and one pinning that `\!` yields two levels,
      not a literal `!`. Each form has ≥1 counted instance in
      `examples/demo.qmd` checked under AC1's manifest; the README syntax
      section documents exactly the four span forms above and no others, and
      how a literal backslash and `"` are written inside `entry=` given
      Pandoc's attribute parsing (reviewer-verified against the list).
- [ ] AC5 (tracking hygiene): `cairn/PROFILE.md`'s `verify` slot names
      `tests/run-tests.sh`; the script fails loudly (`set -euo pipefail`)
      and passes a self-test: run against a deliberately broken fixture (one
      manifest-expected `\index` command removed, one altered) it exits
      non-zero and its output names the mismatching manifest row(s).
- [ ] AC6: With TinyTeX installed (user-approved at the plan gate; requires
      network), `quarto render examples/demo.qmd --to pdf` exits 0 and
      `pdftotext -layout` output, whitespace-normalized, contains an index
      section listing every derived-from-visible-text manifest term
      (single-level, non-`entry=`), including the escaping-probe term(s)
      with their special characters present literally and in order.
      `tests/run-tests.sh` fails loudly if `tinytex`, `makeindex`, or
      `pdftotext` is missing, so this criterion can never pass unrun.
      (Explicit `entry=` entries, single-level and sub-entry, are verified
      at the `.tex` level by AC1, not here.)
- [ ] AC7: `examples/demo.qmd` renders to HTML with exit 0; the output
      contains every visible term's text and none of `\index`, `imakeidx`,
      `\makeindex`, `\printindex` (IP2 pass-through in a back-end-less
      format).

## Coverage

- AC1 → T2, T4, T5
- AC2 → T3, T5
- AC3 → T2, T3, T4, T5
- AC4 → T4, T5, T6
- AC5 → T5
- AC6 → T3, T5
- AC7 → T2, T4, T5

## Tasks

- [ ] T1: Scaffold `_extensions/index/` (`_extension.yml`, Lua filter
      registration); `examples/` consumes it via `_extensions/` as an
      installed user would; a bare render passes.
- [ ] T2: Implement span recognition (`.index` class) and entry semantics:
      visible term → escaped entry beside the term; `entry=` parsed into
      `!`-levels (`!!` → literal `!`, longest-match left-to-right), each
      level LaTeX-escaped and makeindex-quoted; empty span + `entry=` →
      invisible entry; a mark with nothing to index, and an empty level,
      warn and continue (never fail the render, IP2); `@ | "` literal;
      `\index` emission only for LaTeX-derived output formats, visible text
      passed through untouched elsewhere.
- [ ] T3: Conditional injection: with ≥1 mark, `\usepackage{imakeidx}` +
      `\makeindex` via header-includes and one `\printindex` appended at
      document end; with none, no injection at all.
- [ ] T4: Author `examples/demo.qmd` (every supported form incl. sub-entry
      span, the escaping probe set with full character and position
      coverage, and one term marked multiple times) and
      `examples/control.qmd` (mark-like text in fenced and inline code).
- [ ] T5: Install TinyTeX (`quarto install tinytex`); write
      `tests/run-tests.sh` with the hand-authored expected-entries manifest
      (rule stated in header) implementing AC1–AC4, AC6, and AC7 checks,
      the tool-presence guard, and the broken-fixture self-test naming
      mismatching rows; fill the PROFILE `verify` slot.
- [ ] T6: README: install (`quarto add`), the normative syntax forms incl.
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
- 2026-08-16: substantive amendment (`!!` escape): Scope entry-semantics bullet, AC1 manifest-derivation clause, AC4, T2, T6 amended; amended AC-wording audited in full mode by a fresh [O] reader that did not author it — 10 findings, 8 applied as clear fixes, finding 5 resolved by probe (`"` is expressible), findings 9-history and 10 disposed per append-only and documented-claim-owes-a-test.

## Decisions

## Review
