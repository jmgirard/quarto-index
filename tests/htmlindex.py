"""Structural reading of rendered HTML for the acceptance suite.

The checks need to ask structural questions of a rendered page — what is
inside the generated index section, what is outside it, which entry carries
which locators — and a regex over the serialized markup cannot answer them:
the HTML writer chooses attribute order, and a nested list looks exactly like
its parent to a pattern match.

This module reads the ARTIFACT. It never produces expected values: every
manifest row in run-tests.sh is derived by hand from the `.qmd` source (see
the ORACLE RULE there). Nothing here may be used to write a manifest.
"""

import os
from html.parser import HTMLParser

# Elements that never have an end tag, so the builder must not push them.
VOID_ELEMENTS = {
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link',
    'meta', 'param', 'source', 'track', 'wbr',
}

LIST_TAGS = ('ul', 'ol')


class Node:
    """One element. `children` holds Nodes and plain strings, in order."""

    __slots__ = ('tag', 'attrs', 'children')

    def __init__(self, tag, attrs=None):
        self.tag = tag
        self.attrs = attrs or {}
        self.children = []

    def __repr__(self):
        return f'<Node {self.tag} {self.attrs}>'


class _Builder(HTMLParser):
    def __init__(self, decode=True):
        # Two layers, two manifests. The index-entry manifests are stated in
        # what a READER sees, so `&amp;` must come back as `&` (M03-AC5 asks
        # for the character itself as an exact element). The visible-terms
        # manifest predates this module and is stated in the MARKUP layer, so
        # its extraction passes decode=False and the rows it has always
        # carried keep their meaning.
        super().__init__(convert_charrefs=decode)
        self.root = Node('#document')
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = Node(tag, dict(attrs))
        self.stack[-1].children.append(node)
        if tag not in VOID_ELEMENTS:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.stack[-1].children.append(Node(tag, dict(attrs)))

    def handle_endtag(self, tag):
        # Close the nearest matching open element, discarding anything left
        # open inside it. A close tag matching nothing open is ignored rather
        # than allowed to unwind the whole document.
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                return

    def handle_data(self, data):
        self.stack[-1].children.append(data)

    # Only reached with decode=False, where an entity stays as written.
    def handle_entityref(self, name):
        self.stack[-1].children.append(f'&{name};')

    def handle_charref(self, name):
        self.stack[-1].children.append(f'&#{name};')


def parse_text(markup, decode=True):
    """Parse markup already in hand into a Node tree.

    The path-taking `parse` below is the same reading; this form exists for a
    document that is not a file on disk — an XHTML member read out of an EPUB
    container (tests/epubindex.py). One builder, so the two forms cannot come
    to disagree about what the markup says.
    """
    builder = _Builder(decode=decode)
    builder.feed(markup)
    builder.close()
    return builder.root


def parse(path, decode=True):
    """Parse a file into a Node tree rooted at a synthetic `#document`.

    With `decode` false, character entities are left as written — see
    _Builder for which manifest layer wants which.
    """
    with open(path, encoding='utf-8') as fh:
        return parse_text(fh.read(), decode=decode)


def walk(node):
    """Every descendant Node, in document order."""
    for child in node.children:
        if isinstance(child, Node):
            yield child
            yield from walk(child)


def document_order(root):
    """Every element in document order.

    An element's place in this list is its position on the rendered page, so
    two nodes' positions answer "which of these comes first" — the question a
    placement check asks and a manifest of contents cannot.
    """
    return list(walk(root))


def position(root, node):
    """`node`'s place in document order, or -1 if it is not in the tree."""
    for i, other in enumerate(walk(root)):
        if other is node:
            return i
    return -1


def position_of_id(root, identifier):
    """The place in document order of the element carrying this id, or -1.

    Read from the same walk the ids come from, so a missing id and a first
    element are never confused: -1 is absent, 0 is first.
    """
    for i, node in enumerate(walk(root)):
        if node.attrs.get('id') == identifier:
            return i
    return -1


