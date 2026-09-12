<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M096: The pre-release sweep fails on the defects it names, from one definition

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a checker over the repo's own documentation pages, which nothing outside the repo consumes
- **Branch/PR:** m096-prerelease-sweep-plants

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

- [x] AC1: The pre-release sweep's domain enumeration is defined once, in
      `tests/sitecheck.py`. `check_prerelease_absent` in `tests/run-tests.sh`
      holds no `git ls-files` enumeration, no README-tracked test and no floor
      of its own, reaching all three by invoking `tests/sitecheck.py`. The
      domain this claim quantifies over is that function's whole definition,
      read top to bottom.
- [x] AC2: The pre-release sweep reports, rather than crashing or passing
      silently, on every failure branch of its consolidated definition — the
      domain enumerated by reading each branch of that definition that returns
      or prints a failure message. Today that set is: a retired-sentence list
      that is empty; a row with no tab; a row whose sentence half is empty;
      `git ls-files` exiting non-zero; README.md absent from the enumeration;
      a domain smaller than the floor; and a page in the domain that cannot be
      read.
- [x] AC3: A retired-sentence row whose sentence half is empty is refused as
      malformed rather than matching every page in the domain.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2, T4
- AC3 → T2, T4

## Tasks

- [x] T1: Move the retired-sentence comparison and the unreadable-page branch
      into `tests/sitecheck.py` beside `swept_domain` and `read_rows`
      (`tests/sitecheck.py:505-535`), so one definition holds the enumeration,
      the README test, the floor, the row reading and the comparison. Keep the
      overlay-directory argument the self-test drives it with.
- [x] T2: Refuse a retired-sentence row whose sentence half is empty, in
      `read_rows`, beside the existing no-tab refusal. Today an empty sentence
      flattens to the empty string, which is a substring of every page body, so
      the sweep reports the whole domain.
- [x] T3: Replace `check_prerelease_absent`'s inline heredoc in
      `tests/run-tests.sh:1839-1937` with a call to `tests/sitecheck.py`,
      leaving the call site at `tests/run-tests.sh:1935` and its `fail` message
      unchanged. Batch every edit to this file: editing it while a run is in
      flight corrupts that run's own parse (M073).
- [x] T4: Plant the four branches no case reaches — `git ls-files` exiting
      non-zero, README.md untracked, a page in the domain that cannot be read,
      and the empty-sentence row — each asserting the branch's own message
      rather than a bare non-zero exit. Read the `errexit` shape the plant
      helper runs under before trusting a green plant (M37), and show each
      plant red before trusting it.
- [x] T5: Delete the page count from the floor's comment in
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
- 2026-09-11: T1-T5 done and ticked. `tests/run-tests.sh --self-test` clean, 1520 checks, exit 0, on the tree at this commit. The five new red plants are at lines 992-996 of that run.
- 2026-09-11: claim audit: not owed — internal tier.
- 2026-09-11: review pass 1: three fresh-context lenses, eleven findings, all from the diff-bug lens. F1-F9 fixed at the gate, F10 routed to this milestone's post-merge hygiene, F11 rejected as out of scope. No finding reached the return floor.
- 2026-09-11: F3 superseded the first decision entry's Consequences sentence; the merge changed three report wordings and the entry claimed it changed none.
- 2026-09-11: step-7 approval: m096-prerelease-sweep-plants approved for merge, the nine fixed first at the user's selection.
- 2026-09-11: status review.
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

### 2026-09-11: the merge changed three report wordings, so the entry above overstates it

**Supersedes** the Consequences sentence of the entry above, which reads that
the merged sweep reports on the unmutated repository exactly what the inline
copy reported. The review's third finding showed that sentence false.

**What is true.** The verdict is unchanged: green on the unmutated repository,
over the same 22 files, on the same comparison. Three wordings differ. The ok
line reads `none of the 2 … sentence(s)` where the inline copy read `neither of
the 2 … sentences`, and the empty-list and malformed-row refusals now name the
list's path. Nothing asserts any of the three, so no check changed colour.

**What stands.** The rest of the entry above, including the case-sensitivity
decision itself and the gap it leaves, is unaffected.

## Review

### 2026-09-11, pass 1

**AC1 — the domain enumeration is defined once.** `check_prerelease_absent`
read whole, top to bottom, is two lines: `python3 "$PRERELEASE_SWEEP"
prerelease-absent "$1" ${2:+"$2"}`, with `PRERELEASE_SWEEP` set one line above
to `"$PWD/tests/sitecheck.py"`. Grepped over that whole definition: `ls-files`
0 hits, `README` 0 hits, floor 0 hits. Repo-wide, the swept-domain
`git ls-files -z` call is at `tests/sitecheck.py:543` and nowhere else, the
floor constant at `tests/sitecheck.py:121` and nowhere else, and the
README-tracked test at `tests/sitecheck.py:551`. The one other hit for that
test, `tests/run-tests.sh:20041`, is a plant's expected substring rather than a
test of its own. Verified.

