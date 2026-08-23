"""Two checks the acceptance suite makes about its own source (M24).

Both read the file set `git ls-files tests` enumerates — the suite's own
tracked source, discovered rather than written down, for the reason
tests/filtersrc.py enumerates the filter's: a written-down list of file names
becomes the sweep, and every file it omits ships unread.

  reads — no line names a rendered artifact under the fixture directory.
          Quarto writes beside the source, so such a path is whatever the last
          render of that document left there — from this run, an earlier one,
          or a different format entirely — and a check reading it asserts
          nothing about the render it sits under. Every read goes to the copy
          `capture` took at the render that produced it. Two kinds of line are
          exempt: the render command itself, which must name the source it
          renders, and the capture helper's own body, which is the one place
          that touches what a render left in the working tree.

  pairs — every render command line is immediately followed by a call to
          `capture`. A render whose artifacts are never captured leaves them
          behind for the next render to overwrite and for the pre-render clean
          to delete, so the checks stated over it would read a file no render
          of this run wrote.

This file is inside the set it reads, so it spells neither the artifact paths
nor the render command out in full: both patterns below are assembled from
pieces, and the prose above names them rather than quoting them. A checker
exempted from its own check is a checker nothing holds to its own rule.

An optional OVERLAY directory supplies the BYTES for any tracked path it holds
a copy of, while git keeps supplying the file list. That is the probe's handle
for pointing either check at a tree with a violation planted in it, which is
how each is shown to fail on the defect it names rather than merely to pass —
the shape M23's lesson names, one layer up: a scan over source can certify a
property it never asserts, and only a planted break settles that it does.

Usage:  python3 tests/suitescan.py <reads|pairs> [overlay-dir]

Exits non-zero naming every offending file and line.
"""

import os
import re
import subprocess
import sys

# A token ending in one of the extensions a render produces, in any form the
# suite writes one — a literal name, a glob, a shell variable. NOT anchored on
# a whitespace boundary at the start, so such a path inside a quoted string is
# found exactly as a bare word is.
FIXTURE_DIR = 'examples'
ARTIFACT = re.compile(FIXTURE_DIR + r'/\S*\.'
                      r'(?:html|tex|md|pdf|aux|idx|ilg|ind|log)(?![0-9A-Za-z])')
RENDER = re.compile('quarto' + r'\s+' + 'render')
CAPTURE_CALL = re.compile(r'^\s*capture\b')
HELPER_OPEN = re.compile(r'^capture\(\) \{')


def tracked(overlay=None):
    """The suite's own source files, as git enumerates them.

    Returns (reported path, path to read). With an overlay, a tracked path the
    overlay holds is READ from there and still REPORTED under its own name, so
    a planted violation is named where a reader would look for it.
    """
    out = subprocess.run(['git', 'ls-files', 'tests'], check=True,
                         capture_output=True, text=True).stdout.split('\n')
    pairs = []
    for path in out:
        if not path:
            continue
        source = path
        if overlay:
            candidate = os.path.join(overlay, path)
            if os.path.isfile(candidate):
                source = candidate
        if os.path.isfile(source):
            pairs.append((path, source))
    return pairs


def helper_body(lines):
    """The line numbers (1-based) of the capture helper's body, or an empty set.

    The helper is a shell function at column zero, so its body runs to the
    first line that is a bare closing brace at column zero.
    """
    for i, line in enumerate(lines):
        if HELPER_OPEN.match(line):
            for j in range(i + 1, len(lines)):
                if lines[j].rstrip() == '}':
                    return set(range(i + 1, j + 2))
            break
    return set()


def check_reads(files):
    bad = []
    helper_seen = False
    for path, source in files:
        lines = open(source, encoding='utf-8', errors='replace').read().split('\n')
        exempt = helper_body(lines)
        helper_seen = helper_seen or bool(exempt)
        for n, line in enumerate(lines, 1):
            if not ARTIFACT.search(line):
                continue
            if RENDER.search(line) or n in exempt:
                continue
            bad.append('  %s:%d: %s' % (path, n, line.strip()))
    if not helper_seen:
        return ('the capture helper was not found in the suite source, so the '
                'exemption this check grants it was never applied and the '
                'check does not know what it is reading')
    if bad:
        return ('%d line(s) still name a rendered artifact in the fixture '
                'directory rather than the copy captured at its render:\n%s'
                % (len(bad), '\n'.join(bad)))
    return None


def check_pairs(files):
    bad = []
    renders = 0
    for path, source in files:
        lines = open(source, encoding='utf-8', errors='replace').read().split('\n')
        i = 0
        while i < len(lines):
            if RENDER.search(lines[i]):
                renders += 1
                end = i
                # A command continued over several lines ends at the first one
                # that does not end in a backslash.
                while end < len(lines) - 1 and lines[end].rstrip().endswith('\\'):
                    end += 1
                nxt = lines[end + 1] if end + 1 < len(lines) else ''
                if not CAPTURE_CALL.match(nxt):
                    bad.append('  %s:%d: %s\n    followed by: %s'
                               % (path, i + 1, lines[i].strip(),
                                  nxt.strip() or '(end of file)'))
                i = end + 1
                continue
            i += 1
    if not renders:
        return ('no render command was found in the suite source, so this '
                'check pairs nothing and would pass on a suite that renders '
                'nothing at all')
    if bad:
        return ('%d of %d render(s) are not followed by a call to the capture '
                'helper:\n%s' % (len(bad), renders, '\n'.join(bad)))
    return 'ok %d' % renders


MODES = {'reads': check_reads, 'pairs': check_pairs}


def main(argv):
    if len(argv) not in (2, 3) or argv[1] not in MODES:
        raise SystemExit(__doc__)
    mode = argv[1]
    files = tracked(argv[2] if len(argv) == 3 else None)
    if not files:
        raise SystemExit('FAIL: M24: `git ls-files tests` enumerated no file, '
                         'so the %s check would sweep nothing' % mode)
    problem = MODES[mode](files)
    if problem is not None and not problem.startswith('ok '):
        print('FAIL: M24: ' + problem, file=sys.stderr)
        return 1
    if mode == 'reads':
        print('ok   M24-AC1: none of the %d tracked suite source file(s) reads '
              'a rendered artifact out of the fixture directory; every read '
              'names the copy captured at its render' % len(files))
    else:
        print('ok   M24-AC3: all %s render command line(s) across the %d '
              'tracked suite source file(s) are immediately followed by a call '
              'to the capture helper'
              % (problem.split()[1], len(files)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
