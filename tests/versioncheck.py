"""The cross-leg comparison of the version matrix's extractions (M43).

`.github/workflows/versions.yml` renders the same fixtures under several
Quarto releases and reduces each rendered artifact to a row form with
`tests/indexdump.py`. This is the job that reads those extractions back and
asks the milestone's question: does the index the extension emits depend on
which Quarto rendered it?

  legs <floor> <pinned> <event>
      Print, as one JSON line, the matrix the workflow renders on: a leg named
      `floor` at the version the workflow's header records as the oldest
      release the declared range admits, a leg named `pinned` at the version
      `pages.yml` installs, and — only on a scheduled run or a manual one — a
      leg named `release` tracking Quarto's current release. The channel leg is
      kept off pushes deliberately: the other two are exact versions, whose red
      always traces to a commit, while a channel leg can go red on an upstream
      release alone.

  fixtures <workflow.yml> <name> [<name> ...]
      The workflow's render step reduces one rendered artifact per fixture
      with `tests/indexdump.py` and writes each extraction under its fixture's
      own name. The file is read whole: an invocation of that shape anywhere
      in it counts, so a second job or a step outside the matrix carrying one
      joins the set rather than being reported as sitting outside the step. Those names are the domain `compare` below sweeps, and the
      acceptance suite dumps the same fixtures locally so that the extraction
      the matrix rests on is exercised on every run. This holds the two sets
      equal: a fixture added to the workflow and not to the suite ships with
      its dump unexercised until a leg runs, and one added to the suite alone
      is a control over an artifact no leg renders.

  floor <workflow.yml> <doc> [<doc> ...]
      The workflow declares exactly one floor version, and every document
      named after it states that version. README and the site's Tests page
      both tell a reader which Quarto the floor leg installs, and this is what
      stops the number moving in the workflow while the two documents go on
      naming the old one.

      What it reads of the workflow is one `FLOOR:` line and the version on
      it. It does not read which action installs that version, whether the leg
      exists, what any step runs, or that the number is still the oldest
      release the declared range admits — the workflow's own header records
      where the number came from and when, and says that nothing re-derives
      it. What it reads of each document is whether that exact version string
      occurs in it, bounded so a longer version containing it does not count;
      it does not read where in the document the version is named or what is
      claimed about it there.

  compare <legs-dir> <baseline>
      `<legs-dir>` holds one directory per leg, named `index-<leg>` — the
      shape `actions/download-artifact` unpacks the uploads into. Every leg's
      HTML extraction is compared, byte for byte, against the leg named
      `<baseline>`. `*.html.txt` is the whole of what this compares; a leg's
      other uploads, if it ever carries any, are not read here. The workflow's
      render step records what the matrix renders and why.

This is the same-tree comparison D-012 licenses and not the merge-base oracle
D-004 refused: one tree, two sides differing only in an injected condition —
here the Quarto version — so a behavior-preserving change to this repository
moves both sides identically and cannot break it.

Every clause reports the size of the domain it swept, so a comparison that has
gone empty — one leg, no fixture, an unpacked directory that is not where the
artifacts landed — reads as empty rather than as agreement.

Usage:  python3 tests/versioncheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import json
import os
import re
import sys

# The prefix each leg's uploaded artifact carries, so a directory
# `download-artifact` created for something else is not read as a leg.
LEG_PREFIX = 'index-'
# The extraction suffix `indexdump.py` output is written under.
HTML_SUFFIX = '.html.txt'


# `FLOOR: <version>` in the workflow's env block, quoted or not. The floor is
# stated once, in the file whose header records where the number came from and
# when the query that returned it ran.
FLOOR = re.compile(
    r'^\s+FLOOR:\s*(?P<quote>[\'"]?)(?P<value>[^\'"\s]+)(?P=quote)\s*$', re.M)
# A full dotted release number and nothing else. One home for the two readers
# that ask it: the floor read below, and the Pages workflow's pin in
# `tests/pagescheck.py`, which imports this name rather than carrying a second
# copy the two could come to disagree about (M48). It lives here, in the
# module whose imports are the standard library alone, so a reader the version
# matrix runs does not load the docs site's gallery builder to ask it.
EXACT = re.compile(r'^\d+\.\d+\.\d+$')

# The extraction target of one `indexdump.py html` invocation: the command and
# the redirection that follows it, whether on the same line or continued onto
# the next, so a `.html.txt` path written by anything else is not read as a
# fixture and an invocation written without a line continuation is not missed
# (M48). This is the whole of what the `fixtures` mode reads out of the
# workflow — it says nothing about which artifact is rendered, in what order,
# with what tool, or which job or step the invocation sits in, and it is a
# scan of the WHOLE file rather than of the render step alone; a file
# rewritten so that no invocation matches reports an empty domain rather than
# agreement (D-011 licenses a scan narrowed to what it reads).
EXTRACTION = re.compile(
    r'python3 tests/indexdump\.py html [^\n]*?(?:\\\n\s*)?>\s*'
    r'"[^"\n]*/(?P<name>[^"/\n]+)' + re.escape(HTML_SUFFIX) + r'"')

# The events on which the release-channel leg is rendered too.
CHANNEL_EVENTS = ('schedule', 'workflow_dispatch')
# The leg every other leg's HTML extraction is compared against, and the name
# `compare` is handed below. Named here so the workflow and this reader cannot
# come to disagree about which leg is the baseline.
BASELINE = 'pinned'


def fail(message):
    print('FAIL: M43: %s' % message)
    return 1


def legs_under(directory):
    """`{leg name: path}` for every `index-<leg>` directory, sorted by name."""
    found = {}
    for name in sorted(os.listdir(directory)):
        path = os.path.join(directory, name)
        if os.path.isdir(path) and name.startswith(LEG_PREFIX):
            found[name[len(LEG_PREFIX):]] = path
    return found


def dumps_in(path, suffix):
    """`{fixture: file path}` for every `<fixture><suffix>` file in one leg."""
    return {name[:-len(suffix)]: os.path.join(path, name)
            for name in sorted(os.listdir(path)) if name.endswith(suffix)}


def check_compare(directory, baseline):
    if not os.path.isdir(directory):
        return fail('%s is not a directory, so no leg was unpacked there'
                    % directory)
    legs = legs_under(directory)
    if baseline not in legs:
        return fail('%s holds no `%s%s` directory; the %d leg(s) unpacked '
                    'there are %s, and the comparison every other leg is '
                    'judged against is this one'
                    % (directory, LEG_PREFIX, baseline, len(legs),
                       sorted(legs) or 'none'))
    others = [name for name in legs if name != baseline]
    if not others:
        # One leg compares against itself and always agrees. A matrix that
        # lost a leg must read as a matrix that lost a leg.
        return fail('%s holds only the `%s` leg, so there is no second '
                    'rendering to compare it against and this job would pass '
                    'by comparing nothing' % (directory, baseline))

    want = dumps_in(legs[baseline], HTML_SUFFIX)
    if not want:
        return fail('the `%s` leg carries no `*%s` extraction, so every leg '
                    'would be compared over an empty set of fixtures'
                    % (baseline, HTML_SUFFIX))
    for fixture, path in sorted(want.items()):
        if os.path.getsize(path) == 0:
            return fail("the `%s` leg's extraction of %s is empty; an empty "
                        'extraction agrees with anything'
                        % (baseline, fixture))

    differed = []
    compared = 0
    for leg in sorted(others):
        got = dumps_in(legs[leg], HTML_SUFFIX)
        if set(got) != set(want):
            return fail('the `%s` leg extracted %s and the `%s` leg extracted '
                        '%s; the two legs did not render the same fixtures, so '
                        'a comparison over their intersection would report '
                        'agreement about a fixture one of them never rendered'
                        % (leg, sorted(got), baseline, sorted(want)))
        for fixture in sorted(want):
            compared += 1
            with open(want[fixture], 'rb') as handle:
                left = handle.read()
            with open(got[fixture], 'rb') as handle:
                right = handle.read()
            if left == right:
                print('ok   M43-AC2: %s — the `%s` leg emits the index the '
                      '`%s` leg emits, byte for byte (%d row(s))'
                      % (fixture, leg, baseline, left.count(b'\n')))
                continue
            differed.append((fixture, leg,
                             first_difference(left, right, baseline, leg)))

    # The domains, before the verdict and whatever the verdict is: the header
    # promises every clause reports the size of what it swept, and a red run
    # is exactly when a reader needs to know whether the sweep was empty.
    print('     M43: %d comparison(s) over %d fixture(s) — %s — against the '
          '`%s` leg, for each of %s'
          % (compared, len(want), ', '.join(sorted(want)), baseline,
             ', '.join(sorted(others))))

    if differed:
        for fixture, leg, where in differed:
            print('FAIL: M43-AC2: %s — the `%s` leg emits a different index '
                  'from the `%s` leg: %s' % (fixture, leg, baseline, where))
        return 1
    print('ok   M43-AC2: every one of the %d comparison(s) above is '
          'byte-identical to the `%s` leg' % (compared, baseline))
    return 0


def first_difference(left, right, baseline, leg):
    """Where two extractions first differ, in words a log reader can act on.

    Each side is named by the leg it came from: a difference reported as
    "there" and "here" leaves a reader guessing which version emitted which
    row, which is the one thing this message exists to say.
    """
    lines = left.decode('utf-8', 'replace').split('\n')
    other = right.decode('utf-8', 'replace').split('\n')
    for number, (a, b) in enumerate(zip(lines, other), start=1):
        if a != b:
            return ('row %d is %r on the `%s` leg and %r on the `%s` leg'
                    % (number, b, leg, a, baseline))
    if len(lines) != len(other):
        if len(other) > len(lines):
            longer, shorter, name = other, lines, leg
        else:
            longer, shorter, name = lines, other, baseline
        return ('the two agree for %d row(s) and then the `%s` leg has %d '
                'more, the first being %r'
                % (len(shorter), name, len(longer) - len(shorter),
                   longer[len(shorter)]))
    return 'the two differ in bytes that are not rows'


def check_legs(floor, pinned, event):
    if floor == pinned:
        # The matrix exists to render on two different Quarto versions. Equal
        # here, `compare` would hold a version against itself and agree.
        return fail('the floor leg and the pinned leg would both render on '
                    'Quarto %s, so this matrix compares a version against '
                    'itself' % floor)
    legs = [{'name': 'floor', 'version': floor},
            {'name': BASELINE, 'version': pinned}]
    if event in CHANNEL_EVENTS:
        legs.append({'name': 'release', 'version': 'release'})
    print(json.dumps(legs))
    return 0


def version_named(body, version):
    """Whether `body` names `version` and not a longer version containing it.

    A bare `version in body` reads `1.4.549` out of `1.4.5490` and out of
    `1.4.549.1`, so a document left naming a release the workflow has moved off
    could pass on a substring of the new number. The bound is over digits and
    dots on either side, and over those alone: a sentence ending
    `… Quarto 1.4.549.` still names it, `v1.4.549` still names it, and so do
    `1.4.549-rc1` and `1.4.549b` — a longer version whose extra part is not a
    digit or a dot is not caught here (M48).
    """
    return re.search(r'(?<![\d.])%s(?!\.?\d)' % re.escape(version),
                     body) is not None


def check_floor(workflow, *docs):
    with open(workflow, encoding='utf-8') as handle:
        text = handle.read()
    floors = FLOOR.findall(text)
    if len(floors) != 1:
        return fail('%s declares %d `FLOOR:` line(s); the floor version this '
                    'check is about is exactly one' % (workflow, len(floors)))
    version = floors[0][1]
    if not EXACT.match(version):
        return fail('%s declares the floor %r, which is not an exact dotted '
                    'version a reader could install' % (workflow, version))
    if not docs:
        return fail('no document was named to hold against the %s floor %s '
                    'declares, so this check would sweep nothing'
                    % (version, workflow))
    for doc in docs:
        with open(doc, encoding='utf-8') as handle:
            body = handle.read()
        if not version_named(body, version):
            return fail('%s pins the floor leg to Quarto %s and %s does not '
                        'name that version anywhere, so a reader is not told '
                        'which Quarto the floor is actually run on'
                        % (workflow, version, doc))
    print('ok   M43-AC5: %s pins the floor leg to Quarto %s, and each of the '
          '%d document(s) named after it says so (%s)'
          % (workflow, version, len(docs), ', '.join(docs)))
    return 0


def check_fixtures(workflow, *names):
    with open(workflow, encoding='utf-8') as handle:
        text = handle.read()
    rendered = sorted(set(EXTRACTION.findall(text)))
    if not rendered:
        return fail('%s carries no `indexdump.py html` invocation writing a '
                    '`*%s` extraction, so this check would hold the suite '
                    'against an empty set of fixtures'
                    % (workflow, HTML_SUFFIX))
    if not names:
        return fail('no fixture name was given to hold against the %d the %s '
                    'render step extracts (%s), so this check would sweep '
                    'nothing' % (len(rendered), workflow, ', '.join(rendered)))
    covered = sorted(set(names))
    if covered != rendered:
        return fail('%s extracts %s and the suite covers %s; the fixture the '
                    'matrix compares and the fixture this run dumps locally '
                    'are not the same set'
                    % (workflow, rendered, covered))
    print('ok   M48-AC4: %s extracts %d fixture(s) — %s — and the suite dumps '
          'that same set locally'
          % (workflow, len(rendered), ', '.join(rendered)))
    return 0


MODES = {
    'fixtures': (check_fixtures, 1),
    'floor': (check_floor, 1),
    'legs': (check_legs, 3),
    'compare': (check_compare, 2),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    func, needed = MODES[argv[1]]
    args = argv[2:]
    # `needed` is the least this mode takes; a mode declared with a `*rest`
    # parameter accepts more, and every other mode is refused extra arguments
    # rather than silently ignoring them.
    variadic = bool(func.__code__.co_flags & 0x04)
    if len(args) < needed or (not variadic and len(args) > needed):
        raise SystemExit(__doc__)
    return func(*args)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
