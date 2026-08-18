# M06: Sort keys

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP2, GP4, GP5, GP6
- **Branch/PR:** `m06-sort-keys` / https://github.com/jmgirard/quarto-index/pull/6

## Goal

An author can give an index term a sort key separate from its printed text,
via a format-neutral `sort=` span attribute honored by the LaTeX back-end, the
HTML back-end, and a book's aggregated HTML index.

## Scope

Surface tier: **user-facing** — the deliverable is new author-visible mark
syntax plus its README documentation, consumed outside the repo.

**In:** a `sort=` span attribute parsed with the level syntax `entry=` uses
(`!` separator, `!!` literal); positional per-level alignment, a level with no
sort key sorting by its own printed text; a warning when `sort=` carries more
levels than the entry has, when it appears on a mark with nothing to index,
and when one printed index key is given two different sort keys (first mark in
document — in a book, book — order wins); makeindex `sortkey@printed`
emission with `@` still quoted everywhere the extension does not write the
separator itself; HTML collation on the sort key while the printed text is
what prints; the sort key carried through the book sidecar record with
`STORE_VERSION` bumped; README, fixtures, and acceptance-suite coverage.

**Out:**
- Alphabet (A/B/C) headings in the HTML index → stays a ROADMAP candidate row;
  its own milestone once this lands.
- Language- or locale-aware collation of accented and non-Latin text → stays
  the existing ROADMAP candidate row; `sort=` is the manual workaround, and
  this milestone claims no automatic collation.
- Sort keys on `see=` / `see-also=` values → not offered. A target is prose
  naming another entry, and that entry carries its own sort key
  (`_extensions/index/index.lua:198-206`).
- Page ranges and locator styling → the existing "Page-range & styling
  control" candidate row.

## Acceptance criteria

- [x] AC1: Rendering `examples/sortkey.qmd` to PDF produces an index in which
      each term the fixture's manifest names appears at the position its sort
      key dictates, read within the `pdftotext` index region; a boundary term
      names the one neighbour it has. The suite fails unless the manifest
      names every `sort=` occurrence in the fixture, derived from the fixture
      by construction rather than hand-listed. The fixture includes an entry
      whose sort key covers only its second level.
- [x] AC2: Rendering `examples/sortkey.qmd` to HTML produces a `qi-index`
      section whose entry order **at every level** equals the order its
      manifest states (read structurally by `tests/htmlindex.py`), and that
      order differs from the order the same printed terms take in a
      sort-stripped twin fixture the suite also renders.
