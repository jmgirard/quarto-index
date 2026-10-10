# M110: The site says which Quarto renders a Typst book

**Status:** done (2026-10-10, PR #110 https://github.com/jmgirard/quarto-index/pull/110)

**Goal:** The Books page names the Quarto that Typst books were tested on, and
the Typst page states only true facts about Quarto 1.5.52.

**Outcome:** `site/books.qmd` says Typst books were tested on Quarto 1.10.18
and that Quarto 1.5.52 does not render one. `site/typst.qmd` drops "exits
without an error" and states no 1.5.52 exit status, by the user's choice at
the plan gate. `tests/run-tests.sh` pins the new Books sentences and rewrites
the `floor warning` row. `m110-retired.txt` bans the phrase through
`phrase-absent`. Four `m110-*` `--self-test` plants hold the three rows. They
match across any whitespace. PROFILE.md's `verify` names the
`/usr/bin/python3` link the suite needs here.

**Decisions:** none.

**Review:** three lenses, one pass, no return. Of 19 findings, 12 were
rejected and 5 fixed: a lasting floor-warning plant, the M110 label,
whitespace-proof plants, a restored phrase broken across a line. 2 went to
"Hold the Typst pages' Quarto facts to their sources". On 1.10.19: 893 checks,
self-test 1765, 9 pinned-only skips. Two self-test runs hit a Deno segfault
and passed on re-run. PR CI green.
