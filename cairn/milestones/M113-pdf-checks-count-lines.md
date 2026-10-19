<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M113: PDF index checks count whole printed lines

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP6   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — acceptance-suite checks and a suite reader, which no user of the extension runs   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m113-pdf-checks-count-lines   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Five acceptance-suite readings of a compiled PDF index fail on a wrong index
that they pass or read short today.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a cluster of the older acceptance-suite backlog, the three entries
KI69, KI312 and KI313 in `cairn/DESIGN.md`, which M112's review left. The
M02-AC2 and M02-AC3 typeset checks, AC6's term check and the M05-AC5 check
read the index through `tests/pdfindex.py`'s `read` and count a manifest row
as the printed index lines that equal it, rather than as substrings of the
flattened `pdftotext -layout` text (KI313, KI69). M05-AC5 also takes each
term's page count from that one line, where it now takes the first match.
`tests/typstindex.py`'s own `read` gets the stranded-line refusal M112 gave
`tests/pdfindex.py`'s (KI312). Each repair gets a self-test case, and the
three entries are removed from `cairn/DESIGN.md`.

**Out:**
- KI53, KI104 and every other entry under the two acceptance-suite
  subheadings: stays under the backlog candidate row, for a later cluster.
- The EPUB checks' dead code (KI92, KI94, KI95) and the missing-log counts
  (KI311): stay on their own parked candidate rows.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: The M02-AC2 and M02-AC3 typeset checks in `tests/run-tests.sh`
      count a manifest row as the printed index lines, read by
      `tests/pdfindex.py`'s `read`, whose text with whitespace collapsed
      equals the row, and fail naming the row when that count is not 1. A
      row's text occurring inside a longer printed line adds nothing to its
      count.
- [x] AC2: AC6's term check in `tests/run-tests.sh` counts a manifest term
      as the printed index lines, read by `tests/pdfindex.py`'s `read`,
      whose `term` (the line with its locators removed) equals it, and fails
      naming the term when that count is not 1.
- [x] AC3: The M05-AC5 check reads the book PDF's `Index of Subjects`
      through `tests/pdfindex.py`'s `read`, bounded by
      `stop=('Index of People',)`. It counts each term row as the lines
      that read returns whose `term` equals it, and each cross-reference row
      as the same lines whose text equals it; those lines include the body
      prose printed between the two indexes. It fails naming the row when a
      count is not 1, and fails naming the term when the pages its one
      line's locators cover, a range counted as every page in it, differ
      from the row's stated page count.
- [x] AC4: `tests/typstindex.py`'s `read`, given `stop`, raises LookupError
      naming the page and the lines when the page it leaves out prints a line
      ahead of its first line, in reading order (left column before right,
      each top to bottom), that starts with a stop string: one above that
      line, or, where that line sits in the right column, one in the left
      column. A line that itself starts with a stop string, or that is
      printed on the same row as one, as a running header's page number is,
      is not ahead. Today such lines are dropped with no message.
- [x] AC5: A run of `tests/run-tests.sh --self-test` on the fixtures'
      current output passes every check it runs, M02-AC2, M02-AC3, AC6,
      M05-AC5 and every `tests/typstindex.py` reading among them.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T3
- AC5 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Move the line count into a function that takes `pdfindex.read`'s
      entries and the manifest rows, so a self-test can feed it planted
      entries. Rewrite `xref_typeset_check` (`tests/run-tests.sh` ~7290) to
      read the PDF through it rather than the `pdftotext -layout` text, for
      M02-AC3 (`xref-escaping.pdf`) and M02-AC2 (`demo.pdf`). Drop its
      row-inside-another-row refusal if whole-line counting makes it
      unneeded, and say so in the comment. Rework the M112 T1 self-test
      cases (~7383) to plant entries: one row's line given twice is red
      naming that row, a line that holds the row inside longer text is green,
      and the unplanted entries are green.
- [x] T2: Point AC6's term check (~7343) and the M05-AC5 check (~7900) at
      the same function, terms compared by each line's `term`. In M05-AC5,
      replace `pages_after`'s first-match search with the page total of the
      term's one line, keeping its range arithmetic. Add self-test cases: a
      manifest row's line given twice is red naming that row, for each
      check, and a manifest row stating one page fewer than its term's line
      covers is red naming the term.
- [x] T3: In `tests/typstindex.py` `read` (~514-568), when `stop` ends the
      read, check the left-out page for a line ahead of its first line that
      starts with a stop string, column-aware as `tests/pdfindex.py`'s `read`
      is, and raise naming the page and those lines; update the docstring,
      which says the refusal is absent. Add a `--self-test` case that feeds
      `read` stubbed `_pages` output with such a page and asserts the
      message, plus one where a running header is the first line and is
      green. Exempt a line starting with a stop string and a line on the same
      row as one (y0 within 1pt); plant a line one row below a right-column
      header, which stays refused. Add `A second placement marker` as a
      second stop of the M098-AC5 main read (~30765), whose left-out page 14
      prints body prose below its running header.
