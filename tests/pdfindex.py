"""Structural reading of a rendered PDF's printed index for the suite.

A printed index is typeset in two columns, so the reading order a human sees
is not the order any plain text extraction gives: `pdftotext` walks the page
row by row and interleaves the columns, and `pdftotext -layout` preserves the
interleaving with whitespace. Either one reports "Ångström, Alan Turing, The
Hague" for an index whose actual order is "Ångström, The Hague, ... Alan
Turing". A check that reads such output cannot tell a correctly ordered index
from a wrongly ordered one, which is the whole question a sort key raises.

So this module reads word positions instead, from `pdftotext -bbox-layout`,
and reconstructs the order the index is actually printed in: by page, then by
column, then down the column. Indent depth becomes the entry's level, read by
clustering the left edges each column actually uses rather than by assuming a
point size for one level of indentation.

This module reads the ARTIFACT. It never produces expected values: every
manifest row in run-tests.sh is derived by hand from the `.qmd` source (see
the ORACLE RULE there). Nothing here may be used to write a manifest.

One assumption, and it is a property of the fixtures rather than of LaTeX:
every column of an index this module reads carries at least one top-level
entry, so that the column's leftmost edge is a top-level edge. A column
holding nothing but sub-entries would have its own indent read as level 0.
The fixtures are written so that cannot happen, and
`columns_carry_top_level` asserts it rather than trusting it.
"""

import re
import subprocess
import sys
import xml.etree.ElementTree as ET

# `pdftotext -bbox-layout` emits XHTML in this namespace.
NS = {'x': 'http://www.w3.org/1999/xhtml'}

# Two left edges within this many points of each other are the same indent
# level. One level of index indentation is ~12pt, and the same level varies by
# well under a point between lines, so the gap is wide.
EDGE_TOLERANCE_PT = 3.0


class Entry:
    """One printed line of the index."""

    __slots__ = ('text', 'level', 'page', 'column', 'x', 'y')

    def __init__(self, text, level, page, column, x, y):
        self.text = text
        self.level = level
        self.page = page
        self.column = column
        self.x = x
        self.y = y

    @property
    def term(self):
        """The entry text with its trailing locator list removed.

        makeindex prints `term, 1, 3--5`. The split is on the last comma
        followed by something that is only digits, commas, spaces and en
        dashes, so a term containing a comma of its own survives.
        """
        return re.sub(r',\s*[\d,\s–-]+$', '', self.text).strip()

    def __repr__(self):
        return f'<Entry level={self.level} {self.text!r}>'


# A line of nothing but locator characters — digits, commas, spaces and the
# dashes of a page range. Two very different things look like this, and telling
# them apart is what _pages does below.
LOCATOR_ONLY = re.compile(r'^[\d,\s\u2013-]+$')


def _pages(pdf_path):
    """Yield (page_number, page_width, [(xMin, yMin, text), ...]).

    Two kinds of line carry nothing but locator characters, and this module
    read both as the page-number footer until M15's fixture produced the
    second. The footer is the bottom-most line on the page, and it is the only
    one dropped here. The other is a CONTINUATION: makeindex prints an entry
    and its locators on one logical line, but LaTeX wraps a long one, and the
    locators can land alone on the next physical line — a long cross-reference
    target is enough to do it. Dropping that as a footer loses the entry's
    locators silently, which is exactly the kind of evidence a check here must
    not lose.

    Continuations are NOT folded here. The line order this function sees is
    document order, which interleaves the two columns (see the module
    docstring), so "the line above" is not a question this function can answer
    — the fold runs in read(), once the lines are in the order they are
    printed in. Nothing else may consume this function's output directly.
    """
    xml = subprocess.run(
        ['pdftotext', '-bbox-layout', pdf_path, '-'],
        check=True, capture_output=True, text=True).stdout
    root = ET.fromstring(xml)
    for number, page in enumerate(root.iter(f'{{{NS["x"]}}}page'), start=1):
        raw = []
        for line in page.iter(f'{{{NS["x"]}}}line'):
            words = [w.text or '' for w in line.iter(f'{{{NS["x"]}}}word')]
            text = ' '.join(words).strip()
            if text:
                raw.append([float(line.get('xMin')),
                            float(line.get('yMin')), text])
        footer = None
        for i, (_x, y, text) in enumerate(raw):
            if LOCATOR_ONLY.match(text) and (footer is None
                                             or y > raw[footer][1]):
                footer = i
        yield (number, float(page.get('width')),
               [(x, y, text) for i, (x, y, text) in enumerate(raw)
                if i != footer])


