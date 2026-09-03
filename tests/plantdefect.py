"""Plant one defect in a moved-definition tree and name the failure it must cause.

The other half of the M16-AC3 probe. `tests/movedefs.py` shows a check still
FINDS what it reads once the definition moves; that alone is satisfied by a
check that has stopped asserting anything. So for each source-reading check,
plant a defect of the kind that check names — in the moved definition, in the
module file — and require the check to fail, and to fail SAYING SO: the marker
printed here is the text the run greps the check's output for, so a scan that
died for some other reason cannot be read as the scan catching this.

Usage:  python3 tests/plantdefect.py <scratch-ext-dir> <scan-name>
        python3 tests/plantdefect.py --duplicate <scratch-ext-dir> <scan-name>
        python3 tests/plantdefect.py --html <captured-page> <residue-kind>
        python3 tests/plantdefect.py --separator <captured-page> <kind>

Prints the expected failure marker. An aimed-at text the module does not carry
is an error rather than a no-op: a defect that planted nothing would leave the
check passing and be reported as the check failing to discriminate, which is a
defect in the probe wearing the costume of a finding.
"""

import os
import re
import sys

# The count the `warn-distinct` source scan pins, read from that file rather
# than copied here: the marker below has to name the number the scan will
# print, and two files holding the same number is two files that must change
# together and one that will not (M16 review F11).
_WARN_DISTINCT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              'scans', 'warn-distinct.py')
_WARN_EXPECTED = int(re.search(r'^EXPECTED = (\d+)$',
                               open(_WARN_DISTINCT, encoding='utf-8').read(),
                               re.M).group(1))

# scan name -> (old text, new text, expected failure marker)
#
# The old text is the definition AS IT SITS in modules/moved.lua. A value the
# check pins gets a changed value (the disagreement it exists to catch); a
# definition the check merely has to locate gets renamed out of reach (the
# disappearance it exists to catch), since changing such a value is a reading
# the check is supposed to accept, not a defect.
DEFECTS = {
    'latex-escape-table': (
        '  ["%"] = "\\\\%",\n',
        '',
        'FAIL: AC4: probe characters do not match the filter escape table'),
    'html-identifiers': (
        'local HTML_ANCHOR_PREFIX = "qi-mark-"',
        'local HTML_ANCHOR_PREFIX = "qi-planted-"',
        'FAIL: M03-AC3: the suite and the filter disagree on the HTML'),
    'xref-manifest': (
        'local XREF_BOTH_COMMAND = "quartoindexseeboth"',
        'local XREF_BOTH_COMMAND = "quartoindexseebothplanted"',
        'FAIL: M02-AC1: manifest names'),
    'warn-distinct': (
        'warn((',
        'notwarn((',
        f'FAIL: M02-AC5: found {_WARN_EXPECTED - 1} warn() messages, '
        f'expected {_WARN_EXPECTED}'),
    'xref-both-definition': (
        '\\\\emph{\\\\seename}',
        '\\\\emph{see}',
        'FAIL: M02-AC5: the dual-target definition does not use \\seename'),
    'marker-class': (
        'local MARKER_CLASS = "qi-index-here"',
        'local MARKER_CLASS = "qi-planted-here"',
        'FAIL: M04-AC1: suite says'),
    'mark-report-keys': (
        'names the entry it is written on',
        'names the entry it is written upon',
        'FAIL: M10-AC4: key <<names the entry it is written on>> matches 0 '
        'filter warnings, want 1'),
    'store-version': (
        'local STORE_VERSION = ',
        'local STORE_VERSION_PLANTED = ',
        'FAIL: M05-AC1: expected exactly one STORE_VERSION definition'),
    'store-names': (
        'local STORE_SUFFIX = ".qi.json"',
        'local STORE_SUFFIX = ".qi-planted.json"',
        "FAIL: M05-AC1: the suite and the filter disagree on the store's name"),
    'max-levels': (
        'local MAX_LEVELS = ',
        'local MAX_LEVELS_PLANTED = ',
        'FAIL: M09: expected exactly one MAX_LEVELS definition'),
    'overflow-join': (
        'local OVERFLOW_JOIN = ',
        'local OVERFLOW_JOIN_PLANTED = ',
        'FAIL: M09: expected exactly one OVERFLOW_JOIN definition'),
    'm15-joined-messages': (
        'so check that is the entry you meant',
        'so check that is the entry you meant, and note that the index tool '
        'rejects the pair and the render fails',
        'FAIL: M15-AC5: 1 joined warn() message(s) still tell an author'),
}


