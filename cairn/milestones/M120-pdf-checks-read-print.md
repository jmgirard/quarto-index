# M120: Four PDF index checks read what the index prints

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — it changes acceptance-suite checks, which no external consumer of the repo relies on
- **Branch/PR:** m120-pdf-checks-read-print

## Goal

If a compiled PDF index prints a checked term on no line or on two, four
acceptance-suite readings of it fail.

## Scope

**In:** The candidate row "Read the printed PDF in more checks", from KI164
and KI316. M02-AC3 holds 48 hand-written cross-reference rows of
`examples/xref-escaping.qmd` to the printed PDF. Its multi-level,
source-entry and non-ASCII marks are compile-and-accept only. M06-AC3 reads
the `.ind` of a separate pdflatex run and never reads Quarto's own PDF of
`examples/sort-escaping.qmd`. M04-AC2 and `tests/gallerycheck.py pdf` test
presence over flattened text, so a term printed twice passes. Each of the
four checks moves to `tests/pdfindex.py` lines and a count. The
cross-reference rows come from `typstcheck.derived_entries`, the source
derivation M098-AC8 uses for the Typst index of the same fixture. The
hand-written 48 rows stay as a fact stated apart from that derivation.
Observed 2026-10-20 on the last run's captures: every checked term already
prints the expected number of times, so the extension does not change.

**Out:** The order of the sort-key PDF index. The LaTeX back-end orders by
the escaped form it writes for a key, as `site/sorting.qmd` documents, and
no independent oracle states that order. The Typst index of the two probes,
which M098-AC8 already reads. The other acceptance-suite gaps stay under
the candidate rows "Cover clashing ids in anchor checks", "Exercise two
paths no fixture reaches" and "Older acceptance-suite backlog".

## Acceptance criteria

