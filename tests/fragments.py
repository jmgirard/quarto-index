"""Where a captured index's locators land (M071).

  resolve <root> <page>
      Every locator of every generated index section on <page> — a path
      relative to <root>, the capture directory — is read. Each href carrying
      a fragment is resolved against the page it names, a relative path from
      <page> or <page> itself for a fragment-only href, and that page, read
      from <root>, must carry an element with that id. A page the capture
      lacks is a failure naming it; so is a fragment the named page does not
      carry. A locator with no fragment is counted and not judged: it names a
      page and nothing after it, and whether the page is there is what the
      page-lacking clause says about the ones that do. The mode fails on an
      empty domain — <page> must carry at least one generated section, and at
      least one locator across them must carry a fragment — so a page with no
      index, or an index whose locators are all page-only, cannot pass as
      "every fragment resolved".

  inside <html> <container-id> <id>...
      The element carrying <container-id> is on the page exactly once, and
      each listed id is on the page exactly once, inside that element.

  outside <html> <container-id> <id>...
      The same, except each listed id sits outside that element.

The section, anchor and entry prefixes are read from HTML_SECTION_ID,
HTML_ANCHOR_PREFIX and HTML_ENTRY_PREFIX in the environment, as every other
reader of the generated sections reads them, so the domain here is the same
set of sections the manifests are checked against. This module reads the
ARTIFACT and produces no expected value.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import htmlindex as H  # noqa: E402


def fail(message):
    print('FAIL: %s' % message, file=sys.stderr)
    return 1


def minted():
    return (os.environ['HTML_SECTION_ID'], os.environ['HTML_ANCHOR_PREFIX'],
            os.environ['HTML_ENTRY_PREFIX'])


def resolve(root, page):
    prefix = os.environ['HTML_SECTION_ID']
    doc = H.parse(os.path.join(root, page))
    sections = H.index_sections(doc, prefix, minted())
    if not sections:
        return fail('%s carries no generated index section, so there is no '
                    'locator here to resolve' % page)
    ids = {}
    locators = fragments = 0
    for found in sections:
        for record in found['records']:
            if record['kind'] != 'entry':
                continue
            for href in record['locators']:
                locators += 1
                resolved = H.resolve_href(page, href)
                if resolved is None:
                    return fail('%s: %r in section %s links out of the site, '
                                'to %r' % (page, record['term'], found['ident'],
                                           href))
                target, fragment = resolved
                if not fragment:
                    continue
                fragments += 1
                if target not in ids:
                    path = os.path.join(root, target)
                    if not os.path.isfile(path):
                        return fail('%s: %r in section %s links to %r, and %s '
                                    'is no page of the capture'
                                    % (page, record['term'], found['ident'],
                                       href, target))
                    ids[target] = set(H.all_ids(H.parse(path)))
                if fragment not in ids[target]:
                    return fail('%s: %r in section %s links to %r, and %s '
                                'carries no id %r'
                                % (page, record['term'], found['ident'], href,
                                   target, fragment))
    if fragments == 0:
        return fail('%s: none of the %d locator(s) across %d section(s) '
                    'carries a fragment, so this mode resolved nothing'
                    % (page, locators, len(sections)))
    print('ok   %s: every fragment among its %d locator(s) across %d '
          'section(s) names an id the page it links to carries (%d '
          'fragment(s), %d page(s) read)'
          % (page, locators, len(sections), fragments, len(ids)))
    return 0


def containment(path, container, wanted, want_inside):
    doc = H.parse(path)
    name = os.path.basename(path)
    if H.count_id(doc, container) != 1:
        return fail('%s carries the id %r %d time(s), want exactly 1'
                    % (name, container, H.count_id(doc, container)))
    box = H.find_id(doc, container)
    within = {n.attrs['id'] for n in H.walk(box) if n.attrs.get('id')}
    for identifier in wanted:
        count = H.count_id(doc, identifier)
        if count != 1:
            return fail('%s carries the id %r %d time(s), want exactly 1'
                        % (name, identifier, count))
        if want_inside and identifier not in within:
            return fail('%s: the id %r sits outside the element %r'
                        % (name, identifier, container))
        if not want_inside and identifier in within:
            return fail('%s: the id %r sits inside the element %r'
                        % (name, identifier, container))
    print('ok   %s: %d id(s) each on the page once and %s the element %r: %s'
          % (name, len(wanted), 'inside' if want_inside else 'outside',
             container, ' '.join(wanted)))
    return 0


def main(argv):
    if len(argv) == 4 and argv[1] == 'resolve':
        return resolve(argv[2], argv[3])
    if len(argv) >= 5 and argv[1] in ('inside', 'outside'):
        return containment(argv[2], argv[3], argv[4:], argv[1] == 'inside')
    raise SystemExit(__doc__)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
