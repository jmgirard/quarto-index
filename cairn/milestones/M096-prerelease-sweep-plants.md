<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M096: The pre-release sweep fails on the defects it names, from one definition

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a checker over the repo's own documentation pages, which nothing outside the repo consumes
- **Branch/PR:** —

## Goal

The pre-release sweep is defined once and reports on every failure branch it
holds, including the empty-sentence row that today matches every page silently.

## Scope

**In:** merging the sweep's two copies — `check_prerelease_absent` in
`tests/run-tests.sh` and `swept_domain`/`read_rows` in `tests/sitecheck.py` —
into the one definition the module holds; refusing a retired-sentence row whose
sentence half is empty; planting the four branches no case reaches; and
deleting the unmeasured page count from the floor's comment.

**Out:**

- Restoring the report clause that names the offending file on a page that
  cannot be decoded → stays on the candidate row; it takes a decision
  superseding D-029 first.
- Restoring `tests/sitecheck.py links`' containment clause → stays on the
  candidate row; M46 failed it four times and the gated amendment withdrew it.
- Binding the publishing workflow's own steps, the artifact containment beyond
  `.html` and `.pdf`, and the published URL's derivation → stay on the
  candidate row; D-011 refuses the source-shape scan each would take.
- The two book-log partition gaps in `tests/m29book.py` → stay on the candidate
  row; they are a different checker.
- Making the floor fail on a live domain that has grown past it → not planned;
  the gate chose deleting the stale figure over picking a drift threshold.

## Acceptance criteria

- [ ] AC1: The pre-release sweep's domain enumeration is defined once, in
      `tests/sitecheck.py`. `check_prerelease_absent` in `tests/run-tests.sh`
      holds no `git ls-files` enumeration, no README-tracked test and no floor
      of its own, reaching all three by invoking `tests/sitecheck.py`. The
      domain this claim quantifies over is that function's whole definition,
      read top to bottom.
- [ ] AC2: The pre-release sweep reports, rather than crashing or passing
      silently, on every failure branch of its consolidated definition — the
      domain enumerated by reading each branch of that definition that returns
      or prints a failure message. Today that set is: a retired-sentence list
      that is empty; a row with no tab; a row whose sentence half is empty;
      `git ls-files` exiting non-zero; README.md absent from the enumeration;
      a domain smaller than the floor; and a page in the domain that cannot be
      read.
- [ ] AC3: A retired-sentence row whose sentence half is empty is refused as
      malformed rather than matching every page in the domain.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2, T4
- AC3 → T2, T4

## Tasks

- [ ] T1: Move the retired-sentence comparison and the unreadable-page branch
      into `tests/sitecheck.py` beside `swept_domain` and `read_rows`
      (`tests/sitecheck.py:505-535`), so one definition holds the enumeration,
      the README test, the floor, the row reading and the comparison. Keep the
      overlay-directory argument the self-test drives it with.
- [ ] T2: Refuse a retired-sentence row whose sentence half is empty, in
      `read_rows`, beside the existing no-tab refusal. Today an empty sentence
      flattens to the empty string, which is a substring of every page body, so
      the sweep reports the whole domain.
- [ ] T3: Replace `check_prerelease_absent`'s inline heredoc in
      `tests/run-tests.sh:1839-1937` with a call to `tests/sitecheck.py`,
      leaving the call site at `tests/run-tests.sh:1935` and its `fail` message
      unchanged. Batch every edit to this file: editing it while a run is in
      flight corrupts that run's own parse (M073).
- [ ] T4: Plant the four branches no case reaches — `git ls-files` exiting
      non-zero, README.md untracked, a page in the domain that cannot be read,
      and the empty-sentence row — each asserting the branch's own message
      rather than a bare non-zero exit. Read the `errexit` shape the plant
      helper runs under before trusting a green plant (M37), and show each
      plant red before trusting it.
- [ ] T5: Delete the page count from the floor's comment in
      `tests/sitecheck.py:110-112`, which asserts a number nothing measures.
      The floor and its basis stay; each run already prints the live size.

## Work log

- 2026-09-11: created by /milestone-plan, promoting the publishing half of the site, gallery and publishing candidate row (added 2026-08-26, clustered 2026-09-04); the row stays until this milestone's post-merge hygiene.
- 2026-09-11: criteria audit ran in reduced mode (internal tier), fresh-context [O] reader; returned findings on all four drafted criteria — AC1's grep named a byte-string present in neither file, AC2 counted a green control as a failure clause and bound a plant-matrix property, AC3's second sentence bound the plant and duplicated AC2, AC4 bound the floor and the checker's own prose over an unenumerated domain. All five clear-answer findings fixed at the gate; AC4 dropped as a criterion and its repair moved to T5.
- 2026-09-11: plan gate chose planting the branches the sweep already names over restoring the report and containment clauses M46 withdrew, because planting leaves every promise unchanged and needs no superseding decision, where restoring needs one and cost M46 four review rounds; falsified by a planted branch proving unreachable without widening the sweep's promise.
- 2026-09-11: plan gate chose merging the sweep's two copies over leaving both and planting each, because one definition gives each plant one target and deletes the drift; falsified by the merge changing what the sweep reports on the unmutated repository.
- 2026-09-11: branch m096-prerelease-sweep-plants cut from main, status in-progress.
- 2026-09-11: question gate posed one open choice, the merged sweep's case comparison. The user asked the session to decide. The Decisions entry below records it.
- 2026-09-11: CHECKPOINT, no task ticked. T1-T5 are written and each of the four new branches was shown red by hand against scratch repositories. The full `tests/run-tests.sh --self-test` run that must be clean before any box is ticked was still in flight when the turn ended.
- 2026-09-11: plan gate chose deleting the floor comment's unmeasured page count over teaching the check to fail on drift, because the drift threshold would be invented here rather than derived; falsified by a live domain growing past the floor with the run's printed size going unread.

## Decisions

### 2026-09-11: the merged retired-sentence sweep compares case-sensitively

**Context.** The two copies of the sweep differed in one way beyond their
labels. The inline copy in `tests/run-tests.sh` compared case-sensitively. Its
sibling `phrase-absent` in `tests/sitecheck.py` folds case. M52 review F1
changed that sibling, after a case-sensitive sweep read `Two back-ends ship` as
clean on the first line of README.md and of the site's landing page.

**Decision.** `prerelease-absent` compares case-sensitively. The two modes
share one definition of the enumeration, the README test, the floor, the row
reading and the sweep itself. They differ in the fold flag and in the label the
report names. The question gate posed the choice and the user asked the session
to decide.

**Consequences.** The merged sweep reports on the unmutated repository exactly
what the inline copy reported. That is the falsifier the plan gate named for
merging. A retired sentence restored with a different opening capital still
slips past, where the sibling sweep over the same domain catches it. That is a
finding about today's behavior, so it belongs in the Known issues at this
milestone's post-merge hygiene rather than in a criterion here.

## Review