**AC2 — every failure branch reports.** The consolidated definition was read
top to bottom across its four functions (`check_prerelease_absent`,
`read_rows`, `swept_domain`, `sweep_rows`). It holds eight branches that return
or print a failure. Each was run against `prerelease-absent` in this session
and each exited 1 with its own message, none crashing and none passing
silently: an empty list; a row with no tab; a row whose sentence half is empty;
`git ls-files` exiting 128 in a directory that is no repository; README.md
absent from an eleven-page enumeration; a two-file domain under the floor of
11; one page of a twelve-file domain that could not be read, named as
`site/p1.qmd`; and a sentence found on a page, named as
`site/index.qmd (warning header)`. The first seven are the set the criterion
enumerates. The eighth, the sweep's own positive report, is outside that
enumeration and is covered by the two pre-existing restored-sentence plants.
Verified.

**Profile verify slot, re-run after the gate fixes.** `tests/run-tests.sh
--self-test` on the head that merges: 1523 checks, no FAIL line, exit 0. The
three added checks are the blockquote-only row and the empty list asserted on
both halves of its report. The pass before the fixes read 1520 the same way.

**Profile verify slot, pass 1.** `tests/run-tests.sh --self-test`:
1520 checks, no FAIL line, exit 0. The five new plants are red on their own
branches at lines 992-996 of that run, and the two restored-sentence plants,
the collapsed domain and the untabbed row are undisturbed.

**Consistency gate.** `cairn_validate` exit 0, every check PASS or OK. No
principle changed, so the impact report is skipped. The `generic` profile names
no toolchain checks. `LESSONS.md` is 19,968 bytes against its 20,000-byte
budget.

**AC3 — an empty sentence half is refused.** The row `empty half<TAB>` is
refused on this branch as malformed, naming the row. The same row and the same
repository under the pre-M096 definition, extracted from `main` and run in this
session, reported all 22 files of the domain as carrying the retired warning.
Both halves of the criterion's "rather than" are therefore on record. Verified.

### Independent review, 2026-09-11

Three fresh-context reviewers, none of which authored the branch. The
blame-history lens reported no finding, naming what it checked: the NUL-split
enumeration, the stated floor, the README assertion, the malformed-row and
unreadable-page reporting conventions, the blockquote normalization, and the
case sensitivity, each confirmed preserved, and D-029's uncaught
`UnicodeDecodeError` confirmed neither regressed nor silently closed. The
prior-review lens reported no finding: the inline-comment probe returned empty,
and the archived findings it read on these files (M52 F1, M46, M073, M37,
M090) are each honored rather than contradicted. The diff-bug lens reported
eleven, ranked, each triaged below.

F1 (fix now). `tests/run-tests.sh:1848-1849` says the absolute path is needed
because three self-test cases run the check from another directory. Five
helpers do. Verified by grep: the thin repo, the non-repository, the
README-less repo, the unreadable-page repo and the C-quoted-name repo.

F2 (fix now). `tests/run-tests.sh:1829-1830` says the two modes differ in case
folding "and nowhere else". They also differ in the reported label and in the
nouns their reports use, which the same branch's module docstring states.

F3 (fix now, by superseding entry). The milestone-local decision above says the
merged sweep reports on the unmutated repository exactly what the inline copy
reported. The verdict is unchanged, but the ok line reads `none of the 2 …
sentence(s)` where the inline copy read `neither of the 2 … sentences`, and two
refusal messages gained the list's path. Both wordings confirmed by reading
`main` and the branch.

F4 (fix now). The new refusal's predicate is `not flatten(text)` and its
message says "nothing after its tab". Confirmed misleading: a row whose half
holds only spaces, or only a blockquote marker, gets that message and echoes a
row in which the offending bytes are invisible.

F5 (fix now). `read_rows`' new docstring paragraph says such a row "holds a
page to nothing and reports every page swept". No one row does both, and the
module docstring's `claims` and `phrase-absent` blocks do not record the new
refusal, which both modes now enforce.

F6 (fix now). The README-less plant's guard asserts that no README.md exists in
the working tree, where its sibling asserts git's own listing. The weaker shape
is the one `cairn/check-design.md`'s M42 lesson names: were the scratch `.git`
ever absent, git would resolve to this repository, the domain would come back
empty, and the plant would go red on the same message for another reason.

F7 (fix now). AC2's first branch, an empty retired-sentence list, has no plant
driving it through this mode. AC2 is about the code reporting, which the
evidence above establishes directly, so this is an evidence gap rather than a
criterion failure. The plant closes it.

F8 (fix now). The non-repository directory is made with `mktemp -d` outside the
work directory, so a failing plant strands it where the suite's own clean never
reaches, and its bare `rmdir` would kill the run with no FAIL line.

F9 (fix now). The deliberate unquoted expansion at `tests/run-tests.sh:1852`
carries no `shellcheck disable` marker, where the file marks its four others.

F10 (follow-up, this milestone's post-merge hygiene). `cairn/DESIGN.md`'s KI93
describes the duplication this branch removes, and the architecture prose near
line 699 still calls the pre-release sweep a standalone check. Both are hygiene
writes rather than branch work.

F11 (rejected, out of scope). Two prose counts in unmodified lines predate this
branch and the diff did not introduce them.

Return floor: none of the eleven demonstrates an acceptance criterion failing,
and none is a defect in what the checker does for its readers. The sweep's
behavior is verified correct above. No status return.
