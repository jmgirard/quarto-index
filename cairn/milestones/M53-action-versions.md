<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M53: The workflows' actions come up to date

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** `m053-action-versions`

## Goal

The five GitHub Actions the two workflows pin move to their current major
tags, so the deprecation warnings stop and neither workflow is left on a
runtime the runner images are retiring.

Surface tier: **user-facing**. One of the two workflows publishes the
documentation site readers read, so a bump that breaks it is a break a reader
meets.

## Scope

**In:** `actions/checkout` v4 → v7 (five sites), `actions/upload-artifact`
v4 → v7, `actions/download-artifact` v4 → v8,
`actions/upload-pages-artifact` v3 → v5, `actions/deploy-pages` v4 → v5,
across `.github/workflows/pages.yml` and `.github/workflows/versions.yml`.
A `DECISIONS.md` entry recording the re-pin. Evidence is the workflow runs the
branch's own push triggers, never a scan of the YAML.

Three of the bumps carry behavior changes and not only a Node runtime move:
`upload-pages-artifact@v4` stopped including dotfiles in the artifact;
`upload-artifact@v7` and `download-artifact@v8` are a producer/consumer pair
across two different major numbers, and v8 makes a digest mismatch an error
rather than a warning; `checkout@v5` and later require runner v2.327.1, which
GitHub-hosted runners carry.

`actions/deploy-pages` is the one step no run on a branch can reach: it
publishes through the `github-pages` environment, which refuses a deployment
from any branch but the default one, which is why `pages.yml` gates that job.
Its bump therefore ships unexercised, verified on the first default-branch run
after merge; the revert is one line.

**Out:**
- A check holding the workflow files to these versions → refused at the plan
  gate. `versions.yml`'s own header refuses a widened scan of a source file
  the tests do not execute, and the maintainer chose to leave that refusal
  standing rather than supersede it. The runs are the evidence.
- Automated dependency updates (Dependabot or equivalent) → a candidate
  ROADMAP row; this milestone is a one-time catch-up.
- `quarto-dev/quarto-actions/setup@v2` — already the current major; unchanged.
- The exact Quarto version pin — D-024 keeps it exact and this milestone does
  not touch it.
- An EPUB or PDF leg change, a new workflow, or any change to which events
  either workflow runs on.

## Acceptance criteria

- [ ] AC1 — Over the action references
      `grep -nE '^[[:space:]]*(-[[:space:]]+)?uses:' .github/workflows/pages.yml
      .github/workflows/versions.yml` returns — an enumeration asserted
      non-empty, and matching both the mapping-key and the list-item form a
      step may write — the multiset of references is exactly
      `actions/checkout@v7` ×5, `quarto-dev/quarto-actions/setup@v2` ×3,
      `actions/upload-artifact@v7` ×1, `actions/download-artifact@v8` ×1,
      `actions/upload-pages-artifact@v5` ×1, `actions/deploy-pages@v5` ×1,
      and no other reference appears. Stated as a multiset, not a set and a
      count, so one step's action swapped for another approved one fails.
- [ ] AC2 — The `versions.yml` run this branch's own push triggers completes
      with its `plan`, `render (floor, 1.4.549)`, `render (pinned, <version>)`
      and `compare` jobs all green, and the `compare` job's log states the
      same per-leg fixture counts as the most recent pre-bump `versions.yml`
      run on the default branch states. This is what holds the
      `upload-artifact@v7` → `download-artifact@v8` round trip: the comparison
      reads only what the download produced.
- [ ] AC3 — The `pages.yml` run this branch's own push triggers completes its
      `build` job green through `upload-pages-artifact@v5`, and the artifact
      that run produced, fetched and unpacked, carries — each comparison over
      the whole tree by relative path and not by file type, every path set
      asserted non-empty — exactly the relative paths a `quarto render site`
      of that run's commit produces, but for basenames Quarto builds from a
      content hash of the file, which differ by render environment; and, in a
      one-time comparison made inside GitHub's one-day artifact retention,
      exactly the relative paths the pre-bump `@v3` artifact of run
      33210582962 (commit f121733) carried, that commit's `site/` sources
      shown identical to this branch's by `git diff`. The second comparison
      is what a file class dropped by the v4 exclusion would redden, the two
      artifacts coming from different action majors; the site tree writes no
      dotfile, so the exclusion has nothing here to drop.
- [ ] AC4 — `tests/run-tests.sh --self-test` clean (the `verify` slot's fuller
      pre-review check).

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2, T3
- AC3 → T1, T4
- AC4 → T1, T2, T5

