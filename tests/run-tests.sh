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
# Xt = see-also, Xb = both on one mark.
# ---------------------------------------------------------------------------
read -r -d '' XREF_PROBE_TEXT <<'MANIFEST' || true
Xs00, see %
Xt00, see also %
Xb00, see %; see also %
Xs01, see &
Xt01, see also &
Xb01, see &; see also &
Xs02, see #
Xt02, see also #
Xb02, see #; see also #
Xs03, see _
Xt03, see also _
Xb03, see _; see also _
Xs04, see {
Xt04, see also {
Xb04, see {; see also {
Xs05, see }
Xt05, see also }
Xb05, see }; see also }
Xs06, see \
Xt06, see also \
Xb06, see \; see also \
Xs07, see ~
Xt07, see also ~
Xb07, see ~; see also ~
Xs08, see ^
Xt08, see also ^
Xb08, see ^; see also ^
Xs09, see $
Xt09, see also $
Xb09, see $; see also $
Xs10, see @
Xt10, see also @
Xb10, see @; see also @
Xs11, see |
Xt11, see also |
Xb11, see |; see also |
Xs12, see !
Xt12, see also !
Xb12, see !; see also !
Xs13, see "
Xt13, see also "
Xb13, see "; see also "
Xs14, see <
Xt14, see also <
Xb14, see <; see also <
Xs15, see >
Xt15, see also >
Xb15, see >; see also >
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
  got=$(grep -cF -- "$pattern" "$logfile" || true)
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
for f in examples/content.html examples/content.tex; do
  CONTENT_DOTS=$(grep -o 'dot' "$f" | wc -l | tr -d ' ')
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

printf '%s\n' "$VISIBLE_TERMS" > "$WORK/visible.txt"
printf '%s\n' "$ENTRY_VALUES_NO_LEAK" > "$WORK/noleak.txt"
python3 - examples/demo.html examples/demo.qmd "$WORK/visible.txt" "$WORK/noleak.txt" <<'PY'
import re, sys
html_path, qmd_path, vis_path, leak_path = sys.argv[1:5]
html = open(html_path, encoding='utf-8').read()
qmd = open(qmd_path, encoding='utf-8').read()

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
# Attribute values are matched as quoted strings, not as "anything but >":
# Pandoc escapes & and " in an attribute but leaves < and > raw, so an entry
# value containing them would otherwise truncate the tag match.
SPAN_RE = r'<span class="index"(?:\s+[-\w]+="[^"]*")*\s*>(.*?)</span>'
spans = Counter(t for t in re.findall(SPAN_RE, html, re.DOTALL) if t != '')
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

body = re.sub(r'<[^>"]*(?:"[^"]*"[^>"]*)*>', ' ', html)
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
    s, t, b = (encaps.get('Xs%02d' % i), encaps.get('Xt%02d' % i),
               encaps.get('Xb%02d' % i))
    if not (s and t and b):
        drift.append(f'  {c!r}: could not read all three probe forms')
        continue
    if not (s.startswith('see{') and t.startswith('seealso{')
            and b.startswith(both + '{')):
        drift.append(f'  {c!r}: unexpected encap command among {s!r} {t!r} {b!r}')
        continue
    rendered = set(brace_groups(s)) | set(brace_groups(t)) | set(brace_groups(b))
    if len(rendered) != 1:
        drift.append(f'  {c!r}: forms disagree: {sorted(rendered)}')
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
# special set as single-level see, single-level see-also and dual-target
# marks, plus the empty-level probe (one cross-reference) and the unusable
# probe (one plain entry).
XREF_MARKS=$(( (0x7F - 0x21) * 2 + 16 * 3 + 2 ))
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
fi

printf '\nAll checks passed.\n'
