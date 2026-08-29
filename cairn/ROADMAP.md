# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-08-28 (a plan gate on the clustered index-output follow-ups found two of the three already shipped: M09 reports the folded-path key collision KI7 said went unreported, and KI8's empty tree is guarded twice over — both entries corrected in DESIGN.md. The third, KI26, went to a Fable review as RB02/RR02, which chose a shipped translation table keyed on `lang:` over author-declared strings and rejected both table sources the brief posed; D-035, D-036 and D-037 record it, and KI26's enumeration was corrected from two strings to four. M56 and M57 planned; the graduated candidate row was replaced by RR02's locator-punctuation finding. M51's terminal row was pruned to hold the line cap. Two fresh-context readers ran: the Fable reviewer, and one criteria auditor over two rounds — six findings then four, all ten fixed at the gate; D-038 came out of the tenth. ROADMAP 59 lines / 11,525 bytes, LESSONS 49 / 19,003 — under budget (`wc -l -c`). No suite run: nothing outside `cairn/` changed. The `release window` advisory did not fire.)_

_Released 0.1.0 2026-08-26._

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M56 | An author sets the words the index back-end picks itself | in-progress | — | normal | milestones/M056-index-label-override.md |
| M57 | A non-English document gets a non-English index | planned | M56 | normal | milestones/M057-index-label-language.md |
| M55 | An HTML book builds every index its chapters declare | done | — | normal | milestones/archive/M55-book-named-indexes.md |
| M54 | The candidate backlog comes back under D-013 | done | — | normal | milestones/archive/M54-candidate-backlog.md |
| M53 | The workflows' actions come up to date | done | — | normal | milestones/archive/M53-action-versions.md |
| M52 | EPUB gets an index back-end | done | — | normal | milestones/archive/M52-epub-back-end.md |
<!-- rows grouped by status, not sorted by ID; keep only the 5 most recent
     terminal (done or dropped) rows — older ones live in milestones/archive/ + git -->

## Candidates
<!-- proposed work only; one row per line, at most 400 bytes: the work, its promotion condition — added YYYY-MM-DD — sources — and the KI<n> labels motivating it, restating none of them; a row motivated by a whole DESIGN.md Known-issues subheading names the subheading, never a label range (D-034).
     A finding about today's behavior is a DESIGN.md Known-issues entry, not a row (D-013). -->
