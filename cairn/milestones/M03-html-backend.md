# M03: HTML index back-end

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M02
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP4, GP6
- **Branch/PR:** m03-html-backend · https://github.com/jmgirard/quarto-index/pull/3

## Goal

Realize the existing format-neutral marks in single-document HTML output: an
auto-appended index section with linked locators and cross-references.

## Scope

Surface tier: **user-facing** — a new back-end for extension users (full
criteria audit applied).

**In:**
- HTML output (`FORMAT` matching `html` only; revealjs/epub stay pass-through)
  gets an anchor at each locator-contributing mark site and one auto-appended
  index section at the end of the body (GP4 zero-config), identified by a
  pinned section id, with an unnumbered "Index" heading that enters the TOC.
- The section is built from Pandoc AST nodes, never raw HTML strings (IP2:
  Pandoc's writer owns escaping). No CSS is injected; nested lists render
  under Quarto's defaults.
- Locators are numbered links (1, 2, 3 in document order) to the anchors.
  Cross-reference marks contribute no locator (gate: match LaTeX semantics).
- Entries sort by the normative collation rule: ASCII-lowercase fold, then
  codepoint order, ties by codepoint (DESIGN best-effort collation).
- Sub-entries nest at every depth — no level ceiling in HTML; the 3-level
  clamp and its fold warning are makeindex properties and stay LaTeX-only.
- `see`/`see also` render with M02 target semantics (levels join `: `),
  hyperlinked when the target key exists in the index (matched on parsed
  level lists, never rendered strings), plain text otherwise.
- Entry-parse warnings that are genuinely format-neutral (empty level,
  reworded to name no back-end) move before the back-end branch — absorbs the
  ROADMAP candidate from M01 review R19. The clash report stays LaTeX-only.

**Out:**
- Multi-file book aggregation → existing candidate row.
- Explicit placement option → existing candidate row (GP5; M01 rationale).
- Letter-group headings → new candidate row (needs diacritic folding; sort keys).
- see-also entries keeping locators (print convention) → new candidate row
  (a cross-format decision, taken for both back-ends at once).
- epub/revealjs back-ends, CSS styling, non-Latin collation → not planned;
  candidates when demanded.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh --self-test` passes, every M01/M02 check
      keeping its meaning but for two owned exceptions: the no-leak block is
      retargeted (AC3) and the xref-conflict clash rationale is reworded (the
      clash stays LaTeX-only, being a makeindex property). As one-shot review
      evidence, never a checked-in snapshot: `examples/demo.qmd --to latex` on
      the branch is byte-identical to the same render at the merge-base, one
      machine.
- [ ] AC2: `examples/demo.qmd --to html` yields exactly one generated index
      section (pinned id), whose entries match a hand-derived manifest
      row-for-row — text, depth, order under the normative collation rule,
      per-entry locator count — exhaustively: a rendered entry absent from the
      manifest fails. Latin-1 rows (café naïve; Grüße → Straße) pin IP2's
      non-ASCII clause. The same discipline covers a placement fixture whose
      repeated entry is marked in a heading, a table cell and a footnote,
      pinning locator numbering where the renderer relocates content. The
      visible-terms manifest rows are unchanged; its extraction is retargeted
      (attribute-order-proof, scoped outside the generated section).
- [ ] AC3: In demo.html every locator-contributing mark emits exactly one
      anchor — an id the author wrote, its enclosing heading's id, or a minted
      id in the pinned scheme — document-unique; every href inside the index
      section resolves to an id in the same file; the anchor count is pinned
      to a source-derived mark count, and every fixture invariant that count
      rests on is asserted and named in the check's failure message, so a
      violated invariant reports itself rather than surfacing as a bare count
      mismatch. Those same three properties hold for `examples/placement.qmd`
      (a mark in a heading under `toc: true`) and `examples/html-index.qmd`
      (marks carrying ids inside the minted namespace) — the shapes demo.qmd's
      invariants exclude. The reworked no-leak check passes: every
      `entry=`/`see=`/`see-also=` value is absent from the rendered
      document's text, index section excised, compared in a single layer — the
      value against the decoded text a reader would see — so a value
      containing `&`, `<`, `>` or `"` cannot slip past by being escaped in the
      render; the source-pinned completeness check is retained. Scope: rendered HTML text only — Pandoc
      carries attribute values on the span itself, and whether that markup
      residue is acceptable in pass-through formats is tracked separately.
- [ ] AC4: Cross-reference entries in generated HTML indexes render with M02
      target semantics, labelled see/see also, hyperlinked exactly when the
      target key exists (parsed-level-list match) and plain otherwise; the
      linked, unlinked and colliding-string cases are fixture-present and
      manifest-checked, as are a repeated target (one cross-reference) and two
      level-list-distinct targets on one key that print alike (both kept). No
      cross-reference mark contributes a locator, fenced by AC2's exhaustive
      locator counts.
- [ ] AC5: `examples/escaping.qmd --to html`: for every printable ASCII
      character except space (the fixture's by-construction domain, pinned by
      the existing coverage check), the set of entry texts extracted from the
      generated index by an HTML-parsing check contains that character as an
      exact element.
- [ ] AC6: Negatives: `examples/control.qmd --to html` has no generated
      section and no anchor-scheme id; `examples/demo.qmd --to gfm` renders
      clean with no index section or anchor artifacts, the newly
      format-neutral warnings still reaching its author while the makeindex
      level-ceiling warning reaches neither gfm nor HTML; the beamer checks
      pass.
- [ ] AC7: README documents the HTML back-end, grep-pinned in the suite
      SUPPORTED_FORMS-style: the three stale pass-through sentences are gone,
      a beamer-scoped pass-through sentence is present, and every row of the
      enumerated back-end divergence list appears.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T4, T5, T9, T12
- AC3 → T1, T5, T9, T10, T11, T12
- AC4 → T3, T6, T8
- AC5 → T5
- AC6 → T5, T10
- AC7 → T7, T11, T12

## Tasks

- [x] T1: Span pass — format-neutral warnings before the back-end branch,
      clamp+fold LaTeX-only, HTML branch recording marks; `html` match only.
- [x] T2: HTML Pandoc pass — index section from AST nodes: pinned section id,
      unnumbered TOC heading, collation, unlimited nesting, locator links.
- [x] T3: HTML cross-references — labels, parsed-level-list target matching,
      links, no locator; xref-conflict rationale reworded.
- [x] T4: Placement fixture (heading / table cell / footnote) + manifest.
- [x] T5: Suite rework — retargeted visible-terms extraction, no-leak scoped
      outside the index, HTML manifests, href resolution, anchor counts,
      escaping-probe HTML check, gfm + control negatives, merge-base procedure.
- [x] T6: xref-conflict gains linked-target and colliding-string cases +
      manifest.
- [x] T7: README HTML section with suite grep pins; DESIGN Architecture.
- [x] T8: Review F3 — dedupe cross-references on level lists, not the joined
      string; html-index fixture.
- [x] T9: Review F1/F2 — id assignment moves to the document pass; a mark in a
      heading takes the heading's id; minted ids skip every id already used.
- [x] T10: Review F5/F6/F7/F10 — collation fold-tie oracle, fold warning
      asserted absent outside LaTeX, TOC claim exercised, AC3's invariants
      named and asserted.
- [x] T11: Review F8/F9/F12 — README/DESIGN corrections; AC3 narrowed via the
      amendment gate (F4), including the single-layer no-leak comparison; the
      remaining findings recorded as candidate rows.
- [x] T12: pass-2 return — anchors relocate to an empty span after the
      heading (author-id, multi-mark and no-id headings uniform); the id
      collector reads raw-HTML ids; regression fixtures for all three shapes.

## Work log

- 2026-08-16: created by /milestone-plan; promotes ROADMAP candidate "HTML index generation" and absorbs "empty-level warning fires only on the LaTeX branch" (M01 review R19).
- 2026-08-16: criteria audit ran in full mode ([O] fresh reader): 24 findings — unsatisfiable AC1, snapshot sort-order oracle, unpinned section/anchor markers, fixture gaps (linked target, placement hostility), hand-list README pins among them — all repaired in the AC wording above; 4 open findings gated (locators, see-also, warning row, letter groups).
- 2026-08-16: plan gate chose numbered locator links over section-title links because they are predictable, compact, and testable; falsified by user or community feedback preferring section labels.
- 2026-08-16: plan gate chose no-locator-from-xref-marks (matching LaTeX) over HTML realizing the print convention because cross-format semantics stay aligned; falsified by a cross-format decision to keep see-also locators in both back-ends (candidate row).
- 2026-08-16: plan gate chose a flat nested list over letter-group headings because grouping forces diacritic-folding decisions best settled with sort keys; falsified by the sort-key feature landing or user demand.
- 2026-08-16: plan chose normative collation (ASCII fold, codepoint order) over implementation-defined order because manifests need a hand-derivable oracle; falsified by non-Latin corpora needing real collation.
- 2026-08-16: plan chose no HTML level clamp over mirroring makeindex's 3-level ceiling because the ceiling is a back-end property (IP1); falsified by cross-format consistency complaints from users.
- 2026-08-16: plan chose an AST-built index over raw HTML strings because Pandoc's writer owns escaping (IP2); falsified by an index shape AST nodes cannot express.
- 2026-08-16: plan chose a review-time merge-base diff over a checked-in golden `.tex` because the suite's oracle rule forbids snapshots; falsified by LaTeX regressions repeatedly slipping in between reviews.
- 2026-08-16: plan chose no injected CSS over a styled index because nested lists render acceptably under defaults (GP4); falsified by the extension-listing quality bar demanding styling (GP1).

- 2026-08-16: /milestone-implement started; branch m03-html-backend cut from main.
- 2026-08-16: minor amendment (task reorder): T5's suite rework lands alongside each task that requires it rather than as one later task — anchors alone break the M01 visible-terms extraction, so no earlier task can leave the suite green on its own.
- 2026-08-16: implement gate settled three open choices: the `qi-` identifier namespace, author-id preservation, per-entry locator numbering (Decisions below).
- 2026-08-16: T1+T2 — format-neutral empty-level warning moved before the back-end branch and reworded to name no back-end; HTML branch records marks and mints anchors; Pandoc pass builds the index section from AST nodes (collation, unlimited nesting, numbered locator links). New `tests/htmlindex.py` reads rendered HTML structurally; visible-terms extraction retargeted (attribute-order-proof, index section excised); demo HTML index manifest (43 rows) and the anchor/link checks added. Suite green with --self-test.

- 2026-08-16: T3+T6 — xref-conflict.qmd gains a resolving two-level target (sigma), a colliding single-level target that prints identically and must stay plain (rho), and the entry they name; hand-derived HTML manifest (8 rows) plus a check that the resolving link points at the sub-entry itself. The suite's LaTeX-only clash rationale is rewritten: the clash is a makeindex property, not the absence of a back-end.

- 2026-08-16: T4 — new examples/placement.qmd marks one term in a heading, a table cell and a footnote, plus a mark carrying an author id. Hand-derived manifest plus checks that locators are numbered in source order, that the footnote anchor really is relocated behind a later-written mark (so the pin is not vacuous), and that the author id is kept and linked.

- 2026-08-16: T5 — escaping-probe HTML check (94 characters as exact elements of the extracted entry set), control + gfm negatives, and the review-time merge-base `.tex` diff procedure documented at the AC1 render site. .gitignore gains the gfm and epub artifacts.
- 2026-08-16: discrimination probes (LESSONS M01): forcing the HTML branch on for every format puts `# Index` and 107 `qi-` artifacts into the gfm output, so the AC6 negative fires rather than passing vacuously. Quarto's FORMAT is `commonmark` for gfm, `revealjs` for revealjs and `epub` for epub — none carries `html`, which is what makes the Scope pass-through claim hold.

- 2026-08-17: T7 — README gains an HTML back-end section (section/anchor/entry ids, numbered locators, the four class hooks), a beamer-scoped pass-through section, and a six-row back-end divergence list; the three stale one-back-end sentences are gone. Suite pins them by normalized bytes, so a rewrap does not fail and a rewrapped stale sentence cannot hide. DESIGN.md Architecture filled: two passes, two back-ends, the shared format-neutral layer.

- 2026-08-17: all tasks done; tests/run-tests.sh --self-test clean. AC1 evidence rehearsed: demo.qmd --to latex on the branch is byte-identical to the same render at the merge-base (procedure documented in the suite). Status -> review.

- 2026-08-17: review pass 1 RETURNED (defect return 1): AC4 fails — two level-list-distinct cross-reference targets on one key render as one, the second silently dropped, because the dedupe compares the rendered `: `-joined string rather than the level lists Scope requires. Two further load-bearing defects confirmed by reproduction: a mark in a heading under `toc: true` emits its anchor id twice (locator resolves to the TOC copy), and a minted anchor can collide with an id the author already used. Full suite passed throughout — no fixture exercises any of the three shapes.

- 2026-08-17: T8 (review F3, the AC4 failure) — cross-reference dedupe now compares parsed level lists element-wise, not the `: `-joined string, so two targets that print alike but name different things both survive. New HTML-only fixture examples/html-index.qmd holds the repeat case and the look-alike case; verified discriminating by restoring the string comparison, which drops eta's second cross-reference and fails the manifest.

- 2026-08-17: T9 (review F1/F2) — id assignment moved out of the per-mark pass into the document pass, which collects every id the author wrote before minting any. A mark inside a heading now borrows the heading's own id instead of minting one inside it, since Quarto copies heading contents into the sidebar TOC and a link would resolve to the copy. placement.qmd gains toc:true (the repro, and it exercises the TOC claim); html-index.qmd gains marks carrying qi-mark-1 and qi-entry-1. Both fences verified discriminating by reverting each fix in turn.

- 2026-08-17: T10 (review F5/F6/F7/F10) — html-index.qmd gains a fold-tie pair written in the wrong order, so the collation tie-break has an oracle (reversing it now fails); the fold warning is asserted absent from the HTML and gfm logs, so the makeindex ceiling cannot follow the format-neutral warnings out of the LaTeX branch (moving clamp_levels now fails); placement.qmd's TOC exercises the documented TOC claim; AC3's anchor arithmetic now names and asserts all three fixture invariants it rests on, not one.

- 2026-08-17: amendment return: AC3 — "every `entry=`/`see=`/`see-also=` value is absent from the rendered document's text, index section excised, compared in a single layer so a value containing `&`, `<`, `>` or `\"` is matched against its escaped rendering and an escaping leak cannot pass unseen"
- 2026-08-17: T11 (review F8/F9/F12/F4) — README corrected (the section id sits on the wrapping section, not the h1; the heading-id and id-skipping behaviour documented; the pass-through claim narrowed to what is true, since a mark's span attributes do travel into gfm) and rewrapped; DESIGN Architecture updated for document-pass id assignment. AC3 amended through the gate: a fresh [O] reader returned accept-with-changes and found the no-leak sweep compared raw values against markup-layer text, so an escaping-hostile leak could never match itself — verified, fixed by comparing in one decoded layer, and verified caught. The source mark scanner now also sees `[t]{#id .index}`. Five findings recorded as candidate rows.
- 2026-08-17: plan-owned body exceeded the 150-line cap after the amendment; Acceptance criteria compressed, then Tasks, with every promise unchanged in force. Coverage remapped onto T8-T11.

- 2026-08-17: fix pass complete (T8-T11); all review findings triaged fix-now are done, the rest are candidate rows. Suite green with --self-test, cairn_validate clean, AC1 merge-base byte-identity re-confirmed. Status -> review (pass 2).

- 2026-08-17: review pass 2 RETURNED (defect return 2): AC3 fails by three new mechanisms of the SAME shape the pass-1 fix addressed — a heading mark carrying an author id keeps its id inside the heading and duplicates into the TOC (reproduced); an id written in raw HTML is invisible to the id collector, so a minted id collides with it (reproduced); and two marks in one heading share a single borrowed anchor (reproduced). Thrash trigger (b): the remedy is the alternative recorded at the implement gate — emit the anchor just after the heading rather than borrowing the heading's id.

- 2026-08-17: amendment return: AC3 — "compared in a single layer — the value against the decoded text a reader would see — so a value containing `&`, `<`, `>` or `\"` cannot slip past by being escaped in the render"; a second amendment naming AC3 stops per the rules, so the disposition went to the user, who chose to correct the wording. The requirement was already right and already implemented; only its explanation was backwards (review pass 2, blame lens).
- 2026-08-17: PAUSED mid-fix at the user's decision. The pass-2 findings are all recorded above; none is fixed yet. The approach question is OPEN and is the first thing to settle on resume: the session recommended switching to the alternative recorded at the implement gate (emit each mark's anchor in a hidden element just after the heading, rather than borrowing the heading's id), because that makes the author-id, missing-heading-id and two-marks-in-one-heading cases stop being special; the alternatives offered were patching the three cases individually or narrowing the milestone so marks in headings carry no locator. Defect returns so far: 2 — a third hits the descope-or-park threshold.
- 2026-08-17: resume; the open approach question went to the user, who chose the recorded alternative — every heading mark's anchor is an empty span emitted just after the heading, replacing heading-id borrowing (Decisions below). Minor amendment: T12 added; AC2/AC3/AC7 coverage extended to it.
- 2026-08-17: T12 — relocate_heading_anchors moves each heading mark's anchor duty (the author's id, or the pending tag) onto an empty span emitted after the heading; author-id resolution moved from the Span pass into assign_anchors, so heading and body marks take one path; taken_identifiers now also reads ids out of raw HTML. placement.qmd gains the two-marks-in-one-heading and author-id-in-heading shapes, html-index.qmd a raw `qi-mark-3` (a native-span first attempt was silently visible to the Attr walk — the fixture uses a `{=html}` block, which is not). All three shapes verified to fail under the reverted filter for their own named reasons and pass under the fix. README and DESIGN reworded from borrowing to the after-heading anchor. Suite green with --self-test; AC1 merge-base byte-identity re-confirmed.

## Decisions

- 2026-08-16: implement gate chose `qi-index` (section), `qi-mark-<n>` (locator anchors) and `qi-entry-<n>` (index entries) as the HTML identifiers over an `index`-based name because an author's own "Index" heading claims that id, and over a spelled-out `quarto-index-` prefix because these appear in a reader's URL; falsified by a collision with another extension's `qi-` namespace.
- 2026-08-16: implement gate chose to keep an author-supplied id on a mark and link the index to it, rather than overwrite it with a minted anchor, because overwriting would break whatever already points at that id; consequently minted anchors number the marks that needed one, not every mark. Falsified by an author id that is not document-unique.
- 2026-08-16: implement chose to render two marks carrying the same target on one key as ONE cross-reference over repeating it, because that is what the LaTeX index tool does with a repeated cross-reference and a repeat would report how the author spread the marks rather than anything a reader wants; falsified by a use for counting cross-reference marks.
- 2026-08-17: pass-2 gate replaced heading-id borrowing with per-mark anchor elements emitted immediately after the heading, because borrowing made the author-id, missing-id and multi-mark heading shapes each a special case and two of them failed review; an author id on a heading mark now relocates onto its emitted anchor, narrowing the author-id decision above to marks outside headings. Falsified by a reader-visible artifact of the emitted anchor block, or by a consumer that needs the id to sit on the mark span itself.

## Review

### 2026-08-17 — first review pass: RETURNED to in-progress

Consistency gate: `cairn_validate` exit 0 (16 PASS, 7 advisory OK). Profile
`generic` names no toolchain checks. No IP/GP changed, so no impact report.
No CI configured in the repo; the local suite is the whole evidence base.
Draft PR #3 opened.

**Criterion evidence (no box ticked — the milestone returns, so every
criterion is re-verified against the fixed code next pass):**

- AC1: `tests/run-tests.sh --self-test` exits 0, all checks pass. Merge-base
  comparison run twice (implement close and review): `examples/demo.qmd --to
  latex` on the branch is byte-identical to the same render at the merge-base.
  The [S] blame lens independently confirmed the LaTeX emission path is
  byte-for-byte unchanged. **Passes.**
- AC2: 43-row demo manifest, 2-row placement manifest, both matched in order;
  independently re-derived row-for-row by the [O] lens with no disagreement,
  Latin-1 rows included. **Passes as written.**
- AC3: 25 anchors, one per locator-contributing mark, all links resolve.
  **Passes as written, but the property is narrower than the criterion
  claims** — see F1, F2, F4, F10 below; the uniqueness check holds only
  because no fixture sets `toc:` or carries an author id in the minted scheme.
- AC4: **FAILS.** Two level-list-distinct targets on one key
  (`see="A!B"` and `see="A: B"`) render as ONE cross-reference — the second is
  silently dropped and the survivor links. The dedupe compares the `: `-joined
  string, which Scope forbids ("matched on parsed level lists, never rendered
  strings"). Reproduced directly (F3).
- AC5: all 94 printable ASCII characters present as exact elements of the
  extracted entry set. **Passes.**
- AC6: control and gfm negatives pass; beamer checks pass; verified
  discriminating at implement time. **Passes.**
- AC7: 3 stale sentences absent, 7 claims present. **Passes mechanically**, but
  three of the claims are inaccurate or overstated — F8, F9.

**Findings and disposition** (16 reported across three fresh-context lenses;
[O] diff-bug F1–F14, [S] prior-review P1–P2, [S] blame-history none):

- F1 duplicate `qi-mark-N` when a mark sits in a heading under `toc: true` —
  the locator resolves to the TOC copy. Reproduced. → fix now.
- F2 minted anchors can collide with an id the author already used; two
  entries then link to the same anchor. Reproduced. → fix now.
- F3 cross-reference dedupe keyed on the rendered string; silent loss of a
  distinct target (IP2). Reproduced. → fix now; this is the AC4 failure.
- F5 the collation tie-break is grep-pinned in the README but no oracle
  exercises it (`return false` leaves the suite green). → fix now.
- F6 nothing asserts the 3-level fold warning stays LaTeX-only. → fix now.
- F7 "enters the TOC" is claimed but no fixture has a TOC. → fix now (F1
  needs the fixture anyway).
- F8 README says the id sits on the `<h1>`; with section-divs it sits on the
  wrapping `<section>`. DESIGN says every mark span gets an anchor, which the
  author-id case contradicts. → fix now.
- F9 README "no index artifacts appear" is overstated: the mark's class and
  `data-see` survive into gfm. → fix now.
- F10 AC3's arithmetic names one fixture invariant but relies on two. → fix
  now.
- F4 the no-leak sweep reads text only, so it cannot fail for AC3's wording
  (values legitimately persist as span attributes — pre-existing since M01).
  → follow-up, and AC3's wording is narrowed by the same amendment.
- F11 an author writing `{#qi-index}` collides with the section id. →
  follow-up (candidate row).
- F13 a self-referential cross-reference links an entry to itself. →
  follow-up (candidate row).
- F14 no planted-defect proof for the new HTML checks. → follow-up.
- F12 one over-long README line. → fix now (trivial).
- P1 M03 adds two more module-level accumulators, widening deferred M01
  review R16. → follow-up; widen the existing candidate row.
- P2 the bare-attribute no-leak gap (M01 N9) is carried through a block M03
  reworked. → rejected as pre-existing and already tracked by a candidate row.

**Why the suite did not catch F1–F3:** every fixture avoids the triggering
shape. The green suite was evidence about its fixtures, not about the
back-end (LESSONS, M01).
