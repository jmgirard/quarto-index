"""Five checks over the documentation website and the README that points at it
(M40).

  rendered <site-src> <captured-site>
      Every tracked `.qmd` under the site source whose basename does not begin
      with `_` has its `.html` at the same relative path in the captured render.
      The domain is `git ls-files`, discovered rather than written down, for the
      reason tests/filtersrc.py enumerates the filter's source: a written-down
      list becomes the sweep, and every file it omits ships unrendered and
      unread.

  links <captured-site> [base-path]
      Every link the rendered site makes to its own content resolves: the path
      part names a file the render produced, and a `#fragment` names an `id` the
      file it points at actually carries. `<use>` hrefs are excluded (they name
      an SVG symbol, not a document), and so is any value whose scheme is
      `http:`, `https:`, `mailto:`, `tel:`, `data:` or `javascript:`.

  headings <old-readme> <new-readme> <site-dir>
      Every `##`/`###` heading the old README carried, other than the three the
      move keeps, is gone from the new README and is carried as a heading — at
      any level — by some file under the site directory.

  readme <new-readme> <site-index>
      The README that replaces the documentation is short, and still carries the
      pre-release warning, the install line, and a relative link to the site
      index that resolves from the README's own directory.

  prose <old-readme> <new-readme> <site-dir>
      No documentation prose was lost in the move. For every line the old README
      carried and the new one does not, every run of four or more ASCII
      alphanumerics on that line, lowercased, appears in the concatenated
      lowercased text of the files under the site directory.

      The four-character-word bound is the M27 rule in cairn/check-design.md. A
      substring bound reports a reflowed paragraph as loss and cannot tell
      rewrapping from deletion; requiring every word of four or more characters
      to reach a destination separates them. Normalization is stated here and
      nowhere else: the words are the runs `[A-Za-z0-9]{4,}` finds, lowercased
      on both sides, and nothing else about the line is compared — not order,
      not punctuation, not the shorter words.

Every mode reports the size of the domain it swept, so a domain that has gone
empty reads as empty rather than as a pass.

Usage:  python3 tests/sitecheck.py <mode> <args...>

Exits non-zero with a `FAIL:` line naming what it found.
"""

import html
import os
import re
import subprocess
import sys
from html.parser import HTMLParser

# The three headings the move keeps in README, per M40's scope.
KEPT_HEADINGS = ('## Install', '## Examples', '## Tests')

NON_LOCAL_SCHEMES = ('http:', 'https:', 'mailto:', 'tel:', 'data:',
                     'javascript:')

WORD = re.compile(r'[A-Za-z0-9]{4,}')
HEADING = re.compile(r'^(#{1,6})\s+(.*?)\s*$')


def fail(message):
    print('FAIL: M40: ' + message, file=sys.stderr)
    return 1


def tracked_qmd(directory):
    """Tracked `.qmd` paths under `directory`, as git enumerates them."""
    out = subprocess.run(['git', 'ls-files', directory], check=True,
                         capture_output=True, text=True).stdout.split('\n')
    return [p for p in out if p.endswith('.qmd')]


def renderable(paths):
    """The tracked pages a website render turns into a page of their own.

    A `_`-prefixed basename is a partial: Quarto includes it into another page
    and writes no output of its own for it (M40 scope).
    """
    return [p for p in paths if not os.path.basename(p).startswith('_')]


def headings_of(text):
    """Every heading in `text` as (level, heading text), fenced blocks skipped.

    A fenced block can carry a line that reads exactly like a heading — a
    `# References` line inside a copyable markdown recipe is one this repo
    actually ships — and counting it as a heading is how a check reads a
    document's structure wrongly without looking any different.
    """
    found = []
    fence = False
    for line in text.split('\n'):
        if line.startswith('```'):
            fence = not fence
            continue
        if fence:
            continue
        match = HEADING.match(line)
        if match:
            found.append((len(match.group(1)), match.group(2)))
    return found


# ---------------------------------------------------------------------------
# rendered
# ---------------------------------------------------------------------------
def check_rendered(site_src, captured):
    pages = renderable(tracked_qmd(site_src))
    if not pages:
        return fail(f'`git ls-files {site_src}` enumerated no page that a '
                    f'website render writes an output for, so this check '
                    f'would pass over an empty set')
    missing = []
    for page in pages:
        rel = os.path.relpath(page, site_src)
        want = os.path.join(captured, rel[:-len('.qmd')] + '.html')
        if not os.path.isfile(want):
            missing.append(f'  {page} -> {want}')
    if missing:
        return fail(f'{len(missing)} of {len(pages)} tracked page(s) have no '
                    f'rendered output at the path their source names:\n'
                    + '\n'.join(missing))
    print(f'ok   M40-AC1: each of the {len(pages)} tracked page(s) under '
          f'{site_src} that a website render writes an output for has its '
          f'`.html` at the same relative path in the captured render')
    return 0


