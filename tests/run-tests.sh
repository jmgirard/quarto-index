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
)

# Each must be PRESENT: one beamer-scoped pass-through sentence, and one row
# per way the two back-ends diverge. A divergence a reader is not told about is
# a bug report waiting to be filed.
README_HTML_CLAIMS=(
  $'beamer pass-through\tIn beamer, and in any other format with no index back-end, marks pass through'
  $'no level ceiling\tNo level ceiling in HTML'
  $'clash warning scope\tThe clash warning is LaTeX-only'
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
  $'report: extra levels\ta `sort=` with more levels than its entry has, whose extra levels are'
  $'report: two keys\tone entry given two different sort keys, which cannot file in two places'
  $'reaching past a level\ton the way to a deeper one declares nothing for that level'
  $'book adds a fourth report\tA book adds a fourth report, for a term two chapters sort differently'
  $'ordering is per back-end\tA sort key files an entry under the ordering of whichever back-end builds the'
  $'plain keys order alike\tSort keys of plain letters and digits order the same way in both back-ends'
  $'keys past the ceiling\tA sort key written for a level past the third goes with that level in this'
  $'two skipped levels\tTwo skipped levels cannot sit side by side'
  $'key belongs to the level\tit belongs to the entry level you wrote it for, and places that'
)

# ---------------------------------------------------------------------------
# README claims about letter groups (NORMATIVE, M07-AC6). Same discipline as
# README_HTML_CLAIMS: one row per behavior the extension documents, compared
# as bytes, so the docs and what this suite exercises cannot drift apart.
# ---------------------------------------------------------------------------
README_LETTER_CLAIMS=(
  $'label derivation\tA group label comes from the string the entry files under'
  $'sort-key precedence\tits sort key where it has one, and its printed text where it has none'
  $'letter label\tIf that string begins with an ASCII letter the label is that letter, uppercased'
  $'symbols fallback\ta digit, a punctuation mark, an accented or non-Latin letter, or an empty string — files under `Symbols`'
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
HTML_LETTER_CLASS='qi-letter'

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
#      `One!Two!Three!Four!Five!` nests six deep here, trailing empty level
#      included.
#   5. Order, in two parts (M07). Top-level entries are first RANKED INTO
#      GROUPS by the string each files under — its sort key where it has one
#      (step 8, where a manifest has sort keys), its printed text otherwise:
#      the label is that string's first character uppercased when that
#      character is an ASCII letter, and `Symbols` otherwise, the empty
#      filing string included; groups rank `Symbols` first, then A-Z, and each
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
0	A!B	0
1		1
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
4	Five	0
5		1
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
# ---------------------------------------------------------------------------
read -r -d '' BOOK_HTML_INDEX <<'MANIFEST' || true
letter	A
0	Alpha	index.html#qi-mark-2
letter	B
0	Beacon	sub/two.html#qi-mark-2
0	Beta	one.html#qi-mark-1
letter	C
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
# ---------------------------------------------------------------------------
read -r -d '' BOOK_ORDER_INDEX <<'MANIFEST' || true
0	Contested	#qi-mark-2 later chapter.html#qi-mark-2 later chapter.html#qi-mark-3 third.html#qi-mark-1
0	Early	#qi-mark-1
0	Late	later chapter.html#qi-mark-1
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
# forbids. `tests/byte-diff.sh` renders every fixture the merge base carries,
# once with each filter, and compares the two `.tex` files byte for byte — the
# expected diff is empty. Run it from a clean tree on the milestone branch.
# ---------------------------------------------------------------------------

# The HTML back-end's four identifiers are a public surface — a reader's URL
# and an author's CSS hold on to them — so the suite's copies are pinned to
# the filter's own constants, exactly as the dual-target command name is.
HTML_SECTION_ID="$HTML_SECTION_ID" HTML_ANCHOR_PREFIX="$HTML_ANCHOR_PREFIX" \
HTML_ENTRY_PREFIX="$HTML_ENTRY_PREFIX" HTML_LETTER_CLASS="$HTML_LETTER_CLASS" \
python3 - _extensions/index/index.lua <<'PY'
import os, re, sys
src = open(sys.argv[1], encoding='utf-8').read()
bad = []
for name in ('HTML_SECTION_ID', 'HTML_ANCHOR_PREFIX', 'HTML_ENTRY_PREFIX',
             'HTML_LETTER_CLASS'):
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
print('ok   M03-AC3: all 4 HTML identifiers pinned to the filter constants')
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
# Lua string literals take either quote, and a message that itself contains a
# double quote is written with single quotes — so a scan for one quote style
# only would leave that warning outside this check while the comment above
# still claimed every warning was covered.
lits = [m.group(2) for m in re.finditer(
    r'''warn\(\s*\(?(["'])((?:[^\\]|\\.)*?)\1''', src)]
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
letter	K
0	kappa	1	see-plain Elsewhere
letter	L
0	lambda	0	see-plain Here	also-plain There
letter	M
0	mu	0	see-plain Same
letter	N
0	Note	0
1	on birds	1
0	nu	2
letter	R
0	rho	0	see-plain Note: on birds
letter	S
0	sigma	0	see-link Note: on birds
MANIFEST

check_html_index_manifest examples/xref-conflict.html "$XREF_HTML_INDEX" "M03-AC4"
check_letter_sweep examples/xref-conflict.html "M07-AC3 (cross-references)" \
  $'K\nL\nM\nN\nR\nS'

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

MARKER_CLASS="$MARKER_CLASS" HTML_SECTION_ID="$HTML_SECTION_ID" python3 - \
  _extensions/index/index.lua <<'PY'
import os, re, sys
src = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'MARKER_CLASS\s*=\s*"([^"]*)"', src)
if not m:
    print('FAIL: M04-AC1: MARKER_CLASS is not defined in the filter',
          file=sys.stderr)
    sys.exit(1)
