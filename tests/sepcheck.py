"""The punctuation a generated index prints inside an entry, checked (M58).

`tests/htmlindex.py` READS the punctuation — `entry_separators` returns one
`(site, text)` pair per position an entry line prints a mark at — and this
module DECIDES, against a manifest the shell writes out of a hand-derived
heredoc (the ORACLE RULE in run-tests.sh). Nothing here derives an expectation
from a rendered artifact.

The split is `tests/epubcheck.py`'s and for its reason: a check written inline
in run-tests.sh can only ever be run on this run's output, so its green says
only that this run passed, while a module the self-test can point at a
deliberately broken artifact is shown able to fail.

Two subcommands, each printing its own `ok`/`FAIL` line and exiting 0/1:

  html <file> <prefix> <manifest> <label>
      The generated index sections of a rendered page.
  epub <epub> <prefix> <manifest> <label>
      The same manifest, over the spine documents of a rendered publication.

MANIFEST FORMAT. Tab-separated, one row per line:

  section<TAB><section id>       opens a section; every row after it is that
                                 section's until the next `section` row
  <depth><TAB><term><TAB><slot>...   one entry, its slots in printed order

A slot is `<site>=<U+XXXX>`: the position, named for the structure around it
rather than for the character printed, and the code point of the glyph
expected there. The code point and not the character itself, because the
fixtures print Arabic punctuation and a manifest sitting in a file of English
would otherwise turn on two marks a reader cannot tell apart.

The five sites are htmlindex's own constants, which name what a mark sits
between: S1 term to locators, S2 locator to locator, S3 locators to the first
cross-reference, S4 term to the first cross-reference where the entry has
none, S5 cross-reference to cross-reference.

WHAT A SLOT ASSERTS. Three things, reported apart so a failure says which
broke: that the entry prints its marks at exactly the sites the row names, in
that order; that the glyph at each is the code point the row gives; and that
exactly one whitespace character follows it — the `pandoc.Space()` the
extension writes and the author's value never carries. One whitespace
character and not one SPACE: an HTML writer may set that space as a newline,
which a reader sees as the same single space, while a lost space and a doubled
one are both visible here.
"""

import sys

import htmlindex

SECTION_TOKEN = 'section'
SITES = (htmlindex.SEP_TERM_LOCATORS, htmlindex.SEP_LOCATOR_LOCATOR,
         htmlindex.SEP_LOCATORS_XREF, htmlindex.SEP_TERM_XREF,
         htmlindex.SEP_XREF_XREF)


def _codepoint(token, where):
    """The character a `U+XXXX` slot value names."""
    if not token.startswith('U+'):
        raise ValueError(f'{where}: slot value {token!r} is not a code point; '
                         f'a manifest writes the glyph as U+XXXX, never as '
                         f'the character itself')
    try:
        value = int(token[2:], 16)
    except ValueError:
        raise ValueError(f'{where}: slot value {token!r} names no code point')
    return chr(value)


def read_manifest(path):
    """The manifest as a list of `(section id, [(term, depth, slots)])`.

    A slot is `(site, glyph)` with the glyph already decoded, so the caller
    compares characters and never parses.
    """
    sections = []
    with open(path, encoding='utf-8') as fh:
        for number, line in enumerate(fh, 1):
            line = line.rstrip('\n')
            if not line.strip():
                continue
            fields = line.split('\t')
            where = f'{path} line {number}'
            if fields[0] == SECTION_TOKEN:
                if len(fields) != 2:
                    raise ValueError(f'{where}: a section row is the token '
                                     f'and one section id')
                sections.append((fields[1], []))
                continue
            if not sections:
                raise ValueError(f'{where}: an entry row before any section '
                                 f'row, so it belongs to no section')
            if len(fields) < 3:
                raise ValueError(f'{where}: an entry row is a depth, a term '
                                 f'and at least one slot')
            slots = []
            for field in fields[2:]:
                site, _, glyph = field.partition('=')
                if site not in SITES:
                    raise ValueError(f'{where}: {site!r} is no printed '
                                     f'position; they are '
                                     f'{", ".join(SITES)}')
                slots.append((site, _codepoint(glyph, where)))
            sections[-1][1].append((int(fields[0]), fields[1], slots))
    if not sections:
        raise ValueError(f'{path}: the manifest states no section at all, so '
                         f'this comparison would pass over nothing')
    return sections


