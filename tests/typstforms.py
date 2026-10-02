"""Copies of a Typst PDF in the forms Quarto 1.5.52's Typst writes (M108).

tests/typstindex.py reads three things a Typst 0.11 PDF, the one Quarto 1.5.52
bundles, writes differently from the Typst the pinned Quarto bundles. The
self-test runs on the pinned Quarto, so it makes each form here, from a PDF
the pinned Quarto rendered, and reads the copy: once as made, which must
match the manifest, and once with one defect planted, which must not.

  links <in.pdf> <out.pdf> [--drop N]
      Each page's link annotations written inside its `/Annots` array, each
      destination as the `/D` of a `/GoTo` action, and each rectangle with its
      top corner first, as Typst 0.11 writes them. `--drop N` leaves out the
      Nth link annotation of the file, counted from 1 in page order.

  faces <in.pdf> <out.pdf> [--plant bold|italic]
      Every font name with `Bold` or `Italic` in it renamed, letter for
      letter, to one without, as Typst 0.11 names its faces `LinLibertineB`
      and `LinLibertineI`. `--plant bold` also gives the bold face's
      descriptor the regular face's /StemV, and `--plant italic` clears the
      italic face's italic flag.

  ligature <in.pdf> <out.pdf> [--plant]
      The `fi` ligature glyph mapped to the one character U+FB01 in every
      font's /ToUnicode map, as Typst 0.11 maps it, where the pinned Quarto's
      Typst maps it to the two letters. `--plant` maps it to U+FB02, the `fl`
      ligature, so a term spelled with `fi` reads with `fl`.

Each mode exits 1 with a FAIL line when the input carries nothing for it to
rewrite, so a copy is never the input unchanged. The copies' cross-reference
tables no longer match their offsets; poppler rebuilds them, and
tests/typstindex.py reads objects by their `obj` lines and never uses them.
"""

import re
import sys
import zlib

import typstindex


def fail(message):
    print(f'FAIL: {message}', file=sys.stderr)
    sys.exit(1)


def links(data, drop):
    objects = typstindex._objects(data)
    seen = [0]

    def inline(match):
        out = []
        for ref in re.findall(rb'(\d+)\s+0\s+R', match.group(1)):
            body = objects[int(ref)].strip()
            if not (body.startswith(b'<<')
                    and re.search(rb'/Subtype\s*/Link\b', body)):
                out.append(ref + b' 0 R')
                continue
            seen[0] += 1
            if seen[0] == drop:
                continue
            body = body[2:-2]
            dest = re.search(rb'/Dest\s*(\d+)\s+0\s+R', body)
            if dest is None:
                fail(f'link annotation {ref.decode()} carries no /Dest '
                     f'reference to rewrite')
            array = objects[int(dest.group(1))].strip()
            body = (body[:dest.start()] + b'/A<</Type/Action/S/GoTo/D' + array
                    + b'>>' + body[dest.end():])
            rect = re.search(rb'/Rect\s*\[([^\]]*)\]', body)
            x0, y0, x1, y1 = rect.group(1).split()
            body = (body[:rect.start()] + b'/Rect[' + b' '.join([x0, y1, x1, y0])
                    + b']' + body[rect.end():])
            out.append(b'<<' + body + b'>>')
        return b'/Annots[' + b' '.join(out) + b']'

    data = re.sub(rb'/Annots\s*\[([^\]]*)\]', inline, data)
    if seen[0] == 0:
        fail('no page carries a link annotation to rewrite')
    if drop and drop > seen[0]:
        fail(f'--drop {drop} names a link past the {seen[0]} the file carries')
    return data


def faces(data, plant):
    renamed = {b'Bold': b'Bxxx', b'Italic': b'Ixxxxx'}
    count = 0
    for old, new in renamed.items():
        data, n = re.subn(rb'(/(?:BaseFont|FontName)\s*/[^\s/\[\]<>()]*)'
                          + old, rb'\1' + new, data)
        count += n
    if count == 0:
        fail('no font name carries Bold or Italic to rename')
    if plant is None:
        return data
    word = b'Bxxx' if plant == 'bold' else b'Ixxxxx'
    found = re.search(rb'/FontDescriptor\s*/FontName\s*/[^\s/]*' + word, data)
    if found is None:
        fail(f'no font descriptor names the renamed {plant} face')
    end = data.index(b'>>', found.end())
    desc = data[found.start():end]
    if plant == 'bold':
        new, n = re.subn(rb'/StemV\s+[\d.]+', b'/StemV 95.4', desc)
    else:
        flags = int(re.search(rb'/Flags\s+(\d+)', desc).group(1))
        new, n = re.subn(rb'/Flags\s+\d+',
                         b'/Flags %d' % (flags & ~typstindex.ITALIC_FLAG), desc)
    if n != 1 or new == desc:
        fail(f'the {plant} face\'s descriptor carries nothing to plant')
    return data[:found.start()] + new + data[end:]


def ligature(data, plant):
    target = b'<FB02>' if plant else b'<FB01>'
    count = [0]

    def remap(match):
        header, body = match.group(1), match.group(2)
        if b'/FlateDecode' not in header:
            return match.group(0)
        text = zlib.decompress(body)
        text, n = re.subn(rb'<00660069>', target, text, flags=re.I)
        if n == 0:
            return match.group(0)
        count[0] += n
        packed = zlib.compress(text)
        header = re.sub(rb'/Length\s+\d+', b'/Length %d' % len(packed), header)
        return header + b'stream\n' + packed + b'\nendstream'

    data = re.sub(rb'(<<(?:(?!>>).)*?/Type\s*/CMap(?:(?!stream).)*?)'
                  rb'stream\r?\n(.*?)\r?\nendstream', remap, data, flags=re.S)
    if count[0] == 0:
        fail('no /ToUnicode map carries the fi ligature to remap')
    return data


def main(argv):
    mode, source, target = argv[1:4]
    rest = argv[4:]
    data = open(source, 'rb').read()
    if mode == 'links':
        drop = int(rest[1]) if rest[:1] == ['--drop'] else 0
        data = links(data, drop)
    elif mode == 'faces':
        plant = rest[1] if rest[:1] == ['--plant'] else None
        if plant not in (None, 'bold', 'italic'):
            fail(f'--plant takes bold or italic, not {plant!r}')
        data = faces(data, plant)
    elif mode == 'ligature':
        data = ligature(data, rest == ['--plant'])
    else:
        fail(f'no mode {mode!r}; the modes are links, faces and ligature')
    open(target, 'wb').write(data)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
