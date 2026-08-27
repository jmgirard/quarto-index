# M46: The claim-container registry is retired, not widened

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Branch/PR:** `m046-retire-claim-registry` — [PR #46](https://github.com/jmgirard/quarto-index/pull/46)

## Goal

Retire the claim-container registry and its eighteen containers rather than widen
them, keep D-026's pre-release promise by a check that reads its own domain, and
repair the three real defects in the site checks that stay.

## Scope

**In:** Surface tier **internal** — the deliverable is this repo's own acceptance
suite over its own documentation source; no external consumer of the repo relies
on it. Delete `CLAIM_CONTAINERS`, `claim_row`/`claim_kind`/`claim_domain`/
`claim_text`, `check_claim_registry`, `check_claim_sets` and every comparison
check that reads its domain through `claim_text`. Three registered containers —
`README_RECIPE_LINES`, `README_INDEXES_CLAIMS`, `README_INDEXES_YAML` — are read
by checks naming their own page and are kept with those checks; only their
registry rows go. Replace `README_PRERELEASE_STALE` with a standalone check over
`git ls-files 'site/*.qmd'` plus `README.md`. Repair `tests/sitecheck.py links`
(percent-decoding, containment, the base-path clause) and make the standing site
render clean its output directory. Append D-027.

**Out:** the version-matrix disposition → M47. Pinning documentation prose beyond
the two retired pre-release sentences → the residual-risk candidate row D-027
creates. Rewording any site page → not this milestone; the docs' text is
untouched. Every remaining unplanted clause in the kept site checks → the same
candidate row.

## Acceptance criteria

- [x] AC1: In `tests/run-tests.sh`, `grep -c 'CLAIM_CONTAINERS\|claim_row\|claim_kind\|claim_domain\|claim_text'` reports 0.
- [ ] AC2: `tests/run-tests.sh` carries a check whose swept domain is `git ls-files 'site/*.qmd'` plus `README.md`, which reports that domain's size, and which exits non-zero with a `FAIL:` line naming the offending file when either retired pre-release sentence is present in a tracked page supplied through the suite's overlay handle.
- [x] AC3: Every row of the `CLAIM_CONTAINERS` array as it stands at commit 9e6b567 is dispositioned in this file's Decisions section — still pinned by a named kept check, or deleted with the reason.
- [ ] AC4: `tests/sitecheck.py links` percent-decodes each link's path part and resolves it only against files inside the captured site directory it was given.
- [x] AC5: `tests/sitecheck.py links`' base-path clause exits non-zero on a root-relative link carrying no base segment.
- [x] AC6: The suite's standing site render removes its output directory before rendering into it.
- [x] AC7: `tests/run-tests.sh` completes at exit 0 and prints its check count, and `tests/run-tests.sh --self-test` completes at exit 0.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T4
- AC5 → T4
- AC6 → T5
- AC7 → T7

## Tasks

- [x] T1: Enumerate the eighteen `CLAIM_CONTAINERS` rows ([run-tests.sh:657](tests/run-tests.sh:657)) and, for each, name the check that reads it and what its deletion drops; write the table into this file's Decisions section.
- [x] T2: Delete the registry and its helpers ([run-tests.sh:636-727](tests/run-tests.sh:636)), `check_claim_registry` and `check_claim_sets` (~1839-1970), the fourteen container arrays read through `claim_text`, and every comparison check reading them. `README_RECIPE_LINES`, `README_INDEXES_CLAIMS` and `README_INDEXES_YAML` keep their arrays and their checks. The `fail`-inside-a-command-substitution defect goes with `claim_row`.
- [x] T3: Write the standalone pre-release check: the two retired sentences verbatim, domain `git ls-files 'site/*.qmd'` plus `README.md`, swept count reported, offending file named. Drop the two generic rows M44 found — sentences still true, which would report a legitimate future stability sentence as the warning coming back. Plant each sentence through the overlay handle.
- [x] T4: Repair `tests/sitecheck.py links` — percent-decode the path part, confine resolution to the captured site root, fail a root-relative link with no base segment. One planted case each.
- [x] T5: Make the standing site render remove `$SITE_OUT` before rendering ([run-tests.sh:13302](tests/run-tests.sh:13302)).
- [x] T6: Append D-027; strike the DESIGN.md Known-issues entries this closes; rewrite the ROADMAP rows pointing at them.
- [x] T7: Full run plus `--self-test`; record the check count before and after.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan gate chose retiring the claim-container registry over narrowing it to a kept set, because three of the row's findings are repairable only by widening a scan over the suite's own source — the shape D-011 refused and M25 executed under "A check that cannot hold its promise is retired, not widened"; falsified by a documentation sentence drifting from behavior and reaching a release with the suite green.
- 2026-08-26: plan gate chose superseding D-026's mechanism clause with a standalone grep over keeping that one container, because a one-row registry is still a registry and M44 found two of its four rows would report a legitimate stability sentence as the warning coming back; falsified by the standalone check going vacuous where the registry's domain enumeration would not have.
- 2026-08-26: criteria audit ran in reduced mode (internal tier). It returned two findings here — a work-log recording clause on the suite-run criterion, and plant-property wording ("red before the fix and green after") on the site-check repairs. Both were fixed before the criteria above were written: the recording clause was dropped, and the repairs are stated as assertions on the shipped checks.
- 2026-08-27: implement gate settled four open choices, all at the recommendation: the link check's base-segment clause binds only when a base path is given (nine existing plants pass an empty one); an escaping link gets its own failure message rather than reusing "names no file"; percent-decoding covers the path part only, as AC4 states; and the replacement pre-release check keeps printing the `M44-AC1` label.
- 2026-08-27: amendment — Scope In's deletion clause narrowed from "every per-container comparison check" to "every comparison check that reads its domain through `claim_text`", and T2's task wording with it. T1's enumeration found three registered containers the registry does not stand between: `check_recipe_block` and `check_readme_indexes` take their page as an argument. Deleting them would have dropped fifteen planted failure cases and M38-AC6's run-ledger clause, none of which the registry's defects were about. Chosen at a mini gate; recorded as D-028, which supersedes D-027's consequences clause on that one point.
- 2026-08-27: T2 — deleted `CLAIM_CONTAINERS`, `claim_row`/`claim_kind`/`claim_domain`/`claim_text`, `check_claim_registry`, `check_claim_sets`, the fourteen containers read through `claim_text` and the thirteen comparison checks reading them, plus the supported-forms banner (the probe-character line it shared is kept under its own banner). `tests/run-tests.sh` 16,277 -> 15,396 lines; the AC1 grep reports 0.
- 2026-08-27: T3 — the pre-release check now enumerates `git ls-files 'site/*.qmd'` plus `README.md` itself (21 files this run), reports that count, names the offending file and sentence, and takes an overlay directory. Two forbidden sentences, not four. Four self-test cases: the first sentence restored into README.md and into the site front page, the second restored re-wrapped across a line break, each asserting the file and sentence the report names, plus an overlay changing nothing that must leave the check green.
- 2026-08-27: T4 — `tests/sitecheck.py links` percent-decodes the path part, refuses a target normalizing outside the captured site, and, where a base path is given, refuses a root-relative link carrying no base segment. Discrimination shown against the pre-fix reader on three hand-built captures: `/syntax.html` under base `docs` exited 0 before and 1 after; `../outside.html` naming a file that exists one directory up exited 0 before and 1 after; `s%79ntax.html` naming a page the render wrote exited 1 before and 0 after.
- 2026-08-27: T5 — the standing site render removes `site/_site` first, with a guard that the removal took. Not a repair for a defect seen here: Quarto 1.10.18 clears the directory itself — a planted `orphan.html` and `leftover/old.html` were both gone after a render (observed 2026-08-27). It makes the guarantee the suite's rather than the renderer's, which matters on the version matrix's 1.4.549 floor leg.
- 2026-08-27: T6 — D-027 was already appended at plan time; D-028 added. DESIGN's claim-container architecture paragraph rewritten to what the suite now does, and KI73 struck, the duplication it described having gone with the claim checks. Three ROADMAP rows rewritten: the gitignore row loses its claim-check half, the publishing-workflow row records its fourth finding fixed here, and the suite-readers row's residual-risk clause is narrowed per D-028.
- 2026-08-27: the M24-AC3 render scan reads comment lines too, so the first wording of T5's comment quoted the render command and was reported as an uncaptured render; the comment names the render below it instead.
- 2026-08-27: T7 — `tests/run-tests.sh` exits 0 at 385 checks (403 before this milestone) and `tests/run-tests.sh --self-test` exits 0 at 687 (707 before). The plain run loses eighteen: thirteen documentation-comparison checks, the registry check, and four `pass` summaries; the self-test loses twenty, the seven registry and claim-set plants and the three pre-release plants it dropped exceeding the seven cases added by T3 and T4. Status set to review.
- 2026-08-27: review returned the milestone to in-progress. AC4 fails: `tests/sitecheck.py links` resolves outside the captured site in two shapes, both reproduced at exit 0 — a root-relative link whose `..` sits behind an existing segment (`target = stripped` never normalized, so the `os.pardir` test is a textual prefix test), and a percent-encoded absolute path (`%2Fetc%2Fpasswd`), decoded after the branch was chosen, which `os.path.join` resolves against `/` rather than the capture. AC1, AC2, AC3, AC5, AC6 and AC7 verified on fresh evidence (suite 385 checks, self-test 687, both exit 0; `cairn_validate` exit 0). Eleven review findings logged in the Review section; first defect return.
- 2026-08-27: T4 rework, from the review's defect return — the link check's containment test now runs on the path the join reaches rather than on the target's text, and the root-relative branch is chosen on the decoded path. Both escapes the review reproduced are closed: `/sub/../../outside.html` with a real segment behind the `..` and `%2Fetc%2Fpasswd` each exited 0 against the pre-fix reader and exit 1 now, the encoded one confined to `etc/passwd` under the capture. Four plants added — the root-relative escape with and without a base path, and the encoded absolute with and without one. Self-test 687 -> 691.
- 2026-08-27: triage gate over the seven findings the review left for this phase, both answers at the recommendation — fix the four in this milestone's own new code, file the three about link shapes the site does not emit. The pre-release check's domain floor is a stated eleven (ten documentation pages plus README), not a number read off the enumeration.
- 2026-08-27: F5/F6/F7 fixed — the standing render's removal is preceded by a pin on `output-dir: _site` in `site/_quarto.yml`, the pre-release sweep's floor is eleven files rather than two, and a sentence row carrying no tab reports a `FAIL:` line instead of raising at the unpack. Three plants added, each shown red on its own mutation: a project file whose output directory is renamed, a repository whose tracked documentation has collapsed to one page, and an untabbed row. Self-test 691 -> 694.
- 2026-08-27: F9 fixed — the ROADMAP suite-readers row's residual-risk clause corrected in place: three of the fourteen dropped sets banned a sentence rather than requiring one, so a page may re-acquire a sentence false about today's behavior, which the earlier wording understated. F8, F10 and F11 recorded on the same row.
- 2026-08-27: full run at exit 0, 385 checks; `--self-test` at exit 0, 694 checks. Status set to review.

- 2026-08-27: review round 2 returned the milestone to in-progress. AC2 fails: `git ls-files` C-quotes a non-ASCII path and the `.qmd` suffix filter drops the quoted entry with no report, so a tracked page carrying a retired sentence is swept past at exit 0 (reproduced end to end in a twelve-page throwaway repo). AC4 fails again, by a third containment mechanism: `os.path.abspath` does not resolve symlinks, so a link through a symlink inside the capture reads a file above it at exit 0. AC1, AC3, AC5, AC6 and AC7 verified on fresh evidence (suite 385 checks, self-test 694, both exit 0; `cairn_validate` exit 0). Five findings logged in the Review section; second defect return, and AC4's second failure by a containment mechanism of the same shape.
- 2026-08-27: the return also fired the thrash rule's same-criterion trigger, AC4 having failed twice by containment mechanisms of the same shape; the plan gate recorded no alternative on the link check's approach, so escalation to a review brief was offered per instance. The user chose the direct repair over escalation, over narrowing AC4, and over parking: resolve symlinks on both sides of the containment test, and enumerate the pre-release domain with `git ls-files -z` split on NUL.
- 2026-08-27: T4 rework, round 2's return — the containment test resolves symlinks on both sides, comparing `os.path.realpath` of the path the join reaches against `realpath` of the capture root. Resolving the root too is what keeps a checkout reached through a symlinked parent from reading as one long escape. Discrimination on a hand-built capture holding `link -> ../real`: a page linking `link/secret.html` exited 0 against the pre-fix reader and exits 1 now, naming the file above the capture; a symlink pointing inside the capture still resolves at exit 0. Both shapes planted.
- 2026-08-27: T3 rework, round 2's return — the pre-release domain is enumerated with `git ls-files -z -- 'site/*.qmd' 'README.md'` split on NUL, so a path git C-quotes carries its own bytes and the suffix filter that dropped it is gone. README.md is enumerated by that command rather than appended, which is also F14's second half: the reported domain size now counts nothing untracked, and a missing README.md is a `FAIL:` line. Discrimination in a throwaway repo of twelve tracked pages, one named `site/naïve.qmd` carrying the warning header: the pre-fix reader printed `ok … 11 file(s) swept` at exit 0, the repaired one exits 1 at 12 files naming that page. Planted as a standing case.
- 2026-08-27: F14's first half — `git ls-files` is run without `check=True` and a non-zero exit is reported as a `FAIL:` line; a file in the domain the working tree cannot read is reported the same way rather than raising out of `open`.
- 2026-08-27: F13 — the standing output-directory pin now prints a `pass` line naming what it held, so it appears in the run log and in the check count rather than passing silently.
- 2026-08-27: full run at exit 0, 386 checks (385 before, the output-directory pin's new line); `--self-test` at exit 0, 698 checks (694 before: the two symlink cases, the C-quoted-path case, and that same pin line). Status set to review.

## Decisions

### T1 — the eighteen registry rows, dispositioned (AC3)

Every row of `CLAIM_CONTAINERS` as it stands at 9e6b567. "Reads it" names the
check that compares the container against the docs; "disposition" says what the
deletion drops.

| # | Container | Kind | Reads it | Disposition |
|---|---|---|---|---|
| 1 | `SUPPORTED_FORMS` | presence | M02-AC6 exemplar comparison, via `claim_text` | Deleted. Drops the pin holding the ten documented authoring forms to the ones the suite exercises; the forms themselves stay exercised by the render checks. |
| 2 | `README_STALE` | absence | `check_claim_sets` (M03-AC7), via `claim_text` | Deleted. Drops the ban on the one-back-end sentences. |
| 3 | `README_HTML_CLAIMS` | presence | `check_claim_sets` (M03-AC7), via `claim_text` | Deleted with its partner — the check takes both containers at once. |
| 4 | `README_SORT_CLAIMS` | presence | M06-AC6, via `claim_text` | Deleted. Drops the pin on the sort-key prose; the behavior stays checked by the M06 renders. |
| 5 | `README_EMPTY_CLAIMS` | presence | M11-AC6, via `claim_text` | Deleted. Same shape: prose pin only. |
| 6 | `README_PRINCIPAL_CLAIMS` | presence | M20, via `claim_text` | Deleted. Same shape. |
| 7 | `README_STALEAUX_CLAIMS` | presence | M22/M31, via `claim_text` | Deleted. Same shape. |
| 8 | `README_RANGE_CLAIMS` | presence | M21, via `claim_text` | Deleted. Same shape. |
| 9 | `README_LETTER_CLAIMS` | presence | M07-AC6, via `claim_text` | Deleted. Same shape. |
| 10 | `README_REFS_STALE` | absence | M32 stale check, via `claim_text` | Deleted. Drops the ban on the fixed-order sentence. |
| 11 | `README_REFS_CLAIMS` | presence | M32 claims check, via `claim_text` | Deleted. The bibliography recipe's own fixture pair stays; the prose pin goes. |
| 12 | `README_UNICODE_CLAIMS` | presence | M33-AC4 prose check, via `claim_text` | Deleted. The copyable block's own check (row 13) stays. |
| 13 | `README_RECIPE_LINES` | presence | `check_recipe_block site/terms-outside-latin-1.qmd examples/unicode.qmd` — page named as an argument, never `claim_text` | **Kept.** The check survives with four planted cases (dropped line, reordering, unstated line, stated line absent from the fixture). Only the registry row goes. |
| 14 | `README_MISUSE_CLAIMS` | presence | M08, via `claim_text` | Deleted. Prose pin only. |
| 15 | `README_MISUSE_STALE` | absence | M08, via `claim_text` | Deleted with its partner — one check, both containers. |
| 16 | `README_PRERELEASE_STALE` | absence | `check_prerelease_absent`, via `claim_text` | **Replaced** (T3) by a standalone check reading `git ls-files 'site/*.qmd'` plus `README.md`. Its two generic rows — "Breaking changes are recorded in the changelog" and the deprecation sentence — are dropped as still-true sentences; the two retired ones stay forbidden. |
| 17 | `README_INDEXES_CLAIMS` | presence | `check_readme_indexes site/named-indexes.qmd … "$RAN_LEDGER"` — page named as an argument | **Kept.** Eleven planted cases and M38-AC6's run-ledger clause ride on it. Only the registry row goes. |
| 18 | `README_INDEXES_YAML` | presence | same check as row 17 | **Kept**, for the same reason. |

Fourteen deleted, three kept, one replaced. The `fail`-inside-a-command-substitution
defect lives in `claim_row` and goes with rows 1-12 and 14-16.

## Review

### Round 1

_Evidence gathered 2026-08-27 on branch `m046-retire-claim-registry` at 3d2383b,
against `origin/main` at 9e6b567 (unmoved since the branch was cut). PR #46._

#### Acceptance criteria

- **AC1** — verified. `grep -c 'CLAIM_CONTAINERS\|claim_row\|claim_kind\|claim_domain\|claim_text' tests/run-tests.sh` prints `0` (grep exits 1, no match).
- **AC2** — verified. `check_prerelease_absent` (run-tests.sh:1474) enumerates its own domain with `git ls-files 'site/*.qmd'` plus `README.md` and refuses a domain under two files. Run standalone: clean, `ok` naming 2 sentences over 21 files swept; with an overlay restoring the warning header into `site/index.qmd`, exit 1 and `FAIL: ... swept 21 file(s): site/index.qmd (warning header)`; with an overlay restoring the fluid-syntax sentence into `README.md` re-wrapped across two blockquote lines, exit 1 naming `README.md (fluid syntax)`. Both the domain size and the offending file are in the report.
- **AC3** — verified. The eighteen container names in `CLAIM_CONTAINERS` at 9e6b567, extracted from `git show 9e6b567:tests/run-tests.sh`, are set-identical to the eighteen rows of this file's T1 table (`diff` of the two sorted name lists is empty). Each row carries a disposition; the three kept ones name live checks — `check_recipe_block` (run-tests.sh:4356, called 4441) and `check_readme_indexes` (run-tests.sh:11756, called 12319).
- **AC4** — **FAILS.** The percent-decoding half holds: a page linking `s%79ntax.html` to a file named `syntax.html` resolves at exit 0, and decoding is applied to the path part only (sitecheck.py:229), the fragment left as written. The containment half does not. Two escapes resolve outside the captured site at exit 0 (fresh captures, 2026-08-27): `/x/../../outside.html` naming a file one level above the capture root, with and without a base path — the root-relative branch assigns `target = stripped` (sitecheck.py:246) without `normpath`, so the `os.pardir` test (sitecheck.py:265-267) is a textual prefix test a `..` behind an existing segment walks past; and `%2Fetc%2Fpasswd`, which `unquote` (sitecheck.py:229) turns into an absolute path after the branch was chosen on the still-encoded value, so `os.path.join(captured, '/etc/passwd')` discards the capture root entirely and the check reads a file anywhere on the filesystem. The relative-branch escape `../outside.html` is refused correctly (exit 1); it is the only containment shape the T4 plant exercises.
- **AC5** — verified. A capture whose only link is `/syntax.html`, checked with base path `docs`, exits 1 with `is root-relative and carries no \`docs\` base segment`. Control: the same link written `/docs/syntax.html` exits 0.
- **AC7** — verified. `tests/run-tests.sh` exits 0 and prints `All checks passed (385 checks).`; `tests/run-tests.sh --self-test` exits 0 at `All checks passed (687 checks).` Both run 2026-08-27 on this branch.
- **AC6** — verified by reading the standing render (run-tests.sh:12473-12477): `rm -rf site/_site` immediately precedes `quarto render site`, guarded by `[ ! -e site/_site ] || fail`, so a removal that did not take is a loud failure rather than a silent render into stale output.

#### Consistency gate

- `cairn_validate.py` — exit 0, all checks passed; every advisory `OK`, the `release window` advisory did not fire.
- `cairn_impact.py` — skipped. The header names IP3, but the diff changes no `IP`/`GP` principle text; `cairn/DESIGN.md`'s changes are the architecture paragraph and the KI73 strike.
- Toolchain checks — the active profile is `generic`, whose `consistency-gate` slot names none. Clean no-op.

#### Independent review

Three fresh-context lenses, none having seen the implementation, each on a
distinct evidence base. Every reported finding is logged with its disposition.

**[S] blame-history lens — no findings.** It re-derived the eighteen-row
disposition table from git history independently: each of the fourteen deleted
containers is read only through `claim_text` and its own comparison check, with
no second reader and no unrelated milestone's promise riding on it; the three
kept containers and `check_readme_indexes`' M38-AC6 run-ledger clause survive
unmodified; the two dropped generic pre-release sentences are referenced nowhere
else; the registry's own self-test block went with it leaving no orphan; the
`rm -rf site/_site` sits before the M42-AC5 leftover snapshot and so does not
perturb it; and the nine existing empty-base link plants still exercise the
no-base path unchanged.

**[S] prior-review lens — no findings.** Archived `## Review` sections on the
touched files were the primary surface. M44's four pre-release findings, M40's
containment finding and M42's base-segment finding are the ones this milestone
was scoped to fix, and it fixes them rather than regressing them; striking KI73
is consistent with the registry being gone. The GitHub probe
(`pulls/comments?per_page=1`) returned `[]` — no real inline review threads exist
in this repo, matching what M45 found — so the per-PR walk was not paid for.

**[O] diff-bug lens — eleven findings, ranked.**

| # | Finding | Disposition |
|---|---|---|
| F1 | The root-relative branch assigns `target = stripped` (sitecheck.py:246) with no `normpath`, so the `os.pardir` containment test (sitecheck.py:265-267) is a textual prefix test: `/x/../../outside.html` resolves to a file outside the capture at exit 0, with and without a base path. | **Return.** Reproduced. AC4 fails inside its own procedure's domain. |
| F2 | `unquote` (sitecheck.py:229) runs after the branch is chosen on the still-encoded value, so `%2Fetc%2Fpasswd` takes the relative branch and becomes an absolute path; `os.path.join(captured, '/etc/passwd')` discards the capture root and the check reads any file on the filesystem, exit 0. It also skips the new base-segment clause. | **Return.** Reproduced. Same criterion, second mechanism. |
| F3 | `cairn/DESIGN.md`'s rewritten architecture paragraph states the link check resolves "only against files inside the captured directory", which F1 and F2 falsify — the repo's own doctrine is that a record certifying a property no check asserts is the defect. | Fix with F1/F2; the sentence is true once they are. |
| F4 | The T4 containment plant (`m40_plant_link linkescape`, run-tests.sh:12633-12637) exercises only the relative-branch escape, so the clause's root-relative and encoded-absolute halves have no discriminating case — which is why F1 and F2 shipped green. | Fix with F1/F2; a plant for each shape. |
| F5 | AC6's guard asserts an absence, and `site/_site` is written down rather than read from `output-dir` in `site/_quarto.yml`, so a changed output directory would leave the removal removing nothing with the guard still green. | For the implement phase to triage. Real, and against the milestone's own "reads its own domain" standard; the criterion as written is met. |
| F6 | `check_prerelease_absent`'s domain-size guard is `len(domain) < 2` (run-tests.sh:1498), which one tracked `.qmd` plus README satisfies, so a nearly-empty `git ls-files` reads as healthy; the count is printed but pinned to nothing. | For the implement phase to triage. |
| F7 | A row of `prerelease-retired.txt` carrying no tab raises `ValueError` at the unpack (run-tests.sh:1510) rather than reporting a `FAIL:` line as the check's own convention requires. | For the implement phase to triage. |
| F8 | With a base path, a bare `/` href now reports as carrying no base segment — a shape (a home or brand link) the suite has no case for, and the clause is live against the real site with base `quarto-index`. | For the implement phase to triage; the full suite is green, so the real site emits no such link today. |
| F9 | Three of the dropped rows were absence bans, not presence pins, so README may re-acquire a sentence that is false about today's behavior; the ROADMAP residual-risk wording records only that prose is pinned where a check names its own page, which understates that. | For the implement phase to triage — a durable-record accuracy point. |
| F10 | `unquote` decodes `%3F` and `%23` into `?` and `#` and defaults to `errors='replace'`, so a non-UTF-8 escape becomes U+FFFD and reports a false dangling link; the query-string confusion it widens is pre-existing. | For the implement phase to triage; the pre-existing half is out of scope. |
| F11 | `flat()`'s blockquote stripper (run-tests.sh:1483) is unanchored to blockquote context and strips a leading `>` from any line, fenced code included — false-positive direction only. | For the implement phase to triage. |

The lens also verified clean: AC1's grep and the absence of every deleted name,
`bash -n` passing over the ~1,000-line deletion, the two pinned sentences
matching the original blockquote at `22faf8e:README.md:7-8` byte for byte, the
new domain being identical to the retired `ALL` domain rather than a narrowing,
the `linknobase`/`linkencoded`/`linkescape` plants discriminating against the
pre-M46 reader in both directions, the T3 plants asserting file *and* sentence
(closing M44's own gap), and nothing reading `site/_site` before the removal.

#### Outcome

**Returned to `in-progress`.** AC4 is not met: `tests/sitecheck.py links` does
not resolve only against files inside the captured site it was given. Two
escapes were reproduced at exit 0 — a root-relative path walking out with `..`
behind an existing segment, and a percent-encoded absolute path that discards
the capture root. Six of the seven criteria hold on fresh evidence; AC4's
percent-decoding half holds and its containment half does not. F3 and F4 ride
with the repair. The remaining seven findings are logged above for triage in
the implement phase. This is the first defect return on M46.

### Round 2

_Evidence gathered 2026-08-27 on branch `m046-retire-claim-registry` at 0d32e09,
against `origin/main` at 9a883e2 (the branch already carries every commit on it).
PR #46._

#### Acceptance criteria

- **AC1** — verified. `grep -c 'CLAIM_CONTAINERS\|claim_row\|claim_kind\|claim_domain\|claim_text' tests/run-tests.sh` prints `0`.
- **AC2** — **FAILS.** The reported half holds: run against this repo the check enumerates its own domain and prints 21 files swept; an overlay restoring the warning header into `site/index.qmd` exits 1 naming `site/index.qmd (warning header)`, and one restoring the fluid-syntax sentence into `README.md` re-wrapped across two blockquote lines exits 1 naming `README.md (fluid syntax)`; an overlay changing nothing leaves it green. The domain does not. `git ls-files` C-quotes a path holding a non-ASCII byte, so a tracked `site/naïve.qmd` prints as `"site/na\303\257ve.qmd"`, which the `.qmd` suffix filter (run-tests.sh:1506) discards with no report. Reproduced end to end in a throwaway repo of twelve tracked pages, one of them non-ASCII-named and carrying the warning header verbatim: the check printed `ok … 12 file(s) swept` at exit 0, while the same sentence in an ASCII-named page of the same repo exited 1 naming the file. The swept count is no signal either — dropping one page and appending README made it read 12 exactly as a complete sweep would.
- **AC3** — verified. The eighteen container names in `CLAIM_CONTAINERS` at 9e6b567, extracted from `git show`, are set-identical to the eighteen rows of this file's T1 table (`diff` of the sorted name lists is empty). The three kept rows name live checks: `check_recipe_block` (run-tests.sh:4372, called 4457) and `check_readme_indexes` (run-tests.sh:11772, called 12335), with their arrays at 319, 12311 and 12326.
- **AC4** — **FAILS.** The two escapes round 1 reproduced are closed, each shown red against the pre-fix reader and green-to-red in the right direction: `/x/../../outside.html` exited 0 before and 1 now; `%2Fetc%2Fpasswd` exited 0 before and 1 now, confined to `etc/passwd` under the capture. Percent-decoding still resolves `s%79ntax.html` to a page the render wrote, and only the path part is decoded. A third containment shape resolves outside the capture at exit 0: a symlink inside the captured directory. `os.path.abspath` (sitecheck.py:271) normalizes text and does not follow links, so a capture holding `link -> ../real` and a page linking `link/secret.html` reads a file above the capture root and reports every link resolved. Reproduced 2026-08-27 on a hand-built capture. The site renders no symlink today (`find site/_site -type l` is empty) and `capture` copies with `cp -R`, which preserves them.
- **AC5** — verified. A capture whose only link is `/syntax.html`, checked with base path `docs`, exits 1 with `is root-relative and carries no \`docs\` base segment`. Controls: the same link written `/docs/syntax.html` exits 0, and the bare `/syntax.html` with no base path given exits 0.
- **AC6** — verified by reading the standing render (run-tests.sh:12495-12507): `check_output_dir_pinned site/_quarto.yml` holds the project file to `output-dir: _site`, then `rm -rf site/_site`, then `[ ! -e site/_site ] || fail`, then `quarto render site`. The pin fires on a renamed copy (`output-dir: _built` → the grep fails, the FAIL path is taken).
- **AC7** — verified. `tests/run-tests.sh` exits 0 and prints `All checks passed (385 checks).`; `tests/run-tests.sh --self-test` exits 0 at `All checks passed (694 checks).` Both run 2026-08-27 on this branch at 0d32e09.

#### Consistency gate

- `cairn_validate.py` — exit 0, all checks passed; every advisory `OK`, the `release window` advisory did not fire.
- `cairn_impact.py` — skipped. The header names IP3; the diff changes no `IP`/`GP` principle text (`git diff origin/main..HEAD -- cairn/DESIGN.md` matches no principle line).
- Toolchain checks — the active profile is `generic`, whose `consistency-gate` slot names none. Clean no-op.

#### Independent review

Three fresh-context lenses, none having seen the implementation, each on a
distinct evidence base. Finding numbers continue round 1's.

**[S] prior-review lens — no findings.** Archived `## Review` sections on the
touched files (M40, M42, M44) were the primary surface. Round 1's own findings
were checked for regression: the AC4 rework matches round 1's diagnosis, the
four new plants cover the shapes F4 named, F5/F6/F7 are fixed as described, and
F8/F10/F11 are filed on the ROADMAP rather than dropped. The GitHub probe
(`pulls/comments?per_page=1`) returned `[]`, so the per-PR walk was not paid for.

**[S] blame-history lens — one finding (F16 below).** It re-derived the
eighteen-row disposition from `git show 9e6b567` rather than trusting the table,
grepped the tree for every deleted identifier and found no orphan reference or
stale `pass` banner, confirmed M33-AC4's `pass` text was narrowed to match the
one kept recipe claim, checked the D-026/D-027/D-028 chain for coherence, and
reproduced both round-1 escapes as closed.

**[O] diff-bug lens — five findings, ranked.** It tested twelve link shapes
against the repaired reader and found the textual escapes closed; the real
rendered site is green under base `quarto-index` (1877 links across 41 pages).

| # | Finding | Disposition |
|---|---|---|
| F12 | `git ls-files` C-quotes a non-ASCII path, and the `.qmd` suffix filter (run-tests.sh:1506) drops the quoted entry with no report, so a tracked page carrying a retired sentence is swept past at exit 0. | **Return.** Reproduced end to end. AC2 fails inside its own named domain. |
| F15 | Containment is textual: `os.path.abspath` (sitecheck.py:271) does not resolve symlinks, so a link through a symlink inside the capture reads a file outside it at exit 0. | **Return.** Reproduced. AC4 fails inside its own named domain, by a third containment mechanism. |
| F14 | `check_prerelease_absent` keeps two traceback paths of the class F7 just fixed — `check=True` on `git ls-files` (run-tests.sh:1504) and `open(source)` on the unconditionally appended `README.md` (1681), which is also never confirmed tracked though the reported domain size counts it. | For the implement phase to triage with the return. |
| F13 | The new standing output-dir pin reports nothing when it passes, so it is absent from the run log and from the `grep -cE '^ok '` check count; the suite's convention for a silent helper is a `pass` line naming it (run-tests.sh:12119-12125). | For the implement phase to triage with the return. |
| F16 | AC4's checkbox is unticked while the status is `review`. | **Rejected.** Raised by both Sonnet lenses. Not a defect: AC fencing ticks a criterion only against fresh evidence recorded here, which is this round's job. AC4 stays unticked because it fails; AC2's tick is removed for the same reason. |

Round 1's F8, F10 and F11 were confirmed still present and still correctly filed
on the ROADMAP suite-readers row; the diff lens also recorded, without filing it,
that `FLOOR = 11` against a live domain of 21 is the room F12's drop hides in.

#### Outcome

**Returned to `in-progress`.** Two criteria fail on fresh evidence. AC2: the
check's swept domain is not `git ls-files 'site/*.qmd'` plus `README.md` — a
tracked page whose name git C-quotes is dropped silently, and a retired sentence
on it passes at exit 0. AC4: `tests/sitecheck.py links` does not resolve only
against files inside the captured site — a symlink inside the capture reads a
file above it at exit 0. AC1, AC3, AC5, AC6 and AC7 hold. F13 and F14 ride with
the repair; F16 is rejected. This is the second defect return on M46, and the
second time AC4 has failed by a containment mechanism of the same shape.
