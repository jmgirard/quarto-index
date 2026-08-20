"""Move named definitions out of a scratch extension's index.lua into a module.

This is the M16-AC3 probe's hand: the milestone's whole claim is that a check
reading filter source keeps reading it after the definition moves into another
file. The only way to evidence that is to build a tree where it HAS moved and
run the same checks against it — so this script takes a scratch copy of the
extension and relocates the named top-level definitions into
`modules/moved.lua`, leaving nothing of them behind in `index.lua`.

The scratch tree is text, not a filter that runs: a `warn()` call lifted out of
its enclosing pass is no longer valid Lua, and nothing here renders with it.
The scans under `tests/scans/` read source as text, which is exactly the reading
this probe is about.

Usage:  python3 tests/movedefs.py <scratch-ext-dir> <NAME> [<NAME> ...]

A name is a top-level `local` definition — a function, a table, a
continuation-line value, or a one-line constant. An unknown or ambiguous name is
an error: a probe that silently moved nothing would report "the scan still finds
it" about a tree where it never left.
"""

import os
import re
import sys

# A definition complete on its own line: a quoted string, a number, a boolean,
# nil, or a table opened and closed on the line. Anything else is a shape with a
# continuation this script cannot see the end of, and is refused rather than
# truncated.
ONE_LINE = re.compile(
    r'^local \w+ = (?:"[^"]*"|\'[^\']*\'|-?\d+(?:\.\d+)?|true|false|nil|\{.*\})\s*$')

MOVED_HEADER = (
    '-- Definitions moved out of index.lua by tests/movedefs.py, for the M16-AC3\n'
    '-- probe. Text only: this tree is read by the source scans, never rendered.\n')


def block(lines, name):
    """The (start, end) half-open line span of `name`'s top-level definition."""
    starts = [
        i for i, ln in enumerate(lines)
        if re.match(r'local function %s\(' % re.escape(name), ln)
        or re.match(r'local %s\s*=' % re.escape(name), ln)
    ]
    if len(starts) != 1:
        raise SystemExit(
            'FAIL: movedefs: %r has %d top-level definitions in index.lua, '
            'want exactly 1' % (name, len(starts)))
    i = starts[0]
    head = lines[i]
    if head.startswith('local function '):
        j = i + 1
        while j < len(lines) and lines[j] != 'end':
            j += 1
        if j == len(lines):
            raise SystemExit('FAIL: movedefs: no closing `end` for %r' % name)
        return i, j + 1
    if head.rstrip().endswith('{'):
        j = i + 1
        while j < len(lines) and lines[j] != '}':
            j += 1
        if j == len(lines):
            raise SystemExit('FAIL: movedefs: no closing `}` for %r' % name)
        return i, j + 1
    if head.rstrip().endswith('='):
        # A value written across continuation lines, ending at the blank line
        # that follows it.
        j = i + 1
        while j < len(lines) and lines[j].strip():
            j += 1
        return i, j
    if ONE_LINE.match(head):
        return i, i + 1
    raise SystemExit(
        'FAIL: movedefs: %r is written in a shape this script does not know how '
        'to delimit (%s); moving its first line alone would build a tree that '
        'is not the moved-definition case the probe reports on' % (name, head))


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    root, names = argv[1], argv[2:]
    index = os.path.join(root, 'index.lua')
    lines = open(index, encoding='utf-8').read().split('\n')

    spans = []
    for name in names:
        start, end = block(lines, name)
        spans.append((start, end, name))
    spans.sort()
    for a, b in zip(spans, spans[1:]):
        if a[1] > b[0]:
            raise SystemExit(
                'FAIL: movedefs: the definitions of %r and %r overlap; the '
                'probe would move one of them twice' % (a[2], b[2]))

    moved = []
    for start, end, _name in spans:
        moved.extend(lines[start:end])
        # A blank line after each block: the dual-target definition is read
        # with a pattern that ends at one, and two blocks butted together would
        # hand it the next definition as well.
        moved.append('')
    for start, end, _name in reversed(spans):
        del lines[start:end]

    os.makedirs(os.path.join(root, 'modules'), exist_ok=True)
    with open(os.path.join(root, 'modules', 'moved.lua'), 'w',
              encoding='utf-8') as fh:
        fh.write(MOVED_HEADER + '\n' + '\n'.join(moved) + '\n')
    open(index, 'w', encoding='utf-8').write('\n'.join(lines))
    print('moved %d definition(s) into %s/modules/moved.lua: %s'
          % (len(spans), root, ' '.join(n for _s, _e, n in spans)))


if __name__ == '__main__':
    main(sys.argv)
