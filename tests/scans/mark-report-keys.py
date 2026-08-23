# Source-set scan, run from tests/run-tests.sh as `run_scan mark-report-keys`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
# Every key the run passes, not a fixed slice: a key added to the run and
# not to the scan is a key nothing holds to matching one warning, and every
# zero-expectation control resting on it then passes vacuously (M18 review
# F3).
keys = sys.argv[1:]
assert keys, 'mark-report-keys was given no keys to check'
# An EMPTY key is refused rather than swept: the run passes these as shell
# variables, and a variable referenced before its section has run expands to
# nothing — which would match every message and report perfect distinctness
# over a domain that had silently gone empty (M21 review F6, found while
# repairing it).
empty = [i + 1 for i, k in enumerate(keys) if not k]
if empty:
    print(f'FAIL: M10-AC4: key(s) {empty} passed to mark-report-keys are empty; '
          f'an empty needle matches every message, so the distinctness this '
          f'scan reports would be over nothing', file=sys.stderr)
    sys.exit(1)
src = filtersrc.text()
# Each warn() call's message, with its concatenated fragments joined back
# together: these messages are written as `("..." .. "..."):format(...)`, so a
# scan that read only the leading literal would compare keys against a PREFIX
# of each message while claiming to compare them against the message.
calls = re.findall(r'warn\((.*?)\)\s*$', src, re.S | re.M)
frag = re.compile(r'("|\x27)((?:[^\\]|\\.)*?)\1')
lits = [''.join(m.group(2) for m in frag.finditer(c)) for c in calls]
lits = [l for l in lits if l]
errs = []
# Each key must find its own message in the filter, or the key is stale and
# every count using it reads zero forever.
owner = {}
for key in keys:
    owners = [l for l in lits if key in l]
    if len(owners) != 1:
        errs.append(f'key <<{key}>> matches {len(owners)} filter warnings, want 1')
    else:
        owner[key] = owners[0]
# ...and must match no OTHER key's message either.
for key in keys:
    for other in keys:
        if key != other and other in owner and key in owner[other]:
            errs.append(f'key <<{key}>> also matches the message owned by <<{other}>>')
if errs:
    print('FAIL: M10-AC4: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print(f'ok   M10-AC4: each of the {len(keys)} report grep keys the run uses '
      f'matches exactly its own filter warning and none of the others')
