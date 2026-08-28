"""A document built from every snippet, and what its index shows that a
bare-mark document's does not (M50).

The snippet file is prose an editor inserts into somebody's manuscript. Held
against the docs alone it can still be wrong in the way that matters most: a
body an editor inserts that the filter does not act on. So the bodies are
rendered. Every snippet becomes a fixture document, and the SAME snippets
become a control in which every mark is bare, and each attribute is then read
as the difference between the two indexes — which is a claim about the
attribute rather than about a manifest row, and one no rename of an internal
identifier can make vacuously true.

  generate <snippets.json> <fixture.qmd> <control.qmd>
      Write both documents. A body carrying a construct on one of this
      extension's classes is document content; every other body is metadata
      and goes in the front matter, which is where the index declarations
      belong. Tab stops are replaced by their placeholder default text, the
      substitution `tests/editormeta.py` documents.

      The control is the same document under three rules: every mark loses
      its attributes; the snippet placing a declared index by name is omitted
      whole, the control having no such index for it to place; and the
      metadata snippets go with the declarations they carry. Nothing else
      differs, so a difference between the two indexes is an attribute's
      doing and not the documents'.

      Both documents write the placement snippets last, sharing one lead
      sentence: a sentence standing after the index a PDF prints at the first
      marker is read by a text extraction of that PDF as one more line of the
      printed index.

  effects <snippets.json> <fixture.html> <control.html>
      Each attribute's effect, read from the two rendered indexes. Read in
      HTML and not in PDF because one of them cannot be read in PDF at all:
      `mention=` prints its locator in bold, which is a font and not a
      character, and no text extraction of a PDF can see it.

  folded <snippets.json> <pdf-rows>
      The PDF's printed index, given as the rows `tests/indexdump.py pdf`
      dumps: one index carrying the entries of both declared ones, which is
      what a LaTeX render does today and what the docs site says it does.
      Rows rather than the PDF itself, so this clause can be planted without
      typesetting a second document.

Every mode refuses a domain that emptied: a snippet set with no mark in it, an
index section that is not there, an entry the comparison is about that neither
document carries.

Usage:  python3 tests/editorfixture.py <mode> [...]

Exits non-zero with a `FAIL:` line naming what it found.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import editormeta  # noqa: E402
import htmlindex  # noqa: E402

# The section id the HTML back-end mints. run-tests.sh pins it to the filter's
# own constant and passes it in; the default is for a caller outside the suite.
SECTION_ID = os.environ.get('HTML_SECTION_ID', 'qi-index')

# The class the HTML back-end puts on a principal locator's link. Pinned the
# same way, and read here rather than through `htmlindex.row()`, whose row form
# states how many locators an entry has and not how any of them is printed.
PRINCIPAL_CLASS = os.environ.get('HTML_PRINCIPAL_CLASS', 'qi-principal')

# The title of the document the generator writes, and the lead sentence it
# writes before each snippet. Prose with no construct in it, so the sweep the
# checks run over the generated document sees the snippets alone.
TITLE = 'Every snippet this extension ships'
FILTERS = 'filters:\n  - index\n'


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    return 1


class Unreadable(Exception):
    """A rendered section this module cannot read. Carried to `main`, which
    reports it as a finding rather than letting it out as a traceback."""


def levels(value):
    """One attribute value split into index levels.

    The parse the ORACLE RULE in run-tests.sh states, derived by hand from the
    documented semantics and never from output: a single `!` separates levels
    and `!!` is a literal `!`, scanned left to right, longest match first.
    """
    out, current, i = [], '', 0
    while i < len(value):
        if value.startswith('!!', i):
            current += '!'
            i += 2
        elif value[i] == '!':
            out.append(current)
            current = ''
            i += 1
        else:
            current += value[i]
            i += 1
    out.append(current)
    return out


def load(snippets_path):
    """Every snippet, expanded, with the constructs each body carries.

    Each is a dict: `name`, `text` (the body with its tab stops replaced),
    `constructs` (the class and attributes of each of ours in it), and `marks`
    (the visible text of each `.index` span, in written order) — the term a
    mark indexes under when it carries no `entry=`, which is what the control's
    entry for that snippet is.
    """
    try:
        entries = json.loads(editormeta.read(snippets_path))
    except json.JSONDecodeError as bad:
        raise SystemExit(fail(f'{snippets_path}: does not parse as JSON '
                              f'({bad})'))
    out = []
    for name, entry in entries.items():
        text = editormeta.expand(entry.get('body', ''))
        found = editormeta.constructs(text)
        out.append({'name': name, 'text': text, 'constructs': found,
                    'marks': marked_terms(text)})
    return out


def marked_terms(text):
    """The visible text of every `[…]{.index …}` span in `text`.

    Read by walking back from the attribute block to the `]` that closes the
    span and then to its opening `[`, which is what Pandoc's own span syntax
    is; a mark's visible text holds no bracket in any snippet this extension
    ships, and one that did would be reported by the length check below rather
    than read wrong in silence.
    """
    terms = []
    for match in editormeta.ATTR_BLOCK.finditer(text):
        classes, _attrs = editormeta.parse_attrs(match.group(1))
        if editormeta.MARK_CLASS not in classes:
            continue
        head = text[:match.start()]
        if not head.endswith(']'):
            continue
        open_at = head.rfind('[')
        if open_at < 0:
            continue
        terms.append(head[open_at + 1:-1])
    return terms


def attribute_sites(snippets):
    """Every attribute the snippet set writes on a mark, with the term those
    marks carry and the values written.

    Grouped by attribute: `snippets` (the snippet names that write it),
    `terms` and `values` (one entry per mark that writes it, in written
    order). An attribute may be written twice by one snippet — `range=` is
    written on both ends of its pair — but two SNIPPETS writing it would leave
    every clause below reading whichever entry came first, which
    `check_generate` refuses rather than compares arbitrarily.
    """
    sites = {}
    for snippet in snippets:
        marks = list(snippet['marks'])
        index = 0
        for item in snippet['constructs']:
            if item['cls'] != editormeta.MARK_CLASS:
                continue
            term = marks[index] if index < len(marks) else None
            index += 1
            for name, value in item['attrs']:
                site = sites.setdefault(
                    name, {'snippets': [], 'terms': [], 'values': []})
                if snippet['name'] not in site['snippets']:
                    site['snippets'].append(snippet['name'])
                site['terms'].append(term)
                site['values'].append(value)
    for site in sites.values():
        site['term'] = site['terms'][0]
        site['value'] = site['values'][0]
    return sites


def is_metadata(snippet):
    """A snippet with no construct of ours in it is metadata, not content."""
    return not snippet['constructs']


def places_index(snippet):
    """Whether a snippet's body places an index, named or not."""
    return any(item['cls'] == editormeta.MARKER_CLASS
               for item in snippet['constructs'])


