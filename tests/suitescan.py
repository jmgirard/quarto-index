"""Three modes the acceptance suite runs over its own source (M24, M075).

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

  sections — not a check but the domain the run's timing rests on: the banner
          heading of every `# ---` block inside `run_all_checks`, one per line
          on stdout, in source order. The suite reads this to hold the row set
          in its timing file against the sections the source actually has, so
          a section added without a timing call is a red run rather than a
          silent gap. A block's heading is the FIRST comment line between the
          block's two rules; the rest of the block is prose about the section.
          The domain stops at the function on purpose: the banner blocks that
          precede it are the script's own setup, not sections of the run, and
          the run's setup window is timed as one row of its own instead. A
          banner inside a nested function body would be reported here and
          would fire its timing call once per call of that function; nothing
          detects that shape, but it fails loudly rather than quietly, the
          heading-set check being what it fails.

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

Usage:  python3 tests/suitescan.py <reads|pairs|sections> [overlay-dir]

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

# The wrapper whose body is the run, its call site, and the banner rule the
# section blocks are drawn with. Assembled from pieces for the same reason the
# two patterns above are: this file is inside the set the modes sweep.
RUN_ALL = 'run_all_checks'
RUN_ALL_OPEN = re.compile('^' + RUN_ALL + r'\(\) \{')
RUN_ALL_CALL = re.compile('^' + RUN_ALL + r'\s')
BANNER_RULE = re.compile(r'^# -{10,}\s*$')
# The one row of the timing file that is not a section, so no section may be
# called this.
UNATTRIBUTED = 'unattributed'


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


def run_all_span(lines):
    """The 0-based bounds [first, last) of the run wrapper's body, or None.

    The wrapper defines helper functions of its own at column zero, so its
    close is NOT the first bare `}` after its head — it is the last one before
    the line that calls it.
    """
    open_at = None
    for i, line in enumerate(lines):
        if RUN_ALL_OPEN.match(line):
            open_at = i
            break
    if open_at is None:
        return None
    for j in range(open_at + 1, len(lines)):
        if RUN_ALL_CALL.match(lines[j]):
            for k in range(j - 1, open_at, -1):
                if lines[k].rstrip() == '}':
                    return (open_at + 1, k)
            return None
    return None


def banner_headings(lines, lo, hi):
    """(1-based line number, heading) for each banner block in [lo, hi), or a
    string naming the first block whose heading cannot be read.

    A block is a rule, one or more comment lines, and a closing rule; its
    heading is the first of those comment lines that carries text. A rule that
    closes nothing — a lone divider, two rules with nothing between them — is
    no block and is stepped over.

    Every OTHER way a block can fail to yield a heading is reported rather
    than skipped (M075 review F1). A skipped block is a section the timing
    file never has to name, so it would run untimed while both checks over
    that file stayed green — the silent gap the domain exists to close.
    """
    out = []
    i = lo
    while i < hi:
        if BANNER_RULE.match(lines[i]):
            j = i + 1
            heading = None
            while (j < hi and lines[j].startswith('#')
                   and not BANNER_RULE.match(lines[j])):
                if heading is None and lines[j].lstrip('#').strip():
                    heading = lines[j].lstrip('#').strip()
                j += 1
            if j == i + 1:
                # Nothing between this rule and whatever follows it: a lone
                # divider, not a block.
                i += 1
                continue
            if j >= hi or not BANNER_RULE.match(lines[j]):
                return ('%d: this banner block is never closed by a second '
                        'rule, so it declares no section and the timing file '
                        'would not have to name one' % (i + 1))
            if not heading:
                return ('%d: this banner block carries no comment line with '
                        'text, so it declares no heading and the timing file '
                        'would not have to name one' % (i + 1))
            out.append((i + 1, heading))
            i = j + 1
            continue
        i += 1
    return out


def check_sections(files):
    """The section headings, as a list — or a string naming what is wrong.

    Unlike its two neighbours this mode reports a domain rather than a
    verdict, so main prints the list; the string form is the same failure
    shape the checks above return.
    """
    holders = []
    for path, source in files:
        lines = open(source, encoding='utf-8', errors='replace').read().split('\n')
        span = run_all_span(lines)
        if span is not None:
            holders.append((path, lines, span))
    if len(holders) != 1:
        return ('%d tracked suite source file(s) hold the %s wrapper rather '
                'than exactly one, so the section domain is not settled'
                % (len(holders), RUN_ALL))
    path, lines, (lo, hi) = holders[0]
    blocks = banner_headings(lines, lo, hi)
    if not isinstance(blocks, list):
        return '%s:%s' % (path, blocks)
    headings = []
    seen = {}
    for line_no, heading in blocks:
        if '\t' in heading:
            return ('%s:%d: this banner heading contains a tab, which is the '
                    'timing file\'s own column separator' % (path, line_no))
        if heading == UNATTRIBUTED:
            return ('%s:%d: this banner heading is <<%s>>, the label the '
                    'timing file reserves for the run\'s setup window'
                    % (path, line_no, UNATTRIBUTED))
        if heading in seen:
            return ('%s:%d: this banner heading repeats the one at line %d, '
                    'so the two sections would share one timing row'
                    % (path, line_no, seen[heading]))
        seen[heading] = line_no
        headings.append(heading)
    if not headings:
        return ('no banner block was found inside %s, so the timing file '
                'would be held against an empty domain and any set of rows '
                'at all would satisfy it' % RUN_ALL)
    return headings


MODES = {'reads': check_reads, 'pairs': check_pairs,
         'sections': check_sections}


def main(argv):
    if len(argv) not in (2, 3) or argv[1] not in MODES:
        raise SystemExit(__doc__)
    mode = argv[1]
    files = tracked(argv[2] if len(argv) == 3 else None)
    if not files:
        raise SystemExit('FAIL: M24: `git ls-files tests` enumerated no file, '
                         'so the %s check would sweep nothing' % mode)
    problem = MODES[mode](files)
    if mode == 'sections':
        if isinstance(problem, list):
            # Written as bytes on a pinned encoding, not through the locale's:
            # the headings carry em dashes and non-ASCII terms, and under an
            # ASCII stdout locale `print` raises rather than reporting the
            # domain (M075 review F6).
            sys.stdout.buffer.write(
                ('\n'.join(problem) + '\n').encode('utf-8'))
            sys.stdout.flush()
            return 0
        print('FAIL: M075: ' + problem, file=sys.stderr)
        return 1
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
