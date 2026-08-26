# M40: The documentation moves into a Quarto website

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, IP3
- **Branch/PR:** m040-docs-website · https://github.com/jmgirard/quarto-index/pull/40

## Goal

A `site/` Quarto website becomes the documentation's home, README shrinks to a
pointer, and every claim the acceptance suite pins moves with the prose.

## Scope

Surface tier: **user-facing** — the site is the extension's discovery surface,
which GP1 holds to extension-listing quality.

**In:** a `site/` Quarto website project (`_quarto.yml`, navigation,
`site/_extensions` → `../_extensions`, `site/_site` as output dir); README's 17
`## `/`### ` headings other than `## Install`, `## Examples` and `## Tests`
moved into site pages with their prose intact; README rewritten to pitch,
install, pre-release warning and a link to the docs; a **claim-container
registry** in `tests/run-tests.sh` that the suite iterates, so the 16 existing
`README_*` containers plus `SUPPORTED_FORMS` are enumerated by a procedure
rather than by hand, each repointed at the site file or files that now hold it
and each tagged presence or absence; and a link check over the rendered site.

The site uses Quarto's default output naming — no `output-file:` overrides —
and partials are `_`-prefixed, so a source path determines its output path.

**Out:** the rendered-example gallery → M41. The Actions/Pages workflow and the
published URL in README → M42. The Quarto floor/latest CI matrix and KI79 →
the standing candidate row, which M42 amends with a pointer; pinning one Quarto
version does not fence the floor and must not read as closing KI79.

## Acceptance criteria

- [x] AC1. `quarto render site` from a clean checkout exits 0, and for every
      tracked path under `site/` ending in `.qmd` whose basename does not begin
      with `_` (enumerated by `git ls-files site`), the file at the same
      relative path with `.html` for `.qmd` exists under `site/_site/`.
- [x] AC2. Every link the rendered site makes to its own content resolves. For
      each `href` value in each `.html` under `site/_site/`, excluding `<use>`
      hrefs and values whose scheme is `http:`, `https:`, `mailto:`, `tel:`,
      `data:` or `javascript:`: where the value has a path part, that path
      exists under `site/_site/` after the site's configured base path is
      stripped; where it carries a `#fragment`, an element with that `id`
      exists in the file it names, or in the containing page when the value has
      no path part.
- [x] AC3. No documentation prose is lost: for every line
      `git diff <merge-base>..HEAD -- README.md` reports removed, every run of
      four or more ASCII alphanumerics on that line, lowercased, appears in the
      concatenated lowercased text of the tracked files under `site/` at HEAD.
- [x] AC4. Every line matching `^#{2,3} ` in the merge-base README.md other
      than `## Install`, `## Examples` and `## Tests` (17 lines) is absent from
      README.md at HEAD, and for each, a tracked file under `site/` carries a
      heading whose text — the line with its leading `#` run and following
      spaces removed — is identical.
- [x] AC5. README.md at HEAD is under 120 lines and contains the pre-release
      warning paragraph, the `quarto add jmgirard/quarto-index` line, and a
      relative link to `site/index.qmd` that resolves in the repo.
- [x] AC6. Every entry of every presence claim container in
      `tests/run-tests.sh` — `SUPPORTED_FORMS` and the 16 `README_*`
      containers its source defines, 17 in all, of which the claim-container
      registry tags 14 presence and 3 absence — appears, compared with runs of
      whitespace flattened to one space, in the flattened text of some tracked
      `.qmd` file under `site/`.
- [x] AC7. Every entry in every absence container the registry lists —
      `README_STALE` (:318), `README_REFS_STALE` (:500) and
      `README_MISUSE_STALE` (:1860) — appears in no tracked file under `site/`
      and not in README.md.