# The DUPLICATE plant (M25). The plants above all change a VALUE, and a
# value-changing plant passes a first-match reader exactly as it passes an
# exactly-one one: it cannot show that the narrowed scans gained anything.
# What M25 actually added is the count clause, so its own defect is a second
# definition — the stale duplicate left behind by a split that M16 review F3
# named. Each entry is the anchor text whose WHOLE LINE is appended a second
# time to the moved module, and the marker the scan must print for it.
#
# Every key of DEFECTS appears here, `None` where the scan pins no single
# definition to duplicate, so a scan added later cannot slip through this
# probe by simply not being listed.
DUPLICATES = {
    'latex-escape-table': (
        'local LATEX_LITERAL = {',
        'FAIL: AC4: expected exactly one LATEX_LITERAL table in the filter '
        'source set, found 2'),
    'html-identifiers': (
        'local HTML_ANCHOR_PREFIX = "qi-mark-"',
        'HTML_ANCHOR_PREFIX has 2 definition(s) in the filter source set, '
        'want exactly 1'),
    'xref-manifest': (
        'local XREF_BOTH_COMMAND = "quartoindexseeboth"',
        'FAIL: M02-AC1: expected exactly one XREF_BOTH_COMMAND definition in '
        'the filter source set, found 2'),
    'warn-distinct': None,
    'xref-both-definition': (
        'local XREF_BOTH_DEFINITION =',
        'FAIL: M02-AC5: expected exactly one XREF_BOTH_DEFINITION definition '
        'in the filter source set, found 2'),
    'marker-class': (
        'local MARKER_CLASS = "qi-index-here"',
        'FAIL: M04-AC1: expected exactly one MARKER_CLASS definition in the '
        'filter source set, found 2'),
    'mark-report-keys': None,
    'store-version': (
        'local STORE_VERSION = ',
        'FAIL: M05-AC1: expected exactly one STORE_VERSION definition in the '
        'filter source set, found 2'),
    'store-names': (
        'local STORE_SUFFIX = ".qi.json"',
        'FAIL: M05-AC1: expected exactly one STORE_SUFFIX definition in the '
        'filter source set, found 2'),
    'max-levels': (
        'local MAX_LEVELS = ',
        'FAIL: M09: expected exactly one MAX_LEVELS definition in the filter '
        'source set, found 2'),
    'overflow-join': (
        'local OVERFLOW_JOIN = ',
        'FAIL: M09: expected exactly one OVERFLOW_JOIN definition in the '
        'filter source set, found 2'),
    'm15-joined-messages': None,
}
_UNLISTED = sorted(set(DEFECTS) - set(DUPLICATES))
if _UNLISTED:
    raise SystemExit(
        'FAIL: plantdefect: %s has a value plant and no duplicate-plant '
        'decision; add an entry (or None) to DUPLICATES rather than leaving '
        'the count clause unprobed' % ', '.join(_UNLISTED))


def plant_duplicate(root, name):
    """Append a second copy of a scan's pinned definition line; print its marker.

    Prints `SKIP` for a scan that pins no single definition, so the caller can
    tell "nothing to duplicate here" from "the plant landed".
    """
    if name not in DUPLICATES:
        raise SystemExit(
            'FAIL: plantdefect: no duplicate-plant decision for the source '
            'scan %r' % name)
    if DUPLICATES[name] is None:
        print('SKIP')
        return
    anchor, marker = DUPLICATES[name]
    path = os.path.join(root, 'modules', 'moved.lua')
    src = open(path, encoding='utf-8').read()
    hits = [l for l in src.split('\n') if l.startswith(anchor)]
    if len(hits) != 1:
        raise SystemExit(
            'FAIL: plantdefect: %s carries %d line(s) starting <<%s>>, want 1, '
            'so the duplicate plant for %r would plant nothing or start from a '
            'tree that is already wrong' % (path, len(hits), anchor, name))
    with open(path, 'a', encoding='utf-8') as handle:
        handle.write('\n' + hits[0] + '\n')
    print(marker)


# The residue plants (M24; the `meta` plant added M071). Each is the defect its sweep in
# tests/htmlsweep.py exists to catch, planted into one captured page so the
# sweep is shown to READ that page and not merely to walk past it: a sweep over
# a set is satisfied by a set it never opens, which is the vacuous pass the
# per-file checks it replaced could not have.
#
# The marker class is read from the environment, not written down here, for the
# reason the warn-distinct count above is read from its scan: the run pins it to
# the filter's own constant, and a second copy is one more thing that must
# change with it and will not.
#
# Each plant names the text its sweep prints, WITHOUT the page's name — the
# caller knows which page it planted into and requires that name in the output
# too, which is what says the sweep caught this page rather than some other.
HTML_DEFECTS = {
    'pending': ('<body', '<body data-qi-pending="planted"',
                'data-qi-pending survived into rendered HTML'),
    # The tagging pass's plumbing (M071), read by the same `pending` sweep.
    'meta': ('<body', '<body data-qi-meta="planted"',
             'data-qi-meta survived into rendered HTML'),
    'marker': ('</body>', '<div class="%s">planted</div></body>',
               'marker residue in rendered HTML'),
    'emptydiv': ('</body>', '<div class="qi-planted-empty"></div></body>',
                 'empty div(s) left where a marker was removed'),
}


