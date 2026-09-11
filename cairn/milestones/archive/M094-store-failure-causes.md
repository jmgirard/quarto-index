# M094: A failed store write or source read reports its own cause

**Status:** done (2026-09-11, PR #94 https://github.com/jmgirard/quarto-index/pull/94)

**Goal:** A book chapter whose record cannot be written, or whose source cannot be read,
reports the failure that happened and prints no `ERROR` line of Quarto's, and the M062 and
M063 checks around those reports fail on the defects they name.

**Outcome:** Quarto's filter runtime replaces the global `error` with a logger that returns.
The four `error(...)` sites inside `pcall` in `book.lua` now return a failure value instead.
`store_write` reports on `not ok or err ~= nil`, so a held record path names `Is a directory`
as its cause. `check_extension_warning_count` strips SGR escapes before its anchored patterns
read, and it and the new `check_no_quarto_error` refuse a log they cannot read. Pinned counts
moved: M063-AC3 and M064-AC5 6 to 7, M064-AC3 10 to 12. New plants restore the raise (T2), put
an escape before a warning (T3) and drop the refiled mark from five.qmd's record (T4).
`Escutcheon`'s refile into the alpha section is asserted, the M062-AC3 plant re-keys `sorts`,
and KI204, KI206 and KI210-KI213 are struck.

**Decisions:** none milestone-local. The plan kept KI204 here and chose returned failures.

**Review:** one pass, three-lens fan-out. The history and prior-review lenses found nothing.
Of nine diff findings, F1 (an unreadable log passed a zero count) and F4 (the CHANGELOG named
any write failure) were fixed at the gate. F2, F3, F5 and F6 went to KI280-KI283. F7-F9
rejected. Suite run 1 stopped on a Quarto Deno segmentation fault. Runs 2 and 3 passed 1504
checks, and CI was green on PR #94. No lesson. Nothing graduated or retired.
