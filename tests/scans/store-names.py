# Source-set scan, run from tests/run-tests.sh as `run_scan store-names`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
# Every definition, not the first one found: the source set became multi-file
# at M17, so a stale duplicate left behind by a split would mask the live one
# and the footprint sweep would be looking for a name the filter no longer
# writes (M16 review F3). Counted first, so a duplicate is reported as a
# duplicate rather than as a disagreement about the value.
missing = []
for name, value in (('STORE_SUFFIX', os.environ['STORE_SUFFIX']),
                    ('STORE_DIR', os.environ['STORE_DIR'])):
    found = re.findall(r'^local %s = "([^"]*)"$' % name, src, re.MULTILINE)
    if len(found) != 1:
        print(f'FAIL: M05-AC1: expected exactly one {name} definition in the '
              f'filter source set, found {len(found)}', file=sys.stderr)
        sys.exit(1)
    if found[0] != value:
        missing.append(f'{name} = {value!r}, filter writes {found[0]!r}')
if missing:
    print('FAIL: M05-AC1: the suite and the filter disagree on the store\'s '
          'name; the suite expects:', file=sys.stderr)
    for m in missing:
        print(f'  {m}', file=sys.stderr)
    sys.exit(1)
print('ok   M05-AC1: the store name the footprint sweep looks for is the one '
      'the filter writes')
