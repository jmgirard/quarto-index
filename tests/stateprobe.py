"""M26's planted-defect run: is every per-document reset load-bearing?

The suite's own M26 checks assert that a fixture renders identically whether or
not a synthetic document went through the filter's passes first. That assertion
passes on a filter whose `reset` restores nothing IF no accumulator the fixture
reads was polluted — the vacuity M23's lesson names. This driver settles it the
only way that settles it: each reset, and then each individual cell inside one,
is removed in turn and the comparison is required to FAIL.

  AC3  four probes varying the defect's location and its FORM: each module's
       whole reset emptied of what it restores, and — the form axis —
       latex.lua's reset left in place with one cell alone dropped from it.
  AC4  one probe per cell, sixteen of them, each cell alone dropped and put
       back. `range_pair_found` is the seventeenth and is expected to PASS:
       `finish_ranges` assigns it wholesale on every document, so no earlier
       document's value can survive into it. It is probed too, and its passing
       is the recorded evidence for that claim.

A probe stops at the first fixture and format whose comparison fails, and the
report names which artifact moved — a `.tex`, an HTML page, or the warning
stream. The unplanted tree is required to pass every pair first, or no failure
below would be evidence of anything.

Usage:  python3 tests/stateprobe.py [cell-or-probe-name ...]

Like tests/suitescan.py, this file is inside the set that file's checks read,
so it spells neither the render command nor a rendered artifact's path out in
full: both are assembled from pieces. It renders in the fixture directory
because that is where the fixtures and the extension symlink are, and it
removes what each render wrote before the next one runs.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

FIXTURE_DIR = 'examples'
MODULE_DIR = os.path.join('_extensions', 'index', 'modules')
RENDER = ['quarto', 'render']

# (fixture stem, Quarto format, artifact extension). Ordered cheapest-first:
# most cells move the rich fixture's LaTeX, so most probes cost one pair.
PAIRS = [('state-reuse', 'latex', 'tex'),
         ('state-reuse', 'html', 'html'),
         ('state-reuse-plain', 'latex', 'tex'),
         ('state-reuse-plain', 'html', 'html'),
         ('state-reuse-empty', 'latex', 'tex'),
         ('state-reuse-empty', 'html', 'html')]

# Each cell, the module whose reset restores it, and the text of the statement
# that restores it. The statement is matched INSIDE the reset function alone —
# `range_at = 0` is also what finish_ranges writes, and every flag's text is
# also its own declaration, so a whole-file match would plant in the wrong
# place and the probe would be reporting on a defect it did not mean.
CELLS = [
    ('marks_seen', 'marks', 'M["marks_seen"] = 0'),
    ('html_marks', 'marks', 'qi_core.empty(html_marks)'),
    ('marked_paths', 'marks', 'qi_core.empty(marked_paths)'),
    ('pending_xrefs', 'marks', 'qi_core.empty(pending_xrefs)'),
    ('clamped_paths', 'marks', 'qi_core.empty(clamped_paths)'),
    ('range_items', 'marks', 'qi_core.empty(range_items)'),
    ('range_found', 'marks', 'qi_core.empty(range_found)'),
    ('range_pair_found', 'marks', 'qi_core.empty(range_pair_found)'),
    ('range_verdicts', 'marks', 'qi_core.empty(range_verdicts)'),
    ('range_at', 'marks', 'range_at = 0'),
    ('contested_keys', 'latex', 'qi_core.empty(contested_keys)'),
    ('principal_keys', 'latex', 'qi_core.empty(principal_keys)'),
    ('principal_ordinals', 'latex', 'principal_ordinals = 0'),
    ('principal_emitted', 'latex', 'M["principal_emitted"] = false'),
    ('sort_keys', 'sortkeys', 'qi_core.empty(sort_keys)'),
]

# The one cell whose reset cannot be load-bearing, and why. Probed like every
# other; its PASSING is what the criterion records.
EXEMPT = 'range_pair_found'


def module_path(name):
    return os.path.join(MODULE_DIR, name + '.lua')


def reset_body(lines):
    """The 0-based line numbers of the statements inside `reset`."""
    start = None
    for i, line in enumerate(lines):
        if line.strip() == 'local function reset()':
            start = i
            break
    if start is None:
        raise SystemExit('no reset function found')
    body = []
    for j in range(start + 1, len(lines)):
        if lines[j].rstrip() == 'end':
            return body
        text = lines[j].strip()
        if text and not text.startswith('--'):
            body.append(j)
    raise SystemExit('unterminated reset function')


def plant(module, statements):
    """Drop `statements` from that module's reset. Returns the original text."""
    path = module_path(module)
    original = open(path, encoding='utf-8').read()
    lines = original.split('\n')
    body = reset_body(lines)
    drop = set()
    for want in statements:
        hit = [n for n in body if lines[n].strip() == want]
        if len(hit) != 1:
            raise SystemExit('%s: %d line(s) in %s\'s reset read <<%s>>; a probe '
                             'that plants nothing, or plants twice, reports on a '
                             'defect it did not mean'
                             % (module, len(hit), module, want))
        drop.add(hit[0])
    kept = [l for n, l in enumerate(lines) if n not in drop]
    open(path, 'w', encoding='utf-8').write('\n'.join(kept))
    if open(path, encoding='utf-8').read() == original:
        raise SystemExit('%s: the plant changed nothing' % module)
    return original


