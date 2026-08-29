-- Shared constants, the warning channel, and the format tests.
--
-- Everything here is read by more than one of the modules beside it, so it
-- sits below all of them: this module requires nothing, and every other
-- module requires it as `qi_core`.

local M = {}

local INDEX_CLASS = "index"

-- The placement marker: an empty div the author writes where the index should
-- appear. It is deliberately NOT the generated section's id `qi-index` — one
-- string carrying two meanings is a collision waiting to be reported as a bug.
-- Recognized at the top level of the document only: a `\printindex` inside a
-- group or environment is an IP2-class render risk, so a marker written below
-- the top level places nothing.
local MARKER_CLASS = "qi-index-here"

-- The two cross-reference attributes, in the order their targets are emitted
-- when a mark carries both.
-- `command` is the LaTeX back-end's encap command; `label` is the words a
-- reader sees, which the LaTeX back-end gets from `\seename`/`\alsoname`
-- instead so a document loading babel keeps its translations.
-- `label_key` is the key an author overrides this word under in the `labels:`
-- map (D-036). It is spelled out rather than reused from `attr`, which happens
-- to be the same string: the attribute names a cross-reference TARGET and the
-- key names the word printed in front of one, and a later rename of either
-- must not silently move the other.
local XREF_KINDS = {
  { attr = "see", command = "see", label = "see", label_key = "see" },
  { attr = "see-also", command = "seealso", label = "see also",
    label_key = "see-also" },
}

-- The same kinds by attribute name. A book's store holds an attribute name
-- rather than the kind table itself, and reads it back through this.
local XREF_KIND_BY_ATTR = {}
for _, kind in ipairs(XREF_KINDS) do
  XREF_KIND_BY_ATTR[kind.attr] = kind
end

-- A mark carrying both attributes cannot emit two `\index` commands: they
-- share a key and a page, so makeindex reports "Conflicting entries: multiple
-- encaps for the same page under same key" and Quarto turns that warning into
-- a failed render — a marked term breaking the document, which IP2 forbids.
-- One command carrying both targets is emitted instead, through a command the
-- back-end defines itself. Its third argument is the page number makeindex
-- hands every encap, discarded here exactly as `\see` discards it. The labels
-- go through `\seename`/`\alsoname` rather than literal words, so a document
-- loading babel keeps babel's translations, as it does for a lone `\see`.
local XREF_BOTH_COMMAND = "quartoindexseeboth"
local XREF_BOTH_DEFINITION =
  "\\providecommand*\\" .. XREF_BOTH_COMMAND ..
  "[3]{\\emph{\\seename} #1; \\emph{\\alsoname} #2}"

-- A contested key whose marks are ALL cross-references keeps its targets in the
-- encapsulation channel, where makeindex's own term/locator delimiter is the
-- comma that separates the term from them — the same place a single-target
-- mark has always put them. Folding such a key into the printed text instead
-- would leave that delimiter standing before an encap printing nothing, ending
-- the entry on a dangling comma. This command renders the whole target list,
-- which is what lets every mark of the key carry the SAME encap however many
-- targets they have between them, and discards the page makeindex appends,
-- exactly as `\see` does. Emitted only where such a key exists.
local XREF_LIST_COMMAND = "quartoindexxrefs"
local XREF_LIST_DEFINITION =
  "\\providecommand*\\" .. XREF_LIST_COMMAND .. "[2]{#1}"

-- The attribute naming the role one mention of a term plays. It is `mention`
-- and NOT `role`: Pandoc data-prefixes an attribute name it does not know but
-- emits `role` literally, being a real HTML attribute, so `role="principal"`
-- would reach every HTML-family output as an ARIA role — and `principal` is
-- not a valid one, which is an artifact on every marked term (IP2).
local MENTION_ATTR = "mention"

-- The roles a mention may declare. One today; a further role is another value
-- here rather than another attribute (GP5). Written as a set so an unknown
-- value is one lookup, and so the report can quote what the author wrote.
local MENTION_ROLES = {
  ["principal"] = true,
}

