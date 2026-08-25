# M36: The non-Latin-1 readers stop reading text that belongs to no error

**Status:** done (2026-08-25, PR #36 https://github.com/jmgirard/quarto-index/pull/36)

**Goal:** `tests/unicodeprint.py`'s readers no longer let text outside an error report,
or a level spec its callers never read, satisfy a clause claiming to hold them.

**Outcome:** `error_blocks` no longer closes an unclosed final `! ` report at end of file,
so chatter after one belongs to no report; the docstring names the cost, TeX's one-line
fatal-error trailer going with it. `stated()` gained two refusals: a level not in ASCII
digits (`str.isdigit()` took `'٣'` as 3) and an empty term. Three plants — the rejection
stated only in chatter after an unclosed `! ` line, a U+0663 level through `entries`, an
empty term through `marks`, the first plant on that reader's argv contract. The plant
block's matrix, header and pass line narrowed to 23 rows, a run-time count, both unplanted
clauses named. Suite 352 plain / 491 self-test.

**Decisions:** milestone-local — F9 closed by narrowing the pass line, not by planting two
unreachable clauses; F16 (`!pdfTeX error:` opening no block) by naming `! `-with-space as
the reader's domain; F11 folded into the empty-term plant, `marks`' contract being
`stated()`.

**Review:** three lenses, only diff-bug finding anything (13 ranked). Eleven prose defects
fixed at the gate, first the docstring claiming the log carries no report where one is
dropped; `stopped`'s dependence on the fatal-error trailer went to the suite-hardening
row; a `D-118` citation was rejected as cairn's own id. Hygiene added KI88, two LESSONS.
