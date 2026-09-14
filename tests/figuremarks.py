"""The M101 checks on where an alt-text mark's locator lands, and on `alt`.

Pandoc's HTML and EPUB writers print an image's alt text as a flat string, so
an id written on a span inside it names no element of the page. The back-end
moves each such id to an empty span just after the image. Two questions are
asked of a rendered page here, and the manifest a caller hands in is derived
by hand from the fixture's source (the ORACLE RULE in run-tests.sh):

  after <html|epub> <path> <prefix> <term> <n>
      Every locator of <term> in the generated index links to an element that
      comes after the <n>th image outside the generated index, in document
      order, and whose nearest block ancestor is that image's own. The `alts`
      manifest pins which image that is.
  alts <html|epub> <path> <prefix> <manifest>
      The `alt` of each image outside the generated index, in document order,
      is the manifest's line for it. `<none>` states an image that carries no
      `alt` attribute, and `<empty>` one whose `alt` is the empty string.
  pdf <pdf> <manifest>
      The LaTeX index printed in <pdf>, one line an entry in the order
      `tests/pdfindex.py` reads them, is the manifest's lines. Both sides are
      compared in NFC, because a PDF's text layer renormalizes Unicode. The
      acceptance suite and the version matrix both read the manifest
      `tests/figure-marks-pdf.txt`.

Each subcommand prints its own `ok`/`FAIL` line and exits 0 or 1.
"""

import posixpath
import sys
import unicodedata

import epubindex
import htmlindex as H
import pdfindex

# The elements a reader sees as a block of their own. The nearest one above
# an element is the block it sits in.
BLOCK_TAGS = {
    'address', 'article', 'aside', 'blockquote', 'body', 'dd', 'div', 'dl',
    'dt', 'figcaption', 'figure', 'footer', 'h1', 'h2', 'h3', 'h4', 'h5',
    'h6', 'header', 'li', 'main', 'nav', 'ol', 'p', 'pre', 'section', 'table',
    'td', 'th', 'ul',
}

NO_ALT = '<none>'
EMPTY_ALT = '<empty>'


def _documents(kind, path):
    """`(name, root)` pairs: the one page, or the EPUB's documents in spine
    order."""
    if kind == 'html':
        return [(path, H.parse(path))]
    return epubindex.read(path).documents


def _ordered(root):
    """Every element in document order, each with its nearest block
    ancestor."""
    out = []

    def visit(node, block):
        for child in node.children:
            if isinstance(child, H.Node):
                out.append((child, block))
                visit(child, child if child.tag in BLOCK_TAGS else block)

    visit(root, root)
    return out


def _outside_sections(root, prefix):
    """The elements of a document outside every generated index section."""
    inside = set()
    for found in H.index_sections(root, prefix):
        section = H.find_id(root, found['ident'])
        inside.add(id(section))
        inside.update(id(n) for n in H.walk(section))
    return [n for n in H.walk(root) if id(n) not in inside]


def _locators(documents, prefix, term):
    """`(document name, href)` for each locator of `term` in every section."""
    out = []
    for name, root in documents:
        for found in H.index_sections(root, prefix):
            section = H.find_id(root, found['ident'])
            for record in H.index_entries(section):
                if record['kind'] == 'entry' and record['term'] == term:
                    out.extend((name, href) for href in record['locators'])
    return out


