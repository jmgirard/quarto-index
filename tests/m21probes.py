"""The M21 acceptance readers, one per artifact the criteria are stated over.

They live here for the reason the M20 readers do: the self-test runs each of
them again against a deliberately mutated copy of the artifact it reads, and a
check that cannot be re-run cannot be shown to discriminate. The suite is the
only caller of the run-time invocations; the self-test is the only caller of
the mutated ones.

The `.ind` reading helpers are imported from `m20probes` rather than written
again. Both milestones read the same makeindex output through the same
hyperref rewriting, and two independent readers of one artifact drift — which
is the shape M16 recorded when two joined-message readers of one log appeared
in this suite.

Usage:  python3 tests/m21probes.py <ind|tex|html|gfm|bookpdf> <args...>
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402  (needs the path line above)
import m20probes as M20  # noqa: E402

_fail = M20._fail

# What `examples/range.qmd` writes, stated HERE and never read off the artifact
# under test. This is the M20 oracle lesson applied to ranges: the printed
# range, the `.aux` registration and the `.ind` locator are all written by the
# same run, so an expectation derived from any of them moves with a defect in
# the others. What cannot move is the fixture's own structure — how many pages
# a range's two ends are apart, and which ends carry a role — because that is
# in the source the author wrote.
#
# `span` is the number of PAGES the range must cover: every range in the
# fixture but the last is separated from its own closing mark by exactly one
# page holding no mark, so it covers three; the last opens and closes in one
# sentence on one page, so it covers one and makeindex prints it as a page
# rather than as a range. Absolute folios appear nowhere.
RANGES = {
    'alicorn': {'span': 3, 'principal': False},
    'banshee': {'span': 3, 'principal': True},
    'dybbuk': {'span': 3, 'principal': False},
    'erlking': {'span': 1, 'principal': True},
    # The role written on the CLOSING mark rather than the opening one. A range
    # is one discussion, so either end declares it for the span; this slot is
    # what holds that, and every clause below reads it exactly as it reads a
    # range whose opening declared it (review F2).
    'firebird': {'span': 3, 'principal': True},
}
# The control: two ordinary marks, one filler page apart, and no `range=` at
# all. It is here so a report or an encapsulation that fired on every mark
# rather than on a range would be caught by the fixture rather than by review.
CONTROL = 'centaur'
# The contested key: a range plus a cross-reference mark, which the existing
# repair folds into the entry's printed text while the range stays in the
# encapsulation channel.
CONTESTED = ('dybbuk', r'\see{centaur}{}')


def _items(ind):
    """One normalized line per compiled entry, keyed by the term it prints."""
    items = {}
    for chunk in re.split(r'\\item\s', ind)[1:]:
        line = ' '.join(chunk.split())
        # The term is what precedes the first COMMAND, not the first comma —
        # the same rule `m20probes` states, and for the same two reasons: a
        # term may contain a comma, and a contested key prints its folded
        # cross-reference between the term and its locator.
        cut = line.find('\\')
        items[(line if cut < 0 else line[:cut]).strip().rstrip(',').strip()] = line
    return items


def _pages(item):
    """The pages one printed locator covers, and whether it is a range."""
    if '--' not in item:
        if not item.isdigit():
            _fail('M21-AC1: locator %r is not a plain page number; this criterion '
                  'reads the fixture\'s own arabic folios' % item)
        return 1, False
    lo, hi = item.split('--', 1)
    if not (lo.isdigit() and hi.isdigit()):
        _fail('M21-AC1: range %r has a non-numeric end' % item)
    return int(hi) - int(lo) + 1, True


def _ind(argv):
    r"""M21-AC1 and M21-AC2 — the `.ind`, the `.ilg` and the `.aux` of one PDF render.

    AC1 is the `.ind` and the `.ilg`: one locator per range, covering the pages
    the fixture's structure says it must, and a transcript with no range
    warning in it. The warning COUNT is read as a number rather than searched
    for as a substring, for the reason D-007 records: makeindex reports every
    range fault as a warning at exit 0, and Quarto alone fails the render on a
    regex over the transcript, so the count is the stable oracle.

    AC2 is the cross-artifact chain the `.ind` cannot show on its own. Emphasis
    is not in the `.ind` at all — the locator command prints it at
    `\printindex` time by looking each printed page string up in the registry
    the `.aux` feeds — so what is checked here is that the string the registry
    holds for a range's ordinal IS the string that ordinal's locator prints.
    That is the last link the `.ind` can carry; the printed emphasis itself is
    read out of the compiled PDF by the caller.
    """
    ind_path, ilg_path, aux_path = argv[0], argv[1], argv[2]
    locator_cmd, page_cmd = argv[3], argv[4]
    rangeat_cmd, rangeto_cmd = argv[5], argv[6]
    items = _items(open(ind_path, encoding='utf-8').read())

    missing = [t for t in list(RANGES) + [CONTROL] if t not in items]
    if missing:
        _fail('M21-AC1: the compiled index has no entry for %s; it has %s'
              % (missing, sorted(items)))

    ordinals = {}
    for term, want in RANGES.items():
        line = items[term]
        groups = M20._locator_groups(line, locator_cmd)
        bare = re.findall(r'\\hyperpage\{([^{}]*)\}', line)
        # Exactly one locator, whichever channel it came through: a range that
        # failed to pair would print its two ends as two locators, which is the
        # regression this clause exists to catch.
        printed = [p.strip() for g in groups for p in g[1]] + \
                  [p.strip() for b in bare for p in b.split(',')]
        if len(printed) != 1:
            _fail('M21-AC1: the %r entry prints %d locators (%r); a range is one '
                  'locator spanning its two marks: <<%s>>'
                  % (term, len(printed), printed, line))
        covered, is_range = _pages(printed[0])
        if covered != want['span']:
            _fail('M21-AC1: the %r entry\'s locator %r covers %d page(s); the '
                  'fixture separates its two marks by %d page(s) in all: <<%s>>'
                  % (term, printed[0], covered, want['span'], line))
        if is_range != (want['span'] > 1):
            _fail('M21-AC1: the %r entry prints %r, which is %sa range; a %d-page '
                  'span %s be one'
                  % (term, printed[0], '' if is_range else 'not ',
                     want['span'], 'must' if want['span'] > 1 else 'must not'))
        # A range whose opening is principal carries the key's ordinal on BOTH
        # ends, so makeindex could reconcile them at all; one whose opening is
        # not carries no encapsulator, exactly as an ordinary locator does.
        if want['principal']:
            if len(groups) != 1:
                _fail('M21-AC2: the %r entry has %d %s group(s); a range whose '
                      'opening is principal is encapsulated, and the two ends '
                      'must have agreed for makeindex to print one: <<%s>>'
                      % (term, len(groups), locator_cmd, line))
            ordinals[term] = groups[0][0]
        elif groups:
            _fail('M21-AC1: the %r entry carries %s although no mark of it is '
                  'principal: <<%s>>' % (term, locator_cmd, line))

    if locator_cmd in items[CONTROL]:
        _fail('M21-AC1: the range-free control entry carries %s: <<%s>>'
              % (locator_cmd, items[CONTROL]))
    control = re.findall(r'\\hyperpage\{([^{}]*)\}', items[CONTROL])
    control = [p.strip() for b in control for p in b.split(',')]
    if len(control) != 2 or any('--' in p for p in control):
        _fail('M21-AC1: the range-free control entry prints %r; the fixture marks '
              'it twice, a filler page apart, so it must print two separate '
              'pages: <<%s>>' % (control, items[CONTROL]))

    term, fold = CONTESTED
    if fold not in items[term]:
        _fail('M21-AC1: the %r entry does not carry <<%s>> in its printed text; a '
              'key carrying a range AND a cross-reference folds the '
              'cross-reference there and leaves the range where it is: <<%s>>'
              % (term, fold, items[term]))

    # The chain the criterion is really about: for each principal range, the
    # `.aux` composes the two ends it registered into the string the `.ind`
    # prints. Neither artifact settles it alone — a registry naming pages no
    # entry prints emphasizes nothing, and a printed range nothing registered
    # prints plain.
    aux = open(aux_path, encoding='utf-8').read()
    # Read as LISTS first: a `dict` keeps one value per ordinal, so a defect
    # emitting a registration twice for one range would be invisible, and if the
    # surviving line happened to name the true page the check would pass on an
    # `.aux` that also registers a wrong one (review round 3, R3-F7).
    opened_pairs = re.findall(r'\\%s\{([^{}]*)\}\{([^{}]*)\}' % re.escape(rangeat_cmd), aux)
    closed_pairs = re.findall(r'\\%s\{([^{}]*)\}\{([^{}]*)\}' % re.escape(rangeto_cmd), aux)
    for which, pairs in (('opening', opened_pairs), ('closing', closed_pairs)):
        seen = {}
        for ordinal, page in pairs:
            seen.setdefault(ordinal, []).append(page)
        repeated = {k: v for k, v in seen.items() if len(v) > 1}
        if repeated:
            _fail('M21-AC2: the .aux registers a range %s more than once per '
                  'ordinal (%r); each end of a range registers exactly once, and '
                  'a second line under a live ordinal would be read as the first'
                  % (which, repeated))
    opened, closed = dict(opened_pairs), dict(closed_pairs)
    want_ids = set(ordinals.values())
    if set(opened) != want_ids or set(closed) != want_ids:
        _fail('M21-AC2: the .aux registers range openings for %s and closings for '
              '%s; the .ind\'s principal ranges name %s'
              % (sorted(opened), sorted(closed), sorted(want_ids)))
    for term, ordinal in ordinals.items():
        printed = M20._locator_groups(items[term], locator_cmd)[0][1][0].strip()
        composed = opened[ordinal] + '--' + closed[ordinal]
        # Which equality is required depends on the SHAPE printed, so each
        # registered page is constrained in every shape: a disjunction over the
        # two let a same-page range pass on its opening alone, with the closing
        # registration never read at all (review R4-F6).
        if '--' in printed:
            if printed != composed:
                _fail('M21-AC2: the %r range prints %r, but its ordinal %s is '
                      'registered from pages %s and %s, composing %r — the '
                      'lookup that emphasizes it finds nothing'
                      % (term, printed, ordinal, opened[ordinal],
                         closed[ordinal], composed))
        else:
            if opened[ordinal] != closed[ordinal]:
                _fail('M21-AC2: the %r range prints the single page %r, so its '
                      'two ends must register the same page, but ordinal %s is '
                      'registered from %s and %s'
                      % (term, printed, ordinal, opened[ordinal],
                         closed[ordinal]))
            if printed != opened[ordinal]:
                _fail('M21-AC2: the %r range prints the single page %r, but its '
                      'ordinal %s is registered from page %s — the lookup that '
                      'emphasizes it finds nothing'
                      % (term, printed, ordinal, opened[ordinal]))
    # A lone principal mention registers through the page command instead, and
    # this fixture writes none: a registration arriving by that route would mean
    # a range opening emitted the wrong command and its start page was never
    # remembered.
    # `rangeat` CALLS the page command, but only in the preamble's definition —
    # an `.aux` line never carries both names, so the two patterns cannot
    # overlap and no stripping is needed (review round 3, R3-F12).
    lone = re.findall(r'\\%s\{([^{}]*)\}\{([^{}]*)\}' % re.escape(page_cmd), aux)
    if lone:
        _fail('M21-AC2: the .aux carries %d lone principal-page registration(s) '
              '(%r); every principal mark in this fixture opens a range, so each '
              'must register through %s' % (len(lone), lone, rangeat_cmd))

    ilg = open(ilg_path, encoding='utf-8').read()
    for phrase in ('Unmatched range', 'Extra range', 'inconsistent encapsulator',
                   'Inconsistent page encapsulator'):
        if phrase in ilg:
            _fail('M21-AC1: makeindex logged <<%s>> for this fixture; Quarto fails '
                  'a render on exactly that line:\n%s' % (phrase, ilg))
    m = re.search(r'done \((\d+) lines written, (\d+) warnings?\)', ilg)
    if not m:
        _fail('M21-AC1: could not read a warning count out of the makeindex '
              'transcript, so "no warnings" would rest on a substring search '
              'alone:\n' + ilg)
    if m.group(2) != '0':
        _fail('M21-AC1: makeindex reported %s warning(s) for this fixture:\n%s'
              % (m.group(2), ilg))
    print('ok   M21-AC1/AC2: every range prints as one locator covering the pages '
          'the fixture separates its marks by, a principal range carries one '
          'ordinal on both ends and is registered under the very string it '
          'prints, the range-free control is untouched, and makeindex logs no '
          'warning at all')


def _index_commands(tex):
    r"""Every `\index{...}` in a rendered `.tex`, as (key, channel) pairs.

    Split at the FIRST `|`, which is exact here: the encapsulation channel
    opens at `|`, and a key can hold one only as `\textbar{}`, which carries no
    `|` character at all. The brace counting is in `_group`, which reads the
    whole argument — a folded cross-reference brings braces of its own, and a
    pattern stopping at the first `}` would cut the argument short.
    """
    out, i = [], 0
    while True:
        i = tex.find(r'\index{', i)
        if i < 0:
            return out
        arg, i = M20._group(tex, i + 6)
        bar = arg.find('|')
        out.append((arg, '') if bar < 0 else (arg[:bar], arg[bar + 1:]))


def _tex(argv):
    r"""M21-AC2's first clause — the two ends of a range, as emitted.

    Read from the `.tex` rather than from the `.ind`, because makeindex only
    prints a range at all when the two ends already agreed: by the time the
    `.ind` exists, a mismatch has become a transcript warning and a failed
    render, and this clause is about what the filter WROTE.
    """
    tex_path, locator_cmd = argv[0], argv[1]
    rangefrom_cmd, rangeend_cmd = argv[2], argv[3]
    tex = open(tex_path, encoding='utf-8').read()
    commands = _index_commands(tex)
    if not commands:
        _fail('M21-AC2: %s carries no \\index command at all, so every clause '
              'below would be quantified over nothing' % tex_path)
    ordinals = {}
    for term, want in RANGES.items():
        ends = [(key, channel) for key, channel in commands
                if re.match(r'^%s(?:@|$)' % re.escape(term), key)
                # A tuple, never the string `'()'`: `'' in '()'` is True in
                # Python, so an \index with no encapsulation channel at all
                # counted as a range end — which made the no-delimiter plant
                # fail by IndexError below rather than by the diagnostic this
                # reader exists to print, and would miscount the moment an
                # ordinary mark of a ranged term joined the fixture (review F7).
                and channel[:1] in ('(', ')')]
        if len(ends) != 2:
            _fail('M21-AC2: %r has %d range end(s) in the emitted LaTeX (%r); a '
                  'range is exactly one opening and one closing'
                  % (term, len(ends), ends))
        (open_key, open_channel), (close_key, close_channel) = ends
        if open_channel[0] != '(' or close_channel[0] != ')':
            _fail('M21-AC2: %r emits its ends as %r and %r, not an opening then a '
                  'closing' % (term, open_channel, close_channel))
        if open_key != close_key:
            _fail('M21-AC2: %r emits its two ends under different keys, %r and '
                  '%r; makeindex pairs a range by its key alone'
                  % (term, open_key, close_key))
        if open_channel[1:] != close_channel[1:]:
            _fail('M21-AC2: %r emits %r on its opening and %r on its closing; '
                  'makeindex logs an inconsistent-encapsulator warning when the '
                  'two differ, and Quarto fails the render on it'
                  % (term, open_channel[1:], close_channel[1:]))
        encap = open_channel[1:]
        if want['principal']:
            m = re.fullmatch(r'%s\{([^{}]*)\}' % re.escape(locator_cmd), encap)
            if not m:
                _fail('M21-AC2: %r has a principal opening but its ends carry the '
                      'encapsulator %r, not the key\'s locator command'
                      % (term, encap))
            ordinals[term] = m.group(1)
        elif encap:
            _fail('M21-AC2: %r has no principal mark but its ends carry the '
                  'encapsulator %r' % (term, encap))
    # The registrations, and their ordinals, at the marks themselves — the
    # other half of what the `.aux` is later read for.
    for command, which in ((rangefrom_cmd, 'opening'), (rangeend_cmd, 'closing')):
        # The `(?!\{)` is what excludes the preamble's own definition, whose
        # `{#1}` is followed by `{`; nothing further is needed.
        ids = re.findall(r'\\%s\{([^{}]*)\}(?!\{)' % re.escape(command), tex)
        if sorted(ids) != sorted(ordinals.values()):
            _fail('M21-AC2: the %s registrations name %s; the principal ranges '
                  'this document emits are %r' % (which, sorted(ids), ordinals))
    print('ok   M21-AC2: every range emits one opening and one closing under one '
          'key, carrying byte-identical encapsulators — the key\'s locator '
          'ordinal where its opening is principal and nothing at all where it is '
          'not — and each principal range registers both of its ends')


def index_section(path, criterion):
    """The generated index section of one rendered page, or a failure."""
    section = H.find_id(H.parse(path),
                        os.environ.get('HTML_SECTION_ID', 'qi-index'))
    if section is None:
        _fail('%s: %s has no generated index section' % (criterion, path))
    return section


def locator_links(section, term, cls):
    """One entry's locator links as (href, carries the class, is strong).

    Read off the `<li>` itself rather than through `index_entries`, whose
    records carry an href and not the element: the class and the emphasis
    node are half the question here. Returns None for a term with no entry
    at all and [] for an entry with no locator, which are different
    failures and must not be tested alike.

    Module-level rather than a closure of `_html` so that M23's nested-mark
    reader calls THIS one: two independent readers of one artifact drift, and
    the emphasis and class clauses are the half a second copy would drop
    (M16, in the shape m21probes itself takes from m20probes).
    """
    for item in H.find_all(section, 'li'):
        own = list(H.own_nodes(item))
        terms = [n for n in own if 'qi-term' in H.classes(n)]
        if len(terms) != 1 or H.text(terms[0]).strip() != term:
            continue
        out = []
        for node in own:
            if 'qi-locators' in H.classes(node):
                out.extend((a.attrs.get('href', ''), cls in H.classes(a),
                            bool(H.find_all(a, 'strong')))
                           for a in H.find_all(node, 'a'))
        return out
    return None


def body_marks(path):
    """Every index mark in the page BODY, keyed by (visible text, range end).

    The index section is stripped first, so a locator link inside it can never
    be mistaken for a mark. `H.text` gathers a span's descendant text, so a
    mark written inside another mark's content is read under the outer mark's
    whole visible text — which is what M23's fixture is built out of.
    """
    body = H.parse(path)
    H.strip_subtree(body, H.find_id(body, os.environ.get('HTML_SECTION_ID',
                                                         'qi-index')))
    marks = {}
    for node in H.find_all(body, 'span', 'index'):
        marks.setdefault((H.text(node).strip(), node.attrs.get('data-range')),
                         []).append(node)
    return marks


def _html(argv):
    """M21-AC3 — one locator per range, at the opening mark's anchor."""
    path = argv[0]
    cls = os.environ['HTML_PRINCIPAL_CLASS']
    section = index_section(path, 'M21-AC3')

    def locators(term):
        return locator_links(section, term, cls)

    marks = body_marks(path)

    for term, want in RANGES.items():
        opens = marks.get((term, 'open'), [])
        closes = marks.get((term, 'close'), [])
        if len(opens) != 1 or len(closes) != 1:
            _fail('M21-AC3: %r has %d opening and %d closing mark(s) in the body; '
                  'the fixture writes one of each'
                  % (term, len(opens), len(closes)))
        anchor = opens[0].attrs.get('id')
        closing = closes[0].attrs.get('id')
        if not anchor:
            _fail('M21-AC3: the opening mark of %r carries no id, so its locator '
                  'has nothing to point at' % term)
        if not closing:
            _fail('M21-AC3: the closing mark of %r carries no id; it contributes '
                  'no locator, but it is still a place in the text and this '
                  'criterion is read at its anchor' % term)
        # "no text of its own beyond the author's visible text".
        if H.text(closes[0]).strip() != term or H.find_all(closes[0], 'a'):
            _fail('M21-AC3: the closing mark of %r renders %r and holds %d '
                  'link(s); it must pass its visible text through and add nothing'
                  % (term, H.text(closes[0]), len(H.find_all(closes[0], 'a'))))
        got = locators(term)
        if got is None:
            _fail('M21-AC3: the generated index has no %r entry at all, so every '
                  'clause about its locator would pass by not matching' % term)
        if len(got) != 1:
            _fail('M21-AC3: the %r entry carries %d locator link(s) (%r); a range '
                  'contributes one' % (term, len(got), got))
        href, classed, strong = got[0]
        if href != '#' + anchor:
            _fail('M21-AC3: the %r entry\'s locator points at %r; its opening '
                  'mark\'s anchor is %r and its closing mark\'s is %r'
                  % (term, href, '#' + anchor, '#' + closing))
        if (classed, strong) != (want['principal'], want['principal']):
            _fail('M21-AC3: the %r entry\'s locator carries (%s, %s) as (class '
                  '%s, strong); its opening mark %s principal'
                  % (term, classed, strong, cls,
                     'is' if want['principal'] else 'is not'))

    got = locators(CONTROL)
    if got is None:
        _fail('M21-AC3: the generated index has no %r entry, so the range-free '
              'control cannot fail' % CONTROL)
    if len(got) != 2 or any(c or s for _, c, s in got):
        _fail('M21-AC3: the range-free control entry carries %r; the fixture marks '
              'it twice, neither mark is a range end and neither is principal'
              % (got,))
    print('ok   M21-AC3: every range contributes exactly one locator link, at its '
          'opening mark\'s anchor and never at its closing one, emphasized and '
          'classed exactly where the opening mark is principal; each closing mark '
          'keeps an anchor and adds nothing to its own text; and the range-free '
          'control keeps both of its plain locators')


