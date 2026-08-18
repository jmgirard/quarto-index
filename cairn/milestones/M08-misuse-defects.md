# M08: Reachable mark and marker misuse defects

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** m08-misuse-defects

## Goal

Four author-reachable misuse cases the earlier reviews left latent — a document
claiming the index section's id, a cross-reference pointing at its own entry,
the placement-marker class written where it cannot place an index, and a nested
marker that empties its container — are each reported and handled rather than
silently mishandled.

## Scope

Surface tier: **user-facing** — every deliverable here is either a warning an
author reads or markup an HTML reader receives.

**In:**
- The HTML index section's id is minted past ids already taken in the document,
  as anchor and entry ids already are (`html_index_blocks`, index.lua:1219).
- A cross-reference target equal to the mark's own entry is reported and that
  target dropped, before the back-end branch (`Span`, index.lua:629).
- The marker class on a block that is not a Div, or on an inline span, is
  reported; the element itself is left untouched (`is_marker`, index.lua:1239).
- A nested marker that was its container's only content is reported as having
  left that container empty; the container is kept (`strip_nested_markers`,
  index.lua:1273).
- Fixtures and checks for all four, each shown to fail when its fix is reverted.

**Out:**
- Sort keys registered against unclamped level paths while LaTeX writes clamped
  ones → M09.
- Resetting module-level filter state between documents → candidate row; Quarto
  renders each document in its own process, so it is unreachable today.
- An empty entry tree rendering a bare `Index` heading → candidate row;
  unreachable, every path building the section is gated on a mark.
- Percent-escaping locator hrefs for chapter filenames holding `#` or `?` →
  candidate row; not fixable at the filter layer (M05 review F11).

## Acceptance criteria

