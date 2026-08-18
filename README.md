# quarto-index

A Quarto extension for book-quality subject indexing. Mark index entries with
a format-neutral span syntax; the extension emits the right thing per output
format. Two back-ends ship: LaTeX/PDF and HTML.

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

A sort key written for a level past the third goes with that level in this
back-end: the level is folded away here, so its key has nothing left to place.
The folded level files under the third level's own sort key where you wrote
one, and under its printed text where you did not. The HTML index has no
ceiling, so it keeps both the level and the key written for it.

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

In an HTML index the target is a link when it names an entry that exists in the
same index, and plain text when it does not. Whether it does is decided on the
levels, not on the text a reader sees: `see="Note!on birds"` points at the
sub-entry `on birds` under `Note`, while `see="Note: on birds"` is one level
that merely prints the same way, and does not link.

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

The same two rules apply inside `see=` and `see-also=`, and inside `sort=`.

`@`, `|` and `"` are ordinary literal characters here. Locator styling, which
uses some of them in raw `makeindex` syntax, is not part of this syntax and
will arrive later as a separate span attribute.

### Sorting an entry under something else

Some terms do not file where their spelling puts them. `The Hague` belongs
under H, `von Neumann` under N, `10 Downing Street` where a reader would say
it. Write a sort key and the entry prints one way and files another:

```markdown
[The Hague]{.index sort="Hague"}
```

A sort key is ordinary text, not index-tool syntax — the extension writes
whatever its back-end needs. It uses the same level syntax `entry=` does, and
lines up with it position by position: the first sort level places the first
entry level, the second places the second, and so on.

```markdown
[]{.index entry="mathematicians!von Neumann" sort="!Neumann"}
```

A sort level left empty means "file this level under its own printed text", so
you only write the levels you are actually moving. Above, `mathematicians`
files under itself and only the sub-entry is redirected.

Two skipped levels cannot sit side by side, because `!!` is a literal `!` and
not two separators — `sort="!!Zed"` is a one-level key reading `!Zed`. Where
you would need to skip two in a row, write those levels' own printed text
instead: `sort="One!Two!Zed"` rather than `sort="!!Zed"`.

Restating a level's own text on the way to a deeper one declares nothing for
that level — it is how you reach past it — so a key another mark writes for
that level still applies. Written as the last level of a sort key it is an
ordinary declaration: the level files under its own text, and a different key
written elsewhere is reported rather than quietly preferred.

A sort key belongs to the entry, not to the mark you happened to write it on.
Mark a term in six places and give one of them a `sort=`, and all six file
under it — you never have to repeat it.

More exactly, it belongs to the entry level you wrote it for, and places that
level wherever it appears. A key written for `Hague, The` files it the same
way whether the mark carries that term alone or as the parent of a sub-entry,
so one term never files two ways.

Three things are reported, in every output format, because each is a mistake
about the mark rather than about any one back-end:

- a `sort=` on a mark that indexes nothing, which has nothing to sort;
- a `sort=` with more levels than its entry has, whose extra levels are
  ignored;
- one entry given two different sort keys, which cannot file in two places —
  the first one in the document wins, and in a book the first in book order.

A book adds a fourth report, for a term two chapters sort differently. No
single document can see that clash, since each chapter renders on its own, so
it is reported where the book's index is built.

Sorting is otherwise best-effort: neither back-end collates accented or
non-Latin text the way a language would, and a sort key is how you fix an
entry that files wrongly.

A sort key files an entry under the ordering of whichever back-end builds the
index, and the two orderings need not agree. In HTML the ordering is the
extension's own — ASCII case folded, then character code. In PDF it is
`makeindex`'s, which groups punctuation ahead of letters and reads the key in
the escaped form the back-end writes for it. Sort keys of plain letters and
digits order the same way in both back-ends; one built out of punctuation may
not, and neither will a key written past the three-level ceiling, which HTML
honors and LaTeX drops with the level it was written for.

### Placing the index

By default the index goes at the end of the document. To put it somewhere
else, write an empty div where you want it:

```markdown
::: {.qi-index-here}
:::
```

Both back-ends honour the same marker: the HTML index section and the LaTeX
`\printindex` each land where you wrote it. A format with no index back-end
drops the marker and leaves nothing in its place.

Four rules, each of which warns rather than breaking your build:

- **Top level only.** A marker inside a callout, a list or another div places
  nothing: a printed index inside a LaTeX group or environment is a render
  risk. It is dropped, and the index keeps its default place at the end.