def places_named_index(snippet):
    """Whether a snippet's body places a declared index by name."""
    return any(item['cls'] == editormeta.MARKER_CLASS
               and any(name == 'index' for name, _value in item['attrs'])
               for item in snippet['constructs'])


def bare(text):
    """`text` with every mark stripped of its attributes.

    The visible text is untouched, so the control indexes each marked term
    under its own words — which is what every attribute below is read as a
    departure from.
    """
    for match in reversed(list(editormeta.ATTR_BLOCK.finditer(text))):
        classes, _attrs = editormeta.parse_attrs(match.group(1))
        if editormeta.MARK_CLASS not in classes:
            continue
        text = (text[:match.start()] + '{.' + editormeta.MARK_CLASS + '}'
                + text[match.end():])
    return text


def document(snippets, control):
    """One of the two documents, as text.

    The control differs by three rules and no fourth: every mark loses its
    attributes; a snippet placing a declared index by name is omitted whole,
    the control having no such index for it to place and no bare form of that
    snippet to write instead; and the metadata snippets are omitted with the
    declarations they carry. Everything else — the prose, the order, the bare
    placement marker — is the same text, so a difference between the two
    indexes is an attribute's doing and not the documents'.
    """
    metadata = [s for s in snippets if is_metadata(s)]
    content = [s for s in snippets if not is_metadata(s)]
    if control:
        content = [s for s in content if not places_named_index(s)]
    marks = [s for s in content if not places_index(s)]
    markers = [s for s in content if places_index(s)]
    head = [f'title: "{TITLE}"']
    if not control:
        head += [s['text'] for s in metadata]
    body = []
    for snippet in marks:
        body.append(f'The snippet named {snippet["name"]} writes:')
        body.append('')
        body.append(bare(snippet['text']) if control else snippet['text'])
        body.append('')
    # The placement snippets go last and share one lead sentence, so nothing
    # but an empty div follows the index a PDF prints at the first of them: a
    # sentence standing there is read by a text extraction of the PDF as one
    # more line of the printed index.
    if markers:
        body.append('The snippet(s) named '
                    + ', '.join(s['name'] for s in markers) + ' write:')
        body.append('')
        for snippet in markers:
            body.append(snippet['text'])
            body.append('')
    return ('---\n' + '\n'.join(head) + '\n' + FILTERS + '---\n\n'
            + '\n'.join(body).rstrip() + '\n')


