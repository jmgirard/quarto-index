<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M086: The sweep-discrimination probe stops re-sweeping the set once per page

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** internal — a probe over the acceptance suite's own residue sweeps, which nothing outside this repo runs
- **Branch/PR:** `m086-linear-sweep-discrimination`

## Goal

The M24 residue probe shows each whole-set sweep reading every captured page
without running that sweep once per page.

## Scope

**In:** the per-page plant loop in the M24 section of `tests/run-tests.sh`
(the `while` at 20653-20679, whose body runs only under `--self-test`); a
many-page mode for `tests/plantdefect.py --html`; KI33 in `cairn/DESIGN.md`,
whose stated cost this resolves and whose figure is stale.

**Out:** the ~840 s a plain (non-`--self-test`) run costs → the suite-run
shape candidate row. Parallel legs, a named-subset run, per-render timing →
the same row. The M33 plant matrix in the same section (24 plants, already
one sweep each) and the empty-div half (3 named pages) → untouched. Any
change to what `tests/htmlsweep.py` itself promises → out; this milestone
moves only how the probe exercises it.

## Acceptance criteria

- [x] AC1: The probe plants each residue into every page `find
      "$CAPTURE_ROOT" -name '*.html'` lists, in one pass per residue, and
      requires the sweep to go red naming every one of those pages; the
      three residues are `data-qi-pending`, `data-qi-meta` and the marker
      class.
- [x] AC2: For each of the three residues the probe also plants into a
      single page of an otherwise unplanted mirror, and requires the sweep
      to go red naming that page and no other page the same `find` lists.
- [x] AC3: The probe counts the pages it planted and fails when that count
      is not the page count the same `find` returns, so a plant that
      substituted nothing is reported as the plant it is rather than as the
      sweep failing to discriminate.
- [x] AC4: On a `--self-test` run the M24 section's residue half invokes
      `tests/htmlsweep.py` exactly eight times: two for the unplanted-mirror
      precheck, three for the all-at-once plants, three for the single-page
      plants.
- [x] AC5: The unplanted-mirror precheck still runs ahead of every plant and
      both sweeps pass on it, so a red leg below it is evidence about the
      plant.
- [ ] AC6: `tests/run-tests.sh --self-test` is clean (the `verify` slot's
      pre-review form).

## Coverage

- AC1 → T1, T2, T6
- AC2 → T3, T6
- AC3 → T1, T2, T7
- AC4 → T2, T3
- AC5 → T2
- AC6 → T5, T9

## Tasks

- [x] T1: Give `tests/plantdefect.py --html` a many-page mode: one residue
      kind planted into every page named on the command line, in one
      invocation, printing the marker once. A page whose anchor text is
      absent is an error naming that page, so the existing no-op guard
      holds per page rather than per call (`plant_html`, 266-282).
- [x] T2: Replace the per-page loop (`tests/run-tests.sh` 20653-20679) with
      one plant pass and one sweep per residue: plant all pages, sweep, and
      require the output to carry the expected marker and to name each page
      the `find` listed. Keep the unplanted-mirror precheck ahead of it
      unchanged, and keep the page-count assertion that stops the leg
      running over an empty mirror.
- [x] T3: Add the three single-page legs on a freshly re-copied unplanted
      mirror — one per residue — each requiring the sweep red, naming its
      page, and naming no other page in the mirror.
- [x] T4: Rewrite the section's banner comment to state what the probe now
      does; correct KI33 in `cairn/DESIGN.md` (marked corrected, its 14,000
      figure superseded by the count this milestone leaves).
- [x] T5: Run `tests/run-tests.sh --self-test` whole and record the M24
      section's new row from `tests/.work/timing.tsv` beside the 3080 s the
      2026-09-10 run recorded.
- [x] T6: Read a page as named only between spaces or line ends, the way
      both sweeps print names (`sweep_named`), and replace the path-boundary
      guard with one that fails when a page name could read as named inside
      another page's name or across two adjacent ones; correct the comment's
      exactness claim. Re-prove: `book-html/_book/index.html` left unplanted
      turns the all-pages leg red naming it.
- [x] T7: Plant into the pages `find` lists in the mirror itself, count the
      pages that then differ from the unplanted mirror (`diff -rq`), and
      require that count to equal the capture root's `find` count, failing
      as the plant's fault. Re-prove: a page deleted from the mirror before
      the plant turns this leg red.
- [x] T8: Review findings folded in at the implement gate: KI33's pointer
      and the scope of its timing figure; the two single-page comments in
      `tests/plantdefect.py`; a usage error for `--html` with no page.
