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

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402  (needs the path line above)


def _ind(argv):
    ind_path, ilg_path, cmd = argv[0], argv[1], argv[2]
    ind = open(ind_path, encoding='utf-8').read()
    # One `\item` per entry; makeindex breaks a long locator list across lines, so
    # each item is normalized to one line before anything is read off it.
    items = {}
    for chunk in re.split(r'\\item\s', ind)[1:]:
        line = ' '.join(chunk.split())
        term = line.split(',')[0].strip()
        items[term] = line
    missing = [t for t in ('basilisk', 'faun') if t not in items]
    if missing:
        print(f'FAIL: M20-AC1: the compiled index has no entry for {missing}; '
              f'it has {sorted(items)}', file=sys.stderr)
        sys.exit(1)
    b = items['basilisk']
    # The encapsulated locator, as hyperref rewrites it, on the page the fixture
    # puts the principal mark on. Both halves are asserted: a check for the
    # command alone would pass with the emphasis on the wrong locator, which is
    # the defect that matters here.
    want = r'\hyperxindexformat{\%s}{2}' % cmd
    if b.count(want) != 1:
        print(f'FAIL: M20-AC1: expected exactly one <<{want}>> in the basilisk '
              f'entry, found {b.count(want)}: <<{b}>>', file=sys.stderr)
        sys.exit(1)
    # And the other two locators are plain. Counted, not merely present: a filter
    # that emphasized all three would still carry these two strings.
    for page in ('1', '3'):
        plain = r'\hyperpage{%s}' % page
        if b.count(plain) != 1:
            print(f'FAIL: M20-AC1: expected exactly one plain <<{plain}>> in the '
                  f'basilisk entry, found {b.count(plain)}: <<{b}>>',
                  file=sys.stderr)
            sys.exit(1)
    if b.count(cmd) != 1:
        print(f'FAIL: M20-AC1: the basilisk entry names {cmd} {b.count(cmd)} '
              f'times; exactly one of its three locators is principal: <<{b}>>',
              file=sys.stderr)
        sys.exit(1)
    # The control: a term with no role anywhere must reach the compiled index with
    # no emphasis at all. Without it this check would pass on a back-end that
    # emphasized every locator it wrote.
    if cmd in items['faun']:
        print(f'FAIL: M20-AC1: the role-free control entry carries {cmd}: '
              f'<<{items["faun"]}>>', file=sys.stderr)
        sys.exit(1)
    ilg = open(ilg_path, encoding='utf-8').read()
    if 'Conflicting entries' in ilg:
        print('FAIL: M20-AC1: makeindex reported conflicting entries for this '
              'fixture; a styled and a plain locator of one key are rivals only '
              'where they share a page, and these are three pages apart:\n' + ilg,
              file=sys.stderr)
        sys.exit(1)
    m = re.search(r'done \((\d+) lines written, (\d+) warnings?\)', ilg)
    if not m:
        print('FAIL: M20-AC1: could not read a warning count out of the makeindex '
              'transcript, so "no conflicting-encapsulation warning" rests on a '
              'substring search alone:\n' + ilg, file=sys.stderr)
        sys.exit(1)
    if m.group(2) != '0':
        print(f'FAIL: M20-AC1: makeindex reported {m.group(2)} warning(s) for this '
              f'fixture:\n{ilg}', file=sys.stderr)
        sys.exit(1)
    print('ok   M20-AC1: the compiled index emphasizes exactly one of the three '
          'locators, the one on the principal mark\'s page, leaves the other two '
          'and the role-free control plain, and makeindex logs no warning at all')

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
        """Every `\\index{...}` command, read with a brace COUNTER rather than a
        regular expression. A pattern cannot do this: the shortest match for
        `\\index{gorgon@gorgon, \\see{basilisk}{}|quartoindexprincipal}` ends at
        the first `}` inside the folded cross-reference, which silently truncates
        the encapsulation this check exists to compare — two commands differing
        only past that point then compare equal. The filter emits a literal brace
        in a level as `\\textbraceleft{}`, so the braces it writes are balanced.
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
                print(f'FAIL: M20-AC3/AC4: an \\index command in {path} never '
                      f'closes its brace', file=sys.stderr)
                sys.exit(1)
            out.append(src[i:j])
            i = j
    a, b = commands(argv[0]), commands(argv[1])
    if not a or not b:
        print(f'FAIL: M20-AC3/AC4: one of the two renders emitted no \\index '
              f'command at all ({len(a)} and {len(b)}), so this comparison would '
              f'pass on two empty documents', file=sys.stderr)
        sys.exit(1)
    if len(a) != len(b):
        print(f'FAIL: M20-AC3/AC4: the fixture emits {len(a)} \\index commands and '
              f'its twin {len(b)}; a dropped role must change no command COUNT',
              file=sys.stderr)
        sys.exit(1)
    # Every command must agree EXCEPT the two the role legitimately changes: the
    # principal basilisk mention and the principal gorgon locator. Stated as an
    # exact set, so a role that stopped taking effect fails here just as one that
    # leaked into a mark it should not reach.
    differ = sorted({x for x, y in zip(a, b) if x != y})
    # `imp` is here because its role SURVIVES: its only cross-reference names its
    # own entry, so the target is dropped and the mark indexes plainly, leaving a
    # locator for the role to emphasize. A filter that resolved the role against
    # the declared cross-references rather than the surviving ones would drop it
    # and lose this row (review F2).
    want = sorted({r'\index{basilisk|quartoindexprincipal}',
                   r'\index{gorgon@gorgon, \see{basilisk}{}|quartoindexprincipal}',
                   r'\index{imp|quartoindexprincipal}',
                   r'\index{kraken|quartoindexprincipal}'})
    if differ != want:
        print(f'FAIL: M20-AC3/AC4: the commands that differ from the twin are\n'
              f'  {differ}\nexpected\n  {want}', file=sys.stderr)
        sys.exit(1)
    print(f'ok   M20-AC3/AC4: of {len(a)} emitted \\index commands the fixture and '
          f'its role-free twin agree on all but the two the role is meant to '
          f'change, so every mark whose role was reported and dropped emits '
          f'exactly what it emits without the attribute')

READERS = {'ind': _ind, 'html': _html, 'gfm': _gfm, 'twin': _twin}

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in READERS:
        print(f'usage: {sys.argv[0]} <{"|".join(READERS)}> <args...>',
              file=sys.stderr)
        sys.exit(2)
    READERS[sys.argv[1]](sys.argv[2:])
