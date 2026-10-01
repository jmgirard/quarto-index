# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-10-01 (triage of 25 candidate rows and 205 Known issues. Split: the suite-run follow-ups, the M32 check follow-ups, the version-portable suite and matrix legs, and RTL with `lang:` punctuation. Routed to Known issues: the `resolve_markers` byte evidence, the after-heading anchor pin, and the LaTeX edge cluster. Compressed KI205, KI214. No drops, no decision entry. Validate green.)_
_Released 0.1.0 2026-08-26._
_Released 0.2.0 2026-09-02._
_Released 0.3.0 2026-09-05._
_Released 0.4.0 2026-09-11._

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M106 | The version matrix reads the two-index PDF and the book EPUB | in-progress | — | normal | milestones/M106-matrix-missing-legs.md |
| M105 | Three M095 checks each fail on the gap its review found | done | — | normal | milestones/archive/M105-m095-check-gaps.md |
| M104 | A caption mark beside a shortcode files one locator | done | — | normal | milestones/archive/M104-shortcode-caption-marks.md |
| M103 | The two site-check clauses M46 withdrew hold again | done | — | normal | milestones/archive/M103-site-check-clauses.md |
<!-- rows grouped by status, not sorted by ID; keep only the 3 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- proposed work only; one row per line, at most 400 bytes: the work, its promotion condition — added YYYY-MM-DD — sources — and the KI<n> labels motivating it, restating none of them; a row motivated by a whole DESIGN.md Known-issues subheading names the subheading, never a label range (D-034).
     A finding about today's behavior is a DESIGN.md Known-issues entry, not a row (D-013). -->