- [ ] AC1: In an HTML render of `examples/id-collision.qmd`, whose own elements
      claim the ids `qi-index` (a Pandoc attribute on a Div, never a heading —
      Quarto migrates a heading's id to its wrapper `<section>`), `qi-index-1`,
      `qi-index-2` and `qi-index-3` (a `{=html}` raw block, spelled
      double-quoted, unquoted and uppercase `ID=`) and `qi-index-4` (a `{=html}`
      raw inline, single-quoted): `tests/htmlindex.py`'s scan of every `id`
      attribute in the rendered page reports no `qi-`-prefixed id carried by two
      elements; each of the five claimed ids appears exactly once, on the
      element that claimed it; and the index section, located by the heading
      whose text is `Index`, carries an id distinct from all five.
- [ ] AC2: In a LaTeX, an HTML and a gfm render of `examples/self-xref.qmd`,
      carrying four marks — a single-level `see=` naming its own entry, a
      `see-also=` naming its own two-level `entry=` path, a self-target on a
      mark whose entry comes from its visible text rather than `entry=`, and a
      mark carrying both attributes of which only the `see=` is self-targeting —
      exactly four warnings naming a self-referential target appear per render,
      one per self-targeting attribute. In the LaTeX render the first three
      marks each emit one `\index{}` on their own key carrying no encap, and the
      fourth emits one `\index{}` carrying only its surviving `seealso` encap.
      In the HTML render the first three entries each carry a locator link, the
      fourth carries its cross-reference and no locator, and a scan of every
      locator and cross-reference link inside the index section finds none whose
      href is the id of the entry that contains it.
- [ ] AC3: In a LaTeX, an HTML and a gfm render of `examples/marker-sites.qmd`,
      which writes the marker class on a Header, on an inline span and on a
      fenced code block and holds one real top-level marker, each of the three
      sites is reported exactly once per render by a warning naming that site
      kind, and the index lands at the real marker in the LaTeX and HTML
      renders. In the HTML render all three elements survive carrying the class
      and their content unchanged; in the gfm render their visible content
      survives and no index, anchor or back-end token appears — gfm drops a
      header's attributes itself, so class survival is claimed only of HTML.
- [ ] AC4: In the same three renders of `examples/marker-sites.qmd`, which also
      holds two containers of different kinds (a Div and a blockquote) whose
      only content is a nested placement marker, exactly two warnings per render
      say that removing a marker left its container empty, one per container; no
      index is placed at either container's position; and both containers are
      still present, structurally, in the HTML output.
- [x] AC5: `tests/run-tests.sh --self-test` clean (the `verify` slot).

## Coverage

- AC1 → T4, T5
- AC2 → T6, T7
- AC3 → T1, T2
- AC4 → T1, T3
- AC5 → T1, T4, T6

## Tasks

- [x] T1: Add `examples/marker-sites.qmd` with the three misplaced-class sites
      and the two sole-content nested containers; add the AC3/AC4 checks to
      `tests/run-tests.sh`, failing. A fresh fixture, not an extension of
      `marker-misuse.qmd`: run-tests.sh:2308 pins the duplicate-marker message
      *with its top-level block position*, and :2323 asserts the nested-marker
      warning fires exactly once.
- [x] T2: Report the marker class on any block that is not a Div and on any
      inline span, format-neutrally, naming the site kind; leave the element
      itself untouched.
- [x] T3: Report that stripping a nested marker left its container with no
      content; keep the container.
- [x] T4: Add `examples/id-collision.qmd` with the five id claims; give
      `tests/htmlindex.py` a heading-based index-section lookup (reading the id
      off the `<h1>`'s wrapper `<section>`) and a duplicate-`qi-`-id scan; add
      the AC1 check, failing.
- [x] T5: Mint the HTML index section id against the taken-id table in
      `html_index_blocks`.
- [x] T6: Add `examples/self-xref.qmd` with the four self-reference shapes; add
      the AC2 checks, failing.
- [x] T7: Detect a cross-reference target equal to the mark's own entry levels
      before the back-end branch; warn and drop that target.
- [x] T9: Update README.md for the three new behaviors — the misplaced marker
      class, the emptied container, and the dropped self-reference — and correct
      the sentence at README.md:329 claiming the section id is "fixed rather
      than minted", which AC1 falsifies; pin each new sentence in the suite's
      normative README arrays, since a documented claim owes a test.
- [x] T8: Revert each of the four fixes alone and record the failing check and
      its message in the work log. Process evidence, deliberately mapped to no
      criterion: an acceptance criterion binding the harness rather than the
      emitted output is the instrument-bound shape the plan audit rejected.

## Work log

- 2026-08-18: created by /milestone-plan.
- 2026-08-18: criteria audit ran in FULL mode (user-facing tier), two passes, fresh-context [O] reader; pass 1 returned findings on all five drafts — AC1 self-contradictory (one id string claimed twice could be neither unchanged nor unduplicated), AC2 absence-only and satisfiable by dropping the mark, AC3 an ambiguous count with no residue claim, AC4 leaving the deliverable undetermined, AC5 instrument-bound (deleted) — and pass 2 over the final wording returned AC2 unsatisfiable for the fourth mark (index.lua:720: one \index carries the encap, and no anchor is minted for a mark with an xref), AC3's gfm survival clause false of the writer rather than the filter, T1 breaking run-tests.sh:2308 and :2323, and probe-variety gaps in AC1 and AC4; all disposed in the criteria above, none left to the gate.
- 2026-08-18: plan gate chose warning without editing the element over stripping the misplaced marker class, because the extension otherwise never edits an element the author wrote and the residue is cosmetic; falsified by evidence that the residual class changes rendering or is picked up by styling the extension's own class names invite.
- 2026-08-18: plan gate chose keeping the emptied container and warning over removing it, because deleting a container the author wrote goes beyond removing the marker they asked to be removed; falsified by evidence that an empty container renders as furniture readers read as broken.
- 2026-08-18: plan gate chose warn-and-drop the self-referential target over keeping it (which leaves useless "cats, see cats" output) and over dropping the whole mark (which loses the term, the IP2 corruption class this milestone targets); falsified by an authoring case where a self-target carries meaning, such as a printed form differing from its sort form.
- 2026-08-18: plan chose four defects here with the sort-key clamp as M09 over one five-defect milestone, which reached ~13 tasks past the sizing tripwire; falsified if M09 turns out to share fixtures or code paths with M08 such that splitting duplicates the work.

- 2026-08-18: implement gate — the emptied-container report is additive: the nested-marker message M04 pinned (run-tests.sh:2323) keeps its wording and its check, and the new message names only the extra consequence, so one mistake reads two lines rather than rewriting a pinned contract.
- 2026-08-18: implement gate — a self-target counts as self-referential when it matches what the entry PRINTS, not what it files under, because a reader sees "cats, see cats" whichever sort key the mark carries and the key never appears in the printed index.
- 2026-08-18: minor amendment — added T9 (README + its normative pins). Discovered at T1: README.md documents the marker rules and the cross-reference behavior in prose and README.md:329 states the section id is "fixed rather than minted", which AC1 falsifies; the suite compares named README sentences as bytes, so a documented claim owes a test.
- 2026-08-18: T1 — examples/marker-sites.qmd added (marker class on a heading, an inline span and a fenced code block; a div and a block quote each holding a nested marker as their only content; one real top-level marker with text after it) plus the AC3/AC4 checks. Suite red by design: the first new check reports 0 occurrences of a warning no code emits yet, and every pre-existing check passes.
- 2026-08-18: T2 — report_marker_sites walks the whole document before resolve_markers and reports the marker class on any non-Div block or inline span, naming the site kind (heading / inline span / code block, falling back to the Pandoc type name); the element is never edited. Format-neutral, so it fires in all three formats.
- 2026-08-18: T3 — report_emptied_containers reports, from the shape rather than from walk order, every non-empty block list whose every element is a marker; walk visits contents and never the element itself, so the top-level block is checked directly and its descendants by the walk. Covers Div, block quote, figure and list items, falling back to the type name.
- 2026-08-18: T1's gfm phrase check compared unwrapped text against a wrapped writer's output; the check now collapses whitespace before comparing, the token checks still reading raw source. Suite green: 133 checks.
- 2026-08-18: T4 — examples/id-collision.qmd claims qi-index through qi-index-4 in the five spellings taken_identifiers reads (Pandoc attribute; raw-block double-quoted, unquoted and uppercase ID=; raw-inline single-quoted); htmlindex.py gained index_section (locates the section by its Index heading and returns the wrapper section Quarto puts the id on) and duplicate_ids (prefix-scoped, so Quarto's own furniture is not this milestone's promise). Verified failing first: the render carried qi-index on two elements and the section took a claimed name.
- 2026-08-18: T5 — mint_section_id prefers the bare qi-index and otherwise counts past taken names, so a document with no collision keeps the id it has always had; the fixture's section now mints qi-index-5 and no qi- id is carried twice. Suite green: 135 checks.
- 2026-08-18: T6 — examples/self-xref.qmd carries the four self-reference shapes plus a fifth mark cross-referencing a DIFFERENT entry, the control that tells this check from one dropping every target. Verified failing first: the .tex carried \\index{Cats|see{Cats}}, \\index{Birds!Owls|seealso{Birds: Owls}}, \\index{ferrets|see{ferrets}} and \\index{Dogs|quartoindexseeboth{Dogs}{Pets}}.
- 2026-08-18: T7 — the self-target filter sits after warn_empty_levels and before the back-end branch, comparing levels_key of the target against levels_key of the mark's own levels, so it is format-neutral and compares printed text rather than the filing key. The four reports fire in all three formats; the .tex now carries the three plain keys, Dogs with only its surviving seealso, and Lynxes untouched. Suite green: 138 checks.
- 2026-08-18: T9 — README now states five marker rules (the div-only rule added, the top-level rule extended with the emptied container), documents that a self-referential target is dropped and judged on printed text, and replaces the "fixed rather than minted" section-id sentence with the minting rule. Seven new sentences pinned as bytes in README_MISUSE_CLAIMS and the falsified one in README_MISUSE_STALE. Suite green: 139 checks.
- 2026-08-18: T8 — each fix reverted alone, suite run, first FAIL recorded. T2 removed: "M08-AC3: expected 1 occurrence(s) of <<marker class is written on a heading>> ... got 0". T3 removed: "M08-AC4: expected 2 occurrence(s) of <<was the only content of the>> ... got 0". T5 reverted to the fixed id: "M08-AC1: ids carried by two elements: ['qi-index']; the claimed id 'qi-index' appears 2 time(s), not once; the index section took 'qi-index', a name the document already claimed". T7 reverted: "M08-AC2: expected exactly one \\index{Cats}, found 0; ... a self-referential encap survived: \\index{Cats|see{Cats}}" and seven further clauses. All four fenced; working tree restored clean after each.
- 2026-08-18: completion — tests/run-tests.sh --self-test clean, 153 checks (139 in the plain run). Status to review.
## Decisions

## Review