def _gfm(argv):
    """M21-AC6 — the format with no index back-end."""
    src = open(argv[0], encoding='utf-8').read()
    want = [l.rstrip('\n') for l in open(argv[1], encoding='utf-8') if l.strip()]
    got = re.findall(r'<span class="index"[^>]*>.*?</span>', src)
    if got != want:
        print('FAIL: M21-AC6: the index spans in the gfm render are not, in '
              'document order and byte for byte, the manifest derived from the '
              'fixture:', file=sys.stderr)
        for i in range(max(len(got), len(want))):
            g = got[i] if i < len(got) else '<missing>'
            w = want[i] if i < len(want) else '<not in the manifest>'
            if g != w:
                print(f'  row {i + 1} got  <<{g}>>', file=sys.stderr)
                print(f'  row {i + 1} want <<{w}>>', file=sys.stderr)
        sys.exit(1)
    # The permitted residue is an exact token set rather than an exemption, so
    # a stray one cannot be argued into it. Every command the range channel
    # adds is named, alongside the ones M20's reader already names.
    for token in ('qi-', r'\index{', '|(', '|)', 'quartoindexprincipal',
                  'quartoindexlocator', 'quartoindexregister',
                  'quartoindexprincipalpage', 'quartoindexrangefrom',
                  'quartoindexrangeend', 'quartoindexrangeat',
                  'quartoindexrangeto'):
        if token in src:
            _fail('M21-AC6: the gfm render carries <<%s>>, which is back-end '
                  'residue in a format with no index back-end' % token)
    print('ok   M21-AC6: all %d index spans in the gfm render are, in document '
          'order and byte for byte, the manifest derived from the fixture, and '
          'no range delimiter, index command or registration command reaches the '
          'format at all' % len(got))


