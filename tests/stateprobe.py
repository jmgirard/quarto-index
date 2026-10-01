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
its module nor, in indexes.lua, one of the KEPT lines, naming the line. Where
the reset starts and ends is Lua's answer, not this file's: Quarto's own Lua
loads each module and reports the lines of the `reset` the module exports.
The
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
OPENER = re.compile(r'\s*local\s+function\s+reset\s*\([^)]*\)')

# Run by Quarto's own Lua with the modules directory and module names as
# arguments. For each name it prints the name, then either the source and the
# first and last line of the `reset` function the module exports, or why there
# is none. Lua's parser answers where the function ends, so a comment, a
# string, or an `end` at any column cannot move that answer.
BOUNDS_LUA = r'''
local dir = arg[1]
package.path = dir .. "/?.lua;" .. package.path
for i = 2, #arg do
  local name = arg[i]
  local ok, m = pcall(require, "./" .. name)
  if not ok then
    print(name .. "\terror\t" .. (tostring(m):gsub("%s+", " ")))
  elseif type(m) ~= "table" or type(m.reset) ~= "function" then
    print(name .. "\tnone")
  else
    local info = debug.getinfo(m.reset, "S")
    print(table.concat({name, "found", info.source,
                        info.linedefined, info.lastlinedefined}, "\t"))
  end
end
'''


def lua_code(lines, start):
    """(index, code) for each line from `start`: the line with its comments
    removed and each string literal replaced by `""`.

    A long comment or long string (`--[[ ]]`, `[==[ ]==]`) may span lines, and
    so may a short string whose line ends in a backslash; a line wholly inside
    one has no code. Read from the file's first line, so that a line inside a
    comment is known to be one.
    """
    long_close = None
    in_comment = False
    quote = None
    for i in range(start, len(lines)):
        line = lines[i]
        code = []
        pos = 0
        if quote is not None:
            pos, quote = short_string(line, 0, quote)
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
                pos, quote = short_string(line, pos + 1, line[pos])
                code.append('""')
                continue
            code.append(line[pos])
            pos += 1
        yield i, ''.join(code)


def short_string(line, pos, quote):
    """Where a short string opened before `pos` ends: (the position after it,
    the quote still open on the next line or None). A backslash ending the
    line continues the string there, as Lua reads it."""
    while pos < len(line):
        if line[pos] == '\\':
            if pos + 1 == len(line):
                return len(line), quote
            pos += 2
        elif line[pos] == quote:
            return pos + 1, None
        else:
            pos += 1
    return len(line), None


def opener_rows(codes):
    """The 0-based rows whose code opens with `local function reset(`."""
    return [i for i, code in enumerate(codes) if OPENER.match(code)]


def lua_bounds(module_dir, names):
    """{name: (source path, first line, last line)} for the `reset` each named
    module exports, 1-based, as Quarto's Lua reads it; or {name: reason}
    where it exports none or does not load."""
    with tempfile.NamedTemporaryFile('w', suffix='.lua', delete=False) as f:
        f.write(BOUNDS_LUA)
    try:
        run = subprocess.run(['quarto', 'pandoc', 'lua', f.name,
                              os.path.abspath(module_dir)] + names,
                             capture_output=True, text=True)
    finally:
        os.unlink(f.name)
    if run.returncode != 0:
        raise SystemExit('FAIL: cell guard: Quarto\'s Lua did not run (exit %d): '
                         '%s' % (run.returncode, run.stderr.strip()))
    out = {}
    for row in run.stdout.splitlines():
        cols = row.split('\t')
        if len(cols) == 5 and cols[1] == 'found':
            out[cols[0]] = (cols[2][1:], int(cols[3]), int(cols[4]))
        elif len(cols) >= 2:
            out[cols[0]] = ('it does not load: ' + cols[2] if cols[1] == 'error'
                            else 'it exports no reset function as M.reset')
    for name in names:
        if name not in out:
            raise SystemExit('FAIL: cell guard: Quarto\'s Lua printed nothing '
                             'for %s.lua: %r' % (name, run.stdout))
    return out


