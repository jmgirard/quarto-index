"""Read the labels and the id links of a Typst render (M119).

Two modes, each printing an `ok` line and exiting 0, or a FAIL line naming
what it read and exiting 1:

  typstlabels.py labels <query-output> <fixture.qmd> <check-name>
      <query-output> is what `quarto typst query <file>.typ metadata` wrote,
      warnings included: the JSON array is its one line opening `[`. Fails
      where a label is on two of the listed elements, and where the listed
      labels opening `qi-mark-` are fewer than the spans of class `index` the
      fixture source holds, which is the floor under the first clause.

  typstlabels.py links <pdf> <fixture.qmd> <ids.tsv> <page> <check-name>
      <ids.tsv> holds one `id<TAB>page` row per author's id, in the order the
      links on <page> are written, each page derived by hand from the source.
      Fails where the ids written on spans of class `index` in the fixture are
      not the ids the table names, and where the links on <page>, read top to
      bottom and left to right, do not go to the table's pages in its order.
"""

import json
import re
import sys

sys.path.insert(0, 'tests')
import typstindex  # noqa: E402

# A span of class `index`: the attribute block after `]` that holds `.index`.
SPAN_ATTRS = re.compile(r'\]\{([^{}]*)\}')


def index_spans(path):
    """The attribute blocks of the fixture's spans of class `index`."""
    text = open(path, encoding='utf-8').read()
    return [attrs for attrs in SPAN_ATTRS.findall(text)
            if '.index' in attrs.split()]


def span_ids(path):
    ids = []
    for attrs in index_spans(path):
        ids.extend(word[1:] for word in attrs.split() if word.startswith('#'))
    return ids


def fail(name, message):
    print(f'FAIL: {name}: {message}', file=sys.stderr)
    sys.exit(1)


def labels(query_path, fixture, name):
    lines = [line for line in open(query_path, encoding='utf-8')
             if line.startswith('[')]
    if len(lines) != 1:
        fail(name, f'{query_path} holds {len(lines)} line(s) opening `[`, '
                   f'not the one JSON array the query writes')
    try:
        elements = json.loads(lines[0])
    except json.JSONDecodeError as error:
        fail(name, f'the line opening `[` in {query_path} is not one JSON '
                   f'array ({error})')
    seen = {}
    for element in elements:
        label = element.get('label')
        if label is not None:
            seen[label] = seen.get(label, 0) + 1
    twice = sorted(label for label, n in seen.items() if n > 1)
    if twice:
        fail(name, f'the label(s) {", ".join(twice)} are each on more than '
                   f'one metadata element')
    marks = len(index_spans(fixture))
    minted = sorted(label for label in seen if label.startswith('<qi-mark-'))
    if len(minted) < marks:
        fail(name, f'the query lists {len(minted)} qi-mark label(s), fewer '
                   f'than the {marks} marks {fixture} holds')
    print(f'ok   {name}: {len(seen)} labels on {len(elements)} metadata '
          f'elements, each on one, {len(minted)} of them for the {marks} '
          f'marks')


def links(pdf, fixture, table_path, page, name):
    rows = []
    for line in open(table_path, encoding='utf-8'):
        if line.strip() and not line.startswith('#'):
            label, target = line.rstrip('\n').split('\t')
            rows.append((label, int(target)))
    written = span_ids(fixture)
    if not written:
        fail(name, f'{fixture} holds no id on a span of class `index`')
    if sorted(written) != sorted(label for label, _ in rows):
        fail(name, f'{fixture} writes the ids {sorted(written)!r} on its '
                   f'marks, and {table_path} names '
                   f'{sorted(label for label, _ in rows)!r}')
    boxes = sorted(typstindex._links(pdf).get(page, []),
                   key=lambda box: (round(box[1]), box[0]))
    got = [box[4] for box in boxes]
    want = [target for _, target in rows]
    if got != want:
        fail(name, f'page {page} carries links to pages {got!r}, not '
                   f'{want!r} for the ids {[label for label, _ in rows]!r}')
    print(f'ok   {name}: the {len(rows)} links on page {page} go to the '
          f'pages of their marks')


if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    if mode == 'labels' and len(sys.argv) == 5:
        labels(*sys.argv[2:5])
    elif mode == 'links' and len(sys.argv) == 7:
        links(sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]),
              sys.argv[6])
    else:
        sys.exit(__doc__)
