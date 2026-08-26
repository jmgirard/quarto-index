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
  format but whose two consumers both sit after the HTML early return, so it is
  only ever read where the back-end folds to one index and has one namespace to
  see. WHICH index a mark files
  in is the running back-end's answer, exactly as the printed path a target is
  judged against is (D-005): a back-end that keeps one index resolves every
  mark to that one and says so per mark and per marker, which is what a
  LaTeX-derived render and an HTML book both do — the first because Quarto's
  PDF loop builds only the main `.idx`, the second because the sidecar store's
  record format carries no index name.
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
  at-your-own-risk (stated in the README), with breaks recorded in the
  changelog. The release line is the promise.

### Guiding

- GP1: **Community-grade, discoverable quality.** Docs, tests, and
  edge-case coverage are commitments user-facing work carries by default;
  README and examples are discovery surface held to extension-listing
  quality.
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

One Pandoc-Lua filter, run as four passes over each document (corrected M06,
M21).
Its entry point is `_extensions/index/index.lua`, which defines the Pandoc pass
and nothing else; every other definition lives in a module beside it under
`_extensions/index/modules/`, loaded with a relative `require("./modules/<name>")`
and bound under a `qi_` name so that no local can shadow a module — `levels`,
`marks` and `marker` are all ordinary local names in this filter (added M17).
The modules, in dependency order:

- `core.lua` — the shared constants, the `warn` channel, and the two format
  tests. It requires nothing; every other module requires it.
- `levels.lua` — what an `entry=`, `see=` or `sort=` value means as a list of
  levels: the parse, the empty-level drop, the three-level clamp, and the
  level path a sort key is declared against.
- `indexes.lua` — the indexes a document declares: the ordered name-to-title
  table read out of `indexes:` metadata, the shape a declared name may be, and
  which index a mark or a placement marker files in, folded to the one index a
  back-end that builds one has (added M38; listed here corrected M38, and
  moved above `sortkeys.lua` M39, which now requires it).
- `sortkeys.lua` — the registry mapping a printed level path to the first sort
  key declared for it, and the report drawn when two marks disagree about it.
- `latex.lua` — the LaTeX back-end: the `\index{...}` argument, the
  encapsulation a cross-reference rides in, and the contested-key bookkeeping
  that decides which shape a key gets.
- `marks.lua` — what every back-end needs from one mark, derived once, and the
  document-wide accumulators the passes share.
- `passes.lua` — the per-document reset and the four Span passes, in the order
  the filter returns them: the reset, then three that only read — one
  registering sort keys, one deciding which keys are contested, one pairing
  page ranges — and the emitting pass that rewrites the mark. The range pass
  carries a document hook as well, since whether an opening is ever closed is
  known only once the whole document has been read.
- `html.lua` — the HTML back-end: the entry tree, its ordering and grouping,
  the anchors that link an entry back to its mark, and the index section built
  out of them.
- `marker.lua` — recognizing the placement marker, reporting its misuse, and
  putting the index where it stood.
- `book.lua` — the per-chapter sidecar store, and the one index the chapter
  carrying the marker builds out of it.

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
the document when there is none, so the two back-ends cannot drift apart on
where an index goes.

Two back-ends ship:

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
  that is only knowable once the whole document has been seen. A mark keeps an
  id of the author's own and is otherwise tagged by the Span pass and given a
  minted id later. The index section's own id is minted the same way (corrected
  M08): the bare `qi-index` where that name is free, and a numbered one past it
  where the document has taken it. No anchor id stays inside a heading, because
  Quarto copies a heading's inlines into the table of contents and the id would
  then appear twice; a heading mark's anchor — author id or minted — sits on an
  empty span emitted just after the heading.

Every other format — beamer, revealjs, epub, gfm — takes neither branch: no
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
see another's. Each chapter therefore writes what it found — levels,
cross-reference targets, the mention role where a mark declares one, anchor
ids, its own output page — to a sidecar store
under the project's `.quarto/` scratch directory, keyed by chapter source path,
and the chapter carrying the placement marker reads the whole store back in
book order and builds the one index the book gets. Every chapter still assigns
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
entries and says so. Five cases are reported rather than guessed at: a book
whose chapters mark terms but whose author wrote no marker anywhere (reported
by the last chapter, the only one that can know), a marker in a book that marks
nothing, a second marker chapter (the first in book order builds the index), a
marker with chapters after it (whose entries are one render behind), and a page
Quarto presents as a book chapter without the metadata this needs — which falls
back to indexing that page alone, the pre-M05 defect, and so is never silent.

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
  after filters run: the reference block is appended once the marker has
  already placed the index, so the default order is index first, references
  after, in both back-ends. An author-written empty `#refs` div above the
  marker settles the order instead, which README documents as the recipe; in
  HTML that div also costs the author the appendix wrapper and the
  **References** heading Quarto builds when it appends the block itself, so
  the recipe writes its own heading. — M01 review P2, restored and reworded
  from M32 review F2/F3
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

### Entries, levels and sort keys

