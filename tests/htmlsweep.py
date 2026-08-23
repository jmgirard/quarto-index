"""Sweep every captured HTML artifact for filter residue.

Two promises the suite makes about rendered HTML, each stated over EVERY page
the run rendered rather than over a written-down list of fixtures:

  pending — the `data-qi-pending` attribute is filter plumbing between two
            passes and must never survive into rendered output. An author's
            forged copy must not survive either, which is why the sweep asks
            for the attribute rather than for a mark the filter minted.

  marker  — the author's marker element is consumed by the filter, so no
            rendered page may carry its class, and none may keep the empty div
            a removed marker would leave behind. Quarto's own title block
            carries one empty div in every render, marker or not, so that one
            is named and allowed.

Both walk a ROOT and read every `.html` under it, at any depth: the argument is
the run's capture root, so the domain is exactly what this run's renders
produced — book pages included — and a fixture added to the suite enters the
sweep by being rendered, with nothing to remember to add here. Reading the
working tree instead would sweep whatever the last render of each fixture left
behind, and would silently omit every artifact a later render had removed.

Usage:  python3 tests/htmlsweep.py <pending|marker> <root>

Exits non-zero naming every offending page. The marker mode needs
MARKER_CLASS and QUARTO_EMPTY_DIV in the environment.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402

PENDING_ATTR = 'data-qi-pending'


def pages(root):
    """Every .html under root, relative to it, in a stable order."""
    found = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            if name.endswith('.html'):
                found.append(os.path.relpath(os.path.join(dirpath, name), root))
    return sorted(found)


def sweep_pending(root, names):
    bad = []
    for name in names:
        with open(os.path.join(root, name), encoding='utf-8') as fh:
            if PENDING_ATTR in fh.read():
                bad.append(name)
    if bad:
        return ('%s survived into rendered HTML: %s'
                % (PENDING_ATTR, ' '.join(bad)))
    return None


def sweep_marker(root, names):
    marker = os.environ['MARKER_CLASS']
    allowed = os.environ['QUARTO_EMPTY_DIV']
    bad = []
    for name in names:
        doc = H.parse(os.path.join(root, name))
        kept = [n.tag for n in H.walk(doc) if marker in H.classes(n)]
        if kept:
            bad.append('%s: %d element(s) still carry the marker class'
                       % (name, len(kept)))
        stray = [n.attrs.get('class', '') for n in H.empty_divs(doc)
                 if allowed not in H.classes(n)]
        if stray:
            bad.append('%s: empty div(s) left where a marker was removed: %s'
                       % (name, stray))
    if bad:
        return 'marker residue in rendered HTML: ' + '; '.join(bad)
    return None


MODES = {'pending': sweep_pending, 'marker': sweep_marker}


def main(argv):
    if len(argv) != 3 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    mode, root = argv[1], argv[2]
    names = pages(root)
    if not names:
        # An empty domain is the vacuous pass this sweep exists to avoid: a
        # root holding no page would report "no residue anywhere" having read
        # nothing at all.
        raise SystemExit('FAIL: M24: no rendered HTML under %s, so the %s '
                         'sweep would pass having read nothing' % (root, mode))
    problem = MODES[mode](root, names)
    if problem:
        print('FAIL: %s' % problem, file=sys.stderr)
        return 1
    print('ok   the %s sweep read %d captured page(s) and found none'
          % (mode, len(names)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
