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

There are exactly nine supported forms.

| Form | Writes | Index entry |
|---|---|---|
| `[term]{.index}` | `term` | `term` |
| `[term]{.index entry="Entry"}` | `term` | `Entry` |
| `[term]{.index entry="Top!Sub"}` | `term` | `Top` → `Sub` |
| `[]{.index entry="Entry"}` | nothing | `Entry` |
| `[term]{.index see="Other"}` | `term` | `term`, *see* `Other` |
| `[term]{.index see-also="Other"}` | `term` | `term`, *see also* `Other` |
| `[term]{.index mention="principal"}` | `term` | `term`, its locator emphasized |
| `[term]{.index range="open"}` | `term` | `term`, one locator spanning to its closing mark |
| `[term]{.index range="close"}` | `term` | nothing of its own; it closes the range |

The visible text is always left exactly as written. The first form indexes a
term under its own text; the second indexes it under something else; the
third nests it under a parent heading; the fourth adds an entry with no
visible mark on the page. The next two point the reader at a different entry
instead of at a page. The seventh says which of a term's mentions is its
principal one. The last two mark where a discussion begins and where it ends,
so the index prints one locator spanning them rather than a locator at each.

### Sub-entry levels

Inside `entry=`, a single `!` separates sub-entry levels and `!!` is a
literal exclamation mark:

```markdown
[nested]{.index entry="Top!Middle!Leaf"}   → Top → Middle → Leaf
[wow]{.index entry="Wow!!Really"}          → one entry: Wow!Really
```

Levels are scanned left to right, longest match first, so `A!!!B` is the
entry `A!` with sub-entry `B`.

**An empty level is dropped.** A `!` at either end of the value asks for a
level that prints no text at all. You get one warning per mark, naming the
entry and which positions in the value were empty — `entry="!Sub!"` reports
positions 1 and 3 of 3, and says that 1 of the 3 written levels remains. Those
positions count the levels you wrote, not the `!` characters between them:
`!!` is a literal `!` and not two separators, so `entry="A!!B!"` is two levels
and reports position 2 of 2. A value that is *only* `!` has no level left at
all and gets a different warning, below. The empty levels are dropped and the entry indexes
at the levels that remain, so `entry="!Cats"` and `entry="Cats!"` both index
as `Cats`. This is the same in every format, and it is not tidiness: the
LaTeX index tool rejects an entry outright for a leading or middle null field,
drops it from the index, and still reports no warning and exits 0, so the
entry would vanish from a build that looked clean.

Two empty levels can never sit side by side, because `!!` is a literal `!` and
not two separators, so a level between two others is not something you can
write.

A value that is *only* empty levels leaves nothing to index. The mark falls
back to its own visible text where it has some — `[Cats]{.index entry="!"}`
indexes as `Cats` — and indexes nothing where it has none. Either way you get
a warning naming the value you wrote.

A sort level goes with the entry level it was written for. If that level is
dropped, its key is dropped with it, so `entry="!Cats" sort="zzz!cats"` files
`Cats` under `cats` and never under `zzz`; you get a warning saying how many
keys went. Where every level is dropped, every key goes with them — a mark
falling back to its visible text files under that text, never under a key
written for a level that is gone. Dropping empty levels changes nothing for an
entry that has none: restating a level's own text on the way to a deeper level
still declares nothing for it. See the ceiling below for what happens in an
entry deeper than three levels.

**Three levels is the ceiling.** The LaTeX index back-end stores at most
three. A deeper entry is not dropped: everything past the third level is
folded into it, joined with `, `, and you get a warning naming the entry. So
`entry="One!Two!Three!Four"` indexes as `One` → `Two` → `Three, Four`. Depth
is counted after empty levels have gone, so a stray `!` cannot push an entry
over the ceiling on its own: `entry="One!Two!Three!"` is three levels and
folds nothing. The warning names that depth, and names the depth you wrote
alongside it where a dropped level makes the two differ, so both numbers are
ones you can find in the value you typed.

A sort key written for a level past the third goes with that level in this
back-end: the level is folded away here, so its key has nothing left to place.
The folded level files under the third level's own sort key where you wrote
one, and under its printed text where you did not. The HTML index has no
ceiling, so it keeps both the level and the key written for it.

