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

- [ ] AC1: M02-AC3's typeset check in `tests/run-tests.sh` reads the index
      in Quarto's own PDF of `examples/xref-escaping.qmd`. It holds each
      entry that `typstcheck.derived_entries` derives from that fixture with
      a cross-reference to exactly one line of that index. The expected line
      is the term, then `, see ` and the `see` targets, then `; see also `
      and the `see also` targets. An entry with only `see also` targets has
      `, see also ` after the term. Each `'` is written as `’` and each
      `` ` `` as `‘`. The comparison with the line's text is in NFC. The
      check fails naming each such entry printed on no line or on more than
      one.
- [ ] AC2: M06-AC3 reads the index in Quarto's own PDF of
      `examples/sort-escaping.qmd`. It holds each `term-XX` mark that its
      scan of the fixture finds to exactly one line whose term is the mark's
      text. A line's term is the line with its locators removed. The check
      fails naming each mark printed on no line or on more than one. It does
      not check the order of the lines.
- [ ] AC3: M04-AC2's PDF check reads `examples/marker.qmd`'s PDF with
      `pdfindex.read` and keeps the lines on the `After the marker`
      heading's page whose position is above that heading. It holds each
      term of `MARKER_PDF_TERMS` to exactly one kept line, compared on the
      line's term. It fails naming each term on no kept line or on more
      than one. If the read finds no `After the marker` line, it also fails.
- [ ] AC4: For each shown fixture that the registry gives a PDF manifest,
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

## Decisions

## Review
