"""The EPUB back-end's acceptance checks (M52).

`tests/epubindex.py` READS a rendered EPUB; this module DECIDES. The split is
the one `tests/htmlindex.py` and the shell's own comparison functions already
have, and it is what lets the self-test run each clause against a deliberately
broken artifact: a check written inline in run-tests.sh can be run on this
run's output and on nothing else, so its green says only that this run passed.

Every expected value reaching this module comes from a manifest file the
shell writes out of a hand-derived heredoc (the ORACLE RULE in run-tests.sh).
Nothing here derives an expectation from a rendered artifact — with one named
exception, the `same` subcommand, whose whole question is whether two
artifacts agree, and which refuses to run unless a hand-written manifest has
already pinned one of them.

Subcommands, each printing its own `ok`/`FAIL` line and exiting 0/1:

  sections <epub> <prefix> <manifest> [<sole-id>]
      The generated index sections and their rows, against the manifest.
  same <epub> <html> <prefix> <manifest>
      The EPUB's entry rows against the HTML render's, both first held to the
      manifest that pins them.
  links <epub> <prefix>
      Every link inside a generated index section resolves in the publication.
  absent <file> <token> [<allowed>...]
      A rendered file carries no run of <token> beyond the allowed strings.
"""

import sys

import epubindex
import htmlindex

SECTION_TOKEN = 'section'


def _rows(sections):
    """Manifest rows for a list of sections, section row then its own rows."""
    rows = []
    for found in sections:
        rows.append('\t'.join([SECTION_TOKEN, found['ident'], found['tag'],
                               found['title']]))
        rows.extend(htmlindex.row(r) for r in found['records'])
    return rows


