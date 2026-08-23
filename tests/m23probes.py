"""The M23 acceptance readers — the nested-mark range fixture.

`examples/range-nested.qmd` writes an index mark inside a `range=` mark's own
content, on BOTH ends of one range, and overlaps that range with a plain range
of another term. The emitting pass rewrites the inner mark before it reaches
the outer one, so the outer mark's visible text is not the same object in the
two passes that read it; every clause here is about the outer mark taking the
verdict its own POSITION was planned for regardless.

The readers are imported rather than written again, for the reason m21probes
imports m20probes: two independent readers of one artifact drift (M16). The
`.ind` line splitter and page counter come from `m21probes`, and so do the
HTML index-section, locator-link and body-mark readers.

Usage:  python3 tests/m23probes.py <ind|html> <args...>
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import m20probes as M20  # noqa: E402  (needs the path line above)
import m21probes as M21  # noqa: E402

_fail = M20._fail

# What `examples/range-nested.qmd` writes, stated HERE and never read off the
# artifact under test — the M20 oracle lesson, in the shape M21 gives it: the
# printed range and the mark that carries it are written by one run, so an
# expectation derived from either moves with a defect in the other. What
# cannot move is where the fixture puts its page breaks.
#
# The nested range opens on the fixture's first page and closes on its fourth,
# so it covers four; the plain range opens on the second and closes on the
# third, so it covers two. The two widths differ, and the two ranges overlap,
# so a verdict handed to the wrong mark prints a span of the wrong width
# rather than merely moving an entry.
NESTED = 'nixie ogopogo'
PLAIN = 'pooka'
RANGES = {NESTED: 4, PLAIN: 2}
# The inner mark, written once inside each end of the nested range and
# carrying no `range=` of its own. It is what makes the outer mark's visible
# text differ between the two passes, and it indexes two ordinary locators.
INNER = 'ogopogo'
INNER_LOCATORS = 2


# The criterion these readers are speaking for. Both fixtures assert the same
# clauses — one paired range per term, the widths their page breaks put them
# at, the inner mark unmoved — so they are read by ONE reader under two
# labels rather than by two readers that could drift (M16). `AC` is set by
# `main` from the mode it was called in, and every message below takes its
# label from here rather than carrying one of its own.
AC = 'M23-AC1'


def _afail(msg):
    _fail('%s: %s' % (AC, msg))


def _aok(msg):
    print('ok   %s: %s' % (AC, msg))


def _hyperpages(line):
    """Every page string one compiled entry prints, in order."""
    return [p.strip()
            for b in re.findall(r'\\hyperpage\{([^{}]*)\}', line)
            for p in b.split(',')]


def _ind(argv):
    r"""The LaTeX back-end — the `.ind` and the `.ilg` of one render.

    A range that lost its pairing prints its two ends as two locators, and a
    range paired with the wrong counterpart prints a span of the wrong width.
    Both are read here against the fixture's own page breaks. The `.ilg` is
    read for the warning COUNT rather than searched as a substring, for the
    reason D-007 records: makeindex reports every range fault as a warning at
    exit 0, and Quarto alone fails the render on a regex over the transcript.
    """
    ind_path, ilg_path = argv[0], argv[1]
    items = M21._items(open(ind_path, encoding='utf-8').read())

    missing = [t for t in list(RANGES) + [INNER] if t not in items]
    if missing:
        _afail('the compiled index has no entry for %s; it has %s'
              % (missing, sorted(items)))

    for term, span in RANGES.items():
        line = items[term]
        printed = _hyperpages(line)
        if len(printed) != 1:
            _afail('the %r entry prints %d locators (%r); a paired range '
                  'is one locator spanning its two marks: <<%s>>'
                  % (term, len(printed), printed, line))
        covered, is_range = M21._pages(printed[0])
        if not is_range:
            _afail('the %r entry prints %r, which is not a range; the '
                  'fixture separates its two marks by %d pages: <<%s>>'
                  % (term, printed[0], span, line))
        if covered != span:
            _afail('the %r entry\'s locator %r covers %d page(s); the '
                  'fixture separates its two marks by %d page(s): <<%s>>'
                  % (term, printed[0], covered, span, line))

    # The inner mark: two ordinary pages, neither of them a range. It is the
    # untouched shape here — a mark that names no end at all must be unmoved
    # by anything the range machinery does (the M11 lesson).
    inner = _hyperpages(items[INNER])
    if len(inner) != INNER_LOCATORS or any('--' in p for p in inner):
        _afail('the %r entry prints %r; the fixture writes it once inside '
              'each end of the nested range, with no range= of its own, so it '
              'must print %d separate pages: <<%s>>'
              % (INNER, inner, INNER_LOCATORS, items[INNER]))

    ilg = open(ilg_path, encoding='utf-8').read()
    for phrase in ('Unmatched range', 'Extra range', 'inconsistent encapsulator',
                   'Inconsistent page encapsulator'):
        if phrase in ilg:
            _afail('makeindex logged <<%s>> for this fixture; Quarto fails '
                  'a render on exactly that line:\n%s' % (phrase, ilg))
    m = re.search(r'done \((\d+) lines written, (\d+) warnings?\)', ilg)
    if not m:
        _afail('could not read a warning count out of the makeindex '
              'transcript, so "no warnings" would rest on a substring search '
              'alone:\n' + ilg)
    if m.group(2) != '0':
        _afail('makeindex reported %s warning(s) for this fixture:\n%s'
              % (m.group(2), ilg))
    _aok('a range mark whose own content carries another mark '
          'prints one page range covering the pages the fixture separates its '
          'ends by, the plain range beside it keeps its own narrower span, the '
          'nested inner mark keeps its two separate pages, and makeindex logs '
          'no warning at all')


def _html(argv):
    """The HTML back-end — one locator per range, at its opening mark.

    Read through the HTML parser rather than through the gfm span reader: that
    reader stops at the first `</span>`, so a mark whose visible text carries a
    nested span is truncated rather than enumerated (a standing candidate row,
    M20 review R2-F10). Nothing here needs it — `H.text` gathers a span's
    descendant text, so the outer mark is found under its whole visible term.
    """
    path = argv[0]
    cls = os.environ['HTML_PRINCIPAL_CLASS']
    section = M21.index_section(path, AC)
    marks = M21.body_marks(path)

    for term, span in RANGES.items():
        opens = marks.get((term, 'open'), [])
        closes = marks.get((term, 'close'), [])
        if len(opens) != 1 or len(closes) != 1:
            _afail('%r has %d opening and %d closing mark(s) in the body; '
                  'the fixture writes one of each'
                  % (term, len(opens), len(closes)))
        anchor = opens[0].attrs.get('id')
        closing = closes[0].attrs.get('id')
        if not anchor:
            _afail('the opening mark of %r carries no id, so its locator '
                  'has nothing to point at' % term)
        got = M21.locator_links(section, term, cls)
        if got is None:
            _afail('the generated index has no %r entry at all, so every '
                  'clause about its locator would pass by not matching' % term)
        if len(got) != 1:
            _afail('the %r entry carries %d locator link(s) (%r); a paired '
                  'range contributes one' % (term, len(got), got))
        href = got[0][0]
        if href != '#' + anchor:
            _afail('the %r entry\'s locator points at %r; its opening '
                  'mark\'s anchor is %r and its closing mark\'s is %r'
                  % (term, href, '#' + anchor, '#' + closing))

    got = M21.locator_links(section, INNER, cls)
    if got is None:
        _afail('the generated index has no %r entry, so the nested inner '
              'mark cannot fail' % INNER)
    if len(got) != INNER_LOCATORS:
        _afail('the %r entry carries %r; the fixture writes it once inside '
              'each end of the nested range, with no range= of its own, so it '
              'contributes %d separate locators' % (INNER, got, INNER_LOCATORS))
    _aok('in the HTML index a range mark whose own content carries '
          'another mark contributes one locator at its opening mark\'s anchor, '
          'the plain range beside it does the same, and the nested inner mark '
          'contributes its own two')


# Mode -> (reader, the criterion it speaks for). `posind`/`poshtml` read
# `examples/range-position.qmd`, which carries AC1's two ranges plus the two
# shapes AC1's fixture must not have; the clauses asserted are the same ones,
# which is why they share a reader.
MODES = {
    'ind': (lambda rest: _ind(rest), 'M23-AC1'),
    'html': (lambda rest: _html(rest), 'M23-AC1'),
    'posind': (lambda rest: _ind(rest), 'M23-AC2'),
    'poshtml': (lambda rest: _html(rest), 'M23-AC2'),
}


def main(argv):
    global AC
    if not argv:
        _fail('usage: m23probes.py <%s> <args...>' % '|'.join(MODES))
    which, rest = argv[0], argv[1:]
    if which not in MODES:
        _fail('m23probes.py: unknown reader %r' % which)
    reader, AC = MODES[which]
    return reader(rest)


if __name__ == '__main__':
    main(sys.argv[1:])
