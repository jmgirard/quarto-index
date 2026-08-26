"""Build the documentation site's example gallery (M41).

Quarto runs this as the website's `pre-render` step. For every fixture
`site/gallery.yml` lists under `shown:` it

  1. copies the fixture, the extension, and the fixture directory's shared
     assets into a scratch directory at the REPO ROOT,
  2. renders that copy to a self-contained `.html` and to `.pdf` there, and
  3. places both outputs under `site/gallery/rendered/`, which the project
     declares as a resource, so they reach `site/_site/gallery/rendered/`.

Nothing here names a path under `examples/` as a render target. The fixture
directory is read and never written: that is what the milestone's fifth
criterion checks, by hashing `examples/` on both sides of a site render.

The scratch directory is at the repo root rather than under `site/` because
Quarto walks up from a render target looking for a `_quarto.yml`. A fixture
copied under `site/` would be found by the website project and rendered as one
of its pages — the site's theme and navigation wrapped around it — instead of
as the standalone document a reader would get by rendering the fixture.

`read_gallery` is here rather than in the checks because this is the program
that has to understand the file: the check imports it from here, so the shape
the build accepts and the shape the check accepts cannot drift apart.

Usage:  python3 site/build_gallery.py      (Quarto calls it with no arguments)
"""

import os
import re
import shutil
import subprocess
import sys

KEY = re.compile(r'^([A-Za-z0-9_-]+):\s*$')
ITEM = re.compile(r'^  - (\S.*?)\s*$')

SITE_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SITE_DIR)
GALLERY_YML = os.path.join(SITE_DIR, 'gallery.yml')
BUILD_DIR = os.path.join(REPO_ROOT, '.gallery-build')
RENDERED_DIR = os.path.join(SITE_DIR, 'gallery', 'rendered')
EXAMPLES_DIR = os.path.join(REPO_ROOT, 'examples')
EXTENSIONS_DIR = os.path.join(REPO_ROOT, '_extensions')


def read_gallery(path):
    """The gallery declaration as ({key: [value, ...]}, key order).

    Accepts exactly two line shapes outside comments and blanks: a top-level
    `<key>:` and a `  - <value>` item under the key above it. Every other line
    raises. A reader that returned an empty list for a shape it did not
    understand would turn every check over that list green, so this one
    refuses the shape instead.
    """
    found = {}
    order = []
    current = None
    with open(path, encoding='utf-8') as handle:
        for number, line in enumerate(handle.read().split('\n'), start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            match = KEY.match(line)
            if match:
                current = match.group(1)
                if current in found:
                    raise SystemExit(
                        'FAIL: M41: %s line %d: the key %r is declared twice'
                        % (path, number, current))
                found[current] = []
                order.append(current)
                continue
            match = ITEM.match(line)
            if match:
                if current is None:
                    raise SystemExit(
                        'FAIL: M41: %s line %d: a sequence item before any key'
                        % (path, number))
                found[current].append(match.group(1))
                continue
            raise SystemExit(
                'FAIL: M41: %s line %d: %r is neither a `<key>:` line nor a '
                '`  - <value>` item; this reader accepts only those two shapes'
                % (path, number, line))
    return found, order


def shown_fixtures(path=GALLERY_YML):
    """The `shown:` values, as declared, with their order kept."""
    declared, order = read_gallery(path)
    if 'shown' not in declared:
        raise SystemExit('FAIL: M41: %s declares no `shown:` key; it declares '
                         '%s' % (path, ', '.join(order) or 'nothing'))
    if not declared['shown']:
        raise SystemExit('FAIL: M41: %s declares `shown:` with no fixture '
                         'under it, so the gallery this builds would be empty'
                         % path)
    return declared['shown']


def quarto_env():
    """The environment a nested `quarto render` runs under.

    Quarto exports its own project variables into a pre-render step. Passing
    them down would tell the child render it is part of the website project,
    which is the thing this build exists to avoid.
    """
    env = {key: value for key, value in os.environ.items()
           if not key.startswith('QUARTO_')}
    return env


def stage(fixture):
    """Copy one fixture and everything its render needs into the scratch tree.

    Returns (name, directory, source path inside the directory).

    Everything under `examples/` that is not one of the fixtures themselves is
    copied alongside: the shared bibliography and image, and the `_`-prefixed
    partials a fixture may include. Copying the set rather than a written-down
    per-fixture asset list keeps a fixture that grows an include from failing
    to render for a reason nobody would look for here.
    """
    name = os.path.basename(fixture)[:-len('.qmd')]
    directory = os.path.join(BUILD_DIR, name)
    os.makedirs(directory)
    shutil.copy2(os.path.join(REPO_ROOT, fixture),
                 os.path.join(directory, name + '.qmd'))
    for entry in sorted(os.listdir(EXAMPLES_DIR)):
        path = os.path.join(EXAMPLES_DIR, entry)
        if not os.path.isfile(path):
            continue
        if entry.endswith('.qmd') and not entry.startswith('_'):
            continue
        shutil.copy2(path, os.path.join(directory, entry))
    shutil.copytree(EXTENSIONS_DIR, os.path.join(directory, '_extensions'),
                    symlinks=False)
    return name, directory, os.path.join(directory, name + '.qmd')


def render(source, fmt, extra=()):
    command = ['quarto', 'render', source, '--to', fmt, *extra]
    result = subprocess.run(command, cwd=os.path.dirname(source),
                            env=quarto_env(), capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stdout[-4000:])
        sys.stderr.write(result.stderr[-4000:])
        raise SystemExit('FAIL: M41: %s exited %d; a fixture the gallery '
                         'shows must render' % (' '.join(command),
                                                result.returncode))


def main():
    fixtures = shown_fixtures()
    if os.path.isdir(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)
    if os.path.isdir(RENDERED_DIR):
        shutil.rmtree(RENDERED_DIR)
    os.makedirs(RENDERED_DIR)

    for fixture in fixtures:
        name, directory, source = stage(fixture)
        # Self-contained, so one file carries the whole rendered page: the
        # gallery frames it, and there is no per-fixture `_files` directory to
        # carry along beside it.
        render(source, 'html', ('--embed-resources',))
        render(source, 'pdf')
        for suffix in ('.html', '.pdf'):
            built = os.path.join(directory, name + suffix)
            if not os.path.isfile(built):
                raise SystemExit('FAIL: M41: rendering %s produced no %s'
                                 % (fixture, name + suffix))
            shutil.copy2(built, os.path.join(RENDERED_DIR, name + suffix))
        print('gallery: built %s' % name)

    print('gallery: %d fixture(s) rendered into %s'
          % (len(fixtures), os.path.relpath(RENDERED_DIR, REPO_ROOT)))


if __name__ == '__main__':
    main()
