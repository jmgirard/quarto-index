# M24: Every check reads the copy, never the working tree

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** —

## Goal

Every acceptance check reads an artifact captured into `$WORK` by the render
that produced it, so no check's domain can be filled — or emptied — by a file
an earlier run left under `examples/`.

## Scope

Surface tier: **internal** — the deliverable is the repo's acceptance suite,
dev tooling over repo-internal render artifacts, with no external consumer of
the extension relying on it.

**In:** A capture helper invoked at each of the 85 `quarto render` sites,
copying that render's artifacts into `$WORK`; the 223 read sites over 91
distinct `examples/` artifacts rewritten to read the copy; a pre-render clean
step so every run starts from the state a fresh checkout is in; the residue
sweeps re-pointed at the captured set and made to iterate it rather than a
fixed name list. Each check's promise is unchanged — only the file it reads
moves — so this is repair under D-090's Untouched clause, not the
checker-regress shape D-004 refused.

**Out:**
- The five zero-expectation controls resting on a bare `(W)` pattern → M25.
- Disposition of the source-shape scans (twelve-scan pin, four FIRST-match
  scans, `warn-distinct`'s `:format(` blindness, the one-of-nine
  moved-definition probe) → M25.
- `examples/.gitignore` duplicating the root ignore → stays on the M13 review
  follow-ups candidate row.
- Every other item on the acceptance-suite-hardening candidate row (brace-aware
  `\index` scanner, BSD-sed portability, `]{.index` undercount, `include_text`
  guard, `pdfindex.py`'s folio-band heuristic, the two joined-`warn()` readers,
  `m23probes.py`'s presence-only `_ind` test, the range fixtures' implicit
  page-1 dependence) → stays on that row.

## Acceptance criteria

- [ ] AC1: Over the file set `git ls-files tests` enumerates, every line
      matching `examples/` followed by a token ending in `.html`, `.tex`,
      `.md`, `.pdf`, `.aux`, `.idx`, `.ilg`, `.ind` or `.log` — glob and
      shell-variable forms included — is either a `quarto render` command line
      or a line inside the capture helper's body. That grep over that file set
      is the procedure enumerating the domain, and the suite runs it on itself.
- [ ] AC2: After the run's pre-render clean step, `git clean -Xdn examples/`
      prints nothing.
- [ ] AC3: Over the same `git ls-files tests` set, every line matching
      `quarto render` is immediately followed by a call to the capture helper.
- [ ] AC4: The `data-qi-pending` residue sweep (`tests/run-tests.sh:3600`) and
      the M12 structural-residue check read the captured set under `$WORK` and
      iterate that set, rather than naming a fixed list of artifacts.
- [ ] AC5: `tests/run-tests.sh --self-test` exits 0 and prints its
      "All checks passed" line on a tree with no untracked `examples/`
      artifacts present before the run.

## Coverage

- AC1 → T2, T3, T4, T5, T7
- AC2 → T1, T7
- AC3 → T2, T7
- AC4 → T6
- AC5 → T8

## Tasks

- [ ] T1: Add the pre-render clean step near `tests/run-tests.sh:50` (beside
      the existing `rm -rf "$WORK"`), exempted in `--fixture-check` and
      `--plant-wrapper-defect` mode like the `$WORK` wipe already is. Assert
      `git clean -Xdn examples/` empty immediately after it.
- [ ] T2: Add the capture helper beside `run_scan` (`tests/run-tests.sh:110`):
      given a render's source path and format, copy the artifacts that render
      produced into a per-render directory under `$WORK`. One definition, the
      way `run_scan` is the one place an invocation is written down.
- [ ] T3: Rewrite the single-document `.tex`/`.md` read sites to the captured
      copy. Start at the AC3 control-token block
      (`tests/run-tests.sh:1615-1648`), which is the clean-checkout failure.
- [ ] T4: Rewrite the `.html` read sites, including `tests/htmlindex.py`'s
      callers, to the captured copy.
- [ ] T5: Rewrite the LaTeX aux-family read sites (`.aux`, `.idx`, `.ilg`,
      `.ind`, `.log`), including the M22 block at `tests/run-tests.sh:8653` and
      the M20 principal-registry reads.
- [ ] T6: Re-point the two residue sweeps at the captured set and make each
      iterate it. Prove each discriminating by planting the residue into a
      copy of every captured HTML artifact in turn and requiring failure; wire
      that into `tests/plantdefect.py`'s self-test.
- [ ] T7: Add the AC1 self-grep and the AC3 pairing check to the suite, over
      `git ls-files tests`.
- [ ] T8: Full `tests/run-tests.sh --self-test` from a cleaned tree; capture
      evidence for each criterion.

## Work log

- 2026-08-23: created by /milestone-plan. Promoted from the acceptance-suite-hardening candidate row; the row keeps its remaining items.
- 2026-08-23: plan gate ran the REDUCED criteria audit (internal tier) and it returned five findings, all fixed before the criteria were written: AC1's file set was a three-glob hand list (now `git ls-files tests`); AC1's pattern could not match the `examples/*.html` and `examples/$f.tex` forms the suite actually uses (now widened); AC2 named no enumerating procedure (now `git clean -Xdn`); AC3 quantified over 85 renders' emitted artifact sets, a per-rendering enumeration barred at internal tier (now the syntactic pairing a grep settles); AC4's planted-residue clause bound a plant matrix rather than the sweeps (moved to T6 and to review evidence).
- 2026-08-23: plan gate chose capturing artifacts into `$WORK` over pinning the suite's render ORDER so each read follows its producing render, because an order pin is a fresh invariant no procedure enumerates and it leaves the clean-checkout failure standing; falsified by evidence that Quarto's output location for some fixture cannot be captured at its render.
