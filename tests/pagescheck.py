"""Checks over the Pages workflow and what it publishes (M42).

  pin <workflow.yml> <extension.yml>
      The workflow pins Quarto to an exact version string, and that string
      satisfies the `quarto-required` range the extension declares. Both the
      pin and the range's version are split on `.` and compared as tuples of
      integers, so `1.10.18` is read as greater than `1.4.0` rather than as
      the string that sorts before it. Only a `>=` range is understood; any
      other operator is an error rather than a comparison this reader guesses
      at.

  version <workflow.yml>
      Print, to stdout and alone, the exact Quarto version that workflow pins
      — the same pin `pin` above locates, read through the same function. The
      version matrix (M43) runs one leg on "the version pages.yml installs",
      and asks this rather than carrying its own copy of the number.

  built <gallery.yml> <rendered-site>
      The rendered site carries the entry page a visitor lands on, and every
      fixture the gallery declaration shows has its gallery page, its rendered
      index page and its PDF. This is the render-completeness guard the
      workflow runs before it uploads: Quarto reports a nested fixture render
      failing without failing the render that invoked it, so a site that exits
      0 having dropped a page reaches Pages unless something looks.

  url <readme> <site-index> <runner> [repo-dir]
      README and the site's own entry page both name the URL GitHub Pages
      serves this repository's site at, and the base path `<runner>` resolves
      a root-relative link against is that URL's own path segment. The URL is
      derived from the `origin` remote rather than written into this check, so
      the two documents are held against a fact neither of them states, and
      the base path and the published URL cannot drift apart.

  output <status-listing> <ignored-listing> <tracked-listing>
      The render leaves nothing untracked under `site/` and git tracks nothing
      under the two directories it writes. The three listings are git's own
      output, captured by the caller: `git status --porcelain -z` split on its
      NUL separators (`-z`, so a path with a non-ASCII or special character is
      never C-quoted and cannot slip past an anchored pattern), the same with
      `--ignored`, and `git ls-files` over the two output directories. The
      ignored listing is the non-vacuity control: the render just wrote
      `site/_site/`, so git must report it ignored, and a listing that names it
      nowhere is not a reading of the tree the other two clauses are about.

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
import subprocess
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'site'))
from build_gallery import read_gallery  # noqa: E402

# AC1's floor. The gallery shows ten fixtures and renders a PDF for each; the
# criterion promises at least three, so this is the number a check may rely on
# without pinning the gallery's size.
PDF_FLOOR = 3

# `SITE_BASE_PATH="<value>"` at column 0 in the suite: the assignment, not the
# uses of the variable that follow it.
BASE_PATH = re.compile(r'^SITE_BASE_PATH="(?P<value>[^"]*)"\s*$', re.M)
# `https://github.com/<owner>/<repo>` or `git@github.com:<owner>/<repo>`, with
# an optional `.git`.
REMOTE = re.compile(
    r'^(?:https://github\.com/|git@github\.com:)'
    r'(?P<owner>[^/]+)/(?P<repo>[^/]+?)(?:\.git)?$')

# The Quarto setup action's step, and the `version:` line inside it. Read as a
# pair, because a `version:` line anywhere in the file would otherwise be taken
# for the pin: with the pin deleted from this step and an unrelated step
# carrying one, a pattern matching any indented `version:` reports the workflow
# pinned while Quarto tracks whatever is current (check-design, M23). The step
# runs from its own `- ` to the next line at that indentation or shallower.
SETUP_STEP = re.compile(
    r'^(?P<indent>[ ]*)-[^\n]*\n'
    r'(?:(?P=indent)[ ][^\n]*\n|[ ]*\n)*?'
    r'(?P=indent)[ ]+uses:[ ]*quarto-dev/quarto-actions/setup@[^\n]*\n'
    r'(?:(?P=indent)[ ][^\n]*\n|[ ]*\n)*', re.M)
# `version: <value>` inside that step. The value is required to be a full
# dotted version: `release` and `pre-release` are channels, and a bare major or
# major.minor line names a line rather than a release, so neither is a pin. An
# optional pair of surrounding quotes is stripped, as the range parser below
# strips them, so the two readers in this file agree on YAML quoting.
PIN = re.compile(r'^\s+version:\s*(?P<value>\S+)\s*$')
EXACT = re.compile(r'^\d+\.\d+\.\d+$')
REQUIRED = re.compile(r'^quarto-required:\s*"?(?P<range>[^"\n]+?)"?\s*$')


def fail(message):
    print('FAIL: M42: %s' % message)
    return 1


def parts(version):
    return tuple(int(piece) for piece in version.split('.'))


def read_pin(workflow):
    """The exact Quarto version `workflow` pins: `(version, None)`, or
    `(None, message)` naming what stopped this reader.

    Split out of `check_pin` so the version matrix can ASK a workflow which
    Quarto it installs (the `version` mode) through the same reader that judges
    the pin, rather than through a second pattern that could come to disagree
    with this one about where the pin lives.
    """
    text = open(workflow, encoding='utf-8').read()
    steps = list(SETUP_STEP.finditer(text))
    if len(steps) != 1:
        return None, ('%s declares %d step(s) using quarto-dev/quarto-actions/'
                      'setup; the pin this check is about lives in exactly one'
                      % (workflow, len(steps)))
    step = steps[0]
    first = text[:step.start()].count('\n') + 1
    pins = []
    for number, line in enumerate(step.group(0).split('\n'), start=first):
        match = PIN.match(line)
        if match:
            pins.append((number, match.group('value')))
    if len(pins) != 1:
        return None, ('%s declares %d `version:` line(s) inside the step that '
                      'uses quarto-dev/quarto-actions/setup; the pin this '
                      'check is about is exactly one' % (workflow, len(pins)))
    number, pinned = pins[0]
    if len(pinned) > 2 and pinned[0] == pinned[-1] and pinned[0] in '"\'':
        pinned = pinned[1:-1]
    if not EXACT.match(pinned):
        return None, ('%s line %d pins Quarto to %r, which is not an exact '
                      'version string; a channel name or a partial version is '
                      'not a pin' % (workflow, number, pinned))
    return pinned, None


def check_version(workflow):
    """Print the exact Quarto version `workflow` pins, and nothing else.

    stdout carries the version alone, so a workflow step can capture it into a
    matrix entry; anything this reader has to say goes to stderr. The version
    matrix's pinned leg is defined as "the version pages.yml installs" (M43),
    and reading it here at run time is what keeps that true when the pin moves,
    instead of leaving a second copy of the number to drift.
    """
    pinned, bad = read_pin(workflow)
    if bad is not None:
        print('FAIL: M43: %s' % bad, file=sys.stderr)
        return 1
    print(pinned)
    return 0


def check_pin(workflow, extension):
    pinned, bad = read_pin(workflow)
    if bad is not None:
        return fail(bad)

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


def check_url(readme, site_index, runner, repo_dir='.'):
    result = subprocess.run(
        ['git', '-C', repo_dir, 'remote', 'get-url', 'origin'],
        capture_output=True, text=True)
    if result.returncode != 0:
        return fail('%s has no `origin` remote to derive the published URL '
                    'from, so the URLs below would be held against nothing: '
                    '%s' % (repo_dir, result.stderr.strip()))
    remote = result.stdout.strip()
    match = REMOTE.match(remote)
    if not match:
        return fail('the `origin` remote of %s is %r, which this check cannot '
                    'read as a GitHub owner and repository; the published URL '
                    'is derived from those two and from nothing else'
                    % (repo_dir, remote))
    owner, repo = match.group('owner'), match.group('repo')
    site_url = 'https://%s.github.io/%s/' % (owner.lower(), repo)

    wrong = []
    for path, what in ((readme, 'the repository README'),
                       (site_index, "the site's own entry page")):
        text = open(path, encoding='utf-8').read()
        if site_url not in text:
            wrong.append('%s (%s) does not name %s' % (path, what, site_url))
    if wrong:
        return fail('the published URL the `origin` remote %s implies is %s, '
                    'and %d document(s) do not name it:\n  %s'
                    % (remote, site_url, len(wrong), '\n  '.join(wrong)))

    found = BASE_PATH.findall(open(runner, encoding='utf-8').read())
    if len(found) != 1:
        return fail('%s makes %d assignment(s) to SITE_BASE_PATH; the base '
                    'path this check compares is exactly one'
                    % (runner, len(found)))
    if found[0] != repo:
        return fail('%s resolves a root-relative link against the base path '
                    '%r, and the site is published under %r — the path '
                    'segment of %s. A link the check calls resolved would be '
                    'a 404 in production' % (runner, found[0], repo, site_url))
    print('ok   M42-AC6: %s and %s both name %s, the URL the `origin` remote '
          '%s implies, and %s resolves a root-relative link against %r, that '
          "URL's own path segment"
          % (readme, site_index, site_url, remote, runner, found[0]))
    return 0


def check_output(status, ignored, tracked):
    lines = {}
    for name, path in (('status', status), ('ignored', ignored),
                       ('tracked', tracked)):
        with open(path, encoding='utf-8') as handle:
            lines[name] = [line for line in handle.read().split('\n') if line]

    untracked = [line for line in lines['status'] if line.startswith('?? site/')]
    if untracked:
        return fail('the render left %d untracked path(s) under site/; the '
                    'ignore rules do not cover the whole of what it writes:'
                    '\n  %s' % (len(untracked), '\n  '.join(untracked)))
    if lines['tracked']:
        return fail('git tracks %d path(s) under the render\'s own output '
                    'directories; render output is not the repository\'s to '
                    'carry:\n  %s'
                    % (len(lines['tracked']), '\n  '.join(lines['tracked'])))
    if not any(line.startswith('!! site/_site') for line in lines['ignored']):
        return fail('git reports no ignored path under site/_site/, so the '
                    'listing the two clauses above rest on is not describing a '
                    'tree the site was just rendered in')
    print('ok   M42-AC5: over %d line(s) of git status, none is an untracked '
          'path under site/, git tracks none of the %d path(s) under the '
          "render's output directories, and the render's own output directory "
          'is reported ignored' % (len(lines['status']), len(lines['tracked'])))
    return 0


MODES = {
    'pin': (check_pin, 2),
    'version': (check_version, 1),
    'output': (check_output, 3),
    'url': (check_url, 3),
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
