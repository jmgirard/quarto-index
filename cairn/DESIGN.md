# Design

## Purpose & Scope

quarto-index is a Quarto extension for book-quality subject indexing: authors
mark index entries with a format-neutral span syntax, and per-format back-ends
realize the index — LaTeX/PDF first, HTML and others to follow. **The marking
syntax is the product; output formats are back-ends** (a future format request
is in-scope work, not someone else's problem).

Audience: the general Quarto community from day one — documentation, tests,
and edge-case coverage are commitments, not extras (GP1). The capability
roster is **completeness-driven**: the target is a full indexing suite —
cross-references (see/see also), page-range & styling control, multiple named
indexes, sort keys, an HTML back-end, and multi-file book support — not a
minimal personal tool.

Distribution ambition (declared at init 2026-08-16): **tagged public
releases**, with changelog discipline from the start; at first release, submit
to the Quarto extension listing and aim for discoverability. Release timing
stays user-declared. Toolchain profile: generic (see `cairn/PROFILE.md`).

## Contract boundary

- The extension's job ends at correct emitted output for each supported
  format (GP2); mark values are structured, format-neutral data (IP1).
- Quarto version support is part of the contract: a stated minimum version in
  `_extension.yml` and README, eventually CI-tested against the floor and
  latest (candidate: CI matrix).

## Function Families

_None yet — populated as the codebase takes shape._

## Conventions

- Numeric results carry **no oracle-verification commitment** (declared at
  init, 2026-08-16): the universal ≥2-independent-oracle-types bar is waived;
  numeric results, if any arise, are checked ad hoc. Revisit if scoring or
  statistical work enters the project.
- **A module's definitions keep their plain form, and it exports through
  brackets** (added M17). Every *top-level* definition in
  `_extensions/index/modules/` is written `local function NAME(` or
  `local NAME = <literal>` at column 0, never `function M.NAME(`, and the
  module table is populated afterwards as
  `M["NAME"] = NAME`. Each half is load-bearing for the acceptance suite, and
  each for its own reason. The bracket export: the source scans match a
  definition as an anchored `local NAME = <literal>` line and require exactly
  one of it set-wide (narrowed from first-match at M25, corrected M25), so a
  plain `M.NAME = NAME` line would read as a second definition and fail the
  scan as a stale duplicate — which is what a duplicate left behind by a split
  is (M16 review F3). The plain definition form: `tests/movedefs.py` finds a
  definition only by `local function NAME(` or `local NAME =` at column 0 and
  demands exactly one set-wide, and `tests/scans/warn-distinct.py` excludes
  `warn`'s own definition from its pinned message count by testing that the
  text before the match ends in `function` — which a `function M.warn(` would
  defeat, counting the definition as a call. Helpers nested inside a function
  are outside the rule and stay where they are — `flush` in `html.lua`, the
  `note` and `count_owner` walkers in `html.lua` and `marker.lua` — since they
  close over the locals of the function that holds them.
- **A module is required under `qi_<name>`** (added M17), never its bare name:
  `levels`, `marks` and `marker` are all ordinary local and parameter names in
  this filter, and a top-of-file alias is shadowed by any later inner local or
  parameter that shares its name — `sortkeys.lua`'s `register_sort(levels, …)`
  is the case that forced the rule.
- **Collation is best-effort**: non-ASCII terms appearing correctly is an IP2
  commitment under that principle's engine-and-font condition (corrected M33),
  but sort *order* beyond what the user's index processor
  provides is best-effort. Sort keys (`sort=`) are how an author overrides it,
  and each back-end orders under its own rules (corrected M06). The HTML
  back-end ranks its top-level entries into letter groups — Symbols, then
  A–Z — before collating within a group; only ASCII letters make a letter
  group, which is honest about a collation that only folds ASCII (corrected
  M07).
- **A reported level count names the levels it is over** (added M19). A warning
  that reports a count of index levels says which levels the count is over —
  those the author wrote, or those left after empty levels are dropped (D-002) —
  and gives both counts where the two differ. The rule governs what a number is
  called, never what it is: no count any report computes changes. A report whose
  number has no drop to distinguish — a book's chapter count, a top-level block
  position — is outside THIS bullet's rule, and inside the next one (corrected
  M28).
- **A judgement about a mark is made inside the index the mark files in**
  (added M38). A document declares its indexes in `indexes:` metadata, each
  with a name a mark reaches by `index=` and a title its section is headed
  with; a mark or a placement marker naming none belongs to the first declared
  index, and a document declaring nothing has one unnamed index, which is the
  behavior every document had before. Every format-neutral accumulator is one
  namespace per index — the marked paths a cross-reference target resolves
  against, the sort-key registry, the printed-path collision map, and the
  pairing map a range opening waits in — so a target, a key and a range are
  each settled within one index and never across two, and a report of such a
  judgement names the index it was made in rather than the document (corrected
  M38 review), the remedy such a report offers naming that index too rather
  than sending the author to the document at large (extended M39). One
  format-neutral accumulator is outside that rule:
  `latex.lua`'s `contested_keys`, which `passes.CollectKeys` fills in every
  format but whose two consumers both sit after the HTML early return. No
  back-end folds any more (corrected M55): a LaTeX-derived render builds every
  declared index through `imakeidx` (M49) and an HTML book aggregates through a
  per-chapter record carrying the index each mark files in (M55), so WHICH
  index a mark files in is what its author wrote, in every format, and the
  three reports that once said otherwise are gone.
- **A reported position or count names the sequence it is over** (added M28). A
  warning that reports a position or a count over a sequence says which
  sequence. A top-level block position is counted over the document as the
  filter received it, after Quarto expanded any includes and executable cells,
  so it can differ from the position in the author's source file; a book's
  chapter count is over the files the book renders, in render-list order. Where
  a report names two numbers, each is named where it is printed. The author's
  own source position is not offered alongside the reported one — the expansion
  has already happened and nothing records where a block came from (D-014). A
  report whose number indexes into no sequence is outside it.

## Design Principles

<!-- IP<n> = Inviolable (hard constraint) block first, then GP<n> = Guiding
     (tradeable with justification); numbers never reused or renumbered —
     retiring one takes a D-entry. Elicited /design-interview 2026-08-16. -->

### Inviolable

- IP1: **Format-neutral marking.** The index-mark syntax and all attribute
  values carry format-neutral meaning; back-ends realize them per format. A
  mark value is never raw back-end code (no raw LaTeX or HTML pass-through;
  D-001). A feature's *semantics* must be format-neutral even when only one
  back-end realizes it yet; unrealized formats degrade gracefully (IP2).
- IP2: **Never break the document.** A document using this extension never
  fails to render, and never silently corrupts output, because of a marked
  term: any characters in a visible term appear correctly in the index —
  non-ASCII included, on the condition that the document's PDF engine and
  main font can draw them, which for terms outside Latin-1 means the recipe
  the docs site's Terms outside Latin-1 page names (amended M33, D-016;
  recipe home corrected M40, D-023) —
  and formats without an index back-end pass the
  visible text through untouched, with no artifacts. An escaping bug, a
  crash on exotic input, or garbage in a back-end-less format is the
  highest-severity bug class and earns a regression test forever.
- IP3: **Post-release syntax stability.** From the first tagged release
  onward, documented syntax forms change only via a deprecation cycle.
  Before that release the syntax is fluid: pre-release installs are
  at-your-own-risk, with breaks recorded in the changelog (amended M44,
  D-026). The release line is the promise.

### Guiding

- GP1: **Community-grade, discoverable quality.** Docs, tests, and
  edge-case coverage are commitments user-facing work carries by default;
  the documentation site, README and examples are discovery surface held to
  extension-listing quality (site added M40).
- GP2: **The contract ends at correct emitted output.** Per format, the job
  is correct output (e.g., valid `\index{}` LaTeX); whether the user's
  toolchain then builds the index is a documentation surface — known failure
  modes documented, never detected or managed.
- GP3: **Pure Pandoc-Lua, self-contained.** Zero runtime dependencies
  beyond Quarto; `quarto add` is the entire install story. LaTeX-side needs
  stay within packages bundled in mainstream TeX distributions.
- GP4: **Zero-config defaults.** The common case works with no
  configuration; options are added compatibly for the uncommon case, never
  required for the common one.
- GP5: **Minimal API surface.** Prefer one composable mechanism over
  parallel syntaxes; a new syntax form must express something the existing
  mechanism cannot.
- GP6: **End-to-end verification.** Acceptance evidence for
  output-producing features runs to the final compiled artifact (a PDF with
  a real index), not only intermediate output.

Package choices (e.g., imakeidx) are current idiom, not commitments:
principles bind "the LaTeX back-end," and swapping its implementation is an
ordinary plan-gate choice.

## Architecture

One Pandoc-Lua filter, run as five passes over each document (corrected M06,
M21; the tagging pass added M071).
Its entry point is `_extensions/index/index.lua`, which defines the Pandoc pass
and nothing else; every other definition lives in a module beside it under
`_extensions/index/modules/`, loaded with a relative `require("./modules/<name>")`
and bound under a `qi_` name so that no local can shadow a module — `levels`,
`marks` and `marker` are all ordinary local names in this filter (added M17).
The modules, in dependency order:

- `core.lua` — the shared constants, the `warn` channel, and the format
  tests: `is_latex_derived`, `is_html`, `is_epub`, and `builds_ast_index`
  (`is_html` or `is_epub`) for the two back-ends that build their index in the
  AST (M52). It requires nothing; every other module requires it.
- `levels.lua` — what an `entry=`, `see=` or `sort=` value means as a list of
  levels: the parse, the empty-level drop, the three-level clamp, and the
  level path a sort key is declared against.
- `indexes.lua` — the indexes a document declares: the ordered name-to-title
  table read out of `indexes:` metadata, the shape a declared name may be,
  which index a mark or a placement marker files in, and the reader-facing
  words and marks an author writes under `index-labels:` — which keys are
  writable, which values are refused as unreadable, and the
  per-index-then-document ladder a key resolves on (added M38; listed here
  corrected M38, moved above `sortkeys.lua` M39, which now requires it, the
  fold retired M55, and the label clause added M59).
- `sortkeys.lua` — the registry mapping a printed level path to the first sort
  key declared for it, and the report drawn when two marks disagree about it.
- `latex.lua` — the LaTeX back-end: the `\index{...}` argument, the
  encapsulation a cross-reference rides in, and the contested-key bookkeeping
  that decides which shape a key gets.
- `marks.lua` — what every back-end needs from one mark, derived once, and the
  document-wide accumulators the passes share.
- `passes.lua` — the per-document reset and the five Span passes, in the order
  the filter returns them: the reset; the tagging pass, whose document hook
  tags every index mark in the metadata with `META_MARK_ATTR` and, in an HTML
  render, takes the index class off every span inside Quarto's top-level
  `#quarto-meta-markdown` div (the chapter's metadata fields, copied there
  ahead of every filter and not printed), its element hook discarding an
  author's copy of the tag first (added M071); then three that only read — one
  registering sort keys, one deciding which keys are contested, one pairing
  page ranges — and the emitting pass that rewrites the mark, reading the tag
  off and, in an HTML book chapter, filing a tagged mark as a page locator
  with no anchor (D-048). The range pass carries a document hook as well,
  since whether an opening is ever closed is known only once the whole
  document has been read.
- `html.lua` — the HTML back-end: the entry tree, its ordering and grouping,
  the anchors that link an entry back to its mark, and the index section built
  out of them.
- `marker.lua` — recognizing the placement marker, reporting its misuse, and
  putting the index where it stood.
- `book.lua` — the per-chapter sidecar store, and each declared index built
  out of it by the chapter whose marker places that index (corrected M55).

The document-wide accumulators are module-level and are returned to their
initial values once per document. Each of `indexes.lua`, `marks.lua`, `latex.lua` and
`sortkeys.lua` owns a `reset` restoring every cell it declares; `passes.Reset`
calls the four, `indexes.lua` first because every accumulator below it is keyed
by the index a mark files in (corrected M38); and `index.lua` returns it as the pass list's leading
`{ Pandoc = ... }` table, which Pandoc runs over the document before any later
table's element functions. **A new accumulator joins its module's `reset` in
the commit that adds it** — that is the convention, and `tests/stateprobe.py`
is what holds the existing ones to it, removing each in turn and requiring a
paired render to differ (corrected M26).

Without that, an accumulator lasts as long as the Lua state holding it. Nothing
in Quarto reuses one today — it runs one pandoc process per document — so the
reset is a guarantee rather than a fix, and a probe of the toolchain would find
no path to the defect. M17 made the guarantee worth writing down: it moved
every cell out of the filter chunk's own locals, which re-initialized per
execution, and into module tables `require` caches and does not. Tables are
emptied in place, because each is exported by reference and a rebound local
would restore its own module's view alone. What `quarto add` installs is
unchanged in shape: `_extension.yml` contributes one filter, `index.lua`, and
the install copies `modules/` along with it (GP3).

