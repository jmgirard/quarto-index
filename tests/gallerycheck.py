"""Checks over the documentation site's example gallery (M41).

  listing <gallery.yml>
      Every `.qmd` directly under `examples/`, as `git ls-files` enumerates
      them, appears exactly once as a sequence item in the gallery declaration
      — under `shown:` or under `not-shown:`, and under no other key. A value
      under either of those two keys that names no such fixture is reported
      too, so a renamed fixture cannot leave a dead entry behind.

  manifests <gallery.yml> <registry.tsv>
      Every fixture under `shown:` is one the acceptance suite holds a
      hand-derived HTML index manifest for, `shown:` holds at least the floor
      the criterion names, and at least the floor of shown fixtures also have
      a PDF index manifest. The registry is the table tests/run-tests.sh
      writes: `<fixture>\t<kind>\t<format>\t<variable>\t<path>`, one row per
      addressable manifest.

  source <gallery.yml> <captured-site>
      Every shown fixture's gallery page carries a `<pre><code>` whose text
      content — entities decoded by the parser, a trailing newline normalized
      — is its fixture's `.qmd` under `examples/`, character for character.

  embedded <gallery.yml> <registry.tsv> <captured-site>
      Every shown fixture's gallery page frames exactly one page, that page
      resolves inside the captured site, and its generated index prints every
      entry the fixture's hand-derived HTML index manifest states. The frame's
      target is read off the `src` the page carries, not composed from the
      fixture's name.

  pdf <gallery.yml> <registry.tsv> <captured-site>
      Every shown fixture that has a hand-derived PDF index manifest links
      exactly one `.pdf`, it resolves inside the captured site, and its
      `pdftotext` extraction contains every entry that manifest states.

Reading the CAPTURED site and not the live output directory is the M24 rule:
a check that reads a render's working copy is reading something a later render
can change under it.

The declaration's shape is read by `read_gallery`, imported from
site/build_gallery.py — the program that builds the gallery from the same
file. One reader means the shape the build accepts and the shape this check
accepts cannot drift apart.

Every mode reports the size of the domain it swept, so a domain that has gone
empty reads as empty rather than as a pass.

Usage:  python3 tests/gallerycheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'site'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402
from build_gallery import read_gallery, shown_fixtures  # noqa: E402

# A fixture of the corpus this gallery declares over: a `.qmd` directly under
# `examples/`, which is the set the milestone's first criterion names. The
# book fixtures live one directory deeper and are out of scope.
FIXTURE = re.compile(r'examples/[^/]+\.qmd')

# The floors the milestone's third and fourth criteria state. Pinned here
# rather than merely reported: a shown list that shrank below its floor, or a
# PDF half that lost all but one fixture, would otherwise stay green.
SHOWN_FLOOR = 8
PDF_FLOOR = 3

# A manifest row's entry is the term the index prints. `index` and `sections`
# manifests state it in field 2 of a row whose field 1 is the level; `outline`
# does the same with no locator count; `terms` states one per line. Rows that
# open a letter group or an index section carry no entry of their own.
ENTRY_OF = {
    'index': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'sections': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'outline': lambda f: f[1] if f[0].isdigit() and len(f) > 1 else None,
    'terms': lambda f: f[0] if f[0] else None,
}


def read_registry(path):
    """The manifest table as [(fixture, kind, format, variable, path), ...]."""
    rows = []
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            line = line.rstrip('\n')
            if not line:
                continue
            fields = line.split('\t')
            if len(fields) != 5:
                raise SystemExit(
                    'FAIL: M41: %s carries a row with %d field(s), not the 5 '
                    'this reader expects: %r' % (path, len(fields), line))
            if fields[2] not in ENTRY_OF:
                raise SystemExit(
                    'FAIL: M41: %s names the manifest format %r, which this '
                    'reader has no entry rule for; it knows %s'
                    % (path, fields[2], ', '.join(sorted(ENTRY_OF))))
            rows.append(tuple(fields))
    return rows


def entries_of(manifest_path, fmt):
    """Every entry the manifest at `manifest_path` states, in file order."""
    rule = ENTRY_OF[fmt]
    found = []
    with open(manifest_path, encoding='utf-8') as handle:
        for line in handle:
            line = line.rstrip('\n')
            if not line.strip():
                continue
            entry = rule(line.split('\t'))
            if entry is not None:
                found.append(entry)
    return found


def fixture_name(path):
    """`examples/demo.qmd` -> `demo`."""
    return os.path.basename(path)[:-len('.qmd')]


def fail(message):
    print('FAIL: M41: ' + message, file=sys.stderr)
    return 1


def corpus():
    """The fixture paths, as git enumerates them.

    Discovered rather than written down, for the reason tests/sitecheck.py
    discovers the site's pages: a written-down list becomes the sweep, and
    every fixture it omits goes unlisted and unread.
    """
    out = subprocess.run(['git', 'ls-files', 'examples'], check=True,
                         capture_output=True, text=True).stdout.split('\n')
    return [path for path in out if FIXTURE.fullmatch(path)]


# ---------------------------------------------------------------------------
# listing
# ---------------------------------------------------------------------------
def check_listing(gallery):
    fixtures = corpus()
    if not fixtures:
        return fail('git enumerated no fixture matching %s under examples/; '
                    'the domain this check sweeps is empty, so it can judge '
                    'nothing' % FIXTURE.pattern)
    declared, order = read_gallery(gallery)
    for key in ('shown', 'not-shown'):
        if key not in declared:
            return fail('%s declares no `%s:` key; it declares %s'
                        % (gallery, key, ', '.join(order) or 'nothing'))

    listed = set(declared['shown']) | set(declared['not-shown'])
    counts = {}
    for key in order:
        for value in declared[key]:
            counts.setdefault(value, []).append(key)

    missing = [path for path in fixtures if path not in listed]
    if missing:
        return fail('%s lists neither under `shown:` nor under `not-shown:`: '
                    '%s. Every fixture is declared one way or the other.'
                    % (gallery, ', '.join(missing)))

    twice = [path for path in fixtures if len(counts.get(path, [])) > 1]
    if twice:
        return fail('%s lists %s more than once (under %s). Each fixture is '
                    'declared exactly once.'
                    % (gallery, ', '.join(twice),
                       '; '.join('%s: %s' % (p, ', '.join(counts[p]))
                                 for p in twice)))

    elsewhere = sorted(path for path in fixtures
                       for key in counts.get(path, [])
                       if key not in ('shown', 'not-shown'))
    if elsewhere:
        return fail('%s names %s under a key that is neither `shown:` nor '
                    '`not-shown:`' % (gallery, ', '.join(elsewhere)))

    stale = [value for key in ('shown', 'not-shown')
             for value in declared[key] if value not in fixtures]
    if stale:
        return fail('%s lists %s, which git enumerates no fixture for; a '
                    'renamed or deleted fixture left a dead entry behind'
                    % (gallery, ', '.join(stale)))

    print('ok   M41-AC1: all %d fixture(s) git enumerates under examples/ are '
          'declared exactly once in %s — %d shown, %d not shown'
          % (len(fixtures), gallery, len(declared['shown']),
             len(declared['not-shown'])))
    return 0


# ---------------------------------------------------------------------------
# manifests
# ---------------------------------------------------------------------------
def check_manifests(gallery, registry):
    shown = [fixture_name(p) for p in shown_fixtures(gallery)]
    if not shown:
        return fail('%s declares no shown fixture' % gallery)
    rows = read_registry(registry)
    if not rows:
        return fail('%s holds no manifest row, so every fixture below would '
                    'be judged against nothing' % registry)

    have = {}
    for fixture, kind, fmt, variable, path in rows:
        have.setdefault(kind, {})[fixture] = (fmt, variable, path)

    unbacked = [name for name in shown if name not in have.get('html', {})]
    if unbacked:
        return fail('%s shows %s, which the suite holds no hand-derived HTML '
                    'index manifest for; a shown fixture is one the suite '
                    'already judges' % (gallery, ', '.join(unbacked)))

    if len(shown) < SHOWN_FLOOR:
        return fail('%s shows %d fixture(s); the criterion states at least %d'
                    % (gallery, len(shown), SHOWN_FLOOR))

    with_pdf = [name for name in shown if name in have.get('pdf', {})]
    if len(with_pdf) < PDF_FLOOR:
        return fail('%d shown fixture(s) have a hand-derived PDF index '
                    'manifest (%s); the criterion states at least %d'
                    % (len(with_pdf), ', '.join(with_pdf) or 'none', PDF_FLOOR))

    empty = []
    for kind in ('html', 'pdf'):
        for fixture, (fmt, variable, path) in have.get(kind, {}).items():
            if fixture not in shown:
                continue
            if not entries_of(path, fmt):
                empty.append('%s (%s, %s, read as %s)'
                             % (fixture, kind, variable, fmt))
    if empty:
        return fail('these manifests state no entry at all, so the check that '
                    'reads them would judge nothing: %s' % ', '.join(empty))

    print('ok   M41-AC3/AC4: all %d shown fixture(s) have a hand-derived HTML '
          'index manifest, %d of them a PDF one too (%s), and every one of '
          'those %d manifest(s) states at least one entry'
          % (len(shown), len(with_pdf), ', '.join(with_pdf),
             len(shown) + len(with_pdf)))
    return 0


# ---------------------------------------------------------------------------
# source
# ---------------------------------------------------------------------------
def gallery_page_path(captured, name):
    """The rendered gallery page for one fixture, inside the captured site."""
    return os.path.join(captured, 'gallery', name + '.html')


def check_source(gallery, captured):
    shown = [fixture_name(p) for p in shown_fixtures(gallery)]
    wrong = []
    for name in shown:
        page = gallery_page_path(captured, name)
        if not os.path.isfile(page):
            wrong.append('%s: no gallery page at %s' % (name, page))
            continue
        root = H.parse(page)
        blocks = [H.text(code)
                  for pre in H.find_all(root, tag='pre')
                  for code in H.find_all(pre, tag='code')]
        if not blocks:
            wrong.append('%s: the page carries no <pre><code> element at all'
                         % name)
            continue
        want = open(os.path.join('examples', name + '.qmd'),
                    encoding='utf-8').read().rstrip('\n')
        hit = [b for b in blocks if b.rstrip('\n') == want]
        if not hit:
            closest = max(blocks, key=len)
            where = next((i for i, (a, b) in enumerate(zip(closest, want))
                          if a != b), min(len(closest), len(want)))
            wrong.append(
                '%s: no <pre><code> on the page carries the fixture source; '
                'the longest of its %d block(s) is %d character(s) against '
                'the fixture\'s %d, first differing at %d — page has %r, '
                'fixture has %r'
                % (name, len(blocks), len(closest), len(want), where,
                   closest[where:where + 40], want[where:where + 40]))
    if wrong:
        return fail('the gallery pages under %s do not carry their fixture '
                    'sources:\n  %s' % (captured, '\n  '.join(wrong)))
    if not shown:
        return fail('%s declares no shown fixture' % gallery)
    print('ok   M41-AC2: each of the %d shown fixture(s) has a <pre><code> on '
          'its gallery page under %s whose text content, entities decoded and '
          'a trailing newline normalized, is its fixture\'s bytes'
          % (len(shown), captured))
    return 0


# ---------------------------------------------------------------------------
# embedded
# ---------------------------------------------------------------------------
def embed_target(root, page, captured):
    """The page a gallery page's frame embeds, as a path in the captured site.

    Read off the `src` the page actually carries rather than composed from the
    fixture's name: a page whose frame pointed somewhere else would otherwise
    be judged against a file it does not show.
    """
    frames = H.find_all(root, tag='iframe')
    if len(frames) != 1:
        return None, ('carries %d <iframe> element(s), not the one that frames '
                      'its rendered fixture' % len(frames))
    src = frames[0].attrs.get('src', '')
    if not src:
        return None, 'carries an <iframe> with no src'
    target = os.path.normpath(os.path.join(os.path.dirname(page), src))
    if not os.path.isfile(target):
        return None, 'frames %r, which resolves to no file under %s' % (
            src, captured)
    return target, None


def rendered_entries(path):
    """Every entry term the generated index sections of `path` print."""
    minted = (os.environ['HTML_SECTION_ID'], os.environ['HTML_ANCHOR_PREFIX'],
              os.environ['HTML_ENTRY_PREFIX'])
    rows = H.section_rows(H.parse(path), os.environ['HTML_SECTION_ID'], minted)
    found = []
    for text_row in rows:
        fields = text_row.split('\t')
        if fields[0].isdigit() and len(fields) > 1:
            found.append(fields[1])
    return found


def check_embedded(gallery, registry, captured):
    shown = [fixture_name(p) for p in shown_fixtures(gallery)]
    manifests = {(f, k): (fmt, var, path)
                 for f, k, fmt, var, path in read_registry(registry)}
    wrong = []
    checked = 0
    entries_seen = 0
    for name in shown:
        page = gallery_page_path(captured, name)
        if not os.path.isfile(page):
            wrong.append('%s: no gallery page at %s' % (name, page))
            continue
        target, why = embed_target(H.parse(page), page, captured)
        if target is None:
            wrong.append('%s: its gallery page %s' % (name, why))
            continue
        key = (name, 'html')
        if key not in manifests:
            wrong.append('%s: no HTML index manifest is addressable for it'
                         % name)
            continue
        fmt, variable, manifest_path = manifests[key]
        want = entries_of(manifest_path, fmt)
        if not want:
            wrong.append('%s: the manifest %s states no entry' % (name,
                                                                  variable))
            continue
        try:
            got = rendered_entries(target)
        except ValueError as bad:
            wrong.append('%s: the index of %s could not be read: %s'
                         % (name, target, bad))
            continue
        if not got:
            wrong.append('%s: %s prints no index entry at all' % (name, target))
            continue
        absent = [entry for entry in want if entry not in got]
        if absent:
            wrong.append('%s: %s prints %d entry(s), and these manifest '
                         'entries are not among them: %s'
                         % (name, target, len(got),
                            ', '.join(repr(a) for a in absent)))
            continue
        checked += 1
        entries_seen += len(want)
    if wrong:
        return fail('the fixture pages the gallery embeds do not print the '
                    'index entries their manifests state:\n  %s'
                    % '\n  '.join(wrong))
    print('ok   M41-AC3: each of the %d shown fixture(s) frames a rendered '
          'page whose generated index prints every one of the %d entry(s) its '
          'hand-derived manifest states' % (checked, entries_seen))
    return 0


# ---------------------------------------------------------------------------
# pdf
# ---------------------------------------------------------------------------
def pdf_link(root, page, captured):
    """The `.pdf` a gallery page links to, as a path in the captured site."""
    hrefs = [node.attrs.get('href', '') for node in H.find_all(root, tag='a')]
    pdfs = [href for href in hrefs if href.lower().endswith('.pdf')]
    if len(pdfs) != 1:
        return None, ('carries %d link(s) to a .pdf, not the one that names '
                      'its built PDF' % len(pdfs))
    target = os.path.normpath(os.path.join(os.path.dirname(page), pdfs[0]))
    if not os.path.isfile(target):
        return None, 'links %r, which resolves to no file under %s' % (
            pdfs[0], captured)
    return target, None


def extracted_text(pdf_path):
    """`pdftotext` over one PDF, whitespace runs collapsed to one space.

    The typeset index breaks lines where the column ends, so an entry that a
    reader sees whole can reach the extraction split across two lines. The
    collapse is stated here and nowhere else: every run of whitespace, in the
    extraction and in the entry compared against it, becomes one space.
    """
    out = subprocess.run(['pdftotext', pdf_path, '-'], check=True,
                         capture_output=True, text=True).stdout
    return re.sub(r'\s+', ' ', out)


def check_pdf(gallery, registry, captured):
    shown = [fixture_name(p) for p in shown_fixtures(gallery)]
    manifests = {(f, k): (fmt, var, path)
                 for f, k, fmt, var, path in read_registry(registry)}
    wrong = []
    checked = 0
    entries_seen = 0
    for name in shown:
        key = (name, 'pdf')
        if key not in manifests:
            continue
        fmt, variable, manifest_path = manifests[key]
        page = gallery_page_path(captured, name)
        if not os.path.isfile(page):
            wrong.append('%s: no gallery page at %s' % (name, page))
            continue
        target, why = pdf_link(H.parse(page), page, captured)
        if target is None:
            wrong.append('%s: its gallery page %s' % (name, why))
            continue
        want = entries_of(manifest_path, fmt)
        if not want:
            wrong.append('%s: the manifest %s states no entry' % (name,
                                                                  variable))
            continue
        got = extracted_text(target)
        if not got.strip():
            wrong.append('%s: pdftotext extracted nothing from %s'
                         % (name, target))
            continue
        absent = [entry for entry in want
                  if re.sub(r'\s+', ' ', entry) not in got]
        if absent:
            wrong.append('%s: the extraction of %s does not contain these '
                         'manifest entries: %s'
                         % (name, target, ', '.join(repr(a) for a in absent)))
            continue
        checked += 1
        entries_seen += len(want)
    if checked < PDF_FLOOR:
        wrong.append('only %d shown fixture(s) were judged against a PDF '
                     'manifest; the criterion states at least %d'
                     % (checked, PDF_FLOOR))
    if wrong:
        return fail('the PDFs the gallery links do not carry the index '
                    'entries their manifests state:\n  %s'
                    % '\n  '.join(wrong))
    print('ok   M41-AC4: each of the %d shown fixture(s) with a hand-derived '
          'PDF index manifest links a .pdf under %s whose pdftotext '
          'extraction contains all %d entry(s) that manifest states'
          % (checked, captured, entries_seen))
    return 0


MODES = {
    'listing': (check_listing, 1),
    'manifests': (check_manifests, 2),
    'source': (check_source, 2),
    'embedded': (check_embedded, 3),
    'pdf': (check_pdf, 3),
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