def _entry_rows(sections):
    """`(section id, depth, term, separators)` for every entry, in order."""
    rows = []
    for found in sections:
        for record in found['records']:
            if record['kind'] != 'entry':
                continue
            rows.append((found['ident'], record['depth'], record['term'],
                         record['separators']))
    return rows


def compare(sections, expected, label):
    """Hold a render's entries to the manifest. Returns an exit status."""
    wanted = [(ident, depth, term, slots)
              for ident, entries in expected
              for depth, term, slots in entries]
    found = _entry_rows(sections)
    if not wanted:
        print(f'FAIL: {label}: the manifest names no entry, so this '
              f'comparison would pass over nothing', file=sys.stderr)
        return 1
    # The row-count assertion, made before any row is compared: a manifest
    # short by an entry would otherwise agree with the render on every row it
    # does hold and say nothing about the entry it does not.
    if len(found) != len(wanted):
        print(f'FAIL: {label}: the render prints {len(found)} entry line(s) '
              f'and the manifest states {len(wanted)}; a manifest that does '
              f'not cover every printed entry cannot say the punctuation is '
              f'right everywhere', file=sys.stderr)
        return 1
    for (fid, fdepth, fterm, fseps), (wid, wdepth, wterm, wslots) in zip(
            found, wanted):
        where = f'{wid}: {wterm!r} at depth {wdepth}'
        if (fid, fdepth, fterm) != (wid, wdepth, wterm):
            print(f'FAIL: {label}: expected {where}, and the render prints '
                  f'{fid}: {fterm!r} at depth {fdepth} in that position',
                  file=sys.stderr)
            return 1
        if [site for site, _ in fseps] != [site for site, _ in wslots]:
            print(f'FAIL: {label}: {where} prints punctuation at '
                  f'{", ".join(site for site, _ in fseps) or "no position"}, '
                  f'where the manifest states '
                  f'{", ".join(site for site, _ in wslots)}', file=sys.stderr)
            return 1
        for (site, printed), (_, glyph) in zip(fseps, wslots):
            if not printed.startswith(glyph):
                print(f'FAIL: {label}: {where} prints {printed[:1]!r} at '
                      f'{site}, where the manifest states {glyph!r} '
                      f'(U+{ord(glyph):04X})', file=sys.stderr)
                return 1
            spacing = printed[len(glyph):]
            if len(spacing) != 1 or not spacing.isspace():
                print(f'FAIL: {label}: {where} follows the {site} mark with '
                      f'{spacing!r}, where exactly one whitespace character '
                      f'is what this extension writes after a separator — the '
                      f'space is never the author\'s', file=sys.stderr)
                return 1
    slots = sum(len(slots) for _, _, _, slots in wanted)
    print(f'ok   {label}: {len(wanted)} entry line(s) across '
          f'{len(expected)} section(s) print the stated glyph at all {slots} '
          f'printed position(s), each followed by exactly one space')
    return 0


def main(argv):
    if len(argv) != 5:
        print(__doc__, file=sys.stderr)
        return 2
    mode, artifact, prefix, manifest_path, label = argv
    expected = read_manifest(manifest_path)
    if mode == 'html':
        sections = htmlindex.index_sections(htmlindex.parse(artifact), prefix)
    elif mode == 'epub':
        import epubindex
        sections = epubindex.index_sections(epubindex.read(artifact), prefix)
    else:
        print(f'FAIL: {mode} is no subcommand of this module', file=sys.stderr)
        return 2
    if not sections:
        print(f'FAIL: {label}: {artifact} carries no generated index section '
              f'under the id prefix {prefix!r}, so there is no printed '
              f'punctuation here to hold', file=sys.stderr)
        return 1
    return compare(sections, expected, label)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
