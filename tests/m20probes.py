"""The M20 acceptance readers, one per artifact the criteria are stated over.

They live here rather than inline in the suite for one reason: the self-test
runs each of them again against a deliberately mutated copy of the artifact it
reads, and a check that cannot be re-run cannot be shown to discriminate. The
suite is the only caller of the run-time invocations; the self-test is the only
caller of the mutated ones, and both go through this one file so the two cannot
drift on how a reader is invoked (the discipline `run_scan` applies to the
source-reading scans, which these are not — these read rendered output).

Usage:  python3 tests/m20probes.py <ind|html|gfm|twin> <args...>
"""

import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402  (needs the path line above)


def _fail(msg):
    print('FAIL: ' + msg, file=sys.stderr)
    sys.exit(1)


def _group(text, at):
    """The balanced `{...}` starting at `text[at]`, and the index just past it.

    Brace counting, not a regex: every argument read here may hold braces of
    its own — a folded cross-reference does, and so does the wrapped page list
    hyperref hands the locator command — and a pattern stopping at the first
    `}` reads a truncated argument and compares it happily. The suite has been
    caught by exactly that once already (M20 work log, T5).
    """
    assert text[at] == '{'
    depth, i = 0, at
    while i < len(text):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[at + 1:i], i + 1
        i += 1
    _fail('unbalanced braces reading a group from <<%s>>' % text[at:at + 60])


def _locator_groups(entry, locator_cmd):
    """Every `\hyperxindexformat{\<locator_cmd>{id}}{pages}` in one entry.

    Returns (id, [page, ...]) per group, in the order they print. Only groups
    whose FIRST argument is the locator command count: the same wrapper carries
    `\see` and the both-targets command, which are not locators.
    """
    out, i, wrapper = [], 0, r'\hyperxindexformat'
    while True:
        i = entry.find(wrapper, i)
        if i < 0:
            return out
        j = i + len(wrapper)
        if j >= len(entry) or entry[j] != '{':
            i = j
            continue
        first, j = _group(entry, j)
        if j >= len(entry) or entry[j] != '{':
            i = j
            continue
        second, j = _group(entry, j)
        i = j
        m = re.fullmatch(r'\\%s\{([^{}]*)\}' % re.escape(locator_cmd), first.strip())
        if m:
            out.append((m.group(1), [p.strip() for p in second.split(',')]))


