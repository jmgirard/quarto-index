# M111: Three suite checks tell apart what they now read alike

**Status:** done (2026-10-18, PR #111 https://github.com/jmgirard/quarto-index/pull/111)

**Goal:** Three acceptance-suite checks that now pass or fail alike on two different
states each tell those states apart.

**Outcome:** Closes KI275-KI277 from the older acceptance-suite backlog.
`check_warning_count` in `tests/run-tests.sh` fails naming a log that is not a file,
held by a `--self-test` case in the M02-AC5 section. The M079-AC1 leg reads each refusal
report's wording: a `CONTESTED_XREF` term takes the cross-reference clause and not the
locator one, other `REFUSED` terms the reverse (clauses exported once as
`M111_XREF_CLAUSE`, `M111_LOCATOR_CLAUSE`); plant `xref-locator-wording` makes
`html.lua` pick the locator wording and turns it red. `m081_census_plant` takes an
optional line it must not print; the M090 T3 plant forbids T2's `$M090_T2_LINE`. KI274
left out at the plan gate (M090's choice stands). KI311 added for three inline greps
outside the helper that read a missing log as 0.

**Decisions:** none milestone-local.

**Review:** four-lens fan-out, 15 findings, none failing a criterion. Fixed on the
branch: a KeyError without the clause variables, the wording read only on reports also
naming the expected id, a comment on the two wordings. Follow-up: KI311. Seven rejected,
four noted. Suite 1767 checks green; CI green. No lesson captured or retired.
