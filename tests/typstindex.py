"""Structural reading of a Typst render's printed index for the suite (M098).

tests/pdfindex.py reads the order and nesting of an index; this module reads
what each printed entry line carries, which a Typst index states in three
channels plain text cannot show: which locator is set in a bold face, which
page each locator links to, and which words carry no link at all.

Three readings of the one PDF are combined, word by word:

  * `pdftotext -bbox-layout` gives every word and its box, in points from the
    top of the page. It is the source of the text.
  * `pdftohtml -xml -fontfullname -zoom 1` gives runs of text, one font each,
    with their boxes in the same points. A word takes the face of the run its
    centre falls in: bold and italic are read from that font's descriptor in
    the PDF (`_faces`), not from its name. `-fontfullname` gives the name the
    PDF's font dictionary carries, which is how a run finds its descriptor.
    `-zoom 1` puts the runs in points, the unit the word boxes use.
  * The PDF's own link annotations give each link's rectangle and the page it
    goes to. A word is linked when its centre falls in a rectangle on its page.
    Typst writes each annotation, its destination, the fonts and the page tree
    as plain dictionaries outside any compressed stream, so a regular
    expression reads them; `_links` refuses a PDF where it finds no page tree.

The index is read in printed order, by page, then by column, then down the
column, as tests/pdfindex.py reads it and for the reason its header gives.
Indent depth is the entry's level, read by clustering the left edges of each
column. A line whose words are all bold and unlinked is a letter-group
heading. Every other line is an entry: its term runs up to the first linked
or italic word, each run of linked words up to a comma is one locator, and
each italic run opens a
cross-reference whose target runs to the next italic run.

This module reads the ARTIFACT. It never produces expected values: every
manifest the suite compares its reading against is derived by hand from the
fixture source (the ORACLE RULE in run-tests.sh).

One assumption, a property of the fixtures: no entry line wraps. A wrapped
line would read as a second entry one level deeper, and `read` does not try
to tell the two apart.
"""

import re
import subprocess
import sys
import unicodedata
import xml.etree.ElementTree as ET

NS = {'x': 'http://www.w3.org/1999/xhtml'}

# Two left edges within this many points are one indent level. One Typst
# index level is 1.2em, about 13pt at the default size (typst.lua).
EDGE_TOLERANCE_PT = 3.0

# The bottom-most line of a page, when it is one word of nothing but digits or
# the letters i, v, x, l, c, d and m, is the page number the template prints,
# and is dropped.
PAGE_NUMBER = re.compile(r'^[\divxlcdm]+$', re.I)


# A face whose font descriptor's /StemV is above this is bold. Typst writes
# /StemV from the face's weight: 95.4 for the regular and italic faces and
# 168.6 for the bold face, in the PDFs of Typst 0.11.0 (Quarto 1.5.52) and of
# the Typst Quarto 1.10.18 bundles (observed 2026-10-01). The threshold is the
# midpoint.
BOLD_STEM_V = 132.0

# The /Flags bit a font descriptor sets for an italic face (PDF 1.7, 9.8.2).
ITALIC_FLAG = 1 << 6

def nfkc(text):
    """`text` in Unicode NFKC, as every reading here returns it.

    The Typst that Quarto 1.5.52 bundles maps a glyph the font sets for a
    letter sequence to one compatibility character: pdftotext reads `fig` as
    `ﬁg` (observed 2026-09-13) and `L1!!L3` as `L1‼L3` (observed 2026-10-01).
    NFKC spells each one out, as the Typst of Quarto 1.10.18 already does. No
    fixture's source holds a character NFKC changes (checked 2026-10-01 over
    examples/), so no expected text is folded.
    """
    return unicodedata.normalize('NFKC', text)


class Word:
    __slots__ = ('text', 'x0', 'y0', 'x1', 'y1', 'face', 'link')

    def __init__(self, text, x0, y0, x1, y1):
        self.text = nfkc(text)
        self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1
        self.face = (False, False)
        self.link = None

    @property
    def bold(self):
        return self.face[0]

    @property
    def italic(self):
        return self.face[1]

    def centre(self):
        return ((self.x0 + self.x1) / 2.0, (self.y0 + self.y1) / 2.0)