**A cross-reference target meets the same ceiling.** In the LaTeX back-end a
target is folded exactly as an entry is, and you get a warning naming the mark,
the depth the target is at, the depth you wrote it at where a dropped level
makes the two differ, and the path the target now points at. With
`entry="One!Two!Three!Four"` marked somewhere, `see="One!Two!Three!Four"`
prints as `see One: Two: Three, Four` —
the path that entry prints — rather than sending a reader to a four-level path
the printed index does not contain. The HTML index has no ceiling, so there the
target keeps every level you wrote.

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
produce that yet. Marking the term plainly elsewhere gets you the page numbers
and the cross-reference on one entry, but in this extension's order — `cats,
see also Felines, 12, 47` — not the printed convention above. On its own, a
`see-also=` entry carries its cross-reference and no page numbers.

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

**A cross-reference to its own entry is dropped.** `see="Cats"` on the entry
`Cats` prints as "Cats, see Cats" and, in an HTML index, links the entry to
itself. The target is reported and dropped, and the term is then indexed
normally, with its usual page numbers or links — dropping the mark instead
would lose the term. A target is judged against what the entry *prints*, so a
sort key does not make a self-reference into something else.

**Both attributes on one mark** is almost always a mistake — "see" says the
entries are elsewhere, "see also" says there are entries here too. Neither is
dropped for being one of two: you get one entry carrying both targets, `see
Aye; see also Bee`, and a warning. A target that names its own entry is still
dropped for that reason, and the other one is then the only one emitted.

**One term marked two different ways prints as one entry.** If `cats` gets a
plain mark in one place and a cross-reference in another, you get a single
entry carrying its page numbers and its cross-reference together: `cats, see
Felines, 3, 7`. The cross-reference mark contributes no page number of its own,
exactly as it does not when it stands alone.

Two *different* cross-references on one term — a `see=` in one place and a
`see-also=` in another — merge the same way, but into one entry carrying both
targets and no page numbers at all, since neither mark contributes one: `cats,
see Felines; see also Dogs`. Either way you get a warning naming the entry and
saying which of the two it drew, because two marks describing one term
differently is more often a slip than a plan.

This used to fail the PDF build outright, and in a document that had never
been built to PDF it could sit unnoticed for a long time: `makeindex` rejects
two marks that share an index key and a printed page but describe it
differently, and Quarto turns that rejection into a failed render. The
extension no longer emits such a pair. Marking a term twice *the same* way was
always fine, and still is.

In an HTML index the target is a link when it names an entry that exists in the
same index, and plain text when it does not. Whether it does is decided on the
levels, not on the text a reader sees: `see="Note!on birds"` points at the
sub-entry `on birds` under `Note`, while `see="Note: on birds"` is one level
that merely prints the same way, and does not link.

**A target that names no entry is reported.** A `see=` or `see-also=` naming a
term nothing indexes sends a reader to an entry the index does not have. It is
not dropped — what you wrote is yours — but you get a warning naming the mark
and the target, once per mark per target, whatever you render to. A target
resolves when its levels name an entry the document indexes, including a level
that exists only because a deeper entry hangs from it: with
`entry="Trees!Oak!Acorn"` marked somewhere, `see-also="Trees!Oak"` resolves.
Where the three-level ceiling applies the judgement runs after folding, on both
sides: in PDF a target is compared against the paths entries print, and in HTML
against the levels you wrote. That is why a target spelling a folded path —
`see="One!Two!Three, Four"` against `entry="One!Two!Three!Four"` — is understood
in PDF and reported in an HTML render. In
a book the whole book's marks are what a target is judged against, so a target
naming a term another chapter marks is fine. A PDF book is one document by the
time the extension runs, so nothing special happens there. An HTML book renders
each chapter on its own, so the report is drawn once, by the last chapter in
book order — which means a render that stops short of that chapter draws none,
and a render whose other chapters have never been rendered has nothing recorded
for them and will call their terms unindexed. Render the whole book.

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
- a `sort=` with more levels than there are to sort, whose extra levels are
  ignored. The report says what each count is over — the levels written in
  `sort=`, against the levels the entry is written with — because neither is
  the depth the entry finally indexes at: `entry="Moles!" sort="a!b!c"` is
  written with two levels, sorted with three, and indexes at one. On a mark
  carrying no `entry=` at all the second count is the one level its visible
  text makes, and the report says that instead;
- one entry given two different sort keys, which cannot file in two places —
  the first one in the document wins, and in a book the first in book order.

A book adds a fourth report, for a term two chapters sort differently. No
single document can see that clash, since each chapter renders on its own, so
it is reported where the book's index is built.

A fifth report is LaTeX-only. The index tool stores three levels, and this
extension folds a deeper entry into its third rather than lose it, so two
entries written at different depths can end up printing at one place — and each
still files where it was written to file, under its own sort key or, with none,
under its printed text. That stores the entry once per key and prints it in as
many places, identically. Every key contesting the path is named along with the
path itself, because which one you meant is yours to choose. The HTML index
applies no such ceiling, so there the two entries are two and nothing is
reported.

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

### The principal mention of a term

A term is usually discussed properly in one place and mentioned in passing in
others. `mention="principal"` says which occurrence is the proper one, and the
index emphasizes that locator alone — the convention a printed index uses for
what it calls a principal reference.

```markdown
Cats are mentioned here: [cats]{.index}.

