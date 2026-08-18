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
- [x] T10: Re-key sort registration from the entry path to the level path, so
      every mark of one printed level sorts alike and two marks sorting that
      level differently conflict whatever paths they sit on (F1, F1b, F1c);
      the same re-keying per entry in `book_sort_keys` (F4); fixtures for the
      class, with the AC4(c) probe rewritten onto its strongest instance (F7).
      F8 landed here too, in the same check.
- [x] T11: Document that a sort key orders under each back-end's own rules,
      the premise that they could be made to agree having been compiled and
      falsified (F3); the AC3 LaTeX leg strengthened to tell correct escaping
      from no sort field at all (F9).
- [x] T12: `clamp_sort`'s silent drop past level 3 and `index_argument`'s
      misfiring guard on the folded level (F5); `sort=""`, the doubled `!` in
      warning text, and the v1-store warning's misattributed cause (F11-F13).
- [x] T13: `DESIGN.md`'s "two passes" and "sort keys land later" (F6); the
      README's skipped-level rule and the sentence F1 falsifies, re-pinned;
      manifest 1n's header (F10); the two prior-review follow-ups absorbed
      into the standing accumulator ROADMAP row; `--self-test` and
      `byte-diff.sh` clean.

## Work log

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

## Review

**PR:** https://github.com/jmgirard/quarto-index/pull/6

Second review pass, 2026-08-17. All evidence below is from a fresh
`tests/run-tests.sh --self-test` run at the branch head (exit 0, **117
checks**, against 89 at the merge base), plus `tests/byte-diff.sh` and
`cairn_validate` runs of the same date.

**Outcome: returned to `in-progress`** on one load-bearing defect (finding 1
below), with an amendment return riding beside it on AC4's recorded-text
clause. Criteria evidence is recorded first; the findings and their
dispositions follow.

