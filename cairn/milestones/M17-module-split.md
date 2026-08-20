# M17: index.lua becomes a thin entry point over required modules

- **Status:** review
- **Priority:** normal
- **Depends on:** M16
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch/PR:** `m17-module-split` / https://github.com/jmgirard/quarto-index/pull/17

## Goal

`_extensions/index/index.lua` becomes an entry point that requires modules
under `_extensions/index/modules/`, with the acceptance suite unchanged.

## Scope

Deliverable tier: **user-facing** — it spans both: rendered output must not
move, and the shipped extension's file set changes, which every `quarto add`
consumer receives.

**In:** the 2,729-line filter split along the seams already in it — constants
and `warn`, level semantics, the sort registry, LaTeX emission, shared mark
derivation, the three Span passes, HTML index building, marker/placement, book
support — each moved into a module loaded with a relative
`require("./modules/<name>")`. Verified this session: that form resolves when
the extension is run from the working tree, through the `examples/_extensions`
symlink, and when installed by `quarto add`, which copies subdirectories.

The three passes' shared module-level accumulators (`sort_keys`,
`contested_keys`, `marked_paths`, `pending_xrefs`, `clamped_paths`,
`html_marks`, `marks_seen`) move into the module that owns each and are reached
through its table; `require` caches a module once per process, so the sharing
the passes depend on is preserved.

No merge-base output comparison exists: M16 deletes `tests/byte-diff.sh` and
its D-entry makes the ~100-check acceptance suite the sole oracle. A split that
moves rendered output in a way no check probes would therefore pass AC2. That
residual risk is accepted here, not overlooked, and it is what the suite-
hardening candidate row is for.

**Out:** making that state per-document rather than module-level → stays the
standing `marks_seen` candidate row; the split relocates state, it does not
change its lifetime. Splitting `contributes.filters` into several filter
entries → refused: separate filters would not share the state the passes need.
Any behavior change → none; a rendered-output change is a defect here.

## Acceptance criteria

- [x] AC1: `_extensions/index/index.lua` defines only the `Pandoc` entry
      point; every other function the filter defines lives under
      `_extensions/index/modules/`. The domain is every definition
      `grep -nE '^[[:space:]]*(local )?function |= function\('` reports over
      M16's file-identified source set — 88 in `index.lua` at the merge base,
      which is why the pattern covers the nested and assigned forms and not
      just the top-level one. Afterwards it reports exactly one line whose file
      is `index.lua`: `Pandoc`.
- [ ] AC2: The split changes no check that existed at the merge base. Both
      `tests/run-tests.sh` and `tests/run-tests.sh --self-test` exit 0, and
      every `ok` line of the merge-base run — 195 and 230 of them, measured on
      this machine this session — stands verbatim, and in the same position,
      in the split run's log; the log's lines are the enumeration, since a
      count cannot see one check swapped for another. One line is exempt and
      named: `M16-AC2: the enumeration reaches modules/ (1 -> 2 …)`
      interpolates the source-set size and must read `(N -> N+1 …)` for the N
      `.lua` files the split extension holds, identical either side of the
      parentheses — the growth M16 built it to report.
      Against the merge base, `git status --porcelain` over `tests/`,
      `examples/` and `README.md` names exactly two paths, both modified, none
      untracked: `tests/movedefs.py`, the probe's hand, which relocates named
      definitions and asserts nothing about them, edited only to take them
      from the source set `tests/filtersrc.py` enumerates under the scratch
      root it is passed, never the ambient `QI_EXT_DIR`, rather than from the
      single file `index.lua`; and `tests/run-tests.sh`, where `git diff
      --numstat <base>` reports zero deletions, so every merge-base line
      survives and the additions are AC3's install-path probe. A merge-base
      *check* that needs editing to accommodate the move is a defect in that
      check (tracking-rules "What gets a test"), reported, never patched.
- [x] AC3: The split extension renders identically installed and from the
      working tree. Every `require` in the extension is at file top level,
      above that file's first definition — checked by a grep reporting each
      `require` line and each file's first definition line — so a module
      missing from an installed copy fails on any document, and fixture choice
      is not an axis install can affect. That leaves project shape and format,
      and the probe takes both whole: it packages `_extensions/index/`,
      installs it into a scratch project with `quarto add`, and renders one
      standalone fixture carrying marks and one book project, each to `latex`
      and `html`; all four outputs are byte-identical to the same render from
      the working tree.