def _ind(argv):
    """M20-AC1 — the `.ind`, the `.ilg` and the `.aux` of one PDF render.

    The emphasis itself is NOT in the `.ind` any more: D-007 moves per-locator
    styling off makeindex's encapsulation channel entirely, because two
    locators of one key whose encapsulations differ by any byte are what
    makeindex rejects on a shared page. What the `.ind` shows instead is that
    a key's locators all carry ONE identifier — the property that makes the
    conflict unreachable — and what the `.aux` shows is which page each
    identifier was registered from. That the registered page then prints
    emphasized is exercised by the T9 fixture, whose own render redefines the
    emphasis command to something `pdftotext` can read.
    """
    ind_path, ilg_path, aux_path = argv[0], argv[1], argv[2]
    locator_cmd, page_cmd = argv[3], argv[4]
    ind = open(ind_path, encoding='utf-8').read()
    # One `\item` per entry; makeindex breaks a long locator list across lines,
    # so each item is normalized to one line before anything is read off it.
    items = {}
    for chunk in re.split(r'\\item\s', ind)[1:]:
        line = ' '.join(chunk.split())
        items[line.split(',')[0].strip()] = line
    missing = [t for t in ('basilisk', 'gorgon', 'faun') if t not in items]
    if missing:
        _fail('M20-AC1: the compiled index has no entry for %s; it has %s'
              % (missing, sorted(items)))

    # basilisk: three locators, one identifier between them, one page each, and
    # no two of those pages adjacent. The last is not decoration — makeindex
    # folds a run of three consecutive pages under one encapsulation into a
    # range, and the typeset-time registry looks a page up by its printed
    # string, so `1--3` matches nothing and the entry would print with no
    # emphasis at all while every other clause here still passed.
    groups = _locator_groups(items['basilisk'], locator_cmd)
    if len(groups) != 3 or any(len(pages) != 1 for _, pages in groups):
        _fail('M20-AC1: expected three one-page %s groups in the basilisk entry, '
              'found %r: <<%s>>' % (locator_cmd, groups, items['basilisk']))
    ids = {gid for gid, _ in groups}
    if len(ids) != 1:
        _fail('M20-AC1: basilisk\'s three locators name %d identifiers (%s); one '
              'per key is what makes a same-page pair impossible: <<%s>>'
              % (len(ids), sorted(ids), items['basilisk']))
    basilisk_id = groups[0][0]
    pages = sorted(int(pages[0]) for _, pages in groups)
    if any(b - a < 2 for a, b in zip(pages, pages[1:])):
        _fail('M20-AC1: basilisk\'s locator pages %s include an adjacent pair; the '
              'fixture separates them precisely so makeindex cannot fold them into '
              'a range the registry could not match' % pages)

    # gorgon: a key a cross-reference also marks. Its locator carries the same
    # single encapsulation, and M15's fold has put the cross-reference into the
    # entry's printed text ahead of it rather than into a rival encapsulation.
    gorgon = _locator_groups(items['gorgon'], locator_cmd)
    if len(gorgon) != 1 or len(gorgon[0][1]) != 1:
        _fail('M20-AC1: expected one one-page %s group in the gorgon entry, found '
              '%r: <<%s>>' % (locator_cmd, gorgon, items['gorgon']))
    fold = r'\see{basilisk}{}'
    if fold not in items['gorgon']:
        _fail('M20-AC1: the gorgon entry does not carry <<%s>> in its printed text; '
              'a contested key folds its cross-reference there: <<%s>>'
              % (fold, items['gorgon']))
    if items['gorgon'].index(fold) > items['gorgon'].index(r'\hyperxindexformat'):
        _fail('M20-AC1: the gorgon entry prints its cross-reference after its '
              'locator: <<%s>>' % items['gorgon'])

    # The control: a key no mark of which is principal emits exactly what it
    # emitted before this milestone — no locator command anywhere.
    if _locator_groups(items['faun'], locator_cmd) or locator_cmd in items['faun']:
        _fail('M20-AC1: the role-free control entry carries %s: <<%s>>'
              % (locator_cmd, items['faun']))

    # The two artifacts cross-linked. Neither settles anything alone: an `.aux`
    # of well-formed lines naming identifiers no `.ind` group carries prints
    # nothing, and a `.ind` whose identifiers were never registered prints
    # nothing either.
    every = {}
    for entry in items.values():
        for gid, gpages in _locator_groups(entry, locator_cmd):
            every.setdefault(gid, []).extend(gpages)
    aux = open(aux_path, encoding='utf-8').read()
    lines = re.findall(r'\\%s\{([^{}]*)\}\{([^{}]*)\}' % re.escape(page_cmd), aux)
    if len(lines) != 4:
        _fail('M20-AC1: the .aux carries %d %s lines; the fixture writes '
              'mention="principal" on four marks that contribute a locator: %r'
              % (len(lines), page_cmd, lines))
    if len({gid for gid, _ in lines}) != 4:
        _fail('M20-AC1: the .aux\'s four registrations name %d distinct '
              'identifiers: %r' % (len({g for g, _ in lines}), lines))
    if {gid for gid, _ in lines} != set(every):
        _fail('M20-AC1: the registered identifiers %s are not the ones the .ind\'s '
              '%s groups name (%s), so a registration and a locator disagree about '
              'which entry they are about'
              % (sorted({g for g, _ in lines}), locator_cmd, sorted(every)))
    for gid, page in lines:
        if page not in every[gid]:
            _fail('M20-AC1: %s is registered from page %s, which is not among the '
                  'pages its own entry lists (%s)' % (gid, page, every[gid]))
    registered = dict(lines)
    if int(registered[basilisk_id]) != pages[1]:
        _fail('M20-AC1: basilisk is registered from page %s; the fixture puts its '
              'principal mark on the middle of its three pages %s'
              % (registered[basilisk_id], pages))

    # The .ilg's own warning count, read as a number. It, and not Quarto's exit
    # status, is the stable oracle for this class: Quarto fails a render on a
    # regex over this transcript, which is an implementation detail (D-007 and
    # the milestone's own Decisions entry).
    ilg = open(ilg_path, encoding='utf-8').read()
    if 'Conflicting entries' in ilg:
        _fail('M20-AC1: makeindex reported conflicting entries for this fixture, '
              'which the uniform per-key encapsulation is supposed to make '
              'unreachable:\n' + ilg)
    m = re.search(r'done \((\d+) lines written, (\d+) warnings?\)', ilg)
    if not m:
        _fail('M20-AC1: could not read a warning count out of the makeindex '
              'transcript, so "no warnings" would rest on a substring search '
              'alone:\n' + ilg)
    if m.group(2) != '0':
        _fail('M20-AC1: makeindex reported %s warning(s) for this fixture:\n%s'
              % (m.group(2), ilg))
    print('ok   M20-AC1: every locator of a principal key carries one identifier, '
          'the .aux registers exactly those four identifiers from pages their own '
          'entries list, and makeindex logs no warning at all')


