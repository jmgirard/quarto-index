<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M54: The candidate backlog comes back under D-013

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m054-candidate-backlog` / https://github.com/jmgirard/quarto-index/pull/54

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

- [x] AC1. Every row in `cairn/ROADMAP.md`'s `## Candidates`, enumerated by a
      python sweep over the lines beginning `- ` in that section, is at most
      400 bytes, and the swept rows sum to at most 12,000 bytes.
- [x] AC2. Every `KI<n>` token in `## Candidates`, enumerated by that same
      sweep, matches a `- **KI<n>.**` entry heading in `cairn/DESIGN.md`, and
      the sweep finds no label range (`KI<n>-KI<m>`) and no struck-label
      mention in any row.
- [x] AC3. No `KI<n>` label appears twice as a `- **KI<n>.**` entry heading in
      `cairn/DESIGN.md`, over the entries a sweep of that file enumerates.
- [x] AC4. `cairn/DECISIONS.md` holds a dated entry annotating D-013 that
      states the candidate-row shape and the per-row cap, and the
      `## Candidates` HTML comment in `cairn/ROADMAP.md` names that entry by
      its `D-0NN` id.
- [x] AC5. `cairn_validate` is clean. The profile's `verify` slot
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
- [x] T3. Bound T2 with M27's conservation check: every word of four or more
      characters in each line removed from `## Candidates` must appear in
      `## Known issues`, minus a stop set written down in the work log for
      row-only tokens (dates, `added`, `Promote`, milestone and finding ids).
      Read every residue by hand before accepting it — the check separates
      reflow from loss, it does not decide it.
- [x] T4. Rewrite the nine reader rows to work, promotion condition, and
      `KI<n>` pointers, each under 400 bytes.
- [x] T5. Compress the remaining rows to the cap and drop those T1 disposed
      as dead proposals, each with its reason already in the work log.
- [x] T6. Normalize the pointers: expand the `KI24, KI27-KI74` range into its
      labels, delete the `KI73 struck` mention, and confirm every remaining
      token resolves.
- [x] T7. Write the D-entry annotating D-013 — the row shape (work, promotion
      condition, `KI<n>` pointers, no restatement) and the 400-byte cap — and
      rewrite the `## Candidates` comment to name it.
- [x] T8. Run the AC1-AC3 sweeps and `cairn_validate`, and record the figures
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
- 2026-08-28: T4-T6 rewrote all 36 rows to work, promotion condition and pointers: 36 rows, 8,854 bytes, largest exactly 400, none over. T6 replaced the `KI24, KI27-KI74` range — 49 labels, 292 bytes of tokens against a 400-byte row — with the two acceptance-suite known-issue subheadings named in prose, at the implement mini gate, which took that over enumerating the labels and raising the cap or splitting the row into three (ROADMAP is at 59 of 60 lines, so a split has nowhere to go); the `KI73 struck` mention is gone with row 5's history. 104 pointer tokens, all resolving; no range and no struck mention remain.
- 2026-08-28: T3's conservation check ran over the 36 removed rows against the rewritten rows plus `## Known issues`, words of four or more characters, stop set: dates, `added`/`Promote` and their inflections, milestone/finding/decision ids, row-only bookkeeping (split, cluster and compression notes, row titles, counts of findings), inflectional and possessive variants of a word present in the destination, and history the gate chose to drop (the release row's dated corrections, M51's restoration note, M49's repaired-`folded` correction, row 26's fixed-fourth-finding note, row 5's claim-container note). Three residues survived that reading as real loss and were repaired: the M36 clause's capture condition, folded into KI117; the overlapping-ranges pairing gap, which pairing by entry cannot tell apart, written as KI163 and pointed at from the locator-control row along with its restored `(a defining passage, an illustration)`; and M30's typeset print proof not reaching the cross-reference and sort-key probes, written as KI164 and pointed at from the suite-readers row. Re-run clean of all three.
- 2026-08-28: T7 appended D-034 to `cairn/DECISIONS.md`, annotating D-013 with the row shape (work, promotion condition, dates and sources, `KI<n>` pointers, nothing else) and the 400-byte per-row cap, and naming the subheading form for a row whose motivating set is a whole subheading and the refusal of a label range; the `## Candidates` comment in `cairn/ROADMAP.md` now names it, still two lines so the file stays at 59 of its 60.
- 2026-08-28: T8 swept: 36 rows, section total 8,854 bytes, largest 400 (AC1 pass, cap 400 and 12,000); 104 pointer tokens, none unresolved, no label range, no struck mention (AC2 pass); 157 `- **KI<n>.**` entry headings, no label twice (AC3 pass). Each sweep was shown able to fail before its green was trusted — a 451-byte row reddens AC1 alone, a `KI999` token and a `KI76-KI77` range and a `KI73 struck` mention each redden AC2 alone, and a second `- **KI2.**` heading reddens AC3 (and AC2, the token it displaced no longer resolving). `cairn_validate` clean, 16 PASS and 7 OK, `weight caps` among them: ROADMAP 59 lines / 11,139 bytes, down from 59 / 24,053, which was over the 24,000 budget. The suite was not run: no file it reads changed (AC5).
- 2026-08-28: review corrections to three earlier records, superseding them. T2's line says the moved text was "carried verbatim"; over the twelve rows many clauses are one-clause condensations rather than verbatim carries, T3's word-conservation check being the guard that actually ran. T2's line also says row 21's "Also open" list "becomes pointers at" KI66-KI71; the rewritten row carries no such token, and the list's `entry=`-shape item is KI24, restored to the row at the review gate. The Scope's 21,777 bytes and 14-rows-over-cap for `## Candidates` do not reproduce: the T1 sweep, re-run at review against `origin/main`, measures the same 36 rows at 22,001 bytes with 15 over the 400-byte cap. The sweep figure is the one the criteria were verified against; where the Scope's came from is not recoverable, and the Scope text stands as written.