def cmd_after(kind, path, prefix, term, ordinal):
    label = f'M101-AC2: {path}'
    documents = _documents(kind, path)
    locators = _locators(documents, prefix, term)
    if not locators:
        print(f'FAIL: {label}: the index prints no locator for {term!r}, so '
              f'there is no link to hold to the image', file=sys.stderr)
        return 1
    images = []
    for name, root in documents:
        outside = {id(n) for n in _outside_sections(root, prefix)}
        for i, (node, block) in enumerate(_ordered(root)):
            if node.tag == 'img' and id(node) in outside:
                images.append((name, root, i, block))
    n = int(ordinal)
    if not 1 <= n <= len(images):
        print(f'FAIL: {label}: the page carries {len(images)} image(s) outside '
              f'the index, so there is no image {n}', file=sys.stderr)
        return 1
    image_doc, image_root, image_at, image_block = images[n - 1]
    bad = []
    for name, href in locators:
        target, _, fragment = href.partition('#')
        if kind == 'epub' and target:
            where = posixpath.normpath(
                posixpath.join(posixpath.dirname(name), target))
        else:
            where = name
        if not fragment:
            bad.append(f'  {href}: names no id')
            continue
        if where != image_doc:
            bad.append(f'  {href}: names a document other than the image\'s '
                       f'({image_doc})')
            continue
        hits = [(i, block) for i, (node, block) in enumerate(_ordered(image_root))
                if node.attrs.get('id') == fragment]
        if len(hits) != 1:
            bad.append(f'  {href}: {len(hits)} element(s) carry the id')
            continue
        at, block = hits[0]
        if at <= image_at:
            bad.append(f'  {href}: the element comes before the image')
        elif block is not image_block:
            bad.append(f'  {href}: the element sits in <{block.tag}>, not in '
                       f'the image\'s <{image_block.tag}>')
    if bad:
        print(f'FAIL: {label}: a locator of {term!r} does not land just after '
              f'image {n}:', file=sys.stderr)
        print('\n'.join(bad), file=sys.stderr)
        return 1
    print(f'ok   {label}: each of the {len(locators)} locator(s) of {term!r} '
          f'links to an element after image {n}, in the same '
          f'<{image_block.tag}>')
    return 0


def cmd_alts(kind, path, prefix, manifest):
    label = f'M101-AC2: {path}'
    expected = H.read_manifest(manifest)
    actual = []
    for _name, root in _documents(kind, path):
        for node in _outside_sections(root, prefix):
            if node.tag == 'img':
                actual.append(node.attrs.get('alt', NO_ALT) or EMPTY_ALT)
    if not expected:
        print(f'FAIL: {label}: the manifest is empty', file=sys.stderr)
        return 1
    if actual != expected:
        print(f'FAIL: {label}: the images\' alt attributes are not the ones '
              f'the manifest states', file=sys.stderr)
        for i in range(max(len(actual), len(expected))):
            got = actual[i] if i < len(actual) else '<no such image>'
            want = expected[i] if i < len(expected) else '<not in the manifest>'
            if got != want:
                print(f'  image {i + 1}\n    got  {got!r}\n    want {want!r}',
                      file=sys.stderr)
        return 1
    print(f'ok   {label}: the {len(actual)} image(s) carry the alt '
          f'attributes the manifest states, in order')
    return 0


def cmd_pdf(path, manifest):
    label = f'M101-AC1/AC2: {path}'
    expected = [unicodedata.normalize('NFC', line)
                for line in H.read_manifest(manifest)]
    if not expected:
        print(f'FAIL: {label}: the manifest is empty', file=sys.stderr)
        return 1
    actual = [unicodedata.normalize('NFC', entry.text)
              for entry in pdfindex.read(path)]
    if actual != expected:
        print(f'FAIL: {label}: the printed index is not the {len(expected)} '
              f'lines {manifest} states', file=sys.stderr)
        print(f'  got  {actual!r}\n  want {expected!r}', file=sys.stderr)
        return 1
    print(f'ok   {label}: the printed index is the {len(expected)} lines '
          f'{manifest} states, in order')
    return 0


def main(argv):
    if len(argv) == 6 and argv[0] == 'after' and argv[1] in ('html', 'epub'):
        return cmd_after(*argv[1:])
    if len(argv) == 5 and argv[0] == 'alts' and argv[1] in ('html', 'epub'):
        return cmd_alts(*argv[1:])
    if len(argv) == 3 and argv[0] == 'pdf':
        return cmd_pdf(*argv[1:])
    print('usage: figuremarks.py after <html|epub> <path> <prefix> <term> <n>\n'
          '       figuremarks.py alts <html|epub> <path> <prefix> <manifest>\n'
          '       figuremarks.py pdf <pdf> <manifest>',
          file=sys.stderr)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
