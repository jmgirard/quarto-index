<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M044: Retire the pre-release warning

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** `m044-retire-prerelease-warning`

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

- [ ] AC1 No file in the domain `git ls-files 'site/*.qmd'` plus `README.md`
      carries any of the four sentences of the retired pre-release block,
      compared with whitespace normalized on both sides; the check reporting
      it names the number of files it swept.
- [ ] AC2 That check exits non-zero naming the restored sentence and its
      container, on each of three planted copies of that domain: the block's
      first sentence restored into `README.md`, restored into
      `site/index.qmd`, and restored into `site/index.qmd` re-wrapped across a
      line break at a different column.
- [ ] AC3 `cairn/DESIGN.md`'s IP3 no longer names README as where the
      at-your-own-risk statement lives, and carries an in-place amendment
      marker naming this milestone and its decision entry, in the form IP2
      carries for D-016.
- [ ] AC4 `cairn/DESIGN.md`'s Architecture sentence describing README
      (`cairn/DESIGN.md:481`) no longer lists the pre-release warning among
      what README carries.
- [ ] AC5 `tests/run-tests.sh --self-test` is clean (the profile's `verify`
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
- [ ] T5 Amend IP3 in place — drop `(stated in the README)`, add the marker —
      correct the Architecture sentence at `cairn/DESIGN.md:481`, and append
      the D-entry recording the amendment. (RB tripwire: ip-touching)
- [ ] T6 Run `tests/run-tests.sh --self-test`; fix what it names.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: criteria audit ran in FULL mode (declared tier user-facing), in a fresh-context [O] reader, twice; round 1 returned 8 findings and round 2 returned 9 over the revised wording, all disposed here, none deferred.
- 2026-08-26: plan gate chose an absence claim-container over the `ALL` domain over an absence clause in `tests/sitecheck.py readme` over two named files, because the registry's domain is enumerated by `git ls-files` rather than hand-listed and it already normalizes whitespace; falsified by a reader-facing page the `ALL` domain does not reach.
- 2026-08-26: plan gate chose deleting the block with no replacement sentence over a post-release stability sentence, at the maintainer's direction; falsified by a reader asking whether the syntax is stable with the changelog and DESIGN in front of them.
- 2026-08-26: implement gate chose stripping a leading blockquote marker from each line before flattening whitespace, over whitespace alone as AC1 words it: the retired block is a blockquote, so without it every `>` opening a continuation line lands mid-sentence and only the block's first sentence — the one occupying a whole line — could ever be found. AC2's re-wrapped plant is that case, and is shown red only under the stripping.
- 2026-08-26: T1-T4 — blockquote deleted from README.md and site/index.qmd; `README_PRERELEASE_STALE` defined with the block's four sentences and registered `absence`/`ALL`, registry counts re-pinned to (18, 14, 4); `claim_text` now writes the swept file list beside the concatenation, and the new check reports the count from it; `tests/sitecheck.py`'s `WARNING` constant, its presence clause, its `ok` line and its docstring line retired; the M40 warning-removal plant replaced with AC2's three restorations, each shown red naming the container and the sentence. Committed as one checkpoint: the four are not independently green, since deleting the block reddens the retired clause until it is gone.

## Decisions

## Review
