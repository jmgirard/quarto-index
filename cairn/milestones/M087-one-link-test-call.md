# M087: The link readers call the one link test and use the href it judged

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the acceptance suite's own link readers and their legs, run over rendered in-repo fixtures
- **Branch/PR:** m087-one-link-test-call

## Goal

What each link reader does with an href follows from the one verdict
`htmlindex.leaves_publication` gave that same href, with each of the EPUB
commands' all-links-leave refusals shown able to fire.

## Scope

**In:** the gaps M085's review left in its link-reader legs (F2, F3, F4) and
KI269. The three per-module `leaves_publication` names M085 kept so its
agreement leg could read each reader "at its own call site" are deleted, and
their call sites call `htmlindex.leaves_publication` directly: F2 showed that
name cannot see a change made after its call, so the leg reading it certified
agreement it could not observe. The agreement leg becomes a table test of the
one predicate; what the commands then do with a leaving link stays held by
M085's command-level EPUB and site legs. `resolve_href`, `epubindex.links` and
`epubcheck.cmd_unique` partition the href stripped, as the predicate judges it
(KI269). The two all-links-leave refusals in `epubcheck.py links` and
`epubcheck.py unique` get a plant (F4). `m085_epub_plant` takes one expected
count per command, because the two commands count over different domains (F3).

**Out:** driving every table shape through each command, and naming the hrefs
each EPUB command skipped as leaving → declined at this plan gate (work log);
KI268 stays in `DESIGN.md` Known issues, decided by D-057. A pin on the site
sweep across the broadened skip (M085 review F5) → dropped at this plan gate
(work log). Whitespace shapes other than a leading space (trailing, tab,
newline) → the strip covers them, no criterion promises them. A root-relative
or percent-encoded href → its candidate row (KI120, KI266). A second index
section per document → its row (KI264). `epubcheck.py links` over
`id-collision.epub` → Known issues (KI267).

## Acceptance criteria

- [ ] AC1: `tests/htmlindex.py` is the only tracked module under `tests/`
      carrying a top-level `def leaves_publication`:
      `git grep -n '^def leaves_publication' -- 'tests/*.py'` prints exactly
      one line, and it names `tests/htmlindex.py`.
- [ ] AC2: For each row of `M085_HREF_SHAPES` in `tests/run-tests.sh`,
      `htmlindex.leaves_publication` returns the row's verdict.
- [ ] AC3: `htmlindex.resolve_href('index.html', ' ch1.xhtml#frag')` returns
      `('ch1.xhtml', 'frag')`; and over a copy of the captured `demo.epub` in
      which one of its index locators is given a leading space,
      `epubcheck.py links` and `epubcheck.py unique` each exit 0 with no link
      counted as leaving the publication.
- [ ] AC4: Over a copy of the captured `demo.epub` in which every href inside
      a generated index section is prefixed with `https://example.invalid/`,
      the rest of the href, its `#fragment` included, kept after the prefix,
      `epubcheck.py links` and `epubcheck.py unique` each exit 1 with the
      refusal it prints when every such link leaves the publication, and
      neither prints any other failure.

## Coverage

- AC1 → T1, T6
- AC2 → T2, T6
- AC3 → T3, T6
- AC4 → T5, T6

## Tasks

- [ ] T1: Delete `leaves_publication` from `tests/epubcheck.py` (`:251-262`),
      `tests/epubindex.py` (`:166-176`) and `tests/sitecheck.py`
      (`:110-121`); their callers (`epubcheck.py:322`, `epubindex.py:212`,
      `sitecheck.py:270`) call `htmlindex.leaves_publication`. Rewrite the
      docstrings naming the deleted names — `htmlindex.py:871-873`,
      `sitecheck.py:17`, and `links`/`unresolved` in `epubindex.py` where they
      cite them. Run the readers under the oldest and newest Python in reach
      (LESSONS M082).
- [ ] T2: Rewrite the M085 AC1 leg (`tests/run-tests.sh:23915-24036`) to drive
      every `M085_HREF_SHAPES` row through `htmlindex.leaves_publication`
      alone, failing and naming each row whose verdict it does not return; keep
      its row-shape guard and its both-verdicts guard; rewrite the section
      header comment, which argues for the four-reader reading being removed.
- [ ] T3: Strip the href before partitioning it in `resolve_href`
      (`htmlindex.py:913`), `epubindex.links` (`:213`) and `cmd_unique`
      (`epubcheck.py:319`); the row `links` returns keeps `href` as written.
      Add the AC3 leg beside M085's EPUB legs (a `resolve_href` assertion and a
      leading-space repack through `$M083W/plant.py`, read by both commands'
      printed counts), recording it red against the unstripped readers first.
      Strike KI269.
- [ ] T4: `m085_epub_plant` (`tests/run-tests.sh:24089`) takes the expected
      `links` skipped count and the expected `unique` leaving count as two
      arguments, and its four calls pass both.
- [ ] T5: Build the AC4 copy — `plant.py` refuses a pattern matching more than
      once, so either chain one plant per locator (`$M083W/locators.py` lists
      them) or give `plant.py` an every-match mode that still refuses a pattern
      matching nothing — and assert each command's own refusal text, not exit
      status alone. Record each assertion red against a scratch copy of its
      command with that refusal removed.
- [ ] T6: Run `tests/run-tests.sh --self-test` clean over the finished tree.

## Work log

- 2026-09-10: created by /milestone-plan.
- 2026-09-10: criteria audit ran in reduced mode (internal tier); four findings, all fixed at the gate: AC1 named "defines" where its grep finds only a top-level `def`, narrowed; AC2 described its leg's failure message (instrument), the leg moved to T2; AC3's general whitespace sentence swept more than its two named cases, narrowed to them; a drafted AC5 (`--self-test` clean) bound the harness, moved to T6. Outside the three questions the reader noted AC4 needed the fragment kept, or `unique` refuses on its no-fragment branch instead; reworded.
- 2026-09-10: plan gate chose deleting the three per-module `leaves_publication` names and reading `M085_HREF_SHAPES` through the one predicate over keeping the names and driving every shape through each command, because the scope repairs checks M085 shipped and the per-reader name cannot see a change made after its call (F2) — this reverses M085's implementation-gate choice of a named entry per reader, whose stated falsifier F2 is; falsified by a reader regaining a link test of its own that M085's command-level EPUB and site plants do not reach.
- 2026-09-10: plan gate dropped M085 review F5 (no leg pins the site sweep across the broadened skip): the old and new rule swept the same count at merge (2025 over the staying plant, M085 T7 and review AC4), and a standing leg would have to restate the six-scheme list D-057 declined.

## Decisions

## Review
