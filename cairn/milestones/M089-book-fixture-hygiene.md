# M089: Two book-fixture hygiene gaps close

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — a root ignore rule and one acceptance-suite helper; no consumer of the extension relies on either
- **Branch/PR:** m089-book-fixture-hygiene

## Goal

Close the two suite-hygiene gaps the HTML book fixtures leave open: pages a render writes beside a book project, which a commit can sweep in, and a single-chapter leg that renders over whatever `_book` its copy holds.

## Scope

**In:** `.gitignore` rules for `*.html` and `site_libs/` directly inside every `examples/book*/` project, where an M073 suite run wrote them beside `examples/book-placement/` rather than under its `_book/` and a checkpoint commit (7c83a21, reset before it stood) swept in 22 such files; `m069_cold_chapter` removing its copy's `_book` before it renders, as `m069_tree` does (KI231).

**Out:**
- Finding which run wrote those pages beside the project: not pursued (plan gate); once ignored, a repeat harms nothing and nothing reads the pages.
- `examples/.gitignore` duplicating the root rules: stays KI75.
- Other suite-hygiene and m069-leg work: their own candidate rows (suite-run shape follow-ups; the m061/m063/m065 unasserted locators).

## Acceptance criteria

- [x] AC1: The root `.gitignore` ignores each of the 22 paths under `examples/` that `refs/probes/m073-swept` records: `git check-ignore --no-index --non-matching -v` over the paths `git show --name-only --format= refs/probes/m073-swept -- examples` lists prints one line per path and no line opening `::`, the marker for a path no rule ignores.
- [x] AC2: The ignore rules hide no tracked file: `git ls-files -ci --exclude-standard` prints nothing.
- [x] AC3: `m069_cold_chapter` in `tests/run-tests.sh` removes its copy's `_book` before the `quarto render` it runs, as `m069_tree` removes its own.
- [x] AC4: `tests/run-tests.sh` exits 0 on the branch head.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3

## Tasks

