"""Move named definitions out of a scratch extension's sources into a module.

This is the M16-AC3 probe's hand: the milestone's whole claim is that a check
reading filter source keeps reading it after the definition moves into another
file. The only way to evidence that is to build a tree where it HAS moved and
run the same checks against it — so this script takes a scratch copy of the
extension and relocates the named top-level definitions into
`modules/moved.lua`, leaving nothing of them behind where they were.

Which files it reads is `tests/filtersrc.py`'s enumeration, never a named file:
after M17 the definitions this probe relocates are spread across `index.lua`
and the modules beside it, and a hand that searched one file would refuse a
name that had merely moved. The enumeration is pointed at the scratch root
given as `argv[1]`, never at the ambient `QI_EXT_DIR` — this script rewrites
what it reads, and the ambient value names the shipped extension.

The scratch tree is text, not a filter that runs: a `warn()` call lifted out of
its enclosing pass is no longer valid Lua, and nothing here renders with it.
The source scans read source as text, which is exactly the reading this probe
is about.

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
    "-- Definitions moved out of the extension's sources by tests/movedefs.py,\n"
    '-- for the M16-AC3 probe. Text only: this tree is read by the source scans,\n'
    '-- never rendered.\n')


def block(sources, name):
    """`name`'s definition as (path, start, end), the span half-open.

    Searched across every source file, so a definition that has moved into a
    module is found where it now lives. Exactly one definition set-wide, not
    one per file: two would leave the probe moving whichever it saw first and
    reporting on a tree where the other is still in place.
    """
    starts = [
        (path, i) for path, lines in sources.items()
        for i, ln in enumerate(lines)
        if re.match(r'local function %s\(' % re.escape(name), ln)
        or re.match(r'local %s\s*=' % re.escape(name), ln)
    ]
    if len(starts) != 1:
        raise SystemExit(
            'FAIL: movedefs: %r has %d top-level definitions in the source set, '
            'want exactly 1%s' % (
                name, len(starts),
                '' if not starts else ' (%s)' % ', '.join(
                    '%s:%d' % (p, i + 1) for p, i in starts)))
    path, i = starts[0]
    lines = sources[path]
    head = lines[i]
    if head.startswith('local function '):
        j = i + 1
        while j < len(lines) and lines[j] != 'end':
            j += 1
        if j == len(lines):
            raise SystemExit('FAIL: movedefs: no closing `end` for %r' % name)
        return path, i, j + 1
    if head.rstrip().endswith('{'):
        j = i + 1
        while j < len(lines) and lines[j] != '}':
            j += 1
        if j == len(lines):
            raise SystemExit('FAIL: movedefs: no closing `}` for %r' % name)
        return path, i, j + 1
    if head.rstrip().endswith('='):
        # A value written across continuation lines, ending at the blank line
        # that follows it.
        j = i + 1
        while j < len(lines) and lines[j].strip():
            j += 1
        return path, i, j
    if ONE_LINE.match(head):
        return path, i, i + 1
    raise SystemExit(
        'FAIL: movedefs: %r is written in a shape this script does not know how '
        'to delimit (%s); moving its first line alone would build a tree that '
        'is not the moved-definition case the probe reports on' % (name, head))


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    root, names = argv[1], argv[2:]
    # The enumeration reads QI_EXT_DIR, and the ambient value names the shipped
    # extension. Set it to the scratch root before filtersrc is asked anything,
    # so this script can only ever rewrite the copy it was pointed at.
    os.environ['QI_EXT_DIR'] = root
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import filtersrc

    sources = {}
    for path in filtersrc.sources():
        sources[path] = filtersrc.read(path).split('\n')

    spans = []
    for name in names:
        path, start, end = block(sources, name)
        spans.append((path, start, end, name))
    spans.sort()
    for a, b in zip(spans, spans[1:]):
        if a[0] == b[0] and a[2] > b[1]:
            raise SystemExit(
                'FAIL: movedefs: the definitions of %r and %r overlap; the '
                'probe would move one of them twice' % (a[3], b[3]))

    moved = []
    for path, start, end, _name in spans:
        moved.extend(sources[path][start:end])
        # A blank line after each block: the dual-target definition is read
        # with a pattern that ends at one, and two blocks butted together would
        # hand it the next definition as well.
        moved.append('')
    for path, start, end, _name in reversed(spans):
        del sources[path][start:end]

    os.makedirs(os.path.join(root, 'modules'), exist_ok=True)
    with open(os.path.join(root, 'modules', 'moved.lua'), 'w',
              encoding='utf-8') as fh:
        fh.write(MOVED_HEADER + '\n' + '\n'.join(moved) + '\n')
    for path, lines in sources.items():
        open(path, 'w', encoding='utf-8').write('\n'.join(lines))
    print('moved %d definition(s) into %s/modules/moved.lua: %s'
          % (len(spans), root, ' '.join(n for _p, _s, _e, n in spans)))


if __name__ == '__main__':
    main(sys.argv)
