# M076: A store-report leg asserts every wording, not the ones its author recalled

**Status:** done (2026-09-04, PR #76 https://github.com/jmgirard/quarto-index/pull/76)

**Goal:** A leg that asserts which store reports a render drew asserts every store wording the suite defines — the counts it expects and zero for the ones it does not — so a change drawing a wording spuriously is red on the leg that met it rather than only where a total-warning count happens to sit.

**Outcome:** `check_store_reports` in `tests/run-tests.sh` takes a log, a label and zero or more `<WARN_STORE_NAME>=<count>` pairs; its domain is what `${!WARN_STORE_@}` expands to at the call, so an eleventh wording ships zero-controlled on every leg at once. It refuses an empty family, a name the family does not hold, and a logfile that is not a file. 220 `check_warning_count` calls naming a store wording became 80 calls over renders, 214 asserted (log, wording) pairs became 800, and no old-style call survives. `check_warning_names_nth` picks its line by the chapter lists the caller passes, not by position among the grep matches. Fifteen legs the conversion turned red were settled — every one a report the filter draws that nothing was asserting, none a filter defect; four counts now derive from a fixture's chapter count or ride as a function parameter. Nothing about what the Lua filter draws changed.

**Decisions:** none cross-cutting. Milestone-local: each call site spells the full variable name, so a typo is an unknown name rather than a swept zero; one merged label per log, the helper's failure naming the offending wording.

**Review:** three-lens fan-out; the blame-history and prior-review lenses found no regression. The [O] diff lens returned eight ranked findings — five fixed on the branch (a sweep passing on a logfile that is not there, a `set -e` abort with no FAIL line, an AC4 plant re-typing the leg's expectation instead of expanding it, a convention slip, four labels and a blank line, with two new `--self-test` cases for the first two), two rejected with reasons, one folded. Nothing retired or graduated.