_DEFINERS = (r'providecommand\*?', r'newcommand\*?', r'renewcommand\*?',
             r'def', r'gdef', r'xdef', r'edef', r'let')


def _preamble(path, which):
    text = open(path, encoding='utf-8').read()
    if not text.strip():
        _fail('M20-AC6: %s (%s) is empty, so every clause stated over its '
              'preamble would pass on a file this run did not write' % (path, which))
    marker = r'\begin{document}'
    if text.count(marker) != 1:
        _fail('M20-AC6: %s (%s) carries %d occurrences of %s, so "the region before '
              'it" names no one region' % (path, which, text.count(marker), marker))
    return text[:text.index(marker)]


def _defined(preamble):
    """Control sequences whose name begins `quartoindex` that this region DEFINES.

    Defining forms, not mere occurrences: the subsystem's own `\qi@` helpers
    name the emphasis command inside their bodies, which is a use and not a
    definition. `\csname` is checked separately by the caller, since a name
    built at expansion time is invisible to this pattern by construction.
    """
    return re.findall(r'\\(?:%s)\s*\\(quartoindex[a-zA-Z]*)' % '|'.join(_DEFINERS),
                      preamble)


def _tex(argv):
    """M20-AC6 — the subsystem is injected, with `\providecommand`, only where used."""
    principal_path, content_path = argv[0], argv[1]
    wanted = argv[2:]
    for path in (principal_path, content_path):
        if not os.path.isfile(path):
            _fail('M20-AC6: %s does not exist; the negative half of this criterion '
                  'would otherwise pass on an absent file' % path)
    pre = _preamble(principal_path, 'the principal fixture')
    for cmd in wanted:
        hits = re.findall(r'\\providecommand\*\\%s\[' % re.escape(cmd), pre)
        if len(hits) != 1:
            _fail('M20-AC6: the principal fixture\'s preamble defines \\%s with '
                  '\\providecommand* %d times; exactly one is what makes an author\'s '
                  'own definition win and a second injection impossible'
                  % (cmd, len(hits)))
    # `quartoindexseeboth` is the fixture's own pre-existing cross-reference
    # command: the both-targets mark it carries required it before this
    # milestone, so it is named here rather than left to a wildcard.
    allowed = set(wanted) | {'quartoindexseeboth'}
    extra = sorted(set(_defined(pre)) - allowed)
    if extra:
        _fail('M20-AC6: the principal fixture\'s preamble also defines %s; the '
              'subsystem is exactly %s plus the pre-existing %s'
              % (extra, sorted(wanted), 'quartoindexseeboth'))
    if r'\csname quartoindex' in pre:
        _fail('M20-AC6: the principal fixture\'s preamble builds a quartoindex name '
              'with \\csname, which the definition scan above cannot see')
    content = _preamble(content_path, 'the role-free control fixture')
    if r'\makeindex' not in content:
        _fail('M20-AC6: the control fixture\'s preamble carries no \\makeindex, so it '
              'is not the extension-processed preamble the negative half is about')
    # The four SUBSYSTEM commands, not `allowed`: `quartoindexseeboth` belongs to
    # the cross-reference channel, and a control carrying a both-targets mark is
    # entitled to it. Forbidding it here would make this check about the wrong
    # feature and fail on the role-free twin, which carries exactly that mark.
    leaked = sorted(set(_defined(content)) & set(wanted))
    if leaked or r'\csname quartoindex' in content:
        _fail('M20-AC6: the control fixture, which has no principal mention, has %s '
              'injected into its preamble anyway' % (leaked or '\\csname quartoindex'))
    print('ok   M20-AC6: the four subsystem commands are defined once each with '
          '\\providecommand* in the fixture that uses them, nothing else naming '
          'quartoindex is defined there, and none of them reaches a document '
          'without a principal mention')


