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
      matching the literal `examples/` followed by a token ending in `.html`,
      `.tex`, `.md`, `.pdf`, `.aux`, `.idx`, `.ilg`, `.ind` or `.log` — glob
      and shell-variable-in-the-stem forms included — is either a `quarto
      render` command line or a line inside the capture helper's body. That
      grep over that file set is the procedure enumerating the domain, and the
      suite runs it on itself. A read that spells the fixture directory itself
      through a shell variable is outside what that grep settles, and outside
      what this criterion claims.
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
- 2026-08-23: amendment return: AC1 — "every line matching `examples/` followed by a token ending in `.html`, `.tex`, `.md`, `.pdf`, `.aux`, `.idx`, `.ilg`, `.ind` or `.log` — glob and shell-variable forms included — is either a `quarto render` command line or a line inside the capture helper's body". Eleven book-family reads spell the fixture directory through `$BOOK_OUT` (= `examples/book/_book`) and so fall outside that domain; AC1 passes while the Goal is unmet for the book fixtures. Review stopped before the merge gate; D2-D16 and B1 logged in the Review section for triage at re-review.
- 2026-08-23: AC1 amended at a mini gate (substantive), executing that return: the criterion now promises only what its grep settles — lines spelling the fixture directory literally — and states that a read reaching that directory through a shell variable is outside the claim. Narrowing was recommended and taken; widening the pattern to one further spelling was offered as the non-recommended alternative and declined. The amended wording was audited in-session against the reduced audit's bounded-promise, proportionality and instrument questions rather than by a fresh reader — this session is configured not to spawn subagents — and that was disclosed at the gate. The amendment-return track stays at 1.
- 2026-08-23: chosen at the same gate alongside the amendment, and code work rather than a criteria change: the 14 book-family reads spelling the fixture directory through `$BOOK_OUT`, `$ORDER_OUT` or `$NOMARKER_DIR` now read the captures already taken at their renders (book-html, book-html2, book-ghost, book-nocontext, book-nomarker, book-pdf, book-order-2), so the Goal holds for the book fixtures although AC1's grep does not reach them. The check's blindness to a variable-spelled fixture directory is absorbed into the acceptance-suite-hardening candidate row beside the `.$var` gap already there; ROADMAP is at 23,488 of its 24,000-byte budget and 58 of its 60 lines.
- 2026-08-23: re-review round 2 — fresh evidence for all five criteria from one 396-check `--self-test` on a cleaned tree (exit 0), AC1 for the first time against its amended wording; consistency gate clean. Round 1's deferred findings triaged: D1 repaired by the amendment, D4, D6, D10, D13 and B1 fixed on the branch, eight homed on the acceptance-suite-hardening row, D12 and D16 rejected. No finding meets the return floor. Verifying re-run green: 396 checks, exit 0, the emission sweep now reading 47 captured LaTeX artifacts. All five criteria ticked against round-2 evidence.
- 2026-08-23: merge gate held at the maintainer's decision to run the fresh-context fan-out before merging. Three lenses, distinct evidence bases: prior-review record clean, blame-history one item settled by the runs already taken plus four confirmations, diff-bug ten findings. R3 (three more comments of D4's class) fixed on the branch; R6 rejected in part; the other nine homed on the acceptance-suite-hardening row, which was compressed to hold them inside the 24,000-byte budget (23,800). No return-floor finding.

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

### Fresh-context review — findings

Three lenses, distinct evidence bases. [S] prior-PR-comments: no
prior-review regressions; the GitHub inline-comment probe returned empty, so
`milestones/archive/`'s `## Review` sections were the whole surface, and the
four past lessons bearing on this diff (the `set -e` wrapper guard, reading
constants from source, proving a source scan by a planted violation, sweep
ordering) are each respected. [S] blame-history: one finding, B1 below; its
other four items verified the riskiest changes and found no defect. [O]
diff-bug: sixteen, D1-D16 below, ranked as the lens ranked them.

