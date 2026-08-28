"""Structural reading of a rendered EPUB for the acceptance suite.

An EPUB is a zip container, and the document a reader sees is spread across
several XHTML files inside it: Pandoc's EPUB writer splits at top-level
headings, so the index section lands in a file of its own and the locator
links that point back at marked passages cross files. A check that opened a
single rendered file — the way the HTML checks do — would be reading one
chapter and calling it the document.

WHERE THIS READS FROM. `META-INF/container.xml` names the package document
(`content.opf`); the package document's `<manifest>` names every file the
publication contains, and its `<spine>` names the reading order. The XHTML
members of that manifest are what this module parses, in spine order, each
through `tests/htmlindex.py` — the same structural reader the HTML checks
use, so an entry row means the same thing in both back-ends and the two
cannot drift apart in what they hold an index to be.

WHAT IT HOLDS. Every generated index section across those documents, the
entry and letter-group rows inside each, and every link inside one, resolved
against the manifest. It is the manifest that decides which files count: a
stray XHTML member no manifest lists is not part of the publication, and a
section in it is not a section a reader can reach.

This module reads the ARTIFACT. It never produces expected values: every
manifest row in run-tests.sh is derived by hand from the `.qmd` source (see
the ORACLE RULE there). Nothing here may be used to write a manifest.
"""

import posixpath
import sys
import xml.etree.ElementTree as ET
import zipfile

import htmlindex

CONTAINER_PATH = 'META-INF/container.xml'
CONTAINER_NS = 'urn:oasis:names:tc:opendocument:xmlns:container'
OPF_NS = 'http://www.idpf.org/2007/opf'
XHTML_MEDIA_TYPE = 'application/xhtml+xml'


class Book:
    """One opened EPUB: its package manifest, and its parsed XHTML documents.

    `documents` is a list of `(name, root)` pairs in spine order, where `name`
    is the member's zip name and `root` is htmlindex's Node tree. `manifest`
    is every zip name the package manifest lists, XHTML or not — the set AC2
    resolves a locator's file part against.
    """

    __slots__ = ('path', 'opf', 'manifest', 'documents')

    def __init__(self, path, opf, manifest, documents):
        self.path = path
        self.opf = opf
        self.manifest = manifest
        self.documents = documents

    def document(self, name):
        """The parsed root for a zip name, or None where it is not a document."""
        for member, root in self.documents:
            if member == name:
                return root
        return None


def _package_path(archive, path):
    """The zip name of the package document, out of META-INF/container.xml."""
    try:
        raw = archive.read(CONTAINER_PATH)
    except KeyError:
        raise ValueError(
            f'{path} carries no {CONTAINER_PATH}, so nothing in it names a '
            f'package document and the publication cannot be read')
    root = ET.fromstring(raw)
    roots = root.findall(f'.//{{{CONTAINER_NS}}}rootfile')
    paths = [r.get('full-path') for r in roots if r.get('full-path')]
    if not paths:
        raise ValueError(
            f'{path}: {CONTAINER_PATH} names no rootfile with a full-path, '
            f'so nothing in it names a package document')
    return paths[0]


def read(path):
    """Open an EPUB and parse the XHTML documents its package manifest lists.

    Raises rather than returning an empty Book where the container, the
    package document or the manifest is unreadable: a check reading a Book
    with no documents in it would pass over an empty domain.
    """
    with zipfile.ZipFile(path) as archive:
        opf = _package_path(archive, path)
        base = posixpath.dirname(opf)
        package = ET.fromstring(archive.read(opf))

        items = {}
        manifest = []
        for item in package.findall(f'.//{{{OPF_NS}}}manifest/'
                                    f'{{{OPF_NS}}}item'):
            ident, href = item.get('id'), item.get('href')
            if ident is None or href is None:
                continue
            name = posixpath.normpath(posixpath.join(base, href))
            items[ident] = (name, item.get('media-type'))
            manifest.append(name)
        if not manifest:
            raise ValueError(
                f'{path}: {opf} lists no manifest item, so the publication '
                f'holds no file this reader could read')

        order = [ref.get('idref') for ref
                 in package.findall(f'.//{{{OPF_NS}}}spine/{{{OPF_NS}}}itemref')]
        # Spine first, then any XHTML the manifest lists and the spine does
        # not — the navigation document is usually one of those, and a
        # section in it would still be a section this reader must see.
        seen, documents = set(), []
        for ident in order + [i for i in items if i not in order]:
            entry = items.get(ident)
            if entry is None or entry[0] in seen:
                continue
            name, media = entry
            if media != XHTML_MEDIA_TYPE:
                continue
            seen.add(name)
            documents.append(
                (name, htmlindex.parse_text(
                    archive.read(name).decode('utf-8'))))
        if not documents:
            raise ValueError(
                f'{path}: {opf} lists no {XHTML_MEDIA_TYPE} item, so every '
                f'check reading this publication would read nothing')
    return Book(path, opf, manifest, documents)