def _objects(data):
    """`{number: bytes}` for every `N 0 obj ... endobj` in the file."""
    found = {}
    for match in re.finditer(rb'(?m)^(\d+) 0 obj\b(.*?)\bendobj', data, re.S):
        found[int(match.group(1))] = match.group(2)
    return found


def _balanced(data, start, opener, closer):
    """The text from `start`, which is `opener`, to its matching `closer`."""
    depth, i = 0, start
    while i < len(data):
        if data.startswith(opener, i):
            depth += 1
            i += len(opener)
        elif data.startswith(closer, i):
            depth -= 1
            i += len(closer)
            if depth == 0:
                return data[start:i]
        else:
            i += 1
    raise ValueError(f'no {closer!r} closes the {opener!r} at byte {start}')


def _annotations(objects, page_body):
    """Each annotation of a page, as the bytes of its dictionary.

    Typst 0.11 writes the dictionaries inside the page's `/Annots` array, and
    the Typst of Quarto 1.10.18 writes references to them there.
    """
    found = re.search(rb'/Annots\s*\[', page_body)
    if found is None:
        return []
    array = _balanced(page_body, found.end() - 1, b'[', b']')[1:-1]
    out, i = [], 0
    while i < len(array):
        if array.startswith(b'<<', i):
            body = _balanced(array, i, b'<<', b'>>')
            out.append(body)
            i += len(body)
            continue
        ref = re.match(rb'(\d+)\s+0\s+R', array[i:])
        if ref is not None:
            out.append(objects.get(int(ref.group(1)), b''))
            i += ref.end()
            continue
        i += 1
    return out


def _links(pdf_path):
    """`{page: [(x0, y0, x1, y1, target_page), ...]}`, boxes from the top.

    Pages are numbered from 1 in page-tree order, which is the order
    pdftotext numbers them in.
    """
    data = open(pdf_path, 'rb').read()
    objects = _objects(data)
    catalog = next((body for body in objects.values()
                    if re.search(rb'/Type\s*/Catalog\b', body)), None)
    root = catalog and re.search(rb'/Pages\s+(\d+)\s+0\s+R', catalog)
    if root is None:
        raise LookupError(f'{pdf_path}: no page tree in a plain dictionary, '
                          f'so its links cannot be read here')

    pages = []

    def walk(number):
        body = objects[number]
        kids = re.search(rb'/Kids\s*\[([^\]]*)\]', body)
        if kids is not None and re.search(rb'/Type\s*/Pages\b', body):
            for kid in re.findall(rb'(\d+)\s+0\s+R', kids.group(1)):
                walk(int(kid))
        else:
            pages.append(number)

    walk(int(root.group(1)))
    page_of = {number: i for i, number in enumerate(pages, start=1)}

    def box_height(number):
        body = objects[number]
        media = re.search(rb'/MediaBox\s*\[([^\]]*)\]', body)
        if media is None:
            parent = re.search(rb'/Parent\s+(\d+)\s+0\s+R', body)
            return box_height(int(parent.group(1)))
        values = [float(v) for v in media.group(1).split()]
        return values[3] - values[1]

    links = {}
    for number in pages:
        height = box_height(number)
        for annot in _annotations(objects, objects[number]):
            if not re.search(rb'/Subtype\s*/Link\b', annot):
                continue
            rect = re.search(rb'/Rect\s*\[([^\]]*)\]', annot)
            # The destination is a `/Dest` (the Typst of Quarto 1.10.18) or
            # the `/D` of a `/GoTo` action (Typst 0.11, Quarto 1.5.52). Either
            # is an array opening with the target page, or a reference to one.
            dest = re.search(rb'/Dest\s*(?:(\d+)\s+0\s+R|\[\s*(\d+)\s+0\s+R)',
                             annot)
            if dest is None and re.search(rb'/S\s*/GoTo\b', annot):
                dest = re.search(rb'/D\s*(?:(\d+)\s+0\s+R|\[\s*(\d+)\s+0\s+R)',
                                 annot)
            if rect is None or dest is None:
                continue
            if dest.group(1) is not None:
                target = re.search(rb'\[\s*(\d+)\s+0\s+R',
                                   objects[int(dest.group(1))])
                target_obj = int(target.group(1))
            else:
                target_obj = int(dest.group(2))
            # Typst 0.11 writes a rectangle's corners top first.
            xa, ya, xb, yb = (float(v) for v in rect.group(1).split())
            x0, x1 = sorted((xa, xb))
            y0, y1 = sorted((ya, yb))
            links.setdefault(page_of[number], []).append(
                (x0, height - y1, x1, height - y0, page_of[target_obj]))
    return links


