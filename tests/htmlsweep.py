"""Sweep every captured HTML artifact for filter residue.

Three promises the suite makes about rendered HTML. The first two are stated
over EVERY page the run rendered rather than over a written-down list of
fixtures; the third is stated only where a marker was removed.

  pending — the `data-qi-pending` attribute is filter plumbing between two
            passes and must never survive into rendered output. An author's
            forged copy must not survive either, which is why the sweep asks
            for the attribute rather than for a mark the filter minted. It
            asks STRUCTURALLY — an element of the parsed page carrying that
            attribute — and not for the string in the markup. The promise is
            about an attribute a page carries, and the site's gallery prints
            examples/html-index.qmd's source in a code block, where the forged
            copy that fixture writes is text a reader is meant to see (M41).

  marker  — the author's marker element is consumed by the filter, so a
            rendered page carries its class only where the fixture wrote a
            marker the filter deliberately leaves alone. Comparison is
            EQUALITY per page against the map below, so a page that silently
            gains one fails exactly as one that silently loses one.

  emptydiv — a removed marker leaves no empty div behind. Unlike the two
            above this is checkable only where a marker WAS removed: every
            rendered page carries empty divs Quarto itself wrote, so the mode
            takes the pages to read as arguments rather than sweeping a root.

The first two walk a ROOT and read every `.html` under it, at any depth: the
argument is the run's capture root, so the domain is exactly what this run's
renders produced — book pages included — and a fixture added to the suite
enters the sweep by being rendered, with nothing to remember to add here.
Reading the working tree instead would sweep whatever the last render of each
fixture left behind, and would silently omit every artifact a later render had
removed.

Usage:  python3 tests/htmlsweep.py <pending|marker> <root>
        python3 tests/htmlsweep.py emptydiv <page>...

Exits non-zero naming every offending page. The marker and emptydiv modes need
MARKER_CLASS in the environment, and emptydiv also needs QUARTO_EMPTY_DIV.
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
        doc = H.parse(os.path.join(root, name))
        if any(PENDING_ATTR in node.attrs for node in H.walk(doc)):
            bad.append(name)
    if bad:
        return ('%s survived into rendered HTML: %s'
                % (PENDING_ATTR, ' '.join(bad)))
    return None


# The pages that carry the marker class on purpose, and how many elements each
# carries. Everything else in the captured set must carry none.
#
#   marker-sites  — four sites where an author put the marker somewhere the
#                   filter refuses to place an index (M08-AC3 reads the same
#                   page and asserts what each of them still contains).
#   marker-shapes — the one occurrence Quarto writes from the fixture's own
#                   YAML title, which is metadata the marker machinery never
#                   reaches (M12-AC5 reads the same page and asserts that this
#                   occurrence sits in the title block and not in a body).
KEPT_MARKERS = {'sites-html/marker-sites.html': 4,
                'shapes-html/marker-shapes.html': 1}


def sweep_marker(root, names):
    marker = os.environ['MARKER_CLASS']
    bad = []
    for name in names:
        doc = H.parse(os.path.join(root, name))
        kept = [n.tag for n in H.walk(doc) if marker in H.classes(n)]
        want = KEPT_MARKERS.get(name, 0)
        if len(kept) != want:
            bad.append('%s carries %d element(s) with the marker class, want %d'
                       % (name, len(kept), want))
    missing = sorted(set(KEPT_MARKERS) - set(names))
    if missing:
        bad.append('the captured set holds no %s, so the pages that carry a '
                   'marker on purpose went unread' % missing)
    if bad:
        return 'marker residue in rendered HTML: ' + '; '.join(bad)
    return None


def sweep_emptydiv(pages_to_read):
    """No empty div where a marker was removed, on the pages named."""
    marker = os.environ['MARKER_CLASS']
    allowed = os.environ['QUARTO_EMPTY_DIV']
    bad = []
    for path in pages_to_read:
        doc = H.parse(path)
        kept = [n.tag for n in H.walk(doc) if marker in H.classes(n)]
        if kept:
            bad.append('%s: %d element(s) still carry the marker class'
                       % (path, len(kept)))
        stray = [n.attrs.get('class', '') for n in H.empty_divs(doc)
                 if allowed not in H.classes(n)]
        if stray:
            bad.append('%s: empty div(s) left where a marker was removed: %s'
                       % (path, stray))
    if bad:
        return 'marker residue in rendered HTML: ' + '; '.join(bad)
    return None


MODES = {'pending': sweep_pending, 'marker': sweep_marker}


def main(argv):
    if len(argv) > 2 and argv[1] == 'emptydiv':
        problem = sweep_emptydiv(argv[2:])
        if problem:
            print('FAIL: %s' % problem, file=sys.stderr)
            return 1
        print('ok   no marker element and no empty div in any of the %d page(s) '
              'a marker was removed from' % len(argv[2:]))
        return 0
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
    print('ok   the %s sweep read %d captured page(s) and each held exactly '
          'what it should' % (mode, len(names)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
