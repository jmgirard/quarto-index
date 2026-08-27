<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M044: Retire the pre-release warning

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** `m044-retire-prerelease-warning` · https://github.com/jmgirard/quarto-index/pull/44

## Goal

README and the site stop telling readers the marking syntax may change until
the first tagged release, which shipped as 0.1.0 on 2026-08-26, and the
acceptance suite holds every page a reader meets to that sentence's absence.

## Scope

Surface tier: **user-facing** — the deliverable is the sentence readers meet
before installing, together with the suite's absence rule over it; both are
consumed outside this repo's development.

**In:** delete the four-sentence pre-release blockquote from `README.md:7-10`
and `site/index.qmd:16-19`, and nothing else in either file. Register a
`README_PRERELEASE_STALE` absence container over the `ALL` domain in the
claim-container registry (`tests/run-tests.sh:638`), re-pin the registry's
counts at `tests/run-tests.sh:1863`, and add the check block that reports it.
Retire `tests/sitecheck.py`'s `WARNING` presence clause, its constant and the
docstring line naming it, and invert the M40 warning plant
(`tests/run-tests.sh:13462-13473`) into restorations. Amend IP3 in place and
correct the DESIGN Architecture sentence listing README's contents.

**Out:** any replacement stability sentence in README or on the site — the
plan gate chose none; the changelog and IP3 carry the promise. · Widening the
absence rule beyond the pre-release block → the suite-readers candidate row. ·
Any version-marker or changelog change → none is owed; 0.1.0 shipped.

## Acceptance criteria

- [x] AC1 No file in the domain `git ls-files 'site/*.qmd'` plus `README.md`
      carries any of the four sentences of the retired pre-release block,
      compared with whitespace normalized on both sides; the check reporting
      it names the number of files it swept.
- [x] AC2 That check exits non-zero naming the restored sentence and its
      container, on each of three planted copies of that domain: the block's
      first sentence restored into `README.md`, restored into
      `site/index.qmd`, and restored into `site/index.qmd` re-wrapped across a
      line break at a different column.
- [x] AC3 `cairn/DESIGN.md`'s IP3 no longer names README as where the
      at-your-own-risk statement lives, and carries an in-place amendment
      marker naming this milestone and its decision entry, in the form IP2
      carries for D-016.
- [x] AC4 `cairn/DESIGN.md`'s Architecture sentence describing README
      (`cairn/DESIGN.md:481`) no longer lists the pre-release warning among
      what README carries.
- [x] AC5 `tests/run-tests.sh --self-test` is clean (the profile's `verify`
      slot, plus the fuller pre-review check it names).

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4
- AC3 → T5
- AC4 → T5
- AC5 → T3, T4, T6

## Tasks

- [x] T1 Delete the blockquote at `README.md:7-10` and `site/index.qmd:16-19`,
      changing nothing else in either file.
- [x] T2 Define `README_PRERELEASE_STALE` with the block's four sentences, add
      its `absence`/`ALL` registry row at `tests/run-tests.sh:638`, and move
      the pinned registry counts at `tests/run-tests.sh:1863` from
      `(17, 14, 3)` to `(18, 14, 4)`.
- [x] T3 Add the check block that compares the container against
      `claim_text README_PRERELEASE_STALE`, normalizing whitespace both sides
      as `check_claim_sets` does (`tests/run-tests.sh:1908`), reporting the
      swept file count. Retire `tests/sitecheck.py`'s `WARNING` constant, its
      presence clause (`tests/sitecheck.py:296,309-311`), the `ok` line naming
      it (`:329`) and the docstring line at `:26`.
- [x] T4 Replace the M40 warning-removal plant (`tests/run-tests.sh:13462-13473`)
      with AC2's three restorations, each shown red naming the sentence.
- [x] T5 Amend IP3 in place — drop `(stated in the README)`, add the marker —
      correct the Architecture sentence at `cairn/DESIGN.md:481`, and append
      the D-entry recording the amendment. (RB tripwire: ip-touching)
