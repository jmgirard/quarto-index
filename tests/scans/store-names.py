# Source-set scan, run from tests/run-tests.sh as `run_scan store-names`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
missing = [f'{name} = {value!r}'
           for name, value in (('STORE_SUFFIX', os.environ['STORE_SUFFIX']),
                               ('STORE_DIR', os.environ['STORE_DIR']))
           if not re.search(r'^local %s = "%s"$' % (name, re.escape(value)),
                            src, re.MULTILINE)]
if missing:
    print('FAIL: M05-AC1: the suite and the filter disagree on the store\'s '
          'name; the suite expects:', file=sys.stderr)
    for m in missing:
        print(f'  {m}', file=sys.stderr)
    sys.exit(1)
print('ok   M05-AC1: the store name the footprint sweep looks for is the one '
      'the filter writes')
