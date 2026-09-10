# M086: The sweep-discrimination probe stops re-sweeping the set once per page

**Status:** done (2026-09-10, PR #86 https://github.com/jmgirard/quarto-index/pull/86)

**Goal:** The M24 residue probe shows each whole-set sweep reading every captured
page without running that sweep once per page.

**Outcome:** Under `--self-test` the probe plants each residue (`data-qi-pending`,
`data-qi-meta`, the marker class) into every mirrored page in one
`plantdefect.py --html <kind> <page>...` call and requires one sweep to name
every page `find "$CAPTURE_ROOT" -name '*.html'` lists, read between spaces
(`sweep_named`) behind an awk guard over names that could be misread; a
`diff -rq` count of changed pages must equal the capture root's page count; three
single-page legs require one page named and no other; `sweep_run` counts the
half's sweeps at eight. The section's timing row fell from 3080 s to 23 s.

**Decisions:** none milestone-local.

**Review:** pass 1 returned it (defect return 1): a substring name read let
`book-html/_book/index.html` pass unplanted, and the count check compared two
unchanged `find`s. Pass 2, three-lens fan-out, found no criterion failing; the
gate struck KI33 (its cost closed) and fixed an overclaiming guard comment,
filed KI270 (the guard's false red on two spaced names sharing a first word),
and rejected eight findings, among them the count passing a decoy `<body`
(KI41's plant shape).