-- The emphasis a principal locator is printed in. `\providecommand*` so a
-- document wanting different emphasis redefines it in its own preamble and
-- this definition steps aside (GP4), and injected only into a document that
-- uses it — unlike the two cross-reference commands above, which since M31
-- ride in every LaTeX preamble because each reaches the compiled `.ind`. This
-- one does not: it is applied at `\printindex` time by the subsystem below,
-- never named in the `.ind` itself. Bold is the
-- convention a printed index uses for a principal reference. It is applied by
-- the subsystem below at `\printindex` time, not by makeindex's encapsulation
-- channel, so hyperref never rewrites it.
local PRINCIPAL_COMMAND = "quartoindexprincipal"
local PRINCIPAL_DEFINITION =
  "\\providecommand*\\" .. PRINCIPAL_COMMAND .. "[1]{\\textbf{#1}}"

-- The attribute naming a mark as one end of a page range, and its two values.
-- Format-neutral like every other mark attribute: which end a mark is is a
-- fact about what the author wrote, so it is read and diagnosed in every
-- format and only the realization differs. `range` is not an HTML attribute,
-- so Pandoc data-prefixes it exactly as it does `see` — no `mention`-shaped
-- collision to avoid here.
--
-- A further value is not a further attribute (GP5), and the ends are written
-- as a set for the same reason the mention roles are: an unknown value is one
-- lookup, and the report can quote what the author wrote.
local RANGE_ATTR = "range"
local RANGE_ENDS = {
  ["open"] = true,
  ["close"] = true,
}

-- ---------------------------------------------------------------------------
-- The typeset-time channel (D-007).
--
-- Per-locator styling cannot be expressed through what `\index` commands say:
-- makeindex's conflict predicate is same key, same page, ANY byte difference
-- in the encapsulation string, and a Pandoc filter cannot know page numbers,
-- so a key whose locators carry different encapsulations always has a document
-- that puts two of them on one page — and Quarto fails that render. So every
-- locator mark of a key carrying a principal mention emits the SAME
-- encapsulation, `LOCATOR_COMMAND{<ordinal>}`, which makes the conflict
-- unreachable by construction rather than merely unexercised, and the role
-- travels on a second channel instead.
--
-- That channel is the `.aux`. The principal mark emits REGISTER_COMMAND, which
-- writes its ordinal and `\thepage` through `\protected@write\@auxout` — the
-- same deferred-to-shipout mechanism `\@wrindex` uses for the `.idx`, so the
-- page the registration names and the page the locator names are decided by
-- one shipout and cannot disagree. The next pass reads those lines back as
-- PRINCIPALPAGE_COMMAND calls, which set one flag per (ordinal, page) pair.
--
-- At `\printindex` the locator command receives the key's whole page list and
-- prints it one page at a time, wrapping a registered page in PRINCIPAL_COMMAND
-- and leaving the rest plain. hyperref, where it is loaded, hands that list
-- already wrapped in its own page-link command; the dispatch below detects that
-- by asking whether its argument STARTS WITH a control sequence, and re-applies
-- whatever it found per page, so every locator stays a working hyperlink
-- without this file naming a hyperref internal.
--
-- One known degradation, documented in README: makeindex folds three or more
-- consecutive pages under one encapsulation into a range, and a lookup on the
-- string `1--3` matches no registered page, so a principal page inside a
-- FOLDED range prints unemphasized. A range the AUTHOR wrote is a different
-- case, and M21 closes it (D-008): the filter knows such a range exists, so
-- its two ends register their own pages and the pair is composed into the
-- same string the index prints. The folded case stays open, because no mark
-- there says a range exists at all.
--
-- The range commands are part of THIS block rather than a block of their own,
-- and the difference is a render. Everything here is injected only into a
-- document that carries a principal mention, but the `.aux` lines these
-- commands are defined for outlive the source that produced them: delete a
-- `range=` from a document whose `.aux` survives (`latex-clean: false`, or a
-- failed render) and the next pass reads a `\quartoindexrangeat` nothing
-- defines — `Undefined control sequence`, and the render is over. Four
-- `\providecommand`s cost an unused document nothing, and a marked term must
-- never break a document (IP2), so they ride along (M21 review F3). The same
-- hazard at one remove — a document losing its LAST principal mention — is
-- closed by PRINCIPAL_GOBBLERS below (M22): every LaTeX document that does
-- not define this subsystem defines stand-ins for the three commands an
-- `.aux` line can name and for the one a compiled `.ind` carries (M31).
-- ---------------------------------------------------------------------------
local LOCATOR_COMMAND = "quartoindexlocator"
local REGISTER_COMMAND = "quartoindexregister"
local PRINCIPALPAGE_COMMAND = "quartoindexprincipalpage"

