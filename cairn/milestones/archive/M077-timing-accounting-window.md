# M077: The suite's timing accounting checks only what its own window covers

**Status:** done (2026-09-04, PR #77 https://github.com/jmgirard/quarto-index/pull/77)

**Goal:** Keep the accounting clause the run can settle — every declared section has exactly one row and nothing else does — drop the one whose window it cannot cover, and stop leaving a state where a section opened after the run's last is timed as the whole run.

**Outcome:** The section timer gained a third state, `SECTION_RUN_CLOSED`: `section_close` marks the run closed instead of clearing the variable that also means "before the first section", and `section` fails naming its own call once it is set — before, such a call wrote a second `unattributed` row valued at the whole run. `m075_account` lost its seconds clause and the `M075_OPEN`/`M075_TOTAL` readings feeding it, keeping the membership pair (a heading names a section `tests/suitescan.py sections` reports; each reported section has one row) with the setup-row and malformed-row clauses; the driver still prints the run total and fifteen slowest rows, now checked by nothing (KI250). The T5 plants follow the clauses — the five-seconds plant retired, a three-leg probe for the refusal added — and `m075_plant_source` imports `BANNER_RULE` and `run_all_span` from `tests/suitescan.py` rather than re-typing a dash test and scanning to EOF.

**Decisions:** none milestone-local; D-054 records the narrowing and why widening the measuring window was declined.

**Review:** three fresh-context lenses; prior-review and blame-history found nothing, [O] diff-bug eleven, all about the suite's own self-checks and none showing a criterion failing. Four fixed at the gate: the refusal probe could not tell the new flag from a timer refusing on an empty heading (a third leg pins it); the M075-AC2 pass line claimed the setup row was held to the declared section list; the plant's block scan was bounded by EOF, not the wrapper span; `unattributed` was matched unanchored. One filed as a candidate row (the plant helper's repairs are unexercised), five rejected with reasons. Merge-base counts 766/1397 against 765/1396 — the removed seconds report, and nothing else.
