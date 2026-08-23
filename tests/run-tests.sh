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

# Self-test hook for the wrapper itself: with this flag the run's first check
# is one that fails ONLY by exit status. The suite must then exit non-zero and
# must never print its "All checks passed" line.
PLANT_WRAPPER_DEFECT=0
[ "${1:-}" = "--plant-wrapper-defect" ] && PLANT_WRAPPER_DEFECT=1

WORK="tests/.work"
# Neither self-test invocation may wipe the work directory or the run log: the
# fixture check reads a file the parent wrote there, and the wrapper probe is
# spawned from INSIDE a parent run whose log is still being written.
[ "$FIXTURE_MODE" = "1" ] || [ "$PLANT_WRAPPER_DEFECT" = "1" ] || rm -rf "$WORK"
mkdir -p "$WORK"
RUN_LOG="$WORK/run.log"
[ "$PLANT_WRAPPER_DEFECT" = "1" ] && RUN_LOG="$WORK/run-plant.log"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok   %s\n' "$*"; }

# ---------------------------------------------------------------------------
# The filter's source set (M16). Every check that reads filter source reads
# THIS set, never a named file: a definition moving into a new module has to
# stay inside the domain a check sweeps, or the check goes on passing while it
# reads nothing. The enumeration is recursive and lives in exactly one place —
# a written-down list of file names becomes the sweep, and every file it omits
# ships unread — which is how the deleted merge-base diff script's
# non-recursive fixture list came to miss nine of the thirty-eight fixtures
# without ever failing (D-004).
#
# QI_EXT_DIR lets a probe point the same checks at a scratch tree whose
# definitions have been moved, which is how they are proved discriminating
# against the file-moving case (M16-AC3). tests/filtersrc.py reads it too.
# ---------------------------------------------------------------------------
# QI_EXT_DIR is the AC3 probe's handle, not a setting. The renders resolve the
# filter through the examples/_extensions symlink whatever this says, so a value
# left exported in the caller's environment would leave every source-reading
# check reading one tree while the renders used another — the run green and
# every pin guarding nothing. The probe exports it around the scans it invokes,
# in their own subshells; the run itself refuses any other value. Captured and
# cleared first, so the line below is the one place the root is written down.
QI_EXT_AMBIENT="${QI_EXT_DIR:-}"
unset QI_EXT_DIR
export QI_EXT_DIR="${QI_EXT_DIR:-_extensions/index}"
[ -z "$QI_EXT_AMBIENT" ] || [ "$QI_EXT_AMBIENT" = "$QI_EXT_DIR" ] \
  || fail "M16: QI_EXT_DIR is set to $QI_EXT_AMBIENT in this environment. It is the moved-definition probe's handle for pointing the source scans at a scratch tree, not a setting: the renders read $QI_EXT_DIR regardless, so the source checks would be pinning a different tree than the one being rendered."
[ -d "$QI_EXT_DIR" ] || fail "M16-AC2: no extension directory at $QI_EXT_DIR"
# ONE enumeration, and it is tests/filtersrc.py's. The shell had its own `find`
# here while the sed-based constant reads consumed it; those became scans like
# every other, so a second enumeration would now exist only to be compared with
# the first — two implementations to keep in step, sorting by different rules,
# guarding nothing the one enumeration does not already guard.
FILTER_SOURCES=$(python3 -c "
import sys; sys.path.insert(0,'tests'); import filtersrc
print('\n'.join(filtersrc.sources()))") \
  || fail "M16-AC2: tests/filtersrc.py refused to enumerate a source set under $QI_EXT_DIR; every source-reading check would sweep nothing and pass vacuously"
FILTER_SOURCE_COUNT=$(printf '%s\n' "$FILTER_SOURCES" | wc -l | tr -d ' ')

# ---------------------------------------------------------------------------
# The source-reading checks (M16). Each one's body lives in tests/scans/<name>.py
# and reads the source set through tests/filtersrc.py; this function is the one
# place that says how each is invoked — which environment it gets and which
# arguments. The run calls it at the site, and the M16-AC3 probe calls it again
# with QI_EXT_DIR pointed at a scratch tree whose definitions have been moved.
# Two copies of these env/argv lines would let the probe exercise an invocation
# the run does not, which is the vacuous pass this milestone exists to close.
#
# The globals below are read when run_scan is CALLED, not when it is defined,
# so a scan whose pinned constant is set further down the file still gets it.
# ---------------------------------------------------------------------------
run_scan() {
  local name="$1"
  local script="tests/scans/$name.py"
  [ -f "$script" ] || fail "M16: no source scan named $name (looked for $script)"
  case "$name" in
    latex-escape-table)
      PROBE_CHARS="$PROBE_CHARS" python3 "$script" ;;
    html-identifiers)
      HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
      HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" HTML_LETTER_CLASS="$HTML_LETTER_CLASS" \
        python3 "$script" ;;
    xref-manifest)
      XREF_BOTH_COMMAND="$XREF_BOTH_COMMAND" \
        python3 "$script" examples/demo.qmd "$WORK/xref-manifest.txt" ;;
    warn-distinct|xref-both-definition|store-version|max-levels|overflow-join|m15-joined-messages)
      python3 "$script" ;;
    marker-class)
      MARKER_CLASS="$MARKER_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" \
        python3 "$script" ;;
    mark-report-keys)
      # EVERY key the run greps a mark report by, never a fixed slice: a key
      # the run uses and the scan never sees is a key nothing holds to matching
      # one warning, and every zero-expectation control resting on it passes
      # vacuously (M18 review F3). M20's three and M21's five were both added
      # to the run without reaching here (M21 review F6).
      python3 "$script" "$WARN_SELF_XREF" "$WARN_FOLD_SELF" "$WARN_FOLD_DEPTH" \
        "$WARN_FOLD_TARGET" \
        "$M20_UNKNOWN" "$M20_NOLOCATOR" "$M20_UNINDEXED" \
        "$R_UNKNOWN" "$R_DISPLACED" "$R_ALREADY" "$R_NOOPEN" "$R_NOCLOSE" \
        "$R_BOOKUNPAIRED" ;;
    store-names)
      STORE_SUFFIX="$STORE_SUFFIX" STORE_DIR="$STORE_DIR" python3 "$script" ;;
    *)
      fail "M16: tests/scans/$name.py has no invocation in run_scan; the M16-AC3 probe would run it with the wrong environment and report a defect that is its own" ;;
  esac
}

# ---------------------------------------------------------------------------
# Supported forms (NORMATIVE). The README documents exactly these authoring
# forms — the mark spans, and the div that places the index — and no others.
# Each row is <label><TAB><exemplar>: the exemplar is the exact
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
  $'placement marker\t::: {.qi-index-here}'
  $'sort key span\t[The Hague]{.index sort="Hague"}'
  $'sub-level sort key\t[]{.index entry="mathematicians!von Neumann" sort="!Neumann"}'
  $'principal mention\t[term]{.index mention="principal"}'
  $'range opening\t[term]{.index range="open"}'
  $'range closing\t[term]{.index range="close"}'
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
  $'automatic placement\tPlacement is automatic; there is no option to put the index elsewhere yet'
  $'sort keys unimplemented\tSort keys and locator styling, which use those characters in raw `makeindex` syntax, are not part of this syntax and will arrive later as separate span attributes'
  $'ungrouped collation rule\tEntries sort by folding ASCII uppercase to lowercase, then by character code, with a tie broken by character code, applied to an entry\'s sort key where it has one'
  # M15: the row said the warning existed because the build could fail. It
  # cannot now, so both the row\'s name and its reason are retired; the
  # sentence that replaced them is pinned in README_HTML_CLAIMS below.
  $'clash warning name\tThe clash warning is LaTeX-only'
  $'clash warning reason\tOne term marked two different ways can fail a PDF build, so the extension warns about it'
)

# Each must be PRESENT: one beamer-scoped pass-through sentence, and one row
# per way the two back-ends diverge. A divergence a reader is not told about is
# a bug report waiting to be filed.
README_HTML_CLAIMS=(
  $'beamer pass-through\tIn beamer, and in any other format with no index back-end, marks pass through'
  $'no level ceiling\tNo level ceiling in HTML'
  $'one-entry warning scope\tThe one-entry warning is LaTeX-only'
  $'collation rule\tTop-level entries are ranked into letter groups first; inside a group, and at every level below the top, the order folds ASCII uppercase to lowercase and then compares character codes, breaking a tie by character code, over an entry\'s sort key where it has one'
  $'numbered locator links\tLocators are numbered links in HTML'
  $'targets hyperlinked\tCross-reference targets are hyperlinked in HTML'
  $'no locator from a cross-reference\tA cross-reference carries no locator in either back-end'
)

# ---------------------------------------------------------------------------
# README claims about sort keys (NORMATIVE, M06-AC6). Same discipline as
# README_HTML_CLAIMS: one row per behavior the extension documents, compared
# as bytes, so the docs and what this suite exercises cannot drift apart.
# These assert the named sentences are PRESENT; they never claim the README
# says nothing else, which no procedure here could establish.
# ---------------------------------------------------------------------------
README_SORT_CLAIMS=(
  $'not tool syntax\tA sort key is ordinary text, not index-tool syntax'
  $'level alignment\tlines up with it position by position'
  $'empty level fallback\tfile this level under its own printed text'
  $'key belongs to the entry\tA sort key belongs to the entry, not to the mark you happened to write it on'
  $'reported in every format\tThree things are reported, in every output format'
  $'report: nothing to sort\ta `sort=` on a mark that indexes nothing, which has nothing to sort'
  $'report: extra levels\ta `sort=` with more levels than there are to sort, whose extra levels are'
  # M13: the report's two counts are both taken before the empty-level drop,
  # so README must not let either be read as the depth the entry indexes at.
  # M19-AC6 replaced the wording: the report now says what each count is OVER
  # rather than when it was taken, and README says the same (D-006).
  $'report: counts are named\tThe report says what each count is over'
  $'report: fallback count\tthe second count is the one level its visible text makes'
  $'ceiling report names both\tnames the depth you wrote alongside it where a dropped level'
  $'target report names both\tthe depth you wrote it at where a dropped level'
  $'report: two keys\tone entry given two different sort keys, which cannot file in two places'
  $'reaching past a level\ton the way to a deeper one declares nothing for that level'
  $'book adds a fourth report\tA book adds a fourth report, for a term two chapters sort differently'
  $'latex adds a fifth report\tA fifth report is LaTeX-only'
  $'the fold makes the collision\ttwo entries written at different depths can end up printing at one place'
  $'no ceiling in HTML\tThe HTML index applies no such ceiling'
  $'ordering is per back-end\tA sort key files an entry under the ordering of whichever back-end builds the'
  $'plain keys order alike\tSort keys of plain letters and digits order the same way in both back-ends'
  $'keys past the ceiling\tA sort key written for a level past the third goes with that level in this'
  $'two skipped levels\tTwo skipped levels cannot sit side by side'
  $'key belongs to the level\tit belongs to the entry level you wrote it for, and places that'
)

# ---------------------------------------------------------------------------
# README claims about empty levels (NORMATIVE, M11-AC6). Same discipline as
# the arrays around it: one row per behavior the extension documents, compared
# as bytes, so what README promises about a dropped level and what the M11
# fixture exercises cannot drift apart.
# ---------------------------------------------------------------------------
README_EMPTY_CLAIMS=(
  $'the drop\tThe empty levels are dropped and the entry indexes'
  # M13: one report per mark, naming the positions the author can find in
  # their own value, and the count of WRITTEN levels that remain.
  $'one report per mark\twarning per mark, naming the entry and which positions in the value were'
  $'positions named\t`entry="!Sub!"` reports positions 1 and 3 of 3'
  $'written levels remain\t3 written levels remains'
  $'both ends\t`entry="!Cats"` and `entry="Cats!"` both index as `Cats`'
  $'format-neutral\tThis is the same in every format'
  $'why it matters\trejects an entry outright for a leading or middle null field'
  $'unspellable middle\tTwo empty levels can never sit side by side'
  $'all-empty fallback\tfalls back to its own visible text where it has some'
  $'sort pairing\tfiles `Cats` under `cats` and never under `zzz`'
  $'dropped keys reported\tyou get a warning saying how many keys went'
  $'fallback takes no key\tnever under a key written for a level that is gone'
  $'no empty level, no change\tstill declares nothing for it'
  $'depth after the drop\tDepth is counted after empty levels have gone'
)

# ---------------------------------------------------------------------------
# README claims about the principal mention (NORMATIVE, M20). Same discipline
# as the arrays around it: one row per behavior the extension documents, its
# bytes compared rather than a count, so what README promises and what this
# suite exercises cannot drift. Whitespace is flattened before the comparison,
# so a claim README wraps across lines is still one row here.
README_PRINCIPAL_CLAIMS=(
  $'emphasis\tthe index emphasizes that locator alone'
  $'html class\tcarries the class `qi-principal`'
  $'control\ta term with no role anywhere is unchanged'
  $'redefinable\tDefine your own in the document\'s preamble and yours is kept'
  $'no locator\tThe role is reported and dropped, and the mark indexes exactly as it would without it'
  # The exception the LaTeX level fold creates, which the blanket claim above
  # contradicted once the fold-induced self-target began keeping its role
  # (review round 3).
  $'fold exception\tThe same mark can therefore be emphasized in the PDF and plain in HTML'
  $'empty value\tsince `mention=""` is a value you wrote rather than an attribute you left off'
  # The one silent degradation (RR01 recommendation 4). Pinned like every other
  # documented behavior, and exercised by the T9 fixture's `oni` entry rather
  # than merely asserted here.
  $'range degradation\ta principal mention whose page is anywhere in such a folded range, its first page included, prints plain, silently'
)

# README claims about the page range (NORMATIVE, M21). Same discipline: the
# bytes the extension documents are compared, so a behavior that changes
# without its documentation fails here.
README_RANGE_CLAIMS=(
  $'one locator\tthe index prints one locator spanning the two rather than a locator at each end'
  $'pdf shape\tIn a PDF that prints as `otters, 12--15`'
  $'html shape\tthe entry carries a single numbered link, pointing at the opening mark, and the closing mark contributes no link of its own'
  $'pairing\tthe closing mark is the next `range="close"` on the same entry as an opening'
  $'principal range\tPut `mention="principal"` on either of its two marks and the whole range prints emphasized'
  $'role once\tThe role belongs to the span rather than to either mark, so write it once, on whichever end you like'
  $'either end encapsulates\tWhere either mark of the range is the principal mention, both ends carry the same encapsulation command'
  $'chapter scope\ta range whose two marks are in one chapter is paired there and prints as one locator'
  $'across chapters\tA range whose marks are in *different* chapters is not paired: each mark indexes on its own'
  $'chapter report\tEach chapter reports its own half — the opening as never closed in that chapter, the closing as never opened there'
  $'book report\tthe book adds one report naming the pairs it can see split across its chapters'
  $'pdf book\tQuarto renders it as one merged document, so its ranges span chapters as you would expect'
  $'folded-in mark\t`makeindex` folds that locator into the range and prints nothing extra'
  $'folded-in silence\tsilently, and without a line in its own transcript'
  $'why not warned\tit does not know page numbers, so it cannot tell which marks fall inside a range and which do not'
  $'refusal outcome\tthe mark indexes exactly as it would with no `range=` written'
  $'refusal split\tfor the mark carrying a cross-reference means the cross-reference, which takes a locator\'s place either way'
  $'never closed\tan opening that is never closed'
  $'no opening\ta closing with no opening before it'
  $'second opening\ta second opening for a term whose range is still open'
  $'cross-reference\ta range mark that also carries `see=` or `see-also=`'
  $'unknown value\ta `range=` value that is neither `open` nor `close`'
  $'empty value\tsince `range=""` is a value you wrote rather than an attribute you left off'
  $'overlapping\tTwo overlapping ranges of one term cannot be told apart, since pairing is by entry'
)

# README claims about letter groups (NORMATIVE, M07-AC6). Same discipline as
# README_HTML_CLAIMS: one row per behavior the extension documents, compared
# as bytes, so the docs and what this suite exercises cannot drift apart.
# ---------------------------------------------------------------------------
README_LETTER_CLAIMS=(
  $'label derivation\tA group label comes from the string the entry files under'
  $'sort-key precedence\tits sort key where it has one, and its printed text where it has none'
  $'letter label\tIf that string begins with an ASCII letter the label is that letter, uppercased'
  $'symbols fallback\ta digit, a punctuation mark, or an accented or non-Latin letter'
  # M11: no entry can file under the empty string any more, so README no
  # longer lists it among the cases and this pin no longer asks it to.
  $'no empty filing string\tNothing files under an empty string: a level that'
  $'symbols first\tThe Symbols group comes first**, ahead of A'
  $'always on\tGrouping is always on.** There is nothing to switch on and no threshold'
  $'top level only\tOnly the top level is grouped.** A sub-entry files under its parent rather than under a letter of its own'
  $'class hook\tEach label is a `div` carrying the class `qi-letter` and nothing else'
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
1	A"!B
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
HTML_LETTER_CLASS='qi-letter'
# Declared here with the other pinned HTML identifiers rather than in the M20
# section that first needed it: a book check now reads it several thousand lines
# earlier, and `set -u` turned that into a loud failure rather than an empty
# needle — the same ordering trap the report keys were moved out of.
HTML_PRINCIPAL_CLASS='qi-principal'

# ---------------------------------------------------------------------------
# Manifest 1e — the generated index in examples/demo.html (M03-AC2).
# EXHAUSTIVE: a rendered entry absent from this list fails, as does a listed
# entry the render does not produce.
# Two row shapes. An ENTRY row is
# <depth><TAB><entry text><TAB><locator count>[<TAB><cross-reference>]…
# where a cross-reference is `see-plain`/`see-link`/`also-plain`/`also-link`,
# a space, and the target as a reader sees it. A letter-group HEADING row is
# `letter`<TAB><label>; an entry row always opens with a depth digit, so the
# two shapes cannot be confused. Rows appear in rendered order, headings
# among the entries they introduce.
# Same oracle rule as manifest 1, with the HTML back-end's own layers derived
# by hand on top of the level parse:
#   4. No level ceiling: the three-level clamp is a makeindex property, so
#      `One!Two!Three!Four!Five!` nests five deep here — its trailing empty
#      level is dropped when the entry is derived (M11), in every back-end.
#   5. Order, in two parts (M07). Top-level entries are first RANKED INTO
#      GROUPS by the string each files under — its sort key where it has one
#      (step 8, where a manifest has sort keys), its printed text otherwise:
#      the label is that string's first character uppercased when that
#      character is an ASCII letter, and `Symbols` otherwise; no entry files
#      under the empty string, a level that prints nothing having been dropped
#      (M11); groups rank `Symbols` first, then A-Z, and each
#      is introduced by one heading row. Then, WITHIN a group and at every
#      depth below the top — which is not grouped, a sub-entry filing under
#      its parent rather than under a letter — fold ASCII uppercase to
#      lowercase, compare by codepoint, break a fold tie by codepoint.
#   6. Locators: one per locator-contributing mark on that entry, in document
#      order. A cross-reference mark contributes none.
#   7. Cross-reference targets join with `: ` and are hyperlinked exactly when
#      the target's LEVEL LIST is an entry in this index. No target in
#      demo.qmd names an entry, so every row here is `plain`; the linked and
#      colliding-string cases live in xref-conflict.qmd (M03-AC4).
# ---------------------------------------------------------------------------
read -r -d '' DEMO_HTML_INDEX <<'MANIFEST' || true
letter	Symbols
0	!Bang leads	1
0	\	1
0	{Braced}	1
0	~tilde dollar$	1
letter	A
0	A!	0
1	B	1
0	A!B	1
0	Alpha	0
1	Beta	1
letter	B
0	bang	0	see-plain Wow!Hey
0	bang ! quote "	1
0	both	0	see-plain Aye	also-plain Bee
0	bs \ tilde ~ caret ^	1
letter	C
0	café naïve	1
0	Canids	0
1	Foxes	0	see-plain Vulpes
0	cats	0	see-plain Felines
0	Custom Entry	1
letter	D
0	dogs	0	also-plain Pets
0	dollar $ at @ bar |	1
letter	G
0	Ghost	0
1	Sub	1
0	Ghosts	0	also-plain Spirits
0	Grüße	0
1	Straße	1
letter	L
0	less < more >	1
letter	O
0	One	0
1	Two	0
2	Three	0
3	Four	0
4	Five	1
0	owls	0	see-plain Birds: Owls
letter	P
0	pandoc	3
0	pct % amp & hash #	1
letter	S
0	Specials % & # _ { } \ ~ ^ $ @ | ! " < >	1
letter	T
0	Top	0
1	Middle	0
2	Leaf	1
0	Trail bang!	1
letter	U
0	us _ brace { }	1
letter	W
0	Wow!Really	1
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
# Manifest 5 — the aggregated index in examples/book/_book/last.html (M05-AC1,
# AC2, AC3, AC4). EXHAUSTIVE, and stated in HREFS rather than locator counts:
# a book index that links three times to the wrong chapter has the right
# counts and is still wrong.
# Format: <depth><TAB><entry text><TAB><space-separated hrefs>[<TAB><xref>]…
# Same oracle rule as manifest 1e, with the book layers derived by hand on top
# of it, from _quarto.yml and the four chapter sources:
#   8. Chapter order is the `book.chapters` order — index.qmd, one.qmd,
#      sub/two.qmd, last.qmd — and marks within a chapter are in document
#      order, so an entry marked in several chapters lists its locators in
#      that combined order.
#   9. A locator href is the contributing chapter's output page relative to
#      the page holding the index (last.html, at the site root), then `#` and
#      the mark's anchor: a minted `qi-mark-<n>` numbered per chapter in
#      document order, skipping marks that carry an id of the author's own,
#      which keep it. A mark in the marker chapter itself has no page part.
#  10. A cross-reference is linked exactly when some chapter contributes its
#      target entry: `Alpha` is contributed by index.qmd, `No Such Entry` by
#      no chapter at all.
#  11. A range pairs within one Pandoc process and nowhere else (D-009). A
#      chapter is one process, so `Chapter Range` — both marks in last.qmd —
#      pairs there and contributes ONE locator, at its opening mark's anchor.
#      `Ranged Term` opens in one.qmd (its fourth mark) and closes in
#      sub/two.qmd: no chapter sees both halves, so neither is paired and each
#      indexes on its own, the closing carrying the principal class its own
#      `mention=` asks for. The book reports that pair once.
# ---------------------------------------------------------------------------
read -r -d '' BOOK_HTML_INDEX <<'MANIFEST' || true
letter	A
0	Alpha	index.html#qi-mark-2
letter	B
0	Beacon	sub/two.html#qi-mark-2
0	Beta	one.html#qi-mark-1
letter	C
0	Chapter Range	#qi-mark-2
0	Shared Term	index.html#qi-mark-1 one.html#qi-mark-2 sub/two.html#qi-mark-1
letter	D
0	Delta		see-link Alpha
letter	E
0	Epsilon		see-plain No Such Entry
letter	G
0	Gamma	one.html#gamma-anchor
letter	I
0	Invisible Entry	index.html#qi-mark-3
letter	K
0	Kappa	
1	Sub Level	one.html#qi-mark-3
letter	R
0	Ranged Term	one.html#qi-mark-4 sub/two.html#qi-mark-3
letter	Z
0	Zeta	#qi-mark-1
MANIFEST

# The cross-references whose target another chapter contributes (M05-AC4).
# Each row is <source entry><TAB><target entry>: the check reads the target
# entry's minted id from the rendered page and requires the source's link to
# point at exactly that id, which no substring match can establish.
read -r -d '' BOOK_XREF_LINKS <<'MANIFEST' || true
Delta	Alpha
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 6 — terms that must appear in the compiled book PDF's index
# (M05-AC5), each with the number of PAGES its locators must cover (makeindex
# prints three or more consecutive pages as a range, so printed tokens are not
# the same thing as pages).
# The page NUMBERS are never derived here: what a chapter's content lands on
# is the LaTeX layout's business, and copying them from the output is the
# snapshot the oracle rule forbids. The COUNT is derived by hand from the
# sources — one locator per locator-contributing mark on that entry — and is
# what pins the criterion's real claim, that the book PDF aggregates marks
# from every chapter rather than from the one it happens to be printed in.
# ---------------------------------------------------------------------------
read -r -d '' BOOK_PDF_TERMS <<'MANIFEST' || true
1	Alpha
1	Beacon
1	Beta
1	Gamma
1	Invisible Entry
0	Kappa
1	Sub Level
3	Shared Term
1	Zeta
MANIFEST

# The book PDF's cross-references, as exact typeset strings (M05-AC5).
read -r -d '' BOOK_PDF_XREFS <<'MANIFEST' || true
Delta, see Alpha
Epsilon, see No Such Entry
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 7 — the no-marker book (M05-AC6). Each row is <page><TAB><visible
# term>: the term a reader must still see on that page in a book that gets no
# index at all, derived from the two chapter sources.
# ---------------------------------------------------------------------------
read -r -d '' BOOK_NOMARKER_TERMS <<'MANIFEST' || true
index.html	Nomark One
one.html	Nomark Two
MANIFEST

# The book's own reports, named once each (M05 hardening). The store reports
# are what an author gets instead of a failed render when the filter cannot
# read or write a record, so a check that stopped firing would leave an IP2
# guarantee unproven.
WARN_STORE_UNREADABLE='could not be read and were ignored'
WARN_STORE_STALE='were written by a different version of this extension and were ignored'
WARN_STORE_UNWRITABLE='could not record index marks for'
WARN_MARKER_NOT_LAST='chapter(s) come after it'
WARN_MARKER_SECOND='comes first in book order and carries one too'
# One entry given two sort keys in two chapters (M06-AC4). Only the pass that
# has BOTH chapters' records can see it, so it is reported once in two renders.
WARN_BOOK_SORT_CONFLICT='one entry cannot file in two places, so the first in book order wins'

# ---------------------------------------------------------------------------
# Manifest 8 — the ordering fixture's index (M05 hardening), in the same href
# format as manifest 5. Derived by hand from examples/book-order: the marker
# is in index.qmd, `Early` is marked there and `Late` in "later chapter.qmd",
# collation puts Early before Late; `Contested` is marked in both chapters
# with a different sort key in each, and the first in book order (Aaa) wins,
# which files it ahead of both. After two renders the later chapter's stored
# record contributes its locators. The space in the filename is written
# raw, exactly as Quarto writes its own links to that page.
#
# `Contested` carries four locators: one from index.qmd, two from the later
# chapter, which marks it twice, and one from third.qmd. Neither of the two
# extra marks discriminates a per-mark reporting rule — a chapter's record
# carries one declared key per printed level path however many marks write it
# — but third.qmd repeating the SECOND chapter's rival key does discriminate
# once-per-rival-key reporting from once-per-conflicting-chapter. Locators
# appear in book order and, within a chapter, in the order they are marked.
#
# M14 adds the two cross-reference-only marks. Neither carries a locator — a
# cross-reference takes the locator's place — so neither consumes a
# `qi-mark-<n>` and every row above keeps the anchor it had. `Early Reference`
# is marked in the FIRST chapter and points at `Late`, which the SECOND
# contributes: after two renders the store holds that record, so the target is
# a link. `Missing Reference` points at a term no chapter marks, so it stays
# plain text — and is one of the two things the whole book reports.
# `Unclosed` is a range opening in the LAST chapter that no chapter closes: it
# degrades to an ordinary locator, so it takes that chapter's second
# `qi-mark-<n>`, and the report it draws is its own chapter's never-closed one
# — the book's report must NOT name it, having no counterpart in any other
# chapter's record (R4-F1). `Bridged` is the pair the book DOES name — opened
# in the second chapter (its `qi-mark-4`), closed in the third (also
# `qi-mark-4`), each half refused by its own chapter and each an ordinary
# locator. It sits in THIS fixture rather than the four-chapter one because
# this book builds its index in its FIRST chapter, so the book report firing
# here proves it is drawn by the chapter that has seen every record and not by
# the one holding the marker (M21 review F4). `Twice Opened` is AC4's third
# shape inside ONE chapter of a book: the first opening pairs with the closing
# (one locator at `qi-mark-5`), the second opening is refused already-open and
# degrades to an ordinary locator (`qi-mark-6`); the paired closing keeps an
# anchor (`qi-mark-7`) that nothing links to. `Spanned`'s closing is written
# after `Unclosed` in that chapter, so the two take `qi-mark-2` and
# `qi-mark-3` in that order.
# `Spanned` is the other half of that pairing question: its opening carries a
# cross-reference, so the range is refused where it is written, and the closing
# a chapter later must keep the locator it would have had if no `range=` had
# been written at all. Paired on the raw attribute instead, the book suppressed
# that locator and the entry printed its cross-reference alone — while the
# report told the author the mark indexes as it would without the range (M21
# review F1). The row below is what says the locator survived.
# ---------------------------------------------------------------------------
read -r -d '' BOOK_ORDER_INDEX <<'MANIFEST' || true
0	Contested	#qi-mark-2 later chapter.html#qi-mark-2 later chapter.html#qi-mark-3 third.html#qi-mark-1
0	Bridged	later chapter.html#qi-mark-4 third.html#qi-mark-4
0	Early	#qi-mark-1
0	Early Reference		see-link Late
0	Late	later chapter.html#qi-mark-1
0	Missing Reference		see-plain Nowhere At All
0	Spanned	third.html#qi-mark-3	see-link Late
0	Twice Opened	third.html#qi-mark-5 third.html#qi-mark-6
0	Unclosed	third.html#qi-mark-2
MANIFEST

# The missing-marker report, named once (M05-AC6). The class name is part of
# the string because the criterion asks the warning to name how to add a
# marker chapter, not merely that one is missing.
WARN_BOOK_NOMARKER='no chapter carries an index placement marker, so no index was built; write an empty div with class qi-index-here'

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
  local htmlfile="$1" manifest="$2" label="$3" hrefs="${4:-count}"
  printf '%s\n' "$manifest" > "$WORK/html-index.txt"
  HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ROW_HREFS="$hrefs" python3 - \
    "$htmlfile" "$WORK/html-index.txt" "$label" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, manifest_path, label = sys.argv[1:4]
section_id = os.environ['HTML_SECTION_ID']
hrefs = os.environ.get('HTML_ROW_HREFS') == 'hrefs'

doc = H.parse(html_path)
found = H.count_id(doc, section_id)
if found != 1:
    print(f'FAIL: {label}: expected exactly one generated index section '
          f'(id={section_id!r}) in {html_path}, found {found}', file=sys.stderr)
    sys.exit(1)
actual = [H.row(r, hrefs=hrefs)
          for r in H.index_entries(H.find_id(doc, section_id))]
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

# A WHOLE-DOCUMENT sweep for the letter-group heading class (M07-AC3). The
# expected labels are hand-derived, one per line, in the order the page must
# show them; the sweep reads the entire document rather than the index
# section, so a heading that leaked outside the index fails here even though
# the manifest above would never see it. Every hit must also sit outside any
# list item: a group heading introduces the entry list, it is not an entry.
#
# The ELEMENT is asserted, not only its text. AC1 promises a Div and never a
# Header, and the difference is invisible in the label: Quarto copies a
# heading's inlines into the table of contents and mints an id for it, so a
# Header here would put the whole alphabet in the sidebar and add ids to the
# namespace the generated ones are checked against. The class list and the id
# are pinned for the same reason — the README documents the label as carrying
# `qi-letter` and nothing else, and an extra class or a minted id would break
# an author's CSS or that namespace while every label still read correctly.
check_letter_sweep() {
  local htmlfile="$1" label="$2" expected="$3"
  printf '%s\n' "$expected" > "$WORK/letter-sweep.txt"
  HTML_LETTER_CLASS="$HTML_LETTER_CLASS" python3 - \
    "$htmlfile" "$WORK/letter-sweep.txt" "$label" <<'SWEEPPY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
html_path, expected_path, label = sys.argv[1:4]
if H.LETTER_CLASS != os.environ['HTML_LETTER_CLASS']:
    print(f'FAIL: {label}: the suite and the instrument disagree on the '
          f'heading class', file=sys.stderr)
    sys.exit(1)
hits = H.letter_sweep(H.parse(html_path))
expected = H.read_manifest(expected_path)
if not expected:
    print(f'FAIL: {label}: the expected heading list is empty', file=sys.stderr)
    sys.exit(1)
actual = [h['label'] for h in hits]
if actual != expected:
    print(f'FAIL: {label}: {html_path} carries heading labels {actual}, '
          f'expected {expected}', file=sys.stderr)
    sys.exit(1)
inside = [h['label'] for h in hits if h['in_item']]
if inside:
    print(f'FAIL: {label}: heading(s) {inside} sit inside a list item',
          file=sys.stderr)
    sys.exit(1)
wrong_tag = [(h['label'], h['tag']) for h in hits if h['tag'] != 'div']
if wrong_tag:
    print(f'FAIL: {label}: heading(s) are not a div: {wrong_tag}; a heading '
          f'element would copy its text into the table of contents and mint '
          f'an id', file=sys.stderr)
    sys.exit(1)
extra = [(h['label'], h['classes'], h['ident']) for h in hits
         if h['classes'] != [H.LETTER_CLASS] or h['ident'] != '']
if extra:
    print(f'FAIL: {label}: heading(s) carry more than the documented class '
          f'and no id: {extra}', file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: {len(actual)} letter-group heading(s), in order, each a '
      f'div carrying only {H.LETTER_CLASS} and no id, every one outside any '
      f'entry list item')
SWEEPPY
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

# Every check the suite runs, wrapped so the run can count them. The count is
# printed at the end and compared against the merge base at review time: a
# branch that leaves the suite passing with FEWER checks than before has
# quietly dropped evidence, which a green run alone cannot show.
run_all_checks() {
  # `errexit` FIRST, and not inherited: the wrapper below turns it off in the
  # parent so PIPESTATUS can be read, and this function runs in the pipeline's
  # subshell, which inherits that setting. Without this line every check that
  # signals failure only by exit status — which is most of them — would print
  # its FAIL and let the run continue to "All checks passed". The self-test
  # plants exactly that shape and requires the run to die.
  set -e
  if [ "$PLANT_WRAPPER_DEFECT" = "1" ]; then
    python3 -c 'import sys; print("FAIL: planted wrapper defect", file=sys.stderr); sys.exit(1)'
  fi
printf '== supported forms (normative) ==\n'
printf '%s\n' "${SUPPORTED_FORMS[@]}" | awk -F'\t' '{ printf "   %-26s %s\n", $1, $2 }'
printf '   probe characters: %s\n\n' "$PROBE_CHARS"

[ -e examples/_extensions/index/_extension.yml ] \
  || fail "examples/_extensions/index is missing; examples must consume the installed extension"
pass "AC1: demo resolves the extension via examples/_extensions"

# ---------------------------------------------------------------------------
# M16-AC2 — the source set is one recursive enumeration, and it is what every
# source-reading check below sweeps. Printed rather than merely asserted: the
# count is how a reader sees the domain grow when the filter is split, and a
# silent enumeration is one nobody notices going empty.
# ---------------------------------------------------------------------------
printf '== filter source set (%s) ==\n' "$QI_EXT_DIR"
printf '%s\n' "$FILTER_SOURCES" | sed 's/^/   /'
printf '   %s file(s)\n\n' "$FILTER_SOURCE_COUNT"

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

# M06-AC6 — the same discipline for the sort-key documentation. Separate from
# the block above so a failure names which milestone's docs drifted.
printf '%s\n' "${README_SORT_CLAIMS[@]}" > "$WORK/readme-sort.txt"
python3 - "$WORK/readme-sort.txt" README.md <<'SORTDOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = flat(open(sys.argv[2], encoding='utf-8').read())
missing = [f'  missing ({label}): <<{text}>>'
           for label, text in rows if flat(text) not in readme]
if missing:
    print('FAIL: M06-AC6: README.md does not document sort keys as this suite '
          'exercises them:', file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC6: all {len(rows)} documented sort-key behaviors appear '
      f'verbatim in README.md')
SORTDOCPY

# M11-AC6 — and the same for what README says about an empty level.
printf '%s\n' "${README_EMPTY_CLAIMS[@]}" > "$WORK/readme-empty.txt"
python3 - "$WORK/readme-empty.txt" README.md <<'EMPTYDOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = flat(open(sys.argv[2], encoding='utf-8').read())
missing = [f'  missing ({label}): <<{text}>>'
           for label, text in rows if flat(text) not in readme]
if missing:
    print('FAIL: M11-AC6: README.md does not document empty levels as this '
          'suite exercises them:', file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M11-AC6: all {len(rows)} documented empty-level behaviors appear '
      f'verbatim in README.md')
EMPTYDOCPY

# M07-AC6 — and the same for the letter-group documentation.
printf '%s\n' "${README_LETTER_CLAIMS[@]}" > "$WORK/readme-letter.txt"
python3 - "$WORK/readme-letter.txt" README.md <<'LETTERDOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = flat(open(sys.argv[2], encoding='utf-8').read())
missing = [f'  missing ({label}): <<{text}>>'
           for label, text in rows if flat(text) not in readme]
if missing:
    print('FAIL: M07-AC6: README.md does not document letter groups as this '
          'suite exercises them:', file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M07-AC6: all {len(rows)} documented letter-group behaviors appear '
      f'verbatim in README.md')
LETTERDOCPY

# ---------------------------------------------------------------------------
# README claims about misuse reporting (NORMATIVE, M08). Same discipline as
# README_HTML_CLAIMS: the sentences are compared as bytes with whitespace
# normalized, so what the README promises and what this suite exercises cannot
# drift apart. Each row names a behavior M08 added; each PRESENT claim has a
# check above that fails without the behavior, and the STALE row is the
# sentence AC1 falsified. M14 adds the dangling-target report to the same
# family: it is a misuse report about the mark, told in every format.
# ---------------------------------------------------------------------------
README_MISUSE_CLAIMS=(
  $'a div and nothing else\tThe marker class on a heading, on an inline span or on a code block places nothing and is reported'
  $'element left as written\tYour element is left exactly as you wrote it, class included'
  $'self-reference dropped\tThe target is reported and dropped, and the term is then indexed normally'
  $'self-reference judged on print\tA target is judged against what the entry *prints*, so a sort key does not make a self-reference into something else'
  $'section id minted\tThe section id is minted the same way: `qi-index` where the name is free, and `qi-index-1`, `qi-index-2` and so on where the document has taken it'
  $'section id conditional\tin a section whose id is `qi-index` where the document has not taken that name and a minted one where it has'
  $'both attributes narrowed\tNeither is dropped for being one of two: you get one entry carrying both targets'
  $'self-target still dropped\tA target that names its own entry is still dropped for that reason, and the other one is then the only one emitted'
  $'dangling target reported\tA `see=` or `see-also=` naming a term nothing indexes sends a reader to an entry the index does not have'
  $'two ways print as one entry\tOne term marked two different ways prints as one entry'
  $'two ways keep the locators\tyou get a single entry carrying its page numbers and its cross-reference together'
  $'two ways no locator from the xref\tThe cross-reference mark contributes no page number of its own'
  $'two ways no longer fails\tThe extension no longer emits such a pair'
  $'dangling target kept\tIt is not dropped — what you wrote is yours — but you get a warning naming the mark and the target, once per mark per target, whatever you render to'
  $'parent level resolves\tincluding a level that exists only because a deeper entry hangs from it'
  $'book report drawn once\tthe report is drawn once, by the last chapter in book order'
  $'xref channel has an exception\texcept where a term is marked two different ways, whose single composed entry carries the cross-reference in its printed text instead'
  $'two different xrefs keep no locator\tinto one entry carrying both targets and no page numbers at all, since neither mark contributes one'
)
README_MISUSE_STALE=(
  $'clash can fail the build\tOne term marked two different ways can fail the build'
  $'clash cannot be prevented\tPage numbers do not exist when the extension runs, so it cannot prevent the clash'
  $'clash workaround\tGive the cross-reference its own entry, or move the marks apart'
  $'section id fixed\tthe section id `qi-index` itself, which is fixed rather than minted'
  $'section id unconditional\tin a section carrying the id `qi-index`, listed in the table of contents'
  $'nothing dropped\tNothing is dropped: you get one entry carrying both targets'
  # M15: the unqualified claim, which ENDED at the example. A cross-reference
  # on a contested key now travels in the entry\'s printed text instead, so the
  # sentence is pinned as it stood, example and closing period included.
  $'xref always in the encap channel\tA cross-reference is written into the same `\\index{…}` command, through `makeindex`\'s encapsulation channel — `\\index{cats|see{Felines}}`.'
)

printf '%s\n' "${README_MISUSE_CLAIMS[@]}" > "$WORK/readme-misuse.txt"
printf '%s\n' "${README_MISUSE_STALE[@]}" > "$WORK/readme-misuse-stale.txt"
python3 - "$WORK/readme-misuse.txt" "$WORK/readme-misuse-stale.txt" README.md <<'MISUSEDOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


def rows(path):
    return [l.rstrip('\n').split('\t', 1)
            for l in open(path, encoding='utf-8') if l.strip()]


claims, stale = rows(sys.argv[1]), rows(sys.argv[2])
readme = flat(open(sys.argv[3], encoding='utf-8').read())
bad = [f'  missing ({label}): <<{text}>>'
       for label, text in claims if flat(text) not in readme]
bad += [f'  still present ({label}): <<{text}>>'
        for label, text in stale if flat(text) in readme]
if bad:
    print('FAIL: M08: README.md does not document the misuse reports as this '
          'suite exercises them:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M08: all {len(claims)} documented misuse behaviors appear '
      f'verbatim in README.md, and the {len(stale)} sentence(s) this milestone '
      f'falsified are gone')
MISUSEDOCPY

# The probe set is pinned to the filter's own escape table, so a character the
# filter handles can never go unprobed (and vice versa).
run_scan latex-escape-table

# ---------------------------------------------------------------------------
# OUTPUT NEUTRALITY — where the evidence comes from. A checked-in golden `.tex`
# would be a snapshot, which the oracle rule above forbids; the merge-base
# render comparison this repo once carried is deleted, and D-004 records why.
# The checks in this file are the whole oracle for whether a change moved
# rendered output.
# ---------------------------------------------------------------------------

# The HTML back-end's four identifiers are a public surface — a reader's URL
# and an author's CSS hold on to them — so the suite's copies are pinned to
# the filter's own constants, exactly as the dual-target command name is.
run_scan html-identifiers

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
run_scan xref-manifest

# ---------------------------------------------------------------------------
# M02-AC5 — misuse case (b): one warning, one command, render still clean.
# ---------------------------------------------------------------------------

# Assert no `\index` argument in a rendered fixture carries a null field. The
# index tool rejects an entry whose first or middle level is empty — "Illegal
# null field" — drops it, reports no warning and exits 0, so the build looks
# clean and the entry is gone; a trailing one it swallows instead. The domain
# is every `\index` command in the file, read out of the file rather than
# listed here, so a command added later is covered without editing this check.
check_no_null_field() {
  local texfile="$1" label="$2"
  python3 - "$texfile" "$label" <<'NULLFIELDPY'
import sys
path, label = sys.argv[1:3]


def arguments(path):
    """Every `\index{...}` argument in a file, brace-matched.

    A regex stopping at the first `}` reads an argument carrying an encap
    truncated — `\index{Cats!|see{X}}` comes back as `Cats!|see{X`, whose
    last field is non-empty however the real argument actually ends — so a
    trailing null field on any cross-referencing entry was invisible to a
    scan built that way (M11 review F5).
    """
    src = open(path, encoding='utf-8').read()
    out, i, token = [], 0, '\\index{'
    while True:
        start = src.find(token, i)
        if start < 0:
            return out
        j, depth = start + len(token), 1
        while j < len(src) and depth > 0:
            if src[j] == '{':
                depth += 1
            elif src[j] == '}':
                depth -= 1
            j += 1
        out.append(src[start + len(token):j - 1])
        i = j


args = arguments(path)
if not args:
    print(f'FAIL: {label}: no \\index commands in {path} at all, so this scan '
          f'proves nothing about it', file=sys.stderr)
    sys.exit(1)
errs = []
for arg in args:
    # An author's own `!` is quoted `"!` by the escape table, so an unquoted
    # one is a level separator and an empty piece beside it is a null field.
    seps = [i for i, c in enumerate(arg)
            if c == '!' and (i == 0 or arg[i - 1] != '"')]
    fields, last = [], 0
    for i in seps:
        fields.append(arg[last:i])
        last = i + 1
    fields.append(arg[last:])
    for n, field in enumerate(fields, 1):
        if field == '':
            errs.append(f'\\index{{{arg}}} has an empty field at level {n}')
if errs:
    print(f'FAIL: {label}: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: all {len(args)} \\index arguments in {path} carry no '
      f'null field at any level')
NULLFIELDPY
}

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

# The whole message, not its prefix: the tail was reworded in M08 when a
# self-referential target became droppable, and README now pins the matching
# sentence — a prefix-only pattern would let the two drift apart.
WARN_BOTH='index mark carries both see= and see-also=; this is probably a mistake, and neither is dropped for being one of two'
WARN_NO_SOURCE='cross-reference mark has no source entry'
# M14's dangling-target report, keyed on the invariant tail: the head carries
# the attribute, the mark and the target, which differ per report, so a family
# count greps the part every instance shares. The tail is the half that tells
# the author what to do, so pinning it here is what keeps that half from being
# reworded away unnoticed.
WARN_DANGLING='indexes; a reader following the cross-reference finds no such entry, so mark that term somewhere or correct the target'

# One report's full text, assembled from the two halves rather than written
# out per shape: the head carries the attribute, the mark and the target, and
# the tail is WARN_DANGLING, which every instance shares and which is pinned
# once where that constant is defined.
dangling_report() {
  printf '%s= on %s points at "%s", which no index mark in this %s %s' \
    "$1" "$2" "$3" "$4" "$WARN_DANGLING"
}

check_warning_count "$WORK/demo-latex.log" "$WARN_BOTH" 1 "M02-AC5"
pass "M02-AC5: case (b) warned exactly once in the demo render"

# Every warning the filter can emit must be distinct, or "identified by
# distinctive message text" is not a property the suite can rely on. The
# domain is the filter's own warn() literals, so a warning added later is
# covered without editing this check.
run_scan warn-distinct

# The dual-target command must take its labels from LaTeX's own, or a document
# loading babel silently loses its translations — the property the milestone's
# Decisions entry banks on.
run_scan xref-both-definition

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
check_letter_sweep examples/demo.html "M07-AC3 (demo)" \
  $'Symbols\nA\nB\nC\nD\nG\nL\nO\nP\nS\nT\nU\nW'

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
heading_marks = [line for line in qmd.splitlines()
                 if re.match(r'#{1,6} ', line) and marks(line)]
if heading_marks:
    # A heading mark's anchor is emitted on an empty span AFTER the heading,
    # not on the mark span itself — the per-anchor check below assumes none.
    # Detected with the same quote-aware scanner as the count, so a mark a
    # brace-bearing entry= would hide from a regex cannot hide here; setext
    # headings are outside this fixture's idiom.
    print('FAIL: M03-AC3: the span-anchored check assumes demo.qmd holds no '
          'mark inside a heading, but at least one heading contains a mark',
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

# M07-AC1: this render has no entry manifest of its own — its checks are about
# images and \index counts — so its grouping is asserted by a hand-derived
# sweep. Only one mark here indexes anything (entry="Figure!Dot"); the others
# yield no text or are cross-references with no source entry. So one top-level
# entry, `Figure`, and one group.
check_letter_sweep examples/content.html "M07-AC1 (marked content)" $'F'

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
# The emitted LaTeX, kept: the PDF render in the M15 section below removes
# examples/xref-conflict.tex, and two checks there read the argument this
# fixture emits rather than the index it prints.
cp examples/xref-conflict.tex "$WORK/conflict-latex.tex"
# M15 replaced this report's text: the emission no longer risks the failed
# render the old wording warned of, so the report now says what the author's
# two marks print as. Keyed on the clause that names the outcome, not on the
# lead, so a reworded lead cannot pass a check that claims to read the outcome
# — and since the two shapes print differently, on the tail both share plus
# each shape's own outcome clause.
WARN_CLASH='so check that is the entry you meant'
WARN_CLASH_PLAIN='they are printed as one entry with its page numbers and its cross-reference together'
WARN_CLASH_XREFS='they are printed as one entry carrying both targets and, since neither mark contributes one, no page numbers at all'
# Eight contested entries, of which six have a plain mark (chi, Deep!Level,
# kappa, phi, tau, Tree!Branch!Cedar, Dogwood) and two do not (lambda,
# upsilon); mu (two identical see= marks) and nu (two plain marks) must NOT be
# reported at all, which the exact counts are what fence. A no-plain entry told
# it prints page numbers would be told something false, so the split is
# asserted rather than the total alone.
check_warning_count "$WORK/conflict-latex.log" "$WARN_CLASH" 8 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" "$WARN_CLASH_PLAIN" 6 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" "$WARN_CLASH_XREFS" 2 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" 'index entry kappa ' 1 "M02-AC5"
check_warning_count "$WORK/conflict-latex.log" 'index entry lambda ' 1 "M02-AC5"
# Deliberately LaTeX-only, and it stays that way now that HTML has a back-end
# of its own: the clash is a property of makeindex, which rejects two marks
# sharing a key and a page but carrying different encapsulations. The HTML
# back-end has no such limit — it prints the locator and the cross-reference
# on the same entry — so warning about it there would report a problem the
# reader's format does not have.
check_warning_count "$WORK/conflict-html.log" "$WARN_CLASH" 0 "M02-AC5"
pass "M02-AC5: the composed-entry report names each of the eight contested entries once, in the shape that entry has, ignores the two agreeing keys, and is silent in HTML"

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
letter	C
0	chi	1	see-plain % & # _ { } \ ~ ^ $ @ | ! " < >
letter	D
0	Deep	0
1	Level	1	see-plain Shallow
letter	K
0	kappa	2	see-plain Elsewhere
letter	L
0	lambda	0	see-plain Here	also-plain There
letter	M
0	mu	0	see-plain Same
letter	N
0	Note	0
1	on birds	1
0	nu	2
letter	P
0	phi	1	see-plain Aye Two	also-plain Bee Two
letter	R
0	rho	0	see-plain Note: on birds
letter	S
0	sigma	0	see-link Note: on birds
letter	T
0	tau	1	also-plain Elsewhere Again
0	Tree	0
1	Branch	0
2	Cedar	0
3	Dogwood	1	see-plain Afar
2	Maple	0
3	Holly	1
letter	U
0	upsilon	0	see-plain One Way	see-plain Another Way
MANIFEST

check_html_index_manifest examples/xref-conflict.html "$XREF_HTML_INDEX" "M03-AC4"
check_letter_sweep examples/xref-conflict.html "M07-AC3 (cross-references)" \
  $'C\nD\nK\nL\nM\nN\nP\nR\nS\nT\nU'

# The token above says sigma's target is A link; this says it is the RIGHT
# link. A cross-reference pointing at some other entry would satisfy the
# manifest and mislead every reader who followed it.
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/xref-conflict.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
records = H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))
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
# The fixture also writes three ids the extension would otherwise mint for
# itself — `qi-mark-1` on theta, `qi-mark-3` in raw HTML where no mark is,
# `qi-entry-1` on lambda — so the derivation below skips those numbers: ab
# takes qi-mark-2, iota qi-mark-4, kappa qi-mark-5, bee qi-mark-6, Bee
# qi-mark-7, and the entries are numbered from qi-entry-2.
read -r -d '' HTML_INDEX_MANIFEST <<'MANIFEST' || true
letter	A
0	A	0
1	B	1
letter	B
0	Bee	1
0	bee	1
letter	E
0	eta	0	see-link A: B	see-plain A: B
letter	I
0	iota	1
letter	K
0	kappa	1
letter	L
0	lambda	1
letter	N
0	nu	0	see-link A: B
letter	T
0	theta	1
letter	Z
0	zeta	0	see-link A: B
MANIFEST

quarto render examples/html-index.qmd --to html > "$WORK/html-index.log" 2>&1 \
  || { tail -20 "$WORK/html-index.log" >&2; fail "M03-AC4: html-index.qmd failed to render to HTML"; }
check_html_index_manifest examples/html-index.html "$HTML_INDEX_MANIFEST" "M03-AC4"
check_letter_sweep examples/html-index.html "M07-AC3 (no Symbols group)" \
  $'A\nB\nE\nI\nK\nL\nN\nT\nZ'
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
           H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))}
# The author's own ids are kept and linked, not taken over...
for term, want in (('theta', f'#{anchor_prefix}1'),
                   ('lambda', f'#{entry_prefix}1')):
    if records[term]['locators'] != [want]:
        print(f"FAIL: M03-AC3: {term}'s locator is {records[term]['locators']}, "
              f"expected ['{want}'] — an id the author wrote is never taken "
              f"over", file=sys.stderr)
        sys.exit(1)
# ...and nothing minted reuses them — the id written in raw HTML included,
# which only an HTML reading of the document can see.
if records['lambda']['id'] == f'{entry_prefix}1':
    print(f'FAIL: M03-AC3: an entry was numbered {entry_prefix}1, which the '
          f'author already used', file=sys.stderr)
    sys.exit(1)
if records['iota']['locators'] != [f'#{anchor_prefix}4']:
    print(f"FAIL: M03-AC3: iota's locator is {records['iota']['locators']}, "
          f"expected ['#{anchor_prefix}4'] — minting must skip "
          f"{anchor_prefix}3, which the author wrote in raw HTML",
          file=sys.stderr)
    sys.exit(1)
namespace = [i for i in ids if i.startswith(anchor_prefix)]
if (not {f'{anchor_prefix}1', f'{anchor_prefix}3'} <= set(namespace)
        or len(namespace) != 7):
    print(f'FAIL: M03-AC3: expected the two author-written ids plus 5 minted '
          f'anchors, got {sorted(namespace)}', file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC3: minted anchor and entry ids skip the ids the author '
      'already used — the one written in raw HTML included — and every id '
      'in the document is unique')
PY

# ---------------------------------------------------------------------------
# M03-AC2 — locator numbering where the renderer moves content. Manifest 1g,
# same oracle rule and row format as manifest 1e: `widget` is marked in a
# heading, a table cell and a footnote; `gadget` carries an id of the
# author's own; `sprocket` and `flange` share one heading; `doohickey`
# carries an author id INSIDE a heading; `contraption` is a cross-reference
# mark with an author id in a heading (no locator, id still relocates);
# `gizmo` and `thingamajig` share a heading line, but `thingamajig` sits in
# an inline footnote whose text renders at the foot of the page.
# ---------------------------------------------------------------------------
read -r -d '' PLACEMENT_HTML_INDEX <<'MANIFEST' || true
letter	C
0	contraption	0	see-link widget
letter	D
0	doohickey	1
letter	F
0	flange	1
letter	G
0	gadget	1
0	gizmo	1
letter	S
0	sprocket	1
letter	T
0	thingamajig	1
letter	W
0	widget	3
MANIFEST

quarto render examples/placement.qmd --to html > "$WORK/placement-html.log" 2>&1 \
  || { tail -20 "$WORK/placement-html.log" >&2; fail "M03-AC2: placement.qmd failed to render to HTML"; }
check_html_index_manifest examples/placement.html "$PLACEMENT_HTML_INDEX" "M03-AC2"
check_letter_sweep examples/placement.html "M07-AC3 (placement)" \
  $'C\nD\nF\nG\nS\nT\nW'
check_html_index_links examples/placement.html "M03-AC3"

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
python3 - examples/placement.html <<'PY'
import os, sys
from collections import Counter
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
prefix = os.environ['HTML_ANCHOR_PREFIX']
records = {r['term']: r for r in
           H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))}

# Numbered in the order the marks are WRITTEN. The footnote's mark is written
# third and rendered last, so a numbering taken from rendered position would
# put it out of step with the table cell's. The heading mark's anchor is an
# empty span emitted just AFTER the heading, minted like any other.
want = [f'#{prefix}1', f'#{prefix}2', f'#{prefix}3']
if records['widget']['locators'] != want:
    print(f"FAIL: M03-AC2: widget's locators are "
          f"{records['widget']['locators']}, expected {want} (heading, table "
          f"cell, footnote — the order the marks are written)", file=sys.stderr)
    sys.exit(1)

# No anchor id may remain inside a rendered heading: Quarto copies a
# heading's contents into the sidebar table of contents, so an id in there
# appears twice and the locator resolves to the sidebar copy. Every heading
# mark's anchor — minted or the author's own — sits after its heading.
mark_anchors = {f'{prefix}1', f'{prefix}4', f'{prefix}5', f'{prefix}7',
                'my-gadget', 'my-doohickey', 'my-contraption'}
inside = set()
for h in [n for n in H.walk(doc)
          if n.tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6')]:
    inside.update(n.attrs['id'] for n in H.walk(h) if n.attrs.get('id'))
misplaced = sorted(mark_anchors & inside)
if misplaced:
    print(f'FAIL: M03-AC3: anchor id(s) inside a rendered heading, where the '
          f'sidebar TOC duplicates them: {misplaced}', file=sys.stderr)
    sys.exit(1)
toc = H.find_id(doc, 'TOC')
if toc is None:
    print('FAIL: M03-AC2: no rendered table of contents; this fixture exists '
          'to probe TOC duplication and proves nothing without one',
          file=sys.stderr)
    sys.exit(1)
leaked = sorted(mark_anchors & set(H.all_ids(toc)))
if leaked:
    print(f'FAIL: M03-AC3: anchor id(s) duplicated into the table of '
          f'contents: {leaked}', file=sys.stderr)
    sys.exit(1)

# The uniqueness sweep behind the two checks above: with a TOC present, ANY
# duplicated id is visible here. A document-wide uniqueness check on
# demo.html cannot see this, because demo.qmd has no TOC and no heading mark.
dupes = sorted({i for i, n in Counter(H.all_ids(doc)).items() if n > 1})
if dupes:
    print(f'FAIL: M03-AC2: duplicate id(s) in a document with a TOC and '
          f'marks in headings: {dupes}', file=sys.stderr)
    sys.exit(1)
if not any(a.attrs.get('href') == '#qi-index' for a in H.find_all(doc, 'a')):
    print('FAIL: M03-AC2: the generated index section is not linked from the '
          'table of contents', file=sys.stderr)
    sys.exit(1)

# Two marks in one heading get one anchor EACH: a shared anchor sends two
# index entries to a single place.
for term, want_loc in (('sprocket', [f'#{prefix}4']),
                       ('flange', [f'#{prefix}5'])):
    if records[term]['locators'] != want_loc:
        print(f"FAIL: M03-AC3: {term}'s locator is "
              f"{records[term]['locators']}, expected {want_loc} — each of "
              f"two marks in one heading needs an anchor of its own",
              file=sys.stderr)
        sys.exit(1)

# A mark in an inline footnote written in a heading anchors with the note's
# rendered text at the foot of the page, NOT after the heading — while the
# heading's own mark anchors after the heading as usual. The note's mark
# numbers first: it keeps its place inside the heading's own content, ahead
# of the anchors relocated to just after the heading.
if records['thingamajig']['locators'] != [f'#{prefix}6']:
    print(f"FAIL: M03-AC3: thingamajig's locator is "
          f"{records['thingamajig']['locators']}, expected ['#{prefix}6']",
          file=sys.stderr)
    sys.exit(1)
if records['gizmo']['locators'] != [f'#{prefix}7']:
    print(f"FAIL: M03-AC3: gizmo's locator is {records['gizmo']['locators']},"
          f" expected ['#{prefix}7']", file=sys.stderr)
    sys.exit(1)

# The relocation this fixture exists to probe must actually have happened, or
# the checks above prove nothing: the footnote's anchor sits inside the
# footnotes section the renderer moved to the end of the page, AFTER the mark
# that is written below it in the source.
footnotes = H.find_id(doc, 'footnotes')
if footnotes is None or H.find_id(footnotes, f'{prefix}3') is None:
    print(f'FAIL: M03-AC2: {prefix}3 is not inside the rendered footnotes '
          f'section, so this fixture is not probing relocated content',
          file=sys.stderr)
    sys.exit(1)
if H.find_id(footnotes, f'{prefix}6') is None:
    print(f"FAIL: M03-AC3: {prefix}6 (the inline-note mark written in a "
          f"heading) is not inside the rendered footnotes section — its "
          f"anchor was relocated away from where its text renders",
          file=sys.stderr)
    sys.exit(1)
order = H.all_ids(doc)
if order.index('my-gadget') > order.index(f'{prefix}3'):
    print(f'FAIL: M03-AC2: the footnote mark still renders before the mark '
          f'written after it, so nothing was relocated', file=sys.stderr)
    sys.exit(1)

# An author's own id is the link target and no anchor is minted for it — in
# body text (gadget) and relocated out of a heading (doohickey) alike.
for term, own in (('gadget', '#my-gadget'), ('doohickey', '#my-doohickey')):
    if records[term]['locators'] != [own]:
        print(f"FAIL: M03-AC2: {term}'s locator is "
              f"{records[term]['locators']}, expected ['{own}'] — an id the "
              f"author wrote is never taken over", file=sys.stderr)
        sys.exit(1)
minted = [i for i in order if i.startswith(prefix)]
if len(minted) != 7:
    print(f'FAIL: M03-AC2: {len(minted)} anchors minted, expected 7 (three '
          f'widget marks, the two sharing a heading, gizmo and thingamajig; '
          f'the marks carrying author ids need none)', file=sys.stderr)
    sys.exit(1)
print('ok   M03-AC2: locators are numbered in source order across a heading, '
      'a table cell and a relocated footnote; heading anchors sit after '
      'their headings, out of the TOC; author-supplied ids are kept and '
      'linked')
PY

# ---------------------------------------------------------------------------
# M04 — the placement marker: an empty top-level div carrying the class
# `qi-index-here`, which puts the index where the author wrote it.
#
# The class is a public surface exactly as the three HTML identifiers are — an
# author types it — so the suite's copy is pinned to the filter's own constant,
# and pinned to be a DIFFERENT string from the generated section's id, which is
# the collision this token was chosen to avoid.
# ---------------------------------------------------------------------------
MARKER_CLASS='qi-index-here'

run_scan marker-class

# ---------------------------------------------------------------------------
# Manifest 1i — the generated index in examples/marker.html (M04-AC1), same
# oracle rule and row format as manifest 1e. marker.qmd marks `alpha` once on
# each side of the marker, `beta` under entry="Beta!Nested", and `gamma` after
# the marker. Case folds before ordering, so alpha, Beta, gamma; `Beta` itself
# is never marked, so it carries no locator and its sub-entry carries one.
# ---------------------------------------------------------------------------
read -r -d '' MARKER_HTML_INDEX <<'MANIFEST' || true
letter	A
0	alpha	2
letter	B
0	Beta	0
1	Nested	1
letter	G
0	gamma	1
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1m — every sort key examples/sortkey.qmd declares (M06-AC1).
# Derived BY HAND from the fixture, and then checked against the fixture BY
# CONSTRUCTION: the check below extracts every `sort="..."` value the file
# actually carries and fails unless the two sets are equal. A hand-list alone
# would let a sort key added to the fixture go unprobed while the suite still
# reported a pass.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_KEYS <<'MANIFEST' || true
Hague
Angstrom
ten Downing Street
Neumann
Manet
Le Guin
!Turing
!Neumann
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1n — the order and nesting examples/sortkey.pdf must print its
# index in (M06-AC1). Format: <level><TAB><term>, top to bottom, level 0 for
# a top-level entry.
#
# Derived by hand: each entry files under its sort key where it has one
# (Manifest 1m), under its own printed text where it does not, and the order
# is makeindex's, applied to those keys — NOT the HTML collation rule, which
# is the extension's own and orders a punctuation-leading key elsewhere. This
# manifest is derived from makeindex's rule alone and borrows no row order
# from manifest 1o, which is what lets the check comparing the two mean
# something; the keys here are plain letters, on which the two rules happen to
# agree, and a fixture keyed on punctuation would need two orders.
# The keys in order are therefore Angstrom, Hague, Le Guin, Manet,
# mathematicians (which declares none of its own), Neumann, ten Downing
# Street. The two
# sub-entries under `mathematicians` file under Neumann and Turing, which
# reverses the order their printed text alone would give them.
#
# This order differs from the twin fixture's at every top-level position, so
# the check cannot pass on an index that ignored the sort keys.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_PDF_OUTLINE <<'MANIFEST' || true
0	Ångström
0	The Hague
0	Ursula K. Le Guin
0	Édouard Manet
0	mathematicians
1	von Neumann
1	Alan Turing
0	von Neumann
0	10 Downing Street
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1o — the generated index in examples/sortkey.html (M06-AC2).
# EXHAUSTIVE, same format and same oracle rule as manifest 1e, with one
# further layer derived by hand on top of it:
#   8. Order: an entry files under its sort key (manifest 1m) where it has
#      one and under its own printed text where it does not, and the
#      collation of manifest 1e step 5 is then applied to those keys. This
#      is applied at EVERY depth, so the two sub-entries of `mathematicians`
#      file under Neumann and Turing and appear in that order, which is the
#      reverse of what their printed text alone would give.
#
# `The Hague` carries two locators from two marks, only one of which writes
# a sort= of its own: a sort key belongs to the entry, so both marks file
# under it and the term stays one entry rather than becoming two.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_HTML_INDEX <<'MANIFEST' || true
letter	A
0	Ångström	1
letter	H
0	The Hague	2
letter	L
0	Ursula K. Le Guin	1
letter	M
0	Édouard Manet	1
0	mathematicians	0
1	von Neumann	1
1	Alan Turing	1
letter	N
0	von Neumann	1
letter	T
0	10 Downing Street	1
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1p — the same index in examples/sortkey-twin.html (M06-AC2): the
# same entries with no sort keys at all, so manifest 1e step 5 applies to the
# printed text directly. Every top-level row is in a different position than
# it holds in manifest 1o, and the two sub-entries are in the opposite order;
# the check below asserts that rather than trusting this comment.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_TWIN_HTML_INDEX <<'MANIFEST' || true
letter	Symbols
0	10 Downing Street	1
0	Ångström	1
0	Édouard Manet	1
letter	M
0	mathematicians	0
1	Alan Turing	1
1	von Neumann	1
letter	T
0	The Hague	2
letter	U
0	Ursula K. Le Guin	1
letter	V
0	von Neumann	1
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1q — every `\index{}` argument examples/sortkey-paths.tex must
# carry, in document order (M06-AC1/AC2). ORACLE RULE: derived by hand from
# examples/sortkey-paths.qmd, never read back from a render.
#
# Derived as follows. A sort key is declared for one LEVEL of the entry it is
# written on — positionally, an empty sort level meaning "leave this level
# alone" — and applies to that level wherever that level appears, under the
# same parents. A level no mark declares a key for keeps its own printed text,
# and a level whose key equals its printed text needs no `sortkey@` prefix at
# all. So:
#
#   `Hague, The` is declared `Hague` on the mark that carries no sub-entry,
#   and the later `Hague, The!Scheveningen` inherits it at level 1 while
#   level 2 keeps its own text.
#   `Alpha` is declared `Zed` on the mark that DOES carry a sub-entry, and
#   the later bare `Alpha` inherits it — the same rule read the other way.
#   `Beta` has a key declared for level 2 only, so level 1 stays `Beta` and
#   the bare `Beta` mark carries no sort field anywhere: a key must not climb.
#   `Ccc` is left alone by the first mark and declared `Www` by the second,
#   so `Www` is the only declaration at that level and wins for both marks.
#
# The check below also asserts this manifest names as many entries as the
# fixture has marks, so a row cannot go missing unnoticed.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_PATHS_ENTRIES <<'MANIFEST' || true
Hague@Hague, The
Hague@Hague, The!Scheveningen
Zed@Alpha!inner
Zed@Alpha
Beta!gkey@gamma
Beta
Www@Ccc!pk@p
Www@Ccc
"!Zed@Literal
Qqq@Mmm!nn!Ooo@oo
Qqq@Mmm
MANIFEST

# ---------------------------------------------------------------------------
# Manifest 1r — the generated index in examples/sortkey-paths.html
# (M06-AC2). EXHAUSTIVE, same format and oracle rule as manifest 1o.
#
# The top-level keys are the ones manifest 1q derives: `!Zed` for `Literal`,
# Beta, Hague, Qqq for `Mmm`, Www for `Ccc`, and Zed for `Alpha`. Case-folded
# and ordered by character code those give !zed, beta, hague, qqq, www, zed,
# so the six top-level entries print as Literal, Beta, `Hague, The`, Mmm, Ccc,
# Alpha — `!` sorting ahead of every letter is what heads the index with
# `Literal`, whose key is the one-level `!Zed` that `sort="!!Zed"` gives.
#
# Locators sit on the deepest level each mark writes. `Literal` is marked
# alone, so it carries its own locator and no sub-entry. `Mmm` is marked twice
# — once as `Mmm!nn!oo` and once bare — so it carries one locator, its
# sub-entry `nn` carries none, and `oo` beneath that carries one. The other
# four each have one sub-entry carrying one locator, and one of their own.
#
# `Ccc` is the row that reads differently under a key remembered against a
# whole entry rather than against a level: there the first mark's untouched
# level 1 would occupy the slot and file the term under `Ccc`, putting it
# second rather than third.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_PATHS_HTML_INDEX <<'MANIFEST' || true
letter	Symbols
0	Literal	1
letter	B
0	Beta	1
1	gamma	1
letter	H
0	Hague, The	1
1	Scheveningen	1
letter	Q
0	Mmm	1
1	nn	0
2	oo	1
letter	W
0	Ccc	1
1	p	1
letter	Z
0	Alpha	1
1	inner	1
MANIFEST

# Manifest 1j — the \index{} commands examples/marker.tex must carry (M04-AC2).
read -r -d '' MARKER_ENTRIES <<'MANIFEST' || true
2	alpha
1	Beta!Nested
1	gamma
MANIFEST

# Manifest 1k — the generated index in examples/marker-misuse.html (M04-AC4):
# one term marked on each side of the surviving first marker.
read -r -d '' MISUSE_HTML_INDEX <<'MANIFEST' || true
letter	D
0	delta	1
letter	E
0	epsilon	1
MANIFEST

# Terms the compiled PDF's index must carry (M04-AC2). `gamma` is the one that
# matters most: it is marked AFTER the marker, and a mid-document \printindex
# closes the .idx file it has just read, so an unfixed back-end loses every
# such mark to the log — silently, and only for the marks below the marker.
read -r -d '' MARKER_PDF_TERMS <<'MANIFEST' || true
alpha
Beta
Nested
gamma
MANIFEST

# A removed marker must leave nothing behind, asserted structurally rather than
# by grepping for the token: an element that kept the class is residue, and so
# is an empty div that kept none. Quarto's own title block carries one empty
# div in every render, marker or not, so that one is named and allowed.
QUARTO_EMPTY_DIV='quarto-title-meta'
check_no_html_residue() {
  local htmlfile="$1" label="$2"
  MARKER_CLASS="$MARKER_CLASS" QUARTO_EMPTY_DIV="$QUARTO_EMPTY_DIV" \
  python3 - "$htmlfile" "$label" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
path, label = sys.argv[1:3]
doc = H.parse(path)
marker, allowed = os.environ['MARKER_CLASS'], os.environ['QUARTO_EMPTY_DIV']
kept = [n.tag for n in H.walk(doc) if marker in H.classes(n)]
if kept:
    print(f'FAIL: {label}: {len(kept)} element(s) in {path} still carry the '
          f'marker class', file=sys.stderr)
    sys.exit(1)
stray = [n.attrs.get('class', '') for n in H.empty_divs(doc)
         if allowed not in H.classes(n)]
if stray:
    print(f'FAIL: {label}: empty div(s) left where a marker was removed from '
          f'{path}: {stray}', file=sys.stderr)
    sys.exit(1)
print(f'ok   {label}: no marker element and no empty div in {path}')
PY
}

# ---------------------------------------------------------------------------
# M04-AC1 — the index section lands where the marker was written.
# ---------------------------------------------------------------------------
quarto render examples/marker.qmd --to html > "$WORK/marker-html.log" 2>&1 \
  || { tail -20 "$WORK/marker-html.log" >&2; fail "M04-AC1: marker.qmd failed to render to HTML"; }
check_html_index_manifest examples/marker.html "$MARKER_HTML_INDEX" "M04-AC1"
check_letter_sweep examples/marker.html "M07-AC3 (marker)" \
  $'A\nB\nG'
check_html_index_links examples/marker.html "M04-AC1"
check_no_html_residue examples/marker.html "M04-AC1"

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
python3 - examples/marker.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
section_id = os.environ['HTML_SECTION_ID']
prefix = os.environ['HTML_ANCHOR_PREFIX']


def at(identifier):
    """Where this element sits in document order; absent is a failure, not a
    position, so a missing id can never satisfy an ordering comparison."""
    p = H.position_of_id(doc, identifier)
    if p < 0:
        print(f'FAIL: M04-AC1: no element with id {identifier!r} in the '
              f'rendered page', file=sys.stderr)
        sys.exit(1)
    return p


# The marks that bracket the marker in the source — the last one written
# before it, the first one after it — pin the index to a position between the
# two sections' CONTENT. Section ids alone would pass on an index that landed
# inside the first section rather than after it.
before_mark, index_at, after_mark = (at(prefix + '2'), at(section_id),
                                     at(prefix + '3'))
if not before_mark < index_at < after_mark:
    print(f'FAIL: M04-AC1: the index section sits at document position '
          f'{index_at}, not between the mark before the marker ({before_mark}) '
          f'and the mark after it ({after_mark})', file=sys.stderr)
    sys.exit(1)
if not at('before-the-marker') < index_at < at('after-the-marker'):
    print('FAIL: M04-AC1: the index section does not sit between the two body '
          'sections', file=sys.stderr)
    sys.exit(1)
for body in ('before-the-marker', 'after-the-marker'):
    if H.find_id(H.find_id(doc, body), section_id) is not None:
        print(f'FAIL: M04-AC1: the index section is nested inside the '
              f'{body!r} section rather than sitting between the two',
              file=sys.stderr)
        sys.exit(1)
# "and nowhere else on the page": every rendered entry belongs to the one
# generated section, so no second copy of the index sits anywhere.
outside = len(H.find_all(doc, cls='qi-term')) - len(
    H.find_all(H.find_id(doc, section_id), cls='qi-term'))
if outside:
    print(f'FAIL: M04-AC1: {outside} index entry term(s) render outside the '
          f'generated index section', file=sys.stderr)
    sys.exit(1)
print(f'ok   M04-AC1: the index section sits between the two sections\' '
      f'content in document order (position {index_at}), nested in neither, '
      f'and no entry renders anywhere else')
PY

# ---------------------------------------------------------------------------
# M04-AC2 — one \printindex, at the marker, in the emitted .tex.
# ---------------------------------------------------------------------------
quarto render examples/marker.qmd --to latex > "$WORK/marker-latex.log" 2>&1 \
  || { cat "$WORK/marker-latex.log" >&2; fail "M04-AC2: marker.qmd failed to render to LaTeX"; }
[ -s examples/marker.tex ] || fail "M04-AC2: examples/marker.tex is empty"
check_entry_manifest examples/marker.tex "$MARKER_ENTRIES" "M04-AC2"

python3 - examples/marker.tex examples/demo.tex <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
demo = open(sys.argv[2], encoding='utf-8').read()
errs = []
n = src.count('\\printindex')
if n != 1:
    errs.append(f'expected exactly one \\printindex, found {n}')
else:
    first = src.find('\\section{Before the marker}')
    second = src.find('\\section{After the marker}')
    p = src.find('\\printindex')
    if first < 0 or second < 0:
        errs.append('the two section commands are not both in the .tex')
    elif not first < p < second:
        errs.append('\\printindex does not sit between the two sections')
# A mid-document \printindex closes the .idx file it reads, dropping every
# later \index to the log. `noautomatic` is what keeps the file open, and it
# is emitted only where a marker made it necessary — a document without one
# must keep exactly the preamble it has always had.
if '\\usepackage[noautomatic]{imakeidx}' not in src:
    errs.append('the marker document does not load imakeidx with noautomatic')
if 'noautomatic' in demo:
    errs.append('a document with no marker loads imakeidx with noautomatic')
if errs:
    print('FAIL: M04-AC2: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC2: exactly one \\printindex, between the two sections, with '
      'the index file kept open only where a marker required it')
PY

# ---------------------------------------------------------------------------
# M04-AC4 — misuse. Every warning is emitted before the back-end branch, so
# each fires once in EVERY format; the fixture holds one nested marker, one
# second top-level marker, and content inside that second marker.
# ---------------------------------------------------------------------------
WARN_MARKER_NESTED='index placement marker below the top level'
WARN_MARKER_DUP='index placement marker 2 (top-level block 8) is ignored'
WARN_MARKER_CONTENT='index placement marker is not empty'
# The three sort-key reports (M06-AC4). Each is a report about the MARK, so
# each is asserted in a format with an index back-end and in one without.
WARN_SORT_ORPHAN='has nothing to sort; the mark indexes no entry'
WARN_SORT_EXTRA='the extra sort levels were ignored'
WARN_SORT_CONFLICT='written here cannot apply as well, so the first one wins'
WARN_MARKER_NOMARKS='index placement marker in a document with no index marks'
MARKER_KEPT_CONTENT='Content written inside a marker, which no misuse may delete.'

for fmt in html latex gfm; do
  quarto render examples/marker-misuse.qmd --to $fmt \
    > "$WORK/misuse-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/misuse-$fmt.log" >&2; fail "M04-AC4: marker-misuse.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/misuse-$fmt.log" "$WARN_MARKER_NESTED" 1 "M04-AC4"
  check_warning_count "$WORK/misuse-$fmt.log" "$WARN_MARKER_DUP" 1 "M04-AC4"
  check_warning_count "$WORK/misuse-$fmt.log" "$WARN_MARKER_CONTENT" 1 "M04-AC4"
done
pass "M04-AC4: the nested, duplicate and non-empty marker each warn exactly once in HTML, LaTeX and gfm"

# Nothing an author wrote inside a marker may be deleted with it (IP2), in any
# format — including the one with no index back-end at all.
for f in examples/marker-misuse.html examples/marker-misuse.tex examples/marker-misuse.md; do
  grep -qF -- "$MARKER_KEPT_CONTENT" "$f" \
    || fail "M04-AC4: content written inside a marker was deleted from $f"
done
pass "M04-AC4: content written inside a misused marker survives in every format"

check_html_index_manifest examples/marker-misuse.html "$MISUSE_HTML_INDEX" "M04-AC4"
check_letter_sweep examples/marker-misuse.html "M07-AC3 (misused marker)" \
  $'D\nE'

# The content lives inside the marker that PLACES the index, so this pins the
# splice in place_index — not merely the one in resolve_markers, which the
# removed duplicate would exercise. It must land immediately before the index
# it was written in front of.
HTML_SECTION_ID="$HTML_SECTION_ID" MARKER_KEPT_CONTENT="$MARKER_KEPT_CONTENT" \
python3 - examples/marker-misuse.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
kept = os.environ['MARKER_KEPT_CONTENT']
holders = [n for n in H.walk(doc) if H.text(n).strip() == kept]
if not holders:
    print('FAIL: M04-AC4: the content written inside the placing marker is not '
          'in the rendered page', file=sys.stderr)
    sys.exit(1)
# The innermost element holding exactly that text is the paragraph it became.
at = max(H.position(doc, n) for n in holders)
index_at = H.position_of_id(doc, os.environ['HTML_SECTION_ID'])
if index_at < 0 or not at < index_at:
    print(f'FAIL: M04-AC4: the marker content sits at {at}, not before the '
          f'index section it was written in front of ({index_at})',
          file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: content written inside the PLACING marker survives, '
      'immediately before the index it places')
PY
check_no_html_residue examples/marker-misuse.html "M04-AC4"

# Two misused markers, and the index still lands at the first one: after the
# mark written before it, before the mark written after it.
HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
python3 - examples/marker-misuse.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
prefix = os.environ['HTML_ANCHOR_PREFIX']
first = H.position_of_id(doc, prefix + '1')
index_at = H.position_of_id(doc, os.environ['HTML_SECTION_ID'])
second = H.position_of_id(doc, prefix + '2')
if min(first, index_at, second) < 0 or not first < index_at < second:
    print(f'FAIL: M04-AC4: with two misused markers the index sits at '
          f'{index_at}, not at the first marker (between {first} and '
          f'{second})', file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: the index is placed at the first marker, and the nested '
      'and duplicate markers place nothing')
PY

python3 - examples/marker-misuse.tex <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
n = src.count('\\printindex')
if n != 1:
    print(f'FAIL: M04-AC4: expected exactly one \\printindex in a document '
          f'with three markers, found {n}', file=sys.stderr)
    sys.exit(1)
first = src.find('\\index{delta}')
second = src.find('\\index{epsilon}')
p = src.find('\\printindex')
if not first < p < second:
    print('FAIL: M04-AC4: \\printindex is not at the first marker (it must '
          'follow the delta mark and precede the epsilon mark)',
          file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: one \\printindex, at the first marker, in a document '
      'carrying three')
PY

# ---------------------------------------------------------------------------
# M08-AC3 — marker sites. The class only ever places an index on an empty
# top-level div; written on a heading, an inline span or a code block it places
# nothing and is reported, and the element is left exactly as the author wrote
# it (M08's plan gate: the extension reports rather than edits). The message
# M04 pinned for a nested marker is untouched.
# ---------------------------------------------------------------------------
WARN_SITE_HEADING='marker class is written on a heading'
WARN_SITE_SPAN='marker class is written on an inline span'
WARN_SITE_CODE='marker class is written on a code block'

for fmt in html latex gfm; do
  quarto render examples/marker-sites.qmd --to $fmt \
    > "$WORK/sites-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/sites-$fmt.log" >&2; fail "M08-AC3: marker-sites.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_HEADING" 1 "M08-AC3"
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_SPAN" 1 "M08-AC3"
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_CODE" 1 "M08-AC3"
done
pass "M08-AC3: three misplaced marker classes each report, in HTML, LaTeX and gfm"

# The three misplaced sites survive into HTML carrying the class and their
# content. The heading case lands the class on BOTH the <h2> and the <section>
# wrapper Quarto builds around it, so this asserts presence per tag, never a
# count of elements.
MARKER_CLASS="$MARKER_CLASS" python3 - examples/marker-sites.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
cls = os.environ['MARKER_CLASS']
by_tag = {}
for n in H.walk(doc):
    if cls in H.classes(n):
        by_tag.setdefault(n.tag, []).append(n)
errs = []
for tag, want in (('h2', 'A heading carrying the class'),
                  ('span', 'right here'),
                  ('pre', 'A fenced code block carrying the class places nothing.')):
    got = by_tag.get(tag)
    if not got:
        errs.append(f'no <{tag}> carries the marker class')
    elif not any(want in H.text(n) for n in got):
        errs.append(f'the <{tag}> carrying the marker class lost its content '
                    f'(wanted {want!r})')
if errs:
    print('FAIL: M08-AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC3: the heading, inline span and code block carrying the '
      'marker class all survive into HTML with their class and content')
PY

# gfm carries no index back-end, so nothing this extension emits may reach it.
# Class survival is NOT claimed here: gfm has no heading attributes at all, so
# a dropped heading class is the writer's doing and not this filter's.
python3 - examples/marker-sites.md <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
# gfm is a wrapped format: the writer breaks a line wherever it likes, so a
# phrase is compared with whitespace collapsed. Token checks below read the
# raw source, since no token this extension emits contains a space.
flat = re.sub(r'\s+', ' ', src)
errs = []
for want in ('A heading carrying the class', 'right here',
             'A fenced code block carrying the class places nothing.'):
    if want not in flat:
        errs.append(f'visible content {want!r} did not survive into gfm')
for token in ('\\index{', '\\printindex', 'qi-mark-', 'qi-entry-'):
    if token in src:
        errs.append(f'back-end token {token!r} leaked into gfm')
if '\n# Index\n' in src:
    errs.append('an index section was written into gfm')
if errs:
    print('FAIL: M08-AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC3: in gfm the three elements keep their visible content and '
      'no index, anchor or back-end token appears')
PY

# The index still lands at the one real marker, in both back-ends: after the
# delta mark written above it, before the After-the-marker section below it.
python3 - examples/marker-sites.tex <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
n = src.count('\\printindex')
errs = []
if n != 1:
    errs.append(f'expected exactly one \\printindex, found {n}')
else:
    delta, after = src.find('\\index{delta}'), src.find('After the marker')
    p = src.find('\\printindex')
    if min(delta, after) < 0 or not delta < p < after:
        errs.append('\\printindex is not at the one real marker')
if errs:
    print('FAIL: M08-AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC3: one \\printindex, at the one real marker, in a document '
      'carrying the class in five places')
PY

HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
python3 - examples/marker-sites.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
prefix = os.environ['HTML_ANCHOR_PREFIX']
delta = H.position_of_id(doc, prefix + '1')
index_at = H.position_of_id(doc, os.environ['HTML_SECTION_ID'])
epsilon = H.position_of_id(doc, prefix + '2')
if min(delta, index_at, epsilon) < 0 or not delta < epsilon < index_at:
    print(f'FAIL: M08-AC3: the HTML index sits at {index_at}, not at the one '
          f'real marker (after the epsilon mark at {epsilon}, itself after '
          f'the delta mark at {delta})', file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC3: the HTML index is placed at the one real marker, and no '
      'misplaced class placed anything')
PY

# ---------------------------------------------------------------------------
# M08-AC3 (review F4) — the shapes the misplaced-class report must NOT fire on.
# The marker class in the document title is metadata, which the marker
# machinery never reaches; a report there would tell an author something
# untrue. Its own fixture, so marker-sites.qmd's placement counts stay
# undisturbed.
# ---------------------------------------------------------------------------
WARN_MARKER_SITE='marker class is written on'

for fmt in html latex gfm; do
  quarto render examples/marker-shapes.qmd --to $fmt \
    > "$WORK/shapes-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/shapes-$fmt.log" >&2; fail "M08-AC3: marker-shapes.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/shapes-$fmt.log" "$WARN_MARKER_SITE" 0 "M08-AC3 (F4)"
  # The nested markers still report, and the one carrying content still reports
  # as non-empty — neither message is disturbed by the metadata exclusion.
  # 20 nested markers, counted down the fixture: nine singles — #keeps-content,
  # #keeps-sibling, the callout, the tabset, the figure, the block quote, the
  # bullet list, the table cell and the footnote; then two in #doubly, three in
  # #triply, two in the footnote holding a marker inside a marker, two in the
  # bullet list with two marker-only items, one in the definition list, and the
  # one the top-level placement marker wraps (M12). 9+2+3+2+2+1+1 = 20.
  check_warning_count "$WORK/shapes-$fmt.log" "$WARN_MARKER_NESTED" 20 "M08-AC3"
  # Still one: #keeps-content's marker is the only one carrying content of its
  # own, since the nested markers are stripped bottom-up and each outer one is
  # empty by the time it is spliced.
  check_warning_count "$WORK/shapes-$fmt.log" "$WARN_MARKER_CONTENT" 1 "M08-AC3"
done
pass "M08-AC3: a marker class in the document title is reported nowhere, and the nested-marker messages are undisturbed"

# ---------------------------------------------------------------------------
# M12-AC1/AC2/AC3 — the emptied-place report. Every WARNING line the render
# emits is compared whole, not just the lines that already look like the report:
# a report reworded so it no longer matches the template would slip past a
# template-shaped search entirely, and one carrying a container name BEFORE the
# template would slip past a search anchored at the template's first word. So
# the check partitions all of the render's warnings — the two the fixture's
# other shapes are expected to produce, and the emptied-place reports — and any
# line belonging to neither partition fails.
# ---------------------------------------------------------------------------
for fmt in html latex gfm; do
  python3 - "$WORK/shapes-$fmt.log" examples/marker-shapes.qmd "$fmt" <<'PY'
import re, sys

log, fixture, fmt = sys.argv[1], sys.argv[2], sys.argv[3]
TEMPLATE = ('index placement marker in top-level block {} was the only thing '
            'written where it stood; the marker is removed, so nothing you '
            'wrote remains there')
# The other two warnings this fixture draws, whose counts are pinned above.
OTHER = {
    'index placement marker below the top level of the document places '
    'nothing; write it as a top-level block',
    'index placement marker is not empty; the marker should be an empty div, '
    'and its content is kept where the marker was written',
}

src = open(fixture, encoding='utf-8').read()
row = re.search(r'^#\s+reports at top-level blocks:(.*)$', src, re.M)
shapes = re.findall(r'^#\s+(\d+)\s{2}\S', src, re.M)
if row is None or not shapes:
    print('FAIL: M12-AC2: examples/marker-shapes.qmd carries no manifest for '
          'the emptied-place report', file=sys.stderr)
    sys.exit(1)
listed = row.group(1).split()
# The manifest states its expectation twice, once as a list of positions and
# once as a line per report. They are compared to each other before either is
# used, so a manifest that quietly lost a row cannot make this check pass by
# expecting less than the fixture holds.
if sorted(listed, key=int) != sorted(shapes, key=int):
    print(f'FAIL: M12-AC2: the manifest disagrees with itself — positions '
          f'{listed} against report lines {shapes}', file=sys.stderr)
    sys.exit(1)

text = re.sub(r'\x1b\[[0-9;]*m', '', open(log, encoding='utf-8',
                                          errors='replace').read())
# Every warning the render emitted, as its full text.
emitted = [m.group(1).rstrip() for m in re.finditer(r'^\(W\) (.*)$', text, re.M)]
got = sorted(w for w in emitted if w not in OTHER)
want = sorted(TEMPLATE.format(n) for n in listed)

if got != want:
    print(f'FAIL: M12-AC1/AC2 ({fmt}): the warnings that are not the fixture\'s '
          f'two known ones are not the manifest\'s emptied-place reports',
          file=sys.stderr)
    for w in want:
        if w not in got:
            print(f'  missing: <<{w}>>', file=sys.stderr)
    for g in got:
        if g not in want:
            print(f'  unexpected: <<{g}>>', file=sys.stderr)
    sys.exit(1)
if len(emitted) == len(got):
    print('FAIL: M12-AC1: the render emitted none of the fixture\'s other two '
          'warnings, so the partition this check rests on is not fencing '
          'anything', file=sys.stderr)
    sys.exit(1)
print(f'ok   M12-AC1/AC2/AC3 ({fmt}): of {len(emitted)} warnings, the {len(got)} '
      f'that are not the fixture\'s two known ones are exactly the manifest\'s '
      f'emptied-place reports, each the one template with only its block '
      f'position varying')
PY
done
pass "M12-AC1/AC2/AC3: every warning the three renders emit is either one of the fixture's two known ones or an emptied-place report matching the manifest whole, naming nothing"

# M12-AC5 (IP2) — the fixture renders in all three formats above, and the only
# marker class any output carries is the one Quarto writes from the fixture's
# own YAML title. That one is metadata, which the marker machinery never
# reaches (M08) and this milestone does not touch; every other occurrence would
# be a marker div that survived into a body, which is the residue IP2 forbids.
# Located, not counted: the check reads what each occurrence sits in, so a body
# occurrence fails even though the total is unchanged.
python3 - examples/marker-shapes.html examples/marker-shapes.tex examples/marker-shapes.md <<'PY'
import re, sys

errs = []
for path in sys.argv[1:]:
    try:
        text = open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        errs.append(f'{path} was not produced')
        continue
    for m in re.finditer(r'qi-index-here', text):
        start = text.rfind('\n', 0, m.start()) + 1
        end = text.find('\n', m.end())
        line = text[start:end if end != -1 else len(text)]
        # The title Quarto writes from the fixture's YAML, in the two formats
        # that carry one: an <h1 class="title"> in HTML, the leading `# ` line
        # in gfm. Anything else carrying the class is a surviving marker.
        if 'class="title"' in line or line.startswith('# quarto-index marker-shape probe'):
            continue
        errs.append(f'{path}: the marker class survives outside the title: '
                    f'{line.strip()[:120]}')

if errs:
    print('FAIL: M12-AC5: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M12-AC5: marker-shapes renders to all three formats, and the only '
      'qi-index-here in any output is the one Quarto writes from the '
      'fixture\'s own title')
PY


# What a nested marker carried is spliced in where it stood, so its container
# keeps that content — pinned structurally, not merely by a warning count.
python3 - examples/marker-shapes.html <<'PY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
errs = []
kept = [n for n in H.walk(doc) if n.attrs.get('id') == 'keeps-content']
if not kept:
    errs.append('the container holding a marker with content is gone')
elif 'Content the marker kept' not in H.text(kept[0]):
    errs.append('the content a nested marker carried was not spliced into its '
                'container')
section = H.index_section(doc)
if section is None:
    errs.append('no index section was found')
else:
    after = [n for n in H.walk(doc)
             if n.tag in ('h1', 'h2') and 'After the marker' in H.text(n)]
    if not after or not H.position(doc, section) < H.position(doc, after[0]):
        errs.append('the index is not at the marker that wrapped a nested one')
if errs:
    print('FAIL: M08-AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC3: a nested marker\'s content survives in its container, and '
      'the marker wrapping a nested one still places the index')
PY

# ---------------------------------------------------------------------------
# M08-AC1 — the generated section id is minted, not fixed. Anchor and entry
# ids have always stepped over a name the document already uses; the section
# id did not, so a document claiming `qi-index` got two elements carrying it.
# The fixture claims five names in the five spellings taken_identifiers reads
# — a Pandoc attribute, and raw HTML double-quoted, unquoted, uppercase `ID=`
# and single-quoted in a raw INLINE — so the mint has to step over all five.
# ---------------------------------------------------------------------------
quarto render examples/id-collision.qmd --to html \
  > "$WORK/id-collision-html.log" 2>&1 \
  || { tail -20 "$WORK/id-collision-html.log" >&2; fail "M08-AC1: id-collision.qmd failed to render to HTML"; }

python3 - examples/id-collision.html <<'PY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
claimed = ['qi-index', 'qi-index-1', 'qi-index-2', 'qi-index-3', 'qi-index-4']
errs = []

# The universal is over the ids this extension mints and the names the fixture
# claimed — the namespace it owns. A duplicate elsewhere on the page would be
# Quarto's own furniture, which this milestone neither generates nor promises.
dupes = H.duplicate_ids(doc, prefix='qi-')
if dupes:
    errs.append(f'ids carried by two elements: {dupes}')

for name in claimed:
    n = H.count_id(doc, name)
    if n != 1:
        errs.append(f'the claimed id {name!r} appears {n} time(s), not once')

section = H.index_section(doc)
if section is None:
    errs.append('no index section was found by its heading')
else:
    got = section.attrs.get('id', '')
    if not got:
        errs.append('the index section carries no id at all')
    elif got in claimed:
        errs.append(f'the index section took {got!r}, a name the document '
                    f'already claimed')

if errs:
    print('FAIL: M08-AC1: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print(f'ok   M08-AC1: five claimed ids each survive once, the index section '
      f'minted {H.index_section(doc).attrs["id"]!r} past all five, and no '
      f'qi- id is carried twice')
PY

# The locators must still link: minting a fresh section id is worth nothing if
# the index it names stopped resolving.
python3 - examples/id-collision.html <<'PY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
section = H.index_section(doc)
hrefs = [a.attrs.get('href', '') for a in H.find_all(section, 'a')]
local = [h for h in hrefs if h.startswith('#')]
missing = [h for h in local if H.count_id(doc, h[1:]) != 1]
if not local:
    print('FAIL: M08-AC1: the index section carries no local links at all',
          file=sys.stderr)
    sys.exit(1)
if missing:
    print(f'FAIL: M08-AC1: index links resolving to no unique element: '
          f'{missing}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M08-AC1: all {len(local)} link(s) inside the minted index section '
      f'resolve to exactly one element each')
PY

# ---------------------------------------------------------------------------
# M08-AC2 — a cross-reference target naming its own entry. Reported and
# dropped, and then the term indexes as usual: the positive residue is asserted
# too, because an implementation that simply dropped the whole mark would
# satisfy every absence clause here while losing the term — the IP2 corruption
# this milestone exists to prevent.
#
# Four shapes: entry= single-level, entry= two-level, entry derived from the
# visible text, and both attributes with only the see= self-targeting. A fifth
# mark cross-references a DIFFERENT entry and must be untouched, which is what
# tells this check from one that drops every target.
# ---------------------------------------------------------------------------
# Every key the run greps a mark report by, declared in ONE place above every
# section that uses one. They used to sit in the sections that grep them, which
# put two of them below the scan that sweeps them — a shell variable read before
# its assignment expands to nothing, so the scan would have swept an empty
# needle and reported perfect distinctness over nothing (M21 review F6). The
# scan now refuses an empty key as well, so the two guards are independent.
M20_UNKNOWN='names no role this extension knows'
M20_NOLOCATOR='has no locator to emphasize'
M20_UNINDEXED='the mark indexes nothing, so there is no locator to emphasize'
R_UNKNOWN='names neither end of a range'
R_DISPLACED='there is no locator for a range to span'
R_ALREADY='opens a range for a term whose range is already open'
R_NOOPEN='closes a range this'
R_NOCLOSE='is never closed in this'
# The book's own range report (D-009): an HTML book pairs no range across its
# chapters, and once per render it names the would-be pairs it can see split
# across them — only those; a one-chapter fault is its chapter's to report.
R_BOOKUNPAIRED='is not paired across the chapters of an HTML book'
WARN_SELF_XREF='names the entry it is written on'

# M10 replaces one shared constant with a count per format. The counts must be
# free to differ: a fold-induced self-reference exists only where the levels
# are folded, so LaTeX reports three that HTML and gfm correctly report none of
# (M10-AC4). A single shared constant cannot express that, and a check that
# cannot express the difference cannot detect losing it.
WARN_FOLD_SELF='names the folded path this entry prints'
# Narrowed at M18, which added a second message about the same ceiling — the
# one drawn when the fold rewrites a TARGET. A key both messages match counts
# neither, which is what the distinctness scan below catches.
WARN_FOLD_DEPTH='and deeper were folded into the third'
WARN_FOLD_TARGET='so the target is folded exactly as an entry is'

for fmt in html latex gfm; do
  quarto render examples/self-xref.qmd --to $fmt \
    > "$WORK/self-xref-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/self-xref-$fmt.log" >&2; fail "M08-AC2: self-xref.qmd failed to render to $fmt"; }
  # M08's four shapes plus M10's two empty-level shapes. The empty-level case
  # is format-neutral — an empty level prints nothing in every back-end and in
  # none — so the count is the same in all three, and M11 does not move it:
  # both shapes were already caught here, M10 by ignoring empty levels on both
  # sides of the comparison and M11 by there being none left to ignore.
  check_warning_count "$WORK/self-xref-$fmt.log" "$WARN_SELF_XREF" 6 "M10-AC4"
  # The both-attributes report is about the MARK, not about its targets, so
  # dropping one of the two must not silence it.
  check_warning_count "$WORK/self-xref-$fmt.log" "$WARN_BOTH" 1 "M08-AC2"
done
# Three in LaTeX, none anywhere else. The zero is the load-bearing half: it is
# what says the fold rule stayed inside the back-end whose fold it is. These
# are the three genuinely over-deep entries; `entry="P!Q!R!"` is not among them
# and never was, its target having been caught by the format-neutral pass above
# before this back-end ran.
check_warning_count "$WORK/self-xref-latex.log" "$WARN_FOLD_SELF" 3 "M10-AC4"
check_warning_count "$WORK/self-xref-html.log"  "$WARN_FOLD_SELF" 0 "M10-AC4"
check_warning_count "$WORK/self-xref-gfm.log"   "$WARN_FOLD_SELF" 0 "M10-AC4"
# M11: one trivial mistake draws one warning. `entry="P!Q!R!"` used to be told
# as well that it was four levels deep and had been folded, though the path it
# printed was unchanged — two warnings for one stray `!`. With the empty level
# dropped it is three levels and nothing folds, so this count is three and not
# four: A!B!C!D, F!G!H!I!J and M!N!O!P, the entries that really are too deep.
# The zeros say the fold belongs to the back-end that folds.
check_warning_count "$WORK/self-xref-latex.log" "$WARN_FOLD_DEPTH" 3 "M11-AC5"
check_warning_count "$WORK/self-xref-html.log"  "$WARN_FOLD_DEPTH" 0 "M11-AC5"
check_warning_count "$WORK/self-xref-gfm.log"   "$WARN_FOLD_DEPTH" 0 "M11-AC5"
pass "M08-AC2/M10-AC4/M11-AC5: six self-referential targets each report once in HTML, LaTeX and gfm; the three fold-induced ones report in LaTeX alone; only the three genuinely over-deep entries are told they folded, the stray trailing `!` no longer among them; the both-attributes report still fires"

# ---------------------------------------------------------------------------
# M10-AC4 — the three messages that speak about these marks must stay
# separable. All three quote the same `entry="..."` context, so a count keyed
# on context alone cannot come back as one; what keeps them apart is the key
# each check greps for. Asserted as the operational claim: each key matches its
# own filter warning and none of the others. The domain is every key the run
# passes the scan, which is what makes adding a report to the run without
# adding its key here a failure rather than a silent gap (M18 review F3).
# ---------------------------------------------------------------------------
run_scan mark-report-keys

python3 - examples/self-xref.tex <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
errs = []
# The three marks whose only target was dropped index plainly: one \index each,
# on their own key, carrying no encap at all.
for want in ('\\index{Cats}', '\\index{Birds!Owls}', '\\index{ferrets}'):
    # Exact: the encap form of the same key is `\index{Cats|see{...}}`, whose
    # `|` sits where this string's closing brace is, so it cannot match here.
    n = src.count(want)
    if n != 1:
        errs.append(f'expected exactly one {want}, found {n}')
# The fourth keeps the target that was NOT self-referential, and only that one.
# M14 retargeted it from `Pets`, which this file never indexed, to `Cats`,
# which it does: the surviving half of a both-attributes mark is meant to be a
# working cross-reference, and a target naming nothing is now itself reported.
if src.count('\\index{Dogs|seealso{Cats}}') != 1:
    errs.append('the surviving see-also target on the both-attributes mark was '
                'not emitted as its only encap')
if 'quartoindexseeboth' in src:
    errs.append('the both-targets command was emitted though one target was '
                'dropped')
# The control: a target naming a different entry is untouched.
if src.count('\\index{Lynxes|see{Cats}}') != 1:
    errs.append('the cross-reference to a DIFFERENT entry was not emitted; '
                'this check cannot tell a self-reference from any reference')
# No self-encap survives anywhere.
for bad in ('\\index{Cats|see{Cats}}', '\\index{Birds!Owls|seealso{Birds: Owls}}',
            '\\index{ferrets|see{ferrets}}', '\\index{Dogs|see{Dogs}}'):
    if bad in src:
        errs.append(f'a self-referential encap survived: {bad}')
if errs:
    print('FAIL: M08-AC2: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC2: three self-targeting marks index plainly, the fourth keeps '
      'only its surviving see-also, and a target naming another entry is '
      'untouched')
PY

python3 - examples/self-xref.html <<'PY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse('examples/self-xref.html')
section = H.index_section(doc)
errs = []

records = H.entry_records(section)
by_term = {r['term']: r for r in records}
# The three marks whose only target was dropped are ordinary entries again:
# each carries at least one locator link back into the text.
for term in ('Cats', 'Owls', 'ferrets'):
    rec = by_term.get(term)
    if rec is None:
        errs.append(f'entry {term!r} is not in the index at all')
    elif not rec['locators']:
        errs.append(f'entry {term!r} carries no locator')
# The fourth carries its surviving cross-reference and, per the documented
# semantics, no locator.
dogs = by_term.get('Dogs')
if dogs is None:
    errs.append("entry 'Dogs' is not in the index")
else:
    if dogs['locators']:
        errs.append("entry 'Dogs' carries a locator though it still has a "
                    "cross-reference")
    targets = [target for _kind, target, _linked, _href in dogs['xrefs']]
    if targets != ['Cats']:
        errs.append(f"entry 'Dogs' should carry exactly its surviving see-also "
                    f"target, carries {targets}")
# The control: a target naming a DIFFERENT entry is untouched and still links.
lynxes = by_term.get('Lynxes')
if lynxes is None:
    errs.append("entry 'Lynxes' is not in the index")
elif [t for _k, t, _l, _h in lynxes['xrefs']] != ['Cats']:
    errs.append("the cross-reference to a different entry did not survive; "
                "this check cannot tell a self-reference from any reference")

# No link anywhere inside the index points at the entry that contains it.
for record in records:
    own = record['id']
    if not own:
        continue
    hrefs = list(record['locators'])
    hrefs += [href for _k, _t, _l, href in record['xrefs'] if href]
    if ('#' + own) in hrefs:
        errs.append(f'entry {record["term"]!r} links to itself')

if errs:
    print('FAIL: M08-AC2: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC2: the three dropped-target entries carry locators again, '
      'the both-attributes entry keeps only its see-also, the control '
      'cross-reference survives, and no entry links to itself')
PY

# ---------------------------------------------------------------------------
# M10-AC1/AC2 — the five shapes M08's comparison could not see. Each expected
# argument is stated in full: an extractor keyed on the author's `entry=` text
# would find nothing for the sort-key shape, whose emitted argument
# (`m@M!n@N!o@O, P`) contains none of it, and would then pass vacuously.
#
# Exactness works the same way it does in the M08 block above: the encap form
# of any of these keys puts a `|` exactly where the expected string's closing
# brace is, so no expected string can match an encapped command.
# ---------------------------------------------------------------------------
python3 - examples/self-xref.tex <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
errs = []
# AC1: the three fold shapes. AC2: the two empty-level shapes, which since M11
# reach this back-end with their empty levels already dropped. Each indexes
# plainly, on the key it files under, with no encap at all.
plain = {
    'A!B!C!D':     '\\index{A!B!C, D}',
    'F!G!H!I!J':   '\\index{F!G!H, I, J}',
    'M!N!O!P':     '\\index{m@M!n@N!o@O, P}',
    'Moles!':      '\\index{Moles}',
    'P!Q!R!':      '\\index{P!Q!R}',
}
for entry, want in plain.items():
    n = src.count(want)
    if n != 1:
        errs.append(f'entry="{entry}": expected exactly one {want}, found {n}')
# The pre-fix output, named literally. A rule that stopped emitting these marks
# altogether would satisfy every clause above; these say the target went and
# the term stayed.
for bad in ('\\index{A!B!C, D|seealso{A: B: C, D}}',
            '\\index{F!G!H, I, J|see{F: G: H, I, J}}',
            '\\index{m@M!n@N!o@O, P|seealso{M: N: O, P}}',
            '\\index{Moles|see{Moles}}',
            '\\index{P!Q!R|seealso{P: Q: R}}'):
    if bad in src:
        errs.append(f'a self-referential encap survived the fold: {bad}')
# The count of \index commands is asserted so that "found exactly one" above
# cannot be met by a run that emitted the mark twice under different keys.
total = len(re.findall(r'\\index\{', src))
if total != 10:
    errs.append(f'expected 10 \\index commands in the fixture, found {total}')
if errs:
    print('FAIL: M10-AC1/AC2: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M10-AC1/AC2: the three folded shapes and the two empty-level '
      'shapes each index plainly, and no pre-fix self-encap survives')
PY
# M11-AC2, taken here rather than in the M11 block below: this fixture is
# re-rendered to PDF later in the run and the .tex does not survive it.
check_no_null_field examples/self-xref.tex "M11-AC2 (self-xref)"

# ---------------------------------------------------------------------------
# M10-AC2/AC3 — the same five shapes in HTML, where there is no level ceiling.
# The two empty-level shapes are self-references here too and lose their
# targets; the three folded shapes are NOT, and must keep theirs. Since M11 an
# empty level is dropped rather than kept, so the entries that used to print no
# text at all are gone: `entry="Moles!"` is the single top-level term `Moles`
# and `entry="P!Q!R!"` is `P` -> `Q` -> `R`. Both are asserted to have NO child
# below them, which is what says the level went rather than merely printing
# blank, and to carry the locator themselves.
# ---------------------------------------------------------------------------
python3 - examples/self-xref.html <<'PY'
import re, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse('examples/self-xref.html')
section = H.index_section(doc)
records = H.entry_records(section)
errs = []

def entry_at(term, depth):
    """The record whose term is `term` at `depth`, and the record after it.

    By term now rather than by position: since M11 the entries this locates
    print their own text, an empty level having been dropped rather than kept
    as a child that printed nothing.
    """
    for i, r in enumerate(records):
        if r['term'] == term and r['depth'] == depth:
            nxt = records[i + 1] if i + 1 < len(records) else None
            return r, nxt
    return None, None

# AC2 — the two entries whose empty level was dropped. Each is a real entry
# node (a span carrying qi-term and a minted qi-entry id), carries no
# cross-reference any more, and carries the locator itself: the mark still
# indexes, which is the IP2 half of the rule. The deepest level is the entry's
# own, so nothing hangs below it — the check that says the level went rather
# than merely rendering blank.
for term, depth in (('Moles', 0), ('R', 2)):
    rec, nxt = entry_at(term, depth)
    if rec is None:
        errs.append(f'no depth-{depth} entry {term!r}')
        continue
    if nxt is not None and nxt['depth'] > depth:
        errs.append(f'{term!r} still has a child {nxt["term"]!r} at depth '
                    f'{nxt["depth"]}, so the empty level was kept')
    node = H.find_id(doc, rec['id']) if rec['id'] else None
    if node is None:
        errs.append(f'the entry {term!r} carries no id')
    else:
        if node.tag != 'span':
            errs.append(f'the entry {term!r} is a <{node.tag}>, want span')
        if 'qi-term' not in H.classes(node):
            errs.append(f'the entry {term!r} lacks the qi-term class, '
                        f'has {H.classes(node)}')
        if not re.fullmatch(r'qi-entry-\d+', rec['id']):
            errs.append(f'the entry {term!r} carries a non-minted id '
                        f'{rec["id"]!r}')
    if rec['xrefs']:
        errs.append(f'the entry {term!r} still carries '
                    f'{[t for _k, t, _l, _h in rec["xrefs"]]}')
    if not rec['locators']:
        errs.append(f'the entry {term!r} carries no locator, so the '
                    f'term was lost rather than indexed plainly')

# AC3 — HTML applies no fold, so none of the three folded shapes is a
# self-reference here and all three keep their targets.
for parent, depth, want in (('D', 4, 'A: B: C, D'),
                            ('J', 5, 'F: G: H, I, J'),
                            ('P', 4, 'M: N: O, P')):
    rec = next((r for r in records
                if r['term'] == parent and r['depth'] == depth - 1), None)
    if rec is None:
        errs.append(f'the depth-{depth-1} entry {parent!r} is missing from the index')
        continue
    # The href is read, not discarded: M18-AC2 says these three targets are
    # left UNLINKED here, and a check that drops it asserts only that they
    # survive (M18 review F4). They are unlinked because HTML folds nothing,
    # so the folded path each names is a path no mark in this file indexes —
    # the same fact the format-neutral report draws in this format.
    targets = [(t, h) for _k, t, _l, h in rec['xrefs']]
    if targets != [(want, None)]:
        errs.append(f'entry {parent!r} should keep its target {want!r} as plain '
                    f'text with no link, has {targets}')

if errs:
    print('FAIL: M10-AC2/AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M10-AC2/AC3 + M18-AC2: both empty-level entries lost their '
      'self-targets, index plainly at the levels that survived with nothing '
      'below them, and all three folded entries keep theirs as unlinked text, '
      'HTML having no level ceiling')
PY

# ---------------------------------------------------------------------------
# M04-AC4 — a marker in a document with no index marks. The residue claim is
# made at its strongest here: the same document with the marker deleted by
# hand renders byte-for-byte identically, in every format. An empty div, an
# empty group, a stray blank line — anything the marker left behind is a diff.
# ---------------------------------------------------------------------------
python3 - examples/marker-nomarks.qmd examples/marker-nomarks-twin.qmd \
  "$MARKER_CLASS" <<'PY'
import sys
fixture, twin, cls = (open(sys.argv[1], encoding='utf-8').read(),
                      open(sys.argv[2], encoding='utf-8').read(), sys.argv[3])
out, skip = [], False
for line in fixture.splitlines(True):
    stripped = line.strip()
    if stripped == '::: {.%s}' % cls:
        skip = True
        continue
    if skip and stripped == ':::':
        skip = False
        continue
    out.append(line)
if ''.join(out) != twin:
    print('FAIL: M04-AC4: the twin fixture is not the marker fixture with its '
          'marker block deleted; the two have drifted apart and the byte '
          'comparison below would compare two different documents',
          file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: the twin fixture is the marker fixture with the marker '
      'block deleted, and nothing else')
PY

for fmt in html latex gfm; do
  for f in marker-nomarks marker-nomarks-twin; do
    quarto render examples/$f.qmd --to $fmt > "$WORK/$f-$fmt.log" 2>&1 \
      || { tail -20 "$WORK/$f-$fmt.log" >&2; fail "M04-AC4: $f.qmd failed to render to $fmt"; }
  done
  check_warning_count "$WORK/marker-nomarks-$fmt.log" "$WARN_MARKER_NOMARKS" 1 "M04-AC4"
  check_warning_count "$WORK/marker-nomarks-twin-$fmt.log" "$WARN_MARKER_NOMARKS" 0 "M04-AC4"
done
pass "M04-AC4: a marker with no marks to place warns once in each format, and the same document without the marker warns not at all"

python3 - examples/marker-nomarks examples/marker-nomarks-twin <<'PY'
import sys
fixture, twin = sys.argv[1:3]
bad = []
for ext in ('.html', '.tex', '.md'):
    got = open(fixture + ext, encoding='utf-8').read()
    # The twin's own basename appears in a rendered page; it is the one
    # difference that is not residue, so it is normalized away. The longer
    # name is replaced first — the shorter is a prefix of it.
    want = open(twin + ext, encoding='utf-8').read().replace(
        twin.rsplit('/', 1)[-1], fixture.rsplit('/', 1)[-1])
    if got != want:
        bad.append(ext)
if bad:
    print(f'FAIL: M04-AC4: the marker left something behind in {bad}: the '
          f'render differs from the same document with the marker deleted',
          file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: with no index to place, all three renders are '
      'byte-identical to the same document without the marker')
PY

for tok in '\printindex' 'imakeidx'; do
  if grep -qF -- "$tok" examples/marker-nomarks.tex; then
    fail "M04-AC4: a document whose only index-related content is a marker must not contain $tok"
  fi
done
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/marker-nomarks.html <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
if H.find_id(doc, os.environ['HTML_SECTION_ID']) is not None:
    print('FAIL: M04-AC4: a document with a marker but no marks has a '
          'generated index section', file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC4: a marker with no marks to place emits no index section '
      'and no \\printindex')
PY
check_no_html_residue examples/marker-nomarks.html "M04-AC4"

# ---------------------------------------------------------------------------
# M04-AC4 — the one marker case the filter cannot repair: a document that has
# already loaded imakeidx keeps its own options, so Quarto's conditional load
# never applies `noautomatic` and the index file is closed at the marker. The
# terms below the marker are lost, so the loss is made loud — a begin-document
# warning naming what will be missing.
# ---------------------------------------------------------------------------
quarto render examples/marker-preloaded.qmd --to latex \
  > "$WORK/preloaded-latex.log" 2>&1 \
  || { tail -20 "$WORK/preloaded-latex.log" >&2; fail "M04-AC4: marker-preloaded.qmd failed to render to LaTeX"; }
grep -qF 'ifpackagewith{imakeidx}{noautomatic}' examples/marker-preloaded.tex \
  || fail "M04-AC4: the marker document carries no begin-document check for a preloaded imakeidx"
if grep -qF 'ifpackagewith{imakeidx}' examples/demo.tex; then
  fail "M04-AC4: a document with no marker carries the preloaded-imakeidx check"
fi
# `\PassOptionsToPackage` must NOT be emitted beside the check: it registers the
# option on the already-loaded package, which makes the check report success on
# exactly the document it exists to catch.
if grep -qF 'PassOptionsToPackage{noautomatic}{imakeidx}' examples/marker-preloaded.tex; then
  fail "M04-AC4: PassOptionsToPackage is emitted alongside the check and would silence it"
fi
pass "M04-AC4: a marker document carries the preloaded-imakeidx check, a marker-free one does not, and nothing silences it"

# ---------------------------------------------------------------------------
# M04-AC5 — gfm has no index back-end, so the marker fixture must come out of
# it with no marker element, no empty div and no token. Read structurally
# first: gfm carries spans as inline HTML, so the parser sees any element the
# marker might have left, and the token grep is the belt to that braces.
# ---------------------------------------------------------------------------
quarto render examples/marker.qmd --to gfm > "$WORK/marker-gfm.log" 2>&1 \
  || { tail -20 "$WORK/marker-gfm.log" >&2; fail "M04-AC5: marker.qmd failed to render to gfm"; }
[ -s examples/marker.md ] || fail "M04-AC5: examples/marker.md is empty"

MARKER_CLASS="$MARKER_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" python3 - \
  examples/marker.md <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
path = sys.argv[1]
doc = H.parse(path)
marker = os.environ['MARKER_CLASS']
kept = [n.tag for n in H.walk(doc) if marker in H.classes(n)]
if kept:
    print(f'FAIL: M04-AC5: {path} still carries {len(kept)} marker element(s)',
          file=sys.stderr)
    sys.exit(1)
if H.empty_divs(doc) or H.find_all(doc, 'div'):
    print(f'FAIL: M04-AC5: {path} carries a div; gfm output of this fixture '
          f'has no div of its own, so any div is marker residue',
          file=sys.stderr)
    sys.exit(1)
if H.find_id(doc, os.environ['HTML_SECTION_ID']) is not None:
    print('FAIL: M04-AC5: gfm output carries a generated index section',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M04-AC5: {path} carries no marker element, no div and no index '
      f'section')
PY
for tok in 'qi-index-here' 'qi-index' 'printindex'; do
  if grep -qF -- "$tok" examples/marker.md; then
    fail "M04-AC5: gfm output must not contain $tok"
  fi
done
grep -qF 'gamma' examples/marker.md || fail "M04-AC5: gfm output lost visible term text"
pass "M04-AC5: the marker leaves no token in gfm output, and the visible text is kept"

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
terms = {r['term'] for r in H.entry_records(section)}
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

# M07-AC1/AC3 — the heading list for a render whose entries are checked as a
# SET rather than in order. Derived by hand from the fixture's own domain:
# every printable ASCII character except space files at the top level, so the
# non-letters form the leading Symbols group and each letter forms a group
# holding its upper- and lower-case entries — 27 headings, Symbols then A-Z.
check_letter_sweep examples/escaping.html "M07-AC1 (escaping)" \
  $'Symbols\nA\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ'

# M03-AC3 — the pending tag is filter plumbing and must never survive into
# rendered output; nor may an author's FORGED copy steal a real mark's anchor
# (examples/html-index.qmd carries a forged copy on a non-mark span and on a
# cross-reference mark — the anchor numbering above already pins that neither
# consumed a minted id).
if grep -l 'data-qi-pending' examples/*.html >/dev/null 2>&1; then
  fail "M03-AC3: data-qi-pending survived into rendered HTML: $(grep -l 'data-qi-pending' examples/*.html | tr '\n' ' ')"
fi
pass "M03-AC3: the pending attribute reaches no rendered HTML, forged author copies included"

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

# M07-AC5 — and no letter-group heading either: no marks, no groups.
if grep -qF -- "$HTML_LETTER_CLASS" examples/control.html; then
  fail "M07-AC5: a document with no marks carries $HTML_LETTER_CLASS"
fi
pass "M07-AC5: a document with no marks gets no letter-group heading"

quarto render examples/demo.qmd --to gfm > "$WORK/demo-gfm.log" 2>&1 \
  || { tail -20 "$WORK/demo-gfm.log" >&2; fail "M03-AC6: demo.qmd failed to render to gfm"; }
[ -s examples/demo.md ] || fail "M03-AC6: examples/demo.md is empty"
for tok in 'qi-index' 'qi-mark-' 'qi-entry-' '\index' '\printindex'; do
  if grep -qF -- "$tok" examples/demo.md; then
    fail "M03-AC6: gfm output must not contain $tok (gfm has no index back-end)"
  fi
done
# M07-AC5 — a format with no index back-end builds no index, so it can carry
# neither the heading class nor the label a heading would show. `Symbols` is
# the one label that is a word rather than a letter, so it is the one that can
# be looked for without matching ordinary prose.
if grep -qF -- "$HTML_LETTER_CLASS" examples/demo.md; then
  fail "M07-AC5: gfm output must not contain $HTML_LETTER_CLASS"
fi
if grep -qF 'Symbols' examples/demo.md; then
  fail "M07-AC5: gfm output carries a letter-group label"
fi
pass "M07-AC5: gfm output carries neither the heading class nor a group label"
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

# M04-AC5 — the marker fixture goes through the same beamer compile. beamer
# has no index back-end, so the marker must leave no residue there either and
# the render must stay clean (IP2).
quarto render examples/marker.qmd --to beamer -M keep-tex:true \
  > "$WORK/marker-beamer.log" 2>&1 \
  || { tail -20 "$WORK/marker-beamer.log" >&2; fail "M04-AC5: the marker fixture failed to render to beamer (IP2: a marker must never break a render)"; }
[ -s examples/marker.tex ] || fail "M04-AC5: the beamer render kept no .tex to inspect"
for tok in '\index' 'imakeidx' '\makeindex' '\printindex' 'qi-index-here'; do
  if grep -qF -- "$tok" examples/marker.tex; then
    fail "M04-AC5: the beamer .tex must not contain $tok"
  fi
done
grep -qF 'gamma' examples/marker.tex || fail "M04-AC5: the beamer .tex lost visible term text"
pass "M04-AC5: the marker fixture compiles clean in beamer, no index tokens, no marker residue, visible text kept"

# ---------------------------------------------------------------------------
# M04-AC2 — end to end: the compiled PDF's index sits at the marker, and it
# carries the marks written on BOTH sides of it. The slice is bounded by the
# heading of the section that follows the index, never by end-of-file: an
# index printed mid-document has body text after it, and a slice running to
# the end would find the fixture's terms in that body text whatever the index
# contained.
# ---------------------------------------------------------------------------
quarto render examples/marker.qmd --to pdf > "$WORK/marker-pdf.log" 2>&1 \
  || { tail -40 "$WORK/marker-pdf.log" >&2; fail "M04-AC2: marker.qmd failed to render to PDF"; }
[ -s examples/marker.pdf ] || fail "M04-AC2: examples/marker.pdf is empty"
pdftotext -layout examples/marker.pdf "$WORK/marker.txt"

printf '%s\n' "$MARKER_PDF_TERMS" > "$WORK/markerterms.txt"
python3 - "$WORK/marker.txt" "$WORK/markerterms.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
terms = [l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8') if l.strip()]

m = re.search(r'^\s*Index\s*$', text, re.MULTILINE)
if not m:
    print('FAIL: M04-AC2: no "Index" heading in pdftotext output',
          file=sys.stderr)
    sys.exit(1)
after = text.find('After the marker', m.end())
if after < 0:
    print('FAIL: M04-AC2: the second section\'s heading does not follow the '
          'index in the compiled PDF, so the index was not printed at the '
          'marker', file=sys.stderr)
    sys.exit(1)
# Two-column index setting collapses to single spaces, as the other PDF
# checks do.
region = ' '.join(text[m.end():after].split())
missing = [t for t in terms if ' '.join(t.split()) not in region]
if missing:
    print('FAIL: M04-AC2: term(s) missing from the PDF index printed at the '
          'marker:', file=sys.stderr)
    for t in missing:
        print(f'  <<{t}>>', file=sys.stderr)
    print(f'--- index slice ---\n{region[:800]}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M04-AC2: the PDF index is printed at the marker and lists all '
      f'{len(terms)} derived terms, the ones marked after it included')
PY

# The begin-document check is only worth emitting if it FIRES on the document
# it names and stays silent on the one it does not. Both halves are compiled
# here with the engine that ships, since the warning exists only in a LaTeX
# run's log.
mkdir -p "$WORK/preloaded" && cp examples/marker-preloaded.tex "$WORK/preloaded/"
( cd "$WORK/preloaded" && pdflatex -interaction=nonstopmode marker-preloaded.tex ) \
  > "$WORK/preloaded-tex.log" 2>&1 \
  || { grep -E '^! ' "$WORK/preloaded-tex.log" | head -5 >&2; fail "M04-AC4: the preloaded-imakeidx fixture failed to compile (IP2: it must still render)"; }
grep -qF 'Package quarto-index Warning' "$WORK/preloaded/marker-preloaded.log" \
  || fail "M04-AC4: a document that preloads imakeidx compiled without the warning naming the terms it will lose"
# The loss the warning is about, shown rather than asserted from memory: the
# term marked after the marker never reaches the index file.
grep -qF 'indexentry{zeta|' "$WORK/preloaded/marker-preloaded.idx" \
  || fail "M04-AC4: the preloaded fixture indexed nothing before the marker; it is not probing what it claims"
if grep -qF 'indexentry{omega|' "$WORK/preloaded/marker-preloaded.idx"; then
  fail "M04-AC4: the preloaded fixture kept the term marked after the marker, so the warning it emits is now false"
fi
# The control: the ordinary marker fixture loads imakeidx with the option and
# must compile silent, or the check above proves only that it always fires.
mkdir -p "$WORK/markertex" && quarto render examples/marker.qmd --to latex > "$WORK/marker-latex2.log" 2>&1 \
  || { cat "$WORK/marker-latex2.log" >&2; fail "M04-AC4: marker.qmd failed to re-render to LaTeX"; }
cp examples/marker.tex "$WORK/markertex/"
( cd "$WORK/markertex" && pdflatex -interaction=nonstopmode marker.tex ) \
  > "$WORK/markertex-tex.log" 2>&1 \
  || { grep -E '^! ' "$WORK/markertex-tex.log" | head -5 >&2; fail "M04-AC4: the marker fixture failed to compile"; }
if grep -qF 'Package quarto-index Warning' "$WORK/markertex/marker.log"; then
  fail "M04-AC4: the ordinary marker fixture warns about a preloaded imakeidx, which it does not have"
fi
pass "M04-AC4: the preloaded-imakeidx document compiles, warns, and demonstrably loses the term below its marker, while the ordinary marker document compiles silent"

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
# M05 — book projects. A book renders each chapter in its own Pandoc process,
# so the questions here are ones no single-document check can ask: whether the
# index is built ONCE for the whole site, and whether a link written on the
# page holding the index reaches an anchor on another chapter's page.
# ---------------------------------------------------------------------------
BOOK_DIR="examples/book"
BOOK_OUT="$BOOK_DIR/_book"
STORE_SUFFIX='.qi.json'
STORE_DIR='quarto-index'
# Read from the filter rather than written down here. Every planted record
# below has to be one the CURRENT filter would accept, or the check meant to
# prove some other rule keeps it out passes because the version rejected it
# first — which is what happened when this milestone bumped the version.
STORE_VERSION=$(run_scan store-version)

# The store's own name is a pinned surface like the HTML back-end's ids: the
# footprint sweep below asks "no file named like this under the output
# directory", which proves nothing if the filter names its files something
# else entirely.
run_scan store-names

# A full render from nothing: the store starts empty, so an index built here
# was built from THIS render's chapters and not from a record left behind.
rm -rf "$BOOK_OUT" "$BOOK_DIR/.quarto"
( cd "$BOOK_DIR" && quarto render --to html ) > "$WORK/book-html.log" 2>&1 \
  || { tail -30 "$WORK/book-html.log" >&2; fail "M05-AC1: the book fixture failed to render to HTML"; }

check_html_index_manifest "$BOOK_OUT/last.html" "$BOOK_HTML_INDEX" \
  "M05-AC1/AC3" hrefs
# M21-AC5's role half, read HERE and not in the M21 section below: later
# hardening steps deliberately corrupt a chapter's record and re-render
# `last.qmd` alone, so the copy left in the output directory at the end of a run
# is not the state this criterion is about. Same discipline as the manifest
# check above, which is why it sits beside it.
# Copied at the render, so the self-test's plants below mutate THIS run's
# artifact rather than whatever the output directory holds by the end of a run —
# later hardening steps deliberately corrupt a record and re-render last.qmd
# alone (M15's lesson, in the shape a book takes).
cp "$BOOK_OUT/last.html" "$WORK/book-last.html"
HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" \
  python3 tests/m21probes.py bookhtml "$WORK/book-last.html"
pass "M21-AC5: a range paired inside one chapter gives one locator; a range spanning chapters pairs nowhere and each mark indexes on its own, the closing keeping the role it declares"
# M07-AC4: the book's B group holds Beta, marked in one.qmd, and Beacon,
# marked in sub/two.qmd — a group gathers what every chapter contributed.
check_letter_sweep "$BOOK_OUT/last.html" "M07-AC4" \
  $'A\nB\nC\nD\nE\nG\nI\nK\nR\nZ'

# The manifest above is the positive half: it says the marker chapter's index
# is the whole book's. This is the negative half, and the questions only a
# recursive walk of the rendered site can answer.
HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
STORE_SUFFIX="$STORE_SUFFIX" python3 - "$BOOK_OUT" "$BOOK_DIR" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
out, project = sys.argv[1], sys.argv[2]
section_id = os.environ['HTML_SECTION_ID']
anchor_prefix = os.environ['HTML_ANCHOR_PREFIX']
suffix = os.environ['STORE_SUFFIX']
INDEX_PAGE = 'last.html'

pages = H.html_files(out)
for expected in (INDEX_PAGE, 'index.html', 'one.html', 'sub/two.html'):
    if expected not in pages:
        print(f'FAIL: M05-AC1: {expected} is not among the rendered pages '
              f'{pages}', file=sys.stderr)
        sys.exit(1)
docs = {page: H.parse(os.path.join(out, page)) for page in pages}

# --- exactly one index across the site ------------------------------------
carrying = [p for p in pages if H.count_id(docs[p], section_id) > 0]
if carrying != [INDEX_PAGE]:
    print(f'FAIL: M05-AC1: the index section (id={section_id!r}) appears on '
          f'{carrying}, expected only [{INDEX_PAGE!r}]', file=sys.stderr)
    sys.exit(1)
if H.count_id(docs[INDEX_PAGE], section_id) != 1:
    print(f'FAIL: M05-AC1: {INDEX_PAGE} carries more than one index section',
          file=sys.stderr)
    sys.exit(1)
# An entry list is the index's other half: a page could carry the entries
# without the section id and the check above would not see it.
stray = [p for p in pages
         if p != INDEX_PAGE and H.find_all(docs[p], cls='qi-term')]
if stray:
    print(f'FAIL: M05-AC1: index entry markup on page(s) that hold no index: '
          f'{stray}', file=sys.stderr)
    sys.exit(1)

# --- the store is real, and none of it is in the output -------------------
def store_files(root):
    return sorted(os.path.join(base, name)
                  for base, _dirs, files in os.walk(root)
                  for name in files if name.endswith(suffix))

written = store_files(project + '/.quarto')
if not written:
    print(f'FAIL: M05-AC1: no store file was written under {project}/.quarto; '
          f'the footprint sweep below would pass on a filter that never '
          f'wrote a store at all', file=sys.stderr)
    sys.exit(1)
leaked = store_files(out)
if leaked:
    print(f'FAIL: M05-AC1: store file(s) under the output directory: '
          f'{leaked}', file=sys.stderr)
    sys.exit(1)

# --- every locator link reaches a real anchor on a real page (AC2) --------
ids = {page: set(H.all_ids(doc)) for page, doc in docs.items()}
section = H.find_id(docs[INDEX_PAGE], section_id)
records = H.entry_records(section)
locators = [href for r in records for href in r['locators']]
broken = []
for link in H.find_all(section, 'a'):
    href = link.attrs.get('href', '')
    resolved = H.resolve_href(INDEX_PAGE, href)
    if resolved is None:
        broken.append(f'  {href!r} leaves the site')
        continue
    target, fragment = resolved
    if not fragment:
        broken.append(f'  {href!r} names no anchor')
    elif target not in ids:
        broken.append(f'  {href!r} points at {target!r}, which is not a '
                      f'rendered page')
    elif fragment not in ids[target]:
        broken.append(f'  {href!r} points at no id in {target!r}')
if broken:
    print('FAIL: M05-AC2: link(s) in the book index do not resolve:',
          file=sys.stderr)
    print('\n'.join(broken), file=sys.stderr)
    sys.exit(1)

# --- the axes AC2 asks the fixture to vary, read off the render -----------
# Derived from what was rendered rather than recalled from the sources: a
# fixture edit that quietly drops one of these shapes fails here instead of
# leaving the criterion's claim untested.
targets = [H.resolve_href(INDEX_PAGE, href) for href in locators]
pages_linked = {t for t, _f in targets}
gaps = []
if len(pages_linked) < 3:
    gaps.append(f'locators reach only {sorted(pages_linked)}, fewer than three '
                f'chapters')
if not any('/' in t for t, _f in targets):
    gaps.append('no locator reaches a chapter in a subdirectory')
if not any(t == INDEX_PAGE for t, _f in targets):
    gaps.append('no locator points within the page holding the index')
if not any(not f.startswith(anchor_prefix) for _t, f in targets):
    gaps.append("no locator uses an id of the author's own")
# The heading case: a mark written inside a heading must anchor OUTSIDE it,
# or Quarto's table-of-contents copy duplicates the id (the M03 rule) — asked
# here of a link that crosses a file boundary.
def ids_in_headings(doc):
    inside = set()
    for node in H.walk(doc):
        if node.tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
            inside |= {n.attrs['id'] for n in H.walk(node) if n.attrs.get('id')}
    return inside
heading_marked = [p for p in pages
                  if any(node.tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6')
                         and 'Beta' in H.text(node)
                         for node in H.walk(docs[p]))]
if not heading_marked:
    gaps.append('no chapter marks a term inside a heading')
else:
    for target, fragment in targets:
        if target in heading_marked and fragment in ids_in_headings(docs[target]):
            gaps.append(f'locator #{fragment} on {target} sits inside a '
                        f'heading, where Quarto duplicates it into the '
                        f'table of contents')
# The invisible form contributes an entry with no visible text of its own.
if 'Invisible Entry' in H.text(docs['index.html'], ' '):
    gaps.append("the invisible mark's entry text appears in the chapter body, "
                "so the invisible form is not what the fixture exercises")
if gaps:
    print('FAIL: M05-AC2: the fixture does not vary every axis the criterion '
          'names:', file=sys.stderr)
    for gap in gaps:
        print(f'  {gap}', file=sys.stderr)
    sys.exit(1)

print(f'ok   M05-AC1/AC2: one index across {len(pages)} rendered pages, no '
      f'store file in the output ({len(written)} written outside it), all '
      f'{len(locators)} locators resolve to a real anchor, and they vary '
      f'chapter, subdirectory, same-page, author-id and heading form')
PY

# M05-AC4 — a cross-reference whose target entry only another chapter
# contributes links to that entry's id. Read structurally: the target entry's
# id is minted at render time, so a manifest cannot state it, but which entry
# the link must reach is derived by hand.
printf '%s\n' "$BOOK_XREF_LINKS" > "$WORK/book-xrefs.txt"
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - "$BOOK_OUT/last.html" \
  "$WORK/book-xrefs.txt" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
records = H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))
by_term = {r['term']: r for r in records}
rows = [l.rstrip('\n').split('\t') for l in open(sys.argv[2], encoding='utf-8')
        if l.strip()]
bad = []
for source, target in rows:
    if source not in by_term or target not in by_term:
        bad.append(f'  {source!r} -> {target!r}: entry missing from the index')
        continue
    want = '#' + by_term[target]['id']
    got = [href for _kind, _text, _linked, href in by_term[source]['xrefs']]
    if want not in got:
        bad.append(f'  {source!r} links to {got}, expected {want!r} (the id '
                   f'of the {target!r} entry)')
if bad:
    print('FAIL: M05-AC4: cross-file cross-reference(s) do not link to their '
          'target entry:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M05-AC4: all {len(rows)} cross-file cross-reference(s) link to '
      f'the id of the entry another chapter contributes')
PY

# The unresolvable target is in the exhaustive manifest above as `see-plain`,
# which is the criterion's "renders as unlinked text". M14 replaces AC4's
# other half — "the book renders with nothing to report at all" — because that
# target names a term no chapter indexes and M14-AC5 requires the book to say
# so, once. What AC4 was really asserting survives as the stronger claim: every
# warning the whole book emits is one this suite can NAME, so `see="Alpha"`,
# whose entry another chapter contributes, draws none. Counted across the whole
# four-chapter render, which is what says a single chapter drew each. M21 adds
# three more nameable ones: each chapter of the split `Ranged Term` pair
# reports its own half over the chapter (D-009 makes a chapter the pairing
# scope), and the book names the split pair once.
BOOK_DANGLING='see= on term "Epsilon" in sub/two.qmd points at "No Such Entry", which no index mark in this book indexes; a reader following the cross-reference finds no such entry, so mark that term somewhere or correct the target'
check_warning_count "$WORK/book-html.log" "$BOOK_DANGLING" 1 "M14-AC5"
BOOK_WARNINGS=4
if [ "$( { grep -c '^(W)' "$WORK/book-html.log" || true; } )" != "$BOOK_WARNINGS" ]; then
  grep '^(W)' "$WORK/book-html.log" >&2
  fail "M05-AC4/M14-AC5: the book fixture emitted warning(s) this suite cannot name; its $BOOK_WARNINGS are the dangling-target report, the two chapter halves of the split range, and the book's own unpaired-range report — and a resolvable cross-file target must draw none"
fi
pass "M05-AC4/M14-AC5: all four of the book's warnings are ones this suite names — the target no chapter indexes, each chapter's half of the split range, and the book's report naming the pair — and the resolvable cross-file target draws neither"

# ---------------------------------------------------------------------------
# M05-AC6 — a book with marks and no marker chapter.
# ---------------------------------------------------------------------------
NOMARKER_DIR="examples/book-nomarker"
rm -rf "$NOMARKER_DIR/_book" "$NOMARKER_DIR/.quarto"
( cd "$NOMARKER_DIR" && quarto render --to html ) \
  > "$WORK/book-nomarker.log" 2>&1 \
  || { tail -30 "$WORK/book-nomarker.log" >&2; fail "M05-AC6: the no-marker book failed to render to HTML"; }

printf '%s\n' "$BOOK_NOMARKER_TERMS" > "$WORK/nomarker-terms.txt"
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - "$NOMARKER_DIR/_book" \
  "$WORK/nomarker-terms.txt" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
out, manifest = sys.argv[1], sys.argv[2]
section_id = os.environ['HTML_SECTION_ID']
pages = H.html_files(out)
docs = {page: H.parse(os.path.join(out, page)) for page in pages}
carrying = [p for p in pages if H.count_id(docs[p], section_id) > 0
            or H.find_all(docs[p], cls='qi-term')]
if carrying:
    print(f'FAIL: M05-AC6: a book with no marker chapter built an index on '
          f'{carrying}', file=sys.stderr)
    sys.exit(1)
rows = [l.rstrip('\n').split('\t') for l in open(manifest, encoding='utf-8')
        if l.strip()]
missing = []
for page, term in rows:
    if page not in docs:
        missing.append(f'  {page} was not rendered')
    elif term not in H.text(docs[page], ' '):
        missing.append(f'  {term!r} is not visible on {page}')
if missing:
    print('FAIL: M05-AC6: marked term(s) lost from a book that gets no index:',
          file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M05-AC6: no index on any of the {len(pages)} pages, and all '
      f'{len(rows)} marked terms still visible where they were written')
PY

check_warning_count "$WORK/book-nomarker.log" "$WARN_BOOK_NOMARKER" 1 "M05-AC6"
pass "M05-AC6: the missing-marker report fires exactly once in a full render, naming the marker div"

# ---------------------------------------------------------------------------
# M05-AC5 — the book PDF. One merged document, so the LaTeX back-end needs
# none of the store machinery; this pins that it still aggregates every
# chapter's marks into one printed index (GP6).
# ---------------------------------------------------------------------------
( cd "$BOOK_DIR" && quarto render --to pdf ) > "$WORK/book-pdf.log" 2>&1 \
  || { tail -40 "$WORK/book-pdf.log" >&2; fail "M05-AC5: the book fixture failed to render to PDF"; }
BOOK_PDF=$(find "$BOOK_OUT" -maxdepth 1 -name '*.pdf' | head -1)
[ -s "$BOOK_PDF" ] || fail "M05-AC5: the book render produced no PDF"
pdftotext -layout "$BOOK_PDF" "$WORK/book.txt"

printf '%s\n' "$BOOK_PDF_TERMS" > "$WORK/book-pdf-terms.txt"
printf '%s\n' "$BOOK_PDF_XREFS" > "$WORK/book-pdf-xrefs.txt"
python3 - "$WORK/book.txt" "$WORK/book-pdf-terms.txt" \
  "$WORK/book-pdf-xrefs.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
rows = [l.rstrip('\n').split('\t') for l in open(sys.argv[2], encoding='utf-8')
        if l.strip()]
xrefs = [l.rstrip('\n') for l in open(sys.argv[3], encoding='utf-8')
         if l.strip()]

m = re.search(r'^\s*Index\s*$', text, re.MULTILINE)
if not m:
    print('FAIL: M05-AC5: no "Index" heading in the book PDF', file=sys.stderr)
    sys.exit(1)
# The printed index is set in two columns, so layout spacing collapses the
# same way the single-document checks collapse it.
region = ' '.join(text[m.end():].split())

# One printed locator: a page number, or a range of them. makeindex collapses
# three or more consecutive pages into a range (`3--5`, typeset as an en
# dash), so a locator list is counted in PAGES rather than in printed tokens —
# whether a term's pages happen to be consecutive is pagination, and this
# check must not depend on it.
LOCATOR = r'\d+(?:[-–—]\d+)?'


def pages_after(term):
    # Anchored on both sides: without a boundary, a row asserting a term has
    # NO page numbers passes on a region where that term never reached the
    # index and only appears inside a longer one.
    m = re.search(r'(?<![\w])' + re.escape(term) + r'(?![\w])'
                  + r'((?:,\s' + LOCATOR + r')*)', region)
    if m is None:
        return None
    total = 0
    for token in re.findall(LOCATOR, m.group(1)):
        ends = re.split(r'[-–—]', token)
        total += 1 if len(ends) == 1 else int(ends[1]) - int(ends[0]) + 1
    return total


bad = []
for count, term in rows:
    # The page numbers themselves are the layout's business and are never
    # derived here; how MANY pages follow the term is derived from the
    # sources — one per locator-contributing mark, each in its own chapter,
    # and a book class starts every chapter on a new page — and that count is
    # what shows the printed index aggregated across chapters.
    got = pages_after(term)
    if got is None:
        bad.append(f'  {term!r} is not in the printed index at all')
    elif got != int(count):
        bad.append(f'  {term!r} is followed by {got} page(s) in the printed '
                   f'index, expected {count}')
for xref in xrefs:
    if ' '.join(xref.split()) not in region:
        bad.append(f'  cross-reference <<{xref}>> is not in the printed index')
if bad:
    print('FAIL: M05-AC5: the book PDF index does not match the manifest:',
          file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    print(f'--- index region ---\n{region[:1200]}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M05-AC5: the book PDF prints one index carrying all {len(rows)} '
      f'derived terms with their derived locator counts, and all '
      f'{len(xrefs)} cross-references')
PY

# ---------------------------------------------------------------------------
# M05 hardening — the dimensions one clean-slate render cannot reach: a second
# render over a store that already has records, a stale record for a chapter
# the book no longer lists, a marker that is not in the last chapter, a second
# marker chapter, and a store this filter cannot write at all. None of these
# is named by a criterion; all of them are behaviour this milestone shipped,
# and a green suite is evidence about what it covers (LESSONS 2026-08-16).
# ---------------------------------------------------------------------------

# A second full render must produce the same index, not a doubled one: the
# marker chapter reads a store that already holds its own previous record.
( cd "$BOOK_DIR" && quarto render --to html ) > "$WORK/book-html2.log" 2>&1 \
  || { tail -30 "$WORK/book-html2.log" >&2; fail "M05 hardening: the second book render failed"; }
check_html_index_manifest "$BOOK_OUT/last.html" "$BOOK_HTML_INDEX" \
  "M05 hardening (second render)" hrefs
check_letter_sweep "$BOOK_OUT/last.html" "M07-AC4 (second render)" \
  $'A\nB\nC\nD\nE\nG\nI\nK\nR\nZ'

# A record for a chapter the book does not list must not reach the index. The
# planted record is well-formed and names a chapter absent from _quarto.yml,
# so only the chapter-list filter can keep it out.
GHOST="$BOOK_DIR/.quarto/$STORE_DIR/ghost.qmd$STORE_SUFFIX"
cat > "$GHOST" <<JSON
{"version":$STORE_VERSION,"file":"ghost.qmd","href":"ghost.html","marker":false,
 "marks":[{"levels":["Ghost Chapter Term"],"xrefs":[],"anchor":"qi-mark-1"}]}
JSON
# The planted record must be one this filter would otherwise accept, or the
# chapter-list filter is not what kept it out. Asserted, not assumed: no
# record-ignored report may fire on this render.

( cd "$BOOK_DIR" && quarto render last.qmd --to html ) \
  > "$WORK/book-ghost.log" 2>&1 \
  || { tail -30 "$WORK/book-ghost.log" >&2; fail "M05 hardening: the marker chapter failed to re-render"; }
check_warning_count "$WORK/book-ghost.log" "$WARN_STORE_UNREADABLE" 0 \
  "M05 hardening (ghost record)"
check_warning_count "$WORK/book-ghost.log" "$WARN_STORE_STALE" 0 \
  "M05 hardening (ghost record)"
check_html_index_manifest "$BOOK_OUT/last.html" "$BOOK_HTML_INDEX" \
  "M05 hardening (stale chapter ignored)" hrefs
check_letter_sweep "$BOOK_OUT/last.html" "M07-AC4 (stale chapter)" \
  $'A\nB\nC\nD\nE\nG\nI\nK\nR\nZ'
rm -f "$GHOST"

# A record this filter cannot read must cost that chapter's entries and say
# so, never take the render down (IP2).
CORRUPT="$BOOK_DIR/.quarto/$STORE_DIR/one.qmd$STORE_SUFFIX"
cp "$CORRUPT" "$WORK/one-record.json"
printf '{"version":%s,"file":"one.qmd","href":"one.html","marker":false,"marks":[{"levels":"not a list"}]}\n' "$STORE_VERSION" > "$CORRUPT"
( cd "$BOOK_DIR" && quarto render last.qmd --to html ) \
  > "$WORK/book-corrupt.log" 2>&1 \
  || { tail -30 "$WORK/book-corrupt.log" >&2; fail "M05 hardening: a wrongly shaped store record took the render down; IP2 forbids it"; }
check_warning_count "$WORK/book-corrupt.log" "$WARN_STORE_UNREADABLE" 1 \
  "M05 hardening"
cp "$WORK/one-record.json" "$CORRUPT"
pass "M05 hardening: a wrongly shaped store record is reported and skipped, and the render survives"

# A record an OLDER version of the extension left behind is perfectly readable
# and merely stale. It costs the same chapter and takes the same fix, but the
# author is told which of the two it is: sent looking for a corrupt file that
# is not there, they cannot act on the report they were given.
printf '{"version":0,"file":"one.qmd","href":"one.html","marker":false,"marks":[{"levels":["Older Version Term"],"xrefs":[],"anchor":"qi-mark-1"}]}\n' > "$CORRUPT"
( cd "$BOOK_DIR" && quarto render last.qmd --to html ) \
  > "$WORK/book-stale.log" 2>&1 \
  || { tail -30 "$WORK/book-stale.log" >&2; fail "M05 hardening: a record from an older version took the render down; IP2 forbids it"; }
check_warning_count "$WORK/book-stale.log" "$WARN_STORE_STALE" 1 \
  "M06 (stale store record)"
check_warning_count "$WORK/book-stale.log" "$WARN_STORE_UNREADABLE" 0 \
  "M06 (stale store record)"
cp "$WORK/one-record.json" "$CORRUPT"
pass "M06: a record from an older extension version is reported as stale rather than as unreadable, and the render survives"

# M14 (review F9) — a record whose cross-reference lost its levels. Two
# consumers read these now, and the newer of them runs on every last-chapter
# render before any of the marker logic; reaching it with no levels is a hard
# error and a dead render, which IP2 forbids. Validated and skipped instead.
printf '{"version":%s,"file":"one.qmd","href":"one.html","marker":false,"marks":[{"levels":["Beta"],"xrefs":[{"attr":"see"}],"anchor":"qi-mark-1"}]}\n' "$STORE_VERSION" > "$CORRUPT"
( cd "$BOOK_DIR" && quarto render last.qmd --to html ) \
  > "$WORK/book-badxref.log" 2>&1 \
  || { tail -30 "$WORK/book-badxref.log" >&2; fail "M14 (review F9): a record whose cross-reference lost its levels took the render down; IP2 forbids it"; }
check_warning_count "$WORK/book-badxref.log" "$WARN_STORE_UNREADABLE" 1 \
  "M14 (review F9)"
cp "$WORK/one-record.json" "$CORRUPT"
pass "M14: a stored cross-reference with no levels is reported and skipped rather than taking the render down"

# M14 (review F4) — a record written before chapters carried their marks'
# naming strings. `context` is read by one warning and by nothing that reaches
# the index, so such a record is still a good record: rejecting it would cost
# an author that chapter's terms for the sake of wording. It is accepted with
# neither store warning, its term reaches the index, and the report it draws
# names the chapter and says only what it knows about the mark.
printf '{"version":%s,"file":"one.qmd","href":"one.html","marker":false,"marks":[{"levels":["Legacy Term"],"xrefs":[{"attr":"see","levels":["Nothing Indexed Here"]}],"anchor":"qi-mark-1"}]}\n' "$STORE_VERSION" > "$CORRUPT"
( cd "$BOOK_DIR" && quarto render last.qmd --to html ) \
  > "$WORK/book-nocontext.log" 2>&1 \
  || { tail -30 "$WORK/book-nocontext.log" >&2; fail "M14 (review F4): a record with no per-mark naming string took the render down"; }
check_warning_count "$WORK/book-nocontext.log" "$WARN_STORE_UNREADABLE" 0 \
  "M14 (review F4)"
check_warning_count "$WORK/book-nocontext.log" "$WARN_STORE_STALE" 0 \
  "M14 (review F4)"
check_warning_count "$WORK/book-nocontext.log" \
  "$(dangling_report see 'a mark in one.qmd' 'Nothing Indexed Here' book)" 1 \
  "M14 (review F4)"
grep -qF 'Legacy Term' "$BOOK_OUT/last.html" \
  || fail "M14 (review F4): the chapter's term is missing from the index, so the record was rejected after all"
cp "$WORK/one-record.json" "$CORRUPT"
pass "M14: a record predating the per-mark naming string is accepted, keeps its chapter's terms in the index, and its report names the chapter it came from"

# ---------------------------------------------------------------------------
# The ordering fixture: marker in the first chapter, a second marker in the
# last, and a chapter filename with a space in it.
# ---------------------------------------------------------------------------
ORDER_DIR="examples/book-order"
ORDER_OUT="$ORDER_DIR/_book"
# Derived from the fixture, not written down: the per-chapter reports below
# are counted once per chapter, and a hardcoded count silently stops meaning
# "per chapter" the moment the fixture gains one.
ORDER_CHAPTERS=$(ls "$ORDER_DIR"/*.qmd | wc -l | tr -d ' ')
[ "$ORDER_CHAPTERS" -ge 3 ] \
  || fail "M05 hardening: the ordering fixture needs at least 3 chapters; it has $ORDER_CHAPTERS"
rm -rf "$ORDER_OUT" "$ORDER_DIR/.quarto"
# Rendered twice on purpose: on the first pass the later chapter has not run
# when the marker chapter builds the index, which is the very hazard the
# marker-not-last warning is about.
# Logged separately rather than appended to one file: the cross-chapter sort
# conflict below is asserted per render, so which render finds it is checked
# instead of assumed.
( cd "$ORDER_DIR" && quarto render --to html ) \
  > "$WORK/book-order-1.log" 2>&1 \
  || { tail -30 "$WORK/book-order-1.log" >&2; fail "M05 hardening: the ordering fixture failed to render"; }
( cd "$ORDER_DIR" && quarto render --to html ) \
  > "$WORK/book-order-2.log" 2>&1 \
  || { tail -30 "$WORK/book-order-2.log" >&2; fail "M05 hardening: the ordering fixture failed to render (second pass)"; }
cat "$WORK/book-order-1.log" "$WORK/book-order-2.log" > "$WORK/book-order.log"

check_warning_count "$WORK/book-order.log" "$WARN_MARKER_NOT_LAST" 2 \
  "M05 hardening"
check_warning_count "$WORK/book-order.log" "$WARN_MARKER_SECOND" 2 \
  "M05 hardening"
pass "M05 hardening: a marker that is not last, and a second marker chapter, are each reported once per render"

# M06-AC4 (c), the half a single document cannot probe: each chapter renders in
# its own process, so a term sorted one way in one chapter and another way in
# a second is invisible to the in-document collect pass.
#
# Which render finds it is asserted, not assumed. On the first pass the marker
# chapter builds the index before the later chapter has run, so the store holds
# no record of it and there is nothing to compare; only the second pass has
# both chapters' keys. A single combined count would pass just as happily if
# the report fired on the first pass and not the second, which would mean the
# conflict was being found somewhere it cannot yet be known.
check_warning_count "$WORK/book-order-1.log" "$WARN_BOOK_SORT_CONFLICT" 0 \
  "M06-AC4 (book, first render)"
check_warning_count "$WORK/book-order-2.log" "$WARN_BOOK_SORT_CONFLICT" 1 \
  "M06-AC4 (book, second render)"
# The later chapter marks the contested term twice, which the three-locator row
# of manifest 8 reads. It does NOT discriminate per-path from per-mark
# reporting on this leg: a chapter's record carries one declared key per
# printed level path however many marks write it, so per-mark reporting is not
# expressible here. That discrimination lives on the single-document leg,
# where examples/sortkey-misuse.qmd carries a third mark repeating the rival
# key and the exact count above it would fail under a per-mark rule.
pass "M06-AC4: one entry sorted two ways in two chapters is reported once on the render that can see both, and the first chapter in book order wins"

# M07-AC1: this render's index is checked entry-by-entry below, so its
# headings are asserted by the hand-derived sweep instead. `Contested` files
# under the sort key the FIRST chapter in book order gives it, `Aaa`, not the
# `Zzz` two later chapters write and not its own printed text — so its group
# is A. `Early`, `Early Reference`, `Late` and `Missing Reference` file under
# their printed text, which puts M14's two cross-reference-only entries in the
# E and M groups.
# Where the book's range report is DRAWN, and what it is entitled to NAME
# (R4-F1). This fixture builds its index in its FIRST chapter, so the chapter
# that reads every record is not the chapter that places the index — a report
# drawn by the marker chapter fails here rather than passing on a fixture where
# the two coincide. One report per render — BOTH renders, since a report drawn
# only when the store is freshly written would vanish on the settled second
# pass (R4-F7) — naming exactly the pair split across two chapters: `Bridged`,
# opened in the second chapter and closed in the third. `Unclosed` is a
# one-chapter fault (nothing closes it anywhere) and `Spanned`'s closing has no
# visible counterpart (its opening was displaced by a cross-reference and named
# no range end), so the book names neither — its old message called both
# chapter-crossing, which was the wrong cause.
for log in "$WORK/book-order-1.log" "$WORK/book-order-2.log"; do
  check_warning_count "$log" "$R_BOOKUNPAIRED" 1 \
    "M21-AC5 (drawn once per render by the chapter that has seen every record)"
  for mark in 'term "Bridged" in later chapter.qmd' 'term "Bridged" in third.qmd'; do
    check_warning_count "$log" "$mark" 1 \
      "M21-AC5 (naming both marks of the pair split across chapters)"
  done
  for mark in 'term "Unclosed" in third.qmd' 'term "Spanned" in third.qmd'; do
    check_warning_count "$log" "$mark" 0 \
      "M21-AC5 (and no mark without a counterpart in another chapter)"
  done
done
# A chapter is the pairing scope (D-009), so each chapter draws its own
# kind-specific pairing reports, worded over the chapter: `Bridged`'s opening
# and `Unclosed` are never closed in THEIR chapters, `Spanned`'s and
# `Bridged`'s closings never opened in theirs, and `Twice Opened`'s second
# opening — AC4's third shape, in a book — is refused exactly as in a single
# document, the first opening being the one the closing pairs with (the
# manifest's one-range-plus-one-locator row). The displaced opening still
# draws the displacement report, which is mark-local, not a pairing verdict.
check_warning_count "$WORK/book-order-1.log" 'is never closed in this chapter' 2 \
  "M21-AC5 (each chapter reports its own never-closed opening, over the chapter)"
check_warning_count "$WORK/book-order-1.log" 'closes a range this chapter never opens' 2 \
  "M21-AC5 (each chapter reports its own never-opened closing, over the chapter)"
check_warning_count "$WORK/book-order-1.log" "$R_ALREADY" 1 \
  "M21-AC5 (a second opening inside one chapter is refused there, as AC4 promises)"
check_warning_count "$WORK/book-order-1.log" "$R_DISPLACED" 1 \
  "M21-AC5 (the displaced opening draws its own report instead, once)"

check_letter_sweep "$ORDER_OUT/index.html" "M07-AC1 (book order)" $'A\nB\nE\nL\nM\nS\nT\nU'

printf '%s\n' "$BOOK_ORDER_INDEX" > "$WORK/order-index.txt"
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - "$ORDER_OUT" \
  "$WORK/order-index.txt" <<'PY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
out, manifest = sys.argv[1], sys.argv[2]
section_id = os.environ['HTML_SECTION_ID']
INDEX_PAGE = 'index.html'

pages = H.html_files(out)
docs = {page: H.parse(os.path.join(out, page)) for page in pages}
carrying = [p for p in pages if H.count_id(docs[p], section_id) > 0]
if carrying != [INDEX_PAGE]:
    print(f'FAIL: M05 hardening: two marker chapters produced index sections '
          f'on {carrying}, expected only [{INDEX_PAGE!r}]', file=sys.stderr)
    sys.exit(1)
actual = [H.row(r, hrefs=True)
          for r in H.entry_records(H.find_id(docs[INDEX_PAGE], section_id))]
expected = H.read_manifest(manifest)
if actual != expected:
    print('FAIL: M05 hardening: the ordering fixture index does not match the '
          'manifest', file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        got = actual[i] if i < len(actual) else '<no such row rendered>'
        want = expected[i] if i < len(expected) else '<not in the manifest>'
        if got != want:
            print(f'  row {i + 1}:\n    expected <<{want}>>\n'
                  f'    got      <<{got}>>', file=sys.stderr)
    sys.exit(1)
# The space-named chapter is the point of this fixture: its locator must
# resolve like any other, and it is written the way Quarto writes its own
# links to that page rather than percent-escaped.
ids = {page: set(H.all_ids(doc)) for page, doc in docs.items()}
spaced = [href for r in H.entry_records(H.find_id(docs[INDEX_PAGE], section_id))
          for href in r['locators'] if ' ' in href]
if not spaced:
    print('FAIL: M05 hardening: no locator reaches the space-named chapter, '
          'so the fixture no longer exercises it', file=sys.stderr)
    sys.exit(1)
for href in spaced:
    target, fragment = H.resolve_href(INDEX_PAGE, href)
    if target not in ids or fragment not in ids[target]:
        print(f'FAIL: M05 hardening: the locator {href!r} into the '
              f'space-named chapter resolves to nothing', file=sys.stderr)
        sys.exit(1)
print(f'ok   M05 hardening: one index across {len(pages)} pages with two '
      f'marker chapters, {len(expected)} rows including a later chapter '
      f'carried by its stored record, and the space-named chapter\'s locator '
      f'resolves')
PY

# A store the filter cannot write at all: an ordinary file where its directory
# belongs. The render must survive and say what was lost (IP2).
rm -rf "$ORDER_DIR/.quarto/$STORE_DIR"
mkdir -p "$ORDER_DIR/.quarto"
printf 'not a directory\n' > "$ORDER_DIR/.quarto/$STORE_DIR"
( cd "$ORDER_DIR" && quarto render --to html ) > "$WORK/book-nostore.log" 2>&1 \
  || { tail -30 "$WORK/book-nostore.log" >&2; fail "M05 hardening: a store that cannot be written took the render down; IP2 forbids it"; }

check_warning_count "$WORK/book-nostore.log" "$WARN_STORE_UNWRITABLE" \
  "$ORDER_CHAPTERS" "M05 hardening"
rm -f "$ORDER_DIR/.quarto/$STORE_DIR"
pass "M05 hardening: a store that cannot be written is reported per chapter and the book still renders"

# ---------------------------------------------------------------------------
# M06-AC1 — sort keys, end to end in the PDF.
#
# The manifest is checked against the fixture BY CONSTRUCTION first: every
# `sort="..."` value the fixture carries must be a manifest row and every
# manifest row must be in the fixture. Without that, a sort key added to the
# fixture later would simply go unprobed while this section still passed.
#
# The printed order is then read with tests/pdfindex.py rather than out of
# pdftotext's text output: a two-column index interleaves the columns there,
# so that output's order is not the index's — see that module's header.
# ---------------------------------------------------------------------------
printf '%s\n' "$SORTKEY_KEYS" > "$WORK/sortkeys.txt"
python3 - examples/sortkey.qmd "$WORK/sortkeys.txt" <<'SORTKEYPY'
import re, sys
source = open(sys.argv[1], encoding='utf-8').read()
declared = sorted(re.findall(r'\bsort="([^"]*)"', source))
listed = sorted(l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8')
                if l.strip())
if declared != listed:
    print('FAIL: M06-AC1: the sort-key manifest and the fixture disagree.',
          file=sys.stderr)
    print(f'  only in the fixture:  {sorted(set(declared) - set(listed))}',
          file=sys.stderr)
    print(f'  only in the manifest: {sorted(set(listed) - set(declared))}',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC1: the manifest names every one of the {len(declared)} '
      f'sort keys examples/sortkey.qmd declares, and no others')
SORTKEYPY

# The twin is the fixture with every sort= attribute deleted and NOTHING else
# changed, so a difference between the two indexes is caused by the sort keys
# alone. Asserted rather than assumed: a twin edited by hand could drift into
# a fixture that differs for some other reason.
python3 - examples/sortkey.qmd examples/sortkey-twin.qmd <<'TWINPY'
import re, sys
source = open(sys.argv[1], encoding='utf-8').read()
twin = open(sys.argv[2], encoding='utf-8').read()
# Escape-aware: a sort key can BE a double quote, written `\"`, and a naive
# ` sort="[^"]*"` stops at it and leaves a stray `"}` behind.
if re.sub(r' sort="(?:[^"\\]|\\.)*"', '', source) != twin:
    print('FAIL: M06-AC1/AC2: examples/sortkey-twin.qmd is not '
          'examples/sortkey.qmd with its sort= attributes removed',
          file=sys.stderr)
    sys.exit(1)
if re.search(r'\bsort="', twin):
    print('FAIL: M06-AC1/AC2: the twin still carries a sort= attribute',
          file=sys.stderr)
    sys.exit(1)
print('ok   M06-AC1/AC2: the twin fixture is the sort-key fixture with every '
      'sort= attribute deleted, and nothing else')
TWINPY

quarto render examples/sortkey.qmd --to pdf > "$WORK/sortkey-pdf.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-pdf.log" >&2; fail "M06-AC1: sortkey.qmd failed to render to PDF"; }
[ -s examples/sortkey.pdf ] || fail "M06-AC1: examples/sortkey.pdf is empty"
# A sort key must not cost the author a warning: every mark in this fixture is
# well formed, so a clean render is part of the criterion.
if grep -q '^(W)' "$WORK/sortkey-pdf.log"; then
  grep '^(W)' "$WORK/sortkey-pdf.log" >&2
  fail "M06-AC1: examples/sortkey.qmd warned; every mark in it is well formed"
fi

printf '%s\n' "$SORTKEY_PDF_OUTLINE" > "$WORK/sortkey-outline.txt"
python3 - examples/sortkey.pdf "$WORK/sortkey-outline.txt" <<'OUTLINEPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

entries = pdfindex.read(sys.argv[1])
if not pdfindex.columns_carry_top_level(entries):
    print('FAIL: M06-AC1: a column of the printed index carries no top-level '
          'entry, so pdfindex cannot read its indent levels', file=sys.stderr)
    sys.exit(1)
actual = pdfindex.outline(entries)
expected = []
for line in open(sys.argv[2], encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip():
        level, term = line.split('\t', 1)
        expected.append((int(level), term))
if actual != expected:
    print('FAIL: M06-AC1: the printed index is not in the order the manifest '
          'derives.', file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        a = actual[i] if i < len(actual) else None
        e = expected[i] if i < len(expected) else None
        print(f'{"  " if a == e else "->"} {i}: got {a!r} want {e!r}',
              file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC1: the compiled PDF prints all {len(expected)} index '
      f'entries in the order and nesting their sort keys derive')
OUTLINEPY

# The twin proves the ordering above is the sort keys' doing and not something
# the fixture would have done anyway: the same terms, no sort keys, and an
# order that must differ at every top-level position.
quarto render examples/sortkey-twin.qmd --to pdf > "$WORK/sortkey-twin-pdf.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-twin-pdf.log" >&2; fail "M06-AC1: sortkey-twin.qmd failed to render to PDF"; }
python3 - examples/sortkey.pdf examples/sortkey-twin.pdf <<'DIFFPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

keyed = [t for lv, t in pdfindex.outline(pdfindex.read(sys.argv[1]))
         if lv == 0]
twin = [t for lv, t in pdfindex.outline(pdfindex.read(sys.argv[2]))
        if lv == 0]
if sorted(keyed) != sorted(twin):
    print('FAIL: M06-AC1: the twin indexes a different set of terms, so the '
          'two orders are not comparable', file=sys.stderr)
    print(f'  keyed: {keyed}\n  twin:  {twin}', file=sys.stderr)
    sys.exit(1)
same = [i for i, (a, b) in enumerate(zip(keyed, twin)) if a == b]
if same:
    print(f'FAIL: M06-AC1: sort keys left top-level position(s) {same} '
          'unchanged, so this fixture cannot tell a sorted index from an '
          'unsorted one', file=sys.stderr)
    print(f'  keyed: {keyed}\n  twin:  {twin}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC1: removing the sort keys moves every one of the '
      f'{len(keyed)} top-level entries, so the printed order is theirs')
DIFFPY

# ---------------------------------------------------------------------------
# M06-AC2 — sort keys in the HTML index, at every depth.
#
# The twin renders alongside, so the ordering below is attributed to the sort
# keys rather than to anything the fixture would have done anyway. Both
# manifests are exhaustive and compared in order, which is what makes a
# collation failure a failure rather than something set equality swallows.
# ---------------------------------------------------------------------------
quarto render examples/sortkey.qmd --to html > "$WORK/sortkey-html.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-html.log" >&2; fail "M06-AC2: sortkey.qmd failed to render to HTML"; }
if grep -q '^(W)' "$WORK/sortkey-html.log"; then
  grep '^(W)' "$WORK/sortkey-html.log" >&2
  fail "M06-AC2: examples/sortkey.qmd warned in HTML; every mark in it is well formed"
fi
check_html_index_manifest examples/sortkey.html "$SORTKEY_HTML_INDEX" "M06-AC2"
check_letter_sweep examples/sortkey.html "M07-AC3 (sort keys)" \
  $'A\nH\nL\nM\nN\nT'
check_html_index_links examples/sortkey.html "M06-AC2"

quarto render examples/sortkey-twin.qmd --to html > "$WORK/sortkey-twin-html.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-twin-html.log" >&2; fail "M06-AC2: sortkey-twin.qmd failed to render to HTML"; }
check_html_index_manifest examples/sortkey-twin.html "$SORTKEY_TWIN_HTML_INDEX" "M06-AC2 (twin)"
check_letter_sweep examples/sortkey-twin.html "M07-AC3 (sort-key twin)" \
  $'Symbols\nM\nT\nU\nV'

# The two manifests must disagree at every top-level position and at every
# sub-entry position, or one of them could be satisfied by an index that
# ignored the sort keys. Asserted of the manifests themselves, so the claim
# holds even if both renders were to fail in the same direction.
printf '%s\n' "$SORTKEY_HTML_INDEX" > "$WORK/sk-html.txt"
printf '%s\n' "$SORTKEY_TWIN_HTML_INDEX" > "$WORK/sk-twin-html.txt"
python3 - "$WORK/sk-html.txt" "$WORK/sk-twin-html.txt" <<'ORDERPY'
import sys


def by_depth(path):
    out = {}
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if line.strip():
            fields = line.split('\t')
            # A letter-group heading is not an entry and has no depth; the
            # question here is where the ENTRIES sit.
            if fields[0] == 'letter':
                continue
            out.setdefault(int(fields[0]), []).append(fields[1])
    return out


keyed, twin = by_depth(sys.argv[1]), by_depth(sys.argv[2])
if set(keyed) != set(twin):
    print('FAIL: M06-AC2: the two manifests do not nest to the same depths',
          file=sys.stderr)
    sys.exit(1)
moved = 0
for depth in sorted(keyed):
    a, b = keyed[depth], twin[depth]
    if sorted(a) != sorted(b):
        print(f'FAIL: M06-AC2: depth {depth} lists different terms in the two '
              f'manifests, so their orders are not comparable', file=sys.stderr)
        print(f'  keyed: {a}\n  twin:  {b}', file=sys.stderr)
        sys.exit(1)
    same = [i for i, (x, y) in enumerate(zip(a, b)) if x == y]
    if same:
        print(f'FAIL: M06-AC2: at depth {depth} the sort keys leave '
              f'position(s) {same} unchanged, so the manifest could be '
              f'satisfied by an index that ignored them', file=sys.stderr)
        print(f'  keyed: {a}\n  twin:  {b}', file=sys.stderr)
        sys.exit(1)
    moved += len(a)
print(f'ok   M06-AC2: the sort keys move all {moved} entries, at every one of '
      f'the {len(keyed)} depths the index nests to')
ORDERPY

# The README claims sort keys of plain letters and digits order the same way
# in both back-ends. examples/sortkey.qmd is keyed entirely in plain letters
# and spaces, so its two manifests — the PDF outline (1n) and the HTML index
# (1o) — must agree row for row on term and depth. Asserted of the manifests,
# which are independently hand-derived from the fixture under two different
# collation rules; agreeing by construction is the claim.
printf '%s\n' "$SORTKEY_PDF_OUTLINE" > "$WORK/sk-pdf-outline.txt"
python3 - "$WORK/sk-pdf-outline.txt" "$WORK/sk-html.txt" <<'AGREEPY'
import sys


def rows(path, keep):
    out = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if line.strip():
            fields = line.split('\t')
            # Heading rows are dropped: only the HTML manifest has them, and
            # the claim compared here is about entry order in both back-ends.
            if fields[0] == 'letter':
                continue
            out.append(tuple(fields[:keep]))
    return out


pdf, html = rows(sys.argv[1], 2), rows(sys.argv[2], 2)
if not pdf:
    print('FAIL: M06-AC1/AC2: the PDF outline manifest is empty',
          file=sys.stderr)
    sys.exit(1)
if pdf != html:
    print('FAIL: M06-AC1/AC2: the two back-ends are documented to order plain '
          'letter and digit keys alike, but the manifests disagree:',
          file=sys.stderr)
    for i in range(max(len(pdf), len(html))):
        a = pdf[i] if i < len(pdf) else '<no such row>'
        b = html[i] if i < len(html) else '<no such row>'
        if a != b:
            print(f'  row {i + 1}: pdf {a}  html {b}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC1/AC2: all {len(pdf)} rows of the PDF index and the HTML '
      f'index agree on term and depth, so the plain-key ordering the README '
      f'documents holds in both back-ends')
AGREEPY

# ---------------------------------------------------------------------------
# M06-AC1/AC2 — a sort key belongs to a LEVEL, under its own parents, not to
# the whole entry that declared it.
#
# Both back-ends order level by level: the index tool reads `sortkey@printed`
# inside each level of an entry, and the HTML tree keys each node on its own
# printed text. A key remembered against the whole entry therefore files one
# printed term under two different keys depending on whether a sub-entry
# happened to follow it — in LaTeX the term is printed twice, in two places,
# identically, with nothing in the log to say so.
#
# Both legs are checked, because the two fail differently: LaTeX splits the
# entry, while HTML keeps one node and silently drops one of the two keys.
# ---------------------------------------------------------------------------
quarto render examples/sortkey-paths.qmd --to latex \
  > "$WORK/sortkey-paths-latex.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-paths-latex.log" >&2; fail "M06-AC1: sortkey-paths.qmd failed to render to LaTeX"; }
if grep -q '^(W)' "$WORK/sortkey-paths-latex.log"; then
  grep '^(W)' "$WORK/sortkey-paths-latex.log" >&2
  fail "M06-AC1: examples/sortkey-paths.qmd warned; every mark in it is well formed"
fi
printf '%s\n' "$SORTKEY_PATHS_ENTRIES" > "$WORK/sk-paths-entries.txt"
python3 - examples/sortkey-paths.qmd examples/sortkey-paths.tex \
  "$WORK/sk-paths-entries.txt" <<'PATHSPY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
tex = open(sys.argv[2], encoding='utf-8').read()
expected = [l for l in open(sys.argv[3], encoding='utf-8').read().split('\n')
            if l.strip()]

# By construction, not by hand: the manifest must account for every mark the
# fixture writes. A row quietly dropped from it would otherwise turn a split
# entry into a passing check.
marks = src.count('{.index')
if marks != len(expected):
    print(f'FAIL: M06-AC1: the fixture writes {marks} index marks but the '
          f'manifest names {len(expected)} entries', file=sys.stderr)
    sys.exit(1)

actual = re.findall(r'\\index\{(.*?)\}', tex)
if actual != expected:
    print('FAIL: M06-AC1: the emitted index entries do not match the manifest',
          file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        got = actual[i] if i < len(actual) else '<no such entry emitted>'
        want = expected[i] if i < len(expected) else '<not in the manifest>'
        if got != want:
            print(f'  entry {i + 1}:\n    expected <<{want}>>\n'
                  f'    got      <<{got}>>', file=sys.stderr)
    sys.exit(1)

# The property the manifest exists to pin, asserted of the manifest itself so
# it cannot be satisfied by a manifest that stopped testing it: each printed
# top-level term must carry ONE sort field across every entry that starts with
# it, however deep that entry goes.
#
# Both splits honor makeindex's quote, which covers the character after it: a
# naive split on `!` cuts `"!Zed@Literal` at the author's literal `!` and
# files that row under junk, exempting it from the property below.
def first_level(arg):
    i = 0
    while i < len(arg):
        if arg[i] == '"':
            i += 2
            continue
        if arg[i] == '!':
            return arg[:i]
        i += 1
    return arg


def sort_field(level):
    i = 0
    while i < len(level):
        if level[i] == '"':
            i += 2
            continue
        if level[i] == '@':
            return level[:i]
        i += 1
    return None            # files under its own printed text


keys = {}
for entry in expected:
    level = first_level(entry)
    key = sort_field(level)
    printed = level if key is None else level[len(key) + 1:]
    keys.setdefault(printed, set()).add(key)
split = {p: sorted('<own text>' if k is None else k for k in ks)
         for p, ks in keys.items() if len(ks) > 1}
if split:
    print(f'FAIL: M06-AC1: manifest files one printed term under two keys, '
          f'which is the split it exists to rule out: {split}',
          file=sys.stderr)
    sys.exit(1)
if len(keys) < 2:
    print(f'FAIL: M06-AC1: only {len(keys)} top-level term(s) parsed out of '
          f'the manifest; the split property is not being tested',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC1: all {len(expected)} entries emitted as the manifest '
      f'derives them, each of the {len(keys)} top-level terms under one key '
      f'whether or not a sub-entry follows it')
PATHSPY

quarto render examples/sortkey-paths.qmd --to html \
  > "$WORK/sortkey-paths-html.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-paths-html.log" >&2; fail "M06-AC2: sortkey-paths.qmd failed to render to HTML"; }
check_html_index_manifest examples/sortkey-paths.html \
  "$SORTKEY_PATHS_HTML_INDEX" "M06-AC2 (level paths)"
check_letter_sweep examples/sortkey-paths.html "M07-AC3 (level paths)" \
  $'Symbols\nB\nH\nQ\nW\nZ'
check_html_index_links examples/sortkey-paths.html "M06-AC2 (level paths)"

# ---------------------------------------------------------------------------
# M06-AC4 — the three sort-key reports.
#
# Rendered to gfm as well as to LaTeX because all three are reports about the
# MARK rather than about a back-end's limits: an author drafting to a format
# that builds no index at all still gets them. The counts are exact, so a
# report that started firing twice fails here as loudly as one that stopped.
# ---------------------------------------------------------------------------
for fmt in latex gfm; do
  quarto render examples/sortkey-misuse.qmd --to "$fmt" \
    > "$WORK/sortkey-misuse-$fmt.log" 2>&1 \
    || { tail -40 "$WORK/sortkey-misuse-$fmt.log" >&2; fail "M06-AC4: sortkey-misuse.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/sortkey-misuse-$fmt.log" "$WARN_SORT_ORPHAN" 1 \
    "M06-AC4 ($fmt)"
  check_warning_count "$WORK/sortkey-misuse-$fmt.log" "$WARN_SORT_EXTRA" 1 \
    "M06-AC4 ($fmt)"
  # THREE: two from the four marks sharing the printed level `Ambivalence`
  # (keys Aaa, Bbb, Bbb, Ccc) and one from `Steady`, whose first key names the
  # level's own text and so is a declaration a later key rivals. The count
  # discriminates all three candidate rules — once per mark would give 4,
  # once per level path 2, and once per rival key at a path 3, which is the
  # rule: repeating a rival gives the author nothing further to fix, while a
  # second, different rival is a second thing to fix and would otherwise stay
  # unmentioned until the first was resolved.
  check_warning_count "$WORK/sortkey-misuse-$fmt.log" "$WARN_SORT_CONFLICT" 3 \
    "M06-AC4 ($fmt)"
  pass "M06-AC4: the three sort-key reports fire in $fmt, the conflict once per rival key rather than once per mark or once per entry"
done

# The two folded-entry marks in the same fixture. A sort key is aligned with
# the entry level it was written for, so the guard that decides whether a
# level needs a sort field at all has to compare against THAT level and not
# against the folded text the back-end prints — otherwise every folded entry
# comes out carrying a sort field naming its own third level, which is what
# no sort field already means.
python3 - examples/sortkey-misuse.tex <<'FOLDPY'
import re, sys
tex = open(sys.argv[1], encoding='utf-8').read()
args = re.findall(r'\\index\{(.*?)\}', tex)
want = ['Alpha@one!two!three, four', 'aa!bb!Ckey@cc, dd',
        # `Steady` declares its own printed text and is first, so it wins the
        # tie and files under that text — which needs no sort field at all.
        # `Rrr` reaching the emission would mean the later key had won.
        'Steady']
for expected in want:
    if expected not in args:
        print(f'FAIL: M06: the folded entry was not emitted as expected\n'
              f'  expected <<{expected}>>\n  got      {args}', file=sys.stderr)
        sys.exit(1)
redundant = [a for a in args
             if 'three@three, four' in a or 'cc@cc, dd' in a
             or 'Rrr' in a]
if redundant:
    print(f'FAIL: M06: a level carries a sort field it should not — a folded '
          f'level naming its own third level, or a rival key that lost: '
          f'{redundant}', file=sys.stderr)
    sys.exit(1)
print('ok   M06: a folded entry carries a sort field only where a key was '
      'written for the level it was aligned with')
FOLDPY

# The control: a fixture whose sort keys are all well formed must draw none of
# the three. Without this the counts above would be satisfied by a report that
# fires on every document.
python3 - "$WORK/sortkey-pdf.log" "$WORK/sortkey-html.log" <<'CONTROLPY'
import sys
patterns = {
    'nothing to sort': 'has nothing to sort',
    'extra sort levels': 'the extra sort levels were ignored',
    'two sort keys': 'cannot apply as well',
}
bad = []
for path in sys.argv[1:]:
    text = open(path, encoding='utf-8', errors='replace').read()
    for name, needle in patterns.items():
        if needle in text:
            bad.append(f'  {path}: {name}')
if bad:
    print('FAIL: M06-AC4: a well-formed fixture drew a sort-key report:',
          file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC4: none of the {len(patterns)} sort-key reports fires on '
      f'examples/sortkey.qmd, whose sort keys are all well formed')
CONTROLPY

# ---------------------------------------------------------------------------
# M06-AC5 — the book's sort key is written in a chapter other than the one
# holding the marker. Asserted by construction against the fixture rather than
# stated in a comment: if the key were ever moved into the marker chapter, the
# aggregated-index manifest would still pass while proving nothing about
# carrying a sort key ACROSS chapters, which is the criterion.
# ---------------------------------------------------------------------------
python3 - examples/book <<'BOOKSORTPY'
import os, re, sys
root = sys.argv[1]
declaring, marker_chapters = [], []
for dirpath, _dirs, files in os.walk(root):
    if '_book' in dirpath or '_extensions' in dirpath or '.quarto' in dirpath:
        continue
    for name in sorted(files):
        if not name.endswith('.qmd'):
            continue
        path = os.path.join(dirpath, name)
        text = open(path, encoding='utf-8').read()
        rel = os.path.relpath(path, root)
        if re.search(r'\bsort="', text):
            declaring.append(rel)
        if 'qi-index-here' in text:
            marker_chapters.append(rel)
if not declaring:
    print('FAIL: M06-AC5: no chapter of the book fixture declares a sort key',
          file=sys.stderr)
    sys.exit(1)
if not marker_chapters:
    print('FAIL: M06-AC5: the book fixture has no marker chapter',
          file=sys.stderr)
    sys.exit(1)
overlap = sorted(set(declaring) & set(marker_chapters))
if overlap:
    print(f'FAIL: M06-AC5: sort key(s) declared in the marker chapter '
          f'{overlap}; the criterion is about carrying one across chapters',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC5: the book\'s sort key(s) are declared in {declaring} and '
      f'the marker is in {marker_chapters}, so the aggregated order above '
      f'crossed a chapter boundary')
BOOKSORTPY

# ---------------------------------------------------------------------------
# M06-AC3 — every printable ASCII character as a sort key, in three formats.
#
# A sort key travels the same channel an entry key does, so the same characters
# need the same mechanisms — plus one that matters only here: `@` is what the
# LaTeX back-end writes BETWEEN a sort key and the text it files, so an `@` the
# author wrote must still reach the index tool quoted. The domain is derived by
# construction from the same range the entry-key probe uses, so a character the
# filter handles can never go unprobed.
# ---------------------------------------------------------------------------
python3 - examples/sort-escaping.qmd <<'SORTESCPY'
import re, sys
qmd = open(sys.argv[1], encoding='utf-8').read()
unescape = lambda t: re.sub(r'\\(.)', r'\1', t)
keys = {unescape(m) for m in re.findall(r'sort="((?:\\.|[^"\\])*)"', qmd)}
domain = [chr(c) for c in range(0x21, 0x7F)]
missing = [f'  {c!r} is not its own sort= value' for c in domain
           if ('!!' if c == '!' else c) not in keys]
if missing:
    print('FAIL: M06-AC3: sort-escaping.qmd does not cover printable ASCII:',
          file=sys.stderr)
    print('\n'.join(missing[:20]), file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC3: sort-key probe covers all {len(domain)} printable ASCII '
      f'characters (space excluded) as sort keys')
SORTESCPY

# Leg 1 — LaTeX: the index tool must ACCEPT every entry. This is where a
# missing quote on an author's `@` or `!` shows up, because makeindex would
# read it as its own operator and reject or mis-file the entry.
mkdir -p "$WORK/sortesc"
# The .tex first: `--to pdf` does not leave one behind, and the makeindex leg
# below needs the argument text the filter actually emitted.
quarto render examples/sort-escaping.qmd --to latex > "$WORK/sortesc-latex.log" 2>&1 \
  || { tail -20 "$WORK/sortesc-latex.log" >&2; fail "M06-AC3: sort-escaping.qmd failed to render to LaTeX"; }
cp examples/sort-escaping.tex "$WORK/sortesc/"
quarto render examples/sort-escaping.qmd --to pdf > "$WORK/sortesc-pdf.log" 2>&1 \
  || { tail -20 "$WORK/sortesc-pdf.log" >&2; fail "M06-AC3: the sort-key escaping probe failed to compile through Quarto's own PDF engine"; }
( cd "$WORK/sortesc" && pdflatex -interaction=nonstopmode sort-escaping.tex ) \
  > "$WORK/sortesc-tex.log" 2>&1 \
  || { grep -E '^! ' "$WORK/sortesc-tex.log" | head -5 >&2; fail "M06-AC3: the sort-key escaping probe failed to compile"; }
( cd "$WORK/sortesc" && makeindex sort-escaping.idx ) > "$WORK/sortesc-mkidx.log" 2>&1 \
  || fail "M06-AC3: makeindex failed on the sort-key escaping probe"
SORTESC_MARKS=$(( 0x7F - 0x21 ))
grep -qE "\($SORTESC_MARKS entries accepted, 0 rejected\)" \
  "$WORK/sortesc/sort-escaping.ilg" \
  || { grep -E 'accepted|rejected' "$WORK/sortesc/sort-escaping.ilg" >&2; fail "M06-AC3: makeindex did not accept all $SORTESC_MARKS sort-key entries"; }
pass "M06-AC3: every printable ASCII character survives as a sort key through the index tool, all $SORTESC_MARKS entries accepted"

# The acceptance count alone cannot tell correct escaping from NO SORT FIELD:
# a filter that emitted a bare `\index{term-21}` for every mark would be
# accepted just as happily. Two structural checks close that, both derived by
# construction from the fixture's own term list.
#
#   1. In the .tex, every entry has the shape `key@term-XX`, split at the one
#      `@` the back-end writes itself — so an author `@` left unquoted, which
#      would move the split, fails here as loudly as a missing sort field.
#   2. In the .ind the index tool wrote, the printed entry is `term-XX` and
#      nothing else, which is what proves the tool read that `@` as the
#      separator rather than as part of the text.
python3 - examples/sort-escaping.qmd "$WORK/sortesc/sort-escaping.tex" \
  "$WORK/sortesc/sort-escaping.ind" <<'SORTFIELDPY'
import re, sys
qmd = open(sys.argv[1], encoding='utf-8').read()
tex = open(sys.argv[2], encoding='utf-8').read()
ind = open(sys.argv[3], encoding='utf-8').read()
terms = re.findall(r'\[(term-[0-9a-f]{2})\]\{\.index', qmd)
if not terms:
    print('FAIL: M06-AC3: no probe marks found in the fixture', file=sys.stderr)
    sys.exit(1)


def arguments(text):
    # Every `\index{...}` argument, brace-balanced. A plain regex cannot do
    # this: half the escaped forms the probe produces are LaTeX commands with
    # braces of their own (`\textbraceleft{}`), and a non-greedy match ends at
    # the first one of those.
    out = []
    for m in re.finditer(r'\\index\{', text):
        i, depth = m.end(), 1
        while i < len(text) and depth:
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
            i += 1
        out.append(text[m.end():i - 1])
    return out


def split_at_separator(arg):
    # The argument split at the ONE `@` the back-end writes unquoted; every
    # `@` the author wrote is quoted, and makeindex's quote covers exactly the
    # character after it.
    i = 0
    while i < len(arg):
        if arg[i] == '"':
            i += 2
            continue
        if arg[i] == '@':
            return arg[:i], arg[i + 1:]
        i += 1
    return None, arg


args = arguments(tex)
if len(args) != len(terms):
    print(f'FAIL: M06-AC3: the fixture writes {len(terms)} marks but the .tex '
          f'carries {len(args)} index entries', file=sys.stderr)
    sys.exit(1)
bad = []
for term, arg in zip(terms, args):
    key, printed = split_at_separator(arg)
    if key is None:
        bad.append(f'  {term}: no sort field emitted at all  <<{arg}>>')
    elif key == '':
        bad.append(f'  {term}: empty sort field  <<{arg}>>')
    elif printed != term:
        bad.append(f'  {term}: the separator fell in the wrong place; the '
                   f'printed text reads <<{printed}>>')
if bad:
    print('FAIL: M06-AC3: the emitted sort fields are not what the fixture '
          'declares:', file=sys.stderr)
    print('\n'.join(bad[:10]), file=sys.stderr)
    sys.exit(1)

printed = re.findall(r'\\item (term-[0-9a-f]{2})', ind)
if sorted(printed) != sorted(terms):
    missing = sorted(set(terms) - set(printed))
    print(f'FAIL: M06-AC3: the index tool printed {len(printed)} of '
          f'{len(terms)} probe terms as their text alone; missing '
          f'{missing[:10]}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC3: all {len(terms)} entries carry a sort field split at '
      f'the separator the back-end writes, and the index tool printed every '
      f'one of them as its text alone')
SORTFIELDPY

# Leg 2 — HTML: the same characters reach the generated section as entries.
quarto render examples/sort-escaping.qmd --to html > "$WORK/sortesc-html.log" 2>&1 \
  || { tail -20 "$WORK/sortesc-html.log" >&2; fail "M06-AC3: sort-escaping.qmd failed to render to HTML"; }
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/sort-escaping.html \
  examples/sort-escaping.qmd <<'SORTESCHTMLPY'
import os, re, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
qmd = open(sys.argv[2], encoding='utf-8').read()
want = re.findall(r'\[(term-[0-9a-f]{2})\]\{\.index', qmd)
rows = H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))
got = {r['term'] for r in rows}
missing = [t for t in want if t not in got]
if missing:
    print(f'FAIL: M06-AC3: {len(missing)} probe entr(ies) absent from the '
          f'HTML index: {missing[:10]}', file=sys.stderr)
    sys.exit(1)
if len(rows) != len(want):
    print(f'FAIL: M06-AC3: the HTML index has {len(rows)} entries for '
          f'{len(want)} marks', file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC3: all {len(want)} sort-keyed entries reach the HTML index, '
      f'and it carries no others')
SORTESCHTMLPY

# The same 27 groups, reached the other way: every entry here prints as
# `term-XX` and would file under T on its printed text alone, so the groups
# below are the SORT KEYS' doing — one printable ASCII character each.
check_letter_sweep examples/sort-escaping.html "M07-AC1 (sort-escaping)" \
  $'Symbols\nA\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ'

# Leg 3 — gfm, the format with no index back-end at all (IP2). The twin is the
# probe with its sort= attributes deleted, so the two renders must come out
# IDENTICAL once the data-sort attribute Pandoc passes through is removed. A
# sort key that reached visible text — inside the mark's span or beside it —
# breaks that equality, and so does any other change a sort key makes to a
# format that builds no index.
for f in sort-escaping sort-escaping-twin; do
  quarto render "examples/$f.qmd" --to gfm > "$WORK/$f-gfm.log" 2>&1 \
    || { tail -20 "$WORK/$f-gfm.log" >&2; fail "M06-AC3: $f.qmd failed to render to gfm"; }
done
python3 - examples/sort-escaping.qmd examples/sort-escaping-twin.qmd \
  examples/sort-escaping.md examples/sort-escaping-twin.md <<'SORTESCGFMPY'
import re, sys
source, twin_src, rendered, twin_rendered = sys.argv[1:5]
# Two layers, two grammars, and they are NOT the same. In a Pandoc markdown
# attribute a backslash escapes the next character, so `\"` is a literal quote
# inside the value. In an HTML attribute it escapes nothing — the value ends at
# the first `"`, and a quote in the value is written `&quot;`. Parsing the
# rendered HTML with the markdown rule makes `data-sort="\"` (the mark whose
# sort key IS a backslash) swallow everything up to the next quote, two spans
# later.
SORT_ATTR = r' sort="(?:[^"\\]|\\.)*"'
DATA_SORT_ATTR = r' data-sort="[^"]*"'
src = open(source, encoding='utf-8').read()
if re.sub(SORT_ATTR, '', src) != open(twin_src, encoding='utf-8').read():
    print('FAIL: M06-AC3: the gfm twin fixture is not the probe with its '
          'sort= attributes removed', file=sys.stderr)
    sys.exit(1)
marks = len(re.findall(SORT_ATTR, src))
out = open(rendered, encoding='utf-8').read()
residue = re.findall(DATA_SORT_ATTR, out)
if len(residue) != marks:
    print(f'FAIL: M06-AC3: {marks} marks carry a sort key but gfm output '
          f'carries {len(residue)} data-sort attributes', file=sys.stderr)
    sys.exit(1)
stripped = re.sub(DATA_SORT_ATTR, '', out)
if stripped != open(twin_rendered, encoding='utf-8').read():
    print('FAIL: M06-AC3: a sort key changed gfm output beyond the attribute '
          'that carries it', file=sys.stderr)
    sys.exit(1)
print(f'ok   M06-AC3: in gfm all {marks} sort keys change nothing but the one '
      f'attribute carrying each, so none reaches visible text')
SORTESCGFMPY


# ---------------------------------------------------------------------------
# Manifest 1q — the generated index in examples/letter-groups.html
# (M07-AC1/AC2). EXHAUSTIVE, same format and same oracle rule as manifest 1e,
# every group derivation spelled out entry by entry — the same rule manifest
# 1e's step 5 states, applied here to a fixture built to exercise it:
#   5a. Group: a top-level entry's label is the first character of the string
#      it FILES under — its sort key where it has one, its printed text where
#      it does not — uppercased when that character is an ASCII letter, and
#      `Symbols` in every other case. Groups rank Symbols first, then A-Z;
#      within a group, and at every level below the top, step 5's collation is
#      unchanged. No entry can file under the empty string: a level that would
#      print nothing is dropped when the entry is derived (M11), and a mark
#      with nothing left indexes under its visible text or not at all.
#
# Derived per entry, filing string in parentheses:
#   `Quixote` (`!quixote`)   `!!` is the literal `!`             -> Symbols
#   `#hashtag` (`#hashtag`)  printed text                        -> Symbols
#   `~tilde` (`~tilde`)      printed text                        -> Symbols
#   `éclair` (`éclair`)      first byte of a UTF-8 sequence      -> Symbols
#   `alpha` (`alpha`)        printed text                        -> A
#   `#1 priority` (`alpha priority`)  sort key                   -> A
#   `Mango` (`Mango`)        printed text                        -> M
#   `windmill` (`windmill`)  `!windmill` lost its empty level    -> W
#   `zebra` (`zebra`)        printed text                        -> Z
# ---------------------------------------------------------------------------
read -r -d '' LETTER_GROUPS_INDEX <<'MANIFEST' || true
letter	Symbols
0	Quixote	1
0	#hashtag	1
0	~tilde	1
0	éclair	1
letter	A
0	alpha	1
0	#1 priority	1
letter	M
0	Mango	1
letter	W
0	windmill	1
letter	Z
0	zebra	1
MANIFEST

quarto render examples/letter-groups.qmd --to html \
  > "$WORK/letter-groups-html.log" 2>&1 \
  || { tail -40 "$WORK/letter-groups-html.log" >&2; fail "M07-AC2: letter-groups.qmd failed to render to HTML"; }
check_html_index_manifest examples/letter-groups.html "$LETTER_GROUPS_INDEX" \
  "M07-AC2"
check_html_index_links examples/letter-groups.html "M07-AC2"
check_letter_sweep examples/letter-groups.html "M07-AC3 (letter groups)" \
  $'Symbols\nA\nM\nW\nZ'

# The discriminator the manifest above carries but does not name: `#` and `~`
# are the first and last of the printable ASCII symbols, and every letter and
# digit sits between them in character order. They are neighbours in the
# rendered index ONLY because the letters have been lifted into groups of
# their own — an index that merely collated by character code would print the
# whole alphabet between these two rows.
HTML_SECTION_ID="$HTML_SECTION_ID" python3 - examples/letter-groups.html <<'ADJPY'
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
terms = [r['term'] for r in
         H.entry_records(H.find_id(doc, os.environ['HTML_SECTION_ID']))]
try:
    i, j = terms.index('#hashtag'), terms.index('~tilde')
except ValueError:
    print('FAIL: M07-AC2: the adjacency probe entries are not in the index',
          file=sys.stderr)
    sys.exit(1)
if j != i + 1:
    print(f'FAIL: M07-AC2: `#hashtag` and `~tilde` are {j - i} rows apart, so '
          f'group ranking did not lift the letters out from between them',
          file=sys.stderr)
    sys.exit(1)
print('ok   M07-AC2: the below-`a` and above-`z` symbol entries are adjacent, '
      'which only group ranking makes them')
ADJPY

# ---------------------------------------------------------------------------
# M09 — two entries that print in one place and file under two keys.
#
# The index tool stores three levels and this back-end folds anything deeper
# into the third rather than lose it, while a sort key is declared against the
# level path the author wrote, which the fold does not change. Two entries
# whose paths differ before the fold and agree after it therefore reach the
# index tool as two keys under one printed path: it stores the entry twice and
# prints it twice, in two places, identically. The fixture writes that
# collision twice — once with one side folded, once with both — and the twin
# writes the same entries with one shared key per pair, which is the same
# document without the mistake.
# ---------------------------------------------------------------------------
WARN_CLAMP_SPLIT='file under more than one key'

# The two fixtures are asserted against each other BY CONSTRUCTION, because
# every check below reads them as the same entries under different keys. So is
# the twin's stated constraint — each shared key differing from the third-level
# printed text of both entries carrying it: a shared key equal to one entry's
# third level emits no sort field for that entry, which splits the pair again
# and would make the twin's checks pass for the wrong reason. And so is the
# collision itself: each rival pair must fold to ONE printed level path, or the
# fixture has stopped exercising anything.
# Both read from the filter rather than written down here: this fixture's
# shapes are defined relative to the level ceiling and the string the fold
# joins with, and either one moving would leave the derivation below deriving
# something the back-end no longer does — while still passing, since it
# compares its own derivations against each other.
MAX_LEVELS=$(run_scan max-levels)
OVERFLOW_JOIN=$(run_scan overflow-join)
MAX_LEVELS="$MAX_LEVELS" OVERFLOW_JOIN="$OVERFLOW_JOIN" \
  python3 - examples/sortkey-clamp.qmd examples/sortkey-clamp-twin.qmd <<'CLAMPTWINPY'
import os, re, sys

MAX_LEVELS = int(os.environ['MAX_LEVELS'])
OVERFLOW_JOIN = os.environ['OVERFLOW_JOIN']


def marks(path):
    src = open(path, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'\{\.index ([^}]*)\}', src):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', m.group(1)))
        out.append((attrs.get('entry'), attrs.get('sort')))
    return out


def levels(value):
    # No fixture entry or key here contains the doubled `!!` that writes a
    # literal `!`, which this split would not honor; asserted rather than
    # assumed, since a later edit could add one.
    if '!!' in value:
        print(f'FAIL: M09: {value!r} carries a literal `!`, which this '
              f'derivation does not read', file=sys.stderr)
        sys.exit(1)
    return value.split('!')


def folded(entry):
    lv = levels(entry)
    if len(lv) <= MAX_LEVELS:
        return lv
    return lv[:MAX_LEVELS - 1] + [OVERFLOW_JOIN.join(lv[MAX_LEVELS - 1:])]


rival, twin = marks(sys.argv[1]), marks(sys.argv[2])
if len(rival) != 4 or len(twin) != 4:
    print(f'FAIL: M09: the fixtures write {len(rival)} and {len(twin)} index '
          f'marks; both are two pairs', file=sys.stderr)
    sys.exit(1)
if [e for e, _ in rival] != [e for e, _ in twin]:
    print('FAIL: M09: the twin does not index the same entries, in the same '
          'order, as the fixture:', file=sys.stderr)
    for a, b in zip(rival, twin):
        if a[0] != b[0]:
            print(f'  {a[0]!r} against {b[0]!r}', file=sys.stderr)
    sys.exit(1)

pairs = [(0, 1), (2, 3)]
for i, j in pairs:
    if folded(rival[i][0]) != folded(rival[j][0]):
        print(f'FAIL: M09: {rival[i][0]!r} and {rival[j][0]!r} do not fold to '
              f'one printed level path, so this pair is not the collision',
              file=sys.stderr)
        sys.exit(1)
    if levels(rival[i][0]) == levels(rival[j][0]):
        print(f'FAIL: M09: {rival[i][0]!r} and {rival[j][0]!r} are the same '
              f'entry before the fold; the collision needs two', file=sys.stderr)
        sys.exit(1)
if folded(rival[0][0]) == folded(rival[2][0]):
    print('FAIL: M09: both pairs fold to the same printed path, so the two '
          'reports below cannot be told apart', file=sys.stderr)
    sys.exit(1)
# One side folded in the first pair, both sides in the second: the two shapes
# the criteria name, asserted of the fixture rather than trusted to its prose.
shapes = [sorted(len(levels(rival[i][0])) > MAX_LEVELS for i in pair)
          for pair in pairs]
if shapes != [[False, True], [True, True]]:
    print(f'FAIL: M09: the fixture no longer writes one one-side-folded pair '
          f'and one both-sides-folded pair: {shapes}', file=sys.stderr)
    sys.exit(1)

if len({s for _, s in rival}) != 4:
    print(f'FAIL: M09: the fixture must give all four entries different sort '
          f'keys: {[s for _, s in rival]}', file=sys.stderr)
    sys.exit(1)
for i, j in pairs:
    if twin[i][1] != twin[j][1]:
        print(f'FAIL: M09: the twin pair {twin[i][1]!r}/{twin[j][1]!r} does '
              f'not share one sort key', file=sys.stderr)
        sys.exit(1)
if twin[0][1] == twin[2][1]:
    print('FAIL: M09: the twin gives both pairs the same key, so its two '
          'entries would contest one printed path', file=sys.stderr)
    sys.exit(1)
for entry, key in twin:
    third_key = levels(key)[MAX_LEVELS - 1]
    third_level = levels(entry)[MAX_LEVELS - 1]
    if third_key == third_level:
        print(f'FAIL: M09: the twin key {key!r} names the third level of '
              f'{entry!r} verbatim, so that entry emits no sort field and the '
              f'pair files apart again', file=sys.stderr)
        sys.exit(1)
print('ok   M09: the two fixtures write the same four entries, the first '
      'under four rival keys and the twin under one key per pair, each pair '
      'folding to one printed level path and each twin key differing from '
      'both its entries\' third level')
CLAMPTWINPY

quarto render examples/sortkey-clamp.qmd --to latex \
  > "$WORK/sortkey-clamp-latex.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-clamp-latex.log" >&2; fail "M09-AC1: sortkey-clamp.qmd failed to render to LaTeX"; }
# Exactly one report per PAIR, naming that pair's two keys and the printed
# path they contest. The whole-message checks are what make the count mean
# what it says: two reports about one pair, or one naming the wrong keys,
# would satisfy the count alone.
check_warning_count "$WORK/sortkey-clamp-latex.log" "$WARN_CLAMP_SPLIT" 2 \
  "M09-AC1"
check_warning_count "$WORK/sortkey-clamp-latex.log" \
  'index entries printed as "alpha!beta!gamma, delta" file under more than one key ("alpha!beta!Ada" and "alpha!beta!Zed")' \
  1 "M09-AC1"
check_warning_count "$WORK/sortkey-clamp-latex.log" \
  'index entries printed as "mu!nu!xi, omicron, pi" file under more than one key ("mu!nu!Vee" and "mu!nu!Wye")' \
  1 "M09-AC1"
pass "M09-AC1: each pair of entries contesting one printed level path is reported once, naming both sort keys and the path"

# ---------------------------------------------------------------------------
# Manifest 1s — the generated index in examples/sortkey-clamp.html (M09-AC2).
# EXHAUSTIVE, same row format as manifest 1e, and DERIVED FOR THESE ROWS: the
# HTML back-end applies no level ceiling, so the four entries the LaTeX side
# folds into two stay four here, at the level paths they were written with.
#
# Ordering is derived through the SORT KEYS, which is what orders these rows —
# their printed text would give the opposite order in both groups:
#   `alpha` (`alpha`)  no key at this path, so its printed text  -> group A
#     `beta` (`beta`)  likewise
#       `gamma, delta` (`alpha!beta!Ada`) declared by its own mark
#       `gamma`        (`alpha!beta!Zed`) declared by the four-level mark
#         -> `Ada` before `Zed`, which is `gamma, delta` before `gamma`
#         `delta`      no key; the only child of `gamma`
#   `mu` (`mu`), `nu` (`nu`)  no key at either path            -> group M
#       `xi, omicron` (`mu!nu!Vee`) declared by the four-level mark
#       `xi`          (`mu!nu!Wye`) declared by the five-level mark
#         -> `Vee` before `Wye`, which is `xi, omicron` before `xi`
#         `pi`, and `omicron` > `pi`: each the only child of its parent
#
# Locators: one per mark, on the entry the mark was written for — the deepest
# level of each of the four paths. Every level above them is a parent no mark
# indexes on its own, so it carries none.
# ---------------------------------------------------------------------------
read -r -d '' SORTKEY_CLAMP_HTML_INDEX <<'MANIFEST' || true
letter	A
0	alpha	0
1	beta	0
2	gamma, delta	1
2	gamma	0
3	delta	1
letter	M
0	mu	0
1	nu	0
2	xi, omicron	0
3	pi	1
2	xi	0
3	omicron	0
4	pi	1
MANIFEST

quarto render examples/sortkey-clamp.qmd --to html \
  > "$WORK/sortkey-clamp-html.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-clamp-html.log" >&2; fail "M09-AC2: sortkey-clamp.qmd failed to render to HTML"; }
# The report is the LaTeX back-end's alone: the fold is the index tool's
# ceiling, not an index's, and the entries it collides are four distinct ones
# here. A report that fired in every format would be telling an HTML author to
# fix something that is not wrong.
check_warning_count "$WORK/sortkey-clamp-html.log" "$WARN_CLAMP_SPLIT" 0 \
  "M09-AC2"
check_html_index_manifest examples/sortkey-clamp.html \
  "$SORTKEY_CLAMP_HTML_INDEX" "M09-AC2"
check_html_index_links examples/sortkey-clamp.html "M09-AC2"

# ---------------------------------------------------------------------------
# M09-AC3 — the same entries with one shared key per pair: nothing to report,
# one index-tool key per pair, and (below, with the PDF) one printed entry.
# ---------------------------------------------------------------------------
for fmt in latex html; do
  quarto render examples/sortkey-clamp-twin.qmd --to "$fmt" \
    > "$WORK/sortkey-clamp-twin-$fmt.log" 2>&1 \
    || { tail -40 "$WORK/sortkey-clamp-twin-$fmt.log" >&2; fail "M09-AC3: sortkey-clamp-twin.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/sortkey-clamp-twin-$fmt.log" "$WARN_CLAMP_SPLIT" \
    0 "M09-AC3 ($fmt)"
done
# Hand-derived from the twin: each pair's two marks emit the same argument —
# the pair's printed level path, folded, filed under the one key both carry —
# so the tool receives one key per pair and two locators for it.
python3 - examples/sortkey-clamp-twin.tex <<'CLAMPTWINTEXPY'
import re, sys
from collections import Counter
tex = open(sys.argv[1], encoding='utf-8').read()
args = Counter(re.findall(r'\\index\{(.*?)\}', tex))
want = Counter({'alpha!beta!Kay@gamma, delta': 2,
                'mu!nu!Jay@xi, omicron, pi': 2})
if args != want:
    print('FAIL: M09-AC3: the twin does not write one index-tool key per '
          f'pair.\n  expected {dict(want)}\n  got      {dict(args)}',
          file=sys.stderr)
    sys.exit(1)
print('ok   M09-AC3: each twin pair reaches the index tool as one key, '
      'carrying both of its marks')
CLAMPTWINTEXPY

# The symptom the report exists to prevent is a doubled entry in the built
# index, so the twin is followed all the way there: one key per pair in the
# .tex above, and one printed entry per pair in the compiled PDF. Read with
# tests/pdfindex.py rather than out of pdftotext's text output, for the reason
# that module's header gives.
#
# Derived by hand from the twin: each pair's two marks index one entry, whose
# printed path is the pair's levels folded into three — `alpha!beta!gamma,
# delta` and `mu!nu!xi, omicron, pi` — so the index prints two top-level
# entries, each two levels deep, and neither term twice.
quarto render examples/sortkey-clamp-twin.qmd --to pdf \
  > "$WORK/sortkey-clamp-twin-pdf.log" 2>&1 \
  || { tail -40 "$WORK/sortkey-clamp-twin-pdf.log" >&2; fail "M09-AC3: sortkey-clamp-twin.qmd failed to render to PDF"; }
[ -s examples/sortkey-clamp-twin.pdf ] \
  || fail "M09-AC3: examples/sortkey-clamp-twin.pdf is empty"
check_warning_count "$WORK/sortkey-clamp-twin-pdf.log" "$WARN_CLAMP_SPLIT" 0 \
  "M09-AC3 (pdf)"
read -r -d '' SORTKEY_CLAMP_TWIN_OUTLINE <<'MANIFEST' || true
0	alpha
1	beta
2	gamma, delta
0	mu
1	nu
2	xi, omicron, pi
MANIFEST
printf '%s\n' "$SORTKEY_CLAMP_TWIN_OUTLINE" > "$WORK/clamp-twin-outline.txt"
python3 - examples/sortkey-clamp-twin.pdf "$WORK/clamp-twin-outline.txt" \
  <<'CLAMPPDFPY'
import sys
from collections import Counter
sys.path.insert(0, 'tests')
import pdfindex

entries = pdfindex.read(sys.argv[1])
if not pdfindex.columns_carry_top_level(entries):
    print('FAIL: M09-AC3: a column of the printed index carries no top-level '
          'entry, so pdfindex cannot read its indent levels', file=sys.stderr)
    sys.exit(1)
actual = pdfindex.outline(entries)
expected = []
for line in open(sys.argv[2], encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip():
        level, term = line.split('\t', 1)
        expected.append((int(level), term))
if actual != expected:
    print('FAIL: M09-AC3: the printed index is not what the twin derives.',
          file=sys.stderr)
    for i in range(max(len(actual), len(expected))):
        a = actual[i] if i < len(actual) else None
        e = expected[i] if i < len(expected) else None
        print(f'{"  " if a == e else "->"} {i}: got {a!r} want {e!r}',
              file=sys.stderr)
    sys.exit(1)
# Named separately from the comparison above, because it is the criterion:
# the collision prints its entry once per key, so a pair that files as one key
# has to print its entry exactly once.
printed = Counter(term for _, term in actual)
doubled = {t: n for t, n in printed.items() if n > 1}
if doubled:
    print(f'FAIL: M09-AC3: the printed index carries {doubled}, so a pair '
          f'filed apart after all', file=sys.stderr)
    sys.exit(1)
print(f'ok   M09-AC3: the compiled PDF prints each pair as one entry at its '
      f'folded level path, {len(expected)} rows and no term twice')
CLAMPPDFPY
pass "M09-AC3: two entries sharing one sort key per pair are reported not at all, reach the index tool as one key each, and print once each in the built index"

# ---------------------------------------------------------------------------
# M10-AC6 — the fold-induced drop, followed to the compiled artifact (GP6).
# The emitted `\index` command is checked above; what a reader actually gets
# is settled by makeindex and LaTeX, which run after this extension's contract
# ends, so the entry is read out of the built PDF as well.
#
# ORACLE RULE: the expected rows below are derived BY HAND from
# examples/self-xref.qmd plus the documented fold — the LaTeX back-end stores
# three levels, so `entry="A!B!C!D"` prints `A`, `B`, `C, D` and
# `entry="M!N!O!P"` prints `M`, `N`, `O, P`. Nothing here is read back from
# tests/pdfindex.py, per that module's own header.
#
# Both directions are asserted. The five M10 entries must carry no
# cross-reference text, and the two M08 entries that legitimately keep one
# must still show it — a "no see also anywhere" check would pass just as well
# on an index that had lost every cross-reference in the document.
# ---------------------------------------------------------------------------
quarto render examples/self-xref.qmd --to pdf \
  > "$WORK/self-xref-pdf.log" 2>&1 \
  || { tail -40 "$WORK/self-xref-pdf.log" >&2; fail "M10-AC6: self-xref.qmd failed to render to PDF"; }
[ -s examples/self-xref.pdf ] || fail "M10-AC6: examples/self-xref.pdf is empty"
check_warning_count "$WORK/self-xref-pdf.log" "$WARN_FOLD_SELF" 3 "M10-AC6"
python3 - examples/self-xref.pdf <<'SELFXREFPDFPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

entries = pdfindex.read(sys.argv[1])
if not pdfindex.columns_carry_top_level(entries):
    print('FAIL: M10-AC6: a column of the printed index carries no top-level '
          'entry, so pdfindex cannot read its indent levels', file=sys.stderr)
    sys.exit(1)
actual = pdfindex.outline(entries)
errs = []

# Hand-derived: each folded entry prints its first two levels as written and
# its overflow joined into the third, at levels 0, 1, 2, consecutively.
for want in ([(0, 'A'), (1, 'B'), (2, 'C, D')],
             [(0, 'M'), (1, 'N'), (2, 'O, P')]):
    n = len(want)
    if not any(actual[i:i + n] == want for i in range(len(actual) - n + 1)):
        errs.append(f'{want} does not appear as consecutive rows')

# Which lines may print a cross-reference at all, stated over EVERY printed
# entry rather than over the five M10 added. Naming the five by their term
# cannot be the domain: a surviving target is typeset on the entry's own line,
# so an entry that kept one no longer prints the term the list would name, and
# the clause would pass by not matching. These two are the whole of it, and
# both are M08 shapes this milestone does not touch. (M14 retargeted the first
# from `Pets` to `Cats`, an entry the file marks; the shape is unchanged.)
CROSS_REFERENCED = ('Dogs, see also Cats', 'Lynxes, see Cats')
printed = [e.text for e in entries]
for entry in entries:
    printed_xref = ', see ' in entry.text or ', see also ' in entry.text
    if printed_xref and entry.text not in CROSS_REFERENCED:
        errs.append(f'entry {entry.text!r} prints a cross-reference and is not '
                    f'one of the two entitled to')
# ...and both of those must actually be there, or the loop above is satisfied
# by an index that lost every cross-reference in the document.
for want in CROSS_REFERENCED:
    if want not in printed:
        errs.append(f'{want!r} is not in the printed index, so the check above '
                    f'cannot tell a dropped target from a lost one')

# The IP2 half, followed to the artifact: dropping a target must leave the term
# indexed. Hand-derived from the .qmd — the depth-5 entry folds to F, G,
# "H, I, J"; and since M11 an empty level is dropped when the entry is derived,
# so `entry="P!Q!R!"` is the three levels P, Q, R with no fold at all, and
# `entry="Moles!"` is the single top-level term `Moles`. Neither hands the
# index tool a null field any more — the trailing one it used to swallow, the
# leading one it would have rejected outright.
for want in ([(0, 'F'), (1, 'G'), (2, 'H, I, J')],
             [(0, 'P'), (1, 'Q'), (2, 'R')]):
    n = len(want)
    if not any(actual[i:i + n] == want for i in range(len(actual) - n + 1)):
        errs.append(f'{want} does not appear as consecutive rows, so a term '
                    f'was lost rather than indexed plainly')
if (0, 'Moles') not in actual:
    errs.append("the entry 'Moles' is not in the printed index at all")

if errs:
    print('FAIL: M10-AC6: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M10-AC6: the built index prints both folded entries at their three '
      'derived levels with no cross-reference on any of the five M10 entries, '
      'while the two entries that keep a cross-reference still print one')
SELFXREFPDFPY
pass "M10-AC6: the fold-induced self-target is gone from the compiled index, not only from the emitted LaTeX"

# ---------------------------------------------------------------------------
# M11 — empty index levels are dropped, so a leading empty level can no longer
# hand the index tool a null field that destroys the entry.
#
# Manifest 1r — examples/empty-levels.qmd, derived from the .qmd by applying
# the rule this milestone ships: an empty level prints nothing and is dropped,
# a value that is nothing BUT empty levels falls back to the mark's visible
# text, and a sort level is dropped together with the entry level it was
# written for. Entry by entry, in .qmd order:
#   `entry="!Cats"`                      -> Cats     (leading empty gone)
#   `entry="Dogs!"`                      -> Dogs     (trailing empty gone)
#   `entry="!Sub!"`                      -> Sub      (both gone)
#   `entry="!Owls" see="Owls"`           -> Owls, target dropped as a
#                                           self-reference
#   `entry="!Zebra" sort="mmm!aardvark"` -> Zebra, filing under `aardvark`:
#                                           `mmm` was written for the empty
#                                           level and went with it
#   `entry="Moles!" sort="a!b!c"`       -> Moles, filing under `a`: written
#                                           with two levels, sorted with
#                                           three, indexing at one — the shape
#                                           whose three differing depths the
#                                           extra-sort report must not conflate
#                                           (M13). `b` went with the empty
#                                           level it was written for, `c` past
#                                           the end was ignored
#   `sort="a!b!c"` on [ferns], no entry= -> ferns, filing under `a`: the same
#                                           overreach with no entry= at all,
#                                           reaching the report through the
#                                           visible-text fallback (M13)
#   `entry="!"` on [Ferrets]             -> Ferrets  (visible-text fallback)
#   `entry="!"` on []                    -> nothing indexed, no text to fall
#                                           back on
#   `entry="Birds!Wrens"`                -> Birds -> Wrens (control, untouched)
#   `entry="Q!R"` marked twice, `sort="Q!R!S"` then `sort="Q!yyy"` -> Q -> R
#                                         filing under `yyy`: the first mark's
#                                         `R` restates the level's own text on
#                                         the way to a deeper one and so
#                                         declares nothing, leaving the second
#                                         mark's `yyy` uncontested. NO empty
#                                         level anywhere in this shape — it is
#                                         here to say that dropping empty
#                                         levels did not change what a sort key
#                                         means for an entry that has none
#                                         (M11 review F1)
# ---------------------------------------------------------------------------

# The emitted LaTeX arguments, one per indexed mark, in document order. `!`
# here is the index tool's level separator: the author's own `!` is quoted
# `"!` by the escape table, so an UNQUOTED `!` at either end of an argument,
# or two in a row, is a null field.
read -r -d '' EMPTY_LEVELS_TEX <<'MANIFEST' || true
Cats
Dogs
Sub
Owls
aardvark@Zebra
a@Moles
a@ferns
Ferrets
Birds!Wrens
Q!yyy@R
Q!yyy@R
MANIFEST

# The printed index of the compiled PDF: (level, term) rows in the index
# tool's own order, which collates on the string each entry FILES under, so
# `ferns` and `Moles` both file on `a` and so lead the index, collated
# case-insensitively against each other; `Zebra` follows on `aardvark`.
# Derived from the manifest above.
read -r -d '' EMPTY_LEVELS_PDF <<'MANIFEST' || true
0	ferns
0	Moles
0	Zebra
0	Birds
1	Wrens
0	Cats
0	Dogs
0	Ferrets
0	Owls
0	Q
1	R
0	Sub
MANIFEST

# The same entries in the HTML index, in this back-end's own letter grouping,
# each group labelled by the first character of the string the entry FILES
# under. `Zebra` files under `aardvark`, so it lands in A and not in Z — which
# is what tells a sort level dropped WITH its own level from one re-aligned
# onto the level that survived, since re-aligning would file `Zebra` under
# `mmm`, in M. Row format is manifest 1e's: depth, term, locator count.
read -r -d '' EMPTY_LEVELS_HTML <<'MANIFEST' || true
letter	A
0	ferns	1
0	Moles	1
0	Zebra	1
letter	B
0	Birds	0
1	Wrens	1
letter	C
0	Cats	1
letter	D
0	Dogs	1
letter	F
0	Ferrets	1
letter	O
0	Owls	1
letter	Q
0	Q	0
1	R	2
letter	S
0	Sub	1
MANIFEST

# The shared Python the two checks below both need: every `\index` argument in
# a file, and one argument split on the separators the index tool reads.
index_fields() {
  cat <<'FIELDSPY'
def arguments(path):
    """Every `\index{...}` argument in a file, brace-matched.

    A regex stopping at the first `}` reads an argument carrying an encap
    truncated — `\index{Cats!|see{X}}` comes back as `Cats!|see{X`, whose
    last field is non-empty however the real argument actually ends — so a
    trailing null field on any cross-referencing entry was invisible to a
    scan built that way (M11 review F5).
    """
    src = open(path, encoding='utf-8').read()
    out, i, token = [], 0, '\\index{'
    while True:
        start = src.find(token, i)
        if start < 0:
            return out
        j, depth = start + len(token), 1
        while j < len(src) and depth > 0:
            if src[j] == '{':
                depth += 1
            elif src[j] == '}':
                depth -= 1
            j += 1
        out.append(src[start + len(token):j - 1])
        i = j


def fields(arg):
    """One `\index` argument split on the separators the index tool reads.

    An author's own `!` is quoted `"!` by the escape table, so an unquoted one
    is a level separator.
    """
    seps = [i for i, c in enumerate(arg)
            if c == '!' and (i == 0 or arg[i - 1] != '"')]
    out, last = [], 0
    for i in seps:
        out.append(arg[last:i])
        last = i + 1
    out.append(arg[last:])
    return out
FIELDSPY
}

# The stable half of the empty-level report; the positions it names and the
# count of levels that remain both vary with the value.
WARN_EMPTY_LEVEL='an empty level prints nothing, so it is dropped and '
WARN_ONLY_EMPTY_FALLBACK='is only empty levels, which print nothing; the mark indexes under its visible text instead'
WARN_ONLY_EMPTY_NOTHING='is only empty levels, which print nothing; nothing to index'
# The stable half of the dropped-sort-key report; its count of levels varies.
WARN_SORT_DROPPED='a key is dropped with the level it was written for, and the levels that remain keep their own'
# The rival-key report's own key. `WARN_SORT_EXTRA` and `WARN_SORT_CONFLICT`
# are already defined above with the other sort-key reports (M06-AC4) and are
# reused here rather than redefined.
WARN_SORT_RIVAL='is already sorted as'

for fmt in html latex gfm; do
  quarto render examples/empty-levels.qmd --to $fmt \
    > "$WORK/empty-levels-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/empty-levels-$fmt.log" >&2; fail "M11-AC5: empty-levels.qmd failed to render to $fmt"; }
  # One report per MARK carrying an empty level, not one per empty level
  # (M13): `!Cats`, `Dogs!`, `!Sub!`, `!Owls`, `!Zebra` and `Moles!` are six
  # such marks, and `!Sub!` — which carries two empty levels — draws one of the
  # six rather than two of seven. Format-neutral: an empty level prints nothing
  # in every back-end and in none, so the count is the same in all three.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_EMPTY_LEVEL" 6 "M11-AC5"
  # The all-empty pair: one message each, and each says which way its mark
  # went, rather than the "no entry=" message that would be false about both.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_ONLY_EMPTY_FALLBACK" 1 "M11-AC5"
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_ONLY_EMPTY_NOTHING" 1 "M11-AC5"
  # The self-reference reaches the comparison in every format now, because the
  # entry drops its empty levels exactly as its target already did.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_SELF_XREF" 1 "M11-AC5"
  # The load-bearing zero: nothing here is deep enough to fold, and the drop
  # must not leave one looking deep — a leading empty level and two real ones
  # is three levels, not four.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_FOLD_DEPTH" 0 "M11-AC5"
  # A key written for a level that prints nothing is dropped with it, and said
  # so rather than lost quietly: `entry="!Zebra" sort="mmm!aardvark"` loses
  # `mmm`, `entry="!" sort="fff"` loses all of `fff`, none of it landing on the
  # level the mark falls back to (M11 review F2, F3), and `entry="Moles!"
  # sort="a!b!c"` loses `b` with its own trailing empty level (M13).
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_SORT_DROPPED" 3 "M11-AC5"
  # Three marks reach past what they have to sort: `entry="Q!R" sort="Q!R!S"`
  # by one level, and M13's two shapes — `entry="Moles!" sort="a!b!c"` and the
  # `sort="a!b!c"` mark with no `entry=` at all — each by more. Each draws one
  # warning, never two.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_SORT_EXTRA" 3 "M11-AC5"
  # The F1 regression guard, and the reason the `Q!R` pair is in the fixture at
  # all. Both marks file that entry under one key, because the first mark's `R`
  # merely restates the level's own text on the way to a deeper level and so
  # declares nothing. Reading the last-declared position off the REALIGNED sort
  # list instead of off what the author wrote made it a declaration, which lost
  # the second mark's `yyy` and reported a rival that does not exist — on an
  # entry with no empty level anywhere in it.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$WARN_SORT_RIVAL" 0 "M11-AC5"
done
pass "M11-AC5: each of the six marks carrying an empty level warns exactly once in HTML, LaTeX and gfm, the two-empty-level mark included; the two all-empty entries each say which way they went; both dropped sort keys are reported; nothing folds and no rival key is invented for the entry that has no empty level"

# ---------------------------------------------------------------------------
# M13 — the two reports about a mark's levels name something the author can
# act on. Asserted as whole message text, not as a count of firings: three
# rounds of container-report defects counted right while naming the wrong
# thing (M08), and a count alone cannot tell a report that names position 1
# from one that names position 2.
# ---------------------------------------------------------------------------

# AC1. One report per mark, naming the empty positions in the value as the
# author wrote it and how many of the WRITTEN levels remain — never how many
# the entry indexes at, which this layer cannot know because the LaTeX ceiling
# folds later. Four shapes: leading, trailing, both-in-one-mark, and the deep
# trailing one demo.qmd carries, whose 6 written levels are the case where the
# remaining count is not 1.
M13_EMPTY_LEADING='empty index level in entry="!Cats" at position 1 of 2; an empty level prints nothing, so it is dropped and 1 of the 2 written levels remains'
M13_EMPTY_TRAILING='empty index level in entry="Dogs!" at position 2 of 2; an empty level prints nothing, so it is dropped and 1 of the 2 written levels remains'
M13_EMPTY_BOTH='empty index level in entry="!Sub!" at positions 1 and 3 of 3; an empty level prints nothing, so it is dropped and 1 of the 3 written levels remains'
M13_EMPTY_DEEP='empty index level in entry="One!Two!Three!Four!Five!" at position 6 of 6; an empty level prints nothing, so it is dropped and 5 of the 6 written levels remain'

for fmt in html latex gfm; do
  check_warning_count "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_LEADING" 1 "M13-AC1"
  check_warning_count "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_TRAILING" 1 "M13-AC1"
  # The load-bearing one: two empty levels in a mark, ONE report naming both.
  check_warning_count "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_BOTH" 1 "M13-AC1"
  # And the exception the rule keeps: a value that is only empty levels has
  # its own whole-value message and draws none of this report.
  check_warning_count "$WORK/empty-levels-$fmt.log" 'empty index level in entry="!" at' 0 "M13-AC1"
done
check_warning_count "$WORK/demo-latex.log" "$M13_EMPTY_DEEP" 1 "M13-AC1"
pass "M13-AC1: each mark carrying empty levels draws one report naming the written positions and the levels that remain, in all three formats; the two-empty-level mark draws one and not two, the all-empty mark draws none, and the six-level shape reports 5 of 6 remaining"

# AC2. The leading and trailing reports must differ in the POSITION they name,
# not merely in the value they echo. Masking the echoed value is what makes
# this discriminating: before M13 the two messages were identical either side
# of `entry="..."`, so a plain string-inequality check passed on a filter that
# named no position at all.
for fmt in html latex gfm; do
python3 - "$WORK/empty-levels-$fmt.log" <<'M13AC2PY'
import re, sys
lines = [l.rstrip('\n') for l in open(sys.argv[1], encoding='utf-8',
                                      errors='replace')
         if 'empty index level in entry="!Cats"' in l
         or 'empty index level in entry="Dogs!"' in l]
if len(lines) != 2:
    print(f'FAIL: M13-AC2: expected one report each for the leading and '
          f'trailing shapes in {sys.argv[1]}, got {len(lines)}',
          file=sys.stderr)
    sys.exit(1)
masked = [re.sub(r'entry="[^"]*"', 'entry=<masked>', l) for l in lines]
if masked[0] == masked[1]:
    print('FAIL: M13-AC2: the leading and trailing reports are identical once '
          'the echoed entry= value is masked, so the author is not told which '
          'end went:', file=sys.stderr)
    print(f'  <<{masked[0]}>>', file=sys.stderr)
    sys.exit(1)
M13AC2PY
done
pass 'M13-AC2: in HTML, LaTeX and gfm alike, the leading and trailing empty-level reports differ in the position they name, not only in the value they echo'

# AC3. Both numbers in the extra-sort-levels report are counts taken BEFORE
# the empty-level drop, so neither can be read as the depth the entry indexes
# at — `entry="Moles!" sort="a!b!c"` is written with 2, sorted with 3, and
# indexes at 1, and the emitted \index below is what says so. The second shape
# carries no `entry=` at all: it reaches the report through the visible-text
# fallback, so wording naming an entry value would be false about it.
#
# M19-AC3 reworded both. The second number is now named for what it is measured
# over rather than by a clause about a drop that touches neither of them
# (D-006), and the two shapes read differently there for the first time: the
# entry shape names the entry, the fallback shape names the level its visible
# text makes. The NUMBERS are byte-for-byte the ones M13 pinned — 3 against 2,
# and 3 against 1 — which is what M19-AC5 asks of this pair.
M13_SORT_EXTRA_ENTRY='sort= on entry="Moles!" writes 3 levels against the 2 the entry is written with; the extra sort levels were ignored'
M13_SORT_EXTRA_NOENTRY='sort= on term "ferns" writes 3 levels against the 1 level its visible text makes; the extra sort levels were ignored'
for fmt in html latex gfm; do
  check_warning_count "$WORK/empty-levels-$fmt.log" "$M13_SORT_EXTRA_ENTRY" 1 "M13-AC3"
  check_warning_count "$WORK/empty-levels-$fmt.log" "$M13_SORT_EXTRA_NOENTRY" 1 "M13-AC3"
done
# Exactly one Moles argument, and it is the single-level form: a bare
# presence test for `\index{a@Moles}` plus an absence test for the two-level
# form cannot both fail, since the first already requires the closing brace
# (review F12). Counting every argument that files under `a@Moles` is what
# actually pins the indexed depth at one.
moles=$( { grep -oF 'index{a@Moles' examples/empty-levels.tex || true; } | wc -l | tr -d ' ')
[ "$moles" = 1 ] \
  || fail "M13-AC3: expected exactly 1 emitted argument filing under a@Moles, got $moles"
grep -qF '\index{a@Moles}' examples/empty-levels.tex \
  || fail "M13-AC3: the one a@Moles argument is not the single-level \index{a@Moles}; the report's numbers are not the three-way-distinct case"
pass "M13-AC3: the extra-sort report states both counts as taken before the empty-level drop, for a mark whose written, sorted and indexed depths are 2, 3 and 1, and for one carrying sort= with no entry= at all"

# AC5. Neither report fires for a well-formed mark. sortkey.qmd is asserted
# warning-free above (M06-AC1/AC2); this is the per-line half — no report line
# anywhere names it, or names the no-empty-level control of empty-levels.qmd.
# Not a grep for the report text in those logs: M06-AC1 and M06-AC2 already
# abort on ANY `^(W)` line there, so such a grep is a tautology by the time it
# runs (review F11). What AC5 actually says is that no report line NAMES a
# well-formed mark, so the marks are read out of the fixture and looked for on
# every warning line the suite produced anywhere.
python3 - "$WORK" examples/sortkey.qmd <<'M13AC5PY'
import glob, os, re, sys
work, fixture = sys.argv[1], sys.argv[2]
qmd = open(fixture, encoding='utf-8').read()

# How the filter NAMES a mark in a report (describe()): the entry= value where
# there is one, else the visible text. Both forms are built here, so a report
# naming any mark of this fixture is caught whichever way it refers to it.
SPAN = re.compile(r'\[((?:\\.|[^\]\\])*)\]\{\.index((?:[^}\\]|\\.)*)\}')
spans = SPAN.findall(qmd)
named = set()
for visible, attrs in spans:
    entry = re.search(r'entry="((?:\\.|[^"\\])*)"', attrs)
    named.add(f'entry="{entry.group(1)}"' if entry else f'term "{visible}"')

# Derived, not planted: every `{.index` in the fixture must have been parsed,
# so a fixture edit that outruns this regex fails here instead of quietly
# shrinking the control (M06 lesson).
written = qmd.count('{.index')
if len(spans) != written:
    print(f'FAIL: M13-AC5: parsed {len(spans)} marks from {fixture} but the '
          f'file writes {written}; the control is not being read whole',
          file=sys.stderr)
    sys.exit(1)

REPORTS = ('empty index level in ', 'the extra sort levels were ignored')
bad = []
for log in sorted(glob.glob(os.path.join(work, '*.log'))):
    for line in open(log, encoding='utf-8', errors='replace'):
        if not line.startswith('(W)') or not any(r in line for r in REPORTS):
            continue
        for mark in named:
            if mark in line:
                bad.append(f'  {os.path.basename(log)}: {line.strip()}')
if bad:
    print(f'FAIL: M13-AC5: a level report names a well-formed mark of '
          f'{fixture}:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M13-AC5: neither report names any of the {len(named)} well-formed '
      f'marks of {fixture}, across every render log the suite produced')
M13AC5PY
for fmt in html latex gfm; do
  check_warning_count "$WORK/empty-levels-$fmt.log" 'entry="Birds!Wrens"' 0 "M13-AC5"
done
pass "M13-AC5: neither report names the no-empty-level control entry=\"Birds!Wrens\""


check_no_null_field examples/empty-levels.tex "M11-AC2 (empty-levels)"

# ---------------------------------------------------------------------------
# M11-AC1/AC4 — the emitted LaTeX, argument for argument.
# ---------------------------------------------------------------------------
python3 - examples/empty-levels.tex "$EMPTY_LEVELS_TEX" <<EMPTYTEXPY
import sys
$(index_fields)

want = [line for line in sys.argv[2].splitlines() if line.strip()]
got = arguments(sys.argv[1])
if got != want:
    print(f'FAIL: M11-AC1: emitted \\\\index arguments {got} do not match the '
          f'manifest {want}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M11-AC1: all {len(got)} \\\\index arguments match the manifest in '
      f'document order, the visible-text fallback and the surviving sort key '
      f'included')
EMPTYTEXPY
pass "M11-AC1/AC4: the emitted LaTeX indexes every mark with anything left to index, and only those"

# ---------------------------------------------------------------------------
# M11-AC3/AC4 — the same entries through the HTML back-end.
# ---------------------------------------------------------------------------
quarto render examples/empty-levels.qmd --to html \
  > "$WORK/empty-levels-html.log" 2>&1 \
  || { tail -40 "$WORK/empty-levels-html.log" >&2; fail "M11-AC3: empty-levels.qmd failed to render to HTML"; }
check_html_index_manifest examples/empty-levels.html "$EMPTY_LEVELS_HTML" \
  "M11-AC3"
check_html_index_links examples/empty-levels.html "M11-AC3"
check_letter_sweep examples/empty-levels.html "M11-AC3 (letter groups)" \
  $'A\nB\nC\nD\nF\nO\nQ\nS'

# The two back-ends compared against each other rather than each against its
# own manifest: two manifests can drift apart while both still pass, and the
# claim here is that one mark prints one path wherever it is rendered.
python3 - examples/empty-levels.tex examples/empty-levels.html <<BOTHENDSPY
import os, sys
sys.path.insert(0, 'tests')
import htmlindex as H
$(index_fields)

tex_paths = []
for arg in arguments(sys.argv[1]):
    printed = []
    for field in fields(arg):
        # A level written \`sortkey@printed\` prints the half after the \`@\` this
        # back-end wrote; the author's own \`@\` is quoted \`"@\`.
        at = [i for i, c in enumerate(field)
              if c == '@' and (i == 0 or field[i - 1] != '"')]
        printed.append(field[at[0] + 1:] if at else field)
    tex_paths.append(tuple(printed))

section = H.find_id(H.parse(sys.argv[2]), '$HTML_SECTION_ID')
html_paths, stack = [], []
for record in H.entry_records(section):
    stack = stack[:record['depth']] + [record['term']]
    html_paths.append(tuple(stack))

tex_set, html_set = set(tex_paths), set(html_paths)
missing = sorted(tex_set - html_set)
# The HTML back-end prints a parent row of its own where LaTeX writes the
# parent only as the prefix of its child, so a path every LaTeX path extends
# is not an extra entry.
extra = sorted(p for p in html_set - tex_set
               if not any(q[:len(p)] == p and q != p for q in tex_set))
if missing or extra:
    print(f'FAIL: M11-AC3: the back-ends print different level paths — in '
          f'LaTeX only: {missing}; in HTML only: {extra}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M11-AC3: each of the {len(tex_set)} level paths the LaTeX index '
      f'prints is printed by the HTML index too, and the HTML index prints '
      f'none the LaTeX one does not reach')
BOTHENDSPY
pass "M11-AC3: the two back-ends agree on every printed level path, compared against each other rather than each against its own manifest"

# ---------------------------------------------------------------------------
# M11-AC1 — followed to the compiled artifact, the only thing that settles
# whether the index tool ACCEPTED an entry: it rejects a null field, drops the
# entry, reports "0 warnings" and exits 0, so a clean build proves nothing.
# ---------------------------------------------------------------------------
quarto render examples/empty-levels.qmd --to pdf \
  > "$WORK/empty-levels-pdf.log" 2>&1 \
  || { tail -40 "$WORK/empty-levels-pdf.log" >&2; fail "M11-AC1: empty-levels.qmd failed to render to PDF"; }
[ -s examples/empty-levels.pdf ] || fail "M11-AC1: examples/empty-levels.pdf is empty"
python3 - examples/empty-levels.pdf "$EMPTY_LEVELS_PDF" <<'EMPTYPDFPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

want = [(int(level), term) for level, term in
        (line.split('\t') for line in sys.argv[2].splitlines() if line.strip())]
entries = pdfindex.read(sys.argv[1])
got = [(e.level, e.term) for e in entries]
errs = []
if got != want:
    errs.append(f'the printed index is {got}, not the manifest {want}')
# A locator on each: an entry the tool REJECTED is absent, but so is one it
# accepted and printed with nothing pointing at it, and only the second of
# those two would survive a check that read the terms alone.
#
# A parent carries no locator of its own — its marks hang off its children — so
# the exemption is DERIVED from the printed tree (any row the next row is
# deeper than) rather than named as a list of terms: a hand-list is a list the
# next fixture entry silently falls off.
for i, e in enumerate(entries):
    deeper = i + 1 < len(entries) and entries[i + 1].level > e.level
    if deeper:
        continue
    if e.text == e.term:
        errs.append(f'the entry {e.term!r} prints with no locator')
if errs:
    print('FAIL: M11-AC1: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print(f'ok   M11-AC1: the compiled index prints all {len(got)} manifest '
      f'entries in order, each with a locator, so the index tool accepted '
      f'every one')
EMPTYPDFPY
pass "M11-AC1: every entry written with an empty level survives to the compiled index"

# ---------------------------------------------------------------------------
# M14 — a cross-reference target that names no index entry is reported.
#
# Two fixtures, deliberately twinned. In examples/dangling-xref.qmd every
# report the filter can draw is drawn; in examples/resolving-xref.qmd none is.
# Neither alone is enough: a filter that reported every target would satisfy
# the first fixture entirely, and a filter that reported none would satisfy
# the second.
#
# Rendered to all three formats because the report is format-neutral (IP1):
# whether a target names a term the document indexes is a fact about what the
# author wrote, so the same document must draw the same reports in a format
# with a LaTeX index, one with an HTML index, and one with no index at all.
# ---------------------------------------------------------------------------

for fmt in latex html gfm; do
  quarto render examples/dangling-xref.qmd --to $fmt \
    > "$WORK/dangling-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/dangling-$fmt.log" >&2; fail "M14-AC1: dangling-xref.qmd failed to render to $fmt"; }
  quarto render examples/resolving-xref.qmd --to $fmt \
    > "$WORK/resolving-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/resolving-$fmt.log" >&2; fail "M14-AC2: resolving-xref.qmd failed to render to $fmt"; }
done

# M14-AC1 — the criterion shape: the document indexes `Cats`, a mark points at
# `Felines`, which nothing indexes, and exactly one report names it.
for fmt in latex html gfm; do
  check_warning_count "$WORK/dangling-$fmt.log" \
    "$(dangling_report see 'entry="Lions"' Felines document)" 1 "M14-AC1 ($fmt)"
done
pass "M14-AC1: a target naming a term the document does not index draws exactly one report, naming it, in LaTeX, HTML and gfm"

# M14-AC3 — one row per shape, each with the count it must draw. `Lynxes` is
# written on two marks and draws two reports, which is what says the rule is
# per mark per target rather than per distinct target. The rows are checked
# against the log AND their total against the log's whole count of the report,
# so a shape the filter reports that the manifest does not name fails too.
read -r -d '' DANGLING_SHAPES <<'MANIFEST' || true
1	see-also	entry="Pumas"	Ocelots
1	see	entry="Jaguars"	Servals
1	see	entry="Caracals"	Wild!Cats!Small
1	see	entry="Margays"	Cats!Kittens
1	see	entry="Ocelots Marked"	Lynxes
1	see	entry="Bobcats"	Lynxes
MANIFEST

# Seeded with AC1's own report — the `Felines` shape asserted above, which is
# not one of the rows below — so that the total this loop builds is the whole
# of what the fixture may report (review F13).
DANGLING_TOTAL=1
while IFS=$'\t' read -r want attr context target; do
  [ -n "${want:-}" ] || continue
  DANGLING_TOTAL=$((DANGLING_TOTAL + want))
  for fmt in latex html gfm; do
    check_warning_count "$WORK/dangling-$fmt.log" \
      "$(dangling_report "$attr" "$context" "$target" document)" "$want" \
      "M14-AC3 ($fmt)"
  done
done <<< "$DANGLING_SHAPES"

for fmt in latex html gfm; do
  check_warning_count "$WORK/dangling-$fmt.log" "$WARN_DANGLING" \
    "$DANGLING_TOTAL" "M14-AC3 (total, $fmt)"
  # The resolving halves of the two both-attribute marks. Both name `Cats`,
  # which the fixture indexes, so no report may name it — the trailing comma
  # keeps this from matching the `Cats!Kittens` report, which is a different
  # target and must still be drawn.
  if grep -F -- "$WARN_DANGLING" "$WORK/dangling-$fmt.log" \
     | grep -qF 'points at "Cats",'; then
    grep -F -- "$WARN_DANGLING" "$WORK/dangling-$fmt.log" >&2
    fail "M14-AC3 ($fmt): a report names \`Cats\`, which the fixture indexes; the resolving half of a both-attribute mark must draw none"
  fi
done
pass "M14-AC3: each of the six further shapes draws exactly its own count in all three formats, those counts are the whole of what the fixture reports, and the resolving target appears in no report line"

# M14-AC2 — the twin: every target resolves, so the report is silent. An exact
# zero over each of the three formats, which is the half that says the rule
# resolves rather than merely fires.
for fmt in latex html gfm; do
  check_warning_count "$WORK/resolving-$fmt.log" "$WARN_DANGLING" 0 \
    "M14-AC2 ($fmt)"
done
pass "M14-AC2: a fixture whose every target resolves — an exact single-level match, a full multi-level path, and a level that exists only as a parent — draws no report in any of the three formats"

# The milestone-local decision on what makes a target resolve says the report
# and the HTML back-end's own walk (`lookup_entry`) must agree, and that they
# cannot share code: the entry tree exists in one format only. The agreement
# is asserted here instead. In the HTML index a target is a link exactly when
# the walk found its entry, so the set of unlinked targets must be exactly the
# set of targets the report named.
python3 - "$WORK/dangling-html.log" examples/dangling-xref.html \
         "$WORK/resolving-html.log" examples/resolving-xref.html <<'PY'
import re, sys
sys.path.insert(0, 'tests')
import htmlindex as H

# The report writes a target the way the author typed it (`!` separating
# levels, `!!` a literal one); the HTML index prints it the way a reader reads
# it. Converted here rather than compared loosely, so a target whose own text
# contains a level separator cannot be read as a deeper path.
def printed(target):
    parts, current, i = [], [], 0
    while i < len(target):
        if target[i] == '!':
            if target[i + 1:i + 2] == '!':
                current.append('!')
                i += 2
                continue
            parts.append(''.join(current))
            current = []
            i += 1
            continue
        current.append(target[i])
        i += 1
    parts.append(''.join(current))
    return ': '.join(parts)


REPORTED = re.compile(r'points at "(.*?)", which no index mark in this')
errs = []
for log, page, label in ((sys.argv[1], sys.argv[2], 'dangling'),
                         (sys.argv[3], sys.argv[4], 'resolving')):
    text = open(log, encoding='utf-8', errors='replace').read()
    reported = sorted({printed(m.group(1)) for m in REPORTED.finditer(text)})
    records = H.entry_records(H.index_section(H.parse(page)))
    targets = [(target, linked)
               for r in records for _kind, target, linked, _href in r['xrefs']]
    if not targets:
        errs.append(f'{label}: the rendered index carries no cross-reference '
                    f'at all, so this check compares nothing')
        continue
    unlinked = sorted({target for target, linked in targets if not linked})
    if unlinked != reported:
        errs.append(f'{label}: the index leaves {unlinked} unlinked while the '
                    f'report names {reported}')
if errs:
    print('FAIL: M14 (resolution rule): ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M14: in both fixtures the targets the HTML index leaves unlinked '
      'are exactly the targets the format-neutral report names, so the report '
      'and the HTML entry walk agree without sharing code')
PY

# M14-AC4 — a target dropped as a format-neutral self-reference draws its own
# report and not this one. Asserted over the six marks whose target names the
# entry they are written on, by their context strings: no report line names
# any of them. The three fold-induced shapes are the other half — they DO
# dangle format-neutrally, since the path they name is one the author never
# indexed, so their counts are pinned nonzero rather than zeroed.
for fmt in latex html gfm; do
  for context in 'entry="Cats"' 'entry="Birds!Owls"' 'term "ferrets"' \
                 'entry="Dogs"' 'entry="Moles!"' 'entry="P!Q!R!"'; do
    if grep -F -- "$WARN_DANGLING" "$WORK/self-xref-$fmt.log" \
       | grep -qF "on $context points at"; then
      fail "M14-AC4 ($fmt): the mark $context had its target dropped as a self-reference and is reported as dangling as well"
    fi
  done
  # Their existing reports are still there — without this the clause above
  # would pass on a filter that had stopped reporting self-references at all.
  check_warning_count "$WORK/self-xref-$fmt.log" "$WARN_SELF_XREF" 6 "M14-AC4 ($fmt)"
  # M18-AC2 supersedes the last clause of M14-AC4, for the LaTeX back-end
  # alone (D-005). These three targets name the path the fold makes the entry
  # PRINT, so in LaTeX they now resolve — against printed paths — and the fold
  # reports them as self-references and nothing else. HTML and gfm fold
  # nothing, so there the same targets name a path no mark writes and the
  # format-neutral report stands exactly as M14 pinned it. Before M18 the
  # LaTeX render drew BOTH reports for each of the three: one saying the fold
  # had made the target a self-reference and dropped it, the other telling the
  # author to go mark the term or correct the target.
  if [ "$fmt" = latex ]; then want_fold_dangling=0; else want_fold_dangling=1; fi
  for context in 'entry="A!B!C!D"' 'entry="F!G!H!I!J"' 'entry="M!N!O!P"'; do
    check_warning_count "$WORK/self-xref-$fmt.log" \
      "on $context points at" "$want_fold_dangling" "M14-AC4/M18-AC2 (fold shape, $fmt)"
  done
  check_warning_count "$WORK/self-xref-$fmt.log" "$WARN_DANGLING" \
    "$((want_fold_dangling * 3))" "M14-AC4/M18-AC2 (total, $fmt)"
  # The fold's own report is untouched in every format, which is what tells
  # the repair from a filter that simply stopped judging folded targets.
  check_warning_count "$WORK/self-xref-$fmt.log" "$WARN_FOLD_SELF" \
    "$([ "$fmt" = latex ] && echo 3 || echo 0)" "M18-AC2 (fold self, $fmt)"
done
pass "M14-AC4/M18-AC2: none of the six self-referential targets is also reported as dangling, all six keep their own report, and the three fold-induced targets draw one report in LaTeX where they now resolve against printed paths and the format-neutral one in HTML and gfm, which fold nothing"

# M14-AC5, the ordering fixture's half. The marker sits in the FIRST chapter,
# which is also where the index is built; `Early Reference` there points at
# `Late`, marked in the second chapter, and must draw nothing. It is the
# discriminating shape: a report drawn by the chapter that builds the index
# would call that target broken, on both renders. `Missing Reference` names a
# term no chapter marks and is reported once per whole-book render — once, not
# once per chapter, which is only reachable if a single chapter draws it.
# The book form names the chapter as well as the mark (review F3): in a book
# the mark's own naming string is not somewhere an author can go.
ORDER_DANGLING="$(dangling_report see 'entry="Missing Reference" in later chapter.qmd' 'Nowhere At All' book)"
for pass_log in 1 2; do
  check_warning_count "$WORK/book-order-$pass_log.log" "$ORDER_DANGLING" 1 \
    "M14-AC5 (render $pass_log)"
  check_warning_count "$WORK/book-order-$pass_log.log" "$WARN_DANGLING" 1 \
    "M14-AC5 (total, render $pass_log)"
done
pass "M14-AC5: in a book whose marker sits first, a target another chapter indexes draws nothing on either render, and the one target no chapter indexes is reported exactly once per whole-book render"

# ---------------------------------------------------------------------------
# The corpus reconciliation the report forces. Every example that writes a
# cross-reference target now has an expected report count, and which examples
# those are is derived by grepping the corpus rather than written down: a new
# fixture carrying a target cannot slip past this by not being on a list.
#
# The counts are pinned rather than computed. A routine that re-derived them
# would be a second implementation of the same resolution rule and could agree
# with the filter by sharing its bug; a number that has to be changed by hand
# cannot.
#
# ORACLE RULE, as for every other manifest here: each count is DERIVED from
# the .qmd source and the documented semantics, never read off a render
# (review F5). The derivations, one per nonzero row and one per row whose zero
# is not simply "no targets":
#
#   xref-escaping  272 target attributes, of which one is written `see=""`
#                  and is dropped with "has no usable target text" before any
#                  target exists to resolve. The other 271 name level paths
#                  built by construction from the printable ASCII range
#                  (`L1!x!L3` and its rotations); the file indexes only its
#                  visible probe labels (`x00`, `a00`, ...), so none resolves.
#                  271.
#   demo           8 attributes (Felines, Pets, Birds!Owls, Wow!!Hey, Vulpes,
#                  Spirits, Aye, Bee). The file's entries are its visible terms
#                  plus `Canids!Foxes`, `Ghosts`, `Wow!!Really`, `Top!Middle!
#                  Leaf` and the escaping entries; no target is among them, and
#                  `Wow!!Hey` parses to the single level `Wow!Hey`, which
#                  `Wow!!Really` does not spell. 8.
#   dangling-xref  9 attributes, of which 2 name `Cats`, which the file
#                  indexes. 7.
#   xref-conflict  15 attributes after M15 extended it. Only
#                  `see="Note!on birds"` names an entry the file marks;
#                  `see="Note: on birds"` is a single level that merely prints
#                  the same way (the M02 shape), and the other thirteen name
#                  nothing. 14.
#   html-index     5 attributes: `see="A!B"` four times, which names the file's
#                  one entry, and `see="A: B"` once, which does not. 1.
#   fold-xref      7 attributes. Judged here on the levels the author wrote,
#                  since gfm folds nothing: `Ash!Bay!Cod!Dun` twice and
#                  `Fir!Gum!Ha!Iv!J!!t`, `Lime!Moss!Nut!Orb`, `Elm` and
#                  `Ash!Bay` once each all name a path this file marks or a
#                  parent of one; only `Sil!Tea!Urn!Vin` names nothing. 1.
#   fold-xref-both 2 attributes on one mark, both naming entries the file
#                  marks at overflow depth. 0.
#   fold-xref-self 1 attribute, `Bri!Cal!Del!Emu`, against an entry written
#                  `Bri!Cal!Del, Emu`. The two are one path only after the
#                  LaTeX fold, and gfm folds nothing, so here it names
#                  nothing. 1.
#   self-xref      11 attributes. 6 name the entry they are written on and are
#                  dropped as self-references; 2 name `Cats`, which the file
#                  indexes; the remaining 3 name the path the LaTeX fold makes
#                  the entry print, which no mark writes as an entry. 3.
#   book/sub/two   2 attributes: `see="Alpha"`, contributed by index.qmd, and
#                  `see="No Such Entry"`, contributed by no chapter. 1.
#   book-order     `index.qmd` points at `Late`, marked in the second chapter:
#                  0. `later chapter.qmd` points at `Nowhere At All`, marked
#                  nowhere: 1.
#   content        2 attributes, both on marks with no source entry at all —
#                  an image mark and an empty one — so neither is indexed and
#                  neither target is ever resolved. 0.
#   empty-levels   1 attribute: `entry="!Owls"` drops its empty level to
#                  `Owls`, which `see="Owls"` then names, so it is dropped as a
#                  self-reference. 0.
#   fold-xref-empty  5 attributes. Every one names a path some mark in the
#                  file indexes, judged as written in a format with no
#                  ceiling, so none dangles anywhere. 0.
#   placement      1 attribute: `see="widget"`, and `widget` is marked three
#                  times in that file. 0.
#   principal      2 attributes, both `see="basilisk"` — one on the mark whose
#                  role is dropped for carrying a cross-reference, one on the
#                  cross-reference mark of the contested `gorgon` key. The file
#                  marks `basilisk` three times, so both resolve. 0.
#   principal-twin the same two attributes: the twin removes role attributes
#                  and nothing else, so its target set is identical. 0.
#   principal-cases  1 attribute, on the mark whose entry the LaTeX three-level
#                  fold rewrites to exactly what the target names. This corpus
#                  renders to gfm, which has no ceiling and so no fold, and
#                  there the target names a path nothing indexes and dangles —
#                  the back-end asymmetry D-005 settles, and the reason that
#                  mark is in the fixture at all. 1.
#   range          1 attribute: `see="centaur"` on the cross-reference mark of the
#                  contested `dybbuk` key. The file marks `centaur` twice, so it
#                  resolves. 0.
#   range-misuse   1 attribute: `see="golem"` on the mark whose range is dropped
#                  for carrying it. `golem` is marked in that file — as a closing
#                  with no opening, which indexes as an ordinary locator — so the
#                  target resolves. 0.
#   resolving-xref 3 attributes, all three resolving by construction. 0.
#
# Reconciling xref-escaping's corpus so its targets resolve is its own piece of
# work and is a ROADMAP candidate; this milestone pins what it reports.
# ---------------------------------------------------------------------------
read -r -d '' DANGLING_CORPUS <<'MANIFEST' || true
examples/book-order/index.qmd	0
examples/book-order/later chapter.qmd	1
examples/book/sub/two.qmd	1
examples/content.qmd	0
examples/dangling-xref.qmd	7
examples/demo.qmd	8
examples/empty-levels.qmd	0
examples/fold-xref-both.qmd	0
examples/fold-xref-empty.qmd	0
examples/fold-xref-self.qmd	1
examples/fold-xref.qmd	1
examples/html-index.qmd	1
examples/placement.qmd	0
examples/principal-cases.qmd	1
examples/principal-twin.qmd	0
examples/principal.qmd	0
examples/range-misuse.qmd	0
examples/range.qmd	0
examples/resolving-xref.qmd	0
examples/self-xref.qmd	3
examples/xref-conflict.qmd	14
examples/xref-escaping.qmd	271
MANIFEST

printf '%s\n' "$DANGLING_CORPUS" > "$WORK/dangling-corpus.txt"
# The roster, from the corpus itself. The attribute is matched after
# whitespace, so `notsee="..."` and a bare prose mention of the name do not put
# a file on the roster (review F11). Build output is pruned rather than trusted
# not to hold a copy of a source file, and the whole recursive grep is one
# command with its no-match exit absorbed: piping `find` into `xargs grep` dies
# under `pipefail` with no FAIL line at all when a batch matches nothing
# (review F10). An empty roster cannot pass silently — the diff below fails on
# it.
{ grep -rlE --include='*.qmd' '[[:space:]](see|see-also)="' examples || true; } \
  | grep -v '/_book/\|/\.quarto/' \
  | LC_ALL=C sort > "$WORK/dangling-roster.txt"
cut -f1 "$WORK/dangling-corpus.txt" | LC_ALL=C sort > "$WORK/dangling-listed.txt"
if ! diff -u "$WORK/dangling-roster.txt" "$WORK/dangling-listed.txt" >&2; then
  fail "M14: the examples that write a cross-reference target are not the examples the count manifest lists (- carries targets and has no count; + is listed and carries none)"
fi
pass "M14: every example writing a cross-reference target carries an expected report count, and the roster is read out of the corpus rather than written down"

# Each single-document example, rendered to gfm — the format with no index
# back-end at all, so a count that holds here is a count the report owes to
# what the author wrote rather than to a back-end that happened to run.
BOOK_EXPECTED_TOTAL=0
while IFS=$'\t' read -r file want; do
  [ -n "${file:-}" ] || continue
  case "$file" in
    examples/book*)
      BOOK_EXPECTED_TOTAL=$((BOOK_EXPECTED_TOTAL + want))
      continue
      ;;
  esac
  quarto render "$file" --to gfm > "$WORK/corpus-$(basename "$file" .qmd).log" 2>&1 \
    || { tail -20 "$WORK/corpus-$(basename "$file" .qmd).log" >&2; fail "M14: $file failed to render to gfm"; }
  check_warning_count "$WORK/corpus-$(basename "$file" .qmd).log" \
    "$WARN_DANGLING" "$want" "M14 (corpus, $file)"
done <<< "$DANGLING_CORPUS"

# The book chapters' rows are per chapter, but the report is drawn once for
# the whole book, so what they must add up to is what each book render emits.
# Two books carry targets and each reports one, which is what the sum states.
[ "$BOOK_EXPECTED_TOTAL" = "2" ] \
  || fail "M14: the book chapters' expected counts total $BOOK_EXPECTED_TOTAL, but the two book fixtures report one each"
check_warning_count "$WORK/book-html.log" "$WARN_DANGLING" 1 "M14 (corpus, examples/book)"
check_warning_count "$WORK/book-order-2.log" "$WARN_DANGLING" 1 "M14 (corpus, examples/book-order)"
pass "M14: every example's dangling-target report count matches its pinned expectation, in a format with no index back-end, and the book chapters' counts add up to what their books report"

# The fold fixtures render here, ahead of M15's residue sweep: one of them has
# a contested key, so that sweep needs its artifact, and reading a copy taken
# now is what keeps the sweep off whatever an earlier run happened to leave in
# examples/. The PDF render further down removes the intermediate .tex (M15).
for f in fold-xref fold-xref-both fold-xref-self fold-xref-empty; do
  for fmt in latex html gfm; do
    quarto render "examples/$f.qmd" --to $fmt > "$WORK/$f-$fmt.log" 2>&1 \
      || { tail -20 "$WORK/$f-$fmt.log" >&2; fail "M18: examples/$f.qmd failed to render to $fmt"; }
  done
  cp "examples/$f.tex" "$WORK/$f-latex.tex"
done

# ---------------------------------------------------------------------------
# M15 — a term marked both plainly and with a cross-reference builds.
#
# The fixture holds every way two marks can contest one index key. Before this
# milestone the render below exited 1: makeindex rejected the rival
# encapsulations with "Conflicting entries: multiple encaps for the same page
# under same key" and Quarto turned that into "error generating index". The
# repair is not to detect a toolchain failure but to stop emitting output the
# tool cannot process (D-003), so the evidence is the build itself.
# ---------------------------------------------------------------------------
CONFLICT_FAIL_A='Conflicting entries: multiple encaps for the same page under same key'
CONFLICT_FAIL_B='error generating index'

quarto render examples/xref-conflict.qmd --to pdf \
  > "$WORK/conflict-pdf.log" 2>&1 \
  || { tail -30 "$WORK/conflict-pdf.log" >&2; fail "M15-AC1: xref-conflict.qmd failed to render to PDF; a term marked both ways must build"; }
[ -s examples/xref-conflict.pdf ] || fail "M15-AC1: examples/xref-conflict.pdf is empty"
check_warning_count "$WORK/conflict-pdf.log" "$CONFLICT_FAIL_A" 0 "M15-AC1"
check_warning_count "$WORK/conflict-pdf.log" "$CONFLICT_FAIL_B" 0 "M15-AC1"
pass "M15-AC1: the fixture that could not build now renders to PDF, with neither the index tool's rejection nor Quarto's error"

# M15-AC2/AC3 — the compiled index, every printed line of it. Quantified over
# ALL entries rather than over the contested ones: an entry that keeps a
# cross-reference prints the target too, so a check naming entries by their
# printed term goes vacuous under exactly the regression it guards (the M10
# lesson). Rows are `<level><TAB><term><TAB><locator count>`, derived by hand
# from examples/xref-conflict.qmd and the documented semantics:
#
#   chi        plain mark + a cross-reference whose target carries all sixteen
#              escaped characters. Contested WITH a plain mark, so the target
#              folds into the printed text and the plain mark's page stands: 1.
#              Its line wraps, and its locator lands alone on the continuation.
#   Deep       a parent no mark writes as an entry of its own: 0.
#   Level      the contested sub-entry, folded like chi, one plain mark: 1.
#   kappa      two plain marks on two pages, cross-reference mark on a third.
#              2, not 3, is what says the cross-reference contributed none.
#   lambda     see= against see-also=, no plain mark: the targets stay in the
#              encapsulation channel and the entry has no locator: 0.
#   mu         two IDENTICAL cross-references, which the tool folds by itself.
#              Uncontested, untouched, no locator: 0.
#   Note       a parent, as Deep: 0.  on birds  its sub-entry, one mark: 1.
#   nu         marked plainly twice on one page, which merges to one locator: 1.
#   phi        a both-attributes mark against a plain mark, folded: 1.
#   rho/sigma  single uncontested cross-references, untouched: 0 each.
#   tau        plain against see-also=, folded: 1.
#   Tree       a parent, as Deep: 0.  Branch  its parent sub-entry: 0.
#   Cedar, …   the contested key written FOUR levels deep: the back-end folds
#              `Cedar!Dogwood` into one third level, and the fold appends its
#              cross-reference to the printed text as it does for chi. One
#              plain mark: 1. It files under `Cedar, Dogwood` — the text it
#              prints before the fold — which is what puts it ahead of the
#              uncontested twin below rather than under `Cedar` alone.
#   Maple, …   that twin: the same depth and the same shape of sort key, with
#              no cross-reference to contest the key. One plain mark: 1.
#   upsilon    two DIFFERENT see= targets, no plain mark, as lambda: 0.
#
# Printed in collation order with each sub-entry under its parent, which is the
# order pdfindex reconstructs, so a column break cannot reorder these rows.
read -r -d '' CONFLICT_PDF_INDEX <<'MANIFEST' || true
0	chi, see % & # _ { } \ ~ ^ $ @ | ! " < >	1
0	Deep	0
1	Level, see Shallow	1
0	kappa, see Elsewhere	2
0	lambda, see Here; see also There	0
0	mu, see Same	0
0	Note	0
1	on birds	1
0	nu	1
0	phi, see Aye Two; see also Bee Two	1
0	rho, see Note: on birds	0
0	sigma, see Note: on birds	0
0	tau, see also Elsewhere Again	1
0	Tree	0
1	Branch	0
2	Cedar, Dogwood, see Afar	1
2	Maple, Holly	1
0	upsilon, see One Way; see Another Way	0
MANIFEST

printf '%s\n' "$CONFLICT_PDF_INDEX" > "$WORK/conflict-index.txt"
python3 - examples/xref-conflict.pdf "$WORK/conflict-index.txt" <<'CONFLICTPDFPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

entries = pdfindex.read(sys.argv[1])
if not pdfindex.columns_carry_top_level(entries):
    print('FAIL: M15-AC2: a column holds no top-level entry, so its indent '
          'reads a level too shallow', file=sys.stderr)
    sys.exit(1)


def locators(entry):
    """How many locators the entry prints, from the tail `term` strips.

    Comma-separated groups, so a page RANGE counts as the one locator it
    prints: makeindex collapses three or more consecutive pages into `1--3`,
    and counting the pages behind a range would make this number depend on
    where the fixture's page breaks fall rather than on how many marks the
    author wrote. No row below reaches a range today.
    """
    tail = entry.text[len(entry.term):].lstrip(', ').strip()
    return len([part for part in tail.split(',') if part.strip()])


got = [f'{e.level}\t{e.term}\t{locators(e)}' for e in entries]
want = [l.rstrip('\n') for l in open(sys.argv[2], encoding='utf-8') if l.strip()]
if got != want:
    print('FAIL: M15-AC2/AC3: the compiled index does not match the manifest',
          file=sys.stderr)
    for i in range(max(len(got), len(want))):
        g = got[i] if i < len(got) else '<no such row printed>'
        w = want[i] if i < len(want) else '<not in the manifest>'
        if g != w:
            print(f'  row {i + 1}:\n    expected <<{w}>>\n    got      <<{g}>>',
                  file=sys.stderr)
    sys.exit(1)

# M15-AC3: each contested term prints as ONE entry. The repair merges the marks
# the index tool would otherwise have stored twice, and a count of entries
# whose term begins with the contested term is what says they merged.
CONTESTED = ('chi', 'Level', 'kappa', 'lambda', 'phi', 'tau', 'upsilon',
             'Cedar, Dogwood')
errs = []
for term in CONTESTED:
    # "begins with the contested term" — the term itself, or the term with a
    # folded cross-reference behind it. Split on the first comma would read
    # `Cedar, Dogwood` as `Cedar` and count an entry that is not the one the
    # criterion names.
    n = len([e for e in entries
             if e.term == term or e.term.startswith(term + ',')])
    if n != 1:
        errs.append(f'{term!r} prints as {n} entries, expected 1')
if errs:
    print('FAIL: M15-AC3: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)

# M15-AC4: the folded target sits in the entry's PRINTED field, where the index
# tool reads `!`, `@`, `|` and `"` as its own operators just as it does in the
# encapsulation channel. Every character README pins as escaped must survive
# into the typeset index — the bar examples/xref-escaping.qmd already holds the
# encapsulation channel to (IP2).
ESCAPED = '% & # _ { } \\ ~ ^ $ @ | ! " < >'
folded = [e for e in entries if e.term.startswith('chi,')]
if len(folded) != 1:
    print(f'FAIL: M15-AC4: expected one folded escaping entry, found '
          f'{len(folded)}', file=sys.stderr)
    sys.exit(1)
missing = [c for c in ESCAPED.split(' ') if c not in folded[0].term]
if missing:
    print(f'FAIL: M15-AC4: the folded cross-reference target is missing '
          f'{missing} in the typeset index: <<{folded[0].term}>>',
          file=sys.stderr)
    sys.exit(1)
print(f'ok   M15-AC2/AC3/AC4: all {len(want)} printed index lines match the '
      f'manifest, each of the {len(CONTESTED)} contested terms prints as one '
      f'entry, and all {len(ESCAPED.split(" "))} escaped characters typeset in '
      f'the folded target')
CONFLICTPDFPY
pass "M15-AC2/AC3/AC4: the compiled index matches the exhaustive manifest, every contested key prints once, and the folded target typesets whole"

# M15 (defect return 1) — contesting a key must not MOVE the entry. The folded
# printed text forces a sort field onto the last level, and forcing the
# declared key there would file a folded entry under the third level's own key
# while the same entry uncontested files under the joined text it prints. The
# fixture holds the pair: `Tree!Branch!Cedar!Dogwood`, contested, against
# `Tree!Branch!Maple!Holly`, not contested, both four levels deep and both
# carrying a sort key whose third level merely repeats that level's text — a
# key that declares nothing, so both must file under the text they print.
# Read from the emitted argument, which is the only place the filing key is
# visible: the printed index shows the order, not the string that produced it.
python3 - "$WORK/conflict-latex.tex" <<'M15FILINGPY'
import re, sys

src = open(sys.argv[1], encoding='utf-8').read()


def arguments(text):
    """Every `\index{...}` argument, brace-balanced.

    A folded argument carries `\see{...}`, so the first `}` is not the end of
    the command.
    """
    for m in re.finditer(r'\\index\{', text):
        depth, i = 1, m.end()
        while i < len(text) and depth:
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
            i += 1
        yield text[m.end():i - 1]


def filing(argument):
    """The key each level files under, from what was emitted.

    Levels split on makeindex's unquoted `!`; within a level, an unquoted `@`
    separates the sort field from the printed text, and a level with no `@`
    files under the text it prints. Neither entry read here carries an
    author-written `!` or `@`, which would arrive quoted as `"!` / `"@`.
    """
    keys = []
    for level in re.split(r'(?<!")!', argument):
        keys.append(re.split(r'(?<!")@', level, maxsplit=1)[0])
    return keys


# Derived by hand from the fixture: level 3 is the fold of `Cedar!Dogwood`,
# joined the way the back-end joins an overflow, and the entry files under
# exactly that. The contested one is the SAME string it would be without the
# cross-reference — that is the claim.
WANT = {
    'contested': ['tree', 'branch', 'Cedar, Dogwood'],
    'twin': ['tree', 'branch', 'Maple, Holly'],
}
got = {}
for argument in arguments(src):
    if argument.startswith('tree@Tree!branch@Branch!Cedar'):
        got['contested'] = filing(argument)
        if '\\see{Afar}' not in argument:
            print('FAIL: M15: the deep entry read as contested carries no '
                  f'folded cross-reference: <<{argument}>>', file=sys.stderr)
            sys.exit(1)
    elif argument.startswith('tree@Tree!branch@Branch!Maple'):
        got['twin'] = filing(argument)
        if '\\see' in argument:
            print('FAIL: M15: the uncontested twin carries a cross-reference, '
                  f'so it is no control: <<{argument}>>', file=sys.stderr)
            sys.exit(1)

missing = [name for name in WANT if name not in got]
if missing:
    print(f'FAIL: M15: no emitted argument for {missing} in '
          f'{sys.argv[1]}; the deep contested probe is not in the fixture',
          file=sys.stderr)
    sys.exit(1)
bad = [f'  {name}: expected {WANT[name]}, got {got[name]}'
       for name in sorted(WANT) if got[name] != WANT[name]]
if bad:
    print('FAIL: M15: a contested entry deeper than the back-end stores does '
          'not file where the same entry files uncontested:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print('ok   M15: the four-level contested entry files under the text it '
      'prints, exactly as its uncontested twin does')
M15FILINGPY
pass "M15: contesting a key changes what the entry prints and not where it files, at the depth where the two could differ"

# M15-AC5 — no report claims a build can fail from rival encapsulations, since
# the emission no longer risks one. Read over each warn() call's JOINED
# message, never over a raw scan of the file: the old message was built from
# three literals joined with `..`, so the phrase existed at run time and in no
# single literal — a scan of the source reports it absent against the filter
# that still emits it, and passes for the wrong reason (the M13 lesson). The
# joined message is what an author reads, so the joined message is what is
# read here.
run_scan m15-joined-messages

# The other half of AC5: the replacement report's FULL text, once per contested
# key, over the fixture. The keys are the entry paths the report names — what
# the author wrote, after the back-end's three-level fold — derived by hand
# from examples/xref-conflict.qmd, not read back out of the log.
# Rows are `<shape>\t<entry path>`: `plain` where some mark of the entry is a
# plain locator mark, `xrefs` where none is. The shape decides which of the two
# reports the entry must draw, and telling an `xrefs` entry it prints page
# numbers would be telling the author something the index does not do.
read -r -d '' CONFLICT_REPORTED <<'MANIFEST' || true
plain	Deep!Level
plain	Tree!Branch!Cedar, Dogwood
plain	chi
plain	kappa
plain	phi
plain	tau
xrefs	lambda
xrefs	upsilon
MANIFEST
printf '%s\n' "$CONFLICT_REPORTED" > "$WORK/conflict-reported.txt"
python3 - "$WORK/conflict-latex.log" "$WORK/conflict-reported.txt" <<'M15REPORTPY'
import sys

TEMPLATE = {
    'plain': ('index entry {} carries both a plain locator and a '
              'cross-reference; they are printed as one entry with its page '
              'numbers and its cross-reference together, so check that is the '
              'entry you meant'),
    'xrefs': ('index entry {} carries two different cross-references; they '
              'are printed as one entry carrying both targets and, since '
              'neither mark contributes one, no page numbers at all, so check '
              'that is the entry you meant'),
}

log = open(sys.argv[1], encoding='utf-8').read()
rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[2], encoding='utf-8') if l.strip()]
bad = []
for shape, key in rows:
    n = log.count(TEMPLATE[shape].format(key))
    if n != 1:
        bad.append(f'  {key!r}: the full {shape} report appears {n} times, '
                   f'expected 1')
    # And not the OTHER shape's report, which would tell this author the
    # opposite about their page numbers.
    other = 'xrefs' if shape == 'plain' else 'plain'
    m = log.count(TEMPLATE[other].format(key))
    if m:
        bad.append(f'  {key!r}: also drew the {other} report {m} time(s), '
                   f'which contradicts the {shape} one')
# A key the fixture does NOT contest would not be seen by a count per key;
# the exact count of this report over the same log, asserted above with the
# other clash counts, is what fences that direction.
if bad:
    print('FAIL: M15-AC5: the replacement report is not drawn once per '
          'contested key over examples/xref-conflict.qmd:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M15-AC5: the replacement report is drawn in full, exactly once '
      f'and in the shape the entry has, for each of the {len(rows)} contested '
      f'entries the fixture writes')
M15REPORTPY
pass "M15-AC5: no joined filter message claims a failed render, and the report that replaced it is drawn in full once per contested entry"

# The uncontested half: the folded form and the list command appear in the
# emission of the fixtures that have a contested key and nowhere else. The
# files are discovered by glob over what the run rendered; what each is
# expected to carry is a mapping, and the comparison is EQUALITY per file, so
# a fixture that silently stops carrying its shape fails exactly as one that
# gains a shape it should not have (M16's vacuity mode).
CONFLICT_TEX="$WORK/conflict-latex.tex" FOLD_TEX="$WORK/fold-xref-latex.tex" \
python3 - <<'M15UNTOUCHEDPY'
import glob, os, re, sys
# BOTH repairs, or the sweep fences only half of what the milestone changed:
# the list command comes from the no-plain branch, and the folded printed field
# from the other. `\see{` with a BACKSLASH is the fold's signature — an
# uncontested cross-reference travels the encapsulation channel as `|see{...}`
# with none, and the preamble's \providecommand defines no such macro.
MARKS = {
    'the combined-encapsulation command': re.compile(r'quartoindexxrefs'),
    'a cross-reference folded into the printed field':
        # `\see(?:also)?` — NOT `\seealso?`, which requires the literal
        # `seeals` and so would miss a fold that carries only `\see{`.
        re.compile(r'\\index\{[^\n]*\\see(?:also)?\{'),
}


def carried(path):
    src = open(path, encoding='utf-8').read()
    return [name for name, mark in MARKS.items() if mark.search(src)]


# Both directions, or the check would pass on a filter that emitted neither
# mark anywhere at all. The contested fixture's own artifact is read from the
# copy kept before the PDF render removed it — a glob over examples/*.tex
# cannot see it at this point, so the basename it would have matched is absent.
missing = [name for name in MARKS if name not in carried(os.environ['CONFLICT_TEX'])]
if missing:
    print(f'FAIL: M15: the fixture that HAS contested keys of both shapes '
          f'emitted no {missing}, so the sweep below proves nothing',
          file=sys.stderr)
    sys.exit(1)
# The second fixture with a contested key, read from its own copy for the same
# reason — it writes the folded printed field and no no-plain contest, so it
# carries one of the two shapes and must carry it (M18).
FOLD_ONLY = 'a cross-reference folded into the printed field'
if carried(os.environ['FOLD_TEX']) != [FOLD_ONLY]:
    print(f'FAIL: M15: examples/fold-xref.qmd has a contested key of the '
          f'folded-field shape and only that shape, but its emission carries '
          f'{carried(os.environ["FOLD_TEX"])}', file=sys.stderr)
    sys.exit(1)
# The sweep proper. Neither fixture WITH a contested key is required to be
# here — a PDF render removes the intermediate .tex, so whether one survives to
# this point is not something the sweep should depend on; both are checked
# above from copies taken at their own renders. What is required is that no
# OTHER artifact carries either shape, and that fold-xref's, if it is still on
# disk, carries only the shape it writes.
# M20's two fixtures each mark `gorgon` with a plain locator mark and a
# cross-reference mark, which is a contested key of the folded-field shape, so
# each carries that shape and only it. Listed for the same reason fold-xref is
# — the sweep tolerates their absence, since whichever render ran last decides
# whether the intermediate .tex is still on disk.
ALLOWED = {'examples/fold-xref.tex': {FOLD_ONLY},
           'examples/principal.tex': {FOLD_ONLY},
           'examples/principal-twin.tex': {FOLD_ONLY}}
wrong = []
for path in sorted(glob.glob('examples/*.tex')):
    want = ALLOWED.get(path, set())
    got = set(carried(path))
    if got != want:
        wrong.append((path, sorted(want), sorted(got)))
if wrong:
    print(f'FAIL: M15: the contested-key emission is not where it should be '
          f'(path, expected, found): {wrong}', file=sys.stderr)
    sys.exit(1)
print(f'ok   M15: the contested-key fixture carries both shapes of the '
      f'contested-key emission, the one other fixture with a contested key '
      f'carries exactly the shape it writes, and none of the '
      f'{len(glob.glob("examples/*.tex"))} rendered LaTeX artifacts carries '
      f'anything else')
M15UNTOUCHEDPY
pass "M15-AC5: the failed-render claim is gone from the filter, and the contested-key emission reaches only the fixture that has one"

# ---------------------------------------------------------------------------
# M18 — a cross-reference target is judged against the path the entry prints.
#
# The LaTeX back-end folds everything past the third level into the third, and
# from this milestone it folds a TARGET by the same rule and resolves targets
# against the paths entries print (D-005). Before it, one target could draw two
# reports that contradicted each other — the fold saying it had made the target
# a self-reference and dropped it, the format-neutral report saying it named
# nothing indexed and telling the author to go correct it — and a target naming
# a path the fold had rewritten drew nothing at all while pointing at a path no
# printed entry carried.
# ---------------------------------------------------------------------------

# M18-AC1 — every emitted \index command of both fixtures, argument for
# argument, and the level-by-level agreement between a folded target and the
# entry it names.
FOLD_TEX_A="$WORK/fold-xref-latex.tex" FOLD_TEX_B="$WORK/fold-xref-both-latex.tex" \
python3 - <<'M18TEXPY'
import os, re, sys

# One row per EMITTED command, in emitted order. Compared as a whole list, so a
# command the manifest omits fails rather than passing unseen. Derived by hand
# from the fixtures and the documented semantics — the back-end stores three
# levels and folds the rest into the third with ", ", a level with a sort key
# is written `key@printed`, and a contested key's cross-reference travels in
# the entry's printed field while its own mark emits nothing:
#
#   fold-xref.qmd, mark by mark
#     ash   entry="Ash!Bay!Cod!Dun": 4 levels, so levels 3 and 4 fold into the
#           third -> Ash!Bay!Cod, Dun.
#     elm   see= names those same 4 levels, folded the same way and joined as a
#           target with ": " -> Elm|see{Ash: Bay: Cod, Dun}.
#     fir   entry="Fir!Gum!Ha!Iv!J!!t": `!!` is a literal `!`, so 5 levels
#           (Fir, Gum, Ha, Iv, J!t); levels 3-5 fold -> Fir!Gum!Ha, Iv, J"!t,
#           the `"` being makeindex's quote for a literal `!`.
#     koa   see-also= over the same 5 -> Koa|seealso{Fir: Gum: Ha, Iv, J"!t}.
#     lime  entry 4 levels with sort="zu!ya!xr!wh": the sort key clamps to three
#           and each level whose key differs from the level is written
#           `key@printed` -> zu@Lime!ya@Moss!xr@Nut, Orb.
#     pine  see= names lime's 4 written levels; a target carries no sort field,
#           so it folds to the PRINTED halves -> Pine|see{Lime: Moss: Nut, Orb}.
#     zinc  `Zinc` marked plainly and, on the next mark, with a cross-reference:
#           one contested key, so the target folds into the printed field and
#           that field takes its own text as a sort key ->
#           Zinc@Zinc, \see{Ash: Bay: Cod, Dun}{}. The cross-reference mark
#           emits nothing, which is why these two marks are ONE row.
#     reed  see-also= naming 4 levels nothing here marks: folded like any other
#           -> Reed|seealso{Sil: Tea: Urn, Vin}.
#     wax   see="Elm", one level, nothing to fold -> Wax|see{Elm}.
#     yam   see="Ash!Bay", two levels, nothing to fold -> Yam|see{Ash: Bay}.
#     10 marks, one of them emitting nothing, plus the plain zinc mark = 10 rows.
#
#   fold-xref-both.qmd, mark by mark
#     oat   entry 4 levels -> Oat!Pea!Rye, Soy.
#     tef   entry 5 levels -> Tef!Urd!Vet, Wid, Xan.
#     yuc   both attributes, so one command over both targets, each folded ->
#           Yuc|quartoindexseeboth{Oat: Pea: Rye, Soy}{Tef: Urd: Vet, Wid, Xan}.
#     3 rows.
EXPECTED = {
    'fold-xref': [
        r'Ash!Bay!Cod, Dun',
        r'Elm|see{Ash: Bay: Cod, Dun}',
        r'Fir!Gum!Ha, Iv, J"!t',
        r'Koa|seealso{Fir: Gum: Ha, Iv, J"!t}',
        r'zu@Lime!ya@Moss!xr@Nut, Orb',
        r'Pine|see{Lime: Moss: Nut, Orb}',
        r'Zinc@Zinc, \see{Ash: Bay: Cod, Dun}{}',
        r'Reed|seealso{Sil: Tea: Urn, Vin}',
        r'Wax|see{Elm}',
        r'Yak|see{Zinc}',
        r'Yam|see{Ash: Bay}',
    ],
    'fold-xref-both': [
        r'Oat!Pea!Rye, Soy',
        r'Tef!Urd!Vet, Wid, Xan',
        r'Yuc|quartoindexseeboth{Oat: Pea: Rye, Soy}{Tef: Urd: Vet, Wid, Xan}',
    ],
}
# Which entry row each fold-rewritten target names, by row index. `reed` names
# no entry either fixture marks and so has no pair; `wax` and `yam` carry
# targets the fold does not reach and are not fold-rewritten at all. The
# comparison below is what AC1's second clause asserts — the two forms use
# different separators by construction, so equality of the ARGUMENTS is not
# the claim and equality of the LEVELS is.
PAIRS = {
    # Row 9 is `Yak|see{Zinc}` against row 6, the contested key: its target
    # needs no fold, but the ENTRY it names prints a field carrying a folded
    # cross-reference of its own, which is the only thing that exercises the
    # stripper in entry_levels (review F7).
    'fold-xref': {1: [0], 3: [2], 5: [4], 6: [0], 9: [6]},
    'fold-xref-both': {2: [0, 1]},
}


def balanced(src, start):
    """The text of the group opened just before `start`, and the index past it."""
    depth, k = 1, start
    while k < len(src) and depth:
        depth += {'{': 1, '}': -1}.get(src[k], 0)
        k += 1
    return src[start:k - 1], k


def commands(src):
    out, i = [], 0
    while True:
        j = src.find('\\index{', i)
        if j < 0:
            return out
        arg, i = balanced(src, j + len('\\index{'))
        out.append(arg)


def split_unquoted(text, sep):
    """Split on `sep`, except where makeindex's `"` quotes it into the level."""
    parts, cur, prev = [], [], ''
    for c in text:
        if c == sep and prev != '"':
            parts.append(''.join(cur))
            cur = []
        else:
            cur.append(c)
        prev = c
    parts.append(''.join(cur))
    return parts


FOLDED = re.compile(r', \\see(?:also)?\{.*\}\{\}$')


def entry_levels(arg):
    """The levels an entry command PRINTS: sort fields and any folded
    cross-reference stripped, since neither is part of the path a target has to
    name."""
    levels = []
    for part in split_unquoted(arg, '!'):
        halves = split_unquoted(part, '@')
        printed = '@'.join(halves[1:]) if len(halves) > 1 else halves[0]
        levels.append(FOLDED.sub('', printed))
    return levels


def target_args(arg):
    """Every target rendered in one command, in order — the single-attribute
    encapsulation, the both-attributes command's two, and the form folded into
    a contested key's printed field."""
    out = []
    for m in re.finditer(r'(?:\||\\)(quartoindexseeboth|seealso|see)\{', arg):
        first, k = balanced(arg, m.end())
        out.append(first)
        if m.group(1) == 'quartoindexseeboth':
            second, k = balanced(arg, k + 1)
            out.append(second)
    return out


ok = True
for name, path in (('fold-xref', os.environ['FOLD_TEX_A']),
                   ('fold-xref-both', os.environ['FOLD_TEX_B'])):
    got = commands(open(path, encoding='utf-8').read())
    want = EXPECTED[name]
    if got != want:
        print(f'FAIL: M18-AC1: {name} emitted a different list of \\index '
              f'commands than the manifest holds', file=sys.stderr)
        for line in __import__('difflib').unified_diff(
                want, got, 'manifest', 'emitted', lineterm=''):
            print(f'  {line}', file=sys.stderr)
        ok = False
        continue
    # Read out of `got`, never `want`: comparing the manifest against itself
    # would make this clause an internal-consistency check on hand-written
    # strings, sound only because the equality gate above returned first
    # (review F6).
    for trow, erows in sorted(PAIRS[name].items()):
        targets = target_args(got[trow])
        if len(targets) != len(erows):
            print(f'FAIL: M18-AC1: {name} row {trow} renders {len(targets)} '
                  f'target(s), the pair map expects {len(erows)}', file=sys.stderr)
            ok = False
            continue
        for target, erow in zip(targets, erows):
            printed = entry_levels(got[erow])
            named = target.split(': ')
            if named != printed:
                print(f'FAIL: M18-AC1: {name} row {trow} names {named}, but the '
                      f'entry it points at (row {erow}) prints {printed}',
                      file=sys.stderr)
                ok = False
if not ok:
    sys.exit(1)
print('ok   M18-AC1: both fixtures emit exactly the commands their manifests '
      'hold, and every folded target names level for level what the entry it '
      'points at prints — through the single-attribute encapsulation, the '
      'both-attributes command and a contested key\'s printed field alike')
M18TEXPY
pass "M18-AC1: a target is folded as an entry is, at all three places a target is rendered, with a literal ! still quoted and a sort field still absent from what a target names"

# M18-AC3 — the dangling-target report after the change: once, for the one
# target whose FOLDED form still names no printed path, and not for the target
# that names a parent level of a folded entry. That second clause is what tells
# a prefix-closed printed-path set from one built out of whole paths alone,
# which would report `Yam` and pass everything else here.
for fmt in latex html gfm; do
  check_warning_count "$WORK/fold-xref-$fmt.log" "$WARN_DANGLING" 1 "M18-AC3 (total, $fmt)"
  check_warning_count "$WORK/fold-xref-$fmt.log" 'on entry="Reed" points at' 1 \
    "M18-AC3 (the mark, $fmt)"
  check_warning_count "$WORK/fold-xref-$fmt.log" 'on entry="Yam" points at' 0 \
    "M18-AC3 (parent-level target, $fmt)"
  check_warning_count "$WORK/fold-xref-both-$fmt.log" "$WARN_DANGLING" 0 \
    "M18-AC3 (both-attributes fixture, $fmt)"
done
# The report quotes what the AUTHOR wrote, not the folded path the lookup ran
# against: a derived string names nothing they can search their source for
# (M09). This is the clause that fails if the two spellings are collapsed.
check_warning_count "$WORK/fold-xref-latex.log" 'points at "Sil!Tea!Urn!Vin"' 1 \
  "M18-AC3 (quoted as written, latex)"
# Unchanged where nothing folds, which is the regression half of AC3.
check_warning_count "$WORK/dangling-latex.log" "$WARN_DANGLING" 7 "M18-AC3 (dangling-xref, latex)"
pass "M18-AC3: the one target that still names no printed path after folding is reported and quoted as the author wrote it, a target naming a parent level of a folded entry is not, and the fixture that folds nothing reports exactly what it did before"

# M18-AC5 — the report for a target the fold rewrites, per mark, so that a
# count of the right total distributed over the wrong marks cannot pass.
for context in 'entry="Elm"' 'entry="Koa"' 'entry="Pine"' 'entry="Zinc"' 'entry="Reed"'; do
  check_warning_count "$WORK/fold-xref-latex.log" "on $context names a path" 1 \
    "M18-AC5 ($context)"
done
check_warning_count "$WORK/fold-xref-both-latex.log" 'on entry="Yuc" names a path' 2 \
  "M18-AC5 (both attributes)"
check_warning_count "$WORK/fold-xref-latex.log" "$WARN_FOLD_TARGET" 5 "M18-AC5 (total)"
check_warning_count "$WORK/fold-xref-both-latex.log" "$WARN_FOLD_TARGET" 2 \
  "M18-AC5 (total, both attributes)"
# The marks whose targets the fold does not reach, and the formats that fold
# nothing: without these the check would pass on a filter reporting every
# target in every format.
for context in 'entry="Wax"' 'entry="Yam"'; do
  check_warning_count "$WORK/fold-xref-latex.log" "on $context names a path" 0 \
    "M18-AC5 (unfolded target, $context)"
done
for fmt in html gfm; do
  check_warning_count "$WORK/fold-xref-$fmt.log" "$WARN_FOLD_TARGET" 0 "M18-AC5 ($fmt)"
  check_warning_count "$WORK/fold-xref-both-$fmt.log" "$WARN_FOLD_TARGET" 0 \
    "M18-AC5 (both attributes, $fmt)"
done
pass "M18-AC5: every target the fold rewrites draws one report on its own mark, both of a both-attributes mark's do, the two targets the fold does not reach draw none, and no format without the ceiling draws any"

# ---------------------------------------------------------------------------
# M19 — a reported level count says which levels it counts (D-006).
#
# Three counts exist for one value: the levels written, the levels left after
# an empty one is dropped, and the three the back-end stores. Every number
# below is the number the filter reported before this milestone; only what it
# is CALLED moved, which is what M19-AC5 asks of these marks.
# ---------------------------------------------------------------------------
M19_BOTH=', of the 5 written; the back-end stores 3'
# The semicolon is the discriminator, not the digit: `4 levels deep;` cannot
# also match `4 levels deep, of the 5 written;`, so the control below fails the
# moment a report starts giving two counts where nothing was dropped.
M19_ONE='names a path 4 levels deep; the back-end stores 3'
# 5 written, first or last empty -> 4 left -> over the ceiling of 3, so the
# fold fires and the two counts differ. Three marks, three contexts, because a
# count of the right total spread over the wrong marks would pass a total
# alone (M02).
for context in 'see= on entry="Teak"' 'see= on entry="Willow"' \
               'see-also= on entry="Yewtree"'; do
  check_warning_count "$WORK/fold-xref-empty-latex.log" \
    "$context names a path 4 levels deep, of the 5 written;" 1 "M19-AC2 ($context)"
done
check_warning_count "$WORK/fold-xref-empty-latex.log" "$M19_BOTH" 3 \
  "M19-AC2 (total naming both counts)"
# 4 written, none empty -> 4 left -> folded, but the two counts agree, so one
# number is stated and no drop is implied.
check_warning_count "$WORK/fold-xref-empty-latex.log" \
  "see= on entry=\"Zircon\" $M19_ONE" 1 "M19-AC2 (counts agree, one number)"
# 4 written, first empty -> 3 left -> AT the ceiling, so nothing is folded and
# the fold report must stay silent even though the two counts differ. Its
# empty level is still reported, by the warning that owns that subject: the
# silence has to be the fold's alone, not the mark going unreported.
check_warning_count "$WORK/fold-xref-empty-latex.log" \
  'on entry="Sumac" names a path' 0 "M19-AC2 (drop without a fold is silent)"
check_warning_count "$WORK/fold-xref-empty-latex.log" \
  'empty level in see= on entry="Sumac"; dropped from the cross-reference target' \
  1 "M19-AC2 (its empty level is still reported)"
check_warning_count "$WORK/fold-xref-empty-latex.log" "$WARN_FOLD_TARGET" 4 \
  "M19-AC2 (total)"
# The ceiling is this back-end's alone, so no format without one names a depth.
for fmt in html gfm; do
  check_warning_count "$WORK/fold-xref-empty-$fmt.log" "$WARN_FOLD_TARGET" 0 \
    "M19-AC2 ($fmt)"
  check_warning_count "$WORK/fold-xref-empty-$fmt.log" "$M19_BOTH" 0 \
    "M19-AC2 (both counts, $fmt)"
done
pass "M19-AC2: a folded target names the count left after the drop and the count written where they differ, one count where they agree, and nothing at all where the drop leaves the target at the ceiling"

# The entry-fold report, same rule. demo.qmd's mark is written with 6 levels
# and ends in an empty one, so 6 - 1 = 5 remain and both numbers are named;
# fold-xref.qmd's is written with 4 and drops none, so one is.
check_warning_count "$WORK/demo-latex.log" \
  'index entry in entry="One!Two!Three!Four!Five!" is 5 levels deep, of the 6 written;' \
  1 "M19-AC4 (counts differ)"
check_warning_count "$WORK/fold-xref-latex.log" \
  'index entry in entry="Ash!Bay!Cod!Dun" is 4 levels deep; the back-end stores 3' \
  1 "M19-AC4 (counts agree)"
# No mark in fold-xref.qmd has an empty level, so no report there may carry a
# second count at all. Without this the check above passes on a filter that
# names two counts everywhere and happens to be right about this one.
check_warning_count "$WORK/fold-xref-latex.log" ', of the' 0 \
  "M19-AC4 (no second count where nothing dropped)"
# M19-AC3/AC6 negatives. Every pin above is a SUBSTRING count, so the retired
# clause re-added as a trailing sentence would pass all of them; only a sweep
# for the clause itself can fail on that. The filter source and README are read
# rather than a render log, so the check holds for messages no fixture reaches.
M19_RETIRED='before empty levels are dropped'
# One recursive grep with its no-match exit absorbed, and the emptiness decided
# by the comparison rather than by the pipeline's exit status: `grep ... && fail`
# aborts a `set -e` run with no FAIL line when the grep finds nothing (M14).
m19_retired_hits=$( { grep -rlF -- "$M19_RETIRED" _extensions README.md || true; } | tr '\n' ' ')
[ -z "$(echo "$m19_retired_hits" | tr -d ' ')" ] \
  || fail "M19-AC3: the retired clause <<$M19_RETIRED>> survives in: $m19_retired_hits — it names a drop that touches neither count"
pass "M19-AC3: the clause naming a drop that touches neither count is gone from the filter source and from README, asserted by a sweep rather than by the substring pins above"

pass "M19-AC4: the entry-fold report names both counts where a dropped level makes them differ and one where it does not, and the fixture with no empty level anywhere carries no second count at all"

# M18 — the other side of the format split, which is what makes the LaTeX
# behaviour a fold rather than a rewrite of the mark: HTML applies no ceiling,
# so the same targets keep every level the author wrote and link to entries
# four and five deep. Compared as a whole list, so an entry the manifest omits
# fails rather than passing unseen.
python3 - examples/fold-xref.html <<'M18HTMLPY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H

# depth<TAB>term<TAB>targets, a target written `kind|text|linked`. Derived from
# the fixture: every level the author wrote survives here — `Ash!Bay!Cod!Dun`
# nests four deep and `Fir!Gum!Ha!Iv!J!!t` five — so a target naming either
# names it in full, joined with `: `, and links to the deepest entry. `Sil…`
# is the one target no mark here indexes, so it is text rather than a link.
MANIFEST = """\
0\tAsh\t
1\tBay\t
2\tCod\t
3\tDun\t
0\tElm\tsee|Ash: Bay: Cod: Dun|linked
0\tFir\t
1\tGum\t
2\tHa\t
3\tIv\t
4\tJ!t\t
0\tKoa\tsee also|Fir: Gum: Ha: Iv: J!t|linked
0\tPine\tsee|Lime: Moss: Nut: Orb|linked
0\tReed\tsee also|Sil: Tea: Urn: Vin|plain
0\tWax\tsee|Elm|linked
0\tYak\tsee|Zinc|linked
0\tYam\tsee|Ash: Bay|linked
0\tZinc\tsee|Ash: Bay: Cod: Dun|linked
0\tLime\t
1\tMoss\t
2\tNut\t
3\tOrb\t"""

want = []
for row in MANIFEST.split('\n'):
    depth, term, targets = row.split('\t')
    want.append((int(depth), term,
                 tuple(t for t in targets.split(';') if t)))
got = []
for rec in H.entry_records(H.index_section(H.parse(sys.argv[1]))):
    got.append((rec['depth'], rec['term'],
                tuple(f'{kind}|{text}|' + ('linked' if href else 'plain')
                      for kind, text, resolved, href in rec['xrefs'])))
if got != want:
    print('FAIL: M18: the HTML index of fold-xref.qmd is not what the manifest '
          'holds', file=sys.stderr)
    import difflib
    for line in difflib.unified_diff([repr(r) for r in want],
                                     [repr(r) for r in got],
                                     'manifest', 'rendered', lineterm=''):
        print(f'  {line}', file=sys.stderr)
    sys.exit(1)
print('ok   M18: the HTML index folds nothing — entries nest four and five '
      'deep and every target names every level the author wrote — which is '
      'what makes the LaTeX behaviour this milestone adds a property of that '
      'back-end rather than of the mark')
M18HTMLPY
pass "M18: HTML applies no ceiling, so the same targets the LaTeX back-end folds keep every level written and link to the deep entries they name"

# M18-AC4 — followed to the compiled artifact (GP6): a reader has to be able to
# take the cross-reference in the printed index and find the entry it names.
# Read with tests/pdfindex.py rather than out of pdftotext's text output,
# because a two-column index interleaves when read as lines.
quarto render examples/fold-xref.qmd --to pdf > "$WORK/fold-xref-pdf.log" 2>&1 \
  || { tail -40 "$WORK/fold-xref-pdf.log" >&2; fail "M18-AC4: fold-xref.qmd failed to render to PDF"; }
[ -s examples/fold-xref.pdf ] || fail "M18-AC4: examples/fold-xref.pdf is empty"
python3 - examples/fold-xref.pdf <<'M18PDFPY'
import sys
sys.path.insert(0, 'tests')
import pdfindex

# The whole printed index, in printed order, as `level<TAB>term` — hand-derived
# from the fixture and the documented semantics. Levels are pdfindex's own
# 0-based indent bands, so a four- or five-level entry folded to three prints at
# 0, 1 and 2. Collation is the index tool's: `Lime` files under `zu` and so
# sorts last, which is the sort-key shape — what it FILES under and what it
# PRINTS are different strings, and only the printed one is what a target names.
MANIFEST = """\
0\tAsh
1\tBay
2\tCod, Dun
0\tElm, see Ash: Bay: Cod, Dun
0\tFir
1\tGum
2\tHa, Iv, J!t
0\tKoa, see also Fir: Gum: Ha, Iv, J!t
0\tPine, see Lime: Moss: Nut, Orb
0\tReed, see also Sil: Tea: Urn, Vin
0\tWax, see Elm
0\tYak, see Zinc
0\tYam, see Ash: Bay
0\tZinc, see Ash: Bay: Cod, Dun
0\tLime
1\tMoss
2\tNut, Orb"""

entries = pdfindex.read(sys.argv[1])
if not pdfindex.columns_carry_top_level(entries):
    print('FAIL: M18-AC4: a column of the printed index holds no top-level '
          'entry, so pdfindex cannot read its indent levels', file=sys.stderr)
    sys.exit(1)
want = [(int(lv), term) for lv, term in
        (row.split('\t') for row in MANIFEST.split('\n'))]
got = pdfindex.outline(entries)
if got != want:
    print('FAIL: M18-AC4: the printed index is not what the manifest holds',
          file=sys.stderr)
    import difflib
    for line in difflib.unified_diff([f'{l}\t{t}' for l, t in want],
                                     [f'{l}\t{t}' for l, t in got],
                                     'manifest', 'printed', lineterm=''):
        print(f'  {line}', file=sys.stderr)
    sys.exit(1)
# The claim AC4 is about, stated over the manifest that was just proved to be
# the printed index: each folded entry prints at level 2 under two parents, and
# the cross-reference naming it carries that same folded path.
for parent_a, parent_b, third, ref in (
        ('Ash', 'Bay', 'Cod, Dun', 'Elm, see Ash: Bay: Cod, Dun'),
        ('Fir', 'Gum', 'Ha, Iv, J!t', 'Koa, see also Fir: Gum: Ha, Iv, J!t'),
        ('Lime', 'Moss', 'Nut, Orb', 'Pine, see Lime: Moss: Nut, Orb')):
    rows = {term: level for level, term in want}
    assert rows[parent_a] == 0 and rows[parent_b] == 1 and rows[third] == 2, third
    assert ref.endswith(f'{parent_a}: {parent_b}: {third}'), ref
print(f'ok   M18-AC4: the compiled index matches the manifest row for row, '
      f'each of the three folded entries prints at level 2 under its two '
      f'parents, and the cross-reference that names it prints that same '
      f'folded path')
M18PDFPY
pass "M18-AC4: in the compiled PDF a folded entry and the cross-reference that names it print the same path, so a reader following the reference finds the entry"

# M18 (review F1) — the regression pin for the defect this review returned on:
# a target the fold turns into a self-reference must draw the fold's OWN report
# and nothing else. Reachable only from a target written DEEPER than the
# ceiling whose folded form equals the entry's printed path, which is why no
# shape in the other two fixtures reaches it — theirs are written at exactly
# three levels, so the report about a rewritten target never fires on them.
# Before the fix the LaTeX render drew both: "now names X" and, next line,
# "the fold made the target a cross-reference to itself, so it is dropped".
check_warning_count "$WORK/fold-xref-self-latex.log" "$WARN_FOLD_SELF" 1 "M18 (F1)"
check_warning_count "$WORK/fold-xref-self-latex.log" "$WARN_FOLD_TARGET" 0 "M18 (F1)"
check_warning_count "$WORK/fold-xref-self-latex.log" "$WARN_DANGLING" 0 "M18 (F1)"
for fmt in html gfm; do
  # No ceiling, so nothing folds, nothing is a self-reference here, and the
  # target names a four-level path this file does not index — one report, and
  # it is the format-neutral one.
  check_warning_count "$WORK/fold-xref-self-$fmt.log" "$WARN_FOLD_SELF" 0 "M18 (F1, $fmt)"
  check_warning_count "$WORK/fold-xref-self-$fmt.log" "$WARN_FOLD_TARGET" 0 "M18 (F1, $fmt)"
  check_warning_count "$WORK/fold-xref-self-$fmt.log" "$WARN_DANGLING" 1 "M18 (F1, $fmt)"
done
pass "M18 (F1): a target the fold turns into a self-reference draws exactly one report — the fold's own — and no second one announcing a path it no longer names"

# M18 (review F5) — the both-attributes site followed to a compiled artifact
# (GP6). Its printed row carries two whole folded paths and both labels, so it
# wraps, which is why this fixture stays out of AC4's outline manifest: the
# text is read whitespace-collapsed instead, which a wrap survives and a wrong
# fold does not.
quarto render examples/fold-xref-both.qmd --to pdf > "$WORK/fold-xref-both-pdf.log" 2>&1 \
  || { tail -40 "$WORK/fold-xref-both-pdf.log" >&2; fail "M18 (F5): fold-xref-both.qmd failed to render to PDF"; }
[ -s examples/fold-xref-both.pdf ] || fail "M18 (F5): examples/fold-xref-both.pdf is empty"
python3 - examples/fold-xref-both.pdf <<'M18BOTHPDFPY'
import re, subprocess, sys

text = subprocess.run(['pdftotext', sys.argv[1], '-'], check=True,
                      capture_output=True, text=True).stdout
flat = re.sub(r'\s+', ' ', text)
# The whole row, both targets folded as their entries are. Asserted as one
# string so a fold applied to the first argument and not the second cannot
# pass, and counted so a row printed twice cannot either.
ROW = ('Yuc, see Oat: Pea: Rye, Soy; '
       'see also Tef: Urd: Vet, Wid, Xan')
if flat.count(ROW) != 1:
    print(f'FAIL: M18 (F5): the both-attributes row appears '
          f'{flat.count(ROW)} times in the compiled index, want 1. Wanted '
          f'<<{ROW}>>', file=sys.stderr)
    sys.exit(1)
# The unfolded spellings must be absent, or the check above would pass on a
# build that printed both forms somewhere.
for stale in ('Oat: Pea: Rye: Soy', 'Tef: Urd: Vet: Wid: Xan'):
    if stale in flat:
        print(f'FAIL: M18 (F5): the compiled index still carries the unfolded '
              f'target <<{stale}>>', file=sys.stderr)
        sys.exit(1)
print('ok   M18 (F5): the both-attributes command compiles through makeindex '
      'and prints one row carrying both targets folded to the paths their '
      'entries print, with neither unfolded spelling anywhere in it')
M18BOTHPDFPY
pass "M18 (F5): the both-attributes site reaches a compiled artifact, where both of its folded targets print as the entries they name print"

# ---------------------------------------------------------------------------
# M20 — a term's principal discussion prints as its principal locator.
#
# ORACLE NOTE. Two toolchain layers sit between what the filter emits and what
# is checked here, and both are read from their own documented behavior rather
# than from this run's output:
#   1. hyperref rewrites an encapsulation before makeindex runs. A plain
#      locator becomes `\hyperpage{N}`; one carrying `|CMD` becomes
#      `\hyperxindexformat{\CMD}{N}`. That is the same rewriting the
#      cross-reference channel has always been subject to (see passes.lua).
#   2. makeindex writes the `.ind` and logs to the `.ilg`. Its conflict
#      predicate is same key, same page, ANY byte difference in the
#      encapsulation string — bare against encapsulated included — and it
#      reports a conflict as a WARNING at exit 0; Quarto alone fails the render,
#      on a regex over that transcript. So the `.ilg`'s own warning count, and
#      not the exit status, is what this section reads (D-007).
#   3. makeindex folds a RUN of consecutive pages under one encapsulation into
#      a single group, and three or more of them into a `--` range. The fixture
#      separates its three basilisk marks by filler pages for that reason: a
#      range is a page string the typeset-time registry cannot match, so three
#      adjacent pages would print no emphasis while every check still passed.
# Page numbers are not hardcoded here — the reader takes them from the .ind
# groups themselves and cross-links them against the .aux registrations, since
# the fixture's pagination is not what these criteria are about.
# ---------------------------------------------------------------------------
# Removed before the render, not merely overwritten by it: AC5 is stated over
# the gfm render of this run, and a stale committed .md left in place would
# satisfy the check after the filter had regressed (the audit's F6).
rm -f examples/principal.md examples/principal.html
for fmt in latex html gfm; do
  quarto render examples/principal.qmd --to $fmt > "$WORK/principal-$fmt.log" 2>&1 \
    || { cat "$WORK/principal-$fmt.log" >&2; fail "M20: examples/principal.qmd failed to render to $fmt"; }
done
for artifact in examples/principal.md examples/principal.html; do
  [ -s "$artifact" ] \
    || fail "M20: the render produced no $artifact, so every check stated over it would read a file this run did not write"
done
# Copied before the PDF render below removes the intermediate .tex (M15).
cp examples/principal.tex "$WORK/principal.tex"
for fmt in latex html gfm; do
  quarto render examples/principal-twin.qmd --to $fmt \
    > "$WORK/principal-twin-$fmt.log" 2>&1 \
    || { cat "$WORK/principal-twin-$fmt.log" >&2; fail "M20: examples/principal-twin.qmd failed to render to $fmt"; }
done
cp examples/principal-twin.tex "$WORK/principal-twin.tex"
# Removed, not merely overwritten: AC1 is stated over the artifacts of THIS
# render, and its whole content is a cross-artifact agreement — the identifiers
# the .ind carries against the ones the .aux registers. A stale .aux left in
# place from a tree where the ordinals were assigned differently would satisfy
# the check while this run's filter emitted something else entirely.
rm -f examples/principal.ind examples/principal.ilg examples/principal.aux
quarto render examples/principal.qmd --to pdf > "$WORK/principal-pdf.log" 2>&1 \
  || { cat "$WORK/principal-pdf.log" >&2; fail "M20-AC1: examples/principal.qmd failed to render to PDF"; }
# The fixture sets `latex-clean: false` precisely so these survive; their
# absence means the fixture lost that option, not that the render was clean.
for aux in ind ilg aux; do
  [ -f "examples/principal.$aux" ] \
    || fail "M20-AC1: the PDF render left no examples/principal.$aux — the fixture's latex-clean option is what keeps it, and without it this criterion has no evidence at all"
  cp "examples/principal.$aux" "$WORK/principal.$aux"
done

PRINCIPAL_CMD="quartoindexprincipal"
LOCATOR_CMD="quartoindexlocator"
REGISTER_CMD="quartoindexregister"
PRINCIPALPAGE_CMD="quartoindexprincipalpage"
RANGEFROM_CMD="quartoindexrangefrom"
RANGEEND_CMD="quartoindexrangeend"
RANGEAT_CMD="quartoindexrangeat"
RANGETO_CMD="quartoindexrangeto"
python3 tests/m20probes.py ind "$WORK/principal.ind" "$WORK/principal.ilg" \
  "$WORK/principal.aux" "$LOCATOR_CMD" "$PRINCIPALPAGE_CMD"
pass "M20-AC1: every locator of a principal key carries one uniform encapsulation, the .aux registers exactly those identifiers from pages their own entries list, and makeindex logs no warning"

# M20-AC2 — the same fact in the HTML back-end, read structurally. The class
# AND the emphasis node are both asserted: the class alone needs a stylesheet
# this extension does not ship, and the emphasis alone would leave an author's
# CSS nothing to hold on to.
HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" python3 tests/m20probes.py html examples/principal.html
pass "M20-AC2: the HTML index marks exactly the principal mark's locator link, at its own position, and leaves every other locator plain"

# M20-AC3/AC4 — the two reports, in all three formats, and the counterfactual
# each of them promises. The counts are per MARK, not a total: a filter that
# reported the right number of times about the wrong marks would pass a total.
for fmt in latex html gfm; do
  # Two marks are told their cross-reference took the locator's place, and
  # exactly two: `imp` writes a role beside a target naming its OWN entry, which
  # is dropped as a self-reference so the mark does have a locator after all. A
  # third here would be that mark being told otherwise a line before the drop's
  # own report contradicts it (review F2).
  check_warning_count "$WORK/principal-$fmt.log" \
    "$M20_NOLOCATOR" 2 "M20-AC3 ($fmt)"
  check_warning_count "$WORK/principal-$fmt.log" \
    'mention="principal" on term "cockatrice" carries see= as well' 1 \
    "M20-AC3 (names the mark and the attribute, $fmt)"
  # A mark writing both attributes is told about both: a report naming only the
  # first one it found would describe half the mark (review F12).
  check_warning_count "$WORK/principal-$fmt.log" \
    'mention="principal" on term "harpy" carries see= and see-also= as well' 1 \
    "M20-AC3 (names every cross-reference attribute, $fmt)"
  # And a role on a mark that indexes nothing at all is reported rather than
  # dropped in silence, which is the other way a mark can have no locator for a
  # role to reach (review F11).
  check_warning_count "$WORK/principal-$fmt.log" "$M20_UNINDEXED" 1 \
    "M20-AC3 (a mark that indexes nothing, $fmt)"
  check_warning_count "$WORK/principal-twin-$fmt.log" "$M20_UNINDEXED" 0 \
    "M20-AC3 (twin, a mark that indexes nothing, $fmt)"
  check_warning_count "$WORK/principal-$fmt.log" "$M20_UNKNOWN" 2 \
    "M20-AC4 ($fmt, total)"
  check_warning_count "$WORK/principal-$fmt.log" \
    'on term "dryad" names no role this extension knows ("paramount")' 1 \
    "M20-AC4 (names the mark and the value, $fmt)"
  check_warning_count "$WORK/principal-$fmt.log" \
    'on term "ettin" names no role this extension knows ("")' 1 \
    "M20-AC4 (an empty value is a value, $fmt)"
  # The twin writes no role at all, so neither report may fire for it. Without
  # this the counts above would pass on a filter reporting on every mark.
  check_warning_count "$WORK/principal-twin-$fmt.log" "$M20_UNKNOWN" 0 \
    "M20-AC4 (twin, $fmt)"
  check_warning_count "$WORK/principal-twin-$fmt.log" "$M20_NOLOCATOR" 0 \
    "M20-AC3 (twin, $fmt)"
done
pass "M20-AC3/AC4: the dropped-role report and the unrecognized-value report each name their own mark and fire exactly once per mark in LaTeX, HTML and gfm — the empty value among them — and neither fires anywhere in the role-free twin"

# The counterfactual both criteria state: a mark whose role is reported and
# ignored emits what it emits with the attribute removed. Compared against the
# twin's own emission rather than against a written-down string, so the claim
# is about the filter's behavior and not about what someone typed here.
python3 tests/m20probes.py twin "$WORK/principal.tex" "$WORK/principal-twin.tex"
pass "M20-AC3/AC4: a mark whose role is reported and ignored emits what the same mark emits in the role-free twin, compared command by command"

# ---------------------------------------------------------------------------
# Manifest 9 — every index span examples/principal.qmd writes into gfm, in
# document order, one per line (M20-AC5).
# Same ORACLE RULE as manifest 1, with the pass-through layers derived by hand:
#   4. gfm has no index back-end, so a mark reaches it as the `span` Pandoc read
#      it as: its class, then its attributes in SOURCE order, each name
#      data-prefixed because Pandoc data-prefixes an attribute it does not know
#      (which is why the role attribute is `mention` and not `role` — the
#      milestone's Decisions entry).
#   5. Visible text passes through as written, nested inline markup included.
#   6. A mark that indexes nothing is removed with its content, so the
#      entry-less mark writes no row here; every other mark writes exactly one.
# The fixture renders gfm with `wrap: none`, so no row is broken by the
# writer's column limit and these are the bytes of the render.
# ---------------------------------------------------------------------------
read -r -d '' PRINCIPAL_GFM_SPANS <<'MANIFEST' || true
<span class="index">basilisk</span>
<span class="index" data-mention="principal">basilisk</span>
<span class="index">basilisk</span>
<span class="index" data-mention="principal" data-see="basilisk">cockatrice</span>
<span class="index" data-mention="paramount">dryad</span>
<span class="index" data-mention="">ettin</span>
<span class="index">faun</span>
<span class="index">faun</span>
<span class="index" data-mention="principal">gorgon</span>
<span class="index" data-see="basilisk">gorgon</span>
<span class="index" data-mention="principal" data-see="basilisk" data-see-also="faun">harpy</span>
<span class="index" data-mention="principal" data-see="imp">imp</span>
<span class="index" data-mention="principal">**kraken**</span>
MANIFEST
printf '%s\n' "$PRINCIPAL_GFM_SPANS" > "$WORK/principal-gfm-spans.txt"

# M20-AC5 — the format with no index back-end. Every index span the render
# carries is compared against the manifest above, in document order and byte
# for byte, and the permitted residue is stated as an exact set of tokens
# rather than as an exemption, so a stray one cannot be argued into it.
python3 tests/m20probes.py gfm examples/principal.md "$WORK/principal-gfm-spans.txt"
pass "M20-AC5: in the format with no index back-end every index mark the fixture writes passes through as its visible text plus exactly its own attributes, data-prefixed, in document order and byte for byte against a hand-derived manifest, with no residue of either back-end"

# M20-AC6 — the subsystem is injected where it is used and nowhere else. Both
# directions, or a filter that injected it into every document would pass. The
# reader bounds both reads to the region before `\begin{document}` and refuses
# an absent or empty file, so the negative half cannot pass vacuously.
# The whole subsystem, the four range commands included: M21 folded them back
# into the one block, because the `.aux` lines they are defined FOR outlive the
# source that produced them and a command that is no longer injected is an
# `Undefined control sequence` on the next pass (M21 review F3). So a document
# with a principal mention and no range carries all eight, and the criterion's
# real claim — none of them reaches a document with no principal mention — is
# unchanged and still both-directional.
SUBSYSTEM_CMDS=("$PRINCIPAL_CMD" "$LOCATOR_CMD" "$REGISTER_CMD" "$PRINCIPALPAGE_CMD"
                "$RANGEFROM_CMD" "$RANGEEND_CMD" "$RANGEAT_CMD" "$RANGETO_CMD")
python3 tests/m20probes.py tex "$WORK/principal.tex" examples/content.tex \
  "${SUBSYSTEM_CMDS[@]}"
pass "M20-AC6: the ${#SUBSYSTEM_CMDS[@]} subsystem commands are defined once each with \\providecommand* in the fixture that uses them, nothing else naming quartoindex is defined there, and none of them reaches a document with no principal mention"
python3 tests/m20probes.py tex "$WORK/principal.tex" "$WORK/principal-twin.tex" \
  "${SUBSYSTEM_CMDS[@]}"
pass "M20-AC6: nor does any of them reach the role-free twin, which is the same document with every mention attribute removed"

# ---------------------------------------------------------------------------
# M20 T9 — the regressions IP2's forever clause earns, in a fixture of their
# own. It is separate from examples/principal.qmd for two reasons: adding marks
# there would move AC5's hand-derived thirteen-span manifest, and this document
# redefines the emphasis command, which the fixture the other criteria are
# stated over must not do.
#
# ORACLE NOTE. `pdftotext` cannot see `\textbf`: bold and plain text extract to
# the same bytes. So every emphasis claim below is read through the fixture's
# own redefinition of \quartoindexprincipal to a bracketed marker — which is
# not a workaround but the second thing this section proves, since that
# redefinition taking effect at all is the author-facing promise README makes.
# ---------------------------------------------------------------------------
rm -f examples/principal-cases.ind examples/principal-cases.ilg \
      examples/principal-cases.aux examples/principal-cases.pdf
quarto render examples/principal-cases.qmd --to pdf \
  > "$WORK/principal-cases-pdf.log" 2>&1 \
  || { cat "$WORK/principal-cases-pdf.log" >&2; fail "M20 T9: examples/principal-cases.qmd failed to render to PDF — a plain and a principal mark of one key on one page is the shape this milestone died on, and this render is what proves it no longer breaks the document"; }
for aux in ind ilg aux; do
  [ -f "examples/principal-cases.$aux" ] \
    || fail "M20 T9: the PDF render left no examples/principal-cases.$aux"
  cp "examples/principal-cases.$aux" "$WORK/principal-cases.$aux"
done
[ -s examples/principal-cases.pdf ] \
  || fail "M20 T9: the render produced no PDF, so the printed index every clause below reads was never written"
pdftotext examples/principal-cases.pdf "$WORK/principal-cases.txt"
python3 tests/m20probes.py cases "$WORK/principal-cases.txt" \
  "$WORK/principal-cases.ilg" "$WORK/principal-cases.ind" \
  "$WORK/principal-cases.aux" "$WORK/principal-cases-pdf.log"
pass "M20 T9: every locator of the printed index is marked exactly when the registry names it — derived from the .ind and .aux rather than written down — across a same-page pair, a footnote, two page ranges, a registered page that is not first in its list, a page past nine, a fold-induced self-target and a role-free control, at zero makeindex warnings and through the author's own redefinition of the emphasis command"

# The documentation half of T7, held to the same discipline as every other
# README claim array: the bytes the extension documents are compared, so a
# behavior that changes without its documentation fails here.
printf '%s\n' "${README_PRINCIPAL_CLAIMS[@]}" > "$WORK/readme-principal.txt"
python3 - "$WORK/readme-principal.txt" README.md <<'M20DOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = flat(open(sys.argv[2], encoding='utf-8').read())
missing = [f'  missing ({label}): <<{text}>>'
           for label, text in rows if flat(text) not in readme]
if missing:
    print('FAIL: M20: README.md does not document the principal mention as '
          'this suite exercises it:', file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M20: all {len(rows)} documented claims about the principal '
      f'mention appear verbatim in README.md')
M20DOCPY
pass "M20: every behavior the README documents for the principal mention is present verbatim, and its authoring form is in the suite's normative supported-forms list"

printf '%s\n' "${README_RANGE_CLAIMS[@]}" > "$WORK/readme-range.txt"
python3 - "$WORK/readme-range.txt" README.md <<'M21DOCPY'
import sys


def flat(text):
    return ' '.join(text.split())


rows = [l.rstrip('\n').split('\t', 1)
        for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
readme = flat(open(sys.argv[2], encoding='utf-8').read())
missing = [f'  missing ({label}): <<{text}>>'
           for label, text in rows if flat(text) not in readme]
if missing:
    print('FAIL: M21: README.md does not document the page range as this suite '
          'exercises it:', file=sys.stderr)
    print('\n'.join(missing), file=sys.stderr)
    sys.exit(1)
print(f'ok   M21: all {len(rows)} documented claims about the page range appear '
      f'verbatim in README.md')
M21DOCPY
pass "M21: every behavior the README documents for a page range is present verbatim, and both of its authoring forms are in the suite's normative supported-forms list"

# ---------------------------------------------------------------------------
# M21 — a discussion spanning pages prints as one page range.
#
# ORACLE NOTE. Everything asserted here about a range's extent is stated in
# PAGES SEPARATED, never in folios: `examples/range.qmd` puts exactly one
# mark-free page between each range's two ends but the last, whose ends share a
# sentence. That is a fact about the source the author wrote, and it is the one
# fact this section does not read out of the artifacts under test — the printed
# range, the `.aux` registration and the emphasis are all written by one run, so
# an expectation derived from any of them moves with a defect in the others
# (the M20 lesson, in the shape ranges take).
#
# Two toolchain layers sit in between, read from their own documented behavior:
#   1. hyperref rewrites an encapsulation before makeindex runs, exactly as it
#      does for the cross-reference channel.
#   2. makeindex pairs `|(` with `|)` by KEY, requires the two ends to carry
#      byte-identical encapsulators, prints a same-page pair as one page rather
#      than as a range, and logs every range fault as a WARNING at exit 0.
#      Quarto alone fails the render, on a regex over that transcript — so the
#      `.ilg`'s own warning count, and not the exit status, is the oracle here
#      (D-007), and a range this filter cannot pair must never be emitted.
# ---------------------------------------------------------------------------
# Removed before the render, not merely overwritten: AC6 is stated over the gfm
# render of THIS run, and a stale committed .md would satisfy it after the
# filter had regressed.
rm -f examples/range.md examples/range.html examples/range.tex
for fmt in latex html gfm; do
  quarto render examples/range.qmd --to $fmt > "$WORK/range-$fmt.log" 2>&1 \
    || { cat "$WORK/range-$fmt.log" >&2; fail "M21: examples/range.qmd failed to render to $fmt"; }
done
for artifact in examples/range.md examples/range.html; do
  [ -s "$artifact" ] \
    || fail "M21: the render produced no $artifact, so every check stated over it would read a file this run did not write"
done
# Copied before the PDF render below removes the intermediate .tex (M15), and
# size-checked first like every other artifact here: a render that exits 0 and
# writes nothing would otherwise leave every AC2 clause reading a file this run
# did not produce (review round 3, R3-F6).
[ -s examples/range.tex ] \
  || fail "M21-AC2: the latex render produced no examples/range.tex"
cp examples/range.tex "$WORK/range.tex"
# Removed, not overwritten: AC2 is a cross-artifact agreement between the .ind
# and the .aux of one render, and a stale .aux from a tree where the ordinals
# were assigned differently would satisfy it while this run emitted something
# else entirely.
rm -f examples/range.ind examples/range.ilg examples/range.aux
quarto render examples/range.qmd --to pdf > "$WORK/range-pdf.log" 2>&1 \
  || { cat "$WORK/range-pdf.log" >&2; fail "M21-AC1: examples/range.qmd failed to render to PDF"; }
for aux in ind ilg aux; do
  [ -f "examples/range.$aux" ] \
    || fail "M21-AC1: the PDF render left no examples/range.$aux — the fixture's latex-clean option is what keeps it, and without it this criterion has no evidence at all"
  cp "examples/range.$aux" "$WORK/range.$aux"
done

python3 tests/m21probes.py ind "$WORK/range.ind" "$WORK/range.ilg" \
  "$WORK/range.aux" "$LOCATOR_CMD" "$PRINCIPALPAGE_CMD" \
  "$RANGEAT_CMD" "$RANGETO_CMD"
pass "M21-AC1/AC2: every range prints as one locator covering the pages the fixture separates its marks by, a principal range carries one ordinal on both ends and is registered under the very string it prints, the range-free control keeps its two separate pages, and makeindex logs no warning at all"

python3 tests/m21probes.py tex "$WORK/range.tex" "$LOCATOR_CMD" \
  "$RANGEFROM_CMD" "$RANGEEND_CMD"
pass "M21-AC2: every range emits one opening and one closing under one key carrying byte-identical encapsulators, and each principal range registers both of its ends"

# The stale-`.aux` guard (review F3), stated as the property that closes it:
# every command an `.aux` line can name is defined in EVERY document the
# subsystem reaches, not only in one that still writes a range. A document with
# a principal mention and no range is the case that matters — that is the tree
# an author lands in the moment they delete a `range=` — so the principal
# fixture is read here rather than the range one.
python3 tests/m21probes.py preamble "$WORK/principal.tex" \
  "$RANGEAT_CMD" "$RANGETO_CMD"
pass "M21: the range commands ride with the rest of the subsystem, so a document that loses its ranges but keeps a principal mention still defines every command its own .aux can name"

# The printed index, through the fixture's own redefinition of the emphasis
# command: `\textbf` and plain text extract identically under pdftotext, so the
# bracketed marker is the only way an emphasis claim can be read out of a PDF.
# Which ranges are principal is read from the fixture's source, not the output.
require_pdf_tools
pdftotext "examples/range.pdf" "$WORK/range.txt" \
  || fail "M21-AC2: could not extract text from examples/range.pdf"
python3 - "$WORK/range.txt" <<'M21PDF'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
body = text.splitlines()
heads = [i for i, l in enumerate(body) if l.strip() == 'Index']
if not heads:
    print('FAIL: M21-AC2: the PDF text carries no Index heading', file=sys.stderr)
    sys.exit(1)
index = '\n'.join(body[heads[-1] + 1:])
lines = {' '.join(l.split()) for l in index.splitlines() if l.strip()}
# The fixture's own structure: which openings carry mention="principal".
# Which ranges the fixture marks principal, and on WHICH end — read from the
# fixture's source, never from the output. `firebird` declares it on its
# closing mark, and must print exactly as emphasized as the two that declare it
# on their opening (review F2).
PRINCIPAL = ('banshee', 'erlking', 'firebird')
PLAIN = ('alicorn', 'dybbuk', 'centaur')
LOC = r'\d+(?:\u2013\d+)?'
bad = []
for term in PRINCIPAL:
    if not any(re.fullmatch(re.escape(term) + r', \[P:' + LOC + r'\]', l)
               for l in lines):
        bad.append(f'  {term}: no line printing its whole locator emphasized; '
                   f'lines starting with it: '
                   f'{[l for l in lines if l.startswith(term)]}')
for term in PLAIN:
    hit = [l for l in lines if l.startswith(term + ',')]
    if not hit:
        bad.append(f'  {term}: no entry in the printed index at all')
    elif any('[P:' in l for l in hit):
        bad.append(f'  {term}: printed emphasized ({hit}), and no mark of it is '
                   f'principal')
if index.count('[P:') != len(PRINCIPAL):
    bad.append(f'  the printed index emphasizes {index.count("[P:")} locator(s); '
               f'the fixture writes mention="principal" on {len(PRINCIPAL)} '
               f'range openings')
if bad:
    print('FAIL: M21-AC2: the compiled index does not print the ranges the '
          'fixture marks as principal, and only those, emphasized:',
          file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
print(f'ok   M21-AC2: the compiled PDF prints each of the {len(PRINCIPAL)} '
      f'principal ranges emphasized as a whole range, and every other entry '
      f'plain')
M21PDF
pass "M21-AC2: in the compiled PDF the principal ranges print emphasized whole — the last link of the chain the .ind cannot carry — and no other entry does"

HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" \
  python3 tests/m21probes.py html examples/range.html
pass "M21-AC3: every range contributes exactly one locator link, at its opening mark's anchor and never at its closing one, emphasized exactly where the opening is principal, while each closing mark keeps an anchor and adds nothing to its own text"

# M21-AC6 — the format with no index back-end. Derived by hand from the .qmd
# (the ORACLE RULE), in document order, attributes in the order the author
# wrote them.
read -r -d '' RANGE_GFM_SPANS <<'MANIFEST' || true
<span class="index" data-range="open">alicorn</span>
<span class="index" data-range="close">alicorn</span>
<span class="index" data-range="open" data-mention="principal">banshee</span>
<span class="index" data-range="close">banshee</span>
<span class="index">centaur</span>
<span class="index">centaur</span>
<span class="index" data-range="open">dybbuk</span>
<span class="index" data-range="close">dybbuk</span>
<span class="index" data-see="centaur">dybbuk</span>
<span class="index" data-range="open" data-mention="principal">erlking</span>
<span class="index" data-range="close">erlking</span>
<span class="index" data-range="open">firebird</span>
<span class="index" data-range="close" data-mention="principal">firebird</span>
MANIFEST
printf '%s\n' "$RANGE_GFM_SPANS" > "$WORK/range-gfm-spans.txt"
python3 tests/m21probes.py gfm examples/range.md "$WORK/range-gfm-spans.txt"
pass "M21-AC6: in the format with no index back-end an opening and a closing mark pass their visible text through with exactly their own attributes data-prefixed, range= included, and no range delimiter or registration command reaches the format"

# M21-AC4 — the five misuse shapes, in all three formats. The needles are per
# SHAPE and the identity checks are per MARK: a filter that reported the right
# number of times about the wrong marks would pass a count alone (the M08
# lesson).
for fmt in latex html gfm; do
  quarto render examples/range-misuse.qmd --to $fmt \
    > "$WORK/range-misuse-$fmt.log" 2>&1 \
    || { cat "$WORK/range-misuse-$fmt.log" >&2; fail "M21-AC4: examples/range-misuse.qmd failed to render to $fmt"; }
  # Copied at the render, so the emitted-LaTeX check below reads this run's
  # artifact and not whatever the working tree happens to hold (M15).
  if [ "$fmt" = "latex" ]; then
    [ -s examples/range-misuse.tex ] \
      || fail "M21-AC4: the latex render produced no examples/range-misuse.tex"
    cp examples/range-misuse.tex "$WORK/range-misuse-latex.tex"
  fi
  # Two marks of this shape: a value naming neither end, and an EMPTY value,
  # which README singles out as a value the author wrote rather than an
  # attribute they left off and which nothing exercised until round 3 (R3-F10).
  check_warning_count "$WORK/range-misuse-$fmt.log" "$R_UNKNOWN" 2 \
    "M21-AC4 (a value that is neither end, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range= on term "kobold" names neither end of a range ("")' 1 \
    "M21-AC4 (an empty value is a value, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" "$R_DISPLACED" 1 \
    "M21-AC4 (a range mark carrying a cross-reference, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" "$R_ALREADY" 1 \
    "M21-AC4 (a second opening while a range is open, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" "$R_NOOPEN" 1 \
    "M21-AC4 (a closing with no opening, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" "$R_NOCLOSE" 1 \
    "M21-AC4 (an opening never closed, $fmt)"
  # Which mark each report is about, and what it says the index will show.
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range= on term "jinn" names neither end of a range ("middle")' 1 \
    "M21-AC4 (names the mark and the value, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range="open" on term "imp" carries see= as well' 1 \
    "M21-AC4 (names the mark and the attribute in the way, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range="open" on term "hydra" opens a range' 1 \
    "M21-AC4 (names the mark, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range="close" on term "golem" closes a range' 1 \
    "M21-AC4 (names the mark, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'range="open" on term "fenrir" is never closed' 1 \
    "M21-AC4 (names the mark, $fmt)"
  # What the index will show instead, in the two shapes the five take: the
  # three pairing faults degrade the mark to an ordinary locator, and the two
  # mark-local ones leave the mark indexing as though the attribute were not
  # there. Matched without the leading noun, since one of the three says "this
  # mark" to tell it apart from the earlier opening it names.
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'indexes as an ordinary page number' 3 \
    "M21-AC4 (says what the index will show instead, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'indexes as though the attribute were absent' 2 \
    "M21-AC4 (says what the index will show instead, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" \
    'the range is dropped and the mark indexes as it would without it' 1 \
    "M21-AC4 (says what the index will show instead, $fmt)"
  # The controls, which no report may name: a well-formed range and an
  # ordinary mark, in the same document as all five faults.
  check_warning_count "$WORK/range-misuse-$fmt.log" 'lamia' 0 \
    "M21-AC4 (the well-formed range control, $fmt)"
  check_warning_count "$WORK/range-misuse-$fmt.log" 'kelpie' 0 \
    "M21-AC4 (the range-free control, $fmt)"
  # And the fixture that gets everything right draws none of the five at all.
  for needle in "$R_UNKNOWN" "$R_DISPLACED" "$R_ALREADY" "$R_NOOPEN" "$R_NOCLOSE"; do
    check_warning_count "$WORK/range-$fmt.log" "$needle" 0 \
      "M21-AC4 (the well-formed fixture, $fmt)"
  done
done
pass "M21-AC4: each of the five misuse shapes draws exactly one warning naming its own mark and saying the term is indexed as an ordinary page number instead, in the LaTeX render, the HTML render and a format with no index back-end, while the well-formed range and the range-free mark beside them draw none"

# What every one of those refusals is FOR: a range the extension cannot pair
# must never reach the index tool at all, because makeindex logs a transcript
# warning for an unmatched, extra or inconsistently encapsulated range and
# Quarto fails the whole render on that line. Nothing above holds it — five
# reports would still fire while the range operator went out anyway (review
# F5). Read from the emitted LaTeX rather than by rendering the fixture to PDF:
# the property is that the operator is not EMITTED, and a PDF render would
# prove it only for the pagination this run happens to produce.
python3 tests/m21probes.py misuse "$WORK/range-misuse-latex.tex"
pass "M21-AC4: no refused range reaches the index tool as a range — the emitted LaTeX carries exactly one opening and one closing, both the well-formed control's, which is what keeps an unpairable range from failing the render"

# M21-AC5 — the cross-chapter range. The href and the locator count are the
# BOOK_HTML_INDEX manifest's `Ranged Term` row, checked above. A chapter is the
# pairing scope (D-009, R4-F1), so each chapter states its own half — the
# opening never closed in ITS chapter, the closing never opened in its — and
# the book adds exactly one report of its own, naming both marks of the pair it
# alone can see split.
check_warning_count "$WORK/book-html.log" 'is never closed in this chapter' 1 \
  "M21-AC5 (the opening chapter reports its own half, over the chapter)"
check_warning_count "$WORK/book-html.log" 'closes a range this chapter never opens' 1 \
  "M21-AC5 (the closing chapter reports its own half, over the chapter)"
for needle in "$R_ALREADY" "$R_DISPLACED" "$R_UNKNOWN"; do
  check_warning_count "$WORK/book-html.log" "$needle" 0 \
    "M21-AC5 (no report this book has no mark for)"
done
check_warning_count "$WORK/book-html.log" "$R_BOOKUNPAIRED" 1 \
  "M21-AC5 (the book says once that it pairs no range across chapters)"
for mark in 'term "Ranged Term" in one.qmd' 'term "Ranged Term" in sub/two.qmd'; do
  check_warning_count "$WORK/book-html.log" "$mark" 1 \
    "M21-AC5 (and names both marks of the pair)"
done
# The same-chapter range is paired, so no report of any kind names it — a book
# report naming every range mark it found would pass the count above and be wrong.
check_warning_count "$WORK/book-html.log" 'term "Chapter Range"' 0 \
  "M21-AC5 (and names no mark its own chapter paired)"
python3 tests/m21probes.py bookpdf "$WORK/book.txt" "Ranged Term"
pass "M21-AC5: each chapter of an HTML book reports its own half of a split range over the chapter, the book draws exactly one report naming both marks of the pair it alone can see split, and the same book's PDF — one merged document — still prints that term as a single ranged locator"

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
    pass "$label: the check for <<$pattern>> fails when it is missing and when it is duplicated, and passes as rendered"
  }

  warn_discrimination "$WORK/demo-latex.log" "$WARN_BOTH" 1 "M02-AC5"
  warn_discrimination "$WORK/content-latex.log" "$WARN_NO_SOURCE" 2 "M02-AC5"
  # Not named by a criterion, but the same discipline: a clash report nothing
  # proves discriminating is a report that can quietly stop firing.
  warn_discrimination "$WORK/conflict-latex.log" "$WARN_CLASH" 8 "M02-AC5"

  # M16-AC2 — the source-set enumeration is recursive, and it grows when the
  # filter does. Proved on a scratch copy rather than by reading the `find`
  # call: a non-recursive enumeration reads the same as a recursive one until
  # a subdirectory exists, which is why the deleted merge-base diff script's
  # fixture list went nine fixtures short for months without failing (D-004).
  # The count must rise with NO edit to this script.
  SRC_PROBE="$WORK/src-enum"
  rm -rf "$SRC_PROBE"; mkdir -p "$SRC_PROBE"
  cp -R "$QI_EXT_DIR" "$SRC_PROBE/ext"
  BEFORE=$(QI_EXT_DIR="$SRC_PROBE/ext" python3 -c "
import sys; sys.path.insert(0,'tests'); import filtersrc
print(len(filtersrc.sources()))")
  mkdir -p "$SRC_PROBE/ext/modules"
  printf 'local M = {}\nreturn M\n' > "$SRC_PROBE/ext/modules/probe.lua"
  AFTER=$(QI_EXT_DIR="$SRC_PROBE/ext" python3 -c "
import sys; sys.path.insert(0,'tests'); import filtersrc
print(len(filtersrc.sources()))")
  [ "$AFTER" -eq $((BEFORE + 1)) ] \
    || fail "M16-AC2: adding modules/probe.lua took the source set from $BEFORE to $AFTER, not $((BEFORE + 1)); the enumeration is not reaching subdirectories"

  # And an enumeration that finds nothing must refuse, not sweep an empty
  # domain — the vacuous pass this whole milestone exists to prevent.
  mkdir -p "$SRC_PROBE/empty"
  if QI_EXT_DIR="$SRC_PROBE/empty" python3 -c "
import sys; sys.path.insert(0,'tests'); import filtersrc
filtersrc.sources()" >/dev/null 2>&1; then
    fail "M16-AC2: filtersrc.sources() returned successfully with no .lua files; every source-reading check would sweep nothing and pass"
  fi
  pass "M16-AC2: the enumeration reaches modules/ ($BEFORE -> $AFTER with no edit here) and refuses an empty source set"

  # -------------------------------------------------------------------------
  # M20 — every check the milestone adds, shown discriminating.
  #
  # A green check is evidence about what it covers, not about the code, and a
  # check that cannot fail covers nothing (the M01 lesson, extended four times
  # since). Each reader is re-run against a copy of its own artifact with a
  # defect planted in it, and must FAIL — and the defects vary FORM as well as
  # site, so that one exemplar cannot stand in for the family: the emphasis on
  # the wrong locator, on every locator, on none, and a warning suppressed in
  # one format alone are four different ways for this feature to be broken.
  # -------------------------------------------------------------------------
  probe_defect() {
    local label="$1"; shift
    if ( "$@" ) >/dev/null 2>&1; then
      fail "self-test: the check passed on an artifact with <<$label>> planted in it"
    fi
    printf 'ok   self-test: the check fails on <<%s>>\n' "$label"
  }

  # Named for what they are rather than for the milestone that first needed
  # them: M21 reuses all three, and a second copy would be the duplicated-reader
  # shape M16 recorded.
  #
  # A plant that changes nothing would be reported above as the CHECK failing
  # to discriminate, when the fault is the probe's — a defect wearing the
  # costume of a finding (the discipline tests/plantdefect.py states). Every
  # mutation below therefore goes through here, which refuses a no-op. It bit
  # once already: gfm wraps a long line inside a tag, so a sed aimed at a whole
  # `<span ...>text</span>` matched nothing and the check "passed" on an
  # unmutated file.
  probe_plant() {
    local src="$1" dst="$2"; shift 2
    sed "$@" "$src" > "$dst"
    if cmp -s "$src" "$dst"; then
      fail "self-test: the defect aimed at $dst planted nothing — the check that follows would be reported as failing to discriminate when the fault is this mutation's"
    fi
  }

  # Some mutations below straddle makeindex's own line wrapping — the shape a
  # reader must collapse before it reads anything — so they cannot be aimed
  # with a line-at-a-time sed. Same no-op refusal as probe_plant.
  probe_plantpl() {
    local src="$1" dst="$2" expr="$3"
    perl -0777 -pe "$expr" "$src" > "$dst"
    if cmp -s "$src" "$dst"; then
      fail "self-test: the defect aimed at $dst planted nothing — the check that follows would be reported as failing to discriminate when the fault is this mutation's"
    fi
  }

  M20W="$WORK/m20-planted"
  rm -rf "$M20W"; mkdir -p "$M20W"

  # --- the compiled index and the registry it is read against. The emphasis is
  #     no longer IN the .ind (D-007), so these plants are aimed at the two
  #     properties that replaced it: that a key's every locator carries one
  #     identifier, and that the .aux registers exactly those identifiers from
  #     pages their own entries list. Both artifacts are planted in, and one
  #     registration is planted in the `\csname` form as well as the ordinary
  #     one, so the reader is shown to depend on the form it claims to read.
  cp "$WORK/principal.ilg" "$M20W/clean.ilg"
  cp "$WORK/principal.ind" "$M20W/clean.ind"
  cp "$WORK/principal.aux" "$M20W/clean.aux"
  m20_ind() {
    python3 tests/m20probes.py ind "$1" "$2" "$3" "$LOCATOR_CMD" "$PRINCIPALPAGE_CMD"
  }
  # (i) two locators of one key carrying different identifiers — the emission
  #     that makes a shared page a render-breaking conflict, and the one thing
  #     the uniform encapsulation exists to make unreachable.
  probe_plant "$WORK/principal.ind" "$M20W/split.ind" \
    -e "s/{qi1}}{5}/{qi9}}{5}/"
  probe_defect "two locators of one key carrying different identifiers" \
    m20_ind "$M20W/split.ind" "$M20W/clean.ilg" "$M20W/clean.aux"
  # (ii) a key's locators on adjacent pages. Not cosmetic: makeindex folds a run
  #      of three into a `--` range, which is a page string the registry cannot
  #      match, so the entry would print with no emphasis while every other
  #      clause still passed. This is the trap the fixture's filler pages avoid.
  probe_plant "$WORK/principal.ind" "$M20W/adjacent.ind" \
    -e "s/{qi1}}{5}/{qi1}}{4}/"
  probe_defect "a principal key's locators on adjacent pages" \
    m20_ind "$M20W/adjacent.ind" "$M20W/clean.ilg" "$M20W/clean.aux"
  # (iii) the encapsulation leaking onto the role-free control, which no clause
  #       reading the principal entries would ever show.
  probe_plant "$WORK/principal.ind" "$M20W/control.ind" \
    -e "s/faun, \\\\hyperpage{7, 8}/faun, \\\\hyperxindexformat{\\\\$LOCATOR_CMD{qi5}}{7, 8}/"
  probe_defect "the locator encapsulation leaking onto the role-free control entry" \
    m20_ind "$M20W/control.ind" "$M20W/clean.ilg" "$M20W/clean.aux"
  # (iv) a contested key that stopped folding its cross-reference into the
  #      printed text, and one that folds it after its locator rather than
  #      before. The second straddles the .ind's own line break.
  probe_plant "$WORK/principal.ind" "$M20W/unfolded.ind" \
    -e "s/gorgon, \\\\see{basilisk}{}, /gorgon, /"
  probe_defect "a contested key no longer folding its cross-reference into its printed text" \
    m20_ind "$M20W/unfolded.ind" "$M20W/clean.ilg" "$M20W/clean.aux"
  probe_plantpl "$WORK/principal.ind" "$M20W/afterfold.ind" \
    's/\\see\{basilisk\}\{\}, (\s*)(\\hyperxindexformat\{\\quartoindexlocator\{qi2\}\}\{9\})/$2, $1\\see{basilisk}{}/'
  probe_defect "a contested key printing its cross-reference after its locator" \
    m20_ind "$M20W/afterfold.ind" "$M20W/clean.ilg" "$M20W/clean.aux"
  # (v) the registry, four ways. A registration dropped; two collapsed onto one
  #     identifier; one moved to a page its entry does not list; and one moved
  #     to a page it DOES list, which only the principal mark's own position
  #     rules out.
  probe_plant "$WORK/principal.aux" "$M20W/dropped.aux" \
    -e "/$PRINCIPALPAGE_CMD{qi1}/d"
  probe_defect "a registration dropped from the .aux" \
    m20_ind "$M20W/clean.ind" "$M20W/clean.ilg" "$M20W/dropped.aux"
  probe_plant "$WORK/principal.aux" "$M20W/collapsed.aux" \
    -e "s/$PRINCIPALPAGE_CMD{qi2}{9}/$PRINCIPALPAGE_CMD{qi1}{5}/"
  probe_defect "two registrations collapsed onto one identifier" \
    m20_ind "$M20W/clean.ind" "$M20W/clean.ilg" "$M20W/collapsed.aux"
  probe_plant "$WORK/principal.aux" "$M20W/offentry.aux" \
    -e "s/$PRINCIPALPAGE_CMD{qi1}{3}/$PRINCIPALPAGE_CMD{qi1}{4}/"
  probe_defect "a registration naming a page its own entry does not list" \
    m20_ind "$M20W/clean.ind" "$M20W/clean.ilg" "$M20W/offentry.aux"
  probe_plant "$WORK/principal.aux" "$M20W/wrongpage.aux" \
    -e "s/$PRINCIPALPAGE_CMD{qi1}{3}/$PRINCIPALPAGE_CMD{qi1}{1}/"
  probe_defect "a registration on a page of its entry the principal mark is not on" \
    m20_ind "$M20W/clean.ind" "$M20W/clean.ilg" "$M20W/wrongpage.aux"
  # (vi) the same registration written the OTHER way it can be written — the
  #      expanded `\csname` form the injected reader itself uses. The effect on
  #      the render is identical; the reader must not be satisfied by it, since
  #      what it is checking is what the filter emitted, not what LaTeX did.
  probe_plant "$WORK/principal.aux" "$M20W/csname.aux" \
    -e "s/\\\\$PRINCIPALPAGE_CMD{qi1}{3}/\\\\expandafter\\\\gdef\\\\csname qi@p@qi1@3\\\\endcsname{}/"
  probe_defect "a registration written in the expanded csname form" \
    m20_ind "$M20W/clean.ind" "$M20W/clean.ilg" "$M20W/csname.aux"
  # (vii) the transcript half: makeindex reporting a conflict the check must not
  #       read past. Planted in the .ilg alone, with the .ind left correct.
  # Two clauses, two plants, each through the no-op guard — the reader asserts
  # the absence of the conflict line AND a zero warning count, and a single
  # mutation that broke both would show neither clause to be load-bearing
  # (review round 2, R2-F11; the previous version also carried an `awk` line
  # whose `print` ran before its `next`, so it filtered nothing at all).
  probe_plant "$WORK/principal.ilg" "$M20W/counted.ilg" \
    -e 's/0 warnings)/1 warning)/'
  probe_defect "a nonzero warning count in the makeindex transcript" \
    m20_ind "$M20W/clean.ind" "$M20W/counted.ilg" "$M20W/clean.aux"
  probe_plant "$WORK/principal.ilg" "$M20W/warned.ilg" \
    -e 's|^Output written|## Warning: Conflicting entries: multiple encaps for the same page under same key.\n&|'
  probe_defect "a conflicting-encapsulation line in the makeindex transcript" \
    m20_ind "$M20W/clean.ind" "$M20W/warned.ilg" "$M20W/clean.aux"

  # --- the preamble. Review F4 records this criterion as having no planted
  #     defect at all; here are four, on both halves and in two forms — a
  #     definition that is not a \providecommand, one that is not in the
  #     preamble, one hidden behind a name built at expansion time, and one
  #     injected into a document with no principal mention.
  m20_tex() {
    python3 tests/m20probes.py tex "$1" "$2" \
      "$PRINCIPAL_CMD" "$LOCATOR_CMD" "$REGISTER_CMD" "$PRINCIPALPAGE_CMD"
  }
  probe_plant "$WORK/principal.tex" "$M20W/notprovide.tex" \
    -e "s/providecommand\\*\\\\$REGISTER_CMD\\[1\\]/gdef\\\\$REGISTER_CMD/"
  probe_defect "a subsystem command defined with something other than \\providecommand" \
    m20_tex "$M20W/notprovide.tex" examples/content.tex
  probe_plantpl "$WORK/principal.tex" "$M20W/belowdoc.tex" \
    's/\\providecommand\*\\quartoindexprincipal\[1\]\{\\textbf\{\#1\}\}\n//; s/(\\begin\{document\})/$1\n\\providecommand*\\quartoindexprincipal[1]{\\textbf{\#1}}/'
  probe_defect "a subsystem command defined below \\begin{document} rather than in the preamble" \
    m20_tex "$M20W/belowdoc.tex" examples/content.tex
  probe_plantpl "$WORK/principal.tex" "$M20W/csname.tex" \
    's/(\\begin\{document\})/\\expandafter\\def\\csname quartoindexextra\\endcsname{}\n$1/'
  probe_defect "a quartoindex command whose name is built with \\csname" \
    m20_tex "$M20W/csname.tex" examples/content.tex
  probe_plantpl examples/content.tex "$M20W/leakedpre.tex" \
    's/(\\begin\{document\})/\\providecommand*\\quartoindexlocator[2]{}\n$1/'
  probe_defect "the subsystem injected into a document with no principal mention" \
    m20_tex "$WORK/principal.tex" "$M20W/leakedpre.tex"

  # --- the HTML index. The class and the emphasis node are separable, so each
  #     is removed on its own: a check asserting only one of the two would pass
  #     on the artifact that lost the other.
  probe_plant examples/principal.html "$M20W/wrongmark.html" \
    -e 's/<a href="#qi-mark-2" class="qi-principal"><strong>2<\/strong><\/a>/<a href="#qi-mark-2">2<\/a>/' \
    -e 's/<a href="#qi-mark-1">1<\/a>/<a href="#qi-mark-1" class="qi-principal"><strong>1<\/strong><\/a>/'
  probe_defect "the HTML emphasis on the first mention instead of the principal one" \
    env HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" \
    python3 tests/m20probes.py html "$M20W/wrongmark.html"
  probe_plant examples/principal.html "$M20W/noclass.html" \
    -e 's/class="qi-principal"><strong>2<\/strong>/><strong>2<\/strong>/'
  probe_defect "the class dropped from the HTML principal locator" \
    env HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" \
    python3 tests/m20probes.py html "$M20W/noclass.html"
  probe_plant examples/principal.html "$M20W/nostrong.html" \
    -e 's/class="qi-principal"><strong>2<\/strong><\/a>/class="qi-principal">2<\/a>/'
  probe_defect "the emphasis node dropped from the HTML principal locator" \
    env HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" \
    python3 tests/m20probes.py html "$M20W/nostrong.html"

  # --- the back-end-less format. The ARIA-role defect the attribute was
  #     renamed to avoid is planted directly, since no filter change can
  #     produce it any more and it is the one this criterion exists for.
  probe_plant examples/principal.md "$M20W/aria.md" \
    -e 's/data-mention="principal"/role="principal"/'
  probe_defect "a literal ARIA role attribute in the pass-through format" \
    python3 tests/m20probes.py gfm "$M20W/aria.md" "$WORK/principal-gfm-spans.txt"
  # Aimed at the attribute alone, not at the whole span: gfm wraps a long
  # line inside the tag, so a pattern spanning the element matches nothing.
  probe_plant examples/principal.md "$M20W/residue.md" \
    -e 's/data-mention="paramount"/data-mention="paramount" data-qi-pending="4"/'
  probe_defect "the filter's own plumbing attribute surviving into the pass-through format" \
    python3 tests/m20probes.py gfm "$M20W/residue.md" "$WORK/principal-gfm-spans.txt"
  # The three axes the manifest comparison adds over the residue sweep, each
  # planted on its own: a mark the render lost, one it gained, and two the
  # filter emitted in the wrong order. The last is what a reader that sorted
  # its spans before comparing could not catch at all.
  probe_plant examples/principal.md "$M20W/dropped.md" \
    -e 's|<span class="index" data-mention="paramount">dryad</span>|dryad|'
  probe_defect "an index mark missing from the pass-through render" \
    python3 tests/m20probes.py gfm "$M20W/dropped.md" "$WORK/principal-gfm-spans.txt"
  probe_plant examples/principal.md "$M20W/extra.md" \
    -e 's|<span class="index">faun</span>|<span class="index">faun</span> and <span class="index">faun</span>|'
  probe_defect "an index mark the fixture never wrote appearing in the pass-through render" \
    python3 tests/m20probes.py gfm "$M20W/extra.md" "$WORK/principal-gfm-spans.txt"
  probe_plant examples/principal.md "$M20W/transposed.md" \
    -e 's|<span class="index" data-mention="paramount">dryad</span>|@@QI@@|' \
    -e 's|<span class="index" data-mention="">ettin</span>|<span class="index" data-mention="paramount">dryad</span>|' \
    -e 's|@@QI@@|<span class="index" data-mention="">ettin</span>|'
  probe_defect "two index marks emitted in the wrong order" \
    python3 tests/m20probes.py gfm "$M20W/transposed.md" "$WORK/principal-gfm-spans.txt"
  # The nested-markup mark, mangled: the span the widened scan exists to
  # enumerate. A scan that could not see it would drop it from the domain
  # rather than fail, so the defect has to be inside that span's own text.
  probe_plant examples/principal.md "$M20W/nested.md" \
    -e 's|<span class="index" data-mention="principal">\*\*kraken\*\*</span>|<span class="index" data-mention="principal">kraken</span>|'
  probe_defect "the nested inline markup stripped from a mark's visible text" \
    python3 tests/m20probes.py gfm "$M20W/nested.md" "$WORK/principal-gfm-spans.txt"

  # --- the counterfactual. Both directions: a role that stopped taking effect,
  #     and one that reached a mark it must not.
  probe_plant "$WORK/principal.tex" "$M20W/inert.tex" \
    -e "s/|$LOCATOR_CMD{qi[0-9]*}//g" -e "s/\\\\$REGISTER_CMD{qi[0-9]*}//g"
  probe_defect "the role taking no effect at all" \
    python3 tests/m20probes.py twin "$M20W/inert.tex" "$WORK/principal-twin.tex"
  probe_plant "$WORK/principal.tex" "$M20W/leaked.tex" \
    -e "s/\\\\index{faun}/\\\\index{faun|$LOCATOR_CMD{qi1}}/"
  probe_defect "the role reaching the role-free control mark" \
    python3 tests/m20probes.py twin "$M20W/leaked.tex" "$WORK/principal-twin.tex"
  # Only the PRINCIPAL mark's own command encapsulated, which is the emission
  # D-007 replaced: it reads correctly in every document whose marks happen to
  # sit on different pages, and breaks the render in the one where they do not.
  probe_plant "$WORK/principal.tex" "$M20W/perlocator.tex" \
    -e "s/{basilisk|$LOCATOR_CMD{qi1}}/{basilisk}/g"
  probe_defect "only the principal mark of a key encapsulated, its plain locators bare" \
    python3 tests/m20probes.py twin "$M20W/perlocator.tex" "$WORK/principal-twin.tex"
  # And the registration dropped while the encapsulation stays, which prints a
  # uniform, conflict-free, entirely unemphasized entry.
  probe_plant "$WORK/principal.tex" "$M20W/unregistered.tex" \
    -e "s/\\\\$REGISTER_CMD{qi1}//"
  probe_defect "the principal mark emitting no registration" \
    python3 tests/m20probes.py twin "$M20W/unregistered.tex" "$WORK/principal-twin.tex"

  # --- the two reports, on both axes and in every format. `warn_discrimination`
  #     is the existing tool for the missing/duplicated axis; the loop puts it
  #     over all three formats, which is the axis a report that quietly stopped
  #     being format-neutral would slip through.
  for fmt in latex html gfm; do
    warn_discrimination "$WORK/principal-$fmt.log" "$M20_NOLOCATOR" 2 \
      "M20-AC3 ($fmt)"
    warn_discrimination "$WORK/principal-$fmt.log" "$M20_UNINDEXED" 1 \
      "M20-AC3 (a mark that indexes nothing, $fmt)"
    warn_discrimination "$WORK/principal-$fmt.log" "$M20_UNKNOWN" 2 \
      "M20-AC4 ($fmt)"
  done
  # --- the T9 regressions. One plant per shape the fixture exists to hold, so
  #     a reader that stopped reading any one of them is caught rather than
  #     silently carrying it.
  cp "$WORK/principal-cases.ilg" "$M20W/cases-clean.ilg"
  cp "$WORK/principal-cases.ind" "$M20W/cases-clean.ind"
  cp "$WORK/principal-cases.aux" "$M20W/cases-clean.aux"
  cp "$WORK/principal-cases-pdf.log" "$M20W/cases-clean.log"
  m20_cases() {
    python3 tests/m20probes.py cases "$1" "$2" "${3:-$M20W/cases-clean.ind}" \
      "${4:-$M20W/cases-clean.aux}" "${5:-$M20W/cases-clean.log}"
  }
  probe_plant "$WORK/principal-cases.txt" "$M20W/samepage.txt" \
    -e "s/^wyvern, \[P:1\], 2$/wyvern, 1, 2/"
  probe_defect "the same-page pair printing with no emphasis at all" \
    m20_cases "$M20W/samepage.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/bothpages.txt" \
    -e "s/^wyvern, \[P:1\], 2$/wyvern, [P:1], [P:2]/"
  probe_defect "the emphasis spreading from the registered page to its neighbour" \
    m20_cases "$M20W/bothpages.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/footnote.txt" \
    -e "s/^naga, \[P:2\]$/naga, 2/"
  probe_defect "a principal mark in a footnote losing its registration" \
    m20_cases "$M20W/footnote.txt" "$M20W/cases-clean.ilg"
  # --- the three shapes review round 2 found unexercised. Each is a page the
  #     defect R2-F1 got wrong, and each plant is the printed form that defect
  #     actually produced, not an invented one.
  probe_plant "$WORK/principal-cases.txt" "$M20W/notfirst.txt" \
    -e "s/^troll, 9, \[P:10\]$/troll, 9, 10/"
  probe_defect "a registered page that is not first in its list printing plain" \
    m20_cases "$M20W/notfirst.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/multichar.txt" \
    -e "s/^undine, \[P:11\]$/undine, 11/"
  probe_defect "a page number of more than one character printing plain" \
    m20_cases "$M20W/multichar.txt" "$M20W/cases-clean.ilg"
  # The degradation is ASSERTED, not tolerated: were a future makeindex or a
  # future registry to start matching a range, this fixture is what says so,
  # and README's claim about it would then be stale. Both ranges are planted —
  # the one registered at its middle page and the one registered at its first,
  # which is the range a per-token split could still mark.
  probe_plant "$WORK/principal-cases.txt" "$M20W/range.txt" \
    -e "s/^oni, 3–5$/oni, [P:3–5]/"
  probe_defect "a folded page range printing emphasized, which README says it does not" \
    m20_cases "$M20W/range.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/rangehead.txt" \
    -e "s/^sylph, 6–8$/sylph, [P:6]–8/"
  probe_defect "a range whose first page is registered printing emphasized" \
    m20_cases "$M20W/rangehead.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/foldrole.txt" \
    -e "s/^folk, kin, \[P:11\]$/folk, kin, 11/"
  probe_defect "a role dropped from a mark whose target only self-references after the fold" \
    m20_cases "$M20W/foldrole.txt" "$M20W/cases-clean.ilg"
  probe_plant "$WORK/principal-cases.txt" "$M20W/cases-control.txt" \
    -e "s/^pixie, 12, 13$/pixie, [P:12], 13/"
  probe_defect "the emphasis reaching the role-free control in the regression fixture" \
    m20_cases "$M20W/cases-control.txt" "$M20W/cases-clean.ilg"
  # The redefinition itself: with the author's marker gone, every emphasis claim
  # above becomes unreadable rather than false, which is what makes this fixture
  # depend on the promise README makes.
  probe_plant "$WORK/principal-cases.txt" "$M20W/nomarker.txt" \
    -e "s/\[P:\([0-9–-]*\)\]/\1/g"
  probe_defect "the author's redefinition of the emphasis command not taking effect" \
    m20_cases "$M20W/nomarker.txt" "$M20W/cases-clean.ilg"
  # The registry half: the printed index is unchanged and the .aux moves under
  # it, so the derivation and the page disagree — which is the direction a
  # hand-written oracle cannot see at all.
  probe_plant "$WORK/principal-cases.aux" "$M20W/cases-moved.aux" \
    -e "s/{qi5}{10}/{qi5}{9}/"
  probe_defect "a registration moved to the other locator of its own entry" \
    m20_cases "$WORK/principal-cases.txt" "$M20W/cases-clean.ilg" \
      "$M20W/cases-clean.ind" "$M20W/cases-moved.aux"
  # The two shapes a reader deriving its expectation from the .aux CANNOT see
  # unless it holds an independent statement of where each principal mark sits:
  # here the registry and the printed page are mutated TOGETHER, which is what a
  # real defect in the registration would do, and the previous derived-only
  # reader passed both (review round 3). The first lands on a page the entry
  # does not carry at all; the second on the entry's own other locator.
  probe_plant "$WORK/principal-cases.aux" "$M20W/cases-offpage.aux" \
    -e "s/{qi2}{2}/{qi2}{3}/"
  probe_plant "$WORK/principal-cases.txt" "$M20W/cases-offpage.txt" \
    -e "s/^naga, \[P:2\]$/naga, 2/"
  probe_defect "a registration on a page its own entry does not carry, with the printed index agreeing" \
    m20_cases "$M20W/cases-offpage.txt" "$M20W/cases-clean.ilg" \
      "$M20W/cases-clean.ind" "$M20W/cases-offpage.aux"
  probe_plant "$WORK/principal-cases.aux" "$M20W/cases-otherloc.aux" \
    -e "s/{qi1}{1}/{qi1}{2}/"
  probe_plant "$WORK/principal-cases.txt" "$M20W/cases-otherloc.txt" \
    -e "s/^wyvern, \[P:1\], 2$/wyvern, 1, [P:2]/"
  probe_defect "the same-page pair registered from its other locator, with the printed index agreeing" \
    m20_cases "$M20W/cases-otherloc.txt" "$M20W/cases-clean.ilg" \
      "$M20W/cases-clean.ind" "$M20W/cases-otherloc.aux"
  probe_plant "$WORK/principal-cases.ilg" "$M20W/cases-warned.ilg" \
    -e 's/0 warnings)/1 warning)/'
  probe_defect "a makeindex warning on the fixture carrying the same-page pair" \
    m20_cases "$WORK/principal-cases.txt" "$M20W/cases-warned.ilg"
  # The contradiction round 1 returned this milestone for, in the shape the
  # earlier repair did not reach: the report that must NOT be drawn.
  probe_plant "$WORK/principal-cases-pdf.log" "$M20W/cases-contradict.log" \
    -e 's|^Output created|(W) mention="principal" on entry="deep!water!folk!kin" carries see= as well, and a cross-reference takes the place of a locator, so this mark has no locator to emphasize\n&|'
  probe_defect "a mark told it has no locator to emphasize though the fold gave it one" \
    m20_cases "$WORK/principal-cases.txt" "$M20W/cases-clean.ilg" \
      "$M20W/cases-clean.ind" "$M20W/cases-clean.aux" "$M20W/cases-contradict.log"

  pass "M20 self-test: every reader the milestone adds fails on a planted defect of each kind it names, and both reports are shown discriminating in all three formats"

  # -------------------------------------------------------------------------
  # M21 — every check the range milestone adds, shown discriminating.
  #
  # The plants vary FORM as well as site, so one exemplar cannot stand in for
  # the family: a range's two ends can disagree in their ENCAPSULATOR or in
  # their KEY (makeindex pairs on the key and reconciles on the encapsulator,
  # and the two faults are different faults); a range can lose its pairing and
  # print as two locators; a registration can name a page the printed range
  # does not cover; the HTML locator can point at the closing mark instead of
  # the opening one, or the closing mark can contribute one of its own; and a
  # pairing report can name the wrong mark, which is the fault a count alone
  # would pass (the M08 lesson).
  #
  # Reused rather than re-declared: `probe_defect`, `probe_plant` and `probe_plantpl`
  # are the run's own no-op-refusing mutation helpers, and a second copy of
  # them here would be the duplicated-reader shape M16 recorded.
  # -------------------------------------------------------------------------
  M21W="$WORK/m21-planted"
  rm -rf "$M21W"; mkdir -p "$M21W"
  cp "$WORK/range.ind" "$M21W/clean.ind"
  cp "$WORK/range.ilg" "$M21W/clean.ilg"
  cp "$WORK/range.aux" "$M21W/clean.aux"
  m21_ind() {
    python3 tests/m21probes.py ind "$1" "$2" "$3" \
      "$LOCATOR_CMD" "$PRINCIPALPAGE_CMD" "$RANGEAT_CMD" "$RANGETO_CMD"
  }
  m21_tex() {
    python3 tests/m21probes.py tex "$1" "$LOCATOR_CMD" \
      "$RANGEFROM_CMD" "$RANGEEND_CMD"
  }
  m21_html() {
    HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" \
      HTML_SECTION_ID="$HTML_SECTION_ID" python3 tests/m21probes.py html "$1"
  }
  # The unmutated artifacts must pass, or every failure below would prove only
  # that the readers always fail.
  m21_ind "$M21W/clean.ind" "$M21W/clean.ilg" "$M21W/clean.aux" >/dev/null \
    || fail "M21 self-test: the reader fails on the unplanted artifacts, so no failure below is evidence of anything"

  # (i) a range that lost its pairing and printed as two locators — the whole
  #     feature failing, in the shape it fails in when a verdict is dropped.
  m21_plantpl_two='s/\\hyperpage\{1--3\}/\\hyperpage{1}, \\hyperpage{3}/'
  probe_plantpl "$M21W/clean.ind" "$M21W/two.ind" "$m21_plantpl_two"
  probe_defect "a range printed as two separate locators" \
    m21_ind "$M21W/two.ind" "$M21W/clean.ilg" "$M21W/clean.aux"
  # (ii) a range narrowed to the wrong extent: the printed span no longer
  #      covers the pages the fixture separates its marks by, which is the one
  #      thing this reader takes from the source rather than from the output.
  probe_plant "$M21W/clean.ind" "$M21W/short.ind" -e 's/{1--3}/{1--2}/'
  probe_defect "a range covering fewer pages than the fixture separates its marks by" \
    m21_ind "$M21W/short.ind" "$M21W/clean.ilg" "$M21W/clean.aux"
  # (iii) a registration composing a string the printed range is not — the
  #       lookup then finds nothing and the range prints unemphasized, which
  #       is exactly the degradation D-008 exists to close.
  probe_plant "$M21W/clean.aux" "$M21W/offpage.aux" \
    -e "s/${RANGETO_CMD}{qi1}{6}/${RANGETO_CMD}{qi1}{9}/"
  probe_defect "a range registered under a string it does not print" \
    m21_ind "$M21W/clean.ind" "$M21W/clean.ilg" "$M21W/offpage.aux"
  # (iii-b) the SAME-PAGE range's closing registered from a wrong page. The
  #         printed string is the opening page alone, so a disjunctive reader
  #         satisfied by either equality never read the closing at all and
  #         this plant passed it (review R4-F6); the shape-split reader
  #         requires the two ends of a one-page span to register one page.
  probe_plant "$M21W/clean.aux" "$M21W/offclose.aux" \
    -e "s/${RANGETO_CMD}{qi2}{14}/${RANGETO_CMD}{qi2}{15}/"
  probe_defect "a same-page range whose closing registers a different page" \
    m21_ind "$M21W/clean.ind" "$M21W/clean.ilg" "$M21W/offclose.aux"
  # (iv) a registration under a different ordinal from the one its own locator
  #      carries: the two artifacts stop being about the same entry.
  probe_plant "$M21W/clean.aux" "$M21W/otherid.aux" \
    -e "s/${RANGEAT_CMD}{qi1}/${RANGEAT_CMD}{qi7}/"
  probe_defect "a range opening registered under an ordinal no locator carries" \
    m21_ind "$M21W/clean.ind" "$M21W/clean.ilg" "$M21W/otherid.aux"
  # (v) a makeindex transcript carrying a range warning — the line Quarto fails
  #     a render on, and the one the emission discipline exists to avoid.
  probe_plant "$M21W/clean.ilg" "$M21W/warned.ilg" \
    -e 's/0 warnings/1 warning/' \
    -e 's/^Output written/## Warning: -- Unmatched range opening operator (.\nOutput written/'
  probe_defect "a makeindex transcript reporting an unmatched range" \
    m21_ind "$M21W/clean.ind" "$M21W/warned.ilg" "$M21W/clean.aux"

  # --- the emitted LaTeX, where the two ends are written.
  m21_tex "$WORK/range.tex" >/dev/null \
    || fail "M21 self-test: the tex reader fails on the unplanted render"
  # (vi) the two ends disagreeing on their ENCAPSULATOR — makeindex logs an
  #      inconsistent-encapsulator warning and Quarto fails the render.
  probe_plant "$WORK/range.tex" "$M21W/encap.tex" \
    -e "s/|)${LOCATOR_CMD}{qi1}/|)${LOCATOR_CMD}{qi5}/"
  probe_defect "a closing encapsulation that does not match its opening" \
    m21_tex "$M21W/encap.tex"
  # (vii) the two ends emitted under different KEYS — a different fault from
  #       (vi): makeindex pairs on the key, so this one leaves an unmatched
  #       opening and an unmatched closing rather than a mismatched pair.
  probe_plant "$WORK/range.tex" "$M21W/keys.tex" \
    -e 's/\\index{alicorn|)}/\\index{alicorne|)}/'
  probe_defect "a range whose two ends are emitted under different keys" \
    m21_tex "$M21W/keys.tex"
  # (viii) a range end emitted with no delimiter at all — the pre-milestone
  #        emission, which prints two locators rather than one.
  probe_plant "$WORK/range.tex" "$M21W/nodelim.tex" \
    -e 's/\\index{alicorn|(}/\\index{alicorn}/'
  probe_defect "a range opening emitted as an ordinary locator" \
    m21_tex "$M21W/nodelim.tex"
  # (ix) a principal range whose closing never registers its page: the range
  #      string is then never composed and the entry prints unemphasized.
  probe_plant "$WORK/range.tex" "$M21W/noreg.tex" \
    -e "s/\\\\${RANGEEND_CMD}{qi1}//"
  probe_defect "a principal range whose closing registers nothing" \
    m21_tex "$M21W/noreg.tex"

  # --- the HTML index.
  m21_html examples/range.html >/dev/null \
    || fail "M21 self-test: the html reader fails on the unplanted render"
  # (x) the locator pointing at the CLOSING mark rather than the opening one —
  #     a link that works, to the wrong end of the discussion.
  probe_plantpl examples/range.html "$M21W/closeanchor.html" \
    's/href="#qi-mark-1"/href="#qi-mark-2"/'
  probe_defect "a range locator pointing at its closing mark" \
    m21_html "$M21W/closeanchor.html"
  # (xi) the closing mark contributing a locator of its own, which is the
  #      pre-milestone behavior: two locators where a reader wants one.
  probe_plantpl examples/range.html "$M21W/twolinks.html" \
    's{(<span class="qi-locators"><a href="#qi-mark-1"[^>]*>1</a>)}{$1, <a href="#qi-mark-2">2</a>}'
  probe_defect "a closing mark contributing a locator of its own" \
    m21_html "$M21W/twolinks.html"
  # (xii) the emphasis on a range whose opening is not principal.
  probe_plantpl examples/range.html "$M21W/wrongmark.html" \
    's{<a href="#qi-mark-1">1</a>}{<a href="#qi-mark-1" class="qi-principal"><strong>1</strong></a>}'
  probe_defect "a plain range printed as the principal one" \
    m21_html "$M21W/wrongmark.html"

  # --- the book index, whose reader the round-2 return was taken on and which
  #     had no plant of its own until round 3 said so (R3-F2). Three forms: the
  #     removed cross-chapter pairing coming back, the in-chapter pairing being
  #     lost, and the role dropped from the mark that declares it.
  m21_bookhtml() {
    HTML_PRINCIPAL_CLASS="$HTML_PRINCIPAL_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" \
      python3 tests/m21probes.py bookhtml "$1"
  }
  m21_bookhtml "$WORK/book-last.html" >/dev/null \
    || fail "M21 self-test: the book reader fails on the unplanted render"
  probe_plantpl "$WORK/book-last.html" "$M21W/bookmerged.html" \
    's{, <a href="sub/two\.html\#qi-mark-3"[^>]*><strong>2</strong></a>}{}'
  probe_defect "a cross-chapter range merged into one locator again" \
    m21_bookhtml "$M21W/bookmerged.html"
  probe_plantpl "$WORK/book-last.html" "$M21W/booknorole.html" \
    's{<a href="sub/two\.html\#qi-mark-3" class="qi-principal"><strong>2</strong></a>}{<a href="sub/two.html\#qi-mark-3">2</a>}'
  probe_defect "a book mark losing the role its own mention= declares" \
    m21_bookhtml "$M21W/booknorole.html"
  probe_plantpl "$WORK/book-last.html" "$M21W/booksplit.html" \
    's{(<a href="\#qi-mark-2">1</a>)}{$1, <a href="\#qi-mark-3">2</a>}'
  probe_defect "a range paired inside one chapter split into two locators" \
    m21_bookhtml "$M21W/booksplit.html"
  # And the book's report, by form: missing, duplicated, and naming a mark its
  # own chapter paired.
  warn_discrimination "$WORK/book-html.log" "$R_BOOKUNPAIRED" 1 "M21-AC5"
  warn_discrimination "$WORK/book-order-1.log" "$R_BOOKUNPAIRED" 1 "M21-AC5 (attribution)"
  probe_plant "$WORK/book-html.log" "$M21W/bookwrongmark.log" \
    -e 's/term "Ranged Term" in one\.qmd/term "Chapter Range" in last.qmd/'
  probe_defect "the book report naming a mark its own chapter paired" \
    check_warning_count "$M21W/bookwrongmark.log" 'term "Chapter Range"' 0 "M21 self-test"

  # --- the reports, which a count alone cannot fence.
  m21_report() {
    check_warning_count "$1" "$2" "$3" "M21 self-test"
  }
  # (xiii) a pairing report naming the wrong mark: the counts are all still
  #        right, and only the identity clause can catch it.
  probe_plant "$WORK/range-misuse-gfm.log" "$M21W/wrongmark.log" \
    -e 's/term "fenrir" is never closed/term "lamia" is never closed/'
  probe_defect "a pairing report naming the wrong mark" \
    m21_report "$M21W/wrongmark.log" 'range="open" on term "fenrir" is never closed' 1
  # (xiv) and the same log read by the control clause, which must catch the
  #       well-formed range being named at all.
  probe_defect "a report naming the well-formed range control" \
    m21_report "$M21W/wrongmark.log" 'lamia' 0
  # --- the checks the review's own findings added. Each of these guards a
  #     defect that shipped once, so each is shown discriminating here rather
  #     than trusted (the M01 lesson: a green check is evidence about what it
  #     covers, not about the code).
  # (xv) a range whose CLOSING declared the role failing to register: the
  #      silent role loss review F2 found, in the artifact that would carry it.
  probe_plant "$WORK/range.tex" "$M21W/closerole.tex" \
    -e "s/\\\\${RANGEFROM_CMD}{qi3}//"
  probe_defect "a range whose closing declared the role registering only one end" \
    m21_tex "$M21W/closerole.tex"
  # (xvi) a refused range reaching the index tool anyway — the emission that
  #       makes makeindex warn and Quarto fail the whole render (review F5).
  probe_plant "$WORK/range-misuse-latex.tex" "$M21W/leaked.tex" \
    -e 's/\\index{fenrir}/\\index{fenrir|(}/'
  probe_defect "a refused range emitting a range operator anyway" \
    python3 tests/m21probes.py misuse "$M21W/leaked.tex"
  # (xvii) the stale-`.aux` guard: a preamble that defines the subsystem but
  #        not the two commands an `.aux` line can name (review F3).
  probe_plant "$WORK/principal.tex" "$M21W/norange.tex" \
    -e "s/\\\\providecommand\\*\\\\${RANGEAT_CMD}\\[/\\\\providecommand*\\\\qiGone[/"
  probe_defect "a subsystem preamble missing a command its own .aux can name" \
    python3 tests/m21probes.py preamble "$M21W/norange.tex" \
      "$RANGEAT_CMD" "$RANGETO_CMD"
  # (xviii)/(xix) two clauses the earlier stand-in readers could not reach: a
  #         refused mark emitting a CLOSING rather than an opening, and a
  #         command defined twice rather than absent. Both readers are the
  #         run's own now (review round 2, R2-F3), so what is shown
  #         discriminating here is exactly what runs.
  probe_plant "$WORK/range-misuse-latex.tex" "$M21W/leakclose.tex" \
    -e 's/\\index{golem}/\\index{golem|)}/'
  probe_defect "a refused mark emitting a range CLOSING" \
    python3 tests/m21probes.py misuse "$M21W/leakclose.tex"
  probe_plantpl "$WORK/principal.tex" "$M21W/dupdef.tex" \
    "s/(\\\\providecommand\\*\\\\${RANGEAT_CMD}\\[2\\]\\{)/\$1\$1/"
  probe_defect "an .aux-borne command defined twice" \
    python3 tests/m21probes.py preamble "$M21W/dupdef.tex" \
      "$RANGEAT_CMD" "$RANGETO_CMD"
  pass "M21 self-test: the three checks the review's findings added — a closing-declared role reaching the registry, no refused range reaching the index tool, and every .aux-borne command defined wherever the subsystem lands — each fail on a planted defect of their own kind"

  pass "M21 self-test: every reader the milestone adds fails on a planted defect of each kind it names — a lost pairing, a wrong extent, a registration that composes the wrong string or names the wrong ordinal, a transcript warning, ends disagreeing on their encapsulator and ends disagreeing on their key, a locator at the wrong end, a second locator, a wrongly emphasized range, and a report naming the wrong mark"

  # -------------------------------------------------------------------------
  # M16-AC3 — every source-reading check keeps finding its definition once the
  # definition moves into another file. The enumeration in filtersrc.py is what
  # is supposed to make that true; nothing above proves it does, because a
  # check that reads only index.lua passes identically while the definition is
  # still there. So build a tree where it is NOT, and run the same checks
  # against it through the same run_scan invocations the run itself uses.
  #
  # The list below is the probe's INPUT — which definitions to relocate — not a
  # domain any check sweeps: one name per source-reading check, so no check is
  # left reading a definition that never moved. movedefs.py fails on a name it
  # cannot find or place, so a definition renamed out from under this list
  # stops the run rather than quietly exercising nothing.
  # -------------------------------------------------------------------------
  MOVED_DEFINITIONS='LATEX_LITERAL HTML_SECTION_ID HTML_ANCHOR_PREFIX
    HTML_ENTRY_PREFIX HTML_LETTER_CLASS XREF_BOTH_COMMAND XREF_BOTH_DEFINITION
    MARKER_CLASS STORE_VERSION STORE_SUFFIX STORE_DIR MAX_LEVELS OVERFLOW_JOIN
    clamp_levels latex_plan Span Pandoc'
  SCAN_PROBE="$WORK/scan-probe"
  rm -rf "$SCAN_PROBE"; mkdir -p "$SCAN_PROBE"
  cp -R "$QI_EXT_DIR" "$SCAN_PROBE/ext"
  # shellcheck disable=SC2086
  python3 tests/movedefs.py "$SCAN_PROBE/ext" $MOVED_DEFINITIONS \
    > "$WORK/movedefs.log" \
    || { cat "$WORK/movedefs.log" >&2; fail "M16-AC3: could not build the moved-definition tree"; }

  # Enumerated from the directory, never listed here — the same rule the source
  # set itself follows. A scan file added without an invocation in run_scan
  # fails there rather than going unprobed.
  SCAN_NAMES=$(find tests/scans -name '*.py' | sed 's|.*/||; s|\.py$||' | sort)
  SCAN_COUNT=$(printf '%s\n' "$SCAN_NAMES" | wc -l | tr -d ' ')
  # An exact count, not a floor: AC3's domain is the twelve source-reading
  # sites the merge-base run reported, and a floor would pass while one of them
  # quietly stopped being probed.
  [ "$SCAN_COUNT" -eq 12 ] \
    || fail "M16-AC3: found $SCAN_COUNT source scans under tests/scans, expected 12; either a source-reading check left the probed set or one was added without extending this proof"

  for SCAN_NAME in $SCAN_NAMES; do
    # (a) It still finds what it reads. The passing control: without it, the
    # failure below would be evidence only that the check always fails.
    ( export QI_EXT_DIR="$SCAN_PROBE/ext"; run_scan "$SCAN_NAME" ) >/dev/null \
      || fail "M16-AC3: $SCAN_NAME does not find what it reads once the definition moves to modules/moved.lua; it is reading one named file, not the source set"

    # (b) ...and it is still ASSERTING something about it. Finding a definition
    # is not reading it: a check whose pattern quietly stopped matching passes
    # (a) forever. So plant a defect of the kind this check names, in the moved
    # definition, and require the check to fail SAYING SO — the marker, not the
    # bare exit status, since a scan that died of a broken probe also exits
    # non-zero and would otherwise be read as the scan catching the defect.
    rm -rf "$SCAN_PROBE/defect"
    cp -R "$SCAN_PROBE/ext" "$SCAN_PROBE/defect"
    SCAN_EXPECT=$(python3 tests/plantdefect.py "$SCAN_PROBE/defect" "$SCAN_NAME")
    set +e
    SCAN_OUT=$( export QI_EXT_DIR="$SCAN_PROBE/defect"; run_scan "$SCAN_NAME" 2>&1 )
    SCAN_RC=$?
    set -e
    [ "$SCAN_RC" -ne 0 ] \
      || fail "M16-AC3: $SCAN_NAME passed with a defect planted in the moved definition; it finds the definition and asserts nothing about it"
    printf '%s' "$SCAN_OUT" | grep -qF -- "$SCAN_EXPECT" \
      || { printf '%s\n' "$SCAN_OUT" >&2; fail "M16-AC3: $SCAN_NAME exited $SCAN_RC on the planted defect but did not report it; expected <<$SCAN_EXPECT>>"; }
  done
  pass "M16-AC3: all $SCAN_COUNT source-reading checks still find what they read with their definitions moved into modules/moved.lua, and each one fails, naming the defect, when one of the kind it checks for is planted there"
  # Same discipline for the marker's warnings: a report of a misused marker
  # that quietly stopped firing would leave every misuse check passing on a
  # log that says nothing.
  # The suite's own exit status is an assertion like any other: a check that
  # fails only by exit status must kill the run. Run against THIS script, not
  # a mock of it, so the wrapper being proved is the wrapper that ships.
  set +e
  WRAPPER_OUT=$( "$0" --plant-wrapper-defect 2>&1 )
  WRAPPER_RC=$?
  set -e
  [ "$WRAPPER_RC" -ne 0 ] \
    || fail "AC3: the suite exited 0 with a check that failed by exit status; every manifest oracle here would be advisory"
  if printf '%s' "$WRAPPER_OUT" | grep -q 'All checks passed'; then
    fail "AC3: the suite printed its passing line after a check failed"
  fi
  if ! printf '%s' "$WRAPPER_OUT" | grep -q 'FAIL: planted wrapper defect'; then
    printf '%s\n' "$WRAPPER_OUT" >&2
    fail "AC3: the planted wrapper defect did not report itself; this proof is not testing what it claims"
  fi
  pass "AC3: a check that fails only by exit status kills the run ($WRAPPER_RC) and no passing line is printed"

  # The book's missing-marker report is the only evidence an author gets that
  # a book built no index, so a check for it that quietly stopped firing would
  # leave AC6 passing on a silent render.
  warn_discrimination "$WORK/book-nomarker.log" "$WARN_BOOK_NOMARKER" 1 \
    "M05-AC6"
  # The two store reports stand in for a failed render: if either check
  # stopped firing, a book that silently lost a chapter's entries would look
  # exactly like one that kept them.
  warn_discrimination "$WORK/book-corrupt.log" "$WARN_STORE_UNREADABLE" 1 \
    "M05 hardening"
  warn_discrimination "$WORK/book-nostore.log" "$WARN_STORE_UNWRITABLE" \
    "$ORDER_CHAPTERS" "M05 hardening"
  # The three sort-key reports are the only evidence an author gets that a
  # sort key did not do what they wrote it to do; each is proved to fail both
  # when it goes missing and when it fires twice.
  # M13's six message pins, held to the same bar: a report that quietly
  # stopped firing would leave the count checks green (review F10). The revert
  # probes in the work log proved the same thing once; these re-prove it on
  # every run.
  for fmt in html latex gfm; do
    warn_discrimination "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_LEADING" 1 \
      "M13-AC1"
    warn_discrimination "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_TRAILING" 1 \
      "M13-AC1"
    warn_discrimination "$WORK/empty-levels-$fmt.log" "$M13_EMPTY_BOTH" 1 \
      "M13-AC1"
    warn_discrimination "$WORK/empty-levels-$fmt.log" \
      "$M13_SORT_EXTRA_ENTRY" 1 "M13-AC3"
    warn_discrimination "$WORK/empty-levels-$fmt.log" \
      "$M13_SORT_EXTRA_NOENTRY" 1 "M13-AC3"
  done
  warn_discrimination "$WORK/demo-latex.log" "$M13_EMPTY_DEEP" 1 "M13-AC1"

  warn_discrimination "$WORK/sortkey-misuse-latex.log" "$WARN_SORT_ORPHAN" 1 \
    "M06-AC4"
  warn_discrimination "$WORK/sortkey-misuse-latex.log" "$WARN_SORT_EXTRA" 1 \
    "M06-AC4"
  warn_discrimination "$WORK/sortkey-misuse-latex.log" "$WARN_SORT_CONFLICT" 3 \
    "M06-AC4"
  # The cross-chapter conflict is the only report an author gets that two
  # chapters sorted one term two ways; it is proved discriminating like the
  # three a single document can draw.
  warn_discrimination "$WORK/book-order-2.log" "$WARN_BOOK_SORT_CONFLICT" 1 \
    "M06-AC4"
  # The level-fold collision is the only evidence an author gets that two
  # entries reached the index tool as two keys under one printed path; proved
  # discriminating like the reports about a mark.
  warn_discrimination "$WORK/sortkey-clamp-latex.log" "$WARN_CLAMP_SPLIT" 2 \
    "M09-AC1"
  # The count alone is the coarse half of the criterion; what carries its
  # substance is that each report names THAT pair's keys and path, so both
  # whole-message checks are proved discriminating too.
  warn_discrimination "$WORK/sortkey-clamp-latex.log" \
    'index entries printed as "alpha!beta!gamma, delta" file under more than one key ("alpha!beta!Ada" and "alpha!beta!Zed")' \
    1 "M09-AC1"
  warn_discrimination "$WORK/sortkey-clamp-latex.log" \
    'index entries printed as "mu!nu!xi, omicron, pi" file under more than one key ("mu!nu!Vee" and "mu!nu!Wye")' \
    1 "M09-AC1"
  warn_discrimination "$WORK/misuse-latex.log" "$WARN_MARKER_DUP" 1 "M04-AC4"
  warn_discrimination "$WORK/marker-nomarks-latex.log" "$WARN_MARKER_NOMARKS" 1 "M04-AC4"
  # M18-AC5: the fold-rewritten-target report, held to the same bar as every
  # other report the suite counts — the count must fail when the message is
  # missing and when it is doubled, and pass on the log as rendered.
  warn_discrimination "$WORK/fold-xref-latex.log" "$WARN_FOLD_TARGET" 5 "M18-AC5"
  warn_discrimination "$WORK/fold-xref-both-latex.log" "$WARN_FOLD_TARGET" 2 "M18-AC5"
fi


# ---------------------------------------------------------------------------
# M17-AC3 — the split extension renders identically installed and from the
# working tree.
#
# Two things could make an installed copy behave differently from this
# checkout: a module the packaging leaves behind, and a `require` that
# resolves against a directory the install does not reproduce. The first is
# closed by the position check below — every require sits at file top level,
# above that file's first definition, so a module missing from an installed
# copy fails on ANY document rather than on whichever one happens to reach the
# call. Fixture choice is therefore not an axis the install can affect, which
# leaves project shape and format; the probe takes both whole, rendering the
# same standalone fixture and the same book project from a tree that reaches
# the extension the way examples/ does and from a project that got it through
# `quarto add`.
#
# LAST in the run, after the self-test block, so the two `ok` lines it prints
# land after every line the merge base printed rather than shifting the
# self-test's own lines down by two (M17-AC2, review finding E).
# ---------------------------------------------------------------------------
python3 - <<'REQPY'
import re, sys
sys.path.insert(0, 'tests')
import filtersrc

# A definition in the sense M17-AC1 uses: the top-level, nested and assigned
# forms alike. `local M = {}` is not one, and neither is a require.
DEFN = re.compile(r'^\s*(local\s+)?function |=\s*function\(')
REQ = re.compile(r'\brequire\(')
TOP = re.compile(r'^local \w+ = require\("\./[\w/]+"\)\s*$')

per, bad, seen = {}, [], 0
for path, n, line in filtersrc.lines():
    code = re.sub(r'--.*', '', line)
    info = per.setdefault(path, {'req': [], 'def': None})
    if REQ.search(code):
        info['req'].append((n, line.strip()))
        if not TOP.match(code.rstrip()):
            bad.append('  %s:%d: not a top-level `local NAME = require("./...")`: %s'
                       % (path, n, line.strip()))
    if info['def'] is None and DEFN.search(code):
        info['def'] = n

for path, info in sorted(per.items()):
    for n, _text in info['req']:
        seen += 1
        if info['def'] is not None and n > info['def']:
            bad.append("  %s:%d: require sits below this file's first "
                       'definition, at line %d' % (path, n, info['def']))
if not seen:
    print('FAIL: M17-AC3: the source set contains no require() at all, so the '
          'position rule is asserted of nothing', file=sys.stderr)
    sys.exit(1)
if bad:
    print('FAIL: M17-AC3: require placement:', file=sys.stderr)
    print('\n'.join(bad), file=sys.stderr)
    sys.exit(1)
# Reported, not merely asserted: the criterion asks for each require line and
# each file's first definition line, and a bare count would let the rule hold
# over a source set nobody can see the shape of.
for path, info in sorted(per.items()):
    where = ('first definition at %d' % info['def']) if info['def'] else 'no definition'
    print('     %s: %s' % (path, where))
    for n, text in info['req']:
        print('       %d: %s' % (n, text))
print('ok   M17-AC3: all %d require() calls across the source set sit at file '
      'top level, above their file\'s first definition' % seen)
REQPY

IP="$WORK/install-parity"
rm -rf "$IP"
mkdir -p "$IP/stage/_extensions"
cp -R "$QI_EXT_DIR" "$IP/stage/_extensions/index"
command -v zip >/dev/null \
  || fail "M17-AC3: zip is not installed, so the extension cannot be packaged for quarto add; this check is never skipped"
( cd "$IP/stage" && zip -qr ../ext.zip _extensions ) \
  || fail "M17-AC3: could not package $QI_EXT_DIR for quarto add"
[ -s "$IP/ext.zip" ] || fail "M17-AC3: the packaged extension is empty"
# quarto add is run from inside each scratch project, so the archive it is
# handed has to be named absolutely.
IP_ABS=$( cd "$IP" && pwd )

# The working-tree side reaches the extension exactly as examples/ does: a
# symlink to the directory holding it, resolved from QI_EXT_DIR so the probe
# cannot end up comparing a tree nothing else in this run reads.
EXT_PARENT=$( cd "$(dirname "$QI_EXT_DIR")" && pwd )

# The standalone fixture, copied as itself. Nothing enumerates what it needs
# beside it — not a list of filenames and not a list of front-matter keys,
# which is the same shape one layer down. What catches an asset the copy did
# not bring is the guard further below: this run has ALREADY rendered the
# fixture in place under examples/, where every asset it has is present, and
# the probe's working-tree render is required to match that byte for byte.
SOLO_FIXTURE="examples/demo.qmd"
SOLO_NAME=$(basename "${SOLO_FIXTURE%.qmd}")
for VARIANT in tree inst; do
  mkdir -p "$IP/$VARIANT/solo"
  cp "$SOLO_FIXTURE" "$IP/$VARIANT/solo/"
  for FMT in latex html; do
    # One project per format: a book render clears its output directory, so a
    # shared project would leave only the last format's output to compare.
    # Copied whole rather than file by file, for the same reason the standalone
    # fixture's assets are derived: a chapter added to examples/book/ later
    # must reach this probe without an edit here (review finding C).
    mkdir -p "$IP/$VARIANT/book-$FMT"
    ( cd examples/book && tar cf - --exclude=_book --exclude=.quarto \
        --exclude=_extensions . ) | ( cd "$IP/$VARIANT/book-$FMT" && tar xf - ) \
      || fail "M17-AC3: could not copy examples/book into $IP/$VARIANT/book-$FMT"
    [ -f "$IP/$VARIANT/book-$FMT/_quarto.yml" ] \
      || fail "M17-AC3: the copied book project has no _quarto.yml"
  done
  for PROJ in solo book-latex book-html; do
    if [ "$VARIANT" = tree ]; then
      ln -s "$EXT_PARENT" "$IP/$VARIANT/$PROJ/_extensions"
    else
      ( cd "$IP/$VARIANT/$PROJ" && quarto add "$IP_ABS/ext.zip" --no-prompt ) \
        > "$WORK/parity-add-$PROJ.log" 2>&1 \
        || { cat "$WORK/parity-add-$PROJ.log" >&2; fail "M17-AC3: quarto add failed in $IP/$VARIANT/$PROJ"; }
      [ -f "$IP/$VARIANT/$PROJ/_extensions/index/index.lua" ] \
        || fail "M17-AC3: quarto add installed no index.lua into $IP/$VARIANT/$PROJ"
    fi
  done
done

# The book the probe renders must be the book the suite's own book checks use,
# chapter for chapter — otherwise the parity claim is made about a smaller
# project than the one that ships.
BOOK_CHAPTERS=$(find examples/book -name '*.qmd' -not -path '*/_book/*' -not -path '*/.quarto/*' | wc -l | tr -d ' ')
COPIED_CHAPTERS=$(find "$IP/tree/book-html" -name '*.qmd' | wc -l | tr -d ' ')
[ "$BOOK_CHAPTERS" -eq "$COPIED_CHAPTERS" ] \
  || fail "M17-AC3: examples/book has $BOOK_CHAPTERS chapter(s) but the probe copied $COPIED_CHAPTERS"

# Every module has to arrive: an install missing one is the failure this whole
# criterion is about, and it would otherwise surface as a render error whose
# cause the diff below cannot name.
INSTALLED=$(find "$IP/inst/solo/_extensions/index" -name '*.lua' | wc -l | tr -d ' ')
[ "$INSTALLED" -eq "$FILTER_SOURCE_COUNT" ] \
  || fail "M17-AC3: quarto add installed $INSTALLED .lua file(s), but the extension has $FILTER_SOURCE_COUNT; a module did not survive packaging"

for VARIANT in tree inst; do
  for FMT in latex html; do
    ( cd "$IP/$VARIANT/solo" && quarto render "$SOLO_NAME.qmd" --to "$FMT" ) \
      > "$WORK/parity-$VARIANT-solo-$FMT.log" 2>&1 \
      || { tail -30 "$WORK/parity-$VARIANT-solo-$FMT.log" >&2; fail "M17-AC3: the $VARIANT standalone render to $FMT failed"; }
    ( cd "$IP/$VARIANT/book-$FMT" && quarto render --to "$FMT" ) \
      > "$WORK/parity-$VARIANT-book-$FMT.log" 2>&1 \
      || { tail -30 "$WORK/parity-$VARIANT-book-$FMT.log" >&2; fail "M17-AC3: the $VARIANT book render to $FMT failed"; }
  done
done

SOLO_BASE="$IP/tree/solo/$SOLO_NAME"
# The copy brought everything the fixture needs. Asserted against this run's
# OWN in-place render of the same fixture under examples/, which has every
# asset there is: an asset the scratch copy lacks moves that render's output
# and is reported here, so no list of names has to be right (review, pass 2).
cmp -s "$WORK/demo-latex.tex" "$SOLO_BASE.tex" \
  || fail "M17-AC3: the probe's working-tree latex render of $SOLO_FIXTURE differs from this run's in-place render of the same fixture; the scratch copy is missing something the fixture needs"
cmp -s "examples/$SOLO_NAME.html" "$SOLO_BASE.html" \
  || fail "M17-AC3: the probe's working-tree html render of $SOLO_FIXTURE differs from this run's in-place render of the same fixture; the scratch copy is missing something the fixture needs"

# The comparison is only worth making if each side actually built an index. A
# pair of empty renders is byte-identical too, so all FOUR compared outputs
# carry a guard, not just the two that had one (review finding D).
grep -q '\\index{' "$SOLO_BASE.tex" \
  || fail "M17-AC3: the working-tree standalone latex render emitted no \\index command, so the parity diff below compares two documents with no index in them"
grep -q 'qi-index' "$SOLO_BASE.html" \
  || fail "M17-AC3: the working-tree standalone html render built no index section, so its parity diff proves nothing"
grep -q 'qi-index' "$IP/tree/book-html/_book/last.html" \
  || fail "M17-AC3: the working-tree book html render built no index section, so its parity diff proves nothing"
grep -rq '\\index{' "$IP/tree/book-latex/_book" \
  || fail "M17-AC3: the working-tree book latex render emitted no \\index command, so its parity diff compares two books with no index entries in them"

PARITY=0
for PAIR in "solo/$SOLO_NAME.tex" "solo/$SOLO_NAME.html" book-latex/_book book-html/_book; do
  [ -e "$IP/tree/$PAIR" ] || fail "M17-AC3: the working-tree render produced no $PAIR"
  [ -e "$IP/inst/$PAIR" ] || fail "M17-AC3: the installed render produced no $PAIR"
  PDIFF="$WORK/parity-$(printf '%s' "$PAIR" | tr '/' '-').diff"
  diff -r "$IP/tree/$PAIR" "$IP/inst/$PAIR" > "$PDIFF" 2>&1 \
    || { head -40 "$PDIFF" >&2; fail "M17-AC3: $PAIR differs between the installed extension and the working tree"; }
  PARITY=$((PARITY + 1))
done
pass "M17-AC3: all $PARITY outputs — a standalone fixture and a book project, each to latex and html — are byte-identical rendered from an extension installed by quarto add and from the working tree"

}

# `pipefail` would abort on the function's own exit status before the count is
# read, so the pipeline's status is taken from PIPESTATUS instead.
set +e
# `"$@"` so the body still sees the script's own flags (--self-test).
run_all_checks "$@" 2>&1 | tee "$RUN_LOG"
CHECK_STATUS=${PIPESTATUS[0]}
set -e
[ "$CHECK_STATUS" -eq 0 ] || exit "$CHECK_STATUS"
CHECK_COUNT=$( { grep -cE '^ok ' "$RUN_LOG" || true; } | tr -d ' ')
printf '\nAll checks passed (%s checks).\n' "$CHECK_COUNT"
