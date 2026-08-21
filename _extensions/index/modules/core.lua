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
local XREF_KINDS = {
  { attr = "see", command = "see", label = "see" },
  { attr = "see-also", command = "seealso", label = "see also" },
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

-- The principal locator's encapsulation. `\providecommand*` so a document
-- wanting different emphasis redefines it in its own preamble and this
-- definition steps aside (GP4), and injected only into a document that uses
-- it, exactly like the two cross-reference commands above. Bold is the
-- convention a printed index uses for a principal reference.
local PRINCIPAL_COMMAND = "quartoindexprincipal"
local PRINCIPAL_DEFINITION =
  "\\providecommand*\\" .. PRINCIPAL_COMMAND .. "[1]{\\textbf{#1}}"

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

-- HTML is the second back-end. The match is on `html` alone, so revealjs,
-- epub and every other format keep passing through: none of them carries
-- `html` in FORMAT, and each would need an index shape of its own anyway.
local function is_html()
  return FORMAT:match("html") ~= nil
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
M["MENTION_ATTR"] = MENTION_ATTR
M["MENTION_ROLES"] = MENTION_ROLES
M["PRINCIPAL_COMMAND"] = PRINCIPAL_COMMAND
M["PRINCIPAL_DEFINITION"] = PRINCIPAL_DEFINITION
M["HTML_PRINCIPAL_CLASS"] = HTML_PRINCIPAL_CLASS
M["LATEX_LITERAL"] = LATEX_LITERAL
M["warn"] = warn
M["is_latex_derived"] = is_latex_derived
M["is_html"] = is_html
M["HTML_SECTION_ID"] = HTML_SECTION_ID
M["HTML_ANCHOR_PREFIX"] = HTML_ANCHOR_PREFIX
M["HTML_ENTRY_PREFIX"] = HTML_ENTRY_PREFIX
M["HTML_LETTER_CLASS"] = HTML_LETTER_CLASS
M["HTML_PENDING_ATTR"] = HTML_PENDING_ATTR

return M