## Decisions
## Review

Evidence gathered 2026-08-28 on `m054-candidate-backlog` at the pre-gate
checkpoint, against `origin/main`; the AC1-AC3 sweep is a scratch python
script over `cairn/ROADMAP.md` and `cairn/DESIGN.md`, re-run here rather than
read from the work log.

- AC1. The sweep enumerates 36 rows beginning `- ` in `## Candidates`: largest
  400 bytes, none over the cap, 8,854 bytes summed against the 12,000 cap.
  Planting a 400-character tail on one row reddens AC1 and neither other
  criterion.
- AC2. The same sweep finds 104 `KI<n>` tokens across those rows, every one
  matching a `- **KI<n>.**` entry heading in `cairn/DESIGN.md`; no label range
  and no struck-label mention. Planting `KI999` reddens AC2 alone, as does
  planting `KI76-KI77 and KI73 struck`.
- AC3. A sweep of `cairn/DESIGN.md` enumerates 157 `- **KI<n>.**` entry
  headings with no label used twice. Planting a second `- **KI2.**` heading
  reddens AC3.
- AC4. `cairn/DECISIONS.md` holds `### D-034 (2026-08-28)`, headed as
  annotating D-013; its Decision paragraph states the row shape (work,
  promotion condition, dates and sources, `KI<n>` labels, nothing else) and
  the 400-byte per-row cap. The `## Candidates` HTML comment in
  `cairn/ROADMAP.md` names `D-034` on its first line.
- AC5. `cairn_validate.py` exits 0: 16 PASS, 7 OK, no FAIL and no WARN; the
  `release window` advisory did not fire. The `verify` slot was not run, per
  the criterion: the diff touches only `cairn/` tracking files, none of which
  the acceptance suite reads.

### Consistency gate

`cairn_validate` clean, as above. No `DESIGN.md` IP/GP principle line changed
in the diff, so `cairn_impact.py --changed` is skipped. The active profile is
`generic`, whose `consistency-gate` slot names no toolchain checks, so that
half of the gate is a clean no-op.

### Findings