- Give the suite's banner headings a form the run can use: the heading text sits in executable source the read and pairing sweeps scan, and a wrapped banner names its section by a truncated first line. Promote on a heading a new section wants that either shape refuses — added 2026-09-04 — M075 review F7/F11 — KI247, KI248
- Run the suite in parts: independent sections in parallel, or a named subset once the three whole-run accumulator sweeps declare their own domains. Promote on a section growing past a couple of minutes — added 2026-09-03 — M075 plan gate, split 2026-10-01 — KI238, KI241, KI242, KI243, KI244, KI245
- Time the suite per render rather than per section. Promote on M075's section profile proving too coarse — added 2026-09-03 — M075 plan gate, split 2026-10-01
- Automated dependency updates for the workflows' actions (Dependabot or equivalent), so a bump arrives as its own pull request rather than a hand edit; the config file and the stream of small PRs are the cost. Promote on a second catch-up round, or a deprecation warning going unnoticed long enough to break a run — added 2026-08-28 — M53 plan gate
- Make M32's marker-less plants read the captured artifact rather than the render's working copy. Promote with any other suite-wide capture sweep — added 2026-08-24 — M32 review R2-F9, split 2026-10-01 — KI108
- Narrow M32's HTML-cost check to the bibliography's own wrapper. Promote on that fixture growing a footnote or a Citation block — added 2026-08-24 — M32 review R2-F14, split 2026-10-01 — KI109
- Make the acceptance suite and its PDF comparison version-portable. Promote on an extraction shown engine-neutral across the two engines — added 2026-08-26 — M43, split 2026-10-01 — KI110, KI111
- A `site/gallery/` page for the two-index PDF fixture; promote with any other gallery extension, the gallery build's own checks (M41) needing extending — added 2026-08-27 — M49 Scope Out
- The older acceptance-suite backlog held under `DESIGN.md`'s two acceptance-suite subheadings, which no single milestone can take whole; promote a named cluster of it, never the subheadings — added 2026-08-16, scoped 2026-08-31 — M35-M50
- Repair the site and gallery checks; promote on any turning a run red for a reason that is not the defect it names — added 2026-08-26, clustered 2026-09-04, narrowed 2026-09-30 when M103 took M46's two clauses and the publishing gaps stayed Known issues only — M29, M41, M46, M074 reviews — KI84, KI85, KI140-KI151, KI155, KI156, KI249
- [low] Tidy the M105 cell-guard self-test: derive the module list its red runs assert instead of pinning four names, put the commented-out-opener comment over its own plant, and rewrap the `tests/stateprobe.py` docstring. Promote on a new module gaining a reset, which turns that self-test red — added 2026-10-01 — M105 review W4, W8, W12
- [low] Test that the first counting symbol of a Typst page numbering pattern sets a locator's kind: a pattern with two symbols of different kinds, where taking the last symbol changes an entry's order. Promote on any change to `qi-index-rank` or `qi-index-symbols` — added 2026-09-14 — M100 review round 2 F1
- [low] Close the last id-census shape M081 and M082 leave in `note_raw`: a `style` or `script` inside `svg` or `math`, where a breakout tag is reported to make a real element the walk steps over. Promote on evidence checked against a browser, which this repo does not run, or on an author reporting one — added 2026-09-06, narrowed 2026-09-06 — M080 review round 2 F5 — KI261
- [low] Reach the id-census shapes M080 leaves: an `id=` written in the text content of a `title`, `noscript` or `plaintext` element, none of which a case can exercise on a rendered page. Promote on an author reporting one, or with the reading of the written page KI255 needs — added 2026-09-06, narrowed 2026-09-06 when M080 took the rest — M079 review X1/X4/X5, X7 — KI254
- [low] See an id Quarto's writer generates after the filter runs (`fn1`, `cb1`, `title-block-header`), which the census cannot: a mark written with one keeps it and the page carries it twice, unreported. Needs a reading of the written page rather than of the AST. Promote on an author reporting one — added 2026-09-06 — M079 review X2 — KI255
- [low] Settle where a recovered locator points for a chapter that declares its own `output-file:`, which writes no record and which M069's never-written recovery now reads from source; promote on an author reporting an index link into such a chapter lands nowhere — added 2026-09-03 — M073 implement T3 re-read — KI216
- [low] Declass Quarto's navigation-envelope copies of a chapter's `title:` in an HTML book, so a mark written there files one locator rather than one per sidebar and page-navigation copy on every page; promote on an author reporting a title mark's locator count — added 2026-09-03 — M071 review F1 — KI235
- [low] A way for an author to ask for no word at all in front of a cross-reference target, which M59 removes by refusing an invisible label value; promote on an author reporting they wrote one for that reason, or on a second reference agreeing an index prints a bare target — added 2026-08-29 — M59 plan gate
- [low] Settle whether the emptied-place reports for a callout, a tabset and a captioned figure should keep depending on Quarto's scaffold wrapping; promote on an upstream change surfacing as a manifest mismatch — added 2026-08-19, narrowed 2026-08-23 when M28/M29 took the naming half — M12 review F12 — KI23
- [low] Chapter-based locator labels in the book HTML index (e.g. 2.1 instead of 1, 2, 3) — added 2026-08-17 — M05 gate kept numeric locators; promote on reader evidence that numeric locators fail in long books
- [low] Locator-control follow-ups: locator roles beyond `principal`, on evidence an author wants a second role; an author-written id pairing two overlapping ranges of one term, on evidence authors write them; control over the range dash; and emphasizing a principal page folded inside a range — added 2026-08-21 — M20/M21 Scope Out, RR01 — KI5, KI74, KI163
- [low] Pair a range spanning two chapters of an HTML book; promote on a per-chapter record that separates what the author wrote from what a chapter concluded, never on the feature being wanted, and on a derivation path that reads the mark's rewritten content — added 2026-08-22 — M21 review rounds 1-3, D-009 — KI19, KI20
- [low] Move the index relative to content Quarto adds after filters run, rather than leaving the order to an author-written `#refs` div; promote on evidence Quarto exposes an ordering hook a filter can reach — added 2026-08-24 — M32 Scope Out — KI3
- [low] Print an RTL index term correctly. Promote on a bidi path that also settles locator placement — added 2026-08-24 — M33 Scope Out, split 2026-10-01 — KI6
- [low] Follow `lang:` for the index punctuation, the cross-reference target's level join included: nothing localizes it. Promote on two references of different kinds agreeing on a language's index punctuation — added 2026-08-28 — RR02 B2, M58 Scope Out, split 2026-10-01
