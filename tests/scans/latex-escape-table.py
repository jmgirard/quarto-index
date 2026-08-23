# Source-set scan, run from tests/run-tests.sh as `run_scan latex-escape-table`.
# It reads the whole Lua source set through tests/filtersrc.py rather than one
# named file, so a definition moving into a module stays inside its domain (M16).
#
# READS: the LaTeX escape table's keys out of the source set, and
# examples/demo.qmd as text.
# ASSERTS: the table is opened exactly once in the source set, its key set is
# exactly the suite's probe set, and each probed character appears in demo.qmd
# both as visible term text and inside an entry= level.
# DOES NOT ASSERT: that any character is escaped correctly. The emitted-LaTeX
# manifest checks derive that by hand and are what say it; this scan only keeps
# the probe set and the table from drifting apart.
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
# The opening pinned to exactly one, not taken at the first split: the source
# set became multi-file at M17, so a stale duplicate left behind by a split
# would give this scan a table the filter no longer escapes with (M16 review
# F3, whose four named scans share this shape).
OPENING = 'local LATEX_LITERAL = {'
if src.count(OPENING) != 1:
    print(f'FAIL: AC4: expected exactly one LATEX_LITERAL table in the filter '
          f'source set, found {src.count(OPENING)}', file=sys.stderr)
    sys.exit(1)
table = src.split(OPENING, 1)[1].split('\n}', 1)[0]
keys = set()
for m in re.finditer(r'^\s*\[(".*?"|\'"\')\]\s*=', table, re.MULTILINE):
    raw = m.group(1)
    keys.add('"' if raw == "'\"'" else raw[1:-1].replace('\\\\', '\\'))
probes = set(os.environ['PROBE_CHARS'].split(' '))
if keys != probes:
    print('FAIL: AC4: probe characters do not match the filter escape table',
          file=sys.stderr)
    print(f'  in filter, not probed: {sorted(keys - probes)}', file=sys.stderr)
    print(f'  probed, not in filter: {sorted(probes - keys)}', file=sys.stderr)
    sys.exit(1)

# The pin above compares the probe set to the filter. That alone does not stop
# a character sitting in both and being probed nowhere, so also require each
# one to appear in BOTH contexts of the demo, which is what AC4 promises.
qmd = open('examples/demo.qmd', encoding='utf-8').read()
unescape = lambda t: re.sub(r'\\(.)', r'\1', t)
visible = ''.join(unescape(m) for m in re.findall(r'\[((?:\\.|[^\]\\])*)\]\{\.index', qmd))
entries = ''.join(unescape(m)
                  for m in re.findall(r'entry="((?:\\.|[^"\\])*)"', qmd))
missing = []
for c in sorted(probes):
    if c not in visible:
        missing.append(f'  {c!r} never appears in a visible term')
    if c not in entries:
        missing.append(f'  {c!r} never appears in an entry= level')
if missing:
    print('FAIL: AC4: escape-domain characters unprobed in examples/demo.qmd:',
          file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   AC4: probe set pinned to the filter escape table ({len(keys)} '
      f'chars), each probed in both contexts')