def _faces(pdf_path):
    """`{font_name: (bold, italic)}` for every font with a descriptor.

    Read from each font's descriptor rather than its name: the faces of the
    Typst that Quarto 1.5.52 bundles are named `LinLibertineB` and
    `LinLibertineI`. A composite font's descriptor sits on its descendant, and
    its own name, the one pdftohtml reports, on the font itself.
    """
    objects = _objects(open(pdf_path, 'rb').read())

    def name_of(body):
        found = re.search(rb'/BaseFont\s*/([^\s/\[\]<>()]+)', body)
        return found and found.group(1).decode('latin-1')

    def face_of(body):
        descriptor = re.search(rb'/FontDescriptor\s+(\d+)\s+0\s+R', body)
        if descriptor is None:
            return None
        desc = objects.get(int(descriptor.group(1)), b'')
        stem = re.search(rb'/StemV\s+([\d.]+)', desc)
        flags = re.search(rb'/Flags\s+(\d+)', desc)
        if stem is None or flags is None:
            raise LookupError(f'{pdf_path}: font descriptor '
                              f'{descriptor.group(1).decode()} carries no '
                              f'/StemV or no /Flags, so its face is unknown')
        return (float(stem.group(1)) > BOLD_STEM_V,
                bool(int(flags.group(1)) & ITALIC_FLAG))

    faces = {}
    for body in objects.values():
        if not re.search(rb'/Type\s*/Font\b', body):
            continue
        name = name_of(body)
        if name is None:
            continue
        face = face_of(body)
        if face is None:
            kids = re.search(rb'/DescendantFonts\s*\[\s*(\d+)\s+0\s+R', body)
            if kids is not None:
                face = face_of(objects.get(int(kids.group(1)), b''))
        if face is not None:
            faces[name] = face
    return faces


def _fonts(pdf_path):
    """`{page: [(x0, y0, x1, y1, (bold, italic)), ...]}` from pdftohtml's runs.

    A run whose font `_faces` does not know raises LookupError, so a word is
    never read as upright and regular for want of a descriptor.
    """
    xml = subprocess.run(
        ['pdftohtml', '-xml', '-stdout', '-i', '-q', '-fontfullname',
         '-zoom', '1', pdf_path],
        check=True, capture_output=True, text=True).stdout
    root = ET.fromstring(xml)
    faces = _faces(pdf_path)
    runs = {}
    names = {spec.get('id'): spec.get('family')
             for spec in root.iter('fontspec')}
    for page in root.iter('page'):
        number = int(page.get('number'))
        for text in page.iter('text'):
            name = names.get(text.get('font'), '')
            if name not in faces:
                raise LookupError(f'{pdf_path}: page {number} sets text in '
                                  f'{name!r}, which no font descriptor '
                                  f'describes')
            x0, y0 = float(text.get('left')), float(text.get('top'))
            x1 = x0 + float(text.get('width'))
            y1 = y0 + float(text.get('height'))
            runs.setdefault(number, []).append((x0, y0, x1, y1, faces[name]))
    return runs


def _inside(point, box):
    x, y = point
    return box[0] <= x <= box[2] and box[1] <= y <= box[3]