def index_sections(book, prefix, minted=()):
    """Every generated index section in the publication, in reading order.

    Each hit is htmlindex.index_sections' own dict with a `document` field
    added, naming the zip member the section is in. The `after` field is that
    document's own preceding authored id, which in an EPUB is a statement
    about the split file rather than about the whole publication.
    """
    out = []
    for name, root in book.documents:
        for found in htmlindex.index_sections(root, prefix, minted):
            found = dict(found)
            found['document'] = name
            out.append(found)
    return out


def section_rows(book, prefix, minted=(), hrefs=False):
    """The manifest form of every generated index section, in reading order.

    Exactly htmlindex.section_rows' row shapes, concatenated across the
    publication's documents, so an EPUB index and an HTML one are stated in
    one form and a hand-written manifest reads the same either way.
    """
    rows = []
    for name, root in book.documents:
        rows.extend(htmlindex.section_rows(root, prefix, minted, hrefs))
    return rows


def links(book, prefix, minted=()):
    """Every `<a href>` inside a generated index section.

    Not only the locator links: a cross-reference the back-end hyperlinks is
    a link inside the section too, and a reader that collected locators alone
    would leave the other kind unresolved by anything. Each hit is a dict with
    `document` (the member the link is in), `href` (as written), `file` (the
    member it resolves to, or None for a same-document fragment) and `ident`
    (the fragment, or None where the href carries none).
    """
    out = []
    for found in index_sections(book, prefix, minted):
        section = htmlindex.find_id(book.document(found['document']),
                                    found['ident'])
        if section is None:
            raise ValueError(
                f"{book.path}: the index section {found['ident']!r} was found "
                f"in {found['document']} and then not found again by its own "
                f"id, so this reader cannot say which links are inside it")
        for node in htmlindex.walk(section):
            if node.tag != 'a':
                continue
            href = node.attrs.get('href')
            if href is None:
                continue
            target, _, fragment = href.partition('#')
            name = None
            if target:
                name = posixpath.normpath(
                    posixpath.join(posixpath.dirname(found['document']),
                                   target))
            out.append({'document': found['document'], 'href': href,
                        'file': name, 'ident': fragment or None})
    return out


def unresolved(book, prefix, minted=()):
    """Every link inside an index section that names nothing in the publication.

    A link fails to resolve three ways, and the reason is reported rather than
    the count alone: the file it names is not in the package manifest, the
    manifest lists it but it is not a document this reader parsed, or the
    document carries no element with the href's id. A link with no fragment
    resolves on its file alone — it names a document, not a passage in one.
    """
    bad = []
    for link in links(book, prefix, minted):
        name = link['file'] or link['document']
        if name not in book.manifest:
            bad.append(dict(link, reason='no manifest item names ' + name))
            continue
        root = book.document(name)
        if root is None:
            bad.append(dict(link, reason=name + ' is not an XHTML document'))
            continue
        if link['ident'] is None:
            continue
        if htmlindex.find_id(root, link['ident']) is None:
            bad.append(dict(link,
                            reason=name + ' carries no element with id '
                                   + link['ident']))
    return bad


def main(argv):
    """`epubindex.py <file.epub> <section-id-prefix>` — what the reader sees.

    A hand tool for reading a capture, not a check: it prints the sections,
    their rows and any unresolved link, and exits non-zero only where the
    publication itself could not be read.
    """
    if len(argv) != 3:
        print(f'usage: {argv[0]} <file.epub> <section-id-prefix>',
              file=sys.stderr)
        return 2
    book = read(argv[1])
    print(f'{book.path}: {len(book.documents)} XHTML document(s), '
          f'{len(book.manifest)} manifest item(s), package {book.opf}')
    for found in index_sections(book, argv[2]):
        print(f"{found['document']}\t{found['ident']}\t{found['title']}")
    for line in section_rows(book, argv[2]):
        print(line)
    for link in unresolved(book, argv[2]):
        print(f"unresolved\t{link['document']}\t{link['href']}\t"
              f"{link['reason']}")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
