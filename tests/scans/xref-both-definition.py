# Source-set scan, run from tests/run-tests.sh as `run_scan xref-both-definition`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
m = re.search(r'XREF_BOTH_DEFINITION\s*=\s*(.*?)\n\n', src, re.DOTALL)
if not m:
    print('FAIL: M02-AC5: no XREF_BOTH_DEFINITION in the filter', file=sys.stderr)
    sys.exit(1)
defn = m.group(1)
for needed in ('seename', 'alsoname'):
    if needed not in defn:
        print(f'FAIL: M02-AC5: the dual-target definition does not use '
              f'\\{needed}', file=sys.stderr)
        sys.exit(1)
if re.search(r'see\s+also|\bsee\b(?!name)', defn.replace('seename', '')):
    print('FAIL: M02-AC5: the dual-target definition hard-codes label text '
          'instead of using \\seename/\\alsoname', file=sys.stderr)
    sys.exit(1)
print('ok   M02-AC5: the dual-target command takes its labels from '
      '\\seename/\\alsoname')