def _pages(pdf_path, footer_pattern=None):
    """Yield `(page, width, [[Word, ...], ...])`, one list per line.

    The bottom-most line of each page is dropped when it is the page's footer.
    With no `footer_pattern`, a footer is one PAGE_NUMBER word. With one, a
    footer is a line that carries no link and whose words, joined by single
    spaces, match the pattern, so a caller whose pages print a numbering of
    several words (`5 / 5`) names it (M099).
    """
    xml = subprocess.run(
        ['pdftotext', '-bbox-layout', pdf_path, '-'],
        check=True, capture_output=True, text=True).stdout
    root = ET.fromstring(xml)
    fonts = _fonts(pdf_path)
    links = _links(pdf_path)
    for number, page in enumerate(root.iter(f'{{{NS["x"]}}}page'), start=1):
        lines = []
        for line in page.iter(f'{{{NS["x"]}}}line'):
            words = []
            for w in line.iter(f'{{{NS["x"]}}}word'):
                if not (w.text or '').strip():
                    continue
                word = Word(w.text, float(w.get('xMin')), float(w.get('yMin')),
                            float(w.get('xMax')), float(w.get('yMax')))
                centre = word.centre()
                for run in fonts.get(number, []):
                    if _inside(centre, run):
                        word.face = run[4]
                        break
                for box in links.get(number, []):
                    if _inside(centre, box):
                        word.link = box[4]
                        break
                words.append(word)
            if words:
                lines.append(words)
        if lines:
            bottom = max(range(len(lines)), key=lambda i: lines[i][0].y0)
            if footer_pattern is None:
                is_footer = (len(lines[bottom]) == 1
                             and PAGE_NUMBER.match(lines[bottom][0].text))
            else:
                is_footer = (all(w.link is None for w in lines[bottom])
                             and footer_pattern.match(_text(lines[bottom])))
            if is_footer:
                del lines[bottom]
        yield number, float(page.get('width')), lines


class Line:
    """One printed line of the index: a group heading or an entry."""

    def __init__(self, kind, level, words, page, column):
        self.kind, self.level, self.words = kind, level, words
        self.page, self.column = page, column

    def row(self):
        """The line as a manifest row, for comparison and for reports.

        `group<TAB>heading` or
        `entry<TAB>level<TAB>term<TAB>locators<TAB>references`, where
        locators are `page` or `first–last`, a `*` after a bold one and
        `@N` after one that links to page N, joined by `, `; and references
        are `word|target`, a trailing `@` on one that carries a link, joined
        by `; `.
        """
        if self.kind == 'group':
            return 'group\t' + ' '.join(w.text for w in self.words)
        term, locators, refs = parse_entry(self.words)
        shown = []
        for text, bold, link in locators:
            shown.append(text + ('*' if bold else '')
                         + (f'@{link}' if link is not None else ''))
        refs_shown = [f'{word}|{target}' + ('@' if linked else '')
                      for word, target, linked in refs]
        return '\t'.join(['entry', str(self.level), term, ', '.join(shown),
                          '; '.join(refs_shown)])


def parse_entry(words):
    """`(term, [(locator, bold, link_page)], [(word, target, linked)])`.

    Raises ValueError on a line whose words do not take the entry shape, so
    a malformed line is reported rather than read as some other entry.
    """
    first = next((i for i, w in enumerate(words) if w.link is not None
                  or w.italic), len(words))
    term_words = [w.text for w in words[:first]]
    if first < len(words) and term_words:
        if not term_words[-1].endswith(','):
            raise ValueError(f'no comma after the term in {_text(words)!r}')
        term_words[-1] = term_words[-1][:-1]
    term = ' '.join(term_words)

    # A locator runs over one or more linked words, `5` or `1 / 5`, and ends
    # at a word ending in a comma or at the end of the line (M099). Its words
    # share one link and one face, or the line is not read as an entry.
    locators, refs = [], []
    i = first
    locator = []
    while i < len(words) and not words[i].italic:
        word = words[i]
        if word.link is None:
            raise ValueError(f'an unlinked word {word.text!r} among the '
                             f'locators of {_text(words)!r}')
        locator.append(word)
        i += 1
        # A comma ends a locator only where more words follow. At the end of
        # the line it stays in the text, so a stray separator reads as a
        # mismatch rather than as the locator before it (M099 review R3).
        ends = word.text.endswith(',') and i < len(words)
        if not ends and i < len(words) and not words[i].italic:
            continue
        if not ends and i < len(words):
            raise ValueError(f'no comma after locator {_text(locator)!r} in '
                             f'{_text(words)!r}')
        text = _text(locator)
        if ends:
            text = text[:-1]
        if (len({w.link for w in locator}) != 1
                or len({w.bold for w in locator}) != 1):
            raise ValueError(f'the words of locator {text!r} do not share one '
                             f'link and one face in {_text(words)!r}')
        locators.append((text, locator[0].bold, locator[0].link))
        locator = []
    while i < len(words):
        said = []
        while i < len(words) and words[i].italic:
            said.append(words[i])
            i += 1
        target = []
        while i < len(words) and not words[i].italic:
            target.append(words[i])
            i += 1
        if not target:
            raise ValueError(f'a reference word with no target in '
                             f'{_text(words)!r}')
        target_text = [w.text for w in target]
        if i < len(words):
            if not target_text[-1].endswith(';'):
                raise ValueError(f'no semicolon between two references in '
                                 f'{_text(words)!r}')
            target_text[-1] = target_text[-1][:-1]
        linked = any(w.link is not None for w in said + target)
        refs.append((' '.join(w.text for w in said), ' '.join(target_text),
                     linked))
    return term, locators, refs


