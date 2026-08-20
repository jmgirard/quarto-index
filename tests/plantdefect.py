"""Plant one defect in a moved-definition tree and name the failure it must cause.

The other half of the M16-AC3 probe. `tests/movedefs.py` shows a check still
FINDS what it reads once the definition moves; that alone is satisfied by a
check that has stopped asserting anything. So for each source-reading check,
plant a defect of the kind that check names — in the moved definition, in the
module file — and require the check to fail, and to fail SAYING SO: the marker
printed here is the text the run greps the check's output for, so a scan that
died for some other reason cannot be read as the scan catching this.

Usage:  python3 tests/plantdefect.py <scratch-ext-dir> <scan-name>

Prints the expected failure marker. An aimed-at text the module does not carry
is an error rather than a no-op: a defect that planted nothing would leave the
check passing and be reported as the check failing to discriminate, which is a
defect in the probe wearing the costume of a finding.
"""

import os
import sys

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
        'FAIL: M02-AC5: found 37 warn() messages, expected 38'),
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


def main(argv):
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
