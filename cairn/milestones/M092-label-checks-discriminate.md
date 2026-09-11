# M092: The label and separator checks fail on the defects they name

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP6
- **Resolves:** —
- **Surface tier:** internal — every change is to `tests/run-tests.sh`, `tests/sepcheck.py` or `tests/htmlindex.py`, and no fixture, filter module or page changes
- **Branch/PR:** m092-label-checks-discriminate

## Goal

The M56-M59 label and separator checks each go red on the defect that their
own message names, so a green run over the index-labels and index-separators
fixtures is evidence about those fixtures.

## Scope

**In:** KI180, KI181, KI182, KI186, KI190, KI191, KI192, KI193, KI194 and
KI195, all under "The repo and its packaging" in `cairn/DESIGN.md`. The work
items are these:

- The M56-AC6 comparison and its self-test share one function.
- Total extension-warning pins for `examples/index-labels.qmd`.
- `derive_labels_twin` reads the front matter as YAML.
- `m57_tex_ledger` filters diff headers by position.
- `entry_separators` walks the same nodes as the record builder.
- `tests/sepcheck.py` fails cleanly on a malformed manifest, with true wording.
- The zero controls that cannot fail go: fourteen in the M59 block, and two
  each in the M56-AC5 and M58-AC4 control loops, which the implement gate
  added. The M59 clash report's silence half gets plants.

A `--self-test` plant of its own defect class shows each repaired check red.
Each closed entry is struck from `cairn/DESIGN.md`.

**Out:**
- The label and language shapes that no render reaches (KI183, KI189, KI196,
  KI197) and the language-module cleanups (KI184, KI185, KI187, KI188) go to
  M093.
- A change to what the extension prints or reports is not needed. No item
  here is a filter defect.

## Acceptance criteria

- [ ] AC1: The M56-AC6 `.tex` comparison in `tests/run-tests.sh` is one
      function. The run's own comparison and its `--self-test` plant both
      call it, and it fails on a `.tex` pair that differs.
- [ ] AC2: `examples/index-labels.qmd` draws 0 extension warnings when
      rendered to HTML and when rendered to LaTeX, as
      `check_extension_warning_count` reads each render's log. A render log
      with one extension warning more fails that count.
- [ ] AC3: Each zero-expectation control left in the M59 block of
      `tests/run-tests.sh`, the M59-AC4 control loop included, and each left
      in the M56-AC5 and M58-AC4 control loops, is
      document-level or names an index or `indexes:` position that the
      fixture it reads declares. The count checks over
      `examples/index-labels-clash.qmd`'s HTML log fail when that log carries
      a no-clash report line, and fail when it carries one extension warning
      other than a clash report.
- [ ] AC4: `derive_labels_twin` fails when the twin's parsed front matter or
      its body differs from the fixture's with every `index-labels:` key
      deleted. It passes on a copy of `examples/index-labels.qmd` with a blank
      line inside an `index-labels:` map, held against the unchanged twin. It
      fails when the `index-labels:` block of `examples/index-separators.qmd`
      sets a key other than `separator` and `xref-separator`.
- [ ] AC5: `m57_tex_ledger` classifies a differing line whose body is `--` or
      `++`, and does not discard it as a diff header.
- [ ] AC6: `entry_separators` in `tests/htmlindex.py` returns the same
      separators for a copy of a captured index whose entry lines are wrapped
      in `<p>` as for the unwrapped capture. Given a manifest with an unknown
      slot name, and given one with a space in place of a tab,
      `tests/sepcheck.py` prints one `FAIL:` line and exits 1 with no
      traceback. Its pass and fail
      lines say "whitespace character", which is what the check accepts.
