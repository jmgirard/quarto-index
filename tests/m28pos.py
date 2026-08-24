# M28-AC1 — the fixture where the author's block position and the reported one
# diverge, read as `python3 tests/m28pos.py <render log> <fixture>`.
#
# READS: the two numbers the fixture's own manifest states, and the full text
# of every warning the render emitted.
# ASSERTS: the two numbers differ; the render drew exactly one emptied-place
# report; that report names the manifest's REPORTED number, which is not the
# author's; and it says which sequence that number is counted over.
# DOES NOT ASSERT: anything about the filter's source. What the milestone
# promises is what an author is told, so the expectation is compared against
# emitted text only (D-011).
#
# Run a second and third time on planted copies, which is where its ability to
# fail is shown: a manifest whose two numbers agree, and a log whose report
# names the author's position.
import re
import sys

log, fixture = sys.argv[1], sys.argv[2]
CLAUSE = ('counted over the document as this filter received it, after Quarto '
          'expanded any includes and executable cells, so they can differ from '
          'the positions in your source file')
REPORT = re.compile(r'^index placement marker in top-level block (\d+) was the '
                    r'only thing written where it stood; ')

src = open(fixture, encoding='utf-8').read()


def manifest(name):
    m = re.search(rf'^#\s+{name} position:\s+(\d+)\s*$', src, re.M)
    return None if m is None else int(m.group(1))


author, reported = manifest('author'), manifest('reported')
if author is None or reported is None:
    print(f'FAIL: M28-AC1: {fixture} states no author position, no reported '
          f'position, or neither', file=sys.stderr)
    sys.exit(1)
if author == reported:
    print(f'FAIL: M28-AC1: the manifest gives the same number ({author}) for '
          f'both positions, so it exercises no divergence and the report below '
          f'could be naming either one', file=sys.stderr)
    sys.exit(1)

text = re.sub(r'\x1b\[[0-9;]*m', '',
              open(log, encoding='utf-8', errors='replace').read())
emitted = [m.group(1).rstrip() for m in re.finditer(r'^\(W\) (.*)$', text, re.M)]
reports = [w for w in emitted if REPORT.match(w)]
if len(reports) != 1:
    print(f'FAIL: M28-AC1: the render emitted {len(reports)} emptied-place '
          f'report(s), want exactly 1', file=sys.stderr)
    for w in emitted:
        print(f'  emitted: <<{w}>>', file=sys.stderr)
    sys.exit(1)

got = int(REPORT.match(reports[0]).group(1))
if got == author:
    print(f'FAIL: M28-AC1: the report names block {got}, which is the position '
          f'the marker is written at in the source file; this fixture exists '
          f'because the reported position is not that one', file=sys.stderr)
    sys.exit(1)
if got != reported:
    print(f'FAIL: M28-AC1: the report names block {got}; the manifest says the '
          f'render reports {reported}', file=sys.stderr)
    sys.exit(1)
if CLAUSE not in reports[0]:
    print(f'FAIL: M28-AC1: the emptied-place report does not say which sequence '
          f'its number is counted over: <<{reports[0]}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   M28-AC1: the marker written as top-level block {author} of '
      f'{fixture} is reported at block {reported}, the number the render '
      f'actually emits, and the report says the position is counted over the '
      f'document after Quarto expanded the include')