The **collect pass** reads every mark that writes a `sort=` and registers the
sort key against the printed level path it was written for, reporting once per
rival key a level is given (corrected M06). It runs first because a sort key belongs to the
entry rather than to the mark that declared it: the emitting pass has to know
every key before it emits the first mark, or a mark goes out under a key a
later mark contradicts. It only reads; nothing it sees changes the document.

The **Span pass** handles one mark at a time. Everything that depends only on
what the author wrote happens *before* any back-end is chosen: the `entry=`
value is parsed into levels and its empty ones are dropped, because a level that
prints nothing is not a level — a format-neutral fact, which is why the drop
lives here and not in a back-end the way the three-level ceiling does. That the
LaTeX index tool also rejects a whole entry for a leading null field, silently,
is what made the defect urgent rather than what makes the rule right (added M11;
a value that is only
empty levels falls back to the mark's visible text, and a sort level is dropped
with the entry level it was written for and reported, never re-aligned onto a
level it was not written for — corrected M11 review). The drop is reported once
per mark, naming the positions empty in the value as the author wrote it and how
many of those written levels remain — never how many the entry indexes at, which
this layer cannot state format-neutrally, since the three-level fold runs later
in the back-end that imposes it. The report about a `sort=` reaching past what
it has to sort measures against the same written value, before any empty level
is dropped (added M13). Cross-reference targets are parsed
and validated —
a target naming the mark's own printed levels is reported and dropped, so the
term indexes plainly rather than pointing at itself (corrected M08; neither
side can carry an empty level any more, so the comparison that reconciled the
two spellings is gone — corrected M11) — and the warnings for a malformed mark are
emitted, so a misused mark is diagnosed in every output format, not only where
a back-end exists. One report is the exception, and it is one by construction:
a target that only the LaTeX level fold makes self-referential is judged inside
that back-end, since no other format folds (added M10). Two more judgements
moved there for the same reason: that fold rewrites a target exactly as it
rewrites an entry, and the set a target resolves against is the set of paths
entries print. Where a back-end imposes no ceiling the two sets are one list
and nothing moves (added M18). The pass then branches per format and records
what that back-end will need.

The **Pandoc pass** runs once the whole document has been seen, and is where a
back-end emits anything document-wide. It opens format-neutrally: the placement
marker — an empty top-level div, class `qi-index-here` — is resolved before any
back-end is chosen, so a misused one (nested, duplicate, non-empty, or in a
document with no marks) is diagnosed in every format and no marker survives
into any output. A nested marker that was the only thing in the block list it stood in empties
that place, which is reported — carrying the top-level block position, the
chapter that position was counted over where one is known, and the clause
saying what the position is counted over, and naming nothing else (added M12,
position clause added M28, chapter added M29). A chapter is known only in an
HTML book, the one format Quarto renders a chapter per Pandoc process in; the
duplicate-marker report carries the same chapter on the same terms. Naming
what held it is what the report refuses: Quarto wraps a callout, a tabset and a captioned figure in scaffold
divs no author wrote, so every available name is invented or false, and a
callout holding only a marker still renders its title bar and so is not empty
at all. The count is taken before anything is stripped — the strip runs
bottom-up, so an outer list would look empty by the time it were visited — and
a block list a marker owns is subtracted, because a marker is removed whole at
every depth and is never itself a place an author can find emptied. Counting
that way is what keeps the rule free of per-container code, and so free of the
gap that came with it: a table cell, a footnote body and a definition are block
lists like any other here, where the kind-by-kind check M08 tried reached none
of them.

One further misuse is reported rather than edited away (corrected M08): the marker class written where it cannot place an index — any block that is not a div, and any inline carrying attributes at all, a span, inline code, a link or an image among them — which leaves that element exactly as the author wrote it, class included. It is read from the document's blocks alone, never its metadata, so a class written in the title or the abstract is reported nowhere — and a marker written there is not resolved either, and survives into output (ROADMAP). One shared
function then puts a back-end's index at the surviving marker, or at the end of
the document when there is none, so no back-end can drift apart from another on
where an index goes.

Three back-ends ship:

- **LaTeX** (`FORMAT` containing `latex`, which covers PDF): an `\index{…}`
  command at each mark, `imakeidx` and `\makeindex[intoc]` injected into the
  preamble, one `\printindex` at the marker or, with no marker, after the
  body. A document with a marker loads `imakeidx` with `noautomatic`: printing
  an index mid-document otherwise closes the file the entries are collected
  in, and every mark below the marker is silently lost. Levels are made
  literal per character
  by whichever mechanism that character needs, clamped to makeindex's
  three-level ceiling. The self-target comparison is then run a second time
  against the clamped levels, because the fold can make an entry print a path
  the author never spelled and a target naming that path is a self-reference
  only here (added M10). Every target is put through that same fold before
  either comparison, so what a cross-reference names and what the entry it
  names prints cannot diverge, and a target the fold rewrites is reported once,
  on the mark that wrote it (added M18). A key more than one mark describes
  differently is
  composed into ONE command every mark of it emits — and where any mark of a
  key declares a mention role, that one command carries the per-key
  encapsulation the typeset-time channel below rides on — since makeindex
  refuses to reconcile rival encapsulations on one key and page — it warns at exit 0 and
  writes a correct `.ind`, and Quarto alone fails the render, on a regex over
  that transcript (M15, mechanism corrected M20; D-003 records why repairing
  this sits inside GP2). Where the key
  has a plain locator mark the cross-references go into the entry's printed
  text and the cross-reference marks emit nothing, so a cross-reference still
  carries no locator; where it has none they stay in the encapsulation channel,
  rendered by one command over the key's whole list, because makeindex prints
  its term delimiter either way and a folded entry with no locator would end on
  a dangling comma. Two document-wide reports are drawn: a term marked two
  different ways, and two entries the ceiling folds onto one printed
  level path while their sort keys keep them apart (added M09). A level with a sort key is written in makeindex's own
  `sortkey@printed` form, that `@` being the one the back-end writes and so
  the only one left unquoted (corrected M06). A level carrying a folded
  cross-reference always takes that form, its printed half no longer being the
  entry text alone; the key it is given is the one that level would have filed
  under with nothing folded in, so contesting a key changes what an entry
  prints and never where it files (added M15).
- **HTML** (`FORMAT` containing `html`): a link target for each
  locator-contributing mark, and an index section at the marker or appended,
  built out of
  Pandoc AST nodes so that Pandoc's writer owns escaping (IP2). No level
  ceiling, entries sorted by the filter itself into letter groups introduced
  by `qi-letter` div labels (top level only, never a Header — a heading's
  inlines would be copied into the table of contents), locators and resolvable
  cross-reference targets as links.

  Ids are assigned in the **Pandoc** pass, not at the mark: an id must not
  collide with one the author wrote — ids written in raw HTML included — and
  that is only knowable once the whole document has been seen. The census
  counts the elements carrying each name rather than noting that a name is
  taken (added M079), which is what lets the same pass see a name on two of
  them. A mark keeps an id of the author's own where it is the only element
  carrying that name, and is otherwise tagged by the Span pass and given a
  minted id later. Where something else on the page carries the name, the mark
  yields it and is reported: the other element is the author's and this
  extension renames only its own mark spans, so the mark is the side with a
  minted id to fall back on; between two marks a locator-contributing one
  outranks a cross-reference mark, and between two of a kind the first in
  document order keeps the name (added M079). A cross-reference mark carries an
  id like any other span and yields a contested one the same way, though it
  files no locator that could follow the anchor (corrected M079). The census
  walks the raw HTML rather than pattern-matching it, so an `id=` counts where
  it is an attribute of a tag and nowhere else: one written inside a comment,
  or in a `script` or `style` element's own text, carries nothing on the
  rendered page and contests nothing (added M079). Two marks are outside all of
  this. A front-matter mark of an HTML book chapter stays anchorless per D-048,
  this filter not being able to see which title-block fields Quarto prints; and
  a mark the Span pass never tags — one that indexes nothing — is returned
  untouched, so it keeps a contested name unreported (KI253). The index
  section's own id is minted the same way (corrected M08): the bare `qi-index`
  where that name is free, and a numbered one past it where the document has
  taken it. No anchor id stays inside a heading, because Quarto copies a
  heading's inlines into the table of contents and the id would then appear
  twice; a heading mark's anchor — author id or minted — sits on an empty span
  emitted just after the heading, and an untagged mark's author id moves there
  too, having the same duplicate to avoid (restored M079).
- **EPUB** (`FORMAT` containing `epub`, which covers `epub2` and `epub3`): the
  HTML back-end's index, unchanged (added M52). `builds_ast_index` routes the
  two sites gated on the AST back-ends — the per-mark record in `passes.lua`
  and the back-end branch in `index.lua`, which are what build the index — so
  the same blocks are built and the same ids minted (corrected M55, which retired
  the fold reports the third site used to be). `is_html` stays the
  sole gate on the sidecar store and the chapter-scope wording,
  because Quarto renders an EPUB book in ONE Pandoc process, as it renders a
  PDF one: no chapter file reaches this filter as a chapter, so every declared
  index is built from marks the one process has already seen, and a range
  opened in one chapter and closed in another pairs. Pandoc's EPUB writer then splits the
  document at its top-level headings and rewrites each locator link across the
  resulting XHTML files, so a locator href carries a file part the HTML
  back-end's has only in a book.

Every other format — beamer, revealjs, gfm — takes neither branch: no
index, no anchors, no back-end tokens, and the visible text exactly as
written. What such a format does carry is the mark's own attributes, which
Pandoc passes through on the span as `data-entry`, `data-see`,
`data-see-also`, `data-sort`, `data-mention`, `data-range` and `data-index`
(the last added M38; the enumeration corrected M38); whether that residue should
exist is open (ROADMAP). The mention attribute is spelled `mention` rather than
`role` for this reason and no other: Pandoc data-prefixes a name it does not
know but emits `role` literally, so `role=` would ship an invalid ARIA role on
every marked term (added M20). Corrected M06 — this paragraph previously said "untouched".


**Per-locator styling leaves the encapsulation channel** (added M20, D-007).
An `\index` command cannot say that one of a term's locators is its principal
one: makeindex's conflict predicate is same key, same page, any byte difference
in the encapsulation string, and a filter that runs before typesetting cannot
know which marks will share a page. So the LaTeX back-end gives every locator
mark of a key carrying a principal mention the SAME encapsulation — one per-key
ordinal — which makes the conflict unreachable by construction rather than
merely unexercised, and carries the role on a second channel instead. The
principal mark writes its ordinal and `\thepage` into the `.aux` through
`\protected@write\@auxout`, the mechanism `\@wrindex` uses for the `.idx`, so
the page the registration names and the page the locator names are decided by
one shipout. At `\printindex` the injected preamble splits the entry's page
list and wraps the registered pages, re-applying whatever page-link command it
was handed rather than naming a hyperref internal. Four `\providecommand`
commands are injected, and only into a document that uses them; the emphasis
itself is one of them, so an author redefines it exactly as before. M21 adds
four more to the same block — two emitted beside the `\index` commands, which
write the `.aux` lines, and two the `.aux` itself names, which record the
range's pages — and they ride with the rest rather than being
conditional on a range, because an `.aux` outlives the source that wrote it and
a command it names that is no longer injected fails the render. One
degradation is accepted and documented: makeindex folds three or more
consecutive pages into a range of its own, and a registry lookup on that string
misses, so a principal page anywhere inside a FOLDED range prints plain. A
range the author wrote is not that case — M21 registers its two ends and
composes the very string the index prints, so it is emphasized whole (D-008).

