# Source-set scan, run from tests/run-tests.sh as `run_scan marker-class`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
# Every definition, not the first one found: the source set became multi-file
# at M17, so a stale duplicate left behind by a split would mask the live one
# and this scan would report agreement with a constant the filter no longer uses
# (M16 review F3).
found = re.findall(r'^local MARKER_CLASS = "([^"]*)"$', src, re.MULTILINE)
if len(found) != 1:
    print(f'FAIL: M04-AC1: expected exactly one MARKER_CLASS definition in the '
          f'filter source set, found {len(found)}', file=sys.stderr)
    sys.exit(1)
defined = found[0]
if defined != os.environ['MARKER_CLASS']:
    print(f"FAIL: M04-AC1: suite says {os.environ['MARKER_CLASS']!r}, filter "
          f"defines {defined!r}", file=sys.stderr)
    sys.exit(1)
if defined == os.environ['HTML_SECTION_ID']:
    print(f'FAIL: M04-AC1: the marker class and the generated section id are '
          f'the same string ({defined!r}); one string with two meanings is '
          f'exactly the collision the marker token avoids', file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC1: the marker class is pinned to the filter constant and '
      'differs from the generated section id')
