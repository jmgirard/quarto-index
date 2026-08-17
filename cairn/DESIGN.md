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
  provides is best-effort, aided by the sort-key feature once it lands.

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

One Pandoc-Lua filter, `_extensions/index/index.lua`, run as two passes over
each document.

The **Span pass** handles one mark at a time. Everything that depends only on
what the author wrote happens *before* any back-end is chosen: the `entry=`
value is parsed into levels, cross-reference targets are parsed and validated,
and the warnings for a malformed mark are emitted — so a misused mark is
diagnosed in every output format, not only where a back-end exists. The pass
then branches per format and records what that back-end will need.

The **Pandoc pass** runs once the whole document has been seen, and is where a
back-end emits anything document-wide.

Two back-ends ship:

- **LaTeX** (`FORMAT` containing `latex`, which covers PDF): an `\index{…}`
  command at each mark, `imakeidx` and `\makeindex[intoc]` injected into the
  preamble, one `\printindex` appended. Levels are made literal per character
  by whichever mechanism that character needs, clamped to makeindex's
  three-level ceiling, and a term marked two incompatible ways is reported
  document-wide.
- **HTML** (`FORMAT` containing `html`): a link target for each
  locator-contributing mark, and an index section appended, built out of
  Pandoc AST nodes so that Pandoc's writer owns escaping (IP2). No level
  ceiling, entries sorted by the filter itself, locators and resolvable
  cross-reference targets as links.

  Ids are assigned in the **Pandoc** pass, not at the mark: an id must not
  collide with one the author wrote, and that is only knowable once the whole
  document has been seen. A mark reuses an id where one already exists — its
  own, or its enclosing heading's — and is otherwise tagged by the Span pass
  and given a minted id later. Nothing is minted inside a heading, because
  Quarto copies a heading's inlines into the table of contents and the id
  would then appear twice.

Every other format — beamer, revealjs, epub, gfm — takes neither branch and
passes marks through untouched (IP2).

Shared between them: the level parse, the cross-reference target parse and its
`: ` join, and every warning about the mark itself.

`examples/` holds the fixtures; `tests/run-tests.sh` is the acceptance suite,
which renders them and checks each render against hand-derived manifests
(`tests/htmlindex.py` reads rendered HTML structurally for that).

## Known issues

_None._