if m.group(1) != os.environ['MARKER_CLASS']:
    print(f"FAIL: M04-AC1: suite says {os.environ['MARKER_CLASS']!r}, filter "
          f"defines {m.group(1)!r}", file=sys.stderr)
    sys.exit(1)
if m.group(1) == os.environ['HTML_SECTION_ID']:
    print(f'FAIL: M04-AC1: the marker class and the generated section id are '
          f'the same string ({m.group(1)!r}); one string with two meanings is '
          f'exactly the collision the marker token avoids', file=sys.stderr)
    sys.exit(1)
print('ok   M04-AC1: the marker class is pinned to the filter constant and '
      'differs from the generated section id')
PY

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
# M08-AC3 / M08-AC4 — marker sites. The class only ever places an index on an
# empty top-level div; written on a heading, an inline span or a code block it
# places nothing and is reported, and the element is left exactly as the author
# wrote it (M08's plan gate: the extension reports rather than edits). A nested
# marker that was its container's ONLY content leaves that container empty,
# which is reported as a second message beside the existing nested-marker one —
# both are kept, so the message M04 pinned keeps its wording.
# ---------------------------------------------------------------------------
WARN_SITE_HEADING='marker class is written on a heading'
WARN_SITE_SPAN='marker class is written on an inline span'
WARN_SITE_CODE='marker class is written on a code block'
WARN_EMPTIED='was the only content of the'

for fmt in html latex gfm; do
  quarto render examples/marker-sites.qmd --to $fmt \
    > "$WORK/sites-$fmt.log" 2>&1 \
    || { tail -20 "$WORK/sites-$fmt.log" >&2; fail "M08-AC3: marker-sites.qmd failed to render to $fmt"; }
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_HEADING" 1 "M08-AC3"
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_SPAN" 1 "M08-AC3"
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_SITE_CODE" 1 "M08-AC3"
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_EMPTIED" 2 "M08-AC4"
  # The message M04 pinned still fires for both nested markers: the emptied-
  # container report is additive, never a replacement.
  check_warning_count "$WORK/sites-$fmt.log" "$WARN_MARKER_NESTED" 2 "M08-AC4"
done
pass "M08-AC3/AC4: three misplaced marker classes and two emptied containers each report, in HTML, LaTeX and gfm"

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

# Both emptied containers survive, structurally, and are empty — two container
# kinds, because strip_nested_markers walks every nested Blocks list and one
# shape cannot stand in for that family.
python3 - examples/marker-sites.html <<'PY'
import sys
sys.path.insert(0, 'tests')
import htmlindex as H
doc = H.parse(sys.argv[1])
errs = []
divs = [n for n in H.walk(doc) if n.attrs.get('id') == 'emptied-div']
if not divs:
    errs.append('the div whose only content was a nested marker is gone')
elif H.text(divs[0]).strip():
    errs.append(f'that div is not empty: {H.text(divs[0])!r}')
quotes = [n for n in H.walk(doc) if n.tag == 'blockquote']
if not quotes:
    errs.append('the block quote whose only content was a nested marker is gone')
elif all(H.text(q).strip() for q in quotes):
    errs.append('no block quote was left empty')
if errs:
    print('FAIL: M08-AC4: ' + '; '.join(errs), file=sys.stderr)
    sys.exit(1)
print('ok   M08-AC4: both emptied containers — a div and a block quote — are '
      'still in the page, and both are empty')
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
STORE_VERSION=$(sed -n 's/^local STORE_VERSION = \([0-9][0-9]*\)$/\1/p' \
  _extensions/index/index.lua)