**Book projects** split the HTML back-end in two, and leave the LaTeX one
alone. A PDF book is rendered as one merged document, so its marks are already
in one process; an HTML book renders each chapter separately, so no chapter can
see another's except through what that chapter left behind, or — where what it
left behind cannot be used — through that chapter's own source (added M064).
Each chapter therefore writes what it found — levels,
cross-reference targets, the mention role where a mark declares one, anchor
ids, its own output page — to a sidecar store
under the project's `.quarto/` scratch directory, keyed by chapter source path,
and the chapter carrying a placement marker reads the whole store back in book
order and builds each index that marker places; an index no marker names is
built by the book's LAST chapter, after any index that chapter's own markers
place, provided some chapter of the book places one (corrected M063 — M55 and
M60 gave it to the last chapter that placed an index, a position each chapter
derived from a different mixture of this render's records and the previous
render's). Each record carries the index every mark files in and each
index's own declared sort keys, so every judgement the book makes across its
chapters is made inside one index (D-021); a name the reading chapter does not
declare is a stale record's, and its marks are filed in the first declared
index with the chapter and the name reported. Every chapter still assigns
its anchors, because they are what the index links to. The store is read
through the current chapter list, so a chapter dropped from the book cannot
contribute a stale record; a chapter *rendered* stale can, which makes a full
render the contract for a current index. The chapter list, each chapter's
position, and the paths that make a cross-chapter link come from Quarto's own
metadata (`book.render`, `quarto.doc`, `quarto.project`), never from guesswork
about layout. Whether *this* chapter carries the marker is
known locally and never read back from the store, so a chapter whose own record
failed to write still knows what it is. Nothing about the store may break a
render (IP2): the write is one guarded unit, a record is validated against a
version and a shape before it is read, and every failure costs that chapter's
entries and says so. A record the reading chapter OPENED and could not use —
undecodable, refused for its shape, or written by another version — sends it to
that chapter's source instead: the file is read and parsed inside one guard,
and the marks and placement markers the parse yields join the book's index
(added M064, D-041). A record it could not open at all whose own filename is
among the entries of the directory that record belongs in is the same case, so
one record whose permissions were cleared, and a store directory that has lost
the search bit its records are opened through, recover that chapter rather than
reading as never written (added M068, D-044); the directory itself being there
and unlistable puts every record under it out of reach on that same probe
(added M065, D-043) — every record however deeply nested, since a directory
whose own listing fails takes the answer of the directory above it, and a
chapter written as `sub/two.qmd` keeps its record two failed listings down
(corrected M068, review F1). The listing is remembered per directory, so a render lists
the store once however many records it meets there, and the directory consulted
is the record's own rather than the store's top level, since a chapter in a
subdirectory keeps its record in a matching subdirectory. A file merely NAMED
like a record and unopenable therefore counts as written and is recovered
(KI224). Recovery carries the author's own values
alone — the printed levels, the declared sort keys, the cross-reference
targets that survive the self-target drop and the index each mark files in,
and which indexes the chapter places. The surviving targets are load-bearing:
a mark with one contributes no locator. An id the mark's AUTHOR wrote is one of
their own values and comes back as its anchor, so a recovered locator is the
chapter's page followed by that id; nothing here MINTS one, a minted id being
settled against every id on the finished page, so a recovered mark whose author
wrote none gets the page alone (added M078, D-055). The id is taken from the
blocks walk only: a front-matter mark files the chapter's page with no fragment
on the record route too, that render minting no anchor for it either (D-048,
M071), so the two routes print one row for such a mark whatever id it carries.
No resolved role and no pairing verdict come back, those being conclusions a
chapter reaches about itself (D-009) — so a recovered range's two ends print
that chapter's page, each at its own author id where one was written, and a
principal locator prints unemphasized (corrected M065, which added the declared
sort keys; corrected M078). A record that is simply ABSENT — one whose name no listing of the
directory it belongs in carries — is recovered only in a chapter that can PRINT
an index section: one carrying a placement marker of its own, and the book's
last chapter, which takes on every index no marker names (added M069, D-045).
Both halves are settled from `resolve_markers` and `ctx.position` before the
store is opened, so no two chapters of one render disagree; every other chapter
reads such a record as absent, which is the cost the gate accepts (KI205). A
whole-book render prints the same index — by the time a chapter reads the
store the chapters before it have written their records — so an ordinary first
render of a book whose marker sits in its last chapter recovers nothing, while
one whose marker sits earlier recovers the chapters behind it and reports them
in one line naming each (M074).
The parse is offered only the chapter files this route is a reader
for — `.qmd`, `.md`, `.markdown` and `.Rmd`, compared case-insensitively, a
name carrying no extension refused with the rest — because a book takes an
`.ipynb` chapter too, whose JSON the markdown reader accepts and returns marks
from whose attribute values carry that JSON's own quoting, filed under a name
the book declares nothing by (added M070). It reads an accepted chapter's
METADATA as well as its blocks, and its metadata first, which is the order an
ordinary render reads the two in: a mark written in YAML front matter is
indexed by that chapter's own render, so it is recovered too, and a sort key
declared there beats one declared in the body here exactly as it does there
(added M070); since M071 the render files such a mark exactly as this route
does, one locator to the chapter's page (D-048), where before it filed one
locator per reading Quarto's reflected copies gave it, most into ids the page
did not carry. A placement MARKER written in front matter is not read, because
`resolve_markers` does not read one out of front matter either (KI11).
A mark reaching the chapter through an include shortcode or an
executed cell is not in that parse and is not recovered, and neither is one
inside a block or span carrying Quarto's `.content-visible` or
`.content-hidden` class, which the reader takes out whole — of the front matter
and of the blocks alike — before it reads
anything (D-042, front matter added M070); a source Pandoc's markdown reader
cannot read recovers
nothing, and the reading chapter's own record report says so. Six wordings
carry the outcome (corrected M073): three for a record that was written and
could not be used — recovered, parsed and reaching no mark, unreadable — a
fourth for one no render has written whose source was read back, which never
calls such a record unreadable, a fifth for a chapter whose source this route
does not read, drawn instead of every other whatever state that chapter's
record was in, and so worded to assert nothing about the record (added M070),
and a sixth for one no render has written whose source could not be read
either, which names the record as never written and the source as the one file
it could not read (added M073, D-050). That fifth is drawn at the count of the
wording it stands in for (D-049, M072): where the record came from another
version — which is what a record carrying a `version` this render can read as
a number and does not itself write is read as, and only that (corrected M073,
D-050) — or where no render has written it at all (M074), it is handed to the
report site and drawn there, once per chapter that builds a section and once
by a chapter that builds none whose records show no chapter placing an index;
in the states about a record that WAS there it is drawn where the chapter
met the record, as all four were before. A record decoding to a table whose
`version` is absent, or holds something other than a number, evidences no
version and takes the could-not-be-read wordings — so it is drawn where the
chapter met it, by every chapter that reads the store, and a refused chapter
in that state draws its refusal there too (M073, D-051). Both wordings for a
record no render has written are drawn at that site too, on that same rule and
each once per render, naming every chapter it covers rather than once per
chapter (M074): the reading is gated on a chapter that CAN print a section,
which is not the chapter that does, and a chapter meeting a cold store meets
every other chapter of the book at once. A never-written record whose source
parses to no mark is the one silent outcome: it has lost nothing, and every
chapter of a store-less book that marks nothing would otherwise report on
every render (M069). A REFUSED chapter is outside that silence on every path a
record can fail on, the never-written one included: its source was never read,
so nothing here knows whether it marks a term at all, and guessing that it
marks none would cost its author every term of that chapter with no way to
find out (M070). It reports on each of those paths at the count that path's
own wording follows, so over a record another version wrote a chapter that
builds no section says nothing, exactly as it says nothing about any other
stale record (M072). Five cases are reported rather than guessed at (corrected
M063, which retired two of the seven M061 left): a book whose chapters mark
terms but whose author wrote no marker anywhere (reported by the last chapter,
the only one that can know), a marker in a book that marks nothing, a second
marker chapter (the first in book order builds the index), a marker with
chapters after it (whose entries are one render behind), and a page Quarto
presents as a book chapter without the metadata this needs — which falls back
to indexing that page alone, the pre-M05 defect, and so is never silent. The
two M063 retired were an index no marker names whose section the last placing
chapter did not take on, and that same index taken on by two chapters at once;
the book's last chapter takes the section on wherever the records it read —
recovery included — show any chapter placing an index, so neither can arise
(KI214 is the residual case, narrowed M064 to a record that is absent rather
than unusable). The record fields they read — `adopted`, `unseen`, and M60's
`later` — went with them, and `STORE_VERSION` did not move: a record still
carrying any of them is read as a record without them, so an upgrade costs no
chapter its terms. The store is read once per chapter, before that chapter
writes, with the chapter's own record built in memory and spliced in at its
own position (M061).

Shared between them: the level parse and its empty-level drop, the
cross-reference target parse and its `: ` join, and every warning about the
mark itself except one — the fold-induced self-target, which belongs to the
back-end whose fold creates it (corrected M10).

A cross-reference target naming nothing the marks index is reported from the
same shared layer (M14), and for the same reason: whether a target names an
indexed term depends on what the author wrote and what the document indexes,
not on any back-end, so the report is drawn from the level paths the Pandoc
pass collected rather than from the HTML entry tree — which exists in one
format only. A target resolves against a marked path or any prefix of one,
matching the HTML walk that turns a target into a link — corrected M18: the
report is still drawn in the shared layer and in every format, but the paths it
is drawn from are the ones the running back-end prints, and a target is folded
before it is compared, so where a level ceiling exists the comparison runs in
printed space (D-005). Before that it ran on written paths in every format, and
a LaTeX render of a target spelling a folded path drew this report and the
fold's own self-reference report at once, each contradicting the other, while a
target the fold had moved out from under drew neither. In a book the set is
the whole store's, so a target another chapter indexes resolves; the report is
drawn by the last chapter in book order, the only chapter that has seen every
record, and a render stopping short of it draws none — while a render whose
other chapters have no record yet reports their terms as unindexed, the same
partial-render cost every cross-chapter judgement here carries. A PDF book
takes neither path: it is already one document, so the per-document report is
the right one and says so. The degraded fallback — a page Quarto calls a
chapter without the metadata this needs — draws no dangling report at all,
since every cross-chapter target on it would be reported falsely. The mark's own naming
string travels in its stored record, because the reporting chapter runs in
another process.

`examples/` holds the fixtures; `tests/run-tests.sh` is the acceptance suite,
which renders them and checks each render against hand-derived manifests
(`tests/htmlindex.py` reads rendered HTML structurally for that). Checks that
read the filter's own source read it through `tests/filtersrc.py`, which
enumerates the extension's `.lua` files recursively from one place, so a
definition moving between files stays inside the domain they sweep; each such
check's body is a file under `tests/scans/`, invoked through the suite's
`run_scan`, which is the single place each one's environment and arguments are
written. Under `--self-test` those checks are held to that promise rather than
trusted with it: `tests/movedefs.py` builds a scratch extension with the
definitions relocated into a module, and `tests/plantdefect.py` plants a defect
of the kind each check names, which the check must fail on, naming it.

The documentation's home is `site/`, a Quarto website project (added M40): one
page per topic, each carrying as a heading the text README's `##`/`###` section
carried before the move, and no `output-file:` overrides, so a source path
determines its output path. README is the pointer — pitch, install, a
link to the site, and short Examples and Tests sections.
`site/_extensions` symlinks to the extension, as `examples/_extensions` does.

The site carries an example gallery (added M41). `site/gallery.yml` declares
every `.qmd` directly under `examples/` under `shown:` or `not-shown:`, and
`site/build_gallery.py` is the project's `pre-render` step: it copies each
shown fixture, the extension and the fixture directory's shared assets into
`.gallery-build/` at the REPO ROOT — outside `site/`, so Quarto does not walk
up and render the fixture as a page of the website — renders the copy to a
self-contained `.html` and to `.pdf` there, places both under
`site/gallery/rendered/`, and writes one generated `site/gallery/<name>.qmd`
per fixture carrying that source, a frame around the render and a link to the
PDF. `examples/` is read and never written. The gallery's oracle is the
acceptance suite's own hand-derived index manifests: a table in
`tests/run-tests.sh` names each per-fixture manifest by fixture, kind and
format and writes it out addressably, and `tests/gallerycheck.py` reads that
registry — nothing scans the fixture sources. Because the site build renders
fixtures, it needs a TeX installation: TinyTeX, which carries `makeindex`
(corrected M42 — the site build reaches no further than that; `pdftotext` and
`stix2-otf` are the acceptance suite's own requirements, and the Pages
workflow renders the whole site, PDFs included, with TinyTeX alone). The
whole-set residue sweeps run after the site render, since it is
the last render the suite makes.

The suite pins documentation sentences page by page, each check naming the page
it reads. `check_recipe_block` holds the copyable settings block on the Terms
outside Latin-1 page to the line list `README_RECIPE_LINES` states — equal, in
order, in both directions, and every stated line also in the fixture that proves
the recipe; `check_readme_indexes` holds the named-indexes page's claims and its
copyable YAML block, reading this run's own ledger for the commands that section
shows. One absence check forbids the two retired pre-release sentences over
`git ls-files 'site/*.qmd'` plus README, a domain it enumerates itself and whose
size it reports, and takes an overlay directory so the sentence can be planted
into a tracked page without editing the repo. A `CLAIM_CONTAINERS` registry
stood between eighteen such sentence sets and the pages they were compared
against until M46 retired it (D-027, D-028), taking fourteen of the sets with
it. `tests/sitecheck.py` carries the website's own checks: the render writes a
page for every tracked source; every link the site makes to its own content
resolves — its path part percent-decoded, resolved against files inside the
captured directory in every shape but one, a link naming a directory whose
`index.html` symlinks above the capture, which the containment test does not
reach because `index.html` is appended after it (M46 left that escape open and
withdrew the criterion promising otherwise; the candidate row carries it), and,
where a base path is given, required to carry that segment, since the site is
served under it; README is still the short pointer;
and — for the migration itself, run against the merge base rather than standing
in the suite — every moved heading landed and no prose was lost.

The site is published by `.github/workflows/pages.yml` (added M42), the repo's
only workflow. Its build job runs on every branch: it installs an exactly
pinned Quarto and TinyTeX, renders `site/`, runs `tests/sitecheck.py rendered`
and `tests/pagescheck.py built` over the output, and uploads it as the Pages
artifact. Its deploy job publishes that artifact and is gated on the
repository's default branch, so on any other branch it reports skipped — the
`github-pages` environment refuses a deployment from elsewhere, and a leg that
could only fail there would say nothing about the render. `tests/pagescheck.py`
carries the workflow's own checks: `pin` holds the pinned version against the
`quarto-required` range `_extension.yml` declares, splitting both on `.` and
comparing integer tuples; `built` is the completeness reader the workflow runs
before it uploads, since a render can exit 0 having dropped a gallery page;
`url` derives the published URL from the `origin` remote and requires README,
the site's own entry page and the base path the link check resolves against to
agree with it; and `contains` compares an unpacked Pages artifact against a
reference render. The site is served under the repository's own path segment,
which is why `SITE_BASE_PATH` in `tests/run-tests.sh` is that segment rather
than the empty string M40 left.

## Known issues

What the extension and its acceptance suite do today that a reader should know
about, each naming where it came from — the review that found it, or the
decision or review report that recorded it. Labels are assigned in order and
never reused, so a `cairn/ROADMAP.md` row can point at one and survive a
rewording;
the milestone that closes an issue strikes its entry and rewrites the rows
pointing at it (D-013). A candidate row states the work; the finding lives here.

### The LaTeX back-end

- **KI2.** `\index` inside a moving argument (a section heading) is unprobed,
  and the typeset-time channel puts a second unprotected macro on that path,
  `\quartoindexregister`, whose `\protected@write` would expand inside a
  `.toc`/`.lof` write. — M01 review R17, M20 review round 2 R2-F7
- **KI3.** The filter cannot place the index relative to content Quarto adds
  after filters run: the reference block is appended once the marker has already
  placed the index, so the default order is index first, references after, in
  both back-ends. An author-written empty `#refs` div above the marker settles
  the order instead, which `site/placing-the-index.qmd` and
  `site/latex-and-pdf.qmd` document as the recipe; in HTML that div also costs
  the author the appendix wrapper and the **References** heading Quarto builds
  when it appends the block itself, so the recipe writes its own heading. — M01
  review P2, restored and reworded from M32 review F2/F3; citation corrected
  2026-09-04, the recipe having moved off README at M40
- **KI5.** A registered principal page folded inside a makeindex page range is
  not emphasized: the typeset-time channel D-007 adopts looks a page up by
  string, and a range misses, printing it unemphasized and silently. — RR01
- **KI6.** The engine-and-font recipe the docs site's Terms outside Latin-1
  page names (corrected M40) — xelatex plus a main font loaded by file — is
  proven by a
  typeset-print check for Greek, Cyrillic, and Latin beyond Latin-1 including
  terms written with combining marks. Every other script is unproven under it.
  CJK is unsupported: the font the recipe names does not cover it, and the
  render drops it silently at exit 0. RTL is unsupported and additionally
  unresolved — the text prints unshaped and the comma between an entry and its
  locators lands on the wrong side of the entry, neither of which a covering
  font fixes. The proven set was re-established under STIX Two Text, the font
  the recipe now names (corrected M34; D-018). — M01 review R7/R9, narrowed
  M33 (D-016)

- **KI106.** `\makeindex[name=X]` makes imakeidx write `X.idx`, `X.ilg` and
  `X.ind` named for the index and not the job, so a declared name equal to the
  jobname collides with the default index's files and a stale `.ind` from an
  earlier render is what `\printindex[X]` reads if a later makeindex call
  fails, which would print a WRONG index where D-031's shell-escape failure
  documents an empty one. — M49 review F3
- **KI107.** `passes.lua` emits `\index[<name>]{...}` whenever the format is
  LaTeX-derived while the preamble making that syntax legal rides Quarto's
  preamble channel, so under plain pandoc `-t latex` the `[<name>]` typesets
  into the body where the pre-M49 uniform `\index{...}` was harmless — the
  extension documents no plain-pandoc support anywhere. — M49 review F4

### Entries, levels and sort keys

- **KI7.** Sort-key level paths are keyed on unclamped levels while the LaTeX
  back-end prints clamped ones, so a 4-level entry and a 3-level entry spelling
  the folded form file under two makeindex keys and print twice, in two places,
  identically. The printed-text collision itself predates sort keys. The filter
  does not choose between the two keys — which one the author meant is not
  recoverable from the document — so it reports the pair instead: M09's
  `clamped_paths` registry is keyed on the clamped printed path and warns
  `index entries printed as "…" file under more than one key (…)`, asserted
  message-whole in the suite over `examples/sortkey-clamp.qmd`. The "with no
  report" this entry claimed was written three milestones before that report
  shipped. — M06 review pass 2 F9; corrected 2026-08-28 at a plan gate
- **KI8.** An empty entry tree would render the index as a bare `Index` heading
  with no list and no warning. Unreachable today, and guarded twice over: the
  HTML back-end builds a section only for an index some mark files in, and
  `place_index` emits nothing for an index it holds no blocks for. — M07 review
  F3; second guard recorded 2026-08-28 at a plan gate
- **KI9.** see-also entries keep their locators in both back-ends — M03's gate
  chose LaTeX-aligned no-locator semantics and M15 keeps that semantics for a
  contested key — and the extension prints `see One Way; see Another Way` where
  a printed index would write `see One Way; Another Way`, repeating `\seename`
  per same-kind target. — M03 gate, M15 review

### The HTML back-end and books

- **KI10.** The filter's per-document accumulators are module-level state,
  latent if Lua state is ever reused across documents. A `reset` each module
  owns returns them between documents; a cell added that joins no `reset` is
  unguarded, and D-011 refuses to pin that with a source scan. Four carry more
  than a skewed count. A leaked `pending_xrefs` emits reports naming marks in a
  different file, so it reads as a filter bug rather than a stale number.
  `principal_ordinals` is the first whose value reaches an on-disk artifact, the
  `.aux` registry keys, so a reused state would offset the next document's
  ordinals. `range_at` is the first whose correctness depends on being reset
  mid-document, and `finish_ranges` returns it to the origin while leaving
  `range_items`, `range_found`, `range_pair_found` and `range_verdicts` as the
  first document filled them, so a reused state would pair the second document's
  marks against the first's and report the first's findings again.
  `indexes.lua`'s cells must be settled BEFORE any mark is recorded — every
  other accumulator is keyed by the index a mark files in — which is why
  `indexes.reset` is a `Pandoc` hook taking the document rather than an element
  one, and why it reinstalls the single unnamed index rather than leaving the
  tables empty: a module that acquired an index only once a declaration was read
  would hand a nil key to every accumulator keyed by one. M26's probe resets and
  proves the fifteen cells `tests/stateprobe.py`'s `CELLS` enumerates. The six
  `indexes.lua` resets — `order`, `titles`, `declared`, `language_words`, and
  M56's `doc_labels` and `index_labels` — are outside it:
  `tests/state-pollute.lua` never calls `qi_indexes.read` and no fixture the
  probe drives declares an index, so removing any of the six from `reset` would
  show no difference to compare (KI179). — M01 review R16, widened through M03
  P1, M04, M06 F-a, M09 F6, M14, M17, M20 R2-F14, M23 F8; inventory corrected
  M38; the arrival history and the cell count "19", stale since M56, retired
  2026-09-04 with git holding both
- **KI11.** A placement marker written in YAML `abstract:` survives verbatim
  into the HTML header — filter residue of the IP2 class, since
  `resolve_markers` reads `doc.blocks` alone; the misplaced-class report is
  silent there for the same reason. A book chapter's recovery route matches
  that: `recovered_markers` reads the parsed blocks alone too. A MARK written
  there is a different case and is indexed by both routes (corrected M070). —
  M08 review R4/Q2
- **KI12.** `resolve_markers` rebuilds every Blocks list in every format whether
  or not a marker exists. The LaTeX byte-diff that proved that output-neutral
  was deleted at M16 (D-004), so neither back-end has byte-level evidence for it
  now. — M04 review F12
- **KI13.** Headings consumed by Quarto constructs (callout titles, tabsets)
  bypass the after-heading anchor relocation. No TOC copy today, so no defect;
  the invariant is unpinned against Quarto's own filter ordering. — M03 review
  pass 3 F8
- **KI14.** Locator hrefs into chapter pages cannot be percent-escaped at the
  filter layer: Quarto normalizes a link target either way — verified, the
  filter emitted `later%20chapter.html` and output carried `later chapter.html`,
  matching Quarto's own `./later chapter.html` — so a chapter filename
  containing `#` or `?` yields a broken locator. — M05 review F11
- **KI15.** A mark's attribute values ride into pass-through formats on the span
  itself (`data-see` and its siblings in gfm). Whether that markup residue is
  acceptable is unsettled; M03's AC3 scope note defers it. — M03 review F4/F9
- **KI16.** The book sidecar store is never pruned, so a renamed or removed
  chapter leaves its record forever. Harmless today: reads are filtered by the
  current chapter list and validated against a store version. — M05 review F4
- **KI17.** The store's declared-key map is written in `pairs` order, so an
  identical chapter's record is byte-unstable between renders. Read as a map, so
  no ordering effect. — M06 review pass 2 F11
- **KI18.** A book page rendered but absent from `book.render` (via
  `project: render:`) gets its own per-chapter index rather than contributing to
  the book's. — M05 review F13
- **KI19.** A range spanning two chapters of an HTML book indexes each half on
  its own, and the book reports it. — D-009
- **KI20.** The two range traversals number a mark identically but can still
  derive differently: the collecting pass plans nothing for a mark it derives no
  entry for, and the emitting pass reads the store at that mark's position
  regardless. Unreachable today — both read the same attributes, and only the
  visible text differs between the passes — but M23 changed the failure shape,
  from a verdict handed to the wrong mark (a silently wrong page span) to one
  never consumed (an unmatched range opening, which makeindex logs and Quarto
  fails the render on). — M23 review F7

- **KI115.** `html.lua`'s emitting loop iterates the declared names alone and
  drops a mark group whose key is not one of them with no report —
  unreachable only while every record folds to the reading chapter's default.
  — M38 review round 4, O7

- **KI163.** Pairing by entry cannot tell two overlapping ranges of one term
  apart, so an author-written id is what would separate them and none exists.
  — M20/M21 Scope Out, RR01

- **KI253.** A mark the Span pass leaves untagged — one with no visible text
  and no `entry=`, which indexes nothing — keeps an author-written id another
  element of the page carries, so that name is still on two elements and no
  refusal is reported. Its id is relocated out of a heading, so it is not
  duplicated by the table of contents; what it is not is refused. The mark
  contributes no locator and has no record to mint against, and M079's
  refusal rule reaches only tagged marks. `CHANGELOG.md` and `site/html.qmd`
  both state the exception. — M079 implement gate

### Reports and messages

- **KI21.** No fixture exercises a reported block position where Quarto injects
  a top-level block from an executable cell or from a shortcode other than
  `{{< include >}}`; the include member is covered for the emptied-place report
  by `examples/marker-position.qmd`, and for neither the duplicate-marker
  report nor the book chapter count. What the position is counted over is no
  longer open — the reports say so themselves — so only the un-probed injection
  kinds remain. — M12 review F6, narrowed M28
- **KI83.** No fixture reaches the HTML book path where Quarto supplies too
  little for `book_context` to return a chapter (`index.lua:75-78`), so the two
  marker reports' no-chapter wording is unprobed on the one path where a
  chapter exists and is not known. Producing that state takes metadata Quarto
  does not emit, which is the private-structure modelling M12's gate refused.
  — M29 plan Scope
- **KI84.** `tests/m29book.py` matches a chapter clause as ` of \S+`, so a
  chapter whose filename holds a space would put a genuine marker report in
  neither partition and fail the check for a reason that is not a defect.
  `examples/book-order/` already ships such a filename; the book fixture the
  partition reads does not. — M29 review F8
- **KI85.** Only `book-html.log` carries a total extension-warning count. The
  partition requires exactly one of each marker report, but a repeated one of
  the fixture's other known warnings in `book-pdf.log` or the three
  `misuse-*.log` would pass it unnoticed. — M29 review F11
- **KI23.** The emptied-place reports for a callout, a tabset and a captioned
  figure exist only because Quarto's scaffold wrapping happens to leave the
  marker alone in an inner block list — the private structure M12's gate refused
  to model — so an upstream change would surface as a manifest mismatch reading
  like a regression here. — M12 review F12
- **KI24.** A mark whose `entry=` is all empty levels and whose `sort=` reaches
  past it is told "writes N levels against the M the entry is written with",
  where those M levels print nothing and the mark indexes at one level under its
  visible text. The number is one the author wrote, so D-006 holds, but no
  fixture carries the shape (`entry="!" sort="a!b!c"`) and no check covers it.
  — M19 review F1
- **KI26.** Reader-facing strings the filter emits are hard-coded English —
  four of them, not the two this entry named until now: `Index`, the `Symbols`
  group label, and the `see` and `see also` cross-reference labels
  (`core.lua:24-27`, emitted at `html.lua:296`). HTML and EPUB only: the LaTeX
  back-end emits `\see`, `\seealso` and an untitled `\printindex`, so babel
  supplies all four words per the document's language. Distinct from KI6,
  which is about what an author writes. The policy — D-035, D-036 and D-037 —
  is settled and, since M56-M58, implemented: all four words now resolve
  through an author's `index-labels:` map and then the shipped language table,
  and the English strings are what is left when neither supplies one, which is
  what remains of this entry. — M07 review F6; enumeration corrected 2026-08-28
  from RR02 B1; unimplemented clause corrected M59

- **KI105.** `report_below_marker` reads marker positions off `doc.blocks`
  after `resolve_markers` rebuilt it while the message promises the document as
  received, so an ignored or duplicate marker standing above a named index's
  marker shifts the cited block number down. The comparison is sound, so this
  is a wrong number in a report and never a missed or spurious one, and
  fencing it needs a fixture with an ignored marker above. — M49 review F2

### The acceptance suite: what it reads and what it holds

- **KI27.** The suite hard-depends on git and deletes any ignored file parked
  under `examples/`; neither is recorded as a precondition. — M24 review D14/D15
- **KI28.** `git clean -X` removes and reports only ignored files, so an
  artifact under `examples/` matching no ignore rule escapes both the pre-render
  clean and M24's AC2 assertion. Latent. — M24 review R1
- **KI29.** Nothing asserts which capture a read belongs to, and two captures
  can hold one stem (three `marker.tex`), so a read naming the wrong slug reads
  another render's output. — M24 review D2
- **KI30.** M24's AC2 clean assertion sits outside `run_all_checks`, reaching
  neither the check count nor the run log. — M24 review D3
- **KI31.** The read check exempts any line matching `quarto render` and the
  pairing check treats that phrase in prose as a render, so a comment can
  silence either. — M24 review D5/D11
- **KI32.** Five book captures copy a whole `_book` tree an earlier render
  mostly wrote. — M24 review D7
- **KI33.** The sweep self-test is quadratic in captured pages, about 14,000
  parses. — M24 review D8
- **KI34.** `capture` copies every extension for the render's stem rather than
  what the render produced. — M24 review D9
- **KI35.** The emission sweep's domain includes `.tex` from deliberately-broken
  filters and scratch parity fixtures, and its `ALLOWED` is a written-down slug
  map. — M24 review R2
- **KI36.** `capture` runs inside a command substitution in `m23_render`, where
  its `fail` ends only the subshell. — M24 review R4
- **KI37.** The parity comparison hardcodes the `demo-html` slug. — M24 review R5
- **KI38.** The read check's helper exemption is never exercised. — M24 review R6
- **KI39.** `check_reads` ignores backslash continuations, which `check_pairs`
  follows. — M24 review R7
- **KI40.** Each residue sweep prints two `ok` lines, double-counting in
  `CHECK_COUNT`. — M24 review R8
- **KI41.** The HTML residue plants target the first `<body` textually. — M24
  review R9
- **KI42.** `CAPTURE_CALL` matches the helper's own definition line. — M24
  review R10
- **KI43.** `run-tests.sh:1651` calls `warn-distinct.py --patterns` directly,
  not through `run_scan`, which its header calls the one place saying how each
  scan is invoked. — M25 review F9
- **KI44.** A criterion enumerating scans by `re.search`/`re.match`/`re.findall`
  reaches neither `re.finditer` nor `.count(`/`.split(`, so a scan reading the
  source set through one of those falls outside it. — M25 review F7
- **KI81.** `tests/m28pos.py` matches only the fixture manifest's *reported*
  position against the render; the *author* position it states is held to
  nothing but being a different number, so a manifest naming the wrong author
  position passes. Counting the host file's own top-level blocks is
  mechanically checkable and is not done. — M28 review F2
- **KI82.** The block-position naming clause is written out four times in the
  suite (`run-tests.sh` twice, `tests/m28pos.py` once, `tests/m29book.py` once)
  against one shared string in the filter, so a reword takes four coordinated
  suite edits where the filter takes one. Drift fails loudly in all four, so
  this is cost, not a hole; it is the price of not reading the expectation out
  of the filter's source (D-011). — M28 review F10, count corrected M29

- **KI93.** `tests/sitecheck.py`'s `phrase-absent` duplicates the inline M44
  sweep rather than the M44 sweep routing through it, so two copies of one
  domain each print an ok line naming it. — M52 review F8
- **KI94.** `epubindex.section_rows` is reached by no check and its docstring
  claims a row form manifest 10 does not use. — M52 review F9
- **KI97.** `epubindex.read` raises rather than reporting on a member it cannot
  decode or address. — M52 review F12
- **KI98.** `epubindex.links` would report an external href as unresolved.
  — M52 review F13
- **KI102.** `pdfindex.read`'s `stop` bound drops the whole stop page, so an
  index running onto it loses entries silently and an `absent` cell reads a
  truncated entry identically to a dropped one, which is the distinction
  M49-AC2 exists to make. — M49 review F6
- **KI103.** `editorfixture.check_split` reads its titles from the snippet YAML
  while the row files come from a call site naming the headings separately, so
  nothing ties a row file to the title a failure message names and the plants
  pass row files positionally. — M49 review F7
- **KI104.** `namedpdf.check_reports` splits manifest rows on tab and re-joins
  them, so a row with trailing whitespace fails as "stated, not drawn" rather
  than as a malformed manifest. — M49 review F9
- **KI108.** The marker-less plants read the render's working copy rather than
  the captured artifact, so M24's capture rule is met in letter and not in
  intent. — M32 review R2-F9
- **KI110.** `tests/run-tests.sh` pins `M33_NOENGINE_PRODUCER=LuaTeX`, and
  Quarto 1.4.549 renders PDF through xelatex, so the suite cannot run green on
  M43's floor leg until its engine-dependent checks say which Quarto they are
  about. — M43 plan gate probes
- **KI114.** One `render (floor, 1.4.549)` leg failed and did not reproduce:
  the book's HTML index placed at `sub/two.qmd`'s marker, not `last.qmd`'s,
  leaving `last.html` with nothing to extract, while identical code passed the
  three runs around it. — M52 review
- **KI117.** The `stopped` reading depends on TeX's fatal-error line ending the
  engine log; no capture whose rejection is the log's last `! ` line exists to
  exercise it. — M36
- **KI120.** `%2F%2Fevil.com` is skipped by neither the `//` nor the scheme
  guard and is resolved as a local path, a false report only. — M46 review
- **KI127.** Both sides of the version matrix's fixture-set comparison are
  sets, so two render targets written to one extraction name read as agreement
  while one extraction is silently overwritten. — M48 review
- **KI131.** `DECLARED_EVENTS` in `tests/versioncheck.py` copies the workflow's
  `on:` block by hand and nothing reads the workflow to check it; its refusal
  fires inside `plan`, so a trigger added to the workflow fails `plan` and
  skips `render` and `compare` — the HTML matrix stopping over a PDF-gating
  question. — M51 review F2
- **KI132.** `actions/download-artifact` from v5 on unpacks to the download
  path itself whenever exactly one artifact matches the `pattern`, so a run
  with one leg red lands that leg's files flat in `legs/` and `legs_under`
  finds no `index-<leg>` directory — still red, never a false green, but
  reporting no leg unpacked rather than naming the survivor, and the reader's
  docstring holds only for two or more surviving legs. D-033 and the M53 scope
  block omit this among the bumps' behavior changes. — M53 review F1-F2
- **KI134.** The section-end regex matches one character into a `####`
  heading. — M37 review
- **KI135.** Mutation anchors are matched anywhere in the file. — M37 review
- **KI222.** `m061_mutant` fails a substitution that matched nothing and never
  one that matched more than once, so an anchor gone ambiguous splices every
  match into the filter and passes. The counts file already carries the
  number. The loop is `spliced_copy` since M067, so `m067_mutant`'s copies of
  the test modules inherit the gap. — M066 review F7, M067 review F11
- **KI138.** `check_folded_heading` raises rather than reporting. — M38 review
  round 3
- **KI140.** The gallery's AC4 extracts with plain `pdftotext` where the
  suite's own module documents column interleaving. — M41 review
- **KI144.** The gallery entry comparison discards level and which named index
  printed the entry. — M41 review
- **KI145.** The structural `pending` sweep no longer sees the attribute in a
  comment or in script data. — M41 review
- **KI147.** `.gallery-build/` is left populated. — M41 review
- **KI148.** The gallery's frame and PDF targets are never confined to the
  captured site. — M41 review
- **KI149.** The coupling between `shown:` and the marker sweep's kept-marker
  map is undocumented. — M41 review
- **KI150.** The gallery's shortcode escape is unanchored. — M41 review
- **KI151.** The gallery build carries a dead `has_pdf` parameter. — M41 review
- **KI156.** `text=True` decodes a non-UTF-8 tracked path strictly. — M46
  review F21
- **KI157.** The domain wording in D-027 and in this document's prose stands
  as M46 wrote it, its report clause corrected by D-029. — M46 review F23
- **KI158.** The base-segment comparison runs before `os.path.normpath`, a
  false report only. — M46 review F27
- **KI241.** Three checks sweep what the whole run has accumulated rather than
  a domain they declare: M13's AC5 report scan globs every warning log under
  `$WORK`, M15's untouched-artifact comparison holds the whole capture root to
  a per-file mapping, and M31's stale-`.ind` sweep takes every captured `.tex`
  carrying `\printindex`. Each is a shipped milestone's acceptance criterion,
  and each reads what earlier sections produced, so a run of part of the suite
  either fails them or passes them on an emptier domain than they name. —
  M075 plan
- **KI242.** Around ninety fixed filenames under `$WORK` are written from many
  call sites — `check_index_sections` writes `index-sections.txt` from 69 of
  them and `check_letter_sweep` writes `letter-sweep.txt` from 19 — so no two
  sections can run at once without one overwriting the other's input. — M075
  plan
- **KI243.** `$WORK/one-record.json` is a single backup slot: the M60-AC5 plant
  copies a book's record there before corrupting it, and two later unrelated
  sections restore the original from that one path, so nothing may plant a
  second record while it is held. — M075 plan
- **KI244.** `examples_state` hashes every file under `examples/` and M42-AC5
  holds the listing byte-identical across a render, so anything that writes
  beside a fixture while the run is in flight fails a criterion about
  something else. — M075 plan
- **KI245.** Both nested self-invocations of the suite (`--fixture-check`,
  `--plant-wrapper-defect`) truncate `$RAN_LEDGER`, which is emptied
  unconditionally at startup while the `$WORK` wipe and the pre-render clean
  are guarded against exactly those two modes. Today both `ran_clean` calls
  and M38-AC6's read of the ledger come after both invocations, so nothing is
  lost; a call added before either would be erased with nothing reporting it.
  Latent. — M075 plan
- **KI246.** The fifteen-slowest profile the driver prints sits outside
  `run_all_checks`, after the check count has been taken, so it reaches
  neither `run.log` nor that count and no check reads it — the same shape
  KI30 records for M24's clean assertion. A reader working from the run log
  alone sees no profile. Accepted. — M075 review F3
- **KI247.** The 155 `section '<heading>'` calls put banner heading text into
  executable source, which `tests/suitescan.py`'s read and pairing checks both
  sweep, so a heading naming an artifact under the fixture directory or
  carrying the render command would make those checks report a violation
  against a comment. None of the 155 headings today does. Extends KI31.
  — M075 review F7
- **KI248.** A section's heading is its banner's FIRST comment line, so a
  banner whose sentence wraps names its section by a truncated fragment in the
  timing file and in the profile the run prints. — M075 review F11
- **KI250.** The seconds in `tests/.work/timing.tsv`, and the run total and
  fifteen-slowest figures the driver prints from them, are read by no check:
  M077 removed the clause holding them to the run's own clock (D-054), and
  what remains reads headings only. A row carrying a wrong figure prints as a
  wrong figure with nothing to report it. Accepted. — M077
- **KI251.** A whole run of `tests/run-tests.sh` is not reliably reproducible
  in one attempt on the development machine: Quarto's Deno binary exits 139 on
  a `Segmentation fault: 11` in a render, in a different render each time and
  with no pattern in which. M078's review saw five distinct renders die that
  way across four runs — `M38-AC1`, `M04-AC5`, `M17-AC3`, `M41`/`M40-AC1` —
  and the same crash is recorded in M078's implementation against a sixth,
  `M074-AC3`; every one of those renders passed on a later attempt with
  nothing changed. The suite reports the crash as a render failure, so a red
  run whose ONLY failure is a segfault is toolchain noise and is re-run rather
  than investigated. CI has not shown it. Accepted. — M078 review
- **KI252.** One `pass` line in `tests/run-tests.sh` (the M08-AC2/M10-AC4/
  M11-AC5 line) carries an unescaped backtick pair inside its double-quoted
  message, which the shell reads as an unterminated command substitution: every
  run prints two `command substitution: ... syntax error` lines beside it and
  then the `pass` line with the backticked word gone. The check has already
  decided by then, so nothing is asserted wrongly; what is lost is a word of
  the message and a clean log. The repo's other backticked message escapes
  them, which is the fix. — M079 implement

### The acceptance suite: coverage gaps

- **KI45.** The `\index` scanner is not brace-aware — no longer benign now that
  unbalanced braces are probed. — M01 review R14
- **KI46.** BSD-sed portability is unpinned. — M01 review N12/N13/N14
- **KI47.** A `]{.index` substring undercount. — M04 review F9/F10/F13
- **KI48.** The `include_text` guard is unchecked. — M04 review F9/F10/F13
- **KI49.** There is no structural residue check on LaTeX misuse output. — M04
  review F9/F10/F13
- **KI50.** The check-count baseline is not mechanized. — M01 review, plus a
  clean-clone failure hit at M04 review
- **KI51.** `tests/htmlindex.py`'s `index_section` takes the first heading whose
  text is `Index`, so a fixture carrying its own would silently locate the wrong
  element. — M08 review F10
- **KI52.** Deleting `tests/byte-diff.sh` left no merge-base output comparison
  at all, so a change that moves rendered output outside the roughly 100 checks
  now passes unseen — D-004's own residual risk. D-011 records the second:
  a source-shape regression no render probes. — D-004, D-011
- **KI53.** `tests/pdfindex.py`'s footer heuristic takes the bottom-most
  locator-only line with no check that it sits in the folio band, so a page with
  the folio suppressed loses a genuine continuation's locators. The orphan case
  is now on stderr. — M15 review F4
- **KI54.** Two independent joined-`warn()`-message readers — the M02-AC5
  counter and M15-AC5's — can drift apart. — M15 review
- **KI55.** The moved-definition probe's planted defect exercises only
  `warn-distinct`'s count clause, leaving its single-literal, duplicate and
  prefix clauses unproven against the moving case; and the probe still writes
  every relocated definition into one `modules/moved.lua`, so "a definition
  moved into a module" is a nine-member family the probe exercises one member
  of. — M16 review F7, M17
- **KI56.** M17's AC3 install-parity probe has no planted-defect proof in the
  run: it was shown discriminating out of band at M17 T9, not by a check. — M17
- **KI57.** No check in the suite guards the rule M17-AC1 states, one
  definition per entry point (`one-definition-per-entry-point`), so a later
  hotfix that puts a helper back into `index.lua` leaves
  the run green while the milestone's premise silently reverts.
  `tests/filtersrc.py`'s `lines()` exists for exactly this question and has no
  consumer but the AC3 require-position check. — M17 review F-A
- **KI58.** `tests/scans/warn-distinct.py` cuts each message expression at
  `:format(`, so it reads neither the numbers a message names nor the text built
  there: `depth_phrase`'s two clauses and the extra-sort report's `against`
  clause are built outside the `warn()` call it reads, so they sit outside both
  its pinned literal count and its single-literal needles, held only by the M13
  and M19 rendered-log pins. A report shipping an unlabelled count is therefore
  caught only at its own review. — M19 plan gate, M19 review F3
- **KI59.** The gfm span reader stops at the first `</span>`, so a mark whose
  visible text carried a nested span would be truncated and mismatch rather than
  enumerate. — M20 review round 2 R2-F10
- **KI60.** `book.lua`'s `role` field is written, validated and read with no
  book fixture exercising the round trip. — M20 review round 1 F5, round 2
  R2-F12
- **KI61.** The docs' `\newcommand*` redefinition recipe (in README before M40,
  on the LaTeX and PDF page since) is exercised in one
  header ordering only, where `\providecommand*` would be correct in both and
  `\newcommand*` hard-errors if the extension's definition ever lands first.
  — M20 review round 2 R2-F15
