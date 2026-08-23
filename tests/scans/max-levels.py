"""Read the filter's own MAX_LEVELS and print it.

The suite derives fixtures from this value rather than writing it down, so a
constant the filter changes cannot leave the derivation deriving something the
back-end no longer does while still passing (it would compare its own
derivations against each other). Reading it out of the SOURCE SET rather than
one named file is what keeps that true when the definition moves into a module
(M16-AC3).

It asserts exactly one thing: that the source set defines MAX_LEVELS once.
What the value should BE is no claim of this scan's — it prints the value,
and the checks that derive fixtures from it are where that is decided.
"""

import re
import sys

sys.path.insert(0, 'tests')
import filtersrc

PATTERN = r'^local MAX_LEVELS = ([0-9]+)$'

found = re.findall(PATTERN, filtersrc.text(), re.MULTILINE)
if len(found) != 1:
    print(f'FAIL: M09: expected exactly one MAX_LEVELS definition in the '
          f'filter source set, found {len(found)}', file=sys.stderr)
    sys.exit(1)
print(found[0])