- [x] T6 Run `tests/run-tests.sh --self-test`; fix what it names.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: criteria audit ran in FULL mode (declared tier user-facing), in a fresh-context [O] reader, twice; round 1 returned 8 findings and round 2 returned 9 over the revised wording, all disposed here, none deferred.
- 2026-08-26: plan gate chose an absence claim-container over the `ALL` domain over an absence clause in `tests/sitecheck.py readme` over two named files, because the registry's domain is enumerated by `git ls-files` rather than hand-listed and it already normalizes whitespace; falsified by a reader-facing page the `ALL` domain does not reach.
- 2026-08-26: plan gate chose deleting the block with no replacement sentence over a post-release stability sentence, at the maintainer's direction; falsified by a reader asking whether the syntax is stable with the changelog and DESIGN in front of them.
- 2026-08-26: implement gate chose stripping a leading blockquote marker from each line before flattening whitespace, over whitespace alone as AC1 words it: the retired block is a blockquote, so without it every `>` opening a continuation line lands mid-sentence and only the block's first sentence — the one occupying a whole line — could ever be found. AC2's re-wrapped plant is that case, and is shown red only under the stripping.
- 2026-08-26: T1-T4 — blockquote deleted from README.md and site/index.qmd; `README_PRERELEASE_STALE` defined with the block's four sentences and registered `absence`/`ALL`, registry counts re-pinned to (18, 14, 4); `claim_text` now writes the swept file list beside the concatenation, and the new check reports the count from it; `tests/sitecheck.py`'s `WARNING` constant, its presence clause, its `ok` line and its docstring line retired; the M40 warning-removal plant replaced with AC2's three restorations, each shown red naming the container and the sentence. Committed as one checkpoint: the four are not independently green, since deleting the block reddens the retired clause until it is gone.
- 2026-08-26: T5 — IP3 amended in place (the three words naming README dropped, marker `(amended M44, D-026)` added in the form IP2 carries for D-016) and the DESIGN Architecture sentence no longer lists the pre-release warning among what README carries. The task's third clause was already satisfied: D-026 was appended at plan time. Escalation was offered at the gate for the ip-touching tripwire and declined.
- 2026-08-26: T6 — `tests/run-tests.sh --self-test` exits 0, 693 checks, on the tree carrying T1-T5.

## Decisions

## Review

Reviewed 2026-08-26 on `m044-retire-prerelease-warning` at PR #44, cut from
`origin/main` unmoved since the branch (0 commits behind), tree clean.

### Acceptance criteria

- AC1 — met. `tests/run-tests.sh` emits `ok M44-AC1: all 4 sentence(s) of the
  retired pre-release warning are absent from every one of the 21 file(s)
  swept`. The 21 is the check's own count, read from the file list
  `claim_text` wrote, and it matches an independent enumeration made here
  (`git ls-files 'site/*.qmd'` = 20, plus `README.md`). An independent
  fixed-string sweep of the same 21 files for each of the four sentences
  found none present. The check's empty-domain guards were read: an empty
  container and a swept list under two files each exit non-zero rather than
  passing.
- AC3 — met. `cairn/DESIGN.md:142-146` IP3 now reads "pre-release installs are
  at-your-own-risk, with breaks recorded in the changelog (amended M44,
  D-026)"; the three words `(stated in the README)` are gone and the marker
  matches the form IP2 carries at `cairn/DESIGN.md:136` (`amended M33,
  D-016`). D-026 exists at `cairn/DECISIONS.md:178` and names the amendment.
- AC4 — met. `cairn/DESIGN.md:480-481` now reads "README is the pointer —
  pitch, install, a link to the site, and short Examples and Tests sections";
  the pre-release warning is no longer among what it lists.
- AC2 — met. The `--self-test` run emits three `ok self-test: the check fails
  on <<...>>` lines, one per planted restoration: into `README.md`, into the
  site front page, and into the site front page re-wrapped across a line
  break at a different column. Each plant asserts the check's own
  `still present (README_PRERELEASE_STALE` output and each rebuilds the
  domain from the file list the live check swept, with `m44_restore`
  hard-failing if the target is not in that list or if the restoration
  changed nothing. The "naming the restored sentence" half of the criterion
  was verified here independently of the plants, by running the check's
  Python against a re-wrapped restoration: it prints
  `still present (README_PRERELEASE_STALE / warning header):
  <<**Pre-release: install at your own risk.**>>` and exits 1.
