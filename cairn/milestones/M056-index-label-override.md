# M056: An author sets the words the index back-end picks itself

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP4, GP5
- **Branch/PR:** —

## Goal

An author can set the three English words the HTML and EPUB index back-end
emits on its own — `Symbols`, `see` and `see also` — for a whole document or
for one index.

## Scope

Surface tier: **user-facing** — the deliverable is a metadata surface authors
write and words a reader sees in a published index.

**In:** a `labels:` map holding `symbols`, `see` and `see-also`, read at the
document's top level and inside one `indexes:` entry, the nearer setting
winning key by key and English the fallback (D-036); the three words resolved
through it in `html.lua` and `core.lua`; reports for a `labels:` that is not a
map, an unknown key in one, and a key whose value is empty, each falling back
rather than half-installing; the editor schema and snippets; fixtures, suite
rows and documentation.

**Out:** the shipped translation table and any reading of `lang:` → M057, which
depends on this. The untitled heading's default → M057 (D-037); `title:`
already overrides it and is untouched here. Locator punctuation as a fourth
label → candidate row. The LaTeX back-end, which localizes through babel
already and gains nothing here.

## Acceptance criteria

- [ ] AC1. A document writing a top-level `labels:` with all three keys
      renders to HTML with the non-letter group heading and the two
      cross-reference labels printing exactly those three strings. Evidence:
      the suite's exhaustive HTML index manifest for the fixture, which
      enumerates every group heading and every entry line of the section,
      carries the three declared strings and none of `Symbols`, `see`,
      `see also`.
- [ ] AC2. A per-index `labels:` overrides the document-level one key by key,
      not map by map: in a fixture declaring two indexes where the document
      sets all three keys and one index resets only `see`, that index prints
      its own `see` word with the document's other two, and the second index
      prints all three of the document's. Evidence: the same manifest over
      both sections.
- [ ] AC3. The same fixture rendered to EPUB prints the same words in the same
      places. Evidence: `tests/epubindex.py` over the built EPUB.
- [ ] AC4. The keys stay optional and English stays the default: a twin
      fixture carrying the same marks and no `labels:` anywhere prints
      `Symbols`, `see` and `see also`, and `examples/letter-groups.qmd` and
      `examples/resolving-xref.qmd` render the same index output they render
      today. Evidence: the twin's manifest, and the two existing fixtures'
      manifests passing with no row edited.
- [ ] AC5. Each of three unusable shapes draws one message and leaves the
      words falling back to the next level and then to English: a `labels:`
      that is not a map is reported naming the level it was written at, and an
      unknown key inside one and a key whose value is empty are each reported
      naming that key and its level. Evidence: the misuse fixture's log, each
      message asserted whole rather than by substring, and its manifest showing
      the fallback words.
- [ ] AC6. No `labels:` declaration reaches the LaTeX back-end: the complete
      `diff` of the labels fixture's `.tex` against its no-labels twin's is
      empty. Evidence: the diff itself, which enumerates every difference
      exhaustively rather than sampling emission sites; a non-empty diff fails
      the criterion whatever the differing lines say.
- [ ] AC7. `site/letter-groups.qmd`, `site/cross-references.qmd` and
      `site/back-end-differences.qmd` each state the `labels:` map, its three
      keys, the two levels it is written at, and that it reaches HTML and EPUB
      only. Evidence: a read of the three pages against that list.
- [ ] AC8. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
      0.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T1, T2, T3, T4
- AC3 → T2, T3, T4
- AC4 → T3, T4
- AC5 → T1, T3, T4
- AC6 → T3, T4
- AC7 → T6
- AC8 → T4

## Tasks

- [ ] T1. Read and validate `labels:` in `_extensions/index/modules/indexes.lua`
      at both levels, following `read_declaration`'s existing report-and-fall-
      back discipline (lines 80–116); export a resolver taking an index name
      and a key and returning the nearer declared string or the English
      default.
- [ ] T2. Point `html.lua:45`'s group heading and `core.lua:24-27`'s two
      `XREF_KINDS` labels at that resolver, leaving `latex.lua`'s use of the
      same rows untouched.
- [ ] T3. Fixtures: a two-index document declaring `labels:` at both levels, a
      twin declaring none, and a misuse document carrying the three unusable
      shapes. Give each new mark a term no other mark in its file indexes.
- [ ] T4. Suite: HTML manifest rows for both new fixtures, the EPUB read, the
      LaTeX twin comparison, the message-whole warning assertions, and a
      planted defect proving each new check can go red.
- [ ] T5. Add `labels:` and its three keys to `_extensions/index/_schema.yml`
      and `_snippets.json`.
- [ ] T6. Documentation: the three site pages named in AC7, plus a
      `CHANGELOG.md` entry naming the new metadata surface.

## Work log

- 2026-08-28: created by /milestone-plan, after RB02/RR02 settled the approach.
- 2026-08-28: criteria audit ran in FULL mode (declared tier user-facing), one fresh-context [O] reader over both files' criteria; it returned six findings across the two, all fixed at the gate — instrument-bound promises in this file's AC4 and in M057's AC5, an unsatisfiable message wording in this file's AC5, unbounded universals in this file's AC6 and M057's AC7, and a set-level gap in M057 where no criterion bound the shipped words' correctness. Its seventh point, that the suite-green AC is instrument-bound, was left standing as a template-mandated criterion. A re-audit of the changed wording was commissioned and had not returned when this was committed.
- 2026-08-28: plan gate chose a nested `labels:` map over three flat fields beside `title:` because a flat `see:` collides with the mark attribute `see=`, where the same word names a target rather than a label (D-036); falsified by an author needing a per-index word these three keys cannot express.
- 2026-08-28: plan gate chose two declaration levels over per-index only because an undeclared document cannot override without inventing an index name, which moves the section id and breaks inbound links; falsified by the two levels proving indistinguishable in practice.
- 2026-08-28: plan gate chose splitting the override surface from the shipped table over one milestone because the surface is a permanent naming decision and the table is a data asset, each reviewable alone; falsified by the split forcing a rework of the resolver when M057 wires `lang:` beneath it.

## Decisions

## Review
