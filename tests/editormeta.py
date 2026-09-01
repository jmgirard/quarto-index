"""The editor-metadata files, held against the syntax the docs site documents
(M50).

`_extensions/index/_schema.yml` and `_extensions/index/_snippets.json` tell an
editor which classes and attributes this extension's marking syntax has. They
are prose about the extension's own behaviour in a machine-readable file, and
nothing in a render reads them: shipped wrong, they complete an author into
syntax the filter does not accept and no output goes red. So each is held
against the syntax the docs site writes, which is the same domain M46's
documentation checks read and the one D-011 permits — a scan of what the docs
DOCUMENT, never a widened scan of what the filter's source accepts.

  snippets <snippets.json>
      The snippet file parses as JSON, and every top-level entry carries a
      non-empty `prefix`, a non-empty `body` and a non-empty `description`.
      A body written as a list of lines is non-empty when at least one line
      carries a character, so a body of blank lines is refused with the
      absent one.

  schema <schema.yml> <syntax-table.qmd> <qmd> [<qmd> ...]
      Per class, the attribute names the schema declares equal the names that
      class's constructs use across the swept `.qmd` files, and the schema
      declares those two classes and no third — in `classes:` and in
      `attributes:` alike, either one carrying a class the other does not
      being a schema an editor reads two ways.

      The values enumerated for `mention` and for `range` are read from the
      form table in <syntax-table.qmd> and not from every occurrence in the
      sweep: the table is the one place the docs enumerate those values as
      a set. The table is that file's rows carrying a
      construct in their first cell, and there are as many of them as that
      file's own sentence "There are exactly <count> supported forms"
      states — read off the page, so a row added or the sentence edited
      alone is each refused.

  bodies <snippets.json> <qmd> [<qmd> ...]
      Every attribute name the sweep enumerates for a class appears in at
      least one snippet body's construct of that class; no snippet body's
      construct carries an attribute name outside its class's set; and the
      bare mark, the bare placement marker and the placement marker naming an
      index each have a snippet of their own.

      A body is read with its tab stops replaced by their placeholder default
      text — `${1:cats}` as `cats`, `$0` as nothing — which is the text an
      editor leaves behind once an author tabs through the snippet, and the
      same substitution `tests/editorfixture.py` renders.

  installed <project> <name> [<name> ...]
      The extension a project installed carries each named file.

  docs <page> [<page> ...] -- <name> [<name> ...]
      Each named file is named on each documentation page. The `--` is what
      tells the pages from the names; a page that cannot be read fails
      naming that page.

Every mode prints what it swept, and refuses an empty domain: a sweep over no
file, or over files carrying no construct, would pass by comparing two empty
sets.

Usage:  python3 tests/editormeta.py <mode> [...]

Exits non-zero with a `FAIL:` line naming what it found.
"""

import json
import os
import re
import sys

# The two classes this extension's filter reads, and the file each is
# documented in. Stated here by hand rather than read off the schema: the
# schema is the artifact under test, and a domain derived from it would agree
# with any schema at all, including one that declares nothing.
MARK_CLASS = 'index'
MARKER_CLASS = 'qi-index-here'
CLASSES = (MARK_CLASS, MARKER_CLASS)

# The sentence in `site/syntax.qmd` that states how many forms its table
# tabulates, and the words it may state that count in. A table that grew a
# form is a syntax the schema has to describe, so the table is held to the
# page's own sentence rather than to a count pinned here: the sentence edited
# alone and a row added alone are each refused (M067).
FORM_COUNT = re.compile(r'There are exactly (\S+) supported forms')
NUMBER_WORDS = {word: index for index, word in enumerate(
    ('one two three four five six seven eight nine ten eleven twelve '
     'thirteen fourteen fifteen sixteen seventeen eighteen nineteen '
     'twenty').split(), 1)}

# The character that escapes a quote, or itself, inside a quoted attribute
# value: pandoc 3.11 reads `entry="a \"b\" c"` as the value `a "b" c` and
# `entry="p \\"` as `p \`. A scan without it ends the value at the escaped
# quote and resumes inside it (M067).
ESCAPE = '\\'

