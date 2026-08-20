# Source-set scan, run from tests/run-tests.sh as `run_scan html-identifiers`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
bad = []
for name in ('HTML_SECTION_ID', 'HTML_ANCHOR_PREFIX', 'HTML_ENTRY_PREFIX',
             'HTML_LETTER_CLASS'):
    m = re.search(rf'{name}\s*=\s*"([^"]*)"', src)
    if not m:
        bad.append(f'  {name} is not defined in the filter')
    elif m.group(1) != os.environ[name]:
        bad.append(f'  {name}: suite says {os.environ[name]!r}, filter '
                   f'defines {m.group(1)!r}')
if bad:
    print('FAIL: M03-AC3: the suite and the filter disagree on the HTML '
          'identifiers:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC3: all 4 HTML identifiers pinned to the filter constants')
