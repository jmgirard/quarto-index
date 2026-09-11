# M092: The label and separator checks fail on the defects they name

- **Status:** review
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

- [x] AC1: The M56-AC6 `.tex` comparison in `tests/run-tests.sh` is one
      function. The run's own comparison and its `--self-test` plant both
      call it, and it fails on a `.tex` pair that differs.
- [x] AC2: `examples/index-labels.qmd` draws 0 extension warnings when
      rendered to HTML and when rendered to LaTeX, as
      `check_extension_warning_count` reads each render's log. A render log
      with one extension warning more fails that count.
- [x] AC3: Each zero-expectation control left in the M59 block of
      `tests/run-tests.sh`, the M59-AC4 control loop included, and each left
      in the M56-AC5 and M58-AC4 control loops, is
      document-level or names an index or `indexes:` position that the
      fixture it reads declares. The count checks over
      `examples/index-labels-clash.qmd`'s HTML log fail when that log carries
      a no-clash report line, and fail when it carries one extension warning
      other than a clash report.
- [x] AC4: `derive_labels_twin` fails when the twin's parsed front matter or
      its body differs from the fixture's with every `index-labels:` key
      deleted. It passes on a copy of `examples/index-labels.qmd` with a blank
      line inside an `index-labels:` map, held against the unchanged twin. It
      fails when the `index-labels:` block of `examples/index-separators.qmd`
      sets a key other than `separator` and `xref-separator`.
- [x] AC5: `m57_tex_ledger` classifies a differing line whose body is `--` or
      `++`, and does not discard it as a diff header.
- [x] AC6: `entry_separators` in `tests/htmlindex.py` returns the same
      separators for a copy of a captured index whose entry lines are wrapped
      in `<p>` as for the unwrapped capture. Given a manifest with an unknown
      slot name, and given one with a space in place of a tab,
      `tests/sepcheck.py` prints one `FAIL:` line and exits 1 with no
      traceback. Its pass and fail
      lines say "whitespace character", which is what the check accepts.
- [x] AC7: The active profile's verify command, `tests/run-tests.sh
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

- [x] T1: KI180. Factor the M56-AC6 `diff` (`tests/run-tests.sh` near line
      24755) into a function. Call it from the AC6 leg and from the self-test
      plant (near line 24840) in place of the inline `diff -q`. The M58-AC6
      comparison (near line 25514) calls it too. The plant asserts the
      function's own FAIL text.
- [x] T2: KI181. Add `check_extension_warning_count` at 0 over
      `$WORK/index-labels-html.log` and over the LaTeX log, beside the M56
      pins near line 24674. Add a `--self-test` plant that appends one
      extension warning line to a copy of each log.
- [x] T3: KI194, KI195. Delete the M59 zero controls that name `strata`,
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
- [x] T4: KI182, KI192. Rewrite `derive_labels_twin` (near line 24403). It
      splits the front matter from the body and parses the front matter with
      PyYAML (D-030). It deletes `index-labels` at the document level and
      under each `indexes:` entry, then compares the fixture's parsed map and
      body with the twin's. Give it an optional expected-key argument, and
      pass `separator xref-separator` at the M58-AC2 call (near line 25367).
      Each deleted map's keys must equal that set exactly.
      Plants: a blank line inside a copy's map (passes), a third key in a copy
      of the separators fixture (fails and names the key). Keep the existing
      drift plants.
- [x] T5: KI186. In `m57_tex_ledger` (near line 25163), filter only the two
      header lines of the unified diff, by position. Add a plant over a
      synthetic `.tex` pair whose differing line is `--`.
- [x] T6: KI190, KI191, KI193. Route `entry_separators` (`tests/htmlindex.py`
      near line 589) through the `own_nodes` walk. Add a self-test that wraps
      each entry line of a copy of a captured index in `<p>` and compares the
      separators. In `main()` of `tests/sepcheck.py`, catch the manifest
      `ValueError` into a `FAIL:` line and exit 1. Plant a manifest with an
      unknown slot name and one with a space for a tab, and reword the ok and
      FAIL lines. Run the reader's
      probes under the oldest and newest Python in reach (LESSONS, M082).
