"""One rendered artifact's index, printed in a comparable form (M43).

The version matrix renders the same fixtures under several Quarto releases and
asks whether the index each one emits is the same. That question needs ONE
serialization both sides are reduced to, produced by a command a workflow step
can run against a single file:

  html <file.html> — every generated index section on the page, in
      `htmlindex.section_rows()` form with the locator HREF form of an entry
      row: `section<TAB>id<TAB>heading tag<TAB>title<TAB>id it follows`, then
      that section's entry and letter-group rows in rendered order. WHERE each
      locator points and not how many there are, because a Quarto version that
      repointed an anchor without changing the count is exactly the difference
      this comparison exists to find.

  pdf <file.pdf> [heading] — the printed index, in the order
      `pdfindex.read()` reconstructs it: `level<TAB>term<TAB>printed line`, one
      row per entry. `heading` is the line the index starts after, `Index` by
      default.

The serialization goes to stdout and nothing else does, so a caller can
compare two runs' output byte for byte. What was swept is reported on stderr,
the convention the suite's other readers follow.

This module PRINTS an artifact; it never states an expected value, and no
manifest may be written from its output — the ORACLE RULE in run-tests.sh,
which `htmlindex` and `pdfindex` carry in their own headers and which this
entry point inherits by importing them.

An artifact carrying no index is a loud failure and never an empty print: a
comparison of two empty dumps would agree, and agreeing about nothing is the
one answer this command must not be able to give.

Usage:  python3 tests/indexdump.py <mode> <artifact> [...]

Exits non-zero with a `FAIL:` line naming what it found.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex  # noqa: E402
import pdfindex  # noqa: E402

# The HTML back-end's minted identifiers. run-tests.sh pins these to the
# filter's own constants and passes them in through the environment; the
# defaults here are for a caller outside the suite (a workflow step), where a
# filter that had renamed them would leave this command finding no section at
# all — which is a loud failure below, not a quiet empty dump.
SECTION_ID = os.environ.get('HTML_SECTION_ID', 'qi-index')
ANCHOR_PREFIX = os.environ.get('HTML_ANCHOR_PREFIX', 'qi-mark-')
ENTRY_PREFIX = os.environ.get('HTML_ENTRY_PREFIX', 'qi-entry-')


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    raise SystemExit(1)


def html_rows(rows, path):
    """`rows` judged and reported. Split from the read so the self-test can
    reach this clause with a row list of its own rather than by building an
    HTML page that produces one."""
    if not rows:
        fail(f'{path}: carries no generated index section '
             f'(none with the id {SECTION_ID!r} or a name under it), so there '
             f'is nothing to compare')
    sections = sum(1 for r in rows
                   if r.startswith(htmlindex.SECTION_TOKEN + '\t'))
    print(f'indexdump: {path}: {sections} index section(s), '
          f'{len(rows) - sections} entry/heading row(s)', file=sys.stderr)
    return rows


def dump_html(path):
    """Every generated index section on the page, in href row form."""
    minted = (SECTION_ID, ANCHOR_PREFIX, ENTRY_PREFIX)
    try:
        rows = htmlindex.section_rows(
            htmlindex.parse(path), SECTION_ID, minted, hrefs=True)
    except ValueError as bad:
        # A section this reader cannot read is a finding, not a traceback: a
        # crash exits non-zero for a reason nothing states.
        fail(f'{path}: {bad}')
    return html_rows(rows, path)


def pdf_rows(entries, path, heading):
    """`entries` judged, reported and serialized. Split from the read for the
    same reason `html_rows` is: neither clause below can be reached by handing
    this command a PDF, and a clause no plant can reach is a clause whose green
    says nothing."""
    if not entries:
        fail(f'{path}: the {heading!r} heading is printed but no entry '
             f'follows it, so the index is empty')
    if not pdfindex.columns_carry_top_level(entries):
        # pdfindex's own documented assumption. Unmet, every level it reports
        # in that column is a level too shallow, and a dump nobody can trust
        # the levels of must not be printed as if they were read.
        fail(f'{path}: a printed column carries no top-level entry, so '
             f'pdfindex cannot read its indent levels')
    print(f'indexdump: {path}: {len(entries)} printed entry line(s) under '
          f'{heading!r}', file=sys.stderr)
    return [f'{e.level}\t{e.term}\t{e.text}' for e in entries]


def dump_pdf(path, heading='Index'):
    """The printed index, in the order it is printed."""
    try:
        entries = pdfindex.read(path, heading)
    except LookupError as bad:
        fail(f'{path}: {bad}')
    return pdf_rows(entries, path, heading)


MODES = {
    'html': (dump_html, 1, 1),
    'pdf': (dump_pdf, 1, 2),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(f'usage: {argv[0]} <{"|".join(MODES)}> <artifact> '
                         f'[...]')
    func, least, most = MODES[argv[1]]
    args = argv[2:]
    if not least <= len(args) <= most:
        raise SystemExit(f'usage: {argv[0]} {argv[1]} takes {least}..{most} '
                         f'argument(s), got {len(args)}')
    if not os.path.isfile(args[0]):
        fail(f'{args[0]}: no such artifact')
    for line in func(*args):
        print(line)


if __name__ == '__main__':
    main(sys.argv)
