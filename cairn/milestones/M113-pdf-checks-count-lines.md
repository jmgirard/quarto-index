<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M113: PDF index checks count whole printed lines

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [ ] AC1: The M02-AC2 and M02-AC3 typeset checks in `tests/run-tests.sh`
      count a manifest row as the printed index lines, read by
      `tests/pdfindex.py`'s `read`, whose text with whitespace collapsed
      equals the row, and fail naming the row when that count is not 1. A
      row's text occurring inside a longer printed line adds nothing to its
      count.
- [ ] AC2: AC6's term check in `tests/run-tests.sh` counts a manifest term
      as the printed index lines, read by `tests/pdfindex.py`'s `read`,
      whose `term` (the line with its locators removed) equals it, and fails
      naming the term when that count is not 1.
- [ ] AC3: The M05-AC5 check reads the book PDF's `Index of Subjects`
      through `tests/pdfindex.py`'s `read`, bounded by
      `stop=('Index of People',)`. It counts each term row as the lines
      that read returns whose `term` equals it, and each cross-reference row
      as the same lines whose text equals it; those lines include the body
      prose printed between the two indexes. It fails naming the row when a
      count is not 1, and fails naming the term when the pages its one
      line's locators cover, a range counted as every page in it, differ
      from the row's stated page count.
- [ ] AC4: `tests/typstindex.py`'s `read`, given `stop`, raises LookupError
      naming the page and the lines when the page it leaves out prints a line
      ahead of its first line that starts with a stop string: one above that
      line, or, where that line sits in the right column, one in the left
      column. Today such lines are dropped with no message.
- [ ] AC5: A run of `tests/run-tests.sh --self-test` on the fixtures'
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
- [ ] T2: Point AC6's term check (~7343) and the M05-AC5 check (~7900) at
      the same function, terms compared by each line's `term`. In M05-AC5,
      replace `pages_after`'s first-match search with the page total of the
      term's one line, keeping its range arithmetic. Add self-test cases: a
      manifest row's line given twice is red naming that row, for each
      check, and a term line whose locators cover one page too many is red
      naming the term.
- [ ] T3: In `tests/typstindex.py` `read` (~514-568), when `stop` ends the
      read, check the left-out page for a line ahead of its first line that
      starts with a stop string, column-aware as `tests/pdfindex.py`'s `read`
      is, and raise naming the page and those lines; update the docstring,
      which says the refusal is absent. Add a `--self-test` case that feeds
      `read` stubbed `_pages` output with such a page and asserts the
      message, plus one where a running header is the first line and is
      green.
- [ ] T4: Remove KI69, KI312 and KI313 from `cairn/DESIGN.md`, check that no ROADMAP row
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
