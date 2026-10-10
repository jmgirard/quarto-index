<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M110: The site says which Quarto renders a Typst book

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — the published site pages that authors read   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m110-typst-book-pages   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The Books page names the Quarto that Typst books were tested on, and the Typst
page states only true facts about Quarto 1.5.52.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the Typst-book paragraph of `site/books.qmd` (lines 250-254) and the
Books section of `site/typst.qmd` (lines 94-101); the suite's page-claim rows
that pin their sentences (`tests/run-tests.sh:30766-30855`) and a retired-phrase
row for the false clause.

**Out:** each test book's exit status on Quarto 1.5.52 → not stated, by the
user's choice at the plan gate. A CI job running the suite on Quarto 1.5.52 →
its existing candidate row. A changelog entry → none, since no behavior
changes.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [x] AC1: In `site/books.qmd`, the paragraph that opens "A Typst book is
      merged the same way" says that Typst books were tested on Quarto 1.10.18
      and that Quarto 1.5.52 does not render one.
- [x] AC2: In `site/typst.qmd`'s Books section, the sentences about Quarto
      1.5.52 say that it logs `The typst format is not supported by book
      projects` and writes no PDF, and state no exit status for Quarto 1.5.52.
- [x] AC3: No `site/*.qmd` page and not `README.md` contains the phrase
      `exits without an error`, as `tests/sitecheck.py phrase-absent` sweeps
      them.