def empty_divs(root):
    """Every `div` holding neither text nor an element — the shape a removed
    block leaves behind when it is not removed cleanly."""
    return [n for n in walk(root)
            if n.tag == 'div' and not text(n).strip()
            and not any(isinstance(c, Node) for c in n.children)]


def own_nodes(node):
    """Descendants in document order, NOT descending into nested lists.

    An index entry's own markup and its sub-entries' markup are otherwise
    indistinguishable: both sit inside the same `<li>`.
    """
    for child in node.children:
        if isinstance(child, Node):
            if child.tag in LIST_TAGS:
                continue
            yield child
            yield from own_nodes(child)


def classes(node):
    return set(node.attrs.get('class', '').split())


def find_id(root, identifier):
    """The single element carrying this id, or None."""
    for node in walk(root):
        if node.attrs.get('id') == identifier:
            return node
    return None


def index_section(root):
    """The generated index section, found by its heading rather than by its id.

    An id-collision probe is exactly the case that must not assume the id, and
    Quarto puts a heading's id on the `<section>` wrapper it builds rather than
    on the `<h1>` itself — so the heading locates the section and the wrapper
    carries the name. Returns the innermost section containing the heading, or
    the heading itself where the writer emitted no wrapper.
    """
    heads = [n for n in walk(root)
             if n.tag in ('h1', 'h2') and text(n).strip() == 'Index']
    if not heads:
        return None
    head = heads[0]
    best = None
    # walk() is pre-order, so an ancestor is seen before its descendants and
    # the LAST matching section is the innermost one.
    for node in walk(root):
        if node.tag == 'section' and any(d is head for d in walk(node)):
            best = node
    return best if best is not None else head


def preceding_authored_id(root, node, minted):
    """The id of the last element BEFORE `node` that this extension did not mint.

    A section's place on the page is what a placement check asks about, and the
    element it follows is the only part of that place an author wrote. Read in
    document order rather than as a preceding sibling: the HTML writer nests a
    lower heading's section inside the higher one before it, so the authored
    heading a generated section actually follows is often not its sibling at
    all — it is its predecessor's last child.

    `minted` is the id prefixes this extension mints, passed in rather than
    written here so the suite's own pins against the filter's constants are
    what decide which ids are ours. Skipping them is the whole point: every id
    between an authored heading and the section it precedes is one of ours.

    Returns None where nothing authored comes before the node.
    """
    found = None
    for other in walk(root):
        if other is node:
            return found
        ident = other.attrs.get('id', '')
        if ident and not any(ident.startswith(p) for p in minted):
            found = ident
    return None


def index_sections(root, prefix, minted=()):
    """Every generated index section on the page, in document order.

    `prefix` is the section id this extension mints — passed in rather than
    written here, so the suite's own pin against the filter's constant is what
    decides which ids are ours. A document declaring no indexes has one section
    carrying the bare prefix; one declaring them has a section per index,
    carrying the prefix and the index's own name (M38).

    Each hit is a dict: `ident` (the id the section carries), `tag` and `title`
    (the element its heading is, and the text it shows), `after` (the id of the
    last authored element before it, or None), and `records` (the section's own
    entry and letter-group records, in rendered order).

    The heading's ELEMENT is reported and not only its text: a section headed
    by something other than a heading element would read identically on the
    page and reach neither the table of contents nor a reader's outline.
    """
    out = []
    for node in walk(root):
        ident = node.attrs.get('id', '')
        if ident != prefix and not ident.startswith(prefix + '-'):
            continue
        heads = [n for n in walk(node) if n.tag in ('h1', 'h2', 'h3')]
        if not heads:
            raise ValueError(
                f'the generated index section {ident!r} carries no heading '
                f'element, so it has no title a reader can find it by')
        out.append({'ident': ident, 'tag': heads[0].tag,
                    'title': text(heads[0]).strip(),
                    'after': preceding_authored_id(root, node, minted),
                    'records': index_entries(node)})
    return out


SECTION_TOKEN = 'section'


