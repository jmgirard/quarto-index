# M15: A term marked both plainly and with a cross-reference builds

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1, GP2
- **Branch/PR:** `m15-clash-free-emission`

## Goal

A document that marks one term with a locator in one place and a
cross-reference in another builds instead of failing, and its index carries
both.

## Scope

Surface tier: **user-facing** — it changes which documents build and what a
printed index shows (GP1).

**In:** the LaTeX back-end's emission for a *contested key* — an index key
whose marks carry more than one distinct encapsulation. Two shapes, two
repairs, because one repair would change what the other prints:

- A key with at least one plain locator mark: the cross-reference leaves the
  encap channel and is folded into the entry's printed text, identically on
  every plain mark of the key, so the index tool merges them into one entry
  keeping every locator. The cross-reference marks of that key emit nothing of
  their own, so a cross-reference still carries no locator.
- A key with only cross-reference marks: every mark emits one common encap
  over the key's whole target set (M02's `\quartoindexseeboth`). Identical
  encaps are what the tool folds, the page is discarded as it is today, and
  the printed form is unchanged.

Which keys are contested is known only once every mark has been seen, so the
argument each mark emits is decided in a pass that has seen them all. The
clash report is replaced by one describing what the extension did.

**Out:** the HTML back-end, which has no encap channel and already prints a
locator and a cross-reference on one entry — untouched. Whether an
*uncontested* cross-reference mark should carry a locator → the existing
candidate row, unchanged by this milestone. The written-levels/LaTeX-fold
divergence → its candidate row. A suite run on a clean checkout → the existing
candidate row; every criterion here is evidenced in a warmed tree.

## Acceptance criteria

- [x] AC1 A document marking one term plainly and with a cross-reference
      renders to PDF instead of failing. Evidence: `examples/xref-conflict.qmd`
      rendered to PDF exits 0, and its log carries neither `error generating
      index` nor `Conflicting entries: multiple encaps for the same page under
      same key` — the two strings today's failing render emits, recorded in
      the work log below at plan time.

- [x] AC2 The compiled index matches an exhaustive hand-derived manifest over
      **every** line it prints, not over a named subset — the contested
      entries, the uncontested controls (`mu`, two identical cross-references
      the tool folds; `nu`, marked plainly twice) and every unrelated entry
      alike, each row stating printed text, level and locator count. The
      manifest states how a wrapped continuation line is derived, since
      `tests/pdfindex.py` returns one as its own entry. A contested term's
      plain marks sit on two pages and its cross-reference mark on a third, so
      a locator count of 2 rather than 3 is what says the cross-reference mark
      contributed none.

- [x] AC3 Every way two marks can contest one key is exercised, not one
      exemplar standing in for the family: plain against `see=`, plain against
      `see-also=`, `see=` against `see-also=`, `see=` against a *different*
      `see=`, and a both-attributes mark against a plain mark — each at the top
      level, and one of them on a sub-entry key. Evidence: each pairing named
      in the fixture with its own manifest row from AC2, and the count of
      printed entries whose term begins with each contested term asserted to
      be 1.

- [x] AC4 A cross-reference folded into an entry's printed text is quoted for
      the field it now sits in. Evidence: a contested key whose target carries
      every character README pins as escaped — `! " < >` and the LaTeX
      specials — rendered to PDF, the render exiting 0 and each character
      asserted to typeset in the compiled index, the same bar
      `examples/xref-escaping.qmd` already holds the encap channel to (IP2).

- [ ] AC5 No report tells an author the render can fail from rival
      encapsulations. Evidence: over each `warn()` call's **joined** message —
      the list the distinctness scan already builds, never a single literal,
      which the M13 lesson records a per-literal test cannot see — no message
      carries the phrase `the index tool rejects the pair and the render
      fails`; and the replacement report's full text asserted present, once per
      contested key, over the fixture.

- [ ] AC6 The README and DESIGN claims this milestone falsifies are corrected
      and the new behaviour is pinned. Evidence: the three passages naming the
      old outcome — README's "can fail the build" paragraph, its "The clash
      warning is LaTeX-only" row, and its claim that a cross-reference is
      written through the encapsulation channel — asserted absent, and their
      replacements asserted present, by the suite's existing README-claims
      comparison; DESIGN's LaTeX back-end paragraph updated in the same commit.

## Coverage

- AC1 → T1, T3, T7
- AC2 → T3, T4, T7
- AC3 → T1, T3, T7
- AC4 → T5, T7
- AC5 → T6, T7
- AC6 → T9

