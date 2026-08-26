"""Checks over the Pages workflow and what it publishes (M42).

  pin <workflow.yml> <extension.yml>
      The workflow pins Quarto to an exact version string, and that string
      satisfies the `quarto-required` range the extension declares. Both the
      pin and the range's version are split on `.` and compared as tuples of
      integers, so `1.10.18` is read as greater than `1.4.0` rather than as
      the string that sorts before it. Only a `>=` range is understood; any
      other operator is an error rather than a comparison this reader guesses
      at.

  built <gallery.yml> <rendered-site>
      The rendered site carries the entry page a visitor lands on, and every
      fixture the gallery declaration shows has its gallery page, its rendered
      index page and its PDF. This is the render-completeness guard the
      workflow runs before it uploads: `quarto render` reports a nested
      fixture render failing without failing the outer render, so a site that
      exits 0 having dropped a page reaches Pages unless something looks.

  contains <artifact-dir> <rendered-site>
      Every `.html` and `.pdf` path under the rendered site appears in the
      unpacked Pages artifact at the same relative path. The rendered site is
      the reference and the artifact the thing judged, so an upload that took
      the wrong directory, or a render on the runner that dropped pages the
      same commit produces here, reads as missing paths. A floor on the `.pdf`
      count is asserted too, so an artifact and a reference that are both
      empty of PDFs cannot pass by agreeing.

Each mode reports the size of the domain it swept, so a domain that has gone
empty reads as empty rather than as a pass.

Usage:  python3 tests/pagescheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import os
import re
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'site'))
from build_gallery import read_gallery  # noqa: E402

# AC1's floor. The gallery shows ten fixtures and renders a PDF for each; the
# criterion promises at least three, so this is the number a check may rely on
# without pinning the gallery's size.
PDF_FLOOR = 3

# `version: 1.10.18` under the Quarto setup action's `with:` block. The value
# is required to be a bare dotted numeric string: `release`, `pre-release` and
# a bare major line are channels, not pins, and the criterion is about a pin.
PIN = re.compile(r'^\s+version:\s*(?P<value>\S+)\s*$')
EXACT = re.compile(r'^\d+(\.\d+)*$')
REQUIRED = re.compile(r'^quarto-required:\s*"?(?P<range>[^"\n]+?)"?\s*$')


def fail(message):
    print('FAIL: M42: %s' % message)
    return 1


def parts(version):
    return tuple(int(piece) for piece in version.split('.'))


def check_pin(workflow, extension):
    pins = []
    with open(workflow, encoding='utf-8') as handle:
        for number, line in enumerate(handle.read().split('\n'), start=1):
            match = PIN.match(line)
            if match:
                pins.append((number, match.group('value')))
    if len(pins) != 1:
        return fail('%s declares %d `version:` line(s) under a `with:` block; '
                    'the pin this check is about is exactly one'
                    % (workflow, len(pins)))
    number, pinned = pins[0]
    if not EXACT.match(pinned):
        return fail('%s line %d pins Quarto to %r, which is not an exact '
                    'version string; a channel name or a partial version is '
                    'not a pin' % (workflow, number, pinned))

    ranges = []
    with open(extension, encoding='utf-8') as handle:
        for line in handle.read().split('\n'):
            match = REQUIRED.match(line)
            if match:
                ranges.append(match.group('range').strip())
    if len(ranges) != 1:
        return fail('%s declares %d `quarto-required:` line(s); the range this '
                    'check compares against is exactly one'
                    % (extension, len(ranges)))
    declared = ranges[0]
    if not declared.startswith('>='):
        return fail('%s declares the range %r; this check understands only a '
                    '`>=` floor, and refuses to guess at any other operator'
                    % (extension, declared))
    floor = declared[2:].strip()
    if not EXACT.match(floor):
        return fail('%s declares the floor %r, which is not a dotted numeric '
                    'version this check can compare' % (extension, floor))

    if parts(pinned) < parts(floor):
        return fail('%s pins Quarto to %s, which is below the %s floor %s '
                    'declares: %r < %r as integer tuples'
                    % (workflow, pinned, floor, extension,
                       parts(pinned), parts(floor)))
    print('ok   M42-AC3: %s pins Quarto to %s, and %r >= %r as integer '
          'tuples, so the pin satisfies the %r range %s declares'
          % (workflow, pinned, parts(pinned), parts(floor), declared,
             extension))
    return 0


def check_built(declaration, site):
    shown, _order = read_gallery(declaration)
    fixtures = shown.get('shown', [])
    if not fixtures:
        return fail('%s shows no fixture, so the per-fixture clauses below '
                    'would sweep nothing' % declaration)

    missing = []
    entry = os.path.join(site, 'index.html')
    if not os.path.isfile(entry):
        missing.append('%s — the page a visitor landing on the site gets'
                       % entry)

    pdfs = 0
    for fixture in fixtures:
        name = os.path.splitext(os.path.basename(fixture))[0]
        for relative, what in (
                ('gallery/%s.html' % name, 'its gallery page'),
                ('gallery/rendered/%s.html' % name, 'its rendered index page'),
                ('gallery/rendered/%s.pdf' % name, 'its PDF')):
            path = os.path.join(site, relative)
            if os.path.isfile(path):
                if relative.endswith('.pdf'):
                    pdfs += 1
            else:
                missing.append('%s — %s for %s' % (path, what, fixture))
    if missing:
        return fail('the render left %d path(s) the published site needs:\n'
                    '  %s' % (len(missing), '\n  '.join(missing)))
    if pdfs < PDF_FLOOR:
        return fail('the render wrote %d fixture PDF(s) under %s; the '
                    'criterion states at least %d' % (pdfs, site, PDF_FLOOR))
    print('ok   M42: %s carries index.html, and each of the %d shown '
          'fixture(s) has its gallery page, its rendered index page and its '
          'PDF (%d PDF(s), floor %d)'
          % (site, len(fixtures), pdfs, PDF_FLOOR))
    return 0


def published(root):
    """Every `.html` and `.pdf` path under `root`, relative to it."""
    found = set()
    for base, _dirs, files in os.walk(root):
        for name in files:
            if name.endswith('.html') or name.endswith('.pdf'):
                found.add(os.path.relpath(os.path.join(base, name), root))
    return found


def check_contains(artifact, site):
    for path, what in ((artifact, 'the unpacked Pages artifact'),
                       (site, 'the rendered site')):
        if not os.path.isdir(path):
            return fail('%s is not a directory, so %s has nothing to compare'
                        % (path, what))
    wanted = published(site)
    if not wanted:
        return fail('%s holds no .html or .pdf path at all, so the '
                    'containment below would be a comparison against nothing'
                    % site)
    reference_pdfs = sorted(p for p in wanted if p.endswith('.pdf'))
    if len(reference_pdfs) < PDF_FLOOR:
        return fail('%s holds %d .pdf path(s); the criterion states the set '
                    'compared holds at least %d'
                    % (site, len(reference_pdfs), PDF_FLOOR))
    got = published(artifact)
    absent = sorted(wanted - got)
    if absent:
        return fail('%s is missing %d of the %d .html/.pdf path(s) %s '
                    'produces:\n  %s'
                    % (artifact, len(absent), len(wanted), site,
                       '\n  '.join(absent)))
    print('ok   M42-AC1: %s contains all %d .html/.pdf path(s) %s produces, '
          'among them %d .pdf path(s) (floor %d)'
          % (artifact, len(wanted), site, len(reference_pdfs), PDF_FLOOR))
    return 0


MODES = {
    'pin': (check_pin, 2),
    'built': (check_built, 2),
    'contains': (check_contains, 2),
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