- [x] T9: Run `tests/run-tests.sh --self-test` whole and bring KI33's
      figures to that run.

## Work log

- 2026-09-10: created by /milestone-plan.
- 2026-09-10: plan gate chose all-at-once plants plus three retained single-page legs over an all-at-once-only probe, a sampled subset of pages, and deleting the probe outright, because the accumulating sweeps name every offending page, so one sweep carries the same per-page reading claim while the retained singles keep the one-red-among-clean evidence the all-at-once form loses; falsified by a sweep mode that stops at its first offending page, which would make the all-at-once output silent about every page after it.
- 2026-09-10: plan gate chose a fixed sweep-invocation count as the cost criterion over a wall-clock bound, because KI251 records whole runs as unreliable on this machine and a recorded-seconds promise would go red for reasons that are not this change; falsified by an invocation count staying fixed while per-invocation cost grows.
- 2026-09-10: reduced criteria audit (internal tier) by a fresh [O] reader returned findings on one criterion of five — the drafted AC4 promised a result over an unbounded family of mirror sizes and demanded a second capture root be built; repaired before writing by restating it as a fixed invocation count observed inside the single run. AC1, AC2, AC3, AC5 clean on all three questions.
- 2026-09-10: implement gate chose the plant call's shape as kind-first with a variadic page list (both existing callers rewritten), a run-counted sweep total over a reading of the call sites, and one page for all three single-page legs.
- 2026-09-10: T1-T3 landed together — the plant tool's new call shape and its two callers must move in one commit for the suite to stay runnable. Each new leg proved able to fail by mutating the probe: restoring one planted page silently → the all-pages leg red naming it; planting a second page in a single-page leg → the no-other-page leg red naming it; a ninth sweep → the count leg red at 9; a mirror one page short → the plant-count leg red at 770 of 771.
- 2026-09-10: the sweep's named pages are read with awk's `index` rather than `grep -oFf` — the shim answering `grep` on this machine (ugrep 7.8.4) reported 146 of 771 named pages where the sweep named every one, which would have made the all-pages leg red for a reason that is not the sweep.
- 2026-09-10: T4 — the section banner now states what the probe does, read from `htmlsweep.py`'s two accumulating sweeps; KI33's cost clause corrected, its 14,000-parse figure replaced by eight sweeps over the captured set (6,168 parses at the 771 pages the 2026-09-10 capture root held) and what is left of the entry pointed at the suite-run shape row.
- 2026-09-10: deviation from the per-task verify slot — the M24 residue half runs only under `--self-test`, whose whole run the 2026-09-10 timing recorded at 3080 s, and the profile's own slot forbids concurrent runs. T1-T3 were verified against an extraction of the section over a prior run's 771-page capture root (24 s); the whole `--self-test` run is T5, and stands as the verify for every task.
- 2026-09-10: T5 — `tests/run-tests.sh --self-test` clean, 1451 checks, exit 0. The M24 section's timing row is 23 s against the 3080 s the run before it recorded. The section's own `find` listed 497 pages, the capture root still filling at that point in the run (771 by the end), so the half's cost is 8 x 497 = 3,976 parses.
- 2026-09-10: corrects the T4 line above and the KI33 text it landed — the 771 pages it cited came from a leftover capture root accumulated across runs, not from the 2026-09-10 run's own root at the section's point in it. KI33 fixed in place to 497 pages and 3,976 parses; the mutation and extraction evidence recorded above stands, having been run over that 771-page root.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: review returned to in-progress (defect return 1). AC1 fails: `sweep_named` counts a page as named when its path occurs anywhere in the sweep output, and the path-boundary guard misses `book-html/_book/index.html` inside `parity-inst-book-html/_book/index.html`, so the all-pages leg passed with that page left unplanted. AC3 fails: the count check compares two reads of one unchanged `find`, taken before the plant runs, so it counts no planted page and cannot go red. Evidence and the diff-bug reviewer's ten untriaged findings are in the Review section.
- 2026-09-10: resumed after the review return. Implement gate chose a space-bounded name read, with a guard over names that could read as named inside another name or across two, over parsing the sorted list; a count of pages that differ from the unplanted mirror, over the plant tool reporting its own count; and folding review findings 3-5 into this round, leaving `-type f` out because AC1 and AC3 quote the `find` command. T6-T9 added and Coverage extended to them (minor amendment; no criterion text changed).
- 2026-09-10: T6 — `sweep_named` reads ` name ` against the output padded with a space per line end, and the guard fails on a name that is a word of a name with a space, or a spaced name beginning with a word another name carries or one with no `/`. Verified on the section extracted over a copy of the 771-page capture root (the same deviation as T1-T3; T9's whole run is the verify): control passes at 8 sweeps; `book-html/_book/index.html` left unplanted → all-pages leg red naming it; a second page planted in a single-page leg → red naming it; an added `book-order-1/_book/later x.html` → guard red naming both names.
- 2026-09-10: T7 — the all-pages plant aims at `find "$SWEEPW" -name '*.html'`, and the pages it planted are counted as the `Files … differ` lines of `diff -rq` against the unplanted mirror, required equal to the capture root's `find` count before the sweep runs. Verified on the extraction over the 771-page copy: control passes at 8 sweeps (23 s); a page deleted from the mirror before the plant → count leg red at 770 of 771; a page restored after the plant → the same; a page restored after the count, before the sweep → all-pages leg red naming `book-html/_book/index.html`; a second single-page plant → red naming it; a ninth sweep → red at 9.
- 2026-09-10: T8 — KI33 drops its pointer to the suite-run shape row (that row is at its 400-byte cap and does not list KI33) and says its 23 s row covers the whole section, M33 plant matrix and empty-div half included; `plantdefect.py`'s two residue-plant comments describe the pages named on the command line; `--html` with no page now exits with the usage text (exit 1) instead of falling into the source-scan path. The T7 extraction runs above used this `plantdefect.py`.
- 2026-09-10: T9 — `tests/run-tests.sh --self-test` clean at 0a1de5f, 1451 checks, exit 0, 9 min 41 s wall. The M24 section's `find` listed 497 pages and its timing row is 23 s, the figures KI33 already states, so KI33 is unchanged.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: review pass 2 checkpoint (in progress) — AC1-AC5 evidence recorded and the consistency gate clean; AC6 unticked while the fresh `--self-test` run is going, and the diff-bug reviewer has not reported.

## Decisions

## Review

**Pass 1 — 2026-09-10, at e92fa0f. Stopped at step 3: AC1 and AC3 fail as written.** Branch base abe17d1 is `origin/main`'s head, so no sync merge was needed; no PR exists. Mutation evidence below comes from the M24 residue half extracted into a scratch script over a copy of the run's 771-page capture root (control: exit 0, 8 sweeps, 24 s).

- AC1 — **fail.** Restoring one planted page (`book-corrupt/_book/last.html`) turns the all-pages leg red naming it. But the domain holds 9 page names that occur inside another page's name without a `/` before them (e.g. `book-html/_book/index.html` inside `parity-inst-book-html/_book/index.html` and `parity-tree-book-html/_book/index.html`), and the real run's 497-page mirror holds those pages too. The ambiguity guard checks only suffixes after a `/` and passes. Leaving `book-html/_book/index.html` unplanted in the all-pages leg: the probe passes, exit 0. The probe does not require the sweep to name every page.
- AC2 — pass. Planting a second page (`book-badxref/_book/last.html`) in the single-page leg turns it red naming that page beside `book-badxref/_book/index.html`.
- AC3 — **fail.** The number compared is the length of the target list built from the first `find`, checked against a second `find` over the same unchanged root, before `plantdefect.py` runs; no planted page is counted. Deleting one page from the mirror before the plant is caught by `plantdefect.py`'s `FileNotFoundError` and the "planted nothing" message, not by the count check. Only editing the target array itself turns the count check red (770 of 771).
- AC4 — pass. The suite's pass line reports 8 sweeps and the extraction prints `SWEEP_RUNS=8`; every call in the half goes through `sweep_run`. Adding a ninth `sweep_run` turns the count leg red at 9.
- AC5 — pass. Read at `tests/run-tests.sh` 20701-20707: `sweep_mirror`, then both sweeps required to exit 0, ahead of every plant; each later leg re-copies from that same `$SWEEP_ORIG`. The suite run below reached and passed both.
- AC6 — pass. `tests/run-tests.sh --self-test`: 1451 checks, exit 0, 9 min 50 s wall. The M24 section's timing row is 23 s; its `find` listed 497 pages (771 at the end of the run).

**Consistency gate.** `cairn_validate.py` exit 0, all checks passed. No principle text changed, so `cairn_impact.py` was skipped. The `generic` profile names no toolchain checks.

**Independent review.** [S] blame-history: no findings; one note with no failure case (the page array is sorted by locale, the domain file by C collation; `comm` reads only C-sorted files). [S] prior-review: no prior-review evidence in the archives on these files; the PR-comment probe returned nothing. [O] diff-bug: ten findings, ranked by the reviewer, untriaged because review stopped before the gate:

1. The AC3 count check cannot fail and counts no planted page (`tests/run-tests.sh:20722`) — confirmed above.
2. The ambiguity guard checks only suffixes after `/`, while `sweep_named` matches any substring, so a page can read as named when only a page containing its name was; the comment's exactness claim is wrong for the same reason (20666, 20693) — confirmed live above.
3. KI33 says what remains belongs to the suite-run shape candidate row, which does not list KI33; the entry also carries one run's section timing, which covers the M33 plant matrix and empty-div half as well as the residue half (`cairn/DESIGN.md:1037`, `cairn/ROADMAP.md:30`).
4. Two comments in `tests/plantdefect.py` still describe planting into one page (186, 197).
5. `--html <kind>` with no page falls into the source-scan path and exits with a misleading message rather than a usage error (298).
6. `find -name '*.html'` has no `-type f`; a directory so named would stop the run with no FAIL line (20652, 20722).
7. The AC4 counter counts `sweep_run` calls, so a direct `htmlsweep.py` call added later would go uncounted (20764).
8. A filename containing a newline would break the domain file and the `wc -l` count (20662, 20722).
9. All three single-page legs use the same page, `SWEEP_RELS[0]` — the implement gate's recorded choice.
10. `$WORK/sweepprobe-unplanted` is left in place, a second copy of the captured HTML until the next run.

**Pass 2 — 2026-09-10, at ea5ec63.** Branch base abe17d1 is still `origin/main`'s head and local `main` has no unpushed commits, so no sync merge was needed; no PR exists. Mutation evidence comes from the M24 residue half (`tests/run-tests.sh` 20644-20794) extracted into a scratch script over a copy of the 771-page capture root the T9 run left, one mutated copy per check. Control: exit 0, 8 sweeps, 24 s.

- AC1 — pass. The all-pages legs loop over `pending`, `meta` (judged by the pending sweep) and `marker`; each plants every page the mirror holds in one `plantdefect.py` call, the plant-count leg (AC3) holds that set equal to the capture root's `find` count, and the sweep output is read for every name in the domain file built from `find "$CAPTURE_ROOT" -name '*.html'`. Restoring `book-html/_book/index.html` after the count and before the marker sweep → red naming that page (pass 1's escaping case, now through the marker sweep's `; `-joined output). Adding a page named `book-html/_book/index.html tail.html` → the name guard red, naming both names.
- AC2 — pass. The three single-page legs plant `book-badxref/_book/index.html` (`SWEEP_RELS[0]`) in a freshly re-copied unplanted mirror, one per residue. Planting `book-corrupt/_book/last.html` beside it → red naming that page beside the planted one. Aiming the plant at `book-corrupt/_book/last.html` instead → red: the sweep did not name `book-badxref/_book/index.html`.
- AC3 — pass. After each all-pages plant the leg counts the `Files … differ` lines of `diff -rq` between the unplanted and planted mirrors and requires that count to equal a fresh `find "$CAPTURE_ROOT" -name '*.html' | wc -l`, failing with a message naming the plant as at fault, before the sweep runs. Removing `book-corrupt/_book/last.html` from the unplanted mirror itself (the case pass 1's check missed) → red, "the pending plant changed 770 page(s) where the captured set holds 771". Restoring that page right after the plant → the same red at 770 of 771.
- AC4 — pass. A `python3` shim on the control run's PATH, logging each `tests/htmlsweep.py` call apart from the probe's own counter, recorded 8 calls in the order pending, marker (precheck), pending, pending, marker (all-pages), pending, pending, marker (single-page); the probe printed `SWEEP_RUNS=8`. A ninth `sweep_run` → red at 9.
- AC5 — pass. Read at `tests/run-tests.sh` 20718-20724: `sweep_mirror`, then the pending and marker sweeps each required to exit 0, ahead of every plant; every later leg re-copies from that same `$SWEEP_ORIG`. The shim's call order above shows the two precheck sweeps first. Planting `pending` into one page of the precheck mirror → red, "the pending sweep fails on the unplanted mirror".

**Consistency gate (pass 2).** `cairn_validate.py` exit 0, all checks passed. No principle text changed in `cairn/DESIGN.md`, so `cairn_impact.py` was skipped. The `generic` profile names no toolchain checks.
