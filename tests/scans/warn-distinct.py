# Source-set scan, run from tests/run-tests.sh as `run_scan warn-distinct`.
# It reads the whole Lua source set through tests/filtersrc.py rather than one
# named file, so a definition moving into a module stays inside its domain (M16).
#
# READS: every warn() call's message expression, comments stripped, its string
# literals joined, cut at the `:format(` that fills the template in.
# ASSERTS: the source set holds exactly the pinned number of warn() messages,
# each built from at least one literal, all mutually distinct, and none a prefix
# of another; and that four named reports are each one literal, so the whole
# message is visible at its call site.
# DOES NOT ASSERT: anything about the values a message formats in, or about text
# built outside the call — a helper's return handed in as an argument sits
# outside both the literal count and the single-literal needles, and is held by
# the rendered-log pins instead.
#
# With `--patterns` it prints the same messages as one search pattern per line,
# which is how the run's zero-warning controls tell this extension's warnings
# from any other filter's.
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()

# `--patterns` prints the messages read below as one POSIX extended regular
# expression per line, for `grep -E -f`. It runs only after every assertion in
# this file has passed, so a run can never grep a log against a message set the
# distinctness checks rejected.
PATTERNS_MODE = '--patterns' in sys.argv[1:]

LUA_ESCAPES = {'a': '\a', 'b': '\b', 'f': '\f', 'n': '\n', 'r': '\r',
               't': '\t', 'v': '\v'}


def unescaped(literal):
    """The characters a Lua literal stands for, not the source between quotes.

    `\\index` in the source is one backslash in the emitted message, and a
    pattern built from the source spelling would look for two.
    """
    out, i = [], 0
    while i < len(literal):
        c = literal[i]
        if c == '\\' and i + 1 < len(literal):
            nxt = literal[i + 1]
            out.append(LUA_ESCAPES.get(nxt, nxt))
            i += 2
        else:
            out.append(c)
            i += 1
    return ''.join(out)


# Deliberately not `re.escape`: that quotes characters (`-`, `&`, `~`, `#`,
# space) whose backslashed form is undefined in a POSIX extended regular
# expression, and the greps that read this file are the platform's, not
# Python's.
ERE_SPECIAL = set('.[]\\()*+?{}|^$')
# No space in the flag class: with one, `% o` in a sentence like "50% of
# entries" reads as a conversion and widens to `.*`, a wildcard that can
# swallow another message's text (review F6). Lua's own `string.format`
# accepts the space flag, so a message that ever needs it will fail the
# emitted-line pins rather than pass on a wildcard.
FORMAT_SPEC = re.compile(r'%[-+#0]*[0-9]*(?:\.[0-9]+)?([%a-zA-Z])')


def as_pattern(literal):
    """One message as a pattern matching the line the render actually emits.

    A message is a `:format()` template, so its placeholders stand for values
    this scan cannot know: `%d` widens to a run of digits and every other
    conversion to a wildcard, and the text around them is matched literally.
    """
    text = unescaped(literal)
    if '\n' in text:
        print(f'FAIL: M25: warning message <<{text}>> contains a newline, so a '
              f'line-oriented grep could never match the line it is emitted on',
              file=sys.stderr)
        sys.exit(1)
    out, last = [], 0
    for m in FORMAT_SPEC.finditer(text):
        out.append(quoted(text[last:m.start()]))
        conv = m.group(1)
        out.append('%' if conv == '%'
                   else '[0-9]+' if conv in 'di'
                   else '.*')
        last = m.end()
    out.append(quoted(text[last:]))
    # Anchored to the warning prefix Quarto writes, not merely contained in the
    # line: unanchored, any log line quoting a message — a traceback echoing
    # it, a diagnostic the suite itself writes — counts as a warning this
    # extension emitted (review F5).
    return WARN_PREFIX + ''.join(out)


# The prefix every Quarto warning line carries, as an extended regular
# expression. The controls this file feeds used to grep for that prefix
# anchored and alone, which is where it is known from.
WARN_PREFIX = '^\\(W\\) '


def quoted(text):
    return ''.join('\\' + c if c in ERE_SPECIAL else c for c in text)


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
    pieces, gap, last = [], [], 0
    for m in LITERAL.finditer(call):
        gap.append(call[last:m.start()])
        pieces.append(m.group(2))
        last = m.end()
    gap.append(call[last:])
    return ''.join(pieces), ''.join(gap)


code = uncommented(strip_block_comments(src))
calls = [m for m in re.finditer(r'\bwarn\(', code)
         if not code[:m.start()].rstrip().endswith('function')]
parsed = [message_at(code, m.end() - 1) for m in calls]
lits = [message for message, _gap in parsed]
# What sits BETWEEN the literals, joined. Every message here is written as
# literals concatenated with `..` and nothing else, so joining the literals is
# the emitted text. A message built around a runtime value --
# `warn("term " .. name .. " is bad")` -- joins to `term  is bad`, a pattern
# matching no line the render ever writes, and every zero-warning control
# resting on it goes quietly blind. That is the vacuous pass this scan's own
# patterns exist to close, so it is refused here rather than emitted (review
# F4). The `blank` check below does not reach it: the literals are present.
# Concatenation and grouping only. These messages are written
# `("..." .. "..."):format(...)`, so the wrapping parenthesis is inside the
# slice read here; an identifier or a call between two literals is not, and is
# what this refuses.
CONCATENATION = re.compile(r'^[\s.()]*$')
spliced = [(l, g) for l, g in parsed if not CONCATENATION.match(g)]
if spliced:
    print(f'FAIL: M02-AC5: {len(spliced)} warn() message(s) splice a value '
          f'BETWEEN their literals, so joining the literals is not the text '
          f'the render emits and a pattern built from it would match no line:',
          file=sys.stderr)
    for l, g in spliced:
        print(f'  <<{l}>> with <<{g.strip()}>> between its literals',
              file=sys.stderr)
    sys.exit(1)

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
EXPECTED = 78
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
if PATTERNS_MODE:
    # After every assertion above, never before: the run greps its logs against
    # this set to tell this extension's warnings from any other filter's, and a
    # set this scan had just rejected would be the wrong thing to ask.
    print('\n'.join(as_pattern(l) for l in lits))
    sys.exit(0)
print(f'ok   M02-AC5: all {len(lits)} filter warnings are mutually distinct, '
      f'compared as whole messages')