- [x] AC3: For each printable ASCII character `tests/run-tests.sh` derives for
      the `examples/escaping.qmd` domain, a companion fixture places that
      character in a `sort=` value; the suite renders it with the engine the
      PDF build uses and confirms the index tool accepted every entry,
      renders it to HTML and confirms every entry is present in the
      `qi-index` section, and renders it to gfm alongside a twin the suite
      generates from the fixture by deleting its `sort=` attributes,
      requiring the two outputs identical once `data-sort` attributes are
      removed — so a sort key reaching visible text, in the mark's span or
      beside it, fails here, as does any other change a sort key makes to a
      format with no index back-end (IP2's never-corrupt clause). Whether the
      `data-sort` attribute should ride into such a format at all is the
      standing ROADMAP question M03 deferred (M03 review F4/F9); this
      milestone does not settle it.
- [ ] AC4: Three diagnostics fire with the message text recorded in this
      milestone's Decisions section: (a) `sort=` on a mark with no indexable
      text, (b) a `sort=` value with more levels than the mark's entry has,
      (c) one printed index key given two different sort keys — probed both
      within one document and across two chapters of one book. Each is
      asserted by a suite check proved discriminating by reverting the
      diagnostic and observing the check fail, and each has a control render
      that does not fire it.
- [x] AC5: A book's aggregated HTML index honors a sort key written in a
      chapter other than the marker's: `examples/book/` gains such a sort key
      and `tests/htmlindex.py` asserts the aggregated index orders that term
      by its sort key rather than its printed text.
- [ ] AC6: README documents `sort=` — syntax, per-level alignment, the
      fallback for a level with no sort key, and the three diagnostics — and
      the suite asserts verbatim one normative sentence per documented
      behavior, following the existing `README_HTML_CLAIMS` precedent. The
      sentence declaring sort keys out of scope (README.md:163-165) is gone,
      asserted absent like `README_STALE`, and the pinned HTML collation
      sentence (README.md:303-305) is updated in `README_HTML_CLAIMS` rather
      than left contradicting what ships.
- [x] AC7: `tests/run-tests.sh --self-test` clean (the `verify` slot of
      `cairn/PROFILE.md`, plus the planted-defect self-test the pre-review
      check uses), and every `.qmd` fixture the merge base carries at the top
      level of `examples/` emits byte-identical LaTeX — `tests/byte-diff.sh`
      (whose own header declares it review-time evidence, not a suite check)
      reports no difference over the domain it enumerates via `git ls-tree`.

## Coverage

- AC1 → T1, T2, T3, T11
- AC2 → T1, T4, T6, T10
- AC3 → T2, T4, T7, T11
- AC4 → T1, T5, T8, T10
- AC5 → T5, T6, T10
- AC6 → T9, T13
- AC7 → T9, T13

## Tasks

- [x] T1: Parse `sort=` beside `entry=`, aligned per level with printed-text
      fallback; moved in flight into its own `CollectSort` pass (Decisions).
      *(RB tripwire: ip-touching — IP1 format-neutrality of the new syntax.)*
- [x] T2: LaTeX emission: `index_argument` writes `sortkey@printed` per level,
      keeping `LATEX_LITERAL`'s quoting for every `@` the extension itself
      does not write.
- [x] T3: `examples/sortkey.qmd`, its sort-stripped twin, and PDF checks whose
      manifest is derived from the fixture by construction.
- [x] T4: HTML collation on the sort key in `number_entries`, node identity
      still keyed on printed text, ties falling through to `collate`.
- [x] T5: Book path: sort key in the sidecar record, `valid_record` accepts
      it, `STORE_VERSION` 1 → 2, cross-chapter fixtures.
- [x] T6: HTML order checks at every level, fixture and twin.
- [x] T7: The escaping probe extended to `sort=` across PDF, HTML and gfm.
- [x] T8: The three diagnostics, their text in this file's Decisions, control
      renders, and a reversion proof for each.
- [x] T9: README `sort=` section; `README_HTML_CLAIMS` updated and the
      `README_STALE` absence assertion added.
- [x] T10: Sort registration re-keyed from the entry path to the level path,
      in one document and across a book's chapters; fixtures for the class.
- [x] T11: Each back-end orders under its own rules, documented; the AC3
      LaTeX leg tells correct escaping from no sort field at all.
- [x] T12: The folded-level guard, the stale store record, and two flagged
      non-defects dispositioned in this file's Decisions.
- [x] T13: `DESIGN.md` and README corrected where the fix falsified them;
      manifest 1n's header; the prior-review follow-ups absorbed.
- [x] T14 (return 2): a key equal to its level's own printed text registers
      nothing; the conflict reports once per level path; the two pinned README
      sentences narrowed, the plain-key claim carried by a check; four suite
      and comment defects corrected; the fourth report text recorded.

## Work log

- 2026-08-18: review pass 3 — fresh evidence for every criterion (118 checks, exit 0; byte-diff clean; cairn_validate clean). AC1/AC2/AC3/AC5/AC7 ticked. F1 fixed during the pass (conflict now reports once per rival key). F2-F10 presented at the gate; F2 falsifies a pinned README claim and is the maintainer's load-bearing call.
- 2026-08-18: T14 done — a level key equal to its own printed text no longer registers, so the README's documented skip-two-levels workaround stops discarding a later real key and stops reporting an entry as already sorted as itself; the in-document conflict now reports once per printed level path. Both proved discriminating by reversion: with F1 reverted `Mmm` loses `Qqq` entirely and draws the nonsense report, with F2 reverted one mistake draws two reports. `examples/sortkey-paths.qmd` gained the self-declaration case and `examples/sortkey-misuse.qmd` a third mark repeating the rival key. Suite 103 -> 104 checks.
- 2026-08-18: T14 records — the two README sentences narrowed to what holds in both back-ends (HTML has no level ceiling, so it honors a key LaTeX drops), and the plain-key claim is now carried by a check comparing the PDF and HTML manifests row for row rather than by assertion alone. Manifest 1n's derivation named the wrong key order and was mangled by T13's reflow; the book check's comment claimed a discrimination the version-3 record shape makes structurally impossible; `PATHSPY` split on a quoted `!` and exempted its own last row. All corrected.
- 2026-08-18: implement gate (return 2) — user chose to close AC4's recorded-text gap by recording the missing message rather than amending the criterion to bind the filter's literals by procedure, holding the criteria set where it has been through two returns. No acceptance criterion changed; the amendment return is discharged without an amendment.
- 2026-08-17: REVIEW RETURN (defect return 2) — F1: `register_sort` registers a level key equal to that level's own printed text, so the workaround README:196-199 prescribes for two adjacent skipped levels self-declares the levels it names and beats a genuine later key. Reproduced: `entry="One!Two!Three" sort="One!Two!Zed"` beside `entry="One" sort="Uno"` discards `Uno` and reports `already sorted as "One"`. F2-F8 ride the same fix; F9/F11/F12 are follow-ups, F10/F13 rejected. Status -> in-progress. AC6 unticked (two pinned sentences false and about to change); AC1/AC2/AC3/AC5/AC7 evidence stands.
- 2026-08-17: REVIEW AMENDMENT RETURN — AC4 promises the diagnostics fire with the message text recorded in this file's Decisions section; the filter emits four sort-related `warn()` literals against three recorded, the missing one being the cross-chapter conflict text that AC4(c)'s own book probe asserts. The criterion assumed (c) had one text. Routes to the gated criterion-amendment protocol.
- 2026-08-17: T13 done — `DESIGN.md` corrected in place at three sites (three passes not two, sort keys shipped not pending, the LaTeX bullet naming `sortkey@printed`); README gained the two-adjacent-skipped-levels limit and the level-not-entry precision, both pinned and the first now carried by a fixture mark; manifest 1n's header no longer attributes the PDF order to the HTML collation rule. The two prior-review follow-ups widened their standing ROADMAP rows rather than opening new ones. `tests/run-tests.sh --self-test` clean at 117 checks (89 at the merge base) and `tests/byte-diff.sh` reports every merge-base fixture byte-identical.
- 2026-08-17: all fix tasks done; status -> review for the second time. AC4 re-ticks on the strengthened probe; AC1/AC2/AC3/AC6 evidence was rebuilt by the fixes rather than merely re-run.
- 2026-08-17: T12 done — the folded-level guard now compares a sort key against the level it was aligned with rather than against the folded text, so a third level nobody keyed no longer comes out carrying `three@three, four`; the fold rule for sort keys is documented and pinned. A store record from an older extension version is reported as stale rather than as unreadable. `sort=""` and the doubled `!` are dispositioned as by-design in this file's Decisions. Suite 101 -> 103 checks.
- 2026-08-17: T12 found a pre-existing suite gap this milestone opened — every planted store record was written with `"version":1`, so after T5 bumped the version they were being rejected on version rather than on the rule each check existed to prove. The version is now read from the filter, and the ghost-chapter check asserts no record-ignored report fires, which is what makes the chapter-list filter the thing that kept it out.
- 2026-08-17: T11 done — the AC3 LaTeX leg now reads the emitted sort fields structurally: every entry must split at the separator the back-end writes, and the index tool must print each term as its text alone. Proved discriminating by a filter emitting no sort field at all, which makeindex accepts just as happily (94 accepted, 0 rejected) while the new check fails on all 94. README gained the ordering rule, pinned by two more `README_SORT_CLAIMS` rows. Suite 100 -> 101 checks.
- 2026-08-17: T11 amendment (substantive premise, gated) — F3 asked that both back-ends order on the same characters. Compiled against makeindex: a sort key of `|` sorts before `mango` in PDF and after it in HTML with NO escaping involved, because makeindex groups punctuation ahead of letters while the HTML collator folds case and compares bytes. Escaping is not the cause and removing it would not fix it (it does reorder within LaTeX: `<key` before `~key` raw, after it escaped). User chose documenting the rule over minimising the escaping. No acceptance criterion asked for cross-back-end order identity, so none changed.
- 2026-08-17: T10 done — sort keys now register against a printed LEVEL path rather than a whole entry, so a key written for `Aaa` applies whether `Aaa` stands alone or parents a sub-entry, and a level a mark leaves alone no longer shuts out the mark that declares it. `sort_levels` returns what the author declared (the fallback moved into `sort_for`); the book store carries the chapter's declared key map instead of a resolved key per mark, `STORE_VERSION` 2 -> 3, and `book_sort_keys` merges those maps per path, reporting once per entry. `examples/sortkey-paths.qmd` + manifests 1q/1r pin both legs; the AC4(c) probe moved onto differing level paths. Suite 97 -> 100 checks (114 with --self-test).
- 2026-08-17: T10 discrimination — the pre-fix filter, rendered against the new fixture, emits `\index{Hague@Hague, The}` beside `\index{Hague, The!Scheveningen}` (one term, two makeindex keys) and files `Ccc` in the HTML index under its printed text with the declared `Www` discarded; both new checks fail on it, and the strengthened AC4(c) probe draws the conflict report 0 times.
- 2026-08-17: T10 amendment (minor) — F8's two halves landed with T10 rather than T12: the book conflict report gained a `warn_discrimination` proof, and its render-order assumption is now asserted by logging the two renders separately (0 on the first, 1 on the second) instead of stated in a comment.
- 2026-08-17: implement gate (resume) — user chose level-path sort keys, documenting the two-adjacent-skipped-levels limit rather than adding syntax for it, and accepted the Coverage amendment naming the fix tasks.
- 2026-08-17: created by /milestone-plan.
- 2026-08-17: implementation started on `m06-sort-keys`, cut from main at 6be9f93.
- 2026-08-17: implement gate — user chose to proceed on the `ip-touching` tripwire without escalation, and chose format-neutral scope for the sort-key conflict warning over index-building formats only.
- 2026-08-17: T1 done — `sort=` parsed with `entry=`'s level syntax, aligned per level with printed-text fallback, plus `levels_key`, `sort_levels`, `register_sort`/`sort_for`, `clamp_sort`, and a shared `derive_levels` used by both Span passes.
- 2026-08-17: T1 minor amendment — parse moved into a new `CollectSort` pass ahead of the emitting pass; task text updated, rationale in this file's Decisions.
- 2026-08-17: REVIEW RETURN (defect return 1) — AC4 fails inside its own promise: report (c) does not fire when one printed index key is given two different sort keys through differing level paths. Root cause F1: sort keys register per full entry path while HTML applies them per level, so a key neither propagates to nor conflicts with a sibling or parent path — reproduced emitting `\index{Aaa!subkey@sub}` beside `\index{Zzz@Aaa}`, one entry split in two, silently. F2 compounds it: consecutive empty sort levels are unexpressible, so `sort="!!Zed"` files level 1 under the literal `!Zed` rather than redirecting level 3. Status -> in-progress; F3-F10 and the two prior-review findings ride the same fix. AC4 unticked; AC1/AC2/AC3/AC5/AC7 evidence stands, AC6's promise holds but the sentence it pins is falsified by F1.
- 2026-08-17: review — draft PR #6 opened; every criterion executed with fresh evidence (110 checks, exit 0), byte-diff clean, cairn_validate clean; three-lens fan-out spawned.
- 2026-08-17: all tasks done; `tests/run-tests.sh --self-test` clean (110 checks, 89 at the merge base) and `tests/byte-diff.sh` clean. Status -> review.
- 2026-08-17: T9 done — README gained "Sorting an entry under something else"; two `SUPPORTED_FORMS` exemplars, eight `README_SORT_CLAIMS` rows, the superseded "sort keys ... will arrive later" sentence pinned absent via `README_STALE`, and the `README_HTML_CLAIMS` collation row updated to what ships. Suite 96 -> 97 checks (110 with --self-test); `tests/byte-diff.sh` reports every merge-base fixture byte-identical.
- 2026-08-17: T7 done — `examples/sort-escaping.qmd` generated by construction over the same 0x21-0x7E range the entry-key probe uses, plus its derived gfm twin; three legs pass (94 entries accepted by makeindex with the author's `@` quoted and only the back-end's separator bare, 94 entries in the HTML index and no others, gfm identical to the twin once `data-sort` is stripped). Suite 92 -> 96 checks.
- 2026-08-17: T7 found and fixed a defect in its own check, not in the filter — the gfm strip regex parsed HTML attributes with the markdown backslash-escape rule, so `data-sort="\\"` (the mark whose sort key is a backslash) swallowed two later spans. HTML attributes end at the first quote; a quote in a value is `&quot;`. The `.qmd`-side regex keeps the markdown rule, which is correct there.
- 2026-08-17: AC3 amended at a mini gate (substantive; user accepted). The original clause "no `sort=` residue" in gfm was unsatisfiable: every mark attribute already rides into a back-end-less format as `data-*`, shipped since M03 and owned by a standing ROADMAP row, so satisfying it would have meant changing behavior for all four attributes. Replaced by a sort-stripped-twin gfm diff. Two fresh-context [O] readers audited the amended wording: the first found the "exactly one attribute" count false (`class="index"` is there too), an `(IP2)` tag that overclaimed the "no artifacts" clause, two unenumerated domains, and a hole — the amendment lost the leak-into-visible-text property; the second rejected my per-mark replacement for that hole as self-referential and built the two defect renders, showing a leak BESIDE the span still passed, then verified the twin-diff formulation catches both. Net effect is not a pure narrowing: it newly binds "nothing else changes in gfm".
- 2026-08-17: T5 done — the sidecar mark record carries `sort`, `valid_record` checks it is one string per level, `STORE_VERSION` 1 -> 2, and a new `book_sort_keys` resolves one key per entry across the whole book (first in book order wins) since no chapter's process can see another's. `examples/book/` gained a cross-chapter sort key on `Shared Term`; `examples/book-order/` gained a term sorted two ways in two chapters, reported once in two renders — derived, not observed: only the second render has both chapters' records. Suite 90 -> 92 checks.
- 2026-08-17: T8 done (single-document half) — `examples/sortkey-misuse.qmd`, the three reports asserted exactly once each in `latex` and in `gfm`, a control assertion that none fires on the well-formed fixture, and three `warn_discrimination` reversion proofs. AC4's cross-chapter conflict probe rides with T5. Suite 87 -> 94 checks (103 with --self-test).
- 2026-08-17: T8 found two suite gaps and fixed both — the warning-distinctness check scanned only double-quoted Lua literals, so a single-quoted message (needed because report 3 contains double quotes) sat outside a check whose comment claimed full coverage; and `warn_discrimination`'s pass line hardcoded `M02-AC5`, filing every other milestone's evidence under the wrong criterion.
- 2026-08-17: T6 done — exhaustive HTML manifests 1o/1p for the fixture and its twin, compared in order at every depth, plus a check asserting the two manifests disagree at every position so neither could be satisfied by an index that ignored sort keys. Suite 83 -> 87 checks.
- 2026-08-17: T4 done — the entry-tree node carries a `sort` field, node identity stays keyed on printed text, and `number_entries` collates on the sort key with a printed-text tie-break; the rendered HTML index now matches the PDF order, sub-entry reversal included. All 83 checks still pass.
- 2026-08-17: T3 done — `examples/sortkey.qmd` + its derived twin, manifests 1m/1n, and four PDF checks; the manifest is checked against the fixture by construction and the twin proves the order is the sort keys' doing. Suite 79 -> 83 checks.
- 2026-08-17: T3 discovered sub-task (minor amendment) — `tests/pdfindex.py`: a two-column index interleaves under `pdftotext`/`-layout`, so printed order is read from `-bbox-layout` word positions instead; without it the AC1 check could not tell a sorted index from an unsorted one.
- 2026-08-17: T3 fixture repaired at authoring — the discrimination check found `von Neumann` occupying the same position with and without sort keys; a sixth keyed term (`Édouard Manet`) makes the two orders differ at every top-level position.
- 2026-08-17: T2 done — `index_argument` writes makeindex `sortkey@printed` per level, the separator `@` being the only unquoted one; all 79 existing suite checks pass unchanged.
- 2026-08-17: plan-gate criteria audit ran in **full** mode (user-facing tier), fresh-context [O] reader: 11 findings + 4 coverage gaps returned; all fixed in the criteria before writing (AC1 hand-list proxy, AC1 boundary/region wording, AC2 top-level-only domain, AC3 form-list proxy + LaTeX-only scope + non-printing sort key, AC4 single-document probe axis, the byte-identity criterion's unenumerable domain + misdescribed byte-diff.sh scope, the README criterion's instrument-bound converse claim + README_HTML_CLAIMS reachability conflict; gaps 1-3 folded into AC3/AC1/AC2, gap 4 posed at the gate). Criteria then renumbered when the byte-identity criterion merged into the verify-slot criterion to clear the >7 sizing tripwire; the merged wording was re-asked the audit's questions and passes (both halves name enumerating procedures).
- 2026-08-17: plan gate chose a separate `sort=` span attribute over an inline per-level delimiter inside `entry=` because D-001 forbids raw back-end code in mark values, `@` is a documented literal in `entry=` today (README.md:164), and README.md:164-166 already commits to separate span attributes; falsified by an authoring case per-level alignment cannot express that an inline delimiter can.
- 2026-08-17: plan gate chose breaking a sort-key tie by printed text through the existing collator over warning on the tie because two terms legitimately share one sort key; falsified by evidence that silent tie-breaking produces order a reader reads as nondeterministic.
- 2026-08-17: plan gate chose bumping `STORE_VERSION` to 2 over relying on `valid_record` tolerating an unknown field because a retained v1 record would be read as valid with no sort keys and silently produce a wrongly-ordered book index; falsified by evidence that a stale record cannot survive a version-bumping render.

## Decisions

### The three sort-key reports, verbatim

**Context:** AC4 asserts three diagnostics "with the message text recorded in
this milestone's Decisions section". These are those texts, as the filter
emits them (`%s` filled from the mark's context, `%d` from level counts).

**Decision:** The reports are:

1. `sort= on %s has nothing to sort; the mark indexes no entry`
2. `sort= on %s has %d levels but the entry has %d; the extra sort levels were ignored`
3. `index entry in %s is already sorted as "%s"; the sort key "%s" written here cannot apply as well, so the first one wins`

Report 3 names the two sort KEYS rather than the two marks: both marks
usually describe identically — the same term, twice — so naming the contexts
told an author nothing about what to change.

**Consequences:** All three are emitted before any back-end branch, so they
reach an author drafting to a format that builds no index; the suite asserts
each in `latex` and in `gfm`. Each is proved discriminating by the suite's
`warn_discrimination` helper, and `examples/sortkey.qmd` is the control that
draws none of them.

### Sort keys are collected in a pass of their own, before marks are emitted

**Context:** T1 planned to parse `sort=` in the existing Span pass. That pass
emits `\index{...}` inline at the mark, because the mark's position is what
gives the entry its page. A sort key, though, belongs to the *entry*, not to
the mark: if one mark of "The Hague" carries `sort="Hague"` and another does
not, the two emit different makeindex keys and the term prints twice, in two
places, identically. Requiring `sort=` on every mark of a term would fix that
and contradict GP4.

**Decision:** A third filter pass, `{ Span = CollectSort }`, runs before the
emitting Span pass. It derives each mark's levels with the same code the
emitting pass uses (`derive_levels`, called with reporting off so no warning
fires twice), registers the entry's sort key, and reports a conflict; the
emitting pass then looks the resolved key up by printed levels and applies it
to every mark of that entry, whether or not that mark wrote `sort=`.

**Consequences:** `sort=` on any one mark of a term sorts all of them. The
levels derivation is now shared rather than duplicated, so the two passes
cannot drift on what an entry's levels are. The conflict report keeps
first-in-document-order-wins semantics and now fires before any emission, so
no mark is emitted under a key the report then contradicts.

### `sort=""` and a doubled `!` in a report are the syntax working, not defects

**Context:** The review carried two suspected defects into this fix: `sort=""`
is a silent no-op, and a report renders a level's `!` doubled.

**Decision:** Neither changes. An empty sort level means "leave this level
alone" — the documented fallback — so a `sort=` value empty at every level
leaves every level alone, which is exactly what writing no `sort=` at all
does. Nothing is lost for an author to be told about. The doubled `!` is the
syntax an author writes: `levels_key` doubles a level's own `!` exactly as
`entry=` requires it, so a report naming a level PATH names it in the form
that would reproduce it. The in-document conflict report no longer passes a
path through `levels_key` at all — it names the two sort KEYS, each a single
level — so the doubling now appears only in the book report, whose subject
really is a path.

**Consequences:** Three reports stay three. No fourth diagnostic is added, so
the README's "Three things are reported, in every output format" stays true,
and AC4's domain is unchanged.

### The cross-chapter conflict report, verbatim

**Context:** AC4 asserts three diagnostics "with the message text recorded in
this milestone's Decisions section", and its third is probed both within one
document and across two chapters of one book. The two probes draw different
text: a book's chapters render in separate processes, so the report that finds
a cross-chapter conflict can name the two chapters, which the single-document
report cannot. The entry above recorded only the single-document three.

**Decision:** The fourth text is:

4. `index entry "%s" is sorted as "%s" in %s and as "%s" in %s; one entry cannot file in two places, so the first in book order wins`

It is the same diagnostic as report 3 — one printed index key given two
different sort keys — reported where the rival key sits in another chapter. It
names the level path and both chapters, because with the two marks in
different files the author needs to know which file to open.

**Consequences:** Every text the filter can draw from a sort key is now
recorded. AC4's three diagnostics stand; its third has two texts, one per
probe setting. Both are proved discriminating, and both fire once per printed
level path rather than once per mark.

## Review

**PR:** https://github.com/jmgirard/quarto-index/pull/6

Third review pass, 2026-08-18, at branch head. Evidence from a fresh
`tests/run-tests.sh --self-test` (exit 0, **118 checks**, against 89 at the
merge base), `tests/byte-diff.sh`, and `cairn_validate` of the same date. One
earlier suite run died on a Quarto/Deno segmentation fault while three
reviewer subagents were rendering concurrently; the clean run above is the
record, and the fault was in Quarto's runtime, not in a check.

**AC1 — PDF order and nesting. [verified]** Six checks. The manifest names
every one of the 7 sort keys the fixture declares and no others; the compiled
PDF "prints all 8 index entries in the order and nesting their sort keys
derive"; the twin proves the order is the keys' doing ("removing the sort keys
moves every one of the 6 top-level entries"); the level-path fixture emits
"all 11 entries as the manifest derives them, each of the 6 top-level terms
under one key whether or not a sub-entry follows it".

**AC2 — HTML order at every depth. [verified]** Six checks. The generated
index matches all 8 manifest rows in order and the twin's likewise; the two
manifests disagree at every position at both depths; the level-path index
matches all 12 rows in order and all 11 links resolve.

**AC3 — every printable ASCII character as a sort key, three formats.
[verified]** Five checks over a domain derived by construction from the same
0x21-0x7E range the entry-key probe uses. makeindex accepts all 94; all 94
carry a sort field split at the back-end's own separator and the index tool
printed every one as its text alone; all 94 reach the HTML index and it
carries no others; gfm is identical to the sort-stripped twin once `data-sort`
is removed.

**AC4 — the three reports. Held pending the gate disposition.** All three fire
in `latex` and in `gfm` with the texts this file's Decisions records, the
fourth (book) text now recorded too; the conflict count of 2 over four marks
discriminates all three candidate reporting rules; each report has a
`warn_discrimination` proof and a control render. The promise is met as
written. The tick is held because finding F2 below may change the conflict
semantics.

**AC5 — book aggregation across chapters. [verified]** The aggregated index
matches all 10 manifest rows in order with `Shared Term` under its
cross-chapter key, and the crossing is asserted by construction.

**AC6 — README. NOT VERIFIED.** The presence checks pass ("all 13 documented
sort-key behaviors appear verbatim"), and presence is what the criterion
promises — but F2 below shows one pinned sentence is false and F7/F10 show
two more are incomplete or imprecise, so the tick is withheld until the
wording is repaired and the evidence re-gathered.

**AC7 — verify slot and byte-identity. [verified]** `--self-test` exit 0 at
118 checks; `tests/byte-diff.sh` reports every one of the 13 merge-base
fixtures byte-identical.

**Consistency gate.** `cairn_validate` — all checks passed, one advisory
(`sizing`: 14 tasks). `cairn_impact` not run: the DESIGN diff changes no
numbered principle. Profile `generic` names no toolchain checks.

### Review findings (three-lens fan-out, third pass, 2026-08-18)

**[O] diff-bug — 10 findings.** **[S] blame-history — no regressions**, with
one behavioral consequence of T14 raised and fixed during the pass (below).
**[S] prior-review-record — no reintroductions**; every finding from pass 2 is
fixed with a discriminating test, routed to a candidate row, or correctly
rejected. The GitHub inline-comment probe returned empty again.

- **F1 (fixed during the pass).** T14 suppressed every further conflict at a
  level path once one was reported, so a third mark naming a DIFFERENT rival
  key drew nothing and the author learned of it only after fixing the first
  and rendering again. Suppression is now per rival key; the misuse fixture
  carries keys Aaa, Bbb, Bbb, Ccc and the expected count of 2 fails under
  once-per-mark (3) and once-per-level-path (1).
- **F2 (load-bearing, for the maintainer).** A key equal to its level's own
  printed text registers nothing even when it rivals a real key, so it neither
  wins nor reports. Reproduced: `entry="Bbb" sort="Bbb"` followed by
  `entry="Bbb" sort="Yyy"` emits `\index{Yyy@Bbb}` — the SECOND key wins,
  silently, falsifying README:218 "the first one in the document wins", which
  `README_SORT_CLAIMS` pins. Written the other way round, an explicit
  `sort="Aaa"` on `entry="Aaa"` is discarded with no diagnostic. The T14 skip
  is what makes the documented two-adjacent-skipped-levels workaround safe,
  but the rival case was never carved out of it.
- **F3.** `book_sort_keys` has no suppression at all, so the book side
  reports once per conflicting CHAPTER where the single-document side now
  reports once per rival key; three chapters naming one rival key draw two
  warnings for one thing to fix. Read-verified in the code; the suite cannot
  catch it, since `examples/book-order/` has only two chapters.
- **F4.** Manifest 8's comment still claims the second mark shows per-entry
  rather than per-mark reporting — the claim pass 2's F5 fix removed from the
  check itself. Fixed in one of the two places it lives.
- **F5.** Manifest 1r's derivation says "the four top-level entries" where six
  are listed, never mentions `Mmm` (the row T14 added), and its "except
  `Literal`, which has none" sentence is false twice. Under the ORACLE RULE
  the comment is the derivation, so two rows are unbacked.
- **F6.** The plain-key cross-back-end check asserts a property manifest 1n's
  own header says it borrowed ("the same row order serves both here"), so
  that check cannot fail independently. The property does hold — confirmed
  against makeindex on plain keys — but the check's comment overclaims.
- **F7.** Three records state a reporting rule the code no longer has: the
  comment above `book_sort_keys`, this file's Decisions entry for the
  cross-chapter report, and DESIGN's phrasing.
- **F8.** The T14 rule is undocumented: the README tells an author to write a
  level's own printed text to skip past it but never says such a key
  registers nothing, so with F2 the outcome of `sort="Bbb"` on `entry="Bbb"`
  cannot be predicted from the documentation.
- **F9.** "the extra sort levels were ignored" fires when the extra level is
  EMPTY. Reproduced: `sort="Zed!"` on a one-level entry warns, though an
  empty sort level is the documented "leave this level alone" and nothing was
  ignored. The guard counts parsed levels rather than declared ones.
- **F10.** README's "Three things are reported, in every output format" is
  imprecise: the fourth text fires only in an HTML book.
- **F11 (confirmed open, already a candidate row).** Level paths keyed on
  unclamped levels while LaTeX prints clamped ones. README now documents the
  consequence correctly, so this is a scoped limitation.

**Verified clean by the [O] lens:** `level_path`/`levels_key` injectivity,
hand-derivation of manifests 1q and 1r against all 11 marks, empty first
levels, `!`- and `@`-bearing level text, one-level and four-level entries,
`index_argument`'s comparison against the aligned level, the single unquoted
`@`, `number_entries`' comparator totality, `build_entry_tree`'s first-wins
safety, the book store's declared-vs-resolved distinction, `valid_record`'s
shape check and the stale-vs-unreadable split, and IP1/IP2 on the gfm twin.

**Defect returns:** two so far. Whether F2 makes this a third is the
maintainer's judgment at the gate.

**Amendment returns:** two — AC3 at implement time, and AC4's recorded-text
clause at pass 2, discharged without an amendment.