- **KI62.** The pairing-report scope word a merged PDF book prints ("book") has
  no fixture exercising it: every book fixture's PDF render pairs its ranges and
  warns nothing. — M21 review round 5
- **KI63.** `tests/m23probes.py`'s `_ind` tests only that its three expected
  terms are present, and pins neither the entry total nor the `.ilg` line count,
  so a defect that indexed the class-less `range=` span or gave the no-entry
  mark an entry would leave both extents, the makeindex warning count and the
  `(W)` count untouched and pass every AC2 check. — M23 review round 3 F7
- **KI64.** The two range fixtures' opening marks fall on page 1 because the
  prose above them fits one page rather than by an explicit pagebreak, so a
  longer preamble in either silently moves the printed width the readers pin.
  — M23 review round 3 F5
- **KI65.** M24's AC1 read check reaches only a token ending in a literal
  extension, so a read written `examples/<stem>.$var` passes it unseen (five
  such, all repaired in M24), and it matches the fixture directory only where
  that is spelled literally, so a read reaching it through a shell variable
  (`$BOOK_OUT` among them) passes it unseen too (14 such, all repaired in M24).
  — M24, M24 review
- **KI66.** The planted-defect self-test mutates only the `.tex` fixture; no
  HTML index check has a planted-defect proof. — M03 review F14