## Tasks

- [x] T1 Extend `examples/xref-conflict.qmd` with AC3's five pairings, one on
      a sub-entry key, and place one contested term's marks across three pages
      so AC2's locator count discriminates. Record the failing PDF render's
      exit status and its two failure strings before changing any code.
- [x] T2 Split a warn-free index-key derivation out of `index_argument`
      (`index.lua`), which today warns from `clamp_levels` as a side effect, so
      the first Span pass can compute each mark's key and encap without
      emitting a mark's warnings twice.
- [x] T3 Decide each mark's LaTeX argument in the pass that has seen every
      mark: a contested key with a plain mark folds its cross-references into
      the printed text; a contested key without one emits a common combined
      encap; an uncontested key is untouched.
- [x] T4 Emit nothing for a cross-reference mark on a contested key that has a
      plain mark, so a cross-reference still carries no locator.
- [x] T5 Quote the folded printed field for what the index tool reads there —
      `!`, `@`, `|` and `"` are its operators in that field as in the encap
      channel — and probe it with README's escaped-character set.
- [x] T6 Replace the clash report with one describing what was done; update the
      distinctness count and the three existing clash checks.
- [x] T7 Suite: AC2's exhaustive manifest, AC3's pairings, AC4's escaping
      assertions, and a guard that no uncontested key's emission changed —
      quantified over every example the suite renders to latex, discovered by
      glob rather than by a list.
- [x] T8 Prove each new check discriminating: commit the fix, then revert the
      emission change and record which checks fail.