- [ ] AC7: The active profile's verify command, `tests/run-tests.sh
      --self-test`, runs clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7, T8

## Tasks

- [ ] T1: KI180. Factor the M56-AC6 `diff` (`tests/run-tests.sh` near line
      24755) into a function. Call it from the AC6 leg and from the self-test
      plant (near line 24840) in place of the inline `diff -q`. The M58-AC6
      comparison (near line 25514) calls it too. The plant asserts the
      function's own FAIL text.
- [ ] T2: KI181. Add `check_extension_warning_count` at 0 over
      `$WORK/index-labels-html.log` and over the LaTeX log, beside the M56
      pins near line 24674. Add a `--self-test` plant that appends one
      extension warning line to a copy of each log.
- [ ] T3: KI194, KI195. Delete the M59 zero controls that name `strata`,
      `minerals`, `fossils` or `indexes:` entries 5-8: ten in the AC1-AC3
      loops (near lines 25664-25703) and four in the M59-AC4 control loop
      (near lines 25734-25740). Delete the M56-AC5 controls naming `notes`
      and `sources` (near line 24743) and both M58-AC4 controls, which name
      `figures` (near line 25494). The M58-AC4 loop keeps no control. Keep
      the document-level controls. Derive the kept set
      from the fixture's declarations, not by recall. Add two `m59_planted`
      cases on copies of the clash log (near line 25812): one appends a
      no-clash report line, and one appends an extension warning that is not
      a clash report.
- [ ] T4: KI182, KI192. Rewrite `derive_labels_twin` (near line 24403). It
      splits the front matter from the body and parses the front matter with
      PyYAML (D-030). It deletes `index-labels` at the document level and
      under each `indexes:` entry, then compares the fixture's parsed map and
      body with the twin's. Give it an optional expected-key argument, and
      pass `separator xref-separator` at the M58-AC2 call (near line 25367).
      Each deleted map's keys must equal that set exactly.
      Plants: a blank line inside a copy's map (passes), a third key in a copy
      of the separators fixture (fails and names the key). Keep the existing
      drift plants.
- [ ] T5: KI186. In `m57_tex_ledger` (near line 25163), filter only the two
      header lines of the unified diff, by position. Add a plant over a
      synthetic `.tex` pair whose differing line is `--`.
- [ ] T6: KI190, KI191, KI193. Route `entry_separators` (`tests/htmlindex.py`
      near line 589) through the `own_nodes` walk. Add a self-test that wraps
      each entry line of a copy of a captured index in `<p>` and compares the
      separators. In `main()` of `tests/sepcheck.py`, catch the manifest
      `ValueError` into a `FAIL:` line and exit 1. Plant a manifest with an
      unknown slot name and one with a space for a tab, and reword the ok and
      FAIL lines. Run the reader's
      probes under the oldest and newest Python in reach (LESSONS, M082).
- [ ] T7: Strike KI180, KI181, KI182, KI186, KI190, KI191, KI192, KI193,
      KI194 and KI195 from `cairn/DESIGN.md` per D-013. No ROADMAP row names
      any of them.
- [ ] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.
      Do not edit the suite while a run is in flight (LESSONS, M073).

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit (reduced mode, fresh [O] reader) returned four findings, all fixed before the gate: AC3's domain held 14 controls, not 10 (the M59-AC4 loop added to T3); AC3's total plant must add a non-clash warning; AC4 reworded to the parsed comparison and a blank-line copy against the unchanged twin; AC6 names the two malformed-manifest shapes and a copy of a captured index.
- 2026-09-11: plan gate chose two milestones (M092 checks, M093 coverage and module cleanups) over one 18-item milestone because one would carry about 12 criteria; falsified by the two branches conflicting in `tests/run-tests.sh` badly enough that a combined review would have cost less.
- 2026-09-11: plan gate chose a parsed-YAML `derive_labels_twin` over patching the line walker or deleting the drift check, because parsing removes the blank-line defect and makes the key check one line without widening the promise; falsified by a twin whose render differs through a front-matter spelling (a comment, quoting, key order) that the parsed comparison cannot see.
- 2026-09-11: implement started on branch `m092-label-checks-discriminate`.
- 2026-09-11: implement gate chose an exact key set for the M58-AC2 twin check over a subset check, and chose to have M58-AC6 call the T1 comparison function.
- 2026-09-11: amendment (user selection at the implement gate): AC3 and Scope widened to the M56-AC5 `notes`/`sources` controls and both M58-AC4 `figures` controls, which read fixtures that declare none of those indexes. T3 names the four deletions.
- re-audit: AC3 (reduced) — nothing (the reader asked that Scope and T3 name the two added loops, and both now do)
- 2026-09-11: T1 checkpoint: `check_tex_identical` serves M56-AC6, M58-AC6 and the M56 plant, and reports a diff exit 2 apart from a difference. Isolated probe: green on both real pairs, the plant red on a one-line drift and red on an inverted-case mutant. Suite run pending.
- 2026-09-11: T2 checkpoint: zero totals over the labels fixture's HTML and LaTeX logs, and a plant per log appending one extension warning. Isolated probe over the last run's logs: both pins green (the logs hold 0 extension warnings each), both plants red with `expected 0 warning(s)`. Suite run pending.
- 2026-09-11: T3 checkpoint: kept set derived from the three fixtures' front matter (labels declares `main`, `authors`; separators no `indexes:`). Eighteen controls deleted (14 M59, 2 M56-AC5, 2 M58-AC4). The four document-level controls stay (M56-AC5 unknown key and empty `see`, M59 invisible `see-also` and list `symbols`), and the M59 silence count over the clash log stays because that fixture declares `fossils`. Two clash-log plants added. Isolated probe: kept controls and counts green, both plants red. Suite run pending.

## Decisions

## Review
