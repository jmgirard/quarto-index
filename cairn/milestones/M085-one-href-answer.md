# M085: One answer to whether a link leaves the publication

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the acceptance suite's own link readers, run over rendered in-repo fixtures
- **Branch/PR:** `m085-one-href-answer` / https://github.com/jmgirard/quarto-index/pull/85

## Goal

One definition decides whether an href leaves the publication, and the suite's
four link readers reach their verdict through it.

## Scope

**In:** a shared predicate in `tests/htmlindex.py` — strip the href, take the
part before the first `#`, and answer "leaves" for a value opening `//` or
matching an anchored RFC 3986 scheme, case-insensitively (D-057). The four
readers that decide this today route through it and their own tests are
deleted: `htmlindex.resolve_href` (`tests/htmlindex.py:869`),
`epubcheck.leaves_publication` (`tests/epubcheck.py:236-249`),
`epubindex.links`, which has no such test at all (`tests/epubindex.py:191-196`),
and `sitecheck.check_links`' two skip clauses (`tests/sitecheck.py:106-107`,
`:254-257`). Each caller keeps its own policy for a leaving link — the site
check skips it, `epubcheck.py unique` counts it as outside, `epubindex` stops
reporting it as unresolved, and `resolve_href`'s callers keep failing on it.
The agreement is evidenced by one table-driven leg and by a plant against each
reader.

**Out:** resolving a root-relative href (`/ch1.xhtml#frag`) in the EPUB and HTML
readers, and the percent-encoded `%2F%2F` shape neither guard catches (KI120) →
both stay on the rewritten "root-relative" candidate row, whose promotion
condition is a fixture or an author writing one. `sitecheck.check_links`'
root-relative branch and its containment clauses → untouched here; they stay on
the site/gallery/publishing repair row (KI119, KI153). Reading a second index
section per document → its own row (KI264).

## Acceptance criteria

- [ ] AC1: For each href shape the table `M085_HREF_SHAPES` in
      `tests/run-tests.sh` names, the four readers — `htmlindex.resolve_href`,
      `epubcheck.py unique`, `epubindex.links` and `sitecheck.py links` —
      return the same leaves-the-publication verdict, shown by one leg that
      drives every row of that table through all four readers and fails naming
      the row and the disagreeing readers wherever a row's four verdicts are
      not one verdict.
- [ ] AC2: `epubcheck.py links` no longer reports a link that leaves the
      publication as naming nothing in the publication: over the captured
      `demo.epub` repacked to carry one `https:` href and one `//` href inside
      its generated index section, the command exits 0 and its ok line states
      how many of the collected links it skipped as leaving.
- [ ] AC3: The two EPUB commands give one answer over one publication: over the
      AC2 repack, `epubcheck.py unique` and `epubcheck.py links` both exit 0,
      where today `links` fails on the same two hrefs `unique` counts as
      outside.
- [ ] AC4: `sitecheck.py links` decides a scheme it does not name: over a copy
      of the captured site carrying one `ftp://` href and one `irc:` href
      planted by `m40_plant_link`, the check exits 0 and its swept-domain line
      reports the same swept count it reports over the unplanted capture, where
      the planted page carries two hrefs more than the captured one.
- [ ] AC5: `notes:draft.xhtml#x` — a relative filename carrying a colon — reads
      as leaving the publication in each of the four readers AC1 names.
- [ ] AC6: `tests/run-tests.sh --self-test` is clean.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T6
- AC2 → T1, T4, T7, T8
- AC3 → T3, T4, T7, T8
- AC4 → T5, T7, T8
- AC5 → T1, T6
- AC6 → T9

## Tasks

- [x] T1: Write the shared predicate beside `resolve_href` in
      `tests/htmlindex.py`; its docstring states the rule, what it does not
      catch (the percent-encoded shape, KI120), and that a real relative
      filename carrying a colon reads as leaving unless written `./name:x`.
- [x] T2: Route `htmlindex.resolve_href` (`:869`) through T1; delete its
      `'://' in href or href.startswith('mailto:')` test. Callers
      (`tests/fragments.py:68-72`, `run-tests.sh:7305-7307`) keep failing on a
      leaving href.
- [x] T3: Route `epubcheck.leaves_publication` (`:236-249`) through T1 and
      delete its local `SCHEME` regex; `cmd_unique`'s skip-and-count and its
      domain line are unchanged.
