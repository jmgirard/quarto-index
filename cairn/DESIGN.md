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
- **Collation is best-effort**: non-ASCII terms appearing correctly is an IP2
  commitment, but sort *order* beyond what the user's index processor
  provides is best-effort. Sort keys (`sort=`) are how an author overrides it,
  and each back-end orders under its own rules (corrected M06). The HTML
  back-end ranks its top-level entries into letter groups — Symbols, then
  A–Z — before collating within a group; only ASCII letters make a letter
  group, which is honest about a collation that only folds ASCII (corrected
  M07).

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
  term: any characters in a visible term appear correctly in the index
  (non-ASCII included), and formats without an index back-end pass the
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

One Pandoc-Lua filter, `_extensions/index/index.lua`, run as three passes over
each document (corrected M06).

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
that back-end, since no other format folds (added M10).
then branches per format and records what that back-end will need.

The **Pandoc pass** runs once the whole document has been seen, and is where a
back-end emits anything document-wide. It opens format-neutrally: the placement
marker — an empty top-level div, class `qi-index-here` — is resolved before any
back-end is chosen, so a misused one (nested, duplicate, non-empty, or in a
document with no marks) is diagnosed in every format and no marker survives
into any output. A nested marker that was the only thing in the block list it stood in empties
that place, which is reported — carrying the marker's top-level block position
and naming nothing else (added M12). Naming what held it is what the report
refuses: Quarto wraps a callout, a tabset and a captioned figure in scaffold
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
  only here (added M10). A key more than one mark describes differently is
  composed into ONE command every mark of it emits, since makeindex rejects
  rival encapsulations on one key and page and Quarto turns that into a failed
  render (M15; D-003 records why repairing this sits inside GP2). Where the key
  has a plain locator mark the cross-references go into the entry's printed
  text and the cross-reference marks emit nothing, so a cross-reference still
  carries no locator; where it has none they stay in the encapsulation channel,
  rendered by one command over the key's whole list, because makeindex prints
  its term delimiter either way and a folded entry with no locator would end on
  a dangling comma. Two document-wide reports are drawn: a term marked two
  different ways, and two entries the ceiling folds onto one printed
  level path while their sort keys keep them apart (added M09). A level with a sort key is written in makeindex's own
  `sortkey@printed` form, that `@` being the one the back-end writes and so
  the only one left unquoted (corrected M06).
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
`data-see-also` and `data-sort`; whether that residue should exist is open
(ROADMAP). Corrected M06 — this paragraph previously said "untouched".

**Book projects** split the HTML back-end in two, and leave the LaTeX one
alone. A PDF book is rendered as one merged document, so its marks are already
in one process; an HTML book renders each chapter separately, so no chapter can
see another's. Each chapter therefore writes what it found — levels,
cross-reference targets, anchor ids, its own output page — to a sidecar store
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
matching the HTML walk that turns a target into a link. In a book the set is
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
(`tests/htmlindex.py` reads rendered HTML structurally for that).

## Known issues

_None._
