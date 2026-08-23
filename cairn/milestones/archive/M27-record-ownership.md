# M27: A finding about today's behavior is a known issue, not a candidate row

**Status:** done (2026-08-23, PR #27 https://github.com/jmgirard/quarto-index/pull/27)

**Goal:** Refile the findings review had been appending to `cairn/ROADMAP.md`
candidate rows and `cairn/LESSONS.md` lines into the records that own them.

**Outcome:** `cairn/DESIGN.md` gained `## Known issues` — 79 entries labelled
KI1-KI79 in six area groups (LaTeX back-end; entries, levels and sort keys;
HTML and books; reports; the suite's reads and coverage gaps; packaging), each
naming its source. Candidates fell from 37 rows to 28, each
stating work and pointing at its labels; six single-item suite rows folded into
the acceptance-suite row. Sixteen check-, oracle- and criterion-design lessons
graduated whole into `cairn/check-design.md`, budgeted in its own header at
under 40 lines / 18,000 bytes. ROADMAP 23,276 -> 7,059 bytes; LESSONS 18,439 ->
7,928. No code changed (self-test 409 checks).

**Decisions:** D-013 (cross-cutting). Milestone-local: the T1 ledger mapping
every row and lesson line to its disposition; the T4 vocabulary bound; T5's
finding that the enforcement exit misses the check-design family.

**Review:** Reduced routing (internal tier, markdown-only diff) — one diff-bug
lens, run in-session because the session was told not to spawn agents. All six
criteria passed on fresh evidence. F1 (the intro promised a review source where
three name a decision or report) fixed at the gate; F2/F3 rejected.
