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
import re
from html.parser import HTMLParser

# Elements that never have an end tag, so the builder must not push them.
VOID_ELEMENTS = {
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link',
    'meta', 'param', 'source', 'track', 'wbr',
}

# Elements whose TEXT CONTENT a browser reads as text and not as markup, so a
# tag written inside one is no element of the page. Python's parser knows two
# of them; the other five are as much character data as `script` is, and a
# planted `<p id=...>` inside a `textarea` would otherwise come back as a real
# node carrying a real id. The same seven the extension's id census steps over
# (`_extensions/index/modules/html.lua`), so on the pages the fixtures write
# the reader and the code under test read the same elements. They are not the
# same parser, and shapes part them, the census reading each the way a browser
# does and this reader not: `</textarea/>` ends the element for the census and
# not here, so the rest of the string is swallowed as text; and `<iframe/>`
# opens a raw-text element for the census and is self-closing here, so the
# census reads its content as text where this reader reads it as markup. How
# many others there are is not counted here — the ones written down are the
# ones a case has reached. Neither shape is written in any fixture. `title`,
# `noscript` and `plaintext` are text content too and are deliberately absent
# from both: no case renders them here.
RAW_TEXT_ELEMENTS = (
    'script', 'style', 'xmp', 'iframe', 'noembed', 'noframes', 'textarea',
)

# A `template` element's content is markup, but a browser parses it into a
# document fragment of its own: no element of the page carries a name written
# in there, and `getElementById` does not reach one. Python's parser builds it
# as ordinary children, so a planted `<p id=...>` inside a `template` would
# come back as a real node carrying a real id — the same divergence the five
# elements above were named for. The extension's id census steps over the same
# content (`_extensions/index/modules/html.lua`), so on the pages the fixtures
# write the reader and the code under test read the same elements.
TEMPLATE_ELEMENT = 'template'