- [x] T4: Give `epubindex.links` (`:191-196`) the T1 predicate, mark a leaving
      link on the row it returns, have `unresolved` (`:202-227`) skip such a
      row, and have `epubcheck.cmd_links` (`:163-193`) print the skipped count
      on its ok line.
- [x] T5: Route both skip clauses of `sitecheck.check_links`
      (`tests/sitecheck.py:254-257`) through T1 and delete `NON_LOCAL_SCHEMES`
      (`:106-107`); the root-relative branch (`:274-287`) and the containment
      clauses (`:299-314`) are not touched.
- [x] T6: Write `M085_HREF_SHAPES` and the AC1 leg — leaving shapes
      (`https://`, `//host/x`, `mailto:`, `MAILTO:`, `tel:`, `data:`, `ftp://`,
      a leading-whitespace ` mailto:`, `notes:draft.xhtml#x`) and staying
      controls (`ch1.xhtml#frag`, `#frag`, `sub/two.html#frag`,
      `/ch1.xhtml#frag`), each row's expected verdict held in one place and
      expanded at every reader's call site.
- [x] T7: Plant one leaving and one staying href against each of the four
      readers, and show each plant red against the pre-change reader before
      trusting its green — a plant per reader is not a plant per clause, so the
      `//` clause and the scheme clause are planted separately.
- [x] T8: Build the AC2/AC3 repack rows through M083's `plant.py` and the AC4
      `m40_plant_link` rows.
- [x] T9: Strike KI98, correct KI120's sentence naming `leaves_publication`'s
      docstring enumeration to name where it now lives and KI266's clause on
      the four readers' separate answers, rewrite the root-relative candidate
      row, and run `--self-test`.

## Work log