- **KI67.** Demo manifests have no independent count, so coverage can shrink
  silently. — M01 review P10
- **KI68.** The demo's own makeindex acceptance is never asserted. — M01 review
  P11
- **KI69.** The PDF cross-reference checks assert substring presence, not
  counts, so a cross-reference printed twice would pass; the approach mirrors
  M02's own AC6. M15 asserts counts for its contested keys and leaves the rest.
  — M02 review, M15
- **KI70.** Bare (unquoted) `entry=`, `see=` and `see-also=` values escape both
  the no-leak sweep and the probe-coverage pin; for no-leak this is a false
  pass, not a false failure. The suite's `sort=` extraction is double-quote-only
  too, with no false pass today since every fixture quotes its values. — M01
  review N9, M02 review, M06 review F-b
- **KI71.** The escaping probe covers characters singly; combinations remain an
  untested axis. — M01 review, and M01's own milestone Decisions entry
- **KI89.** `recipe_font_files` reads the recipe's front matter with two fixed
  regexes, so a quoted or multi-word `mainfont:`, a flow-style
  `mainfontoptions:`, or an options block naming no `Extension=` is a mis-parse
  rather than a parse error. Deliberately not widened (checker-regress on an
  input class nobody writes): such a fixture surfaces at `require_recipe_fonts`
  as a `kpsewhich` miss on the filename the guard assembled, and that report
  names the mis-spelled-face reading beside the missing-package one because the
  guard cannot tell the two apart. — M37 F3 disposition