def _bookpdf(argv):
    """M21-AC5's LaTeX half — a book PDF pairs its cross-chapter range too.

    A PDF book renders as one merged document, so the pairing is the ordinary
    in-document one; what this holds is that the merged document still gets ONE
    locator for a range whose ends the author wrote in two different chapter
    files. The page numbers are not asserted: which chapter lands on which page
    is the LaTeX layout's business, and the criterion is about the count.
    """
    text = open(argv[0], encoding='utf-8').read()
    term = argv[1]
    m = re.search(r'^\s*Index\s*$', text, re.MULTILINE)
    if not m:
        _fail('M21-AC5: no "Index" heading in the book PDF')
    region = ' '.join(text[m.end():].split())
    found = re.search(r'(?<![\w])' + re.escape(term) + r'(?![\w])'
                      r'((?:,\s\d+(?:[-\u2013\u2014]\d+)?)*)', region)
    if found is None:
        _fail('M21-AC5: the book PDF index has no %r entry: <<%s>>'
              % (term, region[:400]))
    locators = re.findall(r'\d+(?:[-\u2013\u2014]\d+)?', found.group(1))
    if len(locators) != 1:
        _fail('M21-AC5: the book PDF prints %d locator(s) for %r (%r); a range '
              'opened in one chapter and closed in another is one'
              % (len(locators), term, locators))
    if not re.search(r'[-\u2013\u2014]', locators[0]):
        _fail('M21-AC5: the book PDF prints %r for %r, which is a single page; '
              'the fixture opens the range in one chapter and closes it in the '
              'next, which are never one page' % (locators[0], term))
    print('ok   M21-AC5: the book PDF prints one page range for the term whose '
          'range the author opened in one chapter and closed in another')