- 2026-09-10: created by /milestone-plan.
- 2026-09-10: criteria audit ran in reduced mode (internal tier); three findings, all on the draft AC5 — an unbounded "everywhere", a promise disproportionate to the tier by the same wording, and two instrument-bound clauses (a table row's membership, the predicate's docstring wording); repaired at the gate to the four named readers' verdict, docstring moved to T1.
- 2026-09-10: plan gate chose one scheme-shaped test over the site checker's named scheme list because a named list makes every unlisted scheme a false report, which is the defect in hand; falsified by a real fixture filename carrying a colon that authors will not write as `./name:x`.
- 2026-09-10: plan gate chose `tests/htmlindex.py` as the predicate's home over a new `tests/hrefs.py` because three of the four readers already import it; falsified by a second non-HTML reader needing the predicate without wanting the HTML parser.
- 2026-09-10: plan gate chose replacing the four tests without adding a report over also resolving a root-relative href, because the scope hardens checkers this repo already shipped and the deleting option is the one that rule recommends; falsified by an author or a fixture writing a root-relative index locator.
- 2026-09-10: implementation gate chose a named entry per reader over one shared call plus a wiring assertion, so the AC1 leg reads each reader at its own call site; falsified by a reader whose own name shows nothing a shared call could not.
- 2026-09-10: implementation gate chose running the AC2/AC3 EPUB legs on every run over confining them to `--self-test`, so M083's repack machinery is hoisted out of that self-test block.
- 2026-09-10: implementation gate chose a recorded one-time red against the pre-change reader over standing revert legs, the pre-change reader not existing after this branch.
- 2026-09-10: amendment gate replaced AC4's swept-count arithmetic with a before/after comparison against the unplanted capture: the check reports one swept total per captured directory, which no per-page href count can be two lower than. No criterion added, and none widened.
- 2026-09-10: re-audit: AC4 (reduced) — nothing.
- 2026-09-10: amendment gate replaced AC2's publication: `epubcheck.py links` cannot read `id-collision.epub` at all — that fixture's element claiming the index-section id carries no heading, and the prefix-based section reader raises on it — so the criterion names the captured `demo.epub`, which both EPUB commands pass over today. AC3 inherits it with no wording change. No criterion added, and none widened.
- 2026-09-10: re-audit: AC2 (reduced) — nothing.
- 2026-09-10: T9 narrowed to strike KI98 alone; KI266 stands, M085's Scope Out leaving a root-relative href where it found it, and T9 corrects its wording instead.
- 2026-09-10: T1: `htmlindex.leaves_publication` states the rule, the percent-encoded shape it does not catch, and the `./name:x` form for a relative filename carrying a colon; every claim in its docstring was read off a run of the predicate over the shapes it names.
- 2026-09-10: T2: `resolve_href` answers from the shared test, and its own `'://' in href or mailto:` test is gone. Suite green.
- 2026-09-10: T1 and T2 landed in one commit, each verified by its own clean suite run before it was ticked.
- 2026-09-10: T3: `epubcheck.leaves_publication` is a name over the shared test; its local `SCHEME` regex and the module's `import re` are gone, and `cmd_unique` now hands it the whole href rather than the part it had already cut. Suite green.
- 2026-09-10: T4 code landed (checkpoint, unticked): `epubindex.links` marks a leaving row and computes no member name for it, `unresolved` skips such a row, and `epubcheck.cmd_links` prints the skipped count and refuses a publication all of whose index links leave. Its verify run was still in flight at this commit.
- 2026-09-10: T4 verify run clean, so T4 is ticked. `epubcheck.py links` over the captured demo publication reads `all 25 of 25 link(s) … 0 link(s) skipped as leaving the publication`.
- 2026-09-10: T5: `sitecheck.leaves_publication` is a name over the shared test, `NON_LOCAL_SCHEMES` is gone, and the two skip clauses are one. The module imports `htmlindex` — the first non-HTML-parsing reader to, which is the falsifier the plan gate named for that home. The root-relative branch and the containment clauses are untouched. Suite green.
- 2026-09-10: T6/T7/T8 code landed (checkpoint, unticked): the M085 section carries `M085_HREF_SHAPES`, the four-reader agreement leg and the AC2/AC3 repack legs, and it sits after the M52 EPUB checks whose demo capture it reads; M083's repack script and a shared locator reader are hoisted out of that milestone's self-test block; the plants are four EPUB repacks, four HTML-page plants and three site-capture plants. Its `--self-test` run was still in flight at this commit.
- 2026-09-10: T7 pre-change reds recorded, each run against the readers as `main` carries them. `epubcheck.py links` over the two-leaving-locator repack: `FAIL: 2 of 25 link(s) … name nothing in the publication`, naming `EPUB/text/https:/example.invalid/…` and `//example.invalid/…` as manifest items; `unique` over the same file: green, counting the same two as leaving — the disagreement AC3 is about. `sitecheck.py links` over the `ftp:`/`irc:` plant: `FAIL: 2 of 2026 link(s) … looked for ftp:/example.invalid/syntax.html`; over the staying plant: green at 2025 swept. `fragments.py resolve` over the `tel:` plant: GREEN, the locator counted and never judged; over the `//` plant: red as `//example.invalid/seven.html is no page of the capture`, not as leaving; over the `https:` plant: red as leaving; over the `./` plant: green.
- 2026-09-10: T9 record edits landed (checkpoint, unticked): KI98 struck, KI120 and KI266 corrected in place, the root-relative candidate row rewritten, and KI267 added for `epubcheck.py links` being unable to read `id-collision.epub` at all. Still owed on T9: two `epubindex.py` docstrings still cite KI98, and `--self-test` has to run over the finished tree.
- 2026-09-10: T9 finished: two `epubindex.py` docstrings stopped citing the struck KI98 and name the closed report instead. `tests/run-tests.sh --self-test` clean — 1451 checks.
- 2026-09-10: the AC1 leg shown able to fail: over a scratch copy whose `sitecheck.leaves_publication` is reverted to the old six-scheme list, it goes red naming both rows and the reader that parted — `'ftp://example.invalid/ch1.xhtml': the readers part — … sitecheck.leaves_publication says stays`.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: T6-T9 ticked, `cairn_validate` all-pass, status to review.
- 2026-09-10: review opened. `main` had not moved under the branch (0 behind, 9 ahead), so nothing was merged in; draft PR #85 opened and recorded in the header. Consistency gate first half clean — `cairn_validate` all-pass, every advisory OK, `release window` unfired; no principle changed, so `cairn_impact` was skipped; the `generic` profile names no toolchain checks. Criterion evidence run (`--self-test`) and the three review lenses were still in flight at this commit.

## Decisions

## Review
