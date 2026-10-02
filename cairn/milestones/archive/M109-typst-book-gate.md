# M109: The suite checks a Typst book on any Quarto that renders one

**Status:** done (2026-10-02, PR #109 https://github.com/jmgirard/quarto-index/pull/109)

**Goal:** The suite runs its Typst-book output checks on any Quarto that
renders the book, and skips them only when Quarto refuses a Typst book.

**Outcome:** `typst_book_rendered` in `tests/run-tests.sh` reads each book
render's exit status, its log and the PDFs at any depth in the captured
`_book`. It runs M098-AC5, the M098-AC7 outline check and M100-AC3 after one
PDF, exit 0 and no refusal. It prints one `skip` line a label after the
refusal warning with no PDF, at any exit status. Any other render fails.
`capture --refusable` leaves a missing `_book` to the gate. The no-author
check stays on the pin with its own reason (D-067 narrows D-065).
`--self-test` holds 12 gate cases. The `versions.yml` comment names the
refusal skips. Quarto 1.5.52 exits 1 on a Typst-only book.

**Decisions:** AC1 amended at implement to skip at any exit status. D-067.

**Review:** two rounds of three lenses. Round 1 returned M109 once: AC1
failed on a PDF in a `_book` subfolder (D3). T6-T9 fixed D3, D1, D2, D5 and
P2a. Round 2 fixed four test gaps at the gate. D6 extended the books-page
candidate row. Floor 884 checks with 17 skips, pinned 902, self-test 1770,
PR CI green. Two 1.10.18 runs hit a Deno crash and passed on re-run. That
note went to PROFILE.md's `verify`.
