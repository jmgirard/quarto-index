# M06: Sort keys

- **Status:** in-progress
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
- [x] AC6: README documents `sort=` — syntax, per-level alignment, the
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

- AC1 → T1, T2, T3
- AC2 → T1, T4, T6
- AC3 → T2, T4, T7
- AC4 → T1, T5, T8
- AC5 → T5, T6
- AC6 → T9
- AC7 → T9

## Tasks

- [x] T1: Parse `sort=` in the Span pass beside `entry=`
      (`index.lua:341`), reusing `parse_levels` (`index.lua:139-159`), and
      align it positionally against the derived levels before the back-end
      branch (`index.lua:399-402`) so both back-ends see one representation.
      A level with no sort key falls back to its printed text. Amended in
      flight: the parse moved into a third filter pass ahead of the emitting
      one — see this file's Decisions.
      *(RB tripwire: ip-touching — IP1 format-neutrality of the new syntax.)*
- [x] T2: LaTeX emission: extend `index_argument` (`index.lua:236-242`) to
      write `sortkey@printed` per level, keeping `LATEX_LITERAL`'s `"@`
      quoting (`index.lua:92`) for every `@` the extension does not itself
      write as the separator.
- [x] T3: `examples/sortkey.qmd` fixture (multi-level entries, a
      second-level-only sort key, terms whose sort order differs from printed
      order) and its sort-stripped twin; PDF check in `tests/run-tests.sh`
      with the manifest derived from the fixture by construction.
- [x] T4: HTML collation: carry the sort key onto the entry-tree node
      (`new_entry`, `index.lua:534-536`; `build_entry_tree`,
      `index.lua:547-580`) without changing node identity — `children` stays
      keyed by printed level text — and compare sort keys in
      `number_entries`' `table.sort` (`index.lua:593`), ties falling through
      to `collate` on the printed text.
- [x] T5: Book path: add the sort key to the sidecar mark record
      (`index.lua:1056-1057`), accept it in `valid_record`
      (`index.lua:1093-1121`), bump `STORE_VERSION` to 2 (`index.lua:970`);
      add a cross-chapter sort key to `examples/book/` and a cross-chapter
      conflicting-sort-key fixture.
- [x] T6: HTML checks for the sortkey fixture and its twin in
      `tests/htmlindex.py` + `tests/run-tests.sh`, asserting order at every
      level.
- [x] T7: Extend the escaping probe to `sort=` values across PDF, HTML and
      gfm legs.
- [x] T8: The three diagnostics, their message text recorded in this file's
      Decisions section, their control renders, and the reversion proof for
      each.
- [x] T9: README `sort=` section; update `README_HTML_CLAIMS` and add the
      `README_STALE` absence assertion; run `tests/byte-diff.sh` and
      `tests/run-tests.sh --self-test`.

## Work log

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

## Review

**PR:** https://github.com/jmgirard/quarto-index/pull/6

All evidence below is from a fresh `tests/run-tests.sh --self-test` run on
2026-08-17 at the branch head (exit 0, **110 checks**, against 89 at the merge
base), plus `tests/byte-diff.sh` and `cairn_validate` runs of the same date.

