"""What a PDF render of a multi-index document printed, read for the suite.

Three readings, each over an artifact this run captured (M24):

  entries <pdf> <manifest> <label>
      Every printed index section against the entry set that index's own marks
      derive, compared BOTH ways -- an entry the manifest states and the PDF
      does not print fails, and so does one the PDF prints and the manifest
      does not state.

  cells <pdf> <manifest> <label>
      One term at a time: present in, or absent from, the index it was marked
      for. This is the reading the set comparison above cannot make on its own,
      because "absent" is a claim about a term the marks DO derive and the
      printed index deliberately does not carry.

  reports <log> <patterns> <manifest> <label>
      Every report this extension drew during that render, against the set the
      manifest states verbatim. `patterns` is the run's own generated list of
      this extension's warning shapes, so a message some other filter logged is
      never read as one of ours.

Every expectation is a manifest row derived by hand from the `.qmd` source, per
the ORACLE RULE in run-tests.sh. This module reads artifacts and never produces
an expected value.
"""

import re
import sys
from collections import Counter

import pdfindex


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    return 1


def rows(path):
    """The manifest's non-empty lines, tab-split, in order."""
    out = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if line.strip():
            out.append(line.split('\t'))
    return out


def _section(pdf_path, heading, stop):
    """One printed index section's outline, or a finding about reading it."""
    try:
        entries = pdfindex.read(pdf_path, heading, (stop,))
    except LookupError as missing:
        return None, str(missing)
    if not entries:
        return None, (f'the section headed {heading!r} carries no printed line '
                      f'at all, so a comparison against it would pass on an '
                      f'index that printed nothing')
    if not pdfindex.columns_carry_top_level(entries):
        return None, (f'a column of the section headed {heading!r} carries no '
                      f'top-level entry, so pdfindex cannot read its indent '
                      f'levels and every level below is read one too shallow')
    return pdfindex.outline(entries), None


def check_entries(pdf_path, manifest_path, label):
    wanted, order, bounds = {}, [], {}
    current = None
    for row in rows(manifest_path):
        if row[0] == 'index':
            if len(row) != 3:
                return fail(f'{manifest_path}: an `index` row takes the '
                            f'heading and the line that ends the section; got '
                            f'{row!r}')
            current = row[1]
            if current in wanted:
                return fail(f'{manifest_path}: two `index` rows name the '
                            f'heading {current!r}, so one section\'s rows '
                            f'would silently replace the other\'s')
            order.append(current)
            bounds[current] = row[2]
            wanted[current] = Counter()
            continue
        if current is None:
            return fail(f'{manifest_path}: an entry row stands before any '
                        f'`index` row, so it belongs to no section')
        if len(row) != 2:
            return fail(f'{manifest_path}: an entry row takes a level and a '
                        f'term; got {row!r}')
        wanted[current][(int(row[0]), row[1])] += 1
    if not order:
        return fail(f'{manifest_path}: names no index section at all, so a PDF '
                    f'that printed none would match it')

    total = 0
    for heading in order:
        if not wanted[heading]:
            return fail(f'{manifest_path}: the section headed {heading!r} is '
                        f'stated with no entry, so any printed index would '
                        f'match it')
        printed, bad = _section(pdf_path, heading, bounds[heading])
        if printed is None:
            return fail(f'{label}: {bad}')
        got = Counter(printed)
        missing = got.copy()
        missing.subtract(wanted[heading])
        absent = sorted(k for k, n in missing.items() if n < 0)
        extra = sorted(k for k, n in missing.items() if n > 0)
        if absent or extra:
            print(f'FAIL: {label}: the section headed {heading!r} is not the '
                  f'entry set its own marks derive', file=sys.stderr)
            for level, term in absent:
                print(f'  derived from the marks, not printed: '
                      f'level {level} <<{term}>>', file=sys.stderr)
            for level, term in extra:
                print(f'  printed, not derived from the marks: '
                      f'level {level} <<{term}>>', file=sys.stderr)
            return 1
        total += sum(wanted[heading].values())
    print(f'ok   {label}: {len(order)} printed index section(s) carry exactly '
          f'the {total} entry line(s) their own marks derive, and no other')
    return 0


