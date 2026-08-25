"""Whether a term outside Latin-1 PRINTS in the typeset index (M33).

Compiling proves a mark's argument reads; typesetting proves its characters
print. For ASCII the suite already separates the two (M30's widened escaping
check); this module does it for the scripts the README recipe covers, where
the failure mode is not an escaping bug but a main font that does not carry
the script — a render that exits 0 and silently drops every glyph.

Four readings, each its own subcommand:

  marks <qmd> <level>:<term>...
      The fixture's `.index` marks carry exactly the terms named, one term per
      mark. This is the floor under `entries` below: that reading quantifies
      over a term list run-tests.sh states by hand, and without this the list
      could name terms the fixture stopped marking and go on passing. The
      level half is not read here — a mark carries no level — but the list is
      stated once and read by both, so this reading takes the same spelling.

  entries <pdf> <level>:<term>...
      Every term named has an entry line of its OWN in the printed index whose
      text, with its locators removed, equals that term, AND that line is
      printed at the stated level. Presence anywhere in the index region is
      not this: the punctuation an index prints around its own entries would
      satisfy that, and so would a parent line. Neither is text alone: a term
      the render demoted under a parent still prints its own line, and reading
      only the text would call that the entry the suite states. The entry line
      is read structurally, through tests/pdfindex.py.

  stopped <latex-log> <term>...
      The pdflatex control's reading. The LaTeX log carries the error that
      stopped the render, AND that same error names a character one of the
      terms is made of — so the rejection reported is about a term this
      fixture indexes and not about something else in the document. Read per
      error block, not over the whole log: a log carrying the signature in one
      error and an indexed character in another satisfies neither claim
      together, and reading the two independently cannot tell that apart.

  absent <pdf> <level>:<present-term> <absent-term>...
      The control reading. Every absent-term has NO entry line of its own at
      any level, AND the present-term has one at the stated level — the
      positive signal that separates "this render did not print this term"
      from "this render printed no index at all", which is the state a bare
      absence check cannot tell apart. The absent side stays level-free
      deliberately: a term printed anywhere at all is a term this render did
      print, and qualifying the absence by level would let one through. Why a
      term failed to print is not this reading's business: a font that does
      not carry the script and an engine that mangles the term both land here.

Both sides of every comparison are normalized to Unicode NFC first. This is
not politeness about equivalent spellings: xelatex prints a precomposed
character its font lacks by falling back to the character's canonical
decomposition, and a PDF text layer renormalizes in both directions — a
decomposed `e` + U+0301 in the source extracts precomposed, a precomposed
Greek U+03CC extracts decomposed. Byte equality is therefore unsatisfiable for
terms already in this fixture's scope, while NFC equality still fails on every
character actually dropped.

A `Missing character` line in the LaTeX log is NOT evidence of a dropped
glyph and is deliberately read nowhere here: the same line fires for a
character the engine goes on to print from its decomposition.

This module reads the ARTIFACT. It never produces expected values — every
term it is held to is stated by hand in run-tests.sh (the ORACLE RULE there).

Exits non-zero naming what it could not find, or what it found instead.
"""

import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pdfindex  # noqa: E402  (path set above)


# `[visible term]{.index ...}` — the class name must end at the brace or at
# whitespace, so a future `.index-something` span is not read as a mark.
MARK = re.compile(r'\[((?:\\.|[^\]\\])*)\]\{\.index[\s}]')


def nfc(text):
    return unicodedata.normalize('NFC', text)


def unescape(text):
    return re.sub(r'\\(.)', r'\1', text)


def stated(spec):
    """`<level>:<term>` -> `(level, NFC term)`.

    Split at the FIRST colon only, so a term carrying one of its own keeps it.
    A bare term is refused rather than defaulted to level 0: the level is the
    half this reading exists to check, and a caller who forgot it would other-
    wise get a green that says nothing about the level at all.

    Three refusals, each with its own message, because each is a different
    mistake in what the suite stated. A spec with no colon or nothing before
    it states no level. A level written in digits of some other script —
    `str.isdigit()` is true of them and `int()` reads them — states a level
    no caller of this module can have meant, since every level the suite
    states it writes in ASCII. An empty term states no term: `entries` would
    then look for an entry line whose text is the empty string, which no
    printed index has, and report it missing for a reason that is the spec's
    and not the render's.
    """
    level, sep, term = spec.partition(':')
    if not sep or not level:
        die(f'FAIL: M33: {spec!r} is not a <level>:<term> pair, so the level '
            f'this reading holds the term to is not stated')
    if not (level.isascii() and level.isdigit()):
        die(f'FAIL: M33: {spec!r} states its level as {level!r}, which is not '
            f'written in ASCII digits, so it is not a level this suite states '
            f'(codepoints {codepoints(level)})')
    if not term:
        die(f'FAIL: M33: {spec!r} names an empty term, so there is no term '
            f'for this reading to hold to level {int(level)}')
    return int(level), nfc(term)