# The three snippet shapes AC3 names, each as a predicate over one construct
# found in a body: the class it is on, and whether it carries any attribute.
REQUIRED_SHAPES = (
    ('the bare mark `[term]{.index}`', MARK_CLASS, False),
    ('the bare placement marker `::: {.qi-index-here}`', MARKER_CLASS, False),
    ('a placement marker naming an index, `::: {.qi-index-here index="…"}`',
     MARKER_CLASS, True),
)


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    return 1


def parse_attrs(block):
    """One Pandoc attribute block's classes and its `name=value` pairs.

    Written as a scan rather than as a pattern because a value is quoted and
    may hold the characters a pattern would key on: `entry="a=b"` is one
    attribute named `entry`, and a regex reading `name=` anywhere would report
    a second one named `a`. Inside a quoted value a backslash-escaped quote is
    part of the value, without its backslash, and the value ends at the next
    unescaped quote — the reading pandoc gives the filter.
    """
    classes, attrs = [], []
    i, n = 0, len(block)
    while i < n:
        if block[i].isspace():
            i += 1
            continue
        if block[i] in '.#':
            j = i + 1
            while j < n and not block[j].isspace():
                j += 1
            if block[i] == '.':
                classes.append(block[i + 1:j])
            i = j
            continue
        j = i
        while j < n and not block[j].isspace() and block[j] != '=':
            j += 1
        name = block[i:j]
        if j < n and block[j] == '=':
            j += 1
            if j < n and block[j] in '"\'':
                quote = block[j]
                j += 1
                chars = []
                while j < n and block[j] != quote:
                    if (block[j] == ESCAPE and j + 1 < n
                            and block[j + 1] in (quote, ESCAPE)):
                        j += 1
                    chars.append(block[j])
                    j += 1
                value = ''.join(chars)
                j += 1
            else:
                start = j
                while j < n and not block[j].isspace():
                    j += 1
                value = block[start:j]
            attrs.append((name, value))
        i = j
    return classes, attrs


# One attribute block: braces with no newline and no nested brace between
# them. Pandoc writes an attribute block on one line, and the bound is what
# stops an unbalanced `{` in prose from swallowing the rest of a page.
ATTR_BLOCK = re.compile(r'\{([^{}\n]*)\}')


def constructs(text):
    """Every construct in `text` on one of this extension's classes.

    Each is a dict: `cls` (which class), `attrs` (its `name=value` pairs in
    written order), `at` (the offset of its opening brace in `text`, which is
    what lets a reader pair the block with the span it closes). A block on
    any other class — the docs site writes plenty, every fenced code block
    among them — is not one of ours and is skipped.
    """
    found = []
    for match in ATTR_BLOCK.finditer(text):
        classes, attrs = parse_attrs(match.group(1))
        for cls in CLASSES:
            if cls in classes:
                found.append({'cls': cls, 'attrs': attrs,
                              'at': match.start()})
    return found


def read(path):
    try:
        with open(path, encoding='utf-8') as handle:
            return handle.read()
    except OSError as bad:
        raise SystemExit(f'FAIL: {path}: cannot be read ({bad})')


def sweep(paths):
    """Every construct across `paths`, grouped by class, with the per-class
    attribute names the sweep enumerates."""
    found = {cls: [] for cls in CLASSES}
    for path in paths:
        for item in constructs(read(path)):
            item['path'] = path
            found[item['cls']].append(item)
    names = {cls: sorted({name for item in found[cls]
                          for name, _value in item['attrs']})
             for cls in CLASSES}
    return found, names


def check_snippets(path):
    """AC1: the snippet file parses, and every entry is fully written."""
    try:
        entries = json.loads(read(path))
    except json.JSONDecodeError as bad:
        return fail(f'{path}: does not parse as JSON ({bad})')
    if not isinstance(entries, dict):
        return fail(f'{path}: is a {type(entries).__name__} at the top level, '
                    f'where the snippet format is an object keyed by snippet '
                    f'name')
    if not entries:
        return fail(f'{path}: declares no snippet at all, so every clause '
                    f'below would pass over an empty set')
    for name, entry in entries.items():
        if not isinstance(entry, dict):
            return fail(f'{path}: the snippet {name!r} is a '
                        f'{type(entry).__name__}, not an object')
        for field in ('prefix', 'body', 'description'):
            if field not in entry:
                return fail(f'{path}: the snippet {name!r} carries no '
                            f'{field!r}')
            value = entry[field]
            if isinstance(value, list):
                text = ''.join(str(line) for line in value)
            else:
                text = str(value)
            if not text.strip():
                return fail(f'{path}: the snippet {name!r} carries an empty '
                            f'{field!r}')
    print(f'ok   M50-AC1: {path} parses, and each of its {len(entries)} '
          f'snippet(s) carries a prefix, a body and a description')
    return 0