# Inside a `script` element's text a browser tracks how far a `</script>` still
# reaches: a `<!--` starts an escaped run, a `<script>` opened inside that run
# doubles it, and the first `</script>` after that returns the run to merely
# escaped instead of ending the element; a `-->` in either run returns the text
# to plain script data. Python's parser ends the element at the first
# `</script>` whatever came before it, so the markup a fixture writes past that
# point would come back as real elements of the page. `_Builder` below carries
# the three states and holds the element open where a browser holds it open —
# the same reading the extension's id census takes
# (`_extensions/index/modules/html.lua`).
SCRIPT_ELEMENT = 'script'
SCRIPT_DATA, SCRIPT_ESCAPED, SCRIPT_DOUBLE = 'data', 'escaped', 'double'
_SCRIPT_TAG_END = ' \t\n\r\f/>'

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
    # Read as text, never as markup. HTMLParser consults this list by name on
    # the instance, so naming it here is what puts the other five under the
    # same rule its own two already had; its end-tag match is the browser's,
    # `</textarea >` ending the element and `</textareax>` not.
    CDATA_CONTENT_ELEMENTS = RAW_TEXT_ELEMENTS

    def __init__(self, decode=True):
        # How many `template` elements the reader is inside; above zero,
        # nothing read belongs to the page. Templates nest, so it is a depth
        # and not a flag, and one nothing closes swallows the rest.
        self.template_depth = 0
        # Where inside a `script` element's text the reader is, once one is
        # open: plain data, an escaped run, or a doubled one.
        self.script_state = SCRIPT_DATA
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
        if self.template_depth:
            if tag == TEMPLATE_ELEMENT:
                self.template_depth += 1
            return
        node = Node(tag, dict(attrs))
        self.stack[-1].children.append(node)
        if tag == TEMPLATE_ELEMENT:
            # The element itself is on the page and carries its own id; its
            # content is not, so it is never pushed and nothing inside it is
            # built.
            self.template_depth = 1
            return
        if tag not in VOID_ELEMENTS:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        if self.template_depth:
            if tag == TEMPLATE_ELEMENT:
                self.template_depth += 1
            return
        self.stack[-1].children.append(Node(tag, dict(attrs)))
        if tag == TEMPLATE_ELEMENT:
            # A `template` has no self-closing form: `<template/>` opens one
            # for a browser and for the census, so the markup after it is
            # content of the fragment and no element of the page.
            self.template_depth = 1

    def handle_endtag(self, tag):
        if self.template_depth:
            if tag == TEMPLATE_ELEMENT:
                self.template_depth -= 1
            return
        # Close the nearest matching open element, discarding anything left
        # open inside it. A close tag matching nothing open is ignored rather
        # than allowed to unwind the whole document.
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                return

    def parse_html_declaration(self, i):
        # `<![CDATA[…]]>` written in HTML content is a bogus comment for a
        # browser: it ends at the first `>` after the `<!`, and the markup
        # after that `>` is markup. `HTMLParser` reads it as a marked section
        # instead, running it to the `]]>`, so an `id=` standing between the
        # two is swallowed and this reader reported a page one element short
        # of the page a reader meets. The id census ends it at the first `>`
        # (`_extensions/index/modules/html.lua`), so until this the suite's
        # own reader and the census disagreed about that id.
        #
        # Narrowed to `<![` on purpose: `<!--` and `<!DOCTYPE` are the other
        # two things a `<!` opens here and neither reaches this branch. In
        # foreign content — inside `svg` or `math` — a browser DOES end the
        # construct at `]]>`; neither this reader nor the census tracks
        # foreign content, which is the gap DESIGN.md's Known issues record.
        raw = self.rawdata
        if raw[i:i + 3] == '<![':
            gtpos = raw.find('>', i + 3)
            if gtpos < 0:
                return -1
            self.unknown_decl(raw[i + 3:gtpos])
            return gtpos + 1
        return super().parse_html_declaration(i)

    def set_cdata_mode(self, elem, **kwargs):
        # `**kwargs` because the signature moved: Python 3.12 onward passes
        # `escapable=` to say whether the element's text takes character
        # references, and this override must reach both.
        super().set_cdata_mode(elem, **kwargs)
        self.script_state = SCRIPT_DATA
        if elem == SCRIPT_ELEMENT:
            # `HTMLParser` scans a `script`'s text for `</script\s*>` alone, so
            # `</script id=zz>` — an end tag a browser reads, whose attributes
            # it drops — is never reached at all and the rest of the document
            # is dropped with it. Stop on any `</script` and let `parse_endtag`
            # below decide, as a browser decides, which of them ends the
            # element.
            self.interesting = re.compile(r'</\s*script', re.IGNORECASE)

    def parse_endtag(self, i):
        # Inside a `script`, which `</script` ends the element is a browser's
        # question and not this parser's: `HTMLParser` ends one at `</ script>`
        # (which a browser reads as script text) and never ends one at
        # `</script id=zz>` (which a browser does end, reading the attributes
        # and dropping them), and a `</script>` reached inside a doubled run
        # returns that run to merely escaped and leaves the element open. All
        # three are read here the way a browser reads them, the tag's own text
        # being script text like the rest wherever it does not end the element.
        if self.cdata_elem == SCRIPT_ELEMENT:
            raw = self.rawdata
            ends = (raw[i:i + 8].lower() == '</' + SCRIPT_ELEMENT
                    and raw[i + 8:i + 9] in _SCRIPT_TAG_END
                    and raw[i + 8:i + 9] != '')
            if not ends:
                self.handle_data(raw[i:i + 2])
                return i + 2
            gtpos = raw.find('>', i)
            if gtpos < 0:
                return -1
            if self.script_state == SCRIPT_DOUBLE:
                self.handle_data(raw[i:gtpos + 1])
                self.script_state = SCRIPT_ESCAPED
                return gtpos + 1
            self.handle_endtag(SCRIPT_ELEMENT)
            self.clear_cdata_mode()
            return gtpos + 1
        return super().parse_endtag(i)

    def _read_script_states(self, data):
        state, low, i, n = self.script_state, data.lower(), 0, len(data)
        while i < n:
            if state != SCRIPT_DATA and low.startswith('-->', i):
                state, i = SCRIPT_DATA, i + 3
            elif state == SCRIPT_DATA and low.startswith('<!--', i):
                # Two characters in, not four: a `<!-->` or a `<!--->` ends the
                # run it opens, its `-->` overlapping the `<!--`.
                state, i = SCRIPT_ESCAPED, i + 2
            elif (state == SCRIPT_ESCAPED and low.startswith('<script', i)
                  and low[i + 7:i + 8] in _SCRIPT_TAG_END and low[i + 7:i + 8]):
                state, i = SCRIPT_DOUBLE, i + 7
            else:
                i += 1
        self.script_state = state

    def handle_data(self, data):
        if self.cdata_elem == SCRIPT_ELEMENT:
            self._read_script_states(data)
        if self.template_depth:
            return
        self.stack[-1].children.append(data)

    # Only reached with decode=False, where an entity stays as written.
    def handle_entityref(self, name):
        if self.template_depth:
            return
        self.stack[-1].children.append(f'&{name};')

    def handle_charref(self, name):
        if self.template_depth:
            return
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