Cats are discussed here: [cats]{.index mention="principal"}.
```

In a PDF that prints as `cats, 3, **7**`; in HTML the numbered link for the
principal mention is emphasized and carries the class `qi-principal`, and the
others do not. Mark as many other mentions as you like — only the ones you
give the role to are emphasized, and a term with no role anywhere is unchanged.

**Redefining the emphasis.** The LaTeX back-end wraps the locator in
`\quartoindexprincipal`, defined with `\providecommand` as `\textbf` and
injected, with the machinery that applies it, only into a document that uses
it. Define your own in the document's preamble and yours is kept — a document's
own header text lands above what a filter injects, so the extension's
definition steps aside:

```latex
\newcommand*\quartoindexprincipal[1]{\textit{#1}}
```

In HTML the extension ships no stylesheet, so the link carries a `<strong>` as
well as the class; style `.qi-principal` to change it.

**One case prints unemphasized.** makeindex folds three or more consecutive
pages under one entry into a range of its own, and the emphasis is applied by
looking a page up by the number the index prints — which a range like `3--5` is
not. So a principal mention whose page is anywhere in such a folded range, its
first page included, prints plain, silently. Nothing else about the entry
changes and no other locator is affected. This is only about a range the tool
folded for itself: a range you wrote with `range=` is one the extension knows
about, and it prints emphasized whole (see [A discussion that spans
pages](#a-discussion-that-spans-pages)).

**Deleting marks never breaks the next render on a leftover build file.** The
emphasis machinery writes its page registrations into the document's `.aux`,
and the compiled index in the `.ind` carries the commands that print a locator
and a cross-reference. Either file can outlive the marks that wrote it —
`latex-clean: false`, or a failed render, leaves it in place. A document whose
principal, range or cross-reference marks have since been deleted — every mark
included — still defines every command those leftover files name, so the next
render builds cleanly: the `.aux` lines are read and do nothing, and the pages
and targets a stale index holds print as the ordinary locators and
cross-references they now are. The leftovers are gone as soon as that render
rewrites the two files.

**A role needs a locator to apply to.** A cross-reference takes the place of a
locator, so `mention="principal"` on a mark that also carries `see=` or
`see-also=` has nothing to emphasize. The role is reported and dropped, and the
mark indexes exactly as it would without it.

There is one exception, and it can differ between the two back-ends. A target
naming the entry it is written on says nothing, so it is dropped — and the mark
then does have a locator, and keeps its role. The PDF index stores three levels
and folds anything deeper into the third, so a target can match the entry only
once folded: there the target is dropped and the role applies, while in HTML,
which folds nothing, the same target stands and the role is dropped. The same
mark can therefore be emphasized in the PDF and plain in HTML. The reports say
which happened in each render.

**Only `principal` is recognized.** Any other value is reported and the mark
indexes as though the attribute were absent — including an empty one, since
`mention=""` is a value you wrote rather than an attribute you left off.

### A discussion that spans pages

A term is often discussed across several pages rather than mentioned at one.
`range="open"` and `range="close"` say where such a discussion begins and where
it ends, and the index prints one locator spanning the two rather than a
locator at each end.

```markdown
The discussion of [otters]{.index range="open"} begins here.

...several pages of it...

And the discussion of [otters]{.index range="close"} ends here.
```

In a PDF that prints as `otters, 12--15`; in HTML the entry carries a single
numbered link, pointing at the opening mark, and the closing mark contributes
no link of its own. Both marks keep their visible text exactly as written.

**The two marks are paired by the entry they index.** Nothing else has to be
written: the closing mark is the next `range="close"` on the same entry as an
opening. Write the same `entry=` (or the same visible term) on both.

**A range can be the principal discussion.** Put `mention="principal"` on
either of its two marks and the whole range prints emphasized —
`otters, **12--15**` — and in HTML the single link carries `qi-principal` and a
`<strong>`, exactly as a lone principal mention does. The role belongs to the
span rather than to either mark, so write it once, on whichever end you like.

**A range pairs within one chapter.** Quarto renders each chapter of an HTML
book in its own process, so a range whose two marks are in one chapter is paired
there and prints as one locator, exactly as it does in a single document. A
range whose marks are in *different* chapters is not paired: each mark indexes
on its own, as though you had not written `range=` at all. Each chapter reports
its own half — the opening as never closed in that chapter, the closing as
never opened there — and the book adds one report naming the pairs it can see
split across its chapters. A PDF book is unaffected — Quarto renders it as
one merged document, so its ranges span chapters as you would expect.

**An ordinary mark inside a range disappears into it.** If you also write a
plain `[otters]{.index}` on a page inside the range, `makeindex` folds that
locator into the range and prints nothing extra — silently, and without a line
in its own transcript. The extension cannot warn about this: it does not know
page numbers, so it cannot tell which marks fall inside a range and which do
not, and a warning would fire on every mark of the term. Mark the term outside
its own range, or accept that the range covers it.

**Five things the extension refuses.** Each is reported, and in each the mark
indexes exactly as it would with no `range=` written — which for the first three
and the last means an ordinary page number, and for the mark carrying a cross-reference means
the cross-reference, which takes a locator's place either way. The reason a
refused range never reaches the index tool is that `makeindex` writes a
transcript warning for a range it cannot pair, and Quarto fails the whole render
on that warning:

- an opening that is never closed;
- a closing with no opening before it;
- a second opening for a term whose range is still open — the first opening is
  the one the next closing pairs with;
- a range mark that also carries `see=` or `see-also=`, since a cross-reference
  takes the place of a locator and a range is a locator;
- a `range=` value that is neither `open` nor `close` — including an empty one,
  since `range=""` is a value you wrote rather than an attribute you left off.

Two overlapping ranges of one term cannot be told apart, since pairing is by
entry; that is the third case above, and it is reported rather than guessed at.

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

**Putting the index after a bibliography.** Quarto appends a document's
reference block after this extension has already placed the index, so a
document that leaves the bibliography where Quarto puts it gets the index
first and the references after. To have it the other way round, write an empty
`#refs` div where the references belong, and the placement marker below it:

```markdown
::: {#refs}
:::

::: {.qi-index-here}
:::
```

Quarto fills that div in place, so the marker still sits below the finished
bibliography and the index follows it — `\printindex` after the reference
environment in LaTeX, the index section after the bibliography in HTML. Write
no `#refs` div and nothing changes: the references are appended at the end,
after the index.

Six rules, each of which warns rather than breaking your build:

- **Top level only.** A marker inside a callout, a list or another div places
  nothing: a printed index inside a LaTeX group or environment is a render
  risk. It is dropped, and the index keeps its default place at the end.
  Anything written inside it is kept, spliced in where the marker stood.
- **A div, and nothing else.** The marker class on a heading, on an inline span
  or on a code block places nothing and is reported. Your element is left
  exactly as you wrote it, class included: this extension removes markers, not
  the elements people mistake for them.
- **The first marker wins.** A second one is reported by its position and
  dropped. In an HTML book, where each chapter renders on its own, that
  position is reported with the chapter it was counted in.
- **The marker is empty.** Write anything inside it and your content stays
  where the marker was, with a warning. Nothing you wrote is deleted.
- **A marker in a document with no index marks** places nothing, and says so.
- **A nested marker that was the only thing there** empties the place it was
  written in, and that is reported by the number of the top-level block it sat
  under — with the chapter that number was counted in, in an HTML book. (A lone
  top-level marker places the index, so it empties nothing.)
  The report does not name what held it, on purpose: Quarto wraps a callout, a
  tabset and a captioned figure in divs it generates and you never wrote, so
  any name the extension could print is either invented or wrong — and a
  callout holding only a marker still renders its title bar, which is not
  "empty" at all. A marker nested inside another marker empties one place, not
  one per level.

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
with no configuration. In a document with a bibliography, where `\printindex`
lands relative to the reference block follows from where you put an empty
`#refs` div — see *Placing the index*, above. A document with no marks gets
none of this, except six one-line `\providecommand*` definitions: every LaTeX-derived render
carries the two cross-reference commands, and every one that does *not*
emphasize a principal mention carries four more — three against a leftover
`.aux` from a render that did, and one against a leftover `.ind`. They are
described under the principal mention, below.

A cross-reference is written into the same `\index{…}` command, through
`makeindex`'s encapsulation channel — `\index{cats|see{Felines}}` — except
where a term is marked two different ways, whose single composed entry carries
the cross-reference in its printed text instead. A document that puts both
attributes on one mark, or that composes such an entry, also gets one small
`\providecommand` in its preamble, which prints cross-references through
LaTeX's own `\seename` and `\alsoname`, so a document loading `babel` keeps
its translations. A document with neither gets nothing extra on this account.

A page range is written into that same channel, as `makeindex`'s own range
operators — `\index{otters|(}` at the opening mark and `\index{otters|)}` at
the closing one. Where either mark of the range is the principal mention, both
ends carry the same encapsulation command, which is what `makeindex` requires
of a range's two ends, and the pages the two marks land on are recorded through
the `.aux` so the span the index prints can be emphasized whole.

Placement is automatic unless you write a marker; see [Placing the
index](#placing-the-index).

### HTML

For HTML the extension adds an index of its own at the end of the body, or at
your placement marker if the document has one: an
unnumbered level-one **Index** heading, in a section whose id is `qi-index`
where the document has not taken that name and a minted one where it has (see
below), listed in the table of contents, followed by a nested bullet list of
the entries. It is built out of Pandoc's own document nodes rather than out
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
the numbers are link targets, not a count of anything. The section id is minted
the same way: `qi-index` where the name is free, and `qi-index-1`, `qi-index-2`
and so on where the document has taken it. One name sits outside that promise:
an id injected around the document at render time (`include-in-header` and its
relatives are never seen by the filter).

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
2. **The one-entry warning is LaTeX-only.** A term marked two different ways
   reaches the LaTeX index tool as one entry the extension had to compose, so
   the extension says it did. An HTML index prints the locator and the
   cross-reference together on one entry by itself, with nothing to compose,
   so the warning would name a decision that format never has to make.
3. **Sorting is the extension's own in HTML.** Top-level entries are ranked
   into letter groups first; inside a group, and at every level below the top,
   the order folds ASCII uppercase to lowercase and then compares character
   codes, breaking a tie by character code, over an entry's sort key where it
   has one. In LaTeX the order is `makeindex`'s. Neither collates accented or
   non-Latin text the way a language would, which is what sort keys are for.
4. **Locators are numbered links in HTML**, in the order the marks are
   written, where LaTeX gives page numbers.
5. **Cross-reference targets are hyperlinked in HTML** when the target names an
   entry in the same index, and are plain text otherwise. A printed index
   cannot link at all.
6. **A cross-reference carries no locator in either back-end.** The `see also`
   limitation described above is the same in both.
7. **The principal mention is emphasized in both**, but by different means: the
   LaTeX back-end wraps the page number in a command you can redefine, and the
   HTML back-end marks the link with a class and a `<strong>`.
8. **A page range is a page range only in LaTeX.** `makeindex` prints one span
   of pages, `12--15`; HTML has no pages, so a range there is one numbered link
   at the opening mark. Both are one locator where you wrote two marks, which
   is what the syntax means.

### Letter groups in the HTML index

The HTML index prints its top-level entries in groups, each introduced by a
label of its own — one `Symbols` group, then one group per letter, A to Z.

- **A group label comes from the string the entry files under**: its sort key
  where it has one, and its printed text where it has none. If that string
  begins with an ASCII letter the label is that letter, uppercased. Anything
  else — a digit, a punctuation mark, or an accented or non-Latin letter —
  files under `Symbols`. Nothing files under an empty string: a level that
  would print nothing is dropped before it gets this far.
- **The Symbols group comes first**, ahead of A, the way a printed index sets
  it. A sort key is how you move an entry across that boundary, exactly as it
  is how you move one within a group.
- **Grouping is always on.** There is nothing to switch on and no threshold
  below which it stops.
- **Only the top level is grouped.** A sub-entry files under its parent rather
  than under a letter of its own, so no label appears inside a nested list.

Each label is a `div` carrying the class `qi-letter` and nothing else — a hook
for your own CSS, and deliberately not a heading, so the alphabet does not
land in your table of contents. As everywhere else here, the extension ships
no stylesheet of its own.

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
`examples/dangling-xref.qmd` and `examples/resolving-xref.qmd` are a pair:
every cross-reference target in the first names a term nothing indexes, and
every target in the second resolves.

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