def section_rows(root, prefix, minted=(), hrefs=False):
    """The manifest form of every generated index section on a page.

    One `section<TAB>id<TAB>heading tag<TAB>title[<TAB>id it follows]` row per
    section, each followed by that section's own entry and letter-group rows in
    rendered order — the same `row()` form a single index's manifest uses, so
    the two cannot drift apart in what an entry row means. No entry row starts
    with the word `section`: an entry row starts with a depth digit and a
    letter row with `letter`.

    `hrefs` is `row()`'s own flag, passed straight through: False states how
    MANY locators an entry has, True states WHERE each one points. The
    hand-written manifests here read the count form, and the cross-version
    comparison (M43) reads the href form, where a locator that moved without
    changing in number is exactly the difference being looked for.

    The trailing `id it follows` field is written in the COUNT form only. It
    names the last element on the page this extension did not mint, which on a
    page whose author wrote no id before the index is whatever the renderer's
    own scaffold happens to carry — a value the cross-version comparison would
    read as this extension emitting a different index when what moved was
    Quarto's wrapper (M48). The count form is read by manifests written against
    one Quarto version, where the field is what those manifests carry about
    WHERE on the page a generated section sits, so it stays there.
    """
    rows = []
    for found in index_sections(root, prefix, minted):
        fields = [SECTION_TOKEN, found['ident'], found['tag'], found['title']]
        if not hrefs:
            fields.append(found['after'] or '-')
        rows.append('\t'.join(fields))
        rows.extend(row(r, hrefs) for r in found['records'])
    return rows


def duplicate_ids(root, prefix=None):
    """Every id carried by more than one element, in first-seen order.

    `prefix` narrows the sweep to the ids one namespace owns — a page also
    carries whatever its renderer's own furniture claims, which is nothing
    this extension mints or promises.
    """
    seen, dupes = set(), []
    for identifier in all_ids(root):
        if prefix is not None and not identifier.startswith(prefix):
            continue
        if identifier in seen and identifier not in dupes:
            dupes.append(identifier)
        seen.add(identifier)
    return dupes


def count_id(root, identifier):
    return sum(1 for node in walk(root) if node.attrs.get('id') == identifier)


def all_ids(root):
    """Every id in the document, as a list (so duplicates are visible)."""
    return [n.attrs['id'] for n in walk(root) if n.attrs.get('id')]


def text(node, sep=''):
    """Concatenated text of a subtree, entities already decoded.

    `sep` is inserted at every element boundary. The default reads one
    element's own text; a sweep across the whole page passes `' '`, so a
    string that only appears by running two elements together is not mistaken
    for text a reader can see.
    """
    out = []
    for child in node.children:
        if isinstance(child, Node):
            out.append(sep + text(child, sep) + sep)
        else:
            out.append(child)
    return ''.join(out)


def find_all(root, tag=None, cls=None):
    """Descendants matching a tag and/or a class, in document order."""
    return [n for n in walk(root)
            if (tag is None or n.tag == tag)
            and (cls is None or cls in classes(n))]


def strip_subtree(root, node):
    """Remove `node` from the tree, returning True if it was found."""
    for parent in [root, *walk(root)]:
        for i, child in enumerate(parent.children):
            if child is node:
                del parent.children[i]
                return True
    return False


# ---------------------------------------------------------------------------
# The generated index section
# ---------------------------------------------------------------------------

XREF_KIND_CLASS = {'qi-see': 'see', 'qi-see-also': 'see also'}
# The manifest's short token for each (kind, linked) combination.
XREF_TOKEN = {
    ('see', False): 'see-plain', ('see', True): 'see-link',
    ('see also', False): 'also-plain', ('see also', True): 'also-link',
}

# The class a letter-group heading carries, and the token its manifest row
# starts with. An entry row always starts with a depth digit, so the two row
# shapes cannot be mistaken for one another.
LETTER_CLASS = 'qi-letter'
LETTER_TOKEN = 'letter'


def letter_label(node):
    """A group heading's label text.

    Surrounding whitespace is stripped: the HTML writer decides whether a
    block element's content sits on its own line, and a label that ended up
    spanning lines could not be a manifest row at all. A label is a single
    letter or the word Symbols, so nothing meaningful is stripped.
    """
    return text(node).strip()


