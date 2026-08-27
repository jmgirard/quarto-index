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

  floor <workflow.yml> <doc> [<doc> ...]
      The workflow declares exactly one floor version, and every document
      named after it states that version. README and the site's Tests page
      both tell a reader which Quarto the floor leg installs, and this is what
      stops the number moving in the workflow while the two documents go on
      naming the old one.

  compare <legs-dir> <baseline>
      `<legs-dir>` holds one directory per leg, named `index-<leg>` — the
      shape `actions/download-artifact` unpacks the uploads into. Every leg's
      HTML extraction is compared, byte for byte, against the leg named
      `<baseline>`. Of the PDF extractions, the fixture NAMES are compared
      across legs and the CONTENT deliberately is not: two Quarto versions
      render PDF through different TeX engines, and the M30 and M33 lessons
      put engine and font differences in a PDF's text layer, so a comparison
      of content would be red about the engine rather than about this
      extension. The baseline leg must carry at least one PDF extraction, so a
      matrix in which every PDF leg failed to upload reads as that rather than
      as agreement about a format nothing rendered. Each leg's PDF render is
      held to exiting 0 with a non-empty index by `indexdump.py` on the leg
      itself.

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
# The two extraction suffixes `indexdump.py` output is written under. Only the
# first is compared across legs; see the header.
HTML_SUFFIX = '.html.txt'
PDF_SUFFIX = '.pdf.txt'


# `FLOOR: <version>` in the workflow's env block, quoted or not. The floor is
# stated once, in the file whose header records where the number came from and
# when the query that returned it ran.
FLOOR = re.compile(
    r'^\s+FLOOR:\s*(?P<quote>[\'"]?)(?P<value>[^\'"\s]+)(?P=quote)\s*$', re.M)
EXACT = re.compile(r'^\d+\.\d+\.\d+$')

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
    """`{fixture: file path}` for every extraction of one kind in one leg."""
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

    # The PDF side: the fixture NAMES are judged and the content is not. A set
    # that is only printed is a set nothing is held to — a run whose PDF legs
    # all failed to upload would print `none` and exit 0, which is the empty
    # agreement this job exists to refuse (M45).
    want_pdf = dumps_in(legs[baseline], PDF_SUFFIX)
    pdf_findings = []
    if not want_pdf:
        pdf_findings.append(
            'the `%s` leg carries no `*%s` extraction, so no leg rendered a '
            'PDF the others could be held to and the PDF half of this matrix '
            'would be enforced nowhere' % (baseline, PDF_SUFFIX))
    else:
        for leg in sorted(others):
            got_pdf = dumps_in(legs[leg], PDF_SUFFIX)
            if set(got_pdf) == set(want_pdf):
                continue
            pdf_findings.append(
                'the `%s` leg extracted the `*%s` fixture(s) %s and the `%s` '
                'leg extracted %s; the two legs did not render the same '
                'fixtures to PDF, and the %d name(s) they differ in are %s'
                % (leg, PDF_SUFFIX, sorted(got_pdf), baseline,
                   sorted(want_pdf),
                   len(set(got_pdf) ^ set(want_pdf)),
                   sorted(set(got_pdf) ^ set(want_pdf))))

    if differed or pdf_findings:
        for fixture, leg, where in differed:
            print('FAIL: M43-AC2: %s — the `%s` leg emits a different index '
                  'from the `%s` leg: %s' % (fixture, leg, baseline, where))
        for finding in pdf_findings:
            fail(finding)
        return 1
    print('ok   M43-AC2: the `%s` leg carries %d PDF extraction(s) — %s — and '
          'each of %s carries the same fixture name set; their content is '
          'deliberately not compared, because two Quarto versions typeset '
          'through different TeX engines'
          % (baseline, len(want_pdf), ', '.join(sorted(want_pdf)),
             ', '.join(sorted(others))))
    print('ok   M43-AC2: %d comparison(s) over %d fixture(s) — %s — against '
          'the `%s` leg, for each of %s; every one byte-identical'
          % (compared, len(want), ', '.join(sorted(want)), baseline,
             ', '.join(sorted(others))))
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


def check_floor(workflow, *docs):
    text = open(workflow, encoding='utf-8').read()
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
        body = open(doc, encoding='utf-8').read()
        if version not in body:
            return fail('%s pins the floor leg to Quarto %s and %s does not '
                        'name that version anywhere, so a reader is not told '
                        'which Quarto the floor is actually run on'
                        % (workflow, version, doc))
    print('ok   M43-AC5: %s pins the floor leg to Quarto %s, and each of the '
          '%d document(s) named after it says so (%s)'
          % (workflow, version, len(docs), ', '.join(docs)))
    return 0


MODES = {
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
