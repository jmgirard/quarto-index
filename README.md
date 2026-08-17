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

There are exactly six supported forms.

| Form | Writes | Index entry |
|---|---|---|
| `[term]{.index}` | `term` | `term` |
| `[term]{.index entry="Entry"}` | `term` | `Entry` |
| `[term]{.index entry="Top!Sub"}` | `term` | `Top` → `Sub` |
| `[]{.index entry="Entry"}` | nothing | `Entry` |
| `[term]{.index see="Other"}` | `term` | `term`, *see* `Other` |
| `[term]{.index see-also="Other"}` | `term` | `term`, *see also* `Other` |

The visible text is always left exactly as written. The first form indexes a
term under its own text; the second indexes it under something else; the
third nests it under a parent heading; the fourth adds an entry with no
visible mark on the page. The last two point the reader at a different entry
instead of at a page.

### Sub-entry levels

Inside `entry=`, a single `!` separates sub-entry levels and `!!` is a
literal exclamation mark:

```markdown
[nested]{.index entry="Top!Middle!Leaf"}   → Top → Middle → Leaf
[wow]{.index entry="Wow!!Really"}          → one entry: Wow!Really
```

Levels are scanned left to right, longest match first, so `A!!!B` is the
entry `A!` with sub-entry `B`. A trailing empty level in an entry of three
levels or fewer is left as written and warned about rather than silently
repaired; see the ceiling below for what happens in a deeper one.

**Three levels is the ceiling.** The LaTeX index back-end stores at most
three. A deeper entry is not dropped: everything past the third level is
folded into it, joined with `, `, and you get a warning naming the entry. So
`entry="One!Two!Three!Four"` indexes as `One` → `Two` → `Three, Four`. An
empty level inside a folded tail is dropped, since it would otherwise leave a
dangling separator in the printed index.

`!` and `!!` are the extension's own syntax, not LaTeX. They mean the same
thing whatever format you render to.

### Cross-references

`see=` sends the reader somewhere else instead of listing a page; `see-also=`
points somewhere else as well. Both work on any of the mark forms above:

```markdown
[cats]{.index see="Felines"}                → cats, see Felines
[dogs]{.index see-also="Pets"}              → dogs, see also Pets
[owls]{.index see="Birds!Owls"}             → owls, see Birds: Owls
[]{.index entry="Ghosts" see-also="Spirits"}   → Ghosts, see also Spirits
```

The entry the cross-reference hangs off is `entry=` when the mark has one, and
the visible text otherwise, exactly as for an ordinary mark.

**A cross-reference replaces the locator.** A marked term carrying `see=` or
`see-also=` gets no page number for that mark. For `see=` that is what a
printed index does anyway, since "see Felines" means the entries are over
there.

For `see-also=` it is a current limitation, not the intent: a printed index
normally writes `cats, 12, 47, see also Felines`, and this extension cannot
produce that yet. Marking the term plainly elsewhere does **not** work around
it — a plain mark and a cross-reference on the same term can fail the build
outright, as the next paragraph explains. Until that is fixed, a `see-also=`
entry carries its cross-reference and no page numbers.

**The target uses the same level syntax as `entry=`.** A single `!` separates
levels and `!!` is a literal `!`, so `see="Birds!Owls"` points at the sub-entry
`Owls` under `Birds` and prints as `Birds: Owls`. Levels join with `: ` rather
than with `!`, because the target is a phrase a reader reads, not an index key.
Levels join with a colon, so a level that itself contains a colon reads the
same as a level boundary — `see="Note: on birds"` prints exactly like a
two-level target. The value is ordinary literal text in every other respect:
you never write LaTeX in it, and every printable ASCII character works, along
with accented Latin-1 text, including the ones that would otherwise break the
build.

**Both attributes on one mark** is almost always a mistake — "see" says the
entries are elsewhere, "see also" says there are entries here too. Nothing is
dropped: you get one entry carrying both targets, `see Aye; see also Bee`, and
a warning.

**One term marked two different ways can fail the build.** If `cats` gets a
plain mark in one place and a cross-reference in another — or a `see=` in one
place and a `see-also=` in another — and the two land on the same printed page,
`makeindex` rejects the pair and the PDF build fails. Marking a term twice
*the same* way is fine; the index tool folds those together. Page numbers do
not exist when the extension runs, so it cannot prevent the clash — it warns
instead, naming the key. Give the cross-reference its own entry, or move the
marks apart.

In formats with no index back-end, a cross-reference mark is simply a mark: the
visible text passes through and no target text appears anywhere in the output.

### Special characters

Everything in a visible term or an `entry=` level is literal text. You never
escape for LaTeX yourself — the extension does it, including for characters
that would otherwise break the build or act as index operators. Every
printable ASCII character works in both places, including an unbalanced brace.
`examples/escaping.qmd` puts each one in an index entry on its own, and
`examples/xref-escaping.qmd` puts each one in a cross-reference target — a
harder place, since a target travels through the index tool's encapsulation
channel, where an unquoted `!` is rejected outright and the whole render
fails. The test suite compiles both with the same engine your PDF build uses
and checks that the index tool accepted every entry. It additionally confirms
that the sixteen characters needing special handling — `% & # _ { } \ ~ ^ $ @
| ! " < >` — actually typeset, in an entry and in a cross-reference alike.

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

The same two rules apply inside `see=` and `see-also=`.

`@`, `|` and `"` are ordinary literal characters here. Sort keys and locator
styling, which use those characters in raw `makeindex` syntax, are not part
of this syntax and will arrive later as separate span attributes.

## What it emits

For LaTeX-derived formats the extension writes `\index{…}` at the mark's
position. When a document has at least one mark, it also adds
`\usepackage{imakeidx}` and `\makeindex[intoc]` to the preamble and one
`\printindex` after the document body, so the index is built and listed in
the table of contents with no configuration. In a document with a
bibliography the index currently prints before the references. A document
with no marks gets none of this.

A cross-reference is written into the same `\index{…}` command, through
`makeindex`'s encapsulation channel — `\index{cats|see{Felines}}`. A document
that puts both attributes on one mark also gets one small
`\providecommand` in its preamble, which prints the pair through LaTeX's own
`\seename` and `\alsoname`, so a document loading `babel` keeps its
translations. A document with no such mark gets nothing extra.

Placement is automatic; there is no option to put the index elsewhere yet.

In formats with no index back-end — HTML and beamer today — marks pass
through: the visible text is preserved and no LaTeX leaks into the output.
Beamer slides have no index environment, so they are deliberately not a
LaTeX index target; a marked term never breaks a slide deck.

The extension's job ends at correct emitted output. Whether your toolchain
then runs `makeindex` to build the index is up to your build setup; Quarto's
default PDF pipeline does it for you.

## Examples

`examples/demo.qmd` exercises every supported form and the full escaping
probe set. `examples/escaping.qmd` and `examples/xref-escaping.qmd` are the
character probes. `examples/control.qmd` is a negative control: mark-like text
inside code, which must never be indexed.

```bash
quarto render examples/demo.qmd --to pdf
```

## Tests

```bash
tests/run-tests.sh --self-test
```

The suite renders the examples to LaTeX, HTML, PDF and beamer and checks the
output against hand-derived manifests. It needs TinyTeX, `makeindex` and
`pdftotext`, and fails loudly rather than skipping if any is missing.