One fresh-context reviewer was spawned, per the internal tier and a diff that
touches only markdown tracking files: the [O] diff-bug lens over
`git diff origin/main..HEAD` against the criteria, `cairn/DESIGN.md` and
`cairn/DECISIONS.md`. It re-ran the AC1-AC3 sweeps independently and agreed
with the figures above, and confirmed no plan-owned milestone text was
altered. Thirteen findings, ranked by the reviewer, with the disposition each
took at the gate. None demonstrates an acceptance criterion failing, so none
meets the return floor.

- F1. The suite-readers row's subheading pointer covers 122 entries, about 55
  of them the work of six sibling rows, so nothing in `## Candidates`
  distinguishes what that row is for. Disposition: fixed in part (F3's
  rewording names the file); the residual over-claim is inherent to the
  subheading form D-034 blessed, and `ROADMAP.md` at 59 of its 60 lines has no
  room for a row about it, so it is recorded as an accepted limitation in
  `cairn/DESIGN.md`'s Known issues at the post-merge hygiene pass.
- F2. `KI24` was in the old row's `KI24, KI27-KI74` set but lives under
  Reports and messages, which neither named subheading covers, so it is now
  motivated by nothing; the T2 work-log line's claim that the "Also open" list
  became pointers at KI66-KI71 is not true of the rewritten row.
  Disposition: fix now — `KI24` restored to the row's token list, and a
  work-log line correcting the T2 account.
- F3. "this document's two acceptance-suite known-issue subheadings", read
  inside `ROADMAP.md`, names the wrong document and neither subheading by
  title, which is the resolvability D-034 banned ranges to get.
  Disposition: fix now.
- F4. KI164 carries `— M35/M36/M46/M50`, copied from the row's source field;
  the finding is M30's. Disposition: fix now.
- F5. The gallery-checks and publishing-workflow rows, both rewritten by
  T4/T5, state no promotion condition, which D-034's own Decision paragraph
  requires. Disposition: fix now.
- F6. "text carried verbatim" overstates what happened: many moved clauses are
  one-clause condensations rather than verbatim carries. Disposition: fix now
  as a superseding work-log line; the T2 line itself is history and stands.
- F7. KI117 absorbed the M36 clause's per-finding promotion condition, which
  D-013 and D-034 place in the row. Disposition: rejected — the cluster row
  carries one promotion condition by design, and KI117 as written states a
  coverage gap, not a condition.
- F8. The release row's "both since supplied" is unsourced, and the rewrite
  drops the corrected `extensions/quarto-extensions.csv` location.
  Disposition: rejected — topics were recorded added 2026-08-27 and M50 is
  archived done, so the claim is derived, not composed; the PR number in the
  row is the pointer to the file's location.
- F9. Rewritten row 43 and untouched rows still restate behavior.
  Disposition: rejected — the untouched rows are pre-existing and out of this
  diff, and row 43's clause states the proposed work's consequence.
- F10. The `## Candidates` comment is one 305-byte line with a stray comma
  before an em dash. Disposition: the comma fixed now; the unwrapped line
  stands, ROADMAP being at 59 of its 60 lines.
- F11. Scope says 21,777 bytes and the T1 sweep says 22,001, unreconciled.
  Disposition: fix now, folded into F6's work-log line.
- F12. KI157 states that some prose is unchanged rather than naming a defect.
  Disposition: rejected — it carries its row clause faithfully, and retiring
  findings as stale was Scope Out.
- F13. Two source fields lost "M20 amendment gate" and the archive path for
  the M35/M36/M46/M50 Review sections. Disposition: rejected — the provenance
  survives in the KI entries' own suffixes, and this is the compression T4/T5
  planned.

Fix-now work directed at the gate landed after the pre-gate checkpoint: `KI24`
restored to the suite-readers row and its subheading reference rewritten to
name `cairn/DESIGN.md` (F2, F3); KI164's provenance corrected to M30, recovered
by M54 T3 (F4); promotion conditions written for the gallery-checks and
publishing-workflow rows (F5); the `## Candidates` comment's stray comma
removed (F10); and one superseding work-log line covering F6, F11 and F2's
account of the "Also open" list. The AC1-AC3 sweeps were re-run over the fixed
files: 36 rows, 9,051 bytes, largest 400; 105 pointer tokens, all resolving;
157 headings, none twice. `cairn_validate` re-run clean.