def _text(words):
    return ' '.join(w.text for w in words)


def _levels(edges):
    bands = []
    for edge in sorted(edges):
        if not bands or edge - bands[-1] > EDGE_TOLERANCE_PT:
            bands.append(edge)
    return {edge: min(range(len(bands)), key=lambda i: abs(bands[i] - edge))
            for edge in edges}


def read(pdf_path, heading, stop=(), footer_pattern=None):
    """The index under the line `heading`, as a list of Line.

    With `stop`, the read ends at the first later page carrying a line that
    starts with any of those strings, and drops that page, as
    tests/pdfindex.py's bounded read does; a stop no later page carries raises
    LookupError. A start rather than a whole line, because the page after an
    index in a Typst book opens with a running header that names the chapter
    and then the section. Without `stop` the read runs to the end of the
    document. `footer_pattern` names the pages' footer, as `_pages` reads it.
    """
    pages = list(_pages(pdf_path, footer_pattern))
    start = None
    for i, (_n, _w, lines) in enumerate(pages):
        for j, words in enumerate(lines):
            if _text(words) == heading:
                start = (i, j)
                break
        if start:
            break
    if start is None:
        raise LookupError(f'no index heading {heading!r} in {pdf_path}')
    end = len(pages)
    if stop:
        wanted = set(stop)
        for i in range(start[0] + 1, len(pages)):
            if any(_text(words).startswith(want) for words in pages[i][2]
                   for want in wanted):
                end = i
                break
        else:
            raise LookupError(f'no page after {heading!r} in {pdf_path} '
                              f'carries any of {sorted(wanted)!r}')
    collected = []
    for i in range(start[0], end):
        number, width, lines = pages[i]
        for j, words in enumerate(lines):
            if (i, j) <= start:
                continue
            column = 0 if words[0].x0 < width / 2.0 else 1
            collected.append((number, column, words[0].y0, words))
    collected.sort(key=lambda row: (row[0], row[1], row[2]))
    edges = {}
    for _n, column, _y, words in collected:
        edges.setdefault(column, set()).add(words[0].x0)
    levels = {column: _levels(e) for column, e in edges.items()}
    out = []
    for number, column, _y, words in collected:
        is_group = all(w.bold and w.link is None for w in words)
        out.append(Line('group' if is_group else 'entry',
                        levels[column][words[0].x0], words, number, column))
    return out


def link_count(pdf_path, pages):
    """How many link annotations the PDF places on the given pages."""
    links = _links(pdf_path)
    return sum(len(links.get(page, [])) for page in pages)