def index_entries(section):
    """Flatten the generated index section into records, in rendered order.

    Two record kinds, distinguished by `kind`. An `entry` record is a dict:
    `depth` (0 for a top-level entry), `term` (the entry's own text),
    `locators` (the href of each numbered link, in order), and `xrefs` (one
    tuple per cross-reference: kind, target text, linked, href or None). A
    `heading` record is a letter-group heading: `label`, the text it shows.

    Headings and lists are read from the section's own children in the order
    they sit there, so a heading's place among the entries is what the page
    shows rather than something this function decides.
    """
    records = []

    def read_list(list_node, depth):
        for item in list_node.children:
            if not isinstance(item, Node) or item.tag != 'li':
                continue
            terms = [n for n in own_nodes(item) if 'qi-term' in classes(n)]
            if len(terms) != 1:
                raise ValueError(
                    f'index entry at depth {depth} has {len(terms)} term '
                    f'span(s), expected exactly 1')
            locator_spans = [n for n in own_nodes(item)
                             if 'qi-locators' in classes(n)]
            locators = []
            for span in locator_spans:
                locators += [a.attrs.get('href', '')
                             for a in find_all(span, 'a')]
            xrefs = []
            for span in own_nodes(item):
                if 'qi-xref' not in classes(span):
                    continue
                kind = None
                for cls, name in XREF_KIND_CLASS.items():
                    if cls in classes(span):
                        kind = name
                if kind is None:
                    raise ValueError('cross-reference span carries no kind')
                targets = [n for n in walk(span) if 'qi-target' in classes(n)]
                if len(targets) != 1:
                    raise ValueError(
                        f'cross-reference has {len(targets)} target span(s), '
                        f'expected exactly 1')
                links = find_all(targets[0], 'a')
                xrefs.append((kind, text(targets[0]), bool(links),
                              links[0].attrs.get('href') if links else None))
            records.append({
                'kind': 'entry',
                'depth': depth,
                'term': text(terms[0]),
                'locators': locators,
                'xrefs': xrefs,
                'id': terms[0].attrs.get('id', ''),
            })
            for nested in item.children:
                if isinstance(nested, Node) and nested.tag in LIST_TAGS:
                    read_list(nested, depth + 1)

    for top in section.children:
        if not isinstance(top, Node):
            continue
        if LETTER_CLASS in classes(top):
            records.append({'kind': 'heading', 'label': letter_label(top)})
        elif top.tag in LIST_TAGS:
            read_list(top, 0)
    if not any(r['kind'] == 'entry' for r in records):
        # A generated section always has entries — it is built only where
        # marks exist — so no entry record means the shape changed, and
        # silently returning nothing would let every set-shaped check pass by
        # comparing two empty sets. Raise either way, naming which of the
        # three shapes was found: a list sitting where this function reads it
        # and holding nothing, a list somewhere else in the section, and no
        # list at all. Headings alone do not clear this. The empty direct
        # child is named as itself and not as a misplaced list, which is what
        # it was reported as before: a message that says a list is in the
        # wrong place, about a list in the right place, sends a reader of the
        # version matrix's own dump looking for a nesting change that is not
        # there (M45).
        direct = [n for n in section.children
                  if isinstance(n, Node) and n.tag in LIST_TAGS]
        # A list sitting somewhere this function does not read it is the
        # louder finding of the two and is reported first: a page carrying
        # BOTH an empty list where one belongs and the real one a level down
        # would otherwise be reported as an empty index, which says nothing
        # about the nesting that is the actual change.
        if [n for n in walk(section)
                if n.tag in LIST_TAGS and not any(n is d for d in direct)]:
            raise ValueError('the index list is not a direct child of the '
                             'index section')
        if direct:
            raise ValueError('the index section carries an entry list with no '
                             'entry row in it')
        raise ValueError('the index section carries no entry list at all')
    return records


def entry_records(section):
    """Only the entry records of a generated index section.

    Most checks ask a question about entries — how many, which terms, where
    the locators point — and a letter-group heading has no term at all. They
    read through here so that adding headings could not quietly slip an
    entry-shaped hole into a check that indexes records by term.
    """
    return [r for r in index_entries(section) if r['kind'] == 'entry']


