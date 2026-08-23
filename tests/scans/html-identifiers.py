# Source-set scan, run from tests/run-tests.sh as `run_scan html-identifiers`.
# It reads the whole Lua source set through tests/filtersrc.py rather than one
# named file, so a definition moving into a module stays inside its domain (M16).
#
# READS: the four HTML identifier constants, each as an anchored top-level
# `local NAME = "..."` line.
# ASSERTS: each is defined exactly once in the source set, and its value is the
# string the suite's HTML checks grep the rendered pages by.
# DOES NOT ASSERT: that any rendered page carries these strings. The HTML index
# checks that grep by them are what say that, and they are the reason a
# disagreement here matters at all.
import os, re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()
bad = []
# Every definition, not the first one found: the source set became multi-file
# at M17, so a stale duplicate left behind by a split would mask the live one
# and this scan would report agreement with a constant the filter no longer uses
# (M16 review F3).
for name in ('HTML_SECTION_ID', 'HTML_ANCHOR_PREFIX', 'HTML_ENTRY_PREFIX',
             'HTML_LETTER_CLASS'):
    found = re.findall(rf'^local {name} = "([^"]*)"$', src, re.MULTILINE)
    if len(found) != 1:
        bad.append(f'  {name} has {len(found)} definition(s) in the filter '
                   f'source set, want exactly 1')
    elif found[0] != os.environ[name]:
        bad.append(f'  {name}: suite says {os.environ[name]!r}, filter '
                   f'defines {found[0]!r}')
if bad:
    print('FAIL: M03-AC3: the suite and the filter disagree on the HTML '
          'identifiers:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC3: all 4 HTML identifiers pinned to the filter constants')