def printed_text(row):
    """The text a manifest row prints, as `tests/pdfindex.py` reads a line.

    `(level, text)`: a group row prints its heading at level 0, and an entry
    row prints its term, each locator without its bold and link marks, and
    each reference, with the separators `qi-index-entry` sets.
    """
    fields = row.split('\t')
    if fields[0] == 'group':
        return (0, fields[1])
    _kind, level, term, locators, refs = fields
    text = term
    for locator in (locators.split(', ') if locators else []):
        text += ', ' + re.sub(r'\*?(@\d+)?$', '', locator)
    for i, ref in enumerate(refs.split('; ') if refs else []):
        word, target = ref.rstrip('@').split('|', 1)
        text += (', ' if i == 0 else '; ') + word + ' ' + target
    return (int(level), text)


def pages_main(argv, footer_pattern=None):
    """`typstindex.py pages <pdf> <manifest> <label> <heading> [stop ...]`.

    Reads the index with `tests/pdfindex.py`, which needs only pdftotext, and
    compares each line's level and text with the text the manifest's rows
    print: the entries in order, each locator with its page number. The
    version matrix runs this where the bold face and links are not read.
    """
    import pdfindex
    pdf, manifest, label, heading = argv[2:6]
    stop = tuple(argv[6:])
    expected = [printed_text(row) for row in manifest_rows(manifest)]
    try:
        entries = pdfindex.read(pdf, heading=heading, stop=stop,
                                footer_pattern=(footer_pattern
                                                or pdfindex.LOCATOR_ONLY))
    except LookupError as error:
        print(f'FAIL: {label}: {error}', file=sys.stderr)
        return 1
    actual = [(entry.level, entry.text) for entry in entries]
    if not compare(actual, expected, label):
        return 1
    print(f'ok   {label}: pdfindex reads the {len(expected)} lines of '
          f'{heading!r} in the manifest\'s order, each locator\'s text as '
          f'the manifest prints it')
    return 0


def manifest_rows(path):
    """A manifest file's rows: every line but blank ones and `#` comments.

    An entry row with no references ends in an empty field, and a trailing
    tab does not survive every editor, so an entry row is padded back to its
    five fields.
    """
    rows = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        fields = line.split('\t')
        if fields[0] == 'entry':
            fields += [''] * (5 - len(fields))
        rows.append('\t'.join(fields))
    return rows


def compare(actual, expected, label):
    """Print a row-by-row report and return True when the lists match."""
    if actual == expected:
        return True
    print(f'FAIL: {label}: the printed index does not match the manifest.',
          file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        a = actual[i] if i < len(actual) else None
        e = expected[i] if i < len(expected) else None
        print(f'{"  " if a == e else "->"} {i}: got {a!r}\n'
              f'{"  " if a == e else "->"} {i}: want {e!r}', file=sys.stderr)
    return False


def main(argv, footer_pattern=None):
    """`typstindex.py <pdf> <manifest> <label> <heading> [stop ...]`.

    The manifest holds one `row()` per line (`manifest_rows`). Exits 0 on a
    match and 1, with a report, otherwise.
    """
    pdf, manifest, label, heading = argv[1:5]
    stop = tuple(argv[5:])
    expected = manifest_rows(manifest)
    try:
        actual = [line.row()
                  for line in read(pdf, heading, stop, footer_pattern)]
    except (LookupError, ValueError) as error:
        print(f'FAIL: {label}: {error}', file=sys.stderr)
        return 1
    if not compare(actual, expected, label):
        return 1
    print(f'ok   {label}: the {len(expected)} lines of {heading!r} match the '
          f'manifest, each locator\'s face and link included')
    return 0


def _footer_option(argv):
    """`(argv, pattern)`: argv without a `--footer=REGEX` option, and the
    pattern that option names, or None. Both modes take it, for pages whose
    footer is not one page-number word (M099)."""
    rest, pattern = [], None
    for arg in argv:
        if arg.startswith('--footer='):
            pattern = re.compile(arg[len('--footer='):])
        else:
            rest.append(arg)
    return rest, pattern


if __name__ == '__main__':
    ARGV, FOOTER = _footer_option(sys.argv)
    if len(ARGV) > 1 and ARGV[1] == 'pages':
        sys.exit(pages_main(ARGV, FOOTER))
    sys.exit(main(ARGV, FOOTER))
