"""M26's planted-defect run: is every per-document reset load-bearing?

The suite's own M26 checks assert that a fixture renders identically whether or
not a synthetic document went through the filter's passes first. That assertion
passes on a filter whose `reset` restores nothing IF no accumulator the fixture
reads was polluted — the vacuity M23's lesson names. This driver settles it the
only way that settles it: each reset, and then each individual cell inside one,
is removed in turn and the comparison is required to FAIL.

  AC3  one probe per module, its whole reset emptied of what it restores, and
       — the form axis — latex.lua's reset left in place with one cell alone
       dropped from it. The indexes.lua probe drops the six cells that reset
       clears and keeps the two lines installing the unnamed index and the
       `read(doc.meta)` call: a document with no index to file a mark in fails
       to render, which is not a comparison moving.
  AC4  one probe per cell in CELLS, each cell alone dropped and put back. The
       cells EXEMPT names are expected to PASS, each for the reason recorded
       there; they are probed too, and their passing is the evidence for those
       reasons.

A probe stops at the first fixture and format whose comparison fails, and the
report names which artifact moved — a `.tex`, an HTML page, or the warning
stream. The unplanted tree is required to pass every pair first, or no failure
below would be evidence of anything.

Before any of that, the cell guard (M105) reads every module's reset from
source. It fails on a reset line whose text is neither a CELLS statement for
its module nor, in indexes.lua, one of the KEPT lines, naming the line. The
guard reads text, not count: a second copy of an allowed line passes it, and
plant() stops on that copy when the probe runs. The suite runs the guard alone
on every run, since it renders nothing.

Usage:  python3 tests/stateprobe.py [cell-or-probe-name ...]
        python3 tests/stateprobe.py --check-cells

The guard reads the extension through tests/filtersrc.py, so QI_EXT_DIR points
it at a copy. The probes plant and render the extension itself, and refuse to
run while QI_EXT_DIR names anything else.

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

sys.path.insert(0, 'tests')
import filtersrc

FIXTURE_DIR = 'examples'
EXT_DIR = filtersrc.DEFAULT_EXT_DIR
MODULE_DIR = os.path.join(EXT_DIR, 'modules')
RENDER = ['quarto', 'render']

# (fixture stem, Quarto format, artifact extension). Ordered cheapest-first:
# most cells move the rich fixture's LaTeX, so most probes cost one pair.
PAIRS = [('state-reuse', 'latex', 'tex'),
         ('state-reuse', 'html', 'html'),
         ('state-reuse-indexes', 'latex', 'tex'),
         ('state-reuse-indexes', 'html', 'html'),
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
    ('order', 'indexes', 'qi_core.empty(order)'),
    ('titles', 'indexes', 'qi_core.empty(titles)'),
    ('doc_labels', 'indexes', 'qi_core.empty(doc_labels)'),
    ('index_labels', 'indexes', 'qi_core.empty(index_labels)'),
    ('language_words', 'indexes', 'language_words = nil'),
    ('declared', 'indexes', 'declared = false'),
]

# What indexes.lua's reset restores, without the two lines that install the
# unnamed index over them: the whole-module probe drops these and leaves the
# document an index to file a mark in.
INDEXES_RESTORES = [statement for _, module, statement in CELLS
                    if module == 'indexes']

# The lines of indexes.lua's reset that restore no cell, and which the
# reset:indexes probe keeps: the two installing the unnamed index, and the
# `read(doc.meta)` call with the `if` around it. Each is matched stripped, as
# reset_body's lines are.
KEPT = [
    'order[1] = UNNAMED',
    'titles[UNNAMED] = DEFAULT_TITLE',
    'if doc ~= nil then',
    'read(doc.meta)',
    'end',
]

RESET_OPENER = 'local function reset('

# The cells whose reset cannot be load-bearing, and why. Each is probed like
# every other; its PASSING is what the criterion records.
EXEMPT = {
    'range_pair_found':
        'finish_ranges assigns it wholesale on every document, so nothing '
        'survives into one',
    'language_words':
        "read assigns it on every document, from the lang: that document "
        'declares',
    'index_labels':
        'read assigns every declared index its own map, nil included, and '
        'label is asked only for the index a mark files in, which is a '
        'declared name or the unnamed cell no declaration can name',
}


def module_path(name):
    return os.path.join(MODULE_DIR, name + '.lua')


class ResetShape(Exception):
    """A reset the reader cannot delimit. The message names module and line."""


LONG_OPEN = re.compile(r'\[(=*)\[')
BLOCK_OPEN = re.compile(r'\b(?:function|if|do|repeat)\b')
BLOCK_CLOSE = re.compile(r'\b(?:end|until)\b')


def lua_code(lines, start):
    """(index, code) for each line from `start`: the line with its comments
    removed and each string literal replaced by `""`.

    A long comment or long string (`--[[ ]]`, `[==[ ]==]`) may span lines; a
    line wholly inside one has no code. The keywords that open and close a
    block are then counted over code alone, so an `end` in a comment or a
    string closes nothing.
    """
    long_close = None
    in_comment = False
    for i in range(start, len(lines)):
        line = lines[i]
        code = []
        pos = 0
        while pos < len(line):
            if long_close is not None:
                close = line.find(long_close, pos)
                if close < 0:
                    break
                pos = close + len(long_close)
                if not in_comment:
                    code.append('""')
                long_close = None
                continue
            if line.startswith('--', pos):
                m = LONG_OPEN.match(line, pos + 2)
                if not m:
                    break
                long_close, in_comment = ']' + m.group(1) + ']', True
                pos = m.end()
                continue
            m = LONG_OPEN.match(line, pos)
            if m:
                long_close, in_comment = ']' + m.group(1) + ']', False
                pos = m.end()
                continue
            if line[pos] in '"\'':
                quote = line[pos]
                pos += 1
                while pos < len(line) and line[pos] != quote:
                    pos += 2 if line[pos] == '\\' else 1
                pos += 1
                code.append('""')
                continue
            code.append(line[pos])
            pos += 1
        yield i, ''.join(code)


def reset_body(name, lines):
    """The 0-based line numbers of the code lines inside `name`'s reset.

    The function ends where its blocks balance: `function`, `if`, `do` and
    `repeat` open one, `end` and `until` close one. An inner `end` at column 0
    is therefore read as the inner block's, and the lines after it are still
    read. The closing line is a body line too when it holds more than `end`.
    """
    start = next((i for i, line in enumerate(lines)
                  if line.strip().startswith(RESET_OPENER)), None)
    if start is None:
        raise ResetShape('%s.lua: no line opens with %r'
                         % (name, RESET_OPENER))
    depth = 0
    body = []
    for i, code in lua_code(lines, start):
        depth += len(BLOCK_OPEN.findall(code)) - len(BLOCK_CLOSE.findall(code))
        if i == start:
            if depth != 1:
                raise ResetShape('%s.lua line %d: the reset opener shares its '
                                 'line with other blocks, which this reader '
                                 'reads a line at a time' % (name, i + 1))
            continue
        if depth == 0:
            if code.strip() != 'end':
                body.append(i)
            return body
        if code.strip():
            body.append(i)
    raise ResetShape('%s.lua: the reset opened at line %d never closes'
                     % (name, start + 1))


def reset_lines(name, lines):
    """reset_body for the probes, where a reset it cannot read ends the run."""
    try:
        return reset_body(name, lines)
    except ResetShape as e:
        raise SystemExit(str(e))


def reset_modules():
    """(name, lines) for each module under the extension's `modules/` that
    opens a reset, read through filtersrc so QI_EXT_DIR can name a copy."""
    root = os.path.join(filtersrc.ext_dir(), 'modules')
    found = []
    for path in filtersrc.sources():
        rel = os.path.relpath(path, root)
        if rel.startswith(os.pardir):
            continue
        lines = filtersrc.read(path).split('\n')
        if any(line.strip().startswith(RESET_OPENER) for line in lines):
            found.append((rel[:-len('.lua')], lines))
    return found


def check_cells():
    """Every reset line is a CELLS statement for its module, or a KEPT line.

    A module is found by its `local function reset(` line, never by name.
    A reset written in another form is not found. Every module CELLS names
    must be among those found, which keeps the search from passing on a
    tree where it found nothing to read.
    """
    found = reset_modules()
    names = [name for name, _ in found]
    missing = sorted({module for _, module, _ in CELLS} - set(names))
    if missing:
        print('FAIL: cell guard: no %r line under %s in %s, which CELLS names'
              % (RESET_OPENER, os.path.join(filtersrc.ext_dir(), 'modules'),
                 ', '.join(m + '.lua' for m in missing)),
              file=sys.stderr)
        return 1
    stray = []
    lines_read = 0
    for name, lines in found:
        allowed = {statement for _, module, statement in CELLS
                   if module == name}
        if name == 'indexes':
            allowed.update(KEPT)
        try:
            body = reset_body(name, lines)
        except ResetShape as e:
            print('FAIL: cell guard: %s' % e, file=sys.stderr)
            return 1
        for n in body:
            lines_read += 1
            if lines[n].strip() not in allowed:
                stray.append('%s.lua line %d: <<%s>>'
                             % (name, n + 1, lines[n].strip()))
    if stray:
        print('FAIL: cell guard: these reset lines are neither a CELLS '
              'statement for their module nor a KEPT line of indexes.lua, so '
              'no probe would drop them alone:\n  ' + '\n  '.join(stray),
              file=sys.stderr)
        return 1
    print('ok   cell guard: all %d reset line(s) across %s are a CELLS '
          'statement for their module or a KEPT line of indexes.lua'
          % (lines_read, ', '.join(n + '.lua' for n in names)))
    return 0


def plant(module, statements):
    """Drop `statements` from that module's reset. Returns the original text."""
    path = module_path(module)
    original = open(path, encoding='utf-8').read()
    lines = original.split('\n')
    body = reset_lines(module, lines)
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
    yield ('reset:indexes', 'indexes', INDEXES_RESTORES,
           "indexes.lua's reset emptied of the six cells it clears, its two "
           "installation lines and its read call kept")
    yield ('reset:latex-one-cell', 'latex', ['principal_ordinals = 0'],
           "latex.lua's reset kept, principal_ordinals alone dropped from it")
    for name, module, statement in CELLS:
        yield ('cell:' + name, module, [statement], 'the reset of ' + name)


def main(argv):
    if argv[1:2] == ['--check-cells']:
        if len(argv) > 2:
            raise SystemExit(__doc__)
        return check_cells()
    if os.path.normpath(filtersrc.ext_dir()) != os.path.normpath(EXT_DIR):
        raise SystemExit('QI_EXT_DIR names %r, but the probes plant and render '
                         '%r; unset it to run them'
                         % (filtersrc.ext_dir(), EXT_DIR))
    if check_cells() != 0:
        return 1
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
            exempt = (EXEMPT.get(label[len('cell:'):])
                      if label.startswith('cell:') else None)
            drop = statements
            if drop is None:
                lines = open(module_path(module), encoding='utf-8').read().split('\n')
                drop = [lines[n].strip() for n in reset_lines(module, lines)]
            original = plant(module, drop)
            try:
                moved = sweep(pats, work)
            finally:
                restore(module, original)
            if exempt:
                if moved is None:
                    print('ok   %-28s no comparison moves — %s (expected)'
                          % (label, exempt))
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
          'cells recorded as unable to')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
