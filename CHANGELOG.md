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

- An `index-labels:` value a reader could not read is now refused and reported
  rather than printed. Three shapes join the empty value that was already
  refused: a value made only of characters that print nothing — a non-breaking
  space, a zero-width space, one of the typographic spaces — and a value
  written as a nested map or as a list, which is what over-indenting the map by
  one level produces. Each names its own key and the level it was written at,
  and the key falls back exactly as an unwritten one does: to the next level
  out, then — for the three words, the two marks following no language — to the
  document's `lang:`, and then to the English word or the ASCII mark. Without
  this a `see-also: "&nbsp;"` printed an emphasized non-breaking space in front
  of a target and a nested map printed its joined leaf values, both in silence; `tests/run-tests.sh` fails at `M59-AC1/AC2` without it.

- An `indexes:` entry that is refused as a declaration — no `name:`, an empty
  one, a name that is no section id, a name already declared — now draws a
  second message where it also writes an `index-labels:` key, saying that key
  sets no word. Its value is not read: the entry declares no index, so there is
  nothing for its words to be the words of. Without this an author who repeated
  an index name and wrote a correct label map in the second entry was told
  about the name and nothing about the map; `tests/run-tests.sh` fails at
  `M59-AC3` without it.

- An index whose `symbols:` word one of its own letter groups is also headed by
  — `symbols: "A"` in an index that files a term under `A` — now draws a report
  naming the word and the index. What prints is unchanged: both groups are
  still there, in their own places, under the one heading. The report is drawn
  where the index is printed, so it fires for HTML and EPUB and not for a
  format with no letter groups; `tests/run-tests.sh` fails at `M59-AC4`
  without it.

### Output

- In an HTML book, a chapter whose record this render opened and could not use
  — a stale file where the record belongs, a record written by an older version
  of this extension, a record whose shape this version refuses — no longer
  costs the book that chapter's terms. The chapter's own `.qmd` is read and
  parsed instead, and the terms it marks and the placement markers it carries
  join the book's index. Because those markers say which indexes a chapter
  places, a book whose marker chapters' records cannot be read now prints the
  index no marker names in its last chapter, where before it printed no such
  section on any page.

  A recovered term links to its chapter's page with no fragment: the id it
  would link to is minted while that chapter renders, and only its record
  carries it. A mark reaching the chapter through an include shortcode or an
  executed cell is not recovered, and neither is one inside a block or span
  carrying `.content-visible` or `.content-hidden`, which recovery takes out
  whole whatever its `when-` or `unless-` attributes say; a chapter source
  Pandoc's markdown reader cannot read recovers nothing at all. A record
  that is simply absent is not recovered either, so a first render is
  unchanged.

  What comes back is what the author wrote. An `entry=` naming several levels
  rebuilds its sub-entry and the parent it hangs under; a `sort=` still files
  the term where it asks; and `see=` and `see-also=` still print their lines,
  neither carrying a page number, as neither does on an ordinary render. What
  the chapter worked out for itself while it rendered does not come back: a
  recovered mark indexes as though `range=` and `mention=` were absent, so
  both ends of a page range print the one page the chapter is on, and a
  principal locator prints as an undeclared one does.

  The two reports about a record this render could not use each say which of
  three things happened for that chapter — its terms were read back out of its
  own source, its source parsed and carried no mark this route can reach, or
  its source could not be read either.

- In an HTML book, a store directory that is there and cannot be listed — one
  replaced by a file, or whose read permission is gone — no longer reads as a
  book that has never been rendered. Every chapter is read back from its own
  source instead, so the book still gets a complete index, and each chapter is
  reported as recovered by every chapter that looks for its record — where
  before each index carried only the terms of the chapter that built it and the
  index no marker names printed on no page at all. A store directory that is
  not there is untouched: a first render is what it always was. So is one that
  still lists — the records inside it are read as absent whatever is wrong with
  them.

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

- An index no marker names, in an HTML book, is printed at the end of the
  book's last chapter, on every render — provided some chapter of the book
  places an index, since a book asking for no index grows none. Where that
  chapter carries a marker of its own the section follows the ones its markers
  place; where it carries none the section goes at the end of the chapter.
  Which chapter that is comes from the book's own chapter list, which every
  chapter of every render reads the same way, so no render prints such a
  section in two chapters and none of it waits for a second render. Earlier
  versions handed the section to the last chapter that placed an index, worked
  out from the records the other chapters had left, and two chapters of one
  render could reach two different answers; `tests/run-tests.sh` fails at
  `M063-AC1` without this. The
  [Books](site/books.qmd), [Named indexes](site/named-indexes.qmd) and
  [Placing the index](site/placing-the-index.qmd) pages say so.

- A stored chapter record an HTML book cannot use as it stands — one written
  by another version of the extension, and one naming an index the book no
  longer declares — is now reported once by each chapter that builds an index
  section, rather than once by every chapter that renders while it stands. A
  chapter that builds none reports as well where the records it read show no
  chapter of the book placing an index — a book with no placement marker
  anywhere, and equally a chapter rendered while the marker chapter's own
  record cannot be read — where such a chapter used to say nothing at all.

- A stored chapter record whose cross-reference field is not a list is refused
  and reported like any other record this version cannot read. It used to be
  walked before its type was tested, which ended the render — the one thing
  the record check exists to prevent; `tests/run-tests.sh` fails at
  `M60-AC5` without the fix.

- An HTML book no longer reports an index section it did not place, or one
  printed in two chapters: the rule above leaves neither possible, so both
  reports were removed along with the two fields a chapter's stored record
  carried for them. The record format is unchanged, so a record written by
  this version's predecessor still gives its chapter's terms to the index
  rather than being refused. What a chapter whose record can never be
  written — something else holds the path it needs, the project tree is
  read-only — costs the book is now that chapter's own terms alone: the
  section is still printed, short those terms, and the reports naming the
  unreadable record and the failed write say which chapter to look at.

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