- Automated dependency updates for the workflows' actions (Dependabot or equivalent), so a bump arrives as its own pull request rather than a hand edit; the config file and the stream of small PRs are the cost. Promote on a second catch-up round, or a deprecation warning going unnoticed long enough to break a run — added 2026-08-28 — M53 plan gate
- Repair the readers and checks M52's EPUB back-end added; promote on any of them turning a run red for a reason that is not the defect it names — added 2026-08-28 — M52 review F3, F7-F13 — KI91, KI92, KI93, KI94, KI95, KI96, KI97, KI98
- Repair the editor-metadata readers M50 added and the readers M49 added; promote on any of them turning a run red for a reason that is not the defect it names — added 2026-08-27, extended 2026-08-28 — M50 review F1, F2, F3, F6; M49 review F6, F7, F9 — KI99, KI100, KI101, KI102, KI103, KI104
- Fence the three unguarded edges of the named-index LaTeX behavior M49 shipped; promote the first two on an author report or a fixture reaching either edge, the third on the extension claiming a plain-pandoc path at all — added 2026-08-28 — M49 review F2, F3, F4 — KI105, KI106, KI107
- Dedupe `examples/.gitignore` against the root ignore — added 2026-08-19 — M13 review F16 — KI75
- Reconcile the example corpus so its probe `see=`/`see-also=` targets name terms the fixture indexes — added 2026-08-19 — M14 plan gate — KI72
- Settle whether the emptied-place reports for a callout, a tabset and a captioned figure should keep depending on Quarto's scaffold wrapping; promote on an upstream change surfacing as a manifest mismatch — added 2026-08-19, narrowed 2026-08-23 when M28/M29 took the naming half — M12 review F12 — KI23
- Rewrap the filter source under 80 columns, and narrow each module's exports to what is reached from outside — added 2026-08-20 — M17 review J/I — KI76, KI77
- Release bundle, gated on one user-declared window and never agent-proposed; the window opened 2026-08-26 and only the Quarto extension-listing submission is outstanding, mcanouil/quarto-extensions#369, whose check asked for repository topics and for the editor metadata M50 planned, both since supplied; upstream's to re-run and merge — added 2026-08-16
- Chapter-based locator labels in the book HTML index (e.g. 2.1 instead of 1, 2, 3) — added 2026-08-17 — M05 gate kept numeric locators; promote on reader evidence that numeric locators fail in long books
- Locator-control follow-ups: locator roles beyond `principal` (a defining passage, an illustration), on evidence an author wants a second role; an author-written id pairing two overlapping ranges of one term, on evidence authors write them; control over the range dash; and emphasizing a principal page folded inside a range — added 2026-08-21 — M20/M21 Scope Out, RR01 — KI5, KI74, KI163
- Pair a range spanning two chapters of an HTML book; promote on a per-chapter record that separates what the author wrote from what a chapter concluded, never on the feature being wanted, and on a derivation path that reads the mark's rewritten content — added 2026-08-22 — M21 review rounds 1-3, D-009 — KI19, KI20
- Book sidecar-store follow-ups (clustered): prune records for chapters no longer in the book; give the declared-key map a stable order; decide what a page outside `book.render` should do — added 2026-08-17, clustered 2026-08-22 — M05 review F4/F13, M06 review pass 2 F11 — KI16, KI17, KI18
- Make a `,` index entry print as a comma rather than merging with the index style's delimiter into one glyph; promote on evidence that a reader or author reads the merged glyph as wrong, never on the oddity being noticed — added 2026-08-24 — M30 T1 — KI87
- Move the index relative to content Quarto adds after filters run, rather than leaving the order to an author-written `#refs` div; promote on evidence Quarto exposes an ordering hook a filter can reach — added 2026-08-24 — M32 Scope Out — KI3
- M32 check follow-ups (clustered): make the marker-less plants read the captured artifact, promoted with any other suite-wide capture sweep; and narrow the HTML-cost check to the bibliography's own wrapper, promoted on that fixture growing a footnote or a Citation block — added 2026-08-24, clustered 2026-08-27 — M32 review R2-F9, R2-F14 — KI108, KI109
- Make the acceptance suite and its PDF comparison version-portable, and give the matrix its missing legs; promote the comparison on an extraction shown engine-neutral across the two engines, the legs with it or sooner on the restored PDF leg running a clean schedule cycle, the unreproduced floor-leg failure on a recurrence — added 2026-08-26 — M43/M51/M52 — KI110, KI111, KI112, KI113, KI114
- Print an RTL index term correctly: the plan gate's probe shows it unshaped with the locator comma on the wrong side of the entry, which a covering font does not fix; promote on a bidi path that also settles locator placement — added 2026-08-24 — M33 Scope Out — KI6
- A `site/gallery/` page for the two-index PDF fixture; promote with any other gallery extension, the gallery build's own checks (M41) needing extending — added 2026-08-27 — M49 Scope Out
- Suite readers: repair where each check reads from and what it holds, over `cairn/DESIGN.md`'s two acceptance-suite subheadings; promote on any turning a run red for a reason that is not the defect it names, or on a documented sentence drifting from the extension's behavior — added 2026-08-16 — M35/M36/M46/M50 — KI24, KI117, KI118, KI119, KI120, KI121, KI122, KI123, KI124, KI125, KI164
- Repair the version-matrix readers; promote on any of them turning a run red for a reason that is not the defect it names, or on the workflow gaining a trigger — added 2026-08-28 — M48 review, M51 review F2, M53 review F1-F2 — KI126, KI127, KI128, KI129, KI130, KI131, KI132
- Repair the guards and bounded mutations M37 shipped, and prove the clauses M38 descoped; promote with the readers they bind in hand — added 2026-08-25 — M37 review, M38 Scope Out, M38 review round 3 — KI133, KI134, KI135, KI136, KI137, KI138, KI139
- Repair the gallery checks and the plants that fence them; promote on any of them turning a run red for a reason that is not the defect it names — added 2026-08-26 — M41 review — KI84, KI85, KI140, KI141, KI142, KI143, KI144, KI145, KI146, KI147, KI148, KI149, KI150, KI151
- Hold the pre-release sweep's report clause and `tests/sitecheck.py links`' containment clause, the two M46 could not; promote on a containment approach that tests the resolved path once, after every rewrite — never one mechanism at a time — added 2026-08-27 — M46 descope amendment, M46 review rounds 1-4 — KI152, KI153, KI154, KI155, KI156, KI157, KI158, KI159
- Repair the publishing workflow and the checks around it; promote on a publish run failing, or on a check turning a run red for a reason that is not the defect it names — added 2026-08-26 — M42 review — KI160, KI161, KI162
- Support Windows checkouts without symlink support — added 2026-08-16 — M01 review R18 — KI78
- Guard an accumulator added after M26 that joins no `reset`; D-011 refuses a source scan, so the guard is a render or nothing — added 2026-08-16, promoted to M26 2026-08-23 — KI10
- Probe `\index` inside a moving argument, and protect `\quartoindexregister` on that path — added 2026-08-16 — M01 review R17, M20 review round 2 R2-F7 — KI2
- Settle the see-also locator semantics and whether repeated `\seename` should join — added 2026-08-16 — M03 gate chose LaTeX-aligned no-locator semantics, M15 keeps it for a contested key — KI9
- Settle whether a mark's attribute values may ride into pass-through formats — added 2026-08-17 — M03 review F4/F9 — KI15
- Reach markers written in YAML `abstract:` — added 2026-08-18 — M08 review R4/Q2 — KI11
- Restore byte-level evidence that `resolve_markers` is output-neutral; D-004 refused the merge-base oracle and D-012 licenses a same-tree one — added 2026-08-17 — M04 review F12 — KI12, KI52
- Pin the after-heading anchor relocation against Quarto's own filter ordering — added 2026-08-17 — M03 review pass 3 F8 — KI13
- Handle a chapter filename containing `#` or `?` — added 2026-08-17 — M05 review F11 — KI14
- Localize the locator punctuation an index prints — the entry comma and the cross-reference semicolon, which an Arabic index sets differently; promote on the label map M56 ships proving it wants a fourth key, or on an author reporting the punctuation as wrong — added 2026-08-28 — RR02 B2
- Repair the HTML book's index placement and the reports around it: which chapter builds an index no marker names on a first render, the stale-name report's per-chapter count, a record whose `xrefs` is not a table, and the untested sort-key merge order; promote on any reaching an author or turning a run red for a reason that is not the defect it names — added 2026-08-28 — M55 review F1, F2, F4, F8 — KI167, KI168, KI169, KI171
