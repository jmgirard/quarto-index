"""Checks over the documentation site's example gallery (M41).

  listing <gallery.yml>
      Every `.qmd` directly under `examples/`, as `git ls-files` enumerates
      them, appears exactly once as a sequence item in the gallery declaration
      — under `shown:` or under `not-shown:`, and under no other key. A value
      under either of those two keys that names no such fixture is reported
      too, so a renamed fixture cannot leave a dead entry behind.

The declaration's shape is read by `read_gallery` below, which accepts only
`<key>:` at column 0 followed by `  - <value>` lines. Anything else is an
error rather than a key silently parsed as empty: a reader that returns an
empty list for a shape it does not understand turns every check over that list
green, which is the failure this refuses to have.

Every mode reports the size of the domain it swept, so a domain that has gone
empty reads as empty rather than as a pass.

Usage:  python3 tests/gallerycheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import re
import subprocess
import sys

# A fixture of the corpus this gallery declares over: a `.qmd` directly under
# `examples/`, which is the set the milestone's first criterion names. The
# book fixtures live one directory deeper and are out of scope.
FIXTURE = re.compile(r'examples/[^/]+\.qmd')

KEY = re.compile(r'^([A-Za-z0-9_-]+):\s*$')
ITEM = re.compile(r'^  - (\S.*?)\s*$')


def fail(message):
    print('FAIL: M41: ' + message, file=sys.stderr)
    return 1


def read_gallery(path):
    """The declaration as {key: [value, ...]}, in file order.

    Accepts exactly two line shapes outside comments and blanks: a top-level
    `<key>:` and a `  - <value>` item under the key above it. Every other line
    raises. The strictness is the point — see the module docstring.
    """
    found = {}
    order = []
    current = None
    with open(path, encoding='utf-8') as handle:
        for number, line in enumerate(handle.read().split('\n'), start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            match = KEY.match(line)
            if match:
                current = match.group(1)
                if current in found:
                    raise SystemExit(
                        'FAIL: M41: %s line %d: the key %r is declared twice'
                        % (path, number, current))
                found[current] = []
                order.append(current)
                continue
            match = ITEM.match(line)
            if match:
                if current is None:
                    raise SystemExit(
                        'FAIL: M41: %s line %d: a sequence item before any key'
                        % (path, number))
                found[current].append(match.group(1))
                continue
            raise SystemExit(
                'FAIL: M41: %s line %d: %r is neither a `<key>:` line nor a '
                '`  - <value>` item; this reader accepts only those two shapes'
                % (path, number, line))
    return found, order


def corpus():
    """The fixture paths, as git enumerates them.

    Discovered rather than written down, for the reason tests/sitecheck.py
    discovers the site's pages: a written-down list becomes the sweep, and
    every fixture it omits goes unlisted and unread.
    """
    out = subprocess.run(['git', 'ls-files', 'examples'], check=True,
                         capture_output=True, text=True).stdout.split('\n')
    return [path for path in out if FIXTURE.fullmatch(path)]


# ---------------------------------------------------------------------------
# listing
# ---------------------------------------------------------------------------
def check_listing(gallery):
    fixtures = corpus()
    if not fixtures:
        return fail('git enumerated no fixture matching %s under examples/; '
                    'the domain this check sweeps is empty, so it can judge '
                    'nothing' % FIXTURE.pattern)
    declared, order = read_gallery(gallery)
    for key in ('shown', 'not-shown'):
        if key not in declared:
            return fail('%s declares no `%s:` key; it declares %s'
                        % (gallery, key, ', '.join(order) or 'nothing'))

    listed = set(declared['shown']) | set(declared['not-shown'])
    counts = {}
    for key in order:
        for value in declared[key]:
            counts.setdefault(value, []).append(key)

    missing = [path for path in fixtures if path not in listed]
    if missing:
        return fail('%s lists neither under `shown:` nor under `not-shown:`: '
                    '%s. Every fixture is declared one way or the other.'
                    % (gallery, ', '.join(missing)))

    twice = [path for path in fixtures if len(counts.get(path, [])) > 1]
    if twice:
        return fail('%s lists %s more than once (under %s). Each fixture is '
                    'declared exactly once.'
                    % (gallery, ', '.join(twice),
                       '; '.join('%s: %s' % (p, ', '.join(counts[p]))
                                 for p in twice)))

    elsewhere = sorted(path for path in fixtures
                       for key in counts.get(path, [])
                       if key not in ('shown', 'not-shown'))
    if elsewhere:
        return fail('%s names %s under a key that is neither `shown:` nor '
                    '`not-shown:`' % (gallery, ', '.join(elsewhere)))

    stale = [value for key in ('shown', 'not-shown')
             for value in declared[key] if value not in fixtures]
    if stale:
        return fail('%s lists %s, which git enumerates no fixture for; a '
                    'renamed or deleted fixture left a dead entry behind'
                    % (gallery, ', '.join(stale)))

    print('ok   M41-AC1: all %d fixture(s) git enumerates under examples/ are '
          'declared exactly once in %s — %d shown, %d not shown'
          % (len(fixtures), gallery, len(declared['shown']),
             len(declared['not-shown'])))
    return 0


MODES = {
    'listing': (check_listing, 1),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    func, needed = MODES[argv[1]]
    args = argv[2:]
    if not (needed <= len(args) <= func.__code__.co_argcount):
        raise SystemExit(__doc__)
    return func(*args)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
