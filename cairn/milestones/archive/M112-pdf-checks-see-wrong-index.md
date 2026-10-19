# M112: Three PDF index checks see a wrong index

**Status:** done (2026-10-19, PR #112 https://github.com/jmgirard/quarto-index/pull/112)

**Goal:** Three acceptance-suite readers of a compiled PDF index fail on a wrong index that they pass or read short today.

**Outcome:** Closes KI63 and KI102 and narrows KI69, from the older acceptance-suite
backlog. One `xref_typeset_check` reader in `tests/run-tests.sh` serves M02-AC2,
M02-AC3 and their self-test: it counts each manifest row in the flattened index region,
fails naming a row printed more than once, and refuses a manifest with one row inside
another. `tests/m23probes.py` states `MARKS = 2 * 2 + 2` and fails `ind`/`posind` on an
entry outside the three stated terms, and on an `.ilg` count other than `MARKS` accepted
and 0 rejected. A bounded `tests/pdfindex.py` `read` raises LookupError naming the page
and lines when the page it leaves out prints a line above its first section-ending
line, or in the left column below one set in the right. Its self-test feeds stubbed
`_pages` output, since no rendered variant tried builds that page.

**Decisions:** none milestone-local.

**Review:** four-lens fan-out, 23 findings. 14 fixed on the branch: the column-aware
refusal, the rejected-entry clause, plants reading `MARKS`, KI69 narrowed to the two
presence-only checks left (AC6's terms, M05-AC5's book cross-references) rather than
removed, and docstring and comment corrections. 3 to follow-up KI313 (substring counts),
plus KI312 (`typstindex.py`'s own bounded read). 6 rejected. Suite 1770 checks green
under Python 3.9.6; CI green. No lesson captured or retired; no row unparked.
