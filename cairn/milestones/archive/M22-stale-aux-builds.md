# M22: A stale `.aux` outliving its marks still builds

**Status:** done (2026-08-22, PR #22 https://github.com/jmgirard/quarto-index/pull/22)

**Goal:** A LaTeX document whose surviving `.aux` carries the typeset-time
subsystem's commands renders cleanly after the marks that defined them are gone.

**Outcome:** `core.lua` gained `PRINCIPAL_GOBBLERS` — empty-bodied
`\providecommand*` stand-ins for the three `.aux`-borne names
(`\quartoindexprincipalpage`, `\quartoindexrangeat`, `\quartoindexrangeto`) —
and `index.lua` injects it wherever it does not inject `PRINCIPAL_SUBSYSTEM`,
zero-marks documents included, exactly one block per document. M20-AC6's leak
scan gained a `--standins` subtraction bounded to the exact empty form; the
suite renders a parent whose `.aux` carries all three names and probes two
deletion shapes against it. README scopes the promise to the `.aux` — a
surviving `.ind` carries `\quartoindexlocator`, which no stand-in covers.

**Decisions:** none milestone-local.

**Review:** Two rounds. Round 1 returned on amendments to AC1 (named a
non-existent fixture; a clause that could never fail) and AC2 (required the
M20/M21 sections to pass unmodified, impossible alongside AC1), with 13
findings — nine fixed, two follow-up, including a README claim reproduced false.
Round 2's diff lens returned 14 more, all actioned at the gate; the other two
lenses none. 375 checks, 0 FAIL.
