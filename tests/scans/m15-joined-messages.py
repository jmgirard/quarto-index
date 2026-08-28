# Source-set scan, run from tests/run-tests.sh as `run_scan m15-joined-messages`.
# It reads the whole Lua source set through tests/filtersrc.py rather than one
# named file, so a definition moving into a module stays inside its domain (M16).
#
# READS: every warn() call's message text, with the fragments a message is
# concatenated from joined back together.
# ASSERTS: each of the two shapes of the replacement report is carried by
# exactly two messages — the plain one and the one naming the index the
# judgement was made in, which M49 added when a LaTeX render stopped folding
# every declared index into one — and no message tells an author a render can
# fail from rival encapsulations, the claim M15 made untrue.
# DOES NOT ASSERT: that either report ever fires, or that its numbers are right.
# The rendered-log pins are what say that. Text built outside the warn() call —
# a helper's return handed in as a format argument — is outside what it reads.
import re, sys
sys.path.insert(0, 'tests')
import filtersrc

GONE = 'the index tool rejects the pair and the render fails'
# The replacement, in both its shapes, each as a template with its one
# substitution removed. Present as joined messages, which is also this
# scanner's passing control: a scanner that found nothing would satisfy the
# absence check for free. Both, because a scanner that found only one would
# pass while the other shape's message went unread.
REPLACEMENT = (
    ('carries both a plain locator and a cross-reference; they are printed as '
     'one entry with its page numbers and its cross-reference together, so '
     'check that is the entry you meant'),
    ('carries two different cross-references; they are printed as one entry '
     'carrying both targets and, since neither mark contributes one, no page '
     'numbers at all, so check that is the entry you meant'),
)
# The two heads each shape is written under (M49). A judgement about a mark is
# made inside ONE index, and where a document declares more than one the report
# says which — as one literal per shape rather than a clause spliced in, so the
# plain form is not a prefix of the scoped one and a grep for the shorter
# cannot match both. Both heads are required, so a repair that dropped the
# scoped form, or that made one message serve both, fails here.
HEADS = ('index entry %s ', 'index entry %s in %s ')

src = filtersrc.text()

# One Lua string literal: '...' or "...", with backslash escapes. The same
# pattern this suite already uses to read the filter's literals, and one
# alternation rather than two, so which quote a literal happens to use cannot
# change what is read out of it — a two-branch pattern silently returns the
# empty string for whichever branch did not match. Long-bracket literals
# ([[...]]) would need their own pattern; the filter writes none, and the
# controls below are what would notice if that changed.
LITERAL = re.compile(r"""(["'])((?:[^\\]|\\.)*?)\1""")


def calls(text):
    """Every warn(...) CALL's argument list, parenthesis-balanced.

    `\bwarn\(` alone also matches `local function warn(msg)`, whose argument
    list holds no literal — an empty message that inflates the count and
    weakens the "read nothing at all" control below.
    """
    for m in re.finditer(r'(?<!function )\bwarn\(', text):
        depth, i = 1, m.end()
        while i < len(text) and depth:
            if text[i] == '(':
                depth += 1
            elif text[i] == ')':
                depth -= 1
            i += 1
        yield text[m.end():i - 1]


messages = []
for argument in calls(src):
    joined = ''.join(body for _quote, body in LITERAL.findall(argument))
    messages.append(joined)

if not messages:
    print('FAIL: M15-AC5: no warn() call was read out of the filter, so the '
          'absence below is the scanner finding nothing, not the filter '
          'saying nothing', file=sys.stderr)
    sys.exit(1)
# Exactly one message per shape and HEAD, not merely one somewhere: a shape
# found twice under one head is a report the filter draws twice, and a presence
# test reads that as the passing control it is not. Matched as head PLUS shape
# and not by prefix, because the plain head is a prefix of the scoped one --
# read by prefix, one message would answer for both and a dropped scoped form
# would go unnoticed.
wrong = []
for r in REPLACEMENT:
    carrying = [message for message in messages if r in message]
    for head in HEADS:
        n = sum(1 for message in carrying if message == head + r)
        if n != 1:
            wrong.append((head + r, n))
    if len(carrying) != len(HEADS):
        wrong.append((r, len(carrying)))
if wrong:
    print(f'FAIL: M15-AC5: a shape of the replacement report is not carried by '
          f'exactly one of the {len(messages)} joined warn() messages this '
          f'scanner read under each of its {len(HEADS)} heads, so either the '
          f'filter draws one twice, or a head is missing, or this scanner is '
          f'reading the file wrongly:', file=sys.stderr)
    for r, n in wrong:
        print(f'  {n} message(s) carry <<{r}>>', file=sys.stderr)
    sys.exit(1)
guilty = [message for message in messages if GONE in message]
if guilty:
    print(f'FAIL: M15-AC5: {len(guilty)} joined warn() message(s) still tell '
          f'an author <<{GONE}>>, which the emission no longer risks:',
          file=sys.stderr)
    for message in guilty:
        print(f'  <<{message}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   M15-AC5: none of the {len(messages)} joined warn() messages in '
      f'the filter claims a render can fail from rival encapsulations, and '
      f'each of the {len(REPLACEMENT)} shapes of the replacement report is '
      f'carried by exactly one of them under each of its {len(HEADS)} heads '
      f'-- the plain one and the one naming the index the judgement was made '
      f'in')