- [x] AC8. `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T6
- AC2 → T6, T7
- AC3 → T2, T4, T7
- AC4 → T2, T3, T6, T7
- AC5 → T3, T6, T7
- AC6 → T2, T5, T7
- AC7 → T3, T5, T7
- AC8 → T1, T4, T5, T6, T7, T8

## Tasks

- [x] T1. Create the `site/` project: `_quarto.yml` (website, `output-dir:
      _site`, navigation), `site/index.qmd`, the `site/_extensions` symlink,
      and `site/_site/` + `site/.quarto/` in `.gitignore`.
- [x] T2. Move the 17 headings and their prose from README.md into site pages,
      one page per `## ` section with its `### ` subsections intact, keeping
      every pinned sentence byte-identical to what the suite compares today.
- [x] T3. Rewrite README.md: pitch, `## Install`, the pre-release warning, the
      docs link, and short `## Examples` / `## Tests` pointers.
- [x] T4. Write the prose-move bound of AC3 (the M27 four-character-word rule
      in `cairn/check-design.md`), stating its normalization in the check.
- [x] T5. Add the claim-container registry to `tests/run-tests.sh`: every
      `README_*` container and `SUPPORTED_FORMS`, each tagged presence or
      absence and each naming the file it is compared against; add a check that
      the registry names every such container the file defines, so the domain
      cannot half-empty (`check-design.md`, M16); repoint each at its site file.
- [x] T6. Write the render and link-resolution checks (AC1, AC2, AC4, AC5),
      capturing the render and reading the capture (M24; note `suitescan.py`'s
      `pairs` rule binds any `quarto render` line the suite adds).
- [x] T7. Plant a defect per clause of each new check and record each red
      (`check-design.md`, M32 — a plant per clause, not per reader): a dangling
      relative href, a dangling fragment, a root-relative href under the base
      path, an unrendered `.qmd`, a moved heading whose text drifted, a claim
      sentence deleted from its site file, an absence sentence copied into one,
      a registry missing a container, a presence container mis-tagged absence,
      and a README line whose words reach no site file.
- [x] T8. DESIGN.md: record the docs-home split in Architecture; amend any
      Known-issue the move closes. Verify slot clean.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: [O] criteria audit ran twice, full mode both times (user-facing tier). Round 1 returned findings on all ten drafted criteria across the then-two milestones; round 2, after the question gate re-cut them, returned findings on every criterion but the verify-slot ones. Both rounds' findings were disposed here — none deferred, none silent.
- 2026-08-26: plan gate chose moving the prose into the site over generating the site's docs pages from README.md at build time; the user picked site-primary at the question gate for site structure, against the recommendation, accepting the repoint of 16 claim containers. Falsified by evidence that the pinned-claim discipline cannot survive the move — a claim set with no site file that can hold it verbatim.
- 2026-08-26: plan gate chose the claim-container registry over the criterion naming its containers by hand; the audit showed a hand list already wrong (13 named against 16 defined, `README_STALE` counted as a presence set, `SUPPORTED_FORMS` double-counted). Falsified by a container the registry omits that its own completeness check does not catch.
- 2026-08-26: plan gate kept the criteria bound to the site and left "the suite enforces it" in the tasks, over stating enforcement as a criterion; the audit's cross-cutting finding that the site can rot post-merge with the suite green is real, and the answer is T5-T7, not an instrument-bound promise. Falsified by a post-merge site regression no suite check reaches.
- 2026-08-26: sizing tripwire split this from the two milestones the user chose into three; the docs migration plus the claim repoint is a milestone on its own once the prose moves rather than being generated.

- 2026-08-26: T1 done: `site/` Quarto website project (navbar + docked sidebar, `output-dir: _site`), the `site/_extensions` symlink, and `site/_site/` + `site/.quarto/` ignored. Verify slot green (381 checks).
- 2026-08-26: question gate chose one page per README topic (18 pages) over one page per `## ` section, and navbar-plus-sidebar navigation; T2's one-page-per-`## `-section wording is superseded by the finer split, which no criterion binds.