def _misuse(argv):
    r"""M21-AC4's emission half — no refused range reaches the index tool.

    Every refusal in `examples/range-misuse.qmd` exists because makeindex logs
    a transcript warning for an unmatched, extra or inconsistently encapsulated
    range and Quarto fails the whole render on that line. Nothing about the
    reports holds that: five of them would still fire while the range operator
    went out anyway. This reads the emitted LaTeX rather than rendering the
    fixture to PDF, because the property is that the operator is not EMITTED —
    a PDF render would prove it only for the pagination this run produced.
    """
    tex = open(argv[0], encoding='utf-8').read()
    commands = re.findall(r'\\index\{([^|}]*)((?:\|[()])?)', tex)
    if not commands:
        _fail('M21-AC4: the misuse fixture emitted no \index command at all, so '
              'a clause about which of them carry a range operator would be '
              'quantified over nothing')
    # Which of the fixture's ranges actually PAIR, derived from its source and
    # not from this output: `lamia` is the well-formed control, and `hydra`'s
    # FIRST opening pairs with its closing — the second opening is the refused
    # one, which is what its own report says. Everything else is a refusal.
    paired_terms = {'hydra', 'lamia'}
    refused = {'fenrir', 'golem', 'imp', 'jinn'}
    opens, closes = {}, {}
    for term, op in commands:
        if op == '|(':
            opens[term] = opens.get(term, 0) + 1
        elif op == '|)':
            closes[term] = closes.get(term, 0) + 1
    bad = []
    if set(opens) != paired_terms or set(closes) != paired_terms:
        bad.append('  terms emitting a range operator are %s, expected %s'
                   % (sorted(set(opens) | set(closes)), sorted(paired_terms)))
    for term in sorted(paired_terms):
        if opens.get(term) != 1 or closes.get(term) != 1:
            bad.append('  %s: %d opening(s), %d closing(s); a paired range is one '
                       'of each' % (term, opens.get(term, 0), closes.get(term, 0)))
    for term in sorted(refused):
        if term in opens or term in closes:
            bad.append('  %s: refused, yet emitted a range operator' % term)
    if bad:
        _fail('M21-AC4: the misuse fixture does not emit a range operator for '
              'exactly its paired ranges:\n' + '\n'.join(bad))
    print('ok   M21-AC4: of the %d index commands the misuse fixture emits, '
          'exactly the %d ranges that pair carry a range operator — one opening '
          'and one closing each — and all %d refused marks carry none'
          % (len(commands), len(paired_terms), len(refused)))


