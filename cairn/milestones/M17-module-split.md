# M17: index.lua becomes a thin entry point over required modules

- **Status:** planned
- **Priority:** normal
- **Depends on:** M16
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch/PR:** —

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

- [ ] AC1: `_extensions/index/index.lua` defines only the `Pandoc` entry
      point; every other function the filter defines lives under
      `_extensions/index/modules/`. The domain is every definition
      `grep -nE '^[[:space:]]*(local )?function |= function\('` reports over
      M16's file-identified source set — 88 in `index.lua` at the merge base,
      which is why the pattern covers the nested and assigned forms and not
      just the top-level one. Afterwards it reports exactly one line whose file
      is `index.lua`: `Pandoc`.
- [ ] AC2: The split changes no check. `tests/run-tests.sh` and
      `tests/run-tests.sh --self-test` report the same check count and the same
      pass/fail set as at the merge base, and `git diff <base> -- tests/` is
      empty. A check that needs editing to accommodate the move is a defect in
      that check (tracking-rules "What gets a test"), reported rather than
      silently patched.
- [ ] AC3: The split extension renders identically installed and from the
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
- [ ] AC4: `cairn/DESIGN.md` no longer describes the filter as one file: the
      sentence at `DESIGN.md:105` ("One Pandoc-Lua filter,
      `_extensions/index/index.lua`, run as three passes over…") is replaced,
      and the Architecture section names every module. The domain is the module
      set M16's enumeration reports; each member is grepped for in the
      Architecture section in its extension-bearing form (`levels.lua`, not
      `levels`) and found. The bare-name form would not discriminate — seven of
      the nine words already appear in that section today, and none of the nine
      `.lua` forms does.
- [ ] AC5: `_extensions/index/_extension.yml` still declares exactly one
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

- [ ] T1: Create `_extensions/index/modules/`; move the constants, `warn`,
      `is_latex_derived` and `is_html` (`index.lua:30-158`) into
      `modules/core.lua`; wire the relative require.
- [ ] T2: Move level semantics — `parse_levels` through `level_path`
      (`:160-458`) — into `modules/levels.lua`, and the sort registry —
      `sort_keys` through `clamp_sort` (`:459-581`) — into
      `modules/sortkeys.lua`; the registry keys on `level_path`, so the two
      move together.
- [ ] T3: Move LaTeX emission — `index_argument` through `fold_xrefs`
      (`:582-775`) — into `modules/latex.lua`.
- [ ] T4: Move shared mark derivation — `span_text` through `derive_levels`
      (`:776-992`) — into `modules/marks.lua`.
- [ ] T5: Move the three Span passes — `CollectSort`, `CollectKeys`, `Span`
      (`:993-1282`) — into `modules/passes.lua`.
- [ ] T6: Move HTML index building — `fold_case` through `html_index_blocks`
      (`:1283-1773`) — into `modules/html.lua`.
- [ ] T7: Move marker and placement — `is_marker` through `place_index`
      (`:1774-2049`) — into `modules/marker.lua`.
- [ ] T8: Move book support — `as_href` through `html_book` (`:2050-2522`) —
      into `modules/book.lua`, leaving `Pandoc` and the returned pass list.
- [ ] T9: Add the install-path probe of AC3 — package, `quarto add` into a
      scratch project, render the four combinations, compare byte for byte.
- [ ] T10: Rewrite `cairn/DESIGN.md`'s Architecture section for the module
      layout and the relative-`require` convention; confirm `_extension.yml`
      unchanged.

## Work log

- 2026-08-20: created by /milestone-plan; promoted from the "Split `index.lua` into `require`d modules" candidate row (added 2026-08-19).
- 2026-08-20: criteria audit ran in FULL mode (declared tier user-facing); returned five findings — gameable line-count bounds, an instrument-bound output promise, a one-exemplar install probe, a docs criterion no state could fail, and a globals criterion resting on a false premise. All five disposed at the gate: four repaired, the globals criterion dropped.
- 2026-08-20: the globals criterion was dropped because its premise was wrong — `index.lua:1546` forward-declares `local entry_list`, so `:1561`'s `function entry_list` assigns to that local and the file defines no globals.
- 2026-08-20: plan gate chose one milestone of ten move tasks over splitting core and back-ends across two because each move is verified by the task that makes it and the seam between core and back-ends is where module boundaries are least obvious; falsified by a move task that cannot be verified in isolation.
- 2026-08-20: plan chose relative `require("./modules/<name>")` over `package.path` manipulation because Quarto patches `require` to resolve relative paths against the calling script (`share/pandoc/datadir/init.lua:260`), verified working from the working tree, through the symlink, and installed; falsified by a Quarto version dropping that patch.

## Decisions

## Review
