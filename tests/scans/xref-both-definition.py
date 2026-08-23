# Source-set scan, run from tests/run-tests.sh as `run_scan xref-both-definition`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
# Every definition, not the first one found: the source set became multi-file at
# M17, so a stale duplicate left behind by a split would mask the live one and
# this scan would be reading a definition the filter no longer injects (M16
# review F3).
starts = list(re.finditer(r'^local XREF_BOTH_DEFINITION =$', src, re.MULTILINE))
if len(starts) != 1:
    print(f'FAIL: M02-AC5: expected exactly one XREF_BOTH_DEFINITION definition '
          f'in the filter source set, found {len(starts)}', file=sys.stderr)
    sys.exit(1)
# The statement's extent is the source's own paragraph break. Lua ends a
# statement by grammar and not by punctuation, so this is the definition as the
# file LAYS IT OUT, which is all this scan reads and all it claims: a definition
# rewrapped to run into the next one would be read short, and the check below
# would then report a missing label rather than a layout change.
rest = src[starts[0].end():]
defn = rest.split('\n\n', 1)[0]
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