def _preamble(argv):
    r"""M21's stale-`.aux` guard — every command an `.aux` line can name is
    defined in EVERY document the subsystem reaches.

    The `.aux` outlives the source that wrote it, so a command injected only
    into a document that still writes a range becomes an `Undefined control
    sequence` the moment that range is deleted — verified as pdflatex exit 1,
    which is the IP2 break the subsystem exists to avoid. The document that
    matters is one with a principal mention and NO range, which is the tree an
    author lands in the moment they delete one.
    """
    path, wanted = argv[0], argv[1:]
    text = open(path, encoding='utf-8').read()
    if not text.strip():
        _fail('M21: %s is empty, so every clause stated over its preamble would '
              'pass on a file this run did not write' % path)
    if text.count(r'\begin{document}') != 1:
        _fail('M21: %s does not carry exactly one \begin{document}, so "the '
              'region before it" names no one region' % path)
    pre = text[:text.index(r'\begin{document}')]
    if 'quartoindexregister' not in pre:
        _fail('M21: %s has no principal subsystem in it at all, so this check '
              'would pass on a document the subsystem never reached' % path)
    bad = []
    for cmd in wanted:
        hits = re.findall(r'\\providecommand\*\\%s\[' % re.escape(cmd), pre)
        if len(hits) != 1:
            bad.append('  %s: defined %d time(s) with \providecommand*, not once'
                       % (cmd, len(hits)))
    if bad:
        _fail('M21: an .aux line naming one of these after a range is deleted is '
              'an undefined control sequence and the render is over:\n'
              + '\n'.join(bad))
    print('ok   M21: all %d .aux-borne range commands are defined exactly once in '
          'a document that has a principal mention and no range of its own, so '
          'deleting a range cannot leave an .aux line naming a command nothing '
          'defines' % len(wanted))