- **KI88.** Two clauses of `tests/unicodeprint.py` have no planted defect and
  are guarded rather than proved: `entries` and `absent` refusing a PDF whose
  index heading printed but whose entry list is empty, and `levelled` refusing
  a printed index one of whose columns holds no top-level entry. Nothing in the
  suite builds an artifact of either shape, so the self-test's pass line claims
  nothing about them and names them as unplanted. — M36 T5
- **KI87.** In a compiled PDF index the entry for `,` prints as one DOUBLE LOW-9
  QUOTATION MARK followed by the page number, so a reader sees `„1` where every
  other entry's shape would give `,, 1` and a reader would want `, 1`:
  makeindex writes the line as `\item ,, \hyperpage{N}`, and in a T1
  text font `,,` is the ligature for that glyph, merging the entry's own comma
  with the index style's delimiter. The entries for `'` and `` ` `` likewise
  print as the right and left single quotation marks, which is what those ASCII
  positions hold in a T1 text font. — M30 T1
- **KI72.** The example corpus's roughly 250 probe `see=`/`see-also=` targets do
  not all name terms the fixture indexes; M14 pins the expected report counts
  instead. — M14 plan gate
- **KI74.** That a registered page actually prints emphasized is exercised only
  by M20's T9 checks and by no acceptance criterion, the criteria set having
  been held rather than widened, so the last leg of that chain has no criterion
  binding it. — M20 amendment gate

- **KI90.** Nothing holds `_extensions/index/_schema.yml` against the attribute
  set the FILTER accepts. `tests/editormeta.py schema` compares it with the
  set the tracked pages under `site/` document, which is the domain D-011
  permits; the filter's own constants are read by no check, so an attribute
  the filter accepts and no page documents can be missing from the schema, and
  one the filter has stopped accepting can stay in it, with the suite green in
  both directions. The plan gate chose this over a scan of the Lua source
  (M50 work log). Found at M50 T1.

- **KI91.** M52-AC2's `<file>`-part arm is not shown to run over a non-empty
  domain, `epubindex.links` falling back to the link's own document, which the
  manifest holds by construction. — M52 review F3
- **KI92.** `epubcheck.cmd_same`'s third comparison cannot fail, both sides
  having been compared equal to the manifest. — M52 review F7
- **KI95.** `cmd_absent`'s two allowed-string guards have never executed, every
  call site passing an empty list. — M52 review F10
- **KI96.** `RENAMED_HEADINGS` is substituted unconditionally, so nothing
  checks the old heading is absent or the new one on the same page, and no
  plant covers a heading actually deleted. — M52 review F11
- **KI99.** `editorfixture.py generate`'s seven refusal clauses have no plant
  at all. — M50 review
- **KI100.** About ten `editormeta.py` clauses have no plant either: the
  empty-object and non-dict snippet files, `prefix`/`body` empty as distinct
  from `description`, a YAML parse failure, a non-mapping top level, a missing
  `classes:`/`attributes:` section, the `attributes:`-side class mismatch, an
  empty per-class attribute block, a missing `enum:`, and `check_bodies`'
  no-attribute guard. — M50 review
- **KI101.** Nothing holds `_extensions/index/_schema.yml` against the Quarto
  Wizard schema it declares, which is the property deciding whether an editor
  reads the file at all — the file conforms today, verified at M50 review
  against the published v1 schema. Distinct from KI90, which is about the
  attribute set the filter accepts. — M50 review
- **KI109.** The HTML-cost check reads "the fixture carries no
  `#quarto-appendix` at all" rather than the bibliography's own wrapper, so a
  fixture that later grows a footnote or a Citation block would turn it red
  while README stays true. — M32 review R2-F14
- **KI111.** M43 compares HTML indexes only, because the M30 and M33 lessons
  put engine and font differences in a PDF's text layer. — M43 Scope Out
- **KI112.** M49's two-index fixture is deferred out of the version matrix, its
  second index depending on TeX's restricted shell escape (D-031). — M51 Scope
  Out
- **KI113.** The version matrix has no EPUB leg, whose render target Pandoc's
  EPUB writer moves with each Quarto version. — M52 plan gate
- **KI118.** Documentation prose is pinned only where a check names its own
  page (D-027, narrowed by D-028), and three of the dropped sets banned a
  sentence rather than required one, so a page may also re-acquire a sentence
  false about today's behavior. — M46
- **KI119.** Three link-check shapes stay unsettled: a bare `/` under a base
  path, percent-decoding of `%3F`/`%23` and of a non-UTF-8 escape, and a
  blockquote stripper that strips a leading `>` from any line, fenced code
  included. — M46 review
- **KI123.** README and `site/index.qmd` promise a description on every class
  where `check_schema` requires one only under `attributes:`. — M50 review
- **KI223.** `form_table` holds `site/syntax.qmd`'s form table to the count
  that page's own sentence states, so a row added together with the sentence
  edited passes; only `check_schema`'s `enum:` comparison remains to notice a
  new row, and it is blind to one on `entry=`, `see=` or `sort=`. — M067
  review F1
- **KI126.** `minted_carried` is an existence test, so a page whose only
  locator points at an anchor it does not carry dumps at exit 0 and a partial
  rename passes. — M48 review
- **KI128.** The version-matrix comparison report's count assertion is derived
  from the same list that produced the files it counts, where it was an
  independent literal. — M48 review
- **KI129.** The anchor clause couples each fixture's dump to that fixture
  carrying a mark, so removing the book's one mark would redden the matrix with
  a false reason. — M48 review
- **KI130.** The M43 plant helper checks exit status, message substring and
  absence of a traceback, but not that the message sits on a `FAIL: ` line.
  — M48 review
- **KI133.** A bound assertion recomputes its bound with the builder's own
  regex. — M37 review
- **KI136.** The loud-failure fixture is hand-written rather than derived.
  — M37 review
- **KI137.** `check_folded_heading`'s section-count clause has a plant that
  fires an unrelated `ValueError` before the count is ever compared. — M38
  review round 3
- **KI139.** `ran_clean` has one unplanted failure clause. — M38 Scope Out
- **KI141.** The gallery's AC5 comparison and several named clauses have no
  plant. — M41 review
- **KI142.** A gallery PDF plant substitutes a whole different document.
  — M41 review
- **KI143.** `rstrip` widens the gallery's AC2 trailing-newline clause. — M41
  review
- **KI146.** A gallery plant helper discards its mutation's exit status. — M41
  review
- **KI152.** The pre-release check's report clause — a `FAIL:` line naming the
  offending file for every tracked page its domain admits — is unheld: a
  non-UTF-8 byte still aborts before printing. The repair ships unpromised.
  — M46 descope amendment, M46 review rounds 1-4
- **KI153.** `tests/sitecheck.py links`' containment clause failed by four
  mechanisms of one shape: unnormalized root-relative path, percent-encoded
  absolute path, symlink inside the capture, and directory `index.html`
  symlinked above it. The repair ships unpromised. — M46 descope amendment,
  M46 review rounds 1-4