- **KI7.** Sort-key level paths are keyed on unclamped levels while the LaTeX
  back-end prints clamped ones, so a 4-level entry and a 3-level entry spelling
  the folded form collide under two makeindex keys with no report. The
  printed-text collision itself predates sort keys. — M06 review pass 2 F9
- **KI8.** An empty entry tree would render the index as a bare `Index` heading
  with no list and no warning. Unreachable today: every path that builds the
  section is gated on a mark with at least one level. — M07 review F3
- **KI9.** see-also entries keep their locators in both back-ends — M03's gate
  chose LaTeX-aligned no-locator semantics and M15 keeps that semantics for a
  contested key — and the extension prints `see One Way; see Another Way` where
  a printed index would write `see One Way; Another Way`, repeating `\seename`
  per same-kind target. — M03 gate, M15 review

### The HTML back-end and books

- **KI10.** The filter's 19 per-document accumulators are module-level state,
  latent if Lua state is ever reused across documents. `marks_seen` was the
  first (it was `marks_emitted` until M04 made it format-neutral); the HTML
  back-end's `html_marks` was a second until the M03 F1/F2 fix refactored it
  away. The rest arrived one review at a time: `sort_keys`, the sort-key
  registry (M06 F-a); `clamped_paths`, the level-fold collision accumulator
  (M09 F6); `marked_paths` and `pending_xrefs`, the dangling-target report's
  path set and deferred target list (M14) — a leaked `pending_xrefs` emits
  reports naming marks in a different file, so the blast radius is worse than a
  skewed count, reading as a filter bug rather than a stale number;
  `principal_keys`, `principal_ordinals` and `principal_emitted` (M20 R2-F14),
  of which `principal_ordinals` is the first whose value reaches an on-disk
  artifact, the `.aux` registry keys, so a reused state would offset the next
  document's ordinals rather than merely skew a count; and `range_verdicts`
  and `range_at` (M23 F8), which replaced the `range_plan`/`range_cursor` pair.
  `range_at` is the first whose correctness depends on being reset mid-document
  — `finish_ranges` returns it to the origin between the two traversals, so a
  state carried into a second document would number that document's range marks
  from where the first one stopped and hand every one of them another mark's
  verdict; and `finish_ranges` returns that counter to the origin while leaving
  `range_items`, `range_found`, `range_pair_found` and `range_verdicts` as the
  first document filled them, so a reused state would pair the second document's
  marks against the first's and report the first's findings again. M17 made the
  mechanism stronger: the module split moved every one of these out of the
  filter chunk's own locals and into module tables `require` caches in
  `package.loaded`, so a reused state no longer re-initializes them on the next
  execution the way re-running the chunk did. M38 added the last four:
  `indexes.lua`'s `order`, `titles`, `declared` and `folded`, the declared
  indexes and what the running back-end does with them. They are the first that
  must be settled BEFORE any mark is recorded — every other accumulator is
  keyed by the index a mark files in — which is why `indexes.reset` is a
  `Pandoc` hook taking the document rather than an element one, and why it
  reinstalls the single unnamed index rather than leaving the tables empty: a
  module that acquired an index only once a declaration was read would hand a
  nil key to every accumulator keyed by one. The count is what
  `tests/stateprobe.py`'s `CELLS` enumerates plus those four; the prose above
  is a history of how they arrived and names neither `contested_keys` nor them,
  which is what made the older "17" wrong in both directions. M26's probe
  resets and proves 15 of the 19: the four `indexes.lua` cells are reset per
  document but are outside the probe's enumeration, and the fixtures it drives
  declare no indexes, so a removed reset for them would show no difference to
  compare. A cell added after M26 that joins no `reset` is unguarded, and D-011
  refuses to pin that with a source scan. — M01 review R16, widened through
  M03 P1, M04, M06 F-a, M09 F6, M14, M17, M20 R2-F14, M23 F8; inventory
  corrected M38
- **KI11.** A marker written in YAML `abstract:` survives verbatim into the HTML
  header — filter residue of the IP2 class, since `resolve_markers` reads
  `doc.blocks` alone; the misplaced-class report is silent there for the same
  reason. — M08 review R4/Q2
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
- **KI26.** Reader-facing strings the filter emits are hard-coded English
  (`Index`, and the `Symbols` group label) with no `lang` policy in this
  document. Distinct from KI6, which is about what an author writes. — M07
  review F6

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
- **KI61.** README's `\newcommand*` redefinition recipe is exercised in one
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
- **KI73.** The README claim pins and the filter's warning literals are two
  hand-maintained copies of the same strings, and the claim check asserts a
  string is in README, never that the filter emits it. — M13 review F20
- **KI74.** That a registered page actually prints emphasized is exercised only
  by M20's T9 checks and by no acceptance criterion, the criteria set having
  been held rather than widened, so the last leg of that chain has no criterion
  binding it. — M20 amendment gate

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
  `examples/_extensions`. — M01 review R18
- **KI79.** The Quarto version floor is an untested contract claim; a CI matrix
  at floor and latest is what would fence it. — M01 review R15