def section_rows(root, prefix, minted=(), hrefs=False, labels=False):
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
        rows.extend(row(r, hrefs, labels) for r in found['records'])
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


def minted_anchors(root, prefix):
    """Every anchor this extension minted, as (printed text, id) pairs.

    In document order, one pair per ELEMENT carrying such an id. Keyed on the
    element and not on the string it prints: two marks printing one string are
    two anchors, and a read that keys a map by the printed text reports
    whichever it met first and loses the other. A caller that wants the
    anchors on the marks printing one term groups these pairs by their first
    member and reads the whole group (M084 T1).
    """
    return [(text(n).strip(), n.attrs['id']) for n in walk(root)
            if (n.attrs.get('id') or '').startswith(prefix)]


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


# The five positions a generated entry line prints punctuation at, named as
# the milestone that made them author-settable names them (M58). The name is
# read off the STRUCTURE around the punctuation -- which spans it sits between
# and what came before it -- never off the character printed, so a manifest
# stating the wrong glyph at the right position and one stating the right
# glyph at the wrong position fail differently.
SEP_TERM_LOCATORS = 'S1'      # term -> its locators
SEP_LOCATOR_LOCATOR = 'S2'    # one locator -> the next
SEP_LOCATORS_XREF = 'S3'      # locators -> the first cross-reference
SEP_TERM_XREF = 'S4'          # term -> the first cross-reference, no locators
SEP_XREF_XREF = 'S5'          # one cross-reference -> the next


def entry_separators(item):
    """The punctuation one entry line prints between its parts, in order.

    One `(site, text)` pair per position, where `site` is one of the five
    constants above and `text` is the run of characters between the two spans
    EXACTLY as the page holds it -- glyph and trailing whitespace both. The
    whitespace is not stripped here: whether a separator is followed by the
    space this extension writes is the question a check asks of it, and a
    reader that stripped it could not be asked.

    Read from the item's own children in document order, so the sequence is
    the order a reader meets the marks in: the run in front of the locators
    span, then the runs inside it between one numbered link and the next, then
    the run in front of each cross-reference span.
    """
    pairs = []
    pending = None
    seen_locators = False
    seen_xref = False
    for child in item.children:
        if isinstance(child, str):
            pending = (pending or '') + child
            continue
        if not isinstance(child, Node):
            continue
        cls = classes(child)
        if 'qi-locators' in cls:
            pairs.append((SEP_TERM_LOCATORS, pending or ''))
            inner, first = None, True
            for sub in child.children:
                if isinstance(sub, str):
                    inner = (inner or '') + sub
                elif isinstance(sub, Node):
                    if not first:
                        pairs.append((SEP_LOCATOR_LOCATOR, inner or ''))
                    first = False
                    inner = None
            seen_locators = True
        elif 'qi-xref' in cls:
            if seen_xref:
                site = SEP_XREF_XREF
            elif seen_locators:
                site = SEP_LOCATORS_XREF
            else:
                site = SEP_TERM_XREF
            pairs.append((site, pending or ''))
            seen_xref = True
        pending = None
    return pairs


