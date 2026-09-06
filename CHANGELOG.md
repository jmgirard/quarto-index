# Changelog

## Unreleased

### Output

- An id you write on an index mark no longer leaves two elements of a rendered
  page carrying it. Where the name is also on something else — an element of
  your own, in Pandoc attributes or in raw HTML, or another mark — the mark
  gives it up: the element you wrote the name on keeps it, and the mark is
  given a minted `qi-mark-` id, which for a mark that files a locator is where
  that locator points. Between two marks written with one name, the one whose
  locator links to the name keeps it whichever you wrote first; between two of
  a kind the first in the document keeps it. A mark that only points at another
  entry gives a contested name up the same way, having no locator to move.
  Every yield is reported once as the render runs, naming the id given up and
  what the mark files under — the term it prints, or the entry you wrote for
  it. An id nothing else on the page carries is untouched, whatever it is
  spelled and including one only an HTML comment holds, and no element of yours
  is ever renamed. HTML and EPUB alike, both back-ends being the one code path.
  In a book, a chapter read back from its own source rather than from a record
  is settled against no rendered page, so this does not reach it.

## 0.3.0 (2026-09-05)

No record 0.2.0 wrote is refused by this version, so a book keeps its terms
without being rendered again. Three things an author sees change, all of them
in an HTML book: an index link into a chapter recovered from its own source
now lands on the passage its mark sits at rather than at the top of that
chapter's page; a mark written in a chapter's YAML front matter files one
locator rather than one per copy of the field Quarto reflects into the page,
two of which named ids the page did not carry; and a chapter that is a
notebook is no longer read back as markdown, so the garbled terms it appeared
to carry reach no index. All three are described below.

### Output

- In an HTML book, a chapter no render has written a record for is now read
  back from its own source by the chapters that can print an index section —
  a chapter carrying a placement marker of its own, and the book's last
  chapter, which takes on every index no marker names — so a book rendered
  chapter by chapter, or into a tree whose records never survive, prints an
  index carrying every chapter's terms rather than one short of them. Every
  other chapter reads such a record as absent exactly as before. A whole-book
  render prints the index it always printed, since by the time a chapter reads
  the store the chapters before it have written their records: the ordinary
  first render of a book whose marker sits in its last chapter reads no source
  and reports nothing, while one whose marker sits earlier reads the sources of
  the chapters behind it and reports them in one line naming each, the next
  render silent.

  A chapter recovered this way is reported by a wording of its own, naming the
  record as one no render has written rather than one that could not be read.
  A chapter with no record whose source parses and reaches no index mark is
  passed over in silence — it has lost nothing, and a chapter that marks
  nothing looks exactly the same — while one whose source cannot be read at
  all still draws the report naming that outcome.

- Reading a chapter's own source back is now confined to the chapter files it
  is a reader for: one named `.qmd`, `.md`, `.markdown` or `.Rmd`, and no other
  kind. A book may take a notebook chapter, whose file on disk is JSON; that
  file was being read as markdown, and the terms it appeared to carry were
  filed under whatever the JSON's own quoting left of their attributes — often
  in an index the author had not named, with nothing said. Such a chapter is
  now refused and reported by a wording of its own naming the file, and none of
  its terms reach any index. Reading a chapter's source happens only where that
  chapter's record could not be used or was never written, so a notebook chapter
  whose record is there and readable is still read from that record, which is
  what a whole-book render leaves behind.

- A mark written in a chapter's YAML front matter now comes back with the
  marks in that chapter's body when the chapter is recovered. An ordinary
  render has always indexed one written there; the recovery route read the
  chapter's blocks alone, so such a mark was silently missing from every index
  of the book whenever the chapter was recovered rather than read from its
  record.

- In an HTML book, a mark written in a chapter's YAML front matter now files
  one locator, the chapter's page with no fragment, when the chapter is read
  from its own record — the row the recovery route already filed for it — so
  the two routes print the same row for such a mark. Before, the chapter's own
  render filed the mark once for the metadata and once more for each copy of
  the field Quarto reflects into the chapter's body ahead of every filter,
  each copy minting an anchor of its own, and it linked every one by a
  fragment: an `abstract:` mark printed three locators of which two named ids
  the page did not carry, and a `description:` mark printed one that did,
  since a book's title block does not print that field. The reflected copies
  are no longer marks, and the metadata's mark mints no anchor, because which
  fields the page prints is the title-block template's choice and not
  something a filter can see. A single document that is not a book chapter is
  untouched: its front-matter marks keep their anchors and their fragment
  locators, its page printing every one of the probed fields in its own title
  block. A mark written in a chapter's `title:` is not covered: Quarto copies the
  title into every page's sidebar and page navigation, and each copy still
  files a locator of its own.

- In an HTML book, a mark recovered from a chapter's source now carries the
  Pandoc identifier its author wrote on it, so the index links to the passage
  that mark sits at rather than to the top of that chapter's page. A recovered
  mark whose author wrote no id is unchanged — the chapter's page and nothing
  after it — because the id such a mark is anchored at is minted against every
  id on the finished page, which this route cannot see from one chapter's
  source. A cross-reference mark still contributes no locator whatever id it
  carries, and a mark in a chapter's front matter still files the chapter's
  page with no fragment whether that chapter is read from its record or
  recovered from its source, so the two routes keep printing the one row for
  it.