- [x] AC1: M02-AC3's typeset check in `tests/run-tests.sh` reads the index
      in Quarto's own PDF of `examples/xref-escaping.qmd`. It holds each
      entry that `typstcheck.derived_entries` derives from that fixture with
      a cross-reference to exactly one line of that index. The expected line
      is the term, then `, see ` and the `see` targets, then `; see also `
      and the `see also` targets. An entry with only `see also` targets has
      `, see also ` after the term. Each `'` is written as `’` and each
      `` ` `` as `‘`. The comparison with the line's text is in NFC. The
      check fails naming each such entry printed on no line or on more than
      one.
- [x] AC2: M06-AC3 reads the index in Quarto's own PDF of
      `examples/sort-escaping.qmd`. It holds each `term-XX` mark that its
      scan of the fixture finds to exactly one line whose term is the mark's
      text. A line's term is the line with its locators removed. The check
      fails naming each mark printed on no line or on more than one. It does
      not check the order of the lines.
- [x] AC3: M04-AC2's PDF check reads `examples/marker.qmd`'s PDF with
      `pdfindex.read` and keeps the lines on the `After the marker`
      heading's page whose position is above that heading. It holds each
      term of `MARKER_PDF_TERMS` to exactly one kept line, compared on the
      line's term. It fails naming each term on no kept line or on more
      than one. If the read finds no `After the marker` line, it also fails.
- [x] AC4: For each shown fixture that the registry gives a PDF manifest,
      `tests/gallerycheck.py pdf` reads the fixture's linked PDF with
      `pdfindex.read` from the `Index` heading. It holds each entry that the
      manifest states to as many read lines, compared on the line's term, as
      the manifest states it. It fails naming the fixture and each entry
      printed on a different number of lines.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T5
- AC3 → T3, T5
- AC4 → T4, T5

## Tasks

- [x] T1: In `tests/run-tests.sh` near `xref_typeset_check`
      (`tests/run-tests.sh:7299`), derive the cross-reference lines from
      `typstcheck.derived_entries`, apply the two quotation-mark facts, and
      count them in the M02-AC3 read beside `XREF_PROBE_TEXT`. Refuse a
      derived line holding a typesetting sequence the two facts do not model.
      Add `--self-test` plants: a derived line printed twice, and a derived
      line missing, one each for a multi-level, a source-entry and a
      non-ASCII mark. Grep the M112 and M113 plants for want strings that
      the change moves before the first run (the M117 lesson).
- [x] T2: After the M06-AC3 `.ind` check (`tests/run-tests.sh:13393`), read
      `$CAPTURE_ROOT/sortesc-pdf/sort-escaping.pdf` and count each scanned
      mark on the line's term. Add `--self-test` plants for a mark printed
      twice and a mark missing.
- [x] T3: Replace M04-AC2's flattened-text read
      (`tests/run-tests.sh:6881`) with the bounded `pdfindex` read of AC3.
      Add `--self-test` plants for a term printed twice, a term missing, and
      a read with no `After the marker` line.
- [x] T4: Change `check_pdf` in `tests/gallerycheck.py` to read through
      `pdfindex.read` and compare counts. Update the module docstring's `pdf`
      paragraph and the M41-AC4 pass line to say what the check now reads.
      Add a self-test case beside the gallery self-tests
      (`tests/run-tests.sh:21330`) that plants a manifest entry printed
      twice.
- [x] T5: Update the comments that call these checks presence tests, strike
      KI164 and KI316 in `cairn/DESIGN.md`, and run
      `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` green.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: which candidate row to plan — "Read the printed PDF in more checks"; plan only that row — yes, the other two rows stay candidates.
- 2026-10-20: promoted the candidate row "Read the printed PDF in more checks" (KI164, KI316) in full.
- 2026-10-20: collision check: M30 (print proof for `escaping.qmd`), M112 and M113 (count lines in M02-AC2, M02-AC3, AC6, M05-AC5) shipped the neighbouring checks; this plan extends them, no D-entry rejects it. No open issue or PR on GitHub.
- 2026-10-20: checker-regress shape considered and not taken: the four checks read the extension's rendered output, not repo-internal tracking files.
- 2026-10-20: KI164 is narrower than it reads: since M02, M02-AC3 holds the 48 special-set rows to the PDF; the gap is the other 207 cross-reference entries and the sort-key probe.
- 2026-10-20: criteria audit (reduced, internal tier): fresh Opus reader returned 3 findings, all scope; AC3 narrowed to the lines above the heading on its page, AC4 narrowed to registry fixtures and to read lines from the `Index` heading. Context claims checked, none false.
- 2026-10-20: plan gate chose `typstcheck.derived_entries` for AC1's expected lines over a new derivation in `tests/run-tests.sh`, because M098-AC8 already derives the same fixture with it; falsified by a cross-reference that the LaTeX and Typst back-ends print with different target text for one source mark.
- 2026-10-20: plan gate chose a count with no order for AC2 over an order check, because the LaTeX order follows the escaped key and has no independent oracle; falsified by a documented ordering rule for escaped sort keys that a check could state apart from makeindex.
- 2026-10-20: plan gate chose a position bound on the heading's page for AC3 over moving the index to a page of its own in `examples/marker.qmd`, because the fixture is shown in the gallery and read by other checks; falsified by the bound reading a body line as an index line.
- 2026-10-20: lessons surfaced: M30 (typesetting facts, NFC), M117 (plants resting on old output), M118 (apply plant substitutions by script), M073 (no suite edits mid-run), M082 (run with `PATH=/usr/bin:$PATH`).
- 2026-10-20: implement started on branch m120-pdf-checks-read-print.
- 2026-10-20: T1 done: `xref_derived_rows` writes 255 rows from `typstcheck.derived_entries`, refusing a row with an unmodelled ligature input (shown red on a planted `a--b`); `xref_typeset_check` now compares in NFC; self-test plants six cases. Checked alone against the last run's capture; the full suite runs at T5. No M112/M113 want string moved: the hand manifest call is unchanged.
- 2026-10-20: T2 done: `sortesc_pdf_check` counts the 94 scanned marks on the line's term in `sortesc-pdf/sort-escaping.pdf`; self-test plants a mark printed twice and a renamed mark the PDF does not print. Checked alone against the last run's capture. Per-task checks run each new block alone because editing `tests/run-tests.sh` mid-run corrupts the run (M073); one full `--self-test` run at T5 is the verify.
- 2026-10-20: T3 done: `marker_pdf_check` reads `marker.pdf` unbounded and keeps lines on earlier pages or above the `After the marker` line on its page (here page 2, y 96-120 kept, heading at y 157); the dropped `pdftotext -layout` file had no other reader. Self-test plants a term printed twice, a term not printed, and an ending heading the PDF lacks. Checked alone against the last run's capture.
- 2026-10-20: T4 done: `check_pdf` reads each linked PDF through `pdfindex.read` and compares per-entry line counts on the term with the manifest's own counts; `extracted_text` removed. The M41 wrong-PDF plant's want string moved to the new message; two new plants change a registry copy (sortkey manifest stating `von Neumann` once, demo manifest stating `pandoc` twice). Checked alone: 5 fixtures, 65 entries, all four PDF plants red with their own message.
- 2026-10-20: T5 done: KI164 and KI316 struck; no other comment in `tests/` called these four checks presence tests (grep for `presence`, `KI164`, `KI316`, `compile-and-accept`). `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` green, 1868 checks, 2026-10-20 12:58-13:12, every M120 check and plant line present.
- 2026-10-20: claim audit: not owed — internal tier.
- 2026-10-20: status review; handing off to /milestone-review.
- 2026-10-20: review: default branch unmoved since the cut (origin/main d76e66f); Copilot round off. Review suite run at 1e13b9e green, 1868 checks.
- 2026-10-20: review fix-now work committed as eafcef2 (19 findings): hand statement for the 255 derived lines, duplicate-line refusal, stricter T1 plants, non-ASCII missing plant, AC3 bound to the heading's page only, NFC in the M04-AC2 and gallery reads, UTF-8 decode in `pdfindex._pages`, wording. KI326 filed for the follow-up.

## Decisions

## Review

Evidence run: `PATH=/usr/bin:$PATH tests/run-tests.sh --self-test` at eafcef2, 2026-10-20 13:30-13:45, "All checks passed (1869 checks)", rc 0. An earlier run at 1e13b9e, before the fix-now work, was green at 1868.

- AC1: `ok M02-AC3: all 255 cross-reference lines the source derives typeset once each in the probe index` (Quarto's own PDF, `xref-pdf/xref-escaping.pdf`, rows from `typstcheck.derived_entries` with the two quotation-mark facts, compared in NFC), beside `the 255 cross-reference lines derived from examples/xref-escaping.qmd are the ones stated by hand`. Failure naming: `M120 T1 self-test` green, so the check went red naming the row on a multi-level, a source-entry and a non-ASCII row printed twice and on each missing from the print.
- AC2: `ok M06-AC3: each of the 94 sort-keyed marks prints on exactly one line of the index in Quarto's own PDF` (`sortesc-pdf/sort-escaping.pdf`, marks from M06-AC3's own regex scan, compared on the line's term, no order read). Failure naming: `M120 T2 self-test` green (a mark printed twice, x2, and a mark the PDF does not print).
- AC3: `ok M04-AC2: ... prints each of the 4 derived terms on exactly one line` (`marker_pdf_check` keeps lines on the `After the marker` line's page with y above it, compared on the term). Failure naming: `M120 T3 self-test` green (a term printed twice, a term not printed, and an ending heading the PDF lacks).
- AC4: `ok M41-AC4: each of the 5 shown fixture(s) with a hand-derived PDF index manifest ... prints each of the 65 entry(s) ... on as many lines as the manifest states it` (registry rows of kind `pdf`, `pdfindex.read` from `Index`, term counts against the manifest's counts). Failure naming: self-test lines for a PDF whose index drops the entries, a manifest stating once a term printed twice (`von Neumann`), and stating twice a term printed once (`pandoc`), each red with its own message.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: the T1 self-test pattern accepted the row named anywhere, so a "printed twice" plant passed on a missing report — fix now, fixed eafcef2
- diff-bug #2: a derived line written more than once would read as printed twice on a correct index — fix now (the derivation now refuses a repeated line, shown red on a planted `P!x05` mark), fixed eafcef2
- diff-bug #3: the non-ASCII missing plant rewrote the target to ASCII — fix now (now `Straßen`), fixed eafcef2
- diff-bug #4: the gallery read runs past the marker fixture's index into its body text — reject, planned change: AC4 as audited reads from the `Index` heading, and a body line equal to a term turns the check red, never green
- diff-bug #5: AC3's code also kept lines on earlier pages, wider than the criterion — fix now (keeps the heading's page above it only), fixed eafcef2
- diff-bug #6: the derived rows ignore a line's level and never flag a cross-reference line the source does not derive — follow-up, KI326 under the "Older acceptance-suite backlog" row
- diff-bug #7: a derived line carries no locators, so an entry with both page marks and a cross-reference would fail — reject, false: no entry of the fixture's derived domain has both, and all 255 lines print as derived
- diff-bug #8: the M41 pass and fail lines still described a presence test — fix now, fixed eafcef2
- diff-bug #9: the T1 pass line called the source-entry plant a target change — fix now, fixed eafcef2
- diff-bug #10: "under two parents" misdescribes `von Neumann` (once at top level, once under `mathematicians`) — fix now, fixed eafcef2
- diff-bug #11: the gallery count compares without NFC — fix now, fixed eafcef2
- diff-bug #12: the refusal comment claimed any ligature input where the tuple lists eight — fix now, fixed eafcef2
- diff-bug #13: the candidate row still cites struck KI164 and KI316 — reject, planned change: post-merge hygiene removes the row this milestone graduates
- diff-bug #14: the `von Neumann` grep relied on a literal tab byte — fix now (`$'\t'`), fixed eafcef2
- diff-bug #15: the gallery path lost M41's pinned UTF-8 decode — fix now (in `pdfindex._pages`), fixed eafcef2
- blame-history #1: the 255 derived rows came from a program, against the suite's ORACLE RULE; M098-AC8's hand statement holds the derivation's terms but not its references — fix now (a hand-stated construction rule now holds every derived line, with a plant), fixed eafcef2
- blame-history #2: an entry broken across two printed lines now counts zero in the gallery check — reject, planned change: AC4 counts whole read lines, and such a break turns the check red, never green
- blame-history #3: the M41 UTF-8 decode fix is lost — fix now, fixed eafcef2 (same fix as diff-bug #15)
- blame-history #4: the gallery read is unbounded — reject, planned change (as diff-bug #4)
- blame-history #5: the gallery check skips NFC — fix now, fixed eafcef2 (as diff-bug #11)
- blame-history #6: M04-AC2's bound changed mechanism, no defect found — reject, false: reports no defect
- prior-review #1: the gallery path lost the UTF-8 decode the M41 review fixed — fix now, fixed eafcef2 (as diff-bug #15)
- prior-review #2: the marker, sort-key and gallery counts skip NFC — fix now for the marker and gallery reads, fixed eafcef2; the sort-key part rejected, false: its domain is ASCII `term-xx` by the fixture's own regex
- prior-review #3: M04-AC2 keeps lines by position only, so a right-column line below the heading drops — reject, false: the heading is full width and set below both columns, so a line below it on that page is body text
- prior-review #4: the gallery read has no `stop` or `from_page` — reject, planned change (as diff-bug #4); none of the five fixtures prints a contents page
- prior-review #5: `!!` and `fi` ligatures are not modelled — reject, false: `!!` to `‼` is Typst's mapping (M30 lesson), and an unmodelled glyph fails loudly
- ripple #1: the M41 self-test pass line names an extraction — fix now, fixed eafcef2
- ripple #2: the M41-AC4 fail line names presence only — fix now, fixed eafcef2
- ripple #3: the M06-AC3 header's "three formats" — reject, false: the PDF read sits inside the LaTeX leg, so the legs are still LaTeX, HTML and gfm
- ripple #4: the M04-AC2 header comment says "slice" — fix now, fixed eafcef2
- ripple #5: `pdfindex.read`'s docstring says each index gets a page of its own — reject, false: that rule governs `stop`-bounded reads, and M04-AC2 uses none and says why
