"""Build the documentation site's example gallery (M41).

Quarto runs this as the website's `pre-render` step. For every fixture
`site/gallery.yml` lists under `shown:` it

  1. copies the fixture, the extension, and the fixture directory's shared
     assets into a scratch directory at the REPO ROOT,
  2. renders that copy to a self-contained `.html` and to `.pdf` there, and
  3. places both outputs under `site/gallery/rendered/`, which the project
     declares as a resource, so they reach `site/_site/gallery/rendered/`.

It then writes the gallery pages: one `site/gallery/<name>.qmd` per shown
fixture, carrying the fixture's source verbatim in a fenced block, a frame
around the rendered page and a link to the PDF; and the
`site/gallery/index.qmd` a reader arrives on, linking to each of them.

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

# A Quarto shortcode, which is expanded even inside a fenced code block. See
# `gallery_page` for why the gallery escapes rather than expands one.
SHORTCODE = re.compile(r'\{\{<(.*?)>\}\}', re.S)

KEY = re.compile(r'^([A-Za-z0-9_-]+):\s*$')
ITEM = re.compile(r'^  - (\S.*?)\s*$')

SITE_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SITE_DIR)
GALLERY_YML = os.path.join(SITE_DIR, 'gallery.yml')
BUILD_DIR = os.path.join(REPO_ROOT, '.gallery-build')
RENDERED_DIR = os.path.join(SITE_DIR, 'gallery', 'rendered')
EXAMPLES_DIR = os.path.join(REPO_ROOT, 'examples')
EXTENSIONS_DIR = os.path.join(REPO_ROOT, '_extensions')

# What a render leaves beside a fixture, as `.gitignore` enumerates it for
# `examples/`. Never staged: see `stage`.
ARTIFACT_SUFFIXES = frozenset(
    ('.tex', '.pdf', '.html', '.md', '.epub',
     '.aux', '.idx', '.ilg', '.ind', '.log'))


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

    Render artifacts are the one exclusion. README documents `quarto render
    examples/demo.qmd --to pdf`, which leaves a `.pdf`, a `.tex` and the
    makeindex family beside the fixture; staged, they would sit at exactly the
    paths `main` reads its own render's output back from, and a stale one would
    ship as the gallery's PDF. The set is the repo's own ignore list for that
    directory, so it cannot drift from what a render actually leaves.
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
        if os.path.splitext(entry)[1] in ARTIFACT_SUFFIXES:
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


def fence_for(text):
    """A backtick fence longer than any run of backticks the text contains.

    The fixtures are markdown documents and several carry fenced code blocks of
    their own. A three-backtick fence around one of those would close at the
    fixture's own fence, and the page would carry a truncated source while
    still looking like a whole one.
    """
    longest = max((len(run) for run in re.findall(r'`+', text)), default=0)
    return '`' * max(3, longest + 1)


PAGE = '''---
title: "examples/{name}.qmd"
pagetitle: "examples/{name}.qmd"
---

{links}

## The rendered page

The fixture below is rendered on its own, the way `quarto render
examples/{name}.qmd --to html` renders it. This page frames that output rather
than reproducing it.

<iframe class="gallery-frame" src="rendered/{name}.html"
        title="examples/{name}.qmd rendered to HTML"></iframe>

## The source

{fence}markdown
{body}
{fence}
'''

INDEX = '''---
title: "Gallery"
pagetitle: "Gallery"
---

# Gallery

Each page below carries one example fixture: its `.qmd` source, the page that
fixture renders to, and the PDF built from the same source. The fixtures are
the ones `site/gallery.yml` lists under `shown:`; the rest of the corpus is
described on [Examples](../examples.qmd).

{rows}'''


def gallery_page(name, source_text, has_pdf):
    """The `.qmd` for one fixture's gallery page.

    The source goes into the fenced block verbatim, less the file's final
    newline, which the fence supplies: the criterion compares the block's text
    content against the fixture's bytes with a trailing newline normalized.

    One substitution is made on the way in. Quarto expands its own shortcodes
    inside a fenced code block, so a fixture carrying `{{< pagebreak >}}` — and
    examples/xref-conflict.qmd does — would have that line expanded away and
    the page would show a source the fixture does not have. Quarto's escape for
    a shortcode meant literally is a second pair of braces, which renders back
    as the one pair the fixture wrote.
    """
    links = ['[Open the rendered page](rendered/%s.html)' % name]
    if has_pdf:
        links.append('[Open the PDF](rendered/%s.pdf)' % name)
    body = source_text[:-1] if source_text.endswith('\n') else source_text
    body = SHORTCODE.sub(r'{{{<\1>}}}', body)
    return PAGE.format(name=name, links=' &middot; '.join(links),
                       fence=fence_for(source_text), body=body)


def gallery_index(names):
    """The `.qmd` a reader arrives on, linking to every fixture's page."""
    rows = ''.join('- [`examples/%s.qmd`](%s.qmd)\n' % (name, name)
                   for name in names)
    return INDEX.format(rows=rows)


def main():
    fixtures = shown_fixtures()
    if os.path.isdir(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)
    # The whole gallery directory goes, not just the renders under it: a
    # fixture dropped from `shown:` would otherwise leave its page behind, and
    # a page nobody generated any more reads exactly like one that was.
    gallery_dir = os.path.join(SITE_DIR, 'gallery')
    if os.path.isdir(gallery_dir):
        shutil.rmtree(gallery_dir)
    os.makedirs(RENDERED_DIR)

    names = []
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
        # Read from the staged copy rather than from `examples/`: the page
        # shows the source the render it frames was made from.
        with open(source, encoding='utf-8') as handle:
            source_text = handle.read()
        page = os.path.join(SITE_DIR, 'gallery', name + '.qmd')
        with open(page, 'w', encoding='utf-8') as handle:
            handle.write(gallery_page(name, source_text, has_pdf=True))
        names.append(name)
        print('gallery: built %s' % name)

    with open(os.path.join(SITE_DIR, 'gallery', 'index.qmd'), 'w',
              encoding='utf-8') as handle:
        handle.write(gallery_index(names))

    print('gallery: %d fixture(s) rendered and %d gallery page(s) written '
          'into %s' % (len(fixtures), len(names) + 1,
                       os.path.relpath(os.path.join(SITE_DIR, 'gallery'),
                                       REPO_ROOT)))


if __name__ == '__main__':
    main()