def stated_forms(path, text):
    """The count of supported forms the page's own sentence states."""
    stated = FORM_COUNT.findall(text)
    if len(stated) != 1:
        raise SystemExit(fail(
            f'{path}: carries {len(stated)} sentence(s) of the form "There '
            f'are exactly <count> supported forms", where the row count its '
            f'table is held to is read from exactly one'))
    word = stated[0].rstrip('.')
    if word.isascii() and word.isdigit():
        return int(word)
    if word in NUMBER_WORDS:
        return NUMBER_WORDS[word]
    raise SystemExit(fail(
        f'{path}: states "exactly {word} supported forms", and {word!r} is '
        f'neither digits nor a number word from one to twenty, so the count '
        f'its table is held to cannot be read'))


def form_table(path):
    """The form table's rows carrying a construct in the first cell, and the
    count the page's sentence states, the two held equal.

    The table is read rather than every construct the sweep finds because the
    table is the one place the docs enumerate an attribute's values as a set;
    the other pages each demonstrate one value in a construct, and the prose
    demonstrating an empty value writes it in backticks, which is no construct
    at all — so an empty string could reach neither reading, and what the
    table alone gives is the enumeration (M067).
    """
    text = read(path)
    rows = []
    for line in text.splitlines():
        if not line.startswith('|'):
            continue
        first = line.split('|')[1] if line.count('|') > 1 else ''
        if constructs(first):
            rows.append(first)
    stated = stated_forms(path, text)
    if len(rows) != stated:
        raise SystemExit(fail(
            f'{path}: its form table carries {len(rows)} row(s) with a '
            f'construct in the first cell, where that page\'s own sentence '
            f'states exactly {stated} supported forms; the values below '
            f'would be read off a table that is not the one this check is '
            f'about'))
    return rows


def table_values(path, attribute):
    """The values the form table in `path` writes for one attribute."""
    return sorted({value for row in form_table(path) for item in constructs(row)
                   for name, value in item['attrs'] if name == attribute})


