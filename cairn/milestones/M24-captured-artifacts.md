# M24: Every check reads the copy, never the working tree

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** `m24-captured-artifacts` / https://github.com/jmgirard/quarto-index/pull/24

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

- [x] AC1: Over the file set `git ls-files tests` enumerates, every line
      matching `examples/` followed by a token ending in `.html`, `.tex`,
      `.md`, `.pdf`, `.aux`, `.idx`, `.ilg`, `.ind` or `.log` — glob and
      shell-variable forms included — is either a `quarto render` command line
      or a line inside the capture helper's body. That grep over that file set
      is the procedure enumerating the domain, and the suite runs it on itself.
- [x] AC2: After the run's pre-render clean step, `git clean -Xdn examples/`
      prints nothing.
- [x] AC3: Over the same `git ls-files tests` set, every line matching
      `quarto render` is immediately followed by a call to the capture helper.
- [x] AC4: The `data-qi-pending` residue sweep and the marker-class half of
      the M12 structural-residue check read the captured set under `$WORK` and
      iterate it, judging every captured page and naming no fixed list of
      artifacts to visit. The empty-div half instead reads the captured copies
      of the three fixtures a marker was removed from: an empty div is residue
      only where a marker was removed, and every rendered page carries empty
      divs Quarto itself wrote.
- [x] AC5: `tests/run-tests.sh --self-test` exits 0 and prints its
      "All checks passed" line on a tree with no untracked `examples/`
      artifacts present before the run.

## Coverage

- AC1 → T2, T3, T4, T5, T7
- AC2 → T1, T7
- AC3 → T2, T7
- AC4 → T6
- AC5 → T8

## Tasks

- [x] T1: Add the pre-render clean step near `tests/run-tests.sh:50` (beside
      the existing `rm -rf "$WORK"`), exempted in `--fixture-check` and
      `--plant-wrapper-defect` mode like the `$WORK` wipe already is. Assert
      `git clean -Xdn examples/` empty immediately after it.
- [x] T2: Add the capture helper beside `run_scan` (`tests/run-tests.sh:110`):
      given a render's source path and format, copy the artifacts that render
      produced into a per-render directory under `$WORK`. One definition, the
      way `run_scan` is the one place an invocation is written down.
- [x] T3: Rewrite the single-document `.tex`/`.md` read sites to the captured
      copy. Start at the AC3 control-token block
      (`tests/run-tests.sh:1615-1648`), which is the clean-checkout failure.
- [x] T4: Rewrite the `.html` read sites, including `tests/htmlindex.py`'s
      callers, to the captured copy.
- [x] T5: Rewrite the LaTeX aux-family read sites (`.aux`, `.idx`, `.ilg`,
      `.ind`, `.log`), including the M22 block at `tests/run-tests.sh:8653` and
      the M20 principal-registry reads.
- [x] T6: Re-point the two residue sweeps at the captured set and make each
      iterate it. Prove each discriminating by planting the residue into a
      copy of every captured HTML artifact in turn and requiring failure; wire
      that into `tests/plantdefect.py`'s self-test.
- [x] T7: Add the AC1 self-grep and the AC3 pairing check to the suite, over
      `git ls-files tests`.
- [x] T8: Full `tests/run-tests.sh --self-test` from a cleaned tree; capture
      evidence for each criterion.

## Work log