- **The first marker wins.** A second one is reported by its position and
  dropped.
- **The marker is empty.** Write anything inside it and your content stays
  where the marker was, with a warning. Nothing you wrote is deleted.
- **A marker in a document with no index marks** places nothing, and says so.

A document carrying a marker loads `imakeidx` with its `noautomatic` option.
Printing an index in the middle of a document otherwise closes the file the
entries are collected in, and every term marked after the marker vanishes from
the index with no error. The option changes nothing else: building the index
is Quarto's PDF loop's job either way.

## What it emits

### LaTeX and PDF

For LaTeX-derived formats the extension writes `\index{…}` at the mark's
position. When a document has at least one mark, it also adds
`\usepackage{imakeidx}` and `\makeindex[intoc]` to the preamble and one
`\printindex` after the document body — or at your placement marker, if the
document has one — so the index is built and listed in the table of contents
with no configuration. In a document with a bibliography the index currently
prints before the references. A document with no marks gets none of this.

A cross-reference is written into the same `\index{…}` command, through
`makeindex`'s encapsulation channel — `\index{cats|see{Felines}}`. A document
that puts both attributes on one mark also gets one small
`\providecommand` in its preamble, which prints the pair through LaTeX's own
`\seename` and `\alsoname`, so a document loading `babel` keeps its
translations. A document with no such mark gets nothing extra.

