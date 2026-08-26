"""Plant one defect into a rendered gallery page (M41 T6).

The gallery's checks read rendered HTML structurally, so their planted cases
have to be put into rendered HTML. Each mode here makes ONE substitution and
then re-reads the mutated file with the same reader the check uses, so a
mutation that landed somewhere harmless — or nowhere at all — is a failure
here rather than a green plant the check never had to catch.

  bytes-off <page.html>
      Change one character of the TEXT inside the page's `<pre><code>` block,
      leaving the block's length alone. The source-block check must then read a block that is not
      its fixture's bytes.

  double-entity <page.html>
      Turn one `&amp;` inside that block into `&amp;amp;`. Decoded, the block
      now reads `&amp;` where the fixture has `&`. A check that skipped
      entity decoding — or decoded and did not compare — would not notice.

  drop-entry <page.html> <term>
      Take one entry out of the page's generated index, and confirm with
      tests/htmlindex.py that the printed entry set lost exactly that term and
      is not empty. The embedded-index check must then report that term
      missing, rather than reporting a page with no index at all.

Every mode prints what it changed. Exits non-zero, with a `FAIL:` line, if the
substitution changed nothing or did not have the effect it claims.
"""

import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402

CODE_BLOCK = re.compile(r'(<pre[^>]*>\s*<code[^>]*>)(.*?)(</code>)', re.S)


def fail(message):
    print('FAIL: M41 plant: ' + message, file=sys.stderr)
    return 1


def code_block(text, path):
    match = CODE_BLOCK.search(text)
    if match is None:
        raise SystemExit(fail('%s carries no <pre><code> block to plant into'
                              % path))
    return match


def rewrite(path, text):
    with open(path, 'w', encoding='utf-8') as handle:
        handle.write(text)


def read(path):
    with open(path, encoding='utf-8') as handle:
        return handle.read()


def block_text(path):
    """The block's text content, as the check reads it."""
    root = H.parse(path)
    return [H.text(code)
            for pre in H.find_all(root, tag='pre')
            for code in H.find_all(pre, tag='code')]


def plant_bytes_off(page):
    text = read(page)
    before = block_text(page)
    match = code_block(text, page)
    body = match.group(2)
    # The first alphabetic character of the block's TEXT, swapped for another.
    # One character, same length: a check comparing lengths and not bytes
    # would still see the block it expected. The markup is skipped — Quarto
    # highlights the block, so the raw bytes here open with a `<span>` whose
    # tag name is not text a reader sees, and changing that would plant a
    # defect in the highlighting rather than in the source.
    spot = None
    in_tag = False
    for i, char in enumerate(body):
        if char == '<':
            in_tag = True
        elif char == '>':
            in_tag = False
        elif not in_tag and char.isalpha():
            spot = i
            break
    if spot is None:
        return fail('%s: the block\'s text carries no alphabetic character to '
                    'change' % page)
    swapped = 'x' if body[spot] != 'x' else 'y'
    body = body[:spot] + swapped + body[spot + 1:]
    rewrite(page, text[:match.start(2)] + body + text[match.end(2):])
    after = block_text(page)
    if after == before:
        return fail('%s: the one-character substitution left the block\'s '
                    'text content unchanged' % page)
    print('planted: %s, one character of the block\'s text is now %r where '
          'the fixture has %r' % (page, swapped, match.group(2)[spot]))
    return 0


def plant_double_entity(page):
    text = read(page)
    before = block_text(page)
    match = code_block(text, page)
    body = match.group(2)
    if '&amp;' not in body:
        return fail('%s: the block carries no `&amp;` to double, so this mode '
                    'cannot say anything about entity decoding here' % page)
    body = body.replace('&amp;', '&amp;amp;', 1)
    rewrite(page, text[:match.start(2)] + body + text[match.end(2):])
    after = block_text(page)
    if after == before:
        return fail('%s: doubling one entity left the block\'s decoded text '
                    'unchanged' % page)
    if not any('&amp;' in one for one in after):
        return fail('%s: the doubled entity did not decode to `&amp;` in the '
                    'block\'s text, so the plant is not the one this mode '
                    'claims' % page)
    print('planted: %s, one `&amp;` in the block is now `&amp;amp;`, which '
          'decodes to `&amp;` where the fixture has `&`' % page)
    return 0


def printed_entries(page, minted, prefix):
    rows = H.section_rows(H.parse(page), prefix, minted)
    return [r.split('\t')[1] for r in rows
            if r.split('\t')[0].isdigit() and len(r.split('\t')) > 1]


def plant_drop_entry(page, term):
    minted = (os.environ['HTML_SECTION_ID'], os.environ['HTML_ANCHOR_PREFIX'],
              os.environ['HTML_ENTRY_PREFIX'])
    prefix = os.environ['HTML_SECTION_ID']
    before = printed_entries(page, minted, prefix)
    if term not in before:
        return fail('%s prints no index entry %r, so there is nothing here to '
                    'drop; it prints %d entry(s)' % (page, term, len(before)))
    text = read(page)
    # The generated index is the last place the term appears on the page: the
    # body mentions it where it was marked, and the index prints it after. The
    # effect of that assumption is checked below, not assumed.
    needle = html.escape(term, quote=False)
    at = text.rfind(needle)
    if at < 0:
        needle = term
        at = text.rfind(needle)
    if at < 0:
        return fail('%s: neither %r nor its escaped form appears in the '
                    'markup at all' % (page, term))
    text = text[:at] + 'PLANTED-GONE' + text[at + len(needle):]
    rewrite(page, text)
    after = printed_entries(page, minted, prefix)
    if not after:
        return fail('%s: dropping %r left the page printing no index entry at '
                    'all; the plant must remove one entry, not the index'
                    % (page, term))
    if term in after:
        return fail('%s: %r is still among the printed entries, so the '
                    'substitution landed outside the index' % (page, term))
    lost = [one for one in before if one not in after]
    if lost != [term]:
        return fail('%s: dropping %r changed the printed entry set by %s, not '
                    'by that one term' % (page, term, lost))
    print('planted: %s still prints %d index entry(s), as it did before, and '
          '%r is no longer one of them' % (page, len(after), term))
    return 0


MODES = {
    'bytes-off': (plant_bytes_off, 1),
    'double-entity': (plant_double_entity, 1),
    'drop-entry': (plant_drop_entry, 2),
}


def main(argv):
    if len(argv) < 2 or argv[1] not in MODES:
        raise SystemExit(__doc__)
    func, needed = MODES[argv[1]]
    args = argv[2:]
    if len(args) != needed:
        raise SystemExit(__doc__)
    return func(*args)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