def _html(argv):
    path = argv[0]
    cls = os.environ['HTML_PRINCIPAL_CLASS']
    doc = H.parse(path)
    section = H.find_id(doc, os.environ.get('HTML_SECTION_ID', 'qi-index'))
    if section is None:
        print(f'FAIL: M20-AC2: {path} has no generated index section', file=sys.stderr)
        sys.exit(1)


    def locators(term):
        """One entry's locator links, in order, as (carries the class, is strong).

        Read off the `<li>` itself rather than through index_entries, whose
        records carry a locator's href and not the element: the class and the
        emphasis node are the whole question here. `own_nodes` keeps a
        sub-entry's markup out of its parent's answer.
        """
        for item in H.find_all(section, 'li'):
            own = list(H.own_nodes(item))
            terms = [n for n in own if 'qi-term' in H.classes(n)]
            if len(terms) != 1 or H.text(terms[0]).strip() != term:
                continue
            out = []
            for node in own:
                if 'qi-locators' in H.classes(node):
                    out.extend((cls in H.classes(a), bool(H.find_all(a, 'strong')))
                               for a in H.find_all(node, 'a'))
            return out
        return None


    # Three locators, and the SECOND is the principal one: a check that only
    # counted principal links would pass with the emphasis on the wrong mention.
    got = locators('basilisk')
    want = [(False, False), (True, True), (False, False)]
    if got != want:
        print(f'FAIL: M20-AC2: basilisk\'s locator links are {got}, expected '
              f'{want} as (carries {cls}, carries strong)', file=sys.stderr)
        sys.exit(1)
    # The role-free control, for the same reason the .ind check has one.
    got = locators('faun')
    want = [(False, False), (False, False)]
    if got != want:
        print(f'FAIL: M20-AC2: the role-free control faun\'s locator links are '
              f'{got}, expected {want}', file=sys.stderr)
        sys.exit(1)
    # And a mark whose role was dropped contributes no locator at all, so there is
    # nothing here to be principal. The entry's EXISTENCE is asserted first:
    # `locators` returns None for a term with no entry and [] for an entry with
    # no locator links, and testing the two alike would let this control pass on
    # an index that had lost the entry entirely (review F9).
    got = locators('cockatrice')
    if got is None:
        print('FAIL: M20-AC2: the index has no cockatrice entry at all, so the '
              'control for a cross-reference mark\'s dropped role cannot fail',
              file=sys.stderr)
        sys.exit(1)
    if got != []:
        print(f'FAIL: M20-AC2: cockatrice carries {len(got)} locator link(s); its '
              f'only mark is a cross-reference, which takes the locator\'s place',
              file=sys.stderr)
        sys.exit(1)
    print(f'ok   M20-AC2: the index entry\'s second locator link carries {cls} and '
          f'a strong node, its other two carry neither, and the role-free control '
          f'entry carries neither on either of its locators')