**AC1 — PDF order and nesting.** Four checks, plus two the level-path fix
added. The manifest is verified against the fixture by construction ("names
every one of the 7 sort keys examples/sortkey.qmd declares, and no others");
the compiled PDF "prints all 8 index entries in the order and nesting their
sort keys derive", read from `pdftotext -bbox-layout` word positions; the twin
proves the ordering is the keys' doing ("removing the sort keys moves every one
of the 6 top-level entries"). The new level-path fixture emits "all 9 entries
as the manifest derives them, each of the 5 top-level terms under one key
whether or not a sub-entry follows it". Verified.

**AC2 — HTML order at every depth.** Four checks plus two. The generated index
"matches all 8 manifest rows, in order" and the twin's likewise; the two
manifests are asserted to disagree at every position ("the sort keys move all
8 entries, at every one of the 2 depths the index nests to"). The level-path
index "matches all 9 manifest rows, in order" and all its links resolve.
Verified.

**AC3 — every printable ASCII character as a sort key, three formats.** Five
checks. The domain is derived by construction from the same 0x21-0x7E range
the entry-key probe uses ("covers all 94 printable ASCII characters"). LaTeX:
"all 94 entries accepted" by makeindex, and — new this pass — "all 94 entries
carry a sort field split at the separator the back-end writes, and the index
tool printed every one of them as its text alone", which is what the
acceptance count alone could not tell from no sort field at all. HTML: "all 94
sort-keyed entries reach the HTML index, and it carries no others". gfm: "all
94 sort keys change nothing but the one attribute carrying each". Verified.

**AC4 — the three reports. NOT VERIFIED (amendment return).** The three
single-document reports fire exactly once each in `latex` and in `gfm`, each
is proved discriminating by `warn_discrimination`, and the control confirms
none fires on the well-formed fixture. The cross-chapter half now asserts
which render finds the conflict (0 on the first, 1 on the second) and has its
own discrimination proof. But the criterion promises the diagnostics fire
"with the message text recorded in this milestone's Decisions section", and
the filter emits FOUR sort-related `warn()` literals against THREE recorded
there — the missing one being `index entry "%s" is sorted as "%s" in %s and
as "%s" in %s; one entry cannot file in two places, so the first in book order
wins`, which is precisely the text AC4(c)'s "across two chapters of one book"
probe asserts. The work is right; the criterion assumed (c) had one text. See
the amendment return below.

**AC5 — book aggregation across chapters.** The aggregated book index matches
all 10 manifest rows in order, with `Shared Term` filed under its
cross-chapter sort key, and that the key crosses a chapter boundary is
asserted by construction ("the book's sort key(s) are declared in
['index.qmd'] and the marker is in ['last.qmd']"). Verified.

**AC6 — README. NOT VERIFIED.** The suite's presence checks pass ("all 13
documented sort-key behaviors appear verbatim in README.md"; "all 5 stale
pass-through sentences are gone"; "all 7 HTML claims appear"; "all 9
normative syntax exemplars appear verbatim"). The criterion's promise is
presence, and presence holds — but two of the sentences it pins are false
(findings 1 and 4), and repairing them changes the text this evidence is
about, so the tick is withheld until the evidence is re-gathered against the
corrected wording.

**AC7 — verify slot and byte-identity.** `tests/run-tests.sh --self-test`
exit 0, 117 checks. `tests/byte-diff.sh`: "Every merge-base fixture renders
byte-identically" across the 13 top-level fixtures it enumerates via
`git ls-tree`. Verified.

**Consistency gate.** `cairn_validate` — all checks passed, one advisory
(`sizing`: 13 tasks, past the >10 tripwire, because four repair tasks were
added after the first return; they repair the same deliverable rather than
add scope). `cairn_impact` not run: the DESIGN diff adds and corrects no
numbered principle. Profile `generic` names no toolchain checks, so that half
of the gate is a clean no-op.

### Review findings (three-lens fan-out, second pass, 2026-08-17)

**[O] diff-bug — 10 findings plus 3 suspected.** **[S] blame-history — no
regressions**; it corroborated that the level-path rework and the store bump
match their stated rationale rather than relabelling old behavior, and raised
no item this pass had not already dispositioned. **[S] prior-review-record —
no reintroductions**; the GitHub inline-comment probe returned empty, so the
per-PR thread walk was skipped and archived `## Review` sections plus the
ROADMAP candidate rows were the evidence base.

Dispositions:

- **F1 (floor return).** `register_sort` (index.lua:330-348) registers a
  declared level key even when it equals that level's own printed text, so a
  self-declaration occupies the level path and, being first in document
  order, beats a genuine later key. Reproduced: `entry="One!Two!Three"
  sort="One!Two!Zed"` beside `entry="One" sort="Uno"` emits
  `\index{One!Two!Zed@Three}` and `\index{One}` — `Uno` discarded — with the
  report `index entry in entry="One" is already sorted as "One"`, which reads
  as nonsense. This is what an author gets for following the workaround
  README:196-199 prescribes for two adjacent skipped levels, added in T13.
- **F2 (fix on return).** The in-document conflict fires once per MARK where
  the book side was fixed to fire once per printed level path. Reproduced:
  four marks of one term, three of them agreeing, draw three byte-identical
  warnings for one mistake. The suite's exact count passes only because the
  misuse fixture happens to carry two conflicting marks.
- **F3 (fix on return).** Two pinned normative README sentences are false for
  the HTML back-end, which has no level ceiling. Reproduced:
  `entry="w!x!y!aaa" sort="w!x!y!Zzz"` beside `entry="w!x!y!bbb"` orders
  `bbb, aaa` in HTML — the key honored — and `w!x!y, aaa` before
  `w!x!y, bbb` in LaTeX, the key dropped. `Zzz` is plain letters, so
  "Sort keys of plain letters and digits order the same way everywhere"
  (README:227-228) is false, and "goes with that level" (README:72-75) is
  true only under the LaTeX-scoped heading it sits beneath.
- **F4 (fix on return).** Manifest 1n's derivation comment orders the keys
  "Hague, mathematicians ..., Manet" while the manifest it derives lists
  `Édouard Manet` first. Under the suite's ORACLE RULE the comment is the
  derivation, so the manifest is right only by accident of the prose being
  wrong. The same block was reflowed badly by T13.
- **F5 (fix on return).** The book-conflict check's comment claims the
  second conflicting mark discriminates per-path from per-mark reporting;
  under the version-3 record shape a chapter contributes one map entry per
  path however many marks carry it, so per-mark reporting is structurally
  impossible there and the comment claims more than the check asserts.
- **F6 (fix on return).** `PATHSPY`'s one-key-per-term property splits an
  entry on a bare `!` without honoring makeindex quoting, so the
  `"!Zed@Literal` row files under a junk key and sits outside the property
  the block exists to assert.
- **F7 (fix on return).** index.lua:725-726 still says ordering is
  best-effort "until sort keys land" — the same stale class T13 fixed in
  DESIGN.md and missed here.
- **F8 (fix on return, records).** The cross-chapter conflict message is not
  recorded in this file's Decisions section, which is what AC4's amendment
  return below is about.
- **F9 (follow-up).** Level paths are keyed on unclamped levels while the
  LaTeX back-end prints clamped ones, so a 4-level entry and a 3-level entry
  spelling the folded form collide under two makeindex keys with no report.
  The printed-text collision itself predates this branch; sort keys widen it.
  Candidate row.
- **F10 (reject, out of scope).** The AC4 control render is implied by
  earlier no-warning assertions on the same logs. Redundant, not absent —
  AC4 asks for a control, and one exists.
- **F11, F12 (suspected, follow-up).** The sidecar's `sorts` map is written
  in `pairs` order, so an identical chapter's record is byte-unstable
  (read as a map, so no correctness effect). `clamp_sort` truncates where
  `clamp_levels` joins — documented and intentional, but see F3 for the half
  that was not true.
- **F13 (reject, pre-existing).** The suite cannot run from a clean checkout
  (a check reads `examples/control.tex` before anything renders it). Already
  a standing ROADMAP row from M04 review F9.

**Verified clean by the [O] lens:** the `@` separator quoting (exactly one
unquoted `@` per level, author `@` and `!` quoted), `number_entries`'
comparator totality, node identity in `build_entry_tree`, the shared
`derive_levels` across the three passes, the store round-trip through
`pandoc.json` for empty, numeric-string-keyed and `!`-bearing maps, empty
levels with sort keys, byte identity for documents writing no sort key, and
the ORACLE RULE (no manifest read back from a render; F4 is a wrong hand
derivation, not a derived-from-output one).

**Defect returns:** two — the first pass's AC4/F1 return, and this one. The
third would trigger the descope-or-park disposition; this is not it, and the
same criterion is not failing twice by the same shape (the first return was
AC4 failing on differing level paths; this one is a user-facing defect in a
documented workaround).

**Amendment returns:** two — AC3 at implement time before the first review,
and AC4's recorded-text clause here.