- [x] T4: Remove KI69, KI312 and KI313 from `cairn/DESIGN.md`, check that no ROADMAP row
      names a removed entry, and update every suite comment that describes
      the old substring reading of these checks. Run
      `tests/run-tests.sh --self-test` green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: collision check: absorbs a cluster of the older acceptance-suite backlog row (KI69, KI312, KI313, the follow-ups M112's review left); no planned or in-progress milestone, archive entry or D-entry overlaps; checker-regress shape judged not to fire, since the readers read the extension's compiled PDF, not repo-internal artifacts (as at M112).
- 2026-10-19: inbox sweep: no open issues or PRs on jmgirard/quarto-index.
- 2026-10-19: lessons harvested: check-design's M10 line (a check naming entries by their printed text goes vacuous) holds here as a red, not a vacuous pass, since a line that gains text counts 0 and fails as missing.
- 2026-10-19: plan gate chose counting whole printed lines read by `tests/pdfindex.py` over counting word-boundary-anchored substrings of the flattened `pdftotext -layout` text, because a boundary anchor still double-counts a row that sits inside a longer line after a space; falsified by a fixture whose index `pdfindex.read` cannot split into one line per entry. A plan-time read of the current demo, xref-escaping and book captures gave one line per manifest row.
- 2026-10-19: reduced criteria audit (Opus, fresh context): AC4 (now AC5) reworded from "every typstindex call that passes a stop string" to the whole run's checks, since no list of those calls was named; no other finding on AC1-AC4.
- 2026-10-19: question set: which work — the PDF line counts (this milestone); the M05-AC5 term rows' first-match page count — fix it here (user's choice over recording a Known issue), so AC2 split into AC2 and AC3.
- 2026-10-19: reduced criteria re-audit of the new AC2 and AC3 (two Opus readers, fresh context): one found AC3's "printed index lines" false for the book, whose bounded read also returns the body prose between the two indexes; AC3 narrowed to the lines the read returns, prose included. The other found nothing.
- 2026-10-19: status in-progress; branch m113-pdf-checks-count-lines cut from main at fea09c9.
- 2026-10-19: T1 done: `pdfindex.line_counts` counts a row as the entries whose `text` (or `term`) equals it, whitespace collapsed; `xref_typeset_check` reads the PDF through it and takes an optional planted-lines file in place of the region-dump size; the row-inside-another-row refusal is dropped, since whole-line counting makes it unneeded; the M02-AC3 `pdftotext -layout` call is removed. Checked against the 2026-10-18 captures (both green, a twice row red naming it, a longer line holding the row green); the full `--self-test` run is at T4, since a run takes about 15 minutes.
- 2026-10-19: T2 done: AC6 is now `pdf_term_check` and M05-AC5 `book_pdf_check`, both reading through `pdfindex.read` and `line_counts` with the planted-lines argument; M05-AC5 reads a term's pages from its one line's locator tail. The demo `pdftotext -layout` call is removed; the book's stays, since `m21probes.py bookpdf` and a later heredoc read `book.txt`. Minor amendment: T2's page case plants the manifest (one page fewer), because a second line for the term trips the line count before its pages are read. Checked against the 2026-10-18 captures: both green, and each plant red naming its row.
- 2026-10-19: T3 done: `typstindex.read` refuses, naming the page and the lines, a line ahead of the left-out page's first stop-matching line, column-aware as `pdfindex.read`; docstring updated. Self-test beside M112 T3's: control and running-header pages green, stranded line above and left-column cases red naming page 2 and the line; run against the pre-change `typstindex.py` it is red at the stranded-line case, so it discriminates. The M098 bounded read of the 2026-10-18 capture stays green.
- 2026-10-19: T4 suite run 1 stopped at the tool guard: `/usr/local/bin/python3` is now 3.14.6 with no PyYAML, ahead of `/usr/bin/python3` 3.9.6 (PyYAML 6.0.3, which M112's run used). Later runs set `PATH=/usr/bin:$PATH`; nothing installed. The T3 self-test also ran green under 3.14.6. Run 2 stopped on a Quarto segfault in the M084 T6 self-test, which no file of this branch touches.
- 2026-10-19: T4 suite run 3: every check this milestone changed passed, then M098-AC5 (main) was refused by T3's new rule. The Typst book's left-out page 14 holds a running header row ('14' left, 'Chapter 4. Index of Subjects' right) and body prose, and the old read dropped it in silence; page 16 holds a header row only. AC4 as written refused both, so it conflicted with AC5.
- 2026-10-19: substantive amendment: AC4 now reads the first stop line in reading order and exempts a line that starts with a stop string or shares its row; T3 adds the row exemption, a one-row-below plant and a second stop for the M098-AC5 main read. Wording only for the user: the refusal of a stranded index line is unchanged.
- 2026-10-19: re-audit: AC4 (reduced) — "first line" left open between topmost and reading order, and only reading order is satisfiable with AC5; fixed by "in reading order"; the reader also asked for a one-row-below plant (added to T3).
- 2026-10-19: re-audit: AC4 (reduced) — satisfiable with AC5; asked that the row tolerance be named (moved to T3's text as y0 within 1pt, not into the criterion, since a second re-audit line ends re-entry) and noted "first line" could read as the page's first line (the written wording keeps "its first line, in reading order").
- 2026-10-19: T3 amended code: `typstindex.read` exempts stop lines and lines within `SAME_ROW_PT` (1pt) of one; M098-AC5 (main) and the M098 T5/T9 book plants pass `A second placement marker` as a second stop; T3 self-test gains header-row, header-prose (one row below, still refused, naming only that line) and second-stop cases; green under 3.9.6 and 3.14.6, and both book reads green on run 3's capture.
- 2026-10-19: T4 suite runs 4 and 5 (after the T3 amendment) each stopped on a Quarto 1.10.19 segfault ("Segmentation fault: 11" in Quarto's Deno), at M064-AC3 and M069-AC5, neither touched by this branch; every M113 check that ran before them passed. Three of five runs crashed this way at three different renders, while ten renders of examples/control.qmd in a row all passed; load average about 8.
- 2026-10-19: status blocked: Quarto 1.10.19 crashes at random renders on this machine, so no full `tests/run-tests.sh --self-test` run completes and AC5 has no evidence. The blocker is the local Quarto; resume with `/milestone-implement M113`, which reruns T4's suite. T1-T3 are done and committed; T4's record edits are committed and its suite run is what remains.
- 2026-10-19: resumed at the user's request after they closed Docker and LM Studio; status in-progress. Load average still about 9.9 from other work (four R test and check processes, two Xcode clang compiles), left running; T4's suite run retried.
- 2026-10-19: T4 done: suite run 6, `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` under Python 3.9.6, ended "All checks passed (1773 checks)", exit 0, at 7774a1a; no Quarto segfault this run.
- 2026-10-19: claim audit: not owed — internal tier.
- 2026-10-19: implement complete; status review.

## Review

Evidence: suite run 6 (`PATH=/usr/bin:$PATH tests/run-tests.sh --self-test`, Python 3.9.6, Quarto 1.10.19) at 7774a1a, whose tree outside `cairn/` equals HEAD's; plus fresh reruns, at review, of each repaired check extracted from HEAD's `tests/run-tests.sh` over run 6's captures.

- AC1: run 6 printed `ok M02-AC3: all 66 exact cross-reference strings typeset once each` and `ok M02-AC2: all 7 cross-references typeset once each`, and the M112 T1/M113 T1 self-test line. Fresh rerun of `xref_typeset_check` (reads `pdfindex.read`, counts by `line_counts`): both green; `cats, see Felines` planted once more is red with `<<cats, see Felines>> x2`; `Planted cats, see Felines, longer` planted is green.
- AC2: run 6 printed `ok AC6: PDF index heading found, 10 derived terms printed once each` and the M113 T2 AC6 self-test line. Fresh rerun of `pdf_term_check` (compares `Entry.term` through `line_counts(..., field='term')`): green; `pandoc, 9` planted is red with `<<pandoc>> x2`.
- AC3: run 6 printed `ok M05-AC5: the book PDF prints one index carrying all 10 derived terms once each with their derived locator counts, and all 2 cross-references once each` and the M113 T2 M05-AC5 self-test line. Fresh rerun of `book_pdf_check` (bounded `pdfindex.read`, `stop=('Index of People',)`, which returns the prose lines too): green; `Alpha, 9` planted is red with `'Alpha' is printed on 2 line(s)`; `Delta, see Alpha` planted is red with `printed on 2 line(s)`; a manifest stating Alpha at 0 pages is red with `'Alpha' is followed by 1 page(s) in the printed index, expected 0`.
- AC4: run 6 printed the M113 T3 self-test line (stranded line above, left column below a right-column stop, and one row below a right-column header each red naming page 2 and only that line; control, opening header, split header row and second-stop pages green) and `ok M098-AC5 (main): the 25 lines under 'Index of Subjects' are the manifest's`. Fresh rerun: the T3 self-test green; M098-AC5 (main) green on the book capture; the same read with `Chapter 4.` alone is refused naming page 14 and its prose lines, the first stop line in reading order being the right-column header.
- AC5: run 6 ended `All checks passed (1773 checks).`, exit 0, with every `tests/typstindex.py` reading among them green. Runs 2, 4 and 5 stopped on Quarto segfaults at renders this branch does not touch (work log); run 6 had none.
- Consistency gate: `cairn_validate.py` all checks passed; no principle changed, so `cairn_impact` skipped; the generic profile's gate adds no toolchain check.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the same-row exemption in `typstindex.read` covers any line within 1pt of a stop line's row, not only a page number, so an index line on that row is dropped unseen — follow-up, KI314 under the backlog row; AC4 as written exempts such a line, and narrowing it changes AC4, whose re-audit bound is spent.
- diff-bug #2: the `typstindex.read` docstring and the M098-AC5 comment say body text "below" a right-column header is ahead, where the rule is by column — fix now, fixed 918a628.
- diff-bug #3: the main book read and the T5/T9 plants depend on last.qmd's prose opening words — reject, planned change (the AC4 amendment); a change to that prose fails loudly with "no page carries".
- diff-bug #4: a count of 0 also means the row's line carries extra text, so "did not typeset" or "missing" can be false — follow-up, KI315.
- diff-bug #5: `LOCATOR` accepts an em dash that `Entry.term` does not strip — reject, false impact: makeindex prints ranges with an en dash, and such a line fails loudly as 0 lines.
- diff-bug #6: `pdfindex` folds digit- or comma-only terms into the line above, now on M02-AC3's path — follow-up, KI315; no cross-reference row is affected.
- diff-bug #7: the AC6 plant takes its term with no non-empty guard, and the three checks pass an empty manifest as "all 0" — fix now, fixed 918a628 (guard added; each check refuses an empty manifest by name).
- diff-bug #8: `awk -v t=` reads backslash escapes in the page-short plant's term — fix now, fixed 918a628 (`ENVIRON`).
- diff-bug #9: a right-column line above a left-column first stop line is refused though it follows the stop in reading order — reject, planned change: AC4's "one above that line", as `pdfindex.read` does.
- diff-bug #10: the page-short plant would also be red under the old first-match code — reject, false as a defect: it shows the page clause fires; the one-line change is held by the line-count plants.
- diff-bug #11: the M098 fixture comment says each read stops at the running header, but `places` passes no stop — fix now, fixed 918a628.
- blame-history #1: whole-line counts read a wrapped term or cross-reference as missing — follow-up, KI315.
- blame-history #2: the prose stop couples the read to fixture text, and T5/T9 no longer run the header-only read — reject, planned change; the header-only refusal is held by the T3 self-test's header-prose case.
- blame-history #3: the failure dump shows the first 60 lines read, not a 1500-character region — reject, false loss: each failing row is named, and the old dump was cut too.
- blame-history #4: the M112 row-inside-another-row refusal is deleted — reject, planned change (AC1, T1); M112's archive is history.
- blame-history #5: M05's comment on the boundary-anchored search is gone — reject, false: whole-line equality has no boundary to explain, and the no-page case is in `pages_on`'s comment.
- blame-history #6: the row exemption exists in `typstindex.read` only — fix now, fixed 918a628 (the docstring says "Unlike that read" and why).
- prior-review #1: same as diff-bug #1, reproduced with a stub ("zebra, 3" on a stop line's row read green) — follow-up, KI314.
- prior-review #2: a wrapped row reads as missing, which M15 and M110 met before — follow-up, KI315.
- prior-review #3: the row-inside-another-row guard is gone with no replacement — reject, planned change; whole-line counts do not double count.
- ripple #1: `tests/run-tests.sh` M04-AC2 comment says its collapse matches "the other PDF checks" — fix now, fixed 918a628.
- ripple #2: M04-AC2's term check is still a presence test — follow-up, KI316.
- ripple #3: `pdfindex.read`'s docstring says a header on the left-out page is refused, while `typstindex.read` exempts one — fix now, fixed 918a628 (same change as blame-history #6).
- ripple #4: `tests/gallerycheck.py`'s pdf mode is still a presence test — follow-up, KI316.
- Return floor: no finding shows a criterion failing, and the tier is internal, so none returns the milestone; 7 fixed now, 8 to follow-up (KI314-KI316, under the older acceptance-suite backlog row), 9 rejected.
- Verify after the fixes: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at bb921f8 ended "All checks passed (1773 checks).", exit 0.