def check_schema(schema_path, syntax_path, *qmds):
    """AC2: the schema's classes, per-class attribute names and enumerated
    values against what the docs document."""
    try:
        import yaml
    except ImportError:
        return fail('PyYAML is not installed on this python3, so the schema '
                    'cannot be read the way an editor reads it; install it '
                    '(python3 -m pip install pyyaml) — D-030')
    try:
        schema = yaml.safe_load(read(schema_path))
    except yaml.YAMLError as bad:
        return fail(f'{schema_path}: does not parse as YAML ({bad})')
    if not isinstance(schema, dict):
        return fail(f'{schema_path}: is not a mapping at the top level')
    if not qmds:
        return fail('no document was given to sweep, so the comparison below '
                    'would hold the schema against an empty set')
    found, documented = sweep(qmds)
    for cls in CLASSES:
        if not found[cls]:
            return fail(f'the {len(qmds)} swept document(s) carry no '
                        f'{cls!r} construct at all, so the attribute set for '
                        f'that class would be compared empty')

    for section in ('classes', 'attributes'):
        block = schema.get(section)
        if not isinstance(block, dict):
            return fail(f'{schema_path}: carries no {section}: mapping')
        declared = sorted(block)
        if declared != sorted(CLASSES):
            return fail(f'{schema_path}: {section}: declares {declared}, '
                        f'where the filter reads {sorted(CLASSES)}; a class '
                        f'declared here and read nowhere completes an author '
                        f'into syntax this extension does not act on')

    for cls in CLASSES:
        block = schema['attributes'][cls]
        if not isinstance(block, dict) or not block:
            return fail(f'{schema_path}: attributes: {cls}: declares no '
                        f'attribute')
        for name, field in block.items():
            if not isinstance(field, dict) or not str(
                    field.get('description', '')).strip():
                return fail(f'{schema_path}: attributes: {cls}: {name}: '
                            f'carries no description, so an editor shows an '
                            f'author nothing on hover')
        declared = sorted(block)
        if declared != documented[cls]:
            return fail(f'{schema_path}: declares {declared} on class {cls!r} '
                        f'and the {len(qmds)} swept document(s) write '
                        f'{documented[cls]}; the two sets are not equal')

    for attribute in ('mention', 'range'):
        offered = schema['attributes'][MARK_CLASS][attribute].get('enum')
        if offered is None:
            return fail(f'{schema_path}: attributes: {MARK_CLASS}: '
                        f'{attribute}: enumerates no value, where the form '
                        f'table writes a fixed set of them')
        written = table_values(syntax_path, attribute)
        if sorted(offered) != written:
            return fail(f'{schema_path}: offers {sorted(offered)} for '
                        f'{attribute}= and the form table in {syntax_path} '
                        f'writes {written}')

    print(f'ok   M50-AC2: {schema_path} declares the classes '
          f'{sorted(CLASSES)} and no other, its per-class attribute names '
          f'equal those the {len(qmds)} swept document(s) write '
          f'({", ".join(documented[MARK_CLASS])} on {MARK_CLASS}; '
          f'{", ".join(documented[MARKER_CLASS])} on {MARKER_CLASS}), and '
          f'its mention= and range= values equal the '
          f'{len(form_table(syntax_path))} form rows\' '
          f'({", ".join(table_values(syntax_path, "mention"))}; '
          f'{", ".join(table_values(syntax_path, "range"))})')
    return 0


TAB_STOP = re.compile(r'\$\{(\d+):([^{}]*)\}|\$(\d+)')


def expand(body):
    """One snippet body with its tab stops replaced by their placeholder
    default text, joined into the lines an editor would leave behind.

    `${1:cats}` becomes `cats` and a stop with no default becomes nothing,
    which is what an author sees once they tab past it without typing. A
    mirrored stop — the same number written twice, as the range snippet writes
    it — expands to the same text in both places, exactly as an editor mirrors
    it.
    """
    text = body if isinstance(body, str) else '\n'.join(body)
    return TAB_STOP.sub(lambda m: m.group(2) or '', text)


def check_bodies(snippets_path, *qmds):
    """AC3: the snippet bodies against the attribute set the sweep
    enumerates, and the three shapes that must each have a snippet."""
    try:
        entries = json.loads(read(snippets_path))
    except json.JSONDecodeError as bad:
        return fail(f'{snippets_path}: does not parse as JSON ({bad})')
    if not qmds:
        return fail('no document was given to sweep, so the attribute set '
                    'the bodies are held against would be empty')
    _found, documented = sweep(qmds)
    if not any(documented[cls] for cls in CLASSES):
        return fail(f'the {len(qmds)} swept document(s) enumerate no '
                    f'attribute at all, so every clause below would pass '
                    f'over an empty set')

    in_bodies = {cls: {} for cls in CLASSES}
    shapes = {cls: {True: [], False: []} for cls in CLASSES}
    for name, entry in entries.items():
        for item in constructs(expand(entry.get('body', ''))):
            shapes[item['cls']][bool(item['attrs'])].append(name)
            for attribute, _value in item['attrs']:
                in_bodies[item['cls']].setdefault(attribute, []).append(name)

    # The three named shapes are judged FIRST. On a class the docs document
    # exactly one attribute for, the shape "a construct of that class carrying
    # an attribute" and the clause "that attribute is written somewhere" are
    # true together, and whichever runs first is the only one a plant can
    # reach. Ordering the shapes ahead of the coverage clauses puts one plant
    # within reach of each: a marker that stops naming an index reaches the
    # shape, and a MARK snippet dropped reaches the coverage clause.
    for label, cls, attributed in REQUIRED_SHAPES:
        if not shapes[cls][attributed]:
            return fail(f'{snippets_path}: no snippet body writes {label}')

    for cls in CLASSES:
        for attribute in documented[cls]:
            if attribute not in in_bodies[cls]:
                return fail(f'{snippets_path}: no snippet body writes '
                            f'{attribute}= on class {cls!r}, which the '
                            f'{len(qmds)} swept document(s) document')
        for attribute, snippets in sorted(in_bodies[cls].items()):
            if attribute not in documented[cls]:
                return fail(f'{snippets_path}: the snippet(s) '
                            f'{", ".join(repr(s) for s in snippets)} write '
                            f'{attribute}= on class {cls!r}, which no swept '
                            f'document documents; an editor would complete '
                            f'an author into it')

    counts = '; '.join(f'{len(in_bodies[cls])} on {cls}' for cls in CLASSES)
    print(f'ok   M50-AC3: the bare mark, the bare placement marker and a '
          f'marker naming an index each have a snippet; every attribute the '
          f'{len(qmds)} swept document(s) write is written by a snippet body '
          f'on its own class ({counts}); and no body writes one they do not')
    return 0