def _gfm(argv):
    """AC5: every index span the render carries, against a hand-derived manifest.

    `argv` is the rendered file and the manifest file, the latter one expected
    span per line in document order. The manifest is derived from the `.qmd` by
    hand (the suite's ORACLE RULE), never copied from this render, and it lives
    in the suite's M20 section beside every other fixture's.

    The span pattern is deliberately NOT `[^<]*` in the body: a mark whose
    visible text carries nested inline markup — `[**kraken**]{.index}` — is an
    index span the criterion quantifies over, and a scan that could not see one
    would shrink the promised domain instead of failing (the audit's F2/F3). The
    fixture writes one, so the widening is exercised rather than assumed.

    The comparison is byte for byte and in document order, neither normalized
    nor sorted: the fixture renders with `wrap: none`, so the writer never
    breaks a span across lines, and an ordering the reader sorted away could be
    transposed by the filter without any check noticing.
    """
    src = open(argv[0], encoding='utf-8').read()
    want = [l.rstrip('\n') for l in open(argv[1], encoding='utf-8') if l.strip()]
    got = re.findall(r'<span class="index"[^>]*>.*?</span>', src)
    # The count is pinned to the fixture's own marks, not merely to the manifest:
    # thirteen index marks reach the render, the fourteenth being the entry-less
    # mark, which indexes nothing and is removed. A scan that silently stopped
    # enumerating some span would otherwise shrink the domain it is checked over.
    EXPECTED_SPANS = 13
    if len(got) != EXPECTED_SPANS:
        print(f'FAIL: M20-AC5: the gfm render carries {len(got)} index spans; the '
              f'fixture writes {EXPECTED_SPANS} marks that reach it (the '
              f'entry-less mark indexes nothing and is removed)', file=sys.stderr)
        for line in got:
            print(f'  got  <<{line}>>', file=sys.stderr)
        sys.exit(1)
    if len(want) != EXPECTED_SPANS:
        print(f'FAIL: M20-AC5: the expected manifest has {len(want)} rows, not '
              f'{EXPECTED_SPANS}; the manifest and the fixture have drifted apart',
              file=sys.stderr)
        sys.exit(1)
    if got != want:
        print('FAIL: M20-AC5: the index spans in the gfm render are not, in '
              'document order, the ones the manifest derives from the fixture:',
              file=sys.stderr)
        for i, (g, w) in enumerate(zip(got, want)):
            if g != w:
                print(f'  row {i + 1} got  <<{g}>>', file=sys.stderr)
                print(f'  row {i + 1} want <<{w}>>', file=sys.stderr)
        sys.exit(1)
    # `role=` would be the ARIA attribute this milestone renamed the mark
    # attribute to avoid, and it must appear nowhere at all.
    if re.search(r'<span[^>]*\srole=', src):
        print('FAIL: M20-AC5: a span in the gfm render carries a literal role= '
              'attribute; the mark attribute is data-prefixed precisely so no '
              'marked term ships an ARIA role', file=sys.stderr)
        sys.exit(1)
    for token in ('qi-', r'\index{', 'quartoindexprincipal'):
        if token in src:
            print(f'FAIL: M20-AC5: the gfm render carries <<{token}>>, which is '
                  f'back-end residue in a format with no index back-end',
                  file=sys.stderr)
            sys.exit(1)
    print(f'ok   M20-AC5: all {len(got)} index spans in the gfm render are, in '
          f'document order and byte for byte, the manifest derived from the '
          f'fixture, and no anchor, index command, encapsulation command or '
          f'ARIA role reaches the format at all')

