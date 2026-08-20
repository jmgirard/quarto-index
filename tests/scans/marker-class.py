# Source-set scan, run from tests/run-tests.sh as `run_scan marker-class`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
m = re.search(r'MARKER_CLASS\s*=\s*"([^"]*)"', src)
if not m:
    print('FAIL: M04-AC1: MARKER_CLASS is not defined in the filter',
          file=sys.stderr)
    sys.exit(1)
if m.group(1) != os.environ['MARKER_CLASS']:
    print(f"FAIL: M04-AC1: suite says {os.environ['MARKER_CLASS']!r}, filter "
          f"defines {m.group(1)!r}", file=sys.stderr)
    sys.exit(1)
if m.group(1) == os.environ['HTML_SECTION_ID']:
    print(f'FAIL: M04-AC1: the marker class and the generated section id are '
          f'the same string ({m.group(1)!r}); one string with two meanings is '
          f'exactly the collision the marker token avoids', file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC1: the marker class is pinned to the filter constant and '
      'differs from the generated section id')
