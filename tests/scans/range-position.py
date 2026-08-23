# Source-set scan, run from tests/run-tests.sh as `run_scan range-position`.
# Reads the extension's whole Lua source set through tests/filtersrc.py,
# never one named file, so a definition moving into a module stays inside
# the domain this scan sweeps (M16). The two files M23-AC2 names,
# `modules/marks.lua` and `modules/passes.lua`, are where these definitions
# sit today; the set this reads is their superset, and a name that leaves it
# is an absence this scan fails on rather than passes over.
#
# WHAT IT HOLDS. A range mark's verdict is planned and read by the mark's
# DOCUMENT POSITION, not by the entry key derived from its text:
#   * `finish_ranges` builds the store and `next_range` reads one verdict out
#     of it, and neither takes an entry key;
#   * both traversals take a position through ONE function, `range_position`,
#     which is the only thing in the source set that advances the counter — so
#     the guard deciding which spans hold positions is one piece of code and
#     the two passes cannot come to disagree about it.
# The per-key queues it replaces are held absent by name, so a repair that
# left one behind beside the new store would not pass.
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()

AC = 'M23-AC2'
bad = []


def count(pattern, flags=re.MULTILINE):
    return len(re.findall(pattern, src, flags))


def pin(what, pattern, want, why):
    """Fail unless `pattern` occurs exactly `want` times in the source set.

    An exact count rather than a floor, and stated per pin: a pinned name that
    has been renamed away occurs zero times, which is the absence M23-AC2 asks
    this scan to fail on; a second occurrence is a duplicate definition or a
    second call site, either of which breaks what the pin is about.
    """
    got = count(pattern)
    if got != want:
        bad.append('  %s: found %d occurrence(s) of /%s/, expected %d — %s'
                   % (what, got, pattern, want, why))


# --- the store's two functions, pinned by name and by their parameter lists.
pin('finish_ranges', r'^local function finish_ranges\(\)$', 1,
    'the function that builds the verdict store must exist under this name '
    'and take no argument at all, an entry key least of all')
pin('next_range', r'^local function next_range\(pos\)$', 1,
    'the function that reads one verdict must exist under this name and take '
    'a position; a parameter named anything else is the key argument M23-AC2 '
    'is about, back on the reading path')
pin('next_range call site', r'qi_marks\.next_range\(range_pos\)', 1,
    'the emitting pass must read its verdict at the position it took at the '
    'guard, and at nothing else')

# --- the one guard, and the one counter it advances.
pin('range_position', r'^local function range_position\(span\)$', 1,
    'both traversals take a position through this one function, so the guard '
    'is one piece of code rather than one condition written twice')
pin('range_position call sites', r'qi_marks\.range_position\(span\)', 2,
    'exactly two — the collecting pass and the emitting pass; a third caller '
    'would number a span neither of them sees, and a second call in one pass '
    'would slide that pass off the other by one')
pin('the counter is advanced once', r'range_at = range_at \+ 1', 1,
    'the only advance in the source set is the one inside range_position; a '
    'second one is a traversal numbering marks on a condition of its own')
pin('the counter is declared', r'^local range_at = 0$', 1, 'the counter itself')
pin('the counter is reset', r'^  range_at = 0$', 1,
    'reset in finish_ranges between the two traversals, so both number from '
    'the same origin')

# --- the store is indexed by position on both sides.
pin('the store is written by position', r'range_verdicts\[item\.pos\] =', 1,
    'finish_ranges files each verdict under the position its mark was given')
pin('the store is read by position', r'range_verdicts\[pos\]', 1,
    'next_range reads it back at a position and nowhere else')
pin('plan_range takes the position first',
    r'^local function plan_range\(pos, ', 1,
    'the collecting pass hands the mark its position; the entry key beside it '
    'is what an opening pairs with its closing by, which is a different job')

# --- and the per-key queues are gone, not merely bypassed.
for gone in ('range_plan', 'range_cursor'):
    pin('the %s queue is gone' % gone, r'\b%s\b' % gone, 0,
        'a per-key verdict queue left in the source beside the position store '
        'is a second answer to the question the store now answers')

# --- the guard's own two clauses, read out of range_position's own body: a
#     guard that stopped testing one of them would number a different set of
#     spans in BOTH passes, which no call-site count can see.
m = re.search(r'^local function range_position\(span\)\n(.*?)^end$',
              src, re.MULTILINE | re.DOTALL)
if not m:
    bad.append('  range_position: no body found to read the guard out of')
else:
    body = m.group(1)
    for clause, why in (
            (r'span\.classes:includes\(qi_core\.INDEX_CLASS\)',
             'the index class, so a span that is no mark at all takes no position'),
            (r'span\.attributes\[qi_core\.RANGE_ATTR\] == nil',
             'the range attribute, so only a range mark takes one')):
        if not re.search(clause, body):
            bad.append('  range_position: its body does not test /%s/ — %s'
                       % (clause, why))

if bad:
    print('FAIL: %s: a range verdict is no longer planned and read by the '
          'mark\'s document position:' % AC, file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   %s: the verdict store is keyed on document position — finish_ranges '
      'and next_range take no entry key, both traversals take a position '
      'through the one guard that advances the one counter, and the per-key '
      'queues are gone from the source set' % AC)
