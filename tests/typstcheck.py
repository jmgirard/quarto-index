"""The suite's readings of a Typst render beyond one fixture's full rows (M098).

tests/typstindex.py reads each index line with its locators' faces and links,
and compares whole rows. The fixtures this module is for state less, or state
it differently, so each mode here compares a narrower row:

  terms <pdf> <manifest> <label> <heading> [stop ...]
      Group headings, and each entry's level, term and references, with no
      locators. For a fixture whose page layout the source does not fix: the
      rows are the entries each index holds, and nothing about pages.

  book <pdf> <manifest> <label> <heading> [stop ...]
      As `terms`, and each locator named by the chapter whose pages hold it.
      The manifest opens with one `chapter<TAB>key<TAB>heading` row per
      chapter, in book order; a chapter runs from the page carrying its
      heading line to the page before the next chapter's. A locator is then
      `{key}` or `{key}–{key}`, a `*` after a bold one.

  order <pdf> <label> <line> [<line> ...]
      Each line is found after the one before it in `pdftotext` reading
      order: `=text` is a whole line, `^text` a line's start. The first is
      searched for from the top of the document.

  source <pdf> <qmd> <label> <heading> [stop ...]
      Every entry the fixture's marks derive, as (level, term, references),
      against every entry the PDF prints, compared as multisets in Unicode
      NFC. The derivation reads the source by the documented semantics (the
      ORACLE RULE in run-tests.sh): Pandoc's backslash unescaping of a quoted
      attribute value and of visible text, the level parse (a single `!`
      separates levels, `!!` is a literal `!`, left to right), empty levels
      dropped, each parent path printing a line of its own, and a reference
      naming its own entry dropped. It handles the mark shapes the four
      escaping and Unicode fixtures write, and refuses any other.

Every mode exits 0 on a match and 1 with a FAIL line otherwise.
"""

import re
import subprocess
import sys
import unicodedata
from collections import Counter

import typstindex

ENGLISH = {'see': 'see', 'see-also': 'see also'}


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    return 1


def nfc(text):
    return unicodedata.normalize('NFC', text)


def unrepeat_clusters(text):
    """Fold a cluster that carries a combining mark and is read twice running.

    Typst maps each glyph of a base letter with a combining mark to the whole
    cluster's text, so pdftotext reads `x` plus a combining caron as that
    cluster twice. Observed 2026-09-13 on Typst 0.15.1 with examples/unicode.qmd:
    its page image prints `Nux̌alk` once in the index and once in the body, and
    both lines read back as `Nux̌x̌alk`, the body line being Pandoc's writing
    and not this extension's. Only a cluster with a combining mark is folded,
    so a doubled plain letter still reads as the doubling it is.
    """
    clusters = []
    for char in text:
        if clusters and unicodedata.combining(char):
            clusters[-1] += char
        else:
            clusters.append(char)
    out = []
    for cluster in clusters:
        if (out and cluster == out[-1] and len(cluster) > 1
                and any(unicodedata.combining(c) for c in cluster[1:])):
            continue
        out.append(cluster)
    return ''.join(out)


def terms_row(line):
    """A typstindex row with the locators field removed."""
    if line.kind == 'group':
        return line.row()
    _kind, level, term, _locators, refs = line.row().split('\t')
    return '\t'.join(['entry', level, term, refs])


def manifest_terms(path):
    """A terms manifest's rows, an entry row padded to its four fields."""
    rows = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        fields = line.split('\t')
        if fields[0] == 'entry':
            fields += [''] * (4 - len(fields))
        rows.append('\t'.join(fields))
    return rows


def terms_main(argv):
    pdf, manifest, label, heading = argv[2:6]
    stop = tuple(argv[6:])
    try:
        actual = [terms_row(line)
                  for line in typstindex.read(pdf, heading, stop)]
    except (LookupError, ValueError) as error:
        return fail(f'{label}: {error}')
    expected = manifest_terms(manifest)
    if not typstindex.compare(actual, expected, label):
        return 1
    print(f'ok   {label}: the {len(expected)} lines under {heading!r} are the '
          f'group headings and entries the manifest states')
    return 0


