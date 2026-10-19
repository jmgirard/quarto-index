"""Read the lists a Typst render prints with `outline` against a manifest (M115).

`typstlists.py <pdf> <manifest> <label>`

The manifest holds one row per caption a list must hold, tab-separated:

    page<TAB>list title<TAB>caption text

`#` lines and blank lines are skipped. For each row the reader takes the
page's text from `pdftotext -layout`, finds the line that is the list's
title, and joins every line after it up to the next title the manifest names
on that page, whitespace flattened, so a caption that wraps still reads as
one string. The row passes when the caption is in that span.

This module reads the ARTIFACT. Its manifest is derived by hand from the
fixture source (the ORACLE RULE in run-tests.sh). It does not fold
ligatures, so no caption or title a manifest names may hold a letter pair
the Typst of the floor Quarto sets as one glyph.
"""

import subprocess
import sys


def rows(path):
    out = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        page, title, caption = line.split('\t')
        out.append((int(page), title, caption))
    return out


def page_lines(pdf, page):
    text = subprocess.run(['pdftotext', '-f', str(page), '-l', str(page),
                           '-layout', pdf, '-'], check=True,
                          capture_output=True, text=True).stdout
    return [line.strip() for line in text.splitlines()]


def main(argv):
    pdf, manifest, label = argv[1:4]
    wanted = rows(manifest)
    if not wanted:
        print(f'FAIL: {label}: the manifest {manifest} names no caption',
              file=sys.stderr)
        return 1
    titles = {}
    for page, title, _caption in wanted:
        titles.setdefault(page, set()).add(title)
    bad = []
    for page, title, caption in wanted:
        lines = page_lines(pdf, page)
        if title not in lines:
            bad.append(f'page {page} prints no line {title!r}')
            continue
        start = lines.index(title)
        ends = [lines.index(other) for other in titles[page]
                if other in lines and lines.index(other) > start]
        body = ' '.join(' '.join(lines[start + 1:min(ends + [len(lines)])])
                        .split())
        if caption not in body:
            bad.append(f'the list {title!r} on page {page} does not hold '
                       f'{caption!r}')
    for line in bad:
        print(f'FAIL: {label}: {line}', file=sys.stderr)
    if bad:
        return 1
    print(f'ok   {label}: each of the {len(wanted)} captions the manifest '
          f'names is in its list')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