-- The range half of the same channel (D-008). Two inline commands, emitted
-- beside the two `\index` commands of a principal range, and the two `.aux`
-- commands they write. `rangefrom` stands in for REGISTER_COMMAND on a range
-- opening rather than joining it: it does everything that command does and
-- remembers the page as the range's start as well, and a slot only a range
-- opening ever writes cannot be moved by a second principal mark of the same
-- key.
local RANGEFROM_COMMAND = "quartoindexrangefrom"
local RANGEEND_COMMAND = "quartoindexrangeend"
local RANGEAT_COMMAND = "quartoindexrangeat"
local RANGETO_COMMAND = "quartoindexrangeto"

-- makeindex's own range delimiter, which it writes between the two pages of a
-- range and which this file must spell identically to look the printed string
-- up. It is makeindex's `delim_r`, whose default this is; the extension ships
-- no style file that could change it, and author control over the dash is a
-- ROADMAP candidate rather than something this constant anticipates.
local RANGE_DELIM = "--"

-- The ordinal prefix. Ordinals are opaque and csname-safe by construction, so
-- no key text — which may hold any character an author can write — ever
-- reaches a `\csname`.
local LOCATOR_ID_PREFIX = "qi"

-- Written as one block because every line of it is `@`-sensitive: the internal
-- helpers are `\qi@`-prefixed so nothing an author writes can collide with
-- them, and `\protected@write`, `\@auxout`, `\@empty`, `\@firstofone`,
-- `\@gobbletwo`, `\@firstoftwo` and `\@secondoftwo` are all kernel names.
-- `\qi@stop` is a delimiter and deliberately never defined, exactly as the
-- kernel's own `\@nil` is.
local PRINCIPAL_SUBSYSTEM = table.concat({
  "\\makeatletter",
  -- Both sides sanitize the page string before it reaches a `\csname`. A
  -- document may redefine `\thepage` to something holding a non-expandable
  -- token — `\thesection\,\arabic{page}` is an ordinary page style — and
  -- `\protected@write` writes whatever it expands to. Unsanitized, that token
  -- reaches `\csname` and raises `Missing \endcsname inserted` on every pass
  -- after the first. makeindex already rejects such a page outright, so the
  -- document has no index either way, but it must still BUILD: turning a clean
  -- render into a LaTeX error is the IP2 break this subsystem exists to avoid,
  -- not one it may add (review round 3). `\@onelevel@sanitize` is applied
  -- identically here and at lookup, so the two agree on the key.
  "\\providecommand*\\" .. PRINCIPALPAGE_COMMAND ..
    "[2]{\\def\\qi@key{#2}\\@onelevel@sanitize\\qi@key" ..
    "\\expandafter\\gdef\\csname qi@p@#1@\\qi@key\\endcsname{}}",
  "\\providecommand*\\" .. REGISTER_COMMAND ..
    "[1]{\\protected@write\\@auxout{}{\\string\\" .. PRINCIPALPAGE_COMMAND ..
    "{#1}{\\thepage}}}",
  -- The empty-list guard is not decoration: `\qi@sniff` reads its first token
  -- as an undelimited argument, so a page list with no token in it would let
  -- it swallow the `\qi@stop` delimiter and run away — a hard render failure
  -- in the one subsystem whose whole justification is that a marked term must
  -- never break a document (IP2). The test is `\def` and not `\edef`: the page
  -- list arrives already wrapped in the page-link command, and expanding it to
  -- compare would expand that too — which fails outright. So the guard catches
  -- a byte-empty list and not a space-only one, which runs away the same way;
  -- both are unreachable from makeindex, and covering the second is not worth
  -- expanding an argument this command must pass through untouched (review
  -- round 3, which found the space case and the expansion hazard together).
  "\\providecommand*\\" .. LOCATOR_COMMAND ..
    "[2]{\\def\\qi@arg{#2}\\ifx\\qi@arg\\@empty\\else" ..
    "\\qi@sniff{#1}#2\\qi@stop\\fi}",
  "\\def\\qi@nil{\\qi@nil}",
  -- The item arrives with makeindex's separator space still on it; grabbing
  -- the first token as an UNDELIMITED argument is what drops that space,
  -- since TeX skips spaces there. `\@empty` fills the slot for an empty item.
  "\\def\\qi@trim#1#2\\qi@stop{#1#2}",
  "\\def\\qi@print#1{\\ifx\\qi@wrap\\@empty#1\\else\\qi@wrap{#1}\\fi}",
  "\\def\\qi@emit#1{\\qi@sep\\def\\qi@sep{, }" ..
    "\\edef\\qi@pg{\\qi@trim#1\\@empty\\qi@stop}" ..
    "\\@onelevel@sanitize\\qi@pg" ..
    "\\expandafter\\ifx\\csname qi@p@\\qi@id @\\qi@pg\\endcsname\\relax" ..
    "\\qi@print{\\qi@pg}\\else\\" .. PRINCIPAL_COMMAND ..
    "{\\qi@print{\\qi@pg}}\\fi}",
  "\\def\\qi@scan#1,{\\def\\qi@tmp{#1}\\ifx\\qi@tmp\\qi@nil" ..
    "\\expandafter\\@gobbletwo\\else\\expandafter\\@firstofone\\fi" ..
    "{\\qi@emit{#1}\\qi@scan}}",
  "\\def\\qi@split#1#2#3{\\def\\qi@id{#1}\\def\\qi@wrap{#2}" ..
    "\\let\\qi@sep\\@empty\\qi@scan#3,\\qi@nil,\\relax}",
  -- Is the page list already wrapped in someone else's command? `\ifcat`
  -- against `\relax` asks the token's CLASS, so this holds whatever hyperref
  -- calls its own page-link command, and holds equally in a document with no
  -- hyperref at all, where the list arrives bare.
  --
  -- `#3` is BRACED on the way to `\qi@split`, and the brace is load-bearing.
  -- `#3` here is DELIMITED (by `\qi@stop`), so TeX has already stripped the
  -- braces off the `{1, 2}` hyperref handed us; `\qi@split`'s own `#3` is
  -- undelimited and would then take just the first token, leaving the rest of
  -- the page list to be typeset raw — outside the page-link command, and never
  -- looked up in the registry at all. Unbraced, this emphasized only a page
  -- that was both the first item of its list and a single character, so every
  -- principal mention from page 10 on printed plain, and a range whose first
  -- page was registered printed emphasized although README says it does not
  -- (M20 review round 2). The other branch braces `{#2#3}` and always did.
  "\\def\\qi@sniff#1#2#3\\qi@stop{\\ifcat\\noexpand#2\\relax" ..
    "\\expandafter\\@firstoftwo\\else\\expandafter\\@secondoftwo\\fi" ..
    "{\\qi@split{#1}{#2}{#3}}{\\qi@split{#1}{}{#2#3}}}",
  -- A range opening registers its page exactly as a lone principal mark does,
  -- and remembers it as `\qi@f@<ordinal>` for the closing to compose with.
  -- The page is sanitized here again rather than read out of the macro the
  -- registration leaves behind: that macro is set by every principal mark of
  -- every key, and depending on it would make this line's meaning depend on
  -- what ran before it.
  -- The bare-page registration this line ALSO leaves (via the page command)
  -- is live for the whole run; it is what makes a same-page range print
  -- emphasized, because makeindex folds a same-page, same-encapsulator pair
  -- into the single page rather than a `4--4`. Nothing else may print that
  -- key as a bare locator on this page — makeindex's fold is what upholds
  -- that today, and this comment is where the assumption is recorded.
  "\\providecommand*\\" .. RANGEAT_COMMAND ..
    "[2]{\\" .. PRINCIPALPAGE_COMMAND .. "{#1}{#2}" ..
    "\\def\\qi@key{#2}\\@onelevel@sanitize\\qi@key" ..
    "\\expandafter\\xdef\\csname qi@f@#1\\endcsname{\\qi@key}}",
  -- And the closing composes the two pages into the string makeindex prints
  -- for the range and registers THAT, so the lookup at `\printindex` finds it.
  -- Guarded on the opening's slot existing: an `.aux` from a run whose opening
  -- has since been deleted still holds this line, and `\csname` on a name
  -- nothing defined is `\relax`, which would otherwise compose a range
  -- starting with `\relax`. The slot is cleared once used, so the guard means
  -- what it says for a SECOND range of the same key too: without that, an
  -- orphaned closing composed the previous range's start with its own page and
  -- registered a span nothing prints (review round 3, R3-F8).
  "\\providecommand*\\" .. RANGETO_COMMAND ..
    "[2]{\\def\\qi@key{#2}\\@onelevel@sanitize\\qi@key" ..
    "\\expandafter\\ifx\\csname qi@f@#1\\endcsname\\relax\\else" ..
    "\\edef\\qi@key{\\csname qi@f@#1\\endcsname" .. RANGE_DELIM ..
    "\\qi@key}" ..
    "\\expandafter\\gdef\\csname qi@p@#1@\\qi@key\\endcsname{}" ..
    "\\expandafter\\global\\expandafter\\let\\csname qi@f@#1\\endcsname\\relax\\fi}",
  "\\providecommand*\\" .. RANGEFROM_COMMAND ..
    "[1]{\\protected@write\\@auxout{}{\\string\\" .. RANGEAT_COMMAND ..
    "{#1}{\\thepage}}}",
  "\\providecommand*\\" .. RANGEEND_COMMAND ..
    "[1]{\\protected@write\\@auxout{}{\\string\\" .. RANGETO_COMMAND ..
    "{#1}{\\thepage}}}",
  "\\makeatother",
}, "\n")