def _fold_continuations(collected):
    """Fold each locator-only line back into the entry it belongs to.

    `collected` is `(page, column, y, x, text)` already sorted into printed
    order, so the entry a continuation belongs to is the row before it IN THAT
    ORDER — and only when that row is on the same page and in the same column,
    which is what keeps a right-column continuation off the left column's last
    entry. A continuation with no such row (an entry wrapping across a page or
    column break, so its locators open a column) has nothing to fold into and
    is dropped with a note rather than returned: returning it would add a
    third left edge and read every sub-entry in that column a level deeper.
    Dropped, its entry simply prints no locators, which a manifest row can
    state; silently attaching them to a stranger, it could not.
    """
    folded, orphans = [], []
    for row in collected:
        page, column, _y, _x, text = row
        if LOCATOR_ONLY.match(text):
            if folded and folded[-1][0] == page and folded[-1][1] == column:
                previous = folded[-1]
                folded[-1] = (previous[0], previous[1], previous[2],
                              previous[3], previous[4] + ' ' + text)
            else:
                orphans.append((page, column, text))
            continue
        folded.append(row)
    return folded, orphans


def _levels(edges):
    """Map each left edge to an indent level by clustering the edges used."""
    bands = []
    for edge in sorted(edges):
        if not bands or edge - bands[-1] > EDGE_TOLERANCE_PT:
            bands.append(edge)
    return {edge: min(range(len(bands)),
                      key=lambda i: abs(bands[i] - edge))
            for edge in edges}


def read(pdf_path, heading='Index'):
    """Read the printed index, in the order it is printed.

    Returns a list of Entry, starting at the line after the index heading and
    running to the end of the document. Raises LookupError if no line is
    exactly the heading, so a check can never silently read an empty index.
    """
    pages = list(_pages(pdf_path))
    start = None
    for i, (number, _width, lines) in enumerate(pages):
        for j, (_x, _y, text) in enumerate(lines):
            if text == heading:
                start = (i, j)
                break
        if start:
            break
    if start is None:
        raise LookupError(f'no index heading {heading!r} in {pdf_path}')

    collected = []
    for i, (number, width, lines) in enumerate(pages[start[0]:], start[0]):
        middle = width / 2.0
        for j, (x, y, text) in enumerate(lines):
            if (i, j) <= start:
                continue
            collected.append((number, 0 if x < middle else 1, y, x, text))

    # Printed order first: by page, then column, then down the column. The
    # fold below needs it, and so does the returned list.
    collected.sort(key=lambda row: (row[0], row[1], row[2]))
    collected, orphans = _fold_continuations(collected)
    if orphans:
        # Not silent: a dropped continuation is a locator count this module
        # cannot report, and a check reading it deserves to know.
        print(f'pdfindex: {len(orphans)} locator-only line(s) opened a column '
              f'with no entry to fold into and were dropped: {orphans}',
              file=sys.stderr)

    # Left edges cluster per column: the two columns sit at different edges,
    # and a sub-entry in one is further right than a top-level entry in the
    # other, so one global clustering would call them the same level.
    by_column = {}
    for _n, column, _y, x, _t in collected:
        by_column.setdefault(column, set()).add(x)
    levels = {column: _levels(edges) for column, edges in by_column.items()}

    return [Entry(text, levels[column][x], page, column, x, y)
            for page, column, y, x, text in collected]


def columns_carry_top_level(entries):
    """True when every column holds at least one top-level entry.

    The module's one assumption, asserted rather than trusted: a column whose
    entries are all sub-entries would have its own left edge read as level 0,
    and every entry in it would come back a level too shallow.
    """
    columns, top = set(), set()
    for entry in entries:
        key = (entry.page, entry.column)
        columns.add(key)
        if entry.level == 0:
            top.add(key)
    return columns == top


def outline(entries):
    """`[(level, term), ...]` — what a manifest row is compared against."""
    return [(entry.level, entry.term) for entry in entries]
