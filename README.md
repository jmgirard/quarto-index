# quarto-index

A Quarto extension for book-quality subject indexing. Mark index entries with
a format-neutral span syntax; the extension emits the right thing per output
format. LaTeX/PDF is the back-end that ships today.

> **Pre-release: install at your own risk.** Until the first tagged release
> the marking syntax is fluid and may change without a deprecation cycle.
> Breaking changes are recorded in the changelog. From the first tagged
> release onward, documented syntax forms change only via deprecation.

## Install

```bash
quarto add jmgirard/quarto-index
```

Then enable the filter in your document (or `_quarto.yml`):

```yaml
---
title: "My book"
filters:
  - index
---
```

Requires Quarto 1.4 or later. No other runtime dependencies: on the LaTeX
side it uses `imakeidx`, which ships with mainstream TeX distributions.

## Syntax

There are exactly four supported forms.

| Form | Writes | Index entry |
|---|---|---|
| `[term]{.index}` | `term` | `term` |
| `[term]{.index entry="Entry"}` | `term` | `Entry` |
| `[term]{.index entry="Top!Sub"}` | `term` | `Top` → `Sub` |
| `[]{.index entry="Entry"}` | nothing | `Entry` |

The visible text is always left exactly as written. The first form indexes a
term under its own text; the second indexes it under something else; the
third nests it under a parent heading; the fourth adds an entry with no
visible mark on the page.

### Sub-entry levels

Inside `entry=`, a single `!` separates sub-entry levels and `!!` is a
literal exclamation mark:

```markdown
[nested]{.index entry="Top!Middle!Leaf"}   → Top → Middle → Leaf
[wow]{.index entry="Wow!!Really"}          → one entry: Wow!Really
```

Levels are scanned left to right, longest match first, so `A!!!B` is the
entry `A!` with sub-entry `B`. An empty level is left as written and warned
about rather than silently repaired.

`!` and `!!` are the extension's own syntax, not LaTeX. They mean the same
thing whatever format you render to.

### Special characters

Everything in a visible term or an `entry=` level is literal text. You never
escape for LaTeX yourself — the extension does it, including for characters
that would otherwise break the build or act as index operators. All of
`% & # _ { } \ ~ ^ $ @ | ! "` work in both places.

Two characters need care in `entry="…"`, because Quarto's markdown parser
consumes one level of backslash escaping in a quoted attribute before the
extension ever sees the value:

| To get | Write |
|---|---|
| a literal `\` | `\\` |
| a literal `"` | `\"` |
| a literal `!` | `!!` |

Note that `\!` is **not** an escape. The parser turns it into a plain `!`,
which the extension then reads as a level separator — so `entry="A\!B"`
produces the entry `A` with sub-entry `B`, not `A!B`. Use `!!`.

`@`, `|` and `"` are ordinary literal characters here. Sort keys and locator
styling, which use those characters in raw `makeindex` syntax, are not part
of this syntax and will arrive later as separate span attributes.

## What it emits

For LaTeX-derived formats the extension writes `\index{…}` at the mark's
position. When a document has at least one mark, it also adds
`\usepackage{imakeidx}` and `\makeindex[intoc]` to the preamble and one
`\printindex` at the end of the document, so the index is built and listed
in the table of contents with no configuration. A document with no marks
gets none of this.

Placement is automatic; there is no option to put the index elsewhere yet.

In formats with no index back-end — HTML today — marks pass through: the
visible text is preserved and no LaTeX leaks into the output.

The extension's job ends at correct emitted output. Whether your toolchain
then runs `makeindex` to build the index is up to your build setup; Quarto's
default PDF pipeline does it for you.

## Examples

`examples/demo.qmd` exercises every supported form and the full escaping
probe set. `examples/control.qmd` is a negative control: mark-like text
inside code, which must never be indexed.

```bash
quarto render examples/demo.qmd --to pdf
```

## Tests

```bash
tests/run-tests.sh --self-test
```

The suite renders the examples to LaTeX, HTML and PDF and checks the output
against hand-derived manifests. It needs TinyTeX, `makeindex` and
`pdftotext`, and fails loudly rather than skipping if any is missing.