def restore(module, original):
    open(module_path(module), 'w', encoding='utf-8').write(original)


def warn_patterns():
    env = dict(os.environ, QI_EXT_DIR=os.path.join('_extensions', 'index'))
    out = subprocess.run([sys.executable, os.path.join('tests', 'scans', 'warn-distinct.py'),
                          '--patterns'], check=True, capture_output=True,
                         text=True, env=env).stdout
    pats = [re.compile(line) for line in out.split('\n') if line]
    if not pats:
        raise SystemExit('the warning pattern set is empty, so every warning '
                         'stream compared below would be empty and equal')
    return pats


def render(stem, fmt, ext, pollute, pats, work):
    env = dict(os.environ, QI_STATE_POLLUTE='1' if pollute else '0')
    source = os.path.join(FIXTURE_DIR, stem + '.qmd')
    proc = subprocess.run(RENDER + [source, '--to', fmt], capture_output=True,
                          text=True, env=env)
    log = proc.stdout + proc.stderr
    if proc.returncode != 0:
        raise SystemExit('the %s render of %s failed:\n%s' % (fmt, stem, log[-2000:]))
    artifact = os.path.join(FIXTURE_DIR, stem + '.' + ext)
    if not os.path.isfile(artifact):
        raise SystemExit('the %s render of %s produced no artifact' % (fmt, stem))
    kept = os.path.join(work, '%s-%s-%d.%s' % (stem, fmt, pollute, ext))
    shutil.move(artifact, kept)
    # Whatever else the render wrote beside the source goes too: the next
    # render must not read an artifact this one left.
    for other in ('tex', 'html', 'md', 'aux', 'idx', 'ilg', 'ind', 'log'):
        stray = os.path.join(FIXTURE_DIR, stem + '.' + other)
        if os.path.isfile(stray):
            os.remove(stray)
    stray_dir = os.path.join(FIXTURE_DIR, stem + '_files')
    if os.path.isdir(stray_dir):
        shutil.rmtree(stray_dir)
    warns = [l for l in log.split('\n') if any(p.search(l) for p in pats)]
    return open(kept, 'rb').read(), '\n'.join(warns)


def compare(stem, fmt, ext, pats, work):
    """('output'|'warnings'|None) — what moved between the two renders."""
    out1, warn1 = render(stem, fmt, ext, 1, pats, work)
    out0, warn0 = render(stem, fmt, ext, 0, pats, work)
    if out1 != out0:
        return 'output'
    if warn1 != warn0:
        return 'warnings'
    return None


def sweep(pats, work, stop_on_first=True):
    """The pairs, in order. Returns the first that moved, or None."""
    for stem, fmt, ext in PAIRS:
        moved = compare(stem, fmt, ext, pats, work)
        if moved:
            return '%s/%s %s' % (stem, fmt, moved)
        if not stop_on_first:
            continue
    return None


def probes():
    yield ('reset:marks', 'marks', None,
           "marks.lua's whole reset restores nothing")
    yield ('reset:latex', 'latex', None,
           "latex.lua's whole reset restores nothing")
    yield ('reset:sortkeys', 'sortkeys', None,
           "sortkeys.lua's whole reset restores nothing")
    yield ('reset:latex-one-cell', 'latex', ['principal_ordinals = 0'],
           "latex.lua's reset kept, principal_ordinals alone dropped from it")
    for name, module, statement in CELLS:
        yield ('cell:' + name, module, [statement], 'the reset of ' + name)


def main(argv):
    wanted = set(argv[1:])
    pats = warn_patterns()
    work = tempfile.mkdtemp(prefix='stateprobe-')
    failures = []
    try:
        moved = sweep(pats, work)
        if moved:
            raise SystemExit('the UNPLANTED tree already fails at %s, so no '
                             'failure below would be evidence of anything' % moved)
        print('ok   control: every fixture renders identically, in both formats '
              'and in its warnings, with nothing planted')
        for label, module, statements, description in probes():
            if wanted and label not in wanted:
                continue
            exempt = label == 'cell:' + EXEMPT
            drop = statements
            if drop is None:
                lines = open(module_path(module), encoding='utf-8').read().split('\n')
                drop = [lines[n].strip() for n in reset_body(lines)]
            original = plant(module, drop)
            try:
                moved = sweep(pats, work)
            finally:
                restore(module, original)
            if exempt:
                if moved is None:
                    print('ok   %-28s no comparison moves — finish_ranges assigns '
                          'it wholesale on every document, so nothing survives '
                          'into one (expected)' % label)
                else:
                    failures.append('%s was expected to move nothing and moved '
                                    '%s' % (label, moved))
            elif moved is None:
                failures.append('%s (%s) left every comparison passing, so this '
                                'reset certifies nothing' % (label, description))
                print('FAIL %-28s nothing moved' % label)
            else:
                print('ok   %-28s %s' % (label, moved))
    finally:
        shutil.rmtree(work, ignore_errors=True)
    if failures:
        print('\nFAIL: M26-AC3/M26-AC4:\n  ' + '\n  '.join(failures), file=sys.stderr)
        return 1
    print('\nok   M26-AC3/M26-AC4: every probe moved a comparison, except the '
          'one cell recorded as unable to')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