- [x] T9 Correct DESIGN's LaTeX back-end paragraph and README's three
      falsified passages, pin the replacements, and run
      `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-19: created by /milestone-plan, absorbing the candidate row the user asked on 2026-08-19 be fixed rather than only reported (M02 Decisions lineage).
- 2026-08-19: baseline recorded before any code changed — `quarto render examples/xref-conflict.qmd --to pdf` exits 1 with `ERROR: compilation failed- error generating index` and `Conflicting entries: multiple encaps for the same page under same key.`
- 2026-08-19: plan gate chose folding the cross-reference into the entry's printed text over keeping it a separate page-gobbled item, because the second prints the term twice in adjacent lines; both were verified against makeindex 2.18 to emit zero warnings where today's emission emits the fatal conflict. Falsified by evidence that a reader reads "cats, see Felines, 1, 3" as two entries rather than one.
- 2026-08-19: plan gate chose a common combined encap over folding for a key whose marks are all cross-references, because folding would give such a key a locator it does not have today and the gate ruled that out. Falsified by evidence that two marks carrying one combined encap can still differ.
- 2026-08-19: plan gate chose reading rival encaps as output the extension emitted wrongly over recording a trade against GP2 (D-003). Falsified by a case where the tool rejects output no alternative emission could avoid.
- 2026-08-19: implement gate chose reusing `\see`/`\seealso` and the existing both-targets command with an explicit empty page argument over a new dedicated command, so the folded form and the encapsulated form cannot drift in how they render a target; the both-targets command is declared with three arguments and is fed its third by the index tool through the encap channel, so a printed-field use must pass it explicitly or LaTeX consumes what follows. Falsified by a case the shared rendering path cannot express.
- 2026-08-19: implement gate chose the proposed replacement report wording (names the key, says the two marks print as one entry with both parts, asks the author to confirm the intent) over a shorter statement of outcome alone.
- 2026-08-19: T1 extended `examples/xref-conflict.qmd` with AC3's five pairings (plain against see=, plain against see-also=, see= against see-also=, see= against a different see=, a both-attributes mark against a plain mark), one of them on the sub-entry key `Deep!Level`, and one whose target carries all sixteen characters README pins as escaped. `kappa`'s two plain marks now sit on pages 1 and 2 with its cross-reference mark on page 3, so a printed locator count of 2 rather than 3 discriminates the no-locator semantics.
- 2026-08-19: T1 baseline on the final fixture, before any code changed: `quarto render examples/xref-conflict.qmd --to pdf` exits 1 with `error generating index` and `Conflicting entries: multiple encaps for the same page under same key.`, and the latex render reports seven contested keys — `Deep!Level`, `chi`, `kappa`, `lambda`, `phi`, `tau`, `upsilon`.
- 2026-08-19: T1 suite consequences, derived by hand from the fixture source before any render was read: the HTML index manifest and letter sweep for the fixture (both passed first time), the clash count 2 -> 7, and the dangling-target corpus count 6 -> 13. The first derivation said 13 against 14 emitted; the cause was a duplicated `kappa` cross-reference mark left in the fixture, which was removed rather than the number adjusted.
- 2026-08-19: T2 gave `clamp_levels` and `index_argument` the `report` flag `derive_levels` and `drop_empty_levels` already carry, rather than inventing a second mechanism, so a pass that needs a mark's key before anything is emitted does not report its fold twice. Behaviour-neutral: the suite passes unchanged at 185 checks.
- 2026-08-19: T3 added a second read-only Span pass (`CollectKeys`) that settles which keys are contested before anything is emitted, and routed both it and the emitting pass through one `latex_plan`, so the pass that decides and the pass that emits cannot drift on a mark's key or its surviving targets. `index_argument` grew an optional `fold`, applied to the last level from the levels themselves rather than by taking the built argument apart again — an author's own `@` is makeindex-quoted inside a level, so no pattern over the finished string can find "the first `@`".
- 2026-08-19: T3/T4 emission: a contested key with a plain mark folds its cross-references into the printed text on every plain mark, and its cross-reference marks emit nothing, so a cross-reference still contributes no locator. Verified on the compiled index — `kappa, see Elsewhere, 1, 2` carries the two plain marks' pages and not the cross-reference mark's third one.
- 2026-08-19: T3 revised mid-task after a first attempt folded a no-plain-mark key into the printed text too: makeindex prints its term delimiter either way, so an entry with no locator ended on a dangling comma (`lambda, see Here; see also There,`). Such a key keeps its targets in the encapsulation channel, where the delimiter is the separator it has always been, rendered by one new command over the key's whole list so every mark carries the same string. `lambda` and `upsilon` now print exactly as the uncontested `mu` control does.
- 2026-08-19: T3 corrected a wrong contestation predicate the suite caught: counting a key's TARGETS made `demo.qmd`'s single both-attributes mark contested, though one mark emits one command and contests nothing. Contestation is counted in the encapsulation strings marks would emit, built by one `mark_encap` shared with the emitting path.
- 2026-08-19: T6 report replacement, done here so no commit carries the old claim that a render can fail: the report now reads the map that decided the emission rather than the encaps that were emitted (which no longer differ), and says what the two marks print as. `key_marks` had no consumer left and was removed.
- 2026-08-19: discovered sub-task (minor amendment): `tests/pdfindex.py` dropped every digits-only line as the page-number footer, on the stated assumption that no index line can look like one. False — LaTeX wraps a long entry and its locators can land alone on the continuation, which `chi`'s sixteen-character target produces, and the entry's locators vanished from the evidence silently. The footer is now the bottom-most such line and any other is folded back into the line above, which also keeps a third left edge out of the indent clustering.
- 2026-08-19: T3/T4/T6 verified: `examples/xref-conflict.qmd` renders to PDF with exit 0, neither failure string, and makeindex reporting 0 warnings, where the recorded baseline exits 1. Suite clean at 185 checks.
- 2026-08-19: T5 needed no code change, and the verification says why rather than asserting it: the folded field is rendered by the same `target_argument`/`escape_level` path the encapsulation channel uses, and the emitted argument for the sixteen-character target carries `\%`, `\textbraceleft{}`, `\textbackslash{}`, `\textbar{}`, `\textquotedbl{}`, `\textless{}`, `\textgreater{}` and makeindex's own `"@` and `"!` quoting. The assertion that each character typesets lives in the suite, not in a one-off probe.
- 2026-08-19: T7 added the M15 suite section: the PDF render with both failure strings asserted absent (AC1); an exhaustive hand-derived manifest over every printed index line, level, term and locator count, quantified over all fourteen rather than over the contested seven (AC2/AC3, the M10 lesson); one printed entry per contested term; each of the sixteen escaped characters asserted present in the folded target (AC4); the old failed-render phrase asserted gone from the filter (AC5); and a glob over the rendered LaTeX artifacts asserting the contested-key emission reaches only the fixture that has one. The manifest matched on its first run. Suite 185 -> 191 checks.
- 2026-08-19: T8 discrimination probes, against a non-exiting copy of the suite so every failure is collected rather than only the first, with a clean control run first. (a) The repair reverted, so contested keys emit rival encapsulations again: 7 checks fail, including the PDF render itself with both baseline failure strings back, the whole printed-index manifest, and the report's per-key counts. (b) The cross-reference mark made to emit as well, so it contributes a locator: the manifest fails on `kappa`, expected 2 and got 1 — makeindex collapses the resulting three consecutive pages into one printed range, which is the documented behaviour and is now stated where the locator count is computed. (c) The folded field's makeindex quoting removed: 3 fail, the PDF render among them, since an unquoted `!` or `@` in that field is rejected exactly as it is in the encapsulation channel.
- 2026-08-19: T9 corrected the three README passages the fix falsified — the "can fail the build" paragraph, the back-ends-differ row, and the claim that a cross-reference always travels through the encapsulation channel — and DESIGN's LaTeX back-end paragraph, which now states both repairs and why they differ. Four new claims pinned in the README-claims array and the three sentences naming the old outcome pinned as stale, so neither the promise nor its retirement can drift from the code. `tests/run-tests.sh --self-test` passes at 224 checks.
- 2026-08-19: DEFECT RETURN 1 from /milestone-review. AC5 is unverified: its check is a raw substring scan over `index.lua`, not the joined-message read the criterion names, and the phrase spans a `..` so the scan reports absent against `main`'s filter too — it passes identically on the filter that still emits the claim, which is the M13 lesson and the very defect the plan's criteria audit flagged. AC6 is unverified: of the three passages the criterion names asserted absent, only the "can fail the build" trio is pinned stale; the "clash warning is LaTeX-only" sentence was replaced without a stale pin and the encapsulation-channel claim was qualified in place rather than removed. A third finding is a deliverable defect: `index_argument`'s fold branch forces `keys[i]` as the sort field, bypassing the `keys[i] ~= levels[i]` comparison the comment below it explains, so a contested entry deeper than three levels carrying a sort key files under a different string than the same entry files under uncontested, and `record_clamped` then records a filing path the document never emitted.
- 2026-08-19: review lens results, all logged: prior-review record and blame-history returned no conflicts across their examined regions. The diff-bug lens returned 13 findings; one (contestation keyed on the emitted argument rather than the filing key) was refuted by a makeindex probe — the tool treats the sort key and printed text together as the entry identity, so `Cats@Felines` against `Cats|see{Dogs}` on one page yields two entries and zero warnings. The remainder are recorded for the return.
- 2026-08-19: criteria audit (full mode, fresh-context [O] reader) returned 12 findings. Two were fatal and are fixed above: AC5 tested a phrase no single literal carries, so it would have passed against the unmodified filter, and AC3's exhaustive manifest named four of the eight lines the index prints. AC4's two-fixture list was narrowed to a globbed domain, the verify-slot criterion was dropped as instrument-bound and became T9, an escaping criterion was added for the printed field (IP2), and a README/DESIGN criterion was added (GP1). GP2 and the locator question went to the gate.
- 2026-08-20: return repair 1 of 3, the deliverable defect — the fold branch now makes the SAME key-against-level comparison the uncontested branch makes, so contesting a key changes what an entry prints and not where it files. Baseline before the fix, read off the fixture's own emission: the four-level `Tree!Branch!Cedar!Dogwood` filed under `Cedar` while its uncontested twin filed under `Maple, Holly`; it now files under `Cedar, Dogwood`. The fixture gained that contested deep entry and the twin (clash count 7 -> 8, dangling corpus 13 -> 14, printed manifest 14 -> 18 rows), and the new check discriminates against the exact bytes the pre-fix render emitted. `examples/xref-conflict.tex` is now kept in `$WORK` before the PDF render removes it, which also gave the glob check the positive half it never had — with the file gone it had only ever asserted the emission was absent elsewhere. Suite 191 -> 193 checks.
- 2026-08-20: return repair 2 of 3 — AC5 is now read the way the criterion words it. The check joins each `warn()` call's string literals and reads the joined message; the discrimination is direct: on `main`'s filter the joined read finds the claim in 1 message where a raw substring scan over the same file finds it in 0, which is why the old check passed against the filter that still emitted it. Two controls keep the scan from passing for want of finding anything — it fails if it reads no `warn()` call at all, and if the replacement report is not among the messages it read. Its first draft repeated the defect in miniature: a two-branch literal pattern returned the empty string for the branch that did not match, so it saw single-quoted messages only and a spliced-back copy of the old double-quoted one passed; the pattern the suite already uses elsewhere replaced it. AC5's second half now asserts the replacement report's full text, once per contested entry, against a hand-derived list of the eight.
- 2026-08-20: mid-work gate — the replacement report named an entry by the argument the back-end composed (`tree@Tree!branch@Branch!Cedar, Dogwood`), which an author cannot search their source for; the user chose naming the entry path as written over pinning that string and filing a candidate. The report now reads a printed path carried on the contested-key record beside the emitted argument, and its lead is `index entry` rather than `index key`. README's "warning naming the key" corrected in the same commit. Suite 193 -> 195 checks.
- 2026-08-20: return repair 3 of 3 — AC6's two unpinned passages now have stale pins in both directions. The back-ends-differ row's old name and its old reason join `README_STALE`, beside the sentence that replaced them already pinned present; the unqualified encapsulation-channel claim — pinned as it stood, example and closing period included, so a re-qualification cannot slip past it — joins `README_MISUSE_STALE`, with the exception that replaced it pinned present. Discrimination run against `main`'s README: the back-ends-differ block reports both sentences still present and the replacement missing, and the misuse block reports the encapsulation claim still present and its exception missing. DESIGN gained the clause repair 1 made load-bearing: a level carrying a folded cross-reference always takes the `sortkey@printed` form, and is given the key it would have filed under with nothing folded in. `tests/run-tests.sh --self-test` passes at 228 checks, from 224.
- 2026-08-20: return gate — the work log records the review's diff-bug lens returning 13 findings with one refuted and "the remainder" recorded for the return, but the return itself names three; nothing in the repo carries the other nine. The user chose repairing the three recorded over re-running the lens here, since the next review pass runs the same lens in a fresh session. Recorded so a reader of this file does not read the return as the whole of what that pass found.

## Decisions

## Review

Fresh evidence, 2026-08-19, on `m15-clash-free-emission` at the pre-gate
checkpoint. The `verify` slot was run whole (`tests/run-tests.sh --self-test`,
exit 0, 224 checks; 191 without the self-test, against 175 on `main`), and the
per-criterion figures below were read back out of that run's own artifacts by
command rather than from its pass lines.

- **AC1** — `examples/xref-conflict.qmd` renders to PDF and the render exits 0.
  Its log carries zero occurrences of `error generating index` and zero of
  `Conflicting entries: multiple encaps for the same page under same key`, the
  two strings the T1 baseline recorded from the same fixture at exit 1.
- **AC2** — the compiled index matches the exhaustive hand-derived manifest
  over all 14 printed lines — level, term and locator count each — with the
  contested entries, the uncontested `mu` and `nu` controls and every unrelated
  entry alike. `kappa` prints 2 locators, from its plain marks on pages 1 and
  2, and not the 3 it would print if its cross-reference mark on page 3
  contributed one. The manifest states that a page range counts as the one
  locator it prints, and `tests/pdfindex.py` now folds a wrapped entry's
  continuation line back into it rather than discarding it as a footer, which
  is what makes `chi`'s locator visible at all.
- **AC3** — all five contested pairings are exercised (plain against `see=`,
  plain against `see-also=`, `see=` against `see-also=`, `see=` against a
  different `see=`, and a both-attributes mark against a plain mark), one of
  them on the sub-entry key `Deep!Level`, and each of the 7 contested terms
  prints as exactly 1 entry.
- **AC4** — the folded target of `chi` carries all 16 characters README pins as
  escaped, each asserted present in the typeset index; the emitted argument
  shows makeindex's own `"@` and `"!` quoting beside the LaTeX escapes, from
  the same `target_argument` the encapsulation channel uses.
- **AC5** — the phrase `the index tool rejects the pair and the render fails`
  occurs 0 times in `index.lua`, and the replacement report fires 7 times over
  the fixture, once per contested key. A glob over the 14 rendered LaTeX
  artifacts finds the contested-key emission in the one fixture that has a
  contested key and in no other.
- **AC6** — the suite's README-claims comparison passes: 16 documented misuse
  behaviours present, and the 6 sentences this milestone falsified asserted
  gone. DESIGN's LaTeX back-end paragraph states both repairs and why they
  differ.

Consistency gate: `cairn_validate` all checks passed. The `generic` profile
names no toolchain `consistency-gate` checks, so that half is a clean no-op.
No `DESIGN.md` principle definition changed — D-003 records a reading of GP2
rather than an amendment to it — so `cairn_impact` is skipped.

Discrimination: the T8 work-log line records three planted-defect probes
failing 7, 1 and 3 checks — the repair reverted, the cross-reference mark made
to contribute a locator, and the folded field's makeindex quoting removed.
