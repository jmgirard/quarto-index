#!/usr/bin/env bash
#
# quarto-index acceptance tests. Checks labelled AC<n> are M01's criteria;
# those labelled M02-AC<n> are M02's, which are numbered in their own
# milestone and would otherwise collide.
#
# ORACLE RULE — READ BEFORE EDITING A MANIFEST.
# Every manifest row below is derived BY HAND from the `.qmd` source and the
# documented semantics at each layer, in this order:
#   1. Pandoc attribute-value unescaping (a quoted span attribute loses one
#      backslash level: `\!` -> `!`, `\\` -> `\`, `\"` -> `"`), and markdown
#      backslash-unescaping in visible text.
#   2. The extension's level parse: a single `!` separates sub-entry levels,
#      `!!` is a literal `!`, scanned left-to-right longest-match.
#   3. Escaping of each literal level: LaTeX specials escaped, `!` and `@`
#      makeindex-quoted, `|` and `"` emitted as LaTeX commands (see the
#      milestone's Decisions entry), and levels past the third folded into
#      the third, joined with `, `.
# Manifest rows are NEVER copied from filter output. A row that disagrees with
# the rendered result means either the derivation or the filter is wrong, and
# both are inspected before either is changed. Copying output into a manifest
# turns this suite into a snapshot test and destroys its value as an oracle.
#
# Usage:  tests/run-tests.sh            run the acceptance checks
#         tests/run-tests.sh --self-test  also run the planted-defect self-test

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Internal: check one .tex against the demo manifest and exit with its status.
# The AC5 self-test invokes the script this way, so the criterion's "it exits
# non-zero" is asserted of the script itself, not merely of a helper function.
# This mode must not wipe the work directory — the fixture it is given lives
# there, written by the parent invocation.
if [ "${1:-}" = "--fixture-check" ]; then
  FIXTURE_MODE=1
else
  FIXTURE_MODE=0
fi

WORK="tests/.work"
[ "$FIXTURE_MODE" = "1" ] || rm -rf "$WORK"
mkdir -p "$WORK"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok   %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Supported forms (NORMATIVE). The README documents exactly these span forms
# and no others. Each row is <label><TAB><exemplar>: the exemplar is the exact
# syntax, and the check below fails unless it appears verbatim in README.md.
# A form the extension grows must therefore be documented in the same change,
# and a documented form cannot drift from the one this suite exercises.
# ---------------------------------------------------------------------------
SUPPORTED_FORMS=(
  $'visible-term span\t[term]{.index}'
  $'custom-entry span\t[term]{.index entry="Entry"}'
  $'sub-entry span\t[term]{.index entry="Top!Sub"}'
  $'invisible-entry span\t[]{.index entry="Entry"}'
  $'see cross-reference\t[term]{.index see="Other"}'
  $'see-also cross-reference\t[term]{.index see-also="Other"}'
)

# ---------------------------------------------------------------------------
# README claims about the HTML back-end (NORMATIVE, M03-AC7). Same discipline
# as SUPPORTED_FORMS: the bytes are compared, not a count, so the docs and the
# behavior this suite exercises cannot drift apart.
#
# README_STALE names sentences that described a world with one back-end. Each
# must be GONE, or the README is telling a reader that HTML passes marks
# through untouched.
# ---------------------------------------------------------------------------
README_STALE=(
  $'pass-through scope\tformats with no index back-end — HTML and beamer'
  $'cross-reference pass-through\tIn formats with no index back-end, a cross-reference mark is simply a mark'
  $'one back-end\tLaTeX/PDF is the back-end that ships today'
)

# Each must be PRESENT: one beamer-scoped pass-through sentence, and one row
# per way the two back-ends diverge. A divergence a reader is not told about is
# a bug report waiting to be filed.
README_HTML_CLAIMS=(
  $'beamer pass-through\tIn beamer, and in any other format with no index back-end, marks pass through'
  $'no level ceiling\tNo level ceiling in HTML'
  $'clash warning scope\tThe clash warning is LaTeX-only'
  $'collation rule\tEntries sort by folding ASCII uppercase to lowercase, then by character code, with a tie broken by character code'
  $'numbered locator links\tLocators are numbered links in HTML'
  $'targets hyperlinked\tCross-reference targets are hyperlinked in HTML'
  $'no locator from a cross-reference\tA cross-reference carries no locator in either back-end'
)

# Escaping probe set (NORMATIVE): every character below appears independently
# in a visible term and in an `entry=` level in examples/demo.qmd, across
# leading, medial and trailing positions (union coverage, not the
# cross-product), plus `!!` leading/medial/trailing, one odd-length `!` run,
# one empty level, a one-backslash level, one `\!` pin, one entry deeper than
# three levels, and one Latin-1 accented term in each context. The character
# set is the escape domain: Pandoc's LaTeX-writer escapes plus makeindex's
# active characters. It is asserted below to equal the filter's own table, so
# a character the filter handles can never go unprobed.
PROBE_CHARS='% & # _ { } \ ~ ^ $ @ | ! " < >'

