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


def parse(path, decode=True):
    """Parse a file into a Node tree rooted at a synthetic `#document`.

    With `decode` false, character entities are left as written — see
    _Builder for which manifest layer wants which.
    """
    builder = _Builder(decode=decode)
    with open(path, encoding='utf-8') as fh:
        builder.feed(fh.read())
    builder.close()
    return builder.root


def walk(node):
    """Every descendant Node, in document order."""
    for child in node.children:
        if isinstance(child, Node):
            yield child
            yield from walk(child)


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


def index_entries(section):
    """Flatten the generated index section into (depth, entry) records.

    Each record is a dict: `depth` (0 for a top-level entry), `term` (the
    entry's own text), `locators` (the href of each numbered link, in order),
    and `xrefs` (one tuple per cross-reference: kind, target text, linked,
    href or None). Records come out in rendered order.
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
        if isinstance(top, Node) and top.tag in LIST_TAGS:
            read_list(top, 0)
    if not records:
        # A section with no list at its top level means the shape changed;
        # silently returning nothing would let every manifest check pass by
        # comparing two empty sets.
        for node in walk(section):
            if node.tag in LIST_TAGS:
                raise ValueError('the index list is not a direct child of the '
                                 'index section')
    return records


def row(record):
    """The manifest form of one entry record. The format is defined here so
    the hand-written rows and the extraction cannot drift apart."""
    fields = [str(record['depth']), record['term'],
              str(len(record['locators']))]
    for kind, target, linked, _href in record['xrefs']:
        fields.append(f'{XREF_TOKEN[(kind, linked)]} {target}')
    return '\t'.join(fields)


def read_manifest(path):
    """Manifest rows from a file, blank lines dropped, order preserved."""
    with open(path, encoding='utf-8') as fh:
        return [line.rstrip('\n') for line in fh if line.strip()]
