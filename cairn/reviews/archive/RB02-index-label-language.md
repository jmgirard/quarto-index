# RB02: The language of the words the index back-end picks itself (no milestone yet)

- **Date:** 2026-08-28
- **Output required:** write findings to `cairn/reviews/RR02-index-label-language.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`quarto-index` is a Quarto extension: one Pandoc-Lua filter that turns inline
index marks in a `.qmd` source into a back-of-book index. It has three
back-ends. The LaTeX back-end emits `\index{...}` commands and lets
`imakeidx`/`makeindex` build the index. The HTML back-end builds the index
itself, as Pandoc blocks. The EPUB back-end is the HTML one — `builds_ast_index()`
in `core.lua` covers both — so anything decided here lands in EPUB too.

The extension released 0.1.0 on 2026-08-26.

**The problem.** Three of the words a reader sees in an HTML or EPUB index are
words the filter chose, not words the author wrote:

- `Symbols` — the heading of the group holding every top-level entry that does
  not file under an ASCII letter. Entries are grouped `Symbols`, then `A`
  through `Z`.
- `see` and `see also` — the italicized labels printed before a
  cross-reference target, e.g. *see* Birds.

All three are hard-coded English. The LaTeX back-end has the same three jobs
and hard-codes none of them: it emits `\see{...}` and `\seealso{...}`, whose
printed words come from LaTeX's `\seename` and `\alsoname`, which `babel`
redefines per the document's language; and `\printindex` heads the section
with `\indexname`, likewise babel's. So one back-end of this extension already
follows the document's language and the other two never can.

A fourth string, the index section's own heading, is a partial exception. In
HTML/EPUB it defaults to `Index` but an author can already override it
per-index (see Materials). In LaTeX it is `\indexname`. So the heading is
configurable-but-English-by-default in one back-end and language-following in
the other.

This is recorded as known issue KI26 in `cairn/DESIGN.md`. A plan gate on
2026-08-28 put two approaches to the maintainer — (a) author-declared strings
only, with English shipped as the default and the document's declared language
never read; (b) read the document's `lang:` against a translation table the
extension ships, with an author override still available — and the maintainer
chose to escalate the question here rather than pick.

**Why it needs independent review.** The extension is past its first tagged
release, and IP3 (below) makes any documented syntax form changeable only
through a deprecation cycle. Whatever metadata field names this introduces are
effectively permanent. The choice also sets a precedent for every future
reader-facing string the filter might emit.

## Materials

Read these, in the repo root:

- `cairn/DESIGN.md` — read the whole `## Design Principles` section (the IP and
  GP list quoted in Constraints below), the `## Purpose & Scope` and
  `## Contract boundary` sections, and the `KI26` entry under
  `## Known issues` → `### Reports and messages`.
- `_extensions/index/modules/html.lua` — line 45 defines `SYMBOLS_LABEL`;
  lines 20–75 are the normative collation rule and the group-label/group-rank
  functions that consume it; line 296 is where a cross-reference label is
  emitted (`pandoc.Emph(literal_inlines(xref.kind.label))`); lines 557–575 are
  `html_index_blocks`, which heads each index section.
- `_extensions/index/modules/core.lua` — lines 24–33 define `XREF_KINDS`, the
  table carrying each cross-reference kind's attribute name, its LaTeX command,
  and its English `label`.
- `_extensions/index/modules/latex.lua` — lines 300–312 and 370–380, where the
  same `XREF_KINDS` rows are emitted as `\see`/`\seealso` instead.
- `_extensions/index/modules/indexes.lua` — lines 20–30 (`INDEXES_KEY`,
  `NAME_FIELD`, `TITLE_FIELD`, `DEFAULT_TITLE`), lines 80–116
  (`read_declaration`, which parses one index declaration and reports every
  unusable shape), lines 120–155 (`read`), and lines 179–186 (`title`).
- `site/letter-groups.qmd` and `site/cross-references.qmd` — the two
  documentation pages a reader learns these words from.
- `examples/letter-groups.qmd` and `examples/resolving-xref.qmd` — fixtures
  that exercise the group headings and the cross-reference labels.

The existing per-index declaration syntax, which any new field would join,
is written in a document's YAML metadata like this:

    indexes:
      - name: authors
        title: Index of Authors
      - name: subjects
        title: Index of Subjects

A document that writes no `indexes:` key has exactly one index, headed `Index`.

**Two facts established by probe on this machine on 2026-08-28**, which you
should re-run rather than take on trust (pandoc 3.10.2):

1. Pandoc ships translation data files carrying exactly the strings at issue.
   `pandoc --print-default-data-file=translations/fr.yaml` returns a YAML map
   including `Index: Index`, `See: Voir`, `SeeAlso: Voir aussi`. The same keys
   are present for at least de, es, it, pl, ja, nl, pt, ru, sv, tr, ar, he, cs,
   da, fi and nb. Coverage is uneven: `ko.yaml` carries `Index` but neither
   `See` nor `SeeAlso`. No language file carries anything corresponding to
   `Symbols`.