- **KI154.** Four clauses of the pre-release sweep are unplanted. — M46 review
  F19
- **KI155.** `FLOOR = 11` stands against a live domain of 21, pinned by
  nothing. — M46 review F20
- **KI159.** A retired-sentence row with an empty sentence reddens the whole
  domain, a fifth unplanted clause. — M46 review F28
- **KI160.** The published URL is derived from the remote by convention, so a
  custom domain would leave README and the site's entry page naming a URL the
  deploy job does not publish to with the suite green. — M42 review
- **KI161.** The artifact containment compares only `.html` and `.pdf`, so an
  upload dropping `site_libs/` would publish an unstyled site and pass, which
  is M42-AC1's own wording. — M42 review
- **KI162.** The publishing workflow's own steps are bound by no standing
  check, D-011 refusing the source-shape scan that would bind them and the
  probe runs being the evidence instead. — M42 review

- **KI164.** M30's typeset print proof is not extended to the cross-reference
  and sort-key probes, which still assert compile-and-accept only. — M30,
  recovered by M54 T3
- **KI249.** `sitecheck.py`'s claim ledger asks only whether a page STATES each
  pinned sentence, never whether a sentence the ledger no longer holds has come
  back, so a claim rewritten rather than added carries no row and a reword back
  to the old wording is green. The sentence M073 review F1 failed on
  (`site/books.qmd:171`) is such a claim. — M074 review N4

### The repo and its packaging

- **KI75.** `examples/.gitignore` duplicates the root ignore's
  `examples/.quarto/` and adds an unrelated `**/*.quarto_ipynb` rule. — M13
  review F16
- **KI76.** The `qi_` prefixes added at M17 took lines over 80 columns from 14
  at that milestone's merge base to 62, of which 47 are code lines whose
  rewrapping risks the single-literal warning messages `warn-distinct` pins.
  — M17 review J
- **KI77.** Every module exports its entire top-level surface — 106 names, with
  `html.lua` exporting 23 where four are reached from outside — so no module
  boundary carries any information about what is API and what is internal.
  — M17 review I
- **KI78.** Windows checkouts without symlink support break
  `examples/_extensions`, and `site/_extensions` since M40. — M01 review R18,
  extended M40
- **KI79.** The Quarto version floor is an untested contract claim; a CI matrix
  at floor and latest is what would fence it. — M01 review R15

- **KI166.** In a book that declares several indexes, a chapter's own pairing
  reports now name the index rather than the chapter — "closes a range this
  index "main" never opens" where they read "this chapter" before. D-021
  requires the index word wherever the judgement's set is one index of several,
  and the pairing scope is a chapter's share of that index, which no single
  scope word carries; an author reading the report is no longer told that the
  scope is one chapter, which is the fact that explains why a range spanning
  two chapters does not pair. Reaching the pair of words takes a second message
  shape and a superseding entry against D-021. — M55
- **KI170.** The duplicate-marker report a book with one namespace draws still
  ends "and a book has a single index". It is drawn only for a book declaring
  nothing or one index, where it is true, but it is now the only sentence in
  the extension still stating it as a general fact. — M55 review F7
- **KI172.** M40's self-test summary `pass` message in `tests/run-tests.sh`
  writes backtick-quoted tokens inside a double-quoted string, so the shell
  runs one as a command substitution: the run log carries
  `line 13996: ..: command not found` and the tokens vanish from the message a
  reader sees. The check itself is unaffected — the substitution is in the
  message, not in the comparison. Found while adding M56's own, which is
  written with single quotes for this reason. — M56 T4

- **KI177.** No check binds the ordering `read` deliberately has: reading
  `index-labels:` before the `indexes:` early returns, so a document that
  declares no index can still set the words. All three M56 fixtures declare
  `indexes:`, so moving that call below the early return turns nothing red.
  — M56 review F4
- **KI178.** The label-form manifest row folds the printed word and the target
  into one space-joined field (`tests/htmlindex.py:541`), and both can contain
  spaces, so a render printing `siehe` in front of `auch Kestrel` yields the
  row a render printing `siehe auch` in front of `Kestrel` yields. The two are
  read independently and lose that independence in the row. Live rather than
  hypothetical since M57: three of the four languages it ships spell `see also`
  as two words, so every non-English manifest it added carries the fold
  (corrected M057). — M56 review F5, M57 review F12
- **KI179.** The state-reuse comment's cell counts ("seventeen", "fourteen")
  are stale after M56 added `doc_labels` and `index_labels`, and more than the
  prose is stale: `tests/state-pollute.lua` never calls `qi_indexes.read`, so
  deleting either new cell from `reset` turns nothing red. In a reused Lua
  state a second document's index would print the first's declared words.
  — M56 review F7
- **KI180.** AC6's `.tex` comparison is proved able to fail by a plant that
  re-implements the comparison inline rather than calling the real check, so
  an inverted condition or swapped paths in the real check would still let the
  self-test print its pass line. Every other M56 plant goes through
  `m56_planted`. — M56 review F9
- **KI181.** Nothing pins the total extension-warning count for
  `examples/index-labels.qmd` in either format — the twin's logs are pinned at
  zero and the misuse needles are pinned absent, but a valid `index-labels:`
  drawing a spurious report, in LaTeX especially where it would not touch the
  `.tex`, passes the whole M56 block. — M56 review F10
- **KI182.** `m56_derive` ends a block at the first blank line, but a blank
  line inside an `index-labels:` map is legal YAML; with one present the
  derivation check fails with "drifted apart" on a fixture pair that is in
  fact correct, naming the wrong cause. — M56 review F12
- **KI183.** The unknown-key and empty-value reports are exercised only at the
  document level: the misuse fixture writes both per-key shapes there and only
  the not-a-map shape per index, so a defect in how those two messages name an
  index goes unseen. — M56 review F14
- **KI184.** `languages.lua`'s `OUTCOMES` table is read by nothing — not the
  module, the suite or the site. Its comment justifies it as what stops a check
  from naming its own outcomes while a fourth goes unexercised, but the suite's
  coverage is `M57_RESOLVER_FIXTURES`, four strings hard-coded in shell with no
  link to it, so adding a fifth outcome to the resolver fails no check. — M57
  review F3
- **KI185.** `well_formed` matches subtags with `%a` and `%w`, against the
  convention `html.lua:69-70` states verbatim: `[A-Za-z]` rather than `%a`,
  whose meaning follows the C locale. Both outcomes print English, so nothing
  visible diverges; the `miss`/`malformed` distinction the module treats as
  load-bearing becomes machine-dependent. — M57 review F4
- **KI186.** `m57_tex_ledger` filters diff headers by prefix, so a differing
  line whose own body is `--` or `++` arrives as `---`/`+++` and is discarded
  unclassified. No LaTeX preamble line has that shape today. — M57 review F5
- **KI187.** `indexes.lua` exports `TITLE_KEY`, which nothing outside the module
  reads — the surface `languages.lua:158-161` argues against in the same diff.
  — M57 review F6
- **KI188.** `label()` consults the language row for whatever key it is handed,
  and `TITLE_KEY`'s string value shares a table with the three label keys. No
  call site passes `"title"` today, so a future printing site adding a `title`
  label key would silently pick up the index heading. — M57 review F7
- **KI189.** No book fixture declares `lang:`. All six language fixtures are
  single documents, so the aggregated book index — several Pandoc processes in
  HTML, one in EPUB — takes no language path in the suite. The Italian row's
  four words are exercised by no fixture at all. — M57 review F2, F11
- **KI190.** `entry_separators` (`tests/htmlindex.py`) reads `item.children`
  where the record builder beside it reads `own_nodes(item)`, which recurses
  through non-list children. A Pandoc version emitting the index list loose,
  wrapping each entry line in a `<p>`, would leave `locators` and `xrefs`
  reading correctly while `separators` came back empty — a failure attributed
  to the extension rather than to the reader. — M58 review F6
- **KI191.** `tests/sepcheck.py` raises `ValueError` on a malformed manifest
  where its own docstring promises a `FAIL:` line and exit 1, so a bad slot
  name or a stray space instead of a tab is reported by `check_separators` as
  a rendering defect, with a traceback where a diagnosis should be. The
  self-test's no-section probe matches its marker inside that traceback. —
  M58 review F7
- **KI192.** `derive_labels_twin` counts the `index-labels:` blocks it deletes,
  never the keys inside them, so M58's AC2 premise — that the block sets
  `separator` and `xref-separator` and no other key — is fenced by nothing: a
  third key added to the fixture's block leaves every check green. — M58
  review F8
- **KI193.** `tests/sepcheck.py`'s `ok` line and the AC1 pass message both say
  "exactly one space" where the check accepts any single whitespace character,
  deliberately, so an HTML writer's newline passes. The docstring states this;
  the two green lines do not, and a U+00A0 after a separator would be reported
  as "exactly one space". — M58 review F11
- **KI194.** Ten of the twelve zero-expectation controls M59 added cannot fail.
  The needles name the index `strata`, `minerals`, `fossils` and entries 5-8 of
  an `indexes:` list, none of which `examples/index-labels.qmd` declares, so no
  filter behavior could put those strings in its log; only the two
  document-level controls discriminate. — M59 review F1
- **KI195.** No planted defect fences the silence half of the letter-clash
  report: neither the zero-count on the message the `fossils` index would draw
  nor the clash render's total of 1 has been shown red. — M59 review F9
- **KI196.** The changelog says the letter-clash report fires for HTML and
  EPUB. The dispatch supports it — `builds_ast_index` is `is_html() or
  is_epub()` — but `examples/index-labels-clash.qmd` is rendered to HTML only,
  so nothing would catch that sentence becoming false. — M59 review F3
- **KI197.** 25 of the 27 entries in `BLANKS` are unexercised by any render;
  only U+00A0 and U+200B reach one. A transposed code point in the list — say
  `\u{2007}` written as `\u{2070}`, a visible glyph — would ship silently.
  — M59 review F6
- **KI205.** A chapter of an HTML book whose record is ABSENT is read as absent
  in every chapter that carries no placement marker and is not the book's last
  — the chapters M069's gate leaves out (D-045). Such a chapter prints no index
  section, so no term is lost from anything it prints; what it costs is that
  its own page's view of the store is one chapter short, which nothing renders
  and nothing reports. A chapter that CAN print a section reads the missing
  chapter's source, so the printed index no longer goes short. Narrowed M063
  from the whole section being lost, M064 from every unreadable record to the
  absent one, M065 from every absent record, M068 from every record behind a
  listing store directory, and M069 from every chapter to the chapters that
  print nothing. — M60 review F11, corrected M061 review F4, narrowed M063,
  narrowed M064, narrowed M065, narrowed M068, narrowed M069
- **KI214.** A book prints no section for an index no marker names where the
  last chapter can read a usable record for none of the chapters that place
  one, and none of those records can be recovered. The proviso on M063's rule
  — some chapter of the book places an index — is `first`, which each chapter
  derives from the records it could read plus its own marker. M064 puts a
  recovered chapter's markers into that derivation, so a held or refused record
  no longer hides a placement marker; what is left is the ABSENT record, which
  recovery does not read — a chapter rendered on its own against a store no
  earlier render wrote, its record's name in no listing (D-043, D-044).
  Narrowed M064 from every unusable record: the two-held-paths arrangement this
  was observed on is M064-AC3, where both renders now print `gamma` in
  `five.html`; narrowed M065 from every absent record, since a store directory
  that is there and cannot be listed now recovers every chapter and so settles
  `first`; narrowed M069, which reads the sources of the chapters no record
  has been written for in exactly the chapter this is about — the book's last —
  so `first` is settled from every chapter's markers whether or not any record
  exists, and what is left is a last chapter whose own source-reading also
  fails, which is the unreadable-source case rather than the absent-record one.
  — M063 AC3 criteria audit, narrowed M064, narrowed M065, narrowed M069
- **KI215.** The two store reports repeat once more than
  `site/books.qmd` states in a book whose fallback set is entirely unmarked.
  The fallback loop sets `builds = true` for every index no marker names,
  including one no chapter marks, so a last chapter whose `mine_marks` is empty
  and which therefore prints no section still opens the `builds or first ==
  nil` gate. Observed 2026-08-30 on a scratch copy of `examples/book-placement/`
  with every `gamma` mark removed and `four.qmd`'s record made stale and
  unwritable: `five.html` carried no index section, and the stale-record report
  was drawn 3 times where two chapters build a section. The class predates
  M063 — a chapter whose marker places only an unmarked index sets `builds`
  the same way — and M063 adds the marker-less last chapter as a new instance.
  Narrowing it needs `marks_in`, which M063 retired with the reports that were
  its only callers. — M063 review F1
- **KI206.** M063-AC3's warning-count assertion expects 6 anchored `(W)`
  matches because Quarto writes a colour-reset escape at the head of the
  write-failure report's line, which `tests/scans/warn-distinct.py`'s
  `^\(W\) ` patterns then miss. Nothing sets or asserts that escape, so an
  uncoloured log makes the count 7 and the check red for a reason that is not
  the extension's. The raw warning-line count asserted beside it is the stable
  half. — M061 review F2, counts corrected M063