def _bookhtml(argv):
    """M21-AC5 — what an HTML book does now that it pairs no range across chapters.

    Three claims, read off one render. A range whose two marks are in ONE
    chapter pairs there, because a chapter is one Pandoc process and that is
    the scope a range pairs in (D-009): it contributes one locator, at its
    opening mark's anchor. A range whose marks are in DIFFERENT chapters pairs
    nowhere: each mark indexes as though `range=` were absent, its own
    `mention=` role included — which is why the closing's locator here is the
    emphasized one, the author having written the role on it. And the book says
    so once.

    The marks are named rather than quantified over: "every range mark
    contributes its own locator" would be false for one also carrying `see=`,
    which contributes a cross-reference and no locator at all.
    """
    path = argv[0]
    cls = os.environ['HTML_PRINCIPAL_CLASS']
    doc = H.parse(path)
    section = H.find_id(doc, os.environ.get('HTML_SECTION_ID', 'qi-index'))
    if section is None:
        _fail('M21-AC5: %s has no generated index section' % path)

    def locators(term):
        for item in H.find_all(section, 'li'):
            own = list(H.own_nodes(item))
            terms = [n for n in own if 'qi-term' in H.classes(n)]
            if len(terms) != 1 or H.text(terms[0]).strip() != term:
                continue
            out = []
            for node in own:
                if 'qi-locators' in H.classes(node):
                    out.extend((a.attrs.get('href', ''), cls in H.classes(a),
                                bool(H.find_all(a, 'strong')))
                               for a in H.find_all(node, 'a'))
            return out
        return None

    # The same-chapter range: paired, so one locator at the opening's anchor.
    got = locators('Chapter Range')
    if got is None:
        _fail('M21-AC5: the book index has no "Chapter Range" entry, so every '
              'clause about a range paired inside one chapter would pass by not '
              'matching')
    if got != [('#qi-mark-2', False, False)]:
        _fail('M21-AC5: "Chapter Range" carries %r; both its marks are in the '
              'marker chapter, so it pairs there and contributes one plain '
              'locator at its opening mark\'s own-page anchor' % (got,))

    # The cross-chapter range: paired nowhere, so a locator per mark, and the
    # closing's carries the role its own mark declares.
    got = locators('Ranged Term')
    if got is None:
        _fail('M21-AC5: the book index has no "Ranged Term" entry')
    want = [('one.html#qi-mark-4', False, False),
            ('sub/two.html#qi-mark-3', True, True)]
    if got != want:
        _fail('M21-AC5: "Ranged Term" carries %r, expected %r as (href, carries '
              '%s, carries strong): its two marks are in different chapters, so '
              'neither is paired and each indexes as it would with no range= at '
              'all — the closing carrying the principal role IT declares'
              % (got, want, cls))
    print('ok   M21-AC5: a range whose marks share a chapter pairs there and '
          'gives one locator at its opening anchor, while a range spanning two '
          'chapters pairs nowhere and each of its marks indexes on its own, the '
          'closing keeping the principal class and emphasis its own mention= '
          'asks for')


READERS = {'ind': _ind, 'tex': _tex, 'html': _html, 'gfm': _gfm,
           'bookpdf': _bookpdf,
           'misuse': _misuse, 'preamble': _preamble,
           'bookhtml': _bookhtml}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in READERS:
        print('usage: m21probes.py <%s> <args...>' % '|'.join(sorted(READERS)),
              file=sys.stderr)
        sys.exit(2)
    READERS[sys.argv[1]](sys.argv[2:])
