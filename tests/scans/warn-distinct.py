# Source-set scan, run from tests/run-tests.sh as `run_scan warn-distinct`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()


# Line comments removed before anything is read: `\bwarn\(` otherwise matches
# the function's own definition and every mention of `warn()` in a comment,
# and a comment containing a quote would contribute a phantom literal. Quotes
# are tracked while stripping, since a message may itself contain `--`.
def strip_block_comments(text):
    """Remove Lua long-bracket comments, --[[ ... ]] and --[==[ ... ]==].

    A per-line scan cannot see these: a `warn(` written inside one is real
    source to the line scanner and a phantom warning to everything downstream,
    which would break the pinned count with a message blaming a warning change
    (review F6). Newlines are preserved so nothing else shifts line for line.
    """
    out, i = [], 0
    while i < len(text):
        m = re.compile(r'--\[(=*)\[').search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i:m.start()])
        close = text.find(']' + m.group(1) + ']', m.end())
        if close == -1:
            i = len(text)
            break
        out.append('\n' * text.count('\n', m.start(), close))
        i = close + len(m.group(1)) + 2
    return ''.join(out)


def uncommented(text):
    out = []
    for line in text.split('\n'):
        quote, i = None, 0
        while i < len(line):
            c = line[i]
            if quote:
                if c == '\\':
                    i += 1
                elif c == quote:
                    quote = None
            elif c in '"\'':
                quote = c
            elif c == '-' and line[i:i + 2] == '--':
                line = line[:i]
                break
            i += 1
        out.append(line)
    return '\n'.join(out)


# Lua string literals take either quote, and a message containing a double
# quote is written with single quotes, so both styles are read.
LITERAL = re.compile(r"""(["'])((?:[^\\]|\\.)*?)\1""")


def message_at(text, open_paren):
    """Join every string literal in one warn() call's message expression.

    The WHOLE message, not its leading literal: most of these messages are
    written as several literals joined with `..` across source lines, and
    reading only the first compares warnings by a prefix while reporting on
    the message -- the way a distinctness scan goes blind (M10). A revert
    probe proved a pinned literal count cannot see this (M13 T6): splitting a
    message across `..` leaves both the literal count and the call count
    unchanged. Joining the literals is what can.

    The expression ends at the call's own closing paren, or at the `:format(`
    that fills it in -- the arguments to `format` are values, not message
    text, and must not be swept in.
    """
    depth, i, quote, cut = 1, open_paren + 1, None, -1
    while i < len(text):
        c = text[i]
        if quote:
            if c == '\\':
                i += 1
            elif c == quote:
                quote = None
        elif c in '"\'':
            quote = c
        elif c == '(':
            # Found OUTSIDE a literal, which is the whole point: a message
            # whose own text contains `:format(` would otherwise be cut there,
            # silently comparing a distinct warning on a prefix — the exact
            # blindness this scan exists to remove (review F7).
            if cut == -1 and text[i - 7:i + 1] == ':format(':
                cut = i - 7
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                break
        i += 1
    call = text[open_paren + 1:cut if cut != -1 else i]
    return ''.join(m.group(2) for m in LITERAL.finditer(call))


code = uncommented(strip_block_comments(src))
calls = [m for m in re.finditer(r'\bwarn\(', code)
         if not code[:m.start()].rstrip().endswith('function')]
lits = [message_at(code, m.end() - 1) for m in calls]

# A call whose message is not built from literals at all -- a variable, a
# helper's return -- is text this check never sees, so it is named rather than
# silently skipped.
blank = [i for i, l in enumerate(lits) if not l]
if blank:
    print(f'FAIL: M02-AC5: {len(blank)} warn() call(s) pass no string literal, '
          f'so their message text is outside this check', file=sys.stderr)
    sys.exit(1)
# An exact count, not a floor: a floor passes while a warning quietly stops
# being read. This number changes when a warning is added or removed.
EXPECTED = 42
if len(lits) != EXPECTED:
    print(f'FAIL: M02-AC5: found {len(lits)} warn() messages, expected '
          f'{EXPECTED}. Either a warning was added or removed without updating '
          f'this count, or this scan stopped reading the filter — a renamed '
          f'helper, a construct the comment stripper mishandles, or a call the '
          f'definition filter wrongly excluded. What it did read:',
          file=sys.stderr)
    for l in lits:
        print(f'  <<{l}>>', file=sys.stderr)
    sys.exit(1)
# AC4's second clause, which the join above cannot evidence: the two reports
# M13 rewrote — and the one M14 added — are each ONE literal. Asserted on the calls themselves, since a
# joined message reads identically either way. Keeping them whole is also why
# those two lines run past the file's usual width (review F9, F18).
SINGLE_LITERAL = (
    'empty index level in %s at %s;',
    # Reworded at M19-AC3; the needle moves with the message, and the
    # single-literal requirement it stands for does not.
    'sort= on %s writes %d levels against %s;',
    # M14-AC6: the dangling-target report, for the same reason — a message
    # split across `..` is read by this scan only to its first fragment, and a
    # scan that compares warnings on a prefix is the blindness M10 hit.
    '%s= on %s points at "%s", which no index mark in this %s indexes;',
    # M18-AC5: the fold-rewritten-target report, for the same reason. It is
    # also the message whose own subject is a derived string, so a scan that
    # read it to its first fragment would not see which path it names.
    # M19-AC2 spliced the depth in as a `%s` so the message can name the
    # written count too where it differs; still one literal.
    '%s= on %s names a path %s; the back-end stores %d,',
)
for needle in SINGLE_LITERAL:
    owner = [m for m in re.finditer(r'\bwarn\(', code)
             if needle in code[m.start():m.start() + 400]]
    if len(owner) != 1:
        print(f'FAIL: M02-AC5: expected exactly one warn() call carrying '
              f'<<{needle}>>, found {len(owner)}', file=sys.stderr)
        sys.exit(1)
    end = code.index(')', code.index(needle, owner[0].start()))
    pieces = LITERAL.findall(code[owner[0].end():end])
    if len(pieces) != 1:
        print(f'FAIL: M02-AC5: the report <<{needle}>> is built from '
              f'{len(pieces)} literals; M13-AC4 and M14-AC6 require one, so '
              f'the whole message is visible at its call site', file=sys.stderr)
        sys.exit(1)

dupes = {l for l in lits if lits.count(l) > 1}
if dupes:
    print('FAIL: M02-AC5: warning messages are not distinct:', file=sys.stderr)
    for d in sorted(dupes):
        print(f'  <<{d}>>', file=sys.stderr)
    sys.exit(1)
# Neither may be a prefix of another, or a grep for the shorter also matches
# the longer and the two stop being separable.
for a in lits:
    for b in lits:
        if a is not b and b.startswith(a):
            print(f'FAIL: M02-AC5: warning <<{a}>> is a prefix of <<{b}>>',
                  file=sys.stderr)
            sys.exit(1)
print(f'ok   M02-AC5: all {len(lits)} filter warnings are mutually distinct, '
      f'compared as whole messages')