def _twin(argv):
    def commands(path):
        """Every `\index{...}` command, read with a brace COUNTER rather than a
        regular expression. A pattern cannot do this: the shortest match for
        `\index{gorgon@gorgon, \see{basilisk}{}|quartoindexlocator{qi2}}` ends at
        the first `}` inside the folded cross-reference, which silently truncates
        the encapsulation this check exists to compare — two commands differing
        only past that point then compare equal. The filter emits a literal brace
        in a level as `\textbraceleft{}`, so the braces it writes are balanced.
        """
        src = open(path, encoding='utf-8').read()
        out, i, needle = [], 0, '\\index{'
        while True:
            i = src.find(needle, i)
            if i == -1:
                return out
            j, depth = i + len(needle), 1
            while j < len(src) and depth:
                if src[j] == '{':
                    depth += 1
                elif src[j] == '}':
                    depth -= 1
                j += 1
            if depth:
                _fail('M20-AC3/AC4: an \\index command in %s never closes its '
                      'brace' % path)
            out.append(src[i:j])
            i = j

    a, b = commands(argv[0]), commands(argv[1])
    if not a or not b:
        _fail('M20-AC3/AC4: one of the two renders emitted no \\index command at '
              'all (%d and %d), so this comparison would pass on two empty '
              'documents' % (len(a), len(b)))
    if len(a) != len(b):
        _fail('M20-AC3/AC4: the fixture emits %d \\index commands and its twin %d; '
              'a dropped role must change no command COUNT' % (len(a), len(b)))
    # Positionally, and as a MULTISET rather than a set. The distinction is the
    # whole point under D-007: a key carrying a principal mention encapsulates
    # EVERY one of its locators with one ordinal, so `basilisk` differs from the
    # twin three times over — and a set would collapse those three into one row
    # and pass a filter that encapsulated only the principal mark, which is the
    # emission that breaks the render on a shared page.
    differ = collections.Counter(x for x, y in zip(a, b) if x != y)
    # `imp` is here because its role SURVIVES: its only cross-reference names its
    # own entry, so the target is dropped and the mark indexes plainly, leaving a
    # locator for the role to emphasize. A filter that resolved the role against
    # the declared cross-references rather than the surviving ones would drop it
    # and lose this row (review F2).
    want = collections.Counter({
        r'\index{basilisk|quartoindexlocator{qi1}}': 3,
        r'\index{gorgon@gorgon, \see{basilisk}{}|quartoindexlocator{qi2}}': 1,
        r'\index{imp|quartoindexlocator{qi3}}': 1,
        r'\index{kraken|quartoindexlocator{qi4}}': 1,
    })
    if differ != want:
        _fail('M20-AC3/AC4: the commands that differ from the twin are\n  %r\n'
              'expected\n  %r' % (dict(differ), dict(want)))
    # The other half of the emission: the role itself travels in a registration
    # beside the principal mark, not in the encapsulation. One per principal
    # mark that contributes a locator, and none at all in the twin.
    def registrations(path):
        return re.findall(r'\\quartoindexregister\{([^{}]*)\}',
                          open(path, encoding='utf-8').read())
    marks = registrations(argv[0])
    if sorted(marks) != ['qi1', 'qi2', 'qi3', 'qi4']:
        _fail('M20-AC3/AC4: the fixture registers %r; one per principal mark that '
              'contributes a locator, each under its own key\'s ordinal' % (marks,))
    if registrations(argv[1]):
        _fail('M20-AC3/AC4: the role-free twin registers %r, though it declares no '
              'mention anywhere' % (registrations(argv[1]),))
    print('ok   M20-AC3/AC4: of %d emitted \\index commands the fixture and its '
          'role-free twin agree on all but the six the role changes — every '
          'locator of each of the four principal keys — and the four '
          'registrations reach the fixture alone, so every mark whose role was '
          'reported and dropped emits exactly what it emits without the attribute'
          % len(a))


READERS = {'ind': _ind, 'tex': _tex, 'html': _html, 'gfm': _gfm, 'twin': _twin}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in READERS:
        print(f'usage: {sys.argv[0]} <{"|".join(READERS)}> <args...>',
              file=sys.stderr)
        sys.exit(2)
    READERS[sys.argv[1]](sys.argv[2:])