- [x] T1: In the root `.gitignore`, beside the `examples/book*/_book/` rules, add `examples/book*/*.html` and `examples/book*/site_libs/` under a comment naming what they hold (pages and assets a render wrote beside the project rather than under `_book/`, as the reset M073 checkpoint 7c83a21 carried). Run AC1's and AC2's commands.
- [x] T2: Before editing, run one control on a scratch copy of `examples/book-placement` outside the suite (extension installed as `m063_tree` installs it): a whole-book HTML render, then one chapter rendered with `_book` kept, listing `_book/*.html` to show whether the other chapters' pages survive; one work-log line. Then in `m069_cold_chapter` (`tests/run-tests.sh:10760`) remove `"$M061W/$slug/_book"` with the store, as `m069_tree` does (`:10796`), keeping the function's comment true. Mark KI231 resolved in `cairn/DESIGN.md`.
- [x] T3: Run `tests/run-tests.sh`, then `tests/run-tests.sh --self-test` (the profile's pre-review check), one after the other, with no edit to `tests/run-tests.sh` while either runs; record both exit codes.

## Work log

- 2026-09-10: created by /milestone-plan; absorbs two candidate rows (in-place book render output, M073 implement; `m069_cold_chapter`'s `_book`, M069 review F8, KI231).
- 2026-09-10: pinned the unreachable M073 checkpoint 7c83a21 as the local ref `refs/probes/m073-swept`, which garbage collection would otherwise be free to prune from about 2026-10-03.
- 2026-09-10: criteria audit, reduced mode, fresh [O] reader: AC2 and AC3 clean; AC1 narrowed from "the files Quarto wrote beside a book fixture's project" to the 22 recorded paths; AC4's `--self-test` half bound the harness rather than a deliverable, moved to T3.
- 2026-09-10: plan gate chose ignoring `*.html` and `site_libs/` inside every `examples/book*/` project over `examples/book-placement/` alone because the six book fixtures share the layout and AC2 fences tracked files; falsified by a book fixture needing a tracked page or asset at that depth.
- 2026-09-10: plan gate chose recording nothing about the unreproduced write over a Known-issues entry or an investigation task because an ignored repeat harms nothing; falsified by such a page reaching a check or a capture.
- 2026-09-10: plan chose the root `.gitignore` over `examples/.gitignore` because the root already holds every `examples/book*` rule and KI75 records the examples file duplicating it; falsified by a rule the root file cannot express for that directory.
- 2026-09-10: implement started on branch m089-book-fixture-hygiene; question gate skipped, nothing open.
- 2026-09-10: T1 — root `.gitignore` gains `examples/book*/*.html` and `examples/book*/site_libs/`; AC1's command (paths on stdin) prints 22 lines, none `::` (5 matched by the `*.html` rule, 17 by `site_libs/`); AC2's prints nothing; control with the two rules stashed prints `::` for all 22.
- 2026-09-10: T2 control (scratch copy of `examples/book-placement`, extension copied in, Quarto 1.10.18): whole-book HTML render wrote five pages at 21:29:54; `quarto render two.qmd --to html` with `_book` kept rewrote `two.html` at 21:29:57 and left the other four in place, three carrying `qi-index` sections.
- 2026-09-10: T2 — `m069_cold_chapter` removes `"$M061W/$slug/_book"` with the store, comment rewritten to say why; KI231 struck from DESIGN.md. Suite run for T1–T2 is T3's.
- 2026-09-10: T3 — on cea788b, `tests/run-tests.sh` exit 0 (779 checks), then `tests/run-tests.sh --self-test` exit 0 (1453 checks), run one after the other with no edit between; neither run left a page or `site_libs/` beside any `examples/book*/` project.
- 2026-09-10: claim audit: not owed — internal tier
- 2026-09-10: review in progress (checkpoint): AC1–AC3 evidenced and ticked, consistency gate clean; AC4's suite run and the three reviewers still running.
- 2026-09-10: review pre-gate checkpoint: AC1–AC4 evidenced and ticked; three reviewers returned four low findings (F1–F4), none failing a criterion; awaiting the merge gate.

## Decisions

## Review

Evidence gathered 2026-09-10 on 7286864, the branch head; `main` and `origin/main` agree and the branch contains both.

- AC1: `git show --name-only --format= refs/probes/m073-swept -- examples` lists 22 paths; piped to `git check-ignore --no-index --non-matching -v --stdin` it prints 22 lines, none opening `::` (5 matched by `.gitignore:36` `examples/book*/*.html`, 17 by `.gitignore:37` `examples/book*/site_libs/`), exit 0.
- AC2: `git ls-files -ci --exclude-standard` prints nothing, exit 0.
- AC3: read at 7286864, `tests/run-tests.sh:10762` runs `rm -rf "$M061W/$slug/.quarto/$STORE_DIR" "$M061W/$slug/_book"` before the `quarto render "$chapter" --to html` at `:10764`, the same `rm -rf` line `m069_tree` runs at `:10798`.
- Consistency gate: `cairn_validate.py` exit 0, every check PASS or OK; no DESIGN.md principle changed (the DESIGN.md diff strikes KI231 only), so `cairn_impact` is skipped; the `generic` profile names no toolchain checks. `git grep KI231` finds it only in this milestone file.
- AC4: `tests/run-tests.sh` on the 7286864 tree exit 0, "All checks passed (779 checks)", no `FAIL` line; 6dcc40e, the head now, differs from it only under `cairn/`. After the run no `*.html` or `site_libs/` sits directly inside any `examples/book*/` project.

Independent review (full three-reviewer fan-out, the diff touching `tests/run-tests.sh`); dispositions are set at the merge gate:
- [O] F1: the rewritten `m069_cold_chapter` comment (`tests/run-tests.sh:10757-10758`) says an emptied `_book` holds "this chapter's page and no other", but every such render also writes `index.html` (`:10893`), which the callers' manifests name (`:10926`, `:10960`); the old comment carried the same claim.
- [O] F2: the added `rm` of `_book` removes nothing today, `m063_tree` copying a base whose `_book` is already gone (`:8499`); defensive, as KI231 described.
- [O] F3: `examples/book*/*.html` misses a page written beside a nested chapter, e.g. `examples/book/sub/two.html`; the plan scoped the rules to files directly inside each project.
- [O] F4: `examples/book*/` would also match a future `examples/bookmarks/`; today it matches the six book projects, the reach of the `_book/` and `.quarto/` rules beside it.
- [S] blame-history: no findings; the change completes M069 review F8 and matches `m069_tree`.
- [S] prior-review: no findings; no PR review threads exist (`pulls/comments` empty).