- AC5 — met. `tests/run-tests.sh --self-test` exits 0 with
  `All checks passed (693 checks).` on the branch tip, run fresh at review.

### Consistency gate

- `cairn_validate.py` — exit 0, all checks passed, no advisory fired (the
  `release window` advisory the last hygiene stamp expected reads OK here).
- `cairn_impact.py --changed` — reports no changed principles, IP3's
  amendment having landed in an earlier branch commit. Reconciled by hand
  instead: every `IP3` reference under `cairn/` outside this milestone file is
  either the principle itself (amended), append-only history
  (`DECISIONS.md:26`, `D-026`, `reviews/archive/RB01`), or the ROADMAP hygiene
  stamp replaced by this pass. No divergence.
- Toolchain checks — the `generic` profile's `consistency-gate` slot names
  none, so this half is a clean no-op. The suite it does name ran under AC5.

### Independent review

Three fresh-context lenses, none having seen the implementation, each on a
distinct evidence base; the diff touches executable surface, so the full
fan-out ran.

- **[S] blame-history** — no findings. Traced each deletion to the commit that
  added it (`22faf8e0` M01 for the README block, `5cff3467` M40 for the
  `site/index.qmd` copy, the `sitecheck.py` `WARNING` clause and the
  warning-removal plant) and judged each against D-026, which authorizes them
  by name. Nothing deliberate is silently undone.
- **[S] prior-PR-comments** — no prior-review evidence. Archived `## Review`
  sections on the touched files carry nothing this diff reintroduces, and the
  GitHub inline-comment probe found no real threads (as M13, M40, M42 and M43
  each found before it). Zero findings, cleanly.
- **[O] diff-bug** — seven findings, triaged below.

### Findings and disposition

- F1 (`tests/run-tests.sh:2007-2013`) — the failure never names the file
  carrying the restored sentence: `everywhere` is the whole domain flattened
  into one string, so AC2's README plant and its `site/index.qmd` plant
  produce byte-identical output, and the code comment at :13637-13642 claims a
  discrimination the check does not have. Disposition: follow-up.
- F2 (`tests/run-tests.sh:13650, 13674-13700`) — only row 1 of the container's
  four is ever planted; rows 2-4 are never shown red, so a typo in one would
  forbid nothing while reading as enforced. All four rows were confirmed to
  tile the deleted block exactly, so this is latent, not live. Disposition:
  follow-up.
- F3 (`tests/run-tests.sh:537-538`) — two forbidden rows are generic sentences
  that are still true, the second nearly IP3's operative promise verbatim, so
  a legitimate future stability sentence on a site page would be reported as
  the retired warning coming back. Disposition: follow-up.
- F4 (`tests/run-tests.sh:13676, 13682, 13698`) — the plants assert only
  `still present (README_PRERELEASE_STALE`, the container half of AC2's
  "naming the restored sentence and its container"; the sentence half is
  untested by the plants. Verified here independently (AC2 evidence above),
  so the criterion holds. Disposition: follow-up.
- F5 (this file, AC1) — AC1 says "whitespace normalized on both sides" where
  `flat()` also strips a leading blockquote marker per line. Rejected as a
  criterion failure: marker-stripping only widens what can match, so absence
  under it implies absence under whitespace alone, and AC1 as written is
  satisfied. The widening was chosen and logged at the implement gate
  (work log, 2026-08-26) and is stated in the code at :1970-1979.
- F6 (`cairn/ROADMAP.md:4`) — the hygiene stamp still reads "M44 and M45
  planned". Rejected: that stamp is the previous pass's, correct when written,
  and this review's hygiene pass replaces it.
- F7 (`cairn/DESIGN.md:481`) — a 56-character line mid-paragraph where its
  neighbours run 71-79. Rejected as a pure style nitpick; the sentence itself
  is correct per AC4.

No finding meets the return floor: none demonstrates an acceptance criterion
failing, and none is a load-bearing defect in what the suite does — the live
check has no false-green path (its empty-container and empty-domain guards
both exit non-zero), and F1/F2/F4 are plant- and diagnostic-strength gaps
over a container whose four rows were verified correct.