- In an HTML book, the reports about a chapter no render has written a record
  for are now drawn once for every chapter that builds an index section — and
  once by a chapter that builds none where the records it read show no chapter
  of the book placing an index — rather than by every chapter that reads a
  chapter's source back, whether it prints a section or not. That is what such
  a record costs: a section's share of that chapter's terms. The last chapter
  of a book whose every declared index is placed earlier reads those sources
  and now says nothing about them.

  Each report is drawn once however many such records the chapter met, and
  names every chapter it covers, rather than once for each of them. A chapter
  reading a store no render has written meets every other chapter of the book
  at once — a single-chapter render of a five-chapter book drew four reports
  saying one thing — and nothing about where a chapter sits tells a first
  whole-book render from a single-chapter render on a cold store. The three
  sentences are reworded to read correctly whether one names a single chapter
  or six. The refusal a chapter whose source this extension will not read draws
  moves with them where no render has written its record, following the count
  of the report it stands in for.

  Which chapters are read back is unchanged, and so is every term in every
  index: a chapter carrying a placement marker, and the book's last chapter,
  still read the source of each chapter no record has been written for.

- In an HTML book, a chapter no render has written a record for whose own
  source also cannot be read is now reported by a wording of its own, naming
  the record as one no render has written and the source as one that could not
  be read. It said the record could not be read, which asserts a file that was
  never written and sends an author looking for a corrupt record that is not
  there. The report a record that WAS written and could not be read draws is
  unchanged, and still names both files.

- In an HTML book, a record file that decodes to a table carrying no `version`
  field — or one holding something other than a number — is now reported by the
  wordings for a record that could not be read rather than as one written by a
  different version of this extension. Only a `version` this render can read as
  a number and does not itself write evidences a version at all; a truncated or
  hand-emptied record evidences none, and was being reported as carrying one.
  A record whose `version` is a number this render does not write is reported
  as before, at the count it had. Where a record evidencing no version is
  reported moves with its wording: it is now drawn where the chapter met it, by
  every chapter that reads the store, rather than once for every chapter that
  builds an index section — and where that chapter's source is one this
  extension will not read, its refusal is drawn there too rather than at the
  section-building site. No record's usability changes: every one of these was
  already refused and read back from its chapter's source.

- In an HTML book, a chapter whose source this extension will not read is now
  reported once for every chapter that builds an index section — and once by a
  chapter that builds none where the records it read show no chapter of the book
  placing an index — rather than once for every chapter that reads the store,
  where the record that chapter left behind was written by a different version of
  this extension. That is the count every other report about a record from
  another version follows, and it is what such a record costs: a section's share
  of that chapter's terms. A book carrying a notebook chapter with an old record
  said the refusal once per chapter of the book, where it said any other stale
  record once per section. The two states about a record that WAS there — there
  and unopenable, and there and holding bytes that do not decode at all — still
  draw the report where the chapter meets the record, on the counts they have
  always had; a record no render has written is the entry above. A refused
  chapter still says one thing, and never that its record was written by a
  different version.

## 0.2.0 (2026-09-02)

Two changes break what 0.1.0 did. The index words now follow the document's
`lang:`, so an index heading in Spanish or Italian is no longer `Index`, and
restoring the old heading moves the index section's id. And a chapter record
written by 0.1.0 is refused by this version, costing that chapter's terms
until the book is rendered again. Both are described below.

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
  of a target and a nested map printed its joined leaf values, both in silence.

- An `indexes:` entry that is refused as a declaration — no `name:`, an empty
  one, a name that is no section id, a name already declared — now draws a
  second message where it also writes an `index-labels:` key, saying that key
  sets no word. Its value is not read: the entry declares no index, so there is
  nothing for its words to be the words of. Without this an author who repeated
  an index name and wrote a correct label map in the second entry was told
  about the name and nothing about the map.

- An index whose `symbols:` word one of its own letter groups is also headed by
  — `symbols: "A"` in an index that files a term under `A` — now draws a report
  naming the word and the index. What prints is unchanged: both groups are
  still there, in their own places, under the one heading. The report is drawn
  where the index is printed, so it fires for HTML and EPUB and not for a
  format with no letter groups.

### Output

- **Breaking — changed default.** The four words the HTML and EPUB index
  prints for itself now follow the document's `lang:` instead of always
  being English: the `Symbols` heading, the `see` and `see also` in front of
  a cross-reference, and the heading of an index the document did not
  declare.
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

- **Breaking.** An HTML book builds every index its chapters declare, each
  printed at the first marker naming it and an index no marker names after
  them, instead of folding them all into one. Each chapter's stored record
  now carries the
  index every mark files in and each index's own sort keys, so the three
  judgements a book makes across its chapters — a cross-reference target no
  chapter indexes, a rival sort key, and a range left unpaired — are each made
  inside one index and named over it. The record format changed with it: a
  record written by an earlier version is refused with the report it has
  always drawn, costing that chapter's terms until it is rendered again, and a
  record naming an index the book no longer declares has its marks filed in
  the first index it does declare, with the chapter and the name reported. The
  [Books](site/books.qmd) page documents both.

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
  render could reach two different answers. The
  [Books](site/books.qmd), [Named indexes](site/named-indexes.qmd) and
  [Placing the index](site/placing-the-index.qmd) pages say so.

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
  not there is untouched: a first render is what it always was.

- In an HTML book, a record file the store directory lists and which cannot be
  opened — one whose permissions have been cleared, or sitting in a directory
  that has lost the search bit its records are opened through — no longer reads
  as a record no render has written. Its chapter is read back from its own
  source and reported, exactly as a record that was opened and could not be
  used already is, so its terms stay in the book's index instead of going
  missing from every other chapter's in silence. The evidence is the record's
  own filename in the listing of the directory it belongs in; a name the
  listing does not carry is still an absent record, so a first render and a
  tree with no store are untouched. A file merely *named* like a record and
  unopenable counts as one that was written — a broken symlink left at that
  path by hand, say — and its chapter is read back from source, which nothing
  this extension writes can produce and which costs a chapter recovered rather
  than dropped.

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
  the record check exists to prevent.

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
