<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M54: The candidate backlog comes back under D-013

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m054-candidate-backlog`

## Goal

Every finding restated in a `cairn/ROADMAP.md` candidate row moves to a
labelled `cairn/DESIGN.md` known issue, so each row states work and its
promotion condition alone, and a stated row shape keeps it that way.

## Scope

Surface tier: **internal** — the deliverable is this repo's own tracking
records, which no external consumer of the repo reads.

**In:** the 36 rows of `## Candidates` (21,777 bytes, 14 of them naming no
`KI<n>` at all and holding 14,273 of those bytes). Nine are review-finding
clusters on the acceptance suite's own readers and checks — M32, M37/M38,
M41, M42, M46, M48/M51/M53, M49, M50/M49, M52 — restating findings that
D-013 places in `## Known issues`. Their finding prose moves there verbatim
at new labels; every row is then disposed (kept, merged, or dropped) and
compressed under a stated per-row byte cap; the pointer prose is normalized
so a sweep can resolve it; and a D-entry annotating D-013 states the row
shape the `## Candidates` comment then names.

**Out:** repairing or deleting any reader or check the moved findings name →
stays a candidate row, plannable per cluster once the list is legible.
Retiring findings as stale on the way → not done; nothing is dropped for
content in this milestone (rows are dropped only as proposals). A repo-local
checker over the tracking files → refused, not deferred: it is the
checker-regress shape, and `cairn_validate` owns tracking validation.
`cairn/LESSONS.md` and `cairn/check-design.md` → untouched, both under budget.

## Acceptance criteria

- [ ] AC1. Every row in `cairn/ROADMAP.md`'s `## Candidates`, enumerated by a
      python sweep over the lines beginning `- ` in that section, is at most
      400 bytes, and the swept rows sum to at most 12,000 bytes.
- [ ] AC2. Every `KI<n>` token in `## Candidates`, enumerated by that same
      sweep, matches a `- **KI<n>.**` entry heading in `cairn/DESIGN.md`, and
      the sweep finds no label range (`KI<n>-KI<m>`) and no struck-label
      mention in any row.
- [ ] AC3. No `KI<n>` label appears twice as a `- **KI<n>.**` entry heading in
      `cairn/DESIGN.md`, over the entries a sweep of that file enumerates.
- [ ] AC4. `cairn/DECISIONS.md` holds a dated entry annotating D-013 that
      states the candidate-row shape and the per-row cap, and the
      `## Candidates` HTML comment in `cairn/ROADMAP.md` names that entry by
      its `D-0NN` id.
- [ ] AC5. `cairn_validate` is clean. The profile's `verify` slot
      (`tests/run-tests.sh`) is not required: this milestone changes no file
      the suite reads.

## Coverage

- AC1 → T4, T5, T8
- AC2 → T6, T8
- AC3 → T2, T8
- AC4 → T7
- AC5 → T8

## Tasks

- [x] T1. Enumerate `## Candidates` with the python sweep and record, in the
      work log, a disposition for each of the 36 rows — kept, merged into
      which row, or dropped — with a one-clause reason. The sweep is the
      enumeration; no row is disposed off a hand list.
- [x] T2. For each finding clause in the nine reader-cluster rows, write a
      `- **KI<n>.**` entry under the matching `## Known issues` subheading in
      `cairn/DESIGN.md`, text carried verbatim, labels assigned in order from
      KI91 up and never reused.
- [ ] T3. Bound T2 with M27's conservation check: every word of four or more
      characters in each line removed from `## Candidates` must appear in
      `## Known issues`, minus a stop set written down in the work log for
      row-only tokens (dates, `added`, `Promote`, milestone and finding ids).
      Read every residue by hand before accepting it — the check separates
      reflow from loss, it does not decide it.
- [ ] T4. Rewrite the nine reader rows to work, promotion condition, and
      `KI<n>` pointers, each under 400 bytes.
- [ ] T5. Compress the remaining rows to the cap and drop those T1 disposed
      as dead proposals, each with its reason already in the work log.
- [ ] T6. Normalize the pointers: expand the `KI24, KI27-KI74` range into its
      labels, delete the `KI73 struck` mention, and confirm every remaining
      token resolves.
