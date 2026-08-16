# M01: LaTeX index extension skeleton

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
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
- Escaping design: entries derived from visible text are LaTeX-escaped
  (`% & # _ { } \` etc.); an explicit `entry="..."` is raw LaTeX
  pass-through (documented — this is how sub-entries like `animals!cats`
  work).
- LaTeX-derived formats only: emit `\index{}` at the mark's position;
  when ≥1 mark exists, inject `\usepackage{imakeidx}` + `\makeindex` into
  the preamble and append one `\printindex` at document end (auto
  placement; no marks → no injection).
- Demo + control example documents, test script, README, TinyTeX install
  for local PDF verification.

**Out:**
- HTML index generation (span text stays visible in HTML; index behavior
  there is undefined for now) → ROADMAP candidate.
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
      commands fail), and the manifest is non-empty.
- [ ] AC2: The demo `.tex` contains `\usepackage{imakeidx}` and `\makeindex`
      before `\begin{document}`, and exactly one `\printindex`, at document
      end.
- [ ] AC3: `examples/control.qmd` — no index marks, but mark-like text inside
      a fenced code block and inline code — renders to LaTeX with exit 0 and
      a non-empty `.tex` containing no `\index{`, no `imakeidx`, no
      `\makeindex`, no `\printindex`.
- [ ] AC4: The supported-forms list declared in `tests/run-tests.sh` is
      normative for M01 — visible-term span, custom-entry span,
      invisible-entry span, and an escaping probe (visible term containing
      LaTeX special characters, emitted escaped) — each with ≥1 counted
      instance in `examples/demo.qmd` checked under AC1's manifest; the
      README syntax section documents exactly these forms
      (reviewer-verified against the list).
- [ ] AC5 (tracking hygiene): `cairn/PROFILE.md`'s `verify` slot names
      `tests/run-tests.sh`; the script fails loudly (`set -euo pipefail`)
      and passes a self-test: run against a deliberately broken fixture it
      exits non-zero.
- [ ] AC6: With TinyTeX installed (user-approved at the plan gate; requires
      network and a `makeindex` binary in the TinyTeX tree),
      `quarto render examples/demo.qmd --to pdf` exits 0 and
      `pdftotext -layout` output, whitespace-normalized, contains an index
      section listing every flat visible term in the script's manifest (raw
      `entry=` entries are verified at the `.tex` level by AC1, not here).

## Coverage

- AC1 → T2, T4, T5
- AC2 → T3, T5
- AC3 → T2, T3, T4, T5
- AC4 → T4, T5, T6
- AC5 → T5
- AC6 → T3, T5

## Tasks

- [ ] T1: Scaffold `_extensions/index/` (`_extension.yml`, Lua filter
      registration); `examples/` consumes it via `_extensions/` as an
      installed user would; a bare render passes.
- [ ] T2: Implement span recognition (`.index` class): visible term →
      escaped `\index{term}` beside the term; `entry=` → raw pass-through;
      empty span + `entry=` → invisible entry; active only for
      LaTeX-derived output formats.
- [ ] T3: Conditional injection: with ≥1 mark, `\usepackage{imakeidx}` +
      `\makeindex` via header-includes and one `\printindex` appended at
      document end; with none, no injection at all.
- [ ] T4: Author `examples/demo.qmd` (every supported form, the escaping
      probe, and one term marked multiple times) and `examples/control.qmd`
      (mark-like text in fenced and inline code).
- [ ] T5: Install TinyTeX (`quarto install tinytex`); write
      `tests/run-tests.sh` with the expected-entries manifest implementing
      AC1–AC4 and AC6 checks plus the broken-fixture self-test; fill the
      PROFILE `verify` slot.
- [ ] T6: README: install (`quarto add`), the normative syntax forms,
      escaping/raw-entry semantics, auto-placement behavior.

## Work log

- 2026-08-16: created by /milestone-plan.
- 2026-08-16: criteria audit ran in full mode (fresh [O] reader, user-facing tier): ~15 findings + 3 gaps; clear-fix findings applied to the AC wording (manifest with count equality, \makeindex token, control-doc render guards, negative-control code probes, escaping probe, installability via _extensions/, script self-test, AC6 layout/preconditions/disposition); judgment calls disposed at the plan gate.
- 2026-08-16: plan gate chose span-only syntax over shortcode (and both) because one pandoc-native mechanism covers visible/custom/invisible entries with half the API surface; falsified by user demand for a form spans cannot express.
- 2026-08-16: plan gate chose TinyTeX install over .tex-only verification because end-to-end PDF proof covers the compile+makeindex path that .tex inspection cannot; falsified by TinyTeX proving unusable in this environment (install or network failure).
- 2026-08-16: plan gate chose auto \printindex at document end over an explicit placement marker because zero-config covers the common case and a placement option can be added compatibly later; falsified by demand for mid-document placement no compatible option can serve.
- 2026-08-16: plan (autonomous) chose escaped derived-entries + raw entry= pass-through over uniform raw pass-through because visible-text terms containing LaTeX specials must not break builds while power users keep full \index syntax; falsified by an escaping bug class the probe term fails to catch.

## Decisions

## Review
