# Source-set scan, run from tests/run-tests.sh as `run_scan m15-joined-messages`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16).
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
unseen = [r for r in REPLACEMENT
          if not any(r in message for message in messages)]
if unseen:
    print(f'FAIL: M15-AC5: {len(unseen)} of the {len(REPLACEMENT)} shapes of '
          f'the replacement report are not among the {len(messages)} joined '
          f'warn() messages this scanner read, so it is reading the file '
          f'wrongly:', file=sys.stderr)
    for r in unseen:
        print(f'  <<{r}>>', file=sys.stderr)
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
      f'both shapes of the replacement report are among them')