-- The stand-ins for the subsystem, in every LaTeX document the subsystem is
-- NOT injected into. Two build files outlive the marks that wrote them, and
-- each hands the next render a name only the subsystem defines.
--
-- The `.aux` carries three: the page command REGISTER_COMMAND writes, and the
-- two range commands RANGEFROM_COMMAND and RANGEEND_COMMAND write. A document
-- that has just lost its last principal mention still reads such lines on its
-- next pass, at `\begin{document}`. Undefined, each is `Undefined control
-- sequence` and the render is over, which is the IP2 break the subsystem
-- exists to avoid; gobbling both arguments, the line expands to nothing and
-- the page prints as the ordinary locator it now is.
--
-- The compiled `.ind` carries a fourth, LOCATOR_COMMAND, read later at
-- `\printindex` (M31). Its stand-in GOBBLES NOTHING: the live command takes
-- the key's ordinal and the key's whole page list and prints the list, so a
-- stand-in swallowing both arguments would turn a stale index into one with
-- no page numbers in it at all — a render that builds and lies, where the
-- point of the block is a render that builds and tells the truth. Passing
-- `#2` through prints exactly the ordinary locators the entry now has.
--
-- `\providecommand*` like the subsystem's own definitions, and exactly one of
-- the two blocks is injected per document, never both — injected together,
-- whichever landed first would win, and a gobbled subsystem emphasizes
-- nothing while looking installed.
local PRINCIPAL_GOBBLERS = table.concat({
  "\\providecommand*\\" .. PRINCIPALPAGE_COMMAND .. "[2]{}",
  "\\providecommand*\\" .. RANGEAT_COMMAND .. "[2]{}",
  "\\providecommand*\\" .. RANGETO_COMMAND .. "[2]{}",
  "\\providecommand*\\" .. LOCATOR_COMMAND .. "[2]{#2}",
}, "\n")