- 2026-08-26: T2 and T3 landed as one checkpoint, boxes left unticked: the prose is in `site/` (18 pages) and README is 57 lines, so the suite's 17 claim containers still read README.md and the verify slot is red until T5 repoints them.

- 2026-08-26: amendment gate — AC6 replaced and Scope's "the site file" widened to "the site file or files". AC6 as planned was unsatisfiable: `::: {.qi-index-here}` is documented on both the placing-the-index and books pages, as README documented it twice, and six presence containers span two or more pages. Two fresh-context [O] criteria audits ran in full mode (user-facing tier), one on the first replacement draft and one on the wording written; the first killed a draft that defined the promise by reference to the suite's own checks — two of which bound their search by a `### ` heading the move removes — and let the registry pick its own domain. Findings disposed here, none deferred. The user chose the replacement at the gate.
- 2026-08-26: amendment gate — the recipe's home moves to the site and IP2's non-ASCII condition names it there; D-023 records it, IP2 and KI6 corrected in place and marked. Chosen by the user at the gate (RB tripwire: ip-touching, escalation offered and declined).
- 2026-08-26: T7 gains one plant, a presence container mis-tagged absence, so AC6's domain cannot shrink by re-tagging.

- 2026-08-26: T5 done, and T2/T3 tick with it: `CLAIM_CONTAINERS` in `tests/run-tests.sh` names all 17 containers, 14 presence and 3 absence, each presence row naming the site page or pages that hold it and each absence row `ALL` (every tracked page under `site/` plus README). `claim_text` concatenates a row's pages and every claim check reads that instead of README.md; the three section-anchored checks take their heading as a parameter and bound the section outside fenced blocks, which a bare regex got wrong on a `# References` line inside a copyable block. Registry completeness is compared against a scan of the suite's own source reading both the array and here-document definition shapes. Verify slot green: 382 checks, 564 with `--self-test`.

- 2026-08-26: T4 and T6 done: `tests/sitecheck.py` carries five modes — `rendered`, `links`, `headings`, `readme`, `prose` — each reporting the size of the domain it swept. `prose` states its normalization where the M27 four-character-word rule is applied and nowhere else. `capture` grew a `--site` mode so the website render is captured whole, as a book's `_book` is.
- 2026-08-26: task refinement — the suite runs `rendered`, `links` and `readme` as standing checks; `headings` and `prose` compare the pre-move README against the site, which is a one-time fact about the migration, so they are run against the merge base for AC3/AC4 evidence rather than wired into a suite where their domain would be empty forever (M16). No criterion changes: AC3 and AC4 name a comparison, not an instrument. Verify slot green: 385 checks.