def check_generate(snippets_path, fixture_path, control_path):
    snippets = load(snippets_path)
    if not snippets:
        return fail(f'{snippets_path}: declares no snippet, so the documents '
                    f'below would carry nothing to render')
    content = [s for s in snippets if not is_metadata(s)]
    metadata = [s for s in snippets if is_metadata(s)]
    if not content:
        return fail(f'{snippets_path}: no snippet body carries a construct on '
                    f'one of this extension\'s classes, so the fixture would '
                    f'render a document with no mark in it')
    if not metadata:
        return fail(f'{snippets_path}: every snippet body carries a '
                    f'construct, so no snippet declares the indexes the '
                    f'fixture\'s front matter needs')
    sites = attribute_sites(snippets)
    if not sites:
        return fail(f'{snippets_path}: no snippet body writes an attribute on '
                    f'a mark, so the effect clauses would compare nothing')
    repeated = sorted(name for name, site in sites.items()
                      if len(site['snippets']) > 1)
    if repeated:
        return fail(f'{snippets_path}: writes {", ".join(repeated)} in more '
                    f'than one snippet, so the effect clauses could not say '
                    f'which snippet an entry came from')
    split = sorted(name for name, site in sites.items()
                   if len(set(site['terms'])) != 1)
    if split:
        return fail(f'{snippets_path}: writes {", ".join(split)} on marks '
                    f'carrying different terms, so the effect clauses could '
                    f'not say which entry to compare')
    missing = sorted(name for name, site in sites.items() if not site['term'])
    if missing:
        return fail(f'{snippets_path}: writes {", ".join(missing)} on a mark '
                    f'whose visible text could not be read, so the control '
                    f'has no entry to compare against')
    for path, control in ((fixture_path, False), (control_path, True)):
        with open(path, 'w', encoding='utf-8') as handle:
            handle.write(document(snippets, control))
    print(f'ok   M50-AC4: {fixture_path} and {control_path} are written from '
          f'all {len(snippets)} snippet(s) — {len(content)} of content and '
          f'{len(metadata)} of metadata — with tab stops replaced by their '
          f'placeholder text, the control writing every mark bare and '
          f'declaring no index')
    return 0


def sections(path):
    """Every generated index section on a page, as (id, node, records).

    The records are `index_entries`' and not `entry_records`': the letter-group
    headings are records too, and where an entry files under one of them is
    exactly what the sort-key clause below reads.
    """
    root = htmlindex.parse(path)
    out = []
    for node in htmlindex.walk(root):
        ident = node.attrs.get('id', '')
        if ident == SECTION_ID or ident.startswith(SECTION_ID + '-'):
            try:
                records = htmlindex.index_entries(node)
            except ValueError as bad:
                # A section this reader cannot read is a finding, not a
                # traceback: a crash exits non-zero for a reason nothing
                # states. `tests/indexdump.py` catches the same ValueError on
                # the same ground. Review F4.
                raise Unreadable(f'{path}: section {ident!r}: {bad}')
            out.append((ident, node, records))
    return out


def entry(records, term):
    """The one entry record whose term is `term`, or None."""
    hits = [r for r in records if r['kind'] == 'entry' and r['term'] == term]
    return hits[0] if len(hits) == 1 else None


def group_of(records, term):
    """The letter-group label the entry `term` sits under, or None."""
    label = None
    for record in records:
        if record['kind'] == 'heading':
            label = record['label']
        elif record['depth'] == 0 and record['term'] == term:
            return label
    return None


