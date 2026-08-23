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
#     the two passes cannot come to disagree about it;
#   * that position reaches the store on both sides: the collecting traversal
#     hands the guard's own position to `plan_range`, and the emitting one
#     reads at the guard's own position.
# The per-key queues it replaces are held absent by name, so a repair that
# left one behind beside the new store would not pass.
#
# WHERE, NOT ONLY HOW MANY. Three of the pins below read a named function's
# own body rather than the concatenated source set, because a count taken over
# the whole set is satisfied by source that has moved: review round 1 built
# three trees that every count-only pin passed and that mis-assign or lose
# every verdict — the reset made `plan_range`'s first statement, the
# collecting call moved into an earlier traversal, and `plan_range` handed a
# constant. A pin about where a statement sits reads the body it must sit in.
import re, sys
sys.path.insert(0, 'tests')
import filtersrc
src = filtersrc.text()

AC = 'M23-AC2'
bad = []


def count(pattern, where=None, flags=re.MULTILINE):
    return len(re.findall(pattern, src if where is None else where, flags))


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


def body(name):
    """The body of `local function <name>(...)`, or None with a finding logged.

    Bounded by the first `end` written at column 0, which in this source set is
    the function's own — a nested block's `end` is indented. None is returned
    rather than an empty string so a caller cannot mistake "no such function"
    for "a body holding none of what was asked", which would pass every pin
    stated as an absence.
    """
    m = re.search(r'^local function %s\([^\n]*\)\n(.*?)^end$' % re.escape(name),
                  src, re.MULTILINE | re.DOTALL)
    if m is None:
        bad.append('  %s: no `local function %s(...)` body found in the source '
                   'set, so every pin stated over it reads nothing' %
                   (name, name))
        return None
    return m.group(1)


def pin_in(where, pattern, want, why):
    """Fail unless `pattern` occurs exactly `want` times inside `where`'s body.

    The pin M23-AC2's count-only ancestors did not carry: a statement that is
    present in the source set but sits in another function is a different
    program, and the count cannot tell the two apart.
    """
    text = body(where)
    if text is None:
        return
    got = count(pattern, text)
    if got != want:
        bad.append('  %s: found %d occurrence(s) of /%s/ inside the body of '
                   '`%s`, expected %d — %s'
                   % (where, got, pattern, where, want, why))


# --- the store's two functions, pinned by name and by their parameter lists.
pin('finish_ranges', r'^local function finish_ranges\(\)$', 1,
    'the function that builds the verdict store must exist under this name '
    'and take no argument at all, an entry key least of all')
pin('next_range', r'^local function next_range\(pos\)$', 1,
    'the function that reads one verdict must exist under this name and take '
    'a position; a parameter named anything else is the key argument M23-AC2 '
    'is about, back on the reading path')

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
pin('the counter is returned to the origin once', r'\brange_at = 0\b', 2,
    'twice in the whole source set and no more: the declaration above, and '
    'the single reset the next pin puts inside finish_ranges. A third would '
    'be some other code deciding where a document starts counting')
pin_in('finish_ranges', r'\brange_at = 0\b', 1,
    'the reset sits HERE, between the two traversals, so both number from the '
    'same origin. Made `plan_range`\'s first statement instead — which the '
    'source-set count above cannot tell from this — every mark plans at '
    'position 1 while the emitting pass numbers 1, 2, 3, and every range but '
    'the first loses its verdict')

# --- which traversals hold the two call sites, and in which order they run.
pin_in('CollectRanges', r'^  local pos = qi_marks\.range_position\(span\)$', 1,
    'the collecting traversal takes its own position, at the guard and before '
    'it derives anything. Taken in an EARLIER traversal instead, the source '
    'set still holds two calls while this pass files verdicts at positions '
    'the emitting pass never asks for')
pin_in('Span', r'^  local range_pos = qi_marks\.range_position\(span\)$', 1,
    'the emitting traversal takes its own position at the same guard, so the '
    'two number the same spans')
order = [(m.group(1), m.start()) for m in re.finditer(
    r'^  \{ Span = qi_passes\.(CollectRanges|Span)[,\s]', src, re.MULTILINE)]
if [name for name, _ in order] != ['CollectRanges', 'Span']:
    bad.append('  pass order: the filter registers %s, and M23-AC2 needs the '
               'verdict-planning traversal (CollectRanges) registered before '
               'the emitting one (Span) and each registered once — a store '
               'built after it is read hands every mark nil'
               % (' then '.join(name for name, _ in order) or 'neither pass'))
pin('FinishRanges runs with the collecting traversal',
    r'\{ Span = qi_passes\.CollectRanges, Pandoc = qi_passes\.FinishRanges \}', 1,
    'the store is built and the counter returned to the origin at the end of '
    'the traversal that plans, which is what puts both between the numbering '
    'and the reading')

# --- the store is indexed by position on both sides.
pin('the store is written by position', r'range_verdicts\[item\.pos\] =', 1,
    'finish_ranges files each verdict under the position its mark was given')
pin('the store is read by position', r'range_verdicts\[pos\]', 1,
    'next_range reads it back at a position and nowhere else')
pin('plan_range takes the position first',
    r'^local function plan_range\(pos, ', 1,
    'the collecting pass hands the mark its position; the entry key beside it '
    'is what an opening pairs with its closing by, which is a different job')
pin('plan_range call site', r'qi_marks\.plan_range\(', 1,
    'one caller, the collecting traversal; a second would file verdicts at '
    'positions numbered by something else')
pin_in('CollectRanges', r'qi_marks\.plan_range\(pos, ', 1,
    'the position the guard gave this mark is what reaches the store. Handed '
    'a constant or a different variable instead — which the signature pin '
    'above cannot see, since it reads the definition and not the call — every '
    'verdict is filed at one position and the emitting pass reads nil at the '
    'rest')
pin('next_range call site', r'qi_marks\.next_range\(', 1,
    'one caller, the emitting traversal; a second would read the store at a '
    'position numbered by something else')
pin_in('Span', r'qi_marks\.next_range\(range_pos\)', 1,
    'the emitting pass reads its verdict at the position it took at the '
    'guard, and at nothing else')

# --- and the per-key queues are gone, not merely bypassed.
for gone in ('range_plan', 'range_cursor'):
    pin('the %s queue is gone' % gone, r'\b%s\b' % gone, 0,
        'a per-key verdict queue left in the source beside the position store '
        'is a second answer to the question the store now answers')

# --- the guard's own two clauses, read out of range_position's own body: a
#     guard that stopped testing one of them would number a different set of
#     spans in BOTH passes, which no call-site count can see.
guard = body('range_position')
if guard is not None:
    for clause, why in (
            (r'span\.classes:includes\(qi_core\.INDEX_CLASS\)',
             'the index class, so a span that is no mark at all takes no position'),
            (r'span\.attributes\[qi_core\.RANGE_ATTR\] == nil',
             'the range attribute, so only a range mark takes one')):
        if not re.search(clause, guard):
            bad.append('  range_position: its body does not test /%s/ — %s'
                       % (clause, why))

if bad:
    print('FAIL: %s: a range verdict is no longer planned and read by the '
          'mark\'s document position:' % AC, file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   %s: the verdict store is keyed on document position — finish_ranges '
      'and next_range take no entry key, the collecting traversal hands '
      'plan_range the position the one guard gave the mark and the emitting '
      'traversal reads at its own, that guard is the only advance of the one '
      'counter and finish_ranges the only reset of it, and the per-key queues '
      'are gone from the source set' % AC)