def check_installed(project, *names):
    """AC5: the named files are in the extension a project installed.

    The installed directory is found by the manifest every Quarto extension
    carries rather than by its name: an archive that unpacked under another
    name would otherwise be reported as a missing file, which sends a reader
    looking for the wrong defect.
    """
    root = os.path.join(project, '_extensions')
    if not names:
        return fail(f'{root}: no file was named to look for, so this check '
                    f'would pass over an empty set')
    found = []
    for base, _dirs, files in os.walk(root):
        if '_extension.yml' in files or '_extension.yaml' in files:
            found.append(base)
    if len(found) != 1:
        return fail(f'{root}: holds {len(found)} installed extension(s) '
                    f'({", ".join(found) or "none"}), where the archive '
                    f'installs exactly one')
    missing = [name for name in names
               if not os.path.isfile(os.path.join(found[0], name))]
    if missing:
        return fail(f'{found[0]}: the installed extension does not carry '
                    f'{", ".join(missing)}; a file git does not track does '
                    f'not travel to anybody who installs this extension')
    print(f'ok   M50-AC5: the extension installed at {found[0]} carries all '
          f'{len(names)} editor-metadata file(s) — {", ".join(names)}')
    return 0


def check_docs(*args):
    """AC6: each named file is named on each documentation page.

    The pages come before a `--` and the names after it. Told apart by
    position rather than by which arguments exist on disk, a page that is
    missing fails naming that page, where an existence test made it one more
    name to look for in the pages that survived (M067).
    """
    if '--' not in args:
        return fail('no `--` separates the documentation pages from the '
                    'filenames to look for, so this check cannot tell which '
                    'arguments are which')
    at = args.index('--')
    paths, names = list(args[:at]), list(args[at + 1:])
    if not paths or not names:
        return fail(f'{len(paths)} page(s) and {len(names)} name(s) were '
                    f'given, where this check needs at least one of each')
    for path in paths:
        body = read(path)
        missing = [name for name in names if name not in body]
        if missing:
            return fail(f'{path}: does not name {", ".join(missing)}, so a '
                        f'reader of it is not told the extension ships that '
                        f'file')
    print(f'ok   M50-AC6: each of the {len(paths)} documentation page(s) '
          f'({", ".join(paths)}) names all {len(names)} editor-metadata file '
          f'({", ".join(names)})')
    return 0


MODES = {
    'snippets': (check_snippets, 1),
    # The least each mode takes is the argument count below which it cannot
    # be called at all, not the count it needs to say something: `schema` and
    # `bodies` both refuse an empty sweep with a finding of their own, and a
    # usage error printed instead would leave that clause unreachable by any
    # plant.
    'schema': (check_schema, 2),
    'bodies': (check_bodies, 1),
    'installed': (check_installed, 1),
    'docs': (check_docs, 2),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    func, needed = MODES[argv[1]]
    args = argv[2:]
    variadic = bool(func.__code__.co_flags & 0x04)
    if len(args) < needed or (not variadic and len(args) > needed):
        raise SystemExit(__doc__)
    return func(*args)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