- [x] T7: Strike KI180, KI181, KI182, KI186, KI190, KI191, KI192, KI193,
      KI194 and KI195 from `cairn/DESIGN.md` per D-013. No ROADMAP row names
      any of them.
- [x] T8: Run `tests/run-tests.sh --self-test` sequentially and read it clean.
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
- 2026-09-11: T3 checkpoint: kept set derived from the three fixtures' front matter (labels declares `main` and `authors`, separators no `indexes:`). Eighteen controls deleted (14 M59, 2 M56-AC5, 2 M58-AC4). The four document-level controls stay (M56-AC5 unknown key and empty `see`, M59 invisible `see-also` and list `symbols`), and the M59 silence count over the clash log stays because that fixture declares `fossils`. Two clash-log plants added. Isolated probe: kept controls and counts green, both plants red. Suite run pending.
- 2026-09-11: T4 checkpoint: `derive_labels_twin` parses front matter with PyYAML and compares body text, with an optional exact key set passed at M58-AC2. Isolated probe: both real derivations green, the three drift plants and the third-key plant red for their stated reasons, the blank-line copy green where the old walker on `main` fails it. Suite run pending.
- 2026-09-11: T5 checkpoint: `m57_tex_ledger` drops the diff's first two lines by position. Plant: a synthetic pair differing in `--` against `++` fails with 2 unclassified lines, where the filter on `main` reports the pair identical. The four real ledgers classify the same 44, 30, 9 and 9 lines as before. Suite run pending.
- 2026-09-11: T6 checkpoint: `entry_separators` walks through non-list wrappers as `own_nodes` does. `sepcheck.py` reports an unreadable or malformed manifest as one FAIL line with exit 1, rejects whitespace in a slot and a non-ASCII-digit depth, and its ok line says "whitespace character". Plants: unknown slot `S9`, a space between two slots, a space after a depth, and `<p>`-wrapped copies of the separators and resolving-xref pages. Isolated probe under Python 3.9.6 and 3.14.7: M58-AC1/AC3/AC4/AC7 green, all plants as stated. With `main`'s modules the wrapped copy loses Azurite's separators and the S9 manifest prints a traceback. Suite run pending.
- 2026-09-11: T7 done: KI180, KI181, KI182, KI186 and KI190-KI195 deleted from `cairn/DESIGN.md`. A grep finds none of the ten labels there, no ROADMAP row names them, and `cairn_validate` passes.
- 2026-09-11: T8 done: `tests/run-tests.sh --self-test` at 5b06ed5, run alone with no edits in flight, exit 0, "All checks passed (1469 checks)", no FAIL line. Every new check and plant from T1-T6 printed its ok line. T1-T6 ticked on this run.
- claim audit: not owed — internal tier
- 2026-09-11: status set to review.

## Decisions

## Review

Evidence run: `tests/run-tests.sh --self-test` at c291187 on 2026-09-11, alone and with no edits in flight. It exited 0 with "All checks passed (1469 checks)", no `FAIL` line and no traceback, in 10m45s. The branch already contains `origin/main`, so no sync was needed.