def index_entries(section):
    """Flatten the generated index section into records, in rendered order.

    Two record kinds, distinguished by `kind`. An `entry` record is a dict:
    `depth` (0 for a top-level entry), `term` (the entry's own text),
    `locators` (the href of each numbered link, in order), `xrefs` (one
    tuple per cross-reference: kind, target text, linked, href or None, and
    the WORD printed in front of the target), and `separators` (the
    punctuation between the line's parts, see entry_separators). The kind is read from the class
    the back-end writes and the word from the text it prints, so the two are
    independent readings: an override that changed the class, or a class that
    printed the wrong word, is visible as a disagreement rather than folded
    into one field. A
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
                # The label word is the emphasized run in front of the
                # target, which is what the back-end emits and the only text
                # in the span that is not the target itself.
                words = [n for n in own_nodes(span) if n.tag == 'em']
                if len(words) != 1:
                    raise ValueError(
                        f'cross-reference has {len(words)} label word(s), '
                        f'expected exactly 1')
                xrefs.append((kind, text(targets[0]), bool(links),
                              links[0].attrs.get('href') if links else None,
                              text(words[0]).strip()))
            records.append({
                'kind': 'entry',
                'depth': depth,
                'term': text(terms[0]),
                'locators': locators,
                'xrefs': xrefs,
                'separators': entry_separators(item),
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


def row(record, hrefs=False, labels=False):
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

    `labels` puts the WORD a cross-reference prints into its field, between
    the kind token and the target — `see-link cf. Cats` rather than
    `see-link Cats`. Off by default, so every manifest written before the
    words became overridable (M56) keeps the rows it was derived with; on for
    the fixtures whose subject is the word itself, where the kind token alone
    would read the same whatever word the page printed. The group-heading row
    needs no flag: it has always carried the text its heading shows.
    """
    if record['kind'] == 'heading':
        return f'{LETTER_TOKEN}\t{record["label"]}'
    fields = [str(record['depth']), record['term'],
              ' '.join(record['locators']) if hrefs
              else str(len(record['locators']))]
    for kind, target, linked, _href, word in record['xrefs']:
        token = XREF_TOKEN[(kind, linked)]
        fields.append(f'{token} {word} {target}' if labels
                      else f'{token} {target}')
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


# An RFC 3986 scheme: an ASCII letter, then any run of letters, digits, `+`,
# `-` and `.`, closed by the `:` this pattern requires. Both letter classes
# admit either case, which is the case-insensitivity the rule asks for, so
# `MAILTO:` is a scheme here and no flag is needed to make it one.
SCHEME = re.compile(r'[A-Za-z][A-Za-z0-9+.\-]*:')


def leaves_publication(href):
    """True where `href` names something the publication does not contain.

    The one definition of that question for this suite (D-057). Every reader
    that has to tell an outward link from a link into the publication calls
    this by this name: `resolve_href` below, `epubcheck.cmd_unique`,
    `epubindex.links` and `sitecheck.check_links`. Before it there were four
    different answers, and over one publication carrying an `https:` locator
    two commands returned opposite verdicts on the same href.

    The href is stripped of surrounding whitespace and cut at its first `#`,
    and what is left leaves the publication when it opens `//` — a
    protocol-relative reference, whose authority is a host and not a file
    here — or matches an anchored scheme. Joining either against the linking
    document's directory builds a path no page map and no manifest lists, so
    a link that is not broken would be reported as one that is.

    What it does NOT catch: a percent-encoded opening. `%2F%2Fevil.com` is a
    protocol-relative reference written in escapes, and this reads it as a
    relative path with a strange name (KI120). Nor is a fragment-only href
    caught, or an empty one: neither has a file part, and both name the
    document carrying them.

    A relative filename that carries a colon in its first segment reads as
    leaving — `notes:draft.xhtml` is a scheme match, not a file. An author
    who means a file writes `./notes:draft.xhtml`, which is what a relative
    reference already requires of that name; the rule errs only toward
    calling something external.
    """
    target = href.strip().partition('#')[0]
    return target.startswith('//') or SCHEME.match(target) is not None


def resolve_href(page, href):
    """Where `href`, written on the page at relative path `page`, points.

    Returns `(target page, fragment)` with the target normalized against the
    same root `page` is relative to, or `None` where `leaves_publication`
    above says the href leaves, so a locator into the site and one out of it
    are told apart here the way every other reader tells them apart (D-057).
    A fragment-only href resolves to `page` itself, which is how a locator
    inside the chapter holding the index is written.
    """
    if leaves_publication(href):
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