-- The class the HTML back-end puts on a principal locator link. Namespaced
-- like the other pinned HTML identifiers, since an author's CSS may hold on
-- to it. The link also carries Pandoc-level emphasis, so it reads as the
-- principal reference with no stylesheet at all.
local HTML_PRINCIPAL_CLASS = "qi-principal"

-- Characters that are literal text on the way in and need help on the way
-- out. Most LaTeX specials are escaped with a backslash. Three groups cannot
-- be: `!` and `@` are makeindex operators, made literal with its quote
-- character; `|` and `"` are mangled by hyperref and by LaTeX's own quote
-- rendering; and `{`/`}` survive `\@sanitize` as group characters. Those last
-- four are emitted as LaTeX commands instead — see the notes below.
local LATEX_LITERAL = {
  ["%"] = "\\%",
  ["&"] = "\\&",
  ["#"] = "\\#",
  ["_"] = "\\_",
  -- NOT `\{`/`\}`: LaTeX reads an \index argument under `\@sanitize`, which
  -- gives `\` catcode 12, so a backslash there escapes nothing and the brace
  -- stays a group character — an unbalanced one aborts the render outright.
  ["{"] = "\\textbraceleft{}",
  ["}"] = "\\textbraceright{}",
  ["$"] = "\\$",
  ["<"] = "\\textless{}",
  [">"] = "\\textgreater{}",
  ["\\"] = "\\textbackslash{}",
  ["~"] = "\\textasciitilde{}",
  ["^"] = "\\textasciicircum{}",
  -- `!` and `@` are only special to makeindex, so its quote character is
  -- enough. `|` and `"` are NOT: hyperref rewrites an index argument at the
  -- first `|` before makeindex ever runs, and knows nothing about makeindex
  -- quoting, so `"|` corrupts the entry; and a makeindex-quoted `""` reaches
  -- LaTeX as a bare `"`, which typesets as a curly closing quote. Both are
  -- emitted as LaTeX commands instead, which contain no character either
  -- tool treats as active.
  ["!"] = '"!',
  ["@"] = '"@',
  ["|"] = "\\textbar{}",
  ['"'] = "\\textquotedbl{}",
}