2. That table is **not reachable from a Lua filter**. `pandoc.translations` is
   nil, and no key of the `pandoc` module in pandoc 3.10.2 exposes it; the
   probe enumerating `pairs(pandoc)` lists `cli format image json layout log
   mediabag path pipe read readers scaffolding sha1 structure system template
   text types utils walk_block walk_inline with_state write write_classic
   writers zip` and no translations entry. A filter wanting those strings would
   have to vendor them or shell out.

The repository is MIT-licensed (`LICENSE`). Pandoc is GPL-2-or-later.

## Questions

1. Which approach should this extension take: (a) author-declared strings only,
   English shipped as the default, the document's `lang:` never read; (b) read
   `lang:` against a table the extension ships, author override available;
   or (c) neither — keep the English strings, document the limitation, and add
   no metadata surface at all? Weigh the asymmetry with the LaTeX back-end
   (which already localizes via babel and cost the author nothing to get) and
   the principles in Constraints. Name the option you would ship and the
   strongest argument against it.

2. If a table is warranted: where should its content come from? Pandoc's
   `translations/*.yaml` files are the obvious source and carry `See`,
   `SeeAlso` and `Index`, but are unreachable from a Lua filter at runtime
   (Materials fact 2), so using them means vendoring a copy into an MIT repo
   from a GPL-2+ project, or shelling out to `pandoc
   --print-default-data-file` through `pandoc.pipe` on every render. Assess
   both against GP3, and say whether either is acceptable. If neither is,
   does that settle question 1 against option (b)?

3. `Symbols` has no upstream source at all — no pandoc translation key, and
   `makeindex`'s own index styles do not group entries by letter, so the
   grouping and its heading are this extension's invention. Is `Symbols`
   therefore different in kind from `see`/`see also` — a name for a mechanism
   rather than a translatable term — and should it be handled differently from
   them, or does treating the three alike matter more?

4. If new metadata fields are added, what should they be called and what shape
   should they take? The plan gate settled that they sit beside `title:` in the
   per-index `indexes:` list, one set per index; flag disagreement with that
   explicitly rather than working around it. The candidate spelling is three
   flat fields — `symbols:`, `see:`, `see-also:` — chosen so the two
   cross-reference field names match the mark attribute names `see=` and
   `see-also=` that authors already write. Consider instead a nested map (e.g.
   `labels:` holding the three), and say which leaves more room for a fourth
   reader-facing string later without a deprecation cycle. These names are a
   one-way door under IP3.

5. Should the HTML/EPUB index section heading — today `Index` by default, and
   already overridable per index via `title:` — change at all under whichever
   approach you recommend? Specifically: if `lang:` is read for `see`/`see
   also`, does consistency demand it be read for the heading too, superseding
   the existing English default for a document that declares no `title:`; and
   would that be a behavior change to an already-released default that IP3's
   deprecation cycle governs?

6. Is there any shape in which the two back-ends genuinely agree, rather than
   each merely being separately configurable — for instance the HTML back-end
   deriving what the document's babel setup would print? Assess feasibility
   honestly; if the answer is no, say so plainly, because a clear "these two
   back-ends will always be configured separately" is itself a useful finding
   for the documentation this work will write.

## Constraints

Fixed, and not to be relitigated — flag disagreement explicitly rather than
silently working around it:

- **IP1 (Format-neutral marking).** The index-mark syntax and all attribute
  values carry format-neutral meaning; back-ends realize them per format. A
  mark value is never raw back-end code (D-001). A feature's semantics must be
  format-neutral even when only one back-end realizes it yet.
- **IP2 (Never break the document).** A document using this extension never
  fails to render and never silently corrupts output because of a marked term.
- **IP3 (Post-release syntax stability).** From the first tagged release
  onward — 0.1.0, 2026-08-26 — documented syntax forms change only via a
  deprecation cycle.
- **GP2 (The contract ends at correct emitted output).** Per format, the job is
  correct output; whether the user's toolchain then builds the index is a
  documentation surface, never detected or managed.
- **GP3 (Pure Pandoc-Lua, self-contained).** Zero runtime dependencies beyond
  Quarto; `quarto add` is the entire install story.
- **GP4 (Zero-config defaults).** The common case works with no configuration;
  options are added compatibly for the uncommon case, never required for the
  common one.
- **GP5 (Minimal API surface).** Prefer one composable mechanism over parallel
  syntaxes; a new syntax form must express something the existing mechanism
  cannot.
- **D-013.** A finding about the extension's current behavior is a known-issue
  record, not a backlog row. If you find further live defects here, state them
  as findings; do not propose backlog mechanics for them.

Not fixed, and open to your disagreement: the plan gate's answer to question 4
about where the fields live, and the maintainer's framing of the choice as
(a)-versus-(b), which question 1 deliberately reopens with a third option.

## Output format

In `RR02-index-label-language.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under "Beyond
the brief"; end with concrete recommendations, each marked apply / consider /
reject-with-reason. Your report is advisory: this brief's header slot says
`not requested`, so emit no `## Binding criteria` section.
