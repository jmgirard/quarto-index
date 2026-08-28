# M51: The version matrix typesets a PDF again

**Status:** done (2026-08-28, PR #51 https://github.com/jmgirard/quarto-index/pull/51)

**Goal:** A weekly matrix leg renders the two PDF fixtures on every planned
Quarto version and fails when either prints no index.

**Outcome:** `.github/workflows/versions.yml` gains a `pdf` job carrying the
four steps `50899b9` removed — TinyTeX via `quarto-actions/setup`, `imakeidx`
from `https://tlnet.yihui.org`, `poppler-utils`, and the demo and book fixtures
each rendered to PDF then extracted through `tests/indexdump.py pdf` in a step
of its own, so a fixture typesetting at exit 0 with no index shows a green
render beside a red extraction; the book's extraction reads M49's titles rather
than `Index`. It writes outside the render job's uploaded extract directory and
uploads nothing. A `pdf <event>` mode in `tests/versioncheck.py` reads
`PDF_EVENTS` (`false` on a push, undeclared events refused), and the `plan`
job's output of it is what the job's `if:` gates on, naming no event.

**Decisions:** D-032 (the dependency re-add and the off-the-push-path gate).

**Review:** Three lenses; two found nothing, the diff-bug lens ten, none
failing a criterion. Fixed before merge: an unreachable TeX-bin failure branch,
a suite pass line claiming to read the workflow's triggers, an overstated
plan-step comment, README naming two of three legs, a lost true sentence.
Filed: `DECLARED_EVENTS` copies the workflow's `on:` block.
