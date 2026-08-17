# M01: LaTeX index extension skeleton

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, IP3, GP1, GP4, GP5, GP6
- **Branch/PR:** —

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
  `!`-separated sub-entry levels (a literal `!` inside a level is written
  `\!`); each level is literal text. The extension emits correct LaTeX
  itself — LaTeX specials escaped, makeindex-active characters (`@ | ! "`)
  quoted — for derived (visible-term) and explicit entries alike. No raw
  LaTeX pass-through.
- LaTeX-derived formats only: emit `\index{}` at the mark's position;
  when ≥1 mark exists, inject `\usepackage{imakeidx}` + `\makeindex` into
  the preamble and append one `\printindex` at document end (auto
  placement; no marks → no injection).
- HTML pass-through check (verification only): marks degrade gracefully in
  HTML — visible text preserved, no LaTeX artifacts (IP2); HTML *index
  generation* stays out.
- Demo + control example documents, test script, README, TinyTeX install
  for local PDF verification.

**Out:**
- HTML index generation (span text stays visible in HTML; index behavior
  there is undefined for now) → ROADMAP candidate.
- Sort keys and locator styling: `@ | "` are ordinary literal characters in
  entry values; future sort/styling features arrive as separate span
  attributes → ROADMAP candidates (sort-key syntax; page-range & styling).
- Multi-chapter book (cross-file) support → ROADMAP candidate.
- Release prep / first tagged release → ROADMAP candidate (window
  user-declared, D-050 discipline).
- Explicit index-placement option, shortcode syntax → future candidates if
  demanded; not in M01.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh` renders `examples/demo.qmd` to LaTeX via the
      installed extension with exit 0, and the emitted `.tex` matches the
      script's expected-entries manifest exactly: each manifest row (expected
      `\index{<entry>}` text × count) matches its count in the `.tex`, the
      total `\index` count equals the manifest total (extra or missing
      commands fail), and the manifest is non-empty. Manifest rows are
      derived by hand from the `.qmd` source and the documented escaping
      semantics — never copied from filter output — and the script header
      states this rule.
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
      `!` via `\!`), invisible-entry span, and an escaping probe set:
      visible terms and `entry=` levels together containing every character
      of `% & # _ { } \ ~ ^ $ @ | ! "`, with special characters in leading,
      medial, and trailing positions across the probes — each form with ≥1
      counted instance in `examples/demo.qmd` checked under AC1's manifest;
      the README syntax section documents exactly these forms, presenting
      `!`/`\!` as the extension's own format-neutral level syntax
      (reviewer-verified against the list).
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
      `!`-levels (`\!` escape), each level LaTeX-escaped and
      makeindex-quoted; empty span + `entry=` → invisible entry; `@ | "`
      literal; `\index` emission only for LaTeX-derived output formats,
      visible text passed through untouched elsewhere.
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
      `!`/`\!` level syntax as extension-own semantics, escaping and
      literal-`@ | "` behavior, auto-placement, and the pre-release
      at-your-own-risk sentence (IP3).

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

## Decisions

## Review