[ -n "$STORE_VERSION" ] \
  || fail "M05-AC1: could not read STORE_VERSION from the filter"

# The store's own name is a pinned surface like the HTML back-end's ids: the
# footprint sweep below asks "no file named like this under the output
# directory", which proves nothing if the filter names its files something
# else entirely.
STORE_SUFFIX="$STORE_SUFFIX" STORE_DIR="$STORE_DIR" python3 - _extensions/index/index.lua <<'PY'
import os, re, sys
src = open(sys.argv[1], encoding='utf-8').read()
missing = [f'{name} = {value!r}'
           for name, value in (('STORE_SUFFIX', os.environ['STORE_SUFFIX']),
                               ('STORE_DIR', os.environ['STORE_DIR']))
           if not re.search(r'^local %s = "%s"$' % (name, re.escape(value)),
                            src, re.MULTILINE)]
if missing:
    print('FAIL: M05-AC1: the suite and the filter disagree on the store\'s '
          'name; the suite expects:', file=sys.stderr)
    for m in missing:
        print(f'  {m}', file=sys.stderr)
    sys.exit(1)
print('ok   M05-AC1: the store name the footprint sweep looks for is the one '
      'the filter writes')
PY

# A full render from nothing: the store starts empty, so an index built here
# was built from THIS render's chapters and not from a record left behind.
rm -rf "$BOOK_OUT" "$BOOK_DIR/.quarto"
( cd "$BOOK_DIR" && quarto render --to html ) > "$WORK/book-html.log" 2>&1 \
  || { tail -30 "$WORK/book-html.log" >&2; fail "M05-AC1: the book fixture failed to render to HTML"; }

check_html_index_manifest "$BOOK_OUT/last.html" "$BOOK_HTML_INDEX" \
  "M05-AC1/AC3" hrefs
# M07-AC4: the book's B group holds Beta, marked in one.qmd, and Beacon,
# marked in sub/two.qmd — a group gathers what every chapter contributed.
check_letter_sweep "$BOOK_OUT/last.html" "M07-AC4" \
  $'A\nB\nC\nD\nE\nG\nI\nK\nZ'

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
# which is the criterion's "renders as unlinked text"; this is the other half
# of AC4 — a well-formed book renders with nothing to report at all, so a
# cross-file target never draws the warning a missing one would.
if grep -q '^(W)' "$WORK/book-html.log"; then
  grep '^(W)' "$WORK/book-html.log" >&2
  fail "M05-AC4: the book fixture rendered with warning(s); a resolvable cross-file target must draw none"
fi
pass "M05-AC4: the book renders warning-free, unresolvable target included"

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
  $'A\nB\nC\nD\nE\nG\nI\nK\nZ'

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
  $'A\nB\nC\nD\nE\nG\nI\nK\nZ'
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
# is A. `Early` and `Late` file under their printed text.
check_letter_sweep "$ORDER_OUT/index.html" "M07-AC1 (book order)" $'A\nE\nL'

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
#      `Symbols` in every other case, the empty filing string included. Groups
#      rank Symbols first, then A-Z; within a group, and at every level below
#      the top, step 5's collation is unchanged.
#
# Derived per entry, filing string in parentheses:
#   `` (``)                  empty first level of `!windmill`   -> Symbols
#   `Quixote` (`!quixote`)   `!!` is the literal `!`             -> Symbols
#   `#hashtag` (`#hashtag`)  printed text                        -> Symbols
#   `~tilde` (`~tilde`)      printed text                        -> Symbols
#   `éclair` (`éclair`)      first byte of a UTF-8 sequence      -> Symbols
#   `alpha` (`alpha`)        printed text                        -> A
#   `#1 priority` (`alpha priority`)  sort key                   -> A
#   `Mango` (`Mango`)        printed text                        -> M
#   `zebra` (`zebra`)        printed text                        -> Z
# ---------------------------------------------------------------------------
read -r -d '' LETTER_GROUPS_INDEX <<'MANIFEST' || true
letter	Symbols
0		0
1	windmill	1
0	Quixote	1
0	#hashtag	1
0	~tilde	1
0	éclair	1
letter	A
0	alpha	1
0	#1 priority	1
letter	M
0	Mango	1
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
  $'Symbols\nA\nM\nZ'

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
  warn_discrimination "$WORK/conflict-latex.log" "$WARN_CLASH" 2 "M02-AC5"
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
  warn_discrimination "$WORK/misuse-latex.log" "$WARN_MARKER_DUP" 1 "M04-AC4"
  warn_discrimination "$WORK/marker-nomarks-latex.log" "$WARN_MARKER_NOMARKS" 1 "M04-AC4"
fi

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