def row(record, hrefs=False):
    """The manifest form of one entry record. The format is defined here so
    the hand-written rows and the extraction cannot drift apart.

    Two formats, one per question. A single document's index links only
    within its own page, so its manifest states how MANY locators an entry
    has; a book's index links across pages, so `hrefs` states WHERE each
    locator points, space-separated in order. A count cannot answer the book
    question — three locators on one entry is exactly what a book gets right
    by accident when every one of them points at the wrong chapter.

    A letter-group heading is its own row shape, `letter<TAB><label>`, which
    no entry row can collide with: an entry row starts with a depth digit.
    """
    if record['kind'] == 'heading':
        return f'{LETTER_TOKEN}\t{record["label"]}'
    fields = [str(record['depth']), record['term'],
              ' '.join(record['locators']) if hrefs
              else str(len(record['locators']))]
    for kind, target, linked, _href in record['xrefs']:
        fields.append(f'{XREF_TOKEN[(kind, linked)]} {target}')
    return '\t'.join(fields)


def letter_sweep(root):
    """Every `qi-letter` element in the WHOLE document, in document order.

    Each hit is a dict: `label` (its text), `tag` (the element it is),
    `classes` (every class it carries), `ident` (its id, or the empty
    string), and `in_item` (whether it or any ancestor is a list item). The
    sweep is whole-document rather than section-scoped on purpose — a heading
    that leaked outside the generated index is exactly what a check reading
    only the section cannot see — and `in_item` answers the other half: a
    heading belongs between the entry lists, never inside one.

    `tag`, `classes` and `ident` are reported because WHICH element carries
    the class is the whole point of the choice: a heading element would copy
    its text into the table of contents and mint an id into the namespace the
    generated ids are checked against, which is exactly what a div avoids.
    Reading only the label could not tell the two apart.
    """
    hits = []

    def descend(node, in_item):
        for child in node.children:
            if not isinstance(child, Node):
                continue
            # The hit's own tag counts: an element that were itself a list
            # item is inside one, whatever its ancestors are.
            here = in_item or child.tag == 'li'
            if LETTER_CLASS in classes(child):
                hits.append({'label': letter_label(child),
                             'tag': child.tag,
                             'classes': sorted(classes(child)),
                             'ident': child.attrs.get('id', ''),
                             'in_item': here})
            descend(child, here)

    descend(root, False)
    return hits


# ---------------------------------------------------------------------------
# A rendered book: many pages, and links that cross between them
# ---------------------------------------------------------------------------


def html_files(directory):
    """Every `.html` file under `directory`, recursively, as `/`-separated
    paths relative to it, sorted.

    A book's pages sit at whatever depth its chapters do, so a check that
    asks "is there an index section anywhere else in the site" has to walk
    the tree rather than one directory — a subdirectory chapter is exactly
    where a missed page would hide.
    """
    found = []
    for base, _dirs, files in os.walk(directory):
        for name in files:
            if name.endswith('.html'):
                path = os.path.relpath(os.path.join(base, name), directory)
                found.append(path.replace(os.sep, '/'))
    return sorted(found)


def resolve_href(page, href):
    """Where `href`, written on the page at relative path `page`, points.

    Returns `(target page, fragment)` with the target normalized against the
    same root `page` is relative to, or `None` for a link that leaves the
    site (a URL with a scheme). A fragment-only href resolves to `page`
    itself, which is how a locator inside the chapter holding the index is
    written.
    """
    if '://' in href or href.startswith('mailto:'):
        return None
    path, _, fragment = href.partition('#')
    if not path:
        return page, fragment
    target = os.path.normpath(os.path.join(os.path.dirname(page), path))
    return target.replace(os.sep, '/'), fragment


def read_manifest(path):
    """Manifest rows from a file, blank lines dropped, order preserved."""
    with open(path, encoding='utf-8') as fh:
        return [line.rstrip('\n') for line in fh if line.strip()]