-- Empty a table in place, returning it. The per-document `reset` each stateful
-- module owns calls this rather than assigning a fresh table: an accumulator is
-- exported by reference — `M["marked_paths"] = marked_paths` hands the filter
-- the table itself — so a rebound local would restore nothing the filter reads
-- (M26). Setting an existing key to nil during a `pairs` traversal is the one
-- mutation Lua allows there.
local function empty(t)
  for k in pairs(t) do
    t[k] = nil
  end
  return t
end

-- The sub-table one index's share of an accumulator lives in, created on
-- first use. Every format-neutral accumulator is now one namespace per index
-- rather than one per document, so a cross-reference target, a sort key and a
-- range pair are each settled within the index the mark files in; `empty`
-- above still empties the outer table, and with it every namespace inside it.
local function namespace(t, key)
  local inner = t[key]
  if inner == nil then
    inner = {}
    t[key] = inner
  end
  return inner
end

local function warn(msg)
  if quarto and quarto.log and quarto.log.warning then
    quarto.log.warning(msg)
  else
    io.stderr:write("[quarto-index] WARNING: " .. msg .. "\n")
  end
end

-- `latex` (which also covers `pdf` output) is the only back-end that ships.
-- beamer is deliberately excluded: it has no `theindex` environment, so a
-- `\printindex` there aborts the render — and IP2 says a marked term must
-- never break a document. beamer therefore passes through like any format
-- with no index back-end, until a beamer back-end is actually written.
local function is_latex_derived()
  return FORMAT:match("latex") ~= nil
end

-- HTML is the second back-end. The match is on `html` alone, so revealjs and
-- every other format with no back-end keeps passing through: none of them
-- carries `html` in FORMAT, and each would need an index shape of its own
-- anyway. This predicate stays narrower than "builds an index in the AST"
-- (`builds_ast_index` below): it is also what decides that a chapter file
-- means a chapter, which is true of the HTML book alone.
local function is_html()
  return FORMAT:match("html") ~= nil
end

-- EPUB is the third back-end. Pandoc spells the format `epub`, `epub2` and
-- `epub3`, and all three carry `epub` in FORMAT; nothing else does.
local function is_epub()
  return FORMAT:match("epub") ~= nil
end

