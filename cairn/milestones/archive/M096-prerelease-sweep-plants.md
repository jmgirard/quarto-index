# M096: The pre-release sweep fails on the defects it names, from one definition

**Status:** done (2026-09-11, PR #96 https://github.com/jmgirard/quarto-index/pull/96)

**Goal:** The pre-release sweep is defined once and reports on every failure
branch it holds, including the empty-sentence row that matched every page.

**Outcome:** The retired-sentence sweep left a 97-line heredoc in
`tests/run-tests.sh` for a `prerelease-absent` mode in `tests/sitecheck.py`.
A new `sweep_rows` gives it and `phrase-absent` one per-page read, overlay
handle and unreadable-page report, over `swept_domain`'s enumeration, README
test and floor and `read_rows`' row reading. The shell function is two lines,
its call site and message unchanged. `read_rows` refuses a row whose text half
flattens to nothing, which reported all 22 pages. Seven branches gained
plants, the floor comment's unmeasured count is gone, and KI93 is retired.

**Decisions:** two, milestone-local. The merged sweep compares
case-sensitively where `phrase-absent` folds. A superseding entry follows, the
first having overstated the merge as byte-identical.

**Review:** three lenses, eleven findings, all from the diff-bug lens. Nine
fixed at the gate, over a wrong call-site count, two false difference claims,
a misdescribed refusal, a conflating docstring, a weak plant guard, a missing
empty-list plant, a stranded temp directory and no shellcheck marker. One went
to hygiene, one was rejected, none reached the floor. Suite 1523 green.