- **KI208.** The gate drawing the two store reports from a chapter that builds
  no index section, `builds or first == nil`, reads `first` off the records
  that chapter could read, so it fires in any book whose marker chapter's own
  record is unreadable — not only in a book with no placement marker anywhere.
  A book whose only marker sits in its last chapter, rendered after a version
  bump that makes every record stale, therefore reports each stale record once
  per chapter that read it: 3 reports over 3 chapters, 780 over 40, where the
  pre-M062 gate drew 0 (KI200). Observed 2026-08-30 on a scratch three-chapter
  book built from `examples/book-nomarker/` with a marker added to `two.qmd`.
  — M062 review F1
- **KI209.** `DESIGN.md`'s store paragraph enumerates the cases a book reports
  without stating the counting rule for the two store reports, which is now the
  two-branch rule KI208 names — the one place a reader would meet that rule by
  inspection. — M062 review F8
- **KI210.** M062-AC3's "the marks still print" assertion cannot fail on the
  defect it names: `two.html` renders from `two.qmd`'s own source, so
  `Nomark Three` prints whether or not the planted record is refiled. The
  fixture builds no index section, so it holds nowhere a refiled mark is
  observable. — M062 review F3
- **KI211.** M062-AC3's count of 2 does not separate the shipped
  once-per-reading-chapter rule from the one it replaces: with the report drawn
  from inside `fold_undeclared` the same three-chapter render also gives 2. It
  does catch a revert of the gate to `if builds then`, which gives 0; the
  block's header comment claims the wider separation. — M062 review F4
- **KI212.** M062-AC1's single-chapter run separates no counting rule from
  another — one chapter rendered, one reading, one section built and one book
  all give 1. It is a control; the criterion's text calls it more. — M062
  review F6
- **KI213.** M062-AC3's plant renames each mark's index and leaves
  `record['sorts']` alone, where M062-AC1's plant re-keys the sort map and says
  why. `examples/book-nomarker/` carries no sort keys and the check guards
  none, so the key half of `fold_undeclared`'s rebuild would silently stop
  being covered there if the fixture gained one. — M062 review F7
- **KI204.** `store_write`'s open-failure guard does not stop the write. With
  the record's store path held by a directory, the render logs
  `ERROR ([C]:-1) <path>: Is a directory` — the text `io.open` hands back — and
  then draws its own write-failure report whose stated cause is
  `book.lua:209: attempt to index a nil value (local 'fh')`, the line AFTER the
  guard, so execution passed the guard's `error()` without unwinding. The
  render survives and reports once, so IP2 holds; what the author is shown is
  the second failure rather than the first, beside an ERROR line the extension
  did not mean to print. Observed 2026-08-30 on M061-AC3's render. — M061 T8
- **KI216.** A book chapter that declares `output-file:` in its own front
  matter drops out of the book's index entirely and indexes itself alone.
  `quarto.doc.output_file` for such a chapter is `<project>/<name>.html`
  rather than a path under the project's output directory, so
  `book_context`'s `strip_prefix(output, out)` returns nil, the chapter takes
  the no-metadata fallback, and it writes no record — its terms reach no
  section of the book. Recovery read only a record that was opened and refused
  when this was written; since M069 it also reads one no render has written, so
  a chapter that prints an index section does read such a chapter's source
  (corrected M073 — where that recovered locator points, the chapter's declared
  `output-file:` or the href the book expects, is unverified).
  Observed 2026-08-30 on a scratch copy of `examples/book-placement/` with
  `output-file: custom-four.html` in `four.qmd` and `output-file: bare-two` in
  `two.qmd`: both pages landed in `_book/` under the names their front matter
  asked for, while the filter was told `<project>/custom-four.html` and
  `<project>/bare-two.html`; both chapters drew the looks-like-a-book warning
  and neither wrote a store record. Where a leftover record makes the branch
  reachable, a declared name whose stem carries a dot loses its extension:
  `chapter_href`'s already-has-an-extension test is
  `name:match("[^/]%.[^%./]+$")`, which reads `v1.2` as extensioned, so the
  recovered locator is `v1.2` while Quarto writes `v1.2.html`. Derived by
  reading `book.lua:126`, not observed. — M064 T2 probe, extended M064
  review round 2 R2-F6
- **KI217.** A `STORE_VERSION` bump makes every record in the store unusable at
  once, and every unusable record now costs a re-read and a `pandoc.read` of
  that chapter's source. Each chapter of an n-chapter book reads the n-1
  records that are not its own, so the first whole-book render after such an
  upgrade parses n(n-1) chapter sources — derived from `store_read`'s loop and
  `recover_record`'s call site, not measured. Nothing bounds or caches it and
  nothing names it to an author; the cost is invisible at this repo's fixture
  sizes and unmeasured at book sizes. — M064 review F7
- **KI227.** KI217's sibling for a store that was never written: where no
  record exists at all, each chapter admitted by the recovery gate — a chapter
  carrying a placement marker, and the book's last chapter — parses every one
  of the other n-1 chapter sources, so a book rendered one chapter at a time
  into a store-less tree parses on the order of n(n-1) sources across the run.
  Derived from `store_read`'s loop against `recover_absent` at
  `book.lua:1269`, not measured. Nothing bounds or caches it; invisible at the
  fixture's five chapters and unmeasured at book sizes. — M069 Scope Out, M069
  review F6
- **KI218.** A recovered mark naming an index the book does not declare is
  refiled into the first declared index with nothing said. `recovered_marks`
  resolves the name through `mark_index` before the rebuilt record is handed
  on, so the unknown name is already gone by the time `fold_undeclared` walks
  the records and never reaches the `refiled` list the report is drawn from. A
  stored record in the same position draws that report. The same silent
  refiling is reached without an unknown name: `recovered_marks` resolves
  `index=` against the READING chapter's declarations, and while it now walks
  the recovered chapter's metadata for marks, it never reads that chapter's own
  `indexes:` declarations, so a chapter whose own front matter adds an index has
  that term filed in the book's first one. Derived by reading
  `book.lua:756-759`, not observed. — M064 review F5, extended M064 review
  round 2 R2-F3, corrected M070
- **KI220.** A recovered parse that reaches a placement marker and no mark
  reports only the loss. `store_read` appends the rebuilt record before testing
  `#rebuilt.marks > 0`, so such a chapter's markers still settle `placing` and
  `first` — which is what M064's AC3 arrangement rests on — while the no-marks
  report says only that none of its terms are in the index. An author cannot
  tell from it whether the section moved. Derived by reading `book.lua:955-966`,
  not observed. — M064 review round 2 R2-F5, citation corrected M070
- **KI224.** A file merely NAMED like a record and unopenable is recovered as
  though a render had written it. The listing of the directory a record belongs
  in is the whole of the evidence D-044 rests on, and nothing Pandoc's Lua
  interface exposes separates a broken symlink an author left at a record path
  from a record whose permissions were cleared. Nothing this extension writes
  produces a file of that name it cannot open, so the state arises only where
  something else made it, and its cost is that chapter recovered from its own
  source rather than dropped — the direction D-044 accepts. Declined at the
  M068 plan gate and named in D-044's own consequences. Replaces KI221, which
  M068 fixed. — M068 plan gate
- **KI225.** A broken symlink left at the STORE DIRECTORY path by hand has
  every record path beneath it read as out of reach, so a tree no render ever
  wrote is recovered chapter by chapter and reported. The path fails to list
  and its own name is in the parent directory's listing, which is the whole of
  the evidence D-043 rests on; that answer is handed down to every directory
  below it, so a chapter in a subdirectory is recovered too. Observed
  2026-09-02 on a scratch tree: with `.quarto/quarto-index` a symlink to a name
  that is not there, the probe answers "written" both for a record directly in
  it and for one two directories below. Quarto creates no such link, and the
  cost is a chapter read back from its own source rather than dropped — the
  direction D-044 accepts for the record-file mirror of this case (KI224).
  Carries forward the remainder of KI221, which M068 otherwise fixed.
  — M068 review F5
- **KI226.** Where the store directory does not exist AND `.quarto` itself
  cannot be listed, `store_probe` reads every record path as written, so a
  first render into such a tree would recover every chapter from its source
  and report each one. The `lost` answer a directory takes from its parent
  says only that some ancestor is out of reach; it does not distinguish a
  directory that is missing from one that is there and unreachable, and the
  walk goes above the store as far as the first listable ancestor. Observed
  2026-09-02 by running `store_probe` under `pandoc lua` on a scratch tree:
  with no `.quarto/quarto-index` at all and `.quarto` either a regular file or
  at `a-r`, it answers "written" for records flat, one level down and three
  levels down, where the pre-M068 probe answered "never written". No render
  reaches the state — `quarto render` aborts with `PermissionDenied` on the
  unlistable shape and `Failed to ensure directory exists: expected 'dir', got
  'file'` on the other, both before the extension loads — so the prose in
  `site/books.qmd`, `CHANGELOG.md` and D-044 saying an absent record never
  fires is true of every tree a render can reach and false of the probe read
  alone. Accepted at the M068 merge gate rather than fixed. — M068 review G1, G2
- **KI228.** An ordinary first whole-book render of a book whose placement
  marker sits before its last chapter now reports on itself: every marker
  chapter runs before the chapters behind it, meets their absent records,
  recovers them, and warns "render that chapter again" about chapters that are
  about to render. Nothing is wrong with that render and the second is silent.
  Observed 2026-09-02 in the suite's own `place-first` leg, which moved from 2
  extension warnings to 8, six of them recovery reports; M074 draws one report
  per reading chapter naming every chapter it covers, so the same leg now
  stands at 4, two of them recovery reports, and the render still reports on
  itself (corrected M074). Recorded in D-045's consequences and accepted at the
  M069 merge gate. — M069 review F1
- **KI229.** `recover_absent` answers eligibility, not building, so a chapter
  admitted by the gate that prints no section still parses every other chapter's
  source. The reachable shape is a last chapter carrying no marker in a book
  whose every declared index is placed earlier: `mine` is empty and the fallback
  loop adds nothing, so `builds` is false. `site/books.qmd` and this file
  therefore claim a chapter reads back "only where its terms would otherwise be
  lost from a section this chapter itself prints", which is stronger than the
  gate. The parse is what remains, and its cost is KI227's; same class as KI215,
  second shape at KI240. M074 resolved the report half, moving the reports to the
  site where `builds or first == nil` decides, so such a chapter no longer
  reports each source it read; the `m074-quiet` leg renders exactly this shape
  and holds every never-written wording, the refusal included, at zero. — M069
  review F2, F5; report half resolved M074
- **KI231.** `m069_cold_chapter` does not remove its `_book` before rendering
  while its sibling `m069_tree` does. Benign while `$M061W/base` is created
  with `_book` removed; it would silently let `check_book_sections` read a
  stale `_book` if that changed. — M069 review F8
- **KI235.** A mark written in a chapter's `title:` in an HTML book files
  several locators, all live. Quarto copies the title into the top-level
  `#quarto-navigation-envelope` div ahead of every filter, and that div
  survives into each page's sidebar and page-navigation markup, so every
  page's render reaches the copy as a body mark and mints an anchor for it;
  the tagging pass declasses `#quarto-meta-markdown` alone. Measured
  2026-09-03 (quarto 1.10.18) in a two-chapter book: `Widget`, marked in
  `ch1.qmd`'s title, prints five locators on the index page — two into that
  page's own navigation, `ch1.html`, and two into `ch1.html`'s navigation;
  before M071 the same book printed eight, six into `ch1.html`.
  `tests/fragments.py resolve` passes there, the anchors being real. No
  fixture marks a `title:`; `site/books.qmd` and `CHANGELOG.md` name the
  exception. — M071 review F1
- **KI238.** `m072_only_refusal_names` writes its three intermediate files to
  fixed `$WORK` paths reused by every call, so the diagnostics left after a
  failure describe only the last invocation. Harmless while the suite is
  serial. — M072 review F7
- **KI239.** One refusal sentence, two counts at one report site. The
  never-written refusal is joined into a single line naming every refused
  chapter (`book.lua:1632`), while the version-skewed refusal beside it still
  draws one line per chapter (`book.lua:1611`), so a render meeting two refused
  notebook chapters whose records an older version wrote hears the identical
  sentence twice and one meeting two whose records no render has written hears
  it once. Created by M074, which moved the never-written reports and
  aggregated them; D-053 settles the count for the reports it moved and says
  nothing about the sentence the two paths share. — M074 review F5
- **KI240.** KI229's second shape. A chapter whose placement marker names an
  index some earlier chapter also places has `mine` empty — the earlier marker
  takes the index (D-022) — so `builds` is false while `#marker > 0` admits it
  to the store read: it recovers every never-written source and, since M074,
  says nothing about any of them. KI229 and D-053 name the last-chapter shape
  alone, and the `m074-quiet` leg renders that one. The parse it pays is
  KI227's, as KI229's is. — M074 review F6
