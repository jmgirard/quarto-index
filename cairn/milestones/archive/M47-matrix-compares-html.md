# M47: The version matrix compares what it renders

**Status:** done (2026-08-27, PR #47 https://github.com/jmgirard/quarto-index/pull/47)

**Goal:** Cut the version matrix back to the HTML indexes its comparison reads,
removing the PDF renders, extractions and TeX install M45 found unreachable.

**Outcome:** `.github/workflows/versions.yml` renders HTML only; gone from the
every-push path are `tinytex: true`, the TeX-package step with its hardcoded
`https://tlnet.yihui.org` repository and `tlmgr update --self`, the poppler
step, both `--to pdf` renders and both `indexdump.py pdf` extractions.
`check_compare` in `tests/versioncheck.py` lost `PDF_SUFFIX` and its `want_pdf`
block and report lines; `run-tests.sh` lost the `demo.pdf` control-tree entry
and the M45 T4 self-test block. `indexdump.py`'s `pdf` mode and its capture
stay: the suite reads a printed index through them. Renders 22-28s; suite 386
checks, self-test 692 (from 698).

**Decisions:** none.

**Review:** One round, no returns; the blame-history and prior-review lenses
found nothing. The diff-bug lens reported nine, all prose accuracy or test
coverage. Seven were fixed at the gate: a restored self-test assertion that a
failed comparison states its swept domain size, shown red against a reader
whose domain print was moved into the success branch; five prose corrections; a
dead serialization sent to `/dev/null`. F9 rejected, F7 to the candidate row.