Placement is automatic unless you write a marker; see [Placing the
index](#placing-the-index).

### HTML

For HTML the extension adds an index of its own at the end of the body, or at
your placement marker if the document has one: an
unnumbered level-one **Index** heading, in a section carrying the id
`qi-index`, listed in the table of contents, followed by a nested bullet list
of the entries. It is built out of Pandoc's own document nodes rather than out
of HTML text, so Pandoc's writer does the escaping. No stylesheet is added; the
class names below are hooks for styling it yourself.

Each mark that contributes a locator needs somewhere for its locator to link
to:

- a mark carrying an id of your own keeps it, and the index links to that id;
- every other mark gets an anchor on its own span — `qi-mark-1`, `qi-mark-2`
  and so on, numbered in the order the marks are written.

A heading is the one place an anchor cannot sit, because Quarto copies a
heading's contents into the sidebar table of contents, and an id in there
would end up in the page twice. So a heading mark's anchor — your own id or a
minted one — is placed on an invisible element just after the heading, and
the locator lands at the start of that section. Such a mark is numbered where
its anchor lands; a mark inside a footnote written in that same heading keeps
its anchor with the footnote's text and numbers ahead of it.

Each entry carries an id too, `qi-entry-1` onward, so that a cross-reference
can link to it. Both kinds of generated id skip any name written in the
document itself — on its elements, or inside raw HTML in its source — so
writing `qi-mark-1` yourself is safe: the numbering steps over it and your
element keeps the name. That leaves gaps in the sequence, which is harmless —
the numbers are link targets, not a count of anything. Two names sit outside
that promise: an id injected around the document at render time
(`include-in-header` and its relatives are never seen by the filter), and the
section id `qi-index` itself, which is fixed rather than minted.

An entry's locators are numbered links to those anchors: `1`, `2`, `3` for the
first, second and third time the term is marked, restarting at `1` for each
entry. So `pandoc, 1, 2, 3` in an HTML index means what three page numbers mean
in a printed one. The pieces carry these classes:

| Class | On |
|---|---|
| `qi-term` | the entry's own text |
| `qi-locators` | the run of numbered links |
| `qi-xref`, with `qi-see` or `qi-see-also` | one cross-reference |
| `qi-target` | the target text inside a cross-reference |

A document with no marks gets no index section and no anchors.

### Other formats

In beamer, and in any other format with no index back-end, marks pass through:
the visible text is preserved exactly as written, no index is generated, and
no LaTeX or index markup is emitted. The mark itself is still a span, so in a
format that can carry span attributes — GitHub-flavoured markdown does,
through inline HTML — its class and attribute values travel with it, just as
any other span's would. Beamer slides
have no index environment of their own, so a `\printindex` there would abort
the render — and a marked term must never break a document, so beamer is
deliberately not an index target rather than a broken one.

Warnings about the mark itself — an empty sub-entry level, a cross-reference
with no usable target, a mark with nothing to index — are about what you wrote
rather than about any one back-end, so you get them whatever you render to.

### Where the two back-ends differ

The marking syntax means the same thing in both. What the two indexes can do
differs, because the tools underneath them do:

1. **No level ceiling in HTML.** Sub-entries nest as deep as you write them.
   The three-level ceiling described above is `makeindex`'s limit, not the
   extension's.
2. **The clash warning is LaTeX-only.** One term marked two different ways can
   fail a PDF build, so the extension warns about it. An HTML index prints the
   locator and the cross-reference together on one entry, with nothing to
   clash, so the warning would name a problem that format does not have.
3. **Sorting is the extension's own in HTML.** Entries sort by folding ASCII
   uppercase to lowercase, then by character code, with a tie broken by
   character code, applied to an entry's sort key where it has one. In LaTeX
   the order is `makeindex`'s. Neither collates accented or non-Latin text the
   way a language would, which is what sort keys are for.
4. **Locators are numbered links in HTML**, in the order the marks are
   written, where LaTeX gives page numbers.
5. **Cross-reference targets are hyperlinked in HTML** when the target names an
   entry in the same index, and are plain text otherwise. A printed index
   cannot link at all.
6. **A cross-reference carries no locator in either back-end.** The `see also`
   limitation described above is the same in both.

The extension's job ends at correct emitted output. Whether your toolchain
then runs `makeindex` to build the index is up to your build setup; Quarto's
default PDF pipeline does it for you.

## Books

A Quarto book gets one index for the whole book, not one per chapter. Write
the placement marker in the chapter that should hold it:

```markdown
::: {.qi-index-here}
:::
```

**Put that chapter last.** Quarto renders a book's chapters in order, and each
chapter is a separate render that cannot see the others, so the index is built
from the chapters that ran before the one holding the marker. Put the marker
anywhere else and the chapters after it are represented by whatever the
*previous* render recorded: on a first render they are missing, and after an
edit their entries can name terms the chapter no longer marks and link to
anchors its page no longer has. The extension names those chapters every time
it builds the index, so this is loud rather than silent — but the fix is to
move the marker, not to render twice.

In the HTML book, each entry's locators link to the chapters that mark the
term, in book order — across files, and across subdirectories, from wherever
the index chapter sits. A cross-reference links to its target entry whenever
some chapter in the book contributes it, so `see=` works across chapters
exactly as it does inside one document. The PDF book needs none of this: it is
rendered as one merged document, so `makeindex` has always had every chapter's
marks at once, and the printed index gathers page numbers from all of them.

Two things worth knowing:

- **Render the whole book when you publish.** Rendering a single chapter
  updates that chapter's marks only; the index is rebuilt from what the last
  full render recorded for the others. `quarto render` with no file argument
  is what makes the index current.
- **A book with marks but no marker chapter gets no index**, and says so once
  per render, naming the marker to add. The extension will not choose a
  chapter for you.

Each chapter records its marks in `.quarto/quarto-index/` inside your project —
Quarto's own scratch directory, alongside the caches Quarto keeps there, and
never copied into `_book/`. There is nothing to configure. A project created
with `quarto create project` already ignores `/.quarto/` in git; a book whose
`_quarto.yml` you wrote by hand may not, and that one line is worth adding.

If a chapter's record cannot be written or read back — a read-only project
tree, a stale file where the directory belongs, a record left by an older
version of this extension — the book still renders, and the extension names
the chapter whose terms are missing from the index. Rendering that chapter
again is the fix.

## Examples

`examples/book/` is a four-chapter book fixture — a shared term marked in
three chapters, a chapter in a subdirectory, a cross-chapter cross-reference,
and the marker in the last chapter — and `examples/book-nomarker/` is the same
idea with no marker at all.
`examples/demo.qmd` exercises every supported form and the full escaping
probe set. `examples/escaping.qmd` and `examples/xref-escaping.qmd` are the
character probes. `examples/placement.qmd` marks one term in a heading, a table
cell and a footnote, where the renderer moves the mark away from where it was
written. `examples/marker.qmd` puts the index between two sections with a
placement marker; `examples/marker-misuse.qmd` and
`examples/marker-nomarks.qmd` are its misuse cases. `examples/control.qmd` is
a negative control: mark-like text inside code, which must never be indexed.

```bash
quarto render examples/demo.qmd --to pdf
quarto render examples/demo.qmd --to html
```

## Tests

```bash
tests/run-tests.sh --self-test
```

The suite renders the examples to LaTeX, HTML, PDF, beamer and
GitHub-flavoured markdown, and checks the output against hand-derived
manifests. It needs TinyTeX, `makeindex` and `pdftotext`, and fails loudly
rather than skipping if any is missing.