- [ ] T7. Write the D-entry annotating D-013 — the row shape (work, promotion
      condition, `KI<n>` pointers, no restatement) and the 400-byte cap — and
      rewrite the `## Candidates` comment to name it.
- [ ] T8. Run the AC1-AC3 sweeps and `cairn_validate`, and record the figures
      (row count, largest row, section total) in the work log.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: plan gate ran the criteria audit in REDUCED mode (internal tier, no RB-tripwire tag on any criterion or task), returning three results on three drafted criteria: the row/section cap clean but for the section aggregate spanning text the `- ` sweep does not enumerate, fixed by restating the aggregate as the sum of the swept rows; a word-conservation criterion found unproportionate, quantifying over `base..head`, a rendering of change history rather than the deliverable, and false over its own domain since removed rows carry row-only tokens, fixed by moving conservation to T3 as a gate procedure; and the pointer criterion found unbounded, a literal-token sweep enumerating two of the ~49 labels `KI24, KI27-KI74` names while `KI73 struck` forces an unstated exemption, taken to the gate, which chose normalization — AC2's rewritten wording went back through the three questions and returned clean.
- 2026-08-28: plan gate chose fixing the record before burning down its substance, over repairing two or three reader clusters first, because the clusters cannot be prioritized against each other while nine of them are illegible prose in one section; falsified by a triage that finds most rows dead, which would make the compression work wasted.
- 2026-08-28: plan gate chose moving the finding prose verbatim to `## Known issues` over compressing and striking the stale on the way, because D-013's own rule is a move and M27's precedent dropped nothing; falsified by `cairn/DESIGN.md` acquiring a weight cap that the ~12KB addition would breach.
- 2026-08-28: plan gate chose a D-entry plus a row-shape comment plus a byte cap over a repo-local checker over the cairn files, the checker being the checker-regress shape while D-011 governs source-shape scans and `cairn_validate` already owns tracking validation; falsified by a fourth regression under the stated shape, which would say prose does not hold it.
- 2026-08-28: T1 disposition, off the python sweep (36 rows, 22,001 bytes, largest 2,341, 14 over the 400-byte cap): none dropped and none merged — every row proposes work someone would still do, and no two rows propose the same work. Twelve are kept with their finding prose moved out and the row compressed — rows 2 (EPUB readers), 3 (M50/M49 editor-metadata readers), 4 (named-index LaTeX edges), 16 (M32 check follow-ups), 17 (version portability), 20 (named indexes across chapters), 21 (suite readers), 22 (version-matrix readers), 23 (guards and per-clause proofs), 24 (gallery checks), 25 (pre-release sweep and link containment), 26 (publishing-workflow checks); rows 17, 20 and 21 join the nine the Scope named because they restate findings too and cannot reach the cap without losing that text, taken to the implement gate, which chose moving theirs as well. Three are kept and compressed with nothing to move — row 9 (release bundle, its dated correction history dropped to git at the gate's choice), 11 (locator-control follow-ups), 36 (index output follow-ups, 3 bytes over). The remaining twenty-one are kept as they stand, all under the cap, row 5 only losing its struck-label mention at T6.
- 2026-08-28: T2 moved 72 finding clauses out of twelve rows into `cairn/DESIGN.md` `## Known issues` as KI91-KI162, text carried verbatim with a provenance suffix added: two under The LaTeX back-end (KI106, KI107), one under The HTML back-end and books (KI115), one under Reports and messages (KI105), 32 under the suite's what-it-reads-and-holds (a finding about a reader's own behavior — what it reads, what it holds, what it would report), 36 under the suite's coverage gaps (a clause unproven, unplanted or uncovered). Row 21's M35 clause names no finding and stays a pointer to the archived Review section; its "Also open" list restates KI66-KI71 and becomes pointers at those. Row 3's schema clause is distinct from KI90 and takes KI101, which says so. Label sweep: 155 entries, no label used twice, KI91-KI162 contiguous.
- 2026-08-28: minor amendment — T3's conservation check runs after T4-T6 rather than before, because it reads the lines actually removed from `## Candidates` and no line is removed until those tasks rewrite the rows. No criterion or scope text changes.

## Decisions
## Review
