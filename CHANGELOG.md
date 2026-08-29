# Changelog

## Unreleased

### Marking syntax

- Three words the HTML and EPUB index prints itself — the `Symbols` heading
  over the entries that file under no letter, and the `see` and `see also` in
  front of a cross-reference — can be set by the author under `index-labels:`,
  whose keys are `symbols`, `see` and `see-also`. The map is written at a
  document's top level, where it covers every index, and inside one `indexes:`
  entry, where it covers that index alone; where both name a key the index's
  own wins, key by key, and a key written nowhere keeps its English default.
  It is `index-labels:` and not `labels:` because a top-level `labels:` is
  Quarto's own map, which this extension does not read. A LaTeX index is
  unaffected: it takes these words from babel, which sets them from the
  document's `lang:`.

- Two punctuation marks the HTML and EPUB index prints inside an entry can be
  set by the author under the same `index-labels:` map: `separator`, printed
  in front of an entry's locators, between one locator and the next, and in
  front of an entry's first cross-reference whether or not locators precede
  it, and
  `xref-separator`, printed between two cross-references. Both default to what
  they have always been, `,` and `;`, and both resolve on the ladder the words
  resolve on — an index's own map, then the document's, key by key. A key sets
  the glyph alone; the space after it is the extension's own. Neither key
  follows the document's `lang:`, and neither reaches a LaTeX index, whose
  punctuation comes from `makeindex` and from the LaTeX the extension emits
  around a cross-reference.

### Output

- **Changed default.** The four words the HTML and EPUB index prints for
  itself now follow the document's `lang:` instead of always being English:
  the `Symbols` heading, the `see` and `see also` in front of a
  cross-reference, and the heading of an index the document did not declare.
  Spanish, French, German and Italian are covered; German covers three of the
  four and keeps the English `Symbols`. Any other language, and a `lang:` this
  extension cannot read, keeps all four English words and says nothing. The
  words come from a table this extension ships, checked against two published
  references per word; `index-labels:` still beats it, key by key.

  The one visible change to a document that sets no words of its own is the
  index heading, and only where the language's word differs from `Index`: a
  Spanish document is now headed `Índice alfabético` and an Italian one
  `Indice analitico`, where French and German still print `Index`. Writing
  `title: Index` restores the old heading, in an `indexes:` entry rather than
  in the front matter — a front-matter `title:` is the document's own title and
  this extension never reads it. Declaring an index that way also moves the
  index section's id from `qi-index` to `qi-index-<name>`, so a link written
  against the old id has to be updated with it. Only the heading of an index the
  document never declared changes; an index declared under `indexes:` with no
  `title:` is still headed by its own `name`. A LaTeX index is unaffected,
  as before: it takes its words from babel, which already sets them from
  `lang:`.

- An EPUB render gets a real index instead of passing its marks through. It is
  the index the HTML back-end builds, out of the same document nodes: the same
  section id and classes, the same letter groups and entry tree, numbered
  locator links and cross-references. Pandoc's EPUB writer splits the document
  into an XHTML file per top-level heading, so a locator link crosses files;
  the links resolve inside the book. Two things differ from HTML, both
  documented on the [EPUB](site/epub.qmd) page: Quarto renders an EPUB book in
  one Pandoc process, so nothing folds and every index the book declares
  prints under its own title, and a page range opened in one chapter and
  closed in another pairs there where an HTML book cannot see both ends; and
  an EPUB has no pages, so locators are the per-entry sequence numbers HTML
  uses. beamer, reveal.js, `gfm` and every other format still pass marks
  through unchanged.
- A LaTeX or PDF render builds every index the document declares, each at its
  own placement marker, instead of folding them all into one. The first
  declared index is built by Quarto's PDF loop as before; every index after it
  is built by `imakeidx`, which runs the index tool itself through TeX's
  restricted shell escape — permitted for `makeindex` by a stock TeX Live or
  TinyTeX. Where an installation withholds that permission, each index after
  the first prints empty, which the [Named indexes](site/named-indexes.qmd)
  page documents.
- An HTML book builds every index its chapters declare, each printed at the
  first marker naming it and an index no marker names after them, instead of
  folding them all into one. Each chapter's stored record now carries the
  index every mark files in and each index's own sort keys, so the three
  judgements a book makes across its chapters — a cross-reference target no
  chapter indexes, a rival sort key, and a range left unpaired — are each made
  inside one index and named over it. The record format changed with it: a
  record written by an earlier version is refused with the report it has
  always drawn, costing that chapter's terms until it is rendered again, and a
  record naming an index the book no longer declares has its marks filed in
  the first index it does declare, with the chapter and the name reported. The
  [Books](site/books.qmd) page documents both.
- A mark filed in a named index and written below that index's own placement
  marker is reported: `imakeidx` closes that index's entry file where the
  index is printed, so those entries reach no index at all. The first declared
  index is unaffected — its entry file is held open past the place it is
  printed.
- Every per-index judgement a LaTeX render makes now names the index it was
  made in, as the HTML back-end's already did: a cross-reference target that
  resolves against nothing, a rival sort key, a range that pairs in neither
  index, an entry marked both as a plain locator and as a cross-reference, and
  two entries that print in one place and file under two keys.

### Project

- The extension ships editor metadata beside its manifest:
  `_extensions/index/_schema.yml`, a Quarto Wizard schema declaring the
  `index` and `qi-index-here` classes and the attributes each carries, and
  `_extensions/index/_snippets.json`, VS Code-format snippets for every
  marking form. Editors supporting those formats read them for completion and
  hover text; a render reads neither.

## 0.1.0 (2026-08-26)

First tagged release. Earlier development is in the git history.

### Marking syntax

- Ten supported span forms, listed on the [Syntax](site/syntax.qmd) page: a
  bare mark, `entry=` for an entry other than the visible text, `!`-separated
  sub-entry levels, an empty span that indexes without writing anything,
  `see=` and `see-also=` cross-references, `mention="principal"` for the
  locator an entry emphasizes, `range="open"` / `range="close"` for one
  locator spanning a discussion, and `index=` for which named index a mark
  belongs to.
- A `sort=` attribute files an entry under a key other than its own text,
  including a key per sub-entry level.
- A `::: {.qi-index-here}` div says where the index prints. It is honoured at
  the top level of a document, the first marker wins, and a second one is
  reported by its position.
- The visible text of a mark is left exactly as written in every format.

### Output

- A LaTeX/PDF back-end built on `imakeidx`.
- An HTML back-end that prints the entry tree with letter groups and links
  each locator to the marked passage.
- A Quarto book gets one index for the whole book, built from a sidecar store
  the chapter renders share; the extension names any chapter whose entries
  came from an earlier render rather than the current one.
- In beamer and any other format with no back-end, marks pass through: the
  text is preserved and no index markup is emitted.
- Warnings about a mark itself — an empty level, a cross-reference with no
  usable target, a mark with nothing to index — are raised whatever the
  output format.

### Project

- Requires Quarto 1.4 or later. `imakeidx` is the only other runtime
  dependency, on the LaTeX side.
- Released under the MIT license.
- Documentation site at <https://jmgirard.github.io/quarto-index/>.
