"""The extension's Lua source set, as the suite's checks read it.

Every check that reads filter source reads it through here. The point is the
enumeration: `sources()` walks the extension directory recursively, so a
definition moving into a new file stays inside the domain a check sweeps
instead of falling out of it silently. A written-down list of file names would
not do that — it becomes the sweep, and every file it omits goes unread while
the check still passes (M16-AC2).

The root comes from `QI_EXT_DIR` so a probe can point the same checks at a
scratch tree whose definitions have been moved (M16-AC3).

`text()` is the concatenation, for scanners that only pattern-match. `lines()`
keeps each line's FILE identity, which a bare concatenation destroys — M17-AC1
asks which file a definition sits in, and cannot ask it of `text()`.
"""

import os
import re

DEFAULT_EXT_DIR = '_extensions/index'


def ext_dir():
    return os.environ.get('QI_EXT_DIR', DEFAULT_EXT_DIR)


def sources():
    """Every `.lua` file under the extension root, recursively, sorted.

    Sorted so `text()` is stable between runs: an unstable concatenation would
    make a scanner's reported line numbers depend on directory order.
    """
    root = ext_dir()
    found = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            if name.endswith('.lua'):
                found.append(os.path.join(dirpath, name))
    if not found:
        raise SystemExit(
            f'FAIL: no .lua sources under {root!r}; every source-reading check '
            f'would sweep nothing and pass vacuously')
    return sorted(found)


def read(path):
    with open(path, encoding='utf-8') as handle:
        return handle.read()


def text():
    """The whole source set as one string, newline-joined.

    Joined with a newline so a file not ending in one cannot splice its last
    line onto the next file's first.
    """
    return '\n'.join(read(p) for p in sources())


def lines():
    """(path, lineno, line) for every line of the source set.

    `lineno` is 1-based within its own file, so it names a place a reader can
    open — a running index across the concatenation would not.
    """
    out = []
    for path in sources():
        body = read(path)
        # A file ending in a newline has no line after it: splitting on '\n'
        # would report one phantom empty line per source file, and M17-AC1 asks
        # this view which file a definition sits in.
        if body.endswith('\n'):
            body = body[:-1]
        for n, line in enumerate(body.split('\n'), start=1):
            out.append((path, n, line))
    return out


def defining_lines(pattern):
    """Every (path, lineno, line) whose line matches `pattern`.

    Used by the definition-site checks, which care where a definition lives,
    not merely that the source set contains it.
    """
    rx = re.compile(pattern)
    return [(p, n, ln) for p, n, ln in lines() if rx.search(ln)]