def _compare(actual, expected, label, what):
    """Hold two row lists equal, naming the first row that differs."""
    if not expected:
        print(f'FAIL: {label}: the manifest is empty, so this comparison '
              f'would pass over nothing', file=sys.stderr)
        return 1
    if not actual:
        print(f'FAIL: {label}: {what} produced no row at all, so there is '
              f'nothing here for the manifest to hold', file=sys.stderr)
        return 1
    if actual == expected:
        return 0
    print(f'FAIL: {label}: {what} does not match the manifest', file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        got = actual[i] if i < len(actual) else '<no such row>'
        want = expected[i] if i < len(expected) else '<not in the manifest>'
        if got != want:
            print(f'  row {i + 1}\n    got  {got!r}\n    want {want!r}',
                  file=sys.stderr)
    return 1


def cmd_sections(argv):
    """Every generated index section in an EPUB, against a hand-written list.

    `sole-id`, where given, is an id the publication must carry exactly one
    section for — AC1's "exactly one section with id qi-index across the XHTML
    documents its content.opf manifest lists". Counted over the sections this
    reader found, which are the ones inside manifest-listed documents.
    """
    if len(argv) not in (3, 4):
        print('usage: epubcheck.py sections <epub> <prefix> <manifest> '
              '[<sole-id>]', file=sys.stderr)
        return 2
    path, prefix, manifest_path = argv[0], argv[1], argv[2]
    sole = argv[3] if len(argv) == 4 else None
    book = epubindex.read(path)
    sections = epubindex.index_sections(book, prefix)
    label = f'the index sections of {path}'
    if sole is not None:
        hits = [s for s in sections if s['ident'] == sole]
        if len(hits) != 1:
            where = ', '.join(s['document'] for s in hits) or 'no document'
            print(f'FAIL: {label}: {len(hits)} section(s) carry the id '
                  f'{sole!r} across the {len(book.documents)} document(s) '
                  f'{book.opf} lists ({where}); exactly 1 is required',
                  file=sys.stderr)
            return 1
    expected = htmlindex.read_manifest(manifest_path)
    status = _compare(_rows(sections), expected, label,
                      f'the {len(sections)} generated section(s)')
    if status:
        return status
    titles = ', '.join(f"{s['ident']} ({s['title']}) in {s['document']}"
                       for s in sections)
    print(f'ok   {label}: {len(sections)} generated section(s) — {titles} — '
          f'and their {len(expected) - len(sections)} row(s) match the '
          f'manifest')
    return 0


def cmd_same(argv):
    """The EPUB's entry rows against the HTML render's, via the manifest.

    Two comparisons, and the manifest is in both: the HTML rows are held to
    it, the EPUB rows are held to it, and the two row lists are then held to
    each other. The third is what the criterion asks for; the first two are
    what keep it from being two artifacts agreeing about the same mistake.
    """
    if len(argv) != 4:
        print('usage: epubcheck.py same <epub> <html> <prefix> <manifest>',
              file=sys.stderr)
        return 2
    epub_path, html_path, prefix, manifest_path = argv
    expected = htmlindex.read_manifest(manifest_path)
    book = epubindex.read(epub_path)
    epub_rows = [htmlindex.row(r)
                 for s in epubindex.index_sections(book, prefix)
                 for r in s['records']]
    page = htmlindex.parse(html_path)
    html_rows = [htmlindex.row(r)
                 for s in htmlindex.index_sections(page, prefix)
                 for r in s['records']]
    status = _compare(html_rows, expected, f'{html_path} against the manifest',
                      'the HTML render')
    if status:
        return status
    status = _compare(epub_rows, expected, f'{epub_path} against the manifest',
                      'the EPUB render')
    if status:
        return status
    status = _compare(epub_rows, html_rows,
                      f'{epub_path} against {html_path}',
                      'the EPUB render')
    if status:
        return status
    print(f'ok   the {len(epub_rows)} entry and letter row(s) the EPUB render '
          f'of this fixture carries are the rows its HTML render carries, and '
          f'both are the rows {manifest_path} states by hand')
    return 0


def cmd_links(argv):
    """Every link inside a generated index section names something reachable.

    The collected count is printed and required non-zero: an index whose
    entries lost their locator links would have nothing left to resolve, and
    a check that only counted failures would call that publication clean.
    """
    if len(argv) != 2:
        print('usage: epubcheck.py links <epub> <prefix>', file=sys.stderr)
        return 2
    path, prefix = argv
    book = epubindex.read(path)
    found = epubindex.links(book, prefix)
    if not found:
        print(f'FAIL: {path}: no link inside a generated index section, so '
              f'this check would pass over an empty set', file=sys.stderr)
        return 1
    bad = epubindex.unresolved(book, prefix)
    if bad:
        print(f'FAIL: {path}: {len(bad)} of {len(found)} link(s) inside a '
              f'generated index section name nothing in the publication',
              file=sys.stderr)
        for link in bad:
            print(f"  {link['document']}  {link['href']}  — {link['reason']}",
                  file=sys.stderr)
        return 1
    files = len({link['file'] or link['document'] for link in found})
    print(f'ok   {path}: all {len(found)} link(s) inside a generated index '
          f'section resolve — each names one of the {files} manifest-listed '
          f'document(s) and an element it carries')
    return 0


def cmd_absent(argv):
    """A rendered file carries no run of a token beyond the allowed strings.

    The allowed strings are stated by the CALLER, out of the fixture source,
    and every one of them must occur in the file: an exclusion that excludes
    nothing is an exclusion nobody would notice going stale, and the empty
    allowance a fixture with no such prose has is then the honest one rather
    than an untested default.
    """
    if len(argv) < 2:
        print('usage: epubcheck.py absent <file> <token> [<allowed>...]',
              file=sys.stderr)
        return 2
    path, token, allowed = argv[0], argv[1], argv[2:]
    body = open(path, encoding='utf-8', errors='replace').read()
    for text in allowed:
        if token not in text:
            print(f'FAIL: {path}: the allowed string {text!r} does not carry '
                  f'{token!r}, so it excludes nothing here', file=sys.stderr)
            return 1
        if text not in body:
            print(f'FAIL: {path}: the allowed string {text!r} does not occur '
                  f'in this file, so the allowance is stale and would hide a '
                  f'later occurrence of {token!r}', file=sys.stderr)
            return 1
    stripped = body
    for text in allowed:
        stripped = stripped.replace(text, '')
    count = stripped.count(token)
    if count:
        where = stripped.find(token)
        print(f'FAIL: {path}: {count} occurrence(s) of {token!r} outside the '
              f'{len(allowed)} allowed string(s); the first is '
              f'{stripped[max(0, where - 60):where + 60]!r}', file=sys.stderr)
        return 1
    print(f'ok   {path}: no occurrence of {token!r} outside the '
          f'{len(allowed)} string(s) the fixture source puts there')
    return 0


COMMANDS = {'sections': cmd_sections, 'same': cmd_same, 'links': cmd_links,
            'absent': cmd_absent}


def main(argv):
    if len(argv) < 2 or argv[1] not in COMMANDS:
        print(f'usage: {argv[0]} <{"|".join(COMMANDS)}> ...', file=sys.stderr)
        return 2
    return COMMANDS[argv[1]](argv[2:])


if __name__ == '__main__':
    sys.exit(main(sys.argv))