## Tasks

- [x] T1 — `.github/workflows/pages.yml`: `actions/checkout@v4` → `@v7`
      (line 33), `actions/upload-pages-artifact@v3` → `@v5` (line 69),
      `actions/deploy-pages@v4` → `@v5` (line 100). Leave
      `quarto-dev/quarto-actions/setup@v2` (line 40) and the exact Quarto pin
      alone.
- [x] T2 — `.github/workflows/versions.yml`: `actions/checkout@v4` → `@v7`
      (lines 81, 129, 204, 261), `actions/upload-artifact@v4` → `@v7`
      (line 186), `actions/download-artifact@v4` → `@v8` (line 207). Leave
      both `quarto-dev/quarto-actions/setup@v2` (lines 132, 268) alone.
- [x] T3 — push, then read the two runs the push triggers. Record in the work
      log: each job's result, the `compare` job's per-leg fixture counts
      beside the counts the last pre-bump run on the default branch states,
      and both run URLs.
- [x] T4 — fetch the Pages artifact that run produced (`gh run download`),
      unpack it, and compare its file tree by relative path over the whole
      tree against both a `quarto render site` of the same commit and the
      pre-bump `@v3` artifact of the last default-branch run, while that one
      is still inside retention. Record every path count and any difference,
      naming a path the artifacts and the local render name differently.
- [x] T5 — the `DECISIONS.md` entry: the re-pin of five dependencies under
      D-024's major-tag rule, naming what each bump changes behaviorally and
      what would falsify the choice.

## Work log