def _page_lines(pdf):
    """`[[line text, ...], ...]` per page, every line kept."""
    text = subprocess.run(['pdftotext', pdf, '-'], check=True,
                          capture_output=True, text=True).stdout
    return [[l.strip() for l in page.split('\n') if l.strip()]
            for page in text.split('\f')]


def book_main(argv):
    pdf, manifest, label, heading = argv[2:6]
    stop = tuple(argv[6:])
    chapters, expected = [], []
    for line in open(manifest, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        fields = line.split('\t')
        if fields[0] == 'chapter':
            chapters.append((fields[1], fields[2]))
            continue
        if fields[0] == 'entry':
            fields += [''] * (5 - len(fields))
        expected.append('\t'.join(fields))
    if not chapters:
        return fail(f'{label}: {manifest} names no chapter')

    pages = _page_lines(pdf)
    # A page number printed on a page is that page's position in the file,
    # or a locator's number would name a different page than the one read.
    # The template prints it as the page's first or last line; a bare number
    # elsewhere, such as a chapter number in the outline, is not one.
    for number, lines in enumerate(pages, start=1):
        for text in lines[:1] + lines[-1:]:
            if re.fullmatch(r'\d+', text) and int(text) != number:
                return fail(f'{label}: page {number} of {pdf} prints the page '
                            f'number {text}, so a printed locator is not the '
                            f'page this reading maps it to')
    starts = []
    for key, chapter_heading in chapters:
        at = next((n for n, lines in enumerate(pages, start=1)
                   if chapter_heading in lines), None)
        if at is None:
            return fail(f'{label}: no page of {pdf} carries the chapter '
                        f'heading {chapter_heading!r}')
        starts.append((at, key))
    if [s for s, _k in starts] != sorted(s for s, _k in starts):
        return fail(f'{label}: the chapter headings are not in book order: '
                    f'{starts!r}')

    def chapter_of(page):
        found = None
        for start, key in starts:
            if page >= start:
                found = key
        return found

    try:
        lines = typstindex.read(pdf, heading, stop)
    except (LookupError, ValueError) as error:
        return fail(f'{label}: {error}')
    actual = []
    for line in lines:
        if line.kind == 'group':
            actual.append(line.row())
            continue
        term, locators, refs = typstindex.parse_entry(line.words)
        shown = []
        for text, bold, _link in locators:
            ends = [chapter_of(int(p)) for p in text.split('–')]
            shown.append('–'.join('{%s}' % e for e in ends)
                         + ('*' if bold else ''))
        refs_shown = [f'{word}|{target}' + ('@' if linked else '')
                      for word, target, linked in refs]
        actual.append('\t'.join(['entry', str(line.level), term,
                                 ', '.join(shown), '; '.join(refs_shown)]))
    if not typstindex.compare(actual, expected, label):
        return 1
    print(f'ok   {label}: the {len(expected)} lines under {heading!r} are the '
          f'manifest\'s, each locator on a page of the chapter it names')
    return 0


def order_main(argv):
    pdf, label = argv[2:4]
    specs = argv[4:]
    text = subprocess.run(['pdftotext', pdf, '-'], check=True,
                          capture_output=True, text=True).stdout
    lines = [l.strip() for l in text.split('\n')]
    at = -1
    for spec in specs:
        kind, want = spec[0], spec[1:]
        if kind not in '=^':
            return fail(f'{label}: {spec!r} opens with neither = nor ^')
        for i in range(at + 1, len(lines)):
            if (lines[i] == want) if kind == '=' else lines[i].startswith(want):
                at = i
                break
        else:
            return fail(f'{label}: no line {spec!r} follows the one before it '
                        f'in reading order')
    print(f'ok   {label}: the {len(specs)} lines follow one another in reading '
          f'order')
    return 0


# ---------------------------------------------------------------------------
# The source derivation.
# ---------------------------------------------------------------------------

def _unescape(text):
    """Pandoc's backslash unescaping: `\\X` is X, for a punctuation X."""
    return re.sub(r'\\([!-/:-@\[-`{-~])', r'\1', text)


def _marks(source):
    """Yield (visible text, {attr: value}) for every `.index` span."""
    body = source.split('\n---\n', 1)[1]
    i = 0
    while True:
        i = body.find('[', i)
        if i < 0:
            return
        if i > 0 and body[i - 1] == '\\':
            i += 1
            continue
        j = i + 1
        while j < len(body) and body[j] != ']':
            j += 2 if body[j] == '\\' else 1
        if j >= len(body) or body[j + 1:j + 2] != '{':
            i += 1
            continue
        k = j + 2
        attrs, classes = {}, []
        while k < len(body) and body[k] != '}':
            if body[k].isspace():
                k += 1
                continue
            if body[k] == '.':
                m = re.match(r'\.([\w-]+)', body[k:])
                classes.append(m.group(1))
                k += m.end()
                continue
            if body[k] == '#':
                m = re.match(r'#[\w-]+', body[k:])
                k += m.end()
                continue
            m = re.match(r'([\w-]+)="', body[k:])
            if m is None:
                raise ValueError(f'an attribute shape this derivation does '
                                 f'not read, at {body[k:k + 40]!r}')
            k += m.end()
            value = []
            while body[k] != '"':
                if body[k] == '\\':
                    value.append(body[k:k + 2])
                    k += 2
                else:
                    value.append(body[k])
                    k += 1
            k += 1
            attrs[m.group(1)] = _unescape(''.join(value))
        if 'index' in classes:
            visible = ' '.join(_unescape(body[i + 1:j]).split())
            yield visible, attrs
        i = k + 1


def _levels(value):
    levels, current, i = [], '', 0
    while i < len(value):
        if value[i] == '!':
            if value[i + 1:i + 2] == '!':
                current += '!'
                i += 2
            else:
                levels.append(current)
                current = ''
                i += 1
        else:
            current += value[i]
            i += 1
    levels.append(current)
    return [level for level in levels if level != '']


def derived_entries(qmd):
    """Counter of (level, term, refs) over every path the marks derive."""
    source = open(qmd, encoding='utf-8').read()
    nodes = {}
    for visible, attrs in _marks(source):
        if 'index' in attrs:
            raise ValueError(f'{qmd} files a mark in a named index, which '
                             f'this derivation does not read')
        if 'entry' in attrs:
            path = tuple(_levels(attrs['entry']))
        else:
            path = (visible,) if visible else ()
        if not path:
            continue
        for depth in range(1, len(path) + 1):
            nodes.setdefault(path[:depth], [])
        for attr in ('see', 'see-also'):
            if attr not in attrs:
                continue
            target = tuple(_levels(attrs[attr]))
            if not target or target == path:
                continue
            ref = (ENGLISH[attr], ': '.join(target))
            if ref not in nodes[path]:
                nodes[path].append(ref)
    return Counter((len(path) - 1, nfc(path[-1]),
                    tuple(sorted((w, nfc(t)) for w, t in refs)))
                   for path, refs in nodes.items())


def source_main(argv):
    pdf, qmd, label, heading = argv[2:6]
    stop = tuple(argv[6:])
    try:
        expected = derived_entries(qmd)
        lines = typstindex.read(pdf, heading, stop)
    except (LookupError, ValueError) as error:
        return fail(f'{label}: {error}')
    actual = Counter()
    try:
        for line in lines:
            if line.kind != 'entry':
                continue
            term, _locators, refs = typstindex.parse_entry(line.words)
            actual[(line.level, nfc(unrepeat_clusters(term)),
                    tuple(sorted((w, nfc(unrepeat_clusters(t)))
                                 for w, t, _l in refs)))] += 1
    except ValueError as error:
        return fail(f'{label}: {error}')
    if actual != expected:
        missing = sorted((expected - actual).elements())
        extra = sorted((actual - expected).elements())
        return fail(f'{label}: the printed entries are not the ones the '
                    f'source derives.\n  derived, not printed: {missing!r}\n'
                    f'  printed, not derived: {extra!r}')
    print(f'ok   {label}: the {sum(expected.values())} entries under '
          f'{heading!r} are the ones {qmd} derives, each term and reference '
          f'compared in NFC')
    return 0


MODES = {'terms': terms_main, 'book': book_main, 'order': order_main,
         'source': source_main}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in MODES:
        sys.exit(fail(f'usage: typstcheck.py <{"|".join(MODES)}> ...'))
    sys.exit(MODES[sys.argv[1]](sys.argv))
