# M088: Two link-check defects M087's review filed close by deletion

**Status:** done (2026-09-10, PR #88 https://github.com/jmgirard/quarto-index/pull/88)

**Goal:** Both defects M087's review filed against the suite's link checks, KI271
and KI272, close by removing the code that carries them.

**Outcome:** `check_locator_fragments` is deleted from `tests/run-tests.sh` with its
M064-AC2 call, and the M063-AC2 old-store leg runs `tests/fragments.py resolve` over
`index.html` in its place, so every fragment reader in the suite routes through
D-057's one test (KI271 struck). `m085_epub_plant` takes one expected count held by
both `epubcheck.py links` and `unique` (KI272 corrected to the gap left). Both legs
now read the whole page where the removed check read one section, the same set on
today's fixture; `Bramble`'s old-store anchor stays unasserted (KI273).

**Decisions:** none milestone-local; the plan gate's three declines are in the work log (git).

**Review:** pass 1, three-lens fan-out, found no criterion failing. Four wording
findings were fixed before merge: the M063 T2 self-test pass line claimed an anchor
contrast nothing asserts, the M078-AC3 sweep's fail label now names M064-AC2 too,
the plant comment accounts for the clean repack, and KI273's pass condition is
complete. One was rejected as the planned section-to-page widening. Re-run on the
fixed head: suite 779 checks, `--self-test` 1453, 0 FAIL. Nothing graduated or retired.
