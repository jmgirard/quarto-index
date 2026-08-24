"""M32 — where the index lands beside a bibliography.

The three readers `tests/run-tests.sh` runs over the `examples/references.qmd`
fixture pair, in a module rather than in heredocs so the suite can re-run each
one against a copy of its own artifact with a defect planted in it. A green
check is evidence about what it covers, not about the extension, and a check
never shown red covers nothing (the M01 lesson, and the M29 idiom this follows).

    python3 tests/m32refs.py derive <fixture.qmd> <twin.qmd>
    python3 tests/m32refs.py latex  <fixture.tex> <twin.tex>
    python3 tests/m32refs.py html   <fixture.html> <twin.html>

Each prints one `ok` line and exits 0, or prints a FAIL line naming which
clause went wrong and exits 1. `html` reads the generated section's id from
`HTML_SECTION_ID`, as every other HTML reader in the suite does.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
import htmlindex as H  # noqa: E402

# The fixture's own anchors. The marker half of the recipe is only visible
# against something that follows the marker: the index landing at the marker
# and the index landing at the end of the document are the same order relative
# to the bibliography, so a check reading only the bibliography passes on a
# document carrying no marker at all. The Afterword section is what tells them
# apart, and `derive` below refuses a fixture that has stopped writing it.
AFTER_ID = 'qi-afterword'
REFS_OPEN = '::: {#refs}'
MARKER_OPEN = '::: {.qi-index-here}'
FENCE = ':::'


def die(message):
    print(f'FAIL: M32: {message}', file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# derive — the twin is the fixture with its `#refs` div block deleted.
#
# The pair is the whole point: a fixture built only from the shape the recipe
# adds cannot show the div is what moved anything. So the derivation is checked
# before either order is stated, or the two orders would be two different
# documents' orders.
# ---------------------------------------------------------------------------
def cut_block(source, opener, what, path):
    """`source` with the one fenced block opening `opener` removed whole.

    Removed *whole*: a line inside the block that is not a fence is part of the
    block, and a nested fence closes the inner block, not this one. A loop that
    skipped only the two fences would leave the contents behind while both the
    failure message and the ok line said the block was deleted.
    """
    out, depth, cuts = [], 0, 0
    for line in source.splitlines(True):
        stripped = line.strip()
        if depth == 0:
            if stripped == opener:
                depth, cuts = 1, cuts + 1
                continue
            out.append(line)
            continue
        if stripped.startswith(FENCE) and stripped != FENCE:
            depth += 1          # a nested block opens
        elif stripped == FENCE:
            depth -= 1          # ...and its own fence closes it
        continue
    if depth != 0:
        die(f'{path} never closes the {what} block it opens; the fixture is '
            f'not the recipe under test')
    if cuts != 1:
        die(f'{path} writes {cuts} {what} blocks; the recipe under test is '
            f'exactly one')
    return ''.join(out)


def derive(fixture_path, twin_path):
    fixture = open(fixture_path, encoding='utf-8').read()
    twin = open(twin_path, encoding='utf-8').read()

    # The shape the readers below depend on, asserted against the fixture
    # rather than assumed: the div, then the marker, then the Afterword that
    # makes the marker's own work visible.
    for token in (REFS_OPEN, MARKER_OPEN, '{#' + AFTER_ID + '}'):
        if fixture.count(token) != 1:
            die(f'{fixture_path} writes {fixture.count(token)} occurrences of '
                f'`{token}`; the recipe under test writes exactly one')
    if not (fixture.index(REFS_OPEN) < fixture.index(MARKER_OPEN)
            < fixture.index('{#' + AFTER_ID + '}')):
        die(f'{fixture_path} does not write the `#refs` div, then the '
            f'placement marker, then the `{AFTER_ID}` section; the orders '
            f'below are stated over that shape')

    cut = cut_block(fixture, REFS_OPEN, '`#refs` div', fixture_path)
    if cut != twin:
        die(f'{twin_path} is not {fixture_path} with its `#refs` div block '
            f'deleted; the two have drifted apart and the orders below would '
            f'be two different documents\' orders')
    print(f'ok   M32: the twin fixture is the references fixture with the '
          f'`#refs` div block deleted, and nothing else')


# ---------------------------------------------------------------------------
# latex — AC1/AC3. The reference environment is named, not guessed at by
# offset into the prose, and `\printindex` is the one command that prints the
# index. Each must appear exactly once in each artifact before any order over
# them means anything: a file carrying no bibliography at all would otherwise
# pass the "index comes first" half.
# ---------------------------------------------------------------------------
OPEN, CLOSE, INDEX = (r'\begin{CSLReferences}', r'\end{CSLReferences}',
                      r'\printindex')
AFTER_TEX = r'\label{%s}' % AFTER_ID


def tex_places(path):
    src = open(path, encoding='utf-8').read()
    where = {}
    for name in (OPEN, CLOSE, INDEX, AFTER_TEX):
        if src.count(name) != 1:
            die(f'{path} carries {src.count(name)} occurrences of {name}; the '
                f'order below is stated over exactly one of each')
        where[name] = src.index(name)
    return where


def latex(fixture_path, twin_path):
    withdiv, without = tex_places(fixture_path), tex_places(twin_path)
    if not withdiv[INDEX] > withdiv[CLOSE]:
        die(f'AC1: in {fixture_path} the index command does not follow the '
            f'reference environment')
    # The marker clause. Without it the check above passes on a document
    # carrying no placement marker, since an index appended at the end of the
    # body also follows a bibliography Quarto filled in place.
    if not withdiv[INDEX] < withdiv[AFTER_TEX]:
        die(f'AC1: in {fixture_path} the index command does not precede '
            f'{AFTER_TEX}, so it is not at the placement marker but at the end '
            f'of the document; the marker half of the recipe is untested')
    if not without[INDEX] < without[OPEN]:
        die(f'AC3: in {twin_path}, which writes no `#refs` div, the index '
            f'command does not precede the reference environment; the default '
            f'order is not what the recipe moves')
    if not without[INDEX] < without[AFTER_TEX]:
        die(f'AC3: in {twin_path} the index command does not precede '
            f'{AFTER_TEX}, so it is not at the placement marker')
    print(r'ok   M32-AC1/AC3: \printindex sits at the placement marker in both '
          r'artifacts, following \end{CSLReferences} in the fixture that '
          r'writes an empty #refs div and preceding \begin{CSLReferences} in '
          r'the twin that writes none')


# ---------------------------------------------------------------------------
# html — AC2/AC3. Element identity, not text position: the references are the
# element carrying the id `refs` AND the classes Quarto's bibliography writer
# puts on it, and the index is the element carrying the generated section id —
# required to be the same node the index heading sits in, so an id landing on
# some other element could not stand in for it.
#
# The appendix clause is the recipe's cost: when Quarto appends the reference
# block itself it wraps it in `#quarto-appendix` with `role="doc-bibliography"`
# and a References heading, and an author-written `#refs` div gets none of
# that. README says so, and this is what holds that true.
# ---------------------------------------------------------------------------
REF_CLASSES = {'references', 'csl-bib-body'}
APPENDIX_ID = 'quarto-appendix'
BIB_ROLE = 'doc-bibliography'


def has_role(doc, role):
    return any(n.attrs.get('role') == role for n in H.walk(doc))


def html_places(path, section_id):
    doc = H.parse(path)
    refs = H.find_id(doc, 'refs')
    if refs is None:
        die(f'{path} carries no element with the id `refs`, so it holds no '
            f'rendered bibliography to order the index against')
    if not REF_CLASSES <= H.classes(refs):
        die(f'the `refs` element of {path} is a <{refs.tag}> carrying '
            f'{sorted(H.classes(refs))}; the bibliography Quarto writes '
            f'carries {sorted(REF_CLASSES)}')
    section = H.find_id(doc, section_id)
    if section is None:
        die(f'{path} carries no element with the generated index section id '
            f'`{section_id}`')
    if H.index_section(doc) is not section:
        die(f'in {path} the element carrying `{section_id}` is not the section '
            f'the index heading sits in, so its position is not the index\'s '
            f'position')
    after = H.find_id(doc, AFTER_ID)
    if after is None:
        die(f'{path} carries no element with the id `{AFTER_ID}`; without the '
            f'section that follows the marker there is nothing to tell an '
            f'index at the marker apart from one at the end of the document')
    return (doc, H.position(doc, refs), H.position(doc, section),
            H.position(doc, after))


def html(fixture_path, twin_path):
    section_id = os.environ['HTML_SECTION_ID']
    fdoc, f_refs, f_index, f_after = html_places(fixture_path, section_id)
    tdoc, t_refs, t_index, t_after = html_places(twin_path, section_id)

    if not f_index > f_refs:
        die(f'AC2: in {fixture_path} the index section (document position '
            f'{f_index}) does not follow the bibliography ({f_refs})')
    if not f_index < f_after:
        die(f'AC2: in {fixture_path} the index section ({f_index}) does not '
            f'precede the `{AFTER_ID}` section ({f_after}), so it is not at '
            f'the placement marker but at the end of the body; the marker half '
            f'of the recipe is untested')
    if not t_index < t_refs:
        die(f'AC3: in {twin_path}, which writes no `#refs` div, the index '
            f'section ({t_index}) does not precede the bibliography ({t_refs}); '
            f'the default order is not what the recipe moves')
    if not t_index < t_after:
        die(f'AC3: in {twin_path} the index section ({t_index}) does not '
            f'precede the `{AFTER_ID}` section ({t_after}), so it is not at '
            f'the placement marker')

    # The cost, both ways round. Stated over the pair rather than over the
    # fixture alone: "no appendix here" is only a cost if the same document
    # without the div gets one.
    if H.find_id(fdoc, APPENDIX_ID) is not None or has_role(fdoc, BIB_ROLE):
        die(f'{fixture_path}, which writes its own `#refs` div, carries the '
            f'`{APPENDIX_ID}` block or a `{BIB_ROLE}` element; README tells an '
            f'author following the recipe that HTML gives them neither')
    if H.find_id(tdoc, APPENDIX_ID) is None or not has_role(tdoc, BIB_ROLE):
        die(f'{twin_path}, which lets Quarto append the reference block, '
            f'carries no `{APPENDIX_ID}` block or no `{BIB_ROLE}` element; '
            f'there is then no cost for the recipe to have, and README says '
            f'there is one')
    print(f'ok   M32-AC2/AC3: the generated index section sits at the '
          f'placement marker in both, following the bibliography div in the '
          f'fixture that writes an empty #refs div ({f_refs} then {f_index}) '
          f'and preceding it in the twin that writes none ({t_index} then '
          f'{t_refs}); the appendix wrapper Quarto builds is in the twin and '
          f'not in the fixture')


if __name__ == '__main__':
    mode, args = sys.argv[1], sys.argv[2:]
    {'derive': derive, 'latex': latex, 'html': html}[mode](*args)