- 2026-08-28: created by /milestone-plan, promoting the candidate row added at the M52 review gate (2026-08-28) from the maintainer's report of deprecation warnings; the row is absorbed and removed.
- 2026-08-28: the five current majors were read from each action's own releases (`gh api repos/<owner>/<repo>/releases`) on 2026-08-28, not from recollection — checkout v7.0.1, upload-artifact v7.0.1, download-artifact v8.0.1, upload-pages-artifact v5.0.0, deploy-pages v5.0.0, quarto-actions v2.2.0. A dated observation: a newer major is a decision, not a fact to be detected.
- 2026-08-28: criteria audit ran in FULL mode (user-facing tier) in a fresh-context [O] reader, at the maintainer's selection lifting this session's standing no-subagent instruction for the audit. It returned ten findings. Five fixed before the criteria were written: the drafted AC1 grep missed the `- uses:` list-item form; its allowlist-plus-count passed a step whose action was swapped for another approved one, so it became a multiset; the drafted AC3 leaned on `pagescheck.py contains`, which walks `.html` and `.pdf` only and would not see a dropped stylesheet or dotfile, so it became a whole-tree path comparison; a drafted AC4 requiring the `deploy` job to report skipped held identically at the merge base and verified nothing, so it was dropped; and three instrument-bound clauses (where the check lives, that plants exist, that run URLs are recorded) moved into the tasks. One became this round's gate question — the standing refusal of a workflow-file scan — and one was accepted as repo precedent: AC4's suite self-test is the profile's own `verify` slot and every milestone here carries it.
- 2026-08-28: plan gate chose the workflow runs as the evidence over a check pinning the twelve references in the two files, on the maintainer's selection after `versions.yml`'s own header was quoted refusing exactly that ("widening either read is refused: D-011 declines a scan that pins names and shapes in a source file it does not execute"); superseding that refusal stays available and was the alternative weighed. Falsified by a silent downgrade of an action reference reaching the default branch and going unnoticed until a run failed.
- 2026-08-28: plan gate chose bumping `actions/deploy-pages` unexercised, verified on the first default-branch run after merge, over leaving it at v4 until it can be tested, because the `github-pages` environment refuses a deployment from a non-default branch and no branch run can reach the step; the revert is one line. Falsified by that first post-merge run failing to publish.
- 2026-08-28: implement gate approved the re-pin of all five actions as scoped (dependency changes are never unilateral); the three narrower options — holding the publish step, holding the upload/download pair, stopping — were the weighed alternatives.
- 2026-08-28: T1+T2 — twelve `uses:` references now read `actions/checkout@v7` x5, `quarto-dev/quarto-actions/setup@v2` x3, `actions/upload-artifact@v7`, `actions/download-artifact@v8`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`, and nothing else (AC1's grep, counted as a multiset). One `tests/run-tests.sh` run covers both edits, both being YAML-only: 422 checks, all passed.
- 2026-08-28: pre-bump baseline for AC2, read from the last default-branch `versions.yml` run (33210583098, `plan` / `render (pinned, 1.10.18)` / `render (floor, 1.4.549)` / `compare` all success, `pdf` skipped): the `compare` job states book 26 rows, demo 55, html-index 21, named-indexes 41 — 4 comparisons over 4 fixtures against the `pinned` leg.
- 2026-08-28: T3 — the push at 9b8146e triggered both workflows. Versions (https://github.com/jmgirard/quarto-index/actions/runs/33211320047): `plan` success, `render (pinned, 1.10.18)` success, `render (floor, 1.4.549)` success, `compare` success, `pdf` skipped. The `compare` job states book 26 row(s), demo 55, html-index 21, named-indexes 41 — 4 comparisons over 4 fixtures — the same counts as the pre-bump run 33210583098. Pages (https://github.com/jmgirard/quarto-index/actions/runs/33211320021): `build` success through `upload-pages-artifact@v5`, `deploy` skipped, the branch not being the default one.
- 2026-08-28: T4 — the Pages artifact unpacks to 79 relative paths; a clean local `quarto render site` at Quarto 1.10.18 (the workflow's own pin, `site/_site` removed first) produces 79. One path differs: the artifact names the bootstrap bundle `bootstrap-d5382f61a7c05c0e60b360404eaa31c2.min.css`, the local render `bootstrap-629c56ba100745318e9dcb35146191d0.min.css`. The two files are 499,317 bytes each and carry the same rules in a different block order, so the content hash Quarto names them by differs by render environment. The pre-bump `@v3` artifact (run 33210582962, at f121733, whose `site/` is identical to this branch's by `git diff`) unpacks to the same 79 paths as the `@v5` artifact, byte-identical as a path set — so the one difference is the local reference and not the bump. The render writes no dotfile at all (0 found), so the v4 dotfile exclusion has nothing here to exclude.
- 2026-08-28: substantive amendment at a mini gate — AC3's reference changed. As planned it bound the artifact to a render on this machine, and that comparison reports one difference the bump does not cause: Quarto names a bootstrap bundle by a content hash of a 499,317-byte stylesheet whose block order is not stable across render environments (both sides 79 paths, 78 identical). The maintainer chose comparing the two artifacts over keeping the wording, over normalizing the hashed basename, and over stopping. AC3 is the only criterion amended; no criterion was added and none of the others changed.
- 2026-08-28: criteria audit of the amended AC3 ran in FULL mode (user-facing tier) in a fresh-context [O] reader that authored none of the wording, at the maintainer's selection lifting this session's default of not spawning agents. It returned four findings, all with one clear repair and all narrowing, and all four were applied before the text was written: the drafted `@v3` referent was a moving one whose artifact expires 2026-08-29 (`expires_at` read from the API on both runs, and no post-merge run can produce a `@v3` artifact again), so it is pinned to run 33210582962 at f121733 and named as a one-time comparison inside retention; the dotfile clause promised a probe of a class the site produces none of, so it now says the exclusion has nothing here to drop; the local-render side had degraded to a bare path count, which a compensating add-and-drop satisfies, so it is a set relation again with content-hash basenames named as the exception; and the closing "named in the evidence" clause bound a recording act rather than the artifact, so it moved into T4. The reader also recorded that no principle or prior decision blocks the wording, that comparing two artifacts from different action majors is what gives the check a way to fail, and that a later escalation from paths to file contents would need its own superseding entry — noted for T5.
- 2026-08-28: the amended AC3 measured against what T3 and T4 produced, every clause holding: 79 paths in the `@v5` artifact, 79 in the local render, 79 in the `@v3` artifact; the `@v5` and `@v3` path sets identical raw; the `@v5` and local sets identical once a trailing 32-hex basename segment is normalized, their one raw difference being `site_libs/bootstrap/bootstrap-d5382f61a7c05c0e60b360404eaa31c2.min.css` against `bootstrap-629c56ba100745318e9dcb35146191d0.min.css`; and `git diff f121733 9b8146e -- site/` empty. The criterion's box stays unticked — review ticks it against its own evidence.
- 2026-08-28: T5 — D-033 records the re-pin of the five actions under D-024's major-tag rule, naming what each bump changes behaviorally, that the publish step ships unexercised, and that a path comparison escalating to file contents would take its own superseding entry.
- 2026-08-28: `tests/run-tests.sh --self-test` clean at the branch head — 824 checks, all passed. Status to `review`.

## Decisions

## Review