**AC1 — PDF order and nesting.** Four checks. The manifest is verified against
the fixture by construction ("names every one of the 7 sort keys
examples/sortkey.qmd declares, and no others"); the compiled PDF "prints all 8
index entries in the order and nesting their sort keys derive", read from
`pdftotext -bbox-layout` word positions because a two-column index interleaves
under plain extraction; and the twin proves the ordering is the keys' doing —
"removing the sort keys moves every one of the 6 top-level entries". The twin
is itself verified to be the fixture minus its `sort=` attributes and nothing
else.

**AC2 — HTML order at every depth.** Four checks. The generated index "matches
all 8 manifest rows, in order" and the twin's likewise; the two manifests are
asserted to disagree at every position — "the sort keys move all 8 entries, at
every one of the 2 depths the index nests to" — so neither could be satisfied
by an index that ignored sort keys. All 8 index links resolve.

**AC3 — every printable ASCII character as a sort key, three formats.** Four
checks. The domain is derived by construction from the same 0x21–0x7E range
the entry-key probe uses ("covers all 94 printable ASCII characters"). LaTeX:
"all 94 entries accepted" by makeindex, which is where a missing quote on an
author's `@` or `!` would surface. HTML: "all 94 sort-keyed entries reach the
HTML index, and it carries no others". gfm: "all 94 sort keys change nothing
but the one attribute carrying each, so none reaches visible text", compared
against a sort-stripped twin.

**AC4 — the three reports.** Seven checks. Each fires exactly once in `latex`
and once in `gfm`; the cross-chapter case — invisible to a single document,
since each chapter renders in its own process — "is reported once, and the
first chapter in book order wins". The control confirms none fires on the
well-formed fixture, and each of the three is proved discriminating by
`warn_discrimination`, failing both when removed and when duplicated. The
message texts are those recorded in this file's Decisions section.

**AC5 — book aggregation across chapters.** The aggregated book index matches
all 10 manifest rows in order, with `Shared Term` filed under its cross-chapter
sort key. That the key crosses a chapter boundary is asserted by construction
rather than assumed: "the book's sort key(s) are declared in ['index.qmd'] and
the marker is in ['last.qmd']".

**AC6 — README.** "All 8 documented sort-key behaviors appear verbatim in
README.md"; the superseded sentence declaring sort keys out of scope is pinned
absent ("all 5 stale pass-through sentences are gone"); the collation claim was
updated in place rather than left contradicting what ships ("all 7 HTML claims
appear"); and the two new authoring exemplars are pinned ("all 9 normative
syntax exemplars appear verbatim").

**AC7 — verify slot and byte-identity.** `tests/run-tests.sh --self-test`
exit 0, 110 checks. `tests/byte-diff.sh`: "Every merge-base fixture renders
byte-identically" across the 13 top-level fixtures it enumerates via
`git ls-tree`, so a document writing no sort key emits the LaTeX it always did.

**Consistency gate.** `cairn_validate` — all checks passed. `cairn_impact` not
run: no `DESIGN.md` principle changed (the DESIGN edit corrects a description
of behavior, not an IP/GP). Profile `generic` names no toolchain checks, so
that half of the gate is a clean no-op.

### Review findings (three-lens fan-out, 2026-08-17)

**[O] diff-bug — 6 confirmed defects, 4 test-quality findings, 3 suspected.**
**[S] blame-history — no confirmed regressions** (traced every `derive_levels`
branch against the pre-diff `Span` body; zero lines changed in
`LATEX_LITERAL`, `escape_level`, or the anchor machinery). One asymmetry
noted for a human: `clamp_sort` truncates where `clamp_levels` joins.
**[S] prior-review-record — 2 findings.** GitHub inline-comment probe returned
empty, so the per-PR thread walk was skipped; archived `## Review` sections
were the evidence base.

Dispositions:

- **F1 (floor return).** Sort keys register per full entry PATH
  (`register_sort`/`sort_for`, index.lua:309-334) while HTML applies them per
  LEVEL (`build_entry_tree`, index.lua:757-767). Reproduced independently:
  `entry="Aaa!sub" sort="!subkey"` beside `entry="Aaa" sort="Zzz"` emits
  `\index{Aaa!subkey@sub}` and `\index{Zzz@Aaa}` — one entry split across two
  makeindex keys, printed twice in two places, silently. F1b shows AC4's
  report (c) not firing when one printed index key is given two different sort
  keys via differing paths — the criterion failing inside its own promise.
  F1c shows an explicit `sort="Zzz"` discarded outright in HTML because a
  sibling mark's printed-text fallback already occupied `child.sort`. Also
  falsifies the README sentence pinned by `README_SORT_CLAIMS`.
- **F2 (floor return, load-bearing).** Consecutive empty sort levels are
  unexpressible: `parse_levels` reads `!!` as a literal `!`. Reproduced:
  `entry="aaa!bbb!ccc" sort="!!Zed"` emits `\index{"!Zed@aaa!bbb!ccc}` —
  level 1 filed under the literal `!Zed` instead of level 3 redirected. No
  warning. Falsifies the README's "you only write the levels you are actually
  moving" for any level ≥3 or any non-leading gap.
- **F3 (fix on return).** LaTeX sorts on the LaTeX-ESCAPED key
  (`index_argument`, index.lua:357-372) while HTML sorts on the raw one, so
  the back-ends order differently for any key containing an escaped
  character. makeindex half inferred, not compiled — verify when fixing.
- **F4 (fix on return).** `book_sort_keys` (index.lua:1389-1409) warns per
  conflicting MARK, not per entry; masked only because the fixture marks the
  term once.
- **F5 (fix on return).** `clamp_sort` silently drops sort levels past the
  third, and `index_argument`'s `keys[i] ~= level` guard always misfires on
  the folded level 3, emitting a redundant sort field.
- **F6 (fix on return).** `DESIGN.md:100` still says "two passes" (now three);
  `DESIGN.md:43` still says sort keys land later; the LaTeX bullet never
  mentions `sortkey@printed`.
- **F7, F8, F9, F10 (fix on return).** No fixture covers the F1 class and the
  AC4(c) probe is its weakest instance; `WARN_BOOK_SORT_CONFLICT` has no
  `warn_discrimination` proof and its count silently encodes a render-order
  assumption; the AC3 LaTeX leg cannot distinguish correct escaping from no
  sort field emitted at all; manifest 1n's header attributes the PDF order to
  the HTML collation rule rather than makeindex's.
- **Prior-review F-a (follow-up).** `sort_conflicts` (index.lua:300) is a
  third module-level accumulator, widening the standing ROADMAP row from M01
  review R16 / M03 review P1 — absorb into that row.
- **Prior-review F-b (follow-up).** The sort-key extraction regex is
  double-quote-only, propagating the M01 review N9 blind spot; no false pass
  today since every fixture quotes its values — absorb into that row.
- **F11, F12, F13 (suspected, carry to the fix).** Silent no-op for
  `sort=""`; warning text renders `!` doubled; the v1-store warning
  attributes a version bump to unreadability.

**Verified clean by the [O] lens:** the `@` separator escaping (every author
`@` quoted, only the back-end's bare), `sort=` combined with cross-references,
`number_entries`' comparator totality, once-per-mark warning firing,
`levels_key` injectivity, and no manifest copied from output anywhere in the
diff (the ORACLE RULE holds).

**Amendment returns:** one, at implement time and before review — AC3, gated
and user-approved (see the work log). No defect returns.