Findings are recorded here in full. Triage of D2-D16 and B1 is deferred to
the re-review gate, since D1 returns the milestone before a gate is reached.

- D1 (verified): the book half of the suite still reads the working tree.
  `BOOK_OUT="$BOOK_DIR/_book"` (= `examples/book/_book`) backs ten
  un-rewritten reads, plus `$ORDER_OUT/index.html` and `$NOMARKER_DIR/_book`.
  AC1's scan cannot see them because they spell the fixture directory through
  a variable, so the run prints its "none of the 23 tracked suite source
  file(s) reads a rendered artifact out of the fixture directory" line while
  eleven such reads stand, and the twelve `capture --project` calls are
  write-only. Amendment return; see below.
- D2 (verified): the implement gate's safety argument — "a check aimed at the
  wrong capture fails on a missing file" — is false where two captures hold
  the same stem. `demo.qmd` yields `demo-latex/demo.tex` and
  `demo-beamer/demo.tex`; `marker.qmd` yields three `marker.tex`. A read
  aimed at the wrong one reads another render's output with nothing to trip.
  Neither AC1 nor AC3 asserts the read-to-render correspondence.
- D3 (verified): the M24-AC2 check sits at script top level, outside
  `run_all_checks`, so its `pass` reaches neither `CHECK_COUNT` nor the
  tee'd run log. AC2's own promise still holds — the assertion runs and was
  confirmed independently — but the T8 work-log claim that its evidence is
  "in the run log" is wrong.
- D4: the scripted rewrite ran over comments and inverted `capture`'s own
  header comment, which now says a check reading a capture path "is
  therefore asserting nothing about the render it sits under". Two more
  comments became false (a PDF render cannot consume or remove a file under
  `$WORK/cap`), and about sixteen manifest headers carry quoted
  shell-variable text mid-prose.
- D5: the AC1 scan exempts only render lines and the helper body, so no
  tracked suite file can name a fixture artifact path in prose — the root
  cause of D4.
- D6: the M15 contested-key sweep globs one directory deep, so `.tex` files
  inside a captured `_book` tree are outside a domain its pass line calls
  "none of the N captured LaTeX artifacts".
- D7: five book captures copy a whole `_book` tree most of whose pages an
  earlier render wrote, relocating staleness from `examples/` into `$WORK`.
- D8: the sweep self-test is O(n^2) in captured pages (~14,000 HTML parses).
- D9: `capture` captures by stem across all extensions rather than by what
  the render produced; `fmt` only names the slug.
- D10: `ext` is not declared `local` in `capture`.
- D11: `check_pairs` matches `quarto render` in prose, so a docstring
  mentioning it becomes a hard run failure.
- D12: the AC3 planted-defect proof verifies a capture line was deleted, not
  that the deletion broke a pairing.
- D13: the ROADMAP row's "Remainder:" sentence still lists three items its
  own NARROWED preamble says M24 absorbs.
- D14: the suite now hard-depends on git (`git clean`, `git ls-files`), a
  precondition recorded nowhere.
- D15: the pre-render clean silently deletes ignored-but-wanted developer
  files parked under `examples/`.
- D16: `KEPT_MARKERS` is a written-down list in a module arguing against
  them; drift fails loudly, but a fixture legitimately keeping a marker must
  be remembered here.