def check_effects(snippets_path, fixture_html, control_html):
    """Each attribute's effect, as the difference between the two indexes."""
    snippets = load(snippets_path)
    sites = attribute_sites(snippets)
    fixture = sections(fixture_html)
    control = sections(control_html)
    if not fixture:
        return fail(f'{fixture_html}: carries no generated index section, so '
                    f'every clause below would compare two empty sets')
    if len(control) != 1:
        return fail(f'{control_html}: carries {len(control)} generated index '
                    f'section(s), where a document declaring none has exactly '
                    f'one; the control is not the bare-mark document this '
                    f'compares against')
    control_rows = control[0][2]
    fixture_rows = [r for _ident, _node, rows in fixture for r in rows]
    for name in ('entry', 'see', 'see-also', 'sort', 'mention', 'range',
                 'index'):
        if name not in sites:
            return fail(f'{snippets_path}: no snippet writes {name}=, so its '
                        f'clause below would pass over nothing')

    # entry= — the entry text is the value's levels, and not the marked term.
    site = sites['entry']
    want = levels(site['value'])
    if entry(control_rows, site['term']) is None:
        return fail(f'{control_html}: carries no entry for the term '
                    f'{site["term"]!r}, so entry= has nothing to differ from')
    if entry(fixture_rows, site['term']) is not None:
        return fail(f'{fixture_html}: still carries an entry for the marked '
                    f'term {site["term"]!r}, so entry= indexed it under its '
                    f'own text after all')
    depth = 0
    for level in want:
        found = [r for r in fixture_rows if r['kind'] == 'entry'
                 and r['term'] == level and r['depth'] == depth]
        if not found:
            return fail(f'{fixture_html}: carries no entry {level!r} at depth '
                        f'{depth}, so entry={site["value"]!r} was not split '
                        f'into the {len(want)} level(s) it writes')
        depth += 1

    # see= and see-also= — a cross-reference to the target, in place of a
    # locator. The kind is read as the words a reader sees, which is what
    # htmlindex records; the target as the text of the target span.
    for name, shown in (('see', 'see'), ('see-also', 'see also')):
        site = sites[name]
        plain = entry(control_rows, site['term'])
        marked = entry(fixture_rows, site['term'])
        if plain is None or marked is None:
            return fail(f'the term {site["term"]!r} is not one entry in each '
                        f'of {fixture_html} and {control_html}, so {name}= '
                        f'has nothing to compare')
        if not plain['locators'] or plain['xrefs']:
            return fail(f'{control_html}: the bare mark on {site["term"]!r} '
                        f'prints {len(plain["locators"])} locator(s) and '
                        f'{len(plain["xrefs"])} cross-reference(s), where a '
                        f'bare mark prints one locator and no '
                        f'cross-reference')
        if marked['locators']:
            return fail(f'{fixture_html}: the entry {site["term"]!r} still '
                        f'prints a locator, so {name}= did not replace it')
        kinds = [(kind, target) for kind, target, _linked, _href
                 in marked['xrefs']]
        if kinds != [(shown, site['value'])]:
            return fail(f'{fixture_html}: the entry {site["term"]!r} prints '
                        f'{kinds}, where {name}="{site["value"]}" prints one '
                        f'{shown!r} cross-reference to {site["value"]!r}')

    # sort= — the entry files under its key's letter, not its term's.
    site = sites['sort']
    keyed = group_of(fixture_rows, site['term'])
    plain = group_of(control_rows, site['term'])
    if keyed is None or plain is None:
        return fail(f'the entry {site["term"]!r} sits under no letter group '
                    f'in one of the two indexes, so sort= has no position to '
                    f'compare')
    if keyed != site['value'][0].upper():
        return fail(f'{fixture_html}: the entry {site["term"]!r} files under '
                    f'the letter group {keyed!r}, where sort='
                    f'"{site["value"]}" files it under '
                    f'{site["value"][0].upper()!r}')
    if plain != site['term'][0].upper():
        return fail(f'{control_html}: the bare mark on {site["term"]!r} files '
                    f'under the letter group {plain!r}, where its own text '
                    f'files it under {site["term"][0].upper()!r}')

    # mention= — the locator is emphasized, which is the one effect no PDF
    # text extraction can see. An element and not a class: the class alone
    # needs a stylesheet, and this extension ships none.
    site = sites['mention']
    for path, rows, want_it in ((fixture_html, fixture, True),
                                (control_html, control, False)):
        marked = []
        for ident, node, _records in rows:
            for link in htmlindex.find_all(node, 'a'):
                if PRINCIPAL_CLASS not in htmlindex.classes(link):
                    continue
                if not htmlindex.find_all(link, 'strong'):
                    return fail(f'{path}: a locator in {ident} carries the '
                                f'{PRINCIPAL_CLASS!r} class but no emphasis '
                                f'element, so it reads as an ordinary locator '
                                f'on a page with no stylesheet')
                marked.append(link)
        if want_it and len(marked) != 1:
            return fail(f'{fixture_html}: carries {len(marked)} emphasized '
                        f'locator(s), where mention="{site["value"]}" on '
                        f'{site["term"]!r} emphasizes exactly one')
        if not want_it and marked:
            return fail(f'{control_html}: carries {len(marked)} emphasized '
                        f'locator(s), where a document of bare marks '
                        f'emphasizes none')

    # range= — one locator spanning the pair, where two bare marks print two.
    site = sites['range']
    marked = entry(fixture_rows, site['term'])
    plain = entry(control_rows, site['term'])
    if marked is None or plain is None:
        return fail(f'the term {site["term"]!r} is not one entry in each of '
                    f'{fixture_html} and {control_html}, so range= has '
                    f'nothing to compare')
    if len(plain['locators']) != 2:
        return fail(f'{control_html}: the entry {site["term"]!r} prints '
                    f'{len(plain["locators"])} locator(s), where its two bare '
                    f'marks print two')
    if len(marked['locators']) != 1:
        return fail(f'{fixture_html}: the entry {site["term"]!r} prints '
                    f'{len(marked["locators"])} locator(s), where an opening '
                    f'and its closing print one')

    # index= — the entry sits in the named index's own section, and in no
    # other; the control, declaring none, carries it in its single index.
    site = sites['index']
    named = [(ident, rows) for ident, _node, rows in fixture
             if ident == f'{SECTION_ID}-{site["value"]}']
    if len(named) != 1:
        return fail(f'{fixture_html}: carries {len(named)} section(s) with '
                    f'the id {SECTION_ID}-{site["value"]}, where '
                    f'index="{site["value"]}" prints one')
    if entry(named[0][1], site['term']) is None:
        return fail(f'{fixture_html}: the section {named[0][0]} carries no '
                    f'entry for {site["term"]!r}, so index='
                    f'"{site["value"]}" did not file it there')
    elsewhere = [ident for ident, _node, rows in fixture
                 if ident != named[0][0] and entry(rows, site['term'])]
    if elsewhere:
        return fail(f'{fixture_html}: the entry {site["term"]!r} also appears '
                    f'in {", ".join(elsewhere)}, so index= filed it in more '
                    f'than one index')
    if entry(control_rows, site['term']) is None:
        return fail(f'{control_html}: carries no entry for {site["term"]!r}, '
                    f'so index= has no single-index render to differ from')

    print(f'ok   M50-AC4: every attribute shows in {fixture_html} an effect '
          f'{control_html} does not — entry= splits into '
          f'{len(levels(sites["entry"]["value"]))} level(s), see= and '
          f'see-also= replace the locator, sort= moves the entry to another '
          f'letter group, mention= emphasizes one locator, range= prints one '
          f'locator where two bare marks print two, and index= files the '
          f'entry in the {SECTION_ID}-{sites["index"]["value"]} section '
          f'alone')
    return 0