# ---------------------------------------------------------------------------
# links
# ---------------------------------------------------------------------------
class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.hrefs = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        if attr.get('id'):
            self.ids.add(attr['id'])
        if tag == 'a' and attr.get('name'):
            self.ids.add(attr['name'])
        # A `<use>` href names a symbol inside an SVG sprite, not a document.
        if tag == 'use':
            return
        if attr.get('href'):
            self.hrefs.append(attr['href'])


def check_links(captured, base_path=''):
    base = base_path.strip('/')
    pages = {}
    for root, _dirs, files in os.walk(captured):
        for name in files:
            if not name.endswith('.html'):
                continue
            full = os.path.join(root, name)
            parser = Page()
            parser.feed(open(full, encoding='utf-8', errors='replace').read())
            pages[os.path.relpath(full, captured)] = parser
    if not pages:
        return fail(f'{captured} holds no rendered page at all, so the link '
                    f'check would sweep nothing')

    bad = []
    swept = 0
    for rel, page in pages.items():
        for href in page.hrefs:
            value = href.strip()
            if not value or value.startswith('//'):
                continue
            if value.lower().startswith(NON_LOCAL_SCHEMES):
                continue
            path, _, fragment = value.partition('#')
            fragment = html.unescape(fragment)
            swept += 1
            if path:
                if value.startswith('/'):
                    stripped = path.lstrip('/')
                    if base and (stripped == base
                                 or stripped.startswith(base + '/')):
                        stripped = stripped[len(base):].lstrip('/')
                    target = stripped
                else:
                    target = os.path.normpath(
                        os.path.join(os.path.dirname(rel), path))
                on_disk = os.path.join(captured, target)
                if os.path.isdir(on_disk):
                    target = os.path.join(target, 'index.html')
                    on_disk = os.path.join(captured, target)
                if not os.path.exists(on_disk):
                    bad.append(f'  {rel}: <<{href}>> names no file under '
                               f'{captured} (looked for {target})')
                    continue
                if fragment and target in pages \
                        and fragment not in pages[target].ids:
                    bad.append(f'  {rel}: <<{href}>> names no element with '
                               f'that id in {target}')
            elif fragment:
                if fragment not in page.ids:
                    bad.append(f'  {rel}: <<{href}>> names no element with '
                               f'that id in the page carrying it')
    if not swept:
        return fail(f'the {len(pages)} rendered page(s) under {captured} make '
                    f'no link to their own content at all, so this check '
                    f'passed over an empty set')
    if bad:
        return fail(f'{len(bad)} of {swept} link(s) the rendered site makes to '
                    f'its own content do not resolve:\n' + '\n'.join(bad))
    print(f'ok   M40-AC2: all {swept} link(s) the {len(pages)} rendered '
          f'page(s) make to their own content resolve — the path to a file the '
          f'render produced, and each `#fragment` to an id that file carries')
    return 0


# ---------------------------------------------------------------------------
# headings
# ---------------------------------------------------------------------------
def check_headings(old_readme, new_readme, site_dir):
    old = open(old_readme, encoding='utf-8').read()
    new = open(new_readme, encoding='utf-8').read()
    moved = [line for line in old.split('\n')
             if re.match(r'^#{2,3} ', line) and line not in KEPT_HEADINGS]
    # Pinned, not merely counted off the file: the number is what M40's scope
    # states, and a check that took it from the document it reads would pass on
    # a document that had lost sixteen of them.
    if len(moved) != 17:
        return fail(f'{old_readme} carries {len(moved)} `##`/`###` heading(s) '
                    f'other than {", ".join(KEPT_HEADINGS)}; M40 moves 17, so '
                    f'this check is not reading the document it is about')

    site_headings = set()
    files = 0
    for path in tracked_qmd(site_dir):
        files += 1
        for _level, text in headings_of(
                open(path, encoding='utf-8').read()):
            site_headings.add(text)
    if not files:
        return fail(f'`git ls-files {site_dir}` enumerated no page, so the '
                    f'destination half of this check would sweep nothing')

    bad = []
    for line in moved:
        text = re.sub(r'^#+\s*', '', line).strip()
        if line in new.split('\n'):
            bad.append(f'  still in {new_readme}: <<{line}>>')
        if text not in site_headings:
            bad.append(f'  no heading under {site_dir} reads <<{text}>>')
    if bad:
        return fail(f'the heading move is incomplete:\n' + '\n'.join(bad))
    print(f'ok   M40-AC4: each of the {len(moved)} `##`/`###` heading(s) the '
          f'old README carried other than {", ".join(KEPT_HEADINGS)} is gone '
          f'from {new_readme} and is carried, with its text identical, by a '
          f'heading in one of the {files} tracked page(s) under {site_dir}')
    return 0