-- The back-ends that build their index in the Pandoc AST, as opposed to the
-- LaTeX-derived one that emits commands for a typeset-time subsystem. HTML
-- and EPUB print the same entry tree from the same blocks; what separates
-- them is how a BOOK reaches this filter, which is `is_html`'s question and
-- not this one's.
local function builds_ast_index()
  return is_html() or is_epub()
end

-- The HTML back-end's pinned identifiers. They are the only names a reader's
-- URL or an author's CSS can hold on to, so they are namespaced to the
-- extension rather than named after the word "index", which an author's own
-- heading would collide with.
local HTML_SECTION_ID = "qi-index"
local HTML_ANCHOR_PREFIX = "qi-mark-"
local HTML_ENTRY_PREFIX = "qi-entry-"
local HTML_LETTER_CLASS = "qi-letter"

-- A mark's anchor cannot be settled while the mark is being visited: whether
-- the mark's own id serves, where the anchor may sit, and what a minted id
-- must not collide with all depend on parts of the document not yet seen.
-- The Span pass tags every locator-contributing mark with this attribute,
-- and the Pandoc pass — which has the whole document — resolves the anchor
-- and removes the tag. It never survives into output.
local HTML_PENDING_ATTR = "data-qi-pending"

-- Exported through the bracket form, never `M.NAME = NAME`: the source
-- scans take the FIRST match for `NAME =` over the whole source set, and
-- the M16-AC3 probe relocates a definition into another file — a plain
-- `NAME =` line left behind here would then mask it (M16 review F3).
M["INDEX_CLASS"] = INDEX_CLASS
M["MARKER_CLASS"] = MARKER_CLASS
M["XREF_KINDS"] = XREF_KINDS
M["XREF_KIND_BY_ATTR"] = XREF_KIND_BY_ATTR
M["XREF_BOTH_COMMAND"] = XREF_BOTH_COMMAND
M["XREF_BOTH_DEFINITION"] = XREF_BOTH_DEFINITION
M["XREF_LIST_COMMAND"] = XREF_LIST_COMMAND
M["XREF_LIST_DEFINITION"] = XREF_LIST_DEFINITION
M["RANGE_ATTR"] = RANGE_ATTR
M["RANGE_ENDS"] = RANGE_ENDS
M["RANGE_DELIM"] = RANGE_DELIM
M["RANGEFROM_COMMAND"] = RANGEFROM_COMMAND
M["RANGEEND_COMMAND"] = RANGEEND_COMMAND
M["RANGEAT_COMMAND"] = RANGEAT_COMMAND
M["RANGETO_COMMAND"] = RANGETO_COMMAND
M["MENTION_ATTR"] = MENTION_ATTR
M["MENTION_ROLES"] = MENTION_ROLES
M["PRINCIPAL_COMMAND"] = PRINCIPAL_COMMAND
M["PRINCIPAL_DEFINITION"] = PRINCIPAL_DEFINITION
M["LOCATOR_COMMAND"] = LOCATOR_COMMAND
M["REGISTER_COMMAND"] = REGISTER_COMMAND
M["PRINCIPALPAGE_COMMAND"] = PRINCIPALPAGE_COMMAND
M["LOCATOR_ID_PREFIX"] = LOCATOR_ID_PREFIX
M["PRINCIPAL_SUBSYSTEM"] = PRINCIPAL_SUBSYSTEM
M["PRINCIPAL_GOBBLERS"] = PRINCIPAL_GOBBLERS
M["HTML_PRINCIPAL_CLASS"] = HTML_PRINCIPAL_CLASS
M["LATEX_LITERAL"] = LATEX_LITERAL
M["empty"] = empty
M["namespace"] = namespace
M["warn"] = warn
M["is_latex_derived"] = is_latex_derived
M["is_html"] = is_html
M["is_epub"] = is_epub
M["builds_ast_index"] = builds_ast_index
M["HTML_SECTION_ID"] = HTML_SECTION_ID
M["HTML_ANCHOR_PREFIX"] = HTML_ANCHOR_PREFIX
M["HTML_ENTRY_PREFIX"] = HTML_ENTRY_PREFIX
M["HTML_LETTER_CLASS"] = HTML_LETTER_CLASS
M["HTML_PENDING_ATTR"] = HTML_PENDING_ATTR

return M