- AC1: `check_tex_identical` in `tests/run-tests.sh` is the one `.tex` comparison. M56-AC6 and M58-AC6 call it, and both printed their ok lines. The M56 plant calls it through `m56_planted` on a twin `.tex` with one extra line. That plant printed its ok line, matched against the function's own "differs from" FAIL text.
- AC2: `check_extension_warning_count` holds `index-labels-html.log` and `index-labels-latex.log` at 0, and the run printed "M092: the fixture declaring all three words draws no message". Two plants append one extension warning to a copy of each log. Both printed their ok lines, matched on "expected 0 warning(s)".
- AC3: A grep of the M59 block and the M56-AC5 and M58-AC4 loops lists every zero-count check left. The M56-AC5 and M59-AC1/AC2 controls read the unknown-key, empty `see`, invisible `see-also` and list `symbols` messages, all four worded "in this document's metadata". The M59-AC4 silence count names `fossils`, which `examples/index-labels-clash.qmd` declares. The M58-AC4 loop holds no control, and the M59 block holds no other zero check. The front matter of the four fixtures read shows `index-labels.qmd` declaring only `main` and `authors`. The two clash-log plants printed their ok lines, matched on "expected 0 occurrence" and "expected 1 warning(s)".
- AC4: The suite printed ok lines for both real derivations, the body-drift and byte-copy plants, the blank-line copy passing, and the third-key plant. That plant matched on 'sets the key "see"'. A scratch probe of the extracted function names the part for each drift plant: the appended sentence gives "the body differs", and the byte copy gives "the front matter differs". The same probe shows `main`'s line walker failing the blank-line copy that the new function passes.
- AC5: `m57_tex_ledger` now drops the first two lines of the unified diff by position. The M57 plant over a synthetic pair differing in `--` against `++` printed its ok line, matched on "2 differing line(s) of". The ledger counted both lines and did not report the pair identical. The four real ledgers stayed green in the same run.
- AC6: The loose-list probe printed ok for two captured pages with every entry line wrapped in `<p>`. The separators page gave the same 7 separators over 4 entry lines, and `resolving-xref.html` gave the same 6 over 10. `m092_manifest_refused` asserts exit 1, no traceback, exactly one `FAIL:` line and the named cause. It printed ok for the unknown slot `S9`, a space between two slots, and a space after a depth. In `tests/sepcheck.py`, the ok line (seen in this run's M58 lines) and the spacing FAIL line both say "exactly one whitespace character".
- AC7: The evidence run above is the profile's verify command `tests/run-tests.sh --self-test`. It exited 0 with 1469 checks passed and no `FAIL` line.

Consistency gate: `cairn_validate.py` passed with exit 0 and all 16 checks PASS. No IP or GP principle changed, so `cairn_impact` was skipped. The `generic` profile names no toolchain checks.

Independent review, as a three-lens fan-out because the diff touches scripts. The prior-review lens found no prior-review evidence contradicted, and the GitHub comment probe came back empty. No finding shows a criterion failing, so none meets the return floor. Proposed dispositions go to the approval gate.

- R1 (diff-bug): `tests/sepcheck.py` does not catch a space in place of the tab between the term and the first slot. The slot joins the term and the FAIL line blames the render. Proposed: follow-up.
- R2 (diff-bug): the M56 T4 self-test loop still counts the `notes` and `sources` messages at 0 over `index-labels-html.log`, which cannot carry them. Outside AC3's named loops. Proposed: follow-up.
- R3 (diff-bug): the missing-key and not-a-map branches of `derive_labels_twin`'s key check have no plant. Proposed: follow-up.
- R4 (diff-bug, with blame-history B1): the parsed comparison is blind to YAML 1.1 readings such as `yes` for `true`, and to a duplicate key. The plan recorded only quoting, comments and key order. Proposed: Known issues entry, since the plan chose this trade.
- R5 (diff-bug): `check_tex_identical`'s exit-2 branch has no plant, and a failed redirect reports as "differs". Proposed: follow-up.
- R6 (diff-bug): `read_manifest` now refuses a trailing space and a space-padded depth that `main` accepted. No suite manifest writes either. Proposed: reject, stricter input is the intent.
- R7 (diff-bug): the `_line_pieces` docstring says its descent is `own_nodes`', but text inside a non-part element now joins the separator run. No real capture has such an element. Proposed: fix now, docstring wording.
- R8 (diff-bug): the `[ -s ... ] || fail` guards after two Python heredocs never run, because `set -e` stops first. The Python FAIL line still prints. Proposed: reject, no message is lost.
- R9 (diff-bug): the M58-AC4 comment credits the M56 and M59 document-level controls. The checks that hold a report-everything filter are the new zero totals and M58-AC1's silence count. Proposed: fix now, comment wording.
- R10 (diff-bug): the `tests/sepcheck.py` docstring does not state the new depth and slot rules. Proposed: fix now.
