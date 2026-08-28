#!/usr/bin/env python3
"""Partition a render log's extension warnings around the two marker reports.

M29's subject is what those two reports SAY, so the check reads emitted text
and never the filter's source (D-011): the templates below are written out as
a reader meets them in a log. Every extension warning in the log is matched
against them or against the fixture's other known warnings, and a line
belonging to neither partition fails — a report reworded past the template
would otherwise slip through a template-shaped search, and one carrying the
chapter somewhere other than after the block position would slip through a
search anchored at the template's first word (the M12 precedent this extends).

Usage: m29book.py <logfile> <patternfile> <mode>

`patternfile` is the suite's own extension-warning pattern file, so what counts
as a line of ours is decided in one place. `mode` picks the fixture's other
known warnings and what the two reports must say about a chapter:

  book-html  the HTML book: each chapter is its own Pandoc process, so both
             reports name the chapter their block position was counted over
  book-pdf   the PDF book: Quarto concatenates the chapters into one Pandoc
             process, so no chapter is known and neither report names one
  misuse     the single-document misuse fixture: no book, no chapter, and
             only the duplicate report -- nothing there empties its place
"""
import re
import sys

BASIS = ('Block positions are counted over the document as this filter '
         'received it, after Quarto expanded any includes and executable '
         'cells, so they can differ from the positions in your source file')

# The two reports, with every part that is free to vary named: the block
# position, the marker ordinal, and the chapter clause. Anchored whole, so a
# clause spliced anywhere but immediately after the position fails to match.
EMPTIED = re.compile(
    r'index placement marker in top-level block (?P<pos>\d+)(?P<chapter> of \S+)?'
    r' was the only thing written where it stood; the marker is removed, so '
    r'nothing you wrote remains there\. ' + re.escape(BASIS) + r'$')
DUP = re.compile(
    r'index placement marker (?P<ord>\d+) in document order \(top-level block '
    r'(?P<pos>\d+)(?P<chapter> of \S+)?\) is ignored; the index is placed at '
    r'the first marker\. ' + re.escape(BASIS) + r'$')
# The same report in a document that DECLARES its indexes (M38): which index
# the second marker repeats is the whole question there, so it is named. M29's
# subject is the chapter clause, which sits in the same place in both shapes,
# so both are matched and either counts as the duplicate report.
DUP_NAMED = re.compile(
    r'index placement marker (?P<ord>\d+) in document order \(top-level block '
    r'(?P<pos>\d+)(?P<chapter> of \S+)?\) is a second marker for the index '
    r'named "[^"]*"; that index is placed at the first marker naming it, so '
    r'this one is ignored\. ' + re.escape(BASIS) + r'$')

# The two reports a book draws for the named-index declaration M38 added to
# this fixture: a book aggregates through a store whose record format carries
# no index name, so a named mark and a named marker are both folded into the
# one index the book builds, and each is told so.
FOLD_MARK = ('index="people" on term "Turing" names a second index, and this '
             'output has one index only, so the mark is indexed in that one '
             'index instead; an HTML book aggregates its chapters through a '
             'per-chapter record carrying no index name, which is why it '
             'builds one')
# The marker shape is the one for a marker that does NOT hold the single
# index's place: last.qmd writes an unnamed marker before this one, and the
# author's own marker for the index the book builds is where it goes (M38 R2).
FOLD_MARKER = ('index="people" on an index placement marker names a second '
               'index, and this output has one index only, which goes where '
               'this document already places it, so this marker places '
               'nothing; an HTML book aggregates its chapters through a '
               'per-chapter record carrying no index name, which is why it '
               'builds one')

NESTED = ('index placement marker below the top level of the document places '
          'nothing; write it as a top-level block')