def die(*lines):
    for line in lines:
        print(line, file=sys.stderr)
    sys.exit(1)


def read_entries(pdf):
    """The printed index's entry lines, or a died-on message."""
    try:
        entries = pdfindex.read(pdf)
    except LookupError as exc:
        die(f'FAIL: M33: {exc} — the render produced no printed index, so '
            f'every term below would be reported missing for the wrong '
            f'reason')
    if not entries:
        die(f'FAIL: M33: the index in {pdf} holds no entry lines, so the '
            f'search below would report every term missing')
    return entries


def cmd_marks(qmd, expected):
    source = open(qmd, encoding='utf-8').read()
    found = [nfc(unescape(m)) for m in MARK.findall(source)]
    want = [term for _level, term in (stated(spec) for spec in expected)]
    problems = []
    if len(found) != len(want):
        problems.append(f'  {qmd} carries {len(found)} index mark(s); the '
                        f'suite states {len(want)} term(s)')
    if sorted(found) != sorted(want):
        for term in sorted(set(want) - set(found)):
            problems.append(f'  stated but not marked: {term!r}')
        for term in sorted(set(found) - set(want)):
            problems.append(f'  marked but not stated: {term!r}')
    if problems:
        die('FAIL: M33: the term list the suite states for this fixture is '
            'not what the fixture marks:', *problems)
    print(f'ok   M33: {qmd} marks exactly the {len(want)} terms the suite '
          f'states, one per mark')


def levelled(pdf):
    """The printed entry lines as `(level, term)`, with the level trustworthy.

    `pdfindex` reads a level from where a line's left edge sits in its column,
    which it can only do when the column holds a top-level entry to measure
    against. A column of nothing but sub-entries would have its own edge read
    as level 0 and every entry in it come back a level too shallow, so the
    module's own assertion of that assumption is run here rather than trusted:
    without it a level reading could be uniformly wrong and still agree with
    itself.
    """
    entries = read_entries(pdf)
    if not pdfindex.columns_carry_top_level(entries):
        die(f'FAIL: M33: a column of the printed index in {pdf} holds no '
            f'top-level entry, so pdfindex has no top-level left edge to '
            f'measure that column against and every level it reports there '
            f'may be a level too shallow')
    return [(e.level, nfc(e.term)) for e in entries]


def cmd_entries(pdf, expected):
    if not expected:
        die('FAIL: M33: entries was given no terms to look for, so it would '
            'pass over any index at all')
    want = [stated(spec) for spec in expected]
    printed = levelled(pdf)
    texts = [term for _level, term in printed]
    problems = []
    for level, term in want:
        if term not in texts:
            problems.append(f'  {term!r} has no entry line of its own '
                            f'(codepoints {codepoints(term)})')
        elif (level, term) not in printed:
            at = sorted({lv for lv, t in printed if t == term})
            problems.append(f'  {term!r} prints at level {at}, not at '
                            f'level {level}, the level the suite states for '
                            f'it')
    if problems:
        die(f'FAIL: M33: {len(problems)} of {len(want)} term(s) do not print '
            f'as their own entry at the stated level in the typeset index of '
            f'{pdf}:',
            *problems,
            f'  the index printed these entry lines: {printed}')
    print(f'ok   M33: all {len(want)} terms print as their own entry at the '
          f'level the suite states in the typeset index of {pdf}')


STOP_SIGNATURE = 'not set up for use with LaTeX'

# TeX opens an error report with `! ` in column one and closes it with the
# echoed source line, `l.<n>`. Everything between belongs to that one error,
# including the indented continuation line inputenc/LaTeX writes its
# explanation on — which is where STOP_SIGNATURE sits, one line below the
# `Unicode character` line it is about.
CONTEXT_LINE = re.compile(r'^l\.\d')


