# M24: Every check reads the copy, never the working tree

**Status:** done (2026-08-23, PR #24 https://github.com/jmgirard/quarto-index/pull/24)

**Goal:** Every acceptance check reads an artifact captured into `$WORK` by the render that produced
it, so no check's domain can be filled or emptied by a file an earlier run left under `examples/`.

**Outcome:** A `capture` helper, called at all 85 render sites, copies that render's artifacts
into `$WORK/cap/<slug>/`, removes the originals when they sat under `examples/`, and refuses a
reused slug. 238 read sites were rewritten by one scripted pass to name the capture, and nine
hand-written `rm -f` cleans deleted as its per-fixture form. A pre-render `git clean -Xdf
examples/` starts every run from a fresh checkout's state. The two HTML residue sweeps moved into
`tests/htmlsweep.py`, iterating all 85 captured pages where three call sites stood;
`tests/suitescan.py` holds the suite to both properties over `git ls-files tests`; the M15
emission sweep moved to the run's end over the captured LaTeX set. Each new check is proved on a
planted violation. The suite now passes on a clean checkout, which it did not before.

**Decisions:** Capture at each render rather than pin render order; a capture deletes its
originals under `examples/`; checks spell the capture path in full.

**Review:** Three rounds. Round 1 returned the milestone on AC1 — eleven book reads spelled the
fixture directory through `$BOOK_OUT`, so AC1 passed while the Goal failed; AC1 was narrowed at a
gate to what its grep settles and the 14 reads repaired. Round 2 fixed six findings; round 3's
fan-out found ten, one fixed and nine homed on the acceptance-suite-hardening row. Amendment
returns 1, defect returns 0. Four full runs, three green at 396 checks, one a Quarto segfault.