- [ ] AC4: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` pass on
      the local Quarto with the finished pages.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T2, T3
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: In `site/typst.qmd:99-101`, delete the clause `exits without an
      error`, keeping the quoted warning and that no PDF is written. Re-read
      the whole Books section for any other claim about Quarto 1.5.52.
- [x] T2: In `site/books.qmd:250-254`, keep the sentence "A Typst book is
      merged the same way." and add that Typst books were tested on Quarto
      1.10.18 and that Quarto 1.5.52 does not render one, pointing to the
      Typst page. Re-read the paragraph whole.
- [x] T3: In `tests/run-tests.sh`, replace the `floor warning` row of
      `m098-typst-claims.txt` with T1's sentence, add rows to
      `m098-other-claims.txt` for T2's sentences, and add `exits without an
      error` to a `phrase-absent` ledger. Show each new or changed row red on
      a scratch copy of its page that lacks the sentence, or that carries the
      phrase again, before trusting it green.
- [x] T4: Run `tests/run-tests.sh`, then `tests/run-tests.sh --self-test`,
      one at a time, and record the Quarto version and the check counts. Re-run
      a render that fails with Quarto's Deno segfault before reading it as the
      change's (`cairn/PROFILE.md` verify).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete. -->

- 2026-10-10: created by /milestone-plan. It promotes the [high] candidate row on `site/books.qmd` and `site/typst.qmd` (added 2026-10-01, extended 2026-10-02, from the M108 review and M109 review D6). Both halves of that row are in this milestone.
- 2026-10-10: question set: which work to plan: the Typst book wording fix. How the Typst page describes Quarto 1.5.52: the warning and no PDF only. No download of Quarto 1.5.52 is granted.
- 2026-10-10: plan gate chose stating only the warning and the missing PDF over stating each test book's exit status. The two test books exit differently on 1.5.52 (0, and 1 after a TypeError), and two examples do not support a general rule. Falsified by an author reporting they need the exit status to read a failed build.
- 2026-10-10: criteria audit (full mode, fresh Opus reader): nothing on AC1. On AC2, the books' exit statuses differ, so an exit-status sentence claims more than was observed. AC2 now asks for the warning and no PDF, and no exit status. On AC3, a ban on every paraphrase has no procedure. AC3 now names the literal phrase over the files `phrase-absent` sweeps (`git ls-files 'site/*.qmd'` and `README.md`). AC3 also bound the suite, an instrument. It now states a page property, and the ledger rows moved to T3.
- 2026-10-10: collision sweep: the candidate row is absorbed. M109 (done) gated the suite's Typst-book checks, not the pages. D-065 and D-067 govern suite checks, not page text. No D-entry rejects this work. Inbox: 0 open issues, 0 open PRs.
- 2026-10-10: lessons: M080 (replacing one false claim leaves a page's others standing) shapes the re-reads in T1 and T2. PROFILE verify notes (sequential runs, the Deno segfault re-run) shape T4.
- 2026-10-10: the local Quarto is 1.10.19, not the 1.10.18 that `pages.yml` pins, so the D-065 pinned-only checks will print skip lines in T4. No changelog entry, since the pages change and no behavior does.
- 2026-10-10: implement started on branch m110-typst-book-pages, main synced and unmoved. No question owed: nothing the plan left open needs a permission.
- 2026-10-10: T1-T2: `site/typst.qmd` drops the clause `exits without an error`. `site/books.qmd` adds "Typst books were tested on Quarto 1.10.18." and "Quarto 1.5.52 does not render a Typst book." Neither page carries another Quarto 1.5.52 claim (grep `1\.5`).
- 2026-10-10: T3: `floor warning` row rewritten, rows `typst tested` and `typst floor` added to `m098-other-claims.txt`, and `m110-retired.txt` holds `exits without an error` for `phrase-absent`. Three `--self-test` plants (each new Books sentence dropped, the clause restored on an overlay Typst page) each turned red on its own row in a scratch run. The main-branch pages fail the new rows, and the finished pages pass them.
- 2026-10-10: T4: the first run stopped at the PyYAML check, because `/usr/local/bin/python3` (3.14.6) has no PyYAML. With a link to `/usr/bin/python3` (3.9.6) first on `PATH`, Quarto 1.10.19: "All checks passed (893 checks)", 9 skip lines, each a pinned-only check naming 1.10.19. `--self-test`: "All checks passed (1764 checks)", the three M110 plants red on their own rows. PROFILE.md's `verify` now names the interpreter.
- 2026-10-10: claim audit: 13 claims read, 0 corrected — site/books.qmd, site/typst.qmd, tests/run-tests.sh. Its one wording note led to the M110-AC3 failure message naming the phrase it matches, before the `--self-test` run.
- 2026-10-10: implement done, status review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->

Evidence at 859f922, Quarto 1.10.19, `/usr/bin/python3` 3.9.6 first on `PATH`.

- AC1: `site/books.qmd:250-255` reads "Typst books were tested on Quarto 1.10.18. Quarto 1.5.52 does not render a Typst book." in the paragraph opening "A Typst book is merged the same way". `sitecheck.py claims site/books.qmd` with the suite's `m098-other-claims.txt` rows: all 3 stated.
- AC2: the Books section (`site/typst.qmd:93-101`) says Quarto 1.5.52 "prints the warning `The typst format is not supported by book projects` and writes no PDF". Printing a warning is logging it, so the sentence says what AC2 names. A grep of the section for `exit`, `status` and `error` finds nothing. `sitecheck.py claims site/typst.qmd` with `m098-typst-claims.txt`: all 36 stated.
- AC3: `sitecheck.py phrase-absent` with `m110-retired.txt`: the phrase is on none of the 23 files swept (every tracked `site/*.qmd` page and `README.md`). `git grep -i 'exits without an error' -- 'site/*.qmd' README.md` finds nothing.
- consistency gate: `cairn_validate.py` all checks passed. No DESIGN.md principle changed, so `cairn_impact` is skipped. The generic profile names no toolchain checks.
- AC4 first pass at 859f922: plain run "All checks passed (893 checks)", 9 skip lines. `--self-test` failed at M21-AC4 on a Quarto Deno `Segmentation fault: 11` rendering `examples/range-misuse.qmd`, which the branch does not touch (PROFILE.md `verify`). Re-run after the fix-now commit below.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: the rewritten `floor warning` row had no lasting `--self-test` plant — fix now (plant `m110-warning-lost`).
- diff-bug #2: the new Books rows fail under the label M098-AC7 alone, though they serve M110-AC1 — fix now (the message names both). The `M098 self-test (m110-…)` plant label stays, since `m098_red` names the helper and the slug names M110.
- diff-bug #3: the banned phrase is generic and case-folded, so a true sentence about another command would fail — reject, planned change: AC3 names this literal phrase over this sweep, and the FAIL line names the phrase.
- diff-bug #4: the Books plants hardcode the line break in "Typst books were\ntested" — fix now (the plants match across any whitespace, and a rewrapped copy was shown to work).
- diff-bug #5: PROFILE.md's "observed 2026-10-10, M110" is the wrong date, since M109 ran the same workaround on 2026-10-02 — reject, false: a dated observation records when this observation was made. The note sits beside the slot's other notes about this machine.
- diff-bug #6: the warning quoted on the Typst page and `TYPST_BOOK_REFUSAL` are two strings no check holds equal — follow-up, new candidate row "Hold the Typst pages' Quarto facts to their sources" (pre-existing, not widened by this diff).
- diff-bug #7: "tested on Quarto 1.10.18" rests on the M098 and M109 runs, not on this milestone's 1.10.19 run — reject, false as a defect: the sentence names the version CI pins, and it holds.
- diff-bug #8: the T4 counts 893 and 1764 were not checked by the reviewer — reject, false: the review runs above and below give fresh counts.
- blame-history #1: the change deletes M108's clause "exits without an error" — reject, planned change.
- blame-history #2: both pages now state the tested version and the refusal, and can drift apart — reject, planned change: AC1 asks for it, and claim rows pin each copy.
- blame-history #3: "tested on Quarto 1.10.18" while T4 ran on 1.10.19 — reject, false as a defect (as diff-bug #7).
- blame-history #4: the Books plant hardcodes a line break — fix now (as diff-bug #4).
- blame-history #5: the ban matches one literal phrase — reject, planned change (as diff-bug #3).
- blame-history #6: PROFILE.md's note is specific to this machine — reject, false as a defect: the `verify` slot already carries this machine's Quarto path note.
- prior-review #1: M109 D6 is resolved, not contradicted — reject, false as a defect: it confirms the fix and requests nothing.
- prior-review #2: the restored-phrase plant does not break its line inside the phrase (LESSONS M41/M52) — fix now (the plant breaks it between "without" and "an error", and is red).
- prior-review #3: the ban catches one wording only — reject, planned change (as diff-bug #3).
- prior-review #4: the tested version 1.10.18 sits in several places with nothing tying it to the pin — follow-up, the same new candidate row as diff-bug #6.
- prior-review #5: the M080/M081 lesson is met — reject, false as a defect: it requests nothing.
- fix-now commit: diff-bug #1, #2, #4, blame-history #4 and prior-review #2, fixed 372d0e9. Each of the four plants was red on its own row in a scratch run, the restored phrase broken across a line, and a rewrapped Books copy still built its plant.
- AC4 second pass at 372d0e9: plain run "All checks passed (893 checks)", 9 skip lines. `--self-test` failed at M11-AC1 on a second Deno `Segmentation fault: 11`, rendering `empty-levels.qmd` to PDF, again a render the branch does not touch. Re-run pending.
