"""Checks over the documentation site's example gallery (M41).

  listing <gallery.yml>
      Every `.qmd` directly under `examples/`, as `git ls-files` enumerates
      them, appears exactly once as a sequence item in the gallery declaration
      — under `shown:` or under `not-shown:`, and under no other key. A value
      under either of those two keys that names no such fixture is reported
      too, so a renamed fixture cannot leave a dead entry behind.

  manifests <gallery.yml> <registry.tsv>
      Every fixture under `shown:` is one the acceptance suite holds a
      hand-derived HTML index manifest for, `shown:` holds at least the floor
      the criterion names, and at least the floor of shown fixtures also have
      a PDF index manifest. The registry is the table tests/run-tests.sh
      writes: `<fixture>\t<kind>\t<format>\t<variable>\t<path>`, one row per
      addressable manifest.

The declaration's shape is read by `read_gallery`, imported from
site/build_gallery.py — the program that builds the gallery from the same
file. One reader means the shape the build accepts and the shape this check
accepts cannot drift apart.

Every mode reports the size of the domain it swept, so a domain that has gone
empty reads as empty rather than as a pass.

Usage:  python3 tests/gallerycheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'site'))
from build_gallery import read_gallery, shown_fixtures  # noqa: E402

# A fixture of the corpus this gallery declares over: a `.qmd` directly under
# `examples/`, which is the set the milestone's first criterion names. The
# book fixtures live one directory deeper and are out of scope.
FIXTURE = re.compile(r'examples/[^/]+\.qmd')

# The floors the milestone's third and fourth criteria state. Pinned here
# rather than merely reported: a shown list that shrank below its floor, or a
# PDF half that lost all but one fixture, would otherwise stay green.
SHOWN_FLOOR = 8
PDF_FLOOR = 3

# A manifest row's entry is the term the index prints. `index` and `sections`
# manifests state it in field 2 of a row whose field 1 is the level; `outline`
# does the same with no locator count; `terms` states one per line. Rows that
# open a letter group or an index section carry no entry of their own.
ENTRY_OF = {
    'index': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'sections': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'outline': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'terms': lambda f: f[0] if f[0] else None,
}


def read_registry(path):
    """The manifest table as [(fixture, kind, format, variable, path), ...]."""
    rows = []
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            line = line.rstrip('\n')
            if not line:
                continue
            fields = line.split('\t')
            if len(fields) != 5:
                raise SystemExit(
                    'FAIL: M41: %s carries a row with %d field(s), not the 5 '
                    'this reader expects: %r' % (path, len(fields), line))
            if fields[2] not in ENTRY_OF:
                raise SystemExit(
                    'FAIL: M41: %s names the manifest format %r, which this '
                    'reader has no entry rule for; it knows %s'
                    % (path, fields[2], ', '.join(sorted(ENTRY_OF))))
            rows.append(tuple(fields))
    return rows


def entries_of(manifest_path, fmt):
    """Every entry the manifest at `manifest_path` states, in file order."""
    rule = ENTRY_OF[fmt]
    found = []
    with open(manifest_path, encoding='utf-8') as handle:
        for line in handle:
            line = line.rstrip('\n')
            if not line.strip():
                continue
            entry = rule(line.split('\t'))
            if entry is not None:
                found.append(entry)
    return found


def fixture_name(path):
    """`examples/demo.qmd` -> `demo`."""
    return os.path.basename(path)[:-len('.qmd')]


def fail(message):
    print('FAIL: M41: ' + message, file=sys.stderr)
    return 1


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


# ---------------------------------------------------------------------------
# manifests
# ---------------------------------------------------------------------------
def check_manifests(gallery, registry):
    shown = [fixture_name(p) for p in shown_fixtures(gallery)]
    if not shown:
        return fail('%s declares no shown fixture' % gallery)
    rows = read_registry(registry)
    if not rows:
        return fail('%s holds no manifest row, so every fixture below would '
                    'be judged against nothing' % registry)

    have = {}
    for fixture, kind, fmt, variable, path in rows:
        have.setdefault(kind, {})[fixture] = (fmt, variable, path)

    unbacked = [name for name in shown if name not in have.get('html', {})]
    if unbacked:
        return fail('%s shows %s, which the suite holds no hand-derived HTML '
                    'index manifest for; a shown fixture is one the suite '
                    'already judges' % (gallery, ', '.join(unbacked)))

    if len(shown) < SHOWN_FLOOR:
        return fail('%s shows %d fixture(s); the criterion states at least %d'
                    % (gallery, len(shown), SHOWN_FLOOR))

    with_pdf = [name for name in shown if name in have.get('pdf', {})]
    if len(with_pdf) < PDF_FLOOR:
        return fail('%d shown fixture(s) have a hand-derived PDF index '
                    'manifest (%s); the criterion states at least %d'
                    % (len(with_pdf), ', '.join(with_pdf) or 'none', PDF_FLOOR))

    empty = []
    for kind in ('html', 'pdf'):
        for fixture, (fmt, variable, path) in have.get(kind, {}).items():
            if fixture not in shown:
                continue
            if not entries_of(path, fmt):
                empty.append('%s (%s, %s, read as %s)'
                             % (fixture, kind, variable, fmt))
    if empty:
        return fail('these manifests state no entry at all, so the check that '
                    'reads them would judge nothing: %s' % ', '.join(empty))

    print('ok   M41-AC3/AC4: all %d shown fixture(s) have a hand-derived HTML '
          'index manifest, %d of them a PDF one too (%s), and every one of '
          'those %d manifest(s) states at least one entry'
          % (len(shown), len(with_pdf), ', '.join(with_pdf),
             len(shown) + len(with_pdf)))
    return 0


MODES = {
    'listing': (check_listing, 1),
    'manifests': (check_manifests, 2),
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