# The separator defects (M58), planted in a captured index page. Each names a
# FORM of failure and not just a place: a glyph swapped for the English one, a
# separator gone entirely, the space after it lost, the wrong key consulted at
# a printed position, and a per-index declaration ignored in favour of the
# document's. A matrix that varied only the position would be five copies of
# one probe.
#
# The aimed-at text is the markup around ONE printed position, so a plant that
# matched several would be reported as this probe's fault rather than as the
# check's. Each marker is the substring the check prints for that form, without
# the label the caller passes in — the caller knows which page it planted into.
SEPARATOR_DEFECTS = {
    'glyph': (
        '<span id="qi-entry-1" class="qi-term">Azurite</span>\u060c ',
        '<span id="qi-entry-1" class="qi-term">Azurite</span>, ',
        "prints ',' at S1, where the manifest states"),
    'dropped': (
        'Azurite</span>\u060c <span class="qi-locators">',
        'Azurite</span><span class="qi-locators">',
        "prints '' at S1, where the manifest states"),
    'spacing': (
        'Azurite</span>\u060c <span class="qi-locators">',
        'Azurite</span>\u060c<span class="qi-locators">',
        "follows the S1 mark with ''"),
    'wrongkey': (
        '\u061b <span class="qi-xref qi-see-also">',
        '\u060c <span class="qi-xref qi-see-also">',
        "prints '\u060c' at S5, where the manifest states"),
    'scoped': (
        '<span id="qi-entry-3" class="qi-term">Electrum</span>~ ',
        '<span id="qi-entry-3" class="qi-term">Electrum</span>\u00b7 ',
        "prints '\u00b7' at S1, where the manifest states"),
}


def plant_separator(path, kind):
    """Plant one separator defect in a captured index page; print its marker."""
    if kind not in SEPARATOR_DEFECTS:
        raise SystemExit('FAIL: plantdefect: no separator defect named %r'
                         % kind)
    old, new, marker = SEPARATOR_DEFECTS[kind]
    src = open(path, encoding='utf-8').read()
    found = src.count(old)
    if found != 1:
        raise SystemExit(
            'FAIL: plantdefect: %s carries %d occurrence(s) of <<%s>>, where '
            'the %r defect aims at exactly one; it plants nothing or plants in '
            'more than one place, and the check that follows would be reported '
            'as failing to discriminate when the fault is this mutation\'s'
            % (path, found, old, kind))
    open(path, 'w', encoding='utf-8').write(src.replace(old, new, 1))
    print(marker)


def plant_html(path, kind):
    """Plant one residue defect in a captured HTML page; print its marker."""
    if kind not in HTML_DEFECTS:
        raise SystemExit('FAIL: plantdefect: no HTML residue defect named %r'
                         % kind)
    old, new, marker = HTML_DEFECTS[kind]
    if kind == 'marker':
        new = new % os.environ['MARKER_CLASS']
    src = open(path, encoding='utf-8').read()
    if old not in src:
        raise SystemExit(
            'FAIL: plantdefect: %s carries no <<%s>>, so the %r defect plants '
            'nothing and the sweep that follows would be reported as failing '
            'to discriminate when the fault is this mutation\'s'
            % (path, old, kind))
    open(path, 'w', encoding='utf-8').write(src.replace(old, new, 1))
    print(marker)


def main(argv):
    if len(argv) == 4 and argv[1] == '--separator':
        return plant_separator(argv[2], argv[3])
    if len(argv) == 4 and argv[1] == '--html':
        return plant_html(argv[2], argv[3])
    if len(argv) == 4 and argv[1] == '--duplicate':
        return plant_duplicate(argv[2], argv[3])
    if len(argv) != 3:
        raise SystemExit(__doc__)
    root, name = argv[1], argv[2]
    if name not in DEFECTS:
        raise SystemExit(
            'FAIL: plantdefect: no defect defined for the source scan %r; it '
            'would be probed for finding its definition and never for still '
            'asserting anything about it' % name)
    old, new, marker = DEFECTS[name]
    path = os.path.join(root, 'modules', 'moved.lua')
    src = open(path, encoding='utf-8').read()
    if old not in src:
        raise SystemExit(
            'FAIL: plantdefect: %s does not carry <<%s>>, so the defect for '
            '%r plants nothing' % (path, old, name))
    open(path, 'w', encoding='utf-8').write(src.replace(old, new, 1))
    print(marker)


if __name__ == '__main__':
    main(sys.argv)
