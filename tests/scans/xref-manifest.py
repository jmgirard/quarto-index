# Source-set scan, run from tests/run-tests.sh as `run_scan xref-manifest`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
qmd_path, manifest_path = sys.argv[1:3]
both = os.environ['XREF_BOTH_COMMAND']

# The manifest names the dual-target command; the filter defines it. If they
# ever disagree, every dual row silently reclassifies as single-target and the
# arithmetic below stops meaning anything.
lua = filtersrc.text()
m = re.search(r'XREF_BOTH_COMMAND\s*=\s*"([^"]+)"', lua)
if not m:
    print('FAIL: M02-AC1: no XREF_BOTH_COMMAND in the filter', file=sys.stderr)
    sys.exit(1)
if m.group(1) != both:
    print(f'FAIL: M02-AC1: manifest names {both!r}, filter defines '
          f'{m.group(1)!r}', file=sys.stderr)
    sys.exit(1)

single = dual = 0
for line in open(manifest_path, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip():
        continue
    count, text = line.split('\t', 1)
    if '|' + both in text:
        dual += int(count)
    else:
        single += int(count)

qmd = open(qmd_path, encoding='utf-8').read()
# Occurrences, not matching lines, and quoted values only — the same limits the
# entry= pins carry, recorded as known holes in the milestone file.
found = qmd.count('see="') + qmd.count('see-also="')
expected = single + 2 * dual
if found != expected:
    print(f'FAIL: M02-AC1: examples/demo.qmd has {found} cross-reference '
          f'attribute occurrence(s), but the manifest accounts for {expected} '
          f'({single} single-target + 2 x {dual} dual-target)', file=sys.stderr)
    sys.exit(1)
# The arithmetic above is exact only because demo.qmd holds no mark whose
# target is unusable and none with no source entry — those emit an attribute
# occurrence but no row. Both shapes live in other fixtures on purpose; this
# check reports the invariant by name so a violation is not misread as a
# manifest error.
print(f'ok   M02-AC1: {single} single-target and {dual} dual-target rows '
      f'account for all {found} cross-reference attributes in demo.qmd')