- [x] AC4: `cairn/DESIGN.md` no longer describes the filter as one file: the
      sentence at `DESIGN.md:105` ("One Pandoc-Lua filter,
      `_extensions/index/index.lua`, run as three passes over…") is replaced,
      and the Architecture section names every module. The domain is the module
      set M16's enumeration reports; each member is grepped for in the
      Architecture section in its extension-bearing form (`levels.lua`, not
      `levels`) and found. The bare-name form would not discriminate — seven of
      the nine words already appear in that section today, and none of the nine
      `.lua` forms does.
- [x] AC5: `_extensions/index/_extension.yml` still declares exactly one
      `contributes.filters` entry, `index.lua`, so the install story stays
      `quarto add` alone (GP3).

## Coverage

- AC1 → T1, T2, T3, T4, T5, T6, T7, T8
- AC2 → T1, T2, T3, T4, T5, T6, T7, T8
- AC3 → T9
- AC4 → T10
- AC5 → T10

## Tasks

Each move task ends by running both verify slots, so a bad move is caught by
the task that made it.

- [x] T1: Create `_extensions/index/modules/`; move the constants, `warn`,
      `is_latex_derived` and `is_html` (`index.lua:30-158`) into
      `modules/core.lua`; wire the relative require.
- [x] T2: Move level semantics — `parse_levels` through `level_path`
      (`:160-458`) — into `modules/levels.lua`, and the sort registry —
      `sort_keys` through `clamp_sort` (`:459-581`) — into
      `modules/sortkeys.lua`; the registry keys on `level_path`, so the two
      move together.
- [x] T3: Move LaTeX emission — `index_argument` through `fold_xrefs`
      (`:582-775`) — into `modules/latex.lua`.
- [x] T4: Move shared mark derivation — `span_text` through `derive_levels`
      (`:776-992`) — into `modules/marks.lua`.
- [x] T5: Move the three Span passes — `CollectSort`, `CollectKeys`, `Span`
      (`:993-1282`) — into `modules/passes.lua`.
- [x] T6: Move HTML index building — `fold_case` through `html_index_blocks`
      (`:1283-1773`) — into `modules/html.lua`.
- [x] T7: Move marker and placement — `is_marker` through `place_index`
      (`:1774-2049`) — into `modules/marker.lua`.
- [x] T8: Move book support — `as_href` through `html_book` (`:2050-2522`) —
      into `modules/book.lua`, leaving `Pandoc` and the returned pass list.
- [x] T9: Add the install-path probe of AC3 — package, `quarto add` into a
      scratch project, render the four combinations, compare byte for byte.
- [x] T10: Rewrite `cairn/DESIGN.md`'s Architecture section for the module
      layout and the relative-`require` convention; confirm `_extension.yml`
      unchanged.

## Work log

- 2026-08-20: created by /milestone-plan; promoted from the "Split `index.lua` into `require`d modules" candidate row (added 2026-08-19).
- 2026-08-20: criteria audit ran in FULL mode (declared tier user-facing); returned five findings — gameable line-count bounds, an instrument-bound output promise, a one-exemplar install probe, a docs criterion no state could fail, and a globals criterion resting on a false premise. All five disposed at the gate: four repaired, the globals criterion dropped.
- 2026-08-20: the globals criterion was dropped because its premise was wrong — `index.lua:1546` forward-declares `local entry_list`, so `:1561`'s `function entry_list` assigns to that local and the file defines no globals.
- 2026-08-20: plan gate chose one milestone of ten move tasks over splitting core and back-ends across two because each move is verified by the task that makes it and the seam between core and back-ends is where module boundaries are least obvious; falsified by a move task that cannot be verified in isolation.
- 2026-08-20: plan chose relative `require("./modules/<name>")` over `package.path` manipulation because Quarto patches `require` to resolve relative paths against the calling script (`share/pandoc/datadir/init.lua:260`), verified working from the working tree, through the symlink, and installed; falsified by a Quarto version dropping that patch.
- 2026-08-20: implement start; branch `m17-module-split` cut from cb782df. Merge-base baseline measured on this machine: `tests/run-tests.sh` 195 ok lines, `--self-test` 230, both exit 0.
- 2026-08-20: implementation-gate question — `tests/movedefs.py` reads one named file (`index.lua`) and refuses a name it cannot find there, so T1 alone reds the suite; demonstrated on a scratch tree with `LATEX_LITERAL` hand-moved (`FAIL: movedefs: 'LATEX_LITERAL' has 0 top-level definitions in index.lua, want exactly 1`). Gate chose to name the permitted test-file changes explicitly rather than freeze only run-tests.sh and tests/scans/.
- 2026-08-20: amendment return: AC2 — "The split changes no check that existed at the merge base. Both `tests/run-tests.sh` and `tests/run-tests.sh --self-test` exit 0, and every `ok` line of the merge-base run — 195 and 230 of them, measured on this machine this session — stands verbatim, and in the same position, in the split run's log"
- 2026-08-20: criteria audit ran in FULL mode on the amended AC2 (declared tier user-facing), two fresh-context [O] readers, neither the author. First pass returned seven findings, of which two blocking: AC2's tests/-freeze contradicted the milestone's own T9/AC3, and the "confined to" clause silently constrained the Lua import idiom. Second pass on the repaired wording returned finding 1 fatal — `run-tests.sh`'s `M16-AC2: the enumeration reaches modules/ (1 -> 2 …)` line interpolates the source-set size, so no correct split can leave it verbatim — plus three narrowings (untracked/`examples/`/README left outside the diff domain; "confined to AC3's probe" unmechanizable; movedefs must enumerate the scratch root, not the ambient QI_EXT_DIR). All disposed into the wording written above; the import-idiom finding went to the milestone-local decision instead of the criterion.
- 2026-08-20: two module-level flags beyond the plan's seven accumulators found while mapping the seams — `xref_list_emitted` and `xref_both_emitted`, both written in the Span pass and read in `Pandoc`. Both are LaTeX-emission state, so both land in `modules/latex.lua`; `xref_both_emitted` therefore moves out of T4's line range. Task-range refinement only, no scope change.
- 2026-08-20: T7/T8 boundary refined from the plan's `:2049`/`:2050` to `:2020`/`:2021` — the `STORE_DIR`/`STORE_SUFFIX`/`STORE_VERSION` constants at `:2041-2047` sit under the plan's marker range but belong to book support, and the book section's own banner opens at `:2021`.
- 2026-08-20: T1 — `modules/core.lua` (constants, `warn`, `is_latex_derived`, `is_html`), 17 definitions, 86 call sites qualified to `core.`; `tests/movedefs.py` rewritten to relocate from the source set `filtersrc.py` enumerates under the scratch root it is passed. Verify clean: 195 ok lines identical to the merge base, 230 under `--self-test` with the one exempted interpolated line reading `(2 -> 3)`.
- 2026-08-20: T2 — `modules/levels.lua` (11 definitions, 38 sites) and `modules/sortkeys.lua` (4 definitions, 6 sites). T1's `core` alias renamed to `qi_core` in the same commit under the aliasing decision below. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(4 -> 5)`.
- 2026-08-20: T3 — `modules/latex.lua`, 9 definitions, 11 sites. `xref_both_emitted` moved here from T4's range and both emission flags became `M["name"]` fields, since a scalar cannot be shared by aliasing a local. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(5 -> 6)`.
- 2026-08-20: T4 — `modules/marks.lua`, 12 definitions, 28 sites, carrying `html_marks`, `marked_paths`, `pending_xrefs`, `clamped_paths` as shared tables and `marks_seen` as a field. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(6 -> 7)`.
- 2026-08-20: T5 — `modules/passes.lua`, the three Span passes, 4 sites. The walk-filter and return-table keys named `Span` stay bare; only the values are qualified. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(7 -> 8)`.
- 2026-08-20: T6 — `modules/html.lua`, 23 definitions, 5 sites; only `html_index_blocks`, `taken_identifiers`, `relocate_heading_anchors` and `assign_anchors` are reached from outside it. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(8 -> 9)`.
- 2026-08-20: T7 — `modules/marker.lua`, 9 definitions, 10 sites. T8 — `modules/book.lua`, 18 definitions, 3 sites, carrying the three `STORE_*` constants. `index.lua` is now 256 lines: the mark-syntax header, nine requires in dependency order, `Pandoc`, and the pass list. AC1's grep over the source set reports one definition line whose file is `index.lua`: `local function Pandoc(doc)`. Verify clean: 195 ok lines identical, 230 under `--self-test` with the exempted line reading `(10 -> 11)`.
- 2026-08-20: T9 — the AC3 install-path probe, 131 added lines and zero deleted in `tests/run-tests.sh`. Two new checks: 32 require calls all at file top level above their file's first definition, and four byte-identical outputs (standalone and book, each to latex and html) between a `quarto add` install and the working tree. Run totals 195 -> 197 and 230 -> 232, every merge-base line verbatim and in order.
- 2026-08-20: the AC3 probe discriminates, verified out of band rather than in the run: deleting `modules/marks.lua` from an installed copy fails the render at filter-load time (`inject_user_filters_at_entry_points`), which is the claim that makes fixture choice a non-axis; and moving `sortkeys.lua`'s `qi_levels` require below its first definition fails the position check naming both lines. Neither is a planted-defect check in the suite — that gap goes to the acceptance-suite hardening row.
- 2026-08-20: T10 — `cairn/DESIGN.md`'s Architecture section opens on the module layout and names all ten source files in their `.lua` form; `_extension.yml` unchanged against the merge base (`git diff cb782df` empty for it). Two probe gaps recorded on the acceptance-suite hardening candidate row.
- 2026-08-20: tasks complete, status to `review`. Pre-review check clean: `tests/run-tests.sh` 197, `--self-test` 232, both exit 0. Every merge-base ok line verbatim and in order in both runs, the one exempted interpolated line reading `(10 -> 11)` for the extension's 10 `.lua` files with identical text either side of the parentheses. `git status --porcelain` over `tests/`, `examples/` and `README.md` is clean; `git diff --numstat cb782df` over them names two files, `tests/movedefs.py` (54/26) and `tests/run-tests.sh` (134/0, zero deletions).
- 2026-08-20: review return 1 (defect). AC2 failed: its position clause asks that every merge-base `ok` line stand "in the same position" in the split run's log, and in `--self-test` the probe's two lines shift merge-base lines 196-230 to 198-232. AC1, AC3, AC4 and AC5 verified; consistency gate clean. Status back to `in-progress` with seven further fix-now findings from the review; three findings go to candidate rows and three were refuted or rejected.
- 2026-08-20: return 1 fixed. E — the AC3 probe block moved below the `--self-test` section, so its two `ok` lines land after every merge-base line instead of shifting the self-test's down by two; costs nothing, since the nested `--plant-wrapper-defect` run dies at `run-tests.sh:1066` before any render. C — the probe copies `examples/book` wholesale (excluding `_book`, `.quarto`, `_extensions`) and derives the standalone fixture's assets out of the fixture, with a guard comparing the chapter count it copied against the one `examples/book` holds. D — all four compared outputs now carry a non-emptiness guard, not two. N — the require check reports each file's require lines and its first definition line on success, as AC3 says. G — the two requires `index.lua` never used are gone (7 remain, each used). H — the corrupted comment restored to its merge-base wording. F — the bracket-export and definition-form rules recorded in DESIGN.md Conventions. K, L — the lifetime claim now names `package.loaded` as what changed and points at the standing `marks_seen` row; the stray hard break is gone.
- 2026-08-20: AC2's position clause measured literally after the fix: in both runs every merge-base `ok` line stands verbatim at its own position (195 of 195, 230 of 230, zero mismatches), the exempt line sits at position 200 reading `(10 -> 11)` with identical text either side, and the two added lines land at 196-197 and 231-232. Suite 197 / 232, both exit 0. `git diff --numstat cb782df` over `tests/`, `examples/` and `README.md` still names two files, `tests/movedefs.py` (54/26) and `tests/run-tests.sh` (189/0, zero deletions); `git status --porcelain` over them is clean. Status back to `review`.

## Decisions

### 2026-08-20: modules bind imported names through the module table, and every definition keeps its merge-base form

**Context:** `tests/movedefs.py` matches `local function NAME(` or `local NAME =` at column 0 and demands exactly one hit per name, and `tests/scans/warn-distinct.py` excludes `warn`'s own definition by testing that the text before the match rstrips to `function`. Both are merge-base checks AC2 forbids editing.
**Decision:** A name a module imports is reached through the exporting module's table (`core.warn(...)`, `levels.MAX_LEVELS`) and is never re-bound as a same-named local. Every definition keeps its merge-base form — `local function NAME(` or `local NAME = <literal>` at column 0 — in whichever module it lands in; the module table is populated by assignment afterwards, never by `function M.NAME(`.
**Consequences:** `movedefs.py` still finds exactly one definition per name after the split, and `warn-distinct`'s pinned count of 38 messages holds because call sites still match `\bwarn\(` while the sole definition still rstrips to `function`. The cost is that cross-module call sites gain a module prefix.

### 2026-08-20: a module exports through `M["NAME"]`, never `M.NAME`

**Context:** T1 with plain `M.XREF_BOTH_DEFINITION = XREF_BOTH_DEFINITION` export lines failed the M16-AC3 probe: `FAIL: M02-AC5: the dual-target definition does not use \seename`. `tests/scans/xref-both-definition.py` takes the FIRST `XREF_BOTH_DEFINITION\s*=` match over the sorted source set, and once the probe relocates the real definition into `modules/moved.lua` — which sorts after `modules/core.lua` — the export line left behind in `core.lua` is what the scan reads. This is M16 review F3 arriving in the case it was written about. Narrows the entry above.
**Decision:** Export lines use the bracket form, `M["warn"] = warn`. The name inside the brackets is followed by `"]`, not by `=`, so an export line is invisible to every scan that searches for `NAME =` and to `movedefs.block()`'s exactly-one count.
**Consequences:** No module leaves a second textual `NAME =` behind that could mask its own definition once the probe moves it, and the four first-match scans M16's review flagged keep reading the definition they name. Each module carries a four-line comment saying so, so the unusual form is not read as an accident.

### 2026-08-20: a module is required under the alias `qi_<name>`, not `<name>`

**Context:** `local levels = require("./levels")` in `sortkeys.lua` is shadowed by the parameter of `register_sort(levels, declared, context)`, so `levels.level_path(levels, i)` would index the caller's level list instead of the module. The filter uses `levels` as a local on 131 lines, `marker` on 71 and `marks` on 57, so the collision is not incidental to one function.
**Decision:** Every module is required under `qi_<name>` — `qi_core`, `qi_levels`, `qi_sortkeys` — while the files keep the plain names the plan gave them. `qi_` is already the extension's namespace on the reader-facing side (`qi-index`, `qi-mark-`), and no identifier in the filter begins with it.
**Consequences:** No module alias can be shadowed by a local, and the rule is uniform rather than applied only to the four names that collide today — a later local named `html` or `book` cannot silently capture a module. Cross-module call sites carry three more characters than the bare alias would.

## Review

Verified 2026-08-20 on branch `m17-module-split` at 2cc8c19, against merge base
cb782df. PR: https://github.com/jmgirard/quarto-index/pull/17

- AC1 — `grep -nE '^[[:space:]]*(local )?function |= function\('` over the
  source set `tests/filtersrc.py` enumerates reports 88 definition lines, the
  same 88 the merge base's `index.lua` carried alone. Exactly one has
  `index.lua` as its file: `50:local function Pandoc(doc)`. The other 87 are
  distributed across the nine modules (book 15, core 3, html 29, latex 6,
  levels 8, marker 13, marks 7, passes 3, sortkeys 3).
- AC2 — NOT MET, unticked at this review. `tests/run-tests.sh` 197 checks,
  `--self-test` 232, both exit 0. The diff domain holds: `git status
  --porcelain` over `tests/`, `examples/` and `README.md` is clean, and `git
  diff --numstat cb782df` over the same three names exactly two files,
  `tests/movedefs.py` (54 added, 26 deleted) and `tests/run-tests.sh` (134
  added, 0 deleted). The exempted line reads `(10 -> 11 with no edit here)`
  with identical text either side of the parentheses. But the position clause
  fails: the probe's two `ok` lines are emitted before the `--self-test`
  section, so in the 232-line self-test log the merge-base lines 196-230 stand
  at 198-232, not at their own positions. The plain run is unaffected (the two
  land at 196-197, after all 195). Measured evidence was an in-order
  subsequence, which is weaker than the criterion asks; the tick was withdrawn
  rather than the criterion reread (review finding E).
- AC3 — the two probe checks pass in the run above: 32 `require()` calls across
  the source set all at file top level above their file's first definition, and
  four byte-identical outputs (a standalone fixture and a book project, each to
  latex and html) between an extension installed by `quarto add` and the working
  tree. Both halves were shown discriminating at T9 (work log, 2026-08-20).
- AC4 — `cairn/DESIGN.md:105` no longer describes the filter as one file. Each
  of the ten members of the source set is found in the Architecture section in
  its extension-bearing form: `index.lua`, `core.lua`, `levels.lua`,
  `sortkeys.lua`, `latex.lua`, `marks.lua`, `passes.lua`, `html.lua`,
  `marker.lua`, `book.lua`.
- AC5 — `git diff cb782df -- _extensions/index/_extension.yml` is empty, and the
  file declares one `contributes.filters` entry, `index.lua`.

Consistency gate: `cairn_validate.py` exits 0, all checks passed. The active
profile is `generic`, whose `consistency-gate` slot names no toolchain checks.
No IP or GP text changed — the branch's only DESIGN.md edit is the Architecture
section, which cites GP3 without altering it — so `cairn_impact` does not apply.

Independent review: three fresh-context reviewers, none having seen the
implementation. The [O] diff-bug reviewer reconstructed the output-neutrality
oracle D-004 deleted — 29 fixtures x 3 formats and all 6 book-project renders,
at cb782df and at the split — and found every output, every render log and
every exit code byte-identical. It also confirmed the normalized code-line
multiset equals the merge base's apart from the three scalars that became
fields, each module's code is an in-order subsequence of the merge base, all
ten files compile under `pandoc lua`, and loading all ten shows one global read
(`ipairs`) and zero global writes. Fifteen findings, triaged at the gate:

- E (AC2 position clause) — floor return; see AC2 above. Fix: move the probe
  block below the self-test section so both runs keep every merge-base line at
  its own position. Costs nothing: the nested `--plant-wrapper-defect` run dies
  at `run-tests.sh:1066`, before any render.
- C — the parity probe hard-codes its fixture file lists, the
  written-down-list-becomes-the-sweep shape M16 and D-004 forbid. Fix now.
- D — only two of the four compared outputs carry a non-emptiness guard. Fix now.
- N — AC3 promises a report of each require line and each file's first
  definition line; the check reports a count on success. Fix now.
- G — `qi_levels` and `qi_sortkeys` are required in `index.lua` and never used
  (verified: 0 uses each). Fix now.
- H — the qualification pass rewrote an English word inside a comment,
  `index.lua:129`. Fix now. Class bounded: all 1,038 merge-base comment lines
  survive character-for-character once `qi_` prefixes are stripped, no string
  literal contains `qi_`, and of the 17 prefixed comment lines this is the only
  prose case.
- F — the bracket-export rule and the definition-form rule bind the code but
  live only in this file, which is archived on merge. Fix now: record both in
  DESIGN.md Conventions.
- K, L — DESIGN overstates the lifetime claim (the accumulators' lifetime is
  now `package.loaded`'s, identical today only because Quarto runs one pandoc
  process per document), and carries a stray hard break. Fix now.
- A — no suite check guards AC1's one-definition rule. Follow-up: it cannot be
  fixed here without breaching AC2's own bound on `run-tests.sh`. Absorbed into
  the acceptance-suite hardening candidate row.
- J, I — line-length drift (14 over-80 lines to 62) and whole-surface exports.
  Follow-up: new clustered candidate row.
- B — `quarto-required: ">=1.4.0"` called a newly unverified claim. Refuted:
  Quarto's own 1.4 release notes state "Quarto v1.4 supports the use of
  relative paths in `require()` calls", so the declared floor covers the
  feature. That the floor is untested is the standing candidate row, unchanged
  by this milestone.
- M — AC2's parenthetical calls `movedefs.py` a script that "asserts nothing
  about them", while `block()` does assert exactly-one. Imprecise, but the
  operative clause describes the permitted edit accurately and the delivered
  edit matches it, so the criterion is not falsified and this is not an
  amendment return. Logged, rejected, no action.
- O — no in-tree artifact of the parity block having run. Refuted:
  `tests/.work/install-parity/` holds `ext.zip`, `stage`, `tree` and `inst`,
  and `tests/.work/run.log` carries 232 `ok` lines including both `M17-AC3`
  lines. The reviewer read the tree while a run was in flight.
- Reviewers 2 and 3 (blame-history, prior-review record) reported no
  regression; the blame lens found H independently, and the prior-review lens
  verified empirically that the nested relative `require` resolves and shares
  state under Quarto's extension-loading path though not under raw
  `pandoc --lua-filter`.