# ---------------------------------------------------------------------------
# Manifest 1 — expected \index{} entries in examples/demo.tex (AC1).
# Format: <count><TAB><exact \index{} argument text>
# ---------------------------------------------------------------------------
read -r -d '' DEMO_ENTRIES <<'MANIFEST' || true
3	pandoc
1	Custom Entry
1	Top!Middle!Leaf
1	Ghost!Sub
1	"!Bang leads
1	Wow"!Really
1	Trail bang"!
1	A"!!B
1	\textbackslash{}
1	Alpha!Beta
1	A"!B!
1	One!Two!Three, Four, Five
1	pct \% amp \& hash \#
1	us \_ brace \textbraceleft{} \textbraceright{}
1	bs \textbackslash{} tilde \textasciitilde{} caret \textasciicircum{}
1	dollar \$ at "@ bar \textbar{}
1	bang "! quote \textquotedbl{}
1	Specials \% \& \# \_ \textbraceleft{} \textbraceright{} \textbackslash{} \textasciitilde{} \textasciicircum{} \$ "@ \textbar{} "! \textquotedbl{} \textless{} \textgreater{}
1	\textbraceleft{}Braced\textbraceright{}
1	\textasciitilde{}tilde dollar\$
1	less \textless{} more \textgreater{}
1	café naïve
1	Grüße!Straße
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1b — expected cross-reference \index{} arguments (M02-AC1).
# Same oracle rule as manifest 1, with two further layers derived by hand:
#   4. The target parse: same `!`/`!!` level semantics as `entry=`, with an
#      empty level dropped rather than kept.
#   5. The emission form recorded in M02's Decisions section: a single-target
#      mark emits `<source>|see{<target>}` or `|seealso{...}`, a mark carrying
#      both emits one command, `|quartoindexseeboth{<see>}{<see-also>}`, and
#      target levels join with `: `.
# ---------------------------------------------------------------------------
read -r -d '' XREF_ENTRIES <<'MANIFEST' || true
1	cats|see{Felines}
1	dogs|seealso{Pets}
1	owls|see{Birds: Owls}
1	bang|see{Wow"!Hey}
1	Canids!Foxes|see{Vulpes}
1	Ghosts|seealso{Spirits}
1	both|quartoindexseeboth{Aye}{Bee}
MANIFEST

# The dual-target command, named once. The check below pins it to the filter's
# own constant, so the manifest cannot go on describing a form the filter has
# renamed.
XREF_BOTH_COMMAND='quartoindexseeboth'

# The HTML back-end's pinned identifiers. Named once here and pinned to the
# filter's own constants below, so the suite cannot go on checking names the
# filter has renamed.
HTML_SECTION_ID='qi-index'
HTML_ANCHOR_PREFIX='qi-mark-'
HTML_ENTRY_PREFIX='qi-entry-'

# ---------------------------------------------------------------------------
# Manifest 1e — the generated index in examples/demo.html (M03-AC2).
# EXHAUSTIVE: a rendered entry absent from this list fails, as does a listed
# entry the render does not produce.
# Format: <depth><TAB><entry text><TAB><locator count>[<TAB><cross-reference>]…
# where a cross-reference is `see-plain`/`see-link`/`also-plain`/`also-link`,
# a space, and the target as a reader sees it.
# Same oracle rule as manifest 1, with the HTML back-end's own layers derived
# by hand on top of the level parse:
#   4. No level ceiling: the three-level clamp is a makeindex property, so
#      `One!Two!Three!Four!Five!` nests six deep here, trailing empty level
#      included.
#   5. Order: fold ASCII uppercase to lowercase, compare by codepoint, break a
#      fold tie by codepoint — applied to siblings at every depth.
#   6. Locators: one per locator-contributing mark on that entry, in document
#      order. A cross-reference mark contributes none.
#   7. Cross-reference targets join with `: ` and are hyperlinked exactly when
#      the target's LEVEL LIST is an entry in this index. No target in
#      demo.qmd names an entry, so every row here is `plain`; the linked and
#      colliding-string cases live in xref-conflict.qmd (M03-AC4).
# ---------------------------------------------------------------------------
read -r -d '' DEMO_HTML_INDEX <<'MANIFEST' || true
0	!Bang leads	1
0	\	1
0	A!	0
1	B	1
0	A!B	0
1		1
0	Alpha	0
1	Beta	1
0	bang	0	see-plain Wow!Hey
0	bang ! quote "	1
0	both	0	see-plain Aye	also-plain Bee
0	bs \ tilde ~ caret ^	1
0	café naïve	1
0	Canids	0
1	Foxes	0	see-plain Vulpes
0	cats	0	see-plain Felines
0	Custom Entry	1
0	dogs	0	also-plain Pets
0	dollar $ at @ bar |	1
0	Ghost	0
1	Sub	1
0	Ghosts	0	also-plain Spirits
0	Grüße	0
1	Straße	1
0	less < more >	1
0	One	0
1	Two	0
2	Three	0
3	Four	0
4	Five	0
5		1
0	owls	0	see-plain Birds: Owls
0	pandoc	3
0	pct % amp & hash #	1
0	Specials % & # _ { } \ ~ ^ $ @ | ! " < >	1
0	Top	0
1	Middle	0
2	Leaf	1
0	Trail bang!	1
0	us _ brace { }	1
0	Wow!Really	1
0	{Braced}	1
0	~tilde dollar$	1
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1c — cross-reference text expected in the compiled PDF's index
# region (M02-AC2). Each row is the source entry as makeindex prints it —
# for a multi-level source, its deepest level, which is the sub-item the
# cross-reference hangs off — then makeindex's own `, ` delimiter, then the
# typeset cross-reference text.
# ---------------------------------------------------------------------------
read -r -d '' XREF_PDF_TEXT <<'MANIFEST' || true
cats, see Felines
dogs, see also Pets
owls, see Birds: Owls
bang, see Wow!Hey
Foxes, see Vulpes
Ghosts, see also Spirits
both, see Aye; see also Bee
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1d — exact typeset cross-reference text for each character of the
# special-handling set in examples/xref-escaping.qmd (M02-AC3). Every one of
# these characters is literal text the author wrote, so each must print AS
# ITSELF: the expected string is the character, not a rendering of it. Probe
# keys follow the fixture's order, which is PROBE_CHARS' order. Xs = see,
# Xt = see-also, Xb = both on one mark (whose two targets are deliberately
# DIFFERENT characters, character i and character i+1 wrapping), Xk = a
# special character in the SOURCE entry, Xu = non-ASCII targets.
# ---------------------------------------------------------------------------
read -r -d '' XREF_PROBE_TEXT <<'MANIFEST' || true
Xs00, see %
Xt00, see also %
Xb00, see %; see also &
Xs01, see &
Xt01, see also &
Xb01, see &; see also #
Xs02, see #
Xt02, see also #
Xb02, see #; see also _
Xs03, see _
Xt03, see also _
Xb03, see _; see also {
Xs04, see {
Xt04, see also {
Xb04, see {; see also }
Xs05, see }
Xt05, see also }
Xb05, see }; see also \
Xs06, see \
Xt06, see also \
Xb06, see \; see also ~
Xs07, see ~
Xt07, see also ~
Xb07, see ~; see also ^
Xs08, see ^
Xt08, see also ^
Xb08, see ^; see also $
Xs09, see $
Xt09, see also $
Xb09, see $; see also @
Xs10, see @
Xt10, see also @
Xb10, see @; see also |
Xs11, see |
Xt11, see also |
Xb11, see |; see also !
Xs12, see !
Xt12, see also !
Xb12, see !; see also "
Xs13, see "
Xt13, see also "
Xb13, see "; see also <
Xs14, see <
Xt14, see also <
Xb14, see <; see also >
Xs15, see >
Xt15, see also >
Xb15, see >; see also %
A%B, see Tgt
A&B, see Tgt
A#B, see Tgt
A_B, see Tgt
A{B, see Tgt
A}B, see Tgt
A\B, see Tgt
A~B, see Tgt
A^B, see Tgt
A$B, see Tgt
A@B, see Tgt
A|B, see Tgt
A!B, see Tgt
A"B, see Tgt
A<B, see Tgt
A>B, see Tgt
Xu00, see Grüße: Straße
Xu01, see also café naïve
MANIFEST

# Every \index{} argument demo.qmd must produce, plain and cross-reference
# alike. The planted-defect self-test checks a fixture against this same list,
# so a cross-reference row is fenced exactly as a plain one is.
ALL_DEMO_ENTRIES="$DEMO_ENTRIES
$XREF_ENTRIES"

# ---------------------------------------------------------------------------
# Manifest 2 — control tokens expected in examples/control.tex (AC3).
# For each mark, an escape-free token containing that mark's own `entry=`
# value or visible text, plus the bracketed visible-text tokens.
# ---------------------------------------------------------------------------
read -r -d '' CONTROL_TOKENS <<'MANIFEST' || true
5	.index
3	term
1	entry="Custom Entry"
1	Ghost!Sub
1	{[}term{]}
1	{[}x{]}
1	entry="Top!Leaf"
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 3 — visible terms expected in examples/demo.html (AC7), as rendered
# text: markdown backslash-escapes consumed, then & < > as HTML entities.
# The count total must equal the number of marks carrying visible text.
# ---------------------------------------------------------------------------
read -r -d '' VISIBLE_TERMS <<'MANIFEST' || true
3	pandoc
1	phrase
1	nested term
1	lead
1	mid
1	trail
1	odd
1	bslash
1	old
1	empty
1	deep
1	cats
1	dogs
1	owls
1	bang
1	foxes
1	both
1	entry specials
1	pct % amp &amp; hash #
1	us _ brace { }
1	bs \ tilde ~ caret ^
1	dollar $ at @ bar |
1	bang ! quote "
1	{Braced}
1	~tilde dollar$
1	less &lt; more &gt;
1	café naïve
1	Grüße
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 4 — terms that must appear in the compiled PDF's index (AC6): the
# derived-from-visible-text, single-level, non-`entry=` terms only.
# ---------------------------------------------------------------------------
read -r -d '' PDF_TERMS <<'MANIFEST' || true
pandoc
pct % amp & hash #
us _ brace { }
bs \ tilde ~ caret ^
dollar $ at @ bar |
bang ! quote "
{Braced}
~tilde dollar$
less < more >
café naïve
MANIFEST

# `entry=` values that must NOT leak into rendered HTML text (AC7). A value
# that is also a substring of some visible term is excluded, since the visible
# term is required to be present.
read -r -d '' ENTRY_VALUES_NO_LEAK <<'MANIFEST' || true
Custom Entry
Top!Middle!Leaf
Ghost!Sub
!!Bang leads
Wow!!Really
Trail bang!!
A!!!B
Alpha!Beta
A!!B!
One!Two!Three!Four!Five!
Grüße!Straße
Specials % & # _ { } \ ~ ^ $ @ | !! " < >
Canids!Foxes
Ghosts
Felines
Pets
Birds!Owls
Wow!!Hey
Vulpes
Spirits
Aye
Bee
MANIFEST

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Extract every \index{...} argument (brace-balanced) from a .tex file.
index_args() {
  python3 - "$1" <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
i = 0
while True:
    j = src.find('\\index{', i)
    if j < 0:
        break
    k = j + 7
    depth = 1
    while k < len(src) and depth:
        if src[k] == '{':
            depth += 1
        elif src[k] == '}':
            depth -= 1
        k += 1
    print(src[j + 7:k - 1])
    i = k
PY
}

# Compare actual \index{} arguments against a count<TAB>text manifest.
check_entry_manifest() {
  local texfile="$1" manifest="$2" label="$3"
  index_args "$texfile" > "$WORK/actual-args.txt"
  printf '%s\n' "$manifest" > "$WORK/manifest.txt"
  python3 - "$WORK/actual-args.txt" "$WORK/manifest.txt" "$label" <<'PY'
import sys
from collections import Counter
actual_path, manifest_path, label = sys.argv[1], sys.argv[2], sys.argv[3]
actual = Counter(l.rstrip('\n') for l in open(actual_path, encoding='utf-8'))
rows, total = [], 0
for line in open(manifest_path, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip():
        continue
    count, text = line.split('\t', 1)
    rows.append((int(count), text))
    total += int(count)
if not rows:
    print(f'FAIL: {label}: manifest is empty', file=sys.stderr)
    sys.exit(1)
bad = []
for count, text in rows:
    got = actual.get(text, 0)
    if got != count:
        bad.append(f'  expected {count}x  got {got}x  <<{text}>>')
# Entries present in the .tex but absent from the manifest always fail —
# never only when the totals disagree. Planted defects can cancel out in the
# total (one removed, one added), so a total-gated check would miss the extra.
expected_texts = {t for _, t in rows}
for text, got in sorted(actual.items()):
    if text not in expected_texts:
        bad.append(f'  unexpected entry ({got}x): <<{text}>>')
actual_total = sum(actual.values())
if actual_total != total:
    bad.append(f'  total \\index count: expected {total}, got {actual_total}')
if bad:
    print(f'FAIL: {label}: manifest mismatch', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: {len(rows)} manifest rows, {total} \\index commands')
PY
}

# Compare literal-substring occurrence counts against a count<TAB>text manifest.
check_token_manifest() {
  local file="$1" manifest="$2" label="$3"
  printf '%s\n' "$manifest" > "$WORK/tokens.txt"
  python3 - "$file" "$WORK/tokens.txt" "$label" <<'PY'
import sys
path, manifest_path, label = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(path, encoding='utf-8').read()
bad = []
rows = 0
for line in open(manifest_path, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip():
        continue
    count, text = line.split('\t', 1)
    rows += 1
    got = src.count(text)
    if got != int(count):
        bad.append(f'  expected {count}x  got {got}x  <<{text}>>')
if not rows:
    print(f'FAIL: {label}: manifest is empty', file=sys.stderr)
    sys.exit(1)
if bad:
    print(f'FAIL: {label}: token count mismatch', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: {rows} tokens')
PY
}

# Compare a rendered file's generated index section against an EXHAUSTIVE row
# manifest (format: see manifest 1e). Rows are compared in order, so a
# collation failure is reported as one rather than swallowed by set equality.
check_html_index_manifest() {
  local htmlfile="$1" manifest="$2" label="$3"
  printf '%s\n' "$manifest" > "$WORK/html-index.txt"
  HTML_SECTION_ID="$HTML_SECTION_ID" python3 - "$htmlfile" \
    "$WORK/html-index.txt" "$label" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, manifest_path, label = sys.argv[1:4]
section_id = os.environ['HTML_SECTION_ID']

doc = H.parse(html_path)
found = H.count_id(doc, section_id)
if found != 1:
    print(f'FAIL: {label}: expected exactly one generated index section '
          f'(id={section_id!r}) in {html_path}, found {found}', file=sys.stderr)
    sys.exit(1)
actual = [H.row(r) for r in H.index_entries(H.find_id(doc, section_id))]
expected = H.read_manifest(manifest_path)
if not expected:
    print(f'FAIL: {label}: manifest is empty', file=sys.stderr)
    sys.exit(1)
if actual != expected:
    print(f'FAIL: {label}: the generated index does not match the manifest',
          file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        got = actual[i] if i < len(actual) else '<no such row rendered>'
        want = expected[i] if i < len(expected) else '<not in the manifest>'
        if got != want:
            print(f'  row {i + 1}:\n    expected <<{want}>>\n'
                  f'    got      <<{got}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: the generated index matches all {len(expected)} '
      f'manifest rows, in order')
PY
}

# Every generated id in a rendered file is document-unique, and every link
# inside the generated index resolves to an id in that same file. Applied to
# each HTML fixture, including the two that carry the shapes demo.qmd's
# invariants deliberately exclude.
check_html_index_links() {
  local htmlfile="$1" label="$2"
  HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
  HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" python3 - "$htmlfile" "$label" <<'PY'
import os, sys
from collections import Counter
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, label = sys.argv[1:3]
doc = H.parse(html_path)
ids = H.all_ids(doc)
dupes = sorted({i for i, n in Counter(ids).items() if n > 1})
if dupes:
    print(f'FAIL: {label}: duplicate id(s) in {html_path}: {dupes}',
          file=sys.stderr)
    sys.exit(1)
section = H.find_id(doc, os.environ['HTML_SECTION_ID'])
links = H.find_all(section, 'a')
dangling = sorted({a.attrs.get('href', '') for a in links
                   if a.attrs.get('href', '').startswith('#')
                   and a.attrs['href'][1:] not in set(ids)})
if dangling:
    print(f'FAIL: {label}: link(s) in the generated index of {html_path} '
          f'resolve to no id in the same file: {dangling}', file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: every id unique and all {len(links)} index links resolve '
      f'in {html_path}')
PY
}

# ---------------------------------------------------------------------------
# Tool guard (AC6): fail loudly rather than skipping the end-to-end check.
# ---------------------------------------------------------------------------
require_pdf_tools() {
  # `quarto list tools` prints its table on stderr and reports an installed
  # TinyTeX as "Up to date" or "Update available" — never as "Installed".
  local row
  row=$(quarto list tools 2>&1 | sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g' \
        | grep -E '^tinytex[[:space:]]' || true)
  [ -n "$row" ] || fail "could not determine TinyTeX status from 'quarto list tools'. AC6 must never pass unrun."
  case "$row" in
    *"Not installed"*)
      fail "TinyTeX is not installed (run: quarto install tinytex). AC6 must never pass unrun." ;;
  esac

  # TinyTeX's binaries are not on PATH by default; add them if present so the
  # guard tests the tools this machine would actually use.
  local bindir
  for bindir in "$HOME/Library/TinyTeX/bin/"* "$HOME/.TinyTeX/bin/"*; do
    [ -d "$bindir" ] && PATH="$bindir:$PATH"
  done
  export PATH

  command -v makeindex >/dev/null 2>&1 \
    || fail "makeindex not found on PATH. AC6 must never pass unrun."
  command -v pdflatex >/dev/null 2>&1 \
    || fail "pdflatex not found on PATH (the escaping probe invokes it directly). AC6 must never pass unrun."
  command -v pdftotext >/dev/null 2>&1 \
    || fail "pdftotext not found on PATH. AC6 must never pass unrun."
}

# ---------------------------------------------------------------------------
# AC1 + AC4 — demo renders to LaTeX via the installed extension; entries match.
# ---------------------------------------------------------------------------
if [ "$FIXTURE_MODE" = "1" ]; then
  check_entry_manifest "$2" "$ALL_DEMO_ENTRIES" "fixture"
  exit $?
fi

printf '== supported forms (normative) ==\n'
printf '%s\n' "${SUPPORTED_FORMS[@]}" | awk -F'\t' '{ printf "   %-26s %s\n", $1, $2 }'
printf '   probe characters: %s\n\n' "$PROBE_CHARS"

[ -e examples/_extensions/index/_extension.yml ] \
  || fail "examples/_extensions/index is missing; examples must consume the installed extension"
pass "AC1: demo resolves the extension via examples/_extensions"

# M02-AC6 — the docs and the normative list cannot drift apart. A count would
# pass on a README that documented some other syntax; this compares the bytes.
printf '%s\n' "${SUPPORTED_FORMS[@]}" > "$WORK/forms.txt"
python3 - "$WORK/forms.txt" README.md <<'PY'
import sys
rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = open(sys.argv[2], encoding='utf-8').read()
missing = [(label, ex) for label, ex in rows if ex not in readme]
if missing:
    print('FAIL: M02-AC6: syntax exemplar(s) absent from README.md:',
          file=sys.stderr)
    for label, ex in missing:
        print(f'  {label}: <<{ex}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   M02-AC6: all {len(rows)} normative syntax exemplars appear '
      f'verbatim in README.md')
PY

# M03-AC7 — the README describes the back-end that now exists, and no longer
# describes the one-back-end world. Whitespace is normalized on both sides, so
# a claim that is merely rewrapped still counts as present (and a stale
# sentence cannot hide behind a line break).
printf '%s\n' "${README_STALE[@]}" > "$WORK/readme-stale.txt"
printf '%s\n' "${README_HTML_CLAIMS[@]}" > "$WORK/readme-html.txt"
python3 - "$WORK/readme-stale.txt" "$WORK/readme-html.txt" README.md <<'PY'
import sys

def rows(path):
    return [l.rstrip('\n').split('\t', 1)
            for l in open(path, encoding='utf-8') if l.strip()]

def flat(s):
    return ' '.join(s.split())

stale, claims = rows(sys.argv[1]), rows(sys.argv[2])
readme = flat(open(sys.argv[3], encoding='utf-8').read())

bad = []
for label, text in stale:
    if flat(text) in readme:
        bad.append(f'  still present ({label}): <<{text}>>')
for label, text in claims:
    if flat(text) not in readme:
        bad.append(f'  missing ({label}): <<{text}>>')
if bad:
    print('FAIL: M03-AC7: README.md does not describe the HTML back-end as '
          'this suite exercises it:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M03-AC7: all {len(stale)} stale pass-through sentences are gone '
      f'and all {len(claims)} HTML claims appear in README.md')
PY

# The probe set is pinned to the filter's own escape table, so a character the
# filter handles can never go unprobed (and vice versa).
PROBE_CHARS="$PROBE_CHARS" python3 - _extensions/index/index.lua <<'PY'
import os, re, sys
src = open(sys.argv[1], encoding='utf-8').read()
table = src.split('local LATEX_LITERAL = {', 1)[1].split('\n}', 1)[0]
keys = set()
for m in re.finditer(r'^\s*\[(".*?"|\'"\')\]\s*=', table, re.MULTILINE):
    raw = m.group(1)
    keys.add('"' if raw == "'\"'" else raw[1:-1].replace('\\\\', '\\'))
probes = set(os.environ['PROBE_CHARS'].split(' '))
if keys != probes:
    print('FAIL: AC4: probe characters do not match the filter escape table',
          file=sys.stderr)
    print(f'  in filter, not probed: {sorted(keys - probes)}', file=sys.stderr)
    print(f'  probed, not in filter: {sorted(probes - keys)}', file=sys.stderr)
    sys.exit(1)

# The pin above compares the probe set to the filter. That alone does not stop
# a character sitting in both and being probed nowhere, so also require each
# one to appear in BOTH contexts of the demo, which is what AC4 promises.
qmd = open('examples/demo.qmd', encoding='utf-8').read()
unescape = lambda t: re.sub(r'\\(.)', r'\1', t)
visible = ''.join(unescape(m) for m in re.findall(r'\[((?:\\.|[^\]\\])*)\]\{\.index', qmd))
entries = ''.join(unescape(m)
                  for m in re.findall(r'entry="((?:\\.|[^"\\])*)"', qmd))
missing = []
for c in sorted(probes):
    if c not in visible:
        missing.append(f'  {c!r} never appears in a visible term')
    if c not in entries:
        missing.append(f'  {c!r} never appears in an entry= level')
if missing:
    print('FAIL: AC4: escape-domain characters unprobed in examples/demo.qmd:',
          file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   AC4: probe set pinned to the filter escape table ({len(keys)} '
      f'chars), each probed in both contexts')
PY

# ---------------------------------------------------------------------------
# REVIEW-TIME EVIDENCE, NOT A CHECK: the LaTeX back-end is untouched.
# A checked-in golden `.tex` would be a snapshot, which the oracle rule above
# forbids. Instead the reviewer compares the branch's render against the same
# render at the merge-base, on one machine, and reads the diff — expected to be
# empty. From a clean tree on the milestone branch:
#
#   BASE=$(git merge-base HEAD "$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')")
#   quarto render examples/demo.qmd --to latex && cp examples/demo.tex /tmp/branch-demo.tex
#   git checkout "$BASE" -- _extensions/index/index.lua
#   quarto render examples/demo.qmd --to latex && cp examples/demo.tex /tmp/base-demo.tex
#   git checkout HEAD -- _extensions/index/index.lua
#   diff /tmp/base-demo.tex /tmp/branch-demo.tex
#
# The last line restores the branch's filter; check `git status` is clean
# before trusting anything rendered afterwards.
# ---------------------------------------------------------------------------

# The HTML back-end's three identifiers are a public surface — a reader's URL
# and an author's CSS hold on to them — so the suite's copies are pinned to
# the filter's own constants, exactly as the dual-target command name is.
HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" python3 - _extensions/index/index.lua <<'PY'
import os, re, sys
src = open(sys.argv[1], encoding='utf-8').read()
bad = []
for name in ('HTML_SECTION_ID', 'HTML_ANCHOR_PREFIX', 'HTML_ENTRY_PREFIX'):
    m = re.search(rf'{name}\s*=\s*"([^"]*)"', src)
    if not m:
        bad.append(f'  {name} is not defined in the filter')
    elif m.group(1) != os.environ[name]:
        bad.append(f'  {name}: suite says {os.environ[name]!r}, filter '
                   f'defines {m.group(1)!r}')
if bad:
    print('FAIL: M03-AC3: the suite and the filter disagree on the HTML '
          'identifiers:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC3: all 3 HTML identifiers pinned to the filter constants')
PY

quarto render examples/demo.qmd --to latex > "$WORK/demo-latex.log" 2>&1 \
  || { cat "$WORK/demo-latex.log" >&2; fail "AC1: demo.qmd failed to render to LaTeX"; }
[ -s examples/demo.tex ] || fail "AC1: examples/demo.tex is empty"
check_entry_manifest examples/demo.tex "$ALL_DEMO_ENTRIES" "AC1/AC4"
# Keep a copy: the later PDF render consumes examples/demo.tex, and the AC5
# self-test plants its defects in this snapshot.
cp examples/demo.tex "$WORK/demo-latex.tex"

# Folding deeper levels is defensible under IP2 only because it warns; assert
# the warning, or a refactor that drops it leaves the suite green.
grep -q 'levels deep' "$WORK/demo-latex.log" \
  || fail "AC4: the >3-level probe produced no depth warning; folding without a warning is silent loss (IP2)"
# The probe is deep AND ends in an empty level — the interaction that once let
# folding absorb the empty level and swallow its warning.
grep -q 'empty index level in entry="One!Two!Three!Four!Five!"' "$WORK/demo-latex.log" \
  || fail "AC4: the trailing empty level produced no warning; folding must not swallow it (IP2)"
pass "AC4: both the fold and empty-level warnings emitted for the deep probe"

# ---------------------------------------------------------------------------
# M02-AC1 — the cross-reference manifest is complete, and the form it
# describes is the form the filter emits.
# ---------------------------------------------------------------------------
printf '%s\n' "$XREF_ENTRIES" > "$WORK/xref-manifest.txt"
XREF_BOTH_COMMAND="$XREF_BOTH_COMMAND" python3 - examples/demo.qmd \
  "$WORK/xref-manifest.txt" _extensions/index/index.lua <<'PY'
import os, re, sys
qmd_path, manifest_path, lua_path = sys.argv[1:4]
both = os.environ['XREF_BOTH_COMMAND']

# The manifest names the dual-target command; the filter defines it. If they
# ever disagree, every dual row silently reclassifies as single-target and the
# arithmetic below stops meaning anything.
lua = open(lua_path, encoding='utf-8').read()
m = re.search(r'XREF_BOTH_COMMAND\s*=\s*"([^"]+)"', lua)
if not m:
    print('FAIL: M02-AC1: no XREF_BOTH_COMMAND in the filter', file=sys.stderr)
    sys.exit(1)
if m.group(1) != both:
    print(f'FAIL: M02-AC1: manifest names {both!r}, filter defines '
          f'{m.group(1)!r}', file=sys.stderr)
    sys.exit(1)

single = dual = 0
for line in open(manifest_path, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip():
        continue
    count, text = line.split('\t', 1)
    if '|' + both in text:
        dual += int(count)
    else:
        single += int(count)

qmd = open(qmd_path, encoding='utf-8').read()
# Occurrences, not matching lines, and quoted values only — the same limits the
# entry= pins carry, recorded as known holes in the milestone file.
found = qmd.count('see="') + qmd.count('see-also="')
expected = single + 2 * dual
if found != expected:
    print(f'FAIL: M02-AC1: examples/demo.qmd has {found} cross-reference '
          f'attribute occurrence(s), but the manifest accounts for {expected} '
          f'({single} single-target + 2 x {dual} dual-target)', file=sys.stderr)
    sys.exit(1)
# The arithmetic above is exact only because demo.qmd holds no mark whose
# target is unusable and none with no source entry — those emit an attribute
# occurrence but no row. Both shapes live in other fixtures on purpose; this
# check reports the invariant by name so a violation is not misread as a
# manifest error.
print(f'ok   M02-AC1: {single} single-target and {dual} dual-target rows '
      f'account for all {found} cross-reference attributes in demo.qmd')
PY

# ---------------------------------------------------------------------------
# M02-AC5 — misuse case (b): one warning, one command, render still clean.
# ---------------------------------------------------------------------------

# Assert a warning appears an EXACT number of times. Presence alone would pass
# on a run that warned about the wrong mark, or warned twice for one.
check_warning_count() {
  local logfile="$1" pattern="$2" want="$3" label="$4" got
  # Occurrences, not matching lines: two warnings emitted onto one line would
  # count as one under `grep -c` and the check would pass.
  # `|| true` inside the pipeline, not after it: grep exits 1 on no match, and
  # under `pipefail` that would abort the script instead of reporting 0.
  got=$( { grep -oF -- "$pattern" "$logfile" || true; } | wc -l | tr -d ' ')
  [ "$got" = "$want" ] \
    || fail "$label: expected $want occurrence(s) of <<$pattern>> in $logfile, got $got"
}

WARN_BOTH='index mark carries both see= and see-also='
WARN_NO_SOURCE='cross-reference mark has no source entry'

check_warning_count "$WORK/demo-latex.log" "$WARN_BOTH" 1 "M02-AC5"
pass "M02-AC5: case (b) warned exactly once in the demo render"

# Every warning the filter can emit must be distinct, or "identified by
# distinctive message text" is not a property the suite can rely on. The
# domain is the filter's own warn() literals, so a warning added later is
# covered without editing this check.
python3 - _extensions/index/index.lua <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
# Each warn(...) call's leading string literal, which is the part a grep sees.
lits = re.findall(r'warn\(\s*\(?"((?:[^"\\]|\\.)*)"', src)
if len(lits) < 6:
    print(f'FAIL: M02-AC5: found only {len(lits)} warn() literals; the '
          f'distinctness check is not reading the filter', file=sys.stderr)
    sys.exit(1)
dupes = {l for l in lits if lits.count(l) > 1}
if dupes:
    print('FAIL: M02-AC5: warning messages are not distinct:', file=sys.stderr)
    for d in sorted(dupes):
        print(f'  <<{d}>>', file=sys.stderr)
    sys.exit(1)
# Neither may be a prefix of another, or a grep for the shorter also matches
# the longer and the two stop being separable.
for a in lits:
    for b in lits:
        if a is not b and b.startswith(a):
            print(f'FAIL: M02-AC5: warning <<{a}>> is a prefix of <<{b}>>',
                  file=sys.stderr)
            sys.exit(1)
print(f'ok   M02-AC5: all {len(lits)} filter warnings are mutually distinct')
PY

# The dual-target command must take its labels from LaTeX's own, or a document
# loading babel silently loses its translations — the property the milestone's
# Decisions entry banks on.
python3 - _extensions/index/index.lua <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'XREF_BOTH_DEFINITION\s*=\s*(.*?)\n\n', src, re.DOTALL)
if not m:
    print('FAIL: M02-AC5: no XREF_BOTH_DEFINITION in the filter', file=sys.stderr)
    sys.exit(1)
defn = m.group(1)
for needed in ('seename', 'alsoname'):
    if needed not in defn:
        print(f'FAIL: M02-AC5: the dual-target definition does not use '
              f'\\{needed}', file=sys.stderr)
        sys.exit(1)
if re.search(r'see\s+also|\bsee\b(?!name)', defn.replace('seename', '')):
    print('FAIL: M02-AC5: the dual-target definition hard-codes label text '
          'instead of using \\seename/\\alsoname', file=sys.stderr)
    sys.exit(1)
print('ok   M02-AC5: the dual-target command takes its labels from '
      '\\seename/\\alsoname')
PY

# ---------------------------------------------------------------------------
# AC2 — preamble injection and \printindex placement.
# ---------------------------------------------------------------------------
python3 - examples/demo.tex <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
def need(tok):
    i = src.find(tok)
    if i < 0:
        print(f'FAIL: AC2: {tok!r} not found in demo.tex', file=sys.stderr)
        sys.exit(1)
    return i
usepkg = need('\\usepackage{imakeidx}')
makeidx = need('\\makeindex')
begin = need('\\begin{document}')
end = need('\\end{document}')
n_print = src.count('\\printindex')
errs = []
if not usepkg < makeidx:
    errs.append('\\usepackage{imakeidx} must come before \\makeindex')
if not makeidx < begin:
    errs.append('\\usepackage{imakeidx} and \\makeindex must precede \\begin{document}')
if n_print != 1:
    errs.append(f'expected exactly one \\printindex, found {n_print}')
else:
    p = src.find('\\printindex')
    if not begin < p < end:
        errs.append('\\printindex must sit between \\begin{document} and \\end{document}')
    else:
        # "after all body content": nothing the document body emits may follow
        # it. The last \index{} mark and the last sectioning command are the
        # two body landmarks nearest the end.
        for landmark in ('\\index{', '\\section{'):
            last = src.rfind(landmark, begin, end)
            if last > p:
                errs.append(f'{landmark!r} appears after \\printindex')
if errs:
    print('FAIL: AC2: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   AC2: imakeidx + \\makeindex in preamble, exactly one \\printindex after the body')
PY

# M02: the dual-target command is defined exactly when a document uses one.
# The positive is otherwise only indirectly covered (an undefined command
# would abort the PDF compile); the negative is covered nowhere else, and a
# filter that injected it unconditionally would leave every document carrying
# preamble it does not need.
python3 - examples/demo.tex examples/control.tex <<'PY'
import sys
defn = '\\providecommand*\\quartoindexseeboth'
demo = open(sys.argv[1], encoding='utf-8').read()
control = open(sys.argv[2], encoding='utf-8').read()
n = demo.count(defn)
if n != 1:
    print(f'FAIL: M02-AC5: expected exactly one {defn!r} in demo.tex, found {n}',
          file=sys.stderr)
    sys.exit(1)
if demo.index(defn) > demo.index('\\begin{document}'):
    print(f'FAIL: M02-AC5: {defn!r} appears after \\begin{{document}}',
          file=sys.stderr)
    sys.exit(1)
if defn in control:
    print(f'FAIL: M02-AC5: {defn!r} injected into a document with no '
          f'both-attributes mark', file=sys.stderr)
    sys.exit(1)
print('ok   M02-AC5: the dual-target command is defined once in the preamble '
      'of the document that uses it, and not at all in one that does not')
PY

# ---------------------------------------------------------------------------
# AC3 — negative control.
# ---------------------------------------------------------------------------
quarto render examples/control.qmd --to latex > "$WORK/control-latex.log" 2>&1 \
  || { cat "$WORK/control-latex.log" >&2; fail "AC3: control.qmd failed to render to LaTeX"; }
[ -s examples/control.tex ] || fail "AC3: examples/control.tex is empty"
for tok in '\index{' 'imakeidx' '\makeindex' '\printindex'; do
  if grep -qF -- "$tok" examples/control.tex; then
    fail "AC3: control.tex must not contain $tok"
  fi
done
check_token_manifest examples/control.tex "$CONTROL_TOKENS" "AC3"

# ---------------------------------------------------------------------------
# AC7 — HTML pass-through.
# ---------------------------------------------------------------------------
quarto render examples/demo.qmd --to html > "$WORK/demo-html.log" 2>&1 \
  || { cat "$WORK/demo-html.log" >&2; fail "AC7: demo.qmd failed to render to HTML"; }
[ -s examples/demo.html ] || fail "AC7: examples/demo.html is empty"
for tok in '\index' 'imakeidx' '\makeindex' '\printindex'; do
  if grep -qF -- "$tok" examples/demo.html; then
    fail "AC7: demo.html must not contain $tok"
  fi
done

# ---------------------------------------------------------------------------
# M03-AC2 / M03-AC3 — the generated HTML index, its anchors and its links.
# ---------------------------------------------------------------------------
check_html_index_manifest examples/demo.html "$DEMO_HTML_INDEX" "M03-AC2"

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" python3 - examples/demo.html \
  examples/demo.qmd <<'PY'
import os, re, sys
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, qmd_path = sys.argv[1:3]
section_id = os.environ['HTML_SECTION_ID']
anchor_prefix = os.environ['HTML_ANCHOR_PREFIX']
entry_prefix = os.environ['HTML_ENTRY_PREFIX']

# --- how many anchors the SOURCE demands ------------------------------------
# Derived from the .qmd, never counted off the render: an anchor count read
# back from the artifact would agree with itself however many marks were lost.
qmd = open(qmd_path, encoding='utf-8').read()


def marks(src):
    """Every index mark as (visible text, attribute block).

    The attribute block ends at the first `}` outside a quoted value — an
    `entry=` value may itself contain braces, so a non-quote-aware scan cuts
    the block short and misreads the mark. The class need not come first
    either: `[t]{#id .index}` is the same mark as `[t]{.index}`, and a scanner
    that only recognized the second would leave the first out of the count it
    is the whole point of deriving from source.
    """
    found = []
    for m in re.finditer(r'\[((?:\\.|[^\]\\])*)\]\{', src):
        i, quoted = m.end(), False
        while i < len(src):
            c = src[i]
            if quoted and c == '\\':
                i += 2
                continue
            if c == '"':
                quoted = not quoted
            elif not quoted and c == '}':
                break
            i += 1
        block = src[m.end():i]
        if re.search(r'\.index(?![-\w])', block):
            found.append((re.sub(r'\\(.)', r'\1', m.group(1)), block))
    return found


all_marks = marks(qmd)
# THREE fixture invariants hold this arithmetic up, and a violation of any of
# them must name itself rather than surface as a mysterious count mismatch.
textless = [a for text, a in all_marks if text == '' and 'entry=' not in a]
if textless:
    # A mark with neither visible text nor entry= is dropped and emits no
    # anchor at all.
    print(f'FAIL: M03-AC3: the anchor count assumes demo.qmd holds no textless '
          f'mark, but {len(textless)} mark(s) have neither visible text nor '
          f'entry=', file=sys.stderr)
    sys.exit(1)
authored = [a for _text, a in all_marks if re.search(r'#[-\w]', a)]
if authored:
    # A mark carrying an id of the author's own keeps it and mints nothing.
    print(f'FAIL: M03-AC3: the anchor count assumes demo.qmd holds no mark '
          f'with an author-supplied id, but {len(authored)} mark(s) carry one',
          file=sys.stderr)
    sys.exit(1)
if re.search(r'^#{1,6} .*\]\{\.index', qmd, re.MULTILINE):
    # A mark inside a heading borrows the heading's id and mints nothing.
    print('FAIL: M03-AC3: the anchor count assumes demo.qmd holds no mark '
          'inside a heading, but at least one heading contains a mark',
          file=sys.stderr)
    sys.exit(1)
locator_marks = [m for m in all_marks
                 if 'see=' not in m[1] and 'see-also=' not in m[1]]
want = len(locator_marks)

# --- the anchors the render produced ----------------------------------------
doc = H.parse(html_path)
ids = H.all_ids(doc)
duplicates = sorted({i for i in ids if ids.count(i) > 1})
generated = [i for i in ids
             if i == section_id or i.startswith(anchor_prefix)
             or i.startswith(entry_prefix)]
clashing = [i for i in duplicates if i in generated]
if clashing:
    print(f'FAIL: M03-AC3: generated id(s) are not document-unique: '
          f'{clashing}', file=sys.stderr)
    sys.exit(1)

anchors = sorted(i for i in ids if i.startswith(anchor_prefix))
expected = [f'{anchor_prefix}{n}' for n in range(1, want + 1)]
if sorted(expected) != anchors:
    print(f'FAIL: M03-AC3: expected anchors {anchor_prefix}1..{want} (one per '
          f'locator-contributing mark in demo.qmd), got {len(anchors)} anchor '
          f'id(s)', file=sys.stderr)
    missing = sorted(set(expected) - set(anchors))
    extra = sorted(set(anchors) - set(expected))
    if missing:
        print(f'  missing: {missing}', file=sys.stderr)
    if extra:
        print(f'  unexpected: {extra}', file=sys.stderr)
    sys.exit(1)
for anchor in anchors:
    node = H.find_id(doc, anchor)
    if node.tag != 'span' or 'index' not in H.classes(node):
        print(f'FAIL: M03-AC3: {anchor} sits on <{node.tag}>, not on the '
              f'mark span it is supposed to anchor', file=sys.stderr)
        sys.exit(1)

# --- every link inside the index resolves -----------------------------------
section = H.find_id(doc, section_id)
targets = set(ids)
dangling = sorted({a.attrs.get('href', '') for a in H.find_all(section, 'a')
                   if a.attrs.get('href', '').startswith('#')
                   and a.attrs['href'][1:] not in targets})
if dangling:
    print(f'FAIL: M03-AC3: link(s) in the generated index resolve to no id in '
          f'the same file: {dangling}', file=sys.stderr)
    sys.exit(1)
links = [a for a in H.find_all(section, 'a')]
print(f'ok   M03-AC3: {want} anchors, one per locator-contributing mark '
      f'(demo.qmd holds no textless mark, no author-supplied id and no mark '
      f'in a heading), all generated ids unique, all {len(links)} links in '
      f'the index resolve')
PY

# IP2 regression: a mark whose content yields no text must index nothing and
# delete nothing. An image with empty alt text stringifies to "", which once
# caused the whole span — image included — to be dropped from every format.
for fmt in html latex; do
  quarto render examples/content.qmd --to $fmt > "$WORK/content-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/content-$fmt.log" >&2; fail "AC7: content.qmd failed to render to $fmt"; }
done
# content.qmd holds three marked images: the plain one, the entry= one, and
# the cross-reference one added for M02-AC5 case (a). An exact count, not a
# floor — a floor would pass while one of them was being dropped.
# Counted as `dot.png`, not `dot`: the bare substring collides with ordinary
# prose and with Quarto's own boilerplate (`dotted`), so an exact count of it
# would be pinned to the template rather than to the images.
for f in examples/content.html examples/content.tex; do
  CONTENT_DOTS=$(grep -o 'dot\.png' "$f" | wc -l | tr -d ' ')
  [ "$CONTENT_DOTS" = "3" ] \
    || fail "AC7/M02-AC5: expected 3 image references in $f, got $CONTENT_DOTS; marking an image must never remove it (IP2)"
done
CONTENT_IDX=$(grep -o '\\index{[^}]*}' examples/content.tex | wc -l | tr -d ' ')
[ "$CONTENT_IDX" = "1" ] \
  || fail "AC7: expected exactly one \\index from content.qmd (the entry= mark), got $CONTENT_IDX"
pass "AC7: marked content with no derivable text is indexed not at all and deleted not at all"

# M02-AC5 case (a): a cross-reference mark with no source entry. Two shapes —
# content that yields no text, and a genuinely empty mark — both warn, neither
# adds an \index (the count above is unchanged by them), and neither deletes
# content. Asserted in HTML and in LaTeX, since the warning is emitted in the
# format-neutral layer.
for fmt in html latex; do
  check_warning_count "$WORK/content-$fmt.log" "$WARN_NO_SOURCE" 2 "M02-AC5"
done
pass "M02-AC5: case (a) warned exactly twice in each format, emitted no entry, deleted nothing"

# ---------------------------------------------------------------------------
# The document-level clash report. Two marks on one key with DIFFERENT encaps
# are rejected by makeindex when they land on one page, and Quarto fails the
# render; two marks with the same encap are folded together and are fine. The
# fixture holds one of each shape, so the report is fenced in both directions.
# ---------------------------------------------------------------------------
for fmt in latex html; do
  quarto render examples/xref-conflict.qmd --to $fmt > "$WORK/conflict-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/conflict-$fmt.log" >&2; fail "M02-AC5: xref-conflict.qmd failed to render to $fmt"; }
done
WARN_CLASH='is marked in more than one way'
# kappa (plain against a cross-reference) and lambda (see against see-also),
# once each; mu (two identical see= marks) and nu (two plain marks) must NOT
# be reported, which the exact count of 2 is what fences.
check_warning_count "$WORK/conflict-latex.log" "$WARN_CLASH" 2 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" 'index key kappa ' 1 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" 'index key lambda ' 1 "M02-AC5"
# Deliberately LaTeX-only, and it stays that way now that HTML has a back-end
# of its own: the clash is a property of makeindex, which rejects two marks
# sharing a key and a page but carrying different encapsulations. The HTML
# back-end has no such limit — it prints the locator and the cross-reference
# on the same entry — so warning about it there would report a problem the
# reader's format does not have.
check_warning_count "$WORK/conflict-html.log" "$WARN_CLASH" 0 "M02-AC5"
pass "M02-AC5: the clash report names both differing-encap keys once each, ignores the two agreeing keys, and is silent in HTML"

# ---------------------------------------------------------------------------
# M03-AC4 — cross-references in a generated HTML index.
# Manifest 1f, same oracle rule and same row format as manifest 1e. The
# fixture holds all three shapes the criterion names: a target that resolves
# (sigma), one that does not (kappa, lambda, mu, rho), and the colliding
# string — rho's SINGLE level `Note: on birds` prints exactly like sigma's
# TWO levels `Note`/`on birds`, and only sigma may link. `kappa` carries a
# locator AND a cross-reference, which makeindex rejects but HTML does not.
# ---------------------------------------------------------------------------
read -r -d '' XREF_HTML_INDEX <<'MANIFEST' || true
0	kappa	1	see-plain Elsewhere
0	lambda	0	see-plain Here	also-plain There
0	mu	0	see-plain Same
0	Note	0
1	on birds	1
0	nu	2
0	rho	0	see-plain Note: on birds
0	sigma	0	see-link Note: on birds
MANIFEST

check_html_index_manifest examples/xref-conflict.html "$XREF_HTML_INDEX" "M03-AC4"

# The token above says sigma's target is A link; this says it is the RIGHT
# link. A cross-reference pointing at some other entry would satisfy the
# manifest and mislead every reader who followed it.
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/xref-conflict.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
records = H.index_entries(H.find_id(doc, os.environ['HTML_SECTION_ID']))
by_term = {r['term']: r for r in records}
target_id = by_term['on birds']['id']
href = by_term['sigma']['xrefs'][0][3]
if href != '#' + target_id:
    print(f'FAIL: M03-AC4: sigma links to {href!r}, but the entry it names '
          f'("Note: on birds") is {"#" + target_id!r}', file=sys.stderr)
    sys.exit(1)
# And the entry it points at is the sub-entry, not its parent: a target's
# deepest level is the entry a reader is being sent to.
if by_term['Note']['id'] == target_id:
    print('FAIL: M03-AC4: the two-level target resolved to its parent entry',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M03-AC4: the resolving cross-reference links to the sub-entry it '
      f'names ({href}), and the colliding single-level target does not link')
PY

# ---------------------------------------------------------------------------
# M03-AC4 — repeated and look-alike cross-reference targets. Manifest 1h, same
# oracle rule and row format as manifest 1e.
#
# `zeta` carries the SAME target twice and must show one cross-reference.
# `eta` carries two targets whose LEVEL LISTS differ but whose rendered text
# is identical (`A`/`B` against the single level `A: B`); both must survive,
# and only the two-level one names an entry, so only it links. Folding those
# two together loses an author's cross-reference silently, which is the IP2
# failure this fixture exists to catch — a dedupe keyed on rendered text
# passes every other check in this suite.
# ---------------------------------------------------------------------------
# The fixture also writes two ids the extension would otherwise mint for
# itself (`qi-mark-1` on theta, `qi-entry-1` on lambda), so the derivation
# below skips those numbers: ab takes qi-mark-2, iota qi-mark-3, kappa
# qi-mark-4, and the entries are numbered from qi-entry-2.
read -r -d '' HTML_INDEX_MANIFEST <<'MANIFEST' || true
0	A	0
1	B	1
0	Bee	1
0	bee	1
0	eta	0	see-link A: B	see-plain A: B
0	iota	1
0	kappa	1
0	lambda	1
0	theta	1
0	zeta	0	see-link A: B
MANIFEST

quarto render examples/html-index.qmd --to html > "$WORK/html-index.log" 2>&1 \
  || { tail -20 "$WORK/html-index.log" >&2; fail "M03-AC4: html-index.qmd failed to render to HTML"; }
check_html_index_manifest examples/html-index.html "$HTML_INDEX_MANIFEST" "M03-AC4"
check_html_index_links examples/html-index.html "M03-AC3"

# M03-AC3 — a minted id must never be an id the document already uses. Two
# elements answering to one name is not a cosmetic problem: the browser
# resolves a link to the first, so one of the two locators silently lands
# somewhere the reader did not ask for.
HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" python3 - examples/html-index.html <<'PY'
import os, sys
from collections import Counter
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
anchor_prefix = os.environ['HTML_ANCHOR_PREFIX']
entry_prefix = os.environ['HTML_ENTRY_PREFIX']
ids = H.all_ids(doc)
dupes = sorted({i for i, n in Counter(ids).items() if n > 1})
if dupes:
    print(f'FAIL: M03-AC3: duplicate id(s) in a document whose author used the '
          f'minted scheme: {dupes}', file=sys.stderr)
    sys.exit(1)
records = {r['term']: r for r in
           H.index_entries(H.find_id(doc, os.environ['HTML_SECTION_ID']))}
# The author's own ids are kept and linked, not taken over...
for term, want in (('theta', f'#{anchor_prefix}1'),
                   ('lambda', f'#{entry_prefix}1')):
    if records[term]['locators'] != [want]:
        print(f"FAIL: M03-AC3: {term}'s locator is {records[term]['locators']}, "
              f"expected ['{want}'] — an id the author wrote is never taken "
              f"over", file=sys.stderr)
        sys.exit(1)
# ...and nothing minted reuses them.
if records['lambda']['id'] == f'{entry_prefix}1':
    print(f'FAIL: M03-AC3: an entry was numbered {entry_prefix}1, which the '
          f'author already used', file=sys.stderr)
    sys.exit(1)
minted = [i for i in ids if i.startswith(anchor_prefix)]
if f'{anchor_prefix}1' not in minted or len(minted) != 6:
    print(f'FAIL: M03-AC3: expected the author id plus 5 minted anchors, got '
          f'{sorted(minted)}', file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC3: minted anchor and entry ids skip the ids the author '
      'already used, and every id in the document is unique')
PY

# ---------------------------------------------------------------------------
# M03-AC2 — locator numbering where the renderer moves content. Manifest 1g,
# same oracle rule and row format as manifest 1e: `widget` is marked in a
# heading, a table cell and a footnote, and `gadget` carries an id of the
# author's own.
# ---------------------------------------------------------------------------
read -r -d '' PLACEMENT_HTML_INDEX <<'MANIFEST' || true
0	gadget	1
0	widget	3
MANIFEST

quarto render examples/placement.qmd --to html > "$WORK/placement-html.log" 2>&1 \
  || { tail -20 "$WORK/placement-html.log" >&2; fail "M03-AC2: placement.qmd failed to render to HTML"; }
check_html_index_manifest examples/placement.html "$PLACEMENT_HTML_INDEX" "M03-AC2"
check_html_index_links examples/placement.html "M03-AC3"

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
python3 - examples/placement.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
prefix = os.environ['HTML_ANCHOR_PREFIX']
records = {r['term']: r for r in
           H.index_entries(H.find_id(doc, os.environ['HTML_SECTION_ID']))}

# Numbered in the order the marks are WRITTEN. The footnote's mark is written
# third and rendered last, so a numbering taken from rendered position would
# put it out of step with the table cell's. The first mark sits in a heading
# and takes that heading's own id: Quarto copies a heading's contents into the
# sidebar table of contents, so an id minted there would appear twice and the
# locator would resolve to the sidebar copy instead of the text.
want = ['#a-widget-in-a-heading', f'#{prefix}1', f'#{prefix}2']
if records['widget']['locators'] != want:
    print(f"FAIL: M03-AC2: widget's locators are "
          f"{records['widget']['locators']}, expected {want} (heading, table "
          f"cell, footnote — the order the marks are written)", file=sys.stderr)
    sys.exit(1)

# This fixture has a table of contents precisely so the duplicate above is
# reachable; assert it is not there. A document-wide uniqueness check on
# demo.html cannot see this, because demo.qmd has no TOC and no heading mark.
from collections import Counter
dupes = sorted({i for i, n in Counter(H.all_ids(doc)).items() if n > 1})
if dupes:
    print(f'FAIL: M03-AC2: duplicate id(s) in a document with a TOC and a '
          f'mark in a heading: {dupes}', file=sys.stderr)
    sys.exit(1)
if not any(a.attrs.get('href') == '#qi-index' for a in H.find_all(doc, 'a')):
    print('FAIL: M03-AC2: the generated index section is not linked from the '
          'table of contents', file=sys.stderr)
    sys.exit(1)

# The relocation this fixture exists to probe must actually have happened, or
# the check above proves nothing: the footnote's anchor sits inside the
# footnotes section the renderer moved to the end of the page, AFTER the mark
# that is written below it in the source.
footnotes = H.find_id(doc, 'footnotes')
if footnotes is None or H.find_id(footnotes, f'{prefix}2') is None:
    print(f'FAIL: M03-AC2: {prefix}2 is not inside the rendered footnotes '
          f'section, so this fixture is not probing relocated content',
          file=sys.stderr)
    sys.exit(1)
order = H.all_ids(doc)
if order.index('my-gadget') > order.index(f'{prefix}2'):
    print(f'FAIL: M03-AC2: the footnote mark still renders before the mark '
          f'written after it, so nothing was relocated', file=sys.stderr)
    sys.exit(1)

# The author's own id is the link target, and no anchor was minted for it.
if records['gadget']['locators'] != ['#my-gadget']:
    print(f"FAIL: M03-AC2: gadget's locator is "
          f"{records['gadget']['locators']}, expected ['#my-gadget'] — an id "
          f"the author wrote is never taken over", file=sys.stderr)
    sys.exit(1)
minted = [i for i in H.all_ids(doc) if i.startswith(prefix)]
if len(minted) != 2:
    print(f'FAIL: M03-AC2: {len(minted)} anchors minted, expected 2 (the mark '
          f'in the heading borrows its id and the mark carrying an author id '
          f'needs none)', file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC2: locators are numbered in source order across a heading, a '
      'table cell and a relocated footnote, and an author-supplied id is kept '
      'and linked')
PY

# ---------------------------------------------------------------------------
# M03-AC5 — every printable ASCII character reaches a generated HTML index as
# an entry of its own. The domain is the fixture's by construction and is
# pinned by the coverage check above; this asserts the characters arrive.
# Exact elements of the extracted set, not substrings: `<` is a substring of
# every entry once the markup is included, so a containment test would pass on
# an index that printed nothing at all.
# ---------------------------------------------------------------------------
quarto render examples/escaping.qmd --to html > "$WORK/esc-html.log" 2>&1 \
  || { tail -20 "$WORK/esc-html.log" >&2; fail "M03-AC5: escaping.qmd failed to render to HTML"; }

HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/escaping.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
section = H.find_id(doc, os.environ['HTML_SECTION_ID'])
if section is None:
    print('FAIL: M03-AC5: escaping.html has no generated index section',
          file=sys.stderr)
    sys.exit(1)
terms = {r['term'] for r in H.index_entries(section)}
domain = [chr(c) for c in range(0x21, 0x7F)]
missing = [c for c in domain if c not in terms]
if missing:
    print(f'FAIL: M03-AC5: character(s) absent from the generated index as an '
          f'entry of their own: {missing}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M03-AC5: all {len(domain)} printable ASCII characters (space '
      f'excluded) are entries of the generated HTML index, {len(terms)} '
      f'entries in all')
PY

# ---------------------------------------------------------------------------
# M03-AC6 — negatives. A document with no marks gets no section and no
# anchors, and a format with no index back-end gets neither, while the
# format-neutral warnings still reach its author.
# ---------------------------------------------------------------------------
quarto render examples/control.qmd --to html > "$WORK/control-html.log" 2>&1 \
  || { tail -20 "$WORK/control-html.log" >&2; fail "M03-AC6: control.qmd failed to render to HTML"; }

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" python3 - examples/control.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
section_id = os.environ['HTML_SECTION_ID']
prefixes = (os.environ['HTML_ANCHOR_PREFIX'], os.environ['HTML_ENTRY_PREFIX'])
stray = [i for i in H.all_ids(doc)
         if i == section_id or i.startswith(prefixes)]
if stray:
    print(f'FAIL: M03-AC6: a document with no marks carries generated id(s): '
          f'{stray}', file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC6: a document with no marks gets no index section and no '
      'anchors')
PY

quarto render examples/demo.qmd --to gfm > "$WORK/demo-gfm.log" 2>&1 \
  || { tail -20 "$WORK/demo-gfm.log" >&2; fail "M03-AC6: demo.qmd failed to render to gfm"; }
[ -s examples/demo.md ] || fail "M03-AC6: examples/demo.md is empty"
for tok in 'qi-index' 'qi-mark-' 'qi-entry-' '\index' '\printindex'; do
  if grep -qF -- "$tok" examples/demo.md; then
    fail "M03-AC6: gfm output must not contain $tok (gfm has no index back-end)"
  fi
done
if grep -qE '^# Index$' examples/demo.md; then
  fail "M03-AC6: gfm output must not contain a generated index section"
fi
grep -qF 'café' examples/demo.md || fail "M03-AC6: gfm output lost visible term text"
# The warnings that are genuinely about what the author wrote are emitted in
# every format now, not only where a back-end exists. demo.qmd holds two
# empty levels: the trailing one in `A!!B!` and the trailing one in the
# over-deep probe.
check_warning_count "$WORK/demo-gfm.log" 'empty index level in ' 2 "M03-AC6"
check_warning_count "$WORK/demo-gfm.log" "$WARN_BOTH" 1 "M03-AC6"

# The converse, which is what keeps the split honest: the three-level fold is
# makeindex's ceiling, not the extension's, so its warning must NOT follow the
# format-neutral ones out of the LaTeX branch. Asserted as an exact zero in
# both other formats, since demo.qmd holds the over-deep probe that produces
# it in LaTeX (asserted present, above).
for log in demo-html demo-gfm; do
  check_warning_count "$WORK/$log.log" 'levels deep' 0 "M03-AC6"
done
pass "M03-AC6: gfm renders clean with no index artifacts, the format-neutral warnings still reach its author, and the makeindex level-ceiling warning reaches neither HTML nor gfm"

printf '%s\n' "$VISIBLE_TERMS" > "$WORK/visible.txt"
printf '%s\n' "$ENTRY_VALUES_NO_LEAK" > "$WORK/noleak.txt"
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/demo.html examples/demo.qmd \
  "$WORK/visible.txt" "$WORK/noleak.txt" <<'PY'
import os, re, sys
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, qmd_path, vis_path, leak_path = sys.argv[1:5]
qmd = open(qmd_path, encoding='utf-8').read()

# Both halves of this check are about the document a reader reads OUTSIDE the
# generated index: the visible terms are the marks in the body, and the
# attribute values that must not leak are legitimately printed inside the
# index section. So the section is removed from the tree first, and everything
# below reads what is left.
# The document is read TWICE, because the two halves are stated in different
# layers and comparing across layers is how a leak hides.
#   markup layer (decode=False): the visible-terms manifest's rows are written
#     as `&amp;`/`&lt;`, the meaning they have carried since M01.
#   text layer (decode=True): the no-leak values are the literal strings the
#     author wrote. Swept against markup, a leaked value containing `&`, `<`,
#     `>` or `"` would be rendered escaped and never match itself — the
#     escaping-hostile values are exactly the ones IP2 cares most about, so
#     that comparison would report "no leak" for the worst leak there is.
markup = H.parse(html_path, decode=False)
doc = H.parse(html_path, decode=True)
for tree in (markup, doc):
    section = H.find_id(tree, os.environ['HTML_SECTION_ID'])
    if section is None:
        print('FAIL: AC7: no generated index section in demo.html',
              file=sys.stderr)
        sys.exit(1)
    H.strip_subtree(tree, section)

rows, total = [], 0
for line in open(vis_path, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip():
        continue
    count, text = line.split('\t', 1)
    rows.append((int(count), text))
    total += int(count)

# Completeness pin: count OCCURRENCES (not matching lines) in the source.
marks = qmd.count(']{.index')
invisible = qmd.count('[]{.index')
expected = marks - invisible
if total != expected:
    detail = (']{.index occurrences %d minus []{.index occurrences %d'
              % (marks, invisible))
    print('FAIL: AC7: visible-terms manifest count total %d != '
          'marks-with-visible-text %d (%s)' % (total, expected, detail),
          file=sys.stderr)
    sys.exit(1)

# AC7 requires term x count, as in AC1 — not mere presence. Count the rendered
# text of each `.index` span, so a dropped duplicate is caught and a term that
# also occurs in generator metadata cannot satisfy the check.
from collections import Counter
# The invisible-entry form has no visible text by construction, so its empty
# span is not a term; the completeness pin already accounts for it separately.
# Found structurally rather than by matching the serialized tag: the HTML
# writer orders attributes as it likes, and the marks now carry an anchor id
# alongside their class.
spans = Counter(t for t in (H.text(n)
                            for n in H.find_all(markup, 'span', 'index'))
                if t != '')
bad = []
for count, text in rows:
    got = spans.get(text, 0)
    if got != count:
        bad.append(f'  expected {count}x  got {got}x  <<{text}>>')
for text, got in sorted(spans.items()):
    if not any(text == t for _, t in rows):
        bad.append(f'  unexpected visible term ({got}x): <<{text}>>')
if bad:
    print('FAIL: AC7: visible-term count mismatch in demo.html:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)

no_leak = [v.rstrip('\n') for v in open(leak_path, encoding='utf-8') if v.strip()]

# Pin the no-leak list to the source rather than trusting the hand list: every
# entry=, see= and see-also= value in the .qmd must either be listed, or be a
# substring of some visible term (in which case it is required to be present,
# not absent).
terms = [t for _, t in rows]
declared = []
# `see-also` is listed before `see` so the alternation cannot match the tail of
# the longer name. All three attributes carry values that must never reach the
# reader, so all three are pinned, not just entry=.
for raw in re.findall(r'(?:entry|see-also|see)="((?:\\.|[^"\\])*)"', qmd):
    declared.append(re.sub(r'\\(.)', r'\1', raw))
unaccounted = [v for v in set(declared)
               if v not in no_leak and not any(v in t for t in terms)]
if unaccounted:
    print('FAIL: AC7/M02-AC4: mark attribute value(s) neither in the no-leak '
          'manifest nor a substring of a visible term:', file=sys.stderr)
    for v in sorted(unaccounted):
        print(f'  <<{v}>>', file=sys.stderr)
    sys.exit(1)

# A space at every element boundary, so a value that only exists by running
# two elements together is not reported as text a reader can see. Read from
# the DECODED tree, so a value is compared with the text a reader would
# actually see if it leaked.
body = H.text(doc, sep=' ')
def parsed(v):
    out, i = [], 0
    while i < len(v):
        if v[i] == '!' and v[i:i+2] == '!!':
            out.append('!'); i += 2
        else:
            out.append(v[i]); i += 1
    return ''.join(out)
leaked = sorted({v for v in no_leak
                 if v in body or parsed(v) in body})
if leaked:
    print('FAIL: AC7/M02-AC4: mark attribute value(s) leaked into rendered '
          'text:', file=sys.stderr)
    for v in leaked:
        print(f'  <<{v}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   AC7/M02-AC4: {len(rows)} visible terms present ({total} marks), '
      f'no entry=/see=/see-also= leakage')
PY

# ---------------------------------------------------------------------------
# AC6 — end-to-end to a compiled PDF with a real index.
# ---------------------------------------------------------------------------
require_pdf_tools

# Regression test for the IP2 failure review found: beamer has no `theindex`
# environment, so emitting \printindex there aborted the render. Exit 0 alone
# would not fence it — an \index-only regression exits 0 because \index is a
# no-op without \makeindex — so the kept .tex is checked for every token too.
# This is a full LaTeX compile, hence its place after the tool guard.
quarto render examples/demo.qmd --to beamer -M keep-tex:true \
  > "$WORK/demo-beamer.log" 2>&1 \
  || { tail -20 "$WORK/demo-beamer.log" >&2; fail "AC7: beamer render failed (IP2: a marked term must never break a render)"; }
[ -s examples/demo.tex ] || fail "AC7: beamer render kept no .tex to inspect"
for tok in '\index' 'imakeidx' '\makeindex' '\printindex'; do
  if grep -qF -- "$tok" examples/demo.tex; then
    fail "AC7: beamer .tex must not contain $tok (beamer has no index back-end)"
  fi
done
grep -qF 'café' examples/demo.tex || fail "AC7: beamer .tex lost visible term text"
pass "AC7: beamer renders clean, no index tokens, visible text kept"

# The escaping probe covers a range defined by construction, not by recall:
# every printable ASCII character except the space, as its own visible term
# and its own entry= level. It fences the three ways an escaping bug reaches a
# reader — the build breaks, makeindex rejects the entry, or it fails to
# typeset — so all three are checked here.
quarto render examples/escaping.qmd --to latex > "$WORK/esc-latex.log" 2>&1 \
  || { tail -20 "$WORK/esc-latex.log" >&2; fail "AC4: escaping.qmd failed to render to LaTeX"; }

PROBE_CHARS="$PROBE_CHARS" python3 - examples/escaping.qmd <<'PY'
import os, re, string, sys
qmd = open(sys.argv[1], encoding='utf-8').read()
unescape = lambda t: re.sub(r'\\(.)', r'\1', t)
visible = {unescape(m) for m in re.findall(r'\[((?:\\.|[^\]\\])*)\]\{\.index', qmd)}
entries = {unescape(m) for m in re.findall(r'entry="((?:\\.|[^"\\])*)"', qmd)}
domain = [chr(c) for c in range(0x21, 0x7F)]
missing = []
for c in domain:
    if c not in visible:
        missing.append(f'  {c!r} is not its own visible term')
    # a lone `!` is a level separator, so a literal one is written `!!`
    if (('!!' if c == '!' else c)) not in entries:
        missing.append(f'  {c!r} is not its own entry= level')
if missing:
    print('FAIL: AC4: escaping.qmd does not cover printable ASCII:',
          file=sys.stderr)
    print('\n'.join(missing[:20]), file=sys.stderr)
    sys.exit(1)
print(f'ok   AC4: escaping probe covers all {len(domain)} printable ASCII '
      f'characters (space excluded) in both contexts')
PY

mkdir -p "$WORK/esc" && cp examples/escaping.tex "$WORK/esc/"
quarto render examples/escaping.qmd --to pdf > "$WORK/esc-pdf.log" 2>&1 \
  || { tail -20 "$WORK/esc-pdf.log" >&2; fail "AC4: escaping probe failed to compile through Quarto's own PDF engine — a character in the range breaks the build"; }
( cd "$WORK/esc" && pdflatex -interaction=nonstopmode escaping.tex ) \
  > "$WORK/esc-tex1.log" 2>&1 \
  || { grep -E '^! ' "$WORK/esc-tex1.log" | head -5 >&2; fail "AC4: escaping probe failed to compile"; }
( cd "$WORK/esc" && makeindex escaping.idx ) > "$WORK/esc-mkidx.log" 2>&1 \
  || fail "AC4: makeindex failed on the escaping probe"
ESC_MARKS=$(( (0x7F - 0x21) * 2 ))
grep -qE "\($ESC_MARKS entries accepted, 0 rejected\)" "$WORK/esc/escaping.ilg" \
  || { grep -E 'accepted|rejected' "$WORK/esc/escaping.ilg" >&2; fail "AC4: makeindex did not accept all $ESC_MARKS escaping-probe entries"; }
# The typeset evidence comes from Quarto's own PDF, built with the engine that
# actually ships: compiling proves the argument READS, typesetting proves the
# character PRINTS, and both must hold under the shipping engine.
pdftotext -layout examples/escaping.pdf "$WORK/esc/escaping.txt"
PROBE_CHARS="$PROBE_CHARS" python3 - "$WORK/esc/escaping.txt" <<'PY'
import os, re, sys
txt = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'^\s*Index\s*$', txt, re.MULTILINE)
if not m:
    print('FAIL: AC4: escaping probe produced no index section', file=sys.stderr)
    sys.exit(1)
region = txt[m.end():]
missing = [c for c in os.environ['PROBE_CHARS'].split(' ') if c not in region]
if missing:
    print(f'FAIL: AC4: escape-domain characters absent from the typeset '
          f'index: {missing}', file=sys.stderr)
    sys.exit(1)
print('ok   AC4: escaping probe compiles, all entries accepted, and every '
      'escape-domain character typesets in its index')
PY

# ---------------------------------------------------------------------------
# M02-AC3 — the same three-way test for cross-reference targets, which travel
# through makeindex's encap channel rather than the entry key. That channel is
# stricter: an unquoted `!` there is rejected outright and Quarto turns the
# rejection into a failed render, so a mistake here breaks a reader's build.
# ---------------------------------------------------------------------------
quarto render examples/xref-escaping.qmd --to latex > "$WORK/xref-latex.log" 2>&1 \
  || { tail -20 "$WORK/xref-latex.log" >&2; fail "M02-AC3: xref-escaping.qmd failed to render to LaTeX"; }

XREF_BOTH_COMMAND="$XREF_BOTH_COMMAND" PROBE_CHARS="$PROBE_CHARS" python3 - \
  examples/xref-escaping.qmd examples/xref-escaping.tex <<'PY'
import os, re, sys
qmd = open(sys.argv[1], encoding='utf-8').read()
tex = open(sys.argv[2], encoding='utf-8').read()
both = os.environ['XREF_BOTH_COMMAND']
specials = os.environ['PROBE_CHARS'].split(' ')

# --- coverage by construction, not by recall -------------------------------
unescape = lambda t: re.sub(r'\\(.)', r'\1', t)
def levels(value):
    out, cur, i = [], [], 0
    while i < len(value):
        if value[i] == '!':
            if value[i:i+2] == '!!':
                cur.append('!'); i += 2
            else:
                out.append(''.join(cur)); cur = []; i += 1
        else:
            cur.append(value[i]); i += 1
    out.append(''.join(cur))
    return out

seen = {'see': {}, 'see-also': {}}
for attr, raw in re.findall(r'(see-also|see)="((?:\\.|[^"\\])*)"', qmd):
    lv = levels(unescape(raw))
    for pos, level in enumerate(lv):
        # position recorded only for genuinely multi-level targets
        seen[attr].setdefault(level, set()).add(pos if len(lv) > 1 else None)

domain = [chr(c) for c in range(0x21, 0x7F)]
missing = []
for c in domain:
    for attr in ('see', 'see-also'):
        if c not in seen[attr]:
            missing.append(f'  {c!r} is not its own level under {attr}=')
if missing:
    print('FAIL: M02-AC3: xref-escaping.qmd does not cover printable ASCII:',
          file=sys.stderr)
    print('\n'.join(missing[:20]), file=sys.stderr)
    sys.exit(1)

# Union coverage of the position axis: every one of leading, medial and
# trailing is exercised somewhere, under each attribute.
for attr in ('see', 'see-also'):
    positions = {p for poss in seen[attr].values() for p in poss if p is not None}
    if not {0, 1, 2} <= positions:
        print(f'FAIL: M02-AC3: {attr}= targets never use level position(s) '
              f'{sorted({0,1,2} - positions)}', file=sys.stderr)
        sys.exit(1)

# --- the dual and single forms must render a target identically ------------
# Otherwise the character evidence gathered on one form says nothing about the
# other, and the two could drift apart silently.
def index_arguments(src):
    """Every \\index{...} argument, brace-balanced — the commands sit adjacent
    in the .tex, so a regex would run straight past the closing brace."""
    args, i = [], 0
    while True:
        j = src.find('\\index{', i)
        if j < 0:
            return args
        k, depth = j + 7, 1
        while k < len(src) and depth:
            if src[k] == '{':
                depth += 1
            elif src[k] == '}':
                depth -= 1
            k += 1
        args.append(src[j + 7:k - 1])
        i = k

def brace_groups(text):
    """Split `cmd{a}{b}` into ['a', 'b'], respecting nesting."""
    groups, i = [], text.find('{')
    while i >= 0 and i < len(text):
        depth, k = 1, i + 1
        while k < len(text) and depth:
            if text[k] == '{':
                depth += 1
            elif text[k] == '}':
                depth -= 1
            k += 1
        groups.append(text[i + 1:k - 1])
        i = k if k < len(text) and text[k] == '{' else -1
    return groups

encaps = {}
for arg in index_arguments(tex):
    if '|' in arg:
        source, encap = arg.split('|', 1)
        encaps[source] = encap

drift = []
for i, c in enumerate(specials):
    nxt = (i + 1) % len(specials)
    s, t, b = (encaps.get('Xs%02d' % i), encaps.get('Xt%02d' % nxt),
               encaps.get('Xb%02d' % i))
    if not (s and t and b):
        drift.append(f'  {c!r}: could not read all three probe forms')
        continue
    if not (s.startswith('see{') and t.startswith('seealso{')
            and b.startswith(both + '{')):
        drift.append(f'  {c!r}: unexpected encap command among {s!r} {t!r} {b!r}')
        continue
    # The dual form's two targets are DIFFERENT characters in the fixture, and
    # each group is compared to its own single-target rendering positionally.
    # Comparing a set of all four groups would pass on a dual form that dropped
    # a target or emitted a third, which is the whole failure this pin exists
    # to catch — so the group count is asserted first.
    bg = brace_groups(b)
    if len(bg) != 2:
        drift.append(f'  {c!r}: dual form has {len(bg)} target group(s), not 2')
        continue
    see_group, also_group = brace_groups(s)[0], brace_groups(t)[0]
    if bg[0] != see_group:
        drift.append(f'  {c!r}: dual see-target {bg[0]!r} != single {see_group!r}')
    if bg[1] != also_group:
        drift.append(f'  {specials[nxt]!r}: dual see-also target {bg[1]!r} != '
                     f'single {also_group!r}')
if drift:
    print('FAIL: M02-AC3: single-target and dual-target forms do not render a '
          'target identically:', file=sys.stderr)
    print('\n'.join(drift), file=sys.stderr)
    sys.exit(1)

print(f'ok   M02-AC3: probe covers all {len(domain)} printable ASCII '
      f'characters under both attributes, all three level positions, and the '
      f'single and dual forms render each target identically')
PY

# The two unusable-target shapes live here rather than in demo.qmd, whose
# completeness pin assumes every cross-reference attribute yields a row.
check_warning_count "$WORK/xref-latex.log" \
  'empty level in see= on term "Xe00"' 1 "M02-AC3"
check_warning_count "$WORK/xref-latex.log" \
  'see= on term "Xe01" has no usable target text' 1 "M02-AC3"
pass "M02-AC3: an empty target level and an unusable target each warn once"

# Compile, and require makeindex to accept every probe entry. Counted by
# construction from the fixture's own shape, never read back from the run.
mkdir -p "$WORK/xref" && cp examples/xref-escaping.tex "$WORK/xref/"
quarto render examples/xref-escaping.qmd --to pdf > "$WORK/xref-pdf.log" 2>&1 \
  || { tail -20 "$WORK/xref-pdf.log" >&2; fail "M02-AC3: the cross-reference probe failed to compile through Quarto's own PDF engine"; }
( cd "$WORK/xref" && pdflatex -interaction=nonstopmode xref-escaping.tex ) \
  > "$WORK/xref-tex1.log" 2>&1 \
  || { grep -E '^! ' "$WORK/xref-tex1.log" | head -5 >&2; fail "M02-AC3: the cross-reference probe failed to compile"; }
( cd "$WORK/xref" && makeindex xref-escaping.idx ) > "$WORK/xref-mkidx.log" 2>&1 \
  || fail "M02-AC3: makeindex failed on the cross-reference probe"
# 94 characters x 2 attributes in multi-level targets, plus the 16-character
# special set four times over — single-level see, single-level see-also,
# dual-target, and once inside the SOURCE entry of a cross-reference — plus
# two non-ASCII targets, the empty-level probe (one cross-reference) and the
# unusable probe (one plain entry).
XREF_MARKS=$(( (0x7F - 0x21) * 2 + 16 * 4 + 2 + 2 ))
grep -qE "\($XREF_MARKS entries accepted, 0 rejected\)" "$WORK/xref/xref-escaping.ilg" \
  || { grep -E 'accepted|rejected' "$WORK/xref/xref-escaping.ilg" >&2; fail "M02-AC3: makeindex did not accept all $XREF_MARKS cross-reference probe entries"; }

# Typeset evidence from Quarto's own PDF: compiling proves the encap argument
# READS, typesetting proves the character PRINTS in a cross-reference.
pdftotext -layout examples/xref-escaping.pdf "$WORK/xref/xref-escaping.txt"
printf '%s\n' "$XREF_PROBE_TEXT" > "$WORK/xrefprobe.txt"
python3 - "$WORK/xref/xref-escaping.txt" "$WORK/xrefprobe.txt" <<'PY'
import re, sys
txt = open(sys.argv[1], encoding='utf-8').read()
rows = [l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8') if l.strip()]
m = re.search(r'^\s*Index\s*$', txt, re.MULTILINE)
if not m:
    print('FAIL: M02-AC3: the cross-reference probe produced no index section',
          file=sys.stderr)
    sys.exit(1)
region = ' '.join(txt[m.end():].split())
missing = [r for r in rows if ' '.join(r.split()) not in region]
if missing:
    print('FAIL: M02-AC3: special-handling character(s) did not typeset in '
          'their cross-reference:', file=sys.stderr)
    for r in missing:
        print(f'  <<{r}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   M02-AC3: all {len(rows)} exact cross-reference strings typeset in '
      f'the probe index')
PY

quarto render examples/demo.qmd --to pdf > "$WORK/demo-pdf.log" 2>&1 \
  || { tail -40 "$WORK/demo-pdf.log" >&2; fail "AC6: demo.qmd failed to render to PDF"; }
[ -s examples/demo.pdf ] || fail "AC6: examples/demo.pdf is empty"
pdftotext -layout examples/demo.pdf "$WORK/demo.txt"

printf '%s\n' "$PDF_TERMS" > "$WORK/pdfterms.txt"
python3 - "$WORK/demo.txt" "$WORK/pdfterms.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
terms = [l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8') if l.strip()]

m = re.search(r'^\s*Index\s*$', text, re.MULTILINE)
if not m:
    print('FAIL: AC6: no "Index" heading in pdftotext output', file=sys.stderr)
    sys.exit(1)
region = ' '.join(text[m.end():].split())
missing = [t for t in terms if ' '.join(t.split()) not in region]
if missing:
    print('FAIL: AC6: term(s) missing from the PDF index section:', file=sys.stderr)
    for t in missing:
        print(f'  <<{t}>>', file=sys.stderr)
    print(f'--- index region ---\n{region[:1200]}', file=sys.stderr)
    sys.exit(1)
print(f'ok   AC6: PDF index heading found, {len(terms)} derived terms listed')
PY

# ---------------------------------------------------------------------------
# M02-AC2 — every cross-reference reaches the compiled index as typeset text.
# The .tex check proves the argument was built; only this proves a reader can
# see it (GP6).
# ---------------------------------------------------------------------------
printf '%s\n' "$XREF_PDF_TEXT" > "$WORK/xrefpdf.txt"
python3 - "$WORK/demo.txt" "$WORK/xrefpdf.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
rows = [l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8') if l.strip()]
m = re.search(r'^\s*Index\s*$', text, re.MULTILINE)
if not m:
    print('FAIL: M02-AC2: no "Index" heading in pdftotext output',
          file=sys.stderr)
    sys.exit(1)
# Same whitespace normalization the AC6 check uses: the printed index is set in
# two columns, so runs of layout spacing collapse to one space.
region = ' '.join(text[m.end():].split())
missing = [r for r in rows if ' '.join(r.split()) not in region]
if missing:
    print('FAIL: M02-AC2: cross-reference(s) missing from the PDF index '
          'section:', file=sys.stderr)
    for r in missing:
        print(f'  <<{r}>>', file=sys.stderr)
    print(f'--- index region ---\n{region[:1500]}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M02-AC2: all {len(rows)} cross-references typeset in the PDF '
      f'index, source entry and text together')
PY

# ---------------------------------------------------------------------------
# AC5 — planted-defect self-test.
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--self-test" ]; then
  printf '\n== self-test (planted defects) ==\n'
  BROKEN="$WORK/broken.tex"
  python3 - "$WORK/demo-latex.tex" "$BROKEN" <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
# 1. remove one manifest-expected command
src = src.replace('\\index{Ghost!Sub}', '', 1)
# 2. alter another
src = src.replace('\\index{Custom Entry}', '\\index{Altered Entry}', 1)
# 3. add a spurious one
src = src.replace('\\printindex', '\\index{Spurious}\n\\printindex', 1)
open(sys.argv[2], 'w', encoding='utf-8').write(src)
PY
  set +e
  OUT=$( "$0" --fixture-check "$BROKEN" 2>&1 )
  RC=$?
  set -e
  [ "$RC" -ne 0 ] || fail "AC5: the script exited 0 on a broken fixture"
  for expect in 'Ghost!Sub' 'Custom Entry' 'Spurious'; do
    printf '%s' "$OUT" | grep -qF -- "$expect" \
      || { printf '%s\n' "$OUT" >&2; fail "AC5: self-test output does not name <<$expect>>"; }
  done
  pass "AC5: the script itself exits $RC on removed, altered and spurious entries, naming each"

  # M02-AC5: the warning checks must discriminate on both axes. A check that
  # only greps for presence passes on a log that warned twice for one mark, so
  # absence alone is not enough evidence that the check is doing anything.
  warn_discrimination() {
    local logfile="$1" pattern="$2" want="$3" label="$4"
    local removed="$WORK/warn-removed.log" dup="$WORK/warn-dup.log"

    grep -vF -- "$pattern" "$logfile" > "$removed" || true
    if ( check_warning_count "$removed" "$pattern" "$want" "$label" ) \
         >/dev/null 2>&1; then
      fail "$label: the warning check passed on a log with <<$pattern>> removed"
    fi

    awk -v p="$pattern" '{ print; if (index($0, p)) print }' "$logfile" > "$dup"
    if ( check_warning_count "$dup" "$pattern" "$want" "$label" ) \
         >/dev/null 2>&1; then
      fail "$label: the warning check passed on a log with <<$pattern>> duplicated"
    fi

    # The unmutated log must still pass, or the two failures above would prove
    # only that the check always fails.
    check_warning_count "$logfile" "$pattern" "$want" "$label"
    pass "M02-AC5: the check for <<$pattern>> fails when it is missing and when it is duplicated, and passes as rendered"
  }

  warn_discrimination "$WORK/demo-latex.log" "$WARN_BOTH" 1 "M02-AC5"
  warn_discrimination "$WORK/content-latex.log" "$WARN_NO_SOURCE" 2 "M02-AC5"
  # Not named by a criterion, but the same discipline: a clash report nothing
  # proves discriminating is a report that can quietly stop firing.
  warn_discrimination "$WORK/conflict-latex.log" "$WARN_CLASH" 2 "M02-AC5"
fi

printf '\nAll checks passed.\n'
