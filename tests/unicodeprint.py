"""Whether a term outside Latin-1 PRINTS in the typeset index (M33).

Compiling proves a mark's argument reads; typesetting proves its characters
print. For ASCII the suite already separates the two (M30's widened escaping
check); this module does it for the scripts the README recipe covers, where
the failure mode is not an escaping bug but a main font that does not carry
the script — a render that exits 0 and silently drops every glyph.

Four readings, each its own subcommand:

  marks <qmd> <term>...
      The fixture's `.index` marks carry exactly the terms named, one term per
      mark. This is the floor under `entries` below: that reading quantifies
      over a term list run-tests.sh states by hand, and without this the list
      could name terms the fixture stopped marking and go on passing.

  entries <pdf> <term>...
      Every term named has an entry line of its OWN in the printed index whose
      text, with its locators removed, equals that term. Presence anywhere in
      the index region is not this: the punctuation an index prints around its
      own entries would satisfy that, and so would a parent line. The entry
      line is read structurally, through tests/pdfindex.py.

  stopped <latex-log> <term>...
      The pdflatex control's reading. The LaTeX log carries the error that
      stopped the render, AND that error names a character one of the terms is
      made of — so the rejection reported is about a term this fixture indexes
      and not about something else in the document.

  absent <pdf> <present-term> <absent-term>...
      The control reading. Every absent-term has NO entry line, AND the
      present-term does — the positive signal that separates "the font dropped
      this script" from "this render printed no index at all", which is the
      state a bare absence check cannot tell apart.

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

import re
import sys
import unicodedata

sys.path.insert(0, 'tests')
import pdfindex  # noqa: E402  (path set above)


# `[visible term]{.index ...}` — the class name must end at the brace or at
# whitespace, so a future `.index-something` span is not read as a mark.
MARK = re.compile(r'\[((?:\\.|[^\]\\])*)\]\{\.index[\s}]')


def nfc(text):
    return unicodedata.normalize('NFC', text)


def unescape(text):
    return re.sub(r'\\(.)', r'\1', text)


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
    want = [nfc(t) for t in expected]
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


def cmd_entries(pdf, expected):
    entries = read_entries(pdf)
    printed = [nfc(e.term) for e in entries]
    missing = []
    for term in expected:
        if nfc(term) not in printed:
            missing.append(f'  {term!r} has no entry line of its own '
                           f'(codepoints {codepoints(term)})')
    if missing:
        die(f'FAIL: M33: {len(missing)} of {len(expected)} term(s) do not '
            f'print as their own entry in the typeset index of {pdf}:',
            *missing,
            f'  the index printed these entry lines: {printed}')
    print(f'ok   M33: all {len(expected)} terms print as their own entry in '
          f'the typeset index of {pdf}')


STOP_SIGNATURE = 'not set up for use with LaTeX'


def cmd_stopped(log_path, terms):
    log = open(log_path, encoding='utf-8', errors='replace').read()
    if STOP_SIGNATURE not in log:
        die(f'FAIL: M33: {log_path} does not carry {STOP_SIGNATURE!r}, so '
            f'whatever stopped that render is not the rejection README '
            f'teaches a reader to recognize')
    wanted = {c for term in terms for c in term if ord(c) > 0x7F}
    named = sorted(c for c in wanted if f'Unicode character {c} ' in log)
    if not named:
        die(f'FAIL: M33: the error in {log_path} names no character the '
            f'terms {list(terms)} are made of, so the rejection it reports '
            f'is not about a term this fixture indexes')
    print(f'ok   M33: {log_path} stops on '
          f'{", ".join(f"U+{ord(c):04X}" for c in named)}, which the terms '
          f'named carry')


def cmd_absent(pdf, present, absent):
    entries = read_entries(pdf)
    printed = [nfc(e.term) for e in entries]
    if nfc(present) not in printed:
        die(f'FAIL: M33: the control render {pdf} prints no entry line for '
            f'{present!r}, so its index did not print at all and the absences '
            f'below would say nothing about the font:',
            f'  the index printed these entry lines: {printed}')
    unexpected = [term for term in absent if nfc(term) in printed]
    if unexpected:
        die(f'FAIL: M33: the control render {pdf} printed an entry line for '
            f'{len(unexpected)} term(s) its font does not cover:',
            *[f'  {term!r} printed after all' for term in unexpected])
    print(f'ok   M33: {pdf} prints {present!r} and none of the '
          f'{len(absent)} term(s) its font does not cover')


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