- 2026-08-23: created by /milestone-plan. Promoted from the acceptance-suite-hardening candidate row; the row keeps its remaining items.
- 2026-08-23: plan gate ran the REDUCED criteria audit (internal tier) and it returned five findings, all fixed before the criteria were written: AC1's file set was a three-glob hand list (now `git ls-files tests`); AC1's pattern could not match the `examples/*.html` and `examples/$f.tex` forms the suite actually uses (now widened); AC2 named no enumerating procedure (now `git clean -Xdn`); AC3 quantified over 85 renders' emitted artifact sets, a per-rendering enumeration barred at internal tier (now the syntactic pairing a grep settles); AC4's planted-residue clause bound a plant matrix rather than the sweeps (moved to T6 and to review evidence).
- 2026-08-23: plan gate chose capturing artifacts into `$WORK` over pinning the suite's render ORDER so each read follows its producing render, because an order pin is a fresh invariant no procedure enumerates and it leaves the clean-checkout failure standing; falsified by evidence that Quarto's output location for some fixture cannot be captured at its render.
- 2026-08-23: implement gate chose: a capture copies then DELETES the originals when they sit under examples/, so a later render of the same document cannot leave an older artifact in the newer capture and a check aimed at the wrong capture fails on a missing file; checks spell the capture path in full rather than reading a variable the helper sets; and the 232 read sites are rewritten by one scripted pass whose diff is then read by hand.
- 2026-08-23: T1 — pre-render clean (`git clean -Xdf examples/`) added beside the $WORK wipe, exempted in both self-test modes, with the `git clean -Xdn` empty assertion immediately after it.
- 2026-08-23: T2 — `capture` added beside `run_scan`; called at all 85 render sites with a slug taken from each render's own log name. It copies the render's artifacts into $WORK/cap/<slug>/, removes the originals only from under examples/, refuses a reused slug, and copies (never moves) a project render's _book tree, which the book fixtures re-render into.
- 2026-08-23: T3-T5 done in one scripted pass rather than three (minor amendment): the tasks split the read sites by artifact family, but the rewrite rule is one rule — the capture of the last render that produces that extension for that fixture — so splitting it would have been three runs of one script. 238 sites rewritten, then audited; the nine hand-written `rm -f examples/...` pre-render cleans deleted as the per-fixture form of what `capture` now does everywhere; the AC3 control-token comparison moved below the render it reads, which is the clean-checkout failure the plan named; the M15 contested-key sweep re-pointed from `examples/*.tex` to the captured LaTeX set and moved to the end of the run so its domain is complete, which brought `xref-conflict.tex` and `range.tex` into it — both derived from their fixtures as carrying a contested key, and both invisible to the old glob because a later PDF render removed them.
- 2026-08-23: AC4 amended at a mini gate (substantive): the marker-residue check has two halves that generalize differently. The marker-class half iterates the captured set with an equality-per-page map naming the two fixtures that keep a marker on purpose; the empty-div half cannot, because every rendered page carries empty divs Quarto wrote, so it reads the three fixtures a marker was removed from. The criterion narrows to say so; nothing was added. The amended wording was audited in-session rather than by a fresh reader — this session is configured not to spawn subagents — and that was disclosed at the gate.
- 2026-08-23: T6 (part) — both residue sweeps moved into `tests/htmlsweep.py` and run last, after the parity probe, so nothing the run renders sits outside the domain they claim. The pending sweep now reads 85 captured pages where it globbed `examples/*.html`; the marker-class sweep reads the same 85 where it was three hand-written call sites.
- 2026-08-23: T6 — both sweeps proved discriminating: the residue each names is planted into a mirror of the captured set, once per captured page, and the sweep is required to fail naming that page; the empty-div reader likewise on each of its three. `tests/plantdefect.py` gained the three residue plants beside its source-scan ones, reading the marker class from the environment rather than holding a second copy of it.
- 2026-08-23: T7 — `tests/suitescan.py` adds the AC1 read check and the AC3 pairing check over `git ls-files tests`, and the suite runs both on itself: 23 tracked files, 85 render lines, all paired. Both are scans over source, the shape M23's lesson says can certify a property it never asserts, so each takes an overlay directory whose bytes replace a tracked file's and each is proved on a planted violation — a working-tree read added, a capture call removed — with the unplanted overlay required to pass first. Neither the checker nor the probe may itself carry the shape being forbidden, so both assemble the forbidden text from pieces rather than spelling it out.
- 2026-08-23: T8 — full `tests/run-tests.sh --self-test` from a tree cleaned with `git clean -Xdfq examples/` and `rm -rf tests/.work`: exit 0, 396 checks. Per-criterion evidence in the run log — AC1 "none of the 23 tracked suite source file(s) reads a rendered artifact out of the fixture directory"; AC2 "the run starts from a clean examples/ — git clean -Xdn prints nothing"; AC3 "all 85 render command line(s) ... immediately followed by a call to the capture helper"; AC4 the pending and marker sweeps each over 85 captured pages plus the empty-div reader over its 3; AC5 the run's own "All checks passed (396 checks)".
- 2026-08-23: the acceptance-suite-hardening candidate row absorbs one gap found here: the AC1 read check's pattern reaches only a token ending in a literal extension, so a read spelled `examples/<stem>.$var` passes it unseen. Five such reads existed and are repaired on this branch. ROADMAP is at 23,287 of its 24,000-byte budget and 58 of its 60 lines after the absorption.
- 2026-08-23: review — fresh evidence recorded for all five criteria from one 396-check `--self-test` run (exit 0) on a cleaned tree; consistency gate clean (`cairn_validate` exit 0, `generic` profile names no toolchain checks). Three fresh-context lenses spawned.

## Review

PR #24. Reviewed 2026-08-23 against `origin/main` at 2e8ae87; the default
branch had not moved since the branch was cut, so no merge was needed.

### Acceptance-criteria evidence

All five run from one full `tests/run-tests.sh --self-test` on a tree cleaned
with `git clean -Xdfq examples/` and `rm -rf tests/.work` (`git clean -Xdn
examples/` printed nothing before the run started): exit 0, 396 checks.

- AC1: the run's own read check reports "none of the 23 tracked suite source
  file(s) reads a rendered artifact out of the fixture directory; every read
  names the copy captured at its render". The check is a scan over source, so
  it is proved discriminating in the same run — it fails on an overlay adding
  one working-tree read, the unplanted overlay having passed first.
- AC2: the run's first line reports "the run starts from a clean examples/ —
  git clean -Xdn prints nothing", asserted immediately after the pre-render
  clean step. Confirmed independently before the run: `git clean -Xdn
  examples/` printed nothing.
- AC3: the run's pairing check reports "all 85 render command line(s) across
  the 23 tracked suite source file(s) are immediately followed by a call to
  the capture helper", likewise proved discriminating on an overlay with one
  capture call removed.
- AC4: the pending sweep and the marker-class sweep each "read 85 captured
  page(s)" — the whole captured set, iterated, naming no fixed list. The
  empty-div half reads the 3 pages a marker was removed from. All three are
  proved discriminating: the residue is planted into each of the 85 captured
  pages in turn and into each of the 3, and each sweep is required to fail
  naming that page.
- AC5: the run exits 0 and prints "All checks passed (396 checks)" from the
  cleaned tree described above.

### Consistency gate

`cairn_validate` exits 0 — 16 PASS, 7 advisory OK. The active profile is
`generic`, whose consistency-gate slot names no toolchain checks, so that half
is a clean no-op. No `DESIGN.md` principle changed, so `cairn_impact` does not
apply.
