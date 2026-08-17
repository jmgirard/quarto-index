#!/usr/bin/env bash
#
# quarto-index acceptance tests (M01).
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

WORK="tests/.work"
rm -rf "$WORK"
mkdir -p "$WORK"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok   %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Supported forms (NORMATIVE for M01). The README documents exactly these four
# span forms and no others.
# ---------------------------------------------------------------------------
SUPPORTED_FORMS=(
  'visible-term span:      [term]{.index}'
  'custom-entry span:      [term]{.index entry="Entry"}'
  'sub-entry span:         [term]{.index entry="Top!Sub"}   (literal ! is !!)'
  'invisible-entry span:   []{.index entry="Entry"}'
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
1	us \_ brace \{ \}
1	bs \textbackslash{} tilde \textasciitilde{} caret \textasciicircum{}
1	dollar \$ at "@ bar \textbar{}
1	bang "! quote \textquotedbl{}
1	Specials \% \& \# \_ \{ \} \textbackslash{} \textasciitilde{} \textasciicircum{} \$ "@ \textbar{} "! \textquotedbl{}
1	\{Braced\}
1	\textasciitilde{}tilde dollar\$
1	less \textless{} more \textgreater{}
1	café naïve
1	Grüße!Straße
MANIFEST

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
One!Two!Three!Four!Five
Grüße!Straße
Specials % & # _ { } \ ~ ^ $ @ | !! "
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
  command -v pdftotext >/dev/null 2>&1 \
    || fail "pdftotext not found on PATH. AC6 must never pass unrun."
}

# ---------------------------------------------------------------------------
# AC1 + AC4 — demo renders to LaTeX via the installed extension; entries match.
# ---------------------------------------------------------------------------
printf '== supported forms (normative) ==\n'
printf '   %s\n' "${SUPPORTED_FORMS[@]}"
printf '   probe characters: %s\n\n' "$PROBE_CHARS"

[ -e examples/_extensions/index/_extension.yml ] \
  || fail "examples/_extensions/index is missing; examples must consume the installed extension"
pass "AC1: demo resolves the extension via examples/_extensions"

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
print(f'ok   AC4: probe set pinned to the filter escape table ({len(keys)} chars)')
PY

quarto render examples/demo.qmd --to latex > "$WORK/demo-latex.log" 2>&1 \
  || { cat "$WORK/demo-latex.log" >&2; fail "AC1: demo.qmd failed to render to LaTeX"; }
[ -s examples/demo.tex ] || fail "AC1: examples/demo.tex is empty"
check_entry_manifest examples/demo.tex "$DEMO_ENTRIES" "AC1/AC4"
# Keep a copy: the later PDF render consumes examples/demo.tex, and the AC5
# self-test plants its defects in this snapshot.
cp examples/demo.tex "$WORK/demo-latex.tex"

# Folding deeper levels is defensible under IP2 only because it warns; assert
# the warning, or a refactor that drops it leaves the suite green.
grep -q 'levels deep' "$WORK/demo-latex.log" \
  || fail "AC4: the >3-level probe produced no depth warning; folding without a warning is silent loss (IP2)"
pass "AC4: depth-fold warning emitted for the >3-level probe"

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
spans = Counter(t for t in re.findall(r'<span class="index"[^>]*>(.*?)</span>',
                                      html, re.DOTALL) if t != '')
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
# entry= value in the .qmd must either be listed, or be a substring of some
# visible term (in which case it is required to be present, not absent).
terms = [t for _, t in rows]
declared = []
for raw in re.findall(r'entry="((?:\\.|[^"\\])*)"', qmd):
    declared.append(re.sub(r'\\(.)', r'\1', raw))
unaccounted = [v for v in set(declared)
               if v not in no_leak and not any(v in t for t in terms)]
if unaccounted:
    print('FAIL: AC7: entry= value(s) neither in the no-leak manifest nor a '
          'substring of a visible term:', file=sys.stderr)
    for v in sorted(unaccounted):
        print(f'  <<{v}>>', file=sys.stderr)
    sys.exit(1)

body = re.sub(r'<[^>]*>', ' ', html)
leaked = [v for v in no_leak if v in body]
if leaked:
    print('FAIL: AC7: entry= value(s) leaked into rendered text:', file=sys.stderr)
    for v in leaked:
        print(f'  <<{v}>>', file=sys.stderr)
    sys.exit(1)
print(f'ok   AC7: {len(rows)} visible terms present ({total} marks), no entry= leakage')
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
  OUT=$(check_entry_manifest "$BROKEN" "$DEMO_ENTRIES" "self-test" 2>&1)
  RC=$?
  set -e
  [ "$RC" -ne 0 ] || fail "AC5: self-test did not fail on a broken fixture"
  for expect in 'Ghost!Sub' 'Custom Entry' 'Spurious'; do
    printf '%s' "$OUT" | grep -qF -- "$expect" \
      || { printf '%s\n' "$OUT" >&2; fail "AC5: self-test output does not name <<$expect>>"; }
  done
  pass "AC5: self-test fails on removed, altered, and spurious entries and names each"
fi

printf '\nAll checks passed.\n'