- 2026-08-26: T7 done: 27 planted cases, one per clause of the five site checks, the registry check and the claim-set check, each required to fail AND to name its own clause; plus one positive control, the root-relative href that resolves once the base path it is written under is given. The heading and prose plants use an overlay (suitescan's handle) so the defect enters a tracked set without editing the repo, and the pre-move README is stated in the self-test rather than read from git, since the merge base stops carrying it once M40 ships. Self-test green: 595 checks.

- 2026-08-26: T8 done: DESIGN's Architecture records the docs home, the claim-container registry and the site checks; GP1's discovery surface now names the site; KI61, KI73 and KI78 corrected in place and marked for what the move changed. Pre-review check green: 595 checks under `--self-test`.

- 2026-08-26: all tasks done, status review. Every criterion re-derived on the branch: AC1/AC2 from a clean clone of the branch (20 pages rendered, 752 local links resolve), AC3 (5046 words on 755 dropped lines all reach a site page) and AC4 (17 headings) against the merge base, AC5 (README 57 lines), AC6 (17 containers, 14 presence, all 164 entries land) and AC7 from the suite, AC8 `--self-test` 595 checks.

- 2026-08-26: sizing tripwire also flags 8 acceptance criteria (>7). Not split: AC6 (presence containers) and AC7 (absence containers) are two domains with opposite promises, and the claim repoint cannot land in a later milestone than the prose move without leaving the suite red in between.

- 2026-08-26: review evidence recorded for AC1-AC8, all eight verified fresh on the branch; consistency gate clean. Findings triage pending the [O] diff lens, which died to an API error on its first spawn and is on its second.

- 2026-08-26: an AC3-AC8 evidence write missed its anchor and left six ticks unbacked for one commit; the Review section was rewritten whole and re-verified before this line.

## Decisions

## Review

Fresh evidence, 2026-08-26, on `m040-docs-website` at 10994af with `main`
unmoved (0 commits behind). PR #40.

### Acceptance criteria

- AC1 — pass. Clean clone of the branch into a scratch dir, `quarto render
  site` exit 0, 20 of 20 pages written. `sitecheck.py rendered site
  site/_site` ok over a 20-page domain; the same 20 paths re-derived by hand
  from `git ls-files site` each have their `.html` at the matching relative
  path.
- AC2 — pass. `sitecheck.py links site/_site` over the same clean-clone
  render: all 752 same-site links across the 20 pages resolve, path part and
  `#fragment` alike. An independent href census counted the same 752 in-site
  `href` values (plus 20 external, 0 `<use>`), so the check's domain is the
  whole domain. Re-derived a second time with a resolver written here, confined
  to `site/_site` and percent-decoding both path and fragment — 752 links, 0
  violations — so this evidence does not rest on the resolver F8-F11 attack.
  The site declares no base path, so that clause is exercised by T7's plant.
- AC3 — pass. `sitecheck.py prose` reports 5046 four-or-more-character words
  over the 755 lines it sees dropped, all reaching a site page. Re-derived
  against the criterion's own wording — the 921 lines
  `git diff 2afade7..HEAD -- README.md` reports removed, 942 distinct
  lowercased `[A-Za-z0-9]{4,}` runs — 0 missing from the concatenated text of
  the 20 tracked `site/` files at HEAD.
- AC4 — pass. `sitecheck.py headings` ok over 17 headings and 20 pages.
  Re-derived independently: the merge-base README carries 17 `^#{2,3} `
  headings other than the three kept; none of the 17 lines survives in
  README.md at HEAD, and each one's heading text matches a heading, at some
  level, in a tracked `site/` file.
- AC5 — pass. `sitecheck.py readme README.md site/index.qmd` ok: README.md is
  57 lines (< 120), carries the pre-release warning paragraph (:7), the
  `quarto add jmgirard/quarto-index` line (:15) and a relative link to
  `site/index.qmd` (:33) whose target exists in the repo.
- AC6 — pass. Independent extraction of the containers from
  `tests/run-tests.sh` at HEAD, not through the suite's own helpers: 17
  containers, 16 `README_*` plus `SUPPORTED_FORMS`, tagged 14 presence and 3
  absence, matching the criterion's counts. The 14 presence containers hold 168
  entries; every one, compared whitespace-flattened, appears in the flattened
  text of a tracked `.qmd` under `site/` — 0 missing. The reading of "entry" is
  recorded as F17 below rather than settled silently.
- AC7 — pass. The 3 absence containers hold 16 entries (`README_STALE` 8,
  `README_REFS_STALE` 1, `README_MISUSE_STALE` 7). Swept over all 24 files the
  criterion names — every tracked file under `site/` plus README.md — under
  both readings of an entry: 0 occurrences. The `(:318)`, `(:500)`, `(:1860)`
  locators are merge-base line numbers, correct at 2afade7; the containers they
  name are `tests/run-tests.sh:336`, `:518` and `:2038` at HEAD.
- AC8 — pass. `tests/run-tests.sh --self-test` exit 0, 595 checks, run fresh
  on the branch at 10994af.

No `Driving RR:` is declared, so there are no carried projections to set
against measured outcomes.

### Consistency gate

- `cairn_validate.py` exit 0: every check PASS. One advisory — 8 acceptance
  criteria against the 7 tripwire — already dispositioned in the work log (AC6
  and AC7 are opposite promises over two domains, and the claim repoint cannot
  land later than the prose move without leaving the suite red in between).
  `release window` did not fire.
- `cairn_impact.py --changed` reports no changed principles: the diff's edits
  to IP2 and GP1 fall on continuation lines carrying no principle id, which is
  what the detector scans. Run by hand for the two ids instead — IP2 25
  references, GP1 8. The live references reconcile; the archived ones are
  history under IP4. One divergence found, filed as F2.
- Toolchain `consistency-gate` slot: the `generic` profile names no toolchain
  checks, so this half is a clean no-op.

### Findings

Three fresh-context lenses ran (user-facing tier, executable surface touched).
[S] prior-review record: no prior-review evidence — the archives hold no
`## Review` finding on the touched files that this diff reintroduces, and the
GitHub inline-comment probe came back empty; zero findings. [S] blame-history:
one finding (F2 below, found independently here as well). [O] diff-bug: 28
findings, listed below with the two the orchestrator had already found folded
in. The [O] lens died to an API error on its first spawn and was re-run whole.

Ranked most severe first. Disposition after each.

**F1-F5. Five "above"/"below" cross-references are false after the move.**
`site/latex-and-pdf.qmd:14` ("see *Placing the index*, above" — a separate
page, in a different sidebar section); `:20` ("described under the principal
mention, below" — a separate page, and it precedes this one);
`site/back-end-differences.qmd:11` ("The three-level ceiling described above" —
now on `sub-entry-levels.qmd`); `:30` ("The `see also` limitation described
above" — now on `cross-references.qmd`); `site/cross-references.qmd:8` ("any of
the mark forms above" — the ten-form table is on `syntax.qmd`). A reader
landing on any of these pages from the sidebar is sent to prose the page does
not carry. No criterion reaches them: AC3 is an order-insensitive word bag, AC4
is headings, AC6 is claim sentences, and none of the five is pinned claim text.

**F2. Four comments still locate the Terms-outside-Latin-1 recipe in README.**
`tests/run-tests.sh:780`, `:787`, `:4752`, `:4916`. D-023 moved the recipe's
home to `site/terms-outside-latin-1.qmd`, and IP2, KI6 and the M32 pass message
were repointed; these four were not. `:780`'s comment reasons explicitly about
"a README edit that changed the engine word", which now names the wrong file.

**F3. A presence container's registry domain is unread for 3 of 14 rows.**
`README_RECIPE_LINES`, `README_INDEXES_CLAIMS` and `README_INDEXES_YAML` are
consumed by `check_recipe_block` and `check_readme_indexes`, which take their
page as a literal argument (`tests/run-tests.sh:5082`, `:13037`) rather than
through `claim_text`. Repointing those three rows at any existing file leaves
the suite green, so T5's repoint is nominal for them — and DESIGN.md's new
Architecture paragraph says "no check names a documentation file itself",
which those two call sites and `sitecheck.py readme` contradict.

**F4. An absence row's `ALL` domain is not pinned.** `tests/run-tests.sh:638`,
`:1819`. Editing `README_STALE`'s domain from `ALL` to one page leaves
`check_claim_registry` green (names, kinds and the 17/14/3 counts are
unchanged) and shrinks AC7's sweep from 24 files to 1, so a retired sentence
re-added to another page would go unseen.

**F5. The `kind` field is pinned only by its counts.** `claim_kind`
(`tests/run-tests.sh:670`) is defined and never called; swapping two rows'
tags holds the 14/3 counts, changes no check's behavior, and leaves the
registry misdescribing both containers. T7's mis-tag plant does not reach it.

**F6. The completeness scan's domain is a README-era name pattern.**
`tests/run-tests.sh:1834`. It scans for `^(README_[A-Z_]+|SUPPORTED_FORMS)=\(`
and the here-document shape. A container named for its site page
(`SITE_BOOKS_CLAIMS=(`), or any name carrying a digit, is invisible to both the
registry and the check meant to stop exactly that — which is the falsification
condition M40's own work log states for this decision.

**F7. `fail` inside `$(claim_text …)` exits only the subshell.**
`tests/run-tests.sh:660-698`. A bad domain yields an empty filename and the run
dies later on a Python traceback attributed to the consuming check rather than
on `claim_text`'s message naming the missing file.

**F8-F11. Link-check clauses weaker than AC2 or unexercised.**
`sitecheck.py` resolves a root-relative href not under the configured base path
against the capture root (so it passes where production 404s); does not confine
resolution to the capture, letting `../_quarto.yml` resolve against the working
tree; keeps a query string in the filename and never percent-decodes a path;
and unquotes a fragment's HTML entities but not its percent-encoding. All four
are latent on today's render — re-verified independently here with a resolver
confined to `site/_site` and URL-decoding both parts: 752 links, 0 violations.

**F12-F14. Clauses with no planted case.** The `<use>` exclusion and the
`mailto:`/`tel:`/`data:`/`javascript:` schemes are never planted and the render
carries no `<use>` element, so deleting either clause turns nothing red;
relative resolution from a nested page is unexercised because the site is flat
and every link plant splices into the capture root's `index.html`.

**F15. The standing render check does not clean its output directory.**
`tests/run-tests.sh:13171`. Quarto does not prune deleted pages, so a renamed
`.qmd` leaves a stale `.html`, which `rendered` (source→output only) and
`links` both accept. AC1's "from a clean checkout" is met by the evidence run
above, not by the suite.

**F16. AC5's "warning paragraph" is checked as one sentence.** `sitecheck.py`
tests the substring `**Pre-release: install at your own risk.**`; the rest of
the paragraph could be deleted green.

**F17. "Entry" in AC6 has two readings.** A container row is
`<label><TAB><pinned sentence>`. Read as the pinned sentence — what the
registry's normative comment and every claim check mean — 168 of 168 land.
Read as the whole row, 155 would be absent, since the labels are
failure-message identifiers that were never documentation prose. Recorded here
rather than settled silently.

**F18-F23. Lower-confidence and latent.** `for f in $(git ls-files
'site/*.qmd')` word-splits a path containing a space; `claim_text` joins pages
with one newline, so a claim could in principle be satisfied across a page
boundary; `check_recipe_block` compares its container as exact ordered lines
where AC6 describes whitespace flattening (stricter, not weaker); `page.index`
anchors are substring searches, so `# X` matches inside `## X`; `section_end`
stops at the first `#`-`###` heading, so adding a `##` to an anchored page
truncates its section (loudly, but for the wrong reason); `section_end` is
transcribed verbatim in three here-documents; `sitecheck.py`'s `swept` counter
increments on a bare `#` that checks nothing; site pages name `examples/` and
`tests/` paths that exist only in a source checkout (pre-existing, and M42's
audience question); every `open()` in `sitecheck.py` is unclosed.

**Not findings.** The [O] lens checked and found correct: `_quarto.yml`
navigation covers all 20 tracked pages with no dangling entry; every markdown
link between site pages targets an existing `.qmd`; the 17 heading texts in the
self-test's stub old-README match the site's H1s; `capture --site`'s
slug-collision and empty-`_site` guards; the `ALL` domain's `n >= 2` guard; and
the `set -euo pipefail` interactions in `m40_planted`.

**Return floor.** No finding demonstrates an acceptance criterion failing.
AC2 and AC6-AC7 were re-derived here independently of the instruments F8-F11
and F3-F6 attack, and AC1 and AC8 from a clean clone and a full suite run, so
the evidence above does not rest on the checks these findings weaken.
