# M103: The two site-check clauses M46 withdrew hold again

**Status:** done (2026-10-01, PR #103 https://github.com/jmgirard/quarto-index/pull/103)

**Goal:** The site link check and the pre-release sweep report every link and
page they read, where today one link shape escapes the capture and one page
shape raises an exception.

**Outcome:** `tests/sitecheck.py links` resolves a link only by looking up its
normalized path, or that path plus `index.html`, in `captured_files`. That is
the set of regular files one `os.walk` lists. The `realpath` containment test
is gone, and the base-segment test reads the normalized path. A `.html` entry
that is not a regular file is named as a page whose links were not read.
`sweep_rows` reports a page that does not decode as UTF-8 by name, and returns
its hits beside that report. D-061 supersedes D-029. KI152, KI153 and KI158
closed. KI303-KI305 added.

**Decisions:** none milestone-local. D-061 records the walked set and the
restored report clause.

**Review:** one round, three lenses, 28 findings. The two medium ones were
fixed at the gate: sweep hits dropped beside an unreadable page, and symlinked
pages skipped with no report. Five wording and test-pin items were fixed too.
Five findings became three Known issues, and 12 were rejected with reasons. Suite 1728
green on ec2c631, PR checks green. Nothing graduated or retired.