- B1: the ROADMAP candidate row still records M20 review R2-F13 (the M15
  emission sweep's M20 rows inert on a clean tree) as open, which moving the
  sweep to the end of the run incidentally fixed. Tracking divergence, not a
  code defect.

### Disposition

**Amendment return on AC1.** D1 falsifies the milestone's Goal only outside
the domain AC1's procedure quantifies over: AC1 asks after lines matching
`examples/`, and the eleven standing working-tree reads spell that directory
through a variable, so AC1 passes as written while the property it exists to
fence does not hold. That is evidence about the promise, not about the work,
so it routes to the gated criterion-amendment protocol
(`/milestone-implement` step 6) and re-review, with the amendment the only
work convened. AC1's tick is removed: its recorded evidence was taken against
wording that is being amended.

Returns on this milestone: amendment-return track 1 (this one); defect-return
track 0.

### Round 2 (2026-08-23) — after the AC1 amendment

Re-reviewed against `origin/main` at 2e8ae87, which has still not moved since
the branch was cut, so no merge was needed. PR #24.

#### Acceptance-criteria evidence

All five re-run from one full `tests/run-tests.sh --self-test` on a tree
cleaned with `git clean -Xdfq examples/` and `rm -rf tests/.work`: exit 0,
396 checks. Re-run in full after the fix-now work below: exit 0, 396 checks
again, the M15 emission sweep reading 47 captured LaTeX artifacts where it
read 45. One intervening run died at M20 T9 on a `Segmentation fault: 11` in
Quarto's own Deno binary during a render; it did not reproduce, no fix-now
edit can reach a render, and the same check passed in the runs either side of
it.

- AC1, first evidence against the amended wording: the run's read check
  reports "none of the 23 tracked suite source file(s) reads a rendered
  artifact out of the fixture directory; every read names the copy captured at
  its render", and is proved discriminating in the same run — it fails on an
  overlay adding one working-tree read, the unplanted overlay having passed
  first. The amendment narrows AC1 to what that grep settles, so the repair it
  convened is verified separately from the check that cannot see it:
  `grep -nE '\$(BOOK_OUT|ORDER_OUT)/'` over the suite returns nothing, so no
  read reaches the fixture directory through those variables either — both now
  survive only as `rm -rf` targets and render working directories. Each of the
  14 rewritten reads names the capture of the render it sits under, checked by
  hand: `book-html2`, `book-ghost` and `book-order-2` each read their own
  render's tree, and the two `last.qmd`-only renders read only `last.html`, so
  the partial-render staleness D7 names does not reach them.
- AC2: the run's first line reports "the run starts from a clean examples/ —
  git clean -Xdn prints nothing", asserted immediately after the pre-render
  clean. Confirmed independently before the run: `git clean -Xdn examples/`
  printed nothing.
- AC3: the pairing check reports "all 85 render command line(s) across the 23
  tracked suite source file(s) are immediately followed by a call to the
  capture helper", likewise proved discriminating on an overlay with one
  capture call removed.
- AC4: the pending sweep and the marker-class sweep each "read 85 captured
  page(s)"; the empty-div half reads the 3 pages a marker was removed from.
  All three proved discriminating — the residue planted into each of the 85
  pages in turn and into each of the 3, each sweep required to fail naming
  that page.
- AC5: the run exits 0 and prints "All checks passed" from the cleaned tree
  described above.

#### Consistency gate

`cairn_validate` exits 0 — 16 PASS, 7 advisory OK. The active profile is
`generic`, whose consistency-gate slot names no toolchain checks, so that half
is a clean no-op. No `DESIGN.md` principle changed, so `cairn_impact` does not
apply.

#### Review method, disclosed

This round's reading of the diff was done in session rather than by
fresh-context lenses: this session is configured not to spawn subagents, the
same constraint disclosed at both amendment gates. Round 1's three-lens
fan-out covered the whole diff and its findings are triaged below; the only
code this round adds over what that fan-out read is the 28-line read repair in
f0cb1d3, read here by hand.

#### Triage — round 1's deferred findings

Fixed on the branch this round:

- D1 — repaired by the amendment commit and verified under AC1 above.
- D4 — confirmed, and narrower than reported: three comments the scripted
  rewrite made false, not sixteen. `capture`'s own header said a check reading
  a *capture* path "is therefore asserting nothing about the render it sits
  under", inverting the helper's rationale; two more claimed a later render
  "consumes" or "removes" a file that now lives under `$WORK`. All three
  rewritten to state what is true, without spelling a fixture artifact path,
  which the AC1 check forbids in prose. The ~17 manifest headers that quote a
  capture path mid-sentence are accurate and left alone.
- D6 — confirmed with an instance: `parity-tree-book-latex/_book/book-latex/`
  and `parity-inst-book-latex/_book/book-latex/` each hold an
  `Index-Book-Fixture.tex` two levels down, outside the M15 emission sweep's
  one-deep glob, while its pass line says "none of the N captured LaTeX
  artifacts carries anything else". Neither file carries either contested-key
  shape, so no verdict was wrong; the claim was wider than the domain. The
  glob is now recursive — the sweep reads 47 artifacts where it read 45, and
  passes.
- D10 — confirmed: `ext` was not declared `local` in `capture`. Now local. No
  other site reads `$ext`, so the leak was unobserved.
- D13 — confirmed: the acceptance-suite-hardening row's `Remainder:` listed
  three items its own NARROWED preamble says M24 absorbs, and two more
  clauses later in the row named the M12 residue-check pair and the M23
  `data-qi-pending` empty domain, likewise absorbed. All five struck.
- B1 — confirmed: the M15 emission sweep now runs at the end of the run with
  both M20 fixtures required present in `ALLOWED`, so M20 review R2-F13 is
  closed. Its clause struck from the row.

Follow-up, homed on the acceptance-suite-hardening candidate row:

- D2 — nothing asserts which capture a read belongs to, and two captures can
  hold one stem, so a read aimed at the wrong slug reads another render's
  output with nothing to trip. Neither AC1 nor AC3 claims the correspondence.
- D3 — the M24-AC2 assertion sits at script top level, outside
  `run_all_checks`, so its `pass` reaches neither `CHECK_COUNT` nor the tee'd
  run log. AC2's promise still holds — the assertion runs, fails loudly, and
  was confirmed independently — but the T8 work-log line and round 1's AC2
  evidence both said that evidence is in the run log, and it is not. Corrected
  here rather than in those records (IP4).
- D5 with D11 — the read check exempts any line matching `quarto render`, and
  the pairing check treats that phrase in prose as a render needing a capture
  call, so a comment can silence the first or hard-fail the second. Nothing
  today does either.
- D7 — five book captures copy a whole `_book` tree most of whose pages an
  earlier render wrote, relocating staleness from `examples/` into `$WORK`.
  No read this branch adds is affected (see AC1 above).
- D8 — the sweep self-test is quadratic in captured pages, ~14,000 HTML
  parses, and is most of the run's wall time. The per-page plant is what T6
  planned; the cost is not.
- D9 — `capture` copies every extension for the render's stem rather than what
  the render produced, and `fmt` only names the slug.
- D14 with D15 — the suite now hard-depends on git and deletes any ignored
  file parked under `examples/`; neither is recorded as a precondition.

Rejected:

- D12 — refuted against the implementation. The AC3 planted-defect proof does
  assert the pairing failure identity: after deleting a capture call it greps
  the output for "not followed by a call to the capture", not merely for a
  non-zero exit.
- D16 — `KEPT_MARKERS` is a written-down map, but drift fails loudly in both
  directions (a page that gains the class and a listed page that goes
  missing), which is the equality pin the module's own docstring argues for.
  Intentional.

#### Returns

Amendment-return track 1 (round 1's, executed). Defect-return track 0: no
finding this round demonstrates an acceptance criterion failing inside its
named procedure's domain, and none is a load-bearing defect in what the suite
does for its users.

#### Fresh-context review — round 2's fan-out

Held at the merge gate on the maintainer's decision: the round-2 reading had
been done in session, and the maintainer chose the fan-out before merging. All
three lenses spawned with distinct evidence bases, none having seen the
implementation.

**[S] prior-review record: no regressions.** It read every archived `## Review`
section across M01-M23 and `LESSONS.md`; the GitHub inline-comment probe
returned empty, so that surface was skipped per the gate. It checked the diff
against each lesson bearing on this shape of change — proving a scan
discriminating by a planted violation, refusing an empty domain, the `set -e`
guard shape, counts rather than presence, reading constants from source,
enumerating rather than hand-listing — and found the diff following each. It
independently confirmed the nine deleted `rm -f` lines are covered, checking
every extension they named against `.gitignore`.

**[S] blame-history: one open item, four confirmations.** The open item asked
whether the widened sweep domains now cover self-test and defect-injection
captures with no matching `ALLOWED` or `KEPT_MARKERS` entry, and said it could
find none by inspection but had not run the suite. Settled by evidence: three
full runs, all exit 0. Of its confirmations, one is worth recording — moving
the AC3 control-token block repaired a latent read-before-write bug on the
default branch, where the M02 check read `examples/control.tex` before
anything in the run rendered it.

**[O] diff-bug: ten findings, ranked as the lens ranked them.** It first
verified independently that AC1's own grep returns nothing, that no read
reaches the fixture directory through the three variables round 1 named, and
that every resolvable capture slug — including the ambiguous stems — names a
capture taken at or before its read.

- R1: `git clean -X` removes and reports only IGNORED files, so an artifact a
  render leaves under `examples/` that no ignore rule matches is neither
  deleted nor visible to AC2's assertion. Latent today; the trigger would be
  Quarto emitting one more extension or a fixture directory renamed off the
  `book*` prefix.
- R2: the M15 emission sweep now quantifies over `.tex` produced by
  deliberately-broken filters (`m22-noinj-*`, the nine `m23-*` rows) and
  scratch parity fixtures, so a future splice that made a spliced filter emit
  a contested-key shape would fail M15's acceptance sweep for a reason that is
  M22/M23's plant; and `ALLOWED` is a written-down slug map.
- R3: three more comments of D4's class still standing — 7028, 7917 and 8189
  each said a later PDF render removes the intermediate LaTeX, which `capture`
  now does at the render itself.
- R4: `capture` is called from inside a command substitution at 9550
  (`m23_render`, invoked as `$(...)`), where its `fail` ends only the subshell,
  so the caller's own diagnostic never prints.
- R5: the parity comparison at 10004 hardcodes the `demo-html` slug while
  spelling the stem through `$SOLO_NAME`, so repointing `SOLO_FIXTURE` fails
  with the wrong cause.
- R6: the capture-helper exemption in the AC1 read check is never exercised —
  the helper builds paths from variables and spells no literal artifact path.
- R7: `check_reads` does not follow backslash line continuations the way
  `check_pairs` does, so a render written across two lines would be reported
  as a working-tree read.
- R8: each residue sweep prints an `ok` line from the Python and another from
  the shell `pass`, so `CHECK_COUNT` counts those assertions twice.
- R9: the HTML residue plants target the first `<body` / `</body>` textually
  rather than the document's body element, so a page with either inside a
  script would place the plant where the structural reader cannot see it.
- R10: `CAPTURE_CALL` (`^\s*capture\b`) also matches the helper's own
  definition line, so a render placed immediately above it would count as
  paired.

**Triage.** R3 fixed on the branch — the three comments now state what is
true, completing D4's repair, which had been incomplete. R6 rejected in part:
its off-by claim does not hold, since `helper_body` returns exactly the
`capture() {` line through its closing `}`, and the two brace lines it adds
over the body proper cannot match the artifact pattern; its substantive half —
that the exemption is dead code today — is recorded. R1, R2, R4, R5, R6's
remainder, R7, R8, R9 and R10 go to the acceptance-suite-hardening row.

R1 is the one worth the maintainer's eye, since it is round 1's D1 shape
again: a criterion satisfied while the Goal is not fully fenced. It is not
taken as an amendment return, on two grounds. It is not live — no artifact
escapes today, and it would need an extension outside both `CAPTURE_EXTS` and
`.gitignore` to do so. And its failure scenario does not close even then:
`capture` removes originals under `examples/` for every extension it captures
regardless of ignore status, and every check now reads a capture, so an
unignored residue would be inert litter rather than a file some check reads.
Round 1's D1 differed in exactly that respect — eleven reads actually stood,
reading the working tree.

**Returns.** Amendment-return track 1 (round 1's, executed). Defect-return
track 0: no finding across the three lenses demonstrates an acceptance
criterion failing inside its named procedure's domain.