# Each mode's other known warnings, whole. A fixture that starts emitting
# something new fails here rather than being quietly absorbed.
OTHER = {
    'book-html': {
        NESTED,
        'see= on term "Epsilon" in sub/two.qmd points at "No Such Entry", '
        'which no index mark in this book indexes; a reader following the '
        'cross-reference finds no such entry, so mark that term somewhere or '
        'correct the target',
        'range="open" on term "Ranged Term" is never closed in this chapter; '
        'the mark indexes as an ordinary page number instead of opening a range',
        'range="close" on term "Ranged Term" closes a range this chapter never '
        'opens; the mark indexes as an ordinary page number instead',
        'range= is not paired across the chapters of an HTML book, so each of '
        'these marks indexes on its own rather than as one end of a range: '
        'term "Ranged Term" in one.qmd; term "Ranged Term" in sub/two.qmd. A '
        'range whose two marks are in one chapter, and a range in a PDF book, '
        'are both paired as usual',
        FOLD_MARK,
        FOLD_MARKER,
    },
    # A merged PDF book builds every index the book declares (M49), so it
    # folds nothing -- neither fold report is drawn -- and every per-index
    # judgement names the index it was made in rather than the document.
    'book-pdf': {
        NESTED,
        'see= on term "Epsilon" points at "No Such Entry", which no mark of '
        'index "main" indexes; a reader following the cross-reference finds no '
        'such entry, so mark that term in index "main" or correct the target',
    },
    'misuse': {
        NESTED,
        'index placement marker is not empty; the marker should be an empty '
        'div, and its content is kept where the marker was written',
    },
}

# The chapter each report must name, or None where no chapter is known. The
# two differ by fixture design: the emptied place sits in a subdirectory
# chapter, so the clause has a path to carry, and the duplicate sits in the
# chapter that already places the index, which is the only chapter a second
# marker can go in without moving the book's index page.
CHAPTERS = {
    'book-html': {'emptied': ' of sub/two.qmd', 'dup': ' of last.qmd'},
    'book-pdf': {'emptied': None, 'dup': None},
    'misuse': {'dup': None},
}


def main():
    if len(sys.argv) != 4:
        sys.exit('usage: m29book.py <logfile> <patternfile> <mode>')
    log, patterns, mode = sys.argv[1], sys.argv[2], sys.argv[3]
    if mode not in OTHER:
        sys.exit('M29: unknown mode %r; expected one of %s'
                 % (mode, ', '.join(sorted(OTHER))))

    with open(patterns, encoding='utf-8') as handle:
        pats = [re.compile(line.rstrip('\n')) for line in handle if line.strip()]
    if not pats:
        sys.exit('M29: %s holds no warning patterns, so every line of %s '
                 'would be judged as none of ours' % (patterns, log))

    with open(log, encoding='utf-8', errors='replace') as handle:
        # Colour codes are stripped as the M12 partition strips them: a
        # colourized log would otherwise make every report unmatchable and
        # fail for a reason that is not a defect in what the report says.
        lines = re.sub(r'\x1b\[[0-9;]*m', '', handle.read()).splitlines()

    ours = [ln for ln in lines if any(p.search(ln) for p in pats)]
    if not ours:
        sys.exit('M29: %s holds no warnings from this extension, so the '
                 'partition would pass over an empty set' % log)

    want = CHAPTERS[mode]
    seen, unpartitioned = {'emptied': [], 'dup': []}, []
    for line in ours:
        # The log prefixes each warning; the reports are matched from their
        # own first word to end of line, so the prefix is not part of either.
        text = line.split('(W) ', 1)[-1].strip()
        if text in OTHER[mode]:
            continue
        hit = EMPTIED.search(text)
        if hit is not None and hit.end() == len(text):
            seen['emptied'].append(hit)
            continue
        hit = DUP.search(text) or DUP_NAMED.search(text)
        if hit is not None and hit.end() == len(text):
            seen['dup'].append(hit)
            continue
        unpartitioned.append(text)

    problems = []
    for text in unpartitioned:
        problems.append('warning in neither partition: <<%s>>' % text)
    for name in sorted(seen):
        if name not in want and seen[name]:
            problems.append('%s report matched %d line(s) of %s, and this '
                            'fixture draws none' % (name, len(seen[name]), log))
    for name in sorted(want):
        hits = seen[name]
        if len(hits) != 1:
            problems.append('%s report matched %d line(s) of %s, want exactly 1'
                            % (name, len(hits), log))
            continue
        got = hits[0].group('chapter')
        if got != want[name]:
            problems.append('%s report names chapter clause %r, want %r'
                            % (name, got, want[name]))
    if problems:
        for problem in problems:
            print('FAIL: M29 (%s, %s): %s' % (mode, log, problem),
                  file=sys.stderr)
        sys.exit(1)

    named = [n for n in sorted(want) if want[n] is not None]
    where = ('naming %s' % ' and '.join(want[n].strip() for n in named)
             if named else 'naming no chapter')
    print('M29 (%s): %d extension warning(s) in %s partition into the fixture\'s '
          'known others and %d marker report(s), %s'
          % (mode, len(ours), log, len(want), where))


if __name__ == '__main__':
    main()