def reset_body(name, path, lines, bound):
    """The 0-based line numbers of the code lines inside `name`'s reset.

    `bound` is lua_bounds's answer for the module. The module must have one
    `local function reset(` line outside comments, and it must open the reset
    the module exports. Between that line and the closing line, every line
    with code is a body line. The opener line is one too when code follows
    the parameter list, and the closing line when it holds more than `end`.
    """
    codes = [code for _, code in lua_code(lines, 0)]
    rows = opener_rows(codes)
    if len(rows) != 1:
        raise ResetShape('%s.lua: %d lines open with %r outside comments '
                         '(lines %s), and the guard reads one reset per module'
                         % (name, len(rows), RESET_OPENER,
                            ', '.join(str(r + 1) for r in rows) or 'none'))
    if isinstance(bound, str):
        raise ResetShape('%s.lua: a reset opens at line %d, but %s'
                         % (name, rows[0] + 1, bound))
    source, first, last = bound
    if os.path.realpath(source) != os.path.realpath(path):
        raise ResetShape('%s.lua: the reset it exports is defined in %s'
                         % (name, source))
    if first != rows[0] + 1:
        raise ResetShape('%s.lua: a reset opens at line %d, but the reset it '
                         'exports opens at line %d' % (name, rows[0] + 1, first))
    body = []
    for i in range(first - 1, last):
        code = codes[i]
        if i == first - 1:
            code = code[OPENER.match(code).end():]
            if first == last:
                code = re.sub(r'\bend\s*$', '', code)
            if code.strip():
                body.append(i)
        elif i == last - 1:
            if code.strip() != 'end':
                body.append(i)
        elif code.strip():
            body.append(i)
    return body


def reset_lines(name, lines):
    """reset_body for the probes, where a reset it cannot read ends the run."""
    path = module_path(name)
    try:
        bound = lua_bounds(MODULE_DIR, [name])[name]
        return reset_body(name, path, lines, bound)
    except ResetShape as e:
        raise SystemExit(str(e))


def reset_modules():
    """(name, path, lines) for each module under the extension's `modules/`
    with a `local function reset(` line outside comments, read through
    filtersrc so QI_EXT_DIR can name a copy."""
    root = os.path.join(filtersrc.ext_dir(), 'modules')
    found = []
    for path in filtersrc.sources():
        rel = os.path.relpath(path, root)
        if rel.startswith(os.pardir):
            continue
        lines = filtersrc.read(path).split('\n')
        if opener_rows([code for _, code in lua_code(lines, 0)]):
            found.append((rel[:-len('.lua')], path, lines))
    return found


def check_cells():
    """Every reset line is a CELLS statement for its module, or a KEPT line.

    A module is found by its `local function reset(` line outside comments,
    never by name. A reset written in another form is not found. Every module
    CELLS names must be among those found, which keeps the search from passing
    on a tree where it found nothing to read. Quarto's Lua then says where
    each found module's exported reset starts and ends.
    """
    found = reset_modules()
    names = [name for name, _, _ in found]
    missing = sorted({module for _, module, _ in CELLS} - set(names))
    if missing:
        print('FAIL: cell guard: no %r line under %s in %s, which CELLS names'
              % (RESET_OPENER, os.path.join(filtersrc.ext_dir(), 'modules'),
                 ', '.join(m + '.lua' for m in missing)),
              file=sys.stderr)
        return 1
    bounds = lua_bounds(os.path.join(filtersrc.ext_dir(), 'modules'), names)
    stray = []
    lines_read = 0
    for name, path, lines in found:
        allowed = {statement for _, module, statement in CELLS
                   if module == name}
        if name == 'indexes':
            allowed.update(KEPT)
        try:
            body = reset_body(name, path, lines, bounds[name])
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
