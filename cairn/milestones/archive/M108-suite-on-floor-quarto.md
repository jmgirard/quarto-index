# M108: The acceptance suite passes on Quarto 1.5.52

**Status:** done (2026-10-02, PR #108 https://github.com/jmgirard/quarto-index/pull/108)

**Goal:** On Quarto 1.5.52, the suite passes while it checks the extension's
output, and the Typst page says that this Quarto renders no Typst book.

**Outcome:** `tests/typstindex.py` reads Typst 0.11's inline `/GoTo` links,
faces from each font descriptor (`/FontWeight` or `/StemV`, and the `/Flags`
italic bit), PDF strings in annotations, and NFKC text. `tests/typstforms.py`
writes those forms into a pinned render for the self-test. The gfm readers
take `data-` or bare attributes, one spelling a render. M12-AC5 reads the
wrapped 1.5.52 title, and the front-matter check reads which fields print.
`on_pinned_quarto` prints one `skip` line a label for the D-065 checks and the
Typst-book checks. `site/typst.qmd` quotes the 1.5.52 book warning. KI110 is
closed. The note on editing the suite mid-run went to PROFILE.md's `verify`.

**Decisions:** the front-matter rows follow the printed fields. The gates
amended AC2, AC3 and Scope In, and chose NFKC over ligatures-only.

**Review:** three lenses (F1-F13, H1-H11, P1-P4), no criterion failed. F3,
F4, F5, F7, F8, F9, H10 and F13 were fixed. F1 and the books page became
candidate rows, and 17 were rejected. Floor 884 checks with 17 skips, pinned
902, self-test 1758, PR CI green. LESSONS line 31 now names `‼` and NFKC.