def check_cells(pdf_path, manifest_path, label):
    cells, bounds = [], {}
    for row in rows(manifest_path):
        if row[0] == 'index':
            if len(row) != 3:
                return fail(f'{manifest_path}: an `index` row takes the '
                            f'heading and the line that ends the section')
            bounds[row[1]] = row[2]
            continue
        if len(row) != 4 or row[0] not in ('present', 'absent'):
            return fail(f'{manifest_path}: a cell row is '
                        f'`present|absent<TAB>heading<TAB>term<TAB>why`; got '
                        f'{row!r}')
        cells.append(row)
    if not cells:
        return fail(f'{manifest_path}: states no cell at all, so this check '
                    f'would pass over an empty set')
    if not any(c[0] == 'absent' for c in cells) \
            or not any(c[0] == 'present' for c in cells):
        return fail(f'{manifest_path}: states cells of one kind only; a check '
                    f'with no present cell and no absent cell cannot tell an '
                    f'index that dropped everything from one that dropped '
                    f'nothing')

    read = {}
    for _kind, heading, _term, _why in cells:
        if heading in read:
            continue
        if heading not in bounds:
            return fail(f'{manifest_path}: no `index` row says where the '
                        f'section headed {heading!r} ends')
        printed, bad = _section(pdf_path, heading, bounds[heading])
        if printed is None:
            return fail(f'{label}: {bad}')
        read[heading] = {term for _level, term in printed}

    bad = []
    for kind, heading, term, why in cells:
        there = term in read[heading]
        if there != (kind == 'present'):
            bad.append(f'  {heading!r}: <<{term}>> is '
                       f'{"printed" if there else "not printed"}, and this '
                       f'cell states it {kind} because {why}')
    if bad:
        print(f'FAIL: {label}: a below-marker cell does not read as stated',
              file=sys.stderr)
        print('\n'.join(bad), file=sys.stderr)
        return 1
    print(f'ok   {label}: all {len(cells)} below-marker cell(s) read as stated '
          f'-- {sum(1 for c in cells if c[0] == "present")} term(s) present in '
          f'their own printed index and '
          f'{sum(1 for c in cells if c[0] == "absent")} absent from it')
    return 0


def check_reports(log_path, patterns_path, manifest_path, label):
    patterns = [re.compile(line.rstrip('\n'))
                for line in open(patterns_path, encoding='utf-8')
                if line.strip()]
    if not patterns:
        return fail(f'{patterns_path}: carries no warning pattern, so every '
                    f'report in the log would go unread and a document that '
                    f'drew none would match')
    wanted = Counter()
    for row in rows(manifest_path):
        wanted['\t'.join(row)] += 1
    if not wanted:
        return fail(f'{manifest_path}: states no report at all, so a render '
                    f'that drew none would match it')

    got = Counter()
    for line in open(log_path, encoding='utf-8'):
        line = line.rstrip('\n')
        if any(p.search(line) for p in patterns):
            # Quarto prefixes each of a filter's warnings; the manifest states
            # the message this extension wrote, not Quarto's framing.
            got[re.sub(r'^\(W\)\s*', '', line).strip()] += 1
    if not got:
        return fail(f'{label}: {log_path} carries no report from this '
                    f'extension at all, so the manifest below would be '
                    f'compared against nothing')

    diff = got.copy()
    diff.subtract(wanted)
    absent = sorted(k for k, n in diff.items() if n < 0)
    extra = sorted(k for k, n in diff.items() if n > 0)
    if absent or extra:
        print(f'FAIL: {label}: the reports this render drew are not the set '
              f'stated', file=sys.stderr)
        for text in absent:
            print(f'  stated, not drawn: <<{text}>>', file=sys.stderr)
        for text in extra:
            print(f'  drawn, not stated: <<{text}>>', file=sys.stderr)
        return 1
    print(f'ok   {label}: the render drew exactly the {sum(wanted.values())} '
          f'report(s) stated, verbatim, and no other')
    return 0


MODES = {
    'entries': (check_entries, 3),
    'cells': (check_cells, 3),
    'reports': (check_reports, 4),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        return fail(f'usage: namedpdf.py <{"|".join(MODES)}> ...')
    handler, arity = MODES[argv[1]]
    if len(argv) - 2 != arity:
        return fail(f'namedpdf.py {argv[1]} takes {arity} argument(s), '
                    f'got {len(argv) - 2}')
    return handler(*argv[2:])


if __name__ == '__main__':
    sys.exit(main(sys.argv))
