# M062: A book repeats a record complaint once per index section it costs

**Status:** done (2026-08-30, PR #62 https://github.com/jmgirard/quarto-index/pull/62)

**Goal:** An HTML book reports a stored chapter record it refused for its version, or refiled
because it names an index the book no longer declares, once per index section that record costs.

**Outcome:** `fold_undeclared` returns the chapter-and-name pairs it refiled instead of warning
from inside a function every rendering chapter calls, and `html_book` draws both store reports at
one site, gated on `builds or first == nil`: once per chapter that builds an index section, and
once by a chapter that builds none where the records it read show no chapter of the book placing
any index — so a book with no placement marker anywhere reports an unusable record where it kept
silent before. `examples/book-nomarker/` gained `two.qmd`, a third chapter, so the count separates
once-per-book from once-per-reading-chapter; M05's counts over it were re-derived by hand.
DESIGN.md struck KI168, KI200 and KI202.

**Decisions:** none.

**Review:** Three lenses. Blame-history and prior-review found nothing; the diff-bug lens eight,
none meeting the return floor. Two fixed at the gate: the Books-page and changelog sentences
claiming the extra reports come only in a book with no marker anywhere, falsified by a scratch
render of a book whose only marker sits in its last chapter; and two new count helpers using
`grep -cF` where `check_warning_count` counts occurrences. Six filed as KI208-KI213, KI208
recording that the new gate reaches any book whose marker chapter's record is unreadable. No
candidate row extended, no lesson retired.