def error_blocks(log):
    """The log's `! ...` error reports, each as one string.

    A block runs from its `! ` line to the echoed source line that closes it,
    or to the next `! ` line where no source line intervenes; a `! ` line the
    log never closes — neither a source line nor a later `! ` line before the
    end of the file — opens no block at all. Text outside any error report —
    the font and package chatter that fills most of a LaTeX log, and the tail
    following an unclosed `! ` line — belongs to no block and is deliberately
    unreachable from here. Closing an unclosed final report at EOF would make
    that tail readable as part of it, which is a report the log does not
    carry.

    Only `! ` — the bang with its space — opens a report, which is the shape
    LaTeX's own errors take and the only shape the rejection this module reads
    is written in. pdfTeX writes some of its errors as `!pdfTeX error:`, with
    no space; run against such a line this returns no block, and nothing here
    or in the readings above it says anything about that class of error.
    """
    blocks, current = [], None
    for line in log.splitlines():
        if line.startswith('! '):
            if current is not None:
                blocks.append('\n'.join(current))
            current = [line]
        elif current is not None:
            if CONTEXT_LINE.match(line):
                blocks.append('\n'.join(current))
                current = None
            else:
                current.append(line)
    return blocks


def cmd_stopped(log_path, terms):
    log = open(log_path, encoding='utf-8', errors='replace').read()
    if STOP_SIGNATURE not in log:
        die(f'FAIL: M33: {log_path} does not carry {STOP_SIGNATURE!r}, so '
            f'whatever stopped that render is not the rejection README '
            f'teaches a reader to recognize')
    wanted = {c for term in terms for c in term if ord(c) > 0x7F}
    anywhere = sorted(c for c in wanted if f'Unicode character {c} ' in log)
    if not anywhere:
        die(f'FAIL: M33: no error in {log_path} names a character the terms '
            f'{list(terms)} are made of, so the rejection it reports is not '
            f'about a term this fixture indexes')
    blocks = error_blocks(log)
    named = sorted({c for block in blocks if STOP_SIGNATURE in block
                    for c in wanted if f'Unicode character {c} ' in block})
    if not named:
        die(f'FAIL: M33: {log_path} carries {STOP_SIGNATURE!r} and names '
            f'{", ".join(f"U+{ord(c):04X}" for c in anywhere)}, but never in '
            f'one error: the rejection that stopped this render and the '
            f'character this fixture indexes are not reported together — '
            f'separate error reports, or text belonging to no error report at '
            f'all — and the two read apart say nothing about each other '
            f'({len(blocks)} error report(s) in the log)')
    print(f'ok   M33: {log_path} stops on '
          f'{", ".join(f"U+{ord(c):04X}" for c in named)}, which the terms '
          f'named carry, in one error report')


def cmd_absent(pdf, present_spec, absent):
    level, present = stated(present_spec)
    printed = levelled(pdf)
    texts = [term for _lv, term in printed]
    if present not in texts:
        die(f'FAIL: M33: the control render {pdf} prints no entry line for '
            f'{present!r}, so its index did not print at all and the absences '
            f'below would say nothing about the font:',
            f'  the index printed these entry lines: {printed}')
    if (level, present) not in printed:
        at = sorted({lv for lv, t in printed if t == present})
        die(f'FAIL: M33: the control render {pdf} prints {present!r} at '
            f'level {at}, not at level {level}, the level the control states '
            f'for its present-term, so this control is not reading the index '
            f'it is stated against:',
            f'  the index printed these entry lines: {printed}')
    unexpected = [term for term in absent if nfc(term) in texts]
    if unexpected:
        die(f'FAIL: M33: the control render {pdf} printed an entry line for '
            f'{len(unexpected)} term(s) it is held not to print:',
            *[f'  {term!r} printed after all' for term in unexpected])
    print(f'ok   M33: {pdf} prints {present!r} at level {level} and none of '
          f'the {len(absent)} term(s) it is held not to print')


def codepoints(term):
    return ' '.join(f'U+{ord(c):04X}' for c in term)


def main(argv):
    if len(argv) < 3:
        die(__doc__.strip())
    mode, target, rest = argv[1], argv[2], argv[3:]
    if mode == 'marks':
        cmd_marks(target, rest)
    elif mode == 'entries':
        cmd_entries(target, rest)
    elif mode == 'stopped':
        if not rest:
            die('FAIL: M33: stopped needs at least one term')
        cmd_stopped(target, rest)
    elif mode == 'absent':
        if len(rest) < 2:
            die('FAIL: M33: absent needs a present-term and at least one '
                'absent-term')
        cmd_absent(target, rest[0], rest[1:])
    else:
        die(f'FAIL: M33: unknown mode {mode!r}')


if __name__ == '__main__':
    main(sys.argv)