def check_folded(snippets_path, rows_path):
    """The PDF's one printed index, carrying both declared indexes' entries."""
    snippets = load(snippets_path)
    sites = attribute_sites(snippets)
    if 'index' not in sites:
        return fail(f'{snippets_path}: no snippet writes index=, so there is '
                    f'no second index for the PDF to fold')
    named = sites['index']['term']
    bare_terms = [term for snippet in snippets for term in snippet['marks']
                  if not any(name == 'index' for item in snippet['constructs']
                             for name, _value in item['attrs'])]
    if not bare_terms:
        return fail(f'{snippets_path}: no snippet marks a term outside a '
                    f'named index, so a folded index could not be told from '
                    f'the named one alone')
    printed = [line.split('\t')[1] for line in
               editormeta.read(rows_path).splitlines() if '\t' in line]
    if not printed:
        return fail(f'{rows_path}: carries no printed entry row, so the fold '
                    f'below would be read off an empty index')
    if named not in printed:
        return fail(f'{rows_path}: the printed index carries no entry for '
                    f'{named!r}, which index="{sites["index"]["value"]}" '
                    f'files in the second declared index; a PDF render folds '
                    f'every declared index into one')
    outside = [term for term in bare_terms if term in printed]
    if not outside:
        return fail(f'{rows_path}: the printed index carries none of the '
                    f'{len(bare_terms)} term(s) marked outside the named '
                    f'index, so it is that index alone rather than the fold '
                    f'of both')
    print(f'ok   M50-AC4: the PDF prints one index of {len(printed)} entry '
          f'line(s) carrying both {named!r}, filed in the second declared '
          f'index, and {len(outside)} term(s) filed in the first')
    return 0


MODES = {
    'generate': (check_generate, 3),
    'effects': (check_effects, 3),
    'folded': (check_folded, 2),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    func, needed = MODES[argv[1]]
    args = argv[2:]
    if len(args) != needed:
        raise SystemExit(__doc__)
    try:
        return func(*args)
    except Unreadable as bad:
        return fail(str(bad))


if __name__ == '__main__':
    sys.exit(main(sys.argv))