# ---------------------------------------------------------------------------
# readme
# ---------------------------------------------------------------------------
README_LINE_CAP = 120
WARNING = '**Pre-release: install at your own risk.**'
INSTALL = 'quarto add jmgirard/quarto-index'


def check_readme(new_readme, site_index):
    text = open(new_readme, encoding='utf-8').read()
    lines = text.split('\n')
    if lines and lines[-1] == '':
        lines = lines[:-1]
    bad = []
    if len(lines) >= README_LINE_CAP:
        bad.append(f'  it is {len(lines)} lines, and the criterion is under '
                   f'{README_LINE_CAP}')
    if WARNING not in text:
        bad.append(f'  it does not carry the pre-release warning '
                   f'<<{WARNING}>>')
    if INSTALL not in text:
        bad.append(f'  it does not carry the install line <<{INSTALL}>>')

    want = os.path.relpath(site_index, os.path.dirname(new_readme) or '.')
    targets = [t for _label, t in re.findall(r'\[([^\]]*)\]\(([^)\s]+)\)', text)]
    linked = [t for t in targets if t == want]
    if not linked:
        bad.append(f'  no markdown link in it names {want}; it carries '
                   f'{len(targets)} link(s)')
    elif not os.path.isfile(
            os.path.join(os.path.dirname(new_readme) or '.', want)):
        bad.append(f'  it links to {want}, which does not resolve from '
                   f'{os.path.dirname(new_readme) or "."}')
    if bad:
        return fail(f'{new_readme} is not the pointer M40 replaces the '
                    f'documentation with:\n' + '\n'.join(bad))
    print(f'ok   M40-AC5: {new_readme} is {len(lines)} lines, under '
          f'{README_LINE_CAP}, and carries the pre-release warning, the '
          f'install line and a relative link to {want} that resolves')
    return 0


# ---------------------------------------------------------------------------
# prose
# ---------------------------------------------------------------------------
def check_prose(old_readme, new_readme, site_dir):
    old = open(old_readme, encoding='utf-8').read().split('\n')
    new = set(open(new_readme, encoding='utf-8').read().split('\n'))
    removed = [line for line in old if line not in new]

    destination = []
    files = 0
    for path in tracked_qmd(site_dir):
        files += 1
        destination.append(open(path, encoding='utf-8').read())
    if not files:
        return fail(f'`git ls-files {site_dir}` enumerated no page, so every '
                    f'removed word would be reported lost and the check is not '
                    f'reading the destination it is about')
    reached = set(w.lower() for w in WORD.findall('\n'.join(destination)))

    lost = []
    swept = 0
    for line in removed:
        for word in WORD.findall(line):
            swept += 1
            if word.lower() not in reached:
                lost.append(f'  <<{word}>> from <<{line.strip()}>>')
    if not removed:
        print(f'ok   M40-AC3: {new_readme} drops no line {old_readme} carries, '
              f'so no prose can have been lost — the domain this check sweeps '
              f'is empty, and that is what it reports')
        return 0
    if not swept:
        return fail(f'the {len(removed)} removed line(s) carry no word of four '
                    f'or more ASCII alphanumerics between them, so this check '
                    f'compared nothing')
    if lost:
        return fail(f'{len(lost)} word(s) on the {len(removed)} line(s) '
                    f'{new_readme} drops reach no page under {site_dir}:\n'
                    + '\n'.join(lost))
    print(f'ok   M40-AC3: every one of the {swept} word(s) of four or more '
          f'ASCII alphanumerics on the {len(removed)} line(s) dropped from '
          f'{old_readme} appears, lowercased, in the {files} tracked page(s) '
          f'under {site_dir}')
    return 0


MODES = {
    'rendered': (check_rendered, 2),
    'links': (check_links, 1),
    'headings': (check_headings, 3),
    'readme': (check_readme, 2),
    'prose': (check_prose, 3),
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
