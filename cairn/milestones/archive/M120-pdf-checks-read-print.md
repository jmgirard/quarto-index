# M120: Four PDF index checks read what the index prints

**Status:** done (2026-10-20, PR #120 https://github.com/jmgirard/quarto-index/pull/120)

**Goal:** If a compiled PDF index prints a checked term on no line or on two, four acceptance-suite readings of it fail.

**Outcome:** Strikes KI164 and KI316. M02-AC3 counts all 255 cross-reference
lines of `examples/xref-escaping.qmd` in Quarto's own PDF: `xref_derived_rows`
builds them from `typstcheck.derived_entries` with the `'`/`` ` `` quotation-mark
facts, refuses an unmodelled ligature input or a repeated line, and
`xref_hand_check` holds them to a hand-stated construction rule.
`xref_typeset_check` compares in NFC. M06-AC3's `sortesc_pdf_check` counts the
94 sort-keyed marks in `sortesc-pdf`, order not read. M04-AC2's
`marker_pdf_check` keeps the lines above `After the marker` on its page.
`tests/gallerycheck.py pdf` counts each manifest entry's printed lines through
`pdfindex.read` against the manifest's count, in NFC; `extracted_text` is gone.
`pdfindex._pages` decodes `pdftotext` output as UTF-8. Plants for each.

**Decisions:** none.

**Review:** four lenses, 31 findings: 19 fixed (the hand statement under the
suite's ORACLE RULE, stricter T1 plants, AC3's bound to the heading's page,
NFC and UTF-8 in the PDF reads, wording), 1 to follow-up (KI326 under "Older
acceptance-suite backlog"), 11 rejected. Suite 1869 green; CI green. Graduated
"Read the printed PDF in more checks". One LESSONS line; no row unparked.
